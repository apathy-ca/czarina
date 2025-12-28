#!/bin/bash
# Czarina Agent Launcher
# Auto-launches AI agents in worker windows with instructions

set -e

# Source context builder functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/context-builder.sh"

launch_worker_agent() {
  local worker_id="$1"
  local window_index="$2"
  local agent_type="$3"
  local session="$4"

  local project_root="$(pwd)"
  local config_path=".czarina/config.json"

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

    # Build enhanced context (rules + memory) if enabled
    if is_context_enhancement_enabled "$worker_id" "$config_path"; then
      echo "  📚 Building enhanced context (rules + memory)..."
      local role=$(get_worker_role "$worker_id" "$config_path")
      local task=$(get_worker_task "$worker_id" "$config_path")
      local context_file=$(build_worker_context "$worker_id" "$role" "$task" "$config_path")

      # Copy context file to worktree
      if [ -f "$context_file" ]; then
        cp "$context_file" "$work_path/.czarina-context.md"
        echo "  ✅ Enhanced context created at .czarina-context.md"
      fi
    fi
  fi

  # Launch appropriate agent
  case "$agent_type" in
    aider)
      launch_aider "$worker_id" "$window_index" "$session"
      ;;
    claude|claude-code)
      launch_claude "$worker_id" "$window_index" "$session"
      ;;
    claude-desktop)
      launch_claude_desktop "$worker_id" "$window_index" "$session"
      ;;
    kilocode)
      launch_kilocode "$worker_id" "$window_index" "$session"
      ;;
    cursor)
      launch_cursor_guide "$worker_id" "$window_index" "$session"
      ;;
    windsurf)
      launch_windsurf_guide "$worker_id" "$window_index" "$session"
      ;;
    copilot|github-copilot)
      launch_copilot_guide "$worker_id" "$window_index" "$session"
      ;;
    chatgpt|chatgpt-code)
      launch_chatgpt_guide "$worker_id" "$window_index" "$session"
      ;;
    codeium)
      launch_codeium_guide "$worker_id" "$window_index" "$session"
      ;;
    *)
      echo "❌ Unknown agent type: $agent_type"
      echo "   Supported: claude, claude-desktop, aider, kilocode, cursor, windsurf, copilot, chatgpt, codeium"
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

    # Check if enhanced context is available
    if [ -f "$work_path/.czarina-context.md" ]; then
      local instructions_prompt="Read WORKER_IDENTITY.md to learn who you are, then read .czarina-context.md for enhanced context (agent rules + project memory), then read your full instructions at ../workers/$worker_id.md and begin Task 1"
    else
      local instructions_prompt="Read WORKER_IDENTITY.md to learn who you are, then read your full instructions at ../workers/$worker_id.md and begin Task 1"
    fi
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

launch_kilocode() {
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

    # Check if enhanced context is available
    if [ -f "$work_path/.czarina-context.md" ]; then
      local instructions_prompt="Read WORKER_IDENTITY.md to learn who you are, then read .czarina-context.md for enhanced context (agent rules + project memory), then read your full instructions at ../workers/$worker_id.md and begin Task 1"
    else
      local instructions_prompt="Read WORKER_IDENTITY.md to learn who you are, then read your full instructions at ../workers/$worker_id.md and begin Task 1"
    fi
  fi

  echo "  ✅ Kilocode will use auto-approve mode (--yolo)"

  # Launch Kilocode with autonomous mode and auto-approve
  # --auto: Run in autonomous mode (non-interactive)
  # --yolo: Auto-approve all tool permissions
  # --workspace: Set working directory
  tmux send-keys -t $session:$window_index "kilocode --auto --yolo --workspace '$work_path' '$instructions_prompt'" C-m

  echo "  ✅ Launched Kilocode for $worker_id"
}

launch_aider() {
  local worker_id="$1"
  local window_index="$2"
  local session="$3"

  local worktree_path=".czarina/worktrees/$worker_id"

  # Create aider startup commands
  if [ -f "$worktree_path/.czarina-context.md" ]; then
    # Include enhanced context if available
    cat > "$worktree_path/.aider-init" << EOF
/add ../workers/$worker_id.md
/add .czarina-context.md
/ask You are the $worker_id worker. First read .czarina-context.md for enhanced context (agent rules + project memory), then read your instructions in ../workers/$worker_id.md and begin with Task 1.
EOF
  else
    # Standard initialization
    cat > "$worktree_path/.aider-init" << EOF
/add ../workers/$worker_id.md
/ask You are the $worker_id worker. Read your instructions in the file I just added and begin with Task 1.
EOF
  fi

  echo "  ✅ Created aider init file for $worker_id"

  # Launch aider with auto-yes and init file
  tmux send-keys -t $session:$window_index "aider --yes-always --load .aider-init" C-m

  echo "  ✅ Launched aider for $worker_id"
}

launch_claude_desktop() {
  local worker_id="$1"
  local window_index="$2"
  local session="$3"

  local work_path=".czarina/worktrees/$worker_id"

  echo "⚠️  Claude Desktop requires manual launch (desktop application)"
  echo ""
  echo "📋 Instructions for $worker_id:"
  echo "   1. Open Claude Desktop application"
  echo "   2. Navigate to: $work_path"
  echo "   3. Send this prompt:"
  echo ""
  if [ -f "$work_path/.czarina-context.md" ]; then
    echo "      Read WORKER_IDENTITY.md, then .czarina-context.md for enhanced context,"
    echo "      then ../workers/$worker_id.md and begin Task 1"
  else
    echo "      Read WORKER_IDENTITY.md, then ../workers/$worker_id.md and begin Task 1"
  fi
  echo ""
}

launch_cursor_guide() {
  local worker_id="$1"
  local window_index="$2"
  local session="$3"

  local work_path=".czarina/worktrees/$worker_id"

  echo "⚠️  Cursor requires manual launch (GUI application)"
  echo ""
  echo "📋 Instructions for $worker_id:"
  echo "   1. Open Cursor IDE"
  echo "   2. Open workspace: $work_path"
  echo "   3. Open Cursor Chat and reference files with @:"
  echo ""
  if [ -f "$work_path/.czarina-context.md" ]; then
    echo "      @WORKER_IDENTITY.md @.czarina-context.md @../workers/$worker_id.md"
    echo ""
    echo "      First read the context file for agent rules and memory,"
    echo "      then follow the worker instructions and begin Task 1."
  else
    echo "      @WORKER_IDENTITY.md @../workers/$worker_id.md"
    echo ""
    echo "      Follow the worker instructions exactly and begin Task 1."
  fi
  echo ""
}

launch_windsurf_guide() {
  local worker_id="$1"
  local window_index="$2"
  local session="$3"

  local work_path=".czarina/worktrees/$worker_id"

  echo "⚠️  Windsurf requires manual launch (GUI application)"
  echo ""
  echo "📋 Instructions for $worker_id:"
  echo "   1. Open Windsurf IDE"
  echo "   2. Open workspace: $work_path"
  echo "   3. Use @ to reference files in chat:"
  echo ""
  if [ -f "$work_path/.czarina-context.md" ]; then
    echo "      @WORKER_IDENTITY.md @.czarina-context.md @../workers/$worker_id.md"
    echo ""
    echo "      I am this worker. First read the enhanced context, then begin tasks."
  else
    echo "      @WORKER_IDENTITY.md @../workers/$worker_id.md"
    echo ""
    echo "      I am this worker. Follow the prompt and begin tasks."
  fi
  echo ""
}

launch_copilot_guide() {
  local worker_id="$1"
  local window_index="$2"
  local session="$3"

  local work_path=".czarina/worktrees/$worker_id"

  echo "⚠️  GitHub Copilot requires manual setup (VS Code/IDE)"
  echo ""
  echo "📋 Instructions for $worker_id:"
  echo "   1. Open VS Code or supported IDE"
  echo "   2. Open workspace: $work_path"
  echo "   3. Open Copilot Chat and send:"
  echo ""
  if [ -f "$work_path/.czarina-context.md" ]; then
    echo "      Read WORKER_IDENTITY.md, .czarina-context.md, and ../workers/$worker_id.md"
    echo "      First review the enhanced context, then follow worker instructions."
  else
    echo "      Read WORKER_IDENTITY.md and ../workers/$worker_id.md"
    echo "      Follow the worker instructions exactly."
  fi
  echo ""
}

launch_chatgpt_guide() {
  local worker_id="$1"
  local window_index="$2"
  local session="$3"

  local work_path=".czarina/worktrees/$worker_id"

  echo "⚠️  ChatGPT Code Interpreter requires manual setup (web/desktop)"
  echo ""
  echo "📋 Instructions for $worker_id:"
  echo "   1. Open ChatGPT with Code Interpreter enabled"
  echo "   2. Upload or reference repository files"
  echo "   3. Send this prompt:"
  echo ""
  if [ -f "$work_path/.czarina-context.md" ]; then
    echo "      Read files: WORKER_IDENTITY.md, .czarina-context.md, ../workers/$worker_id.md"
    echo "      Review the context for agent rules and memory, then begin tasks."
  else
    echo "      Read files: WORKER_IDENTITY.md, ../workers/$worker_id.md"
    echo "      Follow the worker prompt exactly."
  fi
  echo ""
  echo "   Note: You may need to copy/paste file contents directly"
  echo ""
}

launch_codeium_guide() {
  local worker_id="$1"
  local window_index="$2"
  local session="$3"

  local work_path=".czarina/worktrees/$worker_id"

  echo "⚠️  Codeium requires manual setup (IDE extension)"
  echo ""
  echo "📋 Instructions for $worker_id:"
  echo "   1. Open your IDE with Codeium extension"
  echo "   2. Open workspace: $work_path"
  echo "   3. Use Codeium chat to send:"
  echo ""
  if [ -f "$work_path/.czarina-context.md" ]; then
    echo "      Read WORKER_IDENTITY.md, .czarina-context.md, and ../workers/$worker_id.md"
    echo "      Review enhanced context, then act as the worker and begin tasks."
  else
    echo "      Read WORKER_IDENTITY.md and ../workers/$worker_id.md"
    echo "      Act as this worker and begin tasks."
  fi
  echo ""
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
