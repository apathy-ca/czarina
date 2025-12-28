#!/usr/bin/env bash
# Test suite for memory-core deliverable

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Test configuration
TEST_DIR=$(mktemp -d)
MEMORY_FILE="$TEST_DIR/memories.md"
export CZARINA_MEMORY_FILE="$MEMORY_FILE"

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Change to project root
cd "$(dirname "$0")/.."

#####################################
# Test Framework
#####################################

test_assert() {
    local description="$1"
    local command="$2"
    local expected_exit="${3:-0}"

    ((TESTS_RUN++))

    echo -n "  Testing: $description ... "

    if eval "$command" &>/dev/null; then
        actual_exit=0
    else
        actual_exit=$?
    fi

    if [[ $actual_exit -eq $expected_exit ]]; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "    Expected exit code $expected_exit, got $actual_exit"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_assert_contains() {
    local description="$1"
    local command="$2"
    local expected_string="$3"

    ((TESTS_RUN++))

    echo -n "  Testing: $description ... "

    local output
    output=$(eval "$command" 2>&1 || true)

    if echo "$output" | grep -q "$expected_string"; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "    Expected to find: $expected_string"
        echo "    Got: $output"
        ((TESTS_FAILED++))
        return 1
    fi
}

#####################################
# Test Suites
#####################################

test_memory_manager_bash() {
    echo ""
    echo "Testing: Bash Memory Manager"
    echo "═══════════════════════════════"

    # Test initialization
    test_assert "Initialize memory file" \
        "./czarina-core/memory-manager.sh init 'Test Project'"

    test_assert "File was created" \
        "test -f '$MEMORY_FILE'"

    # Test validation
    test_assert "Validate memory file" \
        "./czarina-core/memory-manager.sh validate"

    # Test reading sections
    test_assert_contains "Read architectural core" \
        "./czarina-core/memory-manager.sh read-core" \
        "Component Dependencies"

    test_assert_contains "Read project knowledge" \
        "./czarina-core/memory-manager.sh read-sessions" \
        "Project Knowledge"

    # Test stats
    test_assert_contains "Show statistics" \
        "./czarina-core/memory-manager.sh stats" \
        "Memory Statistics"

    # Test appending session
    local session_file="$TEST_DIR/test-session.md"
    cat > "$session_file" <<'EOF'
### Session: 2025-12-28 - Test Session

#### What We Did
- Task 1
- Task 2

#### Prevention
- Learning 1
EOF

    test_assert "Append session from file" \
        "./czarina-core/memory-manager.sh append-session '$session_file'"

    test_assert_contains "Session was added" \
        "cat '$MEMORY_FILE'" \
        "Test Session"

    # Test validation after modification
    test_assert "Validate after append" \
        "./czarina-core/memory-manager.sh validate"
}

test_memory_manager_python() {
    echo ""
    echo "Testing: Python Memory Manager"
    echo "═══════════════════════════════"

    # Test validation
    test_assert "Python validation" \
        "python3 ./czarina-core/memory_manager.py validate"

    # Test statistics
    test_assert_contains "Python statistics" \
        "python3 ./czarina-core/memory_manager.py stats" \
        "session_count"

    # Test reading core
    test_assert_contains "Python read core" \
        "python3 ./czarina-core/memory_manager.py read-core" \
        "Component Dependencies"
}

test_memory_extraction() {
    echo ""
    echo "Testing: Memory Extraction Workflow"
    echo "════════════════════════════════════"

    # Test template generation
    local template_file="$TEST_DIR/template.md"
    test_assert "Generate template" \
        "./czarina-core/memory-extract.sh template '$template_file'"

    test_assert "Template file created" \
        "test -f '$template_file'"

    test_assert_contains "Template has correct structure" \
        "cat '$template_file'" \
        "What We Did"

    # Test quick extraction
    test_assert "Quick extraction" \
        "./czarina-core/memory-extract.sh quick 'Quick Test' '- Quick task 1\\n- Quick task 2'"
}

test_edge_cases() {
    echo ""
    echo "Testing: Edge Cases and Error Handling"
    echo "═══════════════════════════════════════"

    # Test missing file
    local nonexistent_file="$TEST_DIR/nonexistent.md"
    export CZARINA_MEMORY_FILE="$nonexistent_file"

    test_assert "Fail on missing file" \
        "./czarina-core/memory-manager.sh validate" \
        1

    test_assert "Fail on missing file (Python)" \
        "python3 ./czarina-core/memory_manager.py validate" \
        1

    # Restore memory file
    export CZARINA_MEMORY_FILE="$MEMORY_FILE"

    # Test invalid session file
    test_assert "Fail on missing session file" \
        "./czarina-core/memory-manager.sh append-session '/nonexistent/session.md'" \
        1

    # Test double initialization
    test_assert "Fail on re-initialization" \
        "./czarina-core/memory-manager.sh init 'Another Project'" \
        1
}

test_file_size_validation() {
    echo ""
    echo "Testing: File Size and Guidelines"
    echo "═════════════════════════════════"

    local stats_output
    stats_output=$(./czarina-core/memory-manager.sh stats)

    test_assert_contains "Stats include file size" \
        "echo '$stats_output'" \
        "Size:"

    test_assert_contains "Stats include line count" \
        "echo '$stats_output'" \
        "Lines:"

    # Check that memory file is reasonable size (< 10KB for tests)
    local file_size
    file_size=$(wc -c < "$MEMORY_FILE" | tr -d ' ')

    if [[ $file_size -lt 10240 ]]; then
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
        echo -e "  Testing: File size is reasonable ... ${GREEN}PASS${NC}"
    else
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
        echo -e "  Testing: File size is reasonable ... ${RED}FAIL${NC}"
        echo "    File size: $file_size bytes (> 10KB)"
    fi
}

#####################################
# Main Test Runner
#####################################

run_all_tests() {
    echo ""
    echo "╔════════════════════════════════════════════════════╗"
    echo "║   Memory Core Test Suite                          ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    echo "Test directory: $TEST_DIR"

    # Run test suites
    test_memory_manager_bash
    test_memory_manager_python
    test_memory_extraction
    test_edge_cases
    test_file_size_validation

    # Summary
    echo ""
    echo "╔════════════════════════════════════════════════════╗"
    echo "║   Test Summary                                     ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    echo "  Tests run:    $TESTS_RUN"
    echo -e "  Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    # Cleanup
    echo "Cleaning up test directory: $TEST_DIR"
    rm -rf "$TEST_DIR"

    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✅ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed${NC}"
        exit 1
    fi
}

# Run tests
run_all_tests
