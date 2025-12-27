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
PHASE=$(jq -r '.project.phase // 1' "$CONFIG_FILE")
VERSION=$(jq -r '.project.version' "$CONFIG_FILE")
WORKTREES_DIR="${PROJECT_ROOT}/.czarina/worktrees"

# Check for flags
KEEP_WORKTREES=false
FORCE_CLEAN=false

for arg in "$@"; do
    case $arg in
        --keep-worktrees) KEEP_WORKTREES=true ;;
        --force-clean) FORCE_CLEAN=true ;;
    esac
done

echo -e "${BLUE}🎭 Czarina Phase Close${NC}"
echo "   Project: $PROJECT_NAME"
echo "   Phase: $PHASE"
echo "   Slug: $PROJECT_SLUG"
echo ""

# Create phase archive directory with phase and version
PHASE_DIR="${CZARINA_DIR}/phases/phase-${PHASE}-v${VERSION}"
mkdir -p "$PHASE_DIR"

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

echo "📁 Archiving phase data to: $PHASE_DIR"

# Copy config snapshot
cp "$CONFIG_FILE" "$PHASE_DIR/config.json"

# Archive logs if they exist
if [ -d "${CZARINA_DIR}/logs" ]; then
    mkdir -p "$PHASE_DIR/logs"
    cp -r "${CZARINA_DIR}/logs"/* "$PHASE_DIR/logs/" 2>/dev/null || true
fi

# Archive worker statuses
if [ -d "${CZARINA_DIR}/status" ]; then
    cp -r "${CZARINA_DIR}/status" "$PHASE_DIR/status" 2>/dev/null || true
fi

# Archive worker prompts
if [ -d "${CZARINA_DIR}/workers" ]; then
    cp -r "${CZARINA_DIR}/workers" "$PHASE_DIR/workers" 2>/dev/null || true
fi

# Create phase summary
cat > "$PHASE_DIR/PHASE_SUMMARY.md" <<EOF
# Phase $PHASE Summary
**Version:** v${VERSION}
**Completed:** $(date -Iseconds)

## Configuration

\`\`\`json
$(cat "$CONFIG_FILE")
\`\`\`

## Workers

$(jq -r '.workers[] | "- \(.id): \(.description)"' "$CONFIG_FILE")

## Branches

**Omnibus:** $(jq -r '.project.omnibus_branch' "$CONFIG_FILE")

**Worker Branches:**
$(jq -r '.workers[] | "- \(.branch) (\(.id))"' "$CONFIG_FILE")

## Status

Phase closed on $(date '+%Y-%m-%d %H:%M:%S')

See logs/ directory for detailed activity logs.
EOF

echo -e "   ${GREEN}✅ Phase data archived: $PHASE_DIR${NC}"
echo ""

# 4. Smart worktree cleanup
echo -e "${YELLOW}4. Smart worktree cleanup...${NC}"

if [ "$KEEP_WORKTREES" = true ]; then
    echo "   ⏭️  Keeping all worktrees (--keep-worktrees flag)"
elif [ -d "$WORKTREES_DIR" ]; then
    echo "   🔍 Checking worktrees for uncommitted changes..."

    CLEAN_COUNT=0
    DIRTY_COUNT=0

    cd "$PROJECT_ROOT"

    for worktree in "$WORKTREES_DIR"/*; do
        if [ ! -d "$worktree" ]; then
            continue
        fi

        worker_id=$(basename "$worktree")
        cd "$worktree"

        # Check for uncommitted changes
        if git diff --quiet && git diff --cached --quiet; then
            # Clean worktree
            echo "      ✅ $worker_id: Clean (removing)"
            cd "$PROJECT_ROOT"
            git worktree remove "$worktree" 2>/dev/null || {
                if [ "$FORCE_CLEAN" = true ]; then
                    git worktree remove --force "$worktree"
                else
                    echo "         ⚠️  Failed to remove (use --force-clean to override)"
                    ((DIRTY_COUNT++))
                    continue
                fi
            }
            ((CLEAN_COUNT++))
        else
            # Dirty worktree
            if [ "$FORCE_CLEAN" = true ]; then
                echo "      🗑️  $worker_id: Has changes (removing anyway - forced)"
                cd "$PROJECT_ROOT"
                git worktree remove --force "$worktree"
                ((CLEAN_COUNT++))
            else
                echo "      ⚠️  $worker_id: Has uncommitted changes (keeping)"
                ((DIRTY_COUNT++))
            fi
        fi

        cd "$PROJECT_ROOT"
    done

    echo ""
    echo "   📦 Removed $CLEAN_COUNT worktree(s), kept $DIRTY_COUNT with changes"

    if [ $DIRTY_COUNT -gt 0 ]; then
        echo ""
        echo "   ⚠️  Warning: $DIRTY_COUNT worktree(s) have uncommitted changes"
        echo "      Review before next phase:"
        for worktree in "$WORKTREES_DIR"/*; do
            if [ -d "$worktree" ]; then
                echo "        git -C $worktree status"
            fi
        done
    fi

    # Prune worktree references
    git worktree prune

    # Remove worktrees directory if empty
    if [ -d "$WORKTREES_DIR" ] && [ -z "$(ls -A "$WORKTREES_DIR")" ]; then
        rmdir "$WORKTREES_DIR"
    fi
else
    echo "   No worktrees directory found"
fi
echo ""

# 5. Clear phase artifacts (already archived)
echo -e "${YELLOW}5. Clearing phase artifacts...${NC}"

# Clear config (already archived)
if [ -f "${CZARINA_DIR}/config.json" ]; then
    rm -f "${CZARINA_DIR}/config.json"
    echo "   ✅ Config cleared"
fi

# Clear workers (already archived)
if [ -d "${CZARINA_DIR}/workers" ]; then
    rm -rf "${CZARINA_DIR}/workers"/*
    echo "   ✅ Worker prompts cleared"
fi

# Clear status
if [ -d "${CZARINA_DIR}/status" ]; then
    rm -rf "${CZARINA_DIR}/status"/*
    echo "   ✅ Status cleared"
fi

echo -e "   ${GREEN}✅ Phase cleared, ready for next phase${NC}"
echo ""

# 6. Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Phase $PHASE closeout complete${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📦 Phase archived to: .czarina/phases/phase-${PHASE}-v${VERSION}"
echo "   ✅ Complete history preserved"
echo ""
echo "📋 Next steps:"
echo "   1. Initialize next phase:"
echo "      czarina init --from-config <next-phase-config.json>"
echo "      OR: czarina analyze docs/next-plan.md --interactive --init"
echo ""
echo "   2. Launch new workers:"
echo "      czarina launch"
echo ""
