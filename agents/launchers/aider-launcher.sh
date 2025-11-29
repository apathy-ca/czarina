#!/bin/bash
# Aider-specific Worker Launcher
# Launches Czarina workers with Aider CLI

set -euo pipefail

WORKER_ID="${1:-}"
PROJECT_DIR="${2:-.}"
MODEL="${3:-claude-3-5-sonnet-20241022}"

if [ -z "$WORKER_ID" ]; then
    echo "Usage: $0 <worker-id> [project-dir] [model]"
    echo ""
    echo "Example: $0 engineer1 ./myproject"
    echo "         $0 qa1 . gpt-4-turbo"
    exit 1
fi

# Check if aider is installed
if ! command -v aider &> /dev/null; then
    echo "❌ Aider not installed"
    echo ""
    echo "Install with:"
    echo "  pip install aider-chat"
    echo ""
    echo "Or with pipx:"
    echo "  pipx install aider-chat"
    exit 1
fi

# Find orchestration directory
CZARINA_DIR=$(find "$PROJECT_DIR" -maxdepth 1 -type d -name "czarina-*" 2>/dev/null | head -1)

if [ -z "$CZARINA_DIR" ]; then
    echo "❌ No czarina-* directory found in $PROJECT_DIR"
    echo "💡 Run 'czarina embed' first to create orchestration"
    exit 1
fi

WORKER_FILE="$CZARINA_DIR/workers/${WORKER_ID}.md"

if [ ! -f "$WORKER_FILE" ]; then
    # Try uppercase
    WORKER_FILE="$CZARINA_DIR/workers/${WORKER_ID^^}.md"
    if [ ! -f "$WORKER_FILE" ]; then
        echo "❌ Worker not found: ${WORKER_ID}"
        echo ""
        echo "Available workers:"
        ls -1 "$CZARINA_DIR/workers/" 2>/dev/null | sed 's/\.md$//' | sed 's/^/  - /'
        exit 1
    fi
fi

echo "🚀 Launching Aider for worker: $WORKER_ID"
echo "📄 Worker file: $WORKER_FILE"
echo "🤖 Model: $MODEL"
echo ""

# Change to project directory
cd "$PROJECT_DIR"

# Launch Aider with worker prompt
# --read: Read the worker file into context
# --model: Specify AI model
# --auto-commits: Automatically create git commits
echo "Starting Aider session..."
echo ""
echo "In the Aider session, the worker prompt has been loaded."
echo "You can start giving instructions or let Aider proceed autonomously."
echo ""

aider --read "$WORKER_FILE" \
      --model "$MODEL" \
      --auto-commits
