# Worker: QA
## Integration Testing & v0.5.0 Release Prep

**Stream:** 6
**Duration:** Week 3 (3 days)
**Branch:** `feat/v0.5.0-integration`
**Agent:** Aider (recommended)
**Dependencies:** `foundation`, `coordination`, `ux-polish`, `dependencies`, `dashboard`

---

## Mission

Integrate all v0.5.0 enhancements, verify they work together, conduct testing, update documentation, and prepare for release.

## 🚀 YOUR FIRST ACTION

**Create the integration branch and check the status of all feature branches:**

```bash
# Create integration/omnibus branch
git checkout -b feat/v0.5.0-omnibus main

# List all feature branches to be merged
git branch -a | grep "feat/"

# Check the completion status of each dependency worker
for worker in foundation coordination ux-polish dependencies dashboard; do
  echo "=== $worker ==="
  tail -1 .czarina/logs/$worker.log 2>/dev/null || echo "Not started"
done
```

**Then:** Start merging feature branches one by one, resolving any conflicts (Task 1.1).

## Goals

- All 5 enhancement streams integrated
- Full test suite passing
- Documentation complete and accurate
- v0.5.0 ready for release
- Dogfooding validated (czarina improved itself!)

---

## Tasks

### Task 1: Integration Testing (1.5 days)

#### 1.1: Integration Branch
**Action:** Create omnibus branch

```bash
# Create integration branch
git checkout -b feat/v0.5.0-omnibus main

# Merge all feature branches
git merge feat/structured-logging-workspace
git merge feat/proactive-coordination
git merge feat/ux-improvements
git merge feat/dependency-enforcement
git merge feat/dashboard-fix

# Resolve any conflicts
# Commit merge
git commit -m "feat: Integrate all v0.5.0 enhancement streams"
```

**COMMIT CHECKPOINT:**
```bash
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: omnibus_merge" >> .czarina/logs/qa.log
```

#### 1.2: End-to-End Tests
**File:** `tests/test-e2e.sh` (NEW)

Test scenarios:
```bash
#!/bin/bash
# End-to-end integration tests for v0.5.0

test_structured_logging() {
  # Create test project
  # Launch orchestration
  # Verify logs created
  # Verify event stream format
}

test_workspace_creation() {
  # Launch orchestration
  # Verify session workspace created
  # Verify worker plans copied
  # Verify session.json created
}

test_czar_coordination() {
  # Launch with mock workers
  # Simulate completion
  # Verify Czar detects completion
  # Verify status report generated
}

test_daemon_output() {
  # Launch orchestration
  # Check daemon output format
  # Verify worker status displayed
  # Verify timestamps shown
}

test_closeout_report() {
  # Complete orchestration
  # Run czarina closeout
  # Verify CLOSEOUT.md generated
  # Verify report completeness
}

test_tmux_window_names() {
  # Launch orchestration
  # List tmux windows
  # Verify worker IDs shown (not worker1, worker2)
}

test_dependency_enforcement() {
  # Create config with dependencies
  # Set sequential mode
  # Verify workers wait for dependencies
}

test_dashboard_rendering() {
  # Launch orchestration
  # Check dashboard window
  # Verify UI renders correctly
  # Verify metrics displayed
}

# Run all tests
run_all_tests() {
  TESTS=(
    test_structured_logging
    test_workspace_creation
    test_czar_coordination
    test_daemon_output
    test_closeout_report
    test_tmux_window_names
    test_dependency_enforcement
    test_dashboard_rendering
  )

  PASSED=0
  FAILED=0

  for test in "${TESTS[@]}"; do
    echo "Running $test..."
    if $test; then
      echo "✅ $test passed"
      ((PASSED++))
    else
      echo "❌ $test failed"
      ((FAILED++))
    fi
  done

  echo ""
  echo "Results: $PASSED passed, $FAILED failed"

  if [ $FAILED -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

run_all_tests
```

**COMMIT CHECKPOINT:**
```bash
git add tests/test-e2e.sh
git commit -m "test(qa): Add end-to-end integration tests for v0.5.0"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: e2e_tests" >> .czarina/logs/qa.log
```

#### 1.3: Run Test Suite
**Action:** Execute all tests

```bash
# Run unit tests (if any exist)
find tests/ -name "test-*.sh" -type f -executable -exec {} \;

# Run e2e tests
./tests/test-e2e.sh

# Document results
cat > .czarina/work/$(czarina_session_current)/integration/test-results.md << EOF
# Test Results

**Date:** $(date -Iseconds)
**Branch:** feat/v0.5.0-omnibus

## Test Summary
- Total tests: X
- Passed: Y
- Failed: Z

## Failures
[Details of any failures]

## Next Steps
[Required fixes before release]
EOF
```

**COMMIT CHECKPOINT:**
```bash
git add .czarina/work/*/integration/test-results.md
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: test_execution" >> .czarina/logs/qa.log
```

---

### Task 2: Documentation (1 day)

#### 2.1: Update Main README
**File:** `README.md` (UPDATE)

Add v0.5.0 features:
```markdown
## Features

### Structured Logging (v0.5.0)
- Workers log to `.czarina/logs/<worker>.log`
- Machine-readable event stream
- Historical audit trail

### Session Workspaces (v0.5.0)
- Complete session artifacts in `.czarina/work/<session-id>/`
- Plan vs actual comparison
- Comprehensive closeout reports

### Proactive Coordination (v0.5.0)
- Czar monitors and coordinates automatically
- Periodic status reports
- Integration strategy suggestions

### Dependency Enforcement (v0.5.0)
- Workers respect dependency chains
- Configurable orchestration modes
- Dependency graph visualization

### Enhanced UX (v0.5.0)
- Tmux windows show worker IDs
- Commit checkpoint templates
- Improved daemon output
```

**COMMIT CHECKPOINT:**
```bash
git add README.md
git commit -m "docs(qa): Update README with v0.5.0 features"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: readme_update" >> .czarina/logs/qa.log
```

#### 2.2: Create Migration Guide
**File:** `docs/MIGRATION_v0.5.0.md` (NEW)

```markdown
# Migrating to Czarina v0.5.0

## Breaking Changes

None! v0.5.0 is fully backward compatible.

## New Features

### Structured Logging
Logs now saved to `.czarina/logs/`. Add this to `.gitignore`:
\```
.czarina/logs/
.czarina/work/
\```

### Orchestration Modes
Add to config.json (optional):
\```json
{
  "orchestration": {
    "mode": "parallel_spike"
  }
}
\```

### Worker Definitions
Update worker .md files to include commit checkpoints.
See `docs/WORKER_DEFINITIONS.md` for template.

## Migration Steps

1. Update czarina binary: `git pull && ./czarina version`
2. Add `.czarina/logs/` to .gitignore
3. (Optional) Update worker definitions with checkpoints
4. (Optional) Add orchestration mode to config.json
5. Launch as normal: `czarina launch`
```

**COMMIT CHECKPOINT:**
```bash
git add docs/MIGRATION_v0.5.0.md
git commit -m "docs(qa): Add v0.5.0 migration guide"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: migration_guide" >> .czarina/logs/qa.log
```

#### 2.3: Update CHANGELOG
**File:** `CHANGELOG.md` (UPDATE or CREATE)

```markdown
# Changelog

## [0.5.0] - 2025-12-XX

### Added

**Structured Logging System**:
- Worker logs: `.czarina/logs/<worker>.log`
- Event stream: `.czarina/logs/events.jsonl`
- Log parsing utilities
- Worker log helper: `czlog` command

**Session Workspaces**:
- Session artifacts: `.czarina/work/<session-id>/`
- Worker plans, tasks, completion reports
- Comprehensive closeout reports
- Session metadata and metrics

**Proactive Coordination**:
- Czar monitors workers automatically
- Periodic status reports (every 2 hours)
- Completion detection
- Integration strategy suggestions
- Enhanced daemon output with worker activity

**Dependency Enforcement**:
- Worker dependency checking
- Orchestration modes (parallel_spike, sequential_dependencies)
- Dependency graph generation
- CLI commands: `czarina deps graph`, `czarina deps check`

**UX Improvements**:
- Tmux windows show worker IDs (not generic numbers)
- Worker definition template with commit checkpoints
- `czarina init worker` command
- Improved documentation

**Dashboard**:
- Fixed non-functional dashboard
- Live worker status monitoring
- Real-time metrics display
- Color-coded status indicators

### Fixed
- Dashboard rendering issues
- Generic tmux window naming

### Changed
- Enhanced daemon output format
- Improved worker initialization

## [0.4.0] - Previous version
...
```

**COMMIT CHECKPOINT:**
```bash
git add CHANGELOG.md
git commit -m "docs(qa): Add v0.5.0 changelog entries"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: changelog_update" >> .czarina/logs/qa.log
```

---

### Task 3: Release Preparation (0.5 days)

#### 3.1: Version Bump
**Files:** `czarina`, `README.md`, etc.

Update version references:
```bash
# Update version in czarina script
sed -i 's/VERSION="0.4.0"/VERSION="0.5.0"/' czarina

# Update README badges/version mentions
sed -i 's/v0.4.0/v0.5.0/g' README.md
```

**COMMIT CHECKPOINT:**
```bash
git add czarina README.md
git commit -m "chore(release): Bump version to v0.5.0"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: version_bump" >> .czarina/logs/qa.log
```

#### 3.2: Release Checklist
**File:** `.czarina/work/<session>/integration/RELEASE_CHECKLIST.md` (NEW)

```markdown
# v0.5.0 Release Checklist

## Code Quality
- [ ] All feature branches merged to omnibus
- [ ] No merge conflicts
- [ ] All tests passing (E2E + unit)
- [ ] No critical bugs

## Documentation
- [ ] README.md updated
- [ ] CHANGELOG.md updated
- [ ] Migration guide created
- [ ] New features documented
- [ ] API docs updated (if applicable)

## Testing
- [ ] E2E tests passing
- [ ] Manual testing complete
- [ ] Dogfooding successful (czarina improved itself!)

## Release
- [ ] Version bumped to v0.5.0
- [ ] Git tag created: v0.5.0
- [ ] GitHub release created
- [ ] Release notes published

## Post-Release
- [ ] Announce on GitHub Discussions
- [ ] Update demo videos (if needed)
- [ ] Update website/docs (if applicable)
```

**COMMIT CHECKPOINT:**
```bash
git add .czarina/work/*/integration/RELEASE_CHECKLIST.md
git commit -m "docs(qa): Add v0.5.0 release checklist"
echo "[$(date +%H:%M:%S)] 🎉 WORKER_COMPLETE: All QA tasks done, ready for release" >> .czarina/logs/qa.log
```

---

## Deliverables

- ✅ Omnibus branch with all features integrated
- ✅ `tests/test-e2e.sh` (~300 lines)
- ✅ Test results documented
- ✅ Updated `README.md`
- ✅ Updated `CHANGELOG.md`
- ✅ `docs/MIGRATION_v0.5.0.md`
- ✅ Release checklist
- ✅ Version bumped to v0.5.0

---

## Success Metrics

- [ ] All feature branches merged without major conflicts
- [ ] E2E tests: 8/8 passing
- [ ] All documentation updated
- [ ] Release checklist 100% complete
- [ ] Dogfooding successful (this orchestration completed!)

---

## Dogfooding Success Criteria

This QA stream is special - we're using czarina to improve czarina!

Success means:
1. This orchestration completes using v0.4.0 features
2. New v0.5.0 features work when tested
3. CLOSEOUT.md generated for this session proves value
4. We eat our own dog food and it tastes good!

---

## Integration Notes

Depends on ALL other workers:
- `foundation` - Logging and workspace must work
- `coordination` - Czar and daemon enhancements needed
- `ux-polish` - Window naming and templates required
- `dependencies` - Dependency system must function
- `dashboard` - Dashboard must render

This is the final integration point.

---

## References

- Enhancement #9: Closeout Report Generation
- All v0.5.0 enhancement proposals
- SARK v1.3.0 orchestration analysis
