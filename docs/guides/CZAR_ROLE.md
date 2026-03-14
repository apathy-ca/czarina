# The Czar: Orchestration Coordinator

**The Czar is the critical coordinating role that manages the entire Czarina orchestration process.**

---

## 🎭 What is the Czar?

The **Czar** is the autonomous coordinator for your Czarina project - typically a human or AI agent that oversees the orchestration. While workers code in parallel, the Czar monitors, manages, and ensures everything runs smoothly.

**Who can be the Czar:**
- **Claude Code** (Desktop or Web) - Most common
- **Human** - Direct supervision
- **Cursor** - IDE-based monitoring
- **Any AI agent** - As long as they can monitor tmux and manage processes

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
# 1. Validate all requirements (hopper, agents, config)
cd ~/my-projects/awesome-app
czarina validate

# 2. Launch — registers workers in Hopper and starts tmux session
czarina launch

# 3. Attach to monitor
tmux attach -t czarina-awesome-app
```

### As Czar (AI Agent or Human)

**If you're an AI agent, say:**
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

**If you're human:**
- Review `.czarina/config.json` for project configuration
- Use `czarina status` for quick overview
- Check `tmux attach -t czarina-awesome-app` for worker activity
- Follow the monitoring commands below

**The Czar role includes:**
- Project configuration
- Worker assignments
- Current version status
- Token budgets
- Git branches

---

## 📊 Daily Czar Workflow

### Morning (Start of Session)

```bash
# 1. Check project status + Hopper task state
czarina status

# 2. Check Hopper task details directly
hopper --local task list --tag awesome-app
hopper --local lesson list --project awesome-app

# 3. Check worker progress
tmux attach -t czarina-awesome-app
# Ctrl+b then number to switch windows
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

2. **Hopper Task State**
   - All workers still `in_progress`?
   - Any workers `blocked`?
   - New tasks queued?

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

### Check Hopper Task State

```bash
# Summary for this project
czarina status

# All tasks with current status
hopper --local task list --tag awesome-app

# Worker-specific
hopper --local task list --tag worker-backend

# Lessons filed so far
hopper --local lesson list --project awesome-app

# Block a worker task if stuck
hopper --local task status task-abc12345 blocked --force
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

### Worker Lost Context Mid-Task

**Symptoms:**
- Worker seems confused about what they're supposed to be doing
- Worker restarted but doesn't know their task

**Actions:**
The worker recovers themselves — no Czar action needed unless the tmux window is gone:
```bash
# Worker runs:
hopper --local task list --tag worker-<id> --status in_progress
hopper --local task get <task-id> --with-lessons

# If you need to add a task mid-run:
hopper --local task add "[worker-id] New instruction: ..." \
  --tag czarina --tag awesome-app --tag worker-<id> --non-interactive
```

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

- **Check status regularly** (`czarina status` every 30-60 min)
- **Monitor Hopper task state** (`hopper --local task list --tag <project>`)
- **Review learnings as they're filed** (`hopper --local lesson list`)
- **Coordinate workers** (avoid file conflicts between workers)
- **Review PRs promptly** (keep flow moving)
- **Maintain session notes** (for handoffs and learnings)
- **Add mid-run tasks via Hopper** (not by editing worker files)

### DON'T ❌

- Let workers run unsupervised for hours
- Edit `.czarina/workers/<id>.md` mid-run (use Hopper tasks instead)
- Merge PRs without review
- Let workers overlap on the same files
- Skip filing learnings at phase close
- Work without a version plan

---

## 🔧 Czar Tools & Scripts

### Quick Status Check

```bash
#!/bin/bash
# czar-quick-status.sh

echo "=== Czarina Status ==="
czarina status

echo ""
echo "=== Hopper Tasks ==="
PROJECT_SLUG=$(jq -r '.project.slug' .czarina/config.json)
hopper --local task list --tag "$PROJECT_SLUG"

echo ""
echo "=== Lessons Filed ==="
hopper --local lesson list --project "$PROJECT_SLUG"

echo ""
echo "=== Git PRs ==="
gh pr list
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
- **[docs/HOPPER.md](../HOPPER.md)** - Hopper integration guide

---

## 🎯 Success Metrics for Czar

**You're doing well as Czar when:**
- ✅ Workers making steady progress (commits visible in git log)
- ✅ Hopper tasks show `in_progress` for all active workers
- ✅ PRs created regularly and reviewed
- ✅ No worker stuck > 1 hour
- ✅ Lessons being filed (visible in `hopper lesson list`)
- ✅ Version progression on track

**Red flags to address:**
- ❌ Worker Hopper task is `blocked` — investigate
- ❌ No commits from a worker in > 2 hours
- ❌ Same error repeated across sessions
- ❌ Worker prompts unclear or contradictory
- ❌ Merge conflicts accumulating between worker branches
- ❌ No lessons filed at end of a completed phase

---

## 💡 Pro Tips

1. **Use tmux zoom** - `Ctrl+b then z` to fullscreen a worker window
2. **Keep `czarina status` running** - In a separate terminal with `watch -n 60 czarina status`
3. **Batch PR reviews** - Review 2-3 PRs together at natural break points
4. **Review lessons before closeout** - `hopper --local lesson list --project <slug>`
5. **Add work via Hopper** - Never edit worker .md files mid-run; add Hopper tasks
6. **Trust the process** - Workers are autonomous; you're the safety net and decision-maker

---

**Remember:** You're not micromanaging - you're orchestrating. Let workers work autonomously, step in when needed, and keep the project moving forward. 🎭

**Version:** 1.1
**Status:** Active
**Audience:** AI agents or humans acting as Czar
**Note:** While any agent or human can be Czar, Claude Code is commonly used due to its ability to monitor tmux and coordinate autonomously
