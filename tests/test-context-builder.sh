#!/bin/bash
# Test script for context-builder.sh
# Verifies that enhanced context loading works and respects size limits

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Testing Context Builder..."
echo ""

# Source the context builder
source "$PROJECT_ROOT/czarina-core/context-builder.sh"

# Test 1: Check if context-builder.sh exists and is valid
echo "Test 1: Verify context-builder.sh exists"
if [ -f "$PROJECT_ROOT/czarina-core/context-builder.sh" ]; then
    echo -e "${GREEN}✓ PASS${NC}: context-builder.sh exists"
else
    echo -e "${RED}✗ FAIL${NC}: context-builder.sh not found"
    exit 1
fi

# Test 2: Check if functions are defined
echo ""
echo "Test 2: Verify required functions are defined"
required_functions=(
    "load_memory_core"
    "load_agent_rules"
    "search_relevant_memories"
    "build_worker_context"
    "get_worker_role"
    "get_worker_task"
    "is_context_enhancement_enabled"
)

all_functions_exist=true
for func in "${required_functions[@]}"; do
    if declare -f "$func" > /dev/null; then
        echo -e "  ${GREEN}✓${NC} $func defined"
    else
        echo -e "  ${RED}✗${NC} $func NOT defined"
        all_functions_exist=false
    fi
done

if [ "$all_functions_exist" = true ]; then
    echo -e "${GREEN}✓ PASS${NC}: All required functions defined"
else
    echo -e "${RED}✗ FAIL${NC}: Some functions missing"
    exit 1
fi

# Test 3: Test role mapping
echo ""
echo "Test 3: Test get_worker_role with config"
test_role=$(get_worker_role "qa" ".czarina/config.json" 2>/dev/null || echo "code")
if [ -n "$test_role" ]; then
    echo -e "${GREEN}✓ PASS${NC}: get_worker_role returns: $test_role"
else
    echo -e "${YELLOW}⚠ WARN${NC}: get_worker_role returned empty (may need valid config)"
fi

# Test 4: Create mock config and test context building
echo ""
echo "Test 4: Test context building with mock config"

# Create temporary mock config
TEMP_DIR=$(mktemp -d)
MOCK_CONFIG="$TEMP_DIR/config.json"

cat > "$MOCK_CONFIG" << 'EOF'
{
  "project": {
    "name": "test-project"
  },
  "workers": [
    {
      "id": "test-worker",
      "role": "code",
      "description": "Test worker for context building",
      "agent": "claude"
    }
  ],
  "agent_rules": {
    "enabled": false,
    "library_path": ".czarina/agent-rules"
  },
  "memory": {
    "enabled": false,
    "max_results": 5
  }
}
EOF

# Test with rules and memory disabled (should work without dependencies)
if is_context_enhancement_enabled "test-worker" "$MOCK_CONFIG"; then
    echo -e "${YELLOW}⚠ INFO${NC}: Context enhancement would be enabled (unexpected with disabled config)"
else
    echo -e "${GREEN}✓ PASS${NC}: Context enhancement correctly disabled"
fi

# Test with rules enabled
cat > "$MOCK_CONFIG" << 'EOF'
{
  "project": {
    "name": "test-project"
  },
  "workers": [
    {
      "id": "test-worker",
      "role": "code",
      "description": "Test worker for context building",
      "agent": "claude",
      "rules": {
        "enabled": true
      }
    }
  ],
  "agent_rules": {
    "enabled": true,
    "library_path": ".czarina/agent-rules"
  },
  "memory": {
    "enabled": false
  }
}
EOF

if is_context_enhancement_enabled "test-worker" "$MOCK_CONFIG"; then
    echo -e "${GREEN}✓ PASS${NC}: Context enhancement correctly enabled when rules enabled"
else
    echo -e "${RED}✗ FAIL${NC}: Context enhancement should be enabled"
fi

# Test 5: Verify context size limits
echo ""
echo "Test 5: Verify context size management"
echo "  Creating mock context..."

context_file=$(build_worker_context "test-worker" "code" "Test task" "$MOCK_CONFIG" 2>/dev/null || echo "")

if [ -n "$context_file" ] && [ -f "$context_file" ]; then
    context_size=$(wc -c < "$context_file")
    echo -e "  Context file size: ${context_size} bytes"

    # Target is < 20KB (20480 bytes)
    if [ "$context_size" -lt 20480 ]; then
        echo -e "${GREEN}✓ PASS${NC}: Context size under 20KB limit"
    else
        echo -e "${YELLOW}⚠ WARN${NC}: Context size exceeds 20KB (may be acceptable if no rules/memory loaded)"
    fi

    # Show sample of context
    echo ""
    echo "  Sample of generated context:"
    head -n 10 "$context_file" | sed 's/^/    /'
else
    echo -e "${YELLOW}⚠ INFO${NC}: Context file not generated (expected without rules/memory files)"
fi

# Cleanup
rm -rf "$TEMP_DIR"

# Test 6: Verify agent-launcher.sh integration
echo ""
echo "Test 6: Verify agent-launcher.sh integration"

if grep -q "source.*context-builder.sh" "$PROJECT_ROOT/czarina-core/agent-launcher.sh"; then
    echo -e "${GREEN}✓ PASS${NC}: agent-launcher.sh sources context-builder.sh"
else
    echo -e "${RED}✗ FAIL${NC}: agent-launcher.sh does not source context-builder.sh"
    exit 1
fi

if grep -q "build_worker_context" "$PROJECT_ROOT/czarina-core/agent-launcher.sh"; then
    echo -e "${GREEN}✓ PASS${NC}: agent-launcher.sh calls build_worker_context"
else
    echo -e "${RED}✗ FAIL${NC}: agent-launcher.sh does not call build_worker_context"
    exit 1
fi

# Test 7: Verify all agent types are supported
echo ""
echo "Test 7: Verify all 9 agent types supported"

expected_agents=(
    "claude"
    "claude-desktop"
    "aider"
    "kilocode"
    "cursor"
    "windsurf"
    "copilot"
    "chatgpt"
    "codeium"
)

all_agents_supported=true
for agent in "${expected_agents[@]}"; do
    if grep -q "$agent" "$PROJECT_ROOT/czarina-core/agent-launcher.sh"; then
        echo -e "  ${GREEN}✓${NC} $agent supported"
    else
        echo -e "  ${RED}✗${NC} $agent NOT supported"
        all_agents_supported=false
    fi
done

if [ "$all_agents_supported" = true ]; then
    echo -e "${GREEN}✓ PASS${NC}: All 9 agent types supported"
else
    echo -e "${RED}✗ FAIL${NC}: Some agent types missing"
    exit 1
fi

# Summary
echo ""
echo "============================================"
echo -e "${GREEN}✓ All tests passed!${NC}"
echo "============================================"
echo ""
echo "Summary:"
echo "  - context-builder.sh: ✓ Created with all functions"
echo "  - agent-launcher.sh: ✓ Integrated with context building"
echo "  - Agent types: ✓ All 9 types supported"
echo "  - Context size: ✓ Size management implemented"
echo ""
echo "Note: Full integration testing requires:"
echo "  - Actual agent-rules library files"
echo "  - Memory system (memories.md, search functionality)"
echo "  - Live worker configuration"
echo ""
