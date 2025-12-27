#!/usr/bin/env bash
# test-dependency-tracking.sh
# Test suite for dependency tracking with autonomous czar

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPENDENCY_TRACKING="${SCRIPT_DIR}/czar-dependency-tracking.sh"
AUTONOMOUS_SCRIPT="${SCRIPT_DIR}/czar-autonomous-v2.sh"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Dependency Tracking for Autonomous Czar"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Test 1: Check script exists and is executable
echo "Test 1: Script exists and is executable"
if [[ -x "$DEPENDENCY_TRACKING" ]]; then
    pass "Dependency tracking script is executable"
else
    fail "Dependency tracking script not executable: $DEPENDENCY_TRACKING"
fi
echo ""

# Test 2: Syntax check
echo "Test 2: Syntax validation"
if bash -n "$DEPENDENCY_TRACKING"; then
    pass "No syntax errors in dependency tracking script"
else
    fail "Syntax errors detected"
fi
echo ""

# Test 3: Source and check function definitions
echo "Test 3: Function definitions"

# Need to set up minimal environment for sourcing
export CZARINA_DIR="${CZARINA_DIR:-$(dirname "$SCRIPT_DIR")}"
export CONFIG_FILE="${CZARINA_DIR}/config.json"
export STATUS_DIR="${CZARINA_DIR}/status"
export WORKER_STATUS_FILE="${STATUS_DIR}/worker-status.json"
export DECISIONS_LOG="${STATUS_DIR}/autonomous-decisions.log"

# Mock get_worker_ids function (required dependency)
get_worker_ids() {
    echo "worker-a worker-b worker-c"
}

# Mock get_worker_status function (required dependency)
get_worker_status() {
    local worker_id="$1"
    case "$worker_id" in
        worker-a) echo "idle" ;;
        worker-b) echo "working" ;;
        worker-c) echo "pending" ;;
        *) echo "unknown" ;;
    esac
}

# Mock get_worker_dependencies function (required dependency)
get_worker_dependencies() {
    local worker_id="$1"
    case "$worker_id" in
        worker-a) echo "" ;;  # no dependencies
        worker-b) echo "worker-a" ;;  # depends on A
        worker-c) echo "worker-a worker-b" ;;  # depends on A and B
        *) echo "" ;;
    esac
}

# Mock log_decision function (required dependency)
log_decision() {
    :  # No-op for testing
}

export -f get_worker_ids
export -f get_worker_status
export -f get_worker_dependencies
export -f log_decision

# Source the script
source "$DEPENDENCY_TRACKING" || {
    fail "Failed to source dependency tracking script"
    exit 1
}

REQUIRED_FUNCTIONS=(
    "check_worker_dependencies_met"
    "get_unmet_dependencies"
    "get_dependency_progress"
    "is_worker_blocked_by_dependencies"
    "get_blocked_workers"
    "check_worker_integration_ready"
    "get_integration_ready_workers"
    "suggest_integration_order"
    "get_integration_strategy"
    "monitor_dependencies"
)

all_functions_found=true
for func in "${REQUIRED_FUNCTIONS[@]}"; do
    if ! declare -f "$func" > /dev/null; then
        fail "Function not found: $func"
        all_functions_found=false
    fi
done

if $all_functions_found; then
    pass "All required functions are defined"
fi
echo ""

# Test 4: Dependency checking logic
echo "Test 4: Dependency checking logic"

# worker-a: no dependencies → should be met
if check_worker_dependencies_met "worker-a"; then
    pass "Worker with no dependencies: dependencies met"
else
    fail "Worker with no dependencies should have dependencies met"
fi

# worker-b: depends on worker-a (idle) → should be met
if check_worker_dependencies_met "worker-b"; then
    pass "Worker with idle dependency: dependencies met"
else
    fail "Worker with idle dependency should have dependencies met"
fi

# worker-c: depends on worker-a (idle) and worker-b (working) → should be met
if check_worker_dependencies_met "worker-c"; then
    pass "Worker with working dependencies: dependencies met"
else
    fail "Worker with working dependencies should have dependencies met"
fi

echo ""

# Test 5: Unmet dependencies detection
echo "Test 5: Unmet dependencies detection"

# Override get_worker_status to simulate pending dependencies
get_worker_status() {
    local worker_id="$1"
    case "$worker_id" in
        worker-a) echo "pending" ;;  # changed to pending
        worker-b) echo "working" ;;
        worker-c) echo "pending" ;;
        *) echo "unknown" ;;
    esac
}
export -f get_worker_status

# worker-b: depends on worker-a (pending) → should have unmet
unmet=$(get_unmet_dependencies "worker-b")
if [[ "$unmet" == "worker-a" ]]; then
    pass "Correctly identifies pending dependency as unmet"
else
    fail "Expected 'worker-a', got: '$unmet'"
fi

# worker-c: depends on worker-a (pending) and worker-b (working) → should have unmet
unmet=$(get_unmet_dependencies "worker-c")
if [[ "$unmet" == "worker-a" ]]; then
    pass "Correctly identifies only pending dependencies as unmet"
else
    fail "Expected 'worker-a', got: '$unmet'"
fi

echo ""

# Test 6: Dependency progress tracking
echo "Test 6: Dependency progress tracking"

# Restore original status function and dependencies
get_worker_status() {
    local worker_id="$1"
    case "$worker_id" in
        worker-a) echo "idle" ;;
        worker-b) echo "working" ;;
        worker-c) echo "pending" ;;
        *) echo "unknown" ;;
    esac
}

get_worker_dependencies() {
    local worker_id="$1"
    case "$worker_id" in
        worker-a) echo "" ;;  # no dependencies
        worker-b) echo "worker-a" ;;  # depends on A (idle = met)
        worker-c) echo "worker-a worker-b worker-d" ;;  # depends on A (idle=met), B (working=met), D (pending=not met)
        worker-d) echo "" ;;
        *) echo "" ;;
    esac
}

export -f get_worker_status
export -f get_worker_dependencies

progress=$(get_dependency_progress "worker-a")
if [[ "$progress" == "0/0" ]]; then
    pass "Worker with no dependencies: progress 0/0"
else
    fail "Expected '0/0', got: '$progress'"
fi

progress=$(get_dependency_progress "worker-b")
if [[ "$progress" == "1/1" ]]; then
    pass "Worker with 1 met dependency: progress 1/1"
else
    fail "Expected '1/1', got: '$progress'"
fi

progress=$(get_dependency_progress "worker-c")
if [[ "$progress" == "2/3" ]]; then
    pass "Worker with 2/3 dependencies met: progress 2/3"
else
    fail "Expected '2/3', got: '$progress'"
fi

echo ""

# Test 7: Blocked worker detection
echo "Test 7: Blocked worker detection"

# worker-a: idle, no dependencies → not blocked
if ! is_worker_blocked_by_dependencies "worker-a"; then
    pass "Worker with no dependencies is not blocked"
else
    fail "Worker with no dependencies should not be blocked"
fi

# worker-b: working, all dependencies met → not blocked
if ! is_worker_blocked_by_dependencies "worker-b"; then
    pass "Worker with met dependencies is not blocked"
else
    fail "Worker with met dependencies should not be blocked"
fi

# worker-c: pending → not blocked (pending workers are not yet blocked)
if ! is_worker_blocked_by_dependencies "worker-c"; then
    pass "Pending worker is not considered blocked"
else
    fail "Pending workers should not be considered blocked"
fi

# Set worker-c to working but with unmet dependency
get_worker_status() {
    local worker_id="$1"
    case "$worker_id" in
        worker-a) echo "idle" ;;
        worker-b) echo "idle" ;;
        worker-c) echo "working" ;;  # changed to working
        worker-d) echo "pending" ;;  # unmet dependency
        *) echo "unknown" ;;
    esac
}

get_worker_dependencies() {
    local worker_id="$1"
    case "$worker_id" in
        worker-a) echo "" ;;
        worker-b) echo "worker-a" ;;
        worker-c) echo "worker-a worker-b worker-d" ;;  # worker-d is pending
        *) echo "" ;;
    esac
}
export -f get_worker_status
export -f get_worker_dependencies

# worker-c: working, has unmet dependency (worker-d is pending) → blocked
if is_worker_blocked_by_dependencies "worker-c"; then
    pass "Worker with unmet dependencies is blocked"
else
    fail "Worker with unmet dependencies should be blocked"
fi

echo ""

# Test 8: Integration order suggestion
echo "Test 8: Integration order suggestion"

# Reset to simple dependency chain
get_worker_ids() {
    echo "a b c"
}

get_worker_dependencies() {
    case "$1" in
        a) echo "" ;;
        b) echo "a" ;;
        c) echo "a b" ;;
    esac
}
export -f get_worker_ids
export -f get_worker_dependencies

order=$(suggest_integration_order)
expected="a b c"
if [[ "$order" == "$expected" ]]; then
    pass "Integration order correct for simple chain"
else
    fail "Expected '$expected', got: '$order'"
fi

echo ""

# Test 9: Integration readiness
echo "Test 9: Integration readiness"

# Need worker-status.json for commit count check
mkdir -p "$STATUS_DIR"
cat > "$WORKER_STATUS_FILE" <<EOF
{
  "workers": {
    "a": {"status": "idle", "stats": {"commits": 5}},
    "b": {"status": "working", "stats": {"commits": 3}},
    "c": {"status": "idle", "stats": {"commits": 0}}
  }
}
EOF

get_worker_status() {
    jq -r ".workers[\"$1\"].status // \"unknown\"" "$WORKER_STATUS_FILE"
}
export -f get_worker_status

# worker-a: idle, no dependencies, has commits → ready
if check_worker_integration_ready "a"; then
    pass "Worker with commits and no dependencies is ready"
else
    fail "Worker a should be ready for integration"
fi

# worker-b: working, not idle → not ready
if ! check_worker_integration_ready "b"; then
    pass "Working worker is not ready for integration"
else
    fail "Working worker should not be ready"
fi

# worker-c: idle, dependencies met, but no commits → not ready
if ! check_worker_integration_ready "c"; then
    pass "Worker with no commits is not ready"
else
    fail "Worker with no commits should not be ready"
fi

echo ""

# Test 10: Integration with autonomous czar
echo "Test 10: Integration with autonomous czar"

if [[ -f "$AUTONOMOUS_SCRIPT" ]]; then
    if grep -q "source.*czar-dependency-tracking.sh" "$AUTONOMOUS_SCRIPT"; then
        pass "Autonomous czar sources dependency tracking"
    else
        fail "Autonomous czar doesn't source dependency tracking"
    fi

    if grep -q "monitor_dependencies" "$AUTONOMOUS_SCRIPT"; then
        pass "Autonomous czar calls monitor_dependencies"
    else
        fail "Autonomous czar doesn't call monitor_dependencies"
    fi
else
    fail "Autonomous czar script not found"
fi

echo ""

# Cleanup
rm -f "$WORKER_STATUS_FILE"

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "Dependency tracking is ready for use with autonomous czar."
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    echo ""
    echo "Please review the failures above."
    exit 1
fi
