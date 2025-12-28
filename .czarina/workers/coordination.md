# Worker: Coordination
## Proactive Czar + Enhanced Daemon + Closeout Reports

**Stream:** 2
**Duration:** Week 2 (1 week)
**Branch:** `feat/proactive-coordination`
**Agent:** Aider (recommended)
**Dependencies:** `foundation`

---

## Mission

Make czarina autonomous and proactive. The Czar should coordinate workers without manual prompting, the daemon should provide useful status updates, and closeout should generate comprehensive reports.

## 🚀 YOUR FIRST ACTION

**Design the Czar coordination logic:**

```bash
# Create the Czar coordination script
touch czarina-core/czar.sh

# Review foundation worker's logging system to understand how to read worker logs
cat czarina-core/logging.sh

# Plan the coordination functions you'll implement
```

**Then:** Start implementing czar_check_workers() function as described in Task 1.1.

## Goals

- Czar monitors workers and coordinates proactively
- Daemon shows worker activity, not just "auto-approved"
- Closeout generates comprehensive CLOSEOUT.md report
- Status reports generated periodically
- Integration strategy suggested automatically

---

## Tasks

### Task 1: Proactive Czar (3 days)

#### 1.1: Czar Coordination Logic
**File:** `czarina-core/czar.sh` (NEW)

Implement Czar coordination functions:
```bash
czar_check_workers()            # Check all worker logs
czar_detect_completion()        # Detect when workers done
czar_generate_status()          # Generate status report
czar_suggest_integration()      # Suggest omnibus vs sequential
czar_coordinate()               # Main coordination loop
```

**Czar Behaviors:**
1. **Periodic checks** (every 15 min):
   - Read last line of each worker log
   - Check for WORKER_COMPLETE events
   - Detect idle/stuck workers (no activity >10 min)

2. **Completion detection**:
   - When all workers show WORKER_COMPLETE
   - Generate comprehensive status report
   - Post to czar window
   - Suggest integration strategy

3. **Status reports**:
   - Every 2 hours, generate progress report
   - Include: tasks completed, files changed, estimated completion
   - Post to `.czarina/work/<session>/coordination/status-reports/`

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/czar.sh
git commit -m "feat(coordination): Add proactive Czar coordination logic"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: czar_logic" >> .czarina/logs/coordination.log
```

#### 1.2: Integration Strategy Detection
**File:** `czarina-core/integration.sh` (NEW)

Analyze worker branches and suggest strategy:
```bash
detect_integration_strategy() {
  # Count workers
  WORKER_COUNT=$(jq '.workers | length' .czarina/config.json)

  # Check for conflicts
  CONFLICTS=$(detect_potential_conflicts)

  # Suggest omnibus if:
  # - 4+ workers
  # - Related changes (same files modified)
  # - Complex dependencies

  # Suggest sequential PRs if:
  # - <4 workers
  # - Independent changes
  # - No dependencies
}
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/integration.sh
git commit -m "feat(coordination): Add integration strategy detection"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: integration_strategy" >> .czarina/logs/coordination.log
```

#### 1.3: Czar Window Integration
**File:** `czarina` (UPDATE)

Add Czar coordination to tmux window 0:
```bash
# In czar window startup
while true; do
  czar_coordinate
  sleep 900  # 15 minutes
done
```

**COMMIT CHECKPOINT:**
```bash
git add czarina
git commit -m "feat(coordination): Integrate Czar coordination loop"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: czar_window" >> .czarina/logs/coordination.log
```

---

### Task 2: Enhanced Daemon Output (2 days)

#### 2.1: Worker Status Display
**File:** `czarina-core/daemon.sh` (UPDATE)

Enhance daemon monitoring output:
```bash
daemon_show_worker_status() {
  for worker in $(jq -r '.workers[].id' .czarina/config.json); do
    LAST_LOG=$(tail -1 .czarina/logs/${worker}.log 2>/dev/null || echo "No activity")
    TIME_AGO=$(calculate_time_since_last_log "$worker")

    # Parse last event
    EVENT=$(echo "$LAST_LOG" | grep -oP '(?<=] )[^ ]+')

    # Detect status
    if [[ "$EVENT" == "WORKER_COMPLETE" ]]; then
      STATUS="✅ COMPLETE"
    elif [[ "$TIME_AGO" -gt 600 ]]; then  # >10 min
      STATUS="⚠️ IDLE"
    elif [[ "$TIME_AGO" -gt 1800 ]]; then  # >30 min
      STATUS="❌ STUCK?"
    else
      STATUS="🔄 ACTIVE"
    fi

    printf "Worker %d (%s): %s %s (last: %s ago)\n" \
      "$index" "$worker" "$STATUS" "$LAST_LOG" "$(format_time $TIME_AGO)"
  done
}
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/daemon.sh
git commit -m "feat(coordination): Enhance daemon worker status display"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: daemon_status" >> .czarina/logs/coordination.log
```

#### 2.2: Activity Metrics
**File:** `czarina-core/metrics.sh` (NEW)

Calculate real-time metrics:
```bash
metrics_files_changed() {
  cd .czarina/worktrees/$worker
  git status --short | wc -l
}

metrics_tasks_completed() {
  grep "TASK_COMPLETE" .czarina/logs/$worker.log | wc -l
}

metrics_last_activity() {
  stat -c %Y .czarina/logs/$worker.log
}
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/metrics.sh
git commit -m "feat(coordination): Add activity metrics calculation"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: metrics" >> .czarina/logs/coordination.log
```

#### 2.3: Fix Daemon Spacing Issue
**File:** `czarina-core/daemon.sh` (UPDATE)

**Enhancement #11 - Discovered during this orchestration!**

When the daemon has no activity to report, it spams blank lines and pushes text off-screen. This is inelegant and makes the daemon window hard to read.

**Current behavior:**
```bash
while true; do
  echo ""
  echo "=== Iteration $N ==="
  # ... monitoring ...
  sleep 120
done
```

Every 2 minutes it outputs blank lines even when there's no activity, causing:
- Text scrolls off screen
- Hard to see what's happening
- Inelegant user experience

**Fix:**
Only output iteration headers when there's actual activity:

```bash
daemon_monitor_loop() {
  local iteration=0

  while true; do
    ((iteration++))

    # Check for activity
    local has_activity=false

    # Check if any worker has recent activity (<5 min)
    for worker in $(jq -r '.workers[].id' .czarina/config.json); do
      if [ -f ".czarina/logs/$worker.log" ]; then
        local last_mod=$(stat -c %Y ".czarina/logs/$worker.log" 2>/dev/null || echo 0)
        local now=$(date +%s)
        local age=$((now - last_mod))

        if [ "$age" -lt 300 ]; then  # Activity within last 5 minutes
          has_activity=true
          break
        fi
      fi
    done

    # Only output if there's activity
    if [ "$has_activity" = true ]; then
      echo ""
      echo "=== Iteration $iteration - $(date '+%Y-%m-%d %H:%M:%S') ==="
      daemon_show_worker_status
      daemon_auto_approve
    else
      # Silent iteration - just do auto-approval without output spam
      daemon_auto_approve >/dev/null 2>&1
    fi

    sleep 120
  done
}
```

**Benefits:**
- Clean daemon window (only shows updates when things happen)
- Text doesn't scroll off screen unnecessarily
- Easy to see recent activity at a glance
- More elegant and professional output

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/daemon.sh
git commit -m "fix(coordination): Prevent daemon from spamming blank lines when idle (Enhancement #11)"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: daemon_spacing_fix" >> .czarina/logs/coordination.log
```

---

### Task 3: Closeout Report Generation (2 days)

#### 3.1: Report Template
**File:** `czarina-core/templates/CLOSEOUT.md.template` (NEW)

Create comprehensive closeout template:
```markdown
# Czarina Orchestration Closeout Report
## Project: {{PROJECT_NAME}} {{PROJECT_VERSION}}

**Session ID**: {{SESSION_ID}}
**Started**: {{START_TIME}}
**Completed**: {{END_TIME}}
**Duration**: {{DURATION}}
**Outcome**: {{OUTCOME}}

---

## Executive Summary

{{SUMMARY}}

**Key Metrics**:
- Workers: {{WORKER_COUNT}} ({{COMPLETED_COUNT}} completed)
- Tasks completed: {{TASKS_COMPLETE}}/{{TASKS_TOTAL}}
- Files changed: {{FILES_CHANGED}}
- Tests added: {{TESTS_ADDED}}
- Commits: {{COMMIT_COUNT}}

---

## Workers Summary

{{WORKER_SUMMARIES}}

---

## Integration Results

{{INTEGRATION_RESULTS}}

---

## What Went Well ✅

{{SUCCESSES}}

---

## What Didn't Work ❌

{{ISSUES}}

---

## Performance Analysis

{{PERFORMANCE}}

---

## Recommendations for Future Runs

{{RECOMMENDATIONS}}

---

**Report generated**: {{REPORT_TIME}}
**Generated by**: Czarina {{CZARINA_VERSION}}
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/templates/CLOSEOUT.md.template
git commit -m "feat(coordination): Add closeout report template"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: closeout_template" >> .czarina/logs/coordination.log
```

#### 3.2: Report Generation Logic
**File:** `czarina-core/closeout.sh` (NEW)

Generate closeout report:
```bash
czarina_closeout_generate() {
  SESSION_ID=$(czarina_session_current)
  TEMPLATE="czarina-core/templates/CLOSEOUT.md.template"
  OUTPUT=".czarina/work/$SESSION_ID/CLOSEOUT.md"

  # Gather data
  gather_session_metadata
  gather_worker_summaries
  gather_integration_results
  analyze_successes_and_issues
  generate_performance_metrics
  generate_recommendations

  # Render template
  render_template "$TEMPLATE" > "$OUTPUT"

  echo "✅ Closeout report generated: $OUTPUT"
}
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/closeout.sh
git commit -m "feat(coordination): Add closeout report generation"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: closeout_generation" >> .czarina/logs/coordination.log
```

#### 3.3: Closeout Command
**File:** `czarina` (UPDATE)

Add `czarina closeout` command:
```bash
closeout)
  czarina_closeout_generate
  czarina_session_update "status" "CLOSED"
  echo "🎉 Closeout complete. Review: .czarina/work/$(czarina_session_current)/CLOSEOUT.md"
  ;;
```

**COMMIT CHECKPOINT:**
```bash
git add czarina
git commit -m "feat(coordination): Add closeout command"
echo "[$(date +%H:%M:%S)] 🎉 WORKER_COMPLETE: All coordination tasks done" >> .czarina/logs/coordination.log
```

---

## Deliverables

- ✅ `czarina-core/czar.sh` (~300 lines)
- ✅ `czarina-core/integration.sh` (~150 lines)
- ✅ Updated `czarina-core/daemon.sh` (~100 lines added)
- ✅ `czarina-core/metrics.sh` (~200 lines)
- ✅ `czarina-core/closeout.sh` (~400 lines)
- ✅ `czarina-core/templates/CLOSEOUT.md.template`
- ✅ Updated `czarina` main script

---

## Success Metrics

- [ ] Czar generates status reports every 2 hours
- [ ] Czar detects completion automatically
- [ ] Daemon shows worker activity with timestamps
- [ ] Closeout generates comprehensive CLOSEOUT.md
- [ ] Integration strategy suggested based on analysis
- [ ] All tests passing

---

## Integration Notes

Depends on:
- `foundation` - Requires logging system to read worker status

Enables:
- Better orchestration experience
- Autonomous coordination
- Process improvement insights

---

## References

- Enhancement #4: Proactive Czar Coordination
- Enhancement #7: Enhanced Daemon Output
- Enhancement #9: Closeout Report Generation
- SARK v1.3.0 analysis findings
