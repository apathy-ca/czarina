#!/bin/bash
# Send initial task message to all workers in tmux session
# Usage: ./send-task.sh [message]

set -euo pipefail

SESSION_NAME="sark-v2-session"
MESSAGE="${1:-Ready to begin. First, analyze the current state of the SARK repository and your assigned branch to understand what work has already been completed in the previous session. Then, propose a plan for what needs to be done next in your area of responsibility.}"

# Check if session exists
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "❌ Session not found: $SESSION_NAME"
    echo "   Run ./launch-session.sh first"
    exit 1
fi

echo "📨 Sending task to all workers in: $SESSION_NAME"
echo ""
echo "Message:"
echo "  $MESSAGE"
echo ""

# List of all worker windows
WORKERS=("engineer1" "engineer2" "engineer3" "engineer4" "engineer5" "engineer6" "qa1" "qa2" "docs1" "docs2")

for worker in "${WORKERS[@]}"; do
    echo "  → Sending to: $worker"

    # Use tmux paste buffer to handle special characters
    echo "$MESSAGE" | tmux load-buffer -
    tmux paste-buffer -t "$SESSION_NAME:$worker"
    tmux send-keys -t "$SESSION_NAME:$worker" Enter

    # Small delay to avoid overwhelming
    sleep 0.5
done

echo ""
echo "✅ Task sent to all 10 workers!"
echo ""
echo "Monitor progress:"
echo "  - View workers: tmux attach -t $SESSION_NAME"
echo "  - View dashboard: tmux attach -t sark-dashboard"
echo ""
