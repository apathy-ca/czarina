# Worker Identity: autonomous-czar-daemon

**Role:** Code
**Agent:** Claude Code
**Branch:** cz1/feat/autonomous-czar-daemon
**Phase:** 1
**Dependencies:** None

## Mission

Implement a bash-based autonomous Czar daemon that actually monitors workers and coordinates orchestrations without human intervention. Make Czarina truly autonomous.

## 🚀 YOUR FIRST ACTION

**Create the daemon script file:**
```bash
touch czarina-core/autonomous-czar-daemon.sh
chmod +x czarina-core/autonomous-czar-daemon.sh

# Then add basic structure:
cat > czarina-core/autonomous-czar-daemon.sh <<'EOF'
#!/bin/bash
# Autonomous Czar Daemon
# Monitors workers and coordinates orchestration

while true; do
  echo "[$(date)] Czar monitoring cycle starting..."

  # TODO: Add monitoring logic

  sleep 300  # 5 minutes
done
EOF
```

## Objectives

1. Create `czarina-core/autonomous-czar-daemon.sh`
2. Implement monitoring loop (runs every 5 minutes)
3. Implement worker status detection (via git log, branches)
4. Implement stuck worker detection (idle > 30 min)
5. Implement phase completion detection
6. Implement automatic Phase 2 launch when Phase 1 complete
7. Integrate with `czarina launch` to auto-start daemon
8. Add logging to `.czarina/logs/czar-daemon.log`
9. Test with mock orchestration

## Deliverables

- `czarina-core/autonomous-czar-daemon.sh` script
- Worker status detection logic
- Phase auto-transition logic
- Integration with czarina launch
- Comprehensive logging
- Test report showing autonomous operation

## Success Criteria

- [ ] Daemon runs continuously without crashing
- [ ] Monitoring loop executes every 5 minutes
- [ ] Worker status correctly detected (active, idle, stuck)
- [ ] Phase completion automatically detected
- [ ] Phase 2 launches automatically when Phase 1 done
- [ ] All actions logged
- [ ] 0 manual coordination needed in test

## Implementation Details

### Worker Status Detection
```bash
get_worker_status() {
  worker_id=$1
  branch="cz1/feat/$worker_id"

  # Check last commit time
  last_commit=$(git log -1 --format=%ct $branch 2>/dev/null)
  now=$(date +%s)
  idle_time=$((now - last_commit))

  if [ $idle_time -gt 1800 ]; then
    echo "STUCK"  # Idle > 30 min
  else
    echo "ACTIVE"
  fi
}
```

### Phase Completion Detection
```bash
check_phase_complete() {
  phase=$1
  phase_workers=$(get_phase_workers $phase)

  for worker in $phase_workers; do
    if ! is_worker_complete $worker; then
      return 1  # Not complete
    fi
  done

  return 0  # All complete
}
```

## Context

**Problem:** Czar sits idle, human must manually coordinate everything
**Root Cause:** No autonomous monitoring/coordination loop
**Solution:** Bash daemon that monitors, detects, and acts

**Reference:** `.czarina/hopper/issue-czar-not-autonomous.md`

## Notes

- Start simple: monitoring only, then add actions
- Log everything for debugging
- Make it resilient to crashes
- Test thoroughly before integration
- This is THE critical fix for v0.7.1
