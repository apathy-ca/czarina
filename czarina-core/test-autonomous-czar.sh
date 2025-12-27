#!/usr/bin/env bash
# test-autonomous-czar.sh
# Test autonomous czar functionality without running full loop

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTONOMOUS_SCRIPT="${SCRIPT_DIR}/czar-autonomous-v2.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Autonomous Czar v2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Check script exists and is executable
echo "✓ Test 1: Script exists and is executable"
if [[ ! -x "$AUTONOMOUS_SCRIPT" ]]; then
    echo "✗ FAIL: Script not executable: $AUTONOMOUS_SCRIPT"
    exit 1
fi
echo "  Script: $AUTONOMOUS_SCRIPT"
echo ""

# Test 2: Syntax check
echo "✓ Test 2: Syntax validation"
if ! bash -n "$AUTONOMOUS_SCRIPT"; then
    echo "✗ FAIL: Syntax errors in script"
    exit 1
fi
echo "  No syntax errors detected"
echo ""

# Test 3: Check dependencies
echo "✓ Test 3: Check dependencies"

DEPS=(
    "${SCRIPT_DIR}/logging.sh"
    "${SCRIPT_DIR}/update-worker-status.sh"
)

for dep in "${DEPS[@]}"; do
    if [[ ! -f "$dep" ]]; then
        echo "✗ FAIL: Missing dependency: $dep"
        exit 1
    fi
    echo "  Found: $(basename "$dep")"
done
echo ""

# Test 4: Source logging and test functions
echo "✓ Test 4: Test logging system integration"
source "${SCRIPT_DIR}/logging.sh"

# Initialize logging
czarina_log_init

# Test logging functions
czarina_log_event "test" "TEST_EVENT" result=success
czarina_log_daemon "🧪" "TEST_DAEMON" "Testing daemon log"

echo "  Logging system functional"
echo ""

# Test 5: Check configuration
echo "✓ Test 5: Check configuration file"

CZARINA_DIR="${CZARINA_DIR:-$(dirname "$SCRIPT_DIR")}"
CONFIG_FILE="${CZARINA_DIR}/config.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "⚠ WARNING: Config file not found: $CONFIG_FILE"
    echo "  (This is OK if testing outside a czarina project)"
else
    echo "  Found: $CONFIG_FILE"

    # Test reading worker IDs
    if command -v jq >/dev/null 2>&1; then
        WORKER_COUNT=$(jq -r '.workers | length' "$CONFIG_FILE")
        echo "  Workers configured: $WORKER_COUNT"

        # Show worker IDs
        echo "  Worker IDs:"
        jq -r '.workers[].id' "$CONFIG_FILE" | while read -r wid; do
            echo "    - $wid"
        done
    else
        echo "⚠ WARNING: jq not installed, skipping config validation"
    fi
fi
echo ""

# Test 6: Check function definitions in autonomous script
echo "✓ Test 6: Check key functions defined"

REQUIRED_FUNCTIONS=(
    "log_decision"
    "get_worker_ids"
    "update_worker_status"
    "detect_idle_workers"
    "detect_stuck_workers"
    "detect_crashed_workers"
    "prompt_stuck_worker"
    "check_worker_health"
    "main_loop"
)

for func in "${REQUIRED_FUNCTIONS[@]}"; do
    if ! grep -q "^${func}()" "$AUTONOMOUS_SCRIPT"; then
        echo "✗ FAIL: Function not found: $func"
        exit 1
    fi
done

echo "  All key functions defined"
echo ""

# Test 7: Verify status directory setup
echo "✓ Test 7: Verify status directory"
STATUS_DIR="${CZARINA_DIR}/status"

if [[ -d "$STATUS_DIR" ]]; then
    echo "  Status dir exists: $STATUS_DIR"

    if [[ -f "${STATUS_DIR}/worker-status.json" ]]; then
        echo "  Worker status file exists"
    else
        echo "  Worker status file not yet created (OK)"
    fi
else
    echo "  Status dir doesn't exist (will be created on first run)"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All tests passed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Autonomous Czar is ready to run."
echo ""
echo "To start the autonomous czar:"
echo "  $AUTONOMOUS_SCRIPT"
echo ""
echo "To test with timeout (recommended for first run):"
echo "  timeout 60 $AUTONOMOUS_SCRIPT"
echo ""
