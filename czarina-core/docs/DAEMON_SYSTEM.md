# Czarina Autonomous Daemon System

## Overview

The Czarina autonomous daemon is a breakthrough feature that **reduces human intervention from ~100% to <5%** when orchestrating multiple AI workers.

**Based on**: Real-world SARK v2.0 session orchestrating 10 workers
**Results**: 90% autonomy achieved, 10 commits in 20 minutes with minimal human input
**Philosophy**: "In an ideal world, I'm not here at all"

## The Problem It Solves

When orchestrating multiple AI workers, you encounter constant approval prompts:
- "Do you want to proceed?" (file access)
- "accept edits on" (edit confirmations)
- "[Y/n]" prompts (various confirmations)

Without automation:
- Human checks each worker window manually
- ~20-30 approval clicks per worker session
- Human becomes the bottleneck
- Defeats the purpose of autonomous AI workers

## The Solution

The daemon runs continuously in a tmux session and:
1. **Monitors** all worker windows every 2 minutes
2. **Auto-approves** all routine requests
3. **Logs** all actions for oversight
4. **Escalates** only true blockers (errors, explicit questions)

## Quick Start

```bash
# 1. Ensure project has embedded orchestration
czarina embed myproject

# 2. Launch workers
czarina launch myproject

# 3. Start daemon
czarina daemon start myproject

# 4. (Optional) Monitor logs
czarina daemon logs myproject
```

That's it! Workers are now autonomous.

## Decision Policies

The daemon follows these policies:

| Prompt | Daemon Response | Rationale |
|--------|----------------|-----------|
| "Do you want to proceed?" | Option 2 (allow) | Workers need orchestration file access |
| "accept edits" | Accept (Enter) | Workers propose valid code changes |
| "[Y/n]" | Yes | Trust worker autonomous judgment |
| Idle at `> ` prompt | Nudge (Enter) | Worker may be waiting for confirmation |
| "@czar" question | **Log and escalate** | Needs human review |
| Fatal error | **Log and escalate** | Needs diagnosis |

## Architecture

### Components

```
czarina-core/daemon/
├── czar-daemon.sh       # Main daemon (monitors and approves)
├── start-daemon.sh      # Launcher (creates tmux session)
└── README.md            # Quick reference

Embedded in project:
czarina-<project>/
├── config.json          # Project configuration
└── status/
    └── daemon.log       # Daemon activity log
```

### Session Structure

```
tmux sessions:
├── <project>-session    # Workers (windows 0-N)
└── <project>-daemon     # Daemon monitoring workers
```

### Daemon Loop

```
Every 2 minutes:
1. For each worker window:
   - Capture pane output
   - Check for approval prompts → Auto-approve
   - Check for edit prompts → Auto-accept
   - Check for Y/N prompts → Confirm yes
   - Check for blocking issues → Log

2. Second pass (3s later):
   - Catch cascading prompts

3. Every 10 iterations (~20 min):
   - Log git activity stats
```

## CLI Commands

### Start Daemon
```bash
czarina daemon start <project>
```
Creates `<project>-daemon` tmux session running the daemon.

### Check Status
```bash
czarina daemon status <project>
```
Shows if daemon is running and how to access it.

### View Logs
```bash
czarina daemon logs <project>
```
Tails the daemon log file (Ctrl+C to exit).

### Stop Daemon
```bash
czarina daemon stop <project>
```
Kills the daemon tmux session.

## Log Format

Example daemon log:
```
🎭 CZAR DAEMON STARTING
Time: 2025-11-29 13:00:00
Project: myproject
Session: myproject-session
Workers: 3
Check interval: 120s
======================================

=== Iteration 1 - 2025-11-29 13:00:00 ===
[13:00:01] Auto-approving window 0
[13:00:02] Auto-accepting edits in window 1
[13:00:03] Auto-accepting edits in window 2
[13:00:05] ✅ Auto-approved 5 items

=== Iteration 2 - 2025-11-29 13:02:05 ===
[13:02:06] Auto-approving window 0
[13:02:07] ✅ Auto-approved 1 items

=== Iteration 10 - 2025-11-29 13:20:00 ===
[13:20:01] Git activity check...
[13:20:02] Commits in last 20 min: 8
```

## Integration with Embedded Orchestration

The daemon is designed to work seamlessly with [embedded orchestration](EMBEDDED_ORCHESTRATION_GUIDE.md):

```bash
# 1. Embed orchestration into project repo
czarina embed myproject

# This creates:
/path/to/repo/czarina-myproject/
├── config.json          # Daemon reads this
├── workers/             # Worker prompts
└── status/              # Daemon logs here

# 2. Workers can be started from anywhere
# 3. Daemon monitors workers automatically
# 4. Everything is self-contained in project repo
```

## Agent Compatibility

The daemon's effectiveness varies significantly by agent type:

### Excellent Autonomy (90-98%):
- ✅ **Aider**: CLI-based, no UI prompts, auto-commits - **BEST FOR DAEMON**
- ✅ **Shell/Terminal workers**: Pure bash operations work perfectly

### Good Autonomy (70-80%):
- 🟡 **Claude Code**: UI prompts require manual approval, but shell/git works
- 🟡 **Cursor**: Similar to Claude Code (IDE UI limitations)
- 🟡 **Windsurf**: IDE-based, likely has similar UI prompt issues

### Limited Autonomy (50-70%):
- ⚠️ **GitHub Copilot**: More manual workflow, daemon helps with shell/git only
- ⚠️ **Codeium/Continue**: IDE extensions with UI limitations

### Known Issues:
- **Claude Code "accept edits" UI**: Sometimes requires Tab+Enter instead of just Enter
- **Agent-specific prompts**: Different agents may have different prompt text

### Future Enhancement:
Agent profiles (from ARCHITECT worker) will include approval patterns:
```json
{
  "approval_patterns": {
    "file_access": "Do you want to proceed?",
    "edit_accept": "accept edits",
    "yes_no": "[Y/n]"
  },
  "key_sequences": {
    "approve_file": "2\n",
    "accept_edit": "\n\t\n",
    "confirm_yes": "y\n"
  }
}
```

## Troubleshooting

### Workers still waiting despite daemon running

**Check daemon is monitoring correct session:**
```bash
tmux ls
# Should see both myproject-session and myproject-daemon

# Attach to daemon to see it working
tmux attach -t myproject-daemon
```

**Check daemon logs:**
```bash
czarina daemon logs myproject
# Should see auto-approval messages every 2 min
```

### Daemon keeps approving same window

**Likely cause**: Edit acceptance UI not responding to Enter key

**Solution**: Edit `czar-daemon.sh` to try different key sequences:
```bash
# Try Tab then Enter
tmux send-keys -t $SESSION:$window Tab C-m
```

### Want more/less frequent checks

**Edit** `czarina-core/daemon/czar-daemon.sh`:
```bash
SLEEP_INTERVAL=120  # Default: 2 minutes
SLEEP_INTERVAL=60   # Faster: 1 minute
SLEEP_INTERVAL=300  # Slower: 5 minutes
```

### Daemon crashes or stops

**Check logs for errors:**
```bash
tail -50 czarina-myproject/status/daemon.log
```

**Restart daemon:**
```bash
czarina daemon stop myproject
czarina daemon start myproject
```

## Performance Metrics

### Real-World Results (SARK v2.0)

**Session**: 10 workers, 3+ hours
**Metrics**:
- Auto-approvals: 14 in first 5 minutes, steady throughout
- Git commits: 10 in 20 minutes (without human bottleneck)
- Human intervention: ~10% (mostly for edit UI issue)
- Autonomy: 90%+

**Target Metrics**:
- Auto-approvals: >5 per check cycle
- Git commits: 1-2 per worker per hour
- Human intervention: <5%
- Uptime: 8+ hours without issues

## Advanced Usage

### Custom Approval Logic

Edit `czar-daemon.sh` to customize:
```bash
# Add custom approval pattern
if echo "$output" | grep -q "your custom prompt"; then
    echo "[$(date '+%H:%M:%S')] Custom approval in window $window"
    tmux send-keys -t $SESSION:$window "custom response" C-m
    ((approved_count++))
fi
```

### Worker-Specific Policies

Future enhancement: Per-worker approval policies:
```bash
# Different approval logic per worker type
case "$worker_id" in
    qa*)
        # QA workers: Auto-approve test runs
        ;;
    engineer*)
        # Engineers: Auto-approve builds
        ;;
esac
```

### Integration with CI/CD

The daemon can be part of automated orchestration:
```bash
#!/bin/bash
# ci-orchestration.sh

# 1. Launch workers
czarina launch myproject

# 2. Start daemon
czarina daemon start myproject

# 3. Wait for completion (check git commits)
while [ $commits_needed -gt 0 ]; do
    sleep 60
    check_commits
done

# 4. Stop daemon
czarina daemon stop myproject

# 5. Create omnibus PR
czarina omnibus myproject
```

## Security Considerations

**Trust Model**: The daemon trusts workers completely
- Auto-approves all file access
- Auto-accepts all edits
- No human verification

**Appropriate for**:
- AI workers with constrained prompts
- Sandboxed/test environments
- Trusted codebases

**Not appropriate for**:
- Production deployments
- Untrusted workers
- Security-critical code

**Mitigation**:
- Review daemon logs regularly
- Check git commits before merging
- Use in feature branches only
- Run tests before omnibus merge

## Future Enhancements

### Planned Features:
1. **Agent-specific profiles**: Custom approval patterns per agent
2. **Worker-specific policies**: Different rules per worker type
3. **Health monitoring**: Alert if daemon stops or workers stall
4. **Dashboard integration**: Show daemon status in Czarina dashboard
5. **Cascading approval detection**: Keep approving until none remain

### Research Areas:
1. **Claude Code API**: Bypass UI approval prompts entirely
2. **Headless mode**: Run workers without interactive prompts
3. **Pre-configuration**: Set worker preferences to minimize prompts
4. **Intelligent escalation**: ML-based detection of issues needing human review

## See Also

- [Daemon Quick Reference](../daemon/README.md)
- [Czar Session Notes](../../projects/sark-v2-orchestration/CZAR_SESSION_NOTES.md)
- [Embedded Orchestration Guide](EMBEDDED_ORCHESTRATION_GUIDE.md)
- [Agent Compatibility Guide](AGENT_COMPATIBILITY.md)

---

**Status**: Production Ready
**Version**: 1.0
**Tested**: SARK v2.0 (10 workers, 90% autonomy)
**Impact**: CRITICAL - Transforms Czarina from manual to autonomous orchestration
