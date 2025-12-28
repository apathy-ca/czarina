#!/bin/bash
# Test script for Czarina Memory System

set -e

echo "🧪 Testing Czarina Memory System"
echo "================================"
echo

# Test 1: Initialize memory system
echo "Test 1: Initialize memory system"
./czarina memory init
echo "✅ Test 1 passed"
echo

# Test 2: Check that memories.md was created
echo "Test 2: Check memories.md exists"
if [ -f ".czarina/memories.md" ]; then
    echo "✅ Test 2 passed - memories.md created"
else
    echo "❌ Test 2 failed - memories.md not found"
    exit 1
fi
echo

# Test 3: Add some content to architectural core
echo "Test 3: Adding test content to architectural core"
cat >> .czarina/memories.md << 'EOF'

### Component Dependencies
- CLI (czarina) depends on czarina-core modules
- Memory system uses embeddings (OpenAI or local)
- Agent launchers depend on agent availability

### Known Couplings
- Memory commands require .czarina directory to exist
- Embedding providers need API keys or local models

EOF
echo "✅ Test 3 passed - content added"
echo

# Test 4: Add a test session
echo "Test 4: Adding test session to Project Knowledge"
cat >> .czarina/memories.md << 'EOF'

### Session: 2025-12-28 - Memory System Implementation

**What We Did:**
- Implemented 3-tier memory architecture
- Created MemorySystem class with embedding support
- Added CLI commands for memory management

**What Broke:**
- Initial import paths needed adjustment
- Had to add sys.path manipulation for module imports

**Root Cause:**
- Czarina uses dynamic imports from czarina-core directory
- Module wasn't in standard Python path

**Resolution:**
- Added sys.path.insert(0, ...) before imports
- Used get_orchestrator_dir() to find czarina-core

**Learnings:**
- Memory system provides semantic search over project history
- Supports both OpenAI and local embeddings
- Index is regenerable cache, markdown is source of truth

EOF
echo "✅ Test 4 passed - session added"
echo

# Test 5: Build index (requires dependencies)
echo "Test 5: Check if dependencies are available"
if python3 -c "import sentence_transformers" 2>/dev/null; then
    echo "✅ sentence-transformers available, building index..."
    ./czarina memory rebuild
    echo "✅ Test 5 passed - index built"
elif [ -n "$OPENAI_API_KEY" ]; then
    echo "✅ OPENAI_API_KEY available, building index..."
    ./czarina memory rebuild
    echo "✅ Test 5 passed - index built"
else
    echo "⚠️  Test 5 skipped - no embedding provider available"
    echo "   Install sentence-transformers: pip install sentence-transformers"
    echo "   Or set OPENAI_API_KEY environment variable"
fi
echo

# Test 6: Show architectural core
echo "Test 6: Display architectural core"
./czarina memory core
echo "✅ Test 6 passed"
echo

# Test 7: Query memories (if index was built)
if [ -f ".czarina/memories.index" ]; then
    echo "Test 7: Query memories"
    ./czarina memory query "implementation of memory system"
    echo "✅ Test 7 passed"
else
    echo "⚠️  Test 7 skipped - index not built"
fi
echo

echo "================================"
echo "✅ All tests completed!"
echo
echo "📝 Next steps:"
echo "  1. Review .czarina/memories.md"
echo "  2. Install embedding dependencies:"
echo "     pip install sentence-transformers"
echo "     OR export OPENAI_API_KEY=your-key"
echo "  3. Run 'czarina memory rebuild' to build search index"
echo "  4. Try 'czarina memory query \"your query\"'"
