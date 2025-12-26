# Auto-Launch Agent System

## Overview

The Auto-Launch Agent System automatically starts AI agents (Claude Code, Aider, Cursor) in worker windows with instructions pre-loaded. **Zero manual setup required!**

**Before v0.5.1:**
```bash
czarina launch
# Then manually:
# 1. Switch to each tmux window
# 2. Start the AI agent (claude/aider/cursor)
# 3. Paste worker instructions
# 4. Enable auto-approval
# 18 manual steps for 6 workers!
```

**After v0.5.1:**
```bash
czarina launch  # Done! All agents auto-start with instructions
```

## Features

- **Automatic Agent Launch** - Claude, Aider, or Cursor starts automatically
- **Pre-loaded Instructions** - Worker reads their task file on startup
- **Auto-Approval Configured** - Claude and Aider set up with bypass permissions
- **Worker Identity** - Each worker gets a `WORKER_IDENTITY.md` file with context
- **Zero Manual Steps** - From 18 steps to 0 steps

## How It Works

### 1. Worker Configuration

In your `.czarina/config.json`, specify the agent type for each worker:

```json
{
  "workers": [
    {
      "id": "foundation",
      "agent": "claude",
      "branch": "feat/foundation",
      "description": "Set up core infrastructure",
      "dependencies": []
    },
    {
      "id": "api-worker",
      "agent": "aider",
      "branch": "feat/api",
      "description": "Build REST API",
      "dependencies": ["foundation"]
    }
  ]
}
```

**Supported agent types:**
- `claude` - Claude Code CLI with bypassPermissions mode
- `aider` - Aider with `--yes-always` auto-approval
- `cursor` - Manual launch (GUI application)
- `null` or omit - No auto-launch (manual start)

### 2. Launch Process

When you run `czarina launch`:

1. **Worktree Created** - Git worktree on worker's branch
2. **Window Created** - Tmux window with worker info displayed
3. **Identity File** - `WORKER_IDENTITY.md` created with:
   - Worker ID and role description
   - Path to instructions file
   - Branch and dependency info
   - Quick-start commands
4. **Agent Launched** - AI agent starts automatically:
   - **Claude:** Reads `WORKER_IDENTITY.md`, then instructions, begins Task 1
   - **Aider:** Loads instructions file, asks AI to begin Task 1
   - **Cursor:** Manual launch required (GUI app)

### 3. Worker Identity File

Each worker gets a `WORKER_IDENTITY.md` file:

```markdown
# Worker Identity: foundation

You are the **foundation** worker in this czarina orchestration.

## Your Role
Set up core infrastructure

## Your Instructions
Full task list: $(pwd)/../workers/foundation.md

Read it now:
```bash
cat ../workers/foundation.md | less
```

## Quick Reference
- **Branch:** feat/foundation
- **Location:** .czarina/worktrees/foundation
- **Dependencies:** None

## Your Mission
1. Read your full instructions at ../workers/foundation.md
2. Understand your deliverables and success metrics
3. Begin with Task 1
4. Follow commit checkpoints in the instructions
5. Log your progress (when logging system is ready)

Let's build this!
```

### 4. Auto-Approval Configuration

#### Claude Code

Creates `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(pytest:*)",
      "Bash(test:*)",
      "Bash(npm:*)",
      "Bash(chmod:*)",
      "Bash(mkdir:*)",
      "Read(/**)",
      "Write(/**)",
      "Edit(/**)",
      "Grep(*)",
      "Glob(*)",
      "TodoWrite(*)"
    ]
  }
}
```

Launches with:
```bash
claude --permission-mode bypassPermissions 'Read WORKER_IDENTITY.md...'
```

#### Aider

Creates `.aider-init` file:

```
/add ../workers/foundation.md
/ask You are the foundation worker. Read your instructions in the file I just added and begin with Task 1.
```

Launches with:
```bash
aider --yes-always --load .aider-init
```

## Configuration Options

### Disable Auto-Launch

```bash
# Option 1: Set agent to null in config.json
{
  "workers": [
    {
      "id": "manual-worker",
      "agent": null,  // No auto-launch
      "branch": "feat/manual"
    }
  ]
}

# Option 2: Start agents manually (future flag, not yet implemented)
# czarina launch --no-auto-launch
```

### Disable Auto-Approval (future enhancement)

```bash
# Not yet implemented - planned for future release
# czarina launch --no-auto-approve
```

## Agent Launcher Script

The agent launcher is implemented in `czarina-core/agent-launcher.sh`:

**Usage:**
```bash
./agent-launcher.sh launch <worker-id> <window-index> <agent-type> <session-name>
```

**Example:**
```bash
./agent-launcher.sh launch foundation 1 claude czarina-myproject
```

**Functions:**
- `launch_worker_agent()` - Main launcher
- `create_worker_identity()` - Generates WORKER_IDENTITY.md
- `launch_claude()` - Claude Code specific setup
- `launch_aider()` - Aider specific setup

## Troubleshooting

### Agent didn't launch

**Check 1:** Verify agent is specified in config
```bash
jq '.workers[].agent' .czarina/config.json
```

**Check 2:** Verify agent-launcher.sh exists
```bash
ls czarina-core/agent-launcher.sh
```

**Check 3:** Check tmux pane output
```bash
tmux attach -t czarina-myproject
# Switch to worker window (Ctrl+b <number>)
```

### Agent launched but didn't start task

**Claude:**
- Check `.claude/settings.local.json` exists
- Check permission mode is bypassPermissions
- Verify WORKER_IDENTITY.md was created

**Aider:**
- Check `.aider-init` file exists
- Verify aider is installed: `which aider`
- Check for error messages in window

### Want to restart an agent

```bash
# Attach to session
tmux attach -t czarina-myproject

# Switch to worker window (Ctrl+b <number>)

# Kill current agent (Ctrl+c)

# Restart manually:
# For Claude:
claude --permission-mode bypassPermissions

# For Aider:
aider --yes-always --load .aider-init
```

## Examples

### Example 1: 3-Worker Project with Mixed Agents

```json
{
  "project": {
    "name": "API Platform",
    "slug": "api-platform",
    "repository": "/home/user/projects/api-platform"
  },
  "workers": [
    {
      "id": "backend",
      "agent": "claude",
      "branch": "feat/backend",
      "description": "Build REST API backend"
    },
    {
      "id": "frontend",
      "agent": "aider",
      "branch": "feat/frontend",
      "description": "Build React frontend"
    },
    {
      "id": "docs",
      "agent": null,
      "branch": "feat/docs",
      "description": "Write documentation (manual)"
    }
  ]
}
```

**Result:**
- Window 1 (backend): Claude auto-starts
- Window 2 (frontend): Aider auto-starts
- Window 3 (docs): Manual start (displays instructions)

### Example 2: All Claude Workers

```json
{
  "workers": [
    {"id": "auth", "agent": "claude", "branch": "feat/auth"},
    {"id": "api", "agent": "claude", "branch": "feat/api"},
    {"id": "tests", "agent": "claude", "branch": "feat/tests"}
  ]
}
```

**Result:** All 3 workers auto-start Claude with instructions

## Benefits

**Time Saved:**
- 18 manual steps → 0 steps
- 5-10 minutes setup → 0 seconds
- Zero context switching

**Consistency:**
- All workers get same setup
- No forgotten auto-approval settings
- No copy-paste errors

**Developer Experience:**
- Single command to launch everything
- Workers immediately productive
- Clear instructions from the start

## Future Enhancements

**Planned for v0.6.0:**
- `--no-auto-launch` flag to disable auto-launch
- `--no-auto-approve` flag to disable auto-approval
- Support for more AI agents (Copilot, etc.)
- Custom agent launch commands in config
- Agent health checks and restart

## See Also

- [Worker Patterns](WORKER_PATTERNS.md) - How to structure worker tasks
- [Daemon System](DAEMON.md) - Autonomous monitoring
- [Getting Started](GETTING_STARTED.md) - Quick start guide
- [Migration Guide](../docs/MIGRATION_v0.5.1.md) - Upgrading to v0.5.1
