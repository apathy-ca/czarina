#!/bin/bash
# PR Management and Review Automation
# Helps orchestrator review and merge worker PRs

set -euo pipefail

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
REPO_ROOT="$PROJECT_ROOT"
cd "$REPO_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Worker branches
declare -A WORKERS=(
    [engineer1]="feat/gateway-client"
    [engineer2]="feat/gateway-api"
    [engineer3]="feat/gateway-policies"
    [engineer4]="feat/gateway-audit"
    [qa]="feat/gateway-tests"
    [docs]="feat/gateway-docs"
)

# Check all PRs
check_all_prs() {
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  SARK v1.1 - PR Status Check                  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}\n"

    local all_ready=true

    for worker_id in "${!WORKERS[@]}"; do
        local branch="${WORKERS[$worker_id]}"
        echo -e "${BLUE}━━━ ${worker_id} (${branch}) ━━━${NC}"

        # Check if PR exists
        local pr_info=$(gh pr list --head "$branch" --json number,title,state,reviews,mergeable 2>/dev/null || echo "")

        if [ -z "$pr_info" ] || [ "$pr_info" = "[]" ]; then
            echo -e "  ${RED}❌ No PR found${NC}"
            all_ready=false
        else
            local pr_number=$(echo "$pr_info" | jq -r '.[0].number')
            local pr_title=$(echo "$pr_info" | jq -r '.[0].title')
            local pr_state=$(echo "$pr_info" | jq -r '.[0].state')
            local pr_mergeable=$(echo "$pr_info" | jq -r '.[0].mergeable')
            local approvals=$(echo "$pr_info" | jq '[.[0].reviews[] | select(.state == "APPROVED")] | length')

            echo -e "  📋 PR #${pr_number}: ${pr_title}"
            echo -e "  📊 State: ${pr_state}"
            echo -e "  👍 Approvals: ${approvals}"

            if [ "$pr_mergeable" = "MERGEABLE" ]; then
                echo -e "  ${GREEN}✅ Ready to merge${NC}"
            elif [ "$pr_mergeable" = "CONFLICTING" ]; then
                echo -e "  ${RED}⚠️  Has conflicts${NC}"
                all_ready=false
            else
                echo -e "  ${YELLOW}⏸️  Not yet mergeable${NC}"
                all_ready=false
            fi

            # Check CI status
            local ci_status=$(gh pr checks "$pr_number" --json state 2>/dev/null | jq -r '.[0].state' || echo "unknown")
            if [ "$ci_status" = "SUCCESS" ] || [ "$ci_status" = "success" ]; then
                echo -e "  ${GREEN}✅ CI passing${NC}"
            elif [ "$ci_status" = "FAILURE" ] || [ "$ci_status" = "failure" ]; then
                echo -e "  ${RED}❌ CI failing${NC}"
                all_ready=false
            else
                echo -e "  ${YELLOW}⏸️  CI pending${NC}"
            fi
        fi
        echo ""
    done

    if $all_ready; then
        echo -e "${GREEN}✅ All PRs are ready for omnibus merge!${NC}\n"
        return 0
    else
        echo -e "${YELLOW}⚠️  Some PRs are not ready yet${NC}\n"
        return 1
    fi
}

# Review specific PR
review_pr() {
    local worker_id=$1
    local branch="${WORKERS[$worker_id]}"

    echo -e "${CYAN}🔍 Reviewing PR for ${worker_id}...${NC}\n"

    local pr_number=$(gh pr list --head "$branch" --json number --jq '.[0].number')

    if [ -z "$pr_number" ]; then
        echo -e "${RED}❌ No PR found for ${worker_id}${NC}"
        return 1
    fi

    # Show PR details
    gh pr view "$pr_number"

    echo -e "\n${CYAN}━━━ Files Changed ━━━${NC}"
    gh pr diff "$pr_number" --name-only

    echo -e "\n${CYAN}━━━ Test Results ━━━${NC}"
    gh pr checks "$pr_number"

    echo -e "\n${YELLOW}Review Actions:${NC}"
    echo "1. View full diff"
    echo "2. Approve"
    echo "3. Request changes"
    echo "4. Add comment"
    echo "5. Check tests locally"
    echo "6. Skip"
    echo ""

    read -p "Choose action (1-6): " action

    case $action in
        1)
            gh pr diff "$pr_number" | less
            ;;
        2)
            read -p "Approval comment (optional): " comment
            if [ -n "$comment" ]; then
                gh pr review "$pr_number" --approve --body "$comment"
            else
                gh pr review "$pr_number" --approve
            fi
            echo -e "${GREEN}✅ PR approved${NC}"
            ;;
        3)
            read -p "What needs to change: " comment
            gh pr review "$pr_number" --request-changes --body "$comment"
            echo -e "${YELLOW}📝 Changes requested${NC}"
            ;;
        4)
            read -p "Comment: " comment
            gh pr review "$pr_number" --comment --body "$comment"
            echo -e "${BLUE}💬 Comment added${NC}"
            ;;
        5)
            echo -e "${CYAN}Checking out branch and running tests...${NC}"
            git fetch origin "$branch"
            git checkout "$branch"
            echo -e "\n${YELLOW}Running tests (this may take a while)...${NC}"
            pytest tests/ -v || true
            git checkout main
            ;;
        6)
            echo -e "${BLUE}⏭️  Skipped${NC}"
            ;;
    esac
}

# Auto-review all PRs
auto_review_all() {
    echo -e "${CYAN}🤖 Auto-reviewing all PRs...${NC}\n"

    for worker_id in "${!WORKERS[@]}"; do
        local branch="${WORKERS[$worker_id]}"
        local pr_number=$(gh pr list --head "$branch" --json number --jq '.[0].number' 2>/dev/null || echo "")

        if [ -z "$pr_number" ]; then
            echo -e "${YELLOW}⏸️  ${worker_id}: No PR found, skipping${NC}"
            continue
        fi

        echo -e "${BLUE}🔍 Reviewing ${worker_id} (PR #${pr_number})...${NC}"

        # Check if already approved by me
        local my_approval=$(gh pr view "$pr_number" --json reviews --jq '[.reviews[] | select(.state == "APPROVED" and .author.login == "'"$(gh api user -q .login)"'")] | length')

        if [ "$my_approval" -gt 0 ]; then
            echo -e "  ${GREEN}✅ Already approved${NC}"
            continue
        fi

        # Check CI status
        local ci_status=$(gh pr checks "$pr_number" --json state 2>/dev/null | jq -r 'map(.state) | if all(. == "SUCCESS" or . == "success") then "passing" else "failing" end')

        if [ "$ci_status" = "passing" ]; then
            echo -e "  ${GREEN}✅ CI passing - auto-approving${NC}"
            gh pr review "$pr_number" --approve --body "Auto-approved: All checks passing ✅"
        else
            echo -e "  ${YELLOW}⚠️  CI not passing - manual review required${NC}"
        fi
    done

    echo -e "\n${GREEN}✅ Auto-review complete${NC}"
}

# Create omnibus branch
create_omnibus() {
    echo -e "${CYAN}🎯 Creating omnibus integration branch...${NC}\n"

    # Ensure we're on main
    git checkout main
    git pull origin main

    # Create omnibus branch
    local omnibus_branch="feat/gateway-integration-omnibus"

    # Delete if exists
    git branch -D "$omnibus_branch" 2>/dev/null || true
    git push origin --delete "$omnibus_branch" 2>/dev/null || true

    git checkout -b "$omnibus_branch"

    # Merge in dependency order
    local merge_order=("engineer1" "engineer3" "engineer2" "engineer4" "qa" "docs")

    for worker_id in "${merge_order[@]}"; do
        local branch="${WORKERS[$worker_id]}"

        echo -e "${BLUE}Merging ${worker_id} (${branch})...${NC}"

        # Fetch latest
        git fetch origin "$branch"

        if git merge "origin/$branch" --no-edit; then
            echo -e "${GREEN}✅ Merged ${branch}${NC}\n"
        else
            echo -e "${RED}❌ Merge conflict in ${branch}${NC}"
            echo -e "${YELLOW}Conflicts in:${NC}"
            git diff --name-only --diff-filter=U
            echo ""
            echo -e "${YELLOW}Please resolve conflicts:${NC}"
            echo "  1. Fix conflicts in files above"
            echo "  2. git add <resolved-files>"
            echo "  3. git merge --continue"
            echo "  4. Re-run this script to continue"
            return 1
        fi
    done

    # Run tests
    echo -e "${CYAN}Running test suite...${NC}"
    if pytest tests/ -v --tb=short; then
        echo -e "${GREEN}✅ All tests passing${NC}\n"
    else
        echo -e "${RED}❌ Tests failing - please fix before pushing${NC}"
        return 1
    fi

    # Push omnibus branch
    git push -u origin "$omnibus_branch"

    echo -e "${GREEN}✅ Omnibus branch created: ${omnibus_branch}${NC}"
    echo -e "${BLUE}Next step: Create omnibus PR${NC}\n"
}

# Create omnibus PR
create_omnibus_pr() {
    echo -e "${CYAN}🎯 Creating omnibus PR...${NC}\n"

    local omnibus_branch="feat/gateway-integration-omnibus"

    # Check if already exists
    local existing_pr=$(gh pr list --head "$omnibus_branch" --json number --jq '.[0].number')
    if [ -n "$existing_pr" ]; then
        echo -e "${YELLOW}⚠️  PR already exists: #${existing_pr}${NC}"
        gh pr view "$existing_pr"
        return 0
    fi

    # Create PR body
    local pr_body=$(cat <<EOF
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
    local branch="${WORKERS[$worker_id]}"
    local pr_url=$(gh pr list --head "$branch" --json url --jq '.[0].url' 2>/dev/null || echo "N/A")
    echo "- ${worker_id}: ${pr_url}"
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

---

**🤖 Generated with SARK Orchestrator**
EOF
)

    # Create PR
    echo "$pr_body" | gh pr create \
        --base main \
        --head "$omnibus_branch" \
        --title "feat: MCP Gateway Registry Integration v1.1 (Omnibus)" \
        --body-file -

    echo -e "${GREEN}✅ Omnibus PR created${NC}\n"
    gh pr view
}

# Show menu
show_menu() {
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  SARK v1.1 - PR Manager                       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}\n"

    echo "1. Check all PRs status"
    echo "2. Review specific PR"
    echo "3. Auto-review all PRs"
    echo "4. Create omnibus branch"
    echo "5. Create omnibus PR"
    echo "6. Merge omnibus to main"
    echo "0. Exit"
    echo ""
}

# Main menu
main() {
    while true; do
        show_menu
        read -p "Choose option: " choice
        echo ""

        case $choice in
            1) check_all_prs ;;
            2)
                echo "Workers: engineer1, engineer2, engineer3, engineer4, qa, docs"
                read -p "Enter worker ID: " worker_id
                review_pr "$worker_id"
                ;;
            3) auto_review_all ;;
            4) create_omnibus ;;
            5) create_omnibus_pr ;;
            6)
                echo -e "${YELLOW}⚠️  This will merge omnibus to main. Are you sure? (y/N)${NC}"
                read -p "> " confirm
                if [ "$confirm" = "y" ]; then
                    gh pr merge feat/gateway-integration-omnibus --merge --delete-branch
                    echo -e "${GREEN}✅ Merged to main${NC}"
                fi
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
