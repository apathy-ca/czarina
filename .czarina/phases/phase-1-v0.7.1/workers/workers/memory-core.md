# Worker Identity: memory-core

**Role:** Code
**Agent:** Claude Code
**Branch:** feat/v0.7.0-memory-core
**Phase:** 1 (Foundation)
**Dependencies:** None

## Mission

Implement the core memory file structure and basic I/O operations for Czarina's persistent learning system.

## 🚀 YOUR FIRST ACTION

**Read the memory specification to understand the schema:**

```bash
# Read the complete memory specification
cat czarina_memory_spec.md

# Or if it's in the docs folder
cat docs/czarina_memory_spec.md
```

**Then:** Design the memories.md schema based on what you learned and proceed to Objective 2 (implement file I/O).

## Objectives

1. Design `memories.md` schema based on `czarina_memory_spec.md`
2. Implement basic file I/O in bash/python for reading and writing memories
3. Create `.czarina/memories.md` template with proper structure
4. Implement manual extraction workflow (for session end)
5. Add basic validation for memory format

## Context

Memory Architecture (3-tier system):
- **Tier 1:** Architectural Core (always-loaded, ~2-4KB)
- **Tier 2:** Project Knowledge (searchable session history)
- **Tier 3:** Session Context (ephemeral, in-memory)

This worker focuses on the file structure and basic operations. Semantic search will be handled by `memory-search` worker.

Reference: `czarina_memory_spec.md` for complete specification.

## Deliverable

Memory file structure working with:
- Template `.czarina/memories.md` file
- Basic read/write operations
- Manual extraction workflow documented

## Success Criteria

- [ ] memories.md schema implemented
- [ ] File I/O operations working (bash/python)
- [ ] Template file created
- [ ] Manual extraction workflow documented
- [ ] Basic validation implemented

## Notes

- Phase 1, parallel work (no dependencies)
- Foundation for memory-search and launcher-enhancement
- Keep it simple - MVP focus
- Reference: `INTEGRATION_PLAN_v0.7.0.md` and `.czarina/hopper/enhancement-memory-architecture.md`
