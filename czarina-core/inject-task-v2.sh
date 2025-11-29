#!/bin/bash
# Enhanced Task Injection System v2
# More robust handling of special characters

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <worker_id> <task_file>"
    exit 1
fi

WORKER_ID=$1
TASK_FILE=$2
SESSION_NAME="sark-worker-${WORKER_ID}"
LOG_DIR="${ORCHESTRATOR_DIR}/status"
LOG_FILE="${LOG_DIR}/task-injections.log"

mkdir -p "$LOG_DIR"

# Validate session exists
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "❌ Error: Session not found: $SESSION_NAME"
    exit 1
fi

echo "📝 Injecting task to $WORKER_ID via tmux paste buffer..."

# Use tmux's paste buffer instead of send-keys
# This handles special characters much better
tmux load-buffer "$TASK_FILE"
tmux paste-buffer -t "$SESSION_NAME"

# Log it
{
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Worker: ${WORKER_ID}"
    echo "Task file: $TASK_FILE"
    echo "Method: tmux paste-buffer"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
} >> "$LOG_FILE"

echo "✅ Task injected to $WORKER_ID"
