# Migration Guide: v0.6.2 → v0.7.0

**From:** Czarina v0.6.2
**To:** Czarina v0.7.0
**Status:** Production Ready
**Last Updated:** 2025-12-28

## Overview

Czarina v0.7.0 introduces two major enhancements while maintaining **100% backward compatibility** with v0.6.2:

1. **Memory System** - Persistent learning across sessions (3-tier architecture)
2. **Agent Rules Library** - 43K+ lines of production-tested best practices

**Both features are opt-in.** Existing orchestrations work unchanged.

---

## What's New in v0.7.0

### 1. Memory System

Workers can now remember and learn from past sessions:

- **Architectural Core** - Essential context loaded in every session
- **Project Knowledge** - Searchable history via semantic search
- **Session Context** - Ephemeral working state

**Value:** Workers no longer forget everything between sessions. They build institutional knowledge.

**See:** [MEMORY_GUIDE.md](MEMORY_GUIDE.md)

### 2. Agent Rules Integration

Workers now launch with 43K+ lines of best practices:

- Python development standards
- Role-specific guidance (Architect, Code, QA, etc.)
- Workflow best practices
- Design patterns
- Testing and security standards
- Documentation templates

**Value:** Workers start with expert-level knowledge, not just general AI.

**See:** [AGENT_RULES.md](AGENT_RULES.md)

### 3. Enhanced Configuration Schema

Config.json extended to support memory and rules:

```json
{
  "memory": { "enabled": true },
  "agent_rules": { "enabled": true },
  "workers": [
    {
      "id": "backend",
      "role": "code",  // NEW: Determines auto-loaded rules
      "memory": { "enabled": true },
      "rules": { "enabled": true }
    }
  ]
}
```

**Value:** Granular control over memory and rules per worker.

### 4. New CLI Commands

```bash
# Memory commands
czarina memory init
czarina memory query "<search>"
czarina memory extract
czarina memory rebuild
czarina memory status

# Init with new features
czarina init --with-memory --with-rules
```

---

## Breaking Changes

**None!** v0.7.0 is 100% backward compatible.

All v0.6.2 orchestrations run unchanged in v0.7.0. New features are opt-in.

---

## Migration Paths

Choose your migration strategy:

### Path 1: No Migration (Stay on v0.6.2 Behavior)

**Do nothing.** Your orchestrations work exactly as before.

```bash
# Upgrade Czarina
cd ~/Source/GRID/claude-orchestrator
git pull
git checkout v0.7.0

# Launch as usual - v0.6.2 behavior
cd ~/my-project
czarina launch
```

No config changes needed. Memory and rules remain disabled.

### Path 2: Gradual Adoption (Recommended)

**Phase 1: Enable agent rules first**

```json
{
  "agent_rules": {
    "enabled": true  // Add this
  }
  // Rest of config unchanged
}
```

Workers now get best practices. No other changes.

**Phase 2: Add memory later**

```bash
czarina memory init  # Initialize memory
```

Edit `.czarina/memories.md` to add Architectural Core, then:

```json
{
  "agent_rules": { "enabled": true },
  "memory": { "enabled": true }  // Add this
}
```

**Phase 3: Optimize per worker**

```json
{
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "rules": { "enabled": true },
      "memory": { "enabled": true }
    },
    {
      "id": "docs",
      "role": "documentation",
      "rules": { "enabled": true },
      "memory": { "enabled": false }  // Docs don't need memory
    }
  ]
}
```

### Path 3: Full Adoption (Maximize Benefits)

**Enable everything from the start:**

```bash
# Upgrade
cd ~/Source/GRID/claude-orchestrator
git pull
git checkout v0.7.0

# Re-initialize project with new features
cd ~/my-project
czarina init --with-memory --with-rules
```

Update config:

```json
{
  "project": { "name": "my-project" },
  "memory": {
    "enabled": true,
    "embedding_provider": "openai",
    "auto_extract": true
  },
  "agent_rules": {
    "enabled": true,
    "mode": "auto",
    "condensed": true
  },
  "workers": [
    {
      "id": "backend",
      "role": "code",  // Add role for auto-rule loading
      "agent": "claude",
      "branch": "feat/backend"
    },
    {
      "id": "qa",
      "role": "qa",    // QA gets testing rules
      "agent": "aider",
      "branch": "feat/testing"
    }
  ]
}
```

Populate `.czarina/memories.md` with Architectural Core.

Launch with full v0.7.0 capabilities!

---

## Step-by-Step Migration

### Step 1: Upgrade Czarina

```bash
cd ~/Source/GRID/claude-orchestrator
git pull origin main
git checkout v0.7.0
czarina --version  # Should show 0.7.0
```

### Step 2: Verify Existing Config Still Works

```bash
cd ~/my-project
czarina launch  # Should work exactly as before
```

If it works, you're good! v0.7.0 is backward compatible.

### Step 3: (Optional) Enable Agent Rules

Add to `.czarina/config.json`:

```json
{
  "agent_rules": {
    "enabled": true
  }
}
```

Add `role` field to workers:

```json
{
  "workers": [
    {
      "id": "backend",
      "role": "code",     // Add this
      "agent": "claude",
      "branch": "feat/backend"
    }
  ]
}
```

**Test:**
```bash
czarina launch
```

Workers should now load with agent rules.

### Step 4: (Optional) Initialize Memory

```bash
czarina memory init
```

This creates `.czarina/memories.md`. Edit it to add your Architectural Core:

```markdown
## Architectural Core

### Component Dependencies
- [Your essential dependencies]

### Known Couplings
- [Your implicit couplings]

### Critical Constraints
- [Your must-not-violate rules]
```

Enable in config:

```json
{
  "memory": {
    "enabled": true
  }
}
```

**Test:**
```bash
czarina launch
```

Workers should now load with memory context.

### Step 5: Test and Iterate

Run a small orchestration to test:

```bash
czarina launch
# Monitor workers
# Check they have rules and memory context
# Verify everything works
```

Adjust configuration as needed.

---

## Configuration Changes

### v0.6.2 Config

```json
{
  "project": {
    "name": "my-project",
    "slug": "my-project"
  },
  "orchestration": {
    "mode": "local"
  },
  "workers": [
    {
      "id": "backend",
      "agent": "claude",
      "branch": "feat/backend",
      "dependencies": []
    }
  ]
}
```

### v0.7.0 Config (Backward Compatible)

Same config works! Or enhance it:

```json
{
  "project": {
    "name": "my-project",
    "slug": "my-project"
  },
  "orchestration": {
    "mode": "local"
  },
  
  // NEW: Global memory config
  "memory": {
    "enabled": true,
    "embedding_provider": "openai",
    "auto_extract": true
  },
  
  // NEW: Global agent rules config
  "agent_rules": {
    "enabled": true,
    "mode": "auto",
    "condensed": true
  },
  
  "workers": [
    {
      "id": "backend",
      "role": "code",      // NEW: Determines auto-loaded rules
      "agent": "claude",
      "branch": "feat/backend",
      "dependencies": [],
      
      // NEW: Per-worker memory config (optional)
      "memory": {
        "enabled": true,
        "use_core": true,
        "search_on_start": true
      },
      
      // NEW: Per-worker rules config (optional)
      "rules": {
        "enabled": true,
        "auto_load": true
      }
    }
  ]
}
```

**All new fields are optional.** Omit them for v0.6.2 behavior.

---

## Feature Comparison

| Feature | v0.6.2 | v0.7.0 |
|---------|--------|--------|
| Multi-worker orchestration | ✅ | ✅ |
| Git worktrees | ✅ | ✅ |
| Autonomous Czar | ✅ | ✅ |
| Daemon auto-approval | ✅ | ✅ |
| Hopper (enhancement queue) | ✅ | ✅ |
| Phase management | ✅ | ✅ |
| **Memory system** | ❌ | ✅ |
| **Agent rules library** | ❌ | ✅ |
| **Role-based rule loading** | ❌ | ✅ |
| **Semantic memory search** | ❌ | ✅ |
| **Session extraction** | ❌ | ✅ |

---

## Common Migration Scenarios

### Scenario 1: Existing Project, Add Memory

**Goal:** Enable memory for an ongoing project

**Steps:**
1. Initialize memory:
   ```bash
   czarina memory init
   ```

2. Review past sessions/PRs and populate Architectural Core:
   ```markdown
   ## Architectural Core
   
   ### Component Dependencies
   [Extract from your experience]
   
   ### Known Couplings
   [Document the gotchas you've learned]
   
   ### Critical Constraints
   [The rules that must never be broken]
   ```

3. Enable in config:
   ```json
   { "memory": { "enabled": true } }
   ```

4. Going forward, extract learnings after sessions:
   ```bash
   czarina memory extract
   ```

### Scenario 2: New Project, Full v0.7.0

**Goal:** Start fresh with all v0.7.0 features

**Steps:**
1. Initialize with new features:
   ```bash
   cd ~/my-new-project
   czarina init --with-memory --with-rules
   ```

2. Configure workers with roles:
   ```json
   {
     "memory": { "enabled": true },
     "agent_rules": { "enabled": true },
     "workers": [
       { "id": "backend", "role": "code" },
       { "id": "frontend", "role": "code" },
       { "id": "qa", "role": "qa" }
     ]
   }
   ```

3. Launch:
   ```bash
   czarina launch
   ```

Workers get rules and memory from day one!

### Scenario 3: Selective Adoption

**Goal:** Enable memory for some workers, not others

**Config:**
```json
{
  "memory": { "enabled": false },  // Disabled globally
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "memory": { "enabled": true }  // Enabled for this worker only
    },
    {
      "id": "docs",
      "role": "documentation"
      // No memory config = disabled (inherits global)
    }
  ]
}
```

### Scenario 4: Rules Without Memory

**Goal:** Get best practices without memory overhead

**Config:**
```json
{
  "agent_rules": { "enabled": true },
  "memory": { "enabled": false },  // Or omit entirely
  "workers": [
    { "id": "backend", "role": "code" }
  ]
}
```

Workers get rules, but no memory system.

---

## Troubleshooting Migration

### Config Validation Errors

**Error:** `Invalid config: unknown field 'memory'`

**Cause:** Using old Czarina version

**Fix:**
```bash
cd ~/Source/GRID/claude-orchestrator
git pull
git checkout v0.7.0
```

### Workers Not Loading Rules

**Symptom:** Workers don't seem to have rules

**Check:**
1. `agent_rules.enabled: true` in config?
2. Worker has `role` field?
3. `.czarina/agent-rules/` symlink exists?
   ```bash
   ls -la .czarina/agent-rules
   ```

**Fix:**
```bash
# Verify symlink
ls -la ~/Source/GRID/claude-orchestrator/czarina-core/agent-rules

# If missing, reinstall Czarina
cd ~/Source/GRID/claude-orchestrator
git pull
```

### Memory Queries Return Nothing

**Symptom:** `czarina memory query` returns empty

**Cause:** Index not built yet

**Fix:**
```bash
czarina memory rebuild
```

### Embedding API Errors

**Error:** "OpenAI API authentication failed"

**Cause:** Missing or invalid `OPENAI_API_KEY`

**Fix:**
```bash
export OPENAI_API_KEY="sk-..."
# Or add to ~/.bashrc or .env
```

Or switch to local embeddings (when available):
```json
{
  "memory": {
    "embedding_provider": "local"
  }
}
```

---

## Rollback Plan

If you encounter issues with v0.7.0, rollback is easy:

### Option 1: Disable New Features

```json
{
  "memory": { "enabled": false },
  "agent_rules": { "enabled": false }
}
```

This gives you v0.6.2 behavior on v0.7.0 code.

### Option 2: Downgrade Czarina

```bash
cd ~/Source/GRID/claude-orchestrator
git checkout v0.6.2
```

Your configs still work (new fields are ignored).

### Option 3: Remove New Config Fields

Delete memory and agent_rules sections from config.json:

```json
{
  // Remove these sections:
  "memory": { ... },
  "agent_rules": { ... },
  
  // Keep existing:
  "project": { ... },
  "orchestration": { ... },
  "workers": [ ... ]
}
```

---

## Performance Impact

### Context Loading Time

**v0.6.2:** ~500ms to launch worker
**v0.7.0 (with rules + memory):** ~2s to launch worker

**Additional:** ~1.5s for loading rules and querying memory
**Impact:** Negligible for sessions that last minutes/hours

### Memory Usage

**v0.6.2:** ~100MB per worker
**v0.7.0:** ~120MB per worker

**Additional:** ~20MB for rules and memory context
**Impact:** Minimal - well within modern system capabilities

### Storage

**New files:**
- `.czarina/memories.md` - ~100KB typical, grows over time
- `.czarina/memories.index` - ~500KB (regenerable)
- `czarina-core/agent-rules/` - symlink (no space)

**Total:** < 1MB for most projects

---

## Best Practices for Migration

### 1. Test in Non-Critical Project First

Migrate a test project before production:

```bash
cd ~/test-project
git checkout -b test-v0.7.0
czarina init --with-memory --with-rules
# Test orchestration
# Verify everything works
```

### 2. Enable Features Incrementally

Don't enable everything at once:

1. First: Upgrade Czarina, verify v0.6.2 behavior
2. Second: Enable agent rules only
3. Third: Add memory system
4. Fourth: Optimize per-worker configs

### 3. Document Your Architectural Core Early

Don't wait until you have problems. Document now:

- Component dependencies you know about
- Gotchas you've already encountered
- Constraints you've learned the hard way

Even a minimal core is valuable.

### 4. Extract Learnings Consistently

Make it a habit:

```bash
# After fixing a bug
czarina memory extract

# After debugging session
czarina memory extract

# After phase completion
czarina memory extract
```

The value compounds over time.

### 5. Review and Curate Memory

Every few weeks:

```bash
# Review memories.md
nano .czarina/memories.md

# Remove obsolete entries
# Consolidate similar learnings
# Promote important patterns to Architectural Core

# Rebuild index
czarina memory rebuild
```

---

## FAQ

### Do I have to migrate?

No. v0.7.0 is backward compatible. You can stay on v0.6.2 behavior indefinitely.

### Can I enable memory without rules?

Yes:
```json
{
  "memory": { "enabled": true },
  "agent_rules": { "enabled": false }
}
```

### Can I enable rules without memory?

Yes:
```json
{
  "memory": { "enabled": false },
  "agent_rules": { "enabled": true }
}
```

They're completely independent features.

### Will my existing orchestrations break?

No. v0.7.0 maintains 100% backward compatibility. Existing configs work unchanged.

### How long does migration take?

**Minimal:** 5 minutes (just upgrade Czarina, enable in config)
**Full:** 1-2 hours (upgrade, enable features, populate memory, test)

Most time is populating Architectural Core thoughtfully.

### Should I migrate mid-orchestration?

No. Finish current orchestration on v0.6.2, then migrate before next one.

Changing versions mid-orchestration is not recommended.

### What if I don't have OpenAI API key?

Memory system requires embeddings. Options:

1. Get OpenAI API key (cheap: ~$0.50/month)
2. Wait for local embeddings support (coming soon)
3. Don't use memory system (rules still work!)

### Can I try v0.7.0 then revert?

Yes! Rollback is easy:

```bash
cd ~/Source/GRID/claude-orchestrator
git checkout v0.6.2
```

Or just disable features in config:
```json
{
  "memory": { "enabled": false },
  "agent_rules": { "enabled": false }
}
```

---

## Migration Checklist

Use this checklist for migration:

### Pre-Migration
- [ ] Backup current project (git commit all changes)
- [ ] Review current config.json
- [ ] Complete any in-progress orchestrations

### Upgrade
- [ ] Pull latest Czarina: `git pull`
- [ ] Checkout v0.7.0: `git checkout v0.7.0`
- [ ] Verify version: `czarina --version`

### Test Compatibility
- [ ] Launch with existing config: `czarina launch`
- [ ] Verify workers start correctly
- [ ] Verify basic functionality works

### Enable Agent Rules (Optional)
- [ ] Add `agent_rules.enabled: true` to config
- [ ] Add `role` field to workers
- [ ] Test worker launch with rules
- [ ] Verify rules appear in worker context

### Enable Memory (Optional)
- [ ] Run `czarina memory init`
- [ ] Populate `.czarina/memories.md` Architectural Core
- [ ] Add `memory.enabled: true` to config
- [ ] Test worker launch with memory
- [ ] Verify memory context loads

### Optimize (Optional)
- [ ] Fine-tune per-worker configs
- [ ] Adjust memory settings
- [ ] Customize rule domains
- [ ] Test full orchestration

### Validate
- [ ] Run small test orchestration
- [ ] Check logs for errors
- [ ] Verify memory queries work
- [ ] Confirm rules are applied

### Document
- [ ] Update project README with v0.7.0 notes
- [ ] Document any custom configurations
- [ ] Share learnings with team

---

## Getting Help

**Documentation:**
- [AGENT_RULES.md](AGENT_RULES.md) - Agent rules guide
- [MEMORY_GUIDE.md](MEMORY_GUIDE.md) - Memory system guide
- [QUICK_START.md](QUICK_START.md) - Getting started
- [README.md](README.md) - Main documentation

**Issues:**
Report migration issues at: https://github.com/apathy-ca/czarina/issues

**Community:**
Share migration experiences and ask questions in GitHub Discussions.

---

## Summary

**Migration to v0.7.0:**
- ✅ 100% backward compatible
- ✅ All new features are opt-in
- ✅ Existing orchestrations work unchanged
- ✅ Incremental adoption supported
- ✅ Easy rollback if needed
- ✅ Minimal performance impact
- ✅ Significant quality improvement

**Recommended Migration:** Start with agent rules, add memory later, optimize per-worker.

**Estimated Time:** 5 minutes (minimal) to 2 hours (full adoption)

**Worth It?** Absolutely. The improvements in worker quality and consistency are substantial.

---

**Version:** 0.7.0
**Last Updated:** 2025-12-28
**Previous:** [MEMORY_GUIDE.md](MEMORY_GUIDE.md)
**Next:** [CHANGELOG.md](CHANGELOG.md)
