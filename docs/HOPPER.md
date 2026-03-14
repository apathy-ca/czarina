# Hopper Integration

**Hopper is a required dependency of Czarina.** It serves as the persistent
instruction store, task queue, and lesson system for all orchestrations.

> **Note:** This document describes Czarina's integration with the
> [Hopper](https://github.com/apathy-ca/hopper) tool. Earlier versions of
> Czarina had an internal `czarina hopper` command (removed in v0.8.0) which
> managed a file-based backlog. That system has been superseded by this
> integration with the standalone Hopper tool.

---

## Why Hopper

The core problem Hopper solves: **workers lose context**. Sessions crash. Context
windows reset. tmux panes die. When a worker loses their thread in the middle of
a complex task, the old approach required the orchestrator to manually re-launch
and hope the worker re-read the right files.

With Hopper:
- The worker's full brief lives in Hopper, not just in an ephemeral file in a worktree
- A worker that loses context runs two commands and is back on task
- No orchestrator intervention needed for session recovery
- Adding work mid-run means adding a Hopper task — no file edits, no re-launch
- Lessons discovered by workers are filed in Hopper and automatically injected
  into subsequent workers' briefs

---

## Installation

```bash
pip install hopper-cli

# Verify
hopper --version
hopper task list    # Should show empty list, no errors
```

Czarina will refuse to launch if hopper is not installed. `czarina validate`
checks this before every launch.

---

## Local Mode

Czarina uses Hopper in **local mode** only. No server required. Tasks are stored
as markdown files at `~/.hopper/` (global) or `.hopper/` (project-embedded,
auto-detected when you're in a project directory).

Hopper defaults to local mode. Czarina's integration scripts use it directly. You never
need to start a Hopper server for Czarina to work.

---

## How Tasks Are Structured

When `czarina launch` runs, Hopper receives:

**One project-level task:**
```
Title:  My Project v1.0.0 phase 1
Tags:   czarina, my-project, phase-1
Status: in_progress
Body:   Czarina orchestration: 3 worker(s)
```

**One task per worker** (full brief as the task body):
```
Title:  [backend] Build the REST API layer
Tags:   czarina, my-project, worker-backend, role-code
Status: open → in_progress when agent starts
Body:   (full content of .czarina/workers/backend.md)
        + any relevant high-confidence lessons from previous work
        + task queue instructions and lesson-filing template
```

All task IDs are persisted to `.czarina/hopper-tasks.json` so Czarina can
look them up for status queries and closeout.

---

## The Worker Experience

A worker's `WORKER_IDENTITY.md` (written into their git worktree at launch)
contains:

1. **Who they are** — role, branch, dependencies
2. **Their Hopper task ID** — the exact command to get their full brief
3. **Recovery instructions** — what to do if they lose context
4. **Lesson-filing template** — pre-filled with their task ID

The first thing every worker does:

```bash
hopper task get task-abc12345 --with-lessons
```

This returns their complete `.czarina/workers/<id>.md` content, plus any
high-confidence lessons from previous workers on this project prepended at the top.

---

## Session Recovery

If a worker loses their session (context reset, crash, tmux pane death):

```bash
# Step 1: Find the task
hopper task list --tag worker-backend --status in_progress

# Step 2: Get the full brief
hopper task get task-abc12345 --with-lessons

# Step 3: Re-mark in progress
hopper task status task-abc12345 in_progress --force
```

No orchestrator needed. No re-launch needed. The brief survives indefinitely.

---

## Adding Work Mid-Run

To queue a new task for a running worker without re-launching:

```bash
hopper task add "[backend] Add rate limiting to the auth endpoint" \
  --description "See RFC in docs/auth-rfc.md for the spec" \
  --tag czarina \
  --tag my-project \
  --tag worker-backend \
  --priority high \
  --non-interactive
```

Workers check for queued tasks between their existing tasks by running:
```bash
hopper task list --tag worker-backend --status open
```
Their brief includes this instruction explicitly.

---

## Lessons System

Workers file lessons when they discover something useful — a pattern that works,
a trap to avoid, a better approach than the brief specified.

**Filing a lesson (copy-pasteable from `WORKER_IDENTITY.md`, pre-filled):**

```bash
hopper lesson add \
  --task task-abc12345 \
  --title "SQLAlchemy async sessions must not be shared between requests" \
  --domain python \
  --confidence high \
  --non-interactive \
  --body "$(cat << 'EOF'
## What Happened
Each request handler was sharing a single session from a module-level variable.

## What Was Learned
SQLAlchemy async sessions are not thread-safe. Each request needs its own
session created via the async context manager pattern.

## Why It Matters
Causes intermittent DetachedInstanceError that is difficult to reproduce.

## Applies To
Any FastAPI + SQLAlchemy async setup. Use Depends(get_db) consistently.
EOF
)"
```

**Lessons are injected automatically** into the next phase's worker briefs. When
`czarina launch` creates a new worker task, it queries for high-confidence lessons
from the project and prepends them under `## Lessons From Previous Work` before
the worker's task content. Workers see them before Task 1.

---

## Status Monitoring

`czarina status` includes a Hopper summary:

```
📬 Hopper:
   Tasks: 4 total  |  ✅ 1 done  |  🔄 2 active  |  📋 1 open  |  🚫 0 blocked

   ✅  qa                    [qa] Write integration tests
   🔄  backend               [backend] Build the REST API layer
   🔄  frontend              [frontend] Build the UI components
   📋  docs                  [docs] Write API documentation
```

Query directly at any time:

```bash
hopper task list --tag my-project               # All project tasks
hopper task list --tag worker-backend           # Specific worker
hopper task get task-abc12345                   # Full task + brief
hopper task get task-abc12345 --with-lessons    # Brief + lessons
hopper lesson list --project my-project         # Lessons filed
```

---

## Closeout

When `czarina closeout` runs, Hopper marks all tasks:

- `in_progress` → `completed`
- `open` → `cancelled` (not reached this phase)
- Project task → `completed`

The closeout report includes a lesson summary:

```
📚 Lessons filed: 5 total (2 high confidence, 2 medium, 1 low)
   View: hopper lesson list --project my-project
```

---

## Context-Aware Storage

Hopper auto-detects which store to use:

| Location | When used | Storage path |
|----------|-----------|-------------|
| Project-embedded | Inside a project with `.hopper/` | `.hopper/tasks/` |
| Global | Anywhere else | `~/.hopper/tasks/` |

Czarina creates `.hopper/` in each project root during `czarina init`. This keeps
project tasks isolated. Workers running inside a project directory automatically
use the project store.

---

## Viewing Lessons Across All Phases

Lessons persist across phase closeouts:

```bash
# All lessons for a project (all phases)
hopper lesson list --project my-project

# High-confidence lessons by domain
hopper lesson list --project my-project --domain python --confidence high

# Full lesson content
hopper lesson get lesson-abc12345

# All lessons globally (all projects)
hopper lesson list
```

---

## Integration Test

To verify the integration is working:

```bash
bash czarina-core/tests/test-hopper-instruction-store.sh
```

52 assertions covering: registration, brief storage, status transitions, session
recovery, lesson injection, closeout, CLI flags, and structural checks.

Add `--verbose` to see Hopper output for each step:

```bash
bash czarina-core/tests/test-hopper-instruction-store.sh --verbose
```

---

## Troubleshooting

**`hopper not found`**
```bash
pip install hopper-cli
```

**`czarina validate` fails on hopper**
```bash
which hopper
hopper --version
hopper task list
```

**Worker can't find their task**
```bash
cat .czarina/hopper-tasks.json
hopper task list --tag worker-<id>
```

**Lesson not injected into next phase brief**

Only `confidence: high` lessons are injected automatically:
```bash
hopper lesson list --project my-project
```

**Tasks not appearing in project context**

Make sure you're in the project directory. Hopper walks up 10 levels to find
`.hopper/`. Use `--tag <project-slug>` to query from anywhere.

---

## Related

- **[QUICK_START.md](../QUICK_START.md)** — Getting started
- **[docs/CONFIGURATION.md](CONFIGURATION.md)** — config.json reference
- **[docs/PHASE_MANAGEMENT.md](PHASE_MANAGEMENT.md)** — Phase lifecycle
- **[Hopper repository](https://github.com/apathy-ca/hopper)**
