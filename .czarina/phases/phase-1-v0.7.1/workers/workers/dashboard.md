# Worker: Dashboard
## Dashboard Investigation & Fix

**Stream:** 5
**Duration:** Week 1-2 (2 days, parallel with foundation)
**Branch:** `feat/dashboard-fix`
**Agent:** Cursor (recommended)
**Dependencies:** None (investigation task)

---

## Mission

Investigate why the dashboard window shows an empty UI frame and fix it. The dashboard should provide live monitoring of worker activity.

## 🚀 YOUR FIRST ACTION

**Investigate the current dashboard implementation:**

```bash
# Find dashboard-related code
grep -r "dashboard" czarina czarina-core/

# Check what's currently in the dashboard window
tmux capture-pane -t czarina-*-mgmt:2 -p 2>/dev/null || echo "Dashboard window not found"

# Look for dashboard initialization in the main script
grep -A 20 "dashboard" czarina
```

**Then:** Document your findings in an investigation.md file and proceed to Task 2 (implement fix based on what you find).

## Goals

- Understand why dashboard is non-functional
- Fix rendering issues
- Display live worker status
- Show real-time metrics
- Provide useful monitoring interface

---

## Tasks

### Task 1: Investigation (0.5 days)

#### 1.1: Current State Analysis
**Investigation steps:**

1. Find dashboard code location:
```bash
grep -r "dashboard" czarina czarina-core/
```

2. Check tmux dashboard window:
```bash
tmux capture-pane -t czarina-sark-mgmt:2 -p
```

3. Look for dashboard initialization:
```bash
grep -A 20 "dashboard" czarina
```

4. Check for dependencies:
- Is it using a TUI library?
- Does it require Python/Node.js?
- Are there missing dependencies?

**Document findings:**
Create `.czarina/work/<session>/workers/dashboard/investigation.md`:
```markdown
# Dashboard Investigation Findings

## Current Implementation
- Location: [file:line]
- Technology: [bash/python/node]
- Dependencies: [list]

## Issue Identified
[Description of what's broken]

## Root Cause
[Why it's broken]

## Proposed Fix
[How to fix it]
```

**COMMIT CHECKPOINT:**
```bash
git add .czarina/work/*/workers/dashboard/investigation.md
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: investigation_complete" >> .czarina/logs/dashboard.log
```

---

### Task 2: Fix Implementation (1 day)

**Note:** Implementation depends on investigation findings. Below are potential scenarios:

#### Scenario A: Dashboard Not Implemented
If dashboard is just a placeholder:

**File:** `czarina-core/dashboard.sh` (NEW)

Implement basic TUI dashboard:
```bash
#!/bin/bash
# Simple dashboard using watch + cat

while true; do
  clear
  echo "╔════════════════════════════════════════════════════╗"
  echo "║           Czarina Orchestration Dashboard          ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo ""
  echo "Session: $(czarina_session_current)"
  echo "Started: $(jq -r '.started' .czarina/work/$(czarina_session_current)/session.json)"
  echo ""
  echo "Workers:"

  for worker in $(jq -r '.workers[].id' .czarina/config.json); do
    LAST_LOG=$(tail -1 .czarina/logs/${worker}.log 2>/dev/null || echo "No activity")
    FILES_CHANGED=$(cd .czarina/worktrees/$worker 2>/dev/null && git status --short | wc -l || echo 0)

    printf "  %-12s | %s | Files: %d\n" "$worker" "$LAST_LOG" "$FILES_CHANGED"
  done

  sleep 5
done
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/dashboard.sh
git commit -m "feat(dashboard): Implement basic live monitoring dashboard"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: dashboard_implementation" >> .czarina/logs/dashboard.log
```

#### Scenario B: Rendering Issue
If dashboard exists but doesn't render:

Check for:
- Terminal size issues
- Missing escape sequences
- TUI library compatibility
- tmux pane size

**Fix:** Adjust rendering logic or tmux pane configuration

#### Scenario C: Dependency Missing
If dashboard requires external tools:

**File:** `docs/DEPENDENCIES.md` (UPDATE)

Document required dependencies:
```markdown
## Dashboard Dependencies

The live dashboard requires:
- `watch` (for auto-refresh)
- Terminal with ANSI color support
- Minimum terminal size: 80x24
```

**Install script:**
```bash
# In czarina launch
check_dashboard_deps() {
  if ! command -v watch &> /dev/null; then
    echo "⚠️  'watch' not found. Dashboard will be limited."
  fi
}
```

---

### Task 3: Enhancement (0.5 days)

Once dashboard is functional, enhance it:

#### 3.1: Add Metrics Display
Show:
- Tasks completed / total
- Files changed
- Time elapsed
- Estimated completion

#### 3.2: Add Color Coding
- 🟢 Green: Active workers
- 🟡 Yellow: Idle workers
- 🔴 Red: Stuck workers
- ⚪ Gray: Complete workers

#### 3.3: Add Refresh Rate Control
```bash
# Allow configurable refresh rate
REFRESH_RATE=${CZARINA_DASHBOARD_REFRESH:-5}
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/dashboard.sh docs/DEPENDENCIES.md
git commit -m "feat(dashboard): Enhance dashboard with metrics and color coding"
echo "[$(date +%H:%M:%S)] 🎉 WORKER_COMPLETE: Dashboard fixed and enhanced" >> .czarina/logs/dashboard.log
```

---

## Deliverables

- ✅ Investigation report documenting findings
- ✅ Fixed dashboard implementation (or new implementation if missing)
- ✅ Enhanced metrics display
- ✅ Color-coded status indicators
- ✅ Updated documentation

---

## Success Metrics

- [ ] Dashboard renders correctly in tmux pane
- [ ] Shows live worker status
- [ ] Updates every 5 seconds (or configured interval)
- [ ] Displays accurate metrics
- [ ] No rendering artifacts or errors

---

## Testing Checklist

### Manual Tests
1. Launch czarina orchestration
2. Attach to management session: `tmux attach -t czarina-<project>-mgmt`
3. Switch to dashboard window: `Ctrl+b 2`
4. Verify:
   - Dashboard renders correctly
   - Worker status updates
   - Metrics are accurate
   - No errors or flickering

### Edge Cases
- Empty project (no workers)
- Single worker
- Many workers (10+)
- Worker with long log lines
- Terminal resize

---

## Integration Notes

This worker is independent and can run in parallel with all other workers.

**Optional integration:**
- If `foundation` completes first, can use new logging system
- If `coordination` completes first, can display Czar reports

---

## References

- Enhancement #8: Dashboard Fix
- SARK v1.3.0 orchestration (dashboard showed empty UI)
- Czarina dashboard implementation (current code)
