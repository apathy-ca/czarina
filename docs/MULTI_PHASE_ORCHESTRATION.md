# Multi-Phase Orchestration Guide

**Version:** v0.7.2+
**Feature:** Automated Phase Completion Detection & Transitions
**Status:** Production Ready

---

## Overview

Multi-phase orchestration enables running sequential development phases on the same codebase with full automation. Each phase can have different workers, and transitions happen automatically when phases complete.

### What's New in v0.7.2

- **Automatic Phase Completion Detection** - Multi-signal detection knows when phases are done
- **Automated Phase Transitions** - No manual intervention needed between phases
- **Smart Phase Initialization** - Detects previous phases and auto-archives history
- **Flexible Completion Modes** - Configure how strictly to detect completion
- **Complete Audit Trail** - Full logging of all phase decisions and transitions

---

## Quick Start

### Single Phase Project

```bash
# Phase 1: Initial implementation
czarina analyze docs/v1.0-plan.md --interactive --init
czarina launch --go

# Autonomous daemon monitors workers and detects completion
# When all workers complete, phase closes automatically
```

### Multi-Phase Project

```bash
# Phase 1: Core features
czarina analyze docs/phase-1-plan.md --interactive --init
czarina launch --go

# Daemon auto-detects completion and archives phase
# Ready for next phase...

# Phase 2: Additional features
czarina analyze docs/phase-2-plan.md --interactive --init
czarina launch --go

# Continues automatically...
```

---

## Phase Completion Detection

### How It Works

Czarina uses **multi-signal detection** to determine when workers complete:

1. **Worker Log Markers** - `WORKER_COMPLETE` events in worker logs
2. **Git Branch Status** - Worker branch merged to omnibus/integration branch
3. **Worker Status Files** - `worker-status.json` completion markers
4. **Configuration Rules** - Completion criteria defined in config

### Completion Modes

Configure how strictly to detect completion in `config.json`:

```json
{
  "phase_completion_mode": "any"
}
```

**Available Modes:**

| Mode | Behavior | Use Case |
|------|----------|----------|
| `any` | Any signal indicates completion | Flexible, trust worker logs |
| `all` | All signals must indicate completion | Paranoid, want multiple confirmations |
| `strict` | Log marker AND (branch merged OR status) | Production, need high confidence |

**Default:** `any` (recommended for most projects)

### Detection Signals

#### 1. Worker Log Markers

Workers log completion events:

```bash
czarina_log_worker_complete
```

Creates event in `logs/events.jsonl`:
```json
{"timestamp": "2025-12-29T10:30:00Z", "event": "WORKER_COMPLETE", "worker": "api-gateway"}
```

#### 2. Git Branch Status

Worker branch merged to omnibus branch:

```bash
# Worker branch
cz1/feat/api-gateway

# Merged to omnibus
cz1/release/v1.0.0
```

Czarina checks: `git branch --merged cz1/release/v1.0.0 | grep cz1/feat/api-gateway`

#### 3. Worker Status Files

Status file indicates completion:

```json
{
  "worker_id": "api-gateway",
  "status": "complete",
  "completion_time": "2025-12-29T10:30:00Z"
}
```

### Manual Detection Check

Check phase completion manually:

```bash
# Check if current phase is complete
./czarina-core/phase-completion-detector.sh --verbose

# Check specific phase
./czarina-core/phase-completion-detector.sh --phase 1 --verbose

# JSON output for scripting
./czarina-core/phase-completion-detector.sh --json
```

**Exit codes:**
- `0` - Phase is complete
- `1` - Phase is not complete
- `2` - Error occurred

---

## Automated Phase Transitions

### Autonomous Daemon

The autonomous Czar daemon monitors phase completion and triggers transitions:

```bash
# Start daemon (done automatically with 'czarina launch --go')
./czarina-core/autonomous-czar-daemon.sh

# Check daemon status
czarina status
```

### Transition Workflow

1. **Monitoring Phase** (every 5 minutes)
   - Daemon checks worker completion status
   - Logs worker health (active, idle, stuck, complete)
   - Detects when all workers in current phase complete

2. **Phase Complete Detected**
   - All workers show completion signals
   - Phase marked complete in `status/phase-state.json`:
   ```json
   {
     "current_phase": 1,
     "phase_1_complete": true,
     "phase_2_launched": false
   }
   ```

3. **Automatic Archival**
   - Current phase state archived to `.czarina/phases/phase-N-vX.Y.Z/`
   - Includes config snapshot, logs, worker prompts, status files
   - History preserved indefinitely

4. **Next Phase Launch** (if configured)
   - Phase 2 workers automatically launched
   - New worktrees created
   - Workers begin work immediately
   - Zero manual intervention required

### Decision Logging

All phase transition decisions are logged:

**Human-readable:**
```bash
cat status/autonomous-decisions.log
```

```
[2025-12-29 10:30:00] Phase 1 completion detected - all workers complete
[2025-12-29 10:30:15] Archiving phase 1 to .czarina/phases/phase-1-v1.0.0/
[2025-12-29 10:30:30] Launching phase 2 workers: security, performance
```

**Machine-readable:**
```bash
cat logs/events.jsonl
```

```json
{"timestamp": "2025-12-29T10:30:00Z", "event": "PHASE_COMPLETE", "phase": 1}
{"timestamp": "2025-12-29T10:30:15Z", "event": "PHASE_ARCHIVED", "phase": 1, "path": ".czarina/phases/phase-1-v1.0.0"}
{"timestamp": "2025-12-29T10:30:30Z", "event": "PHASE_LAUNCHED", "phase": 2, "workers": ["security", "performance"]}
```

---

## Phase Configuration

### Basic Multi-Phase Config

```json
{
  "project": {
    "name": "myproject",
    "slug": "myproject-v1_0_0",
    "phase": 1,
    "omnibus_branch": "cz1/release/v1.0.0",
    "version": "1.0.0"
  },
  "phase_completion_mode": "any",
  "workers": [
    {
      "id": "api-gateway",
      "phase": 1,
      "branch": "cz1/feat/api-gateway",
      "dependencies": []
    },
    {
      "id": "auth-service",
      "phase": 1,
      "branch": "cz1/feat/auth-service",
      "dependencies": ["api-gateway"]
    },
    {
      "id": "integration",
      "phase": 1,
      "branch": "cz1/release/v1.0.0",
      "role": "integration",
      "dependencies": ["api-gateway", "auth-service"]
    }
  ]
}
```

### Advanced: Multiple Phases

```json
{
  "project": {
    "phase": 1,
    "omnibus_branch": "cz1/release/v1.0.0"
  },
  "phase_completion_mode": "strict",
  "workers": [
    {
      "id": "core-api",
      "phase": 1,
      "branch": "cz1/feat/core-api"
    },
    {
      "id": "integration",
      "phase": 1,
      "branch": "cz1/release/v1.0.0",
      "role": "integration"
    }
  ],
  "phases": {
    "phase_2": {
      "omnibus_branch": "cz2/release/v2.0.0",
      "workers": [
        {
          "id": "security",
          "phase": 2,
          "branch": "cz2/feat/security"
        },
        {
          "id": "performance",
          "phase": 2,
          "branch": "cz2/feat/performance"
        }
      ]
    }
  }
}
```

---

## Smart Phase Initialization

### Auto-Detection

When you run `czarina init`, it automatically detects:

1. **First-time initialization** - No `.czarina/` directory exists
2. **Phase closed** - `.czarina/workers/` is empty (phase was closed)
3. **Active phase** - Workers exist, will prompt before overwriting

### Phase Closed Detection

```bash
# Previous phase was closed
czarina analyze docs/phase-2-plan.md --interactive --init

# Czarina detects:
# - .czarina/ exists
# - workers/ is empty
# - Phase 1 was closed

# Automatically:
# - Archives remaining phase 1 state (if any)
# - Initializes phase 2 configuration
# - No --force flag needed
```

### Force Reinitialization

Override active phase (use with caution):

```bash
czarina analyze docs/new-plan.md --interactive --init --force

# Warning: This will archive current active phase
# Use only when you're sure you want to restart
```

---

## Phase History & Archival

### Archive Structure

Each phase is archived with complete state:

```
.czarina/phases/
├── phase-1-v1.0.0/
│   ├── config.json              # Configuration snapshot
│   ├── PHASE_SUMMARY.md         # What was accomplished
│   ├── logs/
│   │   ├── events.jsonl         # Machine-readable events
│   │   └── workers/
│   │       ├── api-gateway.log  # Worker logs
│   │       └── auth-service.log
│   ├── status/
│   │   ├── worker-status.json   # Final worker states
│   │   ├── autonomous-decisions.log
│   │   └── phase-state.json
│   └── workers/
│       ├── api-gateway.md       # Worker prompt snapshots
│       └── auth-service.md
├── phase-2-v2.0.0/
│   └── ...
```

### Viewing Phase History

```bash
# List all phases
czarina phase list

# Output:
# Phase 1 (v1.0.0) - Completed 2025-12-29 10:30:00
# Phase 2 (v2.0.0) - Active
```

```bash
# View phase summary
cat .czarina/phases/phase-1-v1.0.0/PHASE_SUMMARY.md
```

### Phase Summary Example

```markdown
# Phase 1 Summary - v1.0.0

**Completed:** 2025-12-29 10:30:00
**Duration:** 14 days
**Status:** ✅ Complete

## Workers

- **api-gateway** - ✅ Complete (merged to cz1/release/v1.0.0)
- **auth-service** - ✅ Complete (merged to cz1/release/v1.0.0)
- **integration** - ✅ Complete (all tests passing)

## Deliverables

- REST API gateway with rate limiting
- JWT-based authentication service
- Integration tests (98% coverage)
- API documentation

## Commits

- 47 commits across 3 workers
- All merged to omnibus branch
- Tagged: v1.0.0
```

---

## Worker Health Monitoring

The autonomous daemon tracks worker health:

### Health States

| State | Condition | Action |
|-------|-----------|--------|
| **Active** | Activity within 10 minutes | Continue monitoring |
| **Idle** | No activity for 10-30 minutes | Log warning |
| **Stuck** | No activity for 30+ minutes | Alert, may need intervention |
| **Complete** | Completion markers present | Mark phase progress |

### Monitoring Intervals

- **Check interval:** 5 minutes
- **Idle threshold:** 10 minutes
- **Stuck threshold:** 30 minutes

### Manual Health Check

```bash
# View autonomous decisions
cat status/autonomous-decisions.log

# Recent worker activity
tail -f logs/events.jsonl | grep WORKER
```

---

## Manual Phase Management

### Manual Phase Close

```bash
# Close current phase (smart cleanup)
czarina phase close

# Keep all worktrees
czarina phase close --keep-worktrees

# Force remove all worktrees
czarina phase close --force-clean
```

### Manual Phase Transition

```bash
# 1. Close current phase
czarina phase close

# 2. Edit config for next phase
nano .czarina/config.json
# Update: project.phase, omnibus_branch, workers array

# 3. Create/update worker prompts
nano .czarina/workers/new-worker.md

# 4. Launch next phase
czarina launch
```

---

## Best Practices

### 1. Phase Planning

**Define clear phases:**
```
Phase 1: Core features (v1.0.0)
Phase 2: Security hardening (v1.1.0)
Phase 3: Performance optimization (v1.2.0)
```

**Set completion criteria:**
- All tests passing
- Documentation complete
- Code reviewed and merged
- Integration successful

### 2. Completion Mode Selection

**Use `any` for:**
- Rapid development
- Trusted worker implementations
- Internal projects

**Use `strict` for:**
- Production releases
- Critical systems
- Compliance requirements

### 3. Worker Dependencies

**Within phase:**
```json
{
  "workers": [
    {"id": "api", "phase": 1, "dependencies": []},
    {"id": "auth", "phase": 1, "dependencies": ["api"]},
    {"id": "integration", "phase": 1, "dependencies": ["api", "auth"]}
  ]
}
```

**Across phases:**
- Phase 1 integration worker merges to main/master
- Phase 2 workers branch from main/master
- Clean separation between phases

### 4. Monitoring

**Check daemon status regularly:**
```bash
czarina status
```

**Review decision logs:**
```bash
tail -f status/autonomous-decisions.log
```

**Verify completion detection:**
```bash
./czarina-core/phase-completion-detector.sh --verbose
```

### 5. Archive Management

**Keep phase history:**
- Don't delete `.czarina/phases/` archives
- Provides complete development audit trail
- Useful for retrospectives and debugging

**Review phase summaries:**
- Learn from successful patterns
- Identify improvement opportunities
- Document lessons learned

---

## Troubleshooting

### Phase Not Auto-Completing

**Check completion signals:**

```bash
# Verbose detection check
./czarina-core/phase-completion-detector.sh --verbose

# Check worker logs for WORKER_COMPLETE
grep WORKER_COMPLETE logs/workers/*.log

# Check branch merge status
git branch --merged cz1/release/v1.0.0 | grep cz1/feat/
```

**Common issues:**
- Workers didn't call `czarina_log_worker_complete`
- Branches not merged to omnibus
- Status files not updated
- Wrong completion mode (try `any` instead of `strict`)

### Phase Transition Not Triggering

**Check daemon:**

```bash
# Is daemon running?
czarina status

# Check daemon logs
tail -f logs/autonomous-czar.log
```

**Check phase state:**

```bash
cat status/phase-state.json
```

**Manual trigger:**

```bash
# Close current phase manually
czarina phase close

# Initialize next phase
czarina analyze docs/phase-2-plan.md --interactive --init
czarina launch --go
```

### Worker Showing as Stuck

**Check worker activity:**

```bash
# View worker log
tail -f logs/workers/worker-id.log

# Check tmux session
tmux attach -t projectname-worker-id
```

**If truly stuck:**

```bash
# Stop worker
tmux kill-session -t projectname-worker-id

# Investigate issue
# Fix and restart
czarina launch worker-id
```

### Archive Path Issues

**Check archive exists:**

```bash
ls -la .czarina/phases/

# Should see:
# phase-1-v1.0.0/
# phase-2-v2.0.0/
```

**Manually archive if needed:**

```bash
./czarina-core/phase-close.sh
```

---

## Examples

### Example 1: Three-Phase Release

```bash
# Phase 1: Core API (v1.0.0)
czarina analyze docs/api-plan.md --interactive --init
czarina launch --go
# ... autonomous completion after 2 weeks ...
# Phase auto-archived to .czarina/phases/phase-1-v1.0.0/

# Phase 2: Security Features (v1.1.0)
czarina analyze docs/security-plan.md --interactive --init
czarina launch --go
# ... autonomous completion after 1 week ...
# Phase auto-archived to .czarina/phases/phase-2-v1.1.0/

# Phase 3: Performance (v1.2.0)
czarina analyze docs/performance-plan.md --interactive --init
czarina launch --go
# ... autonomous completion after 1 week ...
# Phase auto-archived to .czarina/phases/phase-3-v1.2.0/

# Complete development history preserved!
```

### Example 2: Strict Completion Mode

```json
{
  "phase_completion_mode": "strict",
  "workers": [
    {
      "id": "payment-gateway",
      "phase": 1,
      "branch": "cz1/feat/payment-gateway"
    }
  ]
}
```

**Strict mode requires:**
1. Worker calls `czarina_log_worker_complete`
2. AND (branch merged to omnibus OR status file shows complete)

**Perfect for financial/critical systems.**

### Example 3: Phase History Review

```bash
# After 6 months and 5 phases...
czarina phase list

# Output:
# Phase 1 (v1.0.0) - Complete - 2025-06-01
# Phase 2 (v1.1.0) - Complete - 2025-07-15
# Phase 3 (v1.2.0) - Complete - 2025-09-01
# Phase 4 (v2.0.0) - Complete - 2025-11-01
# Phase 5 (v2.1.0) - Active

# Review successful phase
cat .czarina/phases/phase-1-v1.0.0/PHASE_SUMMARY.md

# Copy successful worker pattern
cp .czarina/phases/phase-1-v1.0.0/workers/api-gateway.md \
   .czarina/workers/new-api-worker.md
```

---

## Migration from Manual Phases

### Before v0.7.2 (Manual)

```bash
# Phase 1
czarina launch
# ... manual monitoring ...
# ... manual completion check ...
czarina phase close

# Phase 2
# ... manual config edit ...
czarina launch
```

### After v0.7.2 (Automated)

```bash
# Phase 1
czarina analyze docs/phase-1.md --interactive --init
czarina launch --go

# ✅ Automatic completion detection
# ✅ Automatic archival
# ✅ Automatic phase 2 launch (if configured)
# ✅ Complete audit trail
```

**Migration steps:**

1. Add `phase_completion_mode` to config.json
2. Ensure workers call `czarina_log_worker_complete`
3. Use `czarina launch --go` instead of manual daemon start
4. Trust the automation!

---

## API Reference

### Phase Completion Detector

```bash
./czarina-core/phase-completion-detector.sh [options]

Options:
  --config-file <path>   Path to config.json (default: .czarina/config.json)
  --phase <number>       Phase number to check (default: current phase)
  --verbose              Enable verbose output
  --json                 Output JSON format for scripting

Exit Codes:
  0 - Phase is complete
  1 - Phase is not complete
  2 - Error occurred

Examples:
  # Check current phase
  ./czarina-core/phase-completion-detector.sh --verbose

  # Check specific phase with JSON output
  ./czarina-core/phase-completion-detector.sh --phase 1 --json
```

### Phase State File

**Location:** `status/phase-state.json`

```json
{
  "current_phase": 1,
  "phase_1_complete": false,
  "phase_2_launched": false,
  "last_check": "2025-12-29T10:30:00Z"
}
```

---

## Summary

Multi-phase orchestration in v0.7.2 provides:

- ✅ **Automatic completion detection** - Multi-signal, configurable
- ✅ **Automated transitions** - Zero manual intervention
- ✅ **Complete audit trail** - Full history preserved
- ✅ **Smart initialization** - Detects and archives previous phases
- ✅ **Flexible configuration** - Choose completion strictness
- ✅ **Production ready** - Comprehensive testing and logging

**Perfect for:**
- Long-running projects with multiple release phases
- Sequential feature development
- Complex orchestrations requiring phased rollout
- Projects requiring complete development audit trails

**Next:** See [Phase Transition Troubleshooting](../troubleshooting/PHASE_TRANSITIONS.md) for common issues and solutions.
