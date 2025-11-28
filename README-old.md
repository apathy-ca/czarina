# SARK v1.1 Gateway Integration - Orchestration System

Multi-agent orchestration system for managing 6 parallel Claude Code worker instances to implement SARK v1.1 Gateway Integration.

## 🎯 Quick Start

### 1. Initialize the Orchestrator

```bash
cd /home/jhenry/Source/GRID/sark/orchestrator
chmod +x *.sh *.py
./orchestrator.sh
# Choose option 1: Initialize orchestrator
```

### 2. Launch All Workers

**Option A: Using the main orchestrator (terminal-based)**
```bash
./orchestrator.sh
# Choose option 2: Launch all workers
```

**Option B: Using tmux (recommended)**
```bash
# Launch all 6 workers in tmux sessions
./launch-worker.sh engineer1
./launch-worker.sh engineer2
./launch-worker.sh engineer3
./launch-worker.sh engineer4
./launch-worker.sh qa
./launch-worker.sh docs

# View active sessions
tmux ls

# Attach to a worker
tmux attach -t sark-worker-engineer1
```

**Option C: Manual launch with prompts**
```bash
# Generate worker prompts
./generate-worker-prompts.sh

# Copy prompt content from orchestrator/prompts/ and paste into Claude Code
```

### 3. Monitor Progress

**Option A: Live dashboard (recommended)**
```bash
./dashboard.py
```

**Option B: Text-based status**
```bash
./orchestrator.sh
# Choose option 4: Show status
```

### 4. Manage PRs

```bash
./pr-manager.sh
# Interactive PR management menu
```

## 📁 Directory Structure

```
orchestrator/
├── README.md                      # This file
├── orchestrator.sh                # Main orchestration script
├── launch-worker.sh               # Individual worker launcher (tmux)
├── generate-worker-prompts.sh     # Generate Claude Code prompts
├── dashboard.py                   # Live dashboard (requires rich)
├── pr-manager.sh                  # PR review and merge automation
├── prompts/                       # Generated worker prompts
│   ├── engineer1-prompt.md
│   ├── engineer2-prompt.md
│   ├── engineer3-prompt.md
│   ├── engineer4-prompt.md
│   ├── qa-prompt.md
│   └── docs-prompt.md
├── workers/                       # Worker session data
│   ├── engineer1/
│   ├── engineer2/
│   └── ...
├── status/                        # Status tracking
│   └── master-status.json
└── logs/                          # Execution logs
```

## 🎭 Worker Assignments

| Worker | Branch | Role | Priority |
|--------|--------|------|----------|
| **Engineer 1** | `feat/gateway-client` | Gateway Client & Infrastructure | **CRITICAL** (Day 1 blocker) |
| **Engineer 2** | `feat/gateway-api` | Authorization API Endpoints | High |
| **Engineer 3** | `feat/gateway-policies` | OPA Policies & Policy Service | High |
| **Engineer 4** | `feat/gateway-audit` | Audit & Monitoring | Medium |
| **QA** | `feat/gateway-tests` | Testing & Validation | High |
| **Docs** | `feat/gateway-docs` | Documentation & Deployment | Medium |

## 📅 Timeline

### Day 1: Kickoff & Shared Models
- **Hour 0-4:** Engineer 1 creates shared models
- **Hour 4:** All workers review models
- **Hour 6:** Engineer 1 finalizes, all workers pull
- **Hour 8:** All workers begin parallel work

### Day 2-3: Parallel Development
- All workers work independently
- Daily status updates

### Day 4: Integration Checkpoint
- Core services testable
- QA begins integration testing

### Day 5-6: Feature Completion
- Complete remaining features
- Address QA issues

### Day 7: Testing & Refinement
- All features complete
- Performance and security testing

### Day 8: PR Creation & Omnibus Branch
- All workers create individual PRs
- Orchestrator creates omnibus branch

### Day 9: Integration Testing
- Test on omnibus branch
- Fix integration issues

### Day 10: Final Validation & Merge
- Final validation
- Create omnibus PR to main
- Merge!

## 🛠️ Tools Overview

### `orchestrator.sh` - Main Orchestration Script

Interactive menu for managing the entire project:

```bash
./orchestrator.sh
```

Features:
- Initialize orchestrator
- Launch all workers or specific workers
- Monitor status
- Check PRs
- Review PRs
- Create omnibus branch
- Create omnibus PR
- Track checkpoints

### `launch-worker.sh` - Worker Launcher

Launch individual workers in tmux sessions:

```bash
./launch-worker.sh engineer1
```

Each worker gets:
- Dedicated tmux session
- Pre-configured branch
- Helper functions (task, coord, status, test, create_pr)
- Task file ready to view

### `dashboard.py` - Live Dashboard

Real-time monitoring with rich UI:

```bash
./dashboard.py
```

Shows:
- Worker status (active, PR, merged)
- Files changed per worker
- Last commits
- PR approvals
- Checkpoint progress
- Overall statistics

Requirements:
```bash
pip install rich
```

### `pr-manager.sh` - PR Management

Automated PR review and merging:

```bash
./pr-manager.sh
```

Features:
- Check all PRs status
- Review individual PRs
- Auto-review (approves if CI passes)
- Create omnibus branch (merges all worker branches)
- Create omnibus PR
- Merge to main

### `generate-worker-prompts.sh` - Prompt Generator

Generate optimized prompts for Claude Code:

```bash
./generate-worker-prompts.sh
```

Creates markdown files in `prompts/` that you can copy-paste into Claude Code instances.

## 🚀 Usage Workflows

### Workflow 1: Fully Automated (Recommended)

1. **Initialize**
   ```bash
   ./orchestrator.sh
   # Option 1: Initialize
   ```

2. **Launch workers in tmux**
   ```bash
   for worker in engineer1 engineer2 engineer3 engineer4 qa docs; do
       ./launch-worker.sh $worker
   done
   ```

3. **Monitor progress**
   ```bash
   ./dashboard.py
   ```

4. **When PRs are ready (Day 8)**
   ```bash
   ./pr-manager.sh
   # Option 1: Check all PRs
   # Option 3: Auto-review all
   # Option 4: Create omnibus branch
   # Option 5: Create omnibus PR
   ```

5. **Final merge**
   ```bash
   ./pr-manager.sh
   # Option 6: Merge omnibus to main
   ```

### Workflow 2: Manual Claude Code Instances

1. **Generate prompts**
   ```bash
   ./generate-worker-prompts.sh
   ```

2. **Open 6 Claude Code instances**
   - Copy content from `prompts/engineer1-prompt.md` into Claude instance 1
   - Copy content from `prompts/engineer2-prompt.md` into Claude instance 2
   - etc.

3. **Monitor and coordinate**
   ```bash
   ./dashboard.py  # Monitor progress
   ./orchestrator.sh  # Update checkpoints
   ./pr-manager.sh  # Manage PRs when ready
   ```

### Workflow 3: Hybrid (You as Czar)

1. **You monitor via dashboard**
   ```bash
   ./dashboard.py
   ```

2. **Workers work independently** (tmux or Claude Code)

3. **You review PRs as they come in**
   ```bash
   ./pr-manager.sh
   # Option 2: Review specific PR
   ```

4. **You create omnibus when all ready**
   ```bash
   ./pr-manager.sh
   # Option 4: Create omnibus branch
   ```

5. **You validate and merge**
   ```bash
   # Test omnibus branch
   git checkout feat/gateway-integration-omnibus
   pytest tests/

   # Create and merge PR
   ./pr-manager.sh
   # Option 5: Create omnibus PR
   # Option 6: Merge to main
   ```

## 📊 Monitoring

### Status File

The orchestrator maintains state in `status/master-status.json`:

```json
{
  "project": "SARK v1.1 Gateway Integration",
  "started": "2025-11-27T...",
  "phase": "development",
  "workers": {
    "engineer1": {
      "status": "active",
      "branch": "feat/gateway-client",
      "pr": "https://github.com/.../123"
    },
    ...
  },
  "checkpoints": {
    "day1_models": true,
    "day4_integration": false,
    ...
  }
}
```

### Worker Status Values

- `pending` - Not started
- `launched` - Worker session created
- `active` - Working, commits being made
- `pr_ready` - PR created
- `approved` - PR approved
- `merged` - Merged to omnibus

## 🔧 Troubleshooting

### Workers can't see shared models

```bash
# Worker should merge Engineer 1's branch
git checkout feat/gateway-api
git merge feat/gateway-client
```

### Merge conflicts in omnibus

```bash
git checkout feat/gateway-integration-omnibus
# Fix conflicts
git add <files>
git merge --continue
./pr-manager.sh
# Re-run option 4
```

### Dashboard not working

```bash
pip install rich
./dashboard.py
```

### tmux session won't attach

```bash
tmux ls  # List sessions
tmux kill-session -t sark-worker-engineer1  # Kill if needed
./launch-worker.sh engineer1  # Relaunch
```

## 🎯 Success Criteria

### Individual Worker Success
- [ ] All assigned files created/modified
- [ ] Unit tests >85% coverage
- [ ] Code passes quality checks (mypy, black, ruff)
- [ ] PR created with complete description
- [ ] No P0/P1 security issues

### Integrated System Success
- [ ] All integration tests pass
- [ ] Performance: P95 <50ms, 5000+ req/s
- [ ] Security: 0 vulnerabilities
- [ ] Documentation complete and tested
- [ ] Deployment works on Kubernetes
- [ ] Monitoring operational

## 📚 Additional Resources

- **Kickoff Doc:** `../KICKOFF_v1.1_GATEWAY.md`
- **Implementation Plan:** `../IMPLEMENTATION_PLAN_v1.1_GATEWAY.md`
- **Coordination:** `../docs/gateway-integration/COORDINATION.md`
- **Worker Assignments:** `../docs/gateway-integration/WORKER_ASSIGNMENTS.md`
- **Task Files:** `../docs/gateway-integration/tasks/`

## 🤝 Communication

### As Czar (Orchestrator)

1. **Daily Checkpoints**
   - Review dashboard
   - Check worker progress
   - Unblock workers
   - Update checkpoint status

2. **PR Reviews**
   - Review all PRs as they come in
   - Provide feedback
   - Approve when ready

3. **Integration**
   - Create omnibus branch
   - Resolve merge conflicts
   - Run integration tests
   - Create omnibus PR

4. **Final Merge**
   - Validate everything works
   - Merge to main
   - Tag release
   - Deploy

### Worker Communication

Workers should:
- Post daily status in shared doc
- Report blockers immediately
- Request reviews when ready
- Coordinate dependencies (especially with Engineer 1)

## 🚀 Let's Build!

You're ready to orchestrate 6 parallel Claude Code workers building SARK v1.1!

**Next Steps:**
1. Run `./orchestrator.sh` and initialize
2. Launch all workers
3. Monitor via `./dashboard.py`
4. Review PRs as they come in
5. Create omnibus on Day 8
6. Merge and celebrate! 🎉

---

**Created:** November 27, 2025
**Version:** 1.0
**Status:** Ready for vibecoding! 🎸
