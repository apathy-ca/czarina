# Czar Daemon Integration Plan

## Analysis Summary

After ingesting the Czar session notes from SARK v2.0, we've identified a **critical innovation** that should be integrated into Czarina core:

**Autonomous Approval Daemon** - Reduces human intervention from 100% to ~10% when orchestrating multiple AI workers.

## Integration Decision

### Two-Phase Approach

#### Phase 1: Immediate Work (This Session) - 30-45 min
**Do this NOW to unblock and validate the system**

1. Create generalized daemon template in `czarina-core/daemon/`
2. Add basic `czarina daemon` CLI commands
3. Document daemon system
4. **Update INTEGRATOR worker prompt** to include daemon integration

**Why now?**
- Validates daemon works with multi-agent orchestration
- Provides concrete example for INTEGRATOR to follow
- Tests agent-agnostic daemon concept
- Quick win that unblocks current workers

#### Phase 2: Worker Integration (INTEGRATOR) - 1 hr
**Let INTEGRATOR worker complete the full integration**

1. Integrate daemon into launcher scripts
2. Add agent-specific daemon profiles
3. Create embedded orchestration daemon helpers
4. Full testing and documentation

**Why delegate?**
- Fits naturally with INTEGRATOR's launcher work
- Documents the integration process
- Uses orchestration system for orchestration improvement (meta!)
- INTEGRATOR can build on Phase 1 foundation

## Immediate Tasks (This Session)

### Task 1: Create Generalized Daemon Template (15 min)

**Create:** `czarina-core/daemon/czar-daemon.sh`
- Parameterize project-specific values
- Load config from JSON instead of bash
- Make worker count dynamic
- Use relative paths

**Key changes:**
```bash
# Before (SARK-specific):
SESSION="sark-v2-session"
for window in {0..9}; do

# After (Generalized):
PROJECT_SLUG=$(jq -r '.project.slug' config.json)
SESSION="${PROJECT_SLUG}-session"
WORKER_COUNT=$(jq '.workers | length' config.json)
for window in $(seq 0 $((WORKER_COUNT-1))); do
```

### Task 2: Add Daemon CLI Commands (15 min)

**Update:** `czarina-core/czarina` (Python CLI)

Add commands:
```python
def cmd_daemon_start(project_name):
    """Start autonomous daemon for project"""

def cmd_daemon_stop(project_name):
    """Stop daemon for project"""

def cmd_daemon_logs(project_name):
    """Show daemon logs"""

def cmd_daemon_status(project_name):
    """Check daemon status"""
```

### Task 3: Update INTEGRATOR Prompt (10 min)

**Update:** `czarina-multi-agent-support/workers/integrator.md`

Add daemon integration to scope:
- Integrate czar-daemon.sh from sark-v2-orchestration
- Generalize for all projects
- Add to launcher scripts
- Create agent-specific daemon configs
- Test with multi-agent project

### Task 4: Basic Documentation (10 min)

**Create:** `czarina-core/docs/DAEMON_SYSTEM.md`
- Overview of daemon system
- Quick start guide
- Link to full guide (created by INTEGRATOR later)

## Updated Worker Scopes

### REBRAND ✅ COMPLETE
No changes needed.

### ARCHITECT 🔄 IN PROGRESS
**Current scope:** Agent profile system
**Add to scope:** Include daemon approval patterns in agent profiles

**New fields for agent profiles:**
```json
{
  "approval_patterns": {
    "file_access": "Do you want to proceed?",
    "edit_accept": "accept edits",
    "yes_no": "[Y/n]"
  },
  "key_sequences": {
    "approve_file": "2\n",
    "accept_edit": "\n",
    "confirm_yes": "y\n"
  }
}
```

### INTEGRATOR 🔄 IN PROGRESS
**Current scope:** Multi-agent launcher
**Add to scope:** Daemon integration

**Additional tasks:**
1. Generalize daemon scripts from sark-v2-orchestration
2. Add daemon to launcher workflow
3. Create agent-specific daemon helpers
4. Integrate with embedded orchestration
5. Full testing with multi-agent project

**Estimated additional time:** +45 min (total: 2-3 hrs)

## Validation Plan

### Test 1: Daemon with Multi-Agent Project
```bash
# After Phase 1 implementation:
cd ~/Source/GRID/claude-orchestrator
czarina daemon start multi-agent-support

# Should:
# - Start daemon in tmux session
# - Auto-approve ARCHITECT and INTEGRATOR requests
# - Log activity to status/daemon.log

# Monitor:
czarina daemon logs multi-agent-support

# Validate:
# - Workers make progress without manual approvals
# - <5% human intervention needed
```

### Test 2: Embedded Orchestration with Daemon
```bash
# After Phase 2 (INTEGRATOR complete):
cd /path/to/any/embedded/project
./czarina-slug/.daemon-start

# Should work identically to core daemon
```

## Success Criteria

### Phase 1 Success (This Session)
- ✅ Generalized daemon template created
- ✅ Basic CLI commands working
- ✅ INTEGRATOR prompt updated with daemon tasks
- ✅ Daemon tested with multi-agent-support project
- ✅ <10 manual approvals in 30 minute test

### Phase 2 Success (INTEGRATOR Complete)
- ✅ Daemon fully integrated into launcher
- ✅ Agent-specific profiles working
- ✅ Embedded orchestration includes daemon
- ✅ Full documentation complete
- ✅ All tests passing

## Risk Mitigation

### Risk 1: Daemon doesn't work with current workers
**Mitigation:** Phase 1 tests this immediately
**Fallback:** Continue workers manually, fix daemon later

### Risk 2: Agent-specific approval patterns vary too much
**Mitigation:** ARCHITECT creates flexible profile system
**Fallback:** Start with Claude Code only, add others incrementally

### Risk 3: INTEGRATOR scope creep delays completion
**Mitigation:** Clear task list, time estimates
**Fallback:** Split daemon integration to separate worker if needed

## Timeline

```
Now (T+0)       : Complete Phase 1 (this session)
                  ├─ Generalized daemon template
                  ├─ CLI commands
                  ├─ Update INTEGRATOR prompt
                  └─ Test with multi-agent project

T+1-2 hrs       : ARCHITECT completes
                  └─ Agent profiles with daemon patterns

T+2-3 hrs       : INTEGRATOR completes
                  ├─ Full daemon integration
                  ├─ Launcher integration
                  └─ Documentation

T+3-4 hrs       : Omnibus merge
                  └─ All features integrated to main
```

## Next Steps (Immediate)

1. ✅ Read current daemon script structure
2. 🔲 Create generalized `czarina-core/daemon/czar-daemon.sh`
3. 🔲 Add daemon commands to `czarina` CLI
4. 🔲 Test daemon with multi-agent-support project
5. 🔲 Update INTEGRATOR worker prompt
6. 🔲 Report results

**Estimated time:** 45 minutes
**Impact:** HIGH - Enables autonomous orchestration

---

**Ready to proceed with Phase 1 integration.**
