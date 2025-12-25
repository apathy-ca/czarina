#!/bin/bash
# Czarina Autonomous Daemon - Handles all worker approvals and monitoring
# The human should NEVER need to approve - Czar makes all decisions
#
# This is the generalized version that works with any Czarina project

set -uo pipefail  # Don't use -e in daemon - we want it to continue on errors

# Configuration (can be overridden by config file)
PROJECT_DIR="${1:-.}"
CONFIG_FILE="${PROJECT_DIR}/config.json"

# Validate config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    echo "Usage: $0 <project-orchestration-dir>"
    echo "Example: $0 /path/to/project/czarina-myproject"
    exit 1
fi

# Load configuration from JSON
if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed"
    exit 1
fi

PROJECT_SLUG=$(jq -r '.project.slug' "$CONFIG_FILE")
PROJECT_ROOT=$(jq -r '.project.repository' "$CONFIG_FILE")
WORKER_COUNT=$(jq '.workers | length' "$CONFIG_FILE")

# Session and logging
# Try to find actual session name - check multiple naming patterns
POSSIBLE_SESSIONS=(
    "czarina-${PROJECT_SLUG}"
    "${PROJECT_SLUG}-session"
    # Also try without dashes (multi-agent-support -> multiagent or multi-agent)
    "czarina-$(echo $PROJECT_SLUG | sed 's/-//')"
)

SESSION=""
for sess in "${POSSIBLE_SESSIONS[@]}"; do
    if tmux has-session -t "$sess" 2>/dev/null; then
        SESSION="$sess"
        break
    fi
done

if [ -z "$SESSION" ]; then
    echo "⚠️  Warning: No worker session found"
    echo "   Tried: ${POSSIBLE_SESSIONS[*]}"
    echo "   Daemon will start but may not find workers until session is created"
    SESSION="czarina-${PROJECT_SLUG}"  # Default guess
fi
LOG_FILE="${PROJECT_DIR}/status/daemon.log"
SLEEP_INTERVAL=120  # Check every 2 minutes

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

echo "🎭 CZAR DAEMON STARTING" | tee -a "$LOG_FILE"
echo "Time: $(date)" | tee -a "$LOG_FILE"
echo "Project: $PROJECT_SLUG" | tee -a "$LOG_FILE"
echo "Session: $SESSION" | tee -a "$LOG_FILE"
echo "Workers: $WORKER_COUNT" | tee -a "$LOG_FILE"
echo "Check interval: ${SLEEP_INTERVAL}s" | tee -a "$LOG_FILE"
echo "======================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Function to auto-approve all pending requests
auto_approve_all() {
    local approved_count=0

    for ((window=0; window<WORKER_COUNT; window++)); do
        output=$(tmux capture-pane -t $SESSION:$window -p 2>/dev/null || echo "")

        # Check for "Do you want to proceed?" prompts
        if echo "$output" | grep -q "Do you want to proceed?"; then
            # CZAR DECISION: Always approve option 2 (allow reading from directories)
            echo "[$(date '+%H:%M:%S')] Auto-approving window $window" | tee -a "$LOG_FILE"
            tmux send-keys -t $SESSION:$window "2" C-m 2>/dev/null
            ((approved_count++))
            sleep 0.5
        fi

        # Check for edit acceptance prompts "accept edits" - try multiple methods
        if echo "$output" | grep -q "accept edits"; then
            # CZAR DECISION: Always accept edits workers propose
            echo "[$(date '+%H:%M:%S')] Auto-accepting edits in window $window" | tee -a "$LOG_FILE"
            # Try just Enter
            tmux send-keys -t $SESSION:$window C-m 2>/dev/null
            sleep 0.3
            # If still there, try Tab then Enter (to select default)
            tmux send-keys -t $SESSION:$window Tab C-m 2>/dev/null
            ((approved_count++))
            sleep 0.5
        fi

        # Check for Y/N prompts
        if echo "$output" | tail -5 | grep -qiE "\[Y/n\]|\(y/N\)"; then
            # CZAR DECISION: Default to yes for most prompts
            echo "[$(date '+%H:%M:%S')] Auto-confirming Y/N in window $window" | tee -a "$LOG_FILE"
            tmux send-keys -t $SESSION:$window "y" C-m 2>/dev/null
            ((approved_count++))
            sleep 0.5
        fi

        # Check if just waiting at prompt (might need a nudge)
        if echo "$output" | tail -2 | grep -qE "^> $"; then
            last_line=$(echo "$output" | grep -E "complete|finished|done|ready" | tail -1)
            if [ -n "$last_line" ]; then
                # Worker reports done but might be waiting - send enter to confirm
                echo "[$(date '+%H:%M:%S')] Nudging idle worker in window $window" | tee -a "$LOG_FILE"
                tmux send-keys -t $SESSION:$window C-m 2>/dev/null
                ((approved_count++))
                sleep 0.5
            fi
        fi
    done

    if [ $approved_count -gt 0 ]; then
        echo "[$(date '+%H:%M:%S')] ✅ Auto-approved $approved_count items" | tee -a "$LOG_FILE"
    fi

    return $approved_count
}

# Track last activity time for each worker
declare -A LAST_ACTIVITY
declare -A STUCK_COUNT

# Function to check for workers needing guidance
check_for_issues() {
    local issues_found=0

    for ((window=0; window<WORKER_COUNT; window++)); do
        output=$(tmux capture-pane -t $SESSION:$window -p 2>/dev/null || echo "")

        # Get current pane content hash to detect changes
        current_hash=$(echo "$output" | md5sum | cut -d' ' -f1)
        last_hash="${LAST_ACTIVITY[$window]:-}"

        # Check for explicit questions to Czar
        if echo "$output" | tail -20 | grep -qiE "czar.*\?|question for czar|@czar"; then
            echo "[$(date '+%H:%M:%S')] ⚠️  Window $window has question for Czar" | tee -a "$LOG_FILE"
            echo "   Context: $(echo "$output" | grep -iE "czar.*\?|question|@czar" | tail -1)" | tee -a "$LOG_FILE"
            notify_czar "$window" "Question" "$(echo "$output" | grep -iE "czar.*\?|question|@czar" | tail -1)"
            ((issues_found++))
        fi

        # Check for errors that look serious
        if echo "$output" | tail -10 | grep -qiE "fatal|critical|cannot proceed|blocked|error:"; then
            echo "[$(date '+%H:%M:%S')] ❌ Window $window has blocking error" | tee -a "$LOG_FILE"
            error_line=$(echo "$output" | grep -iE "fatal|critical|cannot|blocked|error:" | tail -1)
            echo "   Error: $error_line" | tee -a "$LOG_FILE"
            notify_czar "$window" "Error" "$error_line"
            ((issues_found++))
        fi

        # Check if worker is stuck (no activity for multiple iterations)
        if [ "$current_hash" = "$last_hash" ]; then
            stuck_count=$((${STUCK_COUNT[$window]:-0} + 1))
            STUCK_COUNT[$window]=$stuck_count

            # If stuck for 3+ iterations (6+ minutes), investigate
            if [ $stuck_count -ge 3 ]; then
                # Check if there's a choice/question being asked
                last_10_lines=$(echo "$output" | tail -10)

                # Detect choice patterns (multiple options, numbered lists, Y/N, etc)
                has_choice=false
                if echo "$last_10_lines" | grep -qE "\[1\]|\[2\]|option 1|option 2"; then
                    has_choice=true
                elif echo "$last_10_lines" | grep -qE "\(y/n\)|\[Y/n\]|\(Y/N\)"; then
                    has_choice=true
                elif echo "$last_10_lines" | grep -qE "select|choose|which|would you like"; then
                    has_choice=true
                fi

                if [ "$has_choice" = true ]; then
                    # There's a choice - DON'T auto-answer, escalate to Czar
                    echo "[$(date '+%H:%M:%S')] 🔔 Window $window has CHOICE waiting" | tee -a "$LOG_FILE"
                    choice_context=$(echo "$last_10_lines" | grep -E "\[1\]|\[2\]|option|select|choose|y/n" | head -3)
                    echo "   Choices: $choice_context" | tee -a "$LOG_FILE"
                    notify_czar "$window" "Choice Required" "$choice_context"
                    ((issues_found++))
                    STUCK_COUNT[$window]=0  # Reset after notification
                elif echo "$output" | tail -3 | grep -qE "Ready to begin|✅ Ready|instructions above"; then
                    # Still on initial "Ready to begin" screen - hasn't started yet
                    # Don't nudge, just log
                    if [ $stuck_count -ge 5 ]; then
                        echo "[$(date '+%H:%M:%S')] 💤 Window $window idle on start screen for ${stuck_count} iterations" | tee -a "$LOG_FILE"
                        notify_czar "$window" "Not Started" "Worker hasn't begun (idle 10+ min)"
                        ((issues_found++))
                        STUCK_COUNT[$window]=0
                    fi
                elif [ $stuck_count -ge 5 ]; then
                    # Stuck for 10+ minutes, no choice detected, not on start screen
                    # Could be genuinely stuck - escalate to Czar, don't auto-nudge
                    echo "[$(date '+%H:%M:%S')] ⚠️  Window $window STUCK for ${stuck_count} iterations (10+ min)" | tee -a "$LOG_FILE"
                    stuck_context=$(echo "$output" | tail -3)
                    echo "   Context: $stuck_context" | tee -a "$LOG_FILE"
                    notify_czar "$window" "Stuck" "No activity for $((stuck_count * 2)) minutes - Check window $window"
                    ((issues_found++))
                    STUCK_COUNT[$window]=0  # Reset to avoid spam
                fi
            fi
        else
            # Activity detected, reset counter
            LAST_ACTIVITY[$window]=$current_hash
            STUCK_COUNT[$window]=0
        fi
    done

    return $issues_found
}

# Track notifications to avoid spam
declare -A LAST_NOTIFICATION
NOTIFICATION_COOLDOWN=300  # 5 minutes between same notifications

# Function to notify Czar window (window 0)
notify_czar() {
    local worker_window=$1
    local issue_type=$2
    local message=$3

    # Create notification key
    local notif_key="${worker_window}_${issue_type}"
    local now=$(date +%s)
    local last_notif=${LAST_NOTIFICATION[$notif_key]:-0}

    # Check cooldown - don't spam same notification
    if [ $((now - last_notif)) -lt $NOTIFICATION_COOLDOWN ]; then
        return 0
    fi

    LAST_NOTIFICATION[$notif_key]=$now

    # Write to Czar log file instead of sending tmux commands
    # This prevents tmux lockup from too many send-keys
    CZAR_LOG="${PROJECT_DIR}/status/czar-notifications.log"
    echo "[$(date '+%H:%M:%S')] 🔔 Worker $worker_window - $issue_type: $message" | tee -a "$CZAR_LOG"

    # Also log to daemon log
    echo "[$(date '+%H:%M:%S')] → Notified Czar: Worker $worker_window - $issue_type" | tee -a "$LOG_FILE"
}

# Main daemon loop
iteration=0
while true; do
    ((iteration++))
    echo "" | tee -a "$LOG_FILE"
    echo "=== Iteration $iteration - $(date '+%Y-%m-%d %H:%M:%S') ===" | tee -a "$LOG_FILE"

    # 1. Auto-approve everything that needs approval
    auto_approve_all
    approved=$?

    # 2. Check for issues that need Czar intelligence
    check_for_issues
    issues=$?

    # 3. If there were approvals or issues, give workers a moment then check again
    if [ $approved -gt 0 ] || [ $issues -gt 0 ]; then
        sleep 3
        auto_approve_all  # Second pass to catch cascading prompts
    fi

    # 4. Enhanced worker status display every 5 iterations (~10 min)
    if [ $((iteration % 5)) -eq 0 ]; then
        echo "[$(date '+%H:%M:%S')] 📊 Generating enhanced status report for Czar..." | tee -a "$LOG_FILE"

        # Get orchestrator directory
        ORCHESTRATOR_DIR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
        METRICS_SCRIPT="${ORCHESTRATOR_DIR}/metrics.sh"
        CZAR_SCRIPT="${ORCHESTRATOR_DIR}/czar.sh"

        # Build detailed worker status report
        CZAR_LOG="${PROJECT_DIR}/status/czar-notifications.log"
        {
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "[$(date '+%H:%M:%S')] 📊 WORKER STATUS REPORT"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""

            for ((w=0; w<WORKER_COUNT; w++)); do
                worker_id=$(jq -r ".workers[$w].id" "$CONFIG_FILE")
                worker_desc=$(jq -r ".workers[$w].description" "$CONFIG_FILE")

                # Get worker status from czar script
                if [ -f "$CZAR_SCRIPT" ]; then
                    worker_status=$(bash "$CZAR_SCRIPT" "$PROJECT_DIR" check 2>/dev/null | jq -r ".${worker_id}.status" 2>/dev/null || echo "unknown")
                    last_event=$(bash "$CZAR_SCRIPT" "$PROJECT_DIR" check 2>/dev/null | jq -r ".${worker_id}.last_event" 2>/dev/null || echo "")
                    idle_sec=$(bash "$CZAR_SCRIPT" "$PROJECT_DIR" check 2>/dev/null | jq -r ".${worker_id}.idle_seconds" 2>/dev/null || echo "0")
                else
                    worker_status="unknown"
                    last_event=""
                    idle_sec=0
                fi

                # Get metrics
                if [ -f "$METRICS_SCRIPT" ]; then
                    commits=$(bash "$METRICS_SCRIPT" "$PROJECT_DIR" "$worker_id" commits 2>/dev/null || echo "0")
                    files=$(bash "$METRICS_SCRIPT" "$PROJECT_DIR" "$worker_id" files 2>/dev/null || echo "0")
                    idle_time=$(bash "$METRICS_SCRIPT" "$PROJECT_DIR" "$worker_id" all 2>/dev/null | jq -r '.idle_time' 2>/dev/null || echo "unknown")
                else
                    commits=0
                    files=0
                    idle_time="unknown"
                fi

                # Status emoji
                case "$worker_status" in
                    active) status_emoji="🔄 ACTIVE";;
                    idle) status_emoji="💤 IDLE";;
                    stuck) status_emoji="⚠️ STUCK";;
                    complete) status_emoji="✅ COMPLETE";;
                    not_started) status_emoji="🆕 NOT STARTED";;
                    *) status_emoji="❓ UNKNOWN";;
                esac

                # Worker summary line
                printf "Worker %d (%s): %s\n" $((w+1)) "$worker_id" "$status_emoji"
                printf "  Description: %s\n" "$worker_desc"
                printf "  Activity: %s (last: %s ago)\n" "$last_event" "$idle_time"
                printf "  Progress: %d commits, %d files changed\n" "$commits" "$files"
                echo ""
            done

            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
        } | tee -a "$CZAR_LOG"

        echo "[$(date '+%H:%M:%S')] ✅ Enhanced status report written to czar-notifications.log" | tee -a "$LOG_FILE"

        # Also run czar coordination if czar script exists
        if [ -f "$CZAR_SCRIPT" ]; then
            echo "[$(date '+%H:%M:%S')] 🎭 Running Czar coordination cycle..." | tee -a "$LOG_FILE"
            bash "$CZAR_SCRIPT" "$PROJECT_DIR" coordinate >> "$LOG_FILE" 2>&1 || true
        fi
    fi

    # Wait before next check
    sleep $SLEEP_INTERVAL
done
