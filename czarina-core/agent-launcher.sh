#!/bin/bash
# Czarina Agent Launcher
# Auto-launches AI agents in worker windows with instructions

set -e

launch_worker_agent() {
  local worker_id="$1"
  local window_index="$2"
  local agent_type="$3"
  local session="$4"

  local project_root="$(pwd)"

  echo "🚀 Launching $agent_type agent for: $worker_id (window $window_index)"

  # Czar runs from project root, workers run from worktrees
  if [ "$worker_id" == "czar" ]; then
    local work_path="$project_root"
    # Czar stays in project root
    create_czar_identity "$work_path"
  else
    local worktree_path=".czarina/worktrees/$worker_id"
    local work_path="$project_root/$worktree_path"
    # Change to worktree
    tmux send-keys -t $session:$window_index "cd $work_path" C-m
    sleep 1
    # Create worker identity file
    create_worker_identity "$worker_id" "$work_path"
  fi

  # Launch appropriate agent
  case "$agent_type" in
    aider)
      launch_aider "$worker_id" "$window_index" "$session"
      ;;
    claude)
      launch_claude "$worker_id" "$window_index" "$session"
      ;;
    cursor)
      echo "⚠️  Cursor requires manual launch (GUI application)"
      echo "   Worker $worker_id window: $window_index"
      ;;
    *)
      echo "❌ Unknown agent type: $agent_type"
      return 1
      ;;
  esac
}

create_worker_identity() {
  local worker_id="$1"
  local worktree_path="$2"

  local config_path=".czarina/config.json"
  local worker_desc=$(jq -r ".workers[] | select(.id == \"$worker_id\") | .description" $config_path)
  local worker_branch=$(jq -r ".workers[] | select(.id == \"$worker_id\") | .branch" $config_path)
  local worker_deps=$(jq -r ".workers[] | select(.id == \"$worker_id\") | .dependencies[]" $config_path 2>/dev/null)

  if [ -z "$worker_deps" ]; then
    worker_deps="None"
  fi

  cat > "$worktree_path/WORKER_IDENTITY.md" << EOF
# Worker Identity: $worker_id

You are the **$worker_id** worker in this czarina orchestration.

## Your Role
$worker_desc

## Your Instructions
Full task list: \$(pwd)/../workers/$worker_id.md

Read it now:
\`\`\`bash
cat ../workers/$worker_id.md | less
\`\`\`

Or use this one-liner to start:
\`\`\`bash
cat ../workers/$worker_id.md
\`\`\`

## Quick Reference
- **Branch:** $worker_branch
- **Location:** $worktree_path
- **Dependencies:** $worker_deps

## Logging

You have structured logging available. Use these commands:

\`\`\`bash
# Source logging functions (if not already available)
source \$(git rev-parse --show-toplevel)/czarina-core/logging.sh

# Log your progress
czarina_log_task_start "Task 1.1: Description"
czarina_log_checkpoint "feature_implemented"
czarina_log_task_complete "Task 1.1: Description"

# When all tasks done
czarina_log_worker_complete
\`\`\`

**Your logs:**
- Worker log: \${CZARINA_WORKER_LOG}
- Event stream: \${CZARINA_EVENTS_LOG}

**Log important milestones:**
- Task starts
- Checkpoints (after commits)
- Task completions
- Worker completion

This helps the Czar monitor your progress!

## Your Mission
1. Read your full instructions at ../workers/$worker_id.md
2. Understand your deliverables and success metrics
3. Begin with Task 1
4. Follow commit checkpoints in the instructions
5. Log your progress (when logging system is ready)

Let's build this! 🚀
EOF

  echo "  ✅ Created WORKER_IDENTITY.md for $worker_id"
}

create_czar_identity() {
  local project_root="$1"
  local config_path=".czarina/config.json"

  local project_name=$(jq -r '.project.name' $config_path)
  local worker_count=$(jq '.workers | length' $config_path)

  cat > "$project_root/.czarina/CZAR_IDENTITY.md" << EOF
# Czar Identity: Orchestration Coordinator

You are the **Czar** - the orchestration coordinator for this czarina project.

## Your Role

**Project:** $project_name
**Workers:** $worker_count
**Session:** Current tmux session

## Your Responsibilities

### 1. Monitor Worker Progress
- Track completion of worker tasks
- Identify blockers and dependencies
- Coordinate handoffs between workers
- Review worker logs for status

### 2. Manage Integration
- Review PRs from workers as they complete
- Coordinate merges when dependencies are met
- Ensure integration tests pass
- Resolve conflicts

### 3. Track Project Health
- Monitor test coverage and quality
- Watch for conflicts or duplicate work
- Keep project documentation updated
- Verify deliverables meet success criteria

### 4. Coordinate Communication
- Facilitate cross-worker discussions
- Escalate issues that need user input
- Document decisions and changes

## Quick Commands

### Tmux Navigation
\`\`\`bash
# Switch to worker windows
Ctrl+b 1    # Worker 1
Ctrl+b 2    # Worker 2
# ... etc
Ctrl+b 0    # Back to Czar (you!)

# List windows
Ctrl+b w

# Switch sessions
Ctrl+b s    # Main session <-> Management session

# Detach
Ctrl+b d
\`\`\`

### Git Status
\`\`\`bash
# Check all worker branches
cd .czarina/worktrees
for worker in */ ; do
    echo "=== \$worker ==="
    cd \$worker && git status --short && cd ..
done
\`\`\`

### Monitor Progress
\`\`\`bash
# View all worker logs (if using structured logging)
tail -f .czarina/logs/*.log

# Check worker status
czarina status

# View event stream
cat .czarina/logs/events.jsonl | tail -20
\`\`\`

## Your Mission

Keep this multi-agent project running smoothly. You're the glue that holds it together!

1. **Stay informed** - Monitor worker windows and logs
2. **Stay proactive** - Catch issues early
3. **Stay coordinated** - Facilitate collaboration
4. **Stay focused** - Keep everyone aligned on goals

Good luck, Czar! 🎭
EOF

  echo "  ✅ Created CZAR_IDENTITY.md"
}

launch_claude() {
  local worker_id="$1"
  local window_index="$2"
  local session="$3"

  # Czar runs from project root, workers from worktrees
  if [ "$worker_id" == "czar" ]; then
    local work_path="."
    local identity_file=".czarina/CZAR_IDENTITY.md"
    local instructions_prompt="Read .czarina/CZAR_IDENTITY.md to understand your role as Czar, then monitor worker progress and coordinate integration."
  else
    local work_path=".czarina/worktrees/$worker_id"
    local identity_file="WORKER_IDENTITY.md"
    local instructions_prompt="Read WORKER_IDENTITY.md to learn who you are, then read your full instructions at ../workers/$worker_id.md and begin Task 1"
  fi

  # Configure Claude settings for auto-approval
  mkdir -p "$work_path/.claude"
  cat > "$work_path/.claude/settings.local.json" << 'EOF'
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
EOF

  echo "  ✅ Created Claude settings for $worker_id"

  # Launch Claude with context-specific prompt
  tmux send-keys -t $session:$window_index "claude --permission-mode bypassPermissions '$instructions_prompt'" C-m

  echo "  ✅ Launched Claude for $worker_id"
}

launch_aider() {
  local worker_id="$1"
  local window_index="$2"
  local session="$3"

  local worktree_path=".czarina/worktrees/$worker_id"

  # Create aider startup commands
  cat > "$worktree_path/.aider-init" << EOF
/add ../workers/$worker_id.md
/ask You are the $worker_id worker. Read your instructions in the file I just added and begin with Task 1.
EOF

  echo "  ✅ Created aider init file for $worker_id"

  # Launch aider with auto-yes and init file
  tmux send-keys -t $session:$window_index "aider --yes-always --load .aider-init" C-m

  echo "  ✅ Launched aider for $worker_id"
}

# Main execution
case "$1" in
  launch)
    if [ $# -lt 4 ]; then
      echo "Usage: $0 launch <worker-id> <window-index> <agent-type> <session-name>"
      exit 1
    fi

    launch_worker_agent "$2" "$3" "$4" "$5"
    ;;

  *)
    echo "Czarina Agent Launcher"
    echo ""
    echo "Usage:"
    echo "  $0 launch <worker-id> <window-index> <agent-type> <session-name>"
    echo ""
    echo "Example:"
    echo "  $0 launch foundation 1 claude czarina-project"
    exit 1
    ;;
esac
