#!/bin/bash
# Validation script - ensures orchestrator is ready to go

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Claude Orchestrator - Validation Check       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
REPO_ROOT="$PROJECT_ROOT"
ORCHESTRATOR_DIR="$SCRIPT_DIR"

cd "$ORCHESTRATOR_DIR"

all_good=true

# Check required files
echo -e "${BLUE}Checking required files...${NC}"
required_files=(
    "orchestrator.sh"
    "launch-worker.sh"
    "generate-worker-prompts.sh"
    "dashboard.py"
    "pr-manager.sh"
    "QUICKSTART.sh"
    "README.md"
    "CZAR_GUIDE.md"
    "START_HERE.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✅ ${file}${NC}"
    else
        echo -e "  ${RED}❌ ${file} - MISSING${NC}"
        all_good=false
    fi
done

# Check prompts generated
echo -e "\n${BLUE}Checking worker prompts...${NC}"
prompt_files=(
    "prompts/engineer1-prompt.md"
    "prompts/engineer2-prompt.md"
    "prompts/engineer3-prompt.md"
    "prompts/engineer4-prompt.md"
    "prompts/qa-prompt.md"
    "prompts/docs-prompt.md"
)

for file in "${prompt_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✅ ${file}${NC}"
    else
        echo -e "  ${RED}❌ ${file} - MISSING${NC}"
        all_good=false
    fi
done

# Check task files exist
echo -e "\n${BLUE}Checking worker task files...${NC}"
task_files=(
    "docs/gateway-integration/tasks/ENGINEER_1_TASKS.md"
    "docs/gateway-integration/tasks/ENGINEER_2_TASKS.md"
    "docs/gateway-integration/tasks/ENGINEER_3_TASKS.md"
    "docs/gateway-integration/tasks/ENGINEER_4_TASKS.md"
    "docs/gateway-integration/tasks/QA_WORKER_TASKS.md"
    "docs/gateway-integration/tasks/DOCUMENTATION_ENGINEER_TASKS.md"
)

for file in "${task_files[@]}"; do
    if [ -f "${REPO_ROOT}/${file}" ]; then
        echo -e "  ${GREEN}✅ ${file}${NC}"
    else
        echo -e "  ${RED}❌ ${file} - MISSING${NC}"
        all_good=false
    fi
done

# Check executables
echo -e "\n${BLUE}Checking executables...${NC}"
for file in orchestrator.sh launch-worker.sh generate-worker-prompts.sh pr-manager.sh QUICKSTART.sh dashboard.py; do
    if [ -x "$file" ]; then
        echo -e "  ${GREEN}✅ ${file} is executable${NC}"
    else
        echo -e "  ${RED}❌ ${file} is NOT executable${NC}"
        all_good=false
    fi
done

# Check required commands
echo -e "\n${BLUE}Checking required commands...${NC}"
commands=(
    "git"
    "gh"
    "tmux"
    "python3"
    "jq"
)

for cmd in "${commands[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "  ${GREEN}✅ ${cmd} available${NC}"
    else
        echo -e "  ${YELLOW}⚠️  ${cmd} not found (may be optional)${NC}"
        if [ "$cmd" = "git" ] || [ "$cmd" = "python3" ]; then
            all_good=false
        fi
    fi
done

# Check Python dependencies
echo -e "\n${BLUE}Checking Python dependencies...${NC}"
if python3 -c "import rich" 2>/dev/null; then
    echo -e "  ${GREEN}✅ rich (for dashboard)${NC}"
else
    echo -e "  ${YELLOW}⚠️  rich not installed (dashboard won't work)${NC}"
    echo -e "     Install with: pip3 install rich"
fi

# Check git repository
echo -e "\n${BLUE}Checking git repository...${NC}"
cd "$REPO_ROOT"
if git rev-parse --is-inside-work-tree &> /dev/null; then
    echo -e "  ${GREEN}✅ In git repository${NC}"

    # Check main branch exists
    if git rev-parse --verify main &> /dev/null; then
        echo -e "  ${GREEN}✅ main branch exists${NC}"
    else
        echo -e "  ${RED}❌ main branch not found${NC}"
        all_good=false
    fi

    # Check remote
    if git remote get-url origin &> /dev/null; then
        echo -e "  ${GREEN}✅ origin remote configured${NC}"
        echo -e "     $(git remote get-url origin)"
    else
        echo -e "  ${RED}❌ No origin remote${NC}"
        all_good=false
    fi
else
    echo -e "  ${RED}❌ Not in a git repository${NC}"
    all_good=false
fi

# Summary
echo -e "\n${BLUE}════════════════════════════════════════════════${NC}"
if $all_good; then
    echo -e "${GREEN}✅ All checks passed! Orchestrator is ready.${NC}\n"
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "  1. cd ${ORCHESTRATOR_DIR}"
    echo -e "  2. ./QUICKSTART.sh"
    echo -e "  3. Choose your launch option"
    echo -e "  4. Monitor with ./dashboard.py"
    echo -e "\n${BLUE}Good luck, Czar! 🎭${NC}\n"
    exit 0
else
    echo -e "${RED}❌ Some checks failed. Please fix the issues above.${NC}\n"
    exit 1
fi
