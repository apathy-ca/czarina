# SARK Daemon & Dashboard Improvements

## Overview

The SARK v2.0 project developed significant improvements to the daemon and monitoring systems based on real-world usage with 10 workers. These improvements address the Claude Code UI limitation and provide better visibility into worker status.

**Status:** Developed and tested in SARK v2.0
**Integration:** Needs to be ported to Czarina core
**Impact:** HIGH - Dramatically improves usability and monitoring

---

## Key Improvements

### 1. Alert System 🚨

**Problem Solved:** Daemon had no way to know if approvals actually worked

**Solution:** Daemon now verifies approvals and flags stuck workers

**How it works:**
```bash
# Try approval
tmux send-keys -t window "1" C-m

# Wait and verify
sleep 0.5
if still_showing_prompt; then
    FLAG_AS_STUCK
    WRITE_TO_ALERT_FILE
fi
```

**Benefits:**
- Know exactly which workers need manual intervention
- Prioritize by severity (high/medium)
- Real-time feedback on daemon effectiveness
- No more guessing which windows are stuck

### 2. Smart Approval Logic

**Problem Solved:** Approval prompts have different numbers of options

**Old behavior:** Always select option 2
**New behavior:** Detect number of options and choose correctly

```bash
# Count options
options=$(echo "$output" | grep -E "^\s+[0-9]+\." | wc -l)

if [ $options -eq 2 ]; then
    # 2 options: "Yes" is option 1
    tmux send-keys "1" C-m
elif [ $options -eq 3 ]; then
    # 3 options: "Yes, allow reading" is option 2
    if echo "$output" | grep -q "allow reading"; then
        tmux send-keys "2" C-m
    else
        tmux send-keys "1" C-m
    fi
fi
```

**Benefits:**
- More reliable approvals
- Adapts to different Claude Code prompt formats
- Reduces failed approval attempts

### 3. Visual Status Dashboard 📊

**Problem Solved:** No easy way to see which workers need attention

**Solution:** `czar-status-dashboard.sh` - Color-coded worker status

**Output:**
```
🎭 CZAR STATUS DASHBOARD
========================================
Window 0 | ENGINEER-1   | 🟡 EDIT PROMPT (known bug)
Window 1 | ENGINEER-2   | 🔴 NEEDS APPROVAL
Window 2 | ENGINEER-3   | 🟢 OK
Window 3 | ENGINEER-4   | 🟢 OK
...

========================================
🚨 2 workers need attention

Workers requiring action:
  🔴 ENGINEER-2 - needs_approval
  🟡 ENGINEER-1 - edit_prompt
```

**Color codes:**
- 🔴 Red - High priority (needs immediate action)
- 🟡 Yellow - Medium priority (known issue, approve when convenient)
- 🟢 Green - Working normally
- 🔵 Blue - Actively processing
- ⚪ White - Idle (not stuck)

**Benefits:**
- Instant visibility into worker status
- Know which windows to check
- Prioritize intervention
- Quick status checks

### 4. Real-Time Alert Monitor

**Problem Solved:** Need continuous monitoring option

**Solution:** `watch-alerts.sh` - Auto-refreshing alert display

**Output:**
```
🎭 CZAR ALERT MONITOR
2025-11-29 23:15:42
========================================
🚨 2 ACTIVE ALERTS

🔴 Window 1 (ENGINEER-2): STUCK at approval [23:15:43]
🟡 Window 0 (ENGINEER-1): STUCK at edit prompt [23:15:42]

ACTION NEEDED: Approve prompts in affected windows
Command: tmux attach -t sark-v2-session
========================================
Next update in 10 seconds...
```

**Benefits:**
- Continuous monitoring in dedicated terminal
- Auto-refreshes every 10 seconds
- Shows only active alerts
- Provides action guidance

### 5. Structured Alert Data

**Problem Solved:** Need machine-readable alert data for integration

**Solution:** JSON alert file (`worker-alerts-live.json`)

**Format:**
```json
{"window": 0, "status": "stuck_edit", "severity": "medium", "time": "23:15:42"}
{"window": 1, "status": "stuck_approval", "severity": "high", "time": "23:15:43"}
```

**Alert types:**
- `stuck_approval` (high) - Approval prompt not responding
- `stuck_edit` (medium) - Edit prompt not responding (known bug)
- `error` (high) - Error detected in output

**Benefits:**
- Easy integration with dashboards
- Can trigger notifications (Slack, email, etc.)
- Machine-parseable for automation
- Timestamped for analysis

---

## Files Created in SARK

### Daemon
- `czar-daemon-v2.sh` - Enhanced daemon with alert detection
- `czar-daemon-fixed.sh` - Fixed version with smart approvals
- `approve-all-smart.sh` - Smart approval helper script

### Monitoring
- `czar-status-dashboard.sh` - One-time visual status check
- `watch-alerts.sh` - Continuous alert monitor

### Documentation
- `ALERT_SYSTEM.md` - Complete alert system documentation
- `DAEMON_LIMITATION.md` - Claude Code UI limitation analysis

### Data Files (Generated)
- `worker-alerts-live.json` - Active alerts (real-time)
- `czar-daemon.log` - Daemon activity log

---

## Integration Plan for Czarina Core

### Phase 1: Update Core Daemon (Priority: HIGH)

**Files to update:**
```
czarina-core/daemon/czar-daemon.sh
```

**Changes to integrate:**
1. **Add alert file support:**
   ```bash
   ALERT_FILE="${PROJECT_DIR}/status/alerts.json"
   ```

2. **Add smart approval logic:**
   ```bash
   # Detect number of options and choose correctly
   options=$(echo "$output" | grep -E "^\s+[0-9]+\." | wc -l)
   ```

3. **Add verification after approval:**
   ```bash
   # Try approval
   tmux send-keys ...
   # Wait and verify
   sleep 0.5
   # Check if still stuck
   if still_stuck; then
       write_alert
   fi
   ```

4. **Add alert types:**
   - stuck_approval (high)
   - stuck_edit (medium)
   - error (high)

### Phase 2: Add Monitoring Tools (Priority: MEDIUM)

**New files to create:**
```
czarina-core/tools/status-dashboard.sh
czarina-core/tools/watch-alerts.sh
```

**Generalize for any project:**
- Read worker names from config.json
- Use PROJECT_SLUG for session name
- Load worker count dynamically

**CLI integration:**
```bash
czarina monitor <project>         # Run status dashboard
czarina monitor <project> --watch # Continuous monitoring
czarina alerts <project>          # Show active alerts
```

### Phase 3: Dashboard Integration (Priority: LOW)

**Enhance:** `czarina-core/dashboard.py`

**Add features:**
- Read alerts from alerts.json
- Display stuck workers prominently
- Color-code worker status
- Show alert severity
- Provide action suggestions

**Example display:**
```
╔════════════════════════════════════════╗
║  🚨 2 WORKERS NEED ATTENTION          ║
╚════════════════════════════════════════╝

🔴 ENGINEER-2 (Window 1): Stuck at approval
🟡 ENGINEER-1 (Window 0): Stuck at edit prompt

Action: tmux attach -t project-session
```

---

## Usage Workflow with Improvements

### Before (Without Alerts)
```bash
# 1. Start daemon
czarina daemon start myproject

# 2. ??? How do I know if workers are stuck?
# 3. Check all windows manually
tmux attach -t myproject-session
# Navigate through each window one by one

# 4. Guess which ones need approval
# 5. Hope daemon is working
```

### After (With Alerts)
```bash
# 1. Start daemon
czarina daemon start myproject

# 2. Check status periodically (every 30-60 min)
czarina monitor myproject

# Output shows exactly which workers need attention:
# 🔴 ENGINEER-2 - needs_approval
# 🟡 ENGINEER-1 - edit_prompt

# 3. Attach and fix only the flagged windows
tmux attach -t myproject-session
# Press Ctrl+b 1 (go to ENGINEER-2)
# Approve prompt
# Press Ctrl+b 0 (go to ENGINEER-1)
# Accept edit
# Done!

# 4. Verify all clear
czarina monitor myproject
# ✅ All workers OK - No alerts
```

---

## Benefits Summary

### For Users
- **Know what's happening:** Clear visibility into worker status
- **Targeted intervention:** Know exactly which windows need attention
- **Save time:** Don't check all windows, only flagged ones
- **Prioritize:** High/medium severity helps decide urgency

### For Automation
- **Structured data:** JSON alerts for easy integration
- **Real-time:** Alert file updates every daemon cycle
- **Machine-readable:** Easy to parse for notifications/dashboards
- **Extensible:** Can trigger Slack, email, SMS, etc.

### For Debugging
- **Verify daemon effectiveness:** Know if approvals are working
- **Track failure patterns:** Which prompts fail most often
- **Timestamped:** Can correlate with worker activity
- **Logged:** Full history in daemon.log

---

## Comparison: Old vs. New

| Feature | Old Daemon | New Daemon (SARK) |
|---------|-----------|-------------------|
| Auto-approval | ✅ | ✅ |
| Verify success | ❌ | ✅ |
| Flag stuck workers | ❌ | ✅ |
| Visual dashboard | ❌ | ✅ |
| Real-time monitoring | ❌ | ✅ |
| Alert severity | ❌ | ✅ |
| Smart approval logic | ❌ | ✅ |
| Structured alerts | ❌ | ✅ |
| Know which windows stuck | ❌ | ✅ |

**Result:** Dramatically improved usability and monitoring

---

## Testing Results from SARK

**Setup:** 10 workers, Claude Code, daemon v2

**Observations:**
- Alert system correctly flagged stuck workers
- Dashboard showed real-time status
- Human could target intervention precisely
- Saved ~80% of manual checking time
- Daemon log showed verification working

**Example session:**
```
23:15 - Daemon runs, 3 workers stuck
23:15 - Alerts generated
23:16 - Human checks dashboard: "3 alerts"
23:16 - Human approves 3 windows (30 seconds)
23:16 - Daemon runs again
23:17 - Dashboard: "All workers OK"
```

**Before alerts:** Would need to check all 10 windows individually
**With alerts:** Only checked 3 flagged windows

---

## Recommendations

### Immediate
1. **Integrate alert detection into core daemon** (1-2 hours)
   - Add verification after approval attempts
   - Generate alerts.json file
   - Smart approval logic

2. **Create status dashboard tool** (1 hour)
   - Generalize SARK version for any project
   - Read from config.json
   - Add to czarina CLI

3. **Update documentation** (30 min)
   - Add alert system to daemon docs
   - Update usage workflows
   - Add troubleshooting with alerts

### Nice-to-Have
1. **Watch-alerts tool** - Continuous monitoring option
2. **Dashboard integration** - Show alerts in Python dashboard
3. **Notification integration** - Slack/email alerts
4. **Alert history** - Track alerts over time for analysis

---

## Files to Port

### High Priority
```
SARK → Czarina Core

czar-daemon-v2.sh           → czarina-core/daemon/czar-daemon.sh (update existing)
czar-status-dashboard.sh    → czarina-core/tools/status-dashboard.sh (new)
approve-all-smart.sh        → czarina-core/tools/approve-all.sh (update existing)
ALERT_SYSTEM.md            → czarina-core/docs/ALERT_SYSTEM.md (new)
```

### Medium Priority
```
watch-alerts.sh            → czarina-core/tools/watch-alerts.sh (new)
```

### Documentation
```
DAEMON_LIMITATION.md       → Already ported to czarina-core/docs/
```

---

## Next Steps

1. ✅ **Document improvements** (this file)
2. 🔲 **Port alert detection to core daemon**
3. 🔲 **Create generalized status dashboard**
4. 🔲 **Add CLI commands for monitoring**
5. 🔲 **Test with multi-agent-support project**
6. 🔲 **Update all daemon documentation**

---

**Created:** 2025-11-29
**Source:** SARK v2.0 Session 3 feedback
**Status:** Ready for integration
**Priority:** HIGH - Dramatically improves daemon usability
**Estimated integration time:** 2-4 hours
