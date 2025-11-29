# Czarina Worker Setup Guide

## Works With Any AI Coding Assistant! 🌍

This guide applies to **all AI coding assistants** - Claude Code, Cursor, GitHub Copilot, Aider, and more. The orchestration is agent-agnostic!

## The Problem We Solved

Previously, AI workers would commit directly to `main` because:
1. Worker prompts had NO git workflow instructions
2. Branches weren't pre-created
3. Dashboard couldn't track progress on `main`

## The Czarina Way: Proper Workflow

### For Project Managers

When setting up a new orchestration project:

```bash
# 1. List available projects
./czarina list

# 2. Initialize git branches for all workers
./czarina init <project-name>

# 3. Launch the dashboard to monitor progress
./czarina dashboard <project-name>

# 4. Launch workers (in another terminal)
./czarina launch <project-name>
```

### What `czarina init` Does

The `init` command:
1. ✅ Checks out `main` and pulls latest
2. ✅ Creates a branch for each worker (from config)
3. ✅ Pushes branches to remote
4. ✅ Preserves existing branches that have work
5. ✅ Offers to recreate empty branches

**Example:**
```bash
$ ./czarina init sark-v2

╔════════════════════════════════════════════════════════════╗
║         Git Branch Initialization for Workers             ║
╚════════════════════════════════════════════════════════════╝

Project: SARK v2.0 - Protocol-Agnostic Transformation
Repository: /home/jhenry/Source/GRID/sark

📥 Updating main branch...

🌿 Initializing worker branches...

→ Processing: engineer1
  Branch: feat/v2-lead-architect
  ✅ Branch created and pushed

→ Processing: engineer2
  Branch: feat/v2-http-adapter
  ✅ Branch created and pushed

...

✅ All worker branches initialized!
```

### Worker Prompt Requirements

**ALL worker prompts MUST include git workflow instructions.**

Use the template at: `czarina-core/templates/WORKER_GIT_WORKFLOW.md`

The template includes:
- Branch creation commands
- Commit message conventions
- PR creation workflow
- Verification checklist

### Generating Worker Prompts with Git Instructions

If you have base prompts without git workflow:

```bash
cd czarina-core

./generate-prompts.sh \
  ../projects/sark-v2-orchestration/config.sh \
  ../projects/sark-v2-orchestration/prompts-base \
  ../projects/sark-v2-orchestration/prompts
```

This will:
1. Read your base prompts (task descriptions only)
2. Inject git workflow instructions with worker-specific values
3. Output complete prompts ready for workers

### For Workers (All AI Assistants)

When you receive your worker prompt (regardless of which AI assistant you use), you'll see clear git instructions:

```markdown
## 🔀 Git Workflow Instructions

**CRITICAL: You MUST follow this git workflow for all your work.**

### 1. Branch Setup (First Thing!)

cd /home/jhenry/Source/GRID/sark
git checkout main
git pull origin main
git checkout -b feat/v2-http-adapter
```

**Follow the instructions exactly!**

### Dashboard Tracking

The dashboard tracks your progress by monitoring:
1. **Branch existence** - Does your assigned branch exist?
2. **Commits** - How many commits ahead of main?
3. **Files changed** - How many files modified?
4. **PR status** - Has PR been created? Merged?

If you don't work on your assigned branch, **the dashboard won't see your work!**

## Project Lifecycle

### Initial Setup (Once per project)

```bash
# 1. Create project structure
mkdir -p projects/myproject-orchestration/{configs,prompts,workers,status,logs}

# 2. Create config.sh with worker definitions
# See: projects/sark-v2-orchestration/config.sh for example

# 3. Create base worker prompts (task descriptions)
# See: projects/sark-v2-orchestration/prompts/ for examples

# 4. Initialize branches
./czarina init myproject
```

### Daily Operations

```bash
# Morning: Check status
./czarina status myproject

# Launch dashboard (keep running in one terminal)
./czarina dashboard myproject

# Launch workers (in another terminal/tmux)
./czarina launch myproject

# Monitor progress in dashboard
# Workers commit to their branches
# Dashboard shows real-time progress
```

### Integration & PRs

```bash
# Workers create PRs when their work is ready
# PR workflow is in the worker prompt template

# Review PRs
gh pr list

# Merge PRs
gh pr merge <number>

# Dashboard updates automatically to show merged status
```

## Troubleshooting

### "Dashboard shows no results"

**Cause:** Workers committed to `main` instead of their branches

**Fix:**
1. Check if work is on main: `git log --oneline main | head -20`
2. For future work: Ensure workers follow git workflow instructions
3. Run `czarina init <project>` to create branches for remaining work

### "Worker doesn't know which branch to use"

**Cause:** Worker prompt missing git workflow section

**Fix:**
1. Update prompt using `generate-prompts.sh`
2. Or manually add git workflow from template
3. Relaunch worker with updated prompt

### "Branch already exists with different work"

**Cause:** `czarina init` found existing branch

**Options:**
1. Keep it (if it has valuable work)
2. Recreate it (if it's stale/wrong)
3. Manually resolve: `git branch -D <branch>` then re-init

## Best Practices

### ✅ DO

- Run `czarina init` before launching workers
- Include git workflow in ALL worker prompts
- Monitor dashboard during worker execution
- Review PRs before merging
- Keep worker branches focused on their assigned tasks

### ❌ DON'T

- Launch workers without initializing branches
- Give workers prompts without git instructions
- Let workers commit directly to `main`
- Merge PRs without reviewing
- Reuse worker branches for different tasks

## Config.sh Structure

```bash
# Project settings
export PROJECT_ROOT="/path/to/repo"
export PROJECT_NAME="My Project v1.0"
export ORCHESTRATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Worker definitions
# Format: worker_id|branch_name|task_file|description
export WORKER_DEFINITIONS=(
    "worker1|feat/task1|prompts/WORKER-1.md|Task 1 Description"
    "worker2|feat/task2|prompts/WORKER-2.md|Task 2 Description"
    ...
)

# Omnibus configuration (optional)
export OMNIBUS_BRANCH="feat/omnibus"
export OMNIBUS_MERGE_ORDER=("worker1" "worker2" ...)

# Checkpoints (optional)
export CHECKPOINTS=(
    "week1_foundation|Week 1: Foundation"
    "week2_features|Week 2: Features"
    ...
)
```

## Multi-Agent Considerations

### Using Different AI Assistants

Workers can use **different AI coding assistants** on the same project!

**How it works:**
- ✅ All agents read the same markdown prompts
- ✅ All agents follow the same git workflow
- ✅ Dashboard tracks all agents via git (agent-agnostic)
- ✅ PRs integrate work regardless of which agent created them

**Example team:**
```
Engineer 1: Claude Code (web, mobile-friendly)
Engineer 2: Cursor (desktop IDE, debugging)
QA 1: Aider (CLI, automation)
Docs 1: GitHub Copilot (GitHub integration)
```

### Agent-Specific Setup

**No special setup needed!** The file-based architecture works with any agent.

**Discovery patterns vary by agent:**
- **Claude Code:** "You are Engineer 1" (auto-discovery)
- **Cursor:** `@czarina-project/workers/engineer-1.md` (file reference)
- **Aider:** `aider --read czarina-project/workers/engineer-1.md` (CLI)
- **Copilot:** "Read czarina-project/workers/engineer-1.md" (chat)

**See [AGENT_COMPATIBILITY.md](AGENT_COMPATIBILITY.md) for detailed agent-specific instructions.**

### Benefits of Agent-Agnostic Design

1. **Team Flexibility**
   - Each developer uses their preferred tool
   - No need to standardize on one AI assistant
   - New team members can use familiar tools

2. **Future-Proof**
   - Works with AI assistants that don't exist yet
   - No vendor lock-in
   - No API dependencies to break

3. **Testing & Validation**
   - Test with multiple agents
   - Verify behavior across tools
   - Increase confidence in prompts

## Summary

**The Czarina workflow ensures:**
1. ✅ Every worker has a dedicated branch
2. ✅ Workers know exactly which branch to use (in their prompt)
3. ✅ Dashboard can track progress in real-time (via git)
4. ✅ Work is isolated and reviewable (via branches)
5. ✅ Integration is controlled via PRs
6. ✅ **Any AI coding assistant can participate** (agent-agnostic)

**One command to set it all up:**
```bash
./czarina init <project>
```

Then launch with your preferred AI assistant and monitor! 🚀
