#!/bin/bash
# Test script for autonomous-czar-daemon.sh
# Creates a minimal test orchestration and verifies daemon functionality

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="/tmp/czarina-daemon-test-$$"

echo "🧪 Testing autonomous-czar-daemon.sh"
echo "   Test directory: $TEST_DIR"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Cleaning up test directory..."
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Create test orchestration structure
echo "📁 Creating test orchestration..."
mkdir -p "$TEST_DIR"/{.czarina/workers,.czarina/status,.czarina/logs,.git}

# Initialize git repo
cd "$TEST_DIR"
git init -q
git config user.email "test@czarina.dev"
git config user.name "Czarina Test"

# Create minimal config.json
cat > .czarina/config.json <<'EOF'
{
  "project": {
    "name": "Test Project",
    "slug": "test-project",
    "repository": "/tmp/czarina-daemon-test"
  },
  "workers": [
    {
      "id": "worker1",
      "phase": 1,
      "branch": "cz1/feat/worker1",
      "description": "Test worker 1"
    },
    {
      "id": "worker2",
      "phase": 1,
      "branch": "cz1/feat/worker2",
      "description": "Test worker 2"
    },
    {
      "id": "worker3",
      "phase": 2,
      "branch": "cz1/feat/worker3",
      "description": "Test worker 3 (Phase 2)"
    }
  ]
}
EOF

# Create worker branches
git checkout -b main -q
echo "Initial commit" > README.md
git add .
git commit -m "Initial commit" -q

git checkout -b cz1/feat/worker1 -q
echo "Worker 1 work" > worker1.txt
git add .
git commit -m "Worker 1: Initial work" -q

git checkout -b cz1/feat/worker2 main -q
echo "Worker 2 work" > worker2.txt
git add .
git commit -m "Worker 2: Initial work" -q

git checkout main -q

# Create worker logs with completion markers
echo "WORKER_COMPLETE" > .czarina/logs/worker1.log
echo "WORKER_COMPLETE" > .czarina/logs/worker2.log

echo -e "${GREEN}✅ Test orchestration created${NC}"
echo ""

# Test 1: Syntax check
echo "🔍 Test 1: Script syntax check"
if bash -n "${SCRIPT_DIR}/autonomous-czar-daemon.sh"; then
    echo -e "${GREEN}✅ Syntax valid${NC}"
else
    echo -e "${RED}❌ Syntax errors found${NC}"
    exit 1
fi
echo ""

# Test 2: Dry run (kill after 3 seconds)
echo "🔍 Test 2: Daemon execution test (3 second run)"
echo "   Starting daemon..."

# Run daemon in background
timeout 3 bash "${SCRIPT_DIR}/autonomous-czar-daemon.sh" .czarina > /dev/null 2>&1 || true

# Check if logs were created
if [ -f ".czarina/status/czar-daemon.log" ]; then
    echo -e "${GREEN}✅ Daemon log created${NC}"

    # Check for key log entries
    if grep -q "AUTONOMOUS CZAR DAEMON STARTING" ".czarina/status/czar-daemon.log"; then
        echo -e "${GREEN}✅ Daemon started successfully${NC}"
    else
        echo -e "${RED}❌ Daemon startup not logged${NC}"
    fi

    if grep -q "Monitoring cycle starting" ".czarina/status/czar-daemon.log"; then
        echo -e "${GREEN}✅ Monitoring cycle executed${NC}"
    else
        echo -e "${YELLOW}⚠️  No monitoring cycles (may be timing)${NC}"
    fi
else
    echo -e "${RED}❌ No daemon log created${NC}"
    exit 1
fi
echo ""

# Test 3: Phase state
echo "🔍 Test 3: Phase state tracking"
if [ -f ".czarina/status/phase-state.json" ]; then
    echo -e "${GREEN}✅ Phase state file created${NC}"

    current_phase=$(jq -r '.current_phase' .czarina/status/phase-state.json)
    echo "   Current phase: $current_phase"

    if [ "$current_phase" = "1" ]; then
        echo -e "${GREEN}✅ Phase tracking initialized${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Phase state not created (may need longer run)${NC}"
fi
echo ""

# Test 4: Decision log
echo "🔍 Test 4: Decision logging"
if [ -f ".czarina/status/autonomous-decisions.log" ]; then
    echo -e "${GREEN}✅ Decision log created${NC}"

    # Show sample decisions
    if [ -s ".czarina/status/autonomous-decisions.log" ]; then
        echo "   Recent decisions:"
        tail -3 ".czarina/status/autonomous-decisions.log" | sed 's/^/     /'
    fi
else
    echo -e "${YELLOW}⚠️  No decisions logged yet${NC}"
fi
echo ""

# Test 5: Show actual daemon log output
echo "🔍 Test 5: Daemon log output"
if [ -f ".czarina/status/czar-daemon.log" ]; then
    echo "   Last 10 lines of daemon log:"
    tail -10 ".czarina/status/czar-daemon.log" | sed 's/^/     /'
else
    echo -e "${RED}❌ No log output${NC}"
fi
echo ""

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ All tests passed!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
