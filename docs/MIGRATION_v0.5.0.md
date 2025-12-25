# Migrating to Czarina v0.5.0

**Release Date:** December 2025
**Upgrade Difficulty:** Easy
**Breaking Changes:** None

---

## Overview

Czarina v0.5.0 introduces powerful new features for logging, coordination, and developer experience while maintaining full backward compatibility with v0.4.0. This guide will help you take advantage of the new capabilities.

## What's New

### 1. Structured Logging System
Workers now log to `.czarina/logs/` with both human-readable logs and machine-readable event streams.

**Benefits:**
- Historical audit trail of all worker activity
- Debug issues by reviewing worker logs
- Event stream for programmatic analysis
- Orchestration-level logging for Czar activities

### 2. Session Workspaces
Each orchestration session creates a complete workspace in `.czarina/work/<session-id>/` containing plans, logs, and closeout reports.

**Benefits:**
- Compare planned vs. actual work
- Comprehensive closeout reports with metrics
- Historical record of all sessions
- Better project documentation

### 3. Proactive Coordination
The Czar now actively monitors workers and generates periodic status reports.

**Benefits:**
- Automatic progress tracking
- Early detection of stuck workers
- Integration strategy suggestions
- Reduced manual oversight

### 4. Dependency Enforcement
Workers can now respect dependency chains with configurable orchestration modes.

**Benefits:**
- Sequential dependencies when needed
- Parallel spike mode for exploration
- Dependency graph visualization
- Prevents integration conflicts

### 5. Enhanced UX
Various improvements to make orchestration smoother.

**Benefits:**
- Tmux windows show worker IDs (not generic numbers)
- Commit checkpoint templates in worker definitions
- Improved daemon output with worker activity
- Better documentation

### 6. Fixed Dashboard
The dashboard now properly renders live worker status.

**Benefits:**
- Real-time worker monitoring
- Color-coded status indicators
- Live metrics display
- Better visibility into orchestration

---

## Breaking Changes

**None!** v0.5.0 is fully backward compatible with v0.4.0.

- Existing configurations work without changes
- Old worker definitions continue to function
- No migration of existing data required
- Can upgrade seamlessly

---

## Migration Steps

### Step 1: Update Czarina Binary

```bash
# Pull latest changes
cd ~/Source/GRID/claude-orchestrator  # or wherever you installed czarina
git pull origin main

# Verify version
czarina version
# Should show: Czarina v0.5.0
```

### Step 2: Update .gitignore

Add the new logging and workspace directories to your project's `.gitignore`:

```bash
# Add to .gitignore
echo "" >> .gitignore
echo "# Czarina v0.5.0 - Logs and session workspaces" >> .gitignore
echo ".czarina/logs/" >> .gitignore
echo ".czarina/work/" >> .gitignore
```

**Why:** Logs and session data are temporary artifacts that shouldn't be committed to your repository.

### Step 3: (Optional) Update Worker Definitions

Worker definitions can now include commit checkpoints for better tracking. Update your worker `.md` files to include checkpoint logging:

```markdown
## Tasks

### Task 1: Implement Feature X
**Action:** Add new feature

\`\`\`bash
# Do the work
# ...

# Add checkpoint
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: feature_x_complete" >> .czarina/logs/my-worker.log
\`\`\`
```

**Why:** Checkpoints help track progress and make it easier to debug issues.

### Step 4: (Optional) Configure Orchestration Mode

If your workers have dependencies, add orchestration configuration to `.czarina/config.json`:

```json
{
  "orchestration": {
    "mode": "parallel_spike"
  }
}
```

**Available modes:**
- `parallel_spike` (default) - All workers start immediately for maximum speed
- `sequential_dependencies` - Workers wait for dependencies to complete

**Why:** Choose the mode that best fits your project's needs.

### Step 5: Launch and Enjoy!

That's it! Launch czarina as normal:

```bash
czarina launch
czarina daemon start
```

The new features will automatically be available:
- ✅ Logs appear in `.czarina/logs/`
- ✅ Session workspace created in `.czarina/work/<session-id>/`
- ✅ Czar provides proactive coordination
- ✅ Dashboard shows live status

---

## New CLI Commands

v0.5.0 adds several new commands:

### Logging Commands

```bash
# View worker logs
tail -f .czarina/logs/backend.log

# View orchestration log
tail -f .czarina/logs/orchestration.log

# View event stream
tail -f .czarina/logs/events.jsonl
```

### Session Management

```bash
# Generate closeout report
czarina closeout

# List sessions
ls .czarina/work/
```

### Dependency Management

```bash
# Visualize dependency graph
czarina deps graph

# Check dependencies
czarina deps check
```

---

## Troubleshooting

### Logs not appearing?

Make sure the `.czarina/logs/` directory exists:

```bash
mkdir -p .czarina/logs/
```

### Worker workspace not created?

Check that `.czarina/work/` directory permissions are correct:

```bash
mkdir -p .czarina/work/
chmod 755 .czarina/work/
```

### Dashboard not rendering?

The dashboard fix requires the latest code. Verify you're on v0.5.0:

```bash
czarina version
```

---

## Rollback Instructions

If you need to rollback to v0.4.0:

```bash
cd ~/Source/GRID/claude-orchestrator
git checkout v0.4.0
czarina version  # Verify
```

Your existing configurations and worker definitions will continue to work.

---

## Getting Help

- **Documentation:** See [docs/](../docs/) for detailed guides
- **Issues:** Report bugs at [GitHub Issues](https://github.com/apathy-ca/czarina/issues)
- **Configuration:** See [docs/CONFIGURATION.md](CONFIGURATION.md) for all options
- **Worker Definitions:** See [docs/WORKER_DEFINITIONS.md](WORKER_DEFINITIONS.md) for templates

---

## Next Steps

1. ✅ Upgraded to v0.5.0
2. ✅ Updated .gitignore
3. Explore new logging features
4. Try proactive coordination
5. Configure orchestration modes
6. Generate closeout reports

**Welcome to v0.5.0!** 🎉
