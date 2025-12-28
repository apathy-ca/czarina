# Migration Guide: v0.7.0 → v0.7.1

**From:** Czarina v0.7.0
**To:** Czarina v0.7.1
**Status:** Production Ready
**Last Updated:** 2025-12-28

## Overview

Czarina v0.7.1 fixes three critical UX issues that were blocking smooth adoption:

1. **Worker Onboarding** - Workers no longer get stuck (0 stuck workers, down from 1 per orchestration)
2. **Czar Autonomy** - Czar now actually autonomous (0 manual coordination needed)
3. **Launch Complexity** - One-command launch (<60 seconds, down from 10+ minutes)

**100% backward compatible.** Existing orchestrations work unchanged, but you'll want to adopt the improvements.

---

## What's New in v0.7.1

### 1. Workers Never Get Stuck

**The Problem:**
Workers would launch but not know what to do first, waiting for instructions.

**The Fix:**
All worker identities now include an explicit "YOUR FIRST ACTION" section with the first command to run.

**Example:**
```markdown
## 🚀 YOUR FIRST ACTION

**Create v0.7.1 section in CHANGELOG:**
\```bash
cat CHANGELOG.md | head -50
# ... specific first commands
\```
```

**Value:** Workers immediately start working. No more stuck workers.

### 2. Czar Actually Autonomous

**The Problem:**
Czar required manual monitoring and coordination of workers.

**The Fix:**
Autonomous Czar daemon that:
- Monitors worker progress every 30 seconds
- Detects stuck/idle workers automatically
- Takes corrective action
- Manages phase transitions

**Value:** True hands-off orchestration. Set it and forget it.

### 3. One-Command Launch

**The Problem:**
Launch required 8 manual steps and 10+ minutes:
```bash
czarina analyze plan.md       # 1. Analyze
# Cut/paste into Claude         2. Manual
# Edit config.json              3. Manual
# Create worker files           4. Manual
czarina launch                # 5. Launch
# Wait for workers...           6. Manual
czarina daemon start          # 7. Start daemon
# Check worker status           8. Manual
```

**The Fix:**
```bash
czarina analyze plan.md --go  # That's it!
```

One command that:
- Analyzes the plan
- Creates config.json
- Creates worker files
- Launches workers
- Starts Czar daemon
- All in <60 seconds

**Value:** From plan to running orchestration in under a minute.

---

## Breaking Changes

**None!** v0.7.1 is 100% backward compatible.

All v0.7.0 orchestrations run unchanged in v0.7.1. Improvements are automatic.

---

## Migration Paths

Choose your migration strategy:

### Path 1: Adopt New Workflow (Recommended)

**For new orchestrations:**

1. Use the new one-command launch:
   ```bash
   cd your-project
   czarina analyze implementation-plan.md --go
   ```

2. That's it! Workers launch with:
   - Explicit first actions
   - Autonomous Czar monitoring
   - Fully automated setup

**Migration time:** 0 minutes (just use it)

### Path 2: Update Existing Worker Files

**For existing orchestrations you want to improve:**

1. Pull latest Czarina:
   ```bash
   cd ~/Source/GRID/claude-orchestrator
   git pull origin main
   ```

2. Update worker identity files to include "YOUR FIRST ACTION" section:
   ```bash
   cd .czarina/workers
   nano backend.md  # Add YOUR FIRST ACTION section
   nano frontend.md # Add YOUR FIRST ACTION section
   ```

3. Template format:
   ```markdown
   # Worker Identity: your-worker-id

   **Role:** Your Role
   **Agent:** Claude Code
   **Branch:** cz1/feat/your-feature

   ## 🚀 YOUR FIRST ACTION

   **What to do first:**
   \```bash
   # Specific command to run immediately
   cat README.md | head -20
   \```

   Then proceed with your tasks...

   ## Mission
   [Your worker mission...]
   ```

4. Launch as normal:
   ```bash
   czarina launch
   ```

**Migration time:** 5-10 minutes per orchestration

### Path 3: No Migration (Stay on v0.7.0 Behavior)

**Do nothing.** Your orchestrations work exactly as before.

You won't get:
- Explicit first actions (may have stuck workers)
- Autonomous Czar monitoring (manual coordination needed)
- One-command launch (still use multi-step process)

**When to choose:** If you're mid-orchestration and don't want to change workflow.

---

## Upgrade Instructions

### 1. Pull Latest Czarina

```bash
cd ~/Source/GRID/claude-orchestrator
git pull origin main
```

### 2. Verify Version

```bash
czarina --version
# Should show: Czarina 0.7.1
```

### 3. Test New Workflow

Try the new one-command launch on a test project:

```bash
cd ~/test-project
cat > plan.md <<'EOF'
# Implementation Plan

## Phase 1: Setup
- **backend** - Set up API server
- **frontend** - Create React app

## Deliverables
- Running API
- Working frontend
EOF

czarina analyze plan.md --go
```

Watch it:
1. Analyze the plan
2. Create config
3. Create worker files with first actions
4. Launch workers
5. Start Czar daemon
6. Workers immediately start working

All in <60 seconds!

---

## Common Migration Scenarios

### Scenario 1: Mid-Orchestration (v0.7.0 running)

**Question:** Should I upgrade mid-orchestration?

**Answer:** No, finish your current orchestration first.

**Steps:**
1. Complete current orchestration normally
2. Closeout and merge
3. Upgrade to v0.7.1
4. Start new orchestrations with new workflow

**Risk:** Low. But why change workflows mid-stream?

### Scenario 2: New Project (Starting Fresh)

**Question:** How should I start a new project?

**Answer:** Use the new one-command launch!

**Steps:**
```bash
cd your-project
cat > IMPLEMENTATION_PLAN.md  # Write your plan
czarina analyze IMPLEMENTATION_PLAN.md --go
```

**Time:** <60 seconds from plan to running workers

**Result:** Everything configured automatically with best practices

### Scenario 3: Existing .czarina/ Config

**Question:** I have existing .czarina/ configuration. Should I update it?

**Answer:** Optional. It works as-is, but you can improve it.

**To improve:**
1. Add "YOUR FIRST ACTION" sections to worker files
2. Next launch will benefit from no stuck workers
3. Autonomous Czar will monitor automatically

**To keep as-is:**
1. Do nothing
2. Works exactly as before
3. You just won't get the v0.7.1 improvements

### Scenario 4: Testing the New Features

**Question:** How can I test without affecting production orchestrations?

**Answer:** Create a test orchestration.

**Steps:**
```bash
# Create test project
mkdir ~/test-czarina-v0.7.1
cd ~/test-czarina-v0.7.1
git init

# Create simple plan
cat > plan.md <<'EOF'
# Test Plan
- **worker1** - Test task 1
- **worker2** - Test task 2
EOF

# Launch with new workflow
czarina analyze plan.md --go

# Watch the magic happen!
```

**Time:** 5 minutes total

**Result:** See all v0.7.1 improvements in action

---

## Rollback Instructions

If you need to roll back to v0.7.0:

```bash
cd ~/Source/GRID/claude-orchestrator
git checkout v0.7.0
```

**Note:** Rollback is safe. Your orchestrations continue working.

---

## Verification Checklist

After upgrading, verify these improvements:

- [ ] `czarina --version` shows 0.7.1
- [ ] `czarina analyze plan.md --go` works (test with sample plan)
- [ ] Worker identity files can include "YOUR FIRST ACTION" section
- [ ] Workers launch and immediately start working (no stuck workers)
- [ ] Czar daemon monitors workers automatically
- [ ] Launch time is <60 seconds (vs 10+ minutes before)

---

## Support

**Questions?** See:
- [CHANGELOG.md](CHANGELOG.md) - Full list of changes
- [README.md](README.md) - Updated documentation
- [QUICK_START.md](QUICK_START.md) - New workflow guide

**Issues?** Report at:
- https://github.com/apathy-ca/czarina/issues

---

## Summary

**v0.7.1 is a game-changer for UX:**

| Metric | Before v0.7.1 | After v0.7.1 | Improvement |
|--------|---------------|--------------|-------------|
| Stuck workers per orchestration | 1 | 0 | 100% ✅ |
| Manual coordination needed | Yes | No | 100% ✅ |
| Launch steps | 8 | 1 | 87.5% ✅ |
| Launch time | 10+ min | <60 sec | 90%+ ✅ |
| Worker onboarding clarity | Unclear | Explicit | 100% ✅ |
| Czar autonomy | Manual | Automatic | 100% ✅ |

**Recommendation:** Adopt the new workflow for all new orchestrations. It's dramatically better.

**Bottom line:** Czarina now "just works." No more manual coordination, no more stuck workers, no more complex launch process.

Enjoy! 🎉
