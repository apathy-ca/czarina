# Plan: Hopper as Persistent Instruction Store

**Version:** czarina v1.0.0 (post-refactor)
**Status:** Draft
**Created:** 2026-03-14

---

## Problem Statement

Czarina workers lose their context when sessions restart, context windows reset, or
tmux sessions die. The current instruction pipeline has three layers, all ephemeral:

1. `WORKER_IDENTITY.md` — generated at launch time in the worktree; lost when worktree
   is removed
2. `.czarina/workers/<worker-id>.md` — persists in the project repo but requires the
   worker to know to look there; invisible to a worker that gets a fresh session
3. `.czarina-context.md` — built at launch time from optional rules/memory; also
   ephemeral

When a worker drops their thread, they have no way to recover it themselves. The
orchestrator has to manually re-launch and hope the agent re-reads the right files.
Adding work mid-run requires file edits + re-launching the worker. There is no queue.

**The hypothesis:** hopper's local-mode markdown storage (`~/.hopper/tasks/`) solves
this. Task files persist indefinitely, survive session crashes, hold arbitrary markdown
content, support status transitions, and are queryable via CLI. If the full worker
brief lives in a hopper task body, a worker can self-recover after any interruption
with a single command.

---

## Goals

1. Full worker instructions live in hopper task bodies — not only in `.czarina/workers/`
2. Workers can recover their brief after any session loss without orchestrator
   intervention
3. Adding work to a running worker means adding a hopper task — no file edits, no
   re-launch
4. `czarina status` shows live task state (already partially done)
5. Workers self-mark tasks `in_progress` / `completed` as they work
6. The existing `.czarina/workers/<worker-id>.md` files are preserved as the
   source-of-truth for init — hopper is populated from them, not the reverse

---

## Prerequisites

Hopper is a **required** dependency of Czarina. `czarina validate` blocks if hopper is
not installed. All integration points hard-fail rather than degrade gracefully.

## Non-Goals

- Replacing git/tmux/worktree execution machinery
- Using hopper's server or instance hierarchy (local mode only)
- Real-time inter-worker messaging through hopper
- Automatic push notification to workers when new tasks appear (pull model only)

---

## Architecture

### Current Flow

```
czarina init  →  AI generates .czarina/workers/<id>.md
czarina launch →  launch-project-v2.sh
                    → create_worker_window()
                        → git worktree create
                        → cat .czarina/workers/<id>.md to terminal
                        → agent-launcher.sh launch_worker_agent()
                            → create_worker_identity() → WORKER_IDENTITY.md
                            → tmux: "opencode run 'Read WORKER_IDENTITY.md...'"
```

Workers follow: WORKER_IDENTITY.md → ../workers/<id>.md → begin Task 1

**Problem:** If session dies after step 5, worker has nothing. The worktree may be
gone, WORKER_IDENTITY.md gone, context window reset.

### Target Flow

```
czarina init  →  AI generates .czarina/workers/<id>.md  (unchanged)
czarina launch →  hopper-integration.sh: hopper_register_orchestration()
                    → creates hopper project task
                    → for each worker:
                        → hopper_create_worker_task_with_brief()
                            → reads .czarina/workers/<id>.md
                            → writes full content into hopper task description/body
                    → persists task IDs to .czarina/hopper-tasks.json
               →  launch-project-v2.sh  (mostly unchanged)
                    → create_worker_window()
                        → agent-launcher.sh launch_worker_agent()
                            → create_worker_identity()  (updated)
                                → injects hopper task ID + recovery command
                            → tmux: "opencode run 'Your task is in hopper: <cmd>'"
```

Workers follow: one hopper command → full brief, task list, context, everything.

Recovery after any session loss:
```bash
hopper task list --tag worker-<id> --status in_progress
hopper task get <task-id>
```

Adding work mid-run:
```bash
hopper task add "[worker-id] New task: ..." \
  --description "<full instructions>" \
  --tag czarina --tag <project-slug> --tag worker-<id> \
  --priority high
```
Worker picks it up on their next check, no re-launch needed.

---

## Implementation Plan

### Phase 1: Hopper Task Bodies (Core Change)

**Goal:** Worker brief content lives in hopper, not just a one-liner title.

#### 1.1 — `hopper-integration.sh`: Replace `hopper_create_worker_task`

Current `hopper_create_worker_task` writes only a one-liner description from
`config.json`. Replace with `hopper_create_worker_task_with_brief` that reads
`.czarina/workers/<worker-id>.md` and writes it as the task body.

The hopper task model stores description as the markdown `content` field (YAML
frontmatter + body). The body accepts arbitrary markdown. There is no size limit in
local mode — the file is just a `.md` file on disk.

**New function signature:**
```bash
hopper_create_worker_task_with_brief(
  worker_id,
  description,    # one-liner for title
  role,
  project_slug,
  worker_brief_file,   # path to .czarina/workers/<id>.md
  parent_task_id  # optional
)
```

**Implementation approach:**
- Create the task with `hopper task add` using a short title
- Then use `hopper task update <id> --description "$(cat $worker_brief_file)"`
  to write the full content into the task body
- Alternatively, write the `.md` file directly to `~/.hopper/tasks/` with correct
  YAML frontmatter (faster, no round-trip, but couples to hopper internals)
- Prefer the CLI approach for correctness; test size limits empirically

**Update `hopper_register_orchestration`** to call the new function, passing the
worker brief file path (`.czarina/workers/<worker-id>.md`). If the file doesn't exist,
fall back to the current one-liner behavior with a warning.

**Files changed:**
- `czarina-core/hopper-integration.sh` — add `hopper_create_worker_task_with_brief`,
  update `hopper_register_orchestration`

---

#### 1.2 — `launch-project-v2.sh`: Move hopper registration before agent launch

Currently hopper registration is called from `cmd_launch` in the Python CLI *after*
`launch-project-v2.sh` runs. This means hopper task IDs don't exist yet when
`create_worker_identity()` runs inside the launch script.

Move registration to the **start** of `launch-project-v2.sh`, before
`create_worker_window()` is called for any worker. Registration completes, IDs are
persisted to `.czarina/hopper-tasks.json`, then windows are created — so when
`create_worker_identity()` reads the task store, the IDs are already there.

**Change:**
- Remove hopper registration from `cmd_launch` in the Python CLI
- Add it to the top of `launch-project-v2.sh` (after config is loaded, before the
  window-creation loop)
- Source `hopper-integration.sh` at the top of `launch-project-v2.sh`

**Files changed:**
- `czarina-core/launch-project-v2.sh`
- `czarina` (Python CLI) — remove post-launch hopper call from `cmd_launch`

---

#### 1.3 — `agent-launcher.sh`: Update launch prompt to be hopper-first

Currently the `instructions_prompt` sent to agents is:
```
"Read WORKER_IDENTITY.md to learn who you are, then read your full instructions
at ../workers/<worker-id>.md and begin Task 1"
```

Update to make hopper the primary instruction source when a task ID is available:
```
"Your task brief is in hopper. Run:
  hopper task get <task-id>
to read your full instructions, then begin Task 1.

If hopper is unavailable, your instructions are at:
  ../workers/<worker-id>.md"
```

The `WORKER_IDENTITY.md` still serves as orientation (who you are, branch, logging)
but is no longer the pointer to instructions. Instructions come from hopper directly.

**Also update `WORKER_IDENTITY.md` template** (`create_worker_identity` function,
lines 118-205 of `agent-launcher.sh`) to:
- Replace `## Your Instructions` section with a hopper-first section
- Show the exact command to get their brief
- Show the exact command to mark a task `in_progress`
- Show the polling pattern for checking for new tasks
- Keep the fallback reference to `../workers/<id>.md` for the no-hopper case

**Files changed:**
- `czarina-core/agent-launcher.sh` — `create_worker_identity()` and all
  `instructions_prompt` assignments in `launch_opencode()`, `launch_claude()`,
  `launch_aider()`, etc.

---

### Phase 2: Worker Self-Recovery

**Goal:** A worker that loses their session can fully restore their brief without
orchestrator intervention.

#### 2.1 — Recovery command in WORKER_IDENTITY.md

Add a `## If You Lose Context` section to the generated `WORKER_IDENTITY.md`:

```markdown
## If You Lose Context

Your full task brief is always available in hopper. Run:

    hopper task list --tag worker-<id> --status in_progress

Then get your brief:

    hopper task get <task-id>

Mark yourself in progress again:

    hopper task status <task-id> in_progress --force

Your instructions, task list, and success criteria are all in the task body.
```

Since `WORKER_IDENTITY.md` lives in the worktree and the worktree may be gone after
a crash, also add the recovery instruction to the **hopper task body itself** as the
first section. That way the task is self-contained: reading it tells you everything
including how to re-orient.

**Files changed:**
- `czarina-core/agent-launcher.sh` — `create_worker_identity()` template
- `czarina-core/hopper-integration.sh` — prepend recovery header to task body

---

#### 2.2 — `czarina recover` command (new)

Add a new `czarina recover [worker-id]` command to the CLI that:

1. Reads `.czarina/hopper-tasks.json` for task IDs
2. For each worker (or the specified one):
   - Checks if worktree exists — if not, recreates it
   - Checks if `WORKER_IDENTITY.md` exists — if not, re-runs `create_worker_identity()`
   - Checks hopper task status — if `completed`, skips
   - Prints the recovery command the worker should run
3. Optionally re-launches the agent in the existing tmux session if present

This command lets the orchestrator triage a half-dead run without a full re-launch.

**Files changed:**
- `czarina` (Python CLI) — new `cmd_recover()` function and argument parser entry

---

### Phase 3: Task Queue (Mid-Run Assignment)

**Goal:** Add work to a running worker by adding a hopper task — no re-launch, no
file edits.

#### 3.1 — `czarina task add` command (new)

Wrapper around `hopper task add` with czarina context pre-filled:

```bash
czarina task add <worker-id> "Task title" --description "..." [--priority high]
```

This reads the project slug from `.czarina/config.json`, tags the task correctly
(`czarina`, `<slug>`, `worker-<id>`), and confirms the task ID back to the user.

Workers already have polling instructions in their identity (from Phase 2). This
command is the orchestrator-side of the queue.

**Files changed:**
- `czarina` (Python CLI) — new `cmd_task_add()` function
- Argument parser entry in `main()`

---

#### 3.2 — Worker polling pattern in task body

The task body (written by `hopper_create_worker_task_with_brief`) should include a
standard footer injected by czarina:

```markdown
---
## Task Queue

Check for new tasks assigned to you periodically:

    hopper task list --tag worker-<id> --status open

Mark each task in_progress when you start it, completed when done.
Your orchestrator may add tasks here mid-run without re-launching you.
```

This is injected by `hopper-integration.sh` after the worker brief content, not
written by the AI — it's always present and always accurate.

**Files changed:**
- `czarina-core/hopper-integration.sh` — append queue footer in
  `hopper_create_worker_task_with_brief`

---

### Phase 4: Status & Closeout Cleanup

These are smaller changes to make the existing status/closeout plumbing consistent
with the new model.

#### 4.1 — `czarina status`: Richer per-worker output

Current output from `hopper_print_status` shows one line per worker. Extend to show:
- Which task the worker is currently on (by reading hopper task body for a `## Current
  Task` marker if workers maintain one, or by task creation order)
- How many open tasks remain in their queue
- Last updated timestamp from hopper task metadata

This requires reading the full task list per worker (already available via JSON output)
and counting open tasks tagged `worker-<id>`.

**Files changed:**
- `czarina-core/hopper-integration.sh` — extend `hopper_print_status`

---

#### 4.2 — `czarina closeout`: Cancel incomplete tasks, not just complete them

Current `hopper_closeout_orchestration` marks all tasks `completed` regardless of
their actual state. Update to:
- Mark `completed` tasks that are actually `completed` (no change)
- Mark `in_progress` or `open` tasks as `cancelled` with a note
- Leave `blocked` tasks as `blocked` for post-mortem visibility

**Files changed:**
- `czarina-core/hopper-integration.sh` — update `hopper_closeout_orchestration`

---

## File Change Summary

| File | Change | Phase |
|------|--------|-------|
| `czarina-core/hopper-integration.sh` | Add `hopper_create_worker_task_with_brief`; update `hopper_register_orchestration`; add queue footer injection; fix closeout status logic; extend `hopper_print_status` | 1.1, 3.2, 4.1, 4.2 |
| `czarina-core/launch-project-v2.sh` | Source hopper-integration.sh; call `hopper_register_orchestration` before window creation loop | 1.2 |
| `czarina-core/agent-launcher.sh` | Update `create_worker_identity()` template; update all `instructions_prompt` strings to be hopper-first | 1.3, 2.1 |
| `czarina` (Python CLI) | Remove post-launch hopper call from `cmd_launch`; add `cmd_recover`; add `cmd_task_add` | 1.2, 2.2, 3.1 |

---

## Risks and Mitigations

**Risk: hopper task body size limits**
Mitigation: Test with a real worker `.md` file (largest known: 321 lines ~8KB). The
`hopper task update --description` path passes content via shell argument,
which has an OS limit (~2MB on Linux, well above our needs). No issue expected, but
verify empirically in Phase 1.

**Risk: Worker `.md` file missing at launch time**
Mitigation: `hopper_create_worker_task_with_brief` falls back to one-liner description
if the file is absent, and warns. `launch-project-v2.sh` already errors if the worker
`.md` is missing — that check remains.

**Risk: hopper unavailable breaks launch**
Mitigation: All hopper calls remain non-fatal. If hopper is absent, the instructions
fall back to the existing `../workers/<id>.md` path. The instructions_prompt falls back
to the current format. No regression for hopper-less setups.

**Risk: Worker does not follow polling instructions**
Mitigation: This is an agent compliance issue, not a code issue. The instructions are
explicit and in the first thing the agent reads. Worker briefs should include a note
that task queue checking is mandatory between tasks.

**Risk: Task body is stale if `.czarina/workers/<id>.md` is updated after launch**
Mitigation: Document that post-launch edits to worker files should be propagated via
`czarina task add` (adding a delta task) rather than editing the hopper task body
directly. A future `czarina task sync <worker-id>` command could re-push the updated
`.md` to hopper, but that's out of scope for this plan.

---

## Success Criteria

- [ ] A worker whose tmux session dies can recover their full brief with two hopper
      commands, no orchestrator involvement
- [ ] `czarina status` shows per-worker task counts from hopper
- [ ] Adding a task mid-run with `czarina task add <worker-id> "..."` creates a hopper
      task the worker will pick up on their next poll
- [ ] Closeout correctly distinguishes completed vs cancelled tasks
- [ ] All changes are non-fatal when hopper is absent — existing behaviour preserved

---

## Implementation Order

1. **Phase 1.1** — `hopper_create_worker_task_with_brief` (the core data change;
   everything else depends on rich task bodies existing)
2. **Phase 1.2** — Move registration to `launch-project-v2.sh` (fixes the timing
   problem where IDs weren't available at identity-creation time)
3. **Phase 1.3** — Update `instructions_prompt` and `WORKER_IDENTITY.md` template
   (workers now use hopper as primary instruction source)
4. **Phase 2.1** — Recovery section in identity and task body
5. **Phase 3.2** — Queue footer in task body
6. **Phase 3.1** — `czarina task add` command
7. **Phase 2.2** — `czarina recover` command
8. **Phase 4.1/4.2** — Status and closeout cleanup

Phases 1–3.2 are the meaningful behaviour change. Phases 3.1, 2.2, and 4.x are
quality-of-life improvements that can ship separately.
