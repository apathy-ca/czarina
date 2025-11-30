# Czarina Autonomous Daemon

**Automates worker approvals so you never have to manually intervene.**

## Overview

The Czarina daemon monitors all workers and automatically approves requests, accepts edits, and handles prompts. This reduces human intervention from ~100% to <5%.

**Philosophy**: "In an ideal world, I'm not here at all." - The daemon embodies this by making all routine decisions automatically.

## Quick Start

### Using the CLI (Recommended)

```bash
# Start daemon for a project
czarina daemon start <project-name>

# Check if running
czarina daemon status <project-name>

# View logs (live tail)
czarina daemon logs <project-name>

# Stop daemon
czarina daemon stop <project-name>
```

### Direct Usage

```bash
# From project embedded orchestration directory
cd /path/to/project/czarina-myproject
../path/to/czarina-core/daemon/start-daemon.sh .

# Or with absolute path
/path/to/czarina-core/daemon/start-daemon.sh /path/to/project/czarina-myproject
```

## What the Daemon Does

Every **2 minutes**, the daemon checks all worker windows and:

### 1. Auto-Approves File Access
When workers ask: "Do you want to proceed?"
- **Decision**: Always selects option 2 (allow reading)
- **Rationale**: Workers need access to orchestration files

### 2. Auto-Accepts Edits
When workers propose edits: "accept edits on"
- **Decision**: Always accepts (presses Enter)
- **Rationale**: Workers propose valid changes

### 3. Auto-Confirms Y/N Prompts
When workers ask Y/N questions
- **Decision**: Defaults to "yes"
- **Rationale**: Trust worker judgment

### 4. Nudges Idle Workers
When workers are at prompt but appear done
- **Decision**: Sends Enter to confirm/continue
- **Rationale**: Workers may be waiting for confirmation

### 5. Monitors for Issues
Detects and logs (but doesn't auto-handle):
- Explicit questions tagged for Czar (`@czar`)
- Fatal/critical errors
- Workers explicitly blocked

## Requirements

- **tmux**: Workers must be running in tmux session
- **jq**: For reading JSON configuration
- **Embedded orchestration**: Project must have `czarina-*/` directory with `config.json`

## Architecture

```
┌─────────────────────────────────────────────────┐
│      Czarina Daemon (tmux: project-daemon)      │
│  Runs czar-daemon.sh every 2 minutes            │
└─────────────────┬───────────────────────────────┘
                  │
                  ├─> Check all worker windows
                  │   (project-session:0-N)
                  │
                  ├─> Auto-approve requests
                  │   ├─ File access
                  │   ├─ Edit acceptance
                  │   └─ Y/N prompts
                  │
                  ├─> Detect blocking issues
                  │   ├─ @czar questions
                  │   └─ Fatal errors
                  │
                  └─> Log everything
                      └─ status/daemon.log
```

## Configuration

The daemon reads configuration from `config.json` in the embedded orchestration directory:

```json
{
  "project": {
    "slug": "myproject",
    "repository": "/path/to/repo"
  },
  "workers": [
    { "id": "engineer1", "branch": "feat/task1", ... }
  ]
}
```

### Key Config Values:
- `project.slug`: Used for tmux session name (`{slug}-daemon`)
- `project.repository`: For git activity tracking
- `workers`: Array length determines number of windows to monitor

## Logs

Daemon logs are written to: `czarina-<project>/status/daemon.log`

### Log Format:
```
=== Iteration 1 - 2025-11-29 13:00:00 ===
[13:00:01] Auto-approving window 0
[13:00:02] Auto-accepting edits in window 1
[13:00:05] ✅ Auto-approved 5 items
[13:00:10] Commits in last 20 min: 3
```

## Troubleshooting

### Daemon won't start
```bash
# Check if already running
czarina daemon status <project>

# If stuck, force stop and restart
tmux kill-session -t <project>-daemon
czarina daemon start <project>
```

### Workers still waiting for approval
```bash
# Check daemon logs
czarina daemon logs <project>

# Verify daemon is monitoring correct session
tmux ls  # Should see both <project>-session and <project>-daemon
```

### Want faster/slower checks
Edit `czar-daemon.sh` and change:
```bash
SLEEP_INTERVAL=120  # 2 minutes (default)
SLEEP_INTERVAL=60   # 1 minute (more responsive)
SLEEP_INTERVAL=300  # 5 minutes (less aggressive)
```

## Advanced Usage

### Manual Start with Custom Config
```bash
./czar-daemon.sh /path/to/czarina-project
```

### Monitor Daemon in Real-Time
```bash
tmux attach -t myproject-daemon
# Ctrl+b, d to detach
```

### Check Git Activity
The daemon logs git commits every 10 iterations (~20 minutes).
View in daemon logs or check manually:
```bash
git log --all --since="20 minutes ago" --oneline
```

## Files

- `czar-daemon.sh` - Main daemon script (generalized for any project)
- `start-daemon.sh` - Launcher that creates tmux session
- `README.md` - This file

## Success Metrics

**With Aider/CLI agents (Best Case):**
- ✅ Auto-approvals happening every 2 min
- ✅ Workers committing 1-2x per hour
- ✅ No fatal errors in daemon log
- ✅ Human intervention <5% of time
- ✅ Daemon runs 8+ hours without issues

**With Claude Code/Desktop IDEs (Realistic):**
- ✅ Daemon handles shell/git approvals automatically
- ⚠️ Human approves Claude Code UI prompts every 30-60 min
- ✅ Workers commit 1-2x per hour
- ✅ ~70-80% autonomy achieved
- ⚠️ Claude Code prompts require manual approval

**Limitation:** Claude Code's UI prompts cannot be automated via tmux. Use Aider for maximum autonomy.

## See Also

- [Full Daemon Guide](../../docs/DAEMON_SYSTEM.md) - Comprehensive documentation
- [Czar Session Notes](../../projects/sark-v2-orchestration/CZAR_SESSION_NOTES.md) - Original research and findings
- [Embedded Orchestration Guide](../docs/EMBEDDED_ORCHESTRATION_GUIDE.md) - How embedded mode works

---

**Status**: Production Ready
**Version**: 1.0
**Based on**: SARK v2.0 Czar Session (Nov 2025)
