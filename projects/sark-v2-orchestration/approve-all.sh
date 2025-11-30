#!/bin/bash
# Approve all pending worker requests

for i in 0 1 2 5 6 8 9; do 
    output=$(tmux capture-pane -t sark-v2-session:$i -p | tail -10)
    if echo "$output" | grep -q "Do you want to proceed?"; then
        echo "Window $i needs approval - sending..."
        tmux send-keys -t sark-v2-session:$i "2" C-m
    fi
done
echo "✅ Approval sweep complete"
