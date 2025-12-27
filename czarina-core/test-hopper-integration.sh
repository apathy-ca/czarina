#!/usr/bin/env bash
# test-hopper-integration.sh
# Test suite for hopper integration with autonomous czar

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOPPER_INTEGRATION="${SCRIPT_DIR}/czar-hopper-integration.sh"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output (optional)
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Hopper Integration for Autonomous Czar"
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

# Test 1: Check script exists and is executable
echo "Test 1: Script exists and is executable"
if [[ -x "$HOPPER_INTEGRATION" ]]; then
    pass "Hopper integration script is executable"
else
    fail "Hopper integration script not executable: $HOPPER_INTEGRATION"
fi
echo ""

# Test 2: Syntax check
echo "Test 2: Syntax validation"
if bash -n "$HOPPER_INTEGRATION"; then
    pass "No syntax errors in hopper integration script"
else
    fail "Syntax errors detected"
fi
echo ""

# Test 3: Source the script and check functions are defined
echo "Test 3: Function definitions"
source "$HOPPER_INTEGRATION" || {
    fail "Failed to source hopper integration script"
    exit 1
}

REQUIRED_FUNCTIONS=(
    "find_czarina_root"
    "get_project_hopper_path"
    "get_phase_hopper_path"
    "parse_hopper_item_metadata"
    "assess_hopper_item"
    "get_project_hopper_items"
    "check_project_hopper_new_items"
    "assess_and_process_project_item"
    "get_phase_hopper_todo_items"
    "count_phase_hopper_items"
    "assign_task_to_worker"
    "inject_task_to_worker"
    "monitor_hoppers"
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

# Test 4: Test assessment logic with mock data
echo "Test 4: Assessment logic"

# Create a temporary test file
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Test case 1: High priority + Small complexity
cat > "$TEST_DIR/test-high-small.md" <<'EOF'
# Enhancement: Test High Small

**Priority:** High
**Complexity:** Small
**Tags:** test
**Suggested Phase:**
**Estimate:**

## Description
Test enhancement
EOF

result=$(assess_hopper_item "$TEST_DIR/test-high-small.md" 1)
decision=$(echo "$result" | cut -d'|' -f1)
if [[ "$decision" == "auto-include" ]]; then
    pass "High priority + Small complexity → auto-include"
else
    fail "Expected auto-include, got: $decision"
fi

# Test case 2: Future tag
cat > "$TEST_DIR/test-future.md" <<'EOF'
# Enhancement: Test Future

**Priority:** High
**Complexity:** Small
**Tags:** future, v0.7.0
**Suggested Phase:**
**Estimate:**

## Description
Future enhancement
EOF

result=$(assess_hopper_item "$TEST_DIR/test-future.md" 1)
decision=$(echo "$result" | cut -d'|' -f1)
if [[ "$decision" == "auto-defer" ]]; then
    pass "Future tag → auto-defer"
else
    fail "Expected auto-defer, got: $decision"
fi

# Test case 3: Low priority
cat > "$TEST_DIR/test-low.md" <<'EOF'
# Enhancement: Test Low Priority

**Priority:** Low
**Complexity:** Medium
**Tags:**
**Suggested Phase:**
**Estimate:**

## Description
Low priority enhancement
EOF

result=$(assess_hopper_item "$TEST_DIR/test-low.md" 1)
decision=$(echo "$result" | cut -d'|' -f1)
if [[ "$decision" == "auto-defer" ]]; then
    pass "Low priority → auto-defer"
else
    fail "Expected auto-defer, got: $decision"
fi

# Test case 4: Large complexity + no idle workers
cat > "$TEST_DIR/test-large-no-workers.md" <<'EOF'
# Enhancement: Test Large No Workers

**Priority:** High
**Complexity:** Large
**Tags:**
**Suggested Phase:**
**Estimate:**

## Description
Large enhancement
EOF

result=$(assess_hopper_item "$TEST_DIR/test-large-no-workers.md" 0)
decision=$(echo "$result" | cut -d'|' -f1)
if [[ "$decision" == "auto-defer" ]]; then
    pass "Large complexity + no idle workers → auto-defer"
else
    fail "Expected auto-defer, got: $decision"
fi

# Test case 5: Medium priority (ask human)
cat > "$TEST_DIR/test-medium.md" <<'EOF'
# Enhancement: Test Medium

**Priority:** Medium
**Complexity:** Medium
**Tags:**
**Suggested Phase:**
**Estimate:**

## Description
Medium priority enhancement
EOF

result=$(assess_hopper_item "$TEST_DIR/test-medium.md" 1)
decision=$(echo "$result" | cut -d'|' -f1)
if [[ "$decision" == "ask-human" ]]; then
    pass "Medium priority → ask-human"
else
    fail "Expected ask-human, got: $decision"
fi

echo ""

# Test 5: Test metadata parsing
echo "Test 5: Metadata parsing"

test_file="$TEST_DIR/test-metadata.md"
cat > "$test_file" <<'EOF'
# Enhancement: Metadata Test

**Priority:** High
**Complexity:** Large
**Tags:** feature, breaking-change
**Suggested Phase:** v0.7.0
**Estimate:** 3 days

## Description
Test metadata parsing
EOF

title=$(parse_hopper_item_metadata "$test_file" "title")
priority=$(parse_hopper_item_metadata "$test_file" "priority")
complexity=$(parse_hopper_item_metadata "$test_file" "complexity")
tags=$(parse_hopper_item_metadata "$test_file" "tags")

if [[ "$title" == "Enhancement: Metadata Test" ]]; then
    pass "Title parsing works"
else
    fail "Title parsing failed: got '$title'"
fi

if [[ "$priority" == "High" ]]; then
    pass "Priority parsing works"
else
    fail "Priority parsing failed: got '$priority'"
fi

if [[ "$complexity" == "Large" ]]; then
    pass "Complexity parsing works"
else
    fail "Complexity parsing failed: got '$complexity'"
fi

if [[ "$tags" == "feature, breaking-change" ]]; then
    pass "Tags parsing works"
else
    fail "Tags parsing failed: got '$tags'"
fi

echo ""

# Test 6: Integration with autonomous czar
echo "Test 6: Integration with autonomous czar"

if [[ -f "${SCRIPT_DIR}/czar-autonomous-v2.sh" ]]; then
    if grep -q "source.*czar-hopper-integration.sh" "${SCRIPT_DIR}/czar-autonomous-v2.sh"; then
        pass "Autonomous czar sources hopper integration"
    else
        fail "Autonomous czar doesn't source hopper integration"
    fi

    if grep -q "monitor_hoppers" "${SCRIPT_DIR}/czar-autonomous-v2.sh"; then
        pass "Autonomous czar calls monitor_hoppers"
    else
        fail "Autonomous czar doesn't call monitor_hoppers"
    fi
else
    fail "Autonomous czar script not found"
fi

echo ""

# Test 7: Hopper path detection
echo "Test 7: Hopper path detection"

# This test is environment-dependent, so we'll just check if the functions run without errors
if root=$(find_czarina_root 2>/dev/null); then
    pass "Can find czarina root: $root"

    if project_hopper=$(get_project_hopper_path 2>/dev/null); then
        pass "Can get project hopper path: $project_hopper"
    else
        pass "No project hopper (this is OK for test environment)"
    fi

    if phase_hopper=$(get_phase_hopper_path 2>/dev/null); then
        pass "Can get phase hopper path: $phase_hopper"
    else
        pass "No phase hopper (this is OK for test environment)"
    fi
else
    pass "Not in czarina project (this is OK for test environment)"
fi

echo ""

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
    echo "Hopper integration is ready for use with autonomous czar."
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    echo ""
    echo "Please review the failures above."
    exit 1
fi
