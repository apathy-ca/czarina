# 🚨 Czar Alert System

## Overview

The Czar daemon now detects when workers are STUCK (approvals not processing) and flags them for human attention.

## How It Works

### 1. Daemon Detection
The daemon attempts approvals and then **verifies** they worked:

```bash
# Try approval
tmux send-keys -t window "1" C-m

# Wait 0.5 seconds
sleep 0.5

# Check if STILL stuck
if still_showing_prompt; then
    FLAG_AS_STUCK
fi
```

### 2. Alert Flagging

**Alert File:** `worker-alerts-live.json`

Each stuck worker gets an entry:
```json
{"window": 0, "status": "stuck_edit", "severity": "medium", "time": "23:15:42"}
{"window": 1, "status": "stuck_approval", "severity": "high", "time": "23:15:43"}
```

**Severity Levels:**
- `high` - Approval prompts (blocks work completely)
- `medium` - Edit prompts (known Claude Code bug)

### 3. Visual Dashboard

**Run:** `./czar-status-dashboard.sh`

**Output:**
```
🎭 CZAR STATUS DASHBOARD
========================================
Window 0 | ENGINEER-1   | 🟡 EDIT PROMPT (known bug)
  └─ Window 0 (ENGINEER-1) at edit prompt - tmux send-keys won't work
Window 1 | ENGINEER-2   | 🔴 NEEDS APPROVAL
  └─ Window 1 (ENGINEER-2) waiting for approval
Window 2 | ENGINEER-3   | 🟢 OK

========================================
🚨 2 workers need attention

Workers requiring action:
  🔴 ENGINEER-2 - needs_approval
  🟡 ENGINEER-1 - edit_prompt
```

**Color Codes:**
- 🔴 Red - High priority (needs immediate action)
- 🟡 Yellow - Medium priority (known issue, approve when convenient)
- 🟢 Green - Working normally
- 🔵 Blue - Actively processing
- ⚪ White - Idle (not stuck)

### 4. Real-Time Alert Monitor

**Run:** `./watch-alerts.sh`

Continuously displays active alerts, updates every 10 seconds.

**Example:**
```
🚨 2 ACTIVE ALERTS

🔴 Window 1 (ENGINEER-2): STUCK at approval [23:15:43]
🟡 Window 0 (ENGINEER-1): STUCK at edit prompt [23:15:42]

ACTION NEEDED: Approve prompts in affected windows
Command: tmux attach -t sark-v2-session
```

---

## Usage

### Check Status Once
```bash
./czar-status-dashboard.sh
```

### Watch Continuously
```bash
./watch-alerts.sh
# Updates every 10 seconds
# Ctrl+C to stop
```

### Check Alert File Directly
```bash
cat worker-alerts-live.json
```

### View Daemon Logs
```bash
tail -f czar-daemon.log
```

---

## Workflow Integration

### Recommended: Check Every 30-60 Minutes

```bash
# Quick status check
./czar-status-dashboard.sh

# If alerts exist
tmux attach -t sark-v2-session
# Navigate to flagged windows (Ctrl+b <number>)
# Approve prompts manually
# Ctrl+b d to detach
```

### Alternative: Continuous Monitoring

Open a dedicated terminal:
```bash
./watch-alerts.sh
```

When alerts appear:
- Note which windows need attention
- Attach to worker session
- Approve flagged workers
- Return to monitoring

---

## Alert Types

### `stuck_approval` (🔴 High)
**Cause:** Claude Code approval prompt not responding to tmux send-keys  
**Action:** Manual approval required  
**Fix:** Approve in worker window

### `stuck_edit` (🟡 Medium)  
**Cause:** Claude Code "accept edits" UI (known bug)  
**Action:** Manual acceptance required  
**Fix:** Press Enter in worker window (or manually click)

### `error` (🔴 High)
**Cause:** Error detected in worker output  
**Action:** Investigation required  
**Fix:** Check worker window for error details

---

## Benefits

### Before Alert System
- Daemon tried approvals blindly
- No feedback on success/failure
- Human had to check all 10 windows periodically
- No way to know which workers needed attention

### After Alert System
- Daemon detects stuck workers automatically
- Visual dashboard highlights issues
- Human knows exactly which windows need attention
- Real-time monitoring option available
- Alert severity helps prioritize

---

## Dashboard Integration (Future)

The alert system outputs structured JSON for easy integration:

```json
{
  "window": 0,
  "status": "stuck_edit",
  "severity": "medium",
  "time": "23:15:42"
}
```

Can be consumed by:
- Web dashboard
- Desktop notifications
- Slack/Discord alerts
- Mobile notifications
- Email alerts

---

## Files

**Core:**
- `czar-daemon-v2.sh` - Daemon with alert detection
- `worker-alerts-live.json` - Active alert file (generated)

**Monitoring:**
- `czar-status-dashboard.sh` - One-time status check
- `watch-alerts.sh` - Continuous alert monitor

**Logs:**
- `czar-daemon.log` - Full daemon activity log

---

## Example Session

**Time: 23:15**
```bash
$ ./czar-status-dashboard.sh
🚨 2 workers need attention
  🔴 ENGINEER-2 - needs_approval
  🟡 ENGINEER-1 - edit_prompt
```

**Action:**
```bash
$ tmux attach -t sark-v2-session
# Press Ctrl+b 1 (go to ENGINEER-2)
# Approve prompt
# Press Ctrl+b 0 (go to ENGINEER-1)  
# Accept edit
# Press Ctrl+b d (detach)
```

**Time: 23:20**
```bash
$ ./czar-status-dashboard.sh
✅ All workers OK - No alerts
```

---

## Recommendations

1. **Run dashboard every 30-60 minutes** during active sessions
2. **Use watch-alerts.sh** if you want continuous monitoring
3. **Check daemon log** if unexpected behavior occurs
4. **Alert file is cleared** on each daemon iteration (auto-cleanup)

---

**Created:** 2025-11-29  
**Version:** 2.0  
**Status:** Active and deployed
