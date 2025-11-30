#!/bin/bash
# Czar Autonomous Daemon - Handles all worker approvals and monitoring
# The human should NEVER need to approve - Czar makes all decisions

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SESSION="sark-v2-session"
LOG_FILE="$SCRIPT_DIR/czar-daemon.log"
SLEEP_INTERVAL=120  # Check every 2 minutes

echo "🎭 CZAR DAEMON STARTING" | tee -a "$LOG_FILE"
echo "Time: $(date)" | tee -a "$LOG_FILE"
echo "Session: $SESSION" | tee -a "$LOG_FILE"
echo "Check interval: ${SLEEP_INTERVAL}s" | tee -a "$LOG_FILE"
echo "======================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Function to auto-approve all pending requests
auto_approve_all() {
    local approved_count=0
    
    for window in {0..9}; do
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

# Function to check for workers needing guidance
check_for_issues() {
    local issues_found=0
    
    for window in {0..9}; do
        output=$(tmux capture-pane -t $SESSION:$window -p 2>/dev/null || echo "")
        
        # Check for explicit questions to Czar
        if echo "$output" | tail -20 | grep -qiE "czar.*\?|question for czar|@czar"; then
            echo "[$(date '+%H:%M:%S')] ⚠️  Window $window has question for Czar" | tee -a "$LOG_FILE"
            echo "   Context: $(echo "$output" | grep -iE "czar.*\?|question|@czar" | tail -1)" | tee -a "$LOG_FILE"
            ((issues_found++))
        fi
        
        # Check for errors that look serious
        if echo "$output" | tail -10 | grep -qiE "fatal|critical|cannot proceed|blocked"; then
            echo "[$(date '+%H:%M:%S')] ❌ Window $window has blocking error" | tee -a "$LOG_FILE"
            echo "   Error: $(echo "$output" | grep -iE "fatal|critical|cannot|blocked" | tail -1)" | tee -a "$LOG_FILE"
            ((issues_found++))
        fi
    done
    
    return $issues_found
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
    
    # 4. Log git activity every 10 iterations (~20 min)
    if [ $((iteration % 10)) -eq 0 ]; then
        echo "[$(date '+%H:%M:%S')] Git activity check..." | tee -a "$LOG_FILE"
        cd /home/jhenry/Source/GRID/sark
        recent=$(git log --all --since="20 minutes ago" --oneline 2>/dev/null | wc -l)
        echo "[$(date '+%H:%M:%S')] Commits in last 20 min: $recent" | tee -a "$LOG_FILE"
    fi
    
    # Wait before next check
    sleep $SLEEP_INTERVAL
done
