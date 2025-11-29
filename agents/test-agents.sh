#!/bin/bash
# Czarina Multi-Agent Testing Suite
# Tests agent launchers and validates integration

set -uo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Test 1: Main launcher script exists and is executable
test_main_launcher() {
    section "Test 1: Main Launcher Script"

    LAUNCHER="$PROJECT_ROOT/czarina-core/launch-agent.sh"

    if [ -f "$LAUNCHER" ]; then
        pass "Main launcher exists: $LAUNCHER"
    else
        fail "Main launcher not found: $LAUNCHER"
        return
    fi

    if [ -x "$LAUNCHER" ]; then
        pass "Main launcher is executable"
    else
        fail "Main launcher is not executable"
    fi

    # Test help output
    if "$LAUNCHER" --help &> /dev/null; then
        pass "Main launcher --help works"
    else
        fail "Main launcher --help failed"
    fi
}

# Test 2: Agent-specific helper scripts
test_helper_scripts() {
    section "Test 2: Agent-Specific Helper Scripts"

    local helpers=(
        "cursor-launcher.sh"
        "aider-launcher.sh"
        "copilot-launcher.sh"
        "windsurf-launcher.sh"
    )

    for helper in "${helpers[@]}"; do
        local path="$SCRIPT_DIR/launchers/$helper"
        if [ -f "$path" ]; then
            if [ -x "$path" ]; then
                pass "Helper script: $helper (exists and executable)"
            else
                fail "Helper script: $helper (not executable)"
            fi
        else
            fail "Helper script: $helper (not found)"
        fi
    done
}

# Test 3: Launcher with test orchestration
test_launcher_with_orchestration() {
    section "Test 3: Launcher with Current Orchestration"

    # Find orchestration directory
    CZARINA_DIR=$(find "$PROJECT_ROOT" -maxdepth 1 -type d -name "czarina-*" 2>/dev/null | head -1)

    if [ -z "$CZARINA_DIR" ]; then
        warn "No czarina-* directory found in project root"
        warn "Skipping orchestration tests"
        return
    fi

    pass "Found orchestration directory: $(basename "$CZARINA_DIR")"

    # Check if workers directory exists
    if [ -d "$CZARINA_DIR/workers" ]; then
        pass "Workers directory exists"

        # List available workers
        local worker_count=$(ls -1 "$CZARINA_DIR/workers/"*.md 2>/dev/null | wc -l)
        info "Found $worker_count worker(s)"

        # Test launcher with first worker (if any)
        local first_worker=$(ls -1 "$CZARINA_DIR/workers/"*.md 2>/dev/null | head -1)
        if [ -n "$first_worker" ]; then
            local worker_id=$(basename "$first_worker" .md)
            info "Testing with worker: $worker_id"

            # Test human agent (safe, just displays)
            if "$PROJECT_ROOT/czarina-core/launch-agent.sh" human "$worker_id" "$PROJECT_ROOT" &> /dev/null; then
                pass "Launcher successfully loads worker: $worker_id"
            else
                fail "Launcher failed to load worker: $worker_id"
            fi
        fi
    else
        fail "Workers directory not found"
    fi
}

# Test 4: Agent availability
test_agent_availability() {
    section "Test 4: Available AI Agents"

    local agents=(
        "cursor:Cursor IDE"
        "aider:Aider CLI"
        "code:VS Code (for Copilot)"
        "windsurf:Windsurf IDE"
    )

    for agent_info in "${agents[@]}"; do
        IFS=: read -r cmd name <<< "$agent_info"
        if command -v "$cmd" &> /dev/null; then
            pass "$name available (command: $cmd)"
        else
            info "$name not installed (command: $cmd not found)"
        fi
    done
}

# Test 5: Documentation files
test_documentation() {
    section "Test 5: Documentation"

    local docs=(
        "$PROJECT_ROOT/czarina-core/docs/AGENT_TYPES.md:Agent Types Documentation"
    )

    # Check optional docs
    if [ -f "$PROJECT_ROOT/AGENT_COMPATIBILITY.md" ]; then
        pass "Documentation exists: Agent Compatibility Guide"
    else
        info "Agent Compatibility Guide (optional, not yet created)"
    fi

    for doc_info in "${docs[@]}"; do
        IFS=: read -r path name <<< "$doc_info"
        if [ -f "$path" ]; then
            pass "Documentation exists: $name"
        else
            fail "Documentation missing: $name"
        fi
    done

    # Check if guides directory exists
    if [ -d "$SCRIPT_DIR/guides" ]; then
        local guide_count=$(ls -1 "$SCRIPT_DIR/guides/"*.md 2>/dev/null | wc -l)
        if [ $guide_count -gt 0 ]; then
            pass "Agent-specific guides: $guide_count found"
        else
            warn "Agent-specific guides directory exists but is empty"
        fi
    else
        info "Agent-specific guides directory not yet created"
    fi
}

# Test 6: Error handling
test_error_handling() {
    section "Test 6: Error Handling"

    # Test with no arguments
    if ! "$PROJECT_ROOT/czarina-core/launch-agent.sh" &> /dev/null; then
        pass "Launcher correctly handles missing arguments"
    else
        fail "Launcher should fail with missing arguments"
    fi

    # Test with invalid worker
    if ! "$PROJECT_ROOT/czarina-core/launch-agent.sh" claude-code "nonexistent-worker-xyz" "$PROJECT_ROOT" 2>&1 | grep -q "Worker not found"; then
        fail "Launcher should detect invalid worker"
    else
        pass "Launcher correctly detects invalid worker"
    fi

    # Test with invalid project directory
    if ! "$PROJECT_ROOT/czarina-core/launch-agent.sh" claude-code engineer1 "/nonexistent/path" 2>&1 | grep -q "No czarina-"; then
        fail "Launcher should detect missing orchestration"
    else
        pass "Launcher correctly detects missing orchestration"
    fi
}

# Test 7: Git integration readiness
test_git_integration() {
    section "Test 7: Git Integration"

    # Check if we're in a git repository
    if git rev-parse --git-dir &> /dev/null; then
        pass "Running in git repository"

        # Check if gh CLI is available (useful for PRs)
        if command -v gh &> /dev/null; then
            pass "GitHub CLI (gh) available for PR creation"
        else
            info "GitHub CLI (gh) not installed - manual PR creation needed"
        fi
    else
        fail "Not in a git repository"
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║  Czarina Multi-Agent Integration Testing Suite        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    test_main_launcher
    test_helper_scripts
    test_launcher_with_orchestration
    test_agent_availability
    test_documentation
    test_error_handling
    test_git_integration

    # Summary
    section "Test Summary"

    local total=$((TESTS_PASSED + TESTS_FAILED))
    echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Failed:${NC} $TESTS_FAILED"
    echo -e "Total:  $total"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

# Run tests
main "$@"
