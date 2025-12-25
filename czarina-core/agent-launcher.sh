#!/bin/bash
# Czarina Agent Launcher
# Auto-launches AI agents in worker windows with instructions

set -e

launch_worker_agent() {
  local worker_id="$1"
  local window_index="$2"
  local agent_type="$3"
  local session="$4"

  local worktree_path=".czarina/worktrees/$worker_id"
  local project_root="$(pwd)"

  echo "🚀 Launching $agent_type agent for worker: $worker_id (window $window_index)"

  # Change to worktree
  tmux send-keys -t $session:$window_index "cd $project_root/$worktree_path" C-m
  sleep 1

  # Create worker identity file
  create_worker_identity "$worker_id" "$project_root/$worktree_path"

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

launch_claude() {
  local worker_id="$1"
  local window_index="$2"
  local session="$3"

  local worktree_path=".czarina/worktrees/$worker_id"

  # Configure Claude settings for auto-approval
  mkdir -p "$worktree_path/.claude"
  cat > "$worktree_path/.claude/settings.local.json" << 'EOF'
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

  # Launch Claude with worker context
  tmux send-keys -t $session:$window_index "claude --permission-mode bypassPermissions 'Read WORKER_IDENTITY.md to learn who you are, then read your full instructions at ../workers/$worker_id.md and begin Task 1'" C-m

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
