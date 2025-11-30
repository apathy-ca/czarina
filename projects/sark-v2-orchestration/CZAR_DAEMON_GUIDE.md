# 🎭 Czar Autonomous Daemon - Complete Guide

## Overview

The Czar Daemon is a **fully autonomous system** that monitors all 10 workers and makes approval decisions automatically. **The human never needs to approve anything** - the Czar makes all decisions based on predefined policies.

## Quick Start

### Start the Daemon
```bash
cd /home/jhenry/Source/GRID/claude-orchestrator/projects/sark-v2-orchestration
./start-czar-daemon.sh
```

### Monitor the Daemon
```bash
# View daemon in real-time
tmux attach -t czar-daemon

# View logs
tail -f czar-daemon.log

# Check recent activity
tail -50 czar-daemon.log
```

### Stop the Daemon
```bash
tmux kill-session -t czar-daemon
```

## What the Daemon Does Automatically

Every **2 minutes**, the daemon:

### 1. Auto-Approves File/Directory Access
When workers ask: "Do you want to proceed?"
- **Decision**: Always select option 2 (allow reading from directories)
- **No human intervention needed**

### 2. Auto-Accepts Worker Edits
When workers propose edits: "accept edits on"
- **Decision**: Always accept (press Enter)
- **Workers can proceed with their changes**

### 3. Auto-Confirms Y/N Prompts
When workers ask Y/N questions
- **Decision**: Default to "yes" for most operations
- **Assumption**: Workers are autonomous and know what they're doing**

### 4. Monitors for Blocking Issues
Detects and logs:
- Explicit questions tagged for Czar (`@czar`, "question for czar")
- Fatal/critical errors that block progress
- Workers stuck on unrecognized prompts

### 5. Tracks Git Activity
Every 20 minutes (~10 iterations):
- Counts commits in last 20 minutes
- Logs to daemon log for review

## Daemon Policies

The daemon follows these decision-making policies:

| Situation | Czar Decision | Rationale |
|-----------|---------------|-----------|
| "Do you want to proceed?" | Option 2 (allow reading) | Workers need access to orchestration files |
| "accept edits" prompt | Accept (Enter) | Workers propose valid changes |
| Y/N confirmation | Yes | Trust worker judgment |
| Explicit @czar question | Log and wait | Needs human/intelligent review |
| Fatal error | Log and wait | Needs diagnosis |

## Architecture

```
┌─────────────────────────────────────────────────┐
│          Czar Daemon (tmux: czar-daemon)        │
│  Runs czar-daemon.sh every 2 minutes            │
└─────────────────┬───────────────────────────────┘
                  │
                  ├─> Check all 10 worker windows
                  │   (sark-v2-session:0-9)
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
                      └─ czar-daemon.log
```

## Log Format

```
=== Iteration 1 - 2025-11-29 12:50:18 ===
[12:50:18] Auto-accepting edits in window 0
[12:50:19] Auto-approving window 3
[12:50:22] ✅ Auto-approved 7 items
[12:50:25] ⚠️  Window 5 has question for Czar
[12:50:30] Commits in last 20 min: 3
```

## When Human Intervention IS Needed

The daemon will **log but not auto-handle**:

1. **Explicit Czar Questions**: Workers tag with `@czar` or "question for czar"
2. **Fatal Errors**: "fatal", "critical", "cannot proceed" 
3. **Blocking Situations**: Workers explicitly say they're blocked

In these cases:
- Check `czar-daemon.log` for details
- Attach to specific worker window: `tmux attach -t sark-v2-session` → `Ctrl+b <window-number>`
- Send guidance manually if needed

## Files Created

```
sark-v2-orchestration/
├── czar-daemon.sh              # Main daemon script
├── start-czar-daemon.sh        # Launcher
├── czar-daemon.log             # Activity log
├── CZAR_DAEMON_GUIDE.md        # This file
├── czar-watchdog.sh            # Manual monitoring tool
├── czar-monitor-and-respond.sh # One-time auto-approve
└── approve-all.sh              # Emergency approval sweep
```

## Troubleshooting

### Daemon not starting
```bash
# Check if already running
tmux has-session -t czar-daemon && echo "Running" || echo "Not running"

# Kill and restart
tmux kill-session -t czar-daemon
./start-czar-daemon.sh
```

### Workers still waiting
```bash
# Force immediate approval sweep
./approve-all.sh

# Or restart daemon (it runs on startup)
tmux kill-session -t czar-daemon
./start-czar-daemon.sh
```

### Too many/few checks
Edit `czar-daemon.sh` and change:
```bash
SLEEP_INTERVAL=120  # 2 minutes (default)
SLEEP_INTERVAL=60   # 1 minute (more responsive)
SLEEP_INTERVAL=300  # 5 minutes (less aggressive)
```

## Integration with Session Management

The daemon is designed to run alongside `sark-v2-session`:

```
Terminal 1: Human oversight (optional)
├─ tmux attach -t sark-v2-session  # View workers
└─ Ctrl+b, d to detach

Terminal 2: Daemon monitoring (optional)
├─ tail -f czar-daemon.log         # Watch daemon activity
└─ Or: tmux attach -t czar-daemon  # See daemon in action

Background:
└─ czar-daemon (tmux session)      # Running autonomously
```

## Success Indicators

**Daemon is working well when:**
- ✅ Workers commit code regularly (check git log)
- ✅ Daemon log shows regular auto-approvals
- ✅ No fatal errors in daemon log
- ✅ Workers are not stuck at prompts for >2 minutes

**Check every 30-60 minutes:**
```bash
tail -50 czar-daemon.log  # See recent daemon activity
git log --all --since="30 minutes ago" --oneline
```

## Philosophy

> **"In an ideal world, I'm not here at all."**

The daemon embodies this principle:
- Workers are autonomous AI agents
- Czar trusts worker judgment
- Human only intervenes for true blockers
- System runs 24/7 without human supervision

---

**Status**: ✅ **ACTIVE AND AUTONOMOUS**  
**Started**: 2025-11-29 12:50 PM  
**Next Steps**: Let it run. Check logs periodically. Trust the system.
