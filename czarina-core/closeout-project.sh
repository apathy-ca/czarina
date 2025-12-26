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
# Look for both old naming (czarina-memory*) and new naming (czarina-{slug}*)
for session in $(tmux list-sessions -F "#{session_name}" 2>/dev/null || echo ""); do
    if [[ "$session" =~ czarina.*memory ]] || [[ "$session" =~ czarina-${PROJECT_SLUG} ]] || [[ "$session" =~ ${PROJECT_SLUG} ]]; then
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

# 5. Generate comprehensive closeout report
echo -e "${YELLOW}5. Generating comprehensive closeout report...${NC}"
REPORT_FILE="${ARCHIVE_DIR}/CLOSEOUT.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/templates/CLOSEOUT.md"

cd "$PROJECT_ROOT"

# Get version from git tag or default
CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")

# Calculate orchestration duration
if [ -f "${CZARINA_DIR}/status/orchestration-start.timestamp" ]; then
    START_TIMESTAMP=$(cat "${CZARINA_DIR}/status/orchestration-start.timestamp")
    END_TIMESTAMP=$(date +%s)
    DURATION_SECONDS=$((END_TIMESTAMP - START_TIMESTAMP))
    DURATION_HOURS=$((DURATION_SECONDS / 3600))
    DURATION_MINUTES=$(((DURATION_SECONDS % 3600) / 60))
    DURATION="${DURATION_HOURS}h ${DURATION_MINUTES}m"
    START_TIME=$(date -d "@${START_TIMESTAMP}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "${START_TIMESTAMP}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "Unknown")
else
    DURATION="Unknown"
    START_TIME="Unknown"
fi

# Get orchestration end time
END_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Collect worker branches and stats
WORKER_IDS=$(jq -r '.workers[].id' "$CONFIG_FILE")
WORKER_COUNT=$(echo "$WORKER_IDS" | wc -l)

# Collect git statistics
TOTAL_COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "0")
ALL_COMMITS=$(git log --oneline --all --decorate -50 2>/dev/null || echo "No commits")
GIT_STATUS=$(git status --short 2>/dev/null || echo "Not a git repository")
GIT_LOG=$(git log --oneline -50 2>/dev/null || echo "No commits")

# Calculate lines changed
LINES_ADDED=$(git diff --shortstat main...HEAD 2>/dev/null | grep -oP '\d+(?= insertion)' || echo "0")
LINES_REMOVED=$(git diff --shortstat main...HEAD 2>/dev/null | grep -oP '\d+(?= deletion)' || echo "0")
FILES_CHANGED=$(git diff --name-only main...HEAD 2>/dev/null | wc -l || echo "0")

# Build worker summaries
WORKER_SUMMARIES=""
COMMITS_BY_WORKER=""
FILES_BY_WORKER=""

for worker_id in $WORKER_IDS; do
    # Find branches for this worker
    WORKER_BRANCHES=$(git branch -a | grep -E "feat.*${worker_id}|${worker_id}" | sed 's/^[ *]*//' | sed 's/remotes\/origin\///' | sort -u || echo "")

    if [ -n "$WORKER_BRANCHES" ]; then
        WORKER_SUMMARIES="${WORKER_SUMMARIES}### Worker: ${worker_id}

**Branches:**
"
        for branch in $WORKER_BRANCHES; do
            WORKER_SUMMARIES="${WORKER_SUMMARIES}- \`${branch}\`
"

            # Get commit count for this branch
            BRANCH_COMMIT_COUNT=$(git rev-list --count "$branch" 2>/dev/null || echo "0")

            # Get commits for this branch
            BRANCH_COMMITS=$(git log --oneline "$branch" --not main 2>/dev/null | head -20 || echo "No commits")

            COMMITS_BY_WORKER="${COMMITS_BY_WORKER}#### ${worker_id} - \`${branch}\`

Commits: ${BRANCH_COMMIT_COUNT}

\`\`\`
${BRANCH_COMMITS}
\`\`\`

"

            # Get files changed in this branch
            BRANCH_FILES=$(git diff --name-only main..."$branch" 2>/dev/null | head -30 || echo "")
            if [ -n "$BRANCH_FILES" ]; then
                FILES_BY_WORKER="${FILES_BY_WORKER}#### ${worker_id} - \`${branch}\`

\`\`\`
${BRANCH_FILES}
\`\`\`

"
            fi
        done

        WORKER_SUMMARIES="${WORKER_SUMMARIES}
"
    else
        WORKER_SUMMARIES="${WORKER_SUMMARIES}### Worker: ${worker_id}

**Status:** No branches found

"
    fi
done

# Get all files changed
ALL_FILES_CHANGED=$(git diff --name-status main...HEAD 2>/dev/null | head -50 || echo "No changes")

# Get branch status
BRANCH_STATUS=$(git branch -a 2>/dev/null | head -20 || echo "No branches")

# Get workers config
WORKERS_CONFIG=$(jq -r '.workers[] | "### \(.id)\n- **Role:** \(.description)\n- **Agent:** \(.agent // "claude-code")\n"' "$CONFIG_FILE")

# Get config JSON (prettified)
CONFIG_JSON=$(jq '.' "$CONFIG_FILE" 2>/dev/null || echo "{}")

# Tmux sessions info
TMUX_SESSIONS="Sessions stopped: ${SESSIONS_FOUND}"

# Daemon status
DAEMON_STATUS=$([ -n "$(tmux has-session -t "$DAEMON_SESSION" 2>/dev/null && echo "yes")" ] && echo "Stopped" || echo "Was not running")

# Worktree details
if [ -d "$WORKTREES_DIR" ]; then
    WORKTREE_DETAILS=$(ls -la "$WORKTREES_DIR" 2>/dev/null || echo "No worktrees")
    WORKTREES_STATUS="Initial count: ${WORKTREE_COUNT:-0}, Status: $([ "$remove_worktrees" = "y" ] || [ "$remove_worktrees" = "Y" ] && echo "Removed" || echo "Kept")"
else
    WORKTREE_DETAILS="No worktrees directory found"
    WORKTREES_STATUS="No worktrees"
fi

# Logs status
LOGS_STATUS=$([ -d "${ARCHIVE_DIR}/status" ] && echo "Archived" || echo "None")

# Generate report from template
if [ -f "$TEMPLATE_FILE" ]; then
    cp "$TEMPLATE_FILE" "$REPORT_FILE"

    # Replace all placeholders
    sed -i "s|{PROJECT_NAME}|${PROJECT_NAME}|g" "$REPORT_FILE"
    sed -i "s|{VERSION}|${CURRENT_VERSION}|g" "$REPORT_FILE"
    sed -i "s|{CLOSEOUT_DATE}|$(date '+%Y-%m-%d')|g" "$REPORT_FILE"
    sed -i "s|{DURATION}|${DURATION}|g" "$REPORT_FILE"
    sed -i "s|{ORCHESTRATION_ID}|${PROJECT_SLUG}|g" "$REPORT_FILE"
    sed -i "s|{SUMMARY}|This orchestration has been closed out. All tmux sessions stopped, daemon halted, and logs archived.|g" "$REPORT_FILE"
    sed -i "s|{WORKER_COUNT}|${WORKER_COUNT}|g" "$REPORT_FILE"
    sed -i "s|{TOTAL_COMMITS}|${TOTAL_COMMITS}|g" "$REPORT_FILE"
    sed -i "s|{FILES_CHANGED}|${FILES_CHANGED}|g" "$REPORT_FILE"
    sed -i "s|{LINES_ADDED}|${LINES_ADDED}|g" "$REPORT_FILE"
    sed -i "s|{LINES_REMOVED}|${LINES_REMOVED}|g" "$REPORT_FILE"
    sed -i "s|{START_TIME}|${START_TIME}|g" "$REPORT_FILE"
    sed -i "s|{END_TIME}|${END_TIME}|g" "$REPORT_FILE"
    sed -i "s|{ARCHIVE_DIR}|${ARCHIVE_DIR}|g" "$REPORT_FILE"
    sed -i "s|{LOGS_STATUS}|${LOGS_STATUS}|g" "$REPORT_FILE"
    sed -i "s|{WORKTREES_STATUS}|${WORKTREES_STATUS}|g" "$REPORT_FILE"
    sed -i "s|{TMUX_SESSIONS}|${TMUX_SESSIONS}|g" "$REPORT_FILE"
    sed -i "s|{DAEMON_STATUS}|${DAEMON_STATUS}|g" "$REPORT_FILE"
    sed -i "s|{CZARINA_VERSION}|$(cat "${SCRIPT_DIR}/version.sh" 2>/dev/null | grep VERSION | cut -d'=' -f2 | tr -d '"' || echo "0.6.0")|g" "$REPORT_FILE"
    sed -i "s|{REPORT_TIME}|$(date '+%Y-%m-%d %H:%M:%S')|g" "$REPORT_FILE"
    sed -i "s|{LESSONS_LEARNED}|See archived logs and commit messages for insights.|g" "$REPORT_FILE"

    # Replace multi-line placeholders using a more robust method
    # We'll create a temporary file with the processed content
    awk -v workers="$WORKER_SUMMARIES" '{gsub(/{WORKER_SUMMARIES}/, workers)}1' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
    awk -v commits="$COMMITS_BY_WORKER" '{gsub(/{COMMITS_BY_WORKER}/, commits)}1' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
    awk -v files="$FILES_BY_WORKER" '{gsub(/{FILES_BY_WORKER}/, files)}1' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
    awk -v all_files="$ALL_FILES_CHANGED" '{gsub(/{ALL_FILES_CHANGED}/, all_files)}1' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
    awk -v all_commits="$ALL_COMMITS" '{gsub(/{ALL_COMMITS}/, all_commits)}1' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
    awk -v branch_status="$BRANCH_STATUS" '{gsub(/{BRANCH_STATUS}/, branch_status)}1' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
    awk -v git_status="$GIT_STATUS" '{gsub(/{GIT_STATUS}/, git_status)}1' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
    awk -v git_log="$GIT_LOG" '{gsub(/{GIT_LOG}/, git_log)}1' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
    awk -v config="$CONFIG_JSON" '{gsub(/{CONFIG_JSON}/, config)}1' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
    awk -v workers_cfg="$WORKERS_CONFIG" '{gsub(/{WORKERS_CONFIG}/, workers_cfg)}1' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
    awk -v worktree_details="$WORKTREE_DETAILS" '{gsub(/{WORKTREE_DETAILS}/, worktree_details)}1' "$REPORT_FILE" > "${REPORT_FILE}.tmp" && mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
else
    # Fallback to basic report if template not found
    cat > "$REPORT_FILE" <<REPORT
# Czarina Closeout Report - ${PROJECT_NAME}

**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Project:** ${PROJECT_NAME}
**Version:** ${CURRENT_VERSION}
**Duration:** ${DURATION}

## Summary

This orchestration has been closed out. All tmux sessions stopped, daemon halted, and logs archived.

## Workers

${WORKER_SUMMARIES}

## Commits by Worker

${COMMITS_BY_WORKER}

## Files Changed

${FILES_BY_WORKER}

---

Generated by Czarina on $(date)
REPORT
fi

echo -e "   ${GREEN}✅ Comprehensive report saved: $REPORT_FILE${NC}"
echo ""

# 6. Archive to phases directory
echo -e "${YELLOW}6. Archiving to phases directory...${NC}"
PHASES_DIR="${CZARINA_DIR}/phases"
PHASE_NAME="phase-1-${CURRENT_VERSION}"
PHASE_ARCHIVE="${PHASES_DIR}/${PHASE_NAME}"

mkdir -p "$PHASE_ARCHIVE"

# Copy the closeout report to phase archive
cp "$REPORT_FILE" "${PHASE_ARCHIVE}/CLOSEOUT.md" 2>/dev/null || true

# Copy logs to phase archive
if [ -d "${ARCHIVE_DIR}/status" ]; then
    cp -r "${ARCHIVE_DIR}/status" "${PHASE_ARCHIVE}/logs" 2>/dev/null || true
fi

# Copy config to phase archive
cp "$CONFIG_FILE" "${PHASE_ARCHIVE}/config.json" 2>/dev/null || true

# Create a phase summary file
cat > "${PHASE_ARCHIVE}/PHASE_SUMMARY.md" <<PHASE
# Phase Summary: ${PHASE_NAME}

**Project:** ${PROJECT_NAME}
**Version:** ${CURRENT_VERSION}
**Duration:** ${DURATION}
**Completed:** $(date '+%Y-%m-%d %H:%M:%S')

## Quick Stats

- Workers: ${WORKER_COUNT}
- Total Commits: ${TOTAL_COMMITS}
- Files Changed: ${FILES_CHANGED}
- Lines Added: ${LINES_ADDED}
- Lines Removed: ${LINES_REMOVED}

## Archive Contents

- \`CLOSEOUT.md\` - Full closeout report
- \`PHASE_SUMMARY.md\` - This summary
- \`config.json\` - Project configuration
- \`logs/\` - Archived orchestration logs

## Full Report

See [CLOSEOUT.md](./CLOSEOUT.md) for complete details.

---

Generated on $(date)
PHASE

echo -e "   ${GREEN}✅ Phase archived to: $PHASE_ARCHIVE${NC}"
echo ""

# 7. Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Closeout complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📋 Summary:${NC}"
echo "   • Sessions stopped: $SESSIONS_FOUND"
echo "   • Daemon: Stopped"
echo "   • Logs archived: $ARCHIVE_DIR"
echo "   • Phase archived: $PHASE_ARCHIVE"
echo "   • Worktrees: $([ "$remove_worktrees" = "y" ] || [ "$remove_worktrees" = "Y" ] && echo "Removed" || echo "Kept")"
echo ""
echo -e "${CYAN}📄 Reports:${NC}"
echo "   • Full report: $REPORT_FILE"
echo "   • Phase summary: ${PHASE_ARCHIVE}/PHASE_SUMMARY.md"
echo ""
echo -e "${YELLOW}💡 To restart orchestration:${NC}"
echo "   czarina launch"
echo ""
