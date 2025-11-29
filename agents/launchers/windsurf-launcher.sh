#!/bin/bash
# Windsurf-specific Worker Launcher
# Helps launch Czarina workers in Windsurf IDE

set -euo pipefail

WORKER_ID="${1:-}"
PROJECT_DIR="${2:-.}"

if [ -z "$WORKER_ID" ]; then
    echo "Usage: $0 <worker-id> [project-dir]"
    echo ""
    echo "Example: $0 engineer1 ./myproject"
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

echo "🚀 Launching Windsurf for worker: $WORKER_ID"
echo ""
echo "Next steps in Windsurf:"
echo "1. In Windsurf chat, type:"
echo "   @${WORKER_FILE}"
echo ""
echo "   I am this worker. Follow the prompt exactly."
echo ""
echo "2. Or use Cmd/Ctrl+P to open: ${WORKER_FILE##*/}"
echo ""
echo "💡 Tips:"
echo "  - Use @ to reference files and add them to context"
echo "  - Keep worker file visible in a split pane"
echo "  - Windsurf's git integration works with Czarina branches"
echo "  - Use the AI chat for step-by-step guidance"
echo ""

# Try to open Windsurf
if command -v windsurf &> /dev/null; then
    echo "Opening Windsurf..."
    windsurf "$PROJECT_DIR" "$WORKER_FILE" &
    echo "✓ Windsurf launched"
else
    echo "⚠️  'windsurf' command not found"
    echo "💡 Install Windsurf from their website"
    echo ""
    echo "Or manually open:"
    echo "  Project: $PROJECT_DIR"
    echo "  File: $WORKER_FILE"
fi
