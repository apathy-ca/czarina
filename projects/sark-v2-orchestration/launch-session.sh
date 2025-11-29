#!/bin/bash
# SARK v2.0 - Launch Development Session
# Creates tmux session with all workers in their proper branches

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

SESSION_NAME="sark-v2-session"
SARK_DIR="$PROJECT_ROOT"
PROMPT_DIR="${SCRIPT_DIR}/prompts/sark-v2"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  SARK v2.0 - Development Session Launch                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Project: $PROJECT_NAME"
echo "Repository: $SARK_DIR"
echo ""

# Kill existing session if it exists
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

# Create new session
echo "🚀 Creating tmux session: $SESSION_NAME"
tmux new-session -d -s "$SESSION_NAME" -n "engineer1" -c "$SARK_DIR"

# Function to set up a worker window
setup_worker() {
    local worker_id=$1
    local worker_name=$2
    local branch=$3
    local prompt_file=$4
    local description=$5

    echo "  → Setting up: $worker_id ($description)"

    # Create or select window
    if [ "$worker_id" != "engineer1" ]; then
        tmux new-window -t "$SESSION_NAME" -n "$worker_name" -c "$SARK_DIR"
    fi

    # Checkout branch
    tmux send-keys -t "$SESSION_NAME:$worker_name" "git checkout $branch" C-m

    # Clear and launch Claude Code with prompt
    tmux send-keys -t "$SESSION_NAME:$worker_name" "clear" C-m
    tmux send-keys -t "$SESSION_NAME:$worker_name" "claude $prompt_file" C-m
}

# Set up all workers from WORKER_DEFINITIONS
echo ""
echo "📋 Launching workers..."

IFS='|' read -r id branch task desc <<< "${WORKER_DEFINITIONS[0]}"
setup_worker "$id" "$id" "$branch" "$PROMPT_DIR/ENGINEER-1-LEAD_ARCHITECT.md" "$desc"

IFS='|' read -r id branch task desc <<< "${WORKER_DEFINITIONS[1]}"
setup_worker "$id" "$id" "$branch" "$PROMPT_DIR/ENGINEER-2.md" "$desc"

IFS='|' read -r id branch task desc <<< "${WORKER_DEFINITIONS[2]}"
setup_worker "$id" "$id" "$branch" "$PROMPT_DIR/ENGINEER-3.md" "$desc"

IFS='|' read -r id branch task desc <<< "${WORKER_DEFINITIONS[3]}"
setup_worker "$id" "$id" "$branch" "$PROMPT_DIR/ENGINEER-4.md" "$desc"

IFS='|' read -r id branch task desc <<< "${WORKER_DEFINITIONS[4]}"
setup_worker "$id" "$id" "$branch" "$PROMPT_DIR/ENGINEER-5.md" "$desc"

IFS='|' read -r id branch task desc <<< "${WORKER_DEFINITIONS[5]}"
setup_worker "$id" "$id" "$branch" "$PROMPT_DIR/ENGINEER-6.md" "$desc"

IFS='|' read -r id branch task desc <<< "${WORKER_DEFINITIONS[6]}"
setup_worker "$id" "$id" "$branch" "$PROMPT_DIR/QA-1.md" "$desc"

IFS='|' read -r id branch task desc <<< "${WORKER_DEFINITIONS[7]}"
setup_worker "$id" "$id" "$branch" "$PROMPT_DIR/QA-2.md" "$desc"

IFS='|' read -r id branch task desc <<< "${WORKER_DEFINITIONS[8]}"
setup_worker "$id" "$id" "$branch" "$PROMPT_DIR/DOCS-1.md" "$desc"

IFS='|' read -r id branch task desc <<< "${WORKER_DEFINITIONS[9]}"
setup_worker "$id" "$id" "$branch" "$PROMPT_DIR/DOCS-2.md" "$desc"

# Select first window
tmux select-window -t "$SESSION_NAME:engineer1"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Session Ready!                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Windows created:"
echo "  0: engineer1  - Lead Architect & MCP Adapter"
echo "  1: engineer2  - HTTP/REST Adapter"
echo "  2: engineer3  - gRPC Adapter"
echo "  3: engineer4  - Federation & Discovery"
echo "  4: engineer5  - Advanced Features"
echo "  5: engineer6  - Database & Schema"
echo "  6: qa1        - Integration Testing"
echo "  7: qa2        - Performance & Security"
echo "  8: docs1      - API Documentation"
echo "  9: docs2      - Tutorials & Examples"
echo ""
echo "Navigation:"
echo "  Switch windows: Ctrl+b then 0-9"
echo "  Switch panes: Ctrl+b then arrow keys"
echo "  Detach: Ctrl+b then d"
echo "  Reattach: tmux attach -t $SESSION_NAME"
echo ""
echo "Next: Attach to session and send initial task to workers"
echo "  tmux attach -t $SESSION_NAME"
echo ""
