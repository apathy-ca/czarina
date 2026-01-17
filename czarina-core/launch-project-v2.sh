#!/bin/bash
# Czarina Project Launcher v2
# Launches all workers with improved UX:
# - Auto-starts daemon and dashboard
# - Simple worker numbering (1, 2, 3...)
# - Czar in window 0
# - Management session for overflow + services

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get czarina directory (passed as first argument)
CZARINA_DIR="${1:-}"

if [ -z "$CZARINA_DIR" ] || [ ! -d "$CZARINA_DIR" ]; then
    echo -e "${RED}❌ Usage: $0 <czarina-dir>${NC}"
    echo "   Example: $0 /path/to/project/.czarina"
    exit 1
fi

# Load configuration
CONFIG_FILE="${CZARINA_DIR}/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Config file not found: ${CONFIG_FILE}${NC}"
    exit 1
fi

# Validate config (branch naming, phase, etc.)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/validate-config.sh" ]; then
    "${SCRIPT_DIR}/validate-config.sh" "$CONFIG_FILE" || {
        echo -e "${RED}❌ Fix config errors before launching${NC}"
        exit 1
    }
fi

# Check for required tools
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is required but not installed${NC}"
    echo "   Install: sudo apt install jq"
    exit 1
fi

if ! command -v tmux &> /dev/null; then
    echo -e "${RED}❌ tmux is required but not installed${NC}"
    echo "   Install: sudo apt install tmux"
    exit 1
fi

PROJECT_NAME=$(jq -r '.project.name' "$CONFIG_FILE")
PROJECT_SLUG=$(jq -r '.project.slug' "$CONFIG_FILE")
PROJECT_ROOT=$(jq -r '.project.repository' "$CONFIG_FILE")
CURRENT_PHASE=$(jq -r '.project.phase // 1' "$CONFIG_FILE")

# Phase filtering support
# Set PHASE_FILTER env var to launch only workers for a specific phase
PHASE_FILTER="${PHASE_FILTER:-$CURRENT_PHASE}"

# Get orchestrator directory (where czarina executable lives)
ORCHESTRATOR_DIR="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"

# Create worktrees directory for workers
WORKTREES_DIR="${PROJECT_ROOT}/.czarina/worktrees"
mkdir -p "$WORKTREES_DIR"

# Make sure we're on a safe branch (main) before creating worktrees
echo -e "${BLUE}🔄 Preparing repository for multi-worker launch...${NC}"
cd "$PROJECT_ROOT"

# Clean up any stale worktree references
echo "   Cleaning up stale worktrees..."
git worktree prune 2>/dev/null || true

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo "   Switching from ${CURRENT_BRANCH} to main for worktree setup..."
    git checkout main 2>/dev/null || git checkout master 2>/dev/null || {
        echo -e "${YELLOW}   ⚠️  Could not switch to main/master branch${NC}"
        echo "   Continuing anyway, but some worktrees may fail to create"
    }
fi
echo ""

# Create session name
SESSION_NAME="czarina-${PROJECT_SLUG}"

echo -e "${BLUE}🚀 Launching Czarina Project${NC}"
echo "   Project: $PROJECT_NAME"
echo "   Session: $SESSION_NAME"
echo "   Root: $PROJECT_ROOT"
echo ""

# Helper function: Check if worker belongs to current phase
is_phase_worker() {
    local worker_idx=$1
    local worker_phase=$(jq -r ".workers[$worker_idx].phase // 1" "$CONFIG_FILE")
    [ "$worker_phase" = "$PHASE_FILTER" ]
}

# Get total worker count and phase-filtered count
TOTAL_WORKER_COUNT=$(jq -r '.workers | length' "$CONFIG_FILE")
WORKER_COUNT=0
for idx in $(seq 0 $((TOTAL_WORKER_COUNT - 1))); do
    if is_phase_worker $idx; then
        WORKER_COUNT=$((WORKER_COUNT + 1))
    fi
done

# Session planning:
# - Main session: Window 0 = Czar, Windows 1-9 = Workers 1-9
# - Mgmt session: Workers 10+, Daemon, Dashboard
MAX_WORKERS_IN_MAIN=9

if [ "$PHASE_FILTER" != "$CURRENT_PHASE" ]; then
    echo -e "${BLUE}👷 ${WORKER_COUNT} workers (Phase ${PHASE_FILTER})${NC}"
else
    echo -e "${BLUE}👷 ${WORKER_COUNT} workers${NC}"
fi
if [ $WORKER_COUNT -gt $MAX_WORKERS_IN_MAIN ]; then
    MGMT_SESSION="${SESSION_NAME}-mgmt"
    echo -e "${BLUE}   Main session: Czar + Workers 1-${MAX_WORKERS_IN_MAIN} (windows 0-${MAX_WORKERS_IN_MAIN})${NC}"
    echo -e "${BLUE}   Mgmt session: Workers $((MAX_WORKERS_IN_MAIN + 1))-${WORKER_COUNT}, Daemon, Dashboard${NC}"
else
    MGMT_SESSION="${SESSION_NAME}-mgmt"  # Always create mgmt for daemon/dashboard
    echo -e "${BLUE}   Main session: Czar + Workers 1-${WORKER_COUNT} (windows 0-${WORKER_COUNT})${NC}"
    echo -e "${BLUE}   Mgmt session: Daemon, Dashboard${NC}"
fi
echo ""

# Check if sessions already exist
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Session already exists: ${SESSION_NAME}${NC}"
    echo "   Kill it first: czarina closeout"
    exit 1
fi

if tmux has-session -t "$MGMT_SESSION" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Session already exists: ${MGMT_SESSION}${NC}"
    echo "   Kill it first: czarina closeout"
    exit 1
fi

# Create status directory and track orchestration start time
STATUS_DIR="${CZARINA_DIR}/status"
mkdir -p "$STATUS_DIR"
date +%s > "${STATUS_DIR}/orchestration-start.timestamp"
echo -e "${BLUE}📅 Orchestration started: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

# Function to create worker window
create_worker_window() {
    local session=$1
    local worker_num=$2
    local worker_idx=$3

    local worker_id=$(jq -r ".workers[$worker_idx].id" "$CONFIG_FILE")
    local window_name="$worker_id"  # Use worker ID, not generic "workerN"
    local worker_agent=$(jq -r ".workers[$worker_idx].agent" "$CONFIG_FILE")
    local worker_desc=$(jq -r ".workers[$worker_idx].description" "$CONFIG_FILE")
    local worker_branch=$(jq -r ".workers[$worker_idx].branch" "$CONFIG_FILE")
    local worker_file="${CZARINA_DIR}/workers/${worker_id}.md"

    if [ ! -f "$worker_file" ]; then
        echo -e "${RED}      ⚠️  Worker file not found: ${worker_file}${NC}"
        return
    fi

    echo "   • Worker $worker_num: $worker_id"

    # Create or reuse git worktree
    local worker_dir="${WORKTREES_DIR}/${worker_id}"
    if [ -n "$worker_branch" ] && [ "$worker_branch" != "null" ]; then
        if [ ! -d "$worker_dir" ]; then
            cd "$PROJECT_ROOT"
            echo "      Creating worktree: $worker_dir on branch $worker_branch..."
            if git worktree add "$worker_dir" "$worker_branch" 2>&1; then
                echo "      ✅ Worktree created"
            elif git worktree add -b "$worker_branch" "$worker_dir" 2>&1; then
                echo "      ✅ Worktree created (new branch)"
            else
                echo "      ⚠️  Failed to create worktree, using main directory"
                echo "      Run 'git worktree list' to debug"
                worker_dir="$PROJECT_ROOT"
            fi
        else
            echo "      ↻ Reusing existing worktree: $worker_dir"
        fi
    else
        worker_dir="$PROJECT_ROOT"
        echo "      ℹ  No branch specified, using main directory"
    fi

    # Initialize worker log
    local worker_log="${LOGS_DIR}/${worker_id}.log"
    echo "=== Worker ${worker_id} Started - $(date -Iseconds) ===" > "$worker_log"
    echo "Branch: ${worker_branch}" >> "$worker_log"
    echo "Worktree: ${worker_dir}" >> "$worker_log"
    echo "Agent: ${worker_agent}" >> "$worker_log"
    echo "" >> "$worker_log"

    # Log worker start event
    echo "{\"ts\":\"$(date -Iseconds)\",\"event\":\"WORKER_START\",\"worker\":\"${worker_id}\",\"branch\":\"${worker_branch}\"}" >> "$EVENTS_FILE"

    # Create window
    tmux new-window -t "$session" -n "$window_name"
    tmux send-keys -t "${session}:${window_name}" "cd ${worker_dir}" C-m

    # Export log paths to worker environment
    tmux send-keys -t "${session}:${window_name}" "export CZARINA_WORKER_LOG='${worker_log}'" C-m
    tmux send-keys -t "${session}:${window_name}" "export CZARINA_EVENTS_LOG='${EVENTS_FILE}'" C-m
    tmux send-keys -t "${session}:${window_name}" "export CZARINA_WORKER_ID='${worker_id}'" C-m
    sleep 0.1

    # Display worker info - ONE consolidated output
    tmux send-keys -t "${session}:${window_name}" "clear && cat <<'WORKER_EOF'
═══════════════════════════════════════════════════════════════
🤖 Worker ${worker_num}
📋 ID: ${worker_id}
📝 Role: ${worker_desc}
🔧 Agent: ${worker_agent}
🌿 Branch: ${worker_branch}
📁 Worktree: ${worker_dir}
═══════════════════════════════════════════════════════════════

WORKER_EOF
cat ${worker_file}
cat <<'READY_EOF'

═══════════════════════════════════════════════════════════════

📄 Your instructions are in: .czarina/workers/${worker_id}.md
📁 Working directory: ${worker_dir}
🌿 Branch: ${worker_branch}

✅ Ready to begin! Read your instructions above and start implementing.

READY_EOF
" C-m
    sleep 0.1

    # Auto-launch agent if configured
    if [ -n "$worker_agent" ] && [ "$worker_agent" != "null" ]; then
        echo "      🤖 Launching $worker_agent agent..."
        "${ORCHESTRATOR_DIR}/czarina-core/agent-launcher.sh" launch "$worker_id" "$worker_num" "$worker_agent" "$session"
    fi
}

# Create main session
echo -e "${GREEN}📦 Creating main session: ${SESSION_NAME}${NC}"
tmux new-session -d -s "$SESSION_NAME" -n "czar"
sleep 0.3

# Initialize logging system
echo -e "${BLUE}📝 Initializing logging system...${NC}"

# Source logging functions
source "${ORCHESTRATOR_DIR}/czarina-core/logging.sh"

# Initialize logging directories
LOGS_DIR="${CZARINA_DIR}/logs"
mkdir -p "$LOGS_DIR"

# Initialize orchestration log
ORCH_LOG="${LOGS_DIR}/orchestration.log"
echo "=== Czarina Orchestration Started - $(date -Iseconds) ===" > "$ORCH_LOG"
echo "Project: ${PROJECT_NAME}" >> "$ORCH_LOG"
echo "Session: ${SESSION_NAME}" >> "$ORCH_LOG"
echo "Workers: ${WORKER_COUNT}" >> "$ORCH_LOG"
echo "" >> "$ORCH_LOG"

# Initialize event stream
EVENTS_FILE="${LOGS_DIR}/events.jsonl"
echo "{\"ts\":\"$(date -Iseconds)\",\"event\":\"ORCHESTRATION_START\",\"project\":\"${PROJECT_NAME}\",\"workers\":${WORKER_COUNT}}" > "$EVENTS_FILE"

echo -e "${GREEN}✅ Logging initialized: ${LOGS_DIR}${NC}"

# Set up Czar window (window 0)
echo "   • Window 0: Czar (Orchestrator)"
tmux send-keys -t "${SESSION_NAME}:czar" "cd ${PROJECT_ROOT}" C-m
tmux send-keys -t "${SESSION_NAME}:czar" "clear" C-m

# Check if CZAR.md exists, otherwise show orchestrator info
CZAR_FILE="${CZARINA_DIR}/workers/CZAR.md"
if [ -f "$CZAR_FILE" ]; then
    tmux send-keys -t "${SESSION_NAME}:czar" "cat ${CZAR_FILE}" C-m
else
    tmux send-keys -t "${SESSION_NAME}:czar" "cat <<'CZAR_EOF'
═══════════════════════════════════════════════════════════════
🎭 Czar - Orchestration Coordinator
═══════════════════════════════════════════════════════════════

Project: ${PROJECT_NAME}
Workers: ${WORKER_COUNT}
Session: ${SESSION_NAME}

Your Role:
- Monitor all workers (windows 1-${WORKER_COUNT})
- Manage daemon and dashboard (in mgmt session)
- Coordinate PRs and merges
- Track progress and blockers

Quick Commands:
- Switch windows: Ctrl+b <number>
- List windows: Ctrl+b w
- Switch sessions: Ctrl+b s
- Detach: Ctrl+b d

Workers are in windows 1-9 (and mgmt session if >9)
Daemon and Dashboard are in the mgmt session

✅ All systems ready!
CZAR_EOF
" C-m
fi

# Auto-launch agent for Czar window
CZAR_AGENT=$(jq -r '.czar.agent // "claude"' "$CONFIG_FILE" 2>/dev/null || echo "claude")
if [ -n "$CZAR_AGENT" ] && [ "$CZAR_AGENT" != "null" ]; then
    echo "   🤖 Launching Czar agent..."
    "${ORCHESTRATOR_DIR}/czarina-core/agent-launcher.sh" launch "czar" 0 "$CZAR_AGENT" "$SESSION_NAME"
fi

# Create workers 1-9 in main session (limit to MAX_WORKERS_IN_MAIN)
# Main session has windows 0-9: Window 0 = Czar, Windows 1-9 = Workers 1-9
worker_num=0
for worker_idx in $(seq 0 $((TOTAL_WORKER_COUNT - 1))); do
    if ! is_phase_worker $worker_idx; then
        continue
    fi
    worker_num=$((worker_num + 1))
    if [ $worker_num -le $MAX_WORKERS_IN_MAIN ]; then
        create_worker_window "$SESSION_NAME" $worker_num $worker_idx
    fi
done

# Create management session
echo ""
echo -e "${GREEN}📦 Creating management session: ${MGMT_SESSION}${NC}"
tmux new-session -d -s "$MGMT_SESSION" -n "info"
sleep 0.3

# Info window in mgmt session
tmux send-keys -t "${MGMT_SESSION}:info" "cd ${PROJECT_ROOT}" C-m
tmux send-keys -t "${MGMT_SESSION}:info" "cat <<'INFO_EOF'
═══════════════════════════════════════════════════════════════
📊 Czarina Management Session
═══════════════════════════════════════════════════════════════

Project: ${PROJECT_NAME}
Main Session: ${SESSION_NAME}

This session contains:
INFO_EOF
" C-m

# Create overflow workers (10+) in mgmt session
if [ $WORKER_COUNT -gt $MAX_WORKERS_IN_MAIN ]; then
    tmux send-keys -t "${MGMT_SESSION}:info" "echo '- Workers 10-${WORKER_COUNT}'" C-m
    worker_num=0
    for worker_idx in $(seq 0 $((TOTAL_WORKER_COUNT - 1))); do
        if ! is_phase_worker $worker_idx; then
            continue
        fi
        worker_num=$((worker_num + 1))
        if [ $worker_num -gt $MAX_WORKERS_IN_MAIN ]; then
            create_worker_window "$MGMT_SESSION" $worker_num $worker_idx
        fi
    done
fi

# Install git hooks in all worktrees
echo ""
echo -e "${BLUE}🪝 Installing git hooks in worktrees...${NC}"
"${ORCHESTRATOR_DIR}/czarina-core/install-hooks.sh" "$CZARINA_DIR" "$PROJECT_ROOT"

# Create daemon window (auto-approvals)
echo "   • Daemon (auto-approvals)"
tmux send-keys -t "${MGMT_SESSION}:info" "echo '- Daemon (auto-approvals)'" C-m
tmux new-window -t "$MGMT_SESSION" -n "daemon"
tmux send-keys -t "${MGMT_SESSION}:daemon" "cd ${PROJECT_ROOT}" C-m
sleep 0.1
tmux send-keys -t "${MGMT_SESSION}:daemon" "${ORCHESTRATOR_DIR}/czarina-core/daemon/czar-daemon.sh ${CZARINA_DIR}" C-m

# Create autonomous coordination daemon window
echo "   • Autonomous Czar (coordination)"
tmux send-keys -t "${MGMT_SESSION}:info" "echo '- Autonomous Czar (phase coordination)'" C-m
tmux new-window -t "$MGMT_SESSION" -n "czar-auto"
tmux send-keys -t "${MGMT_SESSION}:czar-auto" "cd ${PROJECT_ROOT}" C-m
sleep 0.1
tmux send-keys -t "${MGMT_SESSION}:czar-auto" "${ORCHESTRATOR_DIR}/czarina-core/autonomous-czar-daemon.sh ${CZARINA_DIR}" C-m

# Create LLM monitor daemon window (if enabled)
LLM_MONITOR_ENABLED=$(jq -r '.llm_monitor.enabled // false' "$CONFIG_FILE")
if [ "$LLM_MONITOR_ENABLED" = "true" ]; then
    echo "   • LLM Monitor (intelligent analysis)"
    tmux send-keys -t "${MGMT_SESSION}:info" "echo '- LLM Monitor (AI-powered worker analysis)'" C-m
    tmux new-window -t "$MGMT_SESSION" -n "llm-monitor"
    tmux send-keys -t "${MGMT_SESSION}:llm-monitor" "cd ${PROJECT_ROOT}" C-m
    sleep 0.1
    tmux send-keys -t "${MGMT_SESSION}:llm-monitor" "python3 ${ORCHESTRATOR_DIR}/czarina-core/llm-monitor-daemon.py ${CZARINA_DIR}" C-m
fi

# Create dashboard window
echo "   • Dashboard (auto-starting)"
tmux send-keys -t "${MGMT_SESSION}:info" "echo '- Dashboard (live monitoring)'" C-m
tmux send-keys -t "${MGMT_SESSION}:info" "echo ''
echo 'Switch to main session: Ctrl+b s, select ${SESSION_NAME}'
echo 'Detach: Ctrl+b d'
echo ''
echo '✅ Management session ready!'
" C-m

tmux new-window -t "$MGMT_SESSION" -n "dashboard"
tmux send-keys -t "${MGMT_SESSION}:dashboard" "cd ${PROJECT_ROOT}" C-m
sleep 0.1
tmux send-keys -t "${MGMT_SESSION}:dashboard" "python3 ${ORCHESTRATOR_DIR}/czarina-core/dashboard-v2.py" C-m

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Czarina orchestration launched!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📺 Attach to sessions:${NC}"
if [ $WORKER_COUNT -gt $MAX_WORKERS_IN_MAIN ]; then
    echo "   ${SESSION_NAME}      - Czar + Workers 1-${MAX_WORKERS_IN_MAIN}"
    echo "   ${MGMT_SESSION}  - Management (Workers $((MAX_WORKERS_IN_MAIN + 1))+, Daemon, Dashboard)"
else
    echo "   ${SESSION_NAME}      - Czar + Workers 1-${WORKER_COUNT}"
    echo "   ${MGMT_SESSION}  - Management (Daemon, Dashboard)"
fi
echo ""
echo -e "${CYAN}🔧 Quick start:${NC}"
echo "   tmux attach -t ${SESSION_NAME}   # Main session (windows 0-${MAX_WORKERS_IN_MAIN})"
echo "   Ctrl+b w                         # List all windows"
echo "   Ctrl+b s                         # Switch sessions"
echo "   Ctrl+b <number>                  # Switch to window (Ctrl+b 1 = Worker 1)"
echo ""
echo -e "${CYAN}📊 What's running:${NC}"
echo "   • Czar: Window 0 of main session"
if [ $WORKER_COUNT -gt $MAX_WORKERS_IN_MAIN ]; then
    echo "   • Workers 1-${MAX_WORKERS_IN_MAIN}: Windows 1-${MAX_WORKERS_IN_MAIN} of main session"
    echo "   • Workers $((MAX_WORKERS_IN_MAIN + 1))-${WORKER_COUNT}: Mgmt session"
else
    echo "   • Workers 1-${WORKER_COUNT}: Windows 1-${WORKER_COUNT} of main session"
fi
echo "   • Daemon: Auto-approvals (mgmt session)"
echo "   • Autonomous Czar: Phase coordination (mgmt session)"
echo "   • Dashboard: Live updating (mgmt session)"
echo ""
echo -e "${CYAN}🎯 To close out:${NC}"
echo "   czarina closeout"
echo ""
