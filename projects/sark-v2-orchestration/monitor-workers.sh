#!/bin/bash
# Czar Monitoring Script - Track worker progress

echo "🎭 CZAR MONITORING DASHBOARD"
echo "=============================="
echo ""

cd /home/jhenry/Source/GRID/sark

echo "📊 GIT ACTIVITY (Last 30 minutes):"
git log --all --since="30 minutes ago" --pretty=format:"%h %an %s" --abbrev-commit

echo ""
echo ""
echo "🌿 BRANCH STATUS:"
git branch -vv | grep "feat/v2"

echo ""
echo ""
echo "📈 COMMIT COUNT BY WORKER (Last 2 hours):"
git log --all --since="2 hours ago" --pretty=format:"%an" | sort | uniq -c | sort -rn

echo ""
echo ""
echo "🔍 RECENT COMMITS BY BRANCH:"
for branch in feat/v2-lead-architect feat/v2-http-adapter feat/v2-grpc-adapter feat/v2-federation feat/v2-advanced-features feat/v2-database feat/v2-integration-tests feat/v2-performance-security feat/v2-api-docs feat/v2-tutorials; do
    count=$(git log $branch --since="1 hour ago" --oneline 2>/dev/null | wc -l)
    if [ "$count" -gt 0 ]; then
        echo "  $branch: $count commits"
    fi
done

echo ""
echo ""
echo "⚠️  POTENTIAL ISSUES:"
# Check for merge conflicts
if git status | grep -q "You have unmerged paths"; then
    echo "  - MERGE CONFLICTS DETECTED"
fi

# Check for uncommitted changes on main
git checkout main &> /dev/null
if ! git diff --quiet; then
    echo "  - UNCOMMITTED CHANGES ON MAIN (should be in feature branches!)"
fi

echo ""
echo "=============================="
echo "Last updated: $(date)"
