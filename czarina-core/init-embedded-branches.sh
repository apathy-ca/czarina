#!/bin/bash
# Initialize czarina worker branches with phase naming
# This ensures workers have clean branches ready to go

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage
usage() {
    cat <<EOF
${BLUE}Czarina Branch Initialization${NC}

Initialize git branches for all workers defined in embedded orchestration.

Usage: $0 <project-dir>

Example:
  $0 /home/theseus/thesymposium
  $0 ../myproject

This script will:
  1. Find .czarina/ orchestration directory
  2. Read config.json for worker definitions
  3. Read phase number from config
  4. Create git branches for each worker (cz<phase>/feat/<worker-id>)
  5. Push branches to remote (if remote exists)

EOF
    exit 0
}

# Check for help
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]] || [[ $# -eq 0 ]]; then
    usage
fi

PROJECT_DIR="${1:-.}"

# Find orchestration directory
CZARINA_DIR=$(find "$PROJECT_DIR" -maxdepth 1 -type d -name ".czarina" 2>/dev/null | head -1)

if [ -z "$CZARINA_DIR" ]; then
    echo -e "${RED}❌ No .czarina directory found in $PROJECT_DIR${NC}"
    echo -e "${YELLOW}💡 Tip: Run 'czarina embed' first to create orchestration${NC}"
    exit 1
fi

CONFIG_FILE="$CZARINA_DIR/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is required but not installed${NC}"
    echo -e "${YELLOW}Install with: sudo apt install jq${NC}"
    exit 1
fi

# Parse config
PROJECT_NAME=$(jq -r '.project.name' "$CONFIG_FILE")
REPO_DIR=$(jq -r '.project.repository' "$CONFIG_FILE")
OMNIBUS_BRANCH=$(jq -r '.project.omnibus_branch // "main"' "$CONFIG_FILE")
ORCHESTRATION_MODE=$(jq -r '.orchestration.mode // "local"' "$CONFIG_FILE")
AUTO_PUSH=$(jq -r '.orchestration.auto_push_branches // false' "$CONFIG_FILE")

# Read phase number from config (default to 1 if not set)
PHASE=$(jq -r '.project.phase // 1' "$CONFIG_FILE")

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Git Branch Initialization for Workers             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${BLUE}Project:${NC}     $PROJECT_NAME"
echo -e "${BLUE}Repository:${NC}  $REPO_DIR"
echo -e "${BLUE}Phase:${NC}       $PHASE"
echo -e "${BLUE}Config:${NC}      $CONFIG_FILE"
echo ""

# Verify git repository
if [ ! -d "$REPO_DIR/.git" ]; then
    echo -e "${RED}❌ Not a git repository: $REPO_DIR${NC}"
    exit 1
fi

cd "$REPO_DIR"

# Get current branch
ORIGINAL_BRANCH=$(git branch --show-current)

# Ensure we're on main and up to date
echo -e "${YELLOW}📥 Checking main branch...${NC}"
MAIN_BRANCH="main"
if ! git show-ref --verify --quiet refs/heads/main; then
    if git show-ref --verify --quiet refs/heads/master; then
        MAIN_BRANCH="master"
    else
        echo -e "${RED}❌ No main or master branch found${NC}"
        exit 1
    fi
fi

git checkout "$MAIN_BRANCH" 2>/dev/null
echo -e "${GREEN}✓ On $MAIN_BRANCH branch${NC}"

# Check if we have a remote
HAS_REMOTE=false
if git remote | grep -q "origin"; then
    HAS_REMOTE=true
    echo -e "${GREEN}✓ Remote 'origin' detected${NC}"

    # Offer to pull latest
    read -p "Pull latest from origin/$MAIN_BRANCH? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        git pull origin "$MAIN_BRANCH" || echo -e "${YELLOW}⚠️  Pull failed, continuing anyway${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No remote 'origin' found (local repo only)${NC}"
fi

echo ""
echo -e "${YELLOW}🌿 Initializing worker branches...${NC}"
echo ""

# Track stats
BRANCHES_CREATED=0
BRANCHES_EXISTS=0

# Read workers from config.json
WORKER_COUNT=$(jq '.workers | length' "$CONFIG_FILE")

for ((i=0; i<$WORKER_COUNT; i++)); do
    worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
    branch=$(jq -r ".workers[$i].branch" "$CONFIG_FILE")
    description=$(jq -r ".workers[$i].description" "$CONFIG_FILE")
    worker_role=$(jq -r ".workers[$i].role // \"worker\"" "$CONFIG_FILE")

    echo -e "${BLUE}→ Processing:${NC} $worker_id"
    echo -e "  ${BLUE}Branch:${NC}      $branch"
    echo -e "  ${BLUE}Description:${NC} $description"

    # VALIDATION: Non-integration workers CANNOT work on omnibus branch
    if [ "$branch" == "$OMNIBUS_BRANCH" ] && [ "$worker_role" != "integration" ]; then
        echo -e "  ${RED}❌ ERROR: Worker '$worker_id' cannot work on omnibus branch '$OMNIBUS_BRANCH'${NC}"
        echo -e "  ${YELLOW}💡 Only workers with role='integration' can use the omnibus branch${NC}"
        echo -e "  ${YELLOW}💡 Omnibus is for integration/release only, not feature work${NC}"
        exit 1
    fi

    # Check if branch exists locally
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        echo -e "  ${YELLOW}Status:${NC} Branch already exists locally"

        # Check if it has commits different from main
        COMMITS_AHEAD=$(git rev-list --count ${MAIN_BRANCH}..$branch 2>/dev/null || echo "0")

        if [ "$COMMITS_AHEAD" -gt 0 ]; then
            echo -e "  ${YELLOW}⚠️  Branch has $COMMITS_AHEAD commit(s) ahead of $MAIN_BRANCH${NC}"
            echo -e "  ${GREEN}Keeping existing branch (has work)${NC}"
            BRANCHES_EXISTS=$((BRANCHES_EXISTS + 1))
        else
            echo -e "  ${GREEN}✓ Branch exists with no unique commits${NC}"
            BRANCHES_EXISTS=$((BRANCHES_EXISTS + 1))
        fi
    else
        # Check if branch exists on remote
        if $HAS_REMOTE && git ls-remote --heads origin "$branch" | grep -q "$branch"; then
            echo -e "  ${YELLOW}Status:${NC} Branch exists on remote, checking out..."
            git checkout -b "$branch" "origin/$branch"
            git checkout "$MAIN_BRANCH"
            echo -e "  ${GREEN}✓ Branch checked out from remote${NC}"
            BRANCHES_EXISTS=$((BRANCHES_EXISTS + 1))
        else
            # Create new branch
            echo -e "  ${YELLOW}Status:${NC} Creating new branch..."
            git checkout -b "$branch" "$MAIN_BRANCH"

            # Conditional push based on orchestration mode
            if $HAS_REMOTE && [ "$ORCHESTRATION_MODE" == "github" ] && [ "$AUTO_PUSH" == "true" ]; then
                git push -u origin "$branch"
                echo -e "  ${GREEN}✓ Branch created and pushed to remote (github orchestration mode)${NC}"
            elif $HAS_REMOTE; then
                echo -e "  ${GREEN}✓ Branch created locally${NC}"
                echo -e "  ${YELLOW}💡 GitHub push disabled (orchestration.mode='$ORCHESTRATION_MODE')${NC}"
                echo -e "  ${YELLOW}💡 Czar will push when ready, or set orchestration.auto_push_branches=true${NC}"
            else
                echo -e "  ${GREEN}✓ Branch created locally (no remote)${NC}"
            fi

            git checkout "$MAIN_BRANCH"
            BRANCHES_CREATED=$((BRANCHES_CREATED + 1))
        fi
    fi

    echo ""
done

# Create omnibus branch if defined
OMNIBUS_BRANCH=$(jq -r '.project.omnibus_branch // empty' "$CONFIG_FILE")

if [ -n "$OMNIBUS_BRANCH" ]; then
    echo -e "${BLUE}→ Processing Omnibus Branch:${NC} $OMNIBUS_BRANCH"

    # Check if omnibus branch exists locally
    if git show-ref --verify --quiet "refs/heads/$OMNIBUS_BRANCH"; then
        echo -e "  ${YELLOW}Status:${NC} Omnibus branch already exists"
        BRANCHES_EXISTS=$((BRANCHES_EXISTS + 1))
    else
        # Check if branch exists on remote
        if $HAS_REMOTE && git ls-remote --heads origin "$OMNIBUS_BRANCH" | grep -q "$OMNIBUS_BRANCH"; then
            echo -e "  ${YELLOW}Status:${NC} Omnibus branch exists on remote, checking out..."
            git checkout -b "$OMNIBUS_BRANCH" "origin/$OMNIBUS_BRANCH"
            git checkout "$MAIN_BRANCH"
            echo -e "  ${GREEN}✓ Omnibus branch checked out from remote${NC}"
            BRANCHES_EXISTS=$((BRANCHES_EXISTS + 1))
        else
            # Create new omnibus branch
            echo -e "  ${YELLOW}Status:${NC} Creating omnibus branch..."
            git checkout -b "$OMNIBUS_BRANCH" "$MAIN_BRANCH"

            if $HAS_REMOTE; then
                git push -u origin "$OMNIBUS_BRANCH"
                echo -e "  ${GREEN}✓ Omnibus branch created and pushed to remote${NC}"
            else
                echo -e "  ${GREEN}✓ Omnibus branch created locally${NC}"
            fi

            git checkout "$MAIN_BRANCH"
            BRANCHES_CREATED=$((BRANCHES_CREATED + 1))
        fi
    fi

    echo ""
else
    echo -e "${YELLOW}⚠️  No omnibus branch defined in config${NC}"
    echo ""
fi

# Return to original branch
if [ "$ORIGINAL_BRANCH" != "$MAIN_BRANCH" ]; then
    git checkout "$ORIGINAL_BRANCH" 2>/dev/null || git checkout "$MAIN_BRANCH"
fi

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Summary                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✓ Branches created:${NC}  $BRANCHES_CREATED"
echo -e "${BLUE}  Branches existing:${NC} $BRANCHES_EXISTS"
echo ""
echo -e "${GREEN}✅ Phase $PHASE branches initialized!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Workers check out their branch: ${BLUE}git checkout <branch-name>${NC}"
echo "  2. Worker prompt will auto-load based on branch"
echo "  3. Create PRs when ready"
echo ""
