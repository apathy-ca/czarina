# Czarina v0.7.2 - Phase 2 Auto-Launch Completion

## Release Goal
Complete the autonomous daemon's ability to automatically detect Phase 1 completion and launch Phase 2 workers without manual intervention.

## Problem Statement

**Current State (v0.7.1):**
- Phase 1 workers launch and complete autonomously ✅
- Autonomous Czar monitors and coordinates Phase 1 ✅
- Phase 1 → Phase 2 transition requires manual intervention ❌
- Human must manually run Phase 2 launch commands ❌

**Target State (v0.7.2):**
- Autonomous Czar detects Phase 1 completion automatically ✅
- Czar automatically launches Phase 2 workers ✅
- Multi-phase orchestrations run completely hands-free ✅
- Zero manual intervention from launch to final integration ✅

## Success Criteria

1. **Phase Detection** - Czar correctly identifies when all Phase 1 workers complete
2. **Auto-Launch** - Phase 2 workers launch automatically without human intervention
3. **Configuration** - Phase transitions configurable in config.json
4. **Backward Compatibility** - Single-phase orchestrations still work
5. **Testing** - End-to-end test validates multi-phase automation
6. **Documentation** - Complete guide for multi-phase orchestrations

## Architecture

### Phase Completion Detection

**File:** `czarina-core/phase-completion-detector.sh`

```bash
#!/bin/bash
# Detects when all workers in current phase have completed

detect_phase_completion() {
    local config_file="$1"
    local current_phase=$(jq -r '.orchestration.current_phase // 1' "$config_file")
    local workers=$(jq -r ".phases.phase_${current_phase}.workers[]" "$config_file")

    for worker in $workers; do
        # Check if worker branch merged or marked complete
        if ! check_worker_complete "$worker"; then
            return 1  # Phase not complete
        fi
    done

    return 0  # All workers complete
}
```

### Phase Transition Logic

**File:** `czarina-core/phase-transition.sh`

```bash
#!/bin/bash
# Manages transition between phases

transition_to_next_phase() {
    local config_file="$1"
    local current_phase=$(jq -r '.orchestration.current_phase // 1' "$config_file")
    local next_phase=$((current_phase + 1))

    # Check if next phase exists
    if ! jq -e ".phases.phase_${next_phase}" "$config_file" > /dev/null; then
        echo "No Phase $next_phase defined. Orchestration complete."
        return 1
    fi

    # Update current phase
    jq ".orchestration.current_phase = $next_phase" "$config_file" > tmp && mv tmp "$config_file"

    # Launch Phase 2 workers
    czarina launch --phase "$next_phase"

    return 0
}
```

### Autonomous Daemon Enhancement

**File:** `czarina-core/czar-autonomous-daemon.sh` (enhancement)

Add to monitoring loop:

```bash
# Check for phase completion
if detect_phase_completion "$CONFIG_FILE"; then
    echo "[CZAR] Phase $CURRENT_PHASE complete! Checking for next phase..."

    if transition_to_next_phase "$CONFIG_FILE"; then
        echo "[CZAR] Phase $NEXT_PHASE launched successfully!"
    else
        echo "[CZAR] All phases complete. Orchestration finished."
        exit 0
    fi
fi
```

### Configuration Schema

**Enhancement to config.json:**

```json
{
  "orchestration": {
    "mode": "local",
    "current_phase": 1,
    "auto_phase_transition": true
  },
  "phases": {
    "phase_1": {
      "name": "Core Implementation",
      "workers": ["backend", "frontend", "database"],
      "completion_criteria": "all_merged"
    },
    "phase_2": {
      "name": "Integration & Testing",
      "workers": ["integration", "qa", "documentation"],
      "completion_criteria": "all_merged",
      "depends_on": ["phase_1"]
    }
  }
}
```

## Workers

### Phase 1: Core Phase Management

### Worker 1: phase-detection
**Role:** Core Developer
**Agent:** Claude Code
**Mission:** Implement phase completion detection system

**Tasks:**
- Implement phase completion detection logic
- Create `czarina-core/phase-completion-detector.sh`
- Add worker completion status tracking (check git branches, merge status)
- Test detection with various completion states
- Add configuration support for completion criteria
- Unit tests for detection logic

**Success Criteria:**
- Phase completion accurately detected (100% accuracy)
- Handles edge cases (crashed workers, incomplete work)
- Clear logging of phase status
- **Deliverable:** Reliable phase completion detection

### Worker 2: phase-transition
**Role:** Core Developer
**Agent:** Claude Code
**Mission:** Implement automated phase transition system

**Tasks:**
- Implement phase transition logic
- Create `czarina-core/phase-transition.sh`
- Add phase-aware worker launch functionality
- Handle edge cases (no next phase, failed launch)
- Update config.json with current_phase tracking
- Integration with launch-project-v2.sh
- Unit tests for transition logic

**Success Criteria:**
- Seamless transition from Phase 1 → Phase 2
- Graceful handling when no next phase exists
- Phase state persisted in config
- **Deliverable:** Automated phase transitions

### Phase 2: Integration & Testing

### Worker 3: daemon-integration
**Role:** Integration Developer
**Agent:** Claude Code
**Mission:** Integrate phase management into autonomous daemon

**Tasks:**
- Integrate phase detection into autonomous daemon monitoring loop
- Add phase transition triggers to czar-autonomous-daemon.sh
- Implement graceful orchestration completion (all phases done)
- Add comprehensive phase transition logging
- Test daemon behavior across phase boundaries
- Ensure phase transition doesn't disrupt running workers

**Success Criteria:**
- Daemon automatically detects and transitions phases
- Zero manual intervention required
- Clear logging of all phase transitions
- **Deliverable:** Fully autonomous multi-phase daemon

### Worker 4: testing
**Role:** QA Engineer
**Agent:** Claude Code
**Mission:** Create comprehensive test suite for multi-phase automation

**Tasks:**
- Create end-to-end multi-phase test (`tests/test-multi-phase.sh`)
- Test Phase 1 → Phase 2 automatic transition
- Test single-phase backward compatibility
- Validate configuration schema changes
- Test edge cases (failed workers, missing phase definitions)
- Performance testing (phase transition overhead)
- Integration test with real worker scenarios

**Success Criteria:**
- All tests passing (100% pass rate)
- Backward compatibility verified
- Edge cases handled gracefully
- **Deliverable:** Comprehensive test suite

### Worker 5: documentation
**Role:** Technical Writer
**Agent:** Claude Code
**Mission:** Create complete v0.7.2 documentation

**Tasks:**
- Create `docs/MULTI_PHASE_ORCHESTRATION.md` guide
- Update config.json schema documentation in `docs/CONFIGURATION.md`
- Add multi-phase example to `QUICK_START.md`
- Create phase transition troubleshooting guide
- Write `RELEASE_NOTES_v0.7.2.md`
- Update `CHANGELOG.md` with v0.7.2 entry
- Update `CZARINA_STATUS.md` with v0.7.2 status
- Add migration notes if needed

**Success Criteria:**
- Complete documentation for all features
- Clear multi-phase examples
- Troubleshooting guide covers common issues
- **Deliverable:** Complete v0.7.2 documentation suite

## Completion Checkpoints

### Phase 1 Checkpoints
- [ ] Phase detection script created and tested
- [ ] Phase transition script created and tested
- [ ] Config schema enhanced and validated
- [ ] Unit tests passing

### Phase 2 Checkpoints
- [ ] Daemon integration complete
- [ ] End-to-end multi-phase test passing
- [ ] Documentation complete
- [ ] Backward compatibility verified
- [ ] Ready for release

## Test Plan

### Test 1: Two-Phase Orchestration
```bash
# Create test project with 2 phases
czarina init --phases 2
# Launch orchestration
czarina analyze plan.md --go
# Verify Phase 1 completes
# Verify Phase 2 auto-launches
# Verify final completion
```

### Test 2: Single-Phase Backward Compatibility
```bash
# Create single-phase project
czarina init
czarina analyze plan.md --go
# Verify works as before
```

### Test 3: Phase Completion Detection
```bash
# Test various completion states
# - All workers merged
# - Some workers pending
# - Workers failed
```

## Release Deliverables

1. **Code:**
   - `czarina-core/phase-completion-detector.sh` (~150 lines)
   - `czarina-core/phase-transition.sh` (~100 lines)
   - Enhanced `czarina-core/czar-autonomous-daemon.sh` (+50 lines)
   - Enhanced `czarina-core/launch-project-v2.sh` (+30 lines)

2. **Tests:**
   - `tests/test-multi-phase.sh` (~200 lines)
   - End-to-end validation script

3. **Documentation:**
   - `docs/MULTI_PHASE_ORCHESTRATION.md` (new)
   - Updated `QUICK_START.md`
   - Updated `docs/CONFIGURATION.md`
   - `RELEASE_NOTES_v0.7.2.md`
   - Updated `CHANGELOG.md`

## Impact Metrics

| Metric | v0.7.1 | v0.7.2 Target |
|--------|--------|---------------|
| Manual phase transitions | 1 per phase | 0 |
| Multi-phase automation | Partial | Complete |
| Hands-free orchestration | Single phase | Multi-phase |
| Phase transition time | 5-10 min (manual) | <30 sec (auto) |

## Risk Assessment

**Low Risk:**
- Well-scoped enhancement to existing daemon
- Backward compatible (single-phase still works)
- Configuration changes are additive

**Mitigation:**
- Extensive testing of phase detection logic
- Clear logging of phase transitions
- Fallback to manual if auto-transition fails

## Version & Timeline

**Version:** v0.7.2
**Type:** Patch release
**Estimated Implementation:** 2-3 workers, 1-2 phases
**Estimated Duration:** 4-6 hours (autonomous)

## Post-Release

**Next Steps:**
- Monitor Phase 2 auto-launch in production
- Gather feedback on multi-phase orchestrations
- Consider v0.8.0 planning (dynamic worker spawning, web UI)

---

**This plan enables:** Truly hands-free multi-phase orchestrations from start to finish. Set it, forget it, come back to completed project.
