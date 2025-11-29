#!/bin/bash
# SARK v1.1 - Quick Start Orchestrator
# One command to rule them all

set -euo pipefail

# Get orchestrator directory
ORCHESTRATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
source "${ORCHESTRATOR_DIR}/config.sh"

clear

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   SARK v1.1 Gateway Integration - Quick Start Orchestrator   ║
║                                                               ║
║   Multi-Agent Vibecoding System                               ║
║   6 Workers | 10 Days | 1 Mission                             ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

cd "$ORCHESTRATOR_DIR"

echo -e "${GREEN}✅ Orchestrator ready${NC}\n"

echo -e "${YELLOW}Choose your adventure:${NC}\n"

echo "1. 🎭 Launch Interactive Orchestrator (Main Menu)"
echo "2. 🚀 Launch All Workers in tmux (Recommended)"
echo "3. 🤖 Start Autonomous Czar (NEW - No Human Needed!)"
echo "4. 📝 Generate Claude Code Prompts (Manual Setup)"
echo "5. 📊 Open Live Dashboard (Monitor Progress)"
echo "6. 🔍 Manage PRs (Review & Merge)"
echo "7. 📚 View Documentation (README)"
echo ""
echo "0. Exit"
echo ""

read -p "Enter choice: " choice
echo ""

case $choice in
    1)
        echo -e "${CYAN}Launching interactive orchestrator...${NC}"
        ./orchestrator.sh
        ;;
    2)
        echo -e "${CYAN}Launching all 6 workers in tmux sessions...${NC}\n"

        workers=("engineer1" "engineer2" "engineer3" "engineer4" "qa" "docs")

        for worker in "${workers[@]}"; do
            echo -e "${GREEN}🚀 Launching worker: ${worker}${NC}"
            # Launch worker script directly (it creates its own tmux session)
            ./launch-worker.sh ${worker} > /dev/null 2>&1 &
            sleep 0.5
        done

        echo ""
        echo -e "${GREEN}✅ All workers launched in tmux!${NC}\n"

        sleep 2

        echo -e "${YELLOW}Active tmux sessions:${NC}"
        tmux ls 2>/dev/null || echo "  (No sessions found - they may be starting...)"
        echo ""

        echo -e "${CYAN}To attach to a worker:${NC}"
        echo "  tmux attach -t sark-worker-engineer1"
        echo ""

        echo -e "${CYAN}To view all sessions:${NC}"
        echo "  tmux ls"
        echo ""

        echo -e "${CYAN}To monitor progress:${NC}"
        echo "  ./dashboard.py"
        echo ""

        echo -e "${YELLOW}Note:${NC} Each worker is in its own tmux session."
        echo "Attach to a session to see what the worker is doing."
        echo "Press Ctrl+B then D to detach from a session."
        ;;
    3)
        echo -e "${CYAN}🤖 Starting Autonomous Czar...${NC}\n"
        echo -e "${YELLOW}The Czar will:${NC}"
        echo "  ✅ Monitor all workers every 30 seconds"
        echo "  ✅ Auto-assign bonus tasks to idle workers"
        echo "  ✅ Detect and prompt stuck workers"
        echo "  ✅ Log all decisions autonomously"
        echo ""
        echo -e "${GREEN}Goal: 'In an ideal world I'm not here at all'${NC}\n"
        echo -e "${YELLOW}Starting in 3 seconds...${NC}"
        sleep 3
        ./czar-autonomous.sh
        ;;
    4)
        echo -e "${CYAN}Generating Claude Code prompts...${NC}\n"
        ./generate-worker-prompts.sh
        echo ""
        echo -e "${GREEN}✅ Prompts generated in prompts/${NC}\n"
        echo -e "${YELLOW}Next steps:${NC}"
        echo "  1. Open 6 Claude Code instances"
        echo "  2. Copy content from prompts/engineer1-prompt.md to instance 1"
        echo "  3. Copy content from prompts/engineer2-prompt.md to instance 2"
        echo "  4. etc."
        echo ""
        echo -e "${CYAN}View prompts:${NC}"
        ls -1 prompts/*.md
        ;;
    5)
        echo -e "${CYAN}Opening live dashboard...${NC}\n"
        echo -e "${YELLOW}Installing dependencies if needed...${NC}"
        pip3 install rich -q 2>/dev/null || true
        ./dashboard.py
        ;;
    6)
        echo -e "${CYAN}Opening PR manager...${NC}\n"
        ./pr-manager.sh
        ;;
    7)
        echo -e "${CYAN}Opening README...${NC}\n"
        less README.md
        ;;
    0)
        echo -e "${CYAN}Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo -e "${YELLOW}Invalid choice. Run again.${NC}"
        ;;
esac
