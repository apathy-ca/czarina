# The Czar: Orchestration Coordinator

**The Czar is the critical Claude Code agent that manages the entire Czarina orchestration process.**

---

## 🎭 What is the Czar?

The **Czar** is a Claude Code agent (Desktop or Web) that acts as the autonomous coordinator for your Czarina project. While workers code in parallel, the Czar monitors, manages, and ensures everything runs smoothly.

**Think of it as:** The conductor of an orchestra - each musician (worker) plays their part, but the conductor ensures harmony, timing, and quality.

---

## 🎯 Core Responsibilities

### 1. **Monitor All Workers**
- Watch tmux sessions for all workers
- Track progress on assigned tasks
- Detect stuck or idle workers
- Verify workers are following their prompts

### 2. **Manage the Daemon**
- Start/stop the auto-approval daemon
- Monitor daemon effectiveness
- Check daemon logs for issues
- Adjust daemon behavior as needed

### 3. **Coordinate Version Progression**
- Track which version/phase the project is in
- Ensure dependencies are met before starting new versions
- Verify completion criteria for each version
- Update config.json with version progress

### 4. **Track Token Budgets**
- Monitor token usage per worker
- Compare recorded vs projected tokens
- Calculate efficiency ratios
- Alert when workers approach budget limits

### 5. **Manage Git Workflow**
- Verify workers are on correct branches
- Check for merge conflicts
- Review PR readiness
- Coordinate integration timing

### 6. **Provide Status Updates**
- Generate regular status reports
- Update project stakeholders
- Document blockers and resolutions
- Maintain session notes

---

## 🚀 Starting as Czar

### Initial Setup

```bash
# 1. Launch the orchestration
cd ~/my-projects/awesome-app
czarina launch

# 2. Start the daemon
czarina daemon start

# 3. Attach to monitoring (optional)
tmux attach -t czarina-awesome-app
```

### As Claude Code (You are the Czar)

**You say in Claude Code:**
```
I am the Czar for this Czarina orchestration.

Project: Awesome App
Current Version: v0.2.1-phase2
Workers: 7 (backend-1, backend-2, frontend-1, frontend-2, frontend-3, qa, docs)

My responsibilities:
1. Monitor all workers via tmux
2. Manage the daemon
3. Track token budgets
4. Coordinate version progression
5. Manage git workflow
6. Provide status updates

Show me the current status and what I should focus on first.
```

**Claude Code auto-discovers the .czarina/ directory and loads:**
- Project configuration
- Worker assignments
- Current version status
- Token budgets
- Git branches

---

## 📊 Daily Czar Workflow

### Morning (Start of Session)

```bash
# 1. Check project status
czarina status

# 2. Review daemon
czarina daemon status
czarina daemon logs | tail -50

# 3. Check worker progress
tmux attach -t czarina-awesome-app
# Ctrl+b then arrow keys to switch panes
# Ctrl+b then d to detach

# 4. Review git status
cd ~/my-projects/awesome-app
git status
git branch -a
gh pr list
```

### During Session (Monitoring)

**Check every 30-60 minutes:**

1. **Worker Health**
   - Are workers making progress?
   - Any stuck on approval prompts?
   - Any errors in logs?

2. **Daemon Status**
   - Is daemon running?
   - Auto-approvals working?
   - Any alerts generated?

3. **Token Budgets**
   - Workers on track with budgets?
   - Any overruns that need investigation?

4. **Git Activity**
   - Commits being made?
   - Branches up to date?
   - PRs ready for review?

### End of Session (Wrap-Up)

1. **Status Report**
   - Version progress
   - Token usage summary
   - Blockers encountered
   - PRs ready for review

2. **Update Documentation**
   - Session notes in czarina-inbox/sessions/
   - Update token metrics in config.json
   - Document any issues/resolutions

3. **Prepare for Next Session**
   - Set priorities for next session
   - Update worker prompts if needed
   - Note any configuration changes needed

---

## 🔍 Monitoring Commands

### Check Worker Status

```bash
# List all tmux sessions
tmux ls

# Attach to main session
tmux attach -t czarina-awesome-app

# Send command to specific worker pane
tmux send-keys -t czarina-awesome-app:0.1 "status" Enter

# Capture pane output
tmux capture-pane -t czarina-awesome-app:0.1 -p
```

### Check Daemon

```bash
# Daemon status
czarina daemon status

# Live daemon logs
czarina daemon logs

# Check for stuck workers (daemon creates alerts)
cat .czarina/status/alerts.json
```

### Check Git Progress

```bash
# See all branches
git branch -a

# Check worker branch status
git log --oneline feat/v0.2.1-phase2-backend-1

# Compare to main
git diff main..feat/v0.2.1-phase2-backend-1 --stat

# List PRs
gh pr list
gh pr view 123
```

### Check Token Usage

**In config.json:**
```json
{
  "version_plan": {
    "v0.2.1-phase2": {
      "token_budget": {
        "projected": 280000,
        "recorded": 142000,
        "remaining": 138000,
        "efficiency": 0.51
      }
    }
  }
}
```

**Update manually or via script**

---

## 🚨 Handling Common Issues

### Worker is Stuck

**Symptoms:**
- No commits in > 30 minutes
- Same prompt repeated
- Daemon can't auto-approve

**Actions:**
1. Attach to worker tmux pane
2. Identify the blocker
3. Manually approve if needed
4. Update worker prompt if confusion
5. Document in session notes

### Daemon Not Working

**Symptoms:**
- Workers constantly asking for approval
- Daemon logs show errors
- Auto-approvals not happening

**Actions:**
1. Check daemon status: `czarina daemon status`
2. Review logs: `czarina daemon logs`
3. Restart daemon: `czarina daemon stop && czarina daemon start`
4. Verify tmux session names match config
5. Check agent compatibility (Aider works best)

### Token Budget Overrun

**Symptoms:**
- Worker using > 110% of projected tokens
- Quality declining (rushing)
- Scope creep

**Actions:**
1. Review what worker has accomplished
2. Assess if overrun is justified
3. Options:
   - Increase budget (document why)
   - Split remaining work to new phase
   - Adjust worker prompt to focus
4. Update config.json with new budget
5. Document variance reason

### Merge Conflicts

**Symptoms:**
- PRs show conflicts
- Workers editing same files
- Integration blocked

**Actions:**
1. Review conflict source
2. Coordinate workers to avoid overlap
3. Update worker prompts with clearer boundaries
4. Manual resolution if needed
5. Update architecture to reduce coupling

---

## 📝 Czar Templates

### Daily Status Report

```markdown
# Czar Status Report - {Date}

## Project: {Name}
**Current Version:** v{X.Y.Z}[-phaseN]

## Token Budget
- Projected: {X}K
- Recorded: {X}K
- Efficiency: {X.XX}
- Status: {On Budget|Over Budget|Under Budget}

## Worker Status

### backend-1
- Status: {Active|Stuck|Idle|Complete}
- Progress: {X}% of tasks
- Tokens: {X}K / {X}K
- Branch: feat/v{X.Y.Z}-backend-1
- Blockers: {None|Description}

### frontend-1
- Status: {Active|Stuck|Idle|Complete}
- Progress: {X}% of tasks
- Tokens: {X}K / {X}K
- Branch: feat/v{X.Y.Z}-frontend-1
- Blockers: {None|Description}

{... repeat for all workers}

## Daemon Status
- Running: {Yes|No}
- Auto-approvals today: {X}
- Issues: {None|Description}

## Git Activity
- Commits today: {X}
- PRs open: {X}
- PRs ready for review: {X}

## Blockers
1. {Blocker description and plan}
2. {Blocker description and plan}

## Next Actions
1. {Priority action}
2. {Priority action}

## Notes
{Any observations, learnings, or context}
```

### Session Notes Template

```markdown
# Czar Session Notes - {Date}

## Session Info
- Start: {Time}
- End: {Time}
- Version: v{X.Y.Z}[-phaseN]

## Accomplishments
- {What was completed}
- {What was completed}

## Challenges
- {Challenge and how resolved}
- {Challenge and how resolved}

## Token Usage
- Session tokens: {X}K
- Running total: {X}K / {X}K projected

## Learnings
- {Pattern or insight discovered}
- {Pattern or insight discovered}

## Tomorrow's Priorities
1. {Priority}
2. {Priority}
```

---

## 🎓 Best Practices

### DO ✅

- **Check status regularly** (every 30-60 min)
- **Keep daemon running** (for autonomy)
- **Update token metrics** (real-time tracking)
- **Document blockers** (for patterns)
- **Coordinate workers** (avoid conflicts)
- **Review PRs promptly** (keep flow moving)
- **Maintain session notes** (for handoffs)
- **Use alerts.json** (daemon creates these)

### DON'T ❌

- Let workers run unsupervised for hours
- Ignore daemon alerts
- Skip token budget updates
- Merge PRs without review
- Let workers overlap on same files
- Forget to document learnings
- Work without version plan
- Ignore efficiency ratios > 1.3

---

## 🔧 Czar Tools & Scripts

### Quick Status Check

```bash
#!/bin/bash
# czar-quick-status.sh

echo "=== Czarina Status ==="
echo ""

# Project status
czarina status

echo ""
echo "=== Daemon Status ==="
czarina daemon status

echo ""
echo "=== Git PRs ==="
gh pr list

echo ""
echo "=== Token Budget ==="
# Parse from config.json
jq '.version_plan | to_entries[] | select(.value.status == "in_progress") | {version: .key, tokens: .value.token_budget}' .czarina/config.json
```

### Worker Health Check

```bash
#!/bin/bash
# czar-worker-health.sh

echo "=== Worker Health Check ==="
echo ""

# For each worker, check last commit time
for worker in backend-1 backend-2 frontend-1; do
    branch="feat/v0.2.1-phase2-$worker"
    last_commit=$(git log -1 --format="%ar" $branch 2>/dev/null || echo "No commits")
    echo "$worker: Last commit $last_commit"
done
```

---

## 📚 Related Documentation

- **[PROJECT_PLANNING_STANDARDS.md](../PROJECT_PLANNING_STANDARDS.md)** - Version and token planning
- **[czarina-core/docs/DAEMON_SYSTEM.md](../../czarina-core/docs/DAEMON_SYSTEM.md)** - Daemon details
- **[WORKER_SETUP_GUIDE.md](WORKER_SETUP_GUIDE.md)** - Worker configuration
- **[czarina-inbox/README.md](../../czarina-inbox/README.md)** - Session notes and improvements

---

## 🎯 Success Metrics for Czar

**You're doing well as Czar when:**
- ✅ Workers making steady progress
- ✅ Daemon auto-approving 90%+ of requests
- ✅ Token efficiency < 1.2 across workers
- ✅ PRs created regularly and reviewed
- ✅ No worker stuck > 1 hour
- ✅ Session notes maintained
- ✅ Version progression on track

**Red flags to address:**
- ❌ Worker idle > 30 minutes
- ❌ Daemon not running
- ❌ Token efficiency > 1.3
- ❌ No commits in > 2 hours
- ❌ Same error repeated
- ❌ Worker prompts unclear
- ❌ Merge conflicts accumulating

---

## 💡 Pro Tips

1. **Use tmux zoom** - `Ctrl+b then z` to fullscreen worker pane
2. **Keep daemon logs visible** - Tail in separate terminal
3. **Auto-refresh git status** - Use watch command
4. **Batch PR reviews** - Review 2-3 PRs together
5. **Document patterns** - Drop notes in czarina-inbox/
6. **Share learnings** - `czarina patterns pending`
7. **Trust the process** - Workers are autonomous, you're the safety net

---

**Remember:** You're not micromanaging - you're orchestrating. Let workers work autonomously, step in when needed, and keep the project moving forward. 🎭

**Version:** 1.0
**Status:** Active
**Audience:** Claude Code agents acting as Czar
