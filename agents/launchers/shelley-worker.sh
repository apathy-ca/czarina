#!/bin/bash
# Shelley Worker Launcher for Czarina
# 
# This script helps launch Shelley workers in exe.dev environments.
# It can be used to:
#   1. Display instructions for manual launch
#   2. Open Shelley in a browser (if available)
#   3. Create a pre-configured conversation prompt
#
# Usage:
#   shelley-worker.sh --worker-file <path> --worktree <path> [--open-browser]
#
# Environment variables:
#   SHELLEY_WORKER_ID     - Worker identifier
#   SHELLEY_WORKER_BRANCH - Git branch for this worker
#   SHELLEY_HOSTNAME      - Hostname for Shelley URL (default: auto-detect)

set -e

# Parse arguments
WORKER_FILE=""
WORKTREE_PATH=""
OPEN_BROWSER=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --worker-file)
      WORKER_FILE="$2"
      shift 2
      ;;
    --worktree)
      WORKTREE_PATH="$2"
      shift 2
      ;;
    --open-browser)
      OPEN_BROWSER=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 --worker-file <path> --worktree <path> [--open-browser]"
      echo ""
      echo "Options:"
      echo "  --worker-file    Path to the worker markdown file"
      echo "  --worktree       Path to the git worktree for this worker"
      echo "  --open-browser   Attempt to open Shelley in browser"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required arguments
if [ -z "$WORKER_FILE" ] || [ -z "$WORKTREE_PATH" ]; then
  echo "❌ Error: --worker-file and --worktree are required"
  echo "Run with --help for usage"
  exit 1
fi

# Get worker info from environment or derive from paths
WORKER_ID="${SHELLEY_WORKER_ID:-$(basename "$WORKER_FILE" .md)}"
WORKER_BRANCH="${SHELLEY_WORKER_BRANCH:-unknown}"

# Detect hostname for Shelley URL
if [ -n "$SHELLEY_HOSTNAME" ]; then
  HOSTNAME="$SHELLEY_HOSTNAME"
else
  HOSTNAME=$(hostname -f 2>/dev/null || hostname)
fi

# Construct Shelley URL
if [[ "$HOSTNAME" == *.exe.xyz ]]; then
  SHELLEY_URL="https://${HOSTNAME}:9999/"
else
  SHELLEY_URL="http://localhost:9999/"
fi

# Build the initial prompt for Shelley
ABS_WORKTREE=$(cd "$WORKTREE_PATH" 2>/dev/null && pwd || echo "$WORKTREE_PATH")
ABS_WORKER_FILE=$(cd "$(dirname "$WORKER_FILE")" 2>/dev/null && pwd)/$(basename "$WORKER_FILE") || echo "$WORKER_FILE"

INIT_PROMPT="cd $ABS_WORKTREE && cat WORKER_IDENTITY.md"

# Display information
echo ""
echo "══════════════════════════════════════════════════"
echo "🚀 Czarina Shelley Worker Launcher"
echo "══════════════════════════════════════════════════"
echo ""
echo "👷 Worker:    $WORKER_ID"
echo "🌿 Branch:    $WORKER_BRANCH"
echo "📂 Worktree:  $ABS_WORKTREE"
echo "📝 Task File: $ABS_WORKER_FILE"
echo ""
echo "──────────────────────────────────────────────────"
echo "🌐 Shelley URL: $SHELLEY_URL"
echo "──────────────────────────────────────────────────"
echo ""
echo "📋 To start this worker:"
echo ""
echo "   1. Open Shelley in your browser"
echo "   2. Start a new conversation"
echo "   3. Send this command:"
echo ""
echo "      $INIT_PROMPT"
echo ""
echo "   4. Follow the instructions in WORKER_IDENTITY.md"
echo ""
echo "══════════════════════════════════════════════════"

# Optionally open browser
if [ "$OPEN_BROWSER" = true ]; then
  if command -v xdg-open &> /dev/null; then
    echo "🌐 Opening browser..."
    xdg-open "$SHELLEY_URL" 2>/dev/null &
  elif command -v open &> /dev/null; then
    echo "🌐 Opening browser..."
    open "$SHELLEY_URL" 2>/dev/null &
  else
    echo "⚠️  Could not open browser automatically"
    echo "   Please open: $SHELLEY_URL"
  fi
fi

# Output the init prompt to stdout for easy copying
echo ""
echo "📋 Quick copy (init prompt):"
echo "$INIT_PROMPT"
