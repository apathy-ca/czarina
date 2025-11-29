# Czarina - Multi-Agent Orchestration System

**The bestestest little orchestrator for managing parallel Claude Code workers!** 👑

## What is Czarina?

Czarina orchestrates multiple Claude Code agents working in parallel on a single codebase. Each agent (worker) gets:
- A dedicated git branch
- A specific task prompt
- Clear git workflow instructions
- Real-time progress tracking

## Quick Start

```bash
# 1. See available projects
./czarina list

# 2. Initialize git branches for workers
./czarina init <project-name>

# 3. Launch dashboard (in one terminal)
./czarina dashboard <project-name>

# 4. Launch workers (in another terminal)
./czarina launch <project-name>
```

That's it! Watch the dashboard as workers execute their tasks in parallel.

## Commands

### `czarina list`
List all available orchestration projects.

```bash
$ ./czarina list
📋 Available projects:
  • sark-v2              - SARK v2.0 - Protocol-Agnostic Transformation
```

### `czarina init <project>`
Initialize git branches for all workers in the project.

**What it does:**
- Checks out and updates `main`
- Creates a branch for each worker (defined in config)
- Pushes branches to remote
- Preserves existing branches with work

```bash
$ ./czarina init sark-v2
🌿 Initializing git branches for: sark-v2

→ Processing: engineer1
  Branch: feat/v2-lead-architect
  ✅ Branch created and pushed

→ Processing: engineer2
  Branch: feat/v2-http-adapter
  ✅ Branch created and pushed
...
```

**💡 Always run this before launching workers!**

### `czarina dashboard <project>`
Launch real-time monitoring dashboard.

**Shows:**
- Worker status (pending/active/PR/merged)
- Branches and commit activity
- Files changed per worker
- PR status and approvals
- Project checkpoints
- Overall progress statistics

```bash
$ ./czarina dashboard sark-v2
🎯 Czarina Dashboard - sark-v2
   Press Ctrl+C to exit

┌────────────────────────────────────────────────────────┐
│ SARK v2.0 - Protocol-Agnostic Transformation           │
│ Started: 2024-11-28 | Phase: week-2                    │
└────────────────────────────────────────────────────────┘

┌─ Worker Status ────────────────────────────────────────┐
│ Worker      Status      Branch              Files  PR  │
│ engineer-1  💻 Active   feat/v2-lead-...   12     -   │
│ engineer-2  🔄 PR #42   feat/v2-http-...   8      👍2 │
...
```

Updates every 5 seconds automatically.

### `czarina launch <project>`
Launch workers in tmux sessions.

Opens organized tmux layout with:
- Worker panes (with prompt file paths)
- Monitoring pane (orchestrator commands)
- Git activity monitor (auto-refresh)

```bash
$ ./czarina launch sark-v2
🚀 Launching workers with launch_week2.sh...
```

**Tmux controls:**
- Switch panes: `Ctrl+b` then arrow keys
- Switch windows: `Ctrl+b` then 0-5
- Detach: `Ctrl+b` then `d`
- Reattach: `tmux attach -t sark-v2-week1`

### `czarina status <project>`
Show project configuration and worker assignments.

```bash
$ ./czarina status sark-v2
📊 Project: sark-v2
   Location: /home/.../projects/sark-v2-orchestration

Workers:
  • engineer1    → feat/v2-lead-architect         (Lead Architect & MCP Adapter)
  • engineer2    → feat/v2-http-adapter           (HTTP/REST Adapter)
  • engineer3    → feat/v2-grpc-adapter           (gRPC Adapter)
...
```

## Project Structure

```
projects/
└── myproject-orchestration/
    ├── config.sh              # Project configuration
    ├── prompts/
    │   └── sark-v2/
    │       ├── ENGINEER-1.md  # Worker task prompts
    │       ├── ENGINEER-2.md
    │       └── ...
    ├── launch_week1.sh        # Worker launch scripts
    ├── launch_week2.sh
    └── status/                # Runtime status tracking
```

## Setting Up a New Project

### 1. Create Project Structure

```bash
mkdir -p projects/myproject-orchestration/{configs,prompts,workers,status,logs}
cd projects/myproject-orchestration
```

### 2. Create `config.sh`

```bash
cat > config.sh <<'EOF'
#!/bin/bash

# Project settings
export PROJECT_ROOT="/home/user/repos/myproject"
export PROJECT_NAME="My Project v1.0"
export ORCHESTRATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Worker definitions
# Format: worker_id|branch_name|task_file|description
export WORKER_DEFINITIONS=(
    "engineer1|feat/component-a|prompts/ENGINEER-1.md|Component A Implementation"
    "engineer2|feat/component-b|prompts/ENGINEER-2.md|Component B Implementation"
    "qa1|feat/testing|prompts/QA-1.md|Integration Testing"
    "docs1|feat/documentation|prompts/DOCS-1.md|Documentation"
)

# Omnibus branch (optional - for merging all worker branches)
export OMNIBUS_BRANCH="feat/v1-omnibus"
export OMNIBUS_MERGE_ORDER=("engineer1" "engineer2" "qa1" "docs1")

# Project checkpoints (optional)
export CHECKPOINTS=(
    "week1_foundation|Week 1: Foundation Complete"
    "week2_features|Week 2: Features Complete"
    "week3_testing|Week 3: Testing Complete"
    "week4_docs|Week 4: Documentation Complete"
)
EOF
```

### 3. Create Worker Prompts

Option A: **Write prompts manually** (include git workflow!)

```bash
mkdir -p prompts
cat > prompts/ENGINEER-1.md <<'EOF'
# ENGINEER-1: Component A Implementation

## Role
backend_engineer

## Skills
python, fastapi, databases

## Responsibilities
- Implement Component A core logic
- Add unit tests
- Create integration examples

## Deliverables
- src/component_a.py
- tests/test_component_a.py
- examples/component_a_example.py

## Instructions
You are ENGINEER-1 working on My Project v1.0.

**Your mission:** Implement Component A

**Working directory:** /home/user/repos/myproject

## 🔀 Git Workflow Instructions

[Include the full git workflow template here]
...
EOF
```

Option B: **Generate prompts from templates**

```bash
# If you have base prompts without git workflow:
../../czarina-core/generate-prompts.sh \
  config.sh \
  prompts-base \
  prompts
```

### 4. Create Launch Script (Optional)

```bash
cat > launch.sh <<'EOF'
#!/bin/bash
SESSION_NAME="myproject-workers"
PROJECT_DIR="/home/user/repos/myproject"
ORCHESTRATOR_DIR="$(dirname "$0")"

tmux new-session -d -s $SESSION_NAME -c $PROJECT_DIR

# Add worker panes, etc.
# See: projects/sark-v2-orchestration/launch_week1.sh for full example

tmux attach-session -t $SESSION_NAME
EOF

chmod +x launch.sh
```

### 5. Initialize & Launch

```bash
cd ../..  # Back to orchestrator root

# Initialize branches
./czarina init myproject

# Launch dashboard
./czarina dashboard myproject

# Launch workers (in another terminal)
./czarina launch myproject
```

## Worker Prompt Best Practices

### ✅ Must Have

1. **Git workflow instructions** - Use the template!
   - Location: `czarina-core/templates/WORKER_GIT_WORKFLOW.md`
   - Includes branch setup, commit conventions, PR workflow

2. **Clear task description** - What to build
3. **Deliverables list** - Specific files to create
4. **Dependencies** - What this worker needs from others
5. **Working directory** - Where to execute

### ❌ Common Mistakes

- ❌ No git workflow instructions (workers commit to main!)
- ❌ Vague deliverables (worker doesn't know what to create)
- ❌ Missing dependencies (worker blocked on other workers)
- ❌ Wrong branch name (doesn't match config.sh)

## Git Workflow

### Worker Workflow (Automated in Prompts)

```bash
# 1. Create branch
git checkout -b feat/my-task

# 2. Work & commit
git add .
git commit -m "feat(worker-id): implement feature"
git push origin feat/my-task

# 3. Create PR
gh pr create --base main --head feat/my-task
```

### Integration Workflow

```bash
# Review PRs
gh pr list

# Review specific PR
gh pr view 42

# Merge when ready
gh pr merge 42

# Dashboard auto-updates to show merged status
```

## Dashboard Tracking

The dashboard monitors:

1. **Branch Status**
   - ⏸️ Pending - Branch doesn't exist yet
   - 💻 Active - Branch exists with commits
   - 🔄 PR #X - Pull request created
   - ✅ Merged - Work merged to main

2. **Progress Metrics**
   - Files changed per worker
   - Commits per branch
   - PR approval status
   - Overall project completion %

3. **Checkpoints** (if configured)
   - Track milestone completion
   - Based on config.sh CHECKPOINTS array

## Troubleshooting

### Dashboard shows no results

**Problem:** Workers committed to `main` instead of branches

**Solution:**
1. Check commits: `cd $PROJECT_ROOT && git log --oneline main | head -20`
2. For future work: Ensure worker prompts include git workflow
3. Run `czarina init <project>` to set up branches properly

### Worker doesn't know which branch

**Problem:** Worker prompt missing git instructions

**Solution:**
1. Add git workflow section to prompt
2. Use template: `czarina-core/templates/WORKER_GIT_WORKFLOW.md`
3. Or regenerate: `czarina-core/generate-prompts.sh`

### Permission prompts for bash commands

**Problem:** `.bash_allowed` file not configured

**Solution:**
```bash
# Add to project root
cd $PROJECT_ROOT
cat > .bash_allowed <<'EOF'
git *
gh *
npm *
pytest *
*  # Allow all (use in trusted directories only!)
EOF
```

## Advanced Features

### Omnibus Branch

Merge all worker branches into one integration branch:

```bash
# Configure in config.sh
export OMNIBUS_BRANCH="feat/v1-omnibus"
export OMNIBUS_MERGE_ORDER=("worker1" "worker2" ...)

# Create omnibus (script TBD)
./czarina-core/create-omnibus.sh <project>
```

### Checkpoints

Track project milestones:

```bash
# Configure in config.sh
export CHECKPOINTS=(
    "checkpoint_id|Checkpoint Description"
    ...
)

# Dashboard shows checkpoint progress automatically
```

### Multi-Week Launches

Launch subsets of workers for phased development:

```bash
# Week 1: Critical path
./czarina launch sark-v2  # Choose launch_week1.sh

# Week 2: Full team
./czarina launch sark-v2  # Choose launch_week2.sh
```

## Architecture

```
Czarina CLI (czarina)
  ├─ list          → Show available projects
  ├─ init          → Initialize git branches (init-branches.sh)
  ├─ dashboard     → Live monitoring (dashboard.py)
  ├─ launch        → Start workers (launch_*.sh)
  └─ status        → Show config

czarina-core/
  ├─ init-branches.sh       # Create worker branches
  ├─ generate-prompts.sh    # Add git workflow to prompts
  ├─ dashboard.py           # Real-time monitoring
  └─ templates/
      └─ WORKER_GIT_WORKFLOW.md  # Git instructions template

projects/
  └─ <project>-orchestration/
      ├─ config.sh          # Project configuration
      ├─ prompts/           # Worker task prompts
      ├─ launch_*.sh        # Tmux launch scripts
      └─ status/            # Runtime state
```

## Philosophy

**Czarina believes in:**
- ✅ Explicit branch assignment (no guessing!)
- ✅ Clear git workflow in prompts (no mistakes!)
- ✅ Real-time visibility (dashboard!)
- ✅ Parallel execution (tmux!)
- ✅ Controlled integration (PRs!)

**One command to rule them all:**
```bash
./czarina init <project>
```

Then launch, monitor, and merge! 🚀👑

## Contributing

Czarina is designed to be **simple and extensible**.

Want to add features?
1. Add scripts to `czarina-core/`
2. Add commands to `czarina` CLI
3. Update docs
4. Test with real project

Let's make Czarina the bestestest! 💪

## License

[Your license here]

---

**Made with ❤️ and Claude Code**
