#!/bin/bash
# Czar Watchdog - Monitor tmux windows for worker issues/questions

SARK_DIR="/home/jhenry/Source/GRID/sark"
SESSION="sark-v2-session"
LOG_FILE="/home/jhenry/Source/GRID/claude-orchestrator/projects/sark-v2-orchestration/czar-watchdog.log"

echo "🎭 CZAR WATCHDOG - $(date)" | tee -a "$LOG_FILE"
echo "======================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Function to check a tmux window for common issues
check_window() {
    local window=$1
    local worker=$2
    local output=$(tmux capture-pane -t $SESSION:$window -p -S -100)
    
    # Check for approval prompts
    if echo "$output" | grep -q "Do you want to proceed?"; then
        echo "⚠️  WINDOW $window ($worker): WAITING FOR APPROVAL" | tee -a "$LOG_FILE"
        echo "    Last line: $(echo "$output" | tail -1)" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Check for questions to Czar
    if echo "$output" | grep -qi "czar\|question\|blocked\|help needed"; then
        echo "❓ WINDOW $window ($worker): QUESTION/BLOCKER DETECTED" | tee -a "$LOG_FILE"
        echo "    Context: $(echo "$output" | grep -i "czar\|question\|blocked\|help" | tail -1)" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Check for errors
    if echo "$output" | tail -20 | grep -qi "error\|failed\|exception"; then
        echo "❌ WINDOW $window ($worker): ERROR DETECTED" | tee -a "$LOG_FILE"
        echo "    Error: $(echo "$output" | grep -i "error\|failed\|exception" | tail -1)" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Check if stuck (same output for multiple checks)
    # This would require storing previous state - simplified for now
    
    # Check for completion messages
    if echo "$output" | tail -10 | grep -qi "complete\|finished\|done\|ready for review"; then
        echo "✅ WINDOW $window ($worker): Task completion detected" | tee -a "$LOG_FILE"
        return 0
    fi
    
    # Check if actively working (processing indicator)
    if echo "$output" | tail -5 | grep -q "…\|Elucidating\|Ebbing\|Processing"; then
        echo "🔄 WINDOW $window ($worker): Actively working" | tee -a "$LOG_FILE"
        return 0
    fi
    
    # Check if idle at prompt
    if echo "$output" | tail -3 | grep -q "^> $"; then
        echo "⏸️  WINDOW $window ($worker): Idle at prompt" | tee -a "$LOG_FILE"
        return 0
    fi
    
    return 0
}

# Array of workers
declare -A WORKERS
WORKERS[0]="engineer1"
WORKERS[1]="engineer2"
WORKERS[2]="engineer3"
WORKERS[3]="engineer4"
WORKERS[4]="engineer5"
WORKERS[5]="engineer6"
WORKERS[6]="qa1"
WORKERS[7]="qa2"
WORKERS[8]="docs1"
WORKERS[9]="docs2"

# Check all windows
NEEDS_ATTENTION=0
for window in {0..9}; do
    if ! check_window $window "${WORKERS[$window]}"; then
        NEEDS_ATTENTION=1
    fi
    echo "" | tee -a "$LOG_FILE"
done

# Git activity check
cd "$SARK_DIR"
echo "📊 GIT ACTIVITY (Last 10 minutes):" | tee -a "$LOG_FILE"
RECENT_COMMITS=$(git log --all --since="10 minutes ago" --oneline 2>/dev/null)
if [ -z "$RECENT_COMMITS" ]; then
    echo "   ⚠️  No commits in last 10 minutes" | tee -a "$LOG_FILE"
else
    echo "$RECENT_COMMITS" | tee -a "$LOG_FILE"
fi
echo "" | tee -a "$LOG_FILE"

# Summary
echo "======================================" | tee -a "$LOG_FILE"
if [ $NEEDS_ATTENTION -eq 1 ]; then
    echo "🚨 CZAR ATTENTION NEEDED - Issues detected above" | tee -a "$LOG_FILE"
    exit 1
else
    echo "✅ All workers OK - No immediate attention needed" | tee -a "$LOG_FILE"
    exit 0
fi
