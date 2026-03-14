#!/bin/bash
# Czarina Agent Launcher
# Auto-launches AI agents in worker windows with instructions

set -e

# Source context builder functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/context-builder.sh"

# Source hopper integration (required)
source "$SCRIPT_DIR/hopper-integration.sh"

launch_worker_agent() {
  local worker_id="$1"
  local window_number="$2"  # Just for display/logging, not used for tmux targeting
  local agent_type="$3"
  local session="$4"

  local project_root="$(pwd)"
  local config_path=".czarina/config.json"

  echo "🚀 Launching $agent_type agent for: $worker_id (window $window_number)"

  # Czar runs from project root, workers run from worktrees
  if [ "$worker_id" == "czar" ]; then
    local work_path="$project_root"
    # Czar stays in project root
    create_czar_identity "$work_path"
  else
    local worktree_path=".czarina/worktrees/$worker_id"
    local work_path="$project_root/$worktree_path"
    # Change to worktree (use worker_id as window name, not window_number)
    tmux send-keys -t "$session:$worker_id" "cd $work_path" C-m
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

  # Mark hopper task as in_progress when worker starts (non-fatal)
  if declare -f hopper_worker_start &>/dev/null && [[ "$worker_id" != "czar" ]]; then
    local czarina_dir="$project_root/.czarina"
    hopper_worker_start "$czarina_dir" "$worker_id" || true
  fi

  # Launch appropriate agent
  case "$agent_type" in
    aider)
      launch_aider "$worker_id" "$session"
      ;;
    opencode)
      launch_opencode "$worker_id" "$session"
      ;;
    claude|claude-code)
      launch_claude "$worker_id" "$session"
      ;;
    claude-desktop)
      launch_claude_desktop "$worker_id" "$session"
      ;;
    kilocode)
      launch_kilocode "$worker_id" "$session"
      ;;
    cursor)
      launch_cursor_guide "$worker_id" "$session"
      ;;
    windsurf)
      launch_windsurf_guide "$worker_id" "$session"
      ;;
    copilot|github-copilot)
      launch_copilot_guide "$worker_id" "$session"
      ;;
    chatgpt|chatgpt-code)
      launch_chatgpt_guide "$worker_id" "$session"
      ;;
    codeium)
      launch_codeium_guide "$worker_id" "$session"
      ;;
    shelley)
      launch_shelley "$worker_id" "$session"
      ;;
    *)
      echo "❌ Unknown agent type: $agent_type"
      echo "   Supported: opencode, claude, claude-desktop, aider, kilocode, cursor, windsurf, copilot, chatgpt, codeium"
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

  # Look up hopper task ID for this worker (required)
  local czarina_dir
  czarina_dir="$(git rev-parse --show-toplevel 2>/dev/null)/.czarina"
  export CZARINA_DIR="$czarina_dir"
  local hopper_task_id
  hopper_task_id=$(hopper_get_worker_task "$worker_id" 2>/dev/null || true)

  if [[ -z "$hopper_task_id" ]]; then
    echo "  ⚠️  No hopper task ID found for $worker_id — WORKER_IDENTITY.md will use file fallback"
  fi

  cat > "$worktree_path/WORKER_IDENTITY.md" << EOF
# Worker Identity: $worker_id

You are the **$worker_id** worker in this czarina orchestration.

## Your Role
$worker_desc

## Quick Reference
- **Branch:** $worker_branch
- **Location:** $worktree_path
- **Dependencies:** $worker_deps

## Your Instructions

Your full brief is stored in hopper. Run this command to read it:

\`\`\`bash
hopper --local task get $hopper_task_id --with-lessons
\`\`\`

Your brief contains your complete task list, deliverables, success criteria,
and any relevant lessons from previous workers on this project.

**Fallback** (if hopper is unavailable):
\`\`\`bash
cat ../workers/$worker_id.md
\`\`\`

## If You Lose Context

Your brief is always in hopper — it survives session crashes and context resets.
To recover after any interruption:

\`\`\`bash
# Find your task
hopper --local task list --tag worker-$worker_id --status in_progress

# Read your full brief
hopper --local task get $hopper_task_id --with-lessons

# Mark yourself back in progress
hopper --local task status $hopper_task_id in_progress --force
\`\`\`

## On Task Completion

Before marking complete, file any lessons learned — patterns discovered, traps
avoided, better approaches found. Future workers will see them automatically.

\`\`\`bash
hopper --local lesson add \\
  --task $hopper_task_id \\
  --title "One line: what was learned" \\
  --domain python \\
  --confidence high \\
  --non-interactive \\
  --body "\$(cat << 'LESSON'
## What Happened
...

## What Was Learned
...

## Why It Matters
...

## Applies To
...
LESSON
)"
\`\`\`

Then mark complete:

\`\`\`bash
hopper --local task status $hopper_task_id completed --force
\`\`\`

## Logging

\`\`\`bash
source \$(git rev-parse --show-toplevel)/czarina-core/logging.sh
czarina_log_task_start "Task 1.1: Description"
czarina_log_checkpoint "feature_implemented"
czarina_log_task_complete "Task 1.1: Description"
czarina_log_worker_complete
\`\`\`

**Your logs:** \${CZARINA_WORKER_LOG} | \${CZARINA_EVENTS_LOG}

---

Let's build this!
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

launch_opencode() {
  local worker_id="$1"
  local session="$2"

  if [ "$worker_id" == "czar" ]; then
    local instructions_prompt="Read .czarina/CZAR_IDENTITY.md to understand your role as Czar, then monitor worker progress and coordinate integration."
  else
    local instructions_prompt="Read WORKER_IDENTITY.md — it contains your hopper task ID and the command to retrieve your full brief. Run that command now to get your complete instructions, then begin Task 1."
  fi

  tmux send-keys -t "$session:$worker_id" "opencode run '$instructions_prompt'" C-m
  echo "  ✅ Launched OpenCode for $worker_id"
}

launch_claude() {
  local worker_id="$1"
  local session="$2"

  local work_path
  if [ "$worker_id" == "czar" ]; then
    work_path="."
  else
    work_path=".czarina/worktrees/$worker_id"
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

  # Launch Claude with context-specific prompt (use worker_id as window name)
  local instructions_prompt
  if [ "$worker_id" == "czar" ]; then
    instructions_prompt="Read .czarina/CZAR_IDENTITY.md to understand your role as Czar, then monitor worker progress and coordinate integration."
  else
    instructions_prompt="Read WORKER_IDENTITY.md — it contains your hopper task ID and the command to retrieve your full brief. Run that command now to get your complete instructions, then begin Task 1."
  fi

  tmux send-keys -t "$session:$worker_id" "claude --permission-mode bypassPermissions '$instructions_prompt'" C-m
  echo "  ✅ Launched Claude for $worker_id"
}

launch_kilocode() {
  local worker_id="$1"
  local session="$2"

  local work_path
  local instructions_prompt
  if [ "$worker_id" == "czar" ]; then
    work_path="."
    instructions_prompt="Read .czarina/CZAR_IDENTITY.md to understand your role as Czar, then monitor worker progress and coordinate integration."
  else
    work_path=".czarina/worktrees/$worker_id"
    instructions_prompt="Read WORKER_IDENTITY.md — it contains your hopper task ID and the command to retrieve your full brief. Run that command now to get your complete instructions, then begin Task 1."
  fi

  echo "  ✅ Kilocode will use auto-approve mode (--yolo)"
  tmux send-keys -t "$session:$worker_id" "kilocode --auto --yolo --workspace '$work_path' '$instructions_prompt'" C-m
  echo "  ✅ Launched Kilocode for $worker_id"
}

launch_aider() {
  local worker_id="$1"
  local session="$2"

  local worktree_path=".czarina/worktrees/$worker_id"

  # Create aider startup commands — hopper-first
  cat > "$worktree_path/.aider-init" << EOF
/add WORKER_IDENTITY.md
/ask Read WORKER_IDENTITY.md — it contains your hopper task ID and the command to retrieve your full brief. Run that command to get your complete instructions, then begin Task 1.
EOF

  echo "  ✅ Created aider init file for $worker_id"

  # Launch aider with auto-yes and init file (use worker_id as window name)
  tmux send-keys -t "$session:$worker_id" "aider --yes-always --load .aider-init" C-m

  echo "  ✅ Launched aider for $worker_id"
}

launch_shelley() {
  local worker_id="$1"
  local session="$2"

  local project_root="$(pwd)"
  local config_path=".czarina/config.json"

  # Get project info
  local project_slug=$(jq -r '.project.slug' "$config_path")
  local worker_branch=$(jq -r ".workers[] | select(.id == \"$worker_id\") | .branch" "$config_path")

  # Czar runs from project root, workers from worktrees
  local work_path instructions_prompt
  if [ "$worker_id" == "czar" ]; then
    work_path="$project_root"
    instructions_prompt="Read .czarina/CZAR_IDENTITY.md to understand your role as Czar, then monitor worker progress and coordinate integration."
  else
    work_path="$project_root/.czarina/worktrees/$worker_id"
    instructions_prompt="Read WORKER_IDENTITY.md — it contains your hopper task ID and the command to retrieve your full brief. Run that command to get your complete instructions, then begin Task 1."
  fi

  # Get hostname for Shelley URL
  local hostname=$(hostname -f 2>/dev/null || hostname)
  if [[ "$hostname" == *.exe.xyz ]]; then
    local shelley_url="https://${hostname}:9999/"
  else
    local shelley_url="http://localhost:9999/"
  fi

  # Create a worker launch script that can be used to start a Shelley conversation
  local launch_script="$work_path/.shelley-launch.sh"
  cat > "$launch_script" << EOF
#!/bin/bash
# Shelley Worker Launch Script for: $worker_id
# Generated by Czarina

echo "🚀 Shelley Worker: $worker_id"
echo "📂 Worktree: $work_path"
echo "🌿 Branch: $worker_branch"
echo ""
echo "📋 Instructions:"
echo "   1. Open Shelley at: $shelley_url"
echo "   2. Start a new conversation"
echo "   3. Send this prompt:"
echo ""
echo "   cd $work_path && cat WORKER_IDENTITY.md"
echo ""
echo "   Then follow the instructions in the identity file."
echo ""
echo "💡 Or copy this one-liner:"
echo "   cd $work_path && $instructions_prompt"
EOF
  chmod +x "$launch_script"

  # Create a conversation slug file for tracking
  echo "czarina-${project_slug}-${worker_id}" > "$work_path/.shelley-conversation-slug"

  echo "  ✅ Shelley worker configured: $worker_id"
  echo ""
  echo "  🌐 Open Shelley: $shelley_url"
  echo "  📂 Worktree: $work_path"
  echo "  🌿 Branch: $worker_branch"
  echo ""
  echo "  📋 Start a new conversation and send:"
  echo "     cd $work_path && cat WORKER_IDENTITY.md"
  echo ""
  echo "  💡 Then follow the instructions in the identity file."
}

launch_claude_desktop() {
  local worker_id="$1"
  local session="$2"

  local work_path=".czarina/worktrees/$worker_id"

  echo "⚠️  Claude Desktop requires manual launch (desktop application)"
  echo ""
  echo "📋 Instructions for $worker_id:"
  echo "   1. Open Claude Desktop application"
  echo "   2. Navigate to: $work_path"
  echo "   3. Send this prompt:"
  echo ""
  echo "      Read WORKER_IDENTITY.md — it contains your hopper task ID and the"
  echo "      command to retrieve your full brief. Run that command to get your"
  echo "      complete instructions, then begin Task 1."
  echo ""
}

launch_cursor_guide() {
  local worker_id="$1"
  local session="$2"

  local work_path=".czarina/worktrees/$worker_id"

  echo "⚠️  Cursor requires manual launch (GUI application)"
  echo ""
  echo "📋 Instructions for $worker_id:"
  echo "   1. Open Cursor IDE"
  echo "   2. Open workspace: $work_path"
  echo "   3. Open Cursor Chat and send:"
  echo ""
  echo "      @WORKER_IDENTITY.md"
  echo ""
  echo "      Read WORKER_IDENTITY.md — it contains your hopper task ID and the"
  echo "      command to retrieve your full brief. Run that command, then begin Task 1."
  echo ""
}

launch_windsurf_guide() {
  local worker_id="$1"
  local session="$2"

  local work_path=".czarina/worktrees/$worker_id"

  echo "⚠️  Windsurf requires manual launch (GUI application)"
  echo ""
  echo "📋 Instructions for $worker_id:"
  echo "   1. Open Windsurf IDE"
  echo "   2. Open workspace: $work_path"
  echo "   3. Use @ to reference files in chat:"
  echo ""
  echo "      @WORKER_IDENTITY.md"
  echo ""
  echo "      Read WORKER_IDENTITY.md — it contains your hopper task ID and the"
  echo "      command to retrieve your full brief. Run that command, then begin Task 1."
  echo ""
}

launch_copilot_guide() {
  local worker_id="$1"
  local session="$2"

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
  local session="$2"

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
  local session="$2"

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
