#!/bin/bash
# Enhanced Task Injection System
# Properly injects full task content into worker tmux sessions
# Fixes the "file path reference" problem that caused 33% task confusion

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Usage check
if [ $# -lt 2 ]; then
    echo "Usage: $0 <worker_id> <task_file>"
    echo ""
    echo "Example:"
    echo "  $0 engineer1 prompts/engineer1_BONUS_TASKS.txt"
    echo ""
    echo "Available workers:"
    printf '%s\n' "${WORKER_DEFINITIONS[@]}" | cut -d'|' -f1 | sed 's/^/  /'
    exit 1
fi

WORKER_ID=$1
TASK_FILE=$2
SESSION_NAME="sark-worker-${WORKER_ID}"
LOG_FILE="${ORCHESTRATOR_DIR}/status/task-injections.log"

# Validate worker exists
if ! printf '%s\n' "${WORKER_DEFINITIONS[@]}" | cut -d'|' -f1 | grep -q "^${WORKER_ID}$"; then
    echo "❌ Error: Unknown worker '${WORKER_ID}'"
    exit 1
fi

# Validate task file exists
if [ ! -f "$TASK_FILE" ]; then
    echo "❌ Error: Task file not found: $TASK_FILE"
    exit 1
fi

# Validate tmux session exists
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "❌ Error: Tmux session not found: $SESSION_NAME"
    echo "   Worker may not be running. Start with: ./launch-worker.sh ${WORKER_ID}"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 INJECTING TASK TO WORKER: ${WORKER_ID}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Task file: $TASK_FILE"
echo "Session: $SESSION_NAME"
echo ""

# Clear any pending input
tmux send-keys -t "$SESSION_NAME" C-c 2>/dev/null || true
sleep 0.5

# Send clear visual separator
tmux send-keys -t "$SESSION_NAME" "" C-m
tmux send-keys -t "$SESSION_NAME" "" C-m
tmux send-keys -t "$SESSION_NAME" "# ════════════════════════════════════════════════════════════════" C-m
tmux send-keys -t "$SESSION_NAME" "# 📋 NEW TASK ASSIGNMENT FOR: ${WORKER_ID}" C-m
tmux send-keys -t "$SESSION_NAME" "# Task file: $(basename $TASK_FILE)" C-m
tmux send-keys -t "$SESSION_NAME" "# Timestamp: $(date '+%Y-%m-%d %H:%M:%S')" C-m
tmux send-keys -t "$SESSION_NAME" "# ════════════════════════════════════════════════════════════════" C-m
tmux send-keys -t "$SESSION_NAME" "" C-m

# Read and inject task content using tmux paste buffer
# This is more reliable than send-keys for complex content
echo "Injecting task content via paste buffer..."

# Load file into tmux paste buffer
tmux load-buffer "$TASK_FILE"

# Paste into the session
tmux paste-buffer -t "$SESSION_NAME"

# Send Enter to submit the pasted content
sleep 0.5
tmux send-keys -t "$SESSION_NAME" C-m

LINE_COUNT=$(wc -l < "$TASK_FILE")

# Send closing separator (after a brief pause)
sleep 0.5
tmux send-keys -t "$SESSION_NAME" "" C-m
tmux send-keys -t "$SESSION_NAME" "# ════════════════════════════════════════════════════════════════" C-m
tmux send-keys -t "$SESSION_NAME" "# 📋 END TASK ASSIGNMENT" C-m
tmux send-keys -t "$SESSION_NAME" "# ════════════════════════════════════════════════════════════════" C-m
tmux send-keys -t "$SESSION_NAME" "" C-m
tmux send-keys -t "$SESSION_NAME" "# Please acknowledge receipt and begin work" C-m
tmux send-keys -t "$SESSION_NAME" "" C-m

# Log the injection
mkdir -p "$(dirname "$LOG_FILE")"
{
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Worker: ${WORKER_ID}"
    echo "Task file: $TASK_FILE"
    echo "Lines injected: $LINE_COUNT"
    echo "Session: $SESSION_NAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
} >> "$LOG_FILE"

echo ""
echo "✅ Task injected successfully!"
echo "   Lines sent: $LINE_COUNT"
echo "   Logged to: $LOG_FILE"
echo ""
echo "💡 To view worker's response:"
echo "   tmux attach -t $SESSION_NAME"
echo ""
