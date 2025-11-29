#!/bin/bash
# Cursor-specific Worker Launcher
# Helps launch Czarina workers in Cursor IDE

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

echo "🚀 Launching Cursor for worker: $WORKER_ID"
echo ""
echo "Next steps in Cursor:"
echo "1. In Cursor chat, type:"
echo "   @${WORKER_FILE}"
echo ""
echo "   Follow this prompt exactly as the assigned worker."
echo ""
echo "2. Or use Cmd/Ctrl+P to open: ${WORKER_FILE##*/}"
echo ""

# Try to open Cursor
if command -v cursor &> /dev/null; then
    echo "Opening Cursor..."
    cursor "$PROJECT_DIR" "$WORKER_FILE" &
    echo "✓ Cursor launched"
else
    echo "⚠️  'cursor' command not found"
    echo "💡 Install Cursor from: https://cursor.sh"
    echo ""
    echo "Or manually open:"
    echo "  Project: $PROJECT_DIR"
    echo "  File: $WORKER_FILE"
fi
