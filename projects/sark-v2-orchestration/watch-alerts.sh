#!/bin/bash
# Watch for worker alerts in real-time

ALERT_FILE="worker-alerts-live.json"

echo "🎭 CZAR ALERT MONITOR"
echo "Watching: $ALERT_FILE"
echo "Press Ctrl+C to stop"
echo ""

while true; do
    clear
    date '+%Y-%m-%d %H:%M:%S'
    echo "========================================"
    
    if [ ! -f "$ALERT_FILE" ] || [ ! -s "$ALERT_FILE" ]; then
        echo -e "\033[0;32m✅ NO ALERTS - All workers OK\033[0m"
    else
        alert_count=$(wc -l < "$ALERT_FILE")
        echo -e "\033[0;31m🚨 $alert_count ACTIVE ALERTS\033[0m"
        echo ""
        
        declare -A WORKERS
        WORKERS[0]="ENGINEER-1"
        WORKERS[1]="ENGINEER-2"
        WORKERS[2]="ENGINEER-3"
        WORKERS[3]="ENGINEER-4"
        WORKERS[4]="ENGINEER-5"
        WORKERS[5]="ENGINEER-6"
        WORKERS[6]="QA-1"
        WORKERS[7]="QA-2"
        WORKERS[8]="DOCS-1"
        WORKERS[9]="DOCS-2"
        
        while IFS= read -r line; do
            window=$(echo "$line" | grep -oP '"window": \K\d+')
            status=$(echo "$line" | grep -oP '"status": "\K[^"]+')
            severity=$(echo "$line" | grep -oP '"severity": "\K[^"]+')
            time=$(echo "$line" | grep -oP '"time": "\K[^"]+')
            
            worker="${WORKERS[$window]}"
            
            if [ "$severity" = "high" ]; then
                color="\033[0;31m" # Red
                icon="🔴"
            else
                color="\033[1;33m" # Yellow
                icon="🟡"
            fi
            
            case "$status" in
                stuck_approval)
                    msg="STUCK at approval (Claude Code UI bug)"
                    ;;
                stuck_edit)
                    msg="STUCK at edit prompt (Claude Code UI bug)"
                    ;;
                error)
                    msg="ERROR detected"
                    ;;
                *)
                    msg="$status"
                    ;;
            esac
            
            echo -e "${color}${icon} Window $window ($worker): $msg [$time]\033[0m"
        done < "$ALERT_FILE"
        
        echo ""
        echo "ACTION NEEDED: Approve prompts in affected windows"
        echo "Command: tmux attach -t sark-v2-session"
    fi
    
    echo "========================================"
    echo "Next update in 10 seconds..."
    sleep 10
done
