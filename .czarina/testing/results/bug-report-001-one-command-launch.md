# Bug Report: One-Command Launch Not Implemented

**Report ID:** BUG-001
**Severity:** CRITICAL
**Priority:** P0
**Status:** Open
**Reporter:** integration-testing worker
**Date:** 2025-12-28

## Summary

The one-command-launch feature (czarina analyze --go) has not been implemented. The worker assigned to this task has made no commits and the feature is completely missing from the codebase.

## Impact

- **v0.7.1 Success Metrics:** Cannot be met (target: <60s launch time)
- **User Experience:** No improvement in launch friction (still 8 manual steps)
- **Release Blocker:** One of three critical UX fixes is missing

## Expected Behavior

According to the enhancement spec (`.czarina/hopper/enhancement-one-command-launch.md`):

```bash
# Should work (one command, <60 seconds):
czarina analyze INTEGRATION_PLAN.md --go

# Should:
# 1. Parse plan
# 2. Close previous phase
# 3. Generate config.json
# 4. Generate worker identities
# 5. Validate config
# 6. Init branches
# 7. Create worktrees
# 8. Launch tmux session
# 9. Start workers
```

## Actual Behavior

```bash
# Current state:
czarina analyze --go
# Error: unrecognized arguments: --go

# The --go flag does not exist
# No plan parsing implemented
# No automation added
```

## Evidence

### Branch Status
- **Branch:** cz1/feat/one-command-launch
- **Last Commit:** 99ecd13 (same as main)
- **New Commits:** 0
- **Modified Files:** WORKER_IDENTITY.md only (not committed)

### Code Analysis
Git diff shows --go code being **removed**, not added:

```diff
- czarina analyze <plan-file> --go         - Automated: parse plan, generate config
- czarina analyze <plan-file> --dry-run    - Preview what --go would create
```

This suggests:
1. Code may have existed from previous work
2. Code was removed/reverted
3. Worker did not re-implement

### Worker Worktree
```bash
$ cd .czarina/worktrees/one-command-launch
$ git status
On branch cz1/feat/one-command-launch
Changes not staged for commit:
  modified:   WORKER_IDENTITY.md  # Only this file changed

no changes added to commit
```

## Root Cause

**Worker has not started implementation**

Possible reasons:
1. Worker didn't understand requirements
2. Worker blocked by something (undocumented)
3. Worker encountered technical difficulty
4. Worker deprioritized this task

## Reproduction

1. Check branch: `git log cz1/feat/one-command-launch --oneline`
2. Result: Same commits as main, no new work
3. Check czarina script: `grep -A 5 "\-\-go" czarina`
4. Result: No --go flag found

## Workaround

None - feature must be implemented.

Users must continue using the 8-step manual process:
1. czarina analyze plan.md --interactive
2. Collaborate with Claude
3. Exit Claude
4. czarina phase close
5. czarina init --from-config config.json
6. Fix config issues
7. czarina launch
8. Done

## Fix Required

The one-command-launch worker needs to:

### Phase 1: Plan Parsing
- [ ] Implement `parse_plan_metadata()` function
- [ ] Implement `parse_worker_from_section()` function
- [ ] Extract workers, roles, dependencies from plan markdown
- [ ] Test with real plan files

### Phase 2: Config Generation
- [ ] Implement `generate_config()` function
- [ ] Auto-generate branch names (cz<N>/feat/<id>)
- [ ] Auto-populate worker metadata
- [ ] Validate generated config

### Phase 3: Worker Identity Generation
- [ ] Implement `generate_worker_identity()` function
- [ ] Generate identity files from plan data
- [ ] Include "YOUR FIRST ACTION" sections
- [ ] Test identity quality

### Phase 4: Full Automation
- [ ] Implement `auto_launch_orchestration()` function
- [ ] Add --go flag to czarina analyze command
- [ ] Integrate with existing launch pipeline
- [ ] Test end-to-end

### Phase 5: Testing
- [ ] Test with v0.7.1 plan
- [ ] Measure launch time (target: <60s)
- [ ] Verify all 9 steps automated
- [ ] Document usage

## Dependencies

None - worker has no dependencies listed

## Related Issues

- Enhancement: `.czarina/hopper/enhancement-one-command-launch.md`
- Test Plan: `.czarina/testing/v0.7.1-test-plan.md`
- Test Results: `.czarina/testing/results/test-session-001.md`

## Recommendation

**URGENT:** This feature is 1 of 3 critical v0.7.1 UX fixes. The worker needs to:

1. Review the enhancement specification
2. Study the existing czarina script architecture
3. Implement plan parsing (start simple, iterate)
4. Implement config generation
5. Add --go flag with full automation
6. Test thoroughly
7. Commit working code
8. Request re-test from integration-testing worker

**Timeline:** Should be completed ASAP to unblock v0.7.1 release

## Test Case for Verification

Once implemented, run:

```bash
# Test case 1: Basic usage
time czarina analyze .czarina/hopper/issue-worker-onboarding-confusion.md --go

# Expected:
# - Completes in <60 seconds
# - Creates config.json
# - Creates all worker identity files
# - Launches orchestration
# - All workers start successfully

# Test case 2: Error handling
czarina analyze invalid-plan.md --go

# Expected:
# - Clear error message
# - No partial files created
# - Graceful failure
```

---

**Status:** Open - Awaiting implementation
**Assigned:** one-command-launch worker
**Blocks:** v0.7.1 release
