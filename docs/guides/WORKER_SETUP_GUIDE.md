# Czarina Worker Setup Guide

## The Czarina Way: Embedded Orchestration

Czarina orchestration lives directly in your project repository as `.czarina/` (similar to `.git/`). This makes orchestration portable, version-controlled, and collaborative.

## Quick Start

### For Project Managers

When setting up orchestration for a project:

```bash
# 1. Go to your project
cd ~/my-projects/awesome-app

# 2. Initialize Czarina (creates .czarina/ directory)
czarina init

# 3. Configure workers
nano .czarina/config.json
nano .czarina/workers/worker1.md

# 4. Commit orchestration setup
git add .czarina/
git commit -m "Add Czarina orchestration"

# 5. Launch workers
czarina launch

# 6. (Optional) Start daemon
czarina daemon start
```

### What `czarina init` Creates

The `init` command creates `.czarina/` in your project with:
1. ✅ `config.json` - Worker configuration
2. ✅ `workers/` - Worker role definitions (markdown files)
3. ✅ `status/` - Runtime logs (gitignored)
4. ✅ `README.md` - Quick reference for workers
5. ✅ `.worker-init` - Auto-discovery script

**Example:**
```bash
$ cd ~/my-projects/awesome-app
$ czarina init

✅ Czarina initialized successfully!

📁 Created in: /home/you/my-projects/awesome-app
📋 Project: awesome-app (awesome-app)

📝 Next steps:
  1. Edit .czarina/config.json - configure workers
  2. Edit .czarina/workers/*.md - define worker roles
  3. git add .czarina/
  4. git commit -m 'Add Czarina orchestration'
  5. czarina launch

💡 Read more: ~/Source/GRID/claude-orchestrator/docs/guides/WORKER_SETUP_GUIDE.md
```

### Worker Prompt Requirements

**Worker prompts define each worker's role and responsibilities.**

Located in `.czarina/workers/`, each worker gets a markdown file that includes:
- Role and responsibilities
- Files they should work on
- Git workflow (branch name, commit/PR process)
- Links to pattern library

**Example worker prompt:**
```markdown
# Backend API Developer

## Role
Build the REST API backend for Awesome App

## Responsibilities
- Design and implement REST endpoints
- Database schema and migrations
- Authentication and authorization

## Files
- src/api/
- src/models/
- src/auth/

## Git Workflow
Branch: feat/backend-api

When complete:
1. Commit changes
2. Push to branch
3. Create PR to main

## Pattern Library
Review before starting:
- czarina-core/patterns/ERROR_RECOVERY_PATTERNS.md
- czarina-core/patterns/CZARINA_PATTERNS.md
```

### For Workers (AI Agents)

Workers discover their role automatically through:

1. **Auto-discovery script:**
   ```bash
   ./.czarina/.worker-init worker1
   ```

2. **Or just say (in Claude Code Web):**
   ```
   "You are worker1"
   ```

The worker prompt will be loaded automatically, showing:
- Your role and responsibilities
- Files you should work on
- Git branch to use
- Pattern library to review

**Follow the git workflow in your prompt!** Each worker should:
1. Work on their assigned branch
2. Commit regularly
3. Create PR when done
4. Wait for review before moving on

## Project Lifecycle

### Initial Setup (Once per project)

```bash
# 1. Go to your project
cd ~/my-projects/awesome-app

# 2. Initialize Czarina
czarina init

# 3. Configure workers
nano .czarina/config.json
nano .czarina/workers/worker1.md

# 4. Commit orchestration
git add .czarina/
git commit -m "Add Czarina orchestration"
```

### Daily Operations

```bash
# From project directory
cd ~/my-projects/awesome-app

# Check status
czarina status

# Launch workers
czarina launch

# Start daemon (optional but recommended)
czarina daemon start

# Monitor via tmux
tmux attach -t czarina-awesome-app
```

### Integration & PRs

```bash
# Workers create PRs when their work is ready

# Review PRs
gh pr list

# Merge PRs
gh pr merge <number>

# Branches are managed automatically by workers
```

## Troubleshooting

### "Workers won't start"

**Cause:** Agent not installed or config syntax error

**Fix:**
1. Check agent installed: `which aider` or `which claude`
2. Check config syntax: `cat .czarina/config.json | jq .`
3. Check worker prompts exist: `ls -la .czarina/workers/`

### "Can't find project"

**Cause:** Not in project directory or project name wrong

**Fix:**
1. From project directory: `cd ~/my-projects/awesome-app && czarina status`
2. Or use project name: `czarina status awesome-app`
3. List all projects: `czarina list`

### "Daemon not approving"

**Cause:** Daemon not running or agent limitation

**Fix:**
1. Check daemon running: `czarina daemon status`
2. Check logs: `czarina daemon logs`
3. Consider using Aider for 95-98% autonomy
4. Restart daemon: `czarina daemon stop && czarina daemon start`

## Best Practices

### ✅ DO

- Initialize Czarina in your project: `czarina init`
- Include git workflow in worker prompts
- Commit .czarina/ to version control
- Use Aider for maximum autonomy (95-98%)
- Review PRs before merging
- Start with 5-10 workers (SARK-proven)

### ❌ DON'T

- Skip the pattern library: `czarina patterns update`
- Launch without configuring workers properly
- Let workers commit directly to `main`
- Merge PRs without reviewing
- Start too small (2-3 workers underutilizes the system)

## Config.json Structure

Located at `.czarina/config.json`:

```json
{
  "project": {
    "name": "Awesome App",
    "slug": "awesome-app",
    "repository": "/home/you/my-projects/awesome-app",
    "orchestration_dir": ".czarina"
  },
  "workers": [
    {
      "id": "backend",
      "agent": "aider",
      "branch": "feat/backend-api",
      "description": "Backend API Developer"
    },
    {
      "id": "frontend",
      "agent": "claude-code",
      "branch": "feat/frontend-ui",
      "description": "Frontend UI Developer"
    },
    {
      "id": "tests",
      "agent": "aider",
      "branch": "feat/test-coverage",
      "description": "Test Engineer"
    }
  ],
  "daemon": {
    "enabled": true,
    "auto_approve": ["read", "write", "commit"]
  }
}
```

## Summary

**The Czarina workflow ensures:**
1. ✅ Orchestration lives in your project (.czarina/)
2. ✅ Every worker has a dedicated branch
3. ✅ Workers know exactly which branch to use
4. ✅ Work is isolated and reviewable
5. ✅ Integration is controlled via PRs

**Quick start:**
```bash
cd ~/my-projects/awesome-app
czarina init
nano .czarina/config.json
czarina launch
```

Then let your AI team build! 🚀
