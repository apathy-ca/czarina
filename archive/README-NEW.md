# Claude Code Multi-Agent Orchestrator

**A reusable system for managing multiple parallel Claude Code worker instances on any project.**

```
╔═══════════════════════════════════════════════════════════════╗
║  Claude Code Multi-Agent Orchestrator                         ║
║  Coordinate parallel AI workers on complex projects           ║
╚═══════════════════════════════════════════════════════════════╝
```

## 🎯 What Is This?

A complete orchestration system that manages 6+ Claude Code worker instances working in parallel on a complex codebase. Think of it as a **conductor for an AI symphony**.

### Key Features

- ✅ **Multi-Worker Coordination** - Run 6+ Claude instances in parallel
- ✅ **Dependency Management** - Workers can depend on each other's output
- ✅ **Progress Tracking** - Real-time dashboard showing all worker status
- ✅ **PR Automation** - Auto-review, create omnibus branches, merge
- ✅ **tmux Integration** - Each worker in its own manageable session
- ✅ **Checkpoint System** - Track project milestones
- ✅ **Reusable** - Configure once, use on any project

## 🚀 Quick Start (For SARK v1.1)

```bash
cd /home/jhenry/Source/GRID/claude-orchestrator

# 1. Validate everything is ready
./validate.sh

# 2. Launch the quick start menu
./QUICKSTART.sh

# 3. Choose option 2 (Launch all workers in tmux)

# 4. In another terminal, monitor progress
./dashboard.py
```

## 🔧 Adapting for Your Project

### Step 1: Edit `config.sh`

```bash
vim config.sh
```

Change these variables to match your project.

See full configuration guide in the original README.md file.

## 📚 Full Documentation

- **START_HERE.md** - Quick visual guide for first-time users
- **CZAR_GUIDE.md** - Complete day-by-day workflow and commands
- **README.md** (original) - Comprehensive system documentation
- **config.sh** - Configuration file (edit for your project)

## 🛠️ Tools Included

1. **orchestrator.sh** - Main control panel
2. **launch-worker.sh** - Launch workers in tmux
3. **dashboard.py** - Live monitoring dashboard
4. **pr-manager.sh** - PR automation and merge
5. **generate-worker-prompts.sh** - Generate Claude Code prompts
6. **validate.sh** - System validation
7. **QUICKSTART.sh** - One-command launcher

## 📦 What's Included

Configured for SARK v1.1 Gateway Integration:
- 6 workers (engineer1-4, qa, docs)
- 10-day timeline
- 6 checkpoints
- Omnibus branch workflow
- Complete task files

**Reusable for any project** - just edit `config.sh`!

---

**Version:** 1.0.0
**Status:** Production-ready
**Created:** November 27, 2025
