#!/bin/bash
# GitHub Copilot-specific Worker Launcher
# Helps launch Czarina workers with GitHub Copilot

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

echo "🚀 GitHub Copilot Setup for worker: $WORKER_ID"
echo ""
echo "📋 Instructions:"
echo ""
echo "1. Open VS Code in this project:"
echo "   cd $PROJECT_DIR"
echo "   code ."
echo ""
echo "2. Ensure GitHub Copilot extension is installed and active"
echo ""
echo "3. Open Copilot Chat (Cmd/Ctrl+Shift+I or click chat icon)"
echo ""
echo "4. In Copilot Chat, type one of these:"
echo ""
echo "   Option A (file reference):"
echo "   #file:${WORKER_FILE}"
echo "   Follow this worker prompt exactly."
echo ""
echo "   Option B (explicit read):"
echo "   Read ${WORKER_FILE} and follow that worker prompt exactly."
echo ""
echo "   Option C (workspace context):"
echo "   @workspace Read the worker file for ${WORKER_ID} and act as that worker."
echo ""
echo "📄 Worker file location: $WORKER_FILE"
echo ""
echo "💡 Tips:"
echo "  - Use @workspace for full project context"
echo "  - Use / commands like /explain, /fix, /tests"
echo "  - GitHub CLI (gh) works great for creating PRs"
echo "  - Copilot can see your git branches and commits"
echo ""

# Try to open VS Code
if command -v code &> /dev/null; then
    echo "Opening VS Code..."
    code "$PROJECT_DIR" "$WORKER_FILE"
    echo "✓ VS Code launched"
else
    echo "⚠️  'code' command not found"
    echo "💡 Install VS Code from: https://code.visualstudio.com"
    echo ""
    echo "Or manually open:"
    echo "  Project: $PROJECT_DIR"
    echo "  File: $WORKER_FILE"
fi
