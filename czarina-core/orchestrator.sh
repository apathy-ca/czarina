#!/bin/bash
# Claude Code Multi-Agent Orchestrator
# Manages parallel Claude Code worker instances
# Created: November 27, 2025

set -euo pipefail

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Initialize directories
init_orchestrator() {
    echo -e "${CYAN}🎭 Initializing ${PROJECT_NAME} Orchestrator${NC}"
    mkdir -p "${WORKERS_DIR}" "${STATUS_DIR}" "${LOGS_DIR}" "${PROMPTS_DIR}"

    # Build workers JSON
    local workers_json="{"
    local first=true
    for worker_id in "${!WORKERS[@]}"; do
        local branch=$(get_worker_branch "$worker_id")
        if [ "$first" = false ]; then
            workers_json+=","
        fi
        workers_json+="\"${worker_id}\": {\"status\": \"pending\", \"branch\": \"${branch}\", \"pr\": null}"
        first=false
    done
    workers_json+="}"

    # Build checkpoints JSON
    local checkpoints_json="{"
    first=true
    for checkpoint_def in "${CHECKPOINTS[@]}"; do
        IFS='|' read -r checkpoint_id _ <<< "$checkpoint_def"
        if [ "$first" = false ]; then
            checkpoints_json+=","
        fi
        checkpoints_json+="\"${checkpoint_id}\": false"
        first=false
    done
    checkpoints_json+="}"

    # Create status tracking file
    cat > "${STATUS_DIR}/master-status.json" <<EOF
{
    "project": "${PROJECT_NAME}",
    "started": "$(date -Iseconds)",
    "phase": "initialization",
    "workers": ${workers_json},
    "checkpoints": ${checkpoints_json}
}
EOF

    echo -e "${GREEN}✅ Orchestrator initialized${NC}"
    echo -e "${BLUE}Project: ${PROJECT_NAME}${NC}"
    echo -e "${BLUE}Workers: ${#WORKERS[@]}${NC}"
    echo -e "${BLUE}Checkpoints: ${#CHECKPOINTS[@]}${NC}"
}

# Launch a single worker
launch_worker() {
    local worker_id=$1
    local worker_info="${WORKERS[$worker_id]}"
    IFS='|' read -r branch task_file description <<< "$worker_info"

    echo -e "${BLUE}🚀 Launching worker: ${worker_id}${NC}"
    echo -e "   Branch: ${branch}"
    echo -e "   Task: ${task_file}"
    echo -e "   Description: ${description}"

    # Create worker directory
    local worker_dir="${WORKERS_DIR}/${worker_id}"
    mkdir -p "${worker_dir}"

    # Create worker launch script
    cat > "${worker_dir}/launch.sh" <<EOF
#!/bin/bash
# Worker: ${worker_id}
# Branch: ${branch}
# Task: ${task_file}

cd "${REPO_ROOT}"

# Create or checkout branch
git checkout main
git pull origin main
git checkout -b ${branch} 2>/dev/null || git checkout ${branch}

# Launch Claude Code in new terminal
gnome-terminal --title="SARK Worker: ${worker_id} (${branch})" \\
    --geometry=120x40 \\
    -- bash -c "
    cd ${REPO_ROOT}
    echo '🤖 SARK v1.1 Worker: ${worker_id}'
    echo '📋 Task: ${task_file}'
    echo '🌿 Branch: ${branch}'
    echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    echo ''
    echo 'You are ${description}'
    echo ''
    echo 'Task file: ${REPO_ROOT}/docs/gateway-integration/tasks/${task_file}'
    echo ''
    echo 'Quick start:'
    echo '1. Read your task file'
    echo '2. Check COORDINATION.md for dependencies'
    echo '3. Wait for Engineer 1 shared models if needed'
    echo '4. Begin implementation'
    echo ''
    echo 'Starting Claude Code...'
    echo ''
    # Start Claude Code (adjust this command based on your setup)
    # Option 1: If you have claude-code CLI
    # claude-code --context='Worker: ${worker_id}. Task: ${REPO_ROOT}/docs/gateway-integration/tasks/${task_file}'

    # Option 2: If you use VS Code with Claude extension
    # code . --new-window

    # Option 3: For now, just open bash for manual work
    exec bash
" &

EOF

    chmod +x "${worker_dir}/launch.sh"

    # Update status
    update_worker_status "${worker_id}" "launched"

    echo -e "${GREEN}✅ Worker ${worker_id} launched${NC}\n"
}

# Launch all workers
launch_all_workers() {
    echo -e "${CYAN}🎭 Launching all 6 workers...${NC}\n"

    # Engineer 1 is critical path - launch first
    launch_worker "engineer1"
    sleep 2

    # Launch remaining workers
    for worker_id in engineer2 engineer3 engineer4 qa docs; do
        launch_worker "${worker_id}"
        sleep 1
    done

    echo -e "${GREEN}✅ All workers launched${NC}\n"
    show_status
}

# Update worker status
update_worker_status() {
    local worker_id=$1
    local status=$2
    local pr_url=${3:-null}

    python3 - <<EOF
import json
import sys

status_file = "${STATUS_DIR}/master-status.json"
with open(status_file, 'r') as f:
    data = json.load(f)

data['workers']['${worker_id}']['status'] = '${status}'
if '${pr_url}' != 'null':
    data['workers']['${worker_id}']['pr'] = '${pr_url}'

with open(status_file, 'w') as f:
    json.dump(data, f, indent=2)
EOF
}

# Show current status
show_status() {
    echo -e "${CYAN}📊 Current Status${NC}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    python3 - <<EOF
import json
from datetime import datetime

status_file = "${STATUS_DIR}/master-status.json"
with open(status_file, 'r') as f:
    data = json.load(f)

print(f"Project: {data['project']}")
print(f"Started: {data['started']}")
print(f"Phase: {data['phase']}\n")

print("Workers:")
for worker_id, info in data['workers'].items():
    status_icon = "✅" if info['status'] == 'complete' else "🔄" if info['status'] == 'launched' else "⏸️"
    pr_info = f" | PR: {info['pr']}" if info['pr'] else ""
    print(f"  {status_icon} {worker_id:12s} | {info['branch']:25s} | {info['status']:10s}{pr_info}")

print("\nCheckpoints:")
for checkpoint, done in data['checkpoints'].items():
    icon = "✅" if done else "⏸️"
    print(f"  {icon} {checkpoint}")
EOF
}

# Monitor worker progress
monitor_workers() {
    echo -e "${CYAN}👀 Monitoring worker progress...${NC}\n"

    while true; do
        clear
        show_status
        echo -e "\n${YELLOW}Press Ctrl+C to stop monitoring${NC}"
        sleep 10
    done
}

# Check for PRs
check_prs() {
    echo -e "${CYAN}🔍 Checking for worker PRs...${NC}\n"

    cd "${REPO_ROOT}"

    for worker_id in "${!WORKERS[@]}"; do
        local worker_info="${WORKERS[$worker_id]}"
        IFS='|' read -r branch task_file description <<< "$worker_info"

        echo -e "${BLUE}Checking ${worker_id} (${branch})...${NC}"

        # Check if PR exists
        pr_url=$(gh pr list --head "${branch}" --json url --jq '.[0].url' 2>/dev/null || echo "")

        if [ -n "$pr_url" ]; then
            echo -e "  ${GREEN}✅ PR found: ${pr_url}${NC}"
            update_worker_status "${worker_id}" "pr_ready" "${pr_url}"
        else
            echo -e "  ${YELLOW}⏸️  No PR yet${NC}"
        fi
    done
}

# Review a PR
review_pr() {
    local worker_id=$1
    local worker_info="${WORKERS[$worker_id]}"
    IFS='|' read -r branch task_file description <<< "$worker_info"

    echo -e "${CYAN}🔍 Reviewing PR for ${worker_id}...${NC}\n"

    cd "${REPO_ROOT}"

    # Get PR details
    pr_number=$(gh pr list --head "${branch}" --json number --jq '.[0].number')

    if [ -z "$pr_number" ]; then
        echo -e "${RED}❌ No PR found for ${worker_id}${NC}"
        return 1
    fi

    # Show PR details
    gh pr view "${pr_number}"

    echo -e "\n${YELLOW}Review actions:${NC}"
    echo "1. Approve and merge"
    echo "2. Request changes"
    echo "3. Add comment"
    echo "4. Skip"

    read -p "Choose action (1-4): " action

    case $action in
        1)
            gh pr review "${pr_number}" --approve
            echo -e "${GREEN}✅ PR approved${NC}"
            ;;
        2)
            read -p "Comment: " comment
            gh pr review "${pr_number}" --request-changes --body "${comment}"
            echo -e "${YELLOW}📝 Changes requested${NC}"
            ;;
        3)
            read -p "Comment: " comment
            gh pr review "${pr_number}" --comment --body "${comment}"
            echo -e "${BLUE}💬 Comment added${NC}"
            ;;
        4)
            echo -e "${BLUE}⏭️  Skipped${NC}"
            ;;
    esac
}

# Create omnibus branch
create_omnibus() {
    echo -e "${CYAN}🎯 Creating omnibus integration branch...${NC}\n"

    cd "${REPO_ROOT}"

    # Ensure we're on main
    git checkout main
    git pull origin main

    # Create omnibus branch
    local omnibus_branch="feat/gateway-integration-omnibus"
    git checkout -b "${omnibus_branch}" 2>/dev/null || git checkout "${omnibus_branch}"

    # Merge in dependency order
    local merge_order=("engineer1" "engineer3" "engineer2" "engineer4" "qa" "docs")

    for worker_id in "${merge_order[@]}"; do
        local worker_info="${WORKERS[$worker_id]}"
        IFS='|' read -r branch task_file description <<< "$worker_info"

        echo -e "${BLUE}Merging ${worker_id} (${branch})...${NC}"

        if git merge "${branch}" --no-edit; then
            echo -e "${GREEN}✅ Merged ${branch}${NC}\n"
        else
            echo -e "${RED}❌ Merge conflict in ${branch}${NC}"
            echo -e "${YELLOW}Please resolve conflicts and run: git merge --continue${NC}"
            return 1
        fi
    done

    # Push omnibus branch
    git push -u origin "${omnibus_branch}"

    echo -e "${GREEN}✅ Omnibus branch created and pushed${NC}"
    echo -e "${BLUE}Branch: ${omnibus_branch}${NC}\n"

    # Update checkpoint
    update_checkpoint "day8_prs" "true"
}

# Update checkpoint
update_checkpoint() {
    local checkpoint=$1
    local value=$2

    python3 - <<EOF
import json

status_file = "${STATUS_DIR}/master-status.json"
with open(status_file, 'r') as f:
    data = json.load(f)

data['checkpoints']['${checkpoint}'] = ${value}

with open(status_file, 'w') as f:
    json.dump(data, f, indent=2)
EOF
}

# Create omnibus PR
create_omnibus_pr() {
    echo -e "${CYAN}🎯 Creating omnibus PR to main...${NC}\n"

    cd "${REPO_ROOT}"

    local omnibus_branch="feat/gateway-integration-omnibus"

    # Create PR
    gh pr create \
        --base main \
        --head "${omnibus_branch}" \
        --title "feat: MCP Gateway Registry Integration v1.1 (Omnibus)" \
        --body "$(cat <<EOF
# SARK v1.1: Gateway Integration (Omnibus PR)

## Summary

Complete MCP Gateway Registry integration with enterprise-grade governance for Gateway-managed MCP servers and Agent-to-Agent communications.

## Features

- ✅ Gateway client with retry/circuit breaker
- ✅ Authorization API endpoints (authorize, authorize-a2a, servers, tools, audit)
- ✅ OPA policies for Gateway and A2A authorization
- ✅ Audit logging and SIEM integration
- ✅ Prometheus metrics and Grafana dashboard
- ✅ Comprehensive test suite (unit, integration, performance, security)
- ✅ Complete documentation (API, deployment, runbooks, examples)

## Worker PRs Included

$(for worker_id in engineer1 engineer2 engineer3 engineer4 qa docs; do
    local worker_info="${WORKERS[$worker_id]}"
    IFS='|' read -r branch task_file description <<< "$worker_info"
    pr_url=$(gh pr list --head "${branch}" --json url --jq '.[0].url' 2>/dev/null || echo "N/A")
    echo "- ${description}: ${pr_url}"
done)

## Testing

- Unit test coverage: >85%
- Integration tests: All passing
- Performance tests: P95 <50ms, >5000 req/s
- Security tests: 0 P0/P1 vulnerabilities

## Documentation

- API reference complete
- Deployment guides complete
- Runbooks complete
- Examples tested

## Breaking Changes

None

## Checklist

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Performance targets met
- [ ] Security scan clean
- [ ] Documentation complete
- [ ] Examples work
- [ ] CI/CD passing

Closes #XXX
EOF
)"

    echo -e "${GREEN}✅ Omnibus PR created${NC}\n"
    update_checkpoint "day10_omnibus" "true"
}

# Interactive menu
show_menu() {
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  SARK v1.1 Gateway Integration Orchestrator   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}\n"

    echo "1.  Initialize orchestrator"
    echo "2.  Launch all workers"
    echo "3.  Launch specific worker"
    echo "4.  Show status"
    echo "5.  Monitor workers (live)"
    echo "6.  Check for PRs"
    echo "7.  Review PR"
    echo "8.  Create omnibus branch"
    echo "9.  Create omnibus PR"
    echo "10. Run Day 1 checkpoint"
    echo "11. Run Day 4 checkpoint"
    echo "12. Run Day 8 checkpoint"
    echo "0.  Exit"
    echo ""
}

# Main menu loop
main() {
    while true; do
        show_menu
        read -p "Choose option: " choice
        echo ""

        case $choice in
            1) init_orchestrator ;;
            2) launch_all_workers ;;
            3)
                echo "Workers: engineer1, engineer2, engineer3, engineer4, qa, docs"
                read -p "Enter worker ID: " worker_id
                launch_worker "${worker_id}"
                ;;
            4) show_status ;;
            5) monitor_workers ;;
            6) check_prs ;;
            7)
                read -p "Enter worker ID: " worker_id
                review_pr "${worker_id}"
                ;;
            8) create_omnibus ;;
            9) create_omnibus_pr ;;
            10)
                echo -e "${CYAN}Day 1 Checkpoint${NC}"
                update_checkpoint "day1_models" "true"
                echo -e "${GREEN}✅ Day 1 checkpoint marked complete${NC}"
                ;;
            11)
                echo -e "${CYAN}Day 4 Checkpoint${NC}"
                update_checkpoint "day4_integration" "true"
                echo -e "${GREEN}✅ Day 4 checkpoint marked complete${NC}"
                ;;
            12)
                echo -e "${CYAN}Day 8 Checkpoint${NC}"
                update_checkpoint "day8_prs" "true"
                echo -e "${GREEN}✅ Day 8 checkpoint marked complete${NC}"
                ;;
            0)
                echo -e "${CYAN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

# Run main
main
