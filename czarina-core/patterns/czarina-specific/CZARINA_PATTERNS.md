# Czarina-Specific Development Patterns

**Battle-tested patterns from real multi-agent orchestration sessions**

> *"My workflow repo is my friend, it is my life. I must master it as I must master my life."*

---

## 🎯 Purpose

These patterns are **Czarina-specific** - learned from actual multi-agent orchestration sessions, not from single-agent development. They complement the upstream patterns with multi-agent workflows.

**Source**: SARK v2.0 (10 workers), Multi-agent support development, Daemon system sessions

---

## 🎭 Multi-Agent Orchestration Patterns

### Pattern: Worker Role Boundaries

**Situation**: Workers stepping on each other's toes

**Root Cause**: Unclear role boundaries or overlapping responsibilities

**Solution**:
1. Define clear worker roles in prompts
2. Use branch-per-worker isolation
3. Document which files each worker owns
4. Include role boundaries in worker prompts

**Example** (from SARK v2.0):
```markdown
# Worker: ENGINEER-1-LEAD_ARCHITECT
Role: Lead architect - system design and integration
Responsibilities:
- Core architecture decisions
- API design
- Integration patterns
Files: src/core/, docs/ARCHITECTURE.md
NOT responsible for: Tests, documentation, deployment
```

**Prevention**:
- Clear role definitions in config.json
- Worker-specific file patterns
- Regular worker status checks

### Pattern: Worker Communication

**Situation**: Workers need to share information but can't directly communicate

**Root Cause**: Isolated tmux sessions, no shared state

**Solution**:
1. Use shared files for communication (status/, handoff/)
2. Czar monitors and relays information
3. Git commits serve as communication channel
4. Status dashboard shows worker progress

**Example** (from SARK v2.0):
```bash
# Workers write status to shared location
echo "ARCHITECT: Core design complete, ready for implementation" > status/architect.txt

# Other workers read status before starting
cat status/architect.txt
```

**Prevention**:
- Establish communication channels upfront
- Use status/ directory for worker updates
- Czar actively monitors and coordinates

### Pattern: Merge Conflict Hell

**Situation**: Multiple workers editing same files causes merge conflicts

**Root Cause**: No file ownership, workers editing overlapping code

**Solution**:
1. Assign file ownership to specific workers
2. Use module boundaries to reduce overlap
3. Merge frequently to main to catch conflicts early
4. Czar coordinates file access

**Example** (from Multi-Agent Support):
```json
{
  "workers": [
    {"role": "architect", "files": ["docs/", "src/core/"]},
    {"role": "backend", "files": ["src/services/"]},
    {"role": "frontend", "files": ["src/ui/"]}
  ]
}
```

**Prevention**:
- Clear file ownership in config
- Modular architecture
- Small, focused workers
- Frequent integration

---

## ⚡ Daemon System Patterns

### Pattern: Claude Code UI Prompts

**Situation**: Daemon can't auto-approve Claude Code's UI dialogs

**Root Cause**: Claude Code intercepts keyboard at UI layer before tmux

**Recovery Strategy**:
1. Accept 70-80% autonomy with Claude Code
2. Use Aider for 95-98% autonomy
3. Hybrid: Claude Code for human workers, Aider for autonomous workers
4. Periodically approve Claude Code workers manually

**Real Data** (from SARK Session 3):
- Claude Code: 70-80% autonomy with daemon
- Aider: 95-98% autonomy with daemon
- Windsurf: 85-95% autonomy with daemon

**Prevention**:
- Choose agent based on autonomy needs
- Document which agents work best with daemon
- Set expectations for manual intervention

### Pattern: Daemon Verification Loop

**Situation**: Daemon approves but worker still stuck

**Root Cause**: Approval didn't actually work, need verification

**Solution**:
1. Daemon sends approval (tmux send-keys)
2. Sleep 0.5s
3. Capture pane again
4. Check if prompt still there
5. If stuck, flag to alerts.json

**Example** (from SARK daemon-v2):
```bash
# Try approval
tmux send-keys -t $SESSION:$window "1" C-m

# Verify it worked
sleep 0.5
output_check=$(tmux capture-pane -t $SESSION:$window -p)
if echo "$output_check" | grep -q "Do you want to proceed?"; then
    # Still stuck - flag it
    echo "{\"window\": $window, \"status\": \"stuck\"}" >> alerts.json
fi
```

**Prevention**:
- Always verify approvals worked
- Alert system for stuck workers
- Dashboard for visual status

---

## 🔀 Git Workflow Patterns

### Pattern: Branch Per Worker

**Situation**: Need isolation but also integration

**Root Cause**: Multiple workers editing same codebase

**Solution**:
```
main
├── worker/architect
├── worker/backend
├── worker/frontend
└── worker/tests
```

**Workflow**:
1. Each worker on own branch
2. Workers commit frequently
3. Create PRs when task complete
4. Human reviews and merges
5. Workers pull latest main regularly

**Prevention**:
- Automated branch creation
- Branch naming convention: `worker/<role>`
- PR template for worker submissions
- Merge frequently to avoid divergence

### Pattern: Commit Message Standards

**Situation**: Worker commits are unclear or inconsistent

**Root Cause**: No commit message guidelines

**Solution**:
```bash
# Worker commits should include:
# 1. What changed
# 2. Why it changed
# 3. Worker attribution

git commit -m "Add user authentication service

Implements JWT-based authentication for API endpoints.
Includes login, logout, and token refresh.

Worker: ENGINEER-2
Task: Authentication system
"
```

**Prevention**:
- Commit message template in worker prompts
- Czar reviews commit quality
- Document standards in .cursorrules

---

## 📊 Monitoring Patterns

### Pattern: Worker Health Detection

**Situation**: Need to know if workers are stuck/idle/working

**Root Cause**: No visibility into worker status

**Solution**:
1. Regular tmux pane captures
2. Pattern matching for stuck states
3. Alert system for attention needed
4. Visual dashboard for status

**Stuck Patterns**:
```bash
# Patterns indicating stuck worker
"Do you want to proceed? (y/n)"
"Command failed with error"
"CONFLICT (content): Merge conflict"
"(waiting for input)"
```

**Example** (from SARK status dashboard):
```bash
# Capture worker output
output=$(tmux capture-pane -t $session:0 -p)

# Check for stuck patterns
if echo "$output" | grep -q "Do you want to proceed?"; then
    status="⚠️ NEEDS APPROVAL"
elif echo "$output" | grep -q "CONFLICT"; then
    status="🚨 MERGE CONFLICT"
else
    status="✅ WORKING"
fi
```

**Prevention**:
- Regular monitoring (every 30s)
- Alert thresholds (stuck >5min)
- Dashboard for quick visual status

---

## 🎯 Autonomy Patterns

### Pattern: Auto-Approval Strategy

**Situation**: Workers need constant approvals, slows down work

**Root Cause**: AI agents ask for permission frequently

**Smart Approval Strategy**:
```bash
# Auto-approve: ✅
- File reads
- File edits (in worker's domain)
- Git operations (commit, pull)
- Test runs
- Build commands

# Require approval: ⚠️
- Deletions
- Push to main
- Changes outside worker domain
- Destructive operations

# Never approve: 🚨
- Force push
- Database modifications
- Credential changes
```

**Implementation**:
```bash
# Detect number of options
if echo "$output" | grep -q "1).*2).*3)"; then
    # 3 options - likely read/write/cancel
    approval="2"  # Choose write
elif echo "$output" | grep -q "1).*2)"; then
    # 2 options - likely yes/no
    approval="1"  # Choose yes
fi
```

**Prevention**:
- Document approval rules clearly
- Train workers to minimize prompts
- Use Aider for fewer prompts

---

## 💡 Worker Selection Patterns

### Pattern: Choose the Right Agent

**Situation**: Need to pick best agent for task

**Decision Matrix**:
```
Task Type              Best Agent        Why
─────────────────────  ───────────────  ──────────────────────
Full autonomy          Aider            95-98% daemon success
Desktop interaction    Claude Code      Best UI, 70-80% daemon
VS Code users          Cursor           Familiar, 80-90% daemon
AI-native IDE          Windsurf         Cascade mode, 85-95%
Local/free             Continue.dev     Supports local LLMs
Manual oversight       Human            100% control, 0% autonomy
```

**Real Data** (from Czarina testing):
- Aider: Best for daemon, CLI-based, auto-commits
- Claude Code: Best for humans, great UI, some daemon limitations
- Cursor: Good middle ground, familiar to VS Code users

**Prevention**:
- Match agent to autonomy needs
- Document agent capabilities
- Test agents before large sessions

---

## 🔧 Troubleshooting Patterns

### Pattern: Worker Won't Start

**Error**: Worker tmux session fails to launch

**Root Causes**:
1. Agent not installed
2. Wrong agent path in profile
3. Missing dependencies
4. Config errors

**Recovery**:
```bash
# 1. Check agent installed
which claude  # or aider, cursor, etc.

# 2. Check agent profile
cat agents/profiles/claude-code.json

# 3. Test agent directly
claude --version

# 4. Check worker config
cat czarina-<project>/config.json
```

**Prevention**:
- Validate agent installation in init
- Clear error messages
- Agent compatibility checks

### Pattern: Daemon Not Auto-Approving

**Error**: Daemon running but not approving workers

**Root Causes**:
1. Session name mismatch
2. Daemon can't find workers
3. Approval pattern not matching

**Recovery**:
```bash
# 1. Check daemon logs
tail -f czarina-<project>/status/daemon.log

# 2. Verify session name
tmux ls | grep czarina

# 3. Test approval pattern
tmux capture-pane -t czarina-project:0 -p | grep "Do you want"

# 4. Restart daemon
./czarina daemon stop project
./czarina daemon start project
```

**Prevention**:
- Consistent session naming
- Pattern testing before sessions
- Daemon health checks

---

## 📈 Success Metrics

**From SARK v2.0** (10 workers):
- ✅ 90% autonomy with daemon
- ✅ 3-4x speedup over sequential
- ✅ 10 workers collaborating effectively
- ✅ Alert system catches stuck workers in <1min

**From Multi-Agent Support** (3 workers):
- ✅ Agent-agnostic architecture working
- ✅ Seamless switching between Claude Code and Aider
- ✅ Clean integration via PRs

---

## 🔄 Pattern Evolution

**These patterns evolve!**

Found a new pattern during a session? **Use the inbox:**
```bash
cp czarina-inbox/templates/FIX_DONE.md \
   czarina-inbox/fixes/$(date +%Y-%m-%d)-new-pattern.md
```

**Good patterns to document:**
- Solutions that saved >30 minutes
- Non-obvious workarounds
- Multi-agent coordination strategies
- Automation improvements
- Agent-specific quirks

**Not worth documenting:**
- One-off issues
- Obvious solutions
- Project-specific hacks

---

## 🔗 Related Patterns

**Upstream patterns** (from agentic-dev-patterns):
- [ERROR_RECOVERY_PATTERNS.md](../ERROR_RECOVERY_PATTERNS.md) - Single-agent errors
- [MODE_CAPABILITIES.md](../MODE_CAPABILITIES.md) - Agent role boundaries
- [TOOL_USE_PATTERNS.md](../TOOL_USE_PATTERNS.md) - Efficient tool usage

**Czarina docs**:
- [DAEMON_SYSTEM.md](../../docs/DAEMON_SYSTEM.md) - Daemon architecture
- [DAEMON_LIMITATIONS.md](../../docs/DAEMON_LIMITATIONS.md) - Known limitations
- [SUPPORTED_AGENTS.md](../../../docs/guides/SUPPORTED_AGENTS.md) - Agent comparison

---

**Pattern Version:** 1.0.0
**Last Updated:** 2025-11-30
**Source:** Real Czarina sessions (SARK v2.0, Multi-agent support)
**Effectiveness:** Proven in production

---

> **"Without me, my repo is useless. Without my repo, I am useless."**
>
> *These patterns are my repo. Learn them. Master them. Evolve them.*
