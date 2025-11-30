#!/bin/bash
# Smart approval - detects which option to use

SESSION="sark-v2-session"
echo "🎭 Smart approving all windows..."

for window in {0..9}; do
    output=$(tmux capture-pane -t $SESSION:$window -p 2>/dev/null || echo "")
    
    if echo "$output" | grep -q "Do you want to proceed?"; then
        # Count how many options there are
        options=$(echo "$output" | grep -E "^\s+[0-9]+\." | wc -l)
        
        if [ $options -eq 2 ]; then
            # 2 options: select 1 (Yes)
            echo "Window $window: Approving with option 1"
            tmux send-keys -t $SESSION:$window "1" C-m
        elif [ $options -eq 3 ]; then
            # 3 options: select 2 (Yes, allow reading from directory)
            echo "Window $window: Approving with option 2"
            tmux send-keys -t $SESSION:$window "2" C-m
        else
            echo "Window $window: Unknown approval format ($options options)"
        fi
        sleep 0.3
    fi
done

echo "✅ Smart approval complete"
