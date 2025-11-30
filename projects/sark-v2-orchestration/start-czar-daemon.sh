#!/bin/bash
DAEMON_SESSION="czar-daemon"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if tmux has-session -t $DAEMON_SESSION 2>/dev/null; then
    echo "⚠️  Czar daemon already running"
    echo "To restart: tmux kill-session -t czar-daemon && ./start-czar-daemon.sh"
    exit 1
fi

echo "🎭 Starting Czar daemon v2 (with alert flagging)..."
tmux new-session -d -s $DAEMON_SESSION -c "$SCRIPT_DIR" "./czar-daemon-v2.sh"

echo "✅ Czar daemon started"
echo ""
echo "Monitor:"
echo "  Logs:      tail -f czar-daemon.log"
echo "  Dashboard: ./czar-status-dashboard.sh"
echo "  Alerts:    cat worker-alerts-live.json"
