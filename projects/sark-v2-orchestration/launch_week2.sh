#!/bin/bash
# SARK v2.0 Week 2+ Launch Script - Full Team
# Launches all 10 engineers in organized tmux layout

SESSION_NAME="sark-v2-full"
SARK_DIR="/home/jhenry/Source/GRID/sark"
ORCHESTRATOR_DIR="/home/jhenry/Source/GRID/claude-orchestrator"

# Kill existing session if it exists
tmux kill-session -t $SESSION_NAME 2>/dev/null

echo "========================================"
echo "SARK v2.0 Full Team Launch"
echo "========================================"
echo ""
echo "⚠️  PREREQUISITE CHECK:"
echo "   Has ENGINEER-1 frozen the ProtocolAdapter interface?"
echo "   (Week 1 milestone must be complete)"
echo ""
read -p "Continue with full team launch? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled. Complete Week 1 first."
    exit 1
fi

# Create new session
tmux new-session -d -s $SESSION_NAME -n "core-arch" -c $SARK_DIR

# ============================================
# Window 0: Core Architecture (ENGINEER-1, 6)
# ============================================
tmux send-keys -t $SESSION_NAME:0.0 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:0.0 "echo '=== ENGINEER-1: Lead Architect ==='" C-m
tmux send-keys -t $SESSION_NAME:0.0 "$ORCHESTRATOR_DIR/orchestrate_sark_v2.py start engineer-1" C-m

tmux split-window -h -t $SESSION_NAME:0 -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:0.1 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:0.1 "echo '=== ENGINEER-6: Database Lead ==='" C-m
tmux send-keys -t $SESSION_NAME:0.1 "$ORCHESTRATOR_DIR/orchestrate_sark_v2.py start engineer-6" C-m

# ============================================
# Window 1: Adapters (ENGINEER-2, 3)
# ============================================
tmux new-window -t $SESSION_NAME:1 -n "adapters" -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:1.0 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:1.0 "echo '=== ENGINEER-2: HTTP Adapter ==='" C-m
tmux send-keys -t $SESSION_NAME:1.0 "$ORCHESTRATOR_DIR/orchestrate_sark_v2.py start engineer-2" C-m

tmux split-window -h -t $SESSION_NAME:1 -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:1.1 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:1.1 "echo '=== ENGINEER-3: gRPC Adapter ==='" C-m
tmux send-keys -t $SESSION_NAME:1.1 "$ORCHESTRATOR_DIR/orchestrate_sark_v2.py start engineer-3" C-m

# ============================================
# Window 2: Advanced Features (ENGINEER-4, 5)
# ============================================
tmux new-window -t $SESSION_NAME:2 -n "advanced" -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:2.0 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:2.0 "echo '=== ENGINEER-4: Federation ==='" C-m
tmux send-keys -t $SESSION_NAME:2.0 "$ORCHESTRATOR_DIR/orchestrate_sark_v2.py start engineer-4" C-m

tmux split-window -h -t $SESSION_NAME:2 -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:2.1 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:2.1 "echo '=== ENGINEER-5: Advanced Features ==='" C-m
tmux send-keys -t $SESSION_NAME:2.1 "$ORCHESTRATOR_DIR/orchestrate_sark_v2.py start engineer-5" C-m

# ============================================
# Window 3: QA (QA-1, QA-2)
# ============================================
tmux new-window -t $SESSION_NAME:3 -n "qa" -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:3.0 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:3.0 "echo '=== QA-1: Integration Testing ==='" C-m
tmux send-keys -t $SESSION_NAME:3.0 "$ORCHESTRATOR_DIR/orchestrate_sark_v2.py start qa-1" C-m

tmux split-window -h -t $SESSION_NAME:3 -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:3.1 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:3.1 "echo '=== QA-2: Performance & Security ==='" C-m
tmux send-keys -t $SESSION_NAME:3.1 "$ORCHESTRATOR_DIR/orchestrate_sark_v2.py start qa-2" C-m

# ============================================
# Window 4: Documentation (DOCS-1, DOCS-2)
# ============================================
tmux new-window -t $SESSION_NAME:4 -n "docs" -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:4.0 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:4.0 "echo '=== DOCS-1: API Documentation ==='" C-m
tmux send-keys -t $SESSION_NAME:4.0 "$ORCHESTRATOR_DIR/orchestrate_sark_v2.py start docs-1" C-m

tmux split-window -h -t $SESSION_NAME:4 -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:4.1 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:4.1 "echo '=== DOCS-2: Tutorials & Examples ==='" C-m
tmux send-keys -t $SESSION_NAME:4.1 "$ORCHESTRATOR_DIR/orchestrate_sark_v2.py start docs-2" C-m

# ============================================
# Window 5: Monitoring & Control
# ============================================
tmux new-window -t $SESSION_NAME:5 -n "monitor" -c $ORCHESTRATOR_DIR
tmux send-keys -t $SESSION_NAME:5.0 "cd $ORCHESTRATOR_DIR" C-m
tmux send-keys -t $SESSION_NAME:5.0 "echo '=== Orchestrator Dashboard ==='" C-m
tmux send-keys -t $SESSION_NAME:5.0 "echo 'Running daily report every 5 minutes...'" C-m
tmux send-keys -t $SESSION_NAME:5.0 "watch -n 300 './orchestrate_sark_v2.py daily-report'" C-m

# Git activity monitor
tmux split-window -v -t $SESSION_NAME:5 -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:5.1 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:5.1 "echo '=== Git Activity (auto-refresh) ==='" C-m
tmux send-keys -t $SESSION_NAME:5.1 "watch -n 60 'git log --oneline --all --graph --since=\"6 hours ago\" | head -30'" C-m

# Test runner
tmux split-window -h -t $SESSION_NAME:5.0 -c $SARK_DIR
tmux send-keys -t $SESSION_NAME:5.2 "cd $SARK_DIR" C-m
tmux send-keys -t $SESSION_NAME:5.2 "echo '=== Test Status ==='" C-m
tmux send-keys -t $SESSION_NAME:5.2 "echo 'Commands:'" C-m
tmux send-keys -t $SESSION_NAME:5.2 "echo '  pytest tests/adapters/ -v'" C-m
tmux send-keys -t $SESSION_NAME:5.2 "echo '  pytest tests/integration/v2/ -v'" C-m
tmux send-keys -t $SESSION_NAME:5.2 "echo '  pytest --cov=src/sark --cov-report=term'" C-m

# Select the first window
tmux select-window -t $SESSION_NAME:0

# Print layout
echo ""
echo "Tmux session created: $SESSION_NAME"
echo ""
echo "Windows:"
echo "  0: core-arch     - ENGINEER-1, ENGINEER-6"
echo "  1: adapters      - ENGINEER-2, ENGINEER-3"
echo "  2: advanced      - ENGINEER-4, ENGINEER-5"
echo "  3: qa            - QA-1, QA-2"
echo "  4: docs          - DOCS-1, DOCS-2"
echo "  5: monitor       - Dashboard, Git, Tests"
echo ""
echo "Navigation:"
echo "  Switch windows: Ctrl+b then 0-5"
echo "  Switch panes: Ctrl+b then arrow keys"
echo "  Detach: Ctrl+b then d"
echo "  Reattach: tmux attach -t $SESSION_NAME"
echo ""
echo "Attaching in 3 seconds..."
sleep 3

tmux attach-session -t $SESSION_NAME
