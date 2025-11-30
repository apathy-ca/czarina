#!/bin/bash
# Auto-launch Claude Code sessions for SARK v2.0 engineers

SARK_DIR="/home/jhenry/Source/GRID/sark"
ORCHESTRATOR_DIR="/home/jhenry/Source/GRID/claude-orchestrator/projects/sark-v2-orchestration"
PROMPTS_DIR="$ORCHESTRATOR_DIR/prompts/sark-v2"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  SARK v2.0 Week 1 - Auto Launch Engineers                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "This will launch 3 Claude Code sessions in separate terminals:"
echo "  1. ENGINEER-1: Lead Architect & MCP Adapter Lead"
echo "  2. ENGINEER-6: Database & Migration Lead"
echo "  3. QA-1: Integration Testing Lead"
echo ""
echo "Each will start in: $SARK_DIR"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Launching engineers..."
echo ""

# Check if we're in WSL and have access to wt.exe (Windows Terminal)
if command -v wt.exe &> /dev/null; then
    echo "Using Windows Terminal (wt.exe)..."

    # Launch ENGINEER-1
    echo "🚀 Launching ENGINEER-1: Lead Architect..."
    wt.exe -w 0 new-tab --title "ENGINEER-1: Lead Architect" bash -c "cd '$SARK_DIR' && claude '@$PROMPTS_DIR/ENGINEER-1-LEAD_ARCHITECT.md'; exec bash" 2>/dev/null &
    sleep 1

    # Launch ENGINEER-6
    echo "🚀 Launching ENGINEER-6: Database Lead..."
    wt.exe -w 0 new-tab --title "ENGINEER-6: Database Lead" bash -c "cd '$SARK_DIR' && claude '@$PROMPTS_DIR/ENGINEER-6.md'; exec bash" 2>/dev/null &
    sleep 1

    # Launch QA-1
    echo "🚀 Launching QA-1: Integration Testing..."
    wt.exe -w 0 new-tab --title "QA-1: Integration Testing" bash -c "cd '$SARK_DIR' && claude '@$PROMPTS_DIR/QA-1.md'; exec bash" 2>/dev/null &
    sleep 1

    echo ""
    echo "✅ All engineers launched in new Windows Terminal tabs!"
    echo ""
    echo "Check Windows Terminal - you should see 3 new tabs."

else
    echo "⚠️  Windows Terminal (wt.exe) not found."
    echo ""
    echo "Manual launch commands:"
    echo ""
    echo "Terminal 1 (ENGINEER-1):"
    echo "  cd $SARK_DIR"
    echo "  claude '@$PROMPTS_DIR/ENGINEER-1-LEAD_ARCHITECT.md'"
    echo ""
    echo "Terminal 2 (ENGINEER-6):"
    echo "  cd $SARK_DIR"
    echo "  claude '@$PROMPTS_DIR/ENGINEER-6.md'"
    echo ""
    echo "Terminal 3 (QA-1):"
    echo "  cd $SARK_DIR"
    echo "  claude '@$PROMPTS_DIR/QA-1.md'"
    echo ""
fi
