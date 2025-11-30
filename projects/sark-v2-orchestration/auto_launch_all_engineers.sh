#!/bin/bash
# Auto-launch ALL 10 Claude Code sessions for SARK v2.0 engineers

SARK_DIR="/home/jhenry/Source/GRID/sark"
ORCHESTRATOR_DIR="/home/jhenry/Source/GRID/claude-orchestrator/projects/sark-v2-orchestration"
PROMPTS_DIR="$ORCHESTRATOR_DIR/prompts/sark-v2"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  SARK v2.0 - Auto Launch ALL 10 Engineers                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "This will launch 10 Claude Code sessions in separate terminals:"
echo ""
echo "Core Engineering (6):"
echo "  1. ENGINEER-1: Lead Architect & MCP Adapter Lead"
echo "  2. ENGINEER-2: HTTP/REST Adapter Lead"
echo "  3. ENGINEER-3: gRPC Adapter Lead"
echo "  4. ENGINEER-4: Federation & Discovery Lead"
echo "  5. ENGINEER-5: Advanced Features Lead"
echo "  6. ENGINEER-6: Database & Migration Lead"
echo ""
echo "Quality & Documentation (4):"
echo "  7. QA-1: Integration Testing Lead"
echo "  8. QA-2: Performance & Security Lead"
echo "  9. DOCS-1: API Documentation Lead"
echo " 10. DOCS-2: Tutorial & Examples Lead"
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
echo "Launching all 10 engineers..."
echo ""

# Check if we're in WSL and have access to wt.exe (Windows Terminal)
if command -v wt.exe &> /dev/null; then
    echo "Using Windows Terminal (wt.exe)..."
    echo ""

    # Launch ENGINEER-1
    echo "🚀 [1/10] Launching ENGINEER-1: Lead Architect..."
    wt.exe -w 0 new-tab --title "ENG-1: Lead Architect" bash -c "cd '$SARK_DIR' && claude '@$PROMPTS_DIR/ENGINEER-1-LEAD_ARCHITECT.md'; exec bash" 2>/dev/null &
    sleep 1

    # Launch ENGINEER-2
    echo "🚀 [2/10] Launching ENGINEER-2: HTTP/REST Adapter..."
    wt.exe -w 0 new-tab --title "ENG-2: HTTP Adapter" bash -c "cd '$SARK_DIR' && claude '@$PROMPTS_DIR/ENGINEER-2.md'; exec bash" 2>/dev/null &
    sleep 1

    # Launch ENGINEER-3
    echo "🚀 [3/10] Launching ENGINEER-3: gRPC Adapter..."
    wt.exe -w 0 new-tab --title "ENG-3: gRPC Adapter" bash -c "cd '$SARK_DIR' && claude '@$PROMPTS_DIR/ENGINEER-3.md'; exec bash" 2>/dev/null &
    sleep 1

    # Launch ENGINEER-4
    echo "🚀 [4/10] Launching ENGINEER-4: Federation & Discovery..."
    wt.exe -w 0 new-tab --title "ENG-4: Federation" bash -c "cd '$SARK_DIR' && claude '@$PROMPTS_DIR/ENGINEER-4.md'; exec bash" 2>/dev/null &
    sleep 1

    # Launch ENGINEER-5
    echo "🚀 [5/10] Launching ENGINEER-5: Advanced Features..."
    wt.exe -w 0 new-tab --title "ENG-5: Advanced Features" bash -c "cd '$SARK_DIR' && claude '@$PROMPTS_DIR/ENGINEER-5.md'; exec bash" 2>/dev/null &
    sleep 1

    # Launch ENGINEER-6
    echo "🚀 [6/10] Launching ENGINEER-6: Database & Migration..."
    wt.exe -w 0 new-tab --title "ENG-6: Database" bash -c "cd '$SARK_DIR' && claude '@$PROMPTS_DIR/ENGINEER-6.md'; exec bash" 2>/dev/null &
    sleep 1

    # Launch QA-1
    echo "🚀 [7/10] Launching QA-1: Integration Testing..."
    wt.exe -w 0 new-tab --title "QA-1: Integration Tests" bash -c "cd '$SARK_DIR' && claude '@$PROMPTS_DIR/QA-1.md'; exec bash" 2>/dev/null &
    sleep 1

    # Launch QA-2
    echo "🚀 [8/10] Launching QA-2: Performance & Security..."
    wt.exe -w 0 new-tab --title "QA-2: Performance & Security" bash -c "cd '$SARK_DIR' && claude '@$PROMPTS_DIR/QA-2.md'; exec bash" 2>/dev/null &
    sleep 1

    # Launch DOCS-1
    echo "🚀 [9/10] Launching DOCS-1: API Documentation..."
    wt.exe -w 0 new-tab --title "DOCS-1: API Docs" bash -c "cd '$SARK_DIR' && claude '@$PROMPTS_DIR/DOCS-1.md'; exec bash" 2>/dev/null &
    sleep 1

    # Launch DOCS-2
    echo "🚀 [10/10] Launching DOCS-2: Tutorials & Examples..."
    wt.exe -w 0 new-tab --title "DOCS-2: Tutorials" bash -c "cd '$SARK_DIR' && claude '@$PROMPTS_DIR/DOCS-2.md'; exec bash" 2>/dev/null &
    sleep 1

    echo ""
    echo "✅ All 10 engineers launched in new Windows Terminal tabs!"
    echo ""
    echo "Check Windows Terminal - you should see 10 new tabs:"
    echo "  • 6 Core Engineers (ENG-1 through ENG-6)"
    echo "  • 2 QA Engineers (QA-1, QA-2)"
    echo "  • 2 Documentation Engineers (DOCS-1, DOCS-2)"
    echo ""
    echo "💡 Tip: Use Ctrl+Tab to cycle through tabs in Windows Terminal"

else
    echo "⚠️  Windows Terminal (wt.exe) not found."
    echo ""
    echo "Manual launch commands (run each in a separate terminal):"
    echo ""
    echo "# Core Engineers"
    echo "cd $SARK_DIR && claude '@$PROMPTS_DIR/ENGINEER-1-LEAD_ARCHITECT.md'"
    echo "cd $SARK_DIR && claude '@$PROMPTS_DIR/ENGINEER-2.md'"
    echo "cd $SARK_DIR && claude '@$PROMPTS_DIR/ENGINEER-3.md'"
    echo "cd $SARK_DIR && claude '@$PROMPTS_DIR/ENGINEER-4.md'"
    echo "cd $SARK_DIR && claude '@$PROMPTS_DIR/ENGINEER-5.md'"
    echo "cd $SARK_DIR && claude '@$PROMPTS_DIR/ENGINEER-6.md'"
    echo ""
    echo "# QA Engineers"
    echo "cd $SARK_DIR && claude '@$PROMPTS_DIR/QA-1.md'"
    echo "cd $SARK_DIR && claude '@$PROMPTS_DIR/QA-2.md'"
    echo ""
    echo "# Documentation Engineers"
    echo "cd $SARK_DIR && claude '@$PROMPTS_DIR/DOCS-1.md'"
    echo "cd $SARK_DIR && claude '@$PROMPTS_DIR/DOCS-2.md'"
    echo ""
fi
