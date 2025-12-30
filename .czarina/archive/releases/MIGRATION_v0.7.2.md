# Migration Guide: v0.7.1 → v0.7.2

**From:** Czarina v0.7.1
**To:** Czarina v0.7.2
**Status:** Production Ready
**Last Updated:** 2026-01-XX

## Overview

Czarina v0.7.2 introduces **automated multi-phase orchestration** while maintaining **100% backward compatibility** with v0.7.1:

1. **Phase Completion Detection** - Multi-signal automatic detection when phases are done
2. **Automated Phase Archival** - Complete state preservation with audit trail
3. **Smart Phase Initialization** - Auto-detects previous phases and transitions smoothly
4. **Enhanced Configuration** - Phase-aware fields for multi-phase projects

**All features are opt-in.** Existing orchestrations work unchanged.

---

## What's New in v0.7.2

### 1. Automated Phase Completion Detection

Workers automatically signal completion, system detects when phases are done:

- **Multi-Signal Detection** - Worker logs + git branches + status files
- **Flexible Modes** - `any`, `strict`, `all` completion modes
- **Daemon Integration** - Autonomous 5-minute monitoring
- **Manual Check** - `./czarina-core/phase-completion-detector.sh --verbose`

**Value:** No more guessing when phases complete. The system knows.

**See:** [docs/MULTI_PHASE_ORCHESTRATION.md](docs/MULTI_PHASE_ORCHESTRATION.md)

### 2. Automatic Phase Archival

Complete phase state preserved forever:

- **Configuration Snapshot** - `config.json` saved
- **Worker Logs** - All logs archived
- **Event Stream** - Machine-readable events
- **Worker Prompts** - Prompt snapshots
- **Phase Summary** - Auto-generated documentation
- **Decision Logs** - All autonomous decisions

**Archive location:** `.czarina/phases/phase-N-vX.Y.Z/`

**Value:** Complete development audit trail for every phase.

### 3. Smart Phase Initialization

Phase transitions are intelligent:

- **Auto-Detection** - Detects if previous phase was closed
- **No --force Needed** - Smart init eliminates need for force flag
- **History Preservation** - Never deletes phase history
- **Seamless Transitions** - Move from phase 1 → 2 → 3 effortlessly

**Value:** Effortless multi-phase workflows with complete safety.

### 4. Enhanced Configuration Schema

Config.json extended for multi-phase support:

```json
{
  "project": {
    "phase": 1,                          // NEW: Current phase number
    "omnibus_branch": "cz1/release/v1.0.0"  // NEW: Integration branch
  },
  "phase_completion_mode": "any",        // NEW: Detection mode
  "workers": [
    {
      "id": "api",
      "phase": 1,                        // NEW: Worker's phase
      "branch": "cz1/feat/api",          // Phase-aware naming
      "role": "feature"                  // NEW: Worker role
    }
  ]
}
```

**Value:** Explicit phase configuration enables automation.

### 5. New Commands & Tools

```bash
# Phase completion detection
./czarina-core/phase-completion-detector.sh --verbose
./czarina-core/phase-completion-detector.sh --json

# Smart initialization (enhanced)
czarina init  # Now auto-detects closed phases

# Existing commands (unchanged)
czarina phase close
czarina phase list
```

---

## Breaking Changes

**None!** v0.7.2 is 100% backward compatible.

All v0.7.1 orchestrations run unchanged in v0.7.2. Multi-phase features are opt-in.

---

## Migration Paths

Choose your migration strategy:

### Path 1: No Migration (Stay on v0.7.1 Behavior)

**Do nothing.** Your orchestrations work exactly as before.

```bash
# Existing workflow continues to work
cd ~/my-project
czarina launch
```

**Use case:** Single-phase projects that don't need automation.

### Path 2: Enable Phase Completion Detection Only

Add phase config to get automatic completion detection without multi-phase:

**Step 1:** Edit `.czarina/config.json`

```json
{
  "project": {
    "phase": 1,
    "omnibus_branch": "main"
  },
  "phase_completion_mode": "any"
}
```

**Step 2:** Ensure workers log completion

```bash
# In worker prompts, add:
czarina_log_worker_complete
```

**Step 3:** Use daemon to monitor

```bash
czarina launch --go
```

**Result:** Daemon auto-detects when phase completes, no multi-phase needed.

**Use case:** Single-phase projects wanting automatic completion detection.

### Path 3: Full Multi-Phase Migration

Enable complete multi-phase orchestration:

**Step 1:** Edit `.czarina/config.json` for Phase 1

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
      "id": "api",
      "phase": 1,
      "branch": "cz1/feat/api",
      "role": "feature",
      "dependencies": []
    },
    {
      "id": "integration",
      "phase": 1,
      "branch": "cz1/release/v1.0.0",
      "role": "integration",
      "dependencies": ["api"]
    }
  ]
}
```

**Step 2:** Update branch names to follow convention

```bash
# Phase 1 branches: cz1/feat/*
# Phase 2 branches: cz2/feat/*
# etc.

# Update worker branches in config.json
```

**Step 3:** Ensure workers log completion

```bash
# In worker prompts:
source $(git rev-parse --show-toplevel)/czarina-core/logging.sh
czarina_log_worker_complete
```

**Step 4:** Launch with daemon

```bash
czarina launch --go
```

**Step 5:** When Phase 1 completes, start Phase 2

```bash
# Phase auto-completes and archives
# Then initialize Phase 2:
czarina analyze docs/phase-2-plan.md --interactive --init
czarina launch --go
```

**Result:** Full automated multi-phase orchestration with complete audit trail.

**Use case:** Long-running projects with multiple sequential phases.

---

## Migration Checklist

### For All Projects

- [ ] Upgrade to v0.7.2: `git pull origin main` in czarina repo
- [ ] Test existing workflow: `czarina launch` (should work unchanged)
- [ ] Review new documentation: [docs/MULTI_PHASE_ORCHESTRATION.md](docs/MULTI_PHASE_ORCHESTRATION.md)

### If Enabling Phase Completion Detection

- [ ] Add `project.phase` to config.json (start with `1`)
- [ ] Add `project.omnibus_branch` to config.json
- [ ] Add `phase_completion_mode` to config.json (recommend `"any"`)
- [ ] Update workers to call `czarina_log_worker_complete`
- [ ] Test completion detection: `./czarina-core/phase-completion-detector.sh --verbose`
- [ ] Launch with daemon: `czarina launch --go`

### If Enabling Multi-Phase

- [ ] All items from "Phase Completion Detection" above
- [ ] Update all worker branches to follow `cz<phase>/feat/<worker-id>` naming
- [ ] Add `workers[].phase` field to all workers
- [ ] Add `workers[].role` field to workers ("feature" or "integration")
- [ ] Set omnibus branch to phase-aware name (e.g., `cz1/release/v1.0.0`)
- [ ] Update project slug to avoid dots (use underscores: `project-v1_0_0`)
- [ ] Create phase 2 plan for when phase 1 completes
- [ ] Test phase archival: `czarina phase close` (creates `.czarina/phases/` archive)
- [ ] Test phase list: `czarina phase list`

---

## Common Migration Scenarios

### Scenario 1: Existing Single-Phase Project

**Current state:**
- Working v0.7.1 orchestration
- Want to keep it simple
- No multi-phase needs

**Recommended migration:** Path 1 (No Migration)

**Action:** Nothing! Continue using `czarina launch` as before.

---

### Scenario 2: Want Automatic Completion Detection

**Current state:**
- Single-phase project
- Manually checking when workers are done
- Want automation but not multi-phase

**Recommended migration:** Path 2 (Phase Completion Detection Only)

**Steps:**
1. Add phase config (phase: 1, omnibus_branch: "main")
2. Add `czarina_log_worker_complete` to worker prompts
3. Use `czarina launch --go`
4. Daemon auto-detects completion

**Time:** 15 minutes

---

### Scenario 3: Multi-Release Project

**Current state:**
- Building v1.0, then v1.1, then v1.2
- Multiple sequential phases planned
- Want complete audit trail

**Recommended migration:** Path 3 (Full Multi-Phase)

**Steps:**
1. Configure Phase 1 with phase-aware fields
2. Update branch naming to `cz1/feat/*`
3. Ensure worker completion logging
4. Launch Phase 1: `czarina launch --go`
5. When complete, archive auto-created
6. Launch Phase 2: `czarina analyze ... --init && czarina launch --go`
7. Repeat for Phase 3, 4, etc.

**Time:** 30 minutes setup, seamless thereafter

**Result:** Complete development history preserved for all phases.

---

### Scenario 4: Migrating In-Progress Project

**Current state:**
- Already mid-orchestration in v0.7.1
- Workers currently active
- Want to upgrade without disrupting work

**Recommended approach:**

**Option A - Wait for completion:**
1. Let current orchestration finish in v0.7.1
2. Upgrade to v0.7.2
3. Start next phase with multi-phase features

**Option B - Migrate mid-flight:**
1. `czarina phase close --keep-worktrees` (preserve worker state)
2. Upgrade to v0.7.2
3. Edit config.json with phase fields
4. `czarina launch` (resumes workers with phase detection enabled)

**Recommended:** Option A (less risk)

---

## Configuration Examples

### Before (v0.7.1)

```json
{
  "project": {
    "name": "myproject",
    "slug": "myproject",
    "version": "1.0.0"
  },
  "workers": [
    {
      "id": "api",
      "branch": "feat/api"
    }
  ]
}
```

### After (v0.7.2 - Minimal)

```json
{
  "project": {
    "name": "myproject",
    "slug": "myproject-v1_0_0",
    "version": "1.0.0",
    "phase": 1,
    "omnibus_branch": "main"
  },
  "phase_completion_mode": "any",
  "workers": [
    {
      "id": "api",
      "phase": 1,
      "branch": "cz1/feat/api"
    }
  ]
}
```

### After (v0.7.2 - Full Multi-Phase)

```json
{
  "project": {
    "name": "myproject",
    "slug": "myproject-v1_0_0",
    "version": "1.0.0",
    "phase": 1,
    "omnibus_branch": "cz1/release/v1.0.0"
  },
  "phase_completion_mode": "strict",
  "workers": [
    {
      "id": "api",
      "phase": 1,
      "branch": "cz1/feat/api",
      "role": "feature",
      "dependencies": []
    },
    {
      "id": "ui",
      "phase": 1,
      "branch": "cz1/feat/ui",
      "role": "feature",
      "dependencies": ["api"]
    },
    {
      "id": "integration",
      "phase": 1,
      "branch": "cz1/release/v1.0.0",
      "role": "integration",
      "dependencies": ["api", "ui"]
    }
  ]
}
```

---

## Testing Your Migration

### Test 1: Backward Compatibility

```bash
# Should work exactly as before
czarina launch

# Workers should launch normally
# No new behavior unless phase config added
```

### Test 2: Phase Completion Detection

```bash
# Check manual detection
./czarina-core/phase-completion-detector.sh --verbose

# Should show worker status
# Exit code 0 = complete, 1 = incomplete
```

### Test 3: Phase Archival

```bash
# Manually close phase
czarina phase close

# Check archive created
ls -la .czarina/phases/
cat .czarina/phases/phase-1-v*/PHASE_SUMMARY.md
```

### Test 4: Smart Initialization

```bash
# After closing phase
czarina init

# Should detect closed phase
# No --force flag needed
```

### Test 5: Multi-Phase Workflow

```bash
# Phase 1
czarina launch --go
# ... wait for auto-completion ...

# Phase 2
czarina analyze docs/phase-2.md --interactive --init
czarina launch --go

# Check history
czarina phase list
```

---

## Troubleshooting

### Issue: Phase not auto-completing

**Solution:** See [docs/troubleshooting/PHASE_TRANSITIONS.md](docs/troubleshooting/PHASE_TRANSITIONS.md)

**Quick fixes:**
- Check `./czarina-core/phase-completion-detector.sh --verbose`
- Ensure workers call `czarina_log_worker_complete`
- Try `phase_completion_mode: "any"` instead of `"strict"`

### Issue: "Config validation failed"

**Cause:** Invalid phase configuration

**Solutions:**
- Ensure `project.phase` is integer ≥ 1
- Ensure `project.slug` has no dots (use underscores)
- Ensure branch naming matches phase (cz1/ for phase 1)

### Issue: Archive not created

**Cause:** Permissions or manual close needed

**Solutions:**
```bash
# Check permissions
chmod u+w .czarina/

# Manually close
czarina phase close

# Check archive
ls -la .czarina/phases/
```

---

## Rollback Procedure

If you need to rollback to v0.7.1 behavior:

**Step 1:** Remove phase config from `.czarina/config.json`

```json
{
  "project": {
    // Remove: "phase", "omnibus_branch"
  }
  // Remove: "phase_completion_mode"
  "workers": [
    {
      // Remove: "phase", "role"
    }
  ]
}
```

**Step 2:** Downgrade czarina (if needed)

```bash
cd ~/Source/GRID/claude-orchestrator
git checkout v0.7.1
```

**Step 3:** Continue as before

```bash
czarina launch
```

---

## Support & Resources

### Documentation

- **[docs/MULTI_PHASE_ORCHESTRATION.md](docs/MULTI_PHASE_ORCHESTRATION.md)** - Complete guide
- **[docs/CONFIGURATION.md](docs/CONFIGURATION.md)** - Config reference
- **[docs/troubleshooting/PHASE_TRANSITIONS.md](docs/troubleshooting/PHASE_TRANSITIONS.md)** - Troubleshooting
- **[RELEASE_NOTES_v0.7.2.md](RELEASE_NOTES_v0.7.2.md)** - What's new

### Migration Help

**Quick questions:**
- Check troubleshooting guide first
- Review configuration examples above
- Test with `--verbose` flags

**Issues:**
- Report at https://github.com/apathy-ca/czarina/issues
- Include: version, config.json, error messages

---

## Summary

**v0.7.2 Migration is:**
- ✅ **100% backward compatible** - Existing projects work unchanged
- ✅ **Opt-in features** - Enable multi-phase only when ready
- ✅ **Zero breaking changes** - No forced migrations
- ✅ **Incremental adoption** - Add features one at a time
- ✅ **Easy rollback** - Can return to v0.7.1 behavior anytime

**Recommended for:**
- Projects with multiple planned phases
- Teams wanting automatic completion detection
- Orgs requiring complete audit trails
- Long-running development cycles

**Not required for:**
- Simple single-phase projects
- Quick prototypes
- Projects happy with manual phase management

**Migration time:**
- No migration: 0 minutes
- Phase detection only: 15 minutes
- Full multi-phase: 30 minutes

**Choose the migration path that fits your needs!** 🚀
