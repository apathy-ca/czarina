# 🤯 Meta-Orchestration: Czarina Orchestrating Czarina

## What Is This?

This is a **Czarina orchestration project to make Czarina agent-agnostic**!

We're using Czarina to coordinate 3 workers who will implement multi-agent support for Czarina itself.

**Meta level:** 💯

## The Workers

### REBRAND - Documentation Rebranding Specialist
**Branch:** `feat/agent-agnostic-docs`
**Mission:** Rebrand docs from "Claude-only" to "works with any AI agent"

**Tasks:**
- Create template versions of docs (with {{AGENT_NAME}} placeholders)
- Add agent compatibility matrix
- Update main docs to mention multi-agent support
- Keep Claude Code as primary example

**Time:** ~30 minutes

### ARCHITECT - Agent Profile System Architect
**Branch:** `feat/agent-profiles`
**Mission:** Design and implement agent profile system

**Tasks:**
- Create `agents/profiles/` with JSON profiles for each agent
- Build profile loader utility
- Integrate with embed command (--agent flag)
- Document profile schema

**Time:** 1-2 hours

### INTEGRATOR - Multi-Agent Integration Engineer
**Branch:** `feat/multi-agent-launcher`
**Mission:** Build tools for using Czarina with different agents

**Tasks:**
- Create multi-agent launcher script
- Build agent-specific helpers (cursor, aider, copilot)
- Write per-agent usage guides
- Test with multiple agents

**Time:** 1-2 hours

## Workflow

```
REBRAND (Phase 1)
    ↓
ARCHITECT (Phase 2) - depends on templates
    ↓
INTEGRATOR (Phase 3) - depends on profiles
    ↓
Merge to omnibus → feat/multi-agent-support
    ↓
Test everything
    ↓
Merge to main → Czarina is agent-agnostic! 🎉
```

## How to Start a Worker

### On Desktop (Local)
```bash
# Option 1: Use helper script
./czarina-multi-agent-support/.worker-init rebrand
./czarina-multi-agent-support/.worker-init architect
./czarina-multi-agent-support/.worker-init integrator

# Option 2: Read worker file directly
cat czarina-multi-agent-support/workers/rebrand.md
```

### On Mobile (Claude Code Web)
```
Just say:
"You are rebrand"
or
"You are architect"
or
"You are integrator"
```

### Using Czarina Dashboard
```bash
# Monitor progress (from orchestrator repo)
./czarina dashboard multi-agent-support

# Shows:
# - Which branches have commits
# - PR status
# - Files changed
# - Real-time progress
```

## Branches Created

- ✅ `feat/agent-agnostic-docs` (rebrand)
- ✅ `feat/agent-profiles` (architect)
- ✅ `feat/multi-agent-launcher` (integrator)
- 📋 `feat/multi-agent-support` (omnibus - for final merge)

## Timeline

**Total estimated time:** 3-4 hours total work

**Phases:**
1. REBRAND (30 min) → Templates ready
2. ARCHITECT (1-2 hrs) → Profiles ready
3. INTEGRATOR (1-2 hrs) → Launchers ready
4. Testing & integration (30 min)

**Can be parallelized:**
- REBRAND must go first
- ARCHITECT & INTEGRATOR can overlap partially
- All merge to omnibus at end

## Expected Outcomes

After all 3 workers complete and merge:

✅ **Documentation is agent-agnostic**
- Templates with {{AGENT_NAME}} placeholders
- Agent compatibility matrix
- Multi-agent usage examples

✅ **Agent profile system exists**
- JSON profiles for 5+ agents
- Profile loader utility
- Integrated with embed command

✅ **Multi-agent launchers work**
- `./czarina-core/launch-agent.sh cursor engineer1`
- Agent-specific helpers
- Per-agent documentation

✅ **Czarina works with ANY AI coding assistant!**

## Why This Is Cool

1. **Self-hosting** - Czarina orchestrating its own development
2. **Dog-fooding** - Testing embedded orchestration in real use
3. **Meta-proof** - If Czarina can orchestrate making itself better, it works!
4. **Practical** - Actually implements useful features

## The Irony

**Problem:** "How do we make Czarina work with non-Claude agents?"
**Solution:** "Use Claude-based Czarina to orchestrate the work!"
**Result:** Czarina makes itself agent-agnostic 🤯

## How to Contribute

Pick a worker and start working!

```bash
# 1. Pick a worker
# "I'll be rebrand" or "I'll be architect" or "I'll be integrator"

# 2. Get the prompt
./czarina-multi-agent-support/.worker-init rebrand

# 3. Follow the instructions
# Branch is already created, just check it out and start working

# 4. Create PR when done
# Instructions are in the worker prompt
```

## Current Status

- [x] Project created
- [x] Branches initialized
- [x] Orchestration embedded
- [ ] REBRAND work (waiting for worker)
- [ ] ARCHITECT work (waiting for worker)
- [ ] INTEGRATOR work (waiting for worker)
- [ ] Omnibus merge
- [ ] Main merge

## References

- **Analysis:** `AGENT_AGNOSTIC_ANALYSIS.md` - Full analysis of what needs to change
- **Worker Prompts:** `czarina-multi-agent-support/workers/*.md`
- **Config:** `projects/multi-agent-support-orchestration/config.sh`

---

**This is Czarina at its finest: orchestrating itself to become better!** 🚀🤖👑
