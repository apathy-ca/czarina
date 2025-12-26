#!/usr/bin/env bash
# czarina-core/czar-hopper-integration.sh
# Hopper monitoring and auto-assignment for autonomous czar
# Implements Task 2: Hopper Monitoring Integration
#
# This module provides:
# - Project hopper monitoring (new items)
# - Assessment logic (auto-include, auto-defer, ask-human)
# - Phase hopper monitoring (todo items)
# - Auto-assignment to idle workers

# This file is meant to be sourced by czar-autonomous-v2.sh
# Required functions from czar-autonomous-v2.sh:
#   - log_decision()
#   - get_worker_ids()

set -euo pipefail

# ============================================================================
# HOPPER PATH FUNCTIONS
# ============================================================================

# find_czarina_root()
# Find the czarina root directory
find_czarina_root() {
    local current_dir="$PWD"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/.czarina" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}

# get_project_hopper_path()
# Get path to project hopper
get_project_hopper_path() {
    local root
    root=$(find_czarina_root) || return 1
    echo "$root/.czarina/hopper"
}

# get_phase_hopper_path()
# Get path to current phase hopper
get_phase_hopper_path() {
    local root
    root=$(find_czarina_root) || return 1

    # Look for phase directories
    local phases_dir="$root/.czarina/phases"
    if [[ ! -d "$phases_dir" ]]; then
        return 1
    fi

    # Find the most recent phase directory
    local phase_dir
    phase_dir=$(find "$phases_dir" -maxdepth 1 -type d -name "phase-*" | sort -V | tail -n 1)

    if [[ -z "$phase_dir" ]]; then
        return 1
    fi

    echo "$phase_dir/hopper"
}

# ============================================================================
# HOPPER ITEM PARSING
# ============================================================================

# parse_hopper_item_metadata()
# Extract metadata from a hopper item file
# Usage: parse_hopper_item_metadata <file-path> <field>
# Fields: priority, complexity, tags, title
parse_hopper_item_metadata() {
    local file="${1:?File path required}"
    local field="${2:?Field required}"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    case "$field" in
        priority)
            grep -E "^\*\*Priority:\*\*" "$file" | sed 's/\*\*Priority:\*\* *//' | xargs 2>/dev/null || echo "Medium"
            ;;
        complexity)
            grep -E "^\*\*Complexity:\*\*" "$file" | sed 's/\*\*Complexity:\*\* *//' | xargs 2>/dev/null || echo "Medium"
            ;;
        tags)
            grep -E "^\*\*Tags:\*\*" "$file" | sed 's/\*\*Tags:\*\* *//' | xargs 2>/dev/null || echo ""
            ;;
        title)
            head -n 1 "$file" | sed 's/^# *//' 2>/dev/null || echo "Untitled"
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
}

# ============================================================================
# ASSESSMENT LOGIC
# ============================================================================

# assess_hopper_item()
# Assess a hopper item for phase inclusion
# Returns: auto-include | auto-defer | ask-human
# Usage: assess_hopper_item <file-path> <idle-worker-count>
assess_hopper_item() {
    local file="${1:?File path required}"
    local idle_count="${2:-0}"

    local priority complexity tags
    priority=$(parse_hopper_item_metadata "$file" "priority")
    complexity=$(parse_hopper_item_metadata "$file" "complexity")
    tags=$(parse_hopper_item_metadata "$file" "tags")

    # Convert to lowercase for comparison
    priority_lower=$(echo "$priority" | tr '[:upper:]' '[:lower:]')
    complexity_lower=$(echo "$complexity" | tr '[:upper:]' '[:lower:]')
    tags_lower=$(echo "$tags" | tr '[:upper:]' '[:lower:]')

    # Rule 1: Auto-defer if tagged with future version or "future"
    if [[ "$tags_lower" =~ (future|v0\.[7-9]\.|v[1-9]\.) ]]; then
        echo "auto-defer|Future version or explicitly tagged for future"
        return 0
    fi

    # Rule 2: Auto-include if High priority + Small complexity + idle workers available
    if [[ "$priority_lower" == "high" && "$complexity_lower" == "small" && $idle_count -gt 0 ]]; then
        echo "auto-include|High priority + Small complexity + Workers available"
        return 0
    fi

    # Rule 3: Auto-defer if Large complexity and no idle workers
    if [[ "$complexity_lower" == "large" && $idle_count -eq 0 ]]; then
        echo "auto-defer|Large complexity + No idle workers"
        return 0
    fi

    # Rule 4: Auto-defer if Low priority
    if [[ "$priority_lower" == "low" ]]; then
        echo "auto-defer|Low priority"
        return 0
    fi

    # Rule 5: Auto-include if High priority + Medium complexity + idle workers
    if [[ "$priority_lower" == "high" && "$complexity_lower" == "medium" && $idle_count -gt 0 ]]; then
        echo "auto-include|High priority + Medium complexity + Workers available"
        return 0
    fi

    # Default: Ask human for Medium priority or ambiguous cases
    echo "ask-human|Medium priority or requires human judgment"
}

# ============================================================================
# PROJECT HOPPER MONITORING
# ============================================================================

# get_project_hopper_items()
# Get list of items in project hopper
# Returns: File paths, one per line
get_project_hopper_items() {
    local hopper
    hopper=$(get_project_hopper_path) || return 1

    if [[ ! -d "$hopper" ]]; then
        return 0
    fi

    find "$hopper" -maxdepth 1 -name "*.md" ! -name "README.md" ! -name "*TEMPLATE*" -type f 2>/dev/null | sort
}

# check_project_hopper_new_items()
# Check for new items in project hopper since last check
# Uses a state file to track what's been seen
# Returns: List of new items
check_project_hopper_new_items() {
    local state_file="${STATUS_DIR}/hopper-seen-items.txt"
    local current_items=$(get_project_hopper_items)

    # Create state file if it doesn't exist
    if [[ ! -f "$state_file" ]]; then
        touch "$state_file"
    fi

    # Find new items (not in state file)
    local new_items=""
    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        if ! grep -Fxq "$item" "$state_file" 2>/dev/null; then
            new_items+="$item"$'\n'
        fi
    done <<< "$current_items"

    # Update state file
    echo "$current_items" > "$state_file"

    # Return new items
    echo -n "$new_items"
}

# assess_and_process_project_item()
# Assess a project hopper item and take action
# Usage: assess_and_process_project_item <file-path> <idle-count>
assess_and_process_project_item() {
    local file="${1:?File path required}"
    local idle_count="${2:-0}"

    local basename=$(basename "$file")
    local title=$(parse_hopper_item_metadata "$file" "title")
    local priority=$(parse_hopper_item_metadata "$file" "priority")
    local complexity=$(parse_hopper_item_metadata "$file" "complexity")

    # Assess the item
    local assessment_result=$(assess_hopper_item "$file" "$idle_count")
    local decision=$(echo "$assessment_result" | cut -d'|' -f1)
    local reason=$(echo "$assessment_result" | cut -d'|' -f2)

    case "$decision" in
        auto-include)
            log_decision "ACTION" "HOPPER_AUTO_INCLUDE" "Auto-including: $basename - $reason" \
                file=$basename title="$title" priority=$priority complexity=$complexity reason="$reason"

            # Move to phase hopper (if phase hopper exists)
            local phase_hopper
            if phase_hopper=$(get_phase_hopper_path 2>/dev/null); then
                mkdir -p "$phase_hopper/todo"
                cp "$file" "$phase_hopper/todo/"
                log_decision "SUCCESS" "HOPPER_MOVED_TO_PHASE" "Moved to phase hopper: $basename" file=$basename
            else
                log_decision "INFO" "HOPPER_NO_PHASE" "No active phase hopper, item remains in project hopper" file=$basename
            fi
            ;;

        auto-defer)
            log_decision "INFO" "HOPPER_AUTO_DEFER" "Auto-deferred: $basename - $reason" \
                file=$basename title="$title" priority=$priority complexity=$complexity reason="$reason"
            ;;

        ask-human)
            log_decision "ALERT" "HOPPER_ASK_HUMAN" "Human decision needed: $basename - $reason" \
                file=$basename title="$title" priority=$priority complexity=$complexity reason="$reason" severity=low
            ;;
    esac
}

# ============================================================================
# PHASE HOPPER MONITORING
# ============================================================================

# get_phase_hopper_todo_items()
# Get list of TODO items in phase hopper
# Returns: File paths, one per line
get_phase_hopper_todo_items() {
    local hopper
    hopper=$(get_phase_hopper_path 2>/dev/null) || return 1

    local todo_dir="$hopper/todo"
    if [[ ! -d "$todo_dir" ]]; then
        return 0
    fi

    find "$todo_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort
}

# count_phase_hopper_items()
# Count items in each phase hopper category
# Returns: "todo:N in_progress:N done:N"
count_phase_hopper_items() {
    local hopper
    hopper=$(get_phase_hopper_path 2>/dev/null) || {
        echo "todo:0 in_progress:0 done:0"
        return 0
    }

    local todo_count in_progress_count done_count
    todo_count=$(find "$hopper/todo" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    in_progress_count=$(find "$hopper/in-progress" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    done_count=$(find "$hopper/done" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)

    echo "todo:$todo_count in_progress:$in_progress_count done:$done_count"
}

# ============================================================================
# WORKER ASSIGNMENT
# ============================================================================

# assign_task_to_worker()
# Assign a hopper task to an idle worker
# Usage: assign_task_to_worker <worker-id> <task-file>
assign_task_to_worker() {
    local worker_id="${1:?Worker ID required}"
    local task_file="${2:?Task file required}"

    local basename=$(basename "$task_file")
    local title=$(parse_hopper_item_metadata "$task_file" "title")

    log_decision "ACTION" "HOPPER_ASSIGN_TASK" "Assigning task to worker" \
        worker=$worker_id file=$basename title="$title"

    # Move from todo to in-progress
    local hopper
    hopper=$(get_phase_hopper_path 2>/dev/null) || {
        log_decision "ERROR" "HOPPER_NO_PHASE" "Cannot assign task, no phase hopper" worker=$worker_id file=$basename
        return 1
    }

    mkdir -p "$hopper/in-progress"

    if [[ -f "$hopper/todo/$basename" ]]; then
        mv "$hopper/todo/$basename" "$hopper/in-progress/"
    fi

    # Inject task into worker session
    inject_task_to_worker "$worker_id" "$task_file"
}

# inject_task_to_worker()
# Inject a task into a worker's tmux session
# Usage: inject_task_to_worker <worker-id> <task-file>
inject_task_to_worker() {
    local worker_id="${1:?Worker ID required}"
    local task_file="${2:?Task file required}"

    # Get project slug from config
    local project_slug
    if [[ -f "$CONFIG_FILE" ]]; then
        project_slug=$(jq -r '.project.slug' "$CONFIG_FILE")
    else
        project_slug="czarina"
    fi

    local session="czarina-${project_slug}:${worker_id}"
    local basename=$(basename "$task_file")
    local title=$(parse_hopper_item_metadata "$task_file" "title")

    # Check if session exists
    if ! tmux has-session -t "$session" 2>/dev/null; then
        log_decision "ERROR" "SESSION_NOT_FOUND" "Cannot inject task, worker session not found" \
            worker=$worker_id session=$session file=$basename
        return 1
    fi

    # Send task via tmux
    tmux send-keys -t "$session" "" C-m
    tmux send-keys -t "$session" "# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" C-m
    tmux send-keys -t "$session" "# 🤖 AUTONOMOUS CZAR: New task assigned" C-m
    tmux send-keys -t "$session" "# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" C-m
    tmux send-keys -t "$session" "#" C-m
    tmux send-keys -t "$session" "# Task: $title" C-m
    tmux send-keys -t "$session" "# File: $basename" C-m
    tmux send-keys -t "$session" "#" C-m
    tmux send-keys -t "$session" "# Please review the task file at:" C-m
    tmux send-keys -t "$session" "#   cat $task_file" C-m
    tmux send-keys -t "$session" "#" C-m
    tmux send-keys -t "$session" "# When complete:" C-m
    tmux send-keys -t "$session" "#   - Commit your changes" C-m
    tmux send-keys -t "$session" "#   - Tag @czar to mark task complete" C-m
    tmux send-keys -t "$session" "# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" C-m
    tmux send-keys -t "$session" "" C-m

    log_decision "SUCCESS" "TASK_INJECTED" "Task injected into worker session" \
        worker=$worker_id file=$basename session=$session
}

# ============================================================================
# HOPPER MONITORING LOOP INTEGRATION
# ============================================================================

# monitor_hoppers()
# Main hopper monitoring function (called from autonomous czar loop)
# Usage: monitor_hoppers <idle-worker-count> [idle-worker-ids]
monitor_hoppers() {
    local idle_count="${1:-0}"
    shift || true
    local idle_workers=("$@")

    # Skip if no hopper monitoring enabled
    if [[ ! -d "$(get_project_hopper_path 2>/dev/null || echo /dev/null)" ]]; then
        return 0
    fi

    # 1. Check project hopper for new items
    local new_items=$(check_project_hopper_new_items)
    if [[ -n "$new_items" ]]; then
        while IFS= read -r item; do
            [[ -z "$item" ]] && continue

            local basename=$(basename "$item")
            log_decision "DETECT" "HOPPER_NEW_ITEM" "New item in project hopper" file=$basename

            # Assess and process the item
            assess_and_process_project_item "$item" "$idle_count"
        done <<< "$new_items"
    fi

    # 2. Check phase hopper for available work if we have idle workers
    if [[ $idle_count -gt 0 ]]; then
        local todo_items=$(get_phase_hopper_todo_items)

        if [[ -n "$todo_items" ]]; then
            # Count how many items we have
            local todo_count=$(echo "$todo_items" | grep -c "^" || echo "0")

            log_decision "DETECT" "HOPPER_WORK_AVAILABLE" "Phase hopper has work available" \
                todo_count=$todo_count idle_workers=$idle_count

            # Assign one task per idle worker (up to available tasks)
            local assigned=0
            for worker in "${idle_workers[@]}"; do
                [[ -z "$worker" ]] && continue

                # Get next available task
                local task=$(echo "$todo_items" | head -n 1)
                if [[ -z "$task" ]]; then
                    break
                fi

                # Assign task to worker
                assign_task_to_worker "$worker" "$task"
                assigned=$((assigned + 1))

                # Remove this task from the list
                todo_items=$(echo "$todo_items" | tail -n +2)
            done

            if [[ $assigned -gt 0 ]]; then
                log_decision "SUCCESS" "HOPPER_ASSIGNED_TASKS" "Assigned tasks to idle workers" count=$assigned
            fi
        fi
    fi
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

# Export all hopper-related functions
export -f find_czarina_root
export -f get_project_hopper_path
export -f get_phase_hopper_path
export -f parse_hopper_item_metadata
export -f assess_hopper_item
export -f get_project_hopper_items
export -f check_project_hopper_new_items
export -f assess_and_process_project_item
export -f get_phase_hopper_todo_items
export -f count_phase_hopper_items
export -f assign_task_to_worker
export -f inject_task_to_worker
export -f monitor_hoppers
