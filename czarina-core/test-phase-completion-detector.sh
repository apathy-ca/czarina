#!/bin/bash
# Test Phase Completion Detector
# Comprehensive test suite for phase-completion-detector.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECTOR="${SCRIPT_DIR}/phase-completion-detector.sh"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

test_start() {
    local test_name="$1"
    echo -e "\n${BLUE}TEST: $test_name${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
    local message="${1:-Test passed}"
    echo -e "  ${GREEN}✓ PASS${NC}: $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    local message="${1:-Test failed}"
    echo -e "  ${RED}✗ FAIL${NC}: $message"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [ "$actual" -eq "$expected" ]; then
        test_pass "$test_name (exit code $actual)"
    else
        test_fail "$test_name (expected exit code $expected, got $actual)"
    fi
}

assert_output_contains() {
    local output="$1"
    local expected="$2"
    local test_name="$3"

    if echo "$output" | grep -q "$expected"; then
        test_pass "$test_name (output contains '$expected')"
    else
        test_fail "$test_name (output missing '$expected')"
    fi
}

assert_json_field() {
    local json="$1"
    local field="$2"
    local expected="$3"
    local test_name="$4"

    local actual=$(echo "$json" | jq -r "$field")

    if [ "$actual" = "$expected" ]; then
        test_pass "$test_name ($field = $expected)"
    else
        test_fail "$test_name ($field expected $expected, got $actual)"
    fi
}

# ============================================================================
# SETUP
# ============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Phase Completion Detector Test Suite${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check that detector exists
if [ ! -f "$DETECTOR" ]; then
    echo -e "${RED}Error: Detector not found at $DETECTOR${NC}"
    exit 1
fi

# Check for required tools
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed${NC}"
    exit 1
fi

# Find project root and config
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
cd "$PROJECT_ROOT"

# Try to find config file
CONFIG_FILE=""
if [ -f ".czarina/config.json" ]; then
    CONFIG_FILE=".czarina/config.json"
elif [ -f "../../../config.json" ]; then
    CONFIG_FILE="../../../config.json"
else
    echo -e "${YELLOW}Warning: No config file found, creating test config${NC}"

    # Create minimal test config
    TEST_CONFIG="/tmp/phase-detector-test-config.json"
    cat > "$TEST_CONFIG" <<'EOF'
{
  "project": {
    "name": "Test Project",
    "slug": "test",
    "version": "0.0.1",
    "phase": 1,
    "repository": ".",
    "orchestration_dir": ".czarina"
  },
  "omnibus_branch": "main",
  "workers": [
    {
      "id": "test-worker-1",
      "role": "core",
      "branch": "test/worker-1",
      "phase": 1
    },
    {
      "id": "test-worker-2",
      "role": "core",
      "branch": "test/worker-2",
      "phase": 1
    }
  ]
}
EOF
    CONFIG_FILE="$TEST_CONFIG"
fi

echo "Using config: $CONFIG_FILE"
echo ""

# ============================================================================
# BASIC FUNCTIONALITY TESTS
# ============================================================================

test_start "Detector script exists and is executable"
if [ -x "$DETECTOR" ]; then
    test_pass "Script is executable"
else
    test_fail "Script is not executable"
fi

test_start "Detector shows help message"
output=$("$DETECTOR" --help 2>&1 || true)
if echo "$output" | grep -q "Usage"; then
    test_pass "Help message displayed"
else
    test_fail "Help message not displayed"
fi

test_start "Detector validates config file exists"
set +e
output=$("$DETECTOR" --config-file /nonexistent/config.json 2>&1)
exit_code=$?
set -e
if [ $exit_code -eq 2 ] && echo "$output" | grep -q "Config file not found"; then
    test_pass "Config validation works"
else
    test_fail "Config validation failed (exit code $exit_code)"
fi

# ============================================================================
# OUTPUT FORMAT TESTS
# ============================================================================

test_start "Detector produces valid text output"
output=$("$DETECTOR" --config-file "$CONFIG_FILE" 2>&1 || true)
if echo "$output" | grep -q "Phase.*is"; then
    test_pass "Text output format is valid"
else
    test_fail "Text output format is invalid"
fi

test_start "Detector produces valid JSON output"
output=$("$DETECTOR" --config-file "$CONFIG_FILE" --json 2>&1 || true)
if echo "$output" | jq empty 2>/dev/null; then
    test_pass "JSON output is valid"

    # Validate JSON fields
    assert_json_field "$output" ".phase" "1" "JSON contains phase field"
    assert_json_field "$output" ".complete" "false" "JSON contains complete field"

    if echo "$output" | jq -e '.total_workers' >/dev/null 2>&1; then
        test_pass "JSON contains total_workers field"
    else
        test_fail "JSON missing total_workers field"
    fi

    if echo "$output" | jq -e '.completed_workers' >/dev/null 2>&1; then
        test_pass "JSON contains completed_workers field"
    else
        test_fail "JSON missing completed_workers field"
    fi
else
    test_fail "JSON output is invalid"
fi

# ============================================================================
# COMPLETION MODE TESTS
# ============================================================================

test_start "Detector reads phase from config"
current_phase=$(jq -r '.project.phase // 1' "$CONFIG_FILE")
output=$("$DETECTOR" --config-file "$CONFIG_FILE" --json 2>&1 || true)
actual_phase=$(echo "$output" | jq -r '.phase')

if [ "$actual_phase" = "$current_phase" ]; then
    test_pass "Detected correct phase: $current_phase"
else
    test_fail "Wrong phase detected (expected $current_phase, got $actual_phase)"
fi

test_start "Detector accepts phase override"
output=$("$DETECTOR" --config-file "$CONFIG_FILE" --phase 2 --json 2>&1 || true)
actual_phase=$(echo "$output" | jq -r '.phase')

if [ "$actual_phase" = "2" ]; then
    test_pass "Phase override works"
else
    test_fail "Phase override failed (got phase $actual_phase)"
fi

# ============================================================================
# VERBOSE OUTPUT TESTS
# ============================================================================

test_start "Verbose mode produces diagnostic output"
output=$("$DETECTOR" --config-file "$CONFIG_FILE" --verbose 2>&1 || true)

if echo "$output" | grep -q "\[PHASE-DETECTOR\]"; then
    test_pass "Verbose output enabled"
else
    test_fail "Verbose output not working"
fi

# ============================================================================
# INTEGRATION TESTS (if real config exists)
# ============================================================================

if [ -f ".czarina/config.json" ]; then
    test_start "Detector works with real project config"
    output=$("$DETECTOR" --config-file .czarina/config.json --json 2>&1 || true)

    if echo "$output" | jq empty 2>/dev/null; then
        test_pass "Real config produces valid output"

        workers=$(jq '.workers | length' .czarina/config.json)
        total_workers=$(echo "$output" | jq -r '.total_workers')

        if [ "$workers" = "$total_workers" ]; then
            test_pass "Correct worker count detected ($workers workers)"
        else
            test_fail "Worker count mismatch (config: $workers, detected: $total_workers)"
        fi
    else
        test_fail "Real config produced invalid output"
    fi
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Total tests: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
else
    echo -e "${RED}Failed: 0${NC}"
    echo ""
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
