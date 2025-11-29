#!/bin/bash
# SARK v2.0 Week 1 Launch Script - Critical Path Engineers
# Launches ENGINEER-1, ENGINEER-6, and QA-1 in tmux

SESSION_NAME="sark-v2-week1"
SARK_DIR="/home/jhenry/Source/GRID/sark"
ORCHESTRATOR_DIR="/home/jhenry/Source/GRID/claude-orchestrator/projects/sark-v2-orchestration"

# Kill existing session if it exists
tmux kill-session -t $SESSION_NAME 2>/dev/null

# Create new session with ENGINEER-1
tmux new-session -d -s $SESSION_NAME -n "week1-critical" -c $SARK_DIR

# Pane 0: ENGINEER-1 (Lead Architect)
tmux send-keys -t $SESSION_NAME:0.0 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:0.0 "clear" C-m
tmux send-keys -t $SESSION_NAME:0.0 "echo '╔════════════════════════════════════════════════════════════╗'" C-m
tmux send-keys -t $SESSION_NAME:0.0 "echo '║  ENGINEER-1: Lead Architect & MCP Adapter Lead            ║'" C-m
tmux send-keys -t $SESSION_NAME:0.0 "echo '╚════════════════════════════════════════════════════════════╝'" C-m
tmux send-keys -t $SESSION_NAME:0.0 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:0.0 "echo 'Prompt file: $ORCHESTRATOR_DIR/prompts/sark-v2/ENGINEER-1-LEAD_ARCHITECT.md'" C-m
tmux send-keys -t $SESSION_NAME:0.0 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:0.0 "echo '📋 In Claude Code, simply reference this file:'" C-m
tmux send-keys -t $SESSION_NAME:0.0 "echo '   @../claude-orchestrator/projects/sark-v2-orchestration/prompts/sark-v2/ENGINEER-1-LEAD_ARCHITECT.md'" C-m
tmux send-keys -t $SESSION_NAME:0.0 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:0.0 "echo 'Or read it now:'" C-m
tmux send-keys -t $SESSION_NAME:0.0 "echo '   cat ../claude-orchestrator/projects/sark-v2-orchestration/prompts/sark-v2/ENGINEER-1-LEAD_ARCHITECT.md'" C-m

# Split horizontally for ENGINEER-6
tmux split-window -h -t $SESSION_NAME:0 -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:0.1 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:0.1 "clear" C-m
tmux send-keys -t $SESSION_NAME:0.1 "echo '╔════════════════════════════════════════════════════════════╗'" C-m
tmux send-keys -t $SESSION_NAME:0.1 "echo '║  ENGINEER-6: Database & Migration Lead                     ║'" C-m
tmux send-keys -t $SESSION_NAME:0.1 "echo '╚════════════════════════════════════════════════════════════╝'" C-m
tmux send-keys -t $SESSION_NAME:0.1 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:0.1 "echo 'Prompt file: $ORCHESTRATOR_DIR/prompts/sark-v2/ENGINEER-6.md'" C-m
tmux send-keys -t $SESSION_NAME:0.1 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:0.1 "echo '📋 In Claude Code, reference:'" C-m
tmux send-keys -t $SESSION_NAME:0.1 "echo '   @../claude-orchestrator/projects/sark-v2-orchestration/prompts/sark-v2/ENGINEER-6.md'" C-m

# Split vertically (bottom right) for QA-1
tmux split-window -v -t $SESSION_NAME:0.1 -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:0.2 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:0.2 "clear" C-m
tmux send-keys -t $SESSION_NAME:0.2 "echo '╔════════════════════════════════════════════════════════════╗'" C-m
tmux send-keys -t $SESSION_NAME:0.2 "echo '║  QA-1: Integration Testing Lead                            ║'" C-m
tmux send-keys -t $SESSION_NAME:0.2 "echo '╚════════════════════════════════════════════════════════════╝'" C-m
tmux send-keys -t $SESSION_NAME:0.2 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:0.2 "echo 'Prompt file: $ORCHESTRATOR_DIR/prompts/sark-v2/QA-1.md'" C-m
tmux send-keys -t $SESSION_NAME:0.2 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:0.2 "echo '📋 In Claude Code, reference:'" C-m
tmux send-keys -t $SESSION_NAME:0.2 "echo '   @../claude-orchestrator/projects/sark-v2-orchestration/prompts/sark-v2/QA-1.md'" C-m

# Create window 2: Monitoring
tmux new-window -t $SESSION_NAME:1 -n "monitoring" -c $ORCHESTRATOR_DIR
tmux send-keys -t $SESSION_NAME:1 "cd $ORCHESTRATOR_DIR" C-m
tmux send-keys -t $SESSION_NAME:1 "clear" C-m
tmux send-keys -t $SESSION_NAME:1 "echo '╔════════════════════════════════════════════════════════════╗'" C-m
tmux send-keys -t $SESSION_NAME:1 "echo '║  SARK v2.0 Orchestrator Monitoring                         ║'" C-m
tmux send-keys -t $SESSION_NAME:1 "echo '╚════════════════════════════════════════════════════════════╝'" C-m
tmux send-keys -t $SESSION_NAME:1 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:1 "echo 'Commands:'" C-m
tmux send-keys -t $SESSION_NAME:1 "echo '  ./orchestrate_sark_v2.py daily-report'" C-m
tmux send-keys -t $SESSION_NAME:1 "echo '  ./orchestrate_sark_v2.py check-blockers'" C-m
tmux send-keys -t $SESSION_NAME:1 "echo '  ./orchestrate_sark_v2.py test-integration'" C-m
tmux send-keys -t $SESSION_NAME:1 "echo '  ./orchestrate_sark_v2.py next-week'" C-m
tmux send-keys -t $SESSION_NAME:1 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:1 "echo 'Auto-monitoring (updates every 5 min):'" C-m
tmux send-keys -t $SESSION_NAME:1 "echo '  watch -n 300 \"./orchestrate_sark_v2.py daily-report\"'" C-m

# Split monitoring window for git log
tmux split-window -v -t $SESSION_NAME:1 -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:1.1 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:1.1 "clear" C-m
tmux send-keys -t $SESSION_NAME:1.1 "echo '╔════════════════════════════════════════════════════════════╗'" C-m
tmux send-keys -t $SESSION_NAME:1.1 "echo '║  Git Activity Monitor (auto-refresh every 60s)             ║'" C-m
tmux send-keys -t $SESSION_NAME:1.1 "echo '╚════════════════════════════════════════════════════════════╝'" C-m
tmux send-keys -t $SESSION_NAME:1.1 "watch -n 60 'git log --oneline --all --graph --since=\"1 day ago\" --color=always | head -20'" C-m

# Select the first window with engineers
tmux select-window -t $SESSION_NAME:0
tmux select-pane -t $SESSION_NAME:0.0

# Attach to the session
clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         SARK v2.0 Week 1 Critical Path Launch             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Launching tmux session: $SESSION_NAME"
echo ""
echo "📐 Layout:"
echo "  Window 0 (week1-critical):"
echo "    Pane 0: ENGINEER-1 (Lead Architect)"
echo "    Pane 1: ENGINEER-6 (Database Lead)"
echo "    Pane 2: QA-1 (Integration Testing)"
echo ""
echo "  Window 1 (monitoring):"
echo "    Pane 0: Orchestrator commands"
echo "    Pane 1: Git activity (auto-refresh)"
echo ""
echo "🎯 To start each engineer in Claude Code:"
echo "   Just reference the prompt file shown in each pane using @filepath"
echo "   Example: @../claude-orchestrator/projects/sark-v2-orchestration/prompts/sark-v2/ENGINEER-1-LEAD_ARCHITECT.md"
echo ""
echo "⌨️  Tmux commands:"
echo "  Switch panes: Ctrl+b then arrow keys"
echo "  Switch windows: Ctrl+b then 0/1"
echo "  Detach: Ctrl+b then d"
echo "  Reattach: tmux attach -t $SESSION_NAME"
echo ""
echo "Attaching to session in 3 seconds..."
sleep 3

tmux attach-session -t $SESSION_NAME
