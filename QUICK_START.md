# Czarina Quick Start Guide

**Get multi-agent orchestration running in under 10 minutes.**

---

## Requirements

### Platform
- Linux, macOS, or Windows via WSL
- Native Windows is not supported (requires bash, tmux, git worktrees)

### Dependencies

```bash
# Required system packages
sudo apt install tmux git jq        # Ubuntu/Debian
brew install tmux git jq            # macOS

# Required: Python 3.11+
python3 --version

# Required: Hopper (task queue and persistent instruction store)
pip install hopper-cli

# Required: At least one AI agent
pip install aider-chat              # Aider (highest autonomy, recommended for automation)
# OR: Install OpenCode, Claude CLI, Cursor, Kilocode, Windsurf, etc.
```

**Hopper is required.** Czarina will not launch without it — it is the persistent
instruction store that keeps workers on task across session crashes and context resets.

---

## Installation

```bash
# Clone czarina
git clone https://github.com/apathy-ca/czarina.git ~/czarina

# Add to PATH
ln -s ~/czarina/czarina ~/.local/bin/czarina
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
czarina version
hopper --version
```

---

## Your First Orchestration

### Step 1 — Write a plan

Create a markdown plan for your project. It can be anything from a paragraph to a
detailed specification. The more detailed it is, the better `czarina plan` performs.

```markdown
# My App — Implementation Plan

## Goal
Build a REST API for a task management app.

## Features
- Task CRUD (create, list, update, delete)
- User authentication (JWT)
- PostgreSQL storage
- Full test coverage

## Approach
- FastAPI backend
- SQLAlchemy + Alembic for database
- pytest for tests
- Separate workers for backend, auth, and QA
```

Save it as `docs/plan.md` in your project directory.

### Step 2 — Go to your project

```bash
cd ~/my-projects/my-app
git init   # if not already a git repo
```

### Step 3 — Generate worker structure

```bash
czarina plan docs/plan.md
```

This uses AI to analyze your plan and suggest a worker breakdown — who does what,
which agent is best for each role, and what the branches should be called.

### Step 4 — Initialize the orchestration

```bash
czarina init docs/plan.md
```

This launches OpenCode (or your configured agent) with your plan. The AI will:
- Read your plan in full
- Create `.czarina/config.json` with worker definitions
- Create `.czarina/workers/<id>.md` — a detailed brief for each worker
- Create `.czarina/workers/<id>-knowledge.md` — relevant agent rules per worker

Review the generated files and edit them if needed.

### Step 5 — Validate

```bash
czarina validate
```

Checks that hopper is installed, all agents are available, config is valid, and
worker brief files exist. Fix any errors before launching.

### Step 6 — Launch

```bash
czarina launch
```

This will:
1. Register the orchestration in Hopper (one project task + one task per worker)
2. Store each worker's full brief in their Hopper task
3. Create git worktrees for each worker
4. Open a tmux session with each worker in their own window
5. Start each agent with: "Read WORKER_IDENTITY.md — it has your Hopper task ID
   and the command to get your full brief. Begin Task 1."

### Step 7 — Attach and monitor

```bash
# Attach to the tmux session
tmux attach -t czarina-my-app

# Navigate between workers:
# Ctrl+b then number (0=czar, 1=first worker, 2=second worker, ...)
# Ctrl+b then d to detach

# Or from another terminal:
czarina status
```

### Step 8 — Review and merge

```bash
# Check PRs created by workers
gh pr list

# Review a PR
gh pr diff 1

# Merge when satisfied
gh pr merge 1
```

---

## The Hopper Connection

Czarina uses Hopper as the persistent instruction store. Here is what this means
in practice:

### When a worker starts

Their `WORKER_IDENTITY.md` contains their Hopper task ID. The first thing they do:

```bash
hopper task get task-abc12345 --with-lessons
```

This gives them:
- Their complete task brief (full `.czarina/workers/<id>.md` content)
- Any high-confidence lessons from previous workers on this project
- Recovery instructions if they lose context

### When a worker loses their session

No orchestrator intervention needed. The worker runs:

```bash
# Find their task
hopper task list --tag worker-backend --status in_progress

# Get their full brief
hopper task get task-abc12345 --with-lessons
```

Their entire brief is in Hopper and survives indefinitely.

### When a worker finishes a task

They file any lessons before marking complete:

```bash
hopper lesson add \
  --task task-abc12345 \
  --title "SQLAlchemy async sessions must not be shared between requests" \
  --domain python \
  --confidence high \
  --non-interactive \
  --body "..."

hopper task status task-abc12345 completed --force
```

Those lessons are automatically injected into the next phase's worker briefs.

### Check task state at any time

```bash
# All tasks for this project
hopper task list --tag my-app

# Just worker tasks
hopper task list --tag my-app --tag worker-backend

# With lessons filed
hopper lesson list --project my-app
```

---

## Multi-Phase Projects

For projects that run in sequential phases:

```bash
# Phase 1
czarina init docs/phase-1-plan.md
czarina launch
# ... workers complete their work ...
czarina closeout

# Phase 2 — lessons from phase 1 automatically injected into phase 2 worker briefs
czarina init docs/phase-2-plan.md
czarina launch
```

**What carries forward automatically:**
- High-confidence lessons filed by phase 1 workers appear in phase 2 briefs
- Phase 1 closeout report documents what was learned

**What requires a new init:**
- Worker configuration (new workers for new roles)
- Worker brief content (new tasks for the new phase)

View phase history:
```bash
czarina phase list
cat .czarina/phases/phase-1-v1.0.0/PHASE_SUMMARY.md
```

---

## Common Commands

```bash
# Planning
czarina plan <file>              # AI analysis of a plan file
czarina init <file>              # AI-assisted orchestration setup

# Orchestration
czarina validate                 # Pre-launch check (agents, hopper, config)
czarina launch                   # Start workers
czarina status                   # Project + Hopper task state
czarina closeout                 # Stop and archive

# Phase management
czarina phase list               # Show completed phases
czarina phase close              # Close current phase

# Learnings
czarina learnings show           # Current phase learnings
czarina learnings history        # All phases

# Wiggum Mode (iterative retry with verification)
czarina wiggum '<task>'                               # Run with config defaults
czarina wiggum '<task>' --verify-command 'make test'  # With test gate
czarina wiggum '<task>' --retries 5 --timeout 900     # Custom limits

# Pattern library
czarina patterns update          # Sync latest from agent-knowledge
czarina patterns version         # Show version
```

---

## Configuration Reference

The `.czarina/config.json` file controls the orchestration:

```json
{
  "project": {
    "name": "My App",
    "slug": "my-app",
    "repository": "/home/you/my-projects/my-app",
    "version": "1.0.0",
    "phase": "1"
  },
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "agent": "opencode",
      "branch": "cz1/feat/backend",
      "description": "Build the REST API layer",
      "dependencies": []
    },
    {
      "id": "qa",
      "role": "qa",
      "agent": "opencode",
      "branch": "cz1/feat/qa",
      "description": "Write integration tests",
      "dependencies": ["backend"]
    }
  ]
}
```

**Worker roles:** `code`, `architect`, `qa`, `documentation`, `integration`

**Supported agents:** `opencode`, `claude`, `aider`, `kilocode`, `cursor`,
`windsurf`, `copilot`, `shelley`

**Branch convention:**
- Phase 1 workers: `cz1/feat/<id>`
- Phase 2 workers: `cz2/feat/<id>`
- Release branch: `cz1/release/v1.0.0`

See [docs/CONFIGURATION.md](docs/CONFIGURATION.md) for the full reference.

---

## Troubleshooting

### "hopper not found"

```bash
pip install hopper-cli
hopper --version
```

Hopper is required. Czarina will not launch without it.

### "czarina validate fails"

Run `czarina validate` and read each error. Common issues:
- Missing agent binary (install the agent)
- Missing worker brief file (run `czarina init` or create manually)
- Config JSON syntax error (`jq . .czarina/config.json` to check)

### "Worker lost context mid-task"

The worker recovers themselves:
```bash
hopper task list --tag worker-<id> --status in_progress
hopper task get <task-id> --with-lessons
```

No restart needed. The full brief is in Hopper.

### "tmux session already exists"

```bash
czarina closeout          # Clean shutdown
# or forcibly:
tmux kill-session -t czarina-my-app
```

### "Worker is stuck"

```bash
tmux attach -t czarina-my-app
# Navigate to stuck worker window
# Check what they're doing
# You can type directly to the worker
```

---

## Next Steps

- **[docs/HOPPER.md](docs/HOPPER.md)** — Full Hopper integration guide
- **[docs/guides/CZAR_ROLE.md](docs/guides/CZAR_ROLE.md)** — How to be an effective Czar
- **[docs/CONFIGURATION.md](docs/CONFIGURATION.md)** — Complete config reference
- **[AGENT_COMPATIBILITY.md](AGENT_COMPATIBILITY.md)** — Choose the right agent for each role
- **[docs/MULTI_PHASE_ORCHESTRATION.md](docs/MULTI_PHASE_ORCHESTRATION.md)** — Multi-phase guide
- **[CHANGELOG.md](CHANGELOG.md)** — What's new in each version
