# Worker: UX Polish
## Tmux Window Names + Commit Checkpoints

**Stream:** 3
**Duration:** Week 1-2 (3 days, parallel with foundation)
**Branch:** `feat/ux-improvements`
**Agent:** Cursor (recommended)
**Dependencies:** None (can run parallel)

---

## Mission

Improve user experience with better tmux window naming and structured commit checkpoints in worker definitions. Small but impactful quality-of-life improvements.

## Goals

- Tmux windows show worker IDs (security-1, devops) not generic names (worker1, worker2)
- Worker definitions include commit checkpoint instructions
- Users can navigate tmux sessions intuitively
- Git history is clean and incremental

---

## Tasks

### Task 1: Tmux Window Naming (1 day)

#### 1.1: Fix Window Creation
**File:** `czarina` (UPDATE)

Current behavior:
```bash
tmux new-window -t czarina-$SLUG:1 -n "worker1"
tmux new-window -t czarina-$SLUG:2 -n "worker2"
```

Expected behavior:
```bash
WORKER_ID=$(jq -r ".workers[$i].id" .czarina/config.json)
tmux new-window -t czarina-$SLUG:$((i+1)) -n "$WORKER_ID"
```

**Implementation:**
Locate the tmux window creation logic in the `launch` command and update to use worker `id` field from config.json.

**COMMIT CHECKPOINT:**
```bash
git add czarina
git commit -m "fix(ux): Use worker IDs for tmux window names instead of generic numbers"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: tmux_window_names" >> .czarina/logs/ux-polish.log
```

#### 1.2: Test Window Naming
**Manual Test:**
1. Create test project with .czarina/config.json
2. Run `czarina launch`
3. Use `Ctrl+b w` to list windows
4. Verify windows named: czar, security-1, security-2, etc.

**Document:**
Update QUICK_START.md to show correct window names in examples.

**COMMIT CHECKPOINT:**
```bash
git add QUICK_START.md
git commit -m "docs(ux): Update tmux window naming in quick start guide"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: window_naming_docs" >> .czarina/logs/ux-polish.log
```

---

### Task 2: Commit Checkpoint Templates (2 days)

#### 2.1: Create Checkpoint Template
**File:** `czarina-core/templates/worker-template.md` (NEW)

Create standard worker definition template with checkpoint sections:

```markdown
# Worker: {{WORKER_ID}}
## {{DESCRIPTION}}

**Stream:** {{STREAM_NUMBER}}
**Duration:** {{DURATION}}
**Branch:** {{BRANCH_NAME}}
**Agent:** {{AGENT_TYPE}}
**Dependencies:** {{DEPENDENCIES}}

---

## Mission

{{MISSION_DESCRIPTION}}

---

## Tasks

### Task 1: {{TASK_NAME}} ({{DURATION}})

#### 1.1: {{SUBTASK_NAME}}
**File:** {{FILE_PATH}} (NEW/UPDATE)

{{IMPLEMENTATION_DETAILS}}

**COMMIT CHECKPOINT:**
\```bash
git add {{FILES}}
git commit -m "{{COMMIT_MESSAGE}}"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: {{CHECKPOINT_ID}}" >> .czarina/logs/{{WORKER_ID}}.log
\```

---

## Deliverables

- ✅ {{DELIVERABLE_1}}
- ✅ {{DELIVERABLE_2}}

---

## Success Metrics

- [ ] {{METRIC_1}}
- [ ] {{METRIC_2}}
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/templates/worker-template.md
git commit -m "feat(ux): Add worker definition template with commit checkpoints"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: worker_template" >> .czarina/logs/ux-polish.log
```

#### 2.2: Document Checkpoint Best Practices
**File:** `docs/WORKER_DEFINITIONS.md` (NEW)

```markdown
# Writing Worker Definitions

## Commit Checkpoints

Workers should commit frequently to preserve incremental progress.

### When to Add Checkpoints

- After each subtask (1.1, 1.2, etc.)
- After creating substantial files (>100 lines)
- After completing a logical unit of work
- Before switching contexts

### Checkpoint Format

\```bash
**COMMIT CHECKPOINT:**
\```bash
git add <files>
git commit -m "<conventional-commit-message>"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: <checkpoint_id>" >> .czarina/logs/<worker-id>.log
\```
\```

### Conventional Commit Messages

- `feat(worker): Add new feature`
- `fix(worker): Fix bug`
- `docs(worker): Update documentation`
- `test(worker): Add tests`
- `refactor(worker): Refactor code`

### Checkpoint IDs

Use descriptive IDs: `task_1.1_complete`, `database_schema`, `api_endpoints`
```

**COMMIT CHECKPOINT:**
```bash
git add docs/WORKER_DEFINITIONS.md
git commit -m "docs(ux): Add worker definition best practices guide"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: checkpoint_docs" >> .czarina/logs/ux-polish.log
```

#### 2.3: CLI Command for Template
**File:** `czarina` (UPDATE)

Add `czarina init worker <worker-id>` command:
```bash
init)
  case "$2" in
    worker)
      WORKER_ID="$3"
      if [ -z "$WORKER_ID" ]; then
        echo "Usage: czarina init worker <worker-id>"
        exit 1
      fi

      # Generate worker definition from template
      cat czarina-core/templates/worker-template.md | \
        sed "s/{{WORKER_ID}}/$WORKER_ID/g" \
        > ".czarina/workers/$WORKER_ID.md"

      echo "✅ Created .czarina/workers/$WORKER_ID.md"
      echo "Edit this file to define tasks and checkpoints."
      ;;
    *)
      # Existing init logic
      ;;
  esac
  ;;
```

**COMMIT CHECKPOINT:**
```bash
git add czarina
git commit -m "feat(ux): Add 'czarina init worker' command for template generation"
echo "[$(date +%H:%M:%S)] 🎉 WORKER_COMPLETE: All UX polish tasks done" >> .czarina/logs/ux-polish.log
```

---

## Deliverables

- ✅ Updated `czarina` script (tmux window naming)
- ✅ `czarina-core/templates/worker-template.md`
- ✅ `docs/WORKER_DEFINITIONS.md`
- ✅ Updated `QUICK_START.md`
- ✅ `czarina init worker` command

---

## Success Metrics

- [ ] Tmux windows show worker IDs correctly
- [ ] Template includes checkpoint sections
- [ ] Documentation explains checkpoint best practices
- [ ] `czarina init worker` generates valid template
- [ ] All manual tests pass

---

## Testing Checklist

### Tmux Window Naming
1. Create test orchestration
2. Run `czarina launch`
3. Verify window names: czar, worker1 → security-1, etc.
4. Test `Ctrl+b w` navigation

### Worker Template
1. Run `czarina init worker test-worker`
2. Verify template generated
3. Check placeholders replaced correctly
4. Validate markdown formatting

---

## Integration Notes

This worker is independent and can run in parallel with:
- `foundation`
- `coordination`
- `dependencies`
- `dashboard`

No dependencies on other workers.

---

## References

- Enhancement #3: Tmux Window Naming
- Enhancement #5: Commit Checkpoints
- SARK v1.3.0 orchestration analysis
