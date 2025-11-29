#!/bin/bash
# Automated Claude Code Worker Launcher
# Spins up Claude Code instances with their tasks pre-loaded

set -euo pipefail

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🤖 Automated Claude Code Worker Launcher                    ║
║                                                               ║
║   Spawning AI workers...                                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

echo -e "${YELLOW}Choose your deployment method:${NC}\n"
echo "1. Browser-based (open claude.ai in browser tabs)"
echo "2. VS Code Extension (if you have Claude extension installed)"
echo "3. Generate startup commands (manual copy-paste)"
echo "4. Create worker instruction files (for any AI assistant)"
echo ""
read -p "Choose option (1-4): " method
echo ""

case $method in
    1)
        echo -e "${CYAN}🌐 Launching Claude Code workers in browser...${NC}\n"

        # Check for browser
        if command -v xdg-open &> /dev/null; then
            BROWSER_CMD="xdg-open"
        elif command -v wslview &> /dev/null; then
            BROWSER_CMD="wslview"
        else
            echo -e "${RED}❌ No browser launcher found${NC}"
            echo "Please open https://claude.ai manually and paste the prompts."
            exit 1
        fi

        # Launch browser tabs with Claude
        workers=($(printf '%s\n' "${WORKER_DEFINITIONS[@]}" | cut -d'|' -f1))

        for worker_id in "${workers[@]}"; do
            echo -e "${GREEN}🚀 Opening browser for ${worker_id}...${NC}"

            # Open Claude.ai in new tab
            $BROWSER_CMD "https://claude.ai/new" &
            sleep 2

            # Show prompt that needs to be pasted
            echo -e "${YELLOW}📋 Copy this prompt for ${worker_id}:${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            cat "${PROMPTS_DIR}/${worker_id}-prompt.md" | head -20
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo -e "${CYAN}Full prompt: ${PROMPTS_DIR}/${worker_id}-prompt.md${NC}\n"

            read -p "Press Enter when you've pasted the prompt and Claude has started..."
        done
        ;;

    2)
        echo -e "${CYAN}📝 Launching VS Code with Claude extension...${NC}\n"

        if ! command -v code &> /dev/null; then
            echo -e "${RED}❌ VS Code not found${NC}"
            echo "Please install VS Code or use another method."
            exit 1
        fi

        # Create workspace for workers
        mkdir -p "${ORCHESTRATOR_DIR}/workspace"

        workers=($(printf '%s\n' "${WORKER_DEFINITIONS[@]}" | cut -d'|' -f1))

        for worker_id in "${workers[@]}"; do
            echo -e "${GREEN}🚀 Creating workspace for ${worker_id}...${NC}"

            # Create a file with the prompt as starting point
            cat > "${ORCHESTRATOR_DIR}/workspace/${worker_id}-START_HERE.md" <<WORKSPACE
# ${worker_id} - STARTING POINT

⚠️ **IMPORTANT: Open Claude in VS Code and paste the content below** ⚠️

$(cat "${PROMPTS_DIR}/${worker_id}-prompt.md")

---

## Quick Actions

Once Claude responds, you can:
1. Let Claude read the task file
2. Let Claude checkout the branch
3. Let Claude start implementing
4. Monitor progress via dashboard: \`cd ${ORCHESTRATOR_DIR} && ./dashboard.py\`

WORKSPACE

            # Open in VS Code
            code "${ORCHESTRATOR_DIR}/workspace/${worker_id}-START_HERE.md" &
            sleep 1
        done

        echo ""
        echo -e "${GREEN}✅ Workspaces created!${NC}\n"
        echo -e "${YELLOW}Next steps:${NC}"
        echo "1. In each VS Code window, select all (Ctrl+A)"
        echo "2. Open Claude panel (if you have the extension)"
        echo "3. Copy the prompt content and paste to Claude"
        echo "4. Claude will start working!"
        ;;

    3)
        echo -e "${CYAN}📋 Generating startup commands...${NC}\n"

        cat > "${ORCHESTRATOR_DIR}/START_WORKERS.sh" <<'STARTER'
#!/bin/bash
# Worker startup commands
# Execute these commands in separate terminal windows/tabs

ORCHESTRATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║  Copy each command below to a separate terminal/tab          ║
╚═══════════════════════════════════════════════════════════════╝

STARTER

        workers=($(printf '%s\n' "${WORKER_DEFINITIONS[@]}" | cut -d'|' -f1))

        for worker_id in "${workers[@]}"; do
            cat >> "${ORCHESTRATOR_DIR}/START_WORKERS.sh" <<STARTER

# ━━━ ${worker_id} ━━━
echo "Worker: ${worker_id}"
cat "${ORCHESTRATOR_DIR}/prompts/${worker_id}-prompt.md"
echo ""
echo "Paste the above prompt to a Claude Code instance."
echo ""

STARTER
        done

        cat >> "${ORCHESTRATOR_DIR}/START_WORKERS.sh" <<'STARTER'
EOF
STARTER

        chmod +x "${ORCHESTRATOR_DIR}/START_WORKERS.sh"

        echo -e "${GREEN}✅ Startup commands generated!${NC}\n"
        echo "Run: ./START_WORKERS.sh"
        echo "Then copy each section to a different Claude instance."
        ;;

    4)
        echo -e "${CYAN}📝 Creating worker instruction files...${NC}\n"

        mkdir -p "${ORCHESTRATOR_DIR}/worker-instructions"

        workers=($(printf '%s\n' "${WORKER_DEFINITIONS[@]}" | cut -d'|' -f1))

        for worker_id in "${workers[@]}"; do
            # Get worker details
            for def in "${WORKER_DEFINITIONS[@]}"; do
                IFS='|' read -r wid branch task_file description <<< "$def"
                if [ "$wid" = "$worker_id" ]; then
                    break
                fi
            done

            cat > "${ORCHESTRATOR_DIR}/worker-instructions/${worker_id}-INSTRUCTIONS.md" <<INSTRUCTIONS
# ${description}

## 🎯 Your Assignment

You are **${description}** working on the ${PROJECT_NAME} project.

## 📋 Task File

Your complete task list is here:
\`${PROJECT_ROOT}/${task_file}\`

Read this file first to understand your deliverables.

## 🌿 Your Branch

\`${branch}\`

You will work on this branch exclusively.

## 📦 Repository

\`${PROJECT_ROOT}\`

## 🚀 Getting Started

\`\`\`bash
cd ${PROJECT_ROOT}
git checkout main
git pull origin main
git checkout -b ${branch}
cat ${task_file}
\`\`\`

## 📚 Reference Documents

- Coordination: \`${PROJECT_ROOT}/docs/gateway-integration/COORDINATION.md\`
- Worker Assignments: \`${PROJECT_ROOT}/docs/gateway-integration/WORKER_ASSIGNMENTS.md\`
- Implementation Plan: \`${PROJECT_ROOT}/IMPLEMENTATION_PLAN_v1.1_GATEWAY.md\`

## 🎯 Your Mission

$(cat "${PROMPTS_DIR}/${worker_id}-prompt.md")

## ✅ Success Criteria

When you're done:
1. All files created/modified per task file
2. Unit tests passing with >85% coverage
3. Code quality checks passing (mypy, black, ruff)
4. PR created to main
5. No P0/P1 security issues

## 📞 Communication

- Post daily status updates
- Report blockers immediately
- Request reviews when ready

---

**NOW BEGIN YOUR WORK!**

Start by reading your task file, then begin implementation.

INSTRUCTIONS

            echo -e "${GREEN}✅ Created: worker-instructions/${worker_id}-INSTRUCTIONS.md${NC}"
        done

        echo ""
        echo -e "${GREEN}✅ All worker instruction files created!${NC}\n"
        echo -e "${YELLOW}Location:${NC} ${ORCHESTRATOR_DIR}/worker-instructions/"
        echo ""
        echo -e "${YELLOW}Usage:${NC}"
        echo "1. Open 6 Claude Code instances (browser, VS Code, etc.)"
        echo "2. In each instance, paste the content from one instruction file"
        echo "3. Claude will read it and start working immediately!"
        echo ""
        echo -e "${CYAN}Example:${NC}"
        echo "  cat worker-instructions/engineer1-INSTRUCTIONS.md | pbcopy"
        echo "  # Then paste into Claude Code instance #1"
        ;;

    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Workers ready to launch!${NC}\n"
echo -e "${CYAN}Monitor progress:${NC}"
echo "  cd ${ORCHESTRATOR_DIR}"
echo "  ./dashboard.py"
echo ""
echo -e "${CYAN}Manage PRs when ready:${NC}"
echo "  ./pr-manager.sh"
echo ""
echo -e "${YELLOW}🎸 Let the vibecoding begin!${NC}"
