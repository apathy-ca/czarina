# Memory Core - Czarina Memory System Implementation

**Phase:** 1 (Foundation)
**Worker:** memory-core
**Status:** Complete
**Version:** 0.7.0-alpha

## Overview

This deliverable implements the core memory file structure and basic I/O operations for Czarina's persistent learning system. It provides the foundation for Czarina workers to remember past work, mistakes, and accumulated project knowledge across sessions.

## What's Included

### 1. Memory File Template

**File:** `.czarina/memories.md`

A human-readable, version-controlled markdown file with three main sections:

- **Architectural Core**: Essential, always-loaded context (~2-4KB)
- **Project Knowledge**: Searchable session history with learnings
- **Patterns and Decisions**: Important architectural decisions

### 2. Bash Memory Manager

**File:** `czarina-core/memory-manager.sh`

Core operations for memory file manipulation:

```bash
# Initialize new memory file
./memory-manager.sh init "Project Name"

# Read sections
./memory-manager.sh read-core
./memory-manager.sh read-sessions
./memory-manager.sh read-patterns

# Append session from file
./memory-manager.sh append-session session.md

# Validate format
./memory-manager.sh validate

# Show statistics
./memory-manager.sh stats
```

### 3. Python Memory Manager

**File:** `czarina-core/memory_manager.py`

Structured Python module for advanced operations:

```python
from memory_manager import MemoryFile, SessionEntry

# Create and validate
memory = MemoryFile()
is_valid, errors = memory.validate()

# Read sections
core = memory.read_architectural_core()
sessions = memory.parse_sessions()

# Append session
session = SessionEntry(
    date="2025-12-28",
    description="Feature implementation",
    what_we_did=["Task 1", "Task 2"],
    what_broke=[],
    root_cause="",
    resolution="",
    prevention=["Learning 1"]
)
memory.append_session(session)

# Get statistics
stats = memory.get_stats()
```

### 4. Interactive Extraction Workflow

**File:** `czarina-core/memory-extract.sh`

Interactive tool for end-of-session learning extraction:

```bash
# Interactive extraction (recommended)
./memory-extract.sh extract

# Quick extraction
./memory-extract.sh quick "Bug fix" "- Fixed timeout issue"

# Generate template for manual editing
./memory-extract.sh template
```

## Memory File Structure

### Format Specification

```markdown
# Project Memory: [Project Name]

## Architectural Core

### Component Dependencies
[Critical relationships and load order]

### Known Couplings
[Explicit and implicit couplings]

### Constraints
[Critical constraints and invariants]

### Technology Stack
[Key technologies and patterns]

---

## Project Knowledge

### Session: YYYY-MM-DD - [Description]

#### What We Did
- Accomplishment 1
- Accomplishment 2

#### What Broke
- Issue 1
- Issue 2

#### Root Cause
[Analysis of why issues occurred]

#### Resolution
[How we fixed it]

#### Prevention
- Learning 1
- Learning 2

---

## Patterns and Decisions

### [Pattern Name]
- **Context**: Why this came up
- **Decision**: What we chose
- **Rationale**: Why
- **Revisit if**: Conditions for reconsideration
```

## Usage Examples

### Initialize Memory for New Project

```bash
cd /path/to/project

# Initialize with default name
./czarina-core/memory-manager.sh init

# Or with custom project name
./czarina-core/memory-manager.sh init "My Awesome Project"

# Verify it was created
./czarina-core/memory-manager.sh validate
```

### End-of-Session Workflow

```bash
# Interactive extraction (recommended)
./czarina-core/memory-extract.sh extract

# Follow the prompts to capture:
# - Session date and description
# - What you accomplished
# - What broke (if anything)
# - Root causes and resolutions
# - Key learnings and prevention strategies

# Verify the entry was added
./czarina-core/memory-manager.sh stats
```

### Manual Session Entry

```bash
# Generate template
./czarina-core/memory-extract.sh template .czarina/my-session.md

# Edit the template file with your session details
vim .czarina/my-session.md

# Append to memory file
./czarina-core/memory-manager.sh append-session .czarina/my-session.md

# Validate the result
./czarina-core/memory-manager.sh validate
```

### Reading Memory Sections

```bash
# Read architectural core
./czarina-core/memory-manager.sh read-core

# Read all session entries
./czarina-core/memory-manager.sh read-sessions

# Read patterns and decisions
./czarina-core/memory-manager.sh read-patterns
```

### Python API Usage

```python
#!/usr/bin/env python3
from czarina_core.memory_manager import MemoryFile, create_session_template

# Initialize
memory = MemoryFile(".czarina/memories.md")

# Validate before reading
is_valid, errors = memory.validate()
if not is_valid:
    print("Validation errors:", errors)
    exit(1)

# Read architectural core
core = memory.read_architectural_core()
print("Architectural Core:")
print(core)

# Parse all sessions
sessions = memory.parse_sessions()
print(f"\nFound {len(sessions)} session(s)")

for session in sessions:
    print(f"\n{session.title}")
    print(f"  Learnings: {len(session.prevention)}")

# Create and append new session
new_session = create_session_template(
    description="API Enhancement"
)
new_session.what_we_did = [
    "Added new endpoint /api/v2/search",
    "Implemented rate limiting"
]
new_session.prevention = [
    "Remember to update API docs when adding endpoints",
    "Rate limiting needs Redis in production"
]

memory.append_session(new_session)

# Get statistics
stats = memory.get_stats()
print(f"\nMemory file: {stats['size_kb']} KB")
print(f"Sessions: {stats['session_count']}")
```

## Validation Rules

The validation system checks for:

1. **Required Header**: `# Project Memory:` at the top
2. **Required Sections**:
   - `## Architectural Core`
   - `## Project Knowledge`
   - `## Patterns and Decisions`
3. **Section Order**: Sections appear in the correct order
4. **Valid Markdown**: Proper markdown formatting

### Running Validation

```bash
# Bash validation
./czarina-core/memory-manager.sh validate

# Python validation
python3 czarina-core/memory_manager.py validate

# Both will exit with code 0 if valid, 1 if invalid
```

## File Size Guidelines

### Architectural Core
- **Target**: 2-4KB
- **Maximum**: 5KB
- **Why**: Loaded in full at every session start
- **Best Practice**: Keep it tight and essential

### Session Entries
- **Target**: 0.5-1KB per session
- **Best Practice**: Be concise but complete
- **Tip**: Focus on learnings, not step-by-step details

### Total Memory File
- **Reasonable**: 50-100 sessions (50-100KB)
- **Large**: 200+ sessions (200KB+)
- **Archive When**: File exceeds 500KB or 1 year old

## Best Practices

### Architectural Core
- Only include essential, frequently-referenced information
- Update when you discover critical couplings or constraints
- Remove outdated information promptly
- Think: "What would save hours if I remembered it?"

### Session Entries
- Extract learnings immediately after work (memory is fresh)
- Focus on the "why" not the "what"
- Include context: what broke, why it broke, how we fixed it
- Link to commits or PRs for details

### Patterns and Decisions
- Document the rationale, not just the decision
- Include conditions for revisiting the decision
- Update when decisions change

## Integration with Czarina

### Current Integration (v0.7.0 Phase 1)

This deliverable provides:
- ✅ Memory file structure
- ✅ Basic I/O operations (bash + Python)
- ✅ Manual extraction workflow
- ✅ Validation system

### Future Integration (v0.7.0 Phase 2)

Waiting on other workers:
- ⏳ Semantic search (memory-search worker)
- ⏳ CLI commands (cli-commands worker)
- ⏳ Automatic loading in launcher (launcher-enhancement worker)
- ⏳ Index generation (memory-search worker)

### Usage in Orchestration

```bash
# At session start (manual for now)
export CZARINA_MEMORY_CORE=$(./czarina-core/memory-manager.sh read-core)

# Workers can access via environment variable
echo "$CZARINA_MEMORY_CORE"

# At session end
./czarina-core/memory-extract.sh extract
```

## Testing

### Manual Testing Checklist

- [x] Create new memory file with `init`
- [x] Validate empty template
- [x] Read architectural core
- [x] Generate session template
- [x] Append session via bash
- [x] Validate after append
- [x] Read sessions via Python
- [x] Check statistics
- [x] Interactive extraction (dry run)

### Automated Tests

```bash
# Run basic tests
cd tests/
./test_memory_core.sh
```

## Troubleshooting

### "Memory file not found"
```bash
# Initialize the memory file first
./czarina-core/memory-manager.sh init "Project Name"
```

### "Validation failed: Missing required section"
```bash
# Check the template structure
./czarina-core/memory-manager.sh stats

# Manually inspect
cat .czarina/memories.md
```

### "Session not properly formatted"
```bash
# Use the template generator
./czarina-core/memory-extract.sh template

# Or use interactive extraction
./czarina-core/memory-extract.sh extract
```

## Environment Variables

- `CZARINA_MEMORY_FILE`: Path to memories.md (default: `.czarina/memories.md`)
- `CZARINA_MEMORY_INDEX`: Path to memories.index (default: `.czarina/memories.index`)

## Files Delivered

```
czarina-core/
├── memory-manager.sh      # Bash memory operations
├── memory_manager.py      # Python memory module
└── memory-extract.sh      # Interactive extraction workflow

.czarina/
└── memories.md           # Memory file template

docs/
└── MEMORY_CORE_README.md # This documentation
```

## Success Criteria

- [x] memories.md schema implemented
- [x] File I/O operations working (bash/python)
- [x] Template file created
- [x] Manual extraction workflow documented
- [x] Basic validation implemented

## Next Steps

This worker's deliverable is complete. The following workers will extend this foundation:

1. **memory-search**: Implement semantic search and vector indexing
2. **cli-commands**: Add CLI commands (`czarina memory query`, `czarina memory extract`)
3. **launcher-enhancement**: Auto-load memory in worker context
4. **integration**: End-to-end testing and integration

## References

- **Specification**: `/czarina/czarina_memory_spec.md`
- **Integration Plan**: `/czarina/INTEGRATION_PLAN_v0.7.0.md`
- **Hopper Enhancement**: `.czarina/hopper/enhancement-memory-architecture.md`
- **Worker Instructions**: `.czarina/workers/memory-core.md`

## Version History

- **0.7.0-alpha**: Initial implementation (2025-12-28)
  - Memory file template
  - Bash and Python I/O operations
  - Interactive extraction workflow
  - Validation system

---

**Status**: ✅ Complete
**Worker**: memory-core
**Phase**: 1 (Foundation)
**Dependencies**: None
**Blocked By**: None
**Blocks**: memory-search, launcher-enhancement
