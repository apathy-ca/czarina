# AGENTS.md - Czarina

## Project Overview

Czarina is a multi-agent orchestration CLI for managing AI worker workflows.

## Build & Test

```bash
# No build step - bash script
# Test by running:
czarina version
czarina status
```

## Memory & Learnings

This project uses [Hopper](https://github.com/apathy-ca/hopper) for persistent memory across sessions.

### On Session Start

Check for relevant context:
```bash
hopper context
```

This shows recent learnings, open tasks, and items flagged for upstream.

### During Work

When you encounter or use something novel (new pattern, unexpected solution, correction to known approach), capture it:
```bash
hopper add "LEARNING: <description>" --tag auto-learned
```

### On Significant Completion

Before ending a session with meaningful work, assess and capture learnings:
```bash
hopper add "LEARNED: <what you discovered>" --tag auto-learned
```

### Querying & Editing Learnings

```bash
hopper ls --tag auto-learned
hopper ls --tag northbound  # Items flagged for upstream
hopper context edit <task-id> --add-tag northbound  # Flag for upstream
hopper context promote <task-id>  # Shortcut for northbound
hopper context dismiss <task-id>  # Archive a learning
```

## Code Style

- Bash scripts should be POSIX-compatible where possible
- Use clear function names
- Document non-obvious behavior

## Knowledge Sources

This project draws from:
- agent-knowledge patterns (embedded in czarina)
- Project-specific patterns in docs/
