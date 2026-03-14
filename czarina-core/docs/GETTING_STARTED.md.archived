# Getting Started with Claude Code Orchestrator

## 🎯 What This Is

A **reusable multi-agent orchestration system** for managing 6+ parallel Claude Code workers on complex projects.

Currently configured for: **SARK v1.1 Gateway Integration**

## 🚀 Quick Start (30 seconds)

```bash
cd /home/jhenry/Source/GRID/claude-orchestrator
./QUICKSTART.sh
```

Choose your adventure:
- **Option 2** - Launch all workers automatically (recommended)
- **Option 3** - Generate prompts for manual Claude Code instances
- **Option 4** - Open live dashboard

## 📝 Configuration

### Current Configuration

The orchestrator is **already configured** for SARK v1.1:

- **Project:** SARK v1.1 Gateway Integration
- **Repository:** `/home/jhenry/Source/GRID/sark`
- **Workers:** 6 (engineer1-4, qa, docs)
- **Branches:** feat/gateway-*
- **Timeline:** 10 days

### To Use for Another Project

Edit **`config.sh`**:

```bash
vim config.sh
```

Change these key variables:

```bash
# Project location
export PROJECT_ROOT="/path/to/your/project"

# Project name (used in titles)
export PROJECT_NAME="Your Project v2.0"

# Define your workers
export WORKER_DEFINITIONS=(
    "worker1|feat/branch1|docs/tasks/worker1.md|Worker 1 Description"
    "worker2|feat/branch2|docs/tasks/worker2.md|Worker 2 Description"
    # ... add more workers
)

# Omnibus branch configuration
export OMNIBUS_BRANCH="feat/your-integration-branch"
export OMNIBUS_MERGE_ORDER=("worker1" "worker2" ...)
```

That's it! The orchestrator will now work with your project.

## 🛠️ Core Tools

### 1. QUICKSTART.sh
One-command launcher with interactive menu.

```bash
./QUICKSTART.sh
```

### 2. dashboard.py
Live monitoring dashboard (reads config automatically).

```bash
./dashboard.py
```

### 3. orchestrator.sh
Main control panel for all orchestration tasks.

```bash
./orchestrator.sh
```

### 4. pr-manager.sh
PR review and merge automation.

```bash
./pr-manager.sh
```

### 5. launch-worker.sh
Launch individual workers in tmux sessions.

```bash
./launch-worker.sh engineer1
```

### 6. validate.sh
Validate that everything is configured correctly.

```bash
./validate.sh
```

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **GETTING_STARTED.md** (this file) | Quick start guide |
| **START_HERE.md** | Visual guide for first-time users |
| **EXECUTIVE_SUMMARY.md** | High-level overview and philosophy |
| **CZAR_GUIDE.md** | Day-by-day workflow and commands |
| **README.md** | Complete technical documentation |
| **config.sh** | Configuration file (edit for your project) |

## 💡 Key Features

### Reusable
Edit `config.sh` and use for any project. No need to modify scripts.

### Configurable
All project-specific settings in one file (`config.sh`).

### No Hardcoded Paths
Everything loads from config - dashboard, scripts, prompts.

### Complete Automation
Launch → Monitor → Review → Merge - minimal manual work.

## 🎭 Your Role

As the "Czar" (orchestrator), you:

1. **Launch workers** (one command)
2. **Monitor progress** (live dashboard)
3. **Review PRs** on Day 8 (or auto-approve)
4. **Merge omnibus** (one command)

**Total time: 4-6 hours over 10 days**

Workers handle:
- Implementation
- Testing
- Documentation
- Daily commits
- Creating PRs

## 🎯 For SARK v1.1 (Current Configuration)

### Timeline

```
Day 1  │ Engineer 1 creates shared models (CRITICAL)
Day 2-3│ All workers develop in parallel
Day 4  │ Integration checkpoint
Day 5-6│ Feature completion
Day 7  │ Testing & refinement
Day 8  │ PRs created, omnibus branch
Day 9  │ Integration testing
Day 10 │ Merge to main! 🎉
```

### Workers

1. **Engineer 1** (feat/gateway-client) - Gateway client & models
2. **Engineer 2** (feat/gateway-api) - API endpoints
3. **Engineer 3** (feat/gateway-policies) - OPA policies
4. **Engineer 4** (feat/gateway-audit) - Audit & monitoring
5. **QA** (feat/gateway-tests) - Testing
6. **Docs** (feat/gateway-docs) - Documentation

### Expected Output

After 10 days:
- ✅ Complete Gateway integration
- ✅ Comprehensive tests (>85% coverage)
- ✅ Full documentation
- ✅ 1 omnibus PR ready to merge

## 🔧 Troubleshooting

### "No such file or directory"
Make sure you're in the orchestrator directory:
```bash
cd /home/jhenry/Source/GRID/claude-orchestrator
```

### "Configuration not found"
Make sure `config.sh` exists and is readable:
```bash
ls -l config.sh
cat config.sh
```

### Dashboard shows wrong project
Edit `config.sh` and update `PROJECT_NAME` and `PROJECT_ROOT`.

### Workers can't find task files
Make sure task files exist in your project repo at the paths specified in `WORKER_DEFINITIONS`.

## ✅ Validation

Before starting, run:

```bash
./validate.sh
```

This checks:
- All required files exist
- Scripts are executable
- Task files are present
- Git is configured
- Dependencies are installed

## 🎸 Ready to Go?

```bash
cd /home/jhenry/Source/GRID/claude-orchestrator
./QUICKSTART.sh
```

Choose option 2, and let the vibecoding begin! 🎉

---

**Version:** 1.0.0
**Status:** ✅ Production Ready
**Location:** `/home/jhenry/Source/GRID/claude-orchestrator`
