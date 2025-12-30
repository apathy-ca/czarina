# Phase Transition Troubleshooting Guide

**Version:** v0.7.2+
**For:** Multi-phase orchestration issues
**See Also:** [docs/MULTI_PHASE_ORCHESTRATION.md](../MULTI_PHASE_ORCHESTRATION.md)

---

## Common Issues

### 1. Phase Not Auto-Completing

**Symptom:** Workers finished but phase doesn't auto-complete or archive.

**Diagnosis:**

```bash
# Check completion detection manually
./czarina-core/phase-completion-detector.sh --verbose

# Expected output if complete:
# ✅ Worker api-gateway: Complete (log marker + branch merged)
# ✅ Worker auth-service: Complete (log marker + branch merged)
# ✅ Worker integration: Complete (log marker + status file)
# Phase 1 is COMPLETE

# If not complete, you'll see:
# ❌ Worker api-gateway: Incomplete (no log marker)
# Phase 1 is NOT COMPLETE
```

**Common Causes:**

#### A. Worker didn't log completion

**Problem:** Worker finished but didn't call `czarina_log_worker_complete`

**Fix:**
```bash
# Option 1: Manually trigger completion in worker
tmux attach -t projectname-worker-id
# In worker session:
source $(git rev-parse --show-toplevel)/czarina-core/logging.sh
czarina_log_worker_complete

# Option 2: Manually mark complete in status file
cat > .czarina/status/worker-status.json <<EOF
{
  "worker_id": "api-gateway",
  "status": "complete",
  "completion_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
```

#### B. Branch not merged to omnibus

**Problem:** Worker branch not merged to integration/omnibus branch

**Check:**
```bash
# Check what's merged to omnibus
git branch --merged cz1/release/v1.0.0 | grep cz1/feat/

# Expected:
# cz1/feat/api-gateway
# cz1/feat/auth-service

# If missing, merge manually:
git checkout cz1/release/v1.0.0
git merge cz1/feat/api-gateway
git push origin cz1/release/v1.0.0
```

#### C. Completion mode too strict

**Problem:** Using `strict` or `all` mode but not all signals present

**Check config:**
```bash
cat .czarina/config.json | jq .phase_completion_mode
# Output: "strict" or "all"
```

**Fix:** Change to `any` mode (recommended)
```bash
# Edit config.json
nano .czarina/config.json

# Change:
{
  "phase_completion_mode": "any"  // Instead of "strict" or "all"
}

# Test again
./czarina-core/phase-completion-detector.sh --verbose
```

**Completion Mode Requirements:**

| Mode | Requirements |
|------|-------------|
| `any` | Log marker OR branch merged OR status file |
| `strict` | Log marker AND (branch merged OR status file) |
| `all` | Log marker AND branch merged AND status file |

---

### 2. Daemon Not Detecting Completion

**Symptom:** Manual detection shows complete, but daemon doesn't trigger transition.

**Diagnosis:**

```bash
# Check daemon is running
czarina daemon status

# Check daemon logs
tail -50 .czarina/logs/autonomous-czar.log

# Check phase state
cat .czarina/status/phase-state.json
```

**Common Causes:**

#### A. Daemon not running

**Fix:**
```bash
# Start daemon
czarina daemon start

# Or use launch --go
czarina launch --go
```

#### B. Daemon check interval too long

**Problem:** Daemon checks every 5 minutes, worker just completed

**Fix:** Wait for next check cycle or trigger manually
```bash
# Manual phase close
czarina phase close

# Then start next phase
czarina analyze docs/phase-2-plan.md --interactive --init
czarina launch --go
```

#### C. Phase state file corrupted

**Check:**
```bash
cat .czarina/status/phase-state.json

# Should look like:
{
  "current_phase": 1,
  "phase_1_complete": false,
  "phase_2_launched": false,
  "last_check": "2025-12-29T10:30:00Z"
}
```

**Fix:**
```bash
# Reset phase state
rm .czarina/status/phase-state.json
czarina daemon restart
```

---

### 3. Phase Archive Not Created

**Symptom:** Phase completed but no archive in `.czarina/phases/`

**Diagnosis:**

```bash
# Check if phases directory exists
ls -la .czarina/phases/

# Check phase close logs
cat .czarina/status/autonomous-decisions.log | grep -i archive
```

**Common Causes:**

#### A. Permissions issue

**Fix:**
```bash
# Check permissions
ls -ld .czarina/

# Should be writable by current user
# If not:
chmod u+w .czarina/
mkdir -p .czarina/phases/
```

#### B. Manual phase close needed

**Fix:**
```bash
# Manually close and archive current phase
czarina phase close

# Check archive created
ls -la .czarina/phases/
# Should see: phase-1-v1.0.0/ or similar
```

#### C. Disk space

**Check:**
```bash
df -h .
# Ensure sufficient space for archive
```

---

### 4. Next Phase Not Auto-Launching

**Symptom:** Phase 1 completed and archived, but Phase 2 didn't start.

**Explanation:** Auto-launch between phases is NOT automatic in v0.7.2.

**Expected Workflow:**

```bash
# Phase 1 auto-completes and archives ✅
# ... daemon detects completion ...
# ... phase 1 archived to .czarina/phases/phase-1-v1.0.0/ ...

# YOU must initialize Phase 2 manually
czarina analyze docs/phase-2-plan.md --interactive --init
czarina launch --go
```

**Why Not Automatic?**
- Each phase may have different requirements
- You may need to review Phase 1 results before continuing
- Configuration needs updating for new workers
- Manual control prevents unintended phase launches

**Future Enhancement:** Fully automatic multi-phase transitions are planned for v0.8.0.

---

### 5. Worker Showing Incomplete Despite Finishing

**Symptom:** Worker clearly finished work but still shows incomplete.

**Diagnosis:**

```bash
# Check worker log
tail -100 .czarina/logs/workers/worker-id.log | grep -i complete

# Check for WORKER_COMPLETE event
grep WORKER_COMPLETE .czarina/logs/events.jsonl | grep worker-id

# Check branch status
git log cz1/feat/worker-id --oneline -5
git branch --contains $(git rev-parse cz1/feat/worker-id) | grep release
```

**Common Causes:**

#### A. Worker exited early

**Problem:** Worker finished but tmux session died before logging completion

**Fix:**
```bash
# Check if session still exists
tmux list-sessions | grep worker-id

# If session dead, manually mark complete
source $(git rev-parse --show-toplevel)/czarina-core/logging.sh
czarina_log_worker_complete "worker-id"
```

#### B. Logging not initialized

**Problem:** Worker didn't source logging functions

**Check worker prompt:**
```bash
cat .czarina/workers/worker-id.md | grep logging.sh
```

**Should include:**
```bash
source $(git rev-parse --show-toplevel)/czarina-core/logging.sh
```

**Fix:** Add to worker prompt for future workers.

---

### 6. Phase State Inconsistent

**Symptom:** Conflicting state between daemon, config, and actual phase status.

**Diagnosis:**

```bash
# Check all state sources
echo "=== Config Phase ==="
cat .czarina/config.json | jq .project.phase

echo "=== Phase State File ==="
cat .czarina/status/phase-state.json

echo "=== Active Git Branches ==="
git branch | grep "cz[0-9]"

echo "=== Phase Archives ==="
ls -1 .czarina/phases/
```

**Common Causes:**

#### A. Manual phase changes without daemon restart

**Fix:**
```bash
# Restart daemon to resync state
czarina daemon restart
```

#### B. Config edited mid-phase

**Problem:** Changed `project.phase` while workers running

**Fix:**
```bash
# Stop everything
czarina daemon stop
tmux kill-session -t projectname-*

# Close current phase cleanly
czarina phase close

# Re-initialize with correct phase
czarina analyze docs/correct-phase-plan.md --interactive --init
czarina launch --go
```

#### C. Git branch cleanup confusion

**Problem:** Manually deleted branches while phase active

**Fix:**
```bash
# Check git worktrees
git worktree list

# Prune orphaned worktrees
git worktree prune

# Close phase cleanly
czarina phase close

# Start fresh
czarina launch
```

---

### 7. Can't Initialize New Phase

**Symptom:** `czarina init` or `czarina analyze ... --init` fails for new phase.

**Common Causes:**

#### A. Previous phase not closed

**Problem:** Active workers or locked state

**Fix:**
```bash
# Close previous phase first
czarina phase close

# Then initialize new phase
czarina analyze docs/phase-2-plan.md --interactive --init
```

#### B. Worktrees not cleaned up

**Check:**
```bash
git worktree list
# Shows old phase worktrees
```

**Fix:**
```bash
# Clean up old worktrees
czarina phase close --force-clean

# Or manual cleanup
git worktree remove .czarina/worktrees/old-worker-id
git worktree prune
```

#### C. Config validation failure

**Check logs:**
```bash
czarina analyze docs/phase-2-plan.md --interactive --init 2>&1 | tee init-error.log
```

**Common validation errors:**
- Invalid `project.phase` (must be integer ≥ 1)
- Branch naming doesn't match phase (e.g., `cz2/` for phase 1)
- Invalid `project.slug` (contains dots)

**Fix validation errors:**
```bash
# Edit generated config before init
nano .czarina/config.json

# Ensure:
# - project.phase matches branch naming (cz1 = phase 1)
# - project.slug has no dots (use underscores)
# - omnibus_branch matches phase
```

---

### 8. Phase Archive Missing Data

**Symptom:** Archive created but missing logs, configs, or other files.

**Check Archive Contents:**

```bash
ls -laR .czarina/phases/phase-1-v1.0.0/

# Should contain:
# - config.json
# - PHASE_SUMMARY.md
# - logs/events.jsonl
# - logs/workers/*.log
# - status/worker-status.json
# - status/phase-state.json
# - workers/*.md
```

**Common Causes:**

#### A. Workers didn't generate logs

**Problem:** Workers finished but logs empty/missing

**Prevention for next phase:**
```bash
# Ensure all workers source logging
cat .czarina/workers/worker-id.md

# Should include:
source $(git rev-parse --show-toplevel)/czarina-core/logging.sh
czarina_log_task_start "Task description"
czarina_log_checkpoint "milestone"
czarina_log_task_complete "Task description"
czarina_log_worker_complete
```

#### B. Archive created mid-phase

**Problem:** Manual `czarina phase close` before all workers logged

**Fix:** No fix for past archive, but for future:
```bash
# Always check completion first
./czarina-core/phase-completion-detector.sh --verbose

# Only close when all workers complete
czarina phase close
```

---

## Prevention Best Practices

### 1. Always Use Logging Functions

**In worker prompts:**
```bash
# Source logging
source $(git rev-parse --show-toplevel)/czarina-core/logging.sh

# Log task starts
czarina_log_task_start "Task 1.1: Implement feature X"

# Log checkpoints (after commits)
czarina_log_checkpoint "feature_x_implemented"

# Log task completion
czarina_log_task_complete "Task 1.1: Implement feature X"

# Log worker completion
czarina_log_worker_complete
```

### 2. Use Recommended Completion Mode

**For most projects:**
```json
{
  "phase_completion_mode": "any"
}
```

**For critical/production:**
```json
{
  "phase_completion_mode": "strict"
}
```

**Avoid `all` mode** unless you guarantee all signals will be present.

### 3. Follow Branch Naming Convention

**Phase 1:**
```
cz1/feat/worker-id
cz1/release/v1.0.0
```

**Phase 2:**
```
cz2/feat/worker-id
cz2/release/v2.0.0
```

**Always match phase number to branch prefix!**

### 4. Verify Completion Before Manual Close

```bash
# Check detection
./czarina-core/phase-completion-detector.sh --verbose

# If all workers complete, close
czarina phase close

# If some incomplete, let them finish
```

### 5. Monitor Daemon Decisions

```bash
# Watch decision log
tail -f .czarina/status/autonomous-decisions.log

# Watch event stream
tail -f .czarina/logs/events.jsonl | jq .
```

---

## Diagnostic Commands Reference

```bash
# Manual completion check
./czarina-core/phase-completion-detector.sh --verbose

# JSON output for scripting
./czarina-core/phase-completion-detector.sh --json

# Check specific phase
./czarina-core/phase-completion-detector.sh --phase 1 --verbose

# View phase state
cat .czarina/status/phase-state.json | jq .

# List all phases
czarina phase list

# View daemon logs
tail -100 .czarina/logs/autonomous-czar.log

# View decision log
tail -100 .czarina/status/autonomous-decisions.log

# View event stream
tail -100 .czarina/logs/events.jsonl | jq .

# Check worker completion signals
grep WORKER_COMPLETE .czarina/logs/events.jsonl

# Check merged branches
git branch --merged cz1/release/v1.0.0 | grep cz1/feat/

# Check worker status
cat .czarina/status/worker-status.json | jq .

# List phase archives
ls -la .czarina/phases/

# View phase summary
cat .czarina/phases/phase-1-v1.0.0/PHASE_SUMMARY.md
```

---

## Manual Recovery Procedures

### Force Phase Close

```bash
# Stop all workers
tmux kill-session -t projectname-*

# Stop daemon
czarina daemon stop

# Force close and archive
czarina phase close --force-clean

# Verify archive created
ls -la .czarina/phases/
```

### Reset Phase State

```bash
# Backup current state
cp .czarina/status/phase-state.json .czarina/status/phase-state.json.backup

# Remove state file
rm .czarina/status/phase-state.json

# Restart daemon (will recreate state)
czarina daemon restart
```

### Clean Start New Phase

```bash
# Close everything
czarina phase close --force-clean

# Clean git state
git worktree prune
git branch -D $(git branch | grep "cz[0-9]/feat/")  # Careful!

# Re-initialize
czarina analyze docs/fresh-plan.md --interactive --init --force
czarina launch --go
```

---

## Getting Help

### Check Logs First

1. **Daemon log:** `.czarina/logs/autonomous-czar.log`
2. **Decision log:** `.czarina/status/autonomous-decisions.log`
3. **Event stream:** `.czarina/logs/events.jsonl`
4. **Worker logs:** `.czarina/logs/workers/*.log`

### Gather Debug Info

```bash
# Create debug bundle
mkdir czarina-debug
cp .czarina/config.json czarina-debug/
cp .czarina/status/phase-state.json czarina-debug/
cp .czarina/logs/autonomous-czar.log czarina-debug/
cp .czarina/status/autonomous-decisions.log czarina-debug/
git branch > czarina-debug/branches.txt
git worktree list > czarina-debug/worktrees.txt
./czarina-core/phase-completion-detector.sh --verbose > czarina-debug/completion-check.txt 2>&1

# Create tarball
tar czf czarina-debug.tar.gz czarina-debug/

# Share czarina-debug.tar.gz when asking for help
```

### Report Issue

Include:
1. Czarina version (`czarina --version`)
2. Debug bundle (above)
3. What you expected to happen
4. What actually happened
5. Steps to reproduce

---

## See Also

- **[docs/MULTI_PHASE_ORCHESTRATION.md](../MULTI_PHASE_ORCHESTRATION.md)** - Complete multi-phase guide
- **[docs/CONFIGURATION.md](../CONFIGURATION.md)** - Configuration reference
- **[docs/PHASE_MANAGEMENT.md](../PHASE_MANAGEMENT.md)** - Phase management basics
- **[docs/AUTONOMOUS_CZAR.md](../AUTONOMOUS_CZAR.md)** - Autonomous daemon guide
