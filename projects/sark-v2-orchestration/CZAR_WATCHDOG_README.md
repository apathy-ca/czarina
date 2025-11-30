# Czar Watchdog System

## Overview
The Czar Watchdog system provides automated monitoring of all 10 worker tmux windows, detecting issues that need Czar attention and automatically handling common problems like approval prompts.

## Files Created

### 1. `czar-watchdog.sh`
**Primary monitoring script** - Checks all 10 tmux windows for:
- ✅ Approval prompts → Auto-approvable
- ❓ Questions/blockers for Czar
- ❌ Errors that need investigation
- ✅ Task completions
- 🔄 Active work status
- ⏸️  Idle workers
- 📊 Git activity (last 10 min)

**Usage:**
```bash
./czar-watchdog.sh
```

**Output:** Console + `czar-watchdog.log`

### 2. `czar-monitor-and-respond.sh`
**Automated response script** - Runs watchdog AND takes action:
- Auto-approves permission requests (option 2)
- Reports which windows need Czar attention
- Shows summary of actions taken

**Usage:**
```bash
./czar-monitor-and-respond.sh
```

**Exit codes:**
- `0` = All OK, no attention needed
- `1` = Issues detected, Czar should review

### 3. `start-watchdog.sh`
**Continuous monitoring** - Runs watchdog every 5 minutes:
- Creates alerts file when issues detected
- Maintains running log
- Good for background monitoring

**Usage:**
```bash
./start-watchdog.sh &   # Run in background
```

Or in a dedicated tmux window:
```bash
tmux new-session -d -s czar-watchdog
tmux send-keys -t czar-watchdog "./start-watchdog.sh" C-m
```

### 4. `monitor-workers.sh`
**Git activity dashboard** - Shows:
- Recent commits (last 30 min)
- Branch status for all feat/v2-* branches
- Commit counts by worker
- Potential issues (merge conflicts, uncommitted changes on main)

**Usage:**
```bash
./monitor-workers.sh
```

## Recommended Workflow for Czar

### Initial Setup (Done ✅)
```bash
cd /home/jhenry/Source/GRID/claude-orchestrator/projects/sark-v2-orchestration
chmod +x *.sh
```

### Active Monitoring (Every 5-10 minutes)
```bash
# Quick auto-check with automatic approvals
./czar-monitor-and-respond.sh

# If it reports issues, view details:
cat /tmp/watchdog-output.txt

# Check git activity:
./monitor-workers.sh
```

### Continuous Monitoring (Optional)
```bash
# Start watchdog in background
tmux new-session -d -s czar-watchdog \
  "cd /home/jhenry/Source/GRID/claude-orchestrator/projects/sark-v2-orchestration && ./start-watchdog.sh"

# Check alerts:
cat czar-alerts.txt
```

### Investigating Issues

When watchdog reports a window needs attention:

```bash
# View the worker's window directly
tmux attach -t sark-v2-session
# Then: Ctrl+b then window number (0-9)

# Or capture pane remotely:
tmux capture-pane -t sark-v2-session:X -p | tail -50
# (replace X with window number)
```

### Sending Messages

**To all workers:**
```bash
./send-task.sh "Your message here"
```

**To specific worker:**
```bash
tmux send-keys -t sark-v2-session:X "# CZAR: Your message" C-m
```

**Important:** Always send carriage return (`C-m`) after messages!

## Common Issues & Solutions

### Issue: Worker waiting for approval
**Detection:** Watchdog shows "WAITING FOR APPROVAL"  
**Auto-fix:** `czar-monitor-and-respond.sh` handles automatically  
**Manual:** `tmux send-keys -t sark-v2-session:X "2" C-m`

### Issue: Worker has question
**Detection:** Watchdog shows "QUESTION/BLOCKER DETECTED"  
**Action:** Review window, send clarification message with C-m

### Issue: Worker has error
**Detection:** Watchdog shows "ERROR DETECTED"  
**Action:** Review window, diagnose error, send guidance

### Issue: Worker on wrong branch
**Detection:** Manual review or worker reports it  
**Action:** Send message: `git checkout correct-branch-name`

### Issue: No commits in 30+ minutes
**Detection:** `monitor-workers.sh` shows no activity  
**Action:** Check if workers are blocked or waiting for something

## Worker Branch Map

| Window | Worker ID | Branch Name |
|--------|-----------|-------------|
| 0 | engineer1 | feat/v2-lead-architect |
| 1 | engineer2 | feat/v2-http-adapter |
| 2 | engineer3 | feat/v2-grpc-adapter |
| 3 | engineer4 | feat/v2-federation |
| 4 | engineer5 | feat/v2-advanced-features |
| 5 | engineer6 | feat/v2-database |
| 6 | qa1 | feat/v2-integration-tests |
| 7 | qa2 | feat/v2-performance-security |
| 8 | docs1 | feat/v2-api-docs |
| 9 | docs2 | feat/v2-tutorials |

## Current Status

**Session:** sark-v2-session (10 workers)  
**Watchdog:** Active  
**Last check:** Run `./czar-monitor-and-respond.sh` to check now

## Integration with Claude Code (Future Enhancement)

The watchdog scripts can be called periodically by a Claude Code instance acting as Czar. Recommended schedule:

```
Every 5 minutes:  ./czar-monitor-and-respond.sh
Every 15 minutes: ./monitor-workers.sh
```

If `czar-monitor-and-respond.sh` exits with code 1, Claude Czar should:
1. Read `/tmp/watchdog-output.txt` for details
2. Investigate windows that need attention
3. Send appropriate guidance messages
4. Update task assignments if needed

## Logs & Output Files

- `czar-watchdog.log` - Full watchdog history
- `czar-alerts.txt` - Alert messages when issues detected
- `/tmp/watchdog-output.txt` - Latest watchdog run output

---

**Last Updated:** 2025-11-29  
**Status:** ✅ Active and functional
