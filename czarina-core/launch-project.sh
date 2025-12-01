#!/bin/bash
# Czarina Project Launcher
# Launches all workers for a project in tmux sessions

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Get czarina directory (passed as first argument)
CZARINA_DIR="${1:-}"

if [ -z "$CZARINA_DIR" ] || [ ! -d "$CZARINA_DIR" ]; then
    echo -e "${RED}❌ Usage: $0 <czarina-dir>${NC}"
    echo "   Example: $0 /path/to/project/.czarina"
    exit 1
fi

# Load configuration
CONFIG_FILE="${CZARINA_DIR}/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Config file not found: ${CONFIG_FILE}${NC}"
    exit 1
fi

# Check for required tools
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is required but not installed${NC}"
    echo "   Install: sudo apt install jq"
    exit 1
fi

if ! command -v tmux &> /dev/null; then
    echo -e "${RED}❌ tmux is required but not installed${NC}"
    echo "   Install: sudo apt install tmux"
    exit 1
fi

PROJECT_NAME=$(jq -r '.project.name' "$CONFIG_FILE")
PROJECT_SLUG=$(jq -r '.project.slug' "$CONFIG_FILE")
PROJECT_ROOT=$(jq -r '.project.repository' "$CONFIG_FILE")

# Create short session name
# Extract version number if present (e.g., v0.4.7 -> v047, v1.2.3 -> v123)
if [[ "$PROJECT_SLUG" =~ ^v?([0-9]+)\.?([0-9]+)?\.?([0-9]+)? ]]; then
    VERSION="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
    SESSION_NAME="czarina-v${VERSION}"
else
    # No version found, use first word of slug (up to 15 chars)
    FIRST_WORD=$(echo "$PROJECT_SLUG" | cut -d'-' -f1 | cut -c1-15)
    SESSION_NAME="czarina-${FIRST_WORD}"
fi

echo -e "${BLUE}🚀 Launching Czarina Project${NC}"
echo "   Project: $PROJECT_NAME"
echo "   Slug: $PROJECT_SLUG"
echo "   Session: $SESSION_NAME"
echo "   Root: $PROJECT_ROOT"
echo ""

# Check if tmux session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Session already exists: ${SESSION_NAME}${NC}"
    echo ""
    echo "Options:"
    echo "  1. Attach to existing session: tmux attach -t ${SESSION_NAME}"
    echo "  2. Kill and restart: tmux kill-session -t ${SESSION_NAME} && czarina launch"
    exit 0
fi

# Create new tmux session
echo -e "${GREEN}📦 Creating tmux session: ${SESSION_NAME}${NC}"
if ! tmux new-session -d -s "$SESSION_NAME" -n "orchestrator" 2>/dev/null; then
    echo -e "${RED}❌ Failed to create tmux session${NC}"
    echo "   This might happen if the session name is invalid or tmux server is not running"
    echo "   Try: tmux kill-server && czarina launch"
    exit 1
fi

# Give tmux a moment to fully initialize
sleep 0.5

# Set up orchestrator window
tmux send-keys -t "${SESSION_NAME}:orchestrator" "cd ${PROJECT_ROOT}" C-m
tmux send-keys -t "${SESSION_NAME}:orchestrator" "echo '🎯 Czarina Orchestrator - ${PROJECT_NAME}'" C-m
tmux send-keys -t "${SESSION_NAME}:orchestrator" "echo ''" C-m
tmux send-keys -t "${SESSION_NAME}:orchestrator" "echo 'Windows:'" C-m

# Get worker count
WORKER_COUNT=$(jq -r '.workers | length' "$CONFIG_FILE")
echo -e "${BLUE}👷 Creating ${WORKER_COUNT} worker windows${NC}"

# Create a window for each worker
for i in $(seq 0 $((WORKER_COUNT - 1))); do
    WORKER_ID=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
    WORKER_AGENT=$(jq -r ".workers[$i].agent" "$CONFIG_FILE")
    WORKER_DESC=$(jq -r ".workers[$i].description" "$CONFIG_FILE")
    WORKER_FILE="${CZARINA_DIR}/workers/${WORKER_ID}.md"

    if [ ! -f "$WORKER_FILE" ]; then
        echo -e "${RED}⚠️  Worker file not found: ${WORKER_FILE}${NC}"
        continue
    fi

    echo "   • ${WORKER_ID} (${WORKER_AGENT})"

    # Create window for this worker
    tmux new-window -t "${SESSION_NAME}" -n "${WORKER_ID}"
    tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "cd ${PROJECT_ROOT}" C-m
    tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "clear" C-m
    tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '═══════════════════════════════════════════════════════════════'" C-m
    tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '🤖 Worker: ${WORKER_ID}'" C-m
    tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '📋 Role: ${WORKER_DESC}'" C-m
    tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '🔧 Agent: ${WORKER_AGENT}'" C-m
    tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '═══════════════════════════════════════════════════════════════'" C-m
    tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo ''" C-m
    tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "cat ${WORKER_FILE}" C-m
    tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo ''" C-m
    tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '═══════════════════════════════════════════════════════════════'" C-m
    tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo ''" C-m

    # Add to orchestrator window list
    tmux send-keys -t "${SESSION_NAME}:orchestrator" "echo '  • ${WORKER_ID} - ${WORKER_DESC}'" C-m

    # Launch agent-specific setup
    case "$WORKER_AGENT" in
        "aider")
            tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '🚀 Launching Aider...'" C-m
            tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo ''" C-m
            # Check if aider is available
            if command -v aider &> /dev/null; then
                # Auto-launch aider with the worker prompt
                tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "aider --model claude-3-5-sonnet-20241022 --message 'Read and follow the instructions in .czarina/workers/${WORKER_ID}.md'" C-m
            else
                tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '⚠️  Aider not found. Install with: pip install aider-chat'" C-m
                tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo ''" C-m
                tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '🔧 To start manually:'" C-m
                tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '   aider --model claude-3-5-sonnet-20241022'" C-m
            fi
            ;;
        "claude-code")
            tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '🔧 To start working with Claude Code:'" C-m
            tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '   1. Open Claude Code in this directory'" C-m
            tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '   2. Load worker prompt with: cat .czarina/workers/${WORKER_ID}.md'" C-m
            tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo ''" C-m
            ;;
        "cursor")
            tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '🔧 To start working with Cursor:'" C-m
            tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '   1. Open Cursor in this directory'" C-m
            tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '   2. Load worker prompt: .czarina/workers/${WORKER_ID}.md'" C-m
            tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo ''" C-m
            ;;
        *)
            tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo '🔧 Ready to start working!'" C-m
            tmux send-keys -t "${SESSION_NAME}:${WORKER_ID}" "echo ''" C-m
            ;;
    esac
done

# Finish orchestrator window
tmux send-keys -t "${SESSION_NAME}:orchestrator" "echo ''" C-m
tmux send-keys -t "${SESSION_NAME}:orchestrator" "echo '📝 Commands:'" C-m
tmux send-keys -t "${SESSION_NAME}:orchestrator" "echo '   • Switch windows: Ctrl+b <number>'" C-m
tmux send-keys -t "${SESSION_NAME}:orchestrator" "echo '   • List windows: Ctrl+b w'" C-m
tmux send-keys -t "${SESSION_NAME}:orchestrator" "echo '   • Detach: Ctrl+b d'" C-m
tmux send-keys -t "${SESSION_NAME}:orchestrator" "echo '   • Attach: tmux attach -t ${SESSION_NAME}'" C-m
tmux send-keys -t "${SESSION_NAME}:orchestrator" "echo ''" C-m
tmux send-keys -t "${SESSION_NAME}:orchestrator" "echo '✅ All workers ready!'" C-m

echo ""
echo -e "${GREEN}✅ Project launched successfully!${NC}"
echo ""
echo "📺 Attach to session:"
echo "   tmux attach -t ${SESSION_NAME}"
echo ""
echo "📋 Switch between workers with: Ctrl+b <window-number>"
echo "🔄 Detach with: Ctrl+b d"
echo ""
