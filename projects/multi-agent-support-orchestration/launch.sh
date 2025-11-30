#!/bin/bash
# Multi-Agent Support Project Launch Script
# Launches 3 workers in tmux to make Czarina agent-agnostic

SESSION_NAME="czarina-multi-agent"
PROJECT_DIR="/home/jhenry/Source/GRID/claude-orchestrator"
ORCHESTRATOR_DIR="$(dirname "$0")"

# Kill existing session if it exists
tmux kill-session -t $SESSION_NAME 2>/dev/null

# Create new session
tmux new-session -d -s $SESSION_NAME -n "workers" -c $PROJECT_DIR

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Czarina Multi-Agent Support Project Launch            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "🤯 Meta-Orchestration: Czarina orchestrating Czarina!"
echo ""
echo "Workers:"
echo "  • REBRAND    - Documentation rebranding (30 min)"
echo "  • ARCHITECT  - Agent profile system (1-2 hrs)"
echo "  • INTEGRATOR - Multi-agent launcher (1-2 hrs)"
echo ""

# ============================================
# Pane 0: REBRAND
# ============================================
tmux send-keys -t $SESSION_NAME:0.0 "cat << 'REBRAND_EOF'
╔════════════════════════════════════════════════════════════╗
║  REBRAND: Documentation Rebranding Specialist              ║
╚════════════════════════════════════════════════════════════╝

📋 In Claude Code, reference this prompt:
   @$PROJECT_DIR/czarina-multi-agent-support/workers/rebrand.md

Or launch with:
   $PROJECT_DIR/czarina-multi-agent-support/.worker-init rebrand

Branch: feat/agent-agnostic-docs
Time: ~30 minutes

Tasks:
- Create template docs with {{AGENT_NAME}} placeholders
- Add agent compatibility matrix
- Update README for multi-agent support

Working directory: $PROJECT_DIR
REBRAND_EOF
" C-m

# Split horizontally for ARCHITECT
tmux split-window -h -t $SESSION_NAME:0 -c $PROJECT_DIR
tmux send-keys -t $SESSION_NAME:0.1 "cat << 'ARCHITECT_EOF'
╔════════════════════════════════════════════════════════════╗
║  ARCHITECT: Agent Profile System Architect                 ║
╚════════════════════════════════════════════════════════════╝

📋 In Claude Code, reference this prompt:
   @$PROJECT_DIR/czarina-multi-agent-support/workers/architect.md

Or launch with:
   $PROJECT_DIR/czarina-multi-agent-support/.worker-init architect

Branch: feat/agent-profiles
Time: 1-2 hours

Tasks:
- Design agent profile JSON schema
- Create profiles for 5+ agents
- Build profile loader utility
- Integrate with embed command

Working directory: $PROJECT_DIR
ARCHITECT_EOF
" C-m

# Split vertically (bottom right) for INTEGRATOR
tmux split-window -v -t $SESSION_NAME:0.1 -c $PROJECT_DIR
tmux send-keys -t $SESSION_NAME:0.2 "cat << 'INTEGRATOR_EOF'
╔════════════════════════════════════════════════════════════╗
║  INTEGRATOR: Multi-Agent Integration Engineer              ║
╚════════════════════════════════════════════════════════════╝

📋 In Claude Code, reference this prompt:
   @$PROJECT_DIR/czarina-multi-agent-support/workers/integrator.md

Or launch with:
   $PROJECT_DIR/czarina-multi-agent-support/.worker-init integrator

Branch: feat/multi-agent-launcher
Time: 1-2 hours

Tasks:
- Build multi-agent launcher script
- Create agent-specific helpers
- Write usage guides
- Test with multiple agents

Working directory: $PROJECT_DIR
INTEGRATOR_EOF
" C-m

# Create window 2: Monitoring
tmux new-window -t $SESSION_NAME:1 -n "monitoring" -c $PROJECT_DIR
tmux send-keys -t $SESSION_NAME:1 "cat << 'MONITOR_EOF'
╔════════════════════════════════════════════════════════════╗
║  Multi-Agent Support Project Monitoring                    ║
╚════════════════════════════════════════════════════════════╝

Meta-orchestration: Czarina making Czarina agent-agnostic! 🤯

Commands:
  ./czarina status multi-agent-support
  ./czarina dashboard multi-agent-support

Git monitoring:
  git log --oneline --all --graph

Branch status:
  git branch -a | grep feat/agent

Current directory:
MONITOR_EOF
" C-m
tmux send-keys -t $SESSION_NAME:1 "pwd" C-m
tmux send-keys -t $SESSION_NAME:1 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:1 "echo 'Branches created:'" C-m
tmux send-keys -t $SESSION_NAME:1 "git branch -a | grep -E '(feat/agent|feat/multi-agent)'" C-m

# Split monitoring window for auto-refresh git log
tmux split-window -v -t $SESSION_NAME:1 -c $PROJECT_DIR
tmux send-keys -t $SESSION_NAME:1.1 "cat << 'GITMON_EOF'
╔════════════════════════════════════════════════════════════╗
║  Git Activity Monitor (auto-refresh every 30s)             ║
╚════════════════════════════════════════════════════════════╝
GITMON_EOF
" C-m
tmux send-keys -t $SESSION_NAME:1.1 "watch -n 30 'git log --oneline --all --graph --since=\"1 day ago\" --color=always | head -20'" C-m

# Select the first window with workers
tmux select-window -t $SESSION_NAME:0
tmux select-pane -t $SESSION_NAME:0.0

# Attach to the session
clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Czarina Multi-Agent Support Project Launched          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Session: $SESSION_NAME"
echo ""
echo "📐 Layout:"
echo "  Window 0 (workers):"
echo "    Pane 0: REBRAND (left)"
echo "    Pane 1: ARCHITECT (top right)"
echo "    Pane 2: INTEGRATOR (bottom right)"
echo ""
echo "  Window 1 (monitoring):"
echo "    Pane 0: Commands & status"
echo "    Pane 1: Git activity (auto-refresh)"
echo ""
echo "🎯 To start each worker in Claude Code:"
echo "   Copy the @filepath shown in each pane"
echo ""
echo "⌨️  Tmux commands:"
echo "  Switch panes: Ctrl+b then arrow keys"
echo "  Switch windows: Ctrl+b then 0 (workers) or 1 (monitoring)"
echo "  Zoom pane fullscreen: Ctrl+b then z (toggle)"
echo "  Detach: Ctrl+b then d"
echo "  Reattach: tmux attach -t $SESSION_NAME"
echo ""
echo "🤯 This is meta-orchestration:"
echo "   Czarina orchestrating work to make Czarina agent-agnostic!"
echo ""
echo "Attaching to session in 3 seconds..."
sleep 3

tmux attach-session -t $SESSION_NAME
