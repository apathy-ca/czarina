# Worker Identity: memory-search

**Role:** Code
**Agent:** Claude Code
**Branch:** feat/v0.7.0-memory-search
**Phase:** 1 (Foundation)
**Dependencies:** None

## Mission

Build semantic search functionality using vector embeddings to retrieve relevant memories from past sessions.

## 🚀 YOUR FIRST ACTION

**Research and choose the embedding provider:**

```bash
# Review the memory specification for embedding requirements
cat czarina_memory_spec.md | grep -A 10 "embedding"

# Check if OpenAI API key is available
echo $OPENAI_API_KEY

# Document your decision: create a brief comparison
```

**Then:** Document your choice (OpenAI API vs local) with rationale and proceed to Objective 2 (implement vector indexing).

## Objectives

1. Choose embedding provider (OpenAI API vs local sentence-transformers)
2. Implement vector indexing system using JSON storage (`memories.index`)
3. Build search functionality (cosine similarity)
4. Test query accuracy with sample memories
5. Document embedding strategy and configuration

## Context

The memory search system enables:
- Semantic search of past session summaries
- Retrieval of top 3-5 relevant memories based on current task
- Regenerable index (markdown is source of truth)

File structure:
- `memories.md` - Human-readable source (from memory-core worker)
- `memories.index` - Vector embeddings cache (this worker creates)

## Deliverable

Semantic search functional with:
- Embedding provider integration
- Vector index generation
- Search query implementation
- 70%+ accuracy on test queries

## Success Criteria

- [ ] Embedding provider chosen and integrated
- [ ] Vector indexing implemented (JSON-based)
- [ ] Search functionality working
- [ ] Query accuracy > 70% on test cases
- [ ] Embedding strategy documented

## Technical Details

**Chunking Strategy:**
- Architectural Core: Single chunk (loaded whole)
- Project Knowledge: One chunk per session entry
- Large sessions: Split at ### headers

**Vector Storage Format:**
```json
{
  "chunks": [
    {
      "id": "session-2025-12-08-001",
      "source_line_start": 45,
      "source_line_end": 78,
      "text": "[chunk text]",
      "embedding": [0.023, -0.089, ...]
    }
  ],
  "metadata": {
    "embedding_model": "text-embedding-3-small",
    "chunk_count": 42,
    "last_indexed": "2025-12-10T14:30:00Z"
  }
}
```

## Notes

- Phase 1, parallel work (no dependencies)
- Integrates with memory-core's file structure
- Consider cost: OpenAI API vs local models
- Reference: `czarina_memory_spec.md` for detailed design
