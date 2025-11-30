#!/bin/bash
# Czar Daemon v2 - With alert flagging and dashboard integration

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SESSION="sark-v2-session"
LOG_FILE="$SCRIPT_DIR/czar-daemon.log"
ALERT_FILE="$SCRIPT_DIR/worker-alerts-live.json"
SLEEP_INTERVAL=120

echo "🎭 CZAR DAEMON V2 STARTING (with alerts)" | tee -a "$LOG_FILE"
echo "Time: $(date)" | tee -a "$LOG_FILE"
echo "Alert file: $ALERT_FILE" | tee -a "$LOG_FILE"
echo "======================================" | tee -a "$LOG_FILE"

auto_approve_all() {
    local approved_count=0
    local stuck_count=0
    
    # Clear previous alerts
    > "$ALERT_FILE"
    
    for window in {0..9}; do
        output=$(tmux capture-pane -t $SESSION:$window -p 2>/dev/null || echo "")
        window_stuck=false
        
        # Check for approval prompts
        if echo "$output" | grep -q "Do you want to proceed?"; then
            options=$(echo "$output" | grep -E "^\s+[0-9]+\." | wc -l)
            
            # Try to approve
            if [ $options -eq 2 ]; then
                tmux send-keys -t $SESSION:$window "1" C-m
            elif [ $options -eq 3 ]; then
                if echo "$output" | grep -q "allow reading"; then
                    tmux send-keys -t $SESSION:$window "2" C-m
                else
                    tmux send-keys -t $SESSION:$window "1" C-m
                fi
            else
                tmux send-keys -t $SESSION:$window "1" C-m
            fi
            
            echo "[$(date '+%H:%M:%S')] Auto-approved window $window ($options options)" | tee -a "$LOG_FILE"
            ((approved_count++))
            
            # Flag as stuck (approval didn't process)
            sleep 0.5
            output_check=$(tmux capture-pane -t $SESSION:$window -p 2>/dev/null || echo "")
            if echo "$output_check" | grep -q "Do you want to proceed?"; then
                echo "[$(date '+%H:%M:%S')] ⚠️  Window $window STUCK at approval (tmux send-keys failed)" | tee -a "$LOG_FILE"
                echo "{\"window\": $window, \"status\": \"stuck_approval\", \"severity\": \"high\", \"time\": \"$(date '+%H:%M:%S')\"}" >> "$ALERT_FILE"
                ((stuck_count++))
                window_stuck=true
            fi
        fi
        
        # Check for edit acceptance prompts
        if echo "$output" | grep -q "accept edits"; then
            tmux send-keys -t $SESSION:$window C-m
            echo "[$(date '+%H:%M:%S')] Auto-accepting edits in window $window" | tee -a "$LOG_FILE"
            ((approved_count++))
            
            # Check if still stuck
            sleep 0.5
            output_check=$(tmux capture-pane -t $SESSION:$window -p 2>/dev/null || echo "")
            if echo "$output_check" | grep -q "accept edits"; then
                echo "[$(date '+%H:%M:%S')] ⚠️  Window $window STUCK at edit prompt (known Claude Code bug)" | tee -a "$LOG_FILE"
                echo "{\"window\": $window, \"status\": \"stuck_edit\", \"severity\": \"medium\", \"time\": \"$(date '+%H:%M:%S')\"}" >> "$ALERT_FILE"
                ((stuck_count++))
                window_stuck=true
            fi
        fi
        
        # Check for errors
        if echo "$output" | tail -10 | grep -qiE "error|failed|exception"; then
            if ! $window_stuck; then
                echo "[$(date '+%H:%M:%S')] ❌ Window $window has ERROR" | tee -a "$LOG_FILE"
                echo "{\"window\": $window, \"status\": \"error\", \"severity\": \"high\", \"time\": \"$(date '+%H:%M:%S')\"}" >> "$ALERT_FILE"
                ((stuck_count++))
            fi
        fi
    done
    
    if [ $approved_count -gt 0 ]; then
        echo "[$(date '+%H:%M:%S')] ✅ Auto-approved $approved_count items" | tee -a "$LOG_FILE"
    fi
    
    if [ $stuck_count -gt 0 ]; then
        echo "[$(date '+%H:%M:%S')] 🚨 $stuck_count workers STUCK - human intervention needed" | tee -a "$LOG_FILE"
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
    
    # Alert summary
    if [ -f "$ALERT_FILE" ] && [ -s "$ALERT_FILE" ]; then
        alert_count=$(wc -l < "$ALERT_FILE")
        echo "[$(date '+%H:%M:%S')] 📢 ACTIVE ALERTS: $alert_count workers need attention" | tee -a "$LOG_FILE"
    fi
    
    # Git activity check
    if [ $((iteration % 10)) -eq 0 ]; then
        cd /home/jhenry/Source/GRID/sark
        recent=$(git log --all --since="20 minutes ago" --oneline 2>/dev/null | wc -l)
        echo "[$(date '+%H:%M:%S')] Commits in last 20 min: $recent" | tee -a "$LOG_FILE"
    fi
    
    sleep $SLEEP_INTERVAL
done
