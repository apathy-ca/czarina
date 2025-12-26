# Daemon Quiet Mode

## Overview

The Daemon Quiet Mode prevents output spam when workers are idle. The daemon only outputs iteration headers and status when workers have recent activity.

**Before v0.5.1:**
```
=== Iteration 42 - 2025-12-25 10:00:00 ===
[10:00:00] No recent activity to report

=== Iteration 43 - 2025-12-25 10:02:00 ===
[10:02:00] No recent activity to report

=== Iteration 44 - 2025-12-25 10:04:00 ===
[10:02:00] No recent activity to report
# Text scrolls off screen...
```

**After v0.5.1:**
```
=== Iteration 42 - 2025-12-25 10:00:00 ===
[10:00:00] ✅ Auto-approved 2 items
# Silent iterations (no output spam)
# ...
# 20 minutes later, worker makes commit
=== Iteration 52 - 2025-12-25 10:20:00 ===
[10:20:00] ✅ Auto-approved 1 item
```

## Features

- **Activity Detection** - Checks git commits and log files
- **Silent Iterations** - No output when workers are idle
- **Still Active** - Daemon still runs auto-approval and checks
- **Configurable Threshold** - Default 5 minutes, customizable
- **Legacy Mode** - Can disable quiet mode if needed

## How It Works

### Activity Detection

The daemon checks for recent activity every iteration (2 minutes):

1. **Git Commits** - Did any worker branch have commits in last N minutes?
2. **Log Files** - Were any log files updated in last N minutes?

If either is true, **has_activity = true** → output is displayed

If neither is true, **has_activity = false** → silent iteration

### Silent Iterations

When `has_activity = false`:

- **Still runs:** Auto-approval, issue detection, status checks
- **Logs to file:** All activity logged to `daemon.log`
- **No terminal output:** Prevents text spam
- **No iteration header:** Clean terminal

### Active Iterations

When `has_activity = true`:

- **Normal output:** Iteration header displayed
- **Status reports:** Auto-approval and issue messages shown
- **Logs to file AND terminal:** Full visibility

## Configuration

### Activity Threshold

**Default:** 5 minutes (300 seconds)

**Environment variable:**
```bash
# 10 minute threshold
export DAEMON_ACTIVITY_THRESHOLD=600
czarina daemon start

# 2 minute threshold
export DAEMON_ACTIVITY_THRESHOLD=120
czarina daemon start
```

**In daemon script:**
```bash
# Default if not set
ACTIVITY_THRESHOLD=${DAEMON_ACTIVITY_THRESHOLD:-300}
```

### Disable Quiet Mode

**Environment variable:**
```bash
# Always output (legacy behavior)
export DAEMON_ALWAYS_OUTPUT=true
czarina daemon start
```

**Result:** Every iteration outputs, regardless of activity (v0.5.0 behavior)

## Implementation

### Function: daemon_has_recent_activity()

Located in `czarina-core/daemon/czar-daemon.sh`:

```bash
daemon_has_recent_activity() {
    local threshold=$ACTIVITY_THRESHOLD
    local now=$(date +%s)

    # Check for recent git commits in any worker branch
    for ((w=0; w<WORKER_COUNT; w++)); do
        worker_branch=$(jq -r ".workers[$w].branch" "$CONFIG_FILE")

        if [ "$worker_branch" != "null" ] && [ -n "$worker_branch" ]; then
            last_commit_time=$(git log "$worker_branch" -1 --format=%ct 2>/dev/null)
            age=$((now - last_commit_time))

            if [ $age -lt $threshold ]; then
                return 0  # Has recent activity
            fi
        fi
    done

    # Check for recent log file updates
    if [ -d "${PROJECT_DIR}/logs" ]; then
        for log_file in "${PROJECT_DIR}/logs"/*.log; do
            last_mod=$(stat -c %Y "$log_file" 2>/dev/null)
            age=$((now - last_mod))

            if [ $age -lt $threshold ]; then
                return 0  # Has recent activity
            fi
        done
    fi

    return 1  # No recent activity
}
```

### Main Loop Integration

```bash
# Check if we should output this iteration (quiet mode)
has_activity=false
if [ "$DAEMON_QUIET_MODE" = "true" ]; then
    # Always output if quiet mode is disabled
    has_activity=true
elif daemon_has_recent_activity; then
    has_activity=true
fi

# Only output iteration header if there's activity
if [ "$has_activity" = true ]; then
    echo "" | tee -a "$LOG_FILE"
    echo "=== Iteration $iteration - $(date '+%Y-%m-%d %H:%M:%S') ===" | tee -a "$LOG_FILE"
fi

# Auto-approve (always runs, but conditionally outputs)
if [ "$has_activity" = true ]; then
    auto_approve_all
else
    auto_approve_all &>> "$LOG_FILE"  # Silent approval
fi
```

## Examples

### Example 1: Active Development Session

**Scenario:** Workers making commits every 2-3 minutes

**Output:**
```
=== Iteration 1 - 2025-12-25 10:00:00 ===
[10:00:00] ✅ Auto-approved 3 items

=== Iteration 2 - 2025-12-25 10:02:00 ===
[10:02:00] ✅ Auto-approved 1 item

=== Iteration 3 - 2025-12-25 10:04:00 ===
[10:04:00] ✅ Auto-approved 2 items
```

**Result:** Every iteration displays (workers active)

### Example 2: Idle Period

**Scenario:** Workers haven't committed in 30 minutes

**Output:**
```
=== Iteration 10 - 2025-12-25 10:00:00 ===
[10:00:00] ✅ Auto-approved 1 item
# Silent for 15 iterations (30 minutes)
# ...
```

**Terminal:** No output for 30 minutes (clean!)

**Log file:** Contains all 15 silent iterations

### Example 3: Sporadic Activity

**Scenario:** Worker commits at iteration 5, then idle until iteration 15

**Output:**
```
=== Iteration 5 - 2025-12-25 10:00:00 ===
[10:00:00] ✅ Auto-approved 2 items
[10:00:00] 📊 STATUS REPORT - Your workers are CRUSHING IT!
   • backend: 1 commit
# Silent for iterations 6-14
# ...
=== Iteration 15 - 2025-12-25 10:20:00 ===
[10:20:00] ✅ Auto-approved 1 item
```

**Result:** Only shows when there's activity

## Benefits

### Clean Terminal

**Before:** Daemon spam pushes everything off-screen
```
# 100 lines of iteration headers...
# Your important output is gone!
```

**After:** Terminal stays clean, only shows relevant updates
```
# Last worker output still visible
# Daemon only speaks when needed
```

### Easy Debugging

**Problem:** Worker had an error 10 minutes ago, but daemon spam scrolled it away

**Solution:** Quiet mode preserves worker output on screen

### Professional Appearance

**Quiet mode looks elegant:**
- No spam when idle
- Clear updates when active
- Easy to see current state

**Legacy mode looks spammy:**
- Constant iteration headers
- "No activity" messages
- Hard to read

### Still Autonomous

**Important:** Daemon still works in quiet mode!

- Auto-approvals still happen
- Issue detection still runs
- Stuck workers still get noticed
- Everything logged to file

Just no terminal spam!

## Troubleshooting

### Daemon not outputting anything

**Check 1:** Is quiet mode enabled? (Default: yes)
```bash
echo $DAEMON_ALWAYS_OUTPUT
# Should be empty or "false"
```

**Check 2:** Has there been activity?
```bash
# Check recent commits
git log --all --since="5 minutes ago" --oneline

# Check log files
ls -lt .czarina/logs/*.log | head -5
```

**Check 3:** View the log file
```bash
tail -f .czarina/status/daemon.log
# Should show all iterations, even silent ones
```

### Want to see all iterations

**Option 1:** Disable quiet mode
```bash
export DAEMON_ALWAYS_OUTPUT=true
czarina daemon start
```

**Option 2:** Watch log file
```bash
tail -f .czarina/status/daemon.log
```

### Activity not being detected

**Debug:** Run activity check manually
```bash
# Add to daemon script temporarily
daemon_has_recent_activity
echo "Activity check result: $?"
# 0 = has activity, 1 = no activity
```

**Check:** Verify activity threshold
```bash
echo $DAEMON_ACTIVITY_THRESHOLD
# Should be 300 (5 min) or your custom value
```

### Want shorter/longer activity window

```bash
# 2 minute threshold (more responsive)
export DAEMON_ACTIVITY_THRESHOLD=120

# 15 minute threshold (less frequent updates)
export DAEMON_ACTIVITY_THRESHOLD=900

czarina daemon start
```

## Comparison: Before vs After

| Aspect | v0.5.0 (Before) | v0.5.1 (After) |
|--------|-----------------|----------------|
| **Idle output** | Every 2 min | Silent |
| **Active output** | Every 2 min | Every 2 min |
| **Terminal spam** | Yes, constant | No, clean |
| **Worker output visibility** | Scrolls away | Preserved |
| **Auto-approval** | Works | Works |
| **Issue detection** | Works | Works |
| **Log file** | All iterations | All iterations |
| **Configuration** | None | DAEMON_ACTIVITY_THRESHOLD |
| **Legacy mode** | N/A | DAEMON_ALWAYS_OUTPUT=true |

## Advanced Usage

### Custom Activity Detection

**Modify `daemon_has_recent_activity()` to check custom indicators:**

```bash
daemon_has_recent_activity() {
    # ... existing checks ...

    # Custom: Check for recent test runs
    if [ -f "test-results/latest.xml" ]; then
        last_test=$(stat -c %Y "test-results/latest.xml")
        age=$((now - last_test))
        if [ $age -lt $threshold ]; then
            return 0
        fi
    fi

    # Custom: Check for active CI builds
    if [ -f ".github/workflows/ci-status.txt" ]; then
        if grep -q "running" ".github/workflows/ci-status.txt"; then
            return 0
        fi
    fi

    return 1
}
```

### Activity Threshold by Time of Day

```bash
# Longer threshold during off-hours
current_hour=$(date +%H)
if [ $current_hour -lt 9 ] || [ $current_hour -gt 17 ]; then
    ACTIVITY_THRESHOLD=1800  # 30 minutes after hours
else
    ACTIVITY_THRESHOLD=300   # 5 minutes during work
fi
```

### Notification on Resume

```bash
# Alert when activity resumes after long idle
if [ "$has_activity" = true ] && [ $idle_iterations -gt 10 ]; then
    echo "🎉 Activity resumed after ${idle_iterations} iterations!"
    idle_iterations=0
elif [ "$has_activity" = false ]; then
    ((idle_iterations++))
fi
```

## See Also

- [Daemon System](DAEMON_SYSTEM.md) - Full daemon documentation
- [Auto-Launch](AUTO_LAUNCH.md) - Agent auto-launch system
- [Worker Patterns](WORKER_PATTERNS.md) - How to structure tasks
- [Migration Guide](../docs/MIGRATION_v0.5.1.md) - Upgrading to v0.5.1
