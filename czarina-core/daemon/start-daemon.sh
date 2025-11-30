#!/bin/bash
# Start the Czarina daemon in a dedicated tmux session
#
# Usage: start-daemon.sh <project-orchestration-dir>
# Example: start-daemon.sh /path/to/project/czarina-myproject

set -euo pipefail

PROJECT_DIR="${1:-.}"
CONFIG_FILE="${PROJECT_DIR}/config.json"

# Validate config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    echo "Usage: $0 <project-orchestration-dir>"
    echo "Example: $0 /path/to/project/czarina-myproject"
    exit 1
fi

# Load project slug
if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed"
    exit 1
fi

PROJECT_SLUG=$(jq -r '.project.slug' "$CONFIG_FILE")
DAEMON_SESSION="${PROJECT_SLUG}-daemon"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if daemon is already running
if tmux has-session -t $DAEMON_SESSION 2>/dev/null; then
    echo "⚠️  Czarina daemon is already running for project: $PROJECT_SLUG"
    echo "Session: $DAEMON_SESSION"
    echo ""
    echo "Commands:"
    echo "  View daemon:  tmux attach -t $DAEMON_SESSION"
    echo "  Stop daemon:  tmux kill-session -t $DAEMON_SESSION"
    echo "  View logs:    tail -f $PROJECT_DIR/status/daemon.log"
    exit 1
fi

# Start daemon in new tmux session
echo "🎭 Starting Czarina autonomous daemon..."
echo "Project: $PROJECT_SLUG"
echo "Session: $DAEMON_SESSION"
echo ""

# Convert to absolute path
PROJECT_DIR_ABS=$(cd "$PROJECT_DIR" && pwd)

tmux new-session -d -s $DAEMON_SESSION -c "$SCRIPT_DIR" "$SCRIPT_DIR/czar-daemon.sh $PROJECT_DIR_ABS"

echo "✅ Czarina daemon started in tmux session: $DAEMON_SESSION"
echo ""
echo "Commands:"
echo "  View daemon:  tmux attach -t $DAEMON_SESSION"
echo "  Stop daemon:  tmux kill-session -t $DAEMON_SESSION"
echo "  View logs:    tail -f $PROJECT_DIR/status/daemon.log"
echo ""
echo "The daemon will:"
echo "  • Auto-approve all worker requests (every 2 minutes)"
echo "  • Auto-accept worker edits"
echo "  • Monitor for blocking issues"
echo "  • Log all activity to status/daemon.log"
echo ""
echo "🎭 Czarina is now autonomous. Human intervention should not be needed."
echo ""
