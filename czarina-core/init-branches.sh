#!/bin/bash
# Initialize git branches for all workers in a project
# This ensures workers have clean branches ready to go

set -euo pipefail

# Usage: ./init-branches.sh <config.sh path>

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-config.sh>"
    echo ""
    echo "Example:"
    echo "  $0 ../projects/sark-v2-orchestration/config.sh"
    exit 1
fi

CONFIG_FILE="$1"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

# Source the config to get PROJECT_ROOT and WORKER_DEFINITIONS
source "$CONFIG_FILE"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Git Branch Initialization for Workers             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Project: $PROJECT_NAME"
echo "Repository: $PROJECT_ROOT"
echo ""

if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "❌ Not a git repository: $PROJECT_ROOT"
    exit 1
fi

cd "$PROJECT_ROOT"

# Ensure we're on main and up to date
echo "📥 Updating main branch..."
git checkout main 2>/dev/null || git checkout master 2>/dev/null
git pull origin $(git branch --show-current)

echo ""
echo "🌿 Initializing worker branches..."
echo ""

# Track stats
BRANCHES_CREATED=0
BRANCHES_EXISTS=0
BRANCHES_DELETED=0

# Process each worker definition
for def in "${WORKER_DEFINITIONS[@]}"; do
    IFS='|' read -r worker_id branch task_file description <<< "$def"

    echo "→ Processing: $worker_id"
    echo "  Branch: $branch"

    # Check if branch exists
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        echo "  Status: Branch already exists"

        # Check if it has commits different from main
        COMMITS_AHEAD=$(git rev-list --count main..$branch 2>/dev/null || echo "0")
        COMMITS_BEHIND=$(git rev-list --count $branch..main 2>/dev/null || echo "0")

        if [ "$COMMITS_AHEAD" -gt 0 ]; then
            echo "  ⚠️  Branch has $COMMITS_AHEAD commit(s) ahead of main"
            echo "  Keeping existing branch (has work)"
            BRANCHES_EXISTS=$((BRANCHES_EXISTS + 1))
        else
            # Branch exists but has no unique commits, offer to recreate
            read -p "  Branch exists with no unique commits. Recreate? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git branch -D "$branch"
                git checkout -b "$branch" main
                git push -u origin "$branch" --force
                echo "  ✅ Branch recreated"
                BRANCHES_DELETED=$((BRANCHES_DELETED + 1))
                BRANCHES_CREATED=$((BRANCHES_CREATED + 1))
            else
                echo "  ⏭️  Skipping"
                BRANCHES_EXISTS=$((BRANCHES_EXISTS + 1))
            fi
        fi
    else
        # Create new branch
        git checkout -b "$branch" main
        git push -u origin "$branch"
        echo "  ✅ Branch created and pushed"
        BRANCHES_CREATED=$((BRANCHES_CREATED + 1))
    fi

    echo ""
done

# Return to main
git checkout main

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Summary                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  Branches created:  $BRANCHES_CREATED"
echo "  Branches existing: $BRANCHES_EXISTS"
echo "  Branches recreated: $BRANCHES_DELETED"
echo ""
echo "✅ All worker branches initialized!"
echo ""
echo "Next steps:"
echo "  1. Launch workers: czarina launch <project>"
echo "  2. Monitor dashboard: czarina dashboard <project>"
echo ""
