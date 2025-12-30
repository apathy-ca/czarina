# Czarina Quick Start Guide

**Get started with multi-agent orchestration in 5 minutes!**

---

## 💻 Platform Requirements

**Supported Platforms:**
- Linux (Ubuntu, Debian, Fedora, etc.)
- macOS
- Windows via WSL (Windows Subsystem for Linux)

**Required Dependencies:**
- bash shell
- tmux
- git
- Python 3.8+
- jq

**Windows Users:** Czarina requires Unix tooling and cannot run natively on Windows. Install and use WSL.

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
# Basic initialization
czarina init

# Or with v0.7.0 features (recommended!)
czarina init --with-memory --with-rules
```

**This creates `.czarina/` directory with:**
- `config.json` - Worker configuration
- `workers/` - Worker role definitions
- `memories.md` - Persistent memory (v0.7.0+, if --with-memory)
- `status/` - Runtime logs (gitignored)
- `README.md` - Quick reference
- `.worker-init` - Auto-discovery script

**v0.7.0 Features (Optional):**
- `--with-memory` - Enable persistent learning across sessions
- `--with-rules` - Enable 43K+ lines of best practices
- Both features are opt-in and backward compatible

See [MIGRATION_v0.7.0.md](MIGRATION_v0.7.0.md) for details.

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
  "memory": {
    "enabled": true
  },
  "agent_rules": {
    "enabled": true
  },
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "agent": "aider",
      "branch": "feat/backend-api",
      "description": "Backend API Developer"
    },
    {
      "id": "frontend",
      "role": "code",
      "agent": "aider",
      "branch": "feat/frontend-ui",
      "description": "Frontend UI Developer"
    },
    {
      "id": "tests",
      "role": "qa",
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

**v0.7.0 additions:**
- `memory.enabled` - Workers remember past sessions
- `agent_rules.enabled` - Workers get best practices
- `role` field - Determines which rules auto-load (code, qa, documentation, etc.)

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

### Step 7: Assign the Czar Role 🎭

**The Czar** is the orchestration coordinator (can be AI agent or human).

**If using an AI agent (Claude Code, Cursor, etc.):**
```
I am the Czar for this Czarina orchestration.

Project: Awesome App
My responsibilities:
1. Monitor all workers
2. Manage the daemon
3. Track token budgets
4. Coordinate version progression
5. Provide status updates

Show me the current status.
```

**If you're human:**
- Monitor via `czarina status`
- Check workers via `tmux attach -t czarina-awesome-app`
- Manage daemon with `czarina daemon` commands

**See [docs/guides/CZAR_ROLE.md](docs/guides/CZAR_ROLE.md) for complete guide.**

### Step 8: Enable Daemon (Recommended)

```bash
czarina daemon start
```

**The daemon provides:**
- Auto-approval of file operations (95-98% autonomy with Aider)
- Stuck worker detection
- Alert system
- Status monitoring

**As Czar, you monitor the daemon and workers, stepping in only when needed.**

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
czarina init                          # Initialize in current directory
czarina init --with-memory            # Initialize with memory system
czarina init --with-rules             # Initialize with agent rules
czarina init --with-memory --with-rules  # Initialize with both
czarina list                          # List all projects
czarina launch                        # Launch workers (from project dir)
czarina launch <project>              # Launch from anywhere
czarina status                        # Show status

# Memory system (v0.7.0+)
czarina memory init                   # Initialize memory
czarina memory query "<search>"       # Search past sessions
czarina memory extract                # Capture session learnings
czarina memory rebuild                # Rebuild search index
czarina memory status                 # Show memory status

# Daemon management
czarina daemon start                  # Start auto-approval
czarina daemon stop                   # Stop daemon
czarina daemon logs                   # View logs
czarina daemon status                 # Check if running

# Pattern library
czarina patterns update               # Get latest patterns
czarina patterns version              # Show version
czarina patterns pending              # List discoveries
czarina patterns contribute           # Contribution guide
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

## 🔄 Multi-Phase Orchestration (v0.7.2+)

Run sequential development phases on the same codebase with **automatic phase transitions**!

### Quick Multi-Phase Example

```bash
# Phase 1: Core Features (v1.0.0)
cd ~/my-project
czarina analyze docs/phase-1-plan.md --interactive --init
czarina launch --go

# ✅ Autonomous daemon detects when all workers complete
# ✅ Phase 1 automatically archived to .czarina/phases/phase-1-v1.0.0/
# ✅ Ready for Phase 2!

# Phase 2: Security & Performance (v1.1.0)
czarina analyze docs/phase-2-plan.md --interactive --init
czarina launch --go

# ✅ Repeat for as many phases as needed
# ✅ Complete audit trail preserved
```

### What Happens Automatically

**Phase Completion Detection:**
- Monitors worker log markers (`czarina_log_worker_complete`)
- Checks git branch merge status
- Validates worker status files
- Multiple detection modes: `any`, `strict`, `all`

**Phase Archival:**
- Complete config snapshot
- All worker logs and prompts
- Phase summary auto-generated
- Saved to `.czarina/phases/phase-N-vX.Y.Z/`

**Phase History:**
```bash
# View all completed phases
czarina phase list

# Review past phase
cat .czarina/phases/phase-1-v1.0.0/PHASE_SUMMARY.md
```

### Configuration

Add to `.czarina/config.json`:

```json
{
  "project": {
    "phase": 1,
    "omnibus_branch": "cz1/release/v1.0.0"
  },
  "phase_completion_mode": "any",
  "workers": [
    {
      "id": "api",
      "phase": 1,
      "branch": "cz1/feat/api"
    }
  ]
}
```

**Branch Naming Convention:**
- Phase 1: `cz1/feat/*`, `cz1/release/*`
- Phase 2: `cz2/feat/*`, `cz2/release/*`
- Phases are isolated - no branch conflicts

**Complete Guide:** [docs/MULTI_PHASE_ORCHESTRATION.md](docs/MULTI_PHASE_ORCHESTRATION.md)

---

## 📚 Learn More

### v0.7.2 Features
- **[docs/MULTI_PHASE_ORCHESTRATION.md](docs/MULTI_PHASE_ORCHESTRATION.md)** - Multi-phase orchestration guide
- **[docs/CONFIGURATION.md](docs/CONFIGURATION.md)** - Phase completion configuration

### v0.7.0 Features
- **[MEMORY_GUIDE.md](MEMORY_GUIDE.md)** - Memory system usage and best practices
- **[AGENT_RULES.md](AGENT_RULES.md)** - Agent rules integration guide
- **[MIGRATION_v0.7.0.md](MIGRATION_v0.7.0.md)** - Migration from v0.6.2

### Core Documentation
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

**New Project (v0.7.0):**
```bash
cd ~/my-project
czarina init --with-memory --with-rules  # Enable v0.7.0 features
nano .czarina/config.json
czarina launch
czarina daemon start
```

**Or without v0.7.0 features (v0.6.2 behavior):**
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
