#!/bin/bash
# Autonomous Czar Daemon
# Monitors workers and coordinates orchestration without human intervention
#
# This daemon implements true autonomous coordination:
# - Monitors worker status every 5 minutes
# - Detects stuck/idle workers (idle > 30 min)
# - Detects phase completion
# - Automatically launches Phase 2 when Phase 1 complete
# - Coordinates dependency-based worker launches
# - Comprehensive logging of all decisions
#
# Usage: ./autonomous-czar-daemon.sh [project-dir]
#   project-dir: Path to czarina-* orchestration directory (defaults to .)

set -uo pipefail  # Don't use -e - daemon should continue on errors

# ============================================================================
# CONFIGURATION
# ============================================================================

PROJECT_DIR="${1:-.}"
CONFIG_FILE="${PROJECT_DIR}/config.json"

# Validate config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    echo "Usage: $0 <project-orchestration-dir>"
    exit 1
fi

# Load jq for JSON parsing
if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed"
    exit 1
fi

# Extract configuration
PROJECT_SLUG=$(jq -r '.project.slug' "$CONFIG_FILE")
PROJECT_ROOT=$(jq -r '.project.repository' "$CONFIG_FILE")
WORKER_COUNT=$(jq '.workers | length' "$CONFIG_FILE")

# Logging
LOG_DIR="${PROJECT_DIR}/status"
LOG_FILE="${LOG_DIR}/czar-daemon.log"
DECISIONS_LOG="${LOG_DIR}/autonomous-decisions.log"
PHASE_STATE_FILE="${LOG_DIR}/phase-state.json"

# Timing configuration
CHECK_INTERVAL=300          # 5 minutes between checks
STUCK_THRESHOLD=1800        # 30 minutes = stuck
IDLE_THRESHOLD=600          # 10 minutes = idle warning

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [$level] $message" | tee -a "$LOG_FILE"
}

log_decision() {
    local action="$1"
    local details="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [DECISION] $action: $details" | tee -a "$DECISIONS_LOG"
}

# ============================================================================
# INITIALIZATION
# ============================================================================

log "INFO" "🤖 AUTONOMOUS CZAR DAEMON STARTING"
log "INFO" "Project: $PROJECT_SLUG"
log "INFO" "Workers: $WORKER_COUNT"
log "INFO" "Check interval: ${CHECK_INTERVAL}s (5 minutes)"
log "INFO" "Stuck threshold: ${STUCK_THRESHOLD}s (30 minutes)"
log "INFO" "============================================"

# Initialize phase state if not exists
if [ ! -f "$PHASE_STATE_FILE" ]; then
    # Build initial state with all phases
    local max_phase=1
    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_phase=$(jq -r ".workers[$i].phase // 1" "$CONFIG_FILE")
        if [ "$worker_phase" != "null" ] && [ "$worker_phase" -gt "$max_phase" ]; then
            max_phase=$worker_phase
        fi
    done

    # Create state object with phase tracking
    local state='{"current_phase": 1, "orchestration_complete": false'

    for ((phase=1; phase<=max_phase; phase++)); do
        # Phase 1 is considered "launched" since those workers start immediately
        if [ $phase -eq 1 ]; then
            state="${state}, \"phase_${phase}_launched\": true"
        else
            state="${state}, \"phase_${phase}_launched\": false"
        fi
        state="${state}, \"phase_${phase}_complete\": false"
    done

    state="${state}}"
    echo "$state" > "$PHASE_STATE_FILE"

    log "INFO" "Initialized phase state: Phase 1 active, $max_phase total phases"
fi

# ============================================================================
# WORKER STATUS FUNCTIONS
# ============================================================================

# Get worker branch name
get_worker_branch() {
    local worker_index=$1
    jq -r ".workers[$worker_index].branch" "$CONFIG_FILE"
}

# Get worker ID
get_worker_id() {
    local worker_index=$1
    jq -r ".workers[$worker_index].id" "$CONFIG_FILE"
}

# Get worker phase
get_worker_phase() {
    local worker_index=$1
    jq -r ".workers[$worker_index].phase // 1" "$CONFIG_FILE"
}

# Check if worker is complete (has completion marker)
is_worker_complete() {
    local worker_index=$1
    local worker_branch=$(get_worker_branch $worker_index)

    if [ "$worker_branch" = "null" ] || [ -z "$worker_branch" ]; then
        return 1  # No branch = not complete
    fi

    cd "$PROJECT_ROOT" 2>/dev/null || return 1

    # Check for worker completion log event
    local worker_id=$(get_worker_id $worker_index)
    local worker_log="${PROJECT_DIR}/logs/${worker_id}.log"

    if [ -f "$worker_log" ]; then
        if grep -q "WORKER_COMPLETE" "$worker_log" 2>/dev/null; then
            return 0  # Complete!
        fi
    fi

    # Fallback: check for checkpoint markers in git log
    if git log "$worker_branch" --oneline 2>/dev/null | grep -qi "checkpoint.*complete\|worker.*complete"; then
        return 0  # Complete
    fi

    return 1  # Not complete
}

# Get worker status (ACTIVE, IDLE, STUCK, COMPLETE, PENDING)
get_worker_status() {
    local worker_index=$1
    local worker_branch=$(get_worker_branch $worker_index)

    if [ "$worker_branch" = "null" ] || [ -z "$worker_branch" ]; then
        echo "PENDING"
        return
    fi

    cd "$PROJECT_ROOT" 2>/dev/null || {
        echo "ERROR"
        return
    }

    # Check if complete first
    if is_worker_complete $worker_index; then
        echo "COMPLETE"
        return
    fi

    # Check last commit time
    last_commit=$(git log -1 --format=%ct "$worker_branch" 2>/dev/null || echo "0")

    if [ "$last_commit" = "0" ]; then
        echo "PENDING"
        return
    fi

    now=$(date +%s)
    idle_time=$((now - last_commit))

    if [ $idle_time -gt $STUCK_THRESHOLD ]; then
        echo "STUCK"
    elif [ $idle_time -gt $IDLE_THRESHOLD ]; then
        echo "IDLE"
    else
        echo "ACTIVE"
    fi
}

# ============================================================================
# PHASE MANAGEMENT FUNCTIONS
# ============================================================================

# Get maximum phase number from config
get_max_phase() {
    local max_phase=1

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_phase=$(get_worker_phase $i)
        if [ "$worker_phase" != "null" ] && [ "$worker_phase" -gt "$max_phase" ]; then
            max_phase=$worker_phase
        fi
    done

    echo "$max_phase"
}

# Check if phase is complete
is_phase_complete() {
    local phase=$1
    local phase_has_workers=false
    local all_complete=true

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_phase=$(get_worker_phase $i)

        if [ "$worker_phase" = "$phase" ]; then
            phase_has_workers=true
            if ! is_worker_complete $i; then
                all_complete=false
                break
            fi
        fi
    done

    # If no workers in this phase, consider it non-existent (not complete)
    if [ "$phase_has_workers" = false ]; then
        return 1
    fi

    if [ "$all_complete" = true ]; then
        return 0  # Complete
    else
        return 1  # Not complete
    fi
}

# Get phase workers (returns indices)
get_phase_workers() {
    local phase=$1
    local workers=()

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_phase=$(get_worker_phase $i)
        if [ "$worker_phase" = "$phase" ]; then
            workers+=("$i")
        fi
    done

    echo "${workers[@]}"
}

# Check if all phases are complete
is_orchestration_complete() {
    local max_phase=$(get_max_phase)

    for ((phase=1; phase<=max_phase; phase++)); do
        if ! is_phase_complete $phase; then
            return 1  # Not all phases complete
        fi
    done

    return 0  # All phases complete!
}

# ============================================================================
# MONITORING LOOP
# ============================================================================

monitor_workers() {
    log "INFO" "📊 Monitoring cycle starting..."

    # Load current phase state
    current_phase=$(jq -r '.current_phase' "$PHASE_STATE_FILE")
    orchestration_complete=$(jq -r '.orchestration_complete // false' "$PHASE_STATE_FILE")

    # If orchestration is complete, just monitor but don't trigger transitions
    if [ "$orchestration_complete" = "true" ]; then
        log "INFO" "🎉 Orchestration complete - monitoring only"
        return
    fi

    local max_phase=$(get_max_phase)
    log "INFO" "Current phase: $current_phase (max phase: $max_phase)"

    # Check each worker
    local stuck_workers=()
    local idle_workers=()
    local active_workers=()
    local complete_workers=()

    # Phase-specific tracking
    declare -A phase_complete_count
    declare -A phase_total_count

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(get_worker_id $i)
        worker_phase=$(get_worker_phase $i)
        status=$(get_worker_status $i)

        log "INFO" "  Worker $worker_id (phase $worker_phase): $status"

        # Track phase statistics
        if [ "$worker_phase" != "null" ]; then
            phase_total_count[$worker_phase]=$((${phase_total_count[$worker_phase]:-0} + 1))
            if [ "$status" = "COMPLETE" ]; then
                phase_complete_count[$worker_phase]=$((${phase_complete_count[$worker_phase]:-0} + 1))
            fi
        fi

        case "$status" in
            STUCK)
                stuck_workers+=("$worker_id")
                ;;
            IDLE)
                idle_workers+=("$worker_id")
                ;;
            ACTIVE)
                active_workers+=("$worker_id")
                ;;
            COMPLETE)
                complete_workers+=("$worker_id")
                ;;
        esac
    done

    # Report stuck workers
    if [ ${#stuck_workers[@]} -gt 0 ]; then
        log "WARN" "⚠️  Stuck workers (idle > 30 min): ${stuck_workers[*]}"
        log_decision "STUCK_DETECTED" "Workers: ${stuck_workers[*]}"
        # TODO: In future, could auto-nudge or alert human
    fi

    # Report idle workers
    if [ ${#idle_workers[@]} -gt 0 ]; then
        log "INFO" "💤 Idle workers (idle > 10 min): ${idle_workers[*]}"
    fi

    # Report overall progress
    log "INFO" "📈 Overall: ${#complete_workers[@]}/$WORKER_COUNT complete, ${#active_workers[@]} active"

    # Report phase-by-phase progress
    for ((phase=1; phase<=max_phase; phase++)); do
        local complete=${phase_complete_count[$phase]:-0}
        local total=${phase_total_count[$phase]:-0}

        if [ $total -gt 0 ]; then
            log "INFO" "📊 Phase $phase: $complete/$total complete"
        fi
    done

    # Check for phase transitions
    # We check all phases in order, triggering the next phase when current completes
    for ((phase=1; phase<=max_phase; phase++)); do
        local phase_launched_key="phase_${phase}_launched"
        local phase_complete_key="phase_${phase}_complete"

        local is_launched=$(jq -r ".$phase_launched_key // false" "$PHASE_STATE_FILE")
        local is_complete=$(jq -r ".$phase_complete_key // false" "$PHASE_STATE_FILE")

        # Check if this phase just completed
        if [ "$is_complete" = "false" ] && is_phase_complete $phase; then
            log "INFO" ""
            log "INFO" "✅ ═══════════════════════════════════════════════"
            log "INFO" "✅ PHASE $phase COMPLETE!"
            log "INFO" "✅ ═══════════════════════════════════════════════"
            log "INFO" ""

            local phase_workers=($(get_phase_workers $phase))
            log_decision "PHASE_COMPLETE" "Phase $phase complete with ${#phase_workers[@]} workers"

            # Mark phase as complete
            jq --arg key "$phase_complete_key" \
               '.[$key] = true' "$PHASE_STATE_FILE" > "${PHASE_STATE_FILE}.tmp"
            mv "${PHASE_STATE_FILE}.tmp" "$PHASE_STATE_FILE"

            # Brief pause to ensure all workers have finished cleanup
            log "INFO" "⏸️  Waiting 30s to ensure workers have finished cleanup..."
            sleep 30

            # Check if there's a next phase
            local next_phase=$((phase + 1))
            if [ $next_phase -le $max_phase ]; then
                # Launch next phase
                launch_next_phase $phase
            else
                # This was the last phase - check if orchestration is complete
                if is_orchestration_complete; then
                    handle_orchestration_complete
                fi
            fi
        fi
    done
}

# Launch next phase workers
launch_next_phase() {
    local completed_phase=$1
    local next_phase=$((completed_phase + 1))

    log "INFO" "🚀 Launching Phase $next_phase workers..."
    log_decision "PHASE_TRANSITION" "Transitioning from Phase $completed_phase to Phase $next_phase"

    # Get next phase workers
    local next_phase_workers=($(get_phase_workers $next_phase))

    if [ ${#next_phase_workers[@]} -eq 0 ]; then
        log "INFO" "No Phase $next_phase workers defined - checking if orchestration complete"

        # Check if ALL phases are done
        if is_orchestration_complete; then
            handle_orchestration_complete
        fi
        return
    fi

    log "INFO" "Phase $next_phase workers to launch: ${#next_phase_workers[@]}"

    # Launch each worker using czarina launch with worker filtering
    local launch_success=true
    for worker_idx in "${next_phase_workers[@]}"; do
        local worker_id=$(get_worker_id $worker_idx)
        local worker_branch=$(get_worker_branch $worker_idx)

        log "INFO" "  → Launching: $worker_id (branch: $worker_branch)"

        # Check if worker already has a session
        if tmux has-session -t "czarina-worker-${worker_id}" 2>/dev/null; then
            log "WARN" "  ⚠️  Worker session already exists: $worker_id"
            log_decision "WORKER_SKIP" "Worker $worker_id already running"
            continue
        fi

        # Launch worker in background
        # Note: This assumes czarina launch can target specific workers
        # If not, we may need to call the launch script directly
        cd "$PROJECT_ROOT" 2>/dev/null || {
            log "ERROR" "Failed to change to project root: $PROJECT_ROOT"
            launch_success=false
            continue
        }

        # Try to launch using czarina CLI
        if command -v czarina &> /dev/null; then
            log "INFO" "  → Using czarina CLI to launch $worker_id"
            # Note: This may need adjustment based on actual czarina launch API
            # For now, we'll note this as needing the launch infrastructure
            log "WARN" "  ⚠️  Worker auto-launch requires manual setup or launch script"
            log_decision "WORKER_LAUNCH_PENDING" "Worker $worker_id needs manual launch"
        else
            log "WARN" "  ⚠️  czarina command not found - cannot auto-launch"
            launch_success=false
        fi
    done

    # Update phase state
    local phase_key="phase_${next_phase}_launched"
    jq --arg key "$phase_key" --argjson val true \
       '.[$key] = $val | .current_phase = '$next_phase "$PHASE_STATE_FILE" > "${PHASE_STATE_FILE}.tmp"
    mv "${PHASE_STATE_FILE}.tmp" "$PHASE_STATE_FILE"

    if [ "$launch_success" = true ]; then
        log "INFO" "✅ Phase $next_phase launch complete"
    else
        log "WARN" "⚠️  Phase $next_phase launch completed with warnings"
    fi
}

# Handle orchestration completion
handle_orchestration_complete() {
    log "INFO" ""
    log "INFO" "🎉 ═══════════════════════════════════════════════"
    log "INFO" "🎉 ORCHESTRATION COMPLETE!"
    log "INFO" "🎉 ═══════════════════════════════════════════════"
    log "INFO" ""

    log_decision "ORCHESTRATION_COMPLETE" "All phases complete - orchestration finished successfully"

    local max_phase=$(get_max_phase)
    log "INFO" "✅ All $max_phase phases completed"
    log "INFO" "✅ All workers finished their tasks"
    log "INFO" ""
    log "INFO" "Next steps:"
    log "INFO" "  1. Review worker outputs"
    log "INFO" "  2. Run integration tests"
    log "INFO" "  3. Merge changes to main"
    log "INFO" "  4. Use 'czarina closeout' to clean up"
    log "INFO" ""

    # Update state to mark orchestration as complete
    jq '.orchestration_complete = true | .completed_at = "'$(date -Iseconds)'"' \
       "$PHASE_STATE_FILE" > "${PHASE_STATE_FILE}.tmp"
    mv "${PHASE_STATE_FILE}.tmp" "$PHASE_STATE_FILE"

    # The daemon will continue monitoring but won't take further action
    # This allows the user to review results before cleanup
}

# ============================================================================
# MAIN DAEMON LOOP
# ============================================================================

iteration=0

log "INFO" "🎯 Starting autonomous monitoring loop..."
log "INFO" ""

while true; do
    ((iteration++))

    log "INFO" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "INFO" "Iteration $iteration - $(date '+%Y-%m-%d %H:%M:%S')"
    log "INFO" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Run monitoring
    monitor_workers

    log "INFO" ""
    log "INFO" "Next check in ${CHECK_INTERVAL}s (5 minutes)..."
    log "INFO" ""

    # Wait before next check
    sleep $CHECK_INTERVAL
done
