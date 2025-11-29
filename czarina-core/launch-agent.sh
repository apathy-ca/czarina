#!/bin/bash
# Czarina Multi-Agent Worker Launcher
# Launches workers using different AI coding assistants

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage information
usage() {
    cat <<EOF
${BLUE}Czarina Multi-Agent Worker Launcher${NC}

Usage: $0 <agent> <worker-id> [project-dir]

${GREEN}Supported Agents:${NC}
  claude-code    - Claude Code (native Czarina workflow)
  cursor         - Cursor IDE
  aider          - Aider CLI
  copilot        - GitHub Copilot
  windsurf       - Windsurf IDE
  codeium        - Codeium
  continue       - Continue.dev
  human          - Human developer (display task only)

${GREEN}Examples:${NC}
  $0 cursor engineer1
  $0 aider qa1 ./myproject
  $0 claude-code docs1

${GREEN}Worker IDs:${NC}
  Any worker defined in czarina-*/workers/ directory
  (e.g., engineer1, engineer2, qa1, docs1, architect, rebrand, integrator)

EOF
    exit 0
}

# Check if help requested
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]] || [[ $# -eq 0 ]]; then
    usage
fi

# Parse arguments
AGENT="${1:-claude-code}"
WORKER_ID="${2:-}"
PROJECT_DIR="${3:-.}"

if [ -z "$WORKER_ID" ]; then
    echo -e "${RED}❌ Error: Worker ID required${NC}"
    echo ""
    usage
fi

# Find orchestration directory
CZARINA_DIR=$(find "$PROJECT_DIR" -maxdepth 1 -type d -name "czarina-*" 2>/dev/null | head -1)

if [ -z "$CZARINA_DIR" ]; then
    echo -e "${RED}❌ No czarina-* directory found in $PROJECT_DIR${NC}"
    echo -e "${YELLOW}💡 Tip: Run 'czarina embed' first to create orchestration${NC}"
    exit 1
fi

WORKER_FILE="$CZARINA_DIR/workers/${WORKER_ID}.md"

if [ ! -f "$WORKER_FILE" ]; then
    # Try uppercase version
    WORKER_FILE="$CZARINA_DIR/workers/${WORKER_ID^^}.md"
    if [ ! -f "$WORKER_FILE" ]; then
        echo -e "${RED}❌ Worker not found: ${WORKER_ID}${NC}"
        echo -e "${YELLOW}Available workers:${NC}"
        ls -1 "$CZARINA_DIR/workers/" 2>/dev/null | sed 's/\.md$//' | sed 's/^/  - /'
        exit 1
    fi
fi

# Display worker info
echo -e "${BLUE}🚀 Czarina Multi-Agent Launcher${NC}"
echo -e "${GREEN}Agent:${NC}    $AGENT"
echo -e "${GREEN}Worker:${NC}   $WORKER_ID"
echo -e "${GREEN}File:${NC}     $WORKER_FILE"
echo ""

# Load agent profile if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_FILE="$SCRIPT_DIR/../agents/profiles/${AGENT}.json"

if [ -f "$PROFILE_FILE" ]; then
    echo -e "${GREEN}✓ Agent profile loaded: $AGENT${NC}"
    echo ""
fi

# Agent-specific launch logic
case "$AGENT" in
    "claude-code")
        echo -e "${BLUE}📋 Claude Code Instructions:${NC}"
        echo ""
        echo "1. Open Claude Code (web or desktop)"
        echo "2. Say: \"You are ${WORKER_ID}\""
        echo "3. Claude will automatically discover and load your worker prompt"
        echo ""
        echo "Alternative (explicit):"
        echo "  Read and follow: @${WORKER_FILE}"
        echo ""

        # Check if .worker-init exists for native launch
        if [ -f "$CZARINA_DIR/.worker-init" ]; then
            echo -e "${YELLOW}🔧 Native launcher detected${NC}"
            echo "You can also run: $CZARINA_DIR/.worker-init $WORKER_ID"
            echo ""
        fi
        ;;

    "cursor")
        echo -e "${BLUE}📋 Cursor Instructions:${NC}"
        echo ""
        echo "1. Open Cursor IDE"
        echo "2. Open this project: $PROJECT_DIR"
        echo "3. In Cursor chat, type:"
        echo "   @${WORKER_FILE}"
        echo ""
        echo "   Follow this prompt exactly as the assigned worker."
        echo ""
        echo "Tips:"
        echo "  - Use Cmd/Ctrl+P to quickly find worker files"
        echo "  - Keep worker file open in split pane for reference"
        echo "  - Cursor's git integration works perfectly with Czarina branches"
        echo ""

        # Try to open Cursor if available
        if command -v cursor &> /dev/null; then
            echo -e "${GREEN}✓ Cursor detected, opening...${NC}"
            cursor "$WORKER_FILE" &
        else
            echo -e "${YELLOW}💡 Install Cursor: https://cursor.sh${NC}"
        fi
        ;;

    "aider")
        echo -e "${BLUE}📋 Aider Instructions:${NC}"
        echo ""

        if ! command -v aider &> /dev/null; then
            echo -e "${YELLOW}⚠️  Aider not installed${NC}"
            echo "Install with: pip install aider-chat"
            echo ""
            exit 1
        fi

        echo -e "${GREEN}🚀 Launching Aider with worker prompt...${NC}"
        echo ""

        # Change to project directory
        cd "$PROJECT_DIR"

        # Launch Aider with worker prompt
        aider --read "$WORKER_FILE" \
              --model claude-3-5-sonnet-20241022 \
              --auto-commits
        ;;

    "copilot"|"github-copilot")
        echo -e "${BLUE}📋 GitHub Copilot Instructions:${NC}"
        echo ""
        echo "1. Open VS Code with GitHub Copilot enabled"
        echo "2. Open this project: $PROJECT_DIR"
        echo "3. Open Copilot Chat (Cmd/Ctrl+Shift+I)"
        echo "4. Type:"
        echo "   Read ${WORKER_FILE} and follow that worker prompt exactly."
        echo ""
        echo "Alternative using file reference:"
        echo "   #file:${WORKER_FILE}"
        echo ""
        echo "Tips:"
        echo "  - Use @workspace for project context"
        echo "  - Use /explain, /fix, /tests commands"
        echo "  - GitHub CLI (gh) works great for PRs"
        echo ""
        ;;

    "windsurf")
        echo -e "${BLUE}📋 Windsurf Instructions:${NC}"
        echo ""
        echo "1. Open Windsurf IDE"
        echo "2. Open this project: $PROJECT_DIR"
        echo "3. In Windsurf chat, type:"
        echo "   @${WORKER_FILE}"
        echo ""
        echo "   I am this worker. Follow the prompt."
        echo ""
        echo "Tips:"
        echo "  - Similar to Cursor workflow"
        echo "  - Use @ to reference files"
        echo "  - Keep worker file visible for reference"
        echo ""

        if command -v windsurf &> /dev/null; then
            echo -e "${GREEN}✓ Windsurf detected, opening...${NC}"
            windsurf "$WORKER_FILE" &
        else
            echo -e "${YELLOW}💡 Install Windsurf from their website${NC}"
        fi
        ;;

    "codeium")
        echo -e "${BLUE}📋 Codeium Instructions:${NC}"
        echo ""
        echo "1. Open your IDE with Codeium extension"
        echo "2. Open this project: $PROJECT_DIR"
        echo "3. Open Codeium Chat"
        echo "4. Type:"
        echo "   Read ${WORKER_FILE} and act as that worker."
        echo ""
        echo "Tips:"
        echo "  - Free alternative to Copilot"
        echo "  - Works in VS Code, JetBrains, etc."
        echo ""
        ;;

    "continue"|"continue.dev")
        echo -e "${BLUE}📋 Continue.dev Instructions:${NC}"
        echo ""
        echo "1. Open your IDE with Continue extension"
        echo "2. Open this project: $PROJECT_DIR"
        echo "3. Open Continue panel (Cmd/Ctrl+L)"
        echo "4. Type:"
        echo "   Read ${WORKER_FILE} and follow that worker prompt."
        echo ""
        echo "Tips:"
        echo "  - Open source AI code assistant"
        echo "  - Supports multiple models"
        echo "  - Can use local models"
        echo ""
        ;;

    "human")
        echo -e "${BLUE}📋 Human Worker Task Assignment${NC}"
        echo ""
        echo -e "${GREEN}Worker:${NC} $WORKER_ID"
        echo -e "${GREEN}Task File:${NC} $WORKER_FILE"
        echo ""
        echo "─────────────────────────────────────────────────────────"
        cat "$WORKER_FILE"
        echo "─────────────────────────────────────────────────────────"
        echo ""
        echo -e "${YELLOW}📧 Next Steps:${NC}"
        echo "1. Review the task above"
        echo "2. Work on your assigned branch"
        echo "3. Follow the git workflow in the task"
        echo "4. Push commits regularly so Czar can monitor progress"
        echo ""
        ;;

    *)
        echo -e "${YELLOW}⚠️  Unknown agent type: $AGENT${NC}"
        echo ""
        echo "Displaying worker file for manual use:"
        echo "─────────────────────────────────────────────────────────"
        cat "$WORKER_FILE"
        echo "─────────────────────────────────────────────────────────"
        echo ""
        echo "Supported agents:"
        echo "  claude-code, cursor, aider, copilot, windsurf, codeium, continue, human"
        echo ""
        exit 1
        ;;
esac

echo -e "${GREEN}✨ Ready to start working!${NC}"
