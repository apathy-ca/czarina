#!/usr/bin/env bash
# czarina-core/czar-dependency-tracking.sh
# Dependency tracking and coordination for autonomous czar
# Implements Task 3: Dependency & Coordination (B4 basic)
#
# This module provides:
# - Worker dependency tracking (from config.json)
# - Blocked worker detection and notification
# - Integration readiness assessment
# - Integration strategy suggestions

# This file is meant to be sourced by czar-autonomous-v2.sh
# Required functions from czar-autonomous-v2.sh:
#   - log_decision()
#   - get_worker_ids()
#   - get_worker_status()
#   - get_worker_dependencies()

set -euo pipefail

# ============================================================================
# DEPENDENCY TRACKING
# ============================================================================

# check_worker_dependencies_met()
# Check if all dependencies for a worker are met
# Usage: check_worker_dependencies_met <worker-id>
# Returns: 0 if all dependencies met, 1 if any are not met
check_worker_dependencies_met() {
    local worker_id="${1:?Worker ID required}"

    # Get dependencies from config
    local dependencies=$(get_worker_dependencies "$worker_id")

    if [[ -z "$dependencies" ]]; then
        # No dependencies, automatically met
        return 0
    fi

    # Check each dependency
    local all_met=true
    for dep in $dependencies; do
        local dep_status=$(get_worker_status "$dep")

        # Dependency is not met if it's pending or unknown
        # We consider "working" as acceptable (work in progress)
        # "idle" means completed but not yet integrated
        if [[ "$dep_status" == "pending" || "$dep_status" == "unknown" ]]; then
            all_met=false
            break
        fi
    done

    if [[ "$all_met" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# get_unmet_dependencies()
# Get list of unmet dependencies for a worker
# Usage: get_unmet_dependencies <worker-id>
# Returns: List of dependency worker IDs that are not yet ready
get_unmet_dependencies() {
    local worker_id="${1:?Worker ID required}"

    local dependencies=$(get_worker_dependencies "$worker_id")
    local unmet=""

    for dep in $dependencies; do
        local dep_status=$(get_worker_status "$dep")

        if [[ "$dep_status" == "pending" || "$dep_status" == "unknown" ]]; then
            unmet+="$dep "
        fi
    done

    echo "$unmet" | xargs
}

# get_dependency_progress()
# Get dependency completion progress for a worker
# Usage: get_dependency_progress <worker-id>
# Returns: "N/M" where N is met dependencies, M is total dependencies
get_dependency_progress() {
    local worker_id="${1:?Worker ID required}"

    local dependencies=$(get_worker_dependencies "$worker_id")

    if [[ -z "$dependencies" ]]; then
        echo "0/0"
        return 0
    fi

    local total=0
    local met=0

    for dep in $dependencies; do
        total=$((total + 1))
        local dep_status=$(get_worker_status "$dep")

        if [[ "$dep_status" != "pending" && "$dep_status" != "unknown" ]]; then
            met=$((met + 1))
        fi
    done

    echo "$met/$total"
}

# ============================================================================
# BLOCKED WORKER DETECTION
# ============================================================================

# is_worker_blocked_by_dependencies()
# Check if a worker is blocked waiting for dependencies
# A worker is considered blocked if:
#   - It has unmet dependencies
#   - It's in "working" or "idle" state (not pending)
#   - (Pending workers are not yet blocked, just not started)
# Usage: is_worker_blocked_by_dependencies <worker-id>
# Returns: 0 if blocked, 1 if not blocked
is_worker_blocked_by_dependencies() {
    local worker_id="${1:?Worker ID required}"

    local worker_status=$(get_worker_status "$worker_id")

    # Pending workers are not yet blocked
    if [[ "$worker_status" == "pending" || "$worker_status" == "unknown" ]]; then
        return 1
    fi

    # Check if dependencies are met
    if ! check_worker_dependencies_met "$worker_id"; then
        return 0  # Blocked
    else
        return 1  # Not blocked
    fi
}

# get_blocked_workers()
# Get list of all workers blocked by dependencies
# Returns: Worker IDs, one per line
get_blocked_workers() {
    local blocked=""

    local workers=$(get_worker_ids)

    for worker in $workers; do
        if is_worker_blocked_by_dependencies "$worker"; then
            blocked+="$worker"$'\n'
        fi
    done

    echo -n "$blocked"
}

# ============================================================================
# INTEGRATION READINESS
# ============================================================================

# check_worker_integration_ready()
# Check if a worker is ready for integration
# A worker is ready for integration if:
#   - Status is "idle" (completed work)
#   - All dependencies are met
#   - Has commits on their branch
# Usage: check_worker_integration_ready <worker-id>
# Returns: 0 if ready, 1 if not ready
check_worker_integration_ready() {
    local worker_id="${1:?Worker ID required}"

    local worker_status=$(get_worker_status "$worker_id")

    # Must be idle (completed)
    if [[ "$worker_status" != "idle" ]]; then
        return 1
    fi

    # All dependencies must be met
    if ! check_worker_dependencies_met "$worker_id"; then
        return 1
    fi

    # Check if worker has commits (from worker-status.json)
    if [[ -f "$WORKER_STATUS_FILE" ]]; then
        local commit_count=$(jq -r ".workers[\"$worker_id\"].stats.commits // 0" "$WORKER_STATUS_FILE")

        if [[ "$commit_count" -eq 0 ]]; then
            return 1
        fi
    fi

    return 0
}

# get_integration_ready_workers()
# Get list of workers ready for integration
# Returns: Worker IDs, one per line
get_integration_ready_workers() {
    local ready=""

    local workers=$(get_worker_ids)

    for worker in $workers; do
        if check_worker_integration_ready "$worker"; then
            ready+="$worker"$'\n'
        fi
    done

    echo -n "$ready"
}

# ============================================================================
# INTEGRATION STRATEGY
# ============================================================================

# suggest_integration_order()
# Suggest order for integrating workers based on dependencies
# Returns: Worker IDs in suggested integration order
suggest_integration_order() {
    local workers=$(get_worker_ids)
    local ordered=""
    local processed=""

    # Simple topological sort based on dependencies
    # Workers with no dependencies or all dependencies met go first

    while true; do
        local added_this_iteration=false

        for worker in $workers; do
            # Skip if already processed
            if echo "$processed" | grep -q "\\b$worker\\b"; then
                continue
            fi

            # Get dependencies
            local dependencies=$(get_worker_dependencies "$worker")

            # Check if all dependencies are already in ordered list
            local deps_met=true
            for dep in $dependencies; do
                if ! echo "$ordered" | grep -q "\\b$dep\\b"; then
                    deps_met=false
                    break
                fi
            done

            # If all dependencies met (or no dependencies), add to ordered list
            if [[ "$deps_met" == "true" ]]; then
                ordered+="$worker "
                processed+="$worker "
                added_this_iteration=true
            fi
        done

        # If we didn't add anything this iteration, we're done (or there's a cycle)
        if [[ "$added_this_iteration" == "false" ]]; then
            # Add any remaining workers (circular dependencies or isolated)
            for worker in $workers; do
                if ! echo "$processed" | grep -q "\\b$worker\\b"; then
                    ordered+="$worker "
                    processed+="$worker "
                fi
            done
            break
        fi
    done

    echo "$ordered" | xargs
}

# get_integration_strategy()
# Get a complete integration strategy report
# Returns: Formatted string with integration plan
get_integration_strategy() {
    local integration_order=$(suggest_integration_order)
    local ready_workers=$(get_integration_ready_workers)

    local strategy="Integration Strategy:\n"
    strategy+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

    strategy+="Suggested Integration Order:\n"
    local position=1
    for worker in $integration_order; do
        local status=$(get_worker_status "$worker")
        local deps=$(get_worker_dependencies "$worker")
        local dep_progress=$(get_dependency_progress "$worker")

        strategy+="  $position. $worker (status: $status, deps: $dep_progress)\n"

        if [[ -n "$deps" ]]; then
            strategy+="     Dependencies: $deps\n"
        fi

        # Check if ready for integration
        if echo "$ready_workers" | grep -q "\\b$worker\\b"; then
            strategy+="     ✓ Ready for integration\n"
        else
            if [[ "$status" == "pending" ]]; then
                strategy+="     ⏳ Not yet started\n"
            elif [[ "$status" == "working" ]]; then
                strategy+="     🔄 Work in progress\n"
            elif is_worker_blocked_by_dependencies "$worker"; then
                local unmet=$(get_unmet_dependencies "$worker")
                strategy+="     ⚠️ Blocked by: $unmet\n"
            fi
        fi

        strategy+="\n"
        position=$((position + 1))
    done

    strategy+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    echo -e "$strategy"
}

# ============================================================================
# DEPENDENCY MONITORING
# ============================================================================

# monitor_dependencies()
# Main dependency monitoring function (called from autonomous czar loop)
# Detects blocked workers and suggests integration strategies
monitor_dependencies() {
    local iteration="${1:-0}"

    # Check for blocked workers
    local blocked_workers=$(get_blocked_workers)

    if [[ -n "$blocked_workers" ]]; then
        while IFS= read -r worker; do
            [[ -z "$worker" ]] && continue

            local unmet=$(get_unmet_dependencies "$worker")

            # Check if we've recently notified about this blockage
            # (Look for notification in last hour)
            local last_notification=$(grep "WORKER_DEPENDENCY_BLOCKED.*worker=$worker" "$DECISIONS_LOG" 2>/dev/null | tail -1 | cut -d']' -f1 | tr -d '[' || echo "")

            if [[ -n "$last_notification" ]]; then
                local last_epoch=$(date -d "$last_notification" +%s 2>/dev/null || echo "0")
                local current_epoch=$(date +%s)
                local time_since=$((current_epoch - last_epoch))

                # Only notify if more than 1 hour since last notification
                if [[ $time_since -lt 3600 ]]; then
                    continue
                fi
            fi

            log_decision "DETECT" "WORKER_DEPENDENCY_BLOCKED" "Worker blocked by dependencies: $worker" \
                worker=$worker blocked_by="$unmet" severity=medium
        done <<< "$blocked_workers"
    fi

    # Check for integration-ready workers (every 30 iterations = 15 minutes)
    if [[ $((iteration % 30)) -eq 0 ]]; then
        local ready_workers=$(get_integration_ready_workers)

        if [[ -n "$ready_workers" ]]; then
            local count=$(echo "$ready_workers" | wc -w)

            log_decision "INFO" "INTEGRATION_READY" "Workers ready for integration" \
                count=$count workers="$ready_workers"

            # Log integration strategy
            local strategy=$(get_integration_strategy)
            log_decision "INFO" "INTEGRATION_STRATEGY" "Current integration strategy" \
                ready_count=$count
        fi
    fi
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

# Export all dependency tracking functions
export -f check_worker_dependencies_met
export -f get_unmet_dependencies
export -f get_dependency_progress
export -f is_worker_blocked_by_dependencies
export -f get_blocked_workers
export -f check_worker_integration_ready
export -f get_integration_ready_workers
export -f suggest_integration_order
export -f get_integration_strategy
export -f monitor_dependencies
