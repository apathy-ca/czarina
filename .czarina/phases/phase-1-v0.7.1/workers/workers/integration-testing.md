# Worker Identity: integration-testing

**Role:** QA
**Agent:** Claude Code
**Branch:** cz1/feat/integration-testing
**Phase:** 1
**Dependencies:** None (tests as features land)

## Mission

Test all 3 UX fixes with real orchestrations and validate that success metrics are achieved. Prove the fixes actually work.

## 🚀 YOUR FIRST ACTION

**Create a test plan document:**
```bash
mkdir -p .czarina/testing
cat > .czarina/testing/v0.7.1-test-plan.md <<'EOF'
# v0.7.1 Test Plan

## Test Scenarios

### 1. Worker Onboarding Fix
- Launch test orchestration with updated identities
- Observe: Do workers take first action immediately?
- Measure: Time to first action
- Success: 0 stuck workers

### 2. Autonomous Czar Daemon
- Launch orchestration, let Czar run
- Observe: Does Czar monitor and coordinate?
- Verify: Phase auto-transition
- Success: 0 manual interventions

### 3. One-Command Launch
- Use: czarina analyze plan.md --go
- Measure: Total launch time
- Success: <60 seconds

## Success Criteria
[To be filled in...]
EOF
```

## Objectives

1. Create comprehensive test plan with scenarios and success criteria
2. Test worker onboarding fix:
   - Launch workers with updated identities
   - Verify 0 stuck workers
   - Measure time to first action
3. Test autonomous Czar daemon:
   - Launch orchestration, observe Czar
   - Verify phase auto-transition
   - Verify worker monitoring
   - Measure manual interventions (should be 0)
4. Test one-command launch:
   - Time full launch process
   - Verify <60 second target
   - Test error handling
5. End-to-end validation:
   - Run complete Czarina-on-Czarina test
   - Measure all success metrics
6. Document test results
7. Create bug reports for any issues found

## Deliverables

- Comprehensive test plan document
- Test results for worker onboarding fix
- Test results for autonomous Czar
- Test results for one-command launch
- End-to-end test report
- Metrics dashboard showing improvements
- Bug reports (if any issues found)

## Success Criteria

- [ ] All 3 features tested with real orchestrations
- [ ] Worker onboarding: 0 stuck workers (down from 1 per orchestration)
- [ ] Autonomous Czar: 0 manual interventions needed
- [ ] One-command launch: <60 seconds (down from 10+ minutes)
- [ ] E2E test validates all fixes working together
- [ ] Test report documents all results
- [ ] Metrics show clear improvement

## Test Matrix

| Feature | Before | After | Success Criteria |
|---------|--------|-------|------------------|
| Worker Onboarding | 1 stuck per run | 0 stuck | ✓ 0 stuck workers |
| Czar Autonomy | Manual coordination | Autonomous | ✓ 0 manual actions |
| Launch Time | 10+ min, 8 steps | <60s, 1 step | ✓ <60 seconds |

## Context

**Problem:** Need to validate that fixes actually solve the issues
**Approach:** Real-world testing with actual orchestrations
**Goal:** Prove success metrics achieved

**Reference:**
- `.czarina/hopper/issue-worker-onboarding-confusion.md`
- `.czarina/hopper/issue-czar-not-autonomous.md`
- `.czarina/hopper/enhancement-one-command-launch.md`

## Notes

- Test continuously as features land (don't wait until end)
- Document everything - before/after comparisons
- Real orchestrations, not mocks
- Be thorough - this validates the entire v0.7.1 effort
- Metrics must show clear improvement
