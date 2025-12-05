#!/bin/bash
# Czarina Project Closeout
# Cleanly shut down all workers, archive sessions, and clean up worktrees

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

echo -e "${BLUE}🎭 Czarina Project Closeout${NC}"
echo "   Project: $PROJECT_NAME"
echo "   Slug: $PROJECT_SLUG"
echo "   Root: $PROJECT_ROOT"
echo ""

# Ask for confirmation
read -p "Are you sure you want to close out this orchestration? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Closeout cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Starting closeout process...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 1. Find and kill tmux sessions
echo -e "${YELLOW}1. Stopping tmux sessions...${NC}"
SESSIONS_FOUND=0

# Find all czarina sessions for this project
for session in $(tmux list-sessions -F "#{session_name}" 2>/dev/null || echo ""); do
    if [[ "$session" =~ czarina.*memory ]] || [[ "$session" =~ $PROJECT_SLUG ]]; then
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

# 3. Archive session logs if they exist
echo -e "${YELLOW}3. Archiving logs...${NC}"
ARCHIVE_DIR="${CZARINA_DIR}/archive/$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$ARCHIVE_DIR"

if [ -d "${CZARINA_DIR}/status" ]; then
    cp -r "${CZARINA_DIR}/status" "$ARCHIVE_DIR/" 2>/dev/null || true
    echo -e "   ${GREEN}✅ Logs archived to: $ARCHIVE_DIR${NC}"
else
    echo "   No logs to archive"
fi
echo ""

# 4. Ask about worktree cleanup
echo -e "${YELLOW}4. Git worktrees cleanup...${NC}"
if [ -d "$WORKTREES_DIR" ]; then
    WORKTREE_COUNT=$(ls -1 "$WORKTREES_DIR" 2>/dev/null | wc -l)
    echo "   Found $WORKTREE_COUNT worktree(s)"

    read -p "   Remove all worktrees? This will delete worker workspaces (y/N): " remove_worktrees

    if [[ "$remove_worktrees" =~ ^[Yy]$ ]]; then
        echo "   Removing worktrees..."
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
        git worktree prune

        # Remove worktrees directory
        rmdir "$WORKTREES_DIR" 2>/dev/null || rm -rf "$WORKTREES_DIR"

        echo -e "   ${GREEN}✅ All worktrees removed${NC}"
    else
        echo "   Keeping worktrees (you can remove them later with: git worktree prune)"
    fi
else
    echo "   No worktrees directory found"
fi
echo ""

# 5. Generate final status report
echo -e "${YELLOW}5. Generating final status report...${NC}"
REPORT_FILE="${ARCHIVE_DIR}/CLOSEOUT_REPORT.md"

cat > "$REPORT_FILE" <<REPORT
# Czarina Closeout Report - ${PROJECT_NAME}

**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Project:** ${PROJECT_NAME}
**Slug:** ${PROJECT_SLUG}
**Location:** ${PROJECT_ROOT}

## Summary

This orchestration has been closed out. All tmux sessions stopped, daemon halted, and logs archived.

## Sessions Stopped

- Worker sessions: ${SESSIONS_FOUND}
- Daemon: $([ -n "$(tmux has-session -t "$DAEMON_SESSION" 2>/dev/null && echo "yes")" ] && echo "Stopped" || echo "Was not running")

## Archives

- Location: ${ARCHIVE_DIR}
- Logs: $([ -d "${ARCHIVE_DIR}/status" ] && echo "Archived" || echo "None")

## Worktrees

- Initial count: ${WORKTREE_COUNT:-0}
- Status: $([ "$remove_worktrees" = "y" ] || [ "$remove_worktrees" = "Y" ] && echo "Removed" || echo "Kept")

## Git Status

\`\`\`
$(cd "$PROJECT_ROOT" && git status --short || echo "Not a git repository")
\`\`\`

## Workers

$(jq -r '.workers[] | "- \(.id): \(.description)"' "$CONFIG_FILE")

## Next Steps

1. Review archived logs in: ${ARCHIVE_DIR}
2. Merge any remaining PRs
3. Clean up branches if needed:
   \`\`\`bash
   git branch --merged | grep -v "\\*\\|main\\|master" | xargs -n 1 git branch -d
   \`\`\`
4. To restart orchestration: \`czarina launch\`

---

Generated by Czarina on $(date)
REPORT

echo -e "   ${GREEN}✅ Report saved: $REPORT_FILE${NC}"
echo ""

# 6. Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Closeout complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📋 Summary:${NC}"
echo "   • Sessions stopped: $SESSIONS_FOUND"
echo "   • Daemon: Stopped"
echo "   • Logs archived: $ARCHIVE_DIR"
echo "   • Worktrees: $([ "$remove_worktrees" = "y" ] || [ "$remove_worktrees" = "Y" ] && echo "Removed" || echo "Kept")"
echo ""
echo -e "${CYAN}📄 Full report: $REPORT_FILE${NC}"
echo ""
echo -e "${YELLOW}💡 To restart orchestration:${NC}"
echo "   czarina launch"
echo ""
