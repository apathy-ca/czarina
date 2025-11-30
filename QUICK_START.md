# Czarina Quick Start Guide

**Get started with multi-agent orchestration in 5 minutes!**

---

## 🚀 Installation (One-Time Setup)

```bash
# 1. Clone Czarina (if you haven't already)
git clone https://github.com/apathy-ca/czarina.git ~/Source/GRID/claude-orchestrator
cd ~/Source/GRID/claude-orchestrator

# 2. Create symlink for easy access from anywhere
ln -s ~/Source/GRID/claude-orchestrator/czarina ~/.local/bin/czarina

# 3. Ensure ~/.local/bin is in your PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 4. Update pattern library
czarina patterns update
```

**That's it! Czarina is now installed and ready to use from anywhere!**

---

## ⚡ Start Your First Project (5 Minutes)

### Step 1: Go to Your Project

```bash
cd ~/my-projects/awesome-app
# Or create a new one:
# mkdir ~/my-projects/awesome-app && cd ~/my-projects/awesome-app
# git init
```

### Step 2: Initialize Czarina

```bash
czarina init
```

**This creates `.czarina/` directory with:**
- `config.json` - Worker configuration
- `workers/` - Worker role definitions
- `status/` - Runtime logs (gitignored)
- `README.md` - Quick reference
- `.worker-init` - Auto-discovery script

### Step 3: Configure Workers

```bash
# Edit configuration
nano .czarina/config.json
```

**Example config:**
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
      "agent": "aider",
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

### Step 4: Define Worker Roles

```bash
# Edit worker prompts (already created as templates)
nano .czarina/workers/backend.md
nano .czarina/workers/frontend.md
nano .czarina/workers/tests.md
```

**Example worker prompt:**
```markdown
# Backend API Developer

## Role
Build the REST API backend for Awesome App

## Responsibilities
- Design and implement REST endpoints
- Database schema and migrations
- Authentication and authorization
- API documentation

## Files
- src/api/
- src/models/
- src/auth/
- tests/api/

## Tech Stack
- Node.js + Express
- PostgreSQL
- JWT auth

## Git Workflow
Branch: feat/backend-api

When complete:
1. Commit changes
2. Push to branch
3. Create PR to main
```

### Step 5: Commit Orchestration

```bash
git add .czarina/
git commit -m "Add Czarina orchestration setup"
```

### Step 6: Launch! 🚀

```bash
# From your project directory
czarina launch

# Or from anywhere
czarina launch awesome-app
```

**Czarina will:**
- Create tmux session with all workers
- Each worker in separate pane
- Git branches auto-created
- Workers ready to receive tasks

### Step 7: Enable Daemon (Optional but Recommended)

```bash
czarina daemon start
```

**The daemon provides:**
- Auto-approval of file operations (95-98% autonomy with Aider)
- Stuck worker detection
- Alert system
- Status monitoring

---

## 📊 Monitor Your Workers

### Check Status

```bash
# From project directory
czarina status

# Or from anywhere
czarina status awesome-app
```

### View Dashboard

```bash
# Attach to tmux session
tmux attach -t czarina-awesome-app

# Tmux navigation:
# - Ctrl+b then arrow keys: Switch panes
# - Ctrl+b then z: Toggle fullscreen
# - Ctrl+b then d: Detach
```

### Check Daemon

```bash
czarina daemon status
czarina daemon logs    # Live log tail
```

---

## 🎯 Give Workers Tasks

### Method 1: Direct in tmux

```bash
# Attach to session
tmux attach -t czarina-awesome-app

# Navigate to worker pane (Ctrl+b then arrows)
# Type your task directly to the worker

# Example:
"Create a new REST endpoint for user registration at POST /api/users/register"
```

### Method 2: Update worker prompts

```bash
# Edit the worker's prompt file
nano .czarina/workers/backend.md

# Add task to the file
# Worker will see it on next initialization
```

---

## 🔄 Review and Merge Work

### Check PRs

```bash
# Workers create PRs when done
gh pr list

# Review specific PR
gh pr view 123
gh pr diff 123

# Merge when ready
gh pr merge 123
```

### Manual Git Review

```bash
# Check worker branches
git branch -a

# View changes
git diff main..feat/backend-api

# Merge locally
git checkout main
git merge feat/backend-api
```

---

## 🎓 Next Steps

### Read the Patterns

```bash
# Error recovery patterns (30-50% faster debugging)
cat ~/Source/GRID/claude-orchestrator/czarina-core/patterns/ERROR_RECOVERY_PATTERNS.md

# Multi-agent patterns (coordination strategies)
cat ~/Source/GRID/claude-orchestrator/czarina-core/patterns/czarina-specific/CZARINA_PATTERNS.md
```

### Scale Up

Start with 2-3 workers, then scale to 5-10 as you gain confidence:

```json
{
  "workers": [
    {"id": "architect", "agent": "claude-code", "description": "System Architect"},
    {"id": "backend-1", "agent": "aider", "description": "Backend Core"},
    {"id": "backend-2", "agent": "aider", "description": "Backend APIs"},
    {"id": "frontend-1", "agent": "aider", "description": "Frontend Components"},
    {"id": "frontend-2", "agent": "aider", "description": "Frontend State"},
    {"id": "tests-unit", "agent": "aider", "description": "Unit Tests"},
    {"id": "tests-integration", "agent": "aider", "description": "Integration Tests"},
    {"id": "docs", "agent": "claude-code", "description": "Documentation"},
    {"id": "devops", "agent": "aider", "description": "DevOps & CI/CD"},
    {"id": "integration", "agent": "windsurf", "description": "Integration Lead"}
  ]
}
```

**Proven:** SARK v2.0 ran 10 workers successfully with 90% autonomy!

---

## 💡 Tips & Tricks

### Use Aider for Maximum Autonomy
- **Aider:** 95-98% autonomy with daemon
- **Claude Code:** 70-80% autonomy (better UI, requires more intervention)

### Clear Role Boundaries
- Assign specific files/directories to each worker
- Avoid overlap in responsibilities
- Use modular architecture

### Monitor Initially
- First session: watch closely
- Check daemon logs: `czarina daemon logs`
- Review PRs carefully
- Learn the patterns

### Document Discoveries
```bash
# Found a useful pattern?
cp ~/Source/GRID/claude-orchestrator/czarina-inbox/templates/FIX_DONE.md \
   ~/Source/GRID/claude-orchestrator/czarina-inbox/patterns/$(date +%Y-%m-%d)-my-pattern.md

# Check what's ready to contribute
czarina patterns pending
```

---

## 🔧 Common Commands

```bash
# Project management
czarina init                    # Initialize in current directory
czarina list                    # List all projects
czarina launch                  # Launch workers (from project dir)
czarina launch <project>        # Launch from anywhere
czarina status                  # Show status

# Daemon management
czarina daemon start            # Start auto-approval
czarina daemon stop             # Stop daemon
czarina daemon logs             # View logs
czarina daemon status           # Check if running

# Pattern library
czarina patterns update         # Get latest patterns
czarina patterns version        # Show version
czarina patterns pending        # List discoveries
czarina patterns contribute     # Contribution guide
```

---

## 🆘 Troubleshooting

### "Workers won't start"
```bash
# Check agent installed
which aider
which claude

# Check config syntax
cat .czarina/config.json | jq .

# Check worker prompts exist
ls -la .czarina/workers/
```

### "Daemon not approving"
```bash
# Check daemon running
czarina daemon status

# Check logs
czarina daemon logs

# Restart daemon
czarina daemon stop
czarina daemon start
```

### "Can't find project"
```bash
# From project directory
cd ~/my-projects/awesome-app
czarina status    # Auto-detects .czarina/

# Or use project name
czarina status awesome-app

# List all projects
czarina list
```

---

## 📚 Learn More

- **[Production Readiness](PRODUCTION_READINESS.md)** - Complete production checklist
- **[Pattern Library](czarina-core/patterns/)** - Error recovery and multi-agent patterns
- **[Documentation Hub](docs/)** - Comprehensive guides
- **[.cursorrules](.cursorrules)** - Development standards

---

## 🎯 Summary

**Installation:**
```bash
ln -s ~/Source/GRID/claude-orchestrator/czarina ~/.local/bin/czarina
czarina patterns update
```

**New Project:**
```bash
cd ~/my-project
czarina init
nano .czarina/config.json
czarina launch
czarina daemon start
```

**That's it!** You're now orchestrating multiple AI agents in parallel! 🚀

**Expected Results:**
- 2-3 workers: 2x speedup
- 5-10 workers: 3-4x speedup (proven in SARK v2.0)
- 90% autonomy with daemon
- Clean PRs for review

**Your workflow repo is ready to orchestrate at scale!** 💪
