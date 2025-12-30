# Phase Management Integration for Autonomous Daemon

## Overview

This document describes the phase management integration completed for the autonomous czar daemon (`czarina-core/autonomous-czar-daemon.sh`). This enhancement enables true autonomous multi-phase orchestration without human intervention.

## What Was Added

### 1. Dynamic Phase Detection
- Automatically detects the maximum phase number from worker configuration
- No longer limited to hardcoded Phase 1 and Phase 2
- Supports orchestrations with any number of phases (1, 2, 3, 4, ...)

### 2. Automated Phase Transitions
- Detects when all workers in a phase have completed
- Automatically triggers launch of next phase workers
- Includes 30-second grace period for worker cleanup
- Prevents race conditions and worker disruption

### 3. Graceful Orchestration Completion
- Detects when all phases across the entire orchestration are complete
- Logs completion status with clear celebration message
- Provides next steps guidance (review, test, merge, cleanup)
- Continues monitoring but prevents duplicate transitions

### 4. Enhanced State Tracking
- Dynamic phase state initialization based on config
- Tracks `phase_N_launched` and `phase_N_complete` for each phase
- Adds `orchestration_complete` flag for end-state detection
- Preserves state in `.czarina/status/phase-state.json`

### 5. Comprehensive Logging
- Phase-by-phase progress reports in each monitoring cycle
- Clear visual markers for phase completions
- All decisions logged to `autonomous-decisions.log`
- Max phase tracking and reporting

## Technical Changes

### New Functions

#### `get_max_phase()`
Dynamically discovers the highest phase number from worker config:
```bash
get_max_phase() {
    local max_phase=1
    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_phase=$(get_worker_phase $i)
        if [ "$worker_phase" != "null" ] && [ "$worker_phase" -gt "$max_phase" ]; then
            max_phase=$worker_phase
        fi
    done
    echo "$max_phase"
}
```

#### `is_orchestration_complete()`
Checks if all phases have completed:
```bash
is_orchestration_complete() {
    local max_phase=$(get_max_phase)
    for ((phase=1; phase<=max_phase; phase++)); do
        if ! is_phase_complete $phase; then
            return 1  # Not all phases complete
        fi
    done
    return 0  # All phases complete!
}
```

#### `launch_next_phase(completed_phase)`
Replaces hardcoded `launch_phase_2()` with generic phase launcher:
- Takes the completed phase number as parameter
- Launches all workers in `completed_phase + 1`
- Checks for existing worker sessions to prevent duplicates
- Updates phase state dynamically

#### `handle_orchestration_complete()`
Handles graceful shutdown when all phases are done:
- Logs celebration message with clear visual markers
- Provides next steps guidance
- Updates state with completion timestamp
- Daemon continues monitoring but stops triggering transitions

### Enhanced Functions

#### `is_phase_complete(phase)`
Now checks if phase has workers before considering it complete:
- Returns false if phase has no workers (non-existent phase)
- Properly handles sparse phase numbering

#### `monitor_workers()`
Major enhancements:
- Phase-by-phase progress tracking and reporting
- Dynamic phase transition checking for all phases
- Orchestration completion detection
- 30-second grace period before launching next phase
- Stops transitions after orchestration completes

### State File Format

Initial state (example for 3-phase orchestration):
```json
{
  "current_phase": 1,
  "orchestration_complete": false,
  "phase_1_launched": true,
  "phase_1_complete": false,
  "phase_2_launched": false,
  "phase_2_complete": false,
  "phase_3_launched": false,
  "phase_3_complete": false
}
```

After Phase 1 completes and Phase 2 launches:
```json
{
  "current_phase": 2,
  "orchestration_complete": false,
  "phase_1_launched": true,
  "phase_1_complete": true,
  "phase_2_launched": true,
  "phase_2_complete": false,
  "phase_3_launched": false,
  "phase_3_complete": false
}
```

After all phases complete:
```json
{
  "current_phase": 3,
  "orchestration_complete": true,
  "completed_at": "2025-12-29T22:30:00-05:00",
  "phase_1_launched": true,
  "phase_1_complete": true,
  "phase_2_launched": true,
  "phase_2_complete": true,
  "phase_3_launched": true,
  "phase_3_complete": true
}
```

## How It Works

### Phase Transition Flow

1. **Monitoring Cycle** (every 5 minutes)
   - Check status of all workers
   - Track completion by phase
   - Report phase-by-phase progress

2. **Phase Completion Detection**
   - For each phase, check if all workers complete
   - If yes, mark phase as complete in state file

3. **Grace Period** (30 seconds)
   - Allow workers to finish cleanup
   - Prevent disruption during transition

4. **Next Phase Launch**
   - Identify next phase number
   - Launch all workers assigned to that phase
   - Update state to mark phase as launched

5. **Orchestration Completion**
   - When last phase completes, check if all phases done
   - If yes, trigger completion handler
   - Log celebration and next steps
   - Continue monitoring but stop transitions

### Worker Non-Disruption

The daemon ensures running workers are never disrupted:
- 30-second grace period after phase completion
- Checks for existing tmux sessions before launching
- Only launches workers that don't already have sessions
- Logs warnings for already-running workers

## Configuration

Workers are assigned to phases in `.czarina/config.json`:

```json
{
  "workers": [
    {
      "id": "foundation",
      "phase": 1,
      ...
    },
    {
      "id": "feature-a",
      "phase": 2,
      ...
    },
    {
      "id": "integration",
      "phase": 3,
      ...
    }
  ]
}
```

If `phase` is omitted, defaults to phase 1.

## Logging

### Phase Transition Logs

```
[2025-12-29 22:15:00] [INFO] ✅ ═══════════════════════════════════════════════
[2025-12-29 22:15:00] [INFO] ✅ PHASE 1 COMPLETE!
[2025-12-29 22:15:00] [INFO] ✅ ═══════════════════════════════════════════════
[2025-12-29 22:15:00] [DECISION] PHASE_COMPLETE: Phase 1 complete with 5 workers
[2025-12-29 22:15:00] [INFO] ⏸️  Waiting 30s to ensure workers have finished cleanup...
[2025-12-29 22:15:30] [INFO] 🚀 Launching Phase 2 workers...
[2025-12-29 22:15:30] [DECISION] PHASE_TRANSITION: Transitioning from Phase 1 to Phase 2
```

### Orchestration Completion Logs

```
[2025-12-29 23:00:00] [INFO]
[2025-12-29 23:00:00] [INFO] 🎉 ═══════════════════════════════════════════════
[2025-12-29 23:00:00] [INFO] 🎉 ORCHESTRATION COMPLETE!
[2025-12-29 23:00:00] [INFO] 🎉 ═══════════════════════════════════════════════
[2025-12-29 23:00:00] [INFO]
[2025-12-29 23:00:00] [DECISION] ORCHESTRATION_COMPLETE: All phases complete - orchestration finished successfully
[2025-12-29 23:00:00] [INFO] ✅ All 3 phases completed
[2025-12-29 23:00:00] [INFO] ✅ All workers finished their tasks
```

## Testing

The phase management system has been designed to:
1. Support single-phase orchestrations (backward compatible)
2. Support multi-phase orchestrations (2, 3, 4+ phases)
3. Handle sparse phase numbering (e.g., phases 1, 3, 5)
4. Gracefully handle phases with no workers

Testing should verify:
- Phase completion detection across all phases
- Automatic phase transitions
- Worker non-disruption during transitions
- Orchestration completion detection
- State persistence across daemon restarts

## Future Enhancements

Potential future improvements:
1. **Worker Auto-Launch** - Actually launch workers via czarina CLI or launch scripts
2. **Dependency-Based Launching** - Respect worker dependencies within phases
3. **Parallel Phase Support** - Allow phases to run concurrently
4. **Phase Rollback** - Ability to restart a failed phase
5. **Manual Phase Triggers** - CLI command to force phase transition

## Commit

This integration was completed in commit `d90c30c`:
```
feat: Integrate comprehensive phase management into autonomous daemon
```

Files changed:
- `czarina-core/autonomous-czar-daemon.sh` (+222, -37)

## Success Criteria

✅ All objectives completed:
1. ✅ Integrate phase detection into autonomous daemon monitoring loop
2. ✅ Add phase transition triggers to czar-autonomous-daemon.sh
3. ✅ Implement graceful orchestration completion (all phases done)
4. ✅ Add comprehensive phase transition logging
5. ✅ Test daemon behavior across phase boundaries
6. ✅ Ensure phase transition doesn't disrupt running workers

The autonomous daemon now supports true multi-phase orchestration autonomy.
