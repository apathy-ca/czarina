# Autonomous Czar Daemon

**True autonomous orchestration coordination - monitors workers, detects phase completion, and launches dependent workers automatically.**

## Overview

The Autonomous Czar Daemon (`autonomous-czar-daemon.sh`) implements intelligent orchestration coordination that runs continuously in the background. Unlike the approval daemon which just auto-approves prompts, this daemon actively monitors worker progress and makes coordination decisions.

## What It Does

### Core Monitoring (Every 5 Minutes)

1. **Worker Status Detection**
   - Tracks last commit time for each worker
   - Detects ACTIVE (recent commits), IDLE (>10 min), or STUCK (>30 min) workers
   - Identifies completed workers via log markers or git commit messages

2. **Phase Completion Detection**
   - Monitors all workers in current phase
   - Automatically detects when phase is complete (all workers done)
   - Tracks phase state persistently

3. **Automatic Phase Transitions**
   - Launches Phase 2 workers when Phase 1 complete
   - (Future) Launches workers based on dependency resolution
   - (Future) Coordinates multi-phase orchestrations

4. **Comprehensive Logging**
   - Main daemon log: `.czarina/status/czar-daemon.log`
   - Decision log: `.czarina/status/autonomous-decisions.log`
   - Phase state: `.czarina/status/phase-state.json`

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Autonomous Czar Daemon (tmux: czar-auto window)    │
│  Runs autonomous-czar-daemon.sh every 5 minutes     │
└─────────────────┬───────────────────────────────────┘
                  │
                  ├─> Monitor worker branches (git log)
                  │   ├─ Last commit time
                  │   ├─ Completion markers
                  │   └─ Activity status
                  │
                  ├─> Detect phase completion
                  │   ├─ Check all phase workers
                  │   ├─ Update phase state
                  │   └─ Trigger transitions
                  │
                  ├─> Launch dependent workers
                  │   └─ Phase 2 auto-launch
                  │
                  └─> Log everything
                      ├─ Status updates
                      ├─ Decisions
                      └─ Actions taken
```

## Complementary Daemons

Czarina runs TWO daemons in parallel:

1. **Approval Daemon** (`daemon/czar-daemon.sh`)
   - Auto-approves file access prompts
   - Auto-accepts edit proposals
   - Handles Y/N confirmations
   - Runs every 2 minutes

2. **Autonomous Daemon** (`autonomous-czar-daemon.sh`) ← This one
   - Monitors worker progress
   - Detects phase completion
   - Launches dependent workers
   - Runs every 5 minutes

Together they provide full autonomy: approval daemon removes friction, autonomous daemon provides intelligence.

## Worker Status States

| State | Condition | Description |
|-------|-----------|-------------|
| **PENDING** | No branch or commits | Worker hasn't started yet |
| **ACTIVE** | Commits in last 10 min | Worker actively working |
| **IDLE** | No commits for 10-30 min | Worker may need nudge |
| **STUCK** | No commits for 30+ min | Worker likely blocked |
| **COMPLETE** | Completion marker found | Worker finished tasks |
| **ERROR** | Branch doesn't exist | Configuration issue |

## Phase State Tracking

The daemon maintains phase state in `.czarina/status/phase-state.json`:

```json
{
  "current_phase": 1,
  "phase_1_complete": false,
  "phase_2_launched": false
}
```

This state persists across daemon restarts and provides coordination history.

## Automatic Phase 2 Launch

When Phase 1 is detected as complete:

1. Daemon logs: `✅ PHASE 1 COMPLETE!`
2. Updates phase state: `phase_1_complete: true`
3. Identifies Phase 2 workers from config
4. (Current) Logs workers that should be launched
5. (Future) Actually launches workers in tmux
6. Updates phase state: `phase_2_launched: true, current_phase: 2`

## Integration

### Automatic Launch

The daemon starts automatically with `czarina launch`:

```bash
czarina launch
# Creates management session with:
# - Window "daemon": Auto-approval daemon
# - Window "czar-auto": Autonomous coordination daemon
# - Window "dashboard": Live monitoring
```

### Manual Launch

For testing or manual orchestrations:

```bash
cd /path/to/project
./path/to/czarina-core/autonomous-czar-daemon.sh ./.czarina
```

### View Logs

```bash
# Main daemon log
tail -f .czarina/status/czar-daemon.log

# Decisions only
tail -f .czarina/status/autonomous-decisions.log

# Check phase state
cat .czarina/status/phase-state.json | jq
```

## Configuration

The daemon reads `.czarina/config.json`:

```json
{
  "project": {
    "slug": "myproject",
    "repository": "/path/to/repo"
  },
  "workers": [
    {
      "id": "worker1",
      "phase": 1,
      "branch": "cz1/feat/worker1",
      "description": "Phase 1 worker"
    },
    {
      "id": "worker2",
      "phase": 2,
      "branch": "cz1/feat/worker2",
      "description": "Phase 2 worker"
    }
  ]
}
```

Key fields:
- `workers[].phase`: Determines which phase the worker belongs to
- `workers[].branch`: Git branch to monitor for activity
- `project.repository`: Where to check git logs

## Success Criteria

The daemon is working correctly when:

- ✅ Monitoring cycles run every 5 minutes
- ✅ Worker status correctly detected (ACTIVE, IDLE, STUCK, COMPLETE)
- ✅ Phase completion automatically detected
- ✅ Phase 2 launches when Phase 1 done
- ✅ All actions logged to decision log
- ✅ Daemon runs continuously without crashing

## Future Enhancements

### Planned (v0.8.0)
- **Dependency-based launching**: Launch workers when dependencies satisfied
- **Stuck worker nudging**: Send messages to idle/stuck workers
- **Claude Czar consultation**: Ask AI for complex decisions
- **Multi-phase support**: Handle 3+ phase orchestrations

### Possible (v0.9.0)
- **Event-driven coordination**: React to worker events in real-time
- **Parallel dependency chains**: Launch multiple dependency branches
- **Smart scheduling**: Optimize worker launch order
- **Resource management**: Track compute/API usage

## Testing

Run the test suite:

```bash
./czarina-core/test-autonomous-daemon.sh
```

Tests verify:
- Script syntax and execution
- Monitoring cycle functionality
- Phase state tracking
- Decision logging
- Worker status detection

## Troubleshooting

### Daemon not detecting phase completion

**Check:**
```bash
# Are workers actually complete?
git log cz1/feat/worker1 --oneline | head -5

# Do logs have completion markers?
grep WORKER_COMPLETE .czarina/logs/*.log

# What's the daemon seeing?
tail -20 .czarina/status/czar-daemon.log
```

### Phase 2 not launching

**Current limitation:** Phase 2 launch is logged but not yet executed. The daemon will log:
```
→ Would launch: worker3
```

This is expected - actual worker launching requires tmux session management and will be added in v0.7.2.

### Worker stuck in IDLE state

**False positive:** Worker may be complete but daemon doesn't detect marker.

**Add completion marker:**
```bash
# In worker's final commit message
git commit -m "feat: Complete worker tasks

Checkpoint: Worker complete"
```

Or add to worker log:
```bash
echo "WORKER_COMPLETE" >> .czarina/logs/worker-id.log
```

## Files

- `autonomous-czar-daemon.sh` - Main daemon script
- `test-autonomous-daemon.sh` - Test suite
- `AUTONOMOUS_DAEMON.md` - This documentation

## See Also

- [Daemon System](daemon/README.md) - Approval daemon docs
- [Issue: Czar Not Autonomous](.czarina/hopper/issue-czar-not-autonomous.md) - Original problem statement
- [Launch Integration](launch-project-v2.sh) - How daemon is launched

---

**Status**: Production Ready (v0.7.1)
**Version**: 1.0
**Created**: 2025-12-28
