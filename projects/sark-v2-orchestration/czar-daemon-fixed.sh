#!/bin/bash
# Czar Autonomous Daemon - FIXED approval logic

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SESSION="sark-v2-session"
LOG_FILE="$SCRIPT_DIR/czar-daemon.log"
SLEEP_INTERVAL=120

echo "🎭 CZAR DAEMON STARTING (FIXED)" | tee -a "$LOG_FILE"
echo "Time: $(date)" | tee -a "$LOG_FILE"
echo "======================================" | tee -a "$LOG_FILE"

auto_approve_all() {
    local approved_count=0
    
    for window in {0..9}; do
        output=$(tmux capture-pane -t $SESSION:$window -p 2>/dev/null || echo "")
        
        # Check for approval prompts
        if echo "$output" | grep -q "Do you want to proceed?"; then
            # Count options
            options=$(echo "$output" | grep -E "^\s+[0-9]+\." | wc -l)
            
            if [ $options -eq 2 ]; then
                # 2 options: 1=Yes, 2=No → Choose 1
                tmux send-keys -t $SESSION:$window "1" C-m
            elif [ $options -eq 3 ]; then
                # 3 options: Usually 1=Yes, 2=Yes+allow directory, 3=No → Choose 2
                if echo "$output" | grep -q "allow reading"; then
                    tmux send-keys -t $SESSION:$window "2" C-m
                else
                    tmux send-keys -t $SESSION:$window "1" C-m
                fi
            else
                # Default to option 1 (Yes)
                tmux send-keys -t $SESSION:$window "1" C-m
            fi
            
            echo "[$(date '+%H:%M:%S')] Auto-approved window $window ($options options)" | tee -a "$LOG_FILE"
            ((approved_count++))
            sleep 0.3
        fi
        
        # Check for edit acceptance prompts
        if echo "$output" | grep -q "accept edits"; then
            tmux send-keys -t $SESSION:$window C-m
            echo "[$(date '+%H:%M:%S')] Auto-accepting edits in window $window" | tee -a "$LOG_FILE"
            ((approved_count++))
            sleep 0.3
        fi
    done
    
    if [ $approved_count -gt 0 ]; then
        echo "[$(date '+%H:%M:%S')] ✅ Auto-approved $approved_count items" | tee -a "$LOG_FILE"
    fi
    
    return $approved_count
}

iteration=0
while true; do
    ((iteration++))
    echo "" | tee -a "$LOG_FILE"
    echo "=== Iteration $iteration - $(date '+%Y-%m-%d %H:%M:%S') ===" | tee -a "$LOG_FILE"
    
    auto_approve_all
    approved=$?
    
    if [ $approved -gt 0 ]; then
        sleep 3
        auto_approve_all  # Second pass
    fi
    
    if [ $((iteration % 10)) -eq 0 ]; then
        cd /home/jhenry/Source/GRID/sark
        recent=$(git log --all --since="20 minutes ago" --oneline 2>/dev/null | wc -l)
        echo "[$(date '+%H:%M:%S')] Commits in last 20 min: $recent" | tee -a "$LOG_FILE"
    fi
    
    sleep $SLEEP_INTERVAL
done
