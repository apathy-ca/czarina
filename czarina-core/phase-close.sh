#!/bin/bash
# Czarina Phase Close
# Close current phase but keep project structure for next phase

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
    exit 1
fi

PROJECT_NAME=$(jq -r '.project.name' "$CONFIG_FILE")
PROJECT_SLUG=$(jq -r '.project.slug' "$CONFIG_FILE")
PROJECT_ROOT=$(jq -r '.project.repository' "$CONFIG_FILE")
WORKTREES_DIR="${PROJECT_ROOT}/.czarina/worktrees"

echo -e "${BLUE}🎭 Czarina Phase Close${NC}"
echo "   Project: $PROJECT_NAME"
echo "   Slug: $PROJECT_SLUG"
echo ""

# Create phase archive directory with timestamp
PHASE_TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
PHASE_ARCHIVE="${CZARINA_DIR}/phases/phase-${PHASE_TIMESTAMP}"
mkdir -p "$PHASE_ARCHIVE"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Closing current phase...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 1. Find and kill tmux sessions
echo -e "${YELLOW}1. Stopping tmux sessions...${NC}"
SESSIONS_FOUND=0

# Find all czarina sessions for this project
for session in $(tmux list-sessions -F "#{session_name}" 2>/dev/null || echo ""); do
    if [[ "$session" =~ czarina-${PROJECT_SLUG} ]] || [[ "$session" == "${PROJECT_SLUG}" ]]; then
        echo "   Stopping session: $session"
        tmux kill-session -t "$session" 2>/dev/null || true
        ((SESSIONS_FOUND++))
    fi
done

if [ $SESSIONS_FOUND -eq 0 ]; then
    echo "   No active sessions found"
else
    echo -e "   ${GREEN}✅ Stopped $SESSIONS_FOUND session(s)${NC}"
fi
echo ""

# 2. Stop daemon
echo -e "${YELLOW}2. Stopping daemon...${NC}"
DAEMON_SESSION="${PROJECT_SLUG}-daemon"
if tmux has-session -t "$DAEMON_SESSION" 2>/dev/null; then
    tmux kill-session -t "$DAEMON_SESSION" 2>/dev/null || true
    echo -e "   ${GREEN}✅ Daemon stopped${NC}"
else
    echo "   No daemon session found"
fi
echo ""

# 3. Archive current phase state
echo -e "${YELLOW}3. Archiving phase state...${NC}"

# Archive worker statuses
if [ -d "${CZARINA_DIR}/status" ]; then
    cp -r "${CZARINA_DIR}/status" "$PHASE_ARCHIVE/status" 2>/dev/null || true
    echo "   ✅ Worker status archived"
fi

# Archive current config (snapshot of this phase)
cp "$CONFIG_FILE" "$PHASE_ARCHIVE/config.json" 2>/dev/null || true
echo "   ✅ Config archived"

# Archive worker prompts (snapshot of this phase)
if [ -d "${CZARINA_DIR}/workers" ]; then
    cp -r "${CZARINA_DIR}/workers" "$PHASE_ARCHIVE/workers" 2>/dev/null || true
    echo "   ✅ Worker prompts archived"
fi

# Create phase summary
cat > "$PHASE_ARCHIVE/PHASE_SUMMARY.md" << EOF
# Phase Closed: $PHASE_TIMESTAMP

**Project:** $PROJECT_NAME
**Closed:** $(date)
**Workers:** $(jq -r '.workers | length' "$CONFIG_FILE")

## Workers in This Phase

$(jq -r '.workers[] | "- **\(.id)**: \(.description // "Worker") (Branch: \(.branch // "N/A"))"' "$CONFIG_FILE")

## Next Steps

This phase has been closed. To start a new phase:

1. Analyze new implementation plan:
   \`\`\`bash
   czarina analyze docs/next-phase-plan.md --interactive --init
   \`\`\`

2. Or manually update workers in .czarina/config.json

3. Launch new phase:
   \`\`\`bash
   czarina launch
   \`\`\`

## Archive Location

Phase state archived to: $PHASE_ARCHIVE
EOF

echo -e "   ${GREEN}✅ Phase archived to: phases/phase-${PHASE_TIMESTAMP}${NC}"
echo ""

# 4. Clean up worktrees
echo -e "${YELLOW}4. Cleaning up git worktrees...${NC}"
if [ -d "$WORKTREES_DIR" ]; then
    WORKTREE_COUNT=$(ls -1 "$WORKTREES_DIR" 2>/dev/null | wc -l)
    echo "   Found $WORKTREE_COUNT worktree(s)"

    cd "$PROJECT_ROOT"

    # Remove each worktree directory
    for worktree in "$WORKTREES_DIR"/*; do
        if [ -d "$worktree" ]; then
            worker_name=$(basename "$worktree")
            echo "      Removing $worker_name..."
            git worktree remove "$worktree" --force 2>/dev/null || rm -rf "$worktree"
        fi
    done

    # Prune stale references
    git worktree prune 2>/dev/null || true

    # Remove worktrees directory
    rmdir "$WORKTREES_DIR" 2>/dev/null || rm -rf "$WORKTREES_DIR"

    echo -e "   ${GREEN}✅ All worktrees removed${NC}"
else
    echo "   No worktrees directory found"
fi
echo ""

# 5. Clear worker status (keep structure)
echo -e "${YELLOW}5. Clearing worker status...${NC}"
if [ -d "${CZARINA_DIR}/status" ]; then
    rm -rf "${CZARINA_DIR}/status"/*
    echo -e "   ${GREEN}✅ Status cleared${NC}"
else
    echo "   No status to clear"
fi
echo ""

# 6. Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Phase closed successfully!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📦 Project structure preserved:"
echo "   ✅ .czarina/config.json (edit for next phase)"
echo "   ✅ .czarina/workers/ (edit or regenerate for next phase)"
echo "   ✅ Phase archived: phases/phase-${PHASE_TIMESTAMP}"
echo ""
echo "📋 Next steps:"
echo "   1. Update .czarina/config.json for next phase (or re-analyze)"
echo "   2. Update worker prompts if needed"
echo "   3. czarina launch (starts next phase)"
echo ""
echo "💡 To start a completely new phase from a new plan:"
echo "   czarina analyze docs/new-plan.md --interactive --init"
echo ""
