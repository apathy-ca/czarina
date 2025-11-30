#!/bin/bash
# Accept all pending edits in worker windows

SESSION="sark-v2-session"
echo "🎭 Accepting all pending edits in $SESSION..."

for window in {0..9}; do
    # Send Enter to accept default (should be "accept")
    tmux send-keys -t $SESSION:$window "" C-m 2>/dev/null
    sleep 0.3
done

echo "✅ Sent accept commands to all 10 windows"
