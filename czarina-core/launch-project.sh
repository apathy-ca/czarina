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

# Create worktrees directory for workers
WORKTREES_DIR="${PROJECT_ROOT}/.czarina/worktrees"
mkdir -p "$WORKTREES_DIR"

# Make sure we're on a safe branch (main) before creating worktrees
echo -e "${BLUE}🔄 Preparing repository for multi-worker launch...${NC}"
cd "$PROJECT_ROOT"

# Clean up any stale worktree references
echo "   Cleaning up stale worktrees..."
git worktree prune 2>/dev/null || true

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo "   Switching from ${CURRENT_BRANCH} to main for worktree setup..."
    git checkout main 2>/dev/null || git checkout master 2>/dev/null || {
        echo -e "${YELLOW}   ⚠️  Could not switch to main/master branch${NC}"
        echo "   Continuing anyway, but some worktrees may fail to create"
    }
fi
echo ""

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

# Get worker count and calculate number of sessions needed
WORKER_COUNT=$(jq -r '.workers | length' "$CONFIG_FILE")
MAX_WINDOWS_PER_SESSION=10
SESSIONS_NEEDED=$(( (WORKER_COUNT + MAX_WINDOWS_PER_SESSION - 1) / MAX_WINDOWS_PER_SESSION ))

# Create sorted worker index array (engineers first, then others)
# This ensures engineer1, engineer2, etc. get tmux window numbers 1, 2, 3...
WORKER_INDICES=()
# First add all workers with "engineer" in their ID
for i in $(seq 0 $((WORKER_COUNT - 1))); do
    WORKER_ID=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
    if [[ "$WORKER_ID" =~ engineer ]]; then
        WORKER_INDICES+=($i)
    fi
done
# Then add all other workers
for i in $(seq 0 $((WORKER_COUNT - 1))); do
    WORKER_ID=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
    if [[ ! "$WORKER_ID" =~ engineer ]]; then
        WORKER_INDICES+=($i)
    fi
done

if [ $SESSIONS_NEEDED -gt 1 ]; then
    echo -e "${BLUE}👷 ${WORKER_COUNT} workers - creating ${SESSIONS_NEEDED} tmux sessions (max 10 windows each)${NC}"
else
    echo -e "${BLUE}👷 Creating ${WORKER_COUNT} worker windows${NC}"
fi
echo ""

# Create sessions
for session_num in $(seq 1 $SESSIONS_NEEDED); do
    if [ $SESSIONS_NEEDED -gt 1 ]; then
        CURRENT_SESSION="${SESSION_NAME}-${session_num}"
    else
        CURRENT_SESSION="${SESSION_NAME}"
    fi

    # Check if session already exists
    if tmux has-session -t "$CURRENT_SESSION" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Session already exists: ${CURRENT_SESSION}${NC}"
        echo "   Kill it first: tmux kill-session -t ${CURRENT_SESSION}"
        exit 1
    fi

    # Create new tmux session
    echo -e "${GREEN}📦 Creating session: ${CURRENT_SESSION}${NC}"
    if ! tmux new-session -d -s "$CURRENT_SESSION" -n "orchestrator" 2>/dev/null; then
        echo -e "${RED}❌ Failed to create tmux session${NC}"
        echo "   Try: tmux kill-server && czarina launch"
        exit 1
    fi

    # Give tmux a moment to fully initialize
    sleep 0.5

    # Set up orchestrator window
    tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "cd ${PROJECT_ROOT}" C-m
    tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo '🎯 Czarina Orchestrator - ${PROJECT_NAME}'" C-m
    if [ $SESSIONS_NEEDED -gt 1 ]; then
        tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo '   Session ${session_num} of ${SESSIONS_NEEDED}'" C-m
    fi
    tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo ''" C-m
    tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo 'Workers:'" C-m

    # Calculate worker range for this session
    START_IDX=$(( (session_num - 1) * MAX_WINDOWS_PER_SESSION ))
    END_IDX=$(( session_num * MAX_WINDOWS_PER_SESSION - 1 ))
    if [ $END_IDX -ge $WORKER_COUNT ]; then
        END_IDX=$((WORKER_COUNT - 1))
    fi

    # Create a window for each worker in this session (using sorted indices)
    for idx in $(seq $START_IDX $END_IDX); do
        i=${WORKER_INDICES[$idx]}
    WORKER_ID=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
    WORKER_AGENT=$(jq -r ".workers[$i].agent" "$CONFIG_FILE")
    WORKER_DESC=$(jq -r ".workers[$i].description" "$CONFIG_FILE")
    WORKER_BRANCH=$(jq -r ".workers[$i].branch" "$CONFIG_FILE")
    WORKER_FILE="${CZARINA_DIR}/workers/${WORKER_ID}.md"

    if [ ! -f "$WORKER_FILE" ]; then
        echo -e "${RED}⚠️  Worker file not found: ${WORKER_FILE}${NC}"
        continue
    fi

        echo "   • ${WORKER_ID} (${WORKER_AGENT})"

        # Create or reuse git worktree for this worker's branch
        WORKER_DIR="${WORKTREES_DIR}/${WORKER_ID}"
        if [ -n "$WORKER_BRANCH" ] && [ "$WORKER_BRANCH" != "null" ]; then
            # Check if worktree already exists
            if [ ! -d "$WORKER_DIR" ]; then
                echo "      Creating worktree: ${WORKER_DIR} on branch ${WORKER_BRANCH}..."
                cd "$PROJECT_ROOT"

                # Check if branch is currently checked out (can't create worktree for it)
                CURRENT_BRANCH=$(git branch --show-current)
                if [ "$CURRENT_BRANCH" = "$WORKER_BRANCH" ]; then
                    echo "      ⚠️  Branch ${WORKER_BRANCH} is currently checked out"
                    echo "      Using main project directory instead"
                    WORKER_DIR="$PROJECT_ROOT"
                else
                    if git worktree add "$WORKER_DIR" "$WORKER_BRANCH" 2>&1; then
                        echo "      ✅ Worktree created"
                    elif git worktree add -b "$WORKER_BRANCH" "$WORKER_DIR" 2>&1; then
                        echo "      ✅ Worktree created (new branch)"
                    else
                        echo "      ⚠️  Failed to create worktree for ${WORKER_BRANCH}"
                        echo "      Run 'git worktree list' to debug"
                        WORKER_DIR="$PROJECT_ROOT"
                    fi
                fi
            fi
        else
            # No branch specified, use main project directory
            WORKER_DIR="$PROJECT_ROOT"
        fi

        # Create window for this worker
        tmux new-window -t "${CURRENT_SESSION}" -n "${WORKER_ID}"
        tmux send-keys -t "${CURRENT_SESSION}:${WORKER_ID}" "cd ${WORKER_DIR}" C-m
        sleep 0.2

        # Display ALL worker info in ONE command (cleaner for humans to read)
        tmux send-keys -t "${CURRENT_SESSION}:${WORKER_ID}" "clear && cat <<'WORKER_HEADER'
═══════════════════════════════════════════════════════════════
🤖 Worker: ${WORKER_ID}
📋 Role: ${WORKER_DESC}
🔧 Agent: ${WORKER_AGENT}
🌿 Branch: ${WORKER_BRANCH}
📁 Worktree: ${WORKER_DIR}
═══════════════════════════════════════════════════════════════

WORKER_HEADER
cat '${WORKER_FILE}'
cat <<'WORKER_FOOTER'

═══════════════════════════════════════════════════════════════

📄 Your instructions: .czarina/workers/${WORKER_ID}.md
📁 Working directory: ${WORKER_DIR}
🌿 Branch: ${WORKER_BRANCH}

✅ Ready to begin! Read your instructions above and start implementing.

WORKER_FOOTER
" C-m

        # Add to orchestrator window list
        tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo '  • ${WORKER_ID} - ${WORKER_DESC}'" C-m
    done

    # Finish orchestrator window for this session
    tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo ''" C-m
    tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo '📝 Commands:'" C-m
    tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo '   • Switch windows: Ctrl+b <number>'" C-m
    tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo '   • List windows: Ctrl+b w'" C-m
    tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo '   • Detach: Ctrl+b d'" C-m
    if [ $SESSIONS_NEEDED -gt 1 ]; then
        tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo '   • Switch sessions: tmux switch -t czarina-v047-<num>'" C-m
    fi
    tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo '   • Attach: tmux attach -t ${CURRENT_SESSION}'" C-m
    tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo ''" C-m
    tmux send-keys -t "${CURRENT_SESSION}:orchestrator" "echo '✅ All workers ready!'" C-m
done

echo ""
echo -e "${GREEN}✅ Project launched successfully!${NC}"
echo ""
if [ $SESSIONS_NEEDED -gt 1 ]; then
    echo "📺 Attach to sessions:"
    for session_num in $(seq 1 $SESSIONS_NEEDED); do
        echo "   tmux attach -t ${SESSION_NAME}-${session_num}"
    done
else
    echo "📺 Attach to session:"
    echo "   tmux attach -t ${SESSION_NAME}"
fi
echo ""
echo "📋 Switch between workers with: Ctrl+b <window-number>"
if [ $SESSIONS_NEEDED -gt 1 ]; then
    echo "📋 Switch between sessions: tmux switch -t ${SESSION_NAME}-<num>"
fi
echo "🔄 Detach with: Ctrl+b d"
echo ""
