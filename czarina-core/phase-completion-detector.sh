#!/bin/bash
# Phase Completion Detector
# Detects when all workers in a phase have completed their work
#
# This script checks multiple signals to determine phase completion:
# - Worker completion logs (WORKER_COMPLETE event)
# - Git branch merge status (merged to omnibus)
# - Worker status in worker-status.json
# - Configuration-based completion criteria
#
# Usage: ./phase-completion-detector.sh [options]
#   --config-file <path>    Path to config.json (default: ./config.json)
#   --phase <number>        Phase to check (default: current phase from config)
#   --verbose              Enable verbose output
#   --json                 Output JSON format
#
# Exit codes:
#   0 - Phase is complete
#   1 - Phase is not complete
#   2 - Error occurred

set -euo pipefail

# ============================================================================
# CONFIGURATION & DEFAULTS
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
CONFIG_FILE="${CONFIG_FILE:-./config.json}"
PHASE=""
VERBOSE=false
JSON_OUTPUT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --config-file)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --phase)
            PHASE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --help)
            head -n 25 "$0" | grep "^#" | sed 's/^# *//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 2
            ;;
    esac
done

# ============================================================================
# VALIDATION
# ============================================================================

# Check for required tools
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    exit 2
fi

# Validate config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE" >&2
    exit 2
fi

# Get project configuration
PROJECT_ROOT=$(jq -r '.project.repository' "$CONFIG_FILE")
ORCHESTRATION_DIR=$(jq -r '.project.orchestration_dir // ".czarina"' "$CONFIG_FILE")
CURRENT_PHASE=$(jq -r '.project.phase // 1' "$CONFIG_FILE")

# Use specified phase or current phase
PHASE="${PHASE:-$CURRENT_PHASE}"

# Paths
CZARINA_DIR="${PROJECT_ROOT}/${ORCHESTRATION_DIR}"
LOGS_DIR="${CZARINA_DIR}/logs"
STATUS_DIR="${CZARINA_DIR}/status"
PHASE_STATE_FILE="${STATUS_DIR}/phase-state.json"
WORKER_STATUS_FILE="${CZARINA_DIR}/worker-status.json"

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "[PHASE-DETECTOR] $*" >&2
    fi
}

log_error() {
    echo "[PHASE-DETECTOR ERROR] $*" >&2
}

# ============================================================================
# WORKER COMPLETION DETECTION
# ============================================================================

# Check if worker has WORKER_COMPLETE marker in logs
check_worker_log_completion() {
    local worker_id="$1"
    local worker_log="${LOGS_DIR}/${worker_id}.log"

    if [ ! -f "$worker_log" ]; then
        log_verbose "No log file for worker: $worker_id"
        return 1
    fi

    if grep -q "WORKER_COMPLETE" "$worker_log" 2>/dev/null; then
        log_verbose "Worker $worker_id has WORKER_COMPLETE marker"
        return 0
    fi

    log_verbose "Worker $worker_id missing WORKER_COMPLETE marker"
    return 1
}

# Check if worker branch is merged to omnibus
check_worker_branch_merged() {
    local worker_branch="$1"
    local omnibus_branch="$2"

    cd "$PROJECT_ROOT" 2>/dev/null || return 1

    # Check if branch exists
    if ! git show-ref --verify --quiet refs/heads/"$worker_branch" 2>/dev/null; then
        log_verbose "Branch $worker_branch does not exist"
        return 1
    fi

    # Check if omnibus branch exists
    if ! git show-ref --verify --quiet refs/heads/"$omnibus_branch" 2>/dev/null; then
        log_verbose "Omnibus branch $omnibus_branch does not exist"
        return 1
    fi

    # Check if worker branch is fully merged into omnibus
    local not_merged=$(git log "$omnibus_branch".."$worker_branch" --oneline 2>/dev/null | wc -l)

    if [ "$not_merged" -eq 0 ]; then
        log_verbose "Branch $worker_branch is fully merged to $omnibus_branch"
        return 0
    else
        log_verbose "Branch $worker_branch has $not_merged unmerged commits"
        return 1
    fi
}

# Check worker status from worker-status.json
check_worker_status_complete() {
    local worker_id="$1"

    if [ ! -f "$WORKER_STATUS_FILE" ]; then
        log_verbose "Worker status file not found: $WORKER_STATUS_FILE"
        return 1
    fi

    local status=$(jq -r ".workers.\"${worker_id}\".status // \"unknown\"" "$WORKER_STATUS_FILE")

    if [ "$status" = "complete" ] || [ "$status" = "completed" ]; then
        log_verbose "Worker $worker_id status is $status"
        return 0
    fi

    log_verbose "Worker $worker_id status is $status (not complete)"
    return 1
}

# Comprehensive worker completion check
is_worker_complete() {
    local worker_id="$1"
    local worker_branch="$2"
    local omnibus_branch="$3"
    local completion_mode="${4:-any}"  # any, all, strict

    local log_complete=false
    local branch_merged=false
    local status_complete=false

    # Check all signals
    if check_worker_log_completion "$worker_id"; then
        log_complete=true
    fi

    if check_worker_branch_merged "$worker_branch" "$omnibus_branch"; then
        branch_merged=true
    fi

    if check_worker_status_complete "$worker_id"; then
        status_complete=true
    fi

    # Determine completion based on mode
    case "$completion_mode" in
        any)
            # Any signal indicates completion
            if [ "$log_complete" = true ] || [ "$branch_merged" = true ] || [ "$status_complete" = true ]; then
                return 0
            fi
            ;;
        all)
            # All signals must indicate completion
            if [ "$log_complete" = true ] && [ "$branch_merged" = true ] && [ "$status_complete" = true ]; then
                return 0
            fi
            ;;
        strict)
            # Log marker AND (branch merged OR status complete)
            if [ "$log_complete" = true ] && ([ "$branch_merged" = true ] || [ "$status_complete" = true ]); then
                return 0
            fi
            ;;
        *)
            log_error "Unknown completion mode: $completion_mode"
            return 1
            ;;
    esac

    return 1
}

# ============================================================================
# PHASE COMPLETION DETECTION
# ============================================================================

detect_phase_completion() {
    local phase_number="$1"
    local completion_mode="${2:-any}"

    log_verbose "Detecting completion for Phase $phase_number"
    log_verbose "Completion mode: $completion_mode"

    # Get omnibus branch
    local omnibus_branch=$(jq -r '.omnibus_branch // .project.omnibus_branch // "main"' "$CONFIG_FILE")
    log_verbose "Omnibus branch: $omnibus_branch"

    # Get all workers for this phase
    local workers=$(jq -c ".workers[] | select(.phase == $phase_number or (.phase == null and $phase_number == 1))" "$CONFIG_FILE")

    if [ -z "$workers" ]; then
        log_verbose "No workers found for phase $phase_number"

        # Output result even when no workers
        if [ "$JSON_OUTPUT" = true ]; then
            cat <<EOF
{
  "phase": $phase_number,
  "complete": false,
  "total_workers": 0,
  "completed_workers": 0,
  "incomplete_workers": [],
  "completion_mode": "$completion_mode",
  "timestamp": "$(date -Iseconds)",
  "error": "No workers found for phase $phase_number"
}
EOF
        else
            echo "Phase $phase_number has no workers"
        fi

        return 1
    fi

    local total_workers=0
    local completed_workers=0
    local incomplete_workers=()

    # Check each worker
    while IFS= read -r worker; do
        total_workers=$((total_workers + 1))

        local worker_id=$(echo "$worker" | jq -r '.id')
        local worker_branch=$(echo "$worker" | jq -r '.branch')
        local worker_role=$(echo "$worker" | jq -r '.role // "unknown"')

        log_verbose "Checking worker: $worker_id ($worker_role, $worker_branch)"

        if is_worker_complete "$worker_id" "$worker_branch" "$omnibus_branch" "$completion_mode"; then
            completed_workers=$((completed_workers + 1))
            log_verbose "  ✓ Worker $worker_id is complete"
        else
            incomplete_workers+=("$worker_id")
            log_verbose "  ✗ Worker $worker_id is incomplete"
        fi
    done < <(echo "$workers")

    log_verbose "Phase $phase_number: $completed_workers/$total_workers workers complete"

    # Build result
    local is_complete=false
    if [ $total_workers -gt 0 ] && [ $completed_workers -eq $total_workers ]; then
        is_complete=true
    fi

    # Output results
    if [ "$JSON_OUTPUT" = true ]; then
        local incomplete_json=$(printf '%s\n' "${incomplete_workers[@]}" | jq -R . | jq -s .)
        cat <<EOF
{
  "phase": $phase_number,
  "complete": $is_complete,
  "total_workers": $total_workers,
  "completed_workers": $completed_workers,
  "incomplete_workers": $incomplete_json,
  "completion_mode": "$completion_mode",
  "timestamp": "$(date -Iseconds)"
}
EOF
    else
        if [ "$is_complete" = true ]; then
            echo "Phase $phase_number is COMPLETE ($completed_workers/$total_workers workers)"
        else
            echo "Phase $phase_number is INCOMPLETE ($completed_workers/$total_workers workers)"
            if [ ${#incomplete_workers[@]} -gt 0 ]; then
                echo "Incomplete workers: ${incomplete_workers[*]}"
            fi
        fi
    fi

    # Return exit code
    if [ "$is_complete" = true ]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Read completion mode from config if available
COMPLETION_MODE=$(jq -r '.phase_completion_mode // "any"' "$CONFIG_FILE")

log_verbose "Starting phase completion detection"
log_verbose "Config file: $CONFIG_FILE"
log_verbose "Phase: $PHASE"
log_verbose "Completion mode: $COMPLETION_MODE"

# Detect phase completion
if detect_phase_completion "$PHASE" "$COMPLETION_MODE"; then
    exit 0
else
    exit 1
fi
