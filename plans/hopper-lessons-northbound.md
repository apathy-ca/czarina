# Plan: Lessons Northbound via Hopper

**Status:** Draft
**Created:** 2026-03-14
**Depends on:** `hopper-instruction-store.md` (hopper as persistent instruction store)
**Prerequisite:** Hopper is a required dependency of Czarina — not optional.

---

## The Problem

When a worker discovers something — a pattern that works, a trap to avoid, a better
approach than what the plan specified — that knowledge dies with the session. At best
it ends up in a commit message. It never reaches other workers in the same phase,
workers in phase 2, or any future orchestration.

The existing czarina `memories.md` and `learnings/` system captures some of this but
requires the Czar to manually extract and file it, has no standard format, and has no
durable store that survives across projects.

Hopper's existing learning system (`feedback`, `episodes`, `patterns`) is built around
routing decisions — wrong tool for this. We need a first-class **lesson** concept in
hopper: structured, persistent, and available to any subsequent worker that needs it.

What happens to a lesson after it's in hopper — whether a human promotes it to
agent-knowledge, shares it elsewhere, or just keeps it — is not in scope here. The
goal is getting knowledge out of workers and into a durable, queryable store.

---

## The Northbound Path

```
Worker completes a task
      │
      ▼
Worker files a lesson           ← explicit action: hopper --local lesson add ...
      │                            stored at: ~/.hopper/lessons/
      │
      ▼
Lesson is available to          ← czarina injects relevant lessons into next
subsequent workers                 worker task briefs automatically (read path)
      │
      ▼
Phase closes                    ← czarina summarises lessons filed in closeout report
      │
      ▼
Human decides what's next       ← out of scope
```

Two active steps: worker files, czarina reads back. Everything else is passive.

---

## What a Lesson Is

A lesson is a structured markdown document. It answers specific questions to make it
useful to a future agent reading it cold — not a free-form note.

```markdown
---
id: lesson-<8hex>
title: "One-line summary of what was learned"
source_task: task-<id>
source_worker: <worker-id>
source_project: <project-slug>
domain: python | shell | git | architecture | testing | security | orchestration | general
confidence: low | medium | high
created_at: <iso timestamp>
---

## What Happened

[2-3 sentences: what was being attempted when this was discovered]

## What Was Learned

[The actual lesson: a pattern, anti-pattern, gotcha, or better approach]

## Why It Matters

[Why a future agent should care — what mistake this prevents or what it enables]

## Applies To

[When/where this lesson is relevant: role, language, situation]

## Evidence

[Optional: commit hash, file path, test result]
```

The schema is intentionally minimal. `domain` is the only field czarina uses for
filtering when injecting lessons into worker briefs. `confidence` is the only field
czarina uses to decide whether to surface a lesson prominently or bury it.

---

## Implementation

### Part 1: Hopper — Lesson Storage and CLI

#### 1.1 — Local storage

Add to hopper's markdown storage structure:

```
~/.hopper/
├── tasks/
├── memory/
├── feedback/
└── lessons/               ← NEW
    ├── <lesson-id>.md     ← flat directory, all lessons
    └── .index/
        └── lessons.json   ← searchable index (id, title, domain, project, confidence)
```

No scope subdirectories. Scope hierarchy adds complexity without payoff given the
stated goal. All lessons live in one flat directory. Filtering by project slug,
domain, or confidence is done at query time via the index.

**New files in hopper:**
- `src/hopper/storage/lessons.py` — `LocalLesson` dataclass + `LessonMarkdownStore`
- Update `src/hopper/storage/markdown.py` — add `lessons_path`, rebuild index on write
- Update `src/hopper/storage/memory.py` — expose lesson store via `LocalClient`

---

#### 1.2 — `hopper lesson` CLI commands

New command group. All work in `--local` mode.

```
hopper --local lesson add     File a new lesson
hopper --local lesson list    List lessons (filterable)
hopper --local lesson get     Get full lesson content
```

**`hopper --local lesson add`**

```bash
hopper --local lesson add \
  --task <task-id> \
  --title "SQLAlchemy async sessions must not be shared across tasks" \
  --domain python \
  --confidence high \
  --body "$(cat lesson.md)"
```

All fields required except `--body` (prompted if omitted and stdin is a tty; empty
string accepted for scripted use). `--task` links the lesson to its source task.
`--non-interactive` flag suppresses all prompts — required for scripted worker use.

Outputs the lesson ID on stdout for scripting:
```
✓ Filed lesson: lesson-a3f8c2d1
```

**`hopper --local lesson list`**

```bash
hopper --local lesson list                          # all lessons
hopper --local lesson list --project <slug>         # for a project
hopper --local lesson list --domain python          # by domain
hopper --local lesson list --confidence high        # by confidence
hopper --json --local lesson list --project <slug>  # machine-readable
```

**`hopper --local lesson get`**

```bash
hopper --local lesson get lesson-a3f8c2d1
```

Prints full lesson content (frontmatter + body) to stdout.

**New files in hopper:**
- `src/hopper/cli/commands/lesson.py` — full command group
- Update `src/hopper/cli/main.py` — register `lesson` group
- Update `src/hopper/cli/local_client.py` — `create_lesson`, `get_lesson`,
  `list_lessons` methods

---

#### 1.3 — `--with-lessons` on `hopper task get`

```bash
hopper --local task get <task-id> --with-lessons
```

When this flag is present, hopper appends a `## Relevant Lessons` section to the task
output. It queries lessons matching the task's project slug and any domain tags present
on the task. If no relevant lessons exist, the section is omitted.

This is the read path — the mechanism by which phase 1 lessons reach phase 2 workers
automatically when they first read their brief.

**Files modified in hopper:**
- `src/hopper/cli/commands/task.py` — add `--with-lessons` flag to `get`
- `src/hopper/cli/local_client.py` — `get_task_with_lessons` method

---

### Part 2: Czarina — Write Path (Worker → Hopper)

#### 2.1 — Lesson-filing instructions in every task body

`hopper_create_worker_task_with_brief` appends a footer to every task body. Add a
lesson-filing section with the task ID already substituted — the worker should be able
to copy-paste without editing:

```markdown
---
## On Task Completion

If you discovered something that a future worker should know, file it before marking
this task complete. When in doubt, file it — a filed lesson that isn't useful costs
nothing; a lost lesson costs a future worker hours.

    hopper --local lesson add \
      --task TASK_ID_HERE \
      --title "One line: what was learned" \
      --domain python \
      --confidence high \
      --non-interactive \
      --body "$(cat << 'EOF'
## What Happened
...

## What Was Learned
...

## Why It Matters
...

## Applies To
...
EOF
)"

Then mark complete:

    hopper --local task status TASK_ID_HERE completed --force
```

The task ID is substituted at task-creation time, not filled in by the worker.

**Files changed in czarina:**
- `czarina-core/hopper-integration.sh` — extend task body footer

---

### Part 3: Czarina — Read Path (Hopper → Next Worker)

#### 3.1 — Inject relevant lessons into new worker task briefs

When `hopper_create_worker_task_with_brief` builds a task body, before writing the
worker's instruction content, query hopper for lessons relevant to this worker:

```bash
relevant=$(hopper --json --local lesson list \
  --project "$project_slug" \
  --domain "$worker_domain" \
  --confidence high 2>/dev/null || echo "[]")
```

Map worker role to domain:

| czarina role | hopper domain |
|---|---|
| `code` | `python` (or inferred from project tags) |
| `architect` | `architecture` |
| `qa` | `testing` |
| `documentation` | `general` |
| `integration` | `orchestration` |

If any lessons exist, prepend to the task body:

```markdown
## Lessons From Previous Work

The following lessons were filed by workers on this project. Read these before
starting Task 1.

### [lesson title] (high confidence)
[lesson body]

---
```

If no lessons exist, the section is omitted entirely — no noise.

**Files changed in czarina:**
- `czarina-core/hopper-integration.sh` — add lesson query + injection in
  `hopper_create_worker_task_with_brief`

---

### Part 4: Czarina — Phase Close Summary

#### 4.1 — Lesson count in closeout report

At `closeout-project.sh`, after workers are torn down, query hopper for lessons filed
during this phase and include a summary in the closeout report:

```bash
lessons=$(hopper --json --local lesson list --project "$PROJECT_SLUG" 2>/dev/null || echo "[]")
lesson_count=$(echo "$lessons" | jq 'length')
high_count=$(echo "$lessons" | jq '[.[] | select(.confidence=="high")] | length')
```

Output in the closeout summary:

```
📚 Lessons filed: 7 total (3 high confidence, 3 medium, 1 low)
   View: hopper --local lesson list --project my-project
```

No automatic promotion. No routing decisions. Just a count and the command to view.
What happens to those lessons is the human's call.

**Files changed in czarina:**
- `czarina-core/closeout-project.sh` — add lesson summary block
- `czarina-core/hopper-integration.sh` — add `hopper_lesson_summary` function

---

## File Change Summary

### Hopper

| File | Change |
|------|--------|
| `src/hopper/storage/lessons.py` | New: `LocalLesson` dataclass + `LessonMarkdownStore` |
| `src/hopper/storage/markdown.py` | Add `lessons_path`, lesson index |
| `src/hopper/storage/memory.py` | Expose lesson store |
| `src/hopper/cli/commands/lesson.py` | New: `lesson add`, `list`, `get` |
| `src/hopper/cli/main.py` | Register `lesson` command group |
| `src/hopper/cli/local_client.py` | Add `create_lesson`, `get_lesson`, `list_lessons`, `get_task_with_lessons` |
| `src/hopper/cli/commands/task.py` | Add `--with-lessons` to `get` |

### Czarina

| File | Change |
|------|--------|
| `czarina-core/hopper-integration.sh` | Lesson footer in task body (2.1); lesson injection on brief creation (3.1); `hopper_lesson_summary` function (4.1) |
| `czarina-core/closeout-project.sh` | Add lesson summary to closeout output |

---

## Implementation Order

1. **Hopper storage** (1.1) — `LocalLesson` + `LessonMarkdownStore` + index. No CLI.
   Write unit tests against the store directly.

2. **Hopper local client** (1.2 partial) — `create_lesson`, `get_lesson`, `list_lessons`
   on `LocalClient`. Keeps CLI as a thin layer over the client.

3. **Hopper CLI: `lesson add`, `list`, `get`** (1.2) — Get the basic filing workflow
   working end-to-end. Test with a real lesson file.

4. **Czarina: lesson footer in task body** (2.1) — String append in
   `hopper-integration.sh`. Unblocks workers from filing lessons immediately. Can ship
   before step 5.

5. **Hopper: `--with-lessons` on `task get`** (1.3) — Read path. Requires steps 1-3.

6. **Czarina: lesson injection into briefs** (3.1) — Requires step 5.

7. **Czarina: closeout lesson summary** (4.1) — Requires steps 1-3.

---

## Risks

**Workers don't file lessons.**
The command is copy-pasteable with the task ID pre-filled. It's in the task body
alongside the completion command. This is the best forcing function available short
of making completion conditional on filing — which would be over-engineering. Accept
that some workers won't file. Filed lessons from workers who do are still net positive.

**Lesson quality is low — noise injected into future briefs.**
Only `confidence: high` lessons are injected automatically (section 3.1). Medium and
low lessons are visible via `hopper lesson list` but not injected. Workers set their
own confidence — they are closer to the evidence than any automated signal.

**Role-to-domain mapping is imprecise.**
A `code` worker might be writing shell, not Python. The domain field on `lesson add`
is set by the worker explicitly, not inferred from role. The role-to-domain map in
czarina is only used for the injection query — it's a best-effort filter, not a gate.
A Python lesson filed by a code worker will still be found by a future code worker even
if the role mapping is imprecise, because both use `python` as the domain.

---

## Success Criteria

- [ ] Worker can file a lesson with a single copy-pasted command from their task brief
- [ ] A new worker in the next phase sees relevant high-confidence lessons at the top
      of their task brief before Task 1, with zero orchestrator action
- [ ] `czarina closeout` reports how many lessons were filed during the phase
- [ ] `hopper --local lesson list --project <slug>` returns all filed lessons in JSON
      with full content accessible via `hopper --local lesson get <id>`
