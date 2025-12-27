#!/usr/bin/env bash
# czarina-core/czar-autonomous-v2.sh
# Autonomous Czar Loop - Modern implementation with structured logging
# Implements A3 (Autonomous Loop) + A4 (Health Monitoring)
#
# Runs continuously (every 30s) to:
# - Monitor worker health (detect stuck/idle/crashed workers)
# - Make autonomous decisions (assign tasks, prompt workers, alert czar)
# - Log all decisions with structured logging
# - Track dependencies and blocked workers

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source logging system
source "${SCRIPT_DIR}/logging.sh"

# Source hopper integration (Task 2)
source "${SCRIPT_DIR}/czar-hopper-integration.sh"

# Source dependency tracking (Task 3)
source "${SCRIPT_DIR}/czar-dependency-tracking.sh"

# Get czarina directory (either from parent dir or environment)
CZARINA_DIR="${CZARINA_DIR:-$(dirname "$SCRIPT_DIR")}"

# Configuration files
CONFIG_FILE="${CZARINA_DIR}/config.json"
STATUS_DIR="${CZARINA_DIR}/status"
WORKER_STATUS_FILE="${STATUS_DIR}/worker-status.json"
DECISIONS_LOG="${STATUS_DIR}/autonomous-decisions.log"

# Monitoring configuration
CHECK_INTERVAL=30  # seconds between checks
STUCK_PROMPT_COOLDOWN=3600  # seconds before re-prompting stuck worker (1 hour)
STATUS_SUMMARY_INTERVAL=10  # iterations between status summaries (5 minutes at 30s interval)

# ============================================================================
# INITIALIZATION
# ============================================================================

# Initialize logging system
czarina_log_init

# Ensure status directory exists
mkdir -p "$STATUS_DIR"

# Initialize decisions log
if [[ ! -f "$DECISIONS_LOG" ]]; then
    touch "$DECISIONS_LOG"
fi

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

# log_decision()
# Log an autonomous decision to both structured log and decisions file
# Usage: log_decision <level> <event-type> <description> [key=value ...]
log_decision() {
    local level="${1:?Level required}"
    local event_type="${2:?Event type required}"
    local description="${3:?Description required}"
    shift 3
    local metadata="$*"

    # Log to structured event stream
    czarina_log_event "czar" "$event_type" $metadata

    # Log to daemon/orchestration log
    local emoji="🤖"
    case "$level" in
        INFO) emoji="ℹ️" ;;
        DETECT) emoji="👀" ;;
        ACTION) emoji="⚡" ;;
        ALERT) emoji="⚠️" ;;
        ERROR) emoji="❌" ;;
        SUCCESS) emoji="✅" ;;
    esac

    czarina_log_daemon "$emoji" "$event_type" "$description" $metadata

    # Also log to decisions file for easy review
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [[ -n "$metadata" ]]; then
        echo "[${timestamp}] [$level] $event_type: $description ($metadata)" >> "$DECISIONS_LOG"
    else
        echo "[${timestamp}] [$level] $event_type: $description" >> "$DECISIONS_LOG"
    fi
}

# ============================================================================
# CONFIGURATION PARSING
# ============================================================================

# get_worker_ids()
# Get list of all worker IDs from config.json
get_worker_ids() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "ERROR: Config file not found: $CONFIG_FILE" >&2
        return 1
    fi

    jq -r '.workers[].id' "$CONFIG_FILE"
}

# get_worker_dependencies()
# Get dependencies for a specific worker
# Usage: get_worker_dependencies <worker-id>
get_worker_dependencies() {
    local worker_id="${1:?Worker ID required}"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        return 0
    fi

    jq -r ".workers[] | select(.id == \"$worker_id\") | .dependencies[]?" "$CONFIG_FILE" || true
}

# ============================================================================
# WORKER STATUS FUNCTIONS
# ============================================================================

# update_worker_status()
# Update worker-status.json using existing script
update_worker_status() {
    if [[ -f "${SCRIPT_DIR}/update-worker-status.sh" ]]; then
        "${SCRIPT_DIR}/update-worker-status.sh" > /dev/null 2>&1 || true
    fi
}

# get_worker_status()
# Get status of a worker from worker-status.json
# Usage: get_worker_status <worker-id>
# Returns: pending|working|idle|unknown
get_worker_status() {
    local worker_id="${1:?Worker ID required}"

    if [[ ! -f "$WORKER_STATUS_FILE" ]]; then
        echo "unknown"
        return 0
    fi

    jq -r ".workers[\"$worker_id\"].status // \"unknown\"" "$WORKER_STATUS_FILE"
}

# get_worker_health()
# Get health status of a worker
# Usage: get_worker_health <worker-id>
# Returns: unknown|healthy|slow|stuck|crashed
get_worker_health() {
    local worker_id="${1:?Worker ID required}"

    if [[ ! -f "$WORKER_STATUS_FILE" ]]; then
        echo "unknown"
        return 0
    fi

    jq -r ".workers[\"$worker_id\"].health // \"unknown\"" "$WORKER_STATUS_FILE"
}

# is_worker_session_active()
# Check if worker's tmux session is active
# Usage: is_worker_session_active <worker-id>
# Returns: 0 if active, 1 if not
is_worker_session_active() {
    local worker_id="${1:?Worker ID required}"

    if [[ ! -f "$WORKER_STATUS_FILE" ]]; then
        return 1
    fi

    local active=$(jq -r ".workers[\"$worker_id\"].session_active // false" "$WORKER_STATUS_FILE")
    [[ "$active" == "true" ]]
}

# ============================================================================
# WORKER DETECTION
# ============================================================================

# detect_idle_workers()
# Get list of idle workers
# Returns: Worker IDs, one per line
detect_idle_workers() {
    if [[ ! -f "$WORKER_STATUS_FILE" ]]; then
        return 0
    fi

    jq -r '.workers | to_entries[] | select(.value.status == "idle") | .key' "$WORKER_STATUS_FILE" || true
}

# detect_stuck_workers()
# Get list of stuck workers
# Returns: Worker IDs, one per line
detect_stuck_workers() {
    if [[ ! -f "$WORKER_STATUS_FILE" ]]; then
        return 0
    fi

    jq -r '.workers | to_entries[] | select(.value.health == "stuck" and .value.session_active == true) | .key' "$WORKER_STATUS_FILE" || true
}

# detect_crashed_workers()
# Get list of crashed workers (session not active)
# Returns: Worker IDs, one per line
detect_crashed_workers() {
    if [[ ! -f "$WORKER_STATUS_FILE" ]]; then
        return 0
    fi

    jq -r '.workers | to_entries[] | select(.value.session_active == false and .value.status != "pending") | .key' "$WORKER_STATUS_FILE" || true
}

# ============================================================================
# WORKER ACTIONS
# ============================================================================

# prompt_stuck_worker()
# Send a prompt to a stuck worker via tmux
# Usage: prompt_stuck_worker <worker-id>
prompt_stuck_worker() {
    local worker_id="${1:?Worker ID required}"

    # Get project slug from config
    local project_slug=$(jq -r '.project.slug' "$CONFIG_FILE")
    local session="czarina-${project_slug}:${worker_id}"

    log_decision "ACTION" "PROMPT_STUCK_WORKER" "Prompting stuck worker: $worker_id" worker=$worker_id

    # Check if session exists
    if ! tmux has-session -t "$session" 2>/dev/null; then
        log_decision "ERROR" "SESSION_NOT_FOUND" "Cannot prompt worker, session not found: $session" worker=$worker_id session=$session
        return 1
    fi

    # Send prompt via tmux
    tmux send-keys -t "$session" "" C-m
    tmux send-keys -t "$session" "# ⚠️  AUTONOMOUS CZAR: You appear to be stuck (no activity detected)" C-m
    tmux send-keys -t "$session" "# Please report your status:" C-m
    tmux send-keys -t "$session" "#   - Are you blocked by dependencies?" C-m
    tmux send-keys -t "$session" "#   - Do you need clarification on requirements?" C-m
    tmux send-keys -t "$session" "#   - Are you waiting for external resources?" C-m
    tmux send-keys -t "$session" "#   - Tag @czar if you need human intervention" C-m
    tmux send-keys -t "$session" "" C-m
}

# should_prompt_stuck_worker()
# Check if we should prompt a stuck worker (cooldown check)
# Usage: should_prompt_stuck_worker <worker-id>
# Returns: 0 if should prompt, 1 if cooldown active
should_prompt_stuck_worker() {
    local worker_id="${1:?Worker ID required}"

    # Check when we last prompted this worker
    local last_prompt=$(grep "PROMPT_STUCK_WORKER.*worker=$worker_id" "$DECISIONS_LOG" 2>/dev/null | tail -1 | cut -d']' -f1 | tr -d '[' || echo "")

    if [[ -z "$last_prompt" ]]; then
        # Never prompted before
        return 0
    fi

    # Calculate time since last prompt
    local last_prompt_epoch=$(date -d "$last_prompt" +%s 2>/dev/null || echo "0")
    local current_epoch=$(date +%s)
    local time_since=$((current_epoch - last_prompt_epoch))

    # Check cooldown
    if [[ $time_since -lt $STUCK_PROMPT_COOLDOWN ]]; then
        # Still in cooldown period
        return 1
    fi

    return 0
}

# alert_crashed_worker()
# Alert about a crashed worker (session not active)
# Usage: alert_crashed_worker <worker-id>
alert_crashed_worker() {
    local worker_id="${1:?Worker ID required}"

    log_decision "ALERT" "WORKER_CRASHED" "Worker session crashed or terminated: $worker_id" worker=$worker_id severity=high
}

# check_dependencies_blocked()
# Check if a worker is blocked by dependencies
# Usage: check_dependencies_blocked <worker-id>
# Returns: 0 if blocked, 1 if not blocked
check_dependencies_blocked() {
    local worker_id="${1:?Worker ID required}"

    # Get worker dependencies
    local dependencies=$(get_worker_dependencies "$worker_id")

    if [[ -z "$dependencies" ]]; then
        # No dependencies, not blocked
        return 1
    fi

    # Check if any dependency is not yet completed
    local blocked=false
    for dep in $dependencies; do
        local dep_status=$(get_worker_status "$dep")

        # If dependency is not in "working" or completed state, worker might be blocked
        if [[ "$dep_status" == "pending" || "$dep_status" == "unknown" ]]; then
            log_decision "DETECT" "DEPENDENCY_NOT_READY" "Worker $worker_id depends on $dep which is $dep_status" worker=$worker_id dependency=$dep dep_status=$dep_status
            blocked=true
        fi
    done

    [[ "$blocked" == true ]]
}

# ============================================================================
# MONITORING LOOP
# ============================================================================

# check_worker_health()
# Check health of all workers and take actions
check_worker_health() {
    local iteration="${1:-0}"

    # Update worker status first
    update_worker_status

    # Get list of all workers
    local workers=$(get_worker_ids)

    if [[ -z "$workers" ]]; then
        log_decision "ERROR" "NO_WORKERS" "No workers found in configuration" config=$CONFIG_FILE
        return 1
    fi

    # Check for crashed workers (highest priority)
    local crashed_workers=$(detect_crashed_workers)
    if [[ -n "$crashed_workers" ]]; then
        while IFS= read -r worker; do
            [[ -z "$worker" ]] && continue
            alert_crashed_worker "$worker"
        done <<< "$crashed_workers"
    fi

    # Check for stuck workers
    local stuck_workers=$(detect_stuck_workers)
    if [[ -n "$stuck_workers" ]]; then
        while IFS= read -r worker; do
            [[ -z "$worker" ]] && continue

            log_decision "DETECT" "STUCK_WORKER" "Detected stuck worker: $worker" worker=$worker

            # Check if worker is blocked by dependencies
            if check_dependencies_blocked "$worker"; then
                log_decision "INFO" "WORKER_BLOCKED" "Worker $worker appears blocked by dependencies" worker=$worker
            elif should_prompt_stuck_worker "$worker"; then
                prompt_stuck_worker "$worker"
            else
                log_decision "INFO" "COOLDOWN_ACTIVE" "Stuck worker $worker in prompt cooldown" worker=$worker
            fi
        done <<< "$stuck_workers"
    fi

    # Check for idle workers
    local idle_workers=$(detect_idle_workers)
    local idle_count=0
    local idle_worker_array=()

    if [[ -n "$idle_workers" ]]; then
        while IFS= read -r worker; do
            [[ -z "$worker" ]] && continue

            log_decision "DETECT" "IDLE_WORKER" "Detected idle worker: $worker" worker=$worker
            idle_worker_array+=("$worker")
            idle_count=$((idle_count + 1))
        done <<< "$idle_workers"
    fi

    # Monitor hoppers and assign work to idle workers (Task 2)
    monitor_hoppers "$idle_count" "${idle_worker_array[@]}"

    # Monitor dependencies and suggest integration strategies (Task 3)
    monitor_dependencies "$iteration"

    # Every N iterations, log a status summary
    if [[ $((iteration % STATUS_SUMMARY_INTERVAL)) -eq 0 ]]; then
        log_status_summary
    fi
}

# log_status_summary()
# Log a summary of worker status
log_status_summary() {
    if [[ ! -f "$WORKER_STATUS_FILE" ]]; then
        return 0
    fi

    local working=$(jq -r '[.workers[] | select(.status == "working")] | length' "$WORKER_STATUS_FILE" 2>/dev/null || echo "0")
    local idle=$(jq -r '[.workers[] | select(.status == "idle")] | length' "$WORKER_STATUS_FILE" 2>/dev/null || echo "0")
    local pending=$(jq -r '[.workers[] | select(.status == "pending")] | length' "$WORKER_STATUS_FILE" 2>/dev/null || echo "0")

    local healthy=$(jq -r '[.workers[] | select(.health == "healthy")] | length' "$WORKER_STATUS_FILE" 2>/dev/null || echo "0")
    local stuck=$(jq -r '[.workers[] | select(.health == "stuck")] | length' "$WORKER_STATUS_FILE" 2>/dev/null || echo "0")
    local crashed=$(jq -r '[.workers[] | select(.session_active == false and .status != "pending")] | length' "$WORKER_STATUS_FILE" 2>/dev/null || echo "0")

    # Get hopper statistics
    local hopper_stats=$(count_phase_hopper_items 2>/dev/null || echo "todo:0 in_progress:0 done:0")
    local hopper_todo=$(echo "$hopper_stats" | grep -oP 'todo:\K\d+' || echo "0")
    local hopper_progress=$(echo "$hopper_stats" | grep -oP 'in_progress:\K\d+' || echo "0")
    local hopper_done=$(echo "$hopper_stats" | grep -oP 'done:\K\d+' || echo "0")

    log_decision "INFO" "STATUS_SUMMARY" "Workers: $working working, $idle idle, $pending pending | Health: $healthy healthy, $stuck stuck, $crashed crashed | Hopper: $hopper_todo todo, $hopper_progress in-progress, $hopper_done done" \
        working=$working idle=$idle pending=$pending healthy=$healthy stuck=$stuck crashed=$crashed hopper_todo=$hopper_todo hopper_progress=$hopper_progress hopper_done=$hopper_done
}

# main_loop()
# Main autonomous monitoring loop
main_loop() {
    local iteration=0

    log_decision "INFO" "CZAR_START" "Autonomous Czar started" interval=${CHECK_INTERVAL}s

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🤖 AUTONOMOUS CZAR - ACTIVE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Monitoring worker health and making autonomous decisions..."
    echo ""
    echo "Configuration:"
    echo "  • Config: $CONFIG_FILE"
    echo "  • Check interval: ${CHECK_INTERVAL}s"
    echo "  • Decision log: $DECISIONS_LOG"
    echo "  • Event stream: ${CZARINA_DIR}/logs/events.jsonl"
    echo ""
    echo "Logs:"
    echo "  • Orchestration: tail -f ${CZARINA_DIR}/logs/orchestration.log"
    echo "  • Decisions: tail -f $DECISIONS_LOG"
    echo ""
    echo "Press Ctrl+C to stop"
    echo ""

    while true; do
        iteration=$((iteration + 1))

        # Check worker health and take actions
        check_worker_health "$iteration"

        # Sleep until next check
        sleep "$CHECK_INTERVAL"
    done
}

# ============================================================================
# SIGNAL HANDLING
# ============================================================================

# Handle graceful shutdown
shutdown() {
    echo ""
    log_decision "INFO" "CZAR_STOP" "Autonomous Czar stopped by user"
    exit 0
}

trap shutdown SIGINT SIGTERM

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

# Validate configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE" >&2
    echo "Please run from czarina project directory or set CZARINA_DIR" >&2
    exit 1
fi

# Validate logging system is available
if ! command -v czarina_log_event >/dev/null 2>&1; then
    echo "ERROR: Logging system not initialized" >&2
    echo "Make sure logging.sh is sourced correctly" >&2
    exit 1
fi

# Run main loop
main_loop
