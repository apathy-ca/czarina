#!/bin/bash
# Autonomous Czar - Continuous Monitoring and Decision Loop
# Runs in background, makes decisions automatically
# Goal: "In an ideal world I'm not here at all"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

CZAR_LOG="${ORCHESTRATOR_DIR}/status/czar-decisions.log"
BONUS_TASK_DIR="${ORCHESTRATOR_DIR}/prompts"

# Logging function
log_decision() {
    local level=$1
    shift
    local message="$@"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$CZAR_LOG"
}

# Check if bonus task exists for worker
has_bonus_task() {
    local worker=$1
    local bonus_file="${BONUS_TASK_DIR}/${worker}_BONUS_TASKS.txt"
    [ -f "$bonus_file" ]
}

# Assign bonus task to worker
assign_bonus_task() {
    local worker=$1
    local bonus_file="${BONUS_TASK_DIR}/${worker}_BONUS_TASKS.txt"

    if [ -f "$bonus_file" ]; then
        log_decision "ACTION" "Assigning bonus tasks to $worker"
        "${SCRIPT_DIR}/inject-task.sh" "$worker" "$bonus_file" >> "$CZAR_LOG" 2>&1
        return 0
    else
        log_decision "INFO" "No bonus tasks available for $worker"
        return 1
    fi
}

# Prompt stuck worker
prompt_stuck_worker() {
    local worker=$1
    local session="sark-worker-${worker}"

    log_decision "ACTION" "Prompting stuck worker: $worker"

    tmux send-keys -t "$session" "" C-m
    tmux send-keys -t "$session" "# ⚠️  CZAR: You appear to be stuck (no activity for 2+ hours)" C-m
    tmux send-keys -t "$session" "# Please report your status:" C-m
    tmux send-keys -t "$session" "#   - Are you blocked by something?" C-m
    tmux send-keys -t "$session" "#   - Do you need clarification?" C-m
    tmux send-keys -t "$session" "#   - Are you waiting for dependencies?" C-m
    tmux send-keys -t "$session" "" C-m
}

# Main autonomous loop
main_loop() {
    local iteration=0

    log_decision "INFO" "Autonomous Czar started"
    log_decision "INFO" "Monitoring ${#WORKER_DEFINITIONS[@]} workers"
    log_decision "INFO" "Press Ctrl+C to stop"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🤖 AUTONOMOUS CZAR ACTIVE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Monitoring workers and making autonomous decisions..."
    echo "Log: $CZAR_LOG"
    echo ""
    echo "Decisions will be logged and executed automatically."
    echo "Dashboard: ./dashboard.py (in another terminal)"
    echo ""
    echo "Press Ctrl+C to stop autonomous mode"
    echo ""

    while true; do
        iteration=$((iteration + 1))

        # Update worker status
        "${SCRIPT_DIR}/update-worker-status.sh" > /dev/null 2>&1

        # Check for idle workers
        idle_workers=$("${SCRIPT_DIR}/detect-idle-workers.sh")

        if [ -n "$idle_workers" ]; then
            for worker in $idle_workers; do
                log_decision "DETECTED" "Idle worker: $worker"

                # Check if already assigned bonus tasks
                # (simple check: see if bonus task file was already injected)
                if ! grep -q "${worker}_BONUS_TASKS" "$CZAR_LOG" 2>/dev/null; then
                    if has_bonus_task "$worker"; then
                        assign_bonus_task "$worker"
                    else
                        log_decision "INFO" "Worker $worker idle but no bonus tasks available"
                    fi
                fi
            done
        fi

        # Check for stuck workers
        stuck_workers=$("${SCRIPT_DIR}/detect-stuck-workers.sh")

        if [ -n "$stuck_workers" ]; then
            for worker in $stuck_workers; do
                # Only prompt once per hour
                last_prompt=$(grep "Prompting stuck worker: $worker" "$CZAR_LOG" 2>/dev/null | tail -1 | cut -d']' -f1 | tr -d '[' || echo "")

                if [ -n "$last_prompt" ]; then
                    last_prompt_epoch=$(date -d "$last_prompt" +%s 2>/dev/null || echo "0")
                    current_epoch=$(date +%s)
                    time_since=$((current_epoch - last_prompt_epoch))

                    if [ $time_since -lt 3600 ]; then
                        # Already prompted within last hour, skip
                        continue
                    fi
                fi

                log_decision "DETECTED" "Stuck worker: $worker"
                prompt_stuck_worker "$worker"
            done
        fi

        # Every 10 iterations (5 minutes), log a status summary
        if [ $((iteration % 10)) -eq 0 ]; then
            log_decision "STATUS" "Iteration $iteration - System healthy"

            # Count worker states
            if [ -f "${ORCHESTRATOR_DIR}/status/worker-status.json" ]; then
                working=$(jq -r '[.workers[] | select(.status == "working")] | length' "${ORCHESTRATOR_DIR}/status/worker-status.json" 2>/dev/null || echo "0")
                idle=$(jq -r '[.workers[] | select(.status == "idle")] | length' "${ORCHESTRATOR_DIR}/status/worker-status.json" 2>/dev/null || echo "0")
                pending=$(jq -r '[.workers[] | select(.status == "pending")] | length' "${ORCHESTRATOR_DIR}/status/worker-status.json" 2>/dev/null || echo "0")

                log_decision "STATUS" "Workers: $working working, $idle idle, $pending pending"
            fi
        fi

        # Sleep 30 seconds between checks
        sleep 30
    done
}

# Handle graceful shutdown
trap 'echo ""; log_decision "INFO" "Autonomous Czar stopped by user"; exit 0' SIGINT SIGTERM

# Ensure log directory exists
mkdir -p "$(dirname "$CZAR_LOG")"

# Run main loop
main_loop
