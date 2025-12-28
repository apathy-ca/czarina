# Project Memory: czarina

Last Updated: 2025-12-28

---

## Architectural Core

**Essential project context - keep tight (target: 2-4KB)**

### Component Dependencies
<!-- Key components and their relationships -->

### Known Couplings
<!-- Implicit dependencies and gotchas -->

### Critical Constraints
<!-- Invariants that must not be violated -->

### Technology Stack
<!-- Key technologies and patterns -->

---

## Project Knowledge

**Searchable session history - what we learned**

<!-- Sessions are added here automatically via `czarina memory extract` -->
<!-- Each session should follow this structure:

### Session: YYYY-MM-DD - [Description]

**What We Did:**
-

**What Broke:**
-

**Root Cause:**
-

**Resolution:**
-

**Learnings:**
-

-->

---

## Patterns and Decisions

**Architectural decisions and their rationale**

<!-- Example:

### [Pattern Name]

**Context:** Why this came up

**Decision:** What we chose

**Rationale:** Why we chose it

**Revisit if:** Conditions that would change this decision

-->

---

## Notes

- This file is the **source of truth** for project memory
- The .index file is a regenerable cache (do not edit manually)
- Edit this file directly to add, update, or remove memories
- Run `czarina memory rebuild` after manual edits to regenerate the index

### Component Dependencies
- CLI (czarina) depends on czarina-core modules
- Memory system uses embeddings (OpenAI or local)
- Agent launchers depend on agent availability

### Known Couplings
- Memory commands require .czarina directory to exist
- Embedding providers need API keys or local models


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

