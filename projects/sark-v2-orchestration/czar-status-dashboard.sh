#!/bin/bash
# Czar Status Dashboard - Recognizes "accept edits" as completion

SESSION="sark-v2-session"
ALERT_FILE="worker-alerts.json"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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

echo "🎭 CZAR STATUS DASHBOARD"
echo "========================================"
echo "Time: $(date '+%H:%M:%S')"
echo ""

> "$ALERT_FILE"
NEEDS_ATTENTION=0
COMPLETED=0

for window in {0..9}; do
    worker="${WORKERS[$window]}"
    output=$(tmux capture-pane -t $SESSION:$window -p 2>/dev/null || echo "")
    
    status="🟢 OK"
    color=$GREEN
    alert=""
    
    # Check for edit acceptance (COMPLETED WORK)
    if echo "$output" | grep -q "accept edits"; then
        status="✅ COMPLETE (needs acceptance)"
        color=$CYAN
        alert="Window $window ($worker) completed work - ready to accept edits"
        ((COMPLETED++))
        echo "{\"window\": $window, \"worker\": \"$worker\", \"status\": \"complete\", \"severity\": \"low\"}" >> "$ALERT_FILE"
    
    # Check for approval prompts (WAITING)
    elif echo "$output" | grep -q "Do you want to proceed?"; then
        status="⏸️  WAITING FOR APPROVAL"
        color=$YELLOW
        alert="Window $window ($worker) waiting for approval to proceed"
        ((NEEDS_ATTENTION++))
        echo "{\"window\": $window, \"worker\": \"$worker\", \"status\": \"needs_approval\", \"severity\": \"medium\"}" >> "$ALERT_FILE"
    
    # Check for errors
    elif echo "$output" | tail -10 | grep -qiE "error|failed|exception"; then
        status="🔴 ERROR DETECTED"
        color=$RED
        alert="Window $window ($worker) has error"
        ((NEEDS_ATTENTION++))
        echo "{\"window\": $window, \"worker\": \"$worker\", \"status\": \"error\", \"severity\": \"high\"}" >> "$ALERT_FILE"
    
    # Check if working
    elif echo "$output" | tail -5 | grep -qE "…|Processing|Writing|Reading|Creating"; then
        status="🔵 WORKING"
        color=$BLUE
    
    # Check if idle
    elif echo "$output" | tail -3 | grep -qE "^> $"; then
        if echo "$output" | tail -20 | grep -qiE "complete|finished|done|success"; then
            status="🟢 DONE"
            color=$GREEN
        else
            status="⚪ IDLE"
            color=$NC
        fi
    fi
    
    printf "Window ${BLUE}%d${NC} | %-12s | ${color}%-35s${NC}\n" "$window" "$worker" "$status"
    
    if [ -n "$alert" ]; then
        echo "  └─ $alert"
    fi
done

echo ""
echo "========================================"

# Summary
if [ $COMPLETED -gt 0 ]; then
    echo -e "${CYAN}✅ $COMPLETED workers COMPLETED - ready to accept edits${NC}"
fi

if [ $NEEDS_ATTENTION -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $NEEDS_ATTENTION workers need approval to proceed${NC}"
fi

if [ $COMPLETED -eq 0 ] && [ $NEEDS_ATTENTION -eq 0 ]; then
    echo -e "${GREEN}✅ All workers actively working or idle${NC}"
fi

if [ $COMPLETED -gt 0 ] || [ $NEEDS_ATTENTION -gt 0 ]; then
    echo ""
    echo "Workers requiring action:"
    while IFS= read -r line; do
        worker=$(echo "$line" | grep -oP '"worker": "\K[^"]+')
        status=$(echo "$line" | grep -oP '"status": "\K[^"]+')
        severity=$(echo "$line" | grep -oP '"severity": "\K[^"]+')
        
        if [ "$status" = "complete" ]; then
            echo -e "  ${CYAN}✅ $worker - Work complete, accept edits to save${NC}"
        elif [ "$severity" = "high" ]; then
            echo -e "  ${RED}● $worker - $status${NC}"
        else
            echo -e "  ${YELLOW}● $worker - $status${NC}"
        fi
    done < "$ALERT_FILE"
fi

echo ""
echo "========================================"

# Git activity
echo "📊 Recent Git Activity (last 30 min):"
cd /home/jhenry/Source/GRID/sark
recent=$(git log --all --since="30 minutes ago" --oneline 2>/dev/null | wc -l)
if [ $recent -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No commits in last 30 minutes${NC}"
else
    echo -e "${GREEN}✅ $recent commits in last 30 minutes${NC}"
    echo ""
    echo "Recent commits:"
    git log --all --since="30 minutes ago" --oneline --decorate | head -5
fi

echo ""
echo "========================================"
echo "Dashboard updates every run"
echo "Monitor: ./czar-status-dashboard.sh"
echo "Accept all edits: tmux attach -t sark-v2-session, then approve each window"
