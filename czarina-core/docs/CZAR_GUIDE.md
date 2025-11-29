# SARK v1.1 - Czar's Command Guide

**You are the Czar. This is your command center.**

## 🎯 Your Mission

Orchestrate 6 Claude Code workers to implement SARK v1.1 Gateway Integration in 10 days with minimal manual intervention.

## 🚀 Getting Started (Choose Your Style)

### Option 1: Full Automation (Minimal Work)

```bash
cd /home/jhenry/Source/GRID/sark/orchestrator

# 1. Launch all workers in separate tmux sessions
./QUICKSTART.sh
# Choose option 2

# 2. Open dashboard in another terminal
./dashboard.py

# 3. Check in periodically, approve PRs when ready
./pr-manager.sh
```

**Your Role:** Monitor dashboard, approve PRs, create omnibus, merge.

---

### Option 2: Claude Code Instances (More Control)

```bash
cd /home/jhenry/Source/GRID/sark/orchestrator

# 1. Generate prompts
./QUICKSTART.sh
# Choose option 3

# 2. Open 6 Claude Code instances
# 3. Copy content from each prompt file into each instance
cat prompts/engineer1-prompt.md  # Copy to Claude instance 1
cat prompts/engineer2-prompt.md  # Copy to Claude instance 2
# etc.

# 4. Monitor progress
./dashboard.py
```

**Your Role:** Coordinate instances, monitor, review, merge.

---

### Option 3: Hybrid (Recommended)

```bash
# Launch critical path worker (Engineer 1) manually in Claude Code
cat prompts/engineer1-prompt.md  # Copy to dedicated Claude instance

# Launch remaining workers in tmux
for worker in engineer2 engineer3 engineer4 qa docs; do
    ./launch-worker.sh $worker &
done

# Monitor everything
./dashboard.py
```

**Your Role:** Focus on Engineer 1 (critical), automate the rest.

---

## 📊 Your Dashboard

```bash
./dashboard.py
```

This shows you everything in real-time:
- Worker status (pending → active → PR → merged)
- Files changed per worker
- Last commits
- PR approval status
- Checkpoint progress
- Overall completion %

**Leave this running in a dedicated terminal.**

---

## 🎛️ Your Control Panel

```bash
./orchestrator.sh
```

Interactive menu for all orchestration tasks:
- Launch workers
- Check status
- Monitor progress
- Track checkpoints
- View logs

---

## 🔍 PR Management (Your Key Tool)

```bash
./pr-manager.sh
```

This is where you spend most of your time as Czar:

### Day 8: When PRs Start Coming In

**Option 1: Auto-Review (Fast)**
```bash
./pr-manager.sh
# Choose option 3: Auto-review all PRs
```
This automatically approves PRs where CI passes.

**Option 2: Manual Review (Careful)**
```bash
./pr-manager.sh
# Choose option 2: Review specific PR
# Enter worker ID (e.g., engineer1)
```

### Day 8: Create Omnibus Branch

Once all 6 PRs are approved:

```bash
./pr-manager.sh
# Choose option 4: Create omnibus branch
```

This:
- Creates `feat/gateway-integration-omnibus`
- Merges all 6 worker branches in correct order
- Runs tests
- Pushes to remote

**If merge conflicts occur:** The script will pause and tell you exactly what to fix.

### Day 8-9: Create Omnibus PR

```bash
./pr-manager.sh
# Choose option 5: Create omnibus PR
```

This creates a single PR to main with all changes.

### Day 10: Final Merge

```bash
./pr-manager.sh
# Choose option 6: Merge omnibus to main
```

**🎉 Done!**

---

## 📅 Your Daily Workflow

### Day 1 (Critical!)

**Morning:**
```bash
# Launch Engineer 1 first (CRITICAL PATH)
./launch-worker.sh engineer1
# OR open Claude Code with prompts/engineer1-prompt.md

# Monitor Engineer 1 closely
# They must complete shared models by Hour 6!
```

**Hour 6-7:**
```bash
# Verify Engineer 1 pushed models
cd /home/jhenry/Source/GRID/sark
git fetch origin feat/gateway-client
git log origin/feat/gateway-client

# If models are there, launch remaining workers
for worker in engineer2 engineer3 engineer4 qa docs; do
    ./launch-worker.sh $worker
done
```

**End of Day:**
```bash
# Mark checkpoint
./orchestrator.sh
# Option 10: Run Day 1 checkpoint
```

---

### Day 2-3 (Parallel Development)

**Your Tasks:**
1. Check dashboard periodically
2. Watch for blockers
3. Answer questions
4. Review commits

```bash
# Morning check
./dashboard.py

# View commits across all branches
git log --oneline --graph --all

# Check specific worker if needed
tmux attach -t sark-worker-engineer2
```

**No action needed unless workers are blocked.**

---

### Day 4 (Integration Checkpoint)

**Your Tasks:**
1. Verify core services are testable
2. Ensure QA can start integration tests
3. Mark checkpoint

```bash
# Check status
./pr-manager.sh
# Option 1: Check all PRs status

# Mark checkpoint
./orchestrator.sh
# Option 11: Run Day 4 checkpoint
```

---

### Day 5-7 (Feature Completion & Testing)

**Your Tasks:**
1. Monitor dashboard
2. Review code as needed
3. Unblock workers

```bash
# Daily check
./dashboard.py

# If a worker needs help, attach to their session
tmux attach -t sark-worker-qa
```

---

### Day 8 (PR Day - You're Busy!)

**Morning:**
```bash
# Check all PRs are created
./pr-manager.sh
# Option 1: Check all PRs status
```

**Afternoon:**
```bash
# Auto-review all (if CI passes)
./pr-manager.sh
# Option 3: Auto-review all PRs

# OR review manually
./pr-manager.sh
# Option 2: Review specific PR (one by one)

# Once all approved, create omnibus
./pr-manager.sh
# Option 4: Create omnibus branch
```

**End of Day:**
```bash
# Mark checkpoint
./orchestrator.sh
# Option 12: Run Day 8 checkpoint
```

---

### Day 9 (Integration Testing)

**Your Tasks:**
1. Monitor omnibus branch testing
2. Fix integration issues
3. Coordinate workers

```bash
# Check out omnibus branch
git checkout feat/gateway-integration-omnibus

# Run full test suite
pytest tests/ -v

# If issues found, coordinate fixes
./pr-manager.sh
```

---

### Day 10 (Final Day - Merge!)

**Morning:**
```bash
# Final validation
git checkout feat/gateway-integration-omnibus
pytest tests/ -v --cov
opa test opa/policies/

# Create omnibus PR
./pr-manager.sh
# Option 5: Create omnibus PR
```

**Afternoon:**
```bash
# Final review
gh pr view feat/gateway-integration-omnibus

# Merge!
./pr-manager.sh
# Option 6: Merge omnibus to main

# Celebrate! 🎉
```

---

## 🔧 Troubleshooting

### Worker is stuck

```bash
# Attach to their session
tmux attach -t sark-worker-engineer2

# Or check what they're working on
git log origin/feat/gateway-api
```

### Engineer 1 models not ready (Day 1 blocker!)

**This is your #1 priority to fix.**

```bash
# Check status
git fetch origin feat/gateway-client
git diff main origin/feat/gateway-client

# If models aren't there, engage with Engineer 1 directly
tmux attach -t sark-worker-engineer1

# Or in Claude Code, ask:
# "What's the status of shared models in src/sark/models/gateway.py?"
```

### Merge conflict in omnibus

```bash
git checkout feat/gateway-integration-omnibus

# See conflicts
git diff --name-only --diff-filter=U

# Fix conflicts in each file
vim <conflicted-file>

# Continue merge
git add <resolved-files>
git merge --continue

# Re-run omnibus creation
./pr-manager.sh
# Option 4: Create omnibus branch
```

### Dashboard not working

```bash
pip3 install rich
./dashboard.py
```

### Worker can't find shared models

```bash
# Worker needs to merge Engineer 1's branch
# Attach to worker session
tmux attach -t sark-worker-engineer2

# In that session:
git merge feat/gateway-client
```

---

## 🎯 Success Metrics

Track these daily on your dashboard:

- [ ] Day 1: Engineer 1 models complete (**CRITICAL**)
- [ ] Day 1: All workers have pulled models
- [ ] Day 4: Core services testable
- [ ] Day 7: All features complete
- [ ] Day 8: All 6 PRs created
- [ ] Day 8: Omnibus branch created
- [ ] Day 9: Integration tests passing
- [ ] Day 10: Omnibus merged to main

---

## 💡 Pro Tips

### Minimize Manual Work

1. **Use auto-review** if you trust the workers and CI passes
2. **Trust the dashboard** - it shows you everything
3. **Only intervene when blocked** - workers are autonomous
4. **Focus on Engineer 1** on Day 1 - everything else depends on this

### Stay Informed

```bash
# Check what changed today across all workers
git log --since="24 hours ago" --all --oneline --graph

# Check specific worker's progress
git log origin/feat/gateway-client --since="24 hours ago"

# View all active branches
git branch -a | grep feat/gateway
```

### Coordinate Dependencies

**Day 1:** Engineer 1 → Everyone (shared models)
**Day 2+:**
- Engineer 2 depends on Engineer 1 (client)
- Engineer 2 depends on Engineer 3 (policies)
- Engineer 2 depends on Engineer 4 (audit)

**Watch for:** Workers waiting on dependencies. Check dashboard for "Files changed: 0" after Day 1.

---

## 🎬 Quick Command Reference

```bash
# Launch everything
./QUICKSTART.sh

# Monitor
./dashboard.py

# Manage PRs
./pr-manager.sh

# Control panel
./orchestrator.sh

# Launch specific worker
./launch-worker.sh engineer1

# Attach to worker
tmux attach -t sark-worker-engineer1

# Check all worker sessions
tmux ls

# View prompts
cat prompts/engineer1-prompt.md
```

---

## 📞 Getting Help

### From a Worker

Attach to their tmux session:
```bash
tmux attach -t sark-worker-<worker-id>
```

Ask them directly in their context.

### From This System

```bash
# View docs
cat README.md | less

# View this guide
cat CZAR_GUIDE.md | less

# Check task files
cat ../docs/gateway-integration/tasks/ENGINEER_1_TASKS.md
```

---

## 🎉 When You're Done

```bash
# Tag release
git tag -a v1.1.0 -m "SARK v1.1: Gateway Integration"
git push origin v1.1.0

# Update main README
# Deploy to staging
# Celebrate! 🎊
```

---

**You are the Czar. You have the tools. Now go orchestrate! 🎭**

---

## Appendix: Directory Map

```
orchestrator/
├── CZAR_GUIDE.md          ← YOU ARE HERE
├── README.md              ← System documentation
├── QUICKSTART.sh          ← One-command launcher
├── orchestrator.sh        ← Main control panel
├── launch-worker.sh       ← Worker launcher (tmux)
├── dashboard.py           ← Live monitoring
├── pr-manager.sh          ← PR automation
├── generate-worker-prompts.sh  ← Prompt generator
├── prompts/               ← Generated Claude prompts
│   ├── engineer1-prompt.md
│   ├── engineer2-prompt.md
│   ├── engineer3-prompt.md
│   ├── engineer4-prompt.md
│   ├── qa-prompt.md
│   └── docs-prompt.md
├── workers/               ← Worker session data
├── status/                ← Status tracking
│   └── master-status.json
└── logs/                  ← Execution logs
```

---

**Version:** 1.0
**Created:** November 27, 2025
**Status:** Ready for mission start 🚀
