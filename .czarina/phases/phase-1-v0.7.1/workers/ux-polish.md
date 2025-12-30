# Worker: UX Polish
## Tmux Window Names + Commit Checkpoints

**Stream:** 3
**Duration:** Week 1-2 (5 days, parallel with foundation)
**Branch:** `feat/ux-improvements`
**Agent:** Cursor (recommended)
**Dependencies:** None (can run parallel)

---

## Mission

Improve user experience with better tmux window naming and structured commit checkpoints in worker definitions. Small but impactful quality-of-life improvements.

## 🚀 YOUR FIRST ACTION

**Locate and examine the tmux window creation logic:**

```bash
# Find where tmux windows are created during launch
grep -n "tmux new-window" czarina

# Check how worker IDs are currently used
jq '.workers[] | {id, agent, description}' .czarina/config.json

# Understand the current window naming pattern
grep -A 5 -B 5 "window.*worker" czarina
```

**Then:** Fix the window naming to use worker IDs instead of generic numbers (Task 1.1).

## Goals

- Tmux windows show worker IDs (security-1, devops) not generic names (worker1, worker2)
- Worker definitions include commit checkpoint instructions
- Users can navigate tmux sessions intuitively
- Git history is clean and incremental
- AI agents auto-launch with instructions loaded (YOLO mode!)
- Zero manual steps to start workers

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
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: worker_init_command" >> .czarina/logs/ux-polish.log
```

---

### Task 3: Auto-Launch Agent System (2 days)

**Enhancement #10 - Discovered during this orchestration!**

The orchestrator had to manually start AI agents in each worker window and provide instructions. This should be automatic!

#### 3.1: Agent Launcher Script
**File:** `czarina-core/agent-launcher.sh` (NEW)

Create script to auto-launch AI agents with instructions:

```bash
#!/bin/bash
# Agent launcher for czarina workers

launch_worker_agent() {
  local worker_id="$1"
  local window_index="$2"
  local agent_type="$3"
  local session="$4"

  local worktree_path=".czarina/worktrees/$worker_id"

  # Change to worktree
  tmux send-keys -t $session:$window_index "cd $worktree_path" C-m

  # Create worker identity file
  create_worker_identity "$worker_id" "$worktree_path"

  case "$agent_type" in
    aider)
      launch_aider "$worker_id" "$window_index" "$session"
      ;;
    claude)
      launch_claude "$worker_id" "$window_index" "$session"
      ;;
    cursor)
      echo "⚠️  Cursor requires manual launch (GUI application)"
      ;;
    *)
      echo "❌ Unknown agent type: $agent_type"
      ;;
  esac
}

create_worker_identity() {
  local worker_id="$1"
  local worktree_path="$2"

  local worker_desc=$(jq -r ".workers[] | select(.id == \"$worker_id\") | .description" .czarina/config.json)
  local worker_branch=$(jq -r ".workers[] | select(.id == \"$worker_id\") | .branch" .czarina/config.json)
  local worker_deps=$(jq -r ".workers[] | select(.id == \"$worker_id\") | .dependencies[]" .czarina/config.json 2>/dev/null || echo "None")

  cat > "$worktree_path/WORKER_IDENTITY.md" << EOF
# Worker Identity: $worker_id

You are the **$worker_id** worker in the czarina orchestration.

## Your Role
$worker_desc

## Your Instructions
Full task list: \$(pwd)/../workers/$worker_id.md

Read it now:
\\\`\\\`\\\`bash
cat ../workers/$worker_id.md | less
\\\`\\\`\\\`

## Quick Reference
- **Branch:** $worker_branch
- **Location:** $worktree_path
- **Dependencies:** $worker_deps

## Your Mission
Read your full instructions, understand your deliverables, and begin with Task 1.

Let's build this! 🚀
EOF

  echo "✅ Created WORKER_IDENTITY.md for $worker_id"
}

launch_claude() {
  local worker_id="$1"
  local window_index="$2"
  local session="$3"

  # Configure Claude settings for auto-approval
  mkdir -p ".czarina/worktrees/$worker_id/.claude"
  cat > ".czarina/worktrees/$worker_id/.claude/settings.local.json" << EOF
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(pytest:*)",
      "Bash(test:*)",
      "Read(/**)",
      "Write(/**)",
      "Edit(/**)",
      "Grep(*)",
      "Glob(*)"
    ]
  }
}
EOF

  # Launch Claude with worker context
  tmux send-keys -t $session:$window_index "claude --permission-mode bypassPermissions 'Read WORKER_IDENTITY.md to learn who you are, then read your full instructions at ../workers/$worker_id.md and begin Task 1'" C-m

  echo "✅ Launched Claude for $worker_id"
}

launch_aider() {
  local worker_id="$1"
  local window_index="$2"
  local session="$3"

  # Create aider startup commands
  cat > ".czarina/worktrees/$worker_id/.aider-init" << EOF
/add ../workers/$worker_id.md
/ask You are the $worker_id worker. Read your instructions in the file I just added and begin with Task 1.
EOF

  # Launch aider with auto-yes and init file
  tmux send-keys -t $session:$window_index "aider --yes-always --load .aider-init" C-m

  echo "✅ Launched aider for $worker_id"
}

# Make executable
chmod +x "$0"
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/agent-launcher.sh
chmod +x czarina-core/agent-launcher.sh
git commit -m "feat(ux): Add agent auto-launch system for workers"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: agent_launcher" >> .czarina/logs/ux-polish.log
```

#### 3.2: Integration into Launch Command
**File:** `czarina` (UPDATE)

Add agent launching after worktree creation:

```bash
# After creating worktrees and tmux windows
echo "🤖 Launching AI agents in worker windows..."

INDEX=1
for worker in $(jq -r '.workers[].id' .czarina/config.json); do
  AGENT=$(jq -r ".workers[] | select(.id == \"$worker\") | .agent" .czarina/config.json)

  # Launch agent in worker window
  ./czarina-core/agent-launcher.sh launch "$worker" "$INDEX" "$AGENT" "czarina-$SLUG"

  sleep 2  # Give agent time to start
  ((INDEX++))
done

echo "✅ All agents launched and initialized"
```

**COMMIT CHECKPOINT:**
```bash
git add czarina
git commit -m "feat(ux): Integrate agent auto-launch into czarina launch"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: launch_integration" >> .czarina/logs/ux-polish.log
```

#### 3.3: Documentation
**File:** `docs/AUTO_LAUNCH.md` (NEW)

Document the auto-launch system:

```markdown
# Agent Auto-Launch System

## Overview

Czarina automatically launches AI agents in worker windows with instructions pre-loaded.

## How It Works

1. `czarina launch` creates tmux windows and worktrees
2. For each worker, creates `WORKER_IDENTITY.md` with role and instructions
3. Launches agent (claude/aider) with auto-approval enabled
4. Agent reads identity file and worker instructions
5. Agent begins Task 1 automatically

## Supported Agents

### Claude Code
- Auto-approval via `--permission-mode bypassPermissions`
- Instructions loaded via initial prompt
- Settings in `.claude/settings.local.json`

### Aider
- Auto-approval via `--yes-always`
- Instructions loaded via `--load .aider-init`

### Cursor
- Manual launch required (GUI application)

## Zero Manual Steps

Before:
- Create windows ✅
- Attach to tmux session ❌
- Start each agent manually ❌
- Provide instructions manually ❌

After:
- Create windows ✅
- Auto-launch agents ✅
- Auto-load instructions ✅
- Workers start immediately ✅
```

**COMMIT CHECKPOINT:**
```bash
git add docs/AUTO_LAUNCH.md
git commit -m "docs(ux): Document agent auto-launch system"
echo "[$(date +%H:%M:%S)] 🎉 WORKER_COMPLETE: All UX polish tasks done including auto-launch!" >> .czarina/logs/ux-polish.log
```

---

## Deliverables

- ✅ Updated `czarina` script (tmux window naming + agent auto-launch)
- ✅ `czarina-core/templates/worker-template.md`
- ✅ `docs/WORKER_DEFINITIONS.md`
- ✅ Updated `QUICK_START.md`
- ✅ `czarina init worker` command
- ✅ `czarina-core/agent-launcher.sh` (auto-launch system)
- ✅ `docs/AUTO_LAUNCH.md`
- ✅ Worker identity files auto-generated
- ✅ Agent settings auto-configured

---

## Success Metrics

- [ ] Tmux windows show worker IDs correctly
- [ ] Template includes checkpoint sections
- [ ] Documentation explains checkpoint best practices
- [ ] `czarina init worker` generates valid template
- [ ] Agents auto-launch with instructions loaded
- [ ] Workers begin Task 1 automatically
- [ ] Zero manual initialization steps required
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
- Enhancement #10: Auto-Launch Agent System (discovered during this orchestration!)
- SARK v1.3.0 orchestration analysis
- Czarina v0.5.0 orchestration analysis (dogfooding!)
