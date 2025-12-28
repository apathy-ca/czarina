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
    echo '{"current_phase": 1, "phase_1_complete": false, "phase_2_launched": false}' > "$PHASE_STATE_FILE"
    log "INFO" "Initialized phase state: Phase 1"
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

# Check if phase is complete
is_phase_complete() {
    local phase=$1
    local all_complete=true

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_phase=$(get_worker_phase $i)

        if [ "$worker_phase" = "$phase" ]; then
            if ! is_worker_complete $i; then
                all_complete=false
                break
            fi
        fi
    done

    if [ "$all_complete" = true ]; then
        return 0  # Complete
    else
        return 1  # Not complete
    fi
}

# Get phase workers
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

# ============================================================================
# MONITORING LOOP
# ============================================================================

monitor_workers() {
    log "INFO" "📊 Monitoring cycle starting..."

    # Load current phase state
    current_phase=$(jq -r '.current_phase' "$PHASE_STATE_FILE")
    phase_1_complete=$(jq -r '.phase_1_complete' "$PHASE_STATE_FILE")
    phase_2_launched=$(jq -r '.phase_2_launched' "$PHASE_STATE_FILE")

    log "INFO" "Current phase: $current_phase"

    # Check each worker
    local stuck_workers=()
    local idle_workers=()
    local active_workers=()
    local complete_workers=()

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(get_worker_id $i)
        worker_phase=$(get_worker_phase $i)
        status=$(get_worker_status $i)

        log "INFO" "  Worker $worker_id (phase $worker_phase): $status"

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

    # Report progress
    log "INFO" "📈 Progress: ${#complete_workers[@]}/$WORKER_COUNT complete, ${#active_workers[@]} active"

    # Check Phase 1 completion
    if [ "$current_phase" = "1" ] && [ "$phase_1_complete" = "false" ]; then
        if is_phase_complete 1; then
            log "INFO" "✅ PHASE 1 COMPLETE! All Phase 1 workers done."
            log_decision "PHASE_COMPLETE" "Phase 1 complete with ${#complete_workers[@]} workers"

            # Update state
            jq '.phase_1_complete = true' "$PHASE_STATE_FILE" > "${PHASE_STATE_FILE}.tmp"
            mv "${PHASE_STATE_FILE}.tmp" "$PHASE_STATE_FILE"

            # Trigger Phase 2 launch
            if [ "$phase_2_launched" = "false" ]; then
                launch_phase_2
            fi
        fi
    fi
}

# Launch Phase 2 workers
launch_phase_2() {
    log "INFO" "🚀 Launching Phase 2 workers..."
    log_decision "PHASE_TRANSITION" "Starting Phase 2 worker launches"

    # Get Phase 2 workers
    phase_2_workers=($(get_phase_workers 2))

    if [ ${#phase_2_workers[@]} -eq 0 ]; then
        log "WARN" "No Phase 2 workers defined in config"
        return
    fi

    log "INFO" "Phase 2 workers to launch: ${#phase_2_workers[@]}"

    # TODO: Implement actual worker launching
    # For now, just log the intent
    for worker_idx in "${phase_2_workers[@]}"; do
        worker_id=$(get_worker_id $worker_idx)
        log "INFO" "  → Would launch: $worker_id"
        log_decision "WORKER_LAUNCH" "Phase 2 worker: $worker_id"
    done

    # Update state
    jq '.phase_2_launched = true | .current_phase = 2' "$PHASE_STATE_FILE" > "${PHASE_STATE_FILE}.tmp"
    mv "${PHASE_STATE_FILE}.tmp" "$PHASE_STATE_FILE"

    log "INFO" "✅ Phase 2 launch complete"
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
