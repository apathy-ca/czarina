# Worker Identity: cli-commands

**Role:** Code
**Agent:** Aider
**Branch:** feat/v0.7.0-cli-commands
**Phase:** 1 (Foundation)
**Dependencies:** None

## Mission

Add CLI commands to the `czarina` Python script for memory management and enhanced initialization.

## 🚀 YOUR FIRST ACTION

**Examine the existing CLI structure:**

```bash
# Read the czarina CLI script to understand the structure
cat czarina | less

# Find existing command patterns (look for cmd_ functions)
grep "^def cmd_" czarina

# Check how subcommands are implemented
grep -A 5 "subparsers" czarina
```

**Then:** Plan where to add the new memory command group and proceed to Objective 1 (implement memory query).

## Objectives

1. Add `czarina memory query "<task description>"` command
2. Add `czarina memory extract` command (for session end)
3. Add `czarina memory rebuild` command (regenerate index)
4. Add flags to `czarina init`: `--with-rules` and `--with-memory`
5. Update CLI help text and documentation

## Context

The `czarina` CLI is a Python script (1,515 lines) at `/home/jhenry/Source/czarina/czarina`.

New memory commands should:
- Integrate with memory-core's file I/O
- Call memory-search's search functionality
- Follow existing CLI patterns and conventions

## Deliverable

CLI commands working:
```bash
czarina memory query "implement authentication"
czarina memory extract
czarina memory rebuild
czarina init my-project --with-rules --with-memory
```

## Success Criteria

- [ ] `memory query` command implemented
- [ ] `memory extract` command implemented
- [ ] `memory rebuild` command implemented
- [ ] `init --with-rules --with-memory` flags working
- [ ] Help text updated
- [ ] All commands tested and functional

## Implementation Notes

**Integration Points:**
- Import memory-core's file I/O functions
- Import memory-search's query functions
- Update `cmd_init()` for new flags
- Add new command group for memory operations

**Command Behavior:**
- `memory query`: Search and display top 5 relevant memories
- `memory extract`: Prompt for session summary, append to memories.md
- `memory rebuild`: Regenerate memories.index from memories.md
- `init --with-rules`: Create symlink to agent-rules
- `init --with-memory`: Create memories.md template, enable in config

## Notes

- Phase 1, parallel work (no dependencies)
- Using Aider for this worker (good for focused code changes)
- Should integrate with but not duplicate work from memory-core and memory-search
- Reference existing CLI commands for patterns
