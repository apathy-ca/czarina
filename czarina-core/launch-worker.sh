#!/bin/bash
# Individual worker launcher with tmux session management
# Usage: ./launch-worker.sh <worker_id>

set -euo pipefail

WORKER_ID=${1:-}
# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
REPO_ROOT="$PROJECT_ROOT"
ORCHESTRATOR_DIR="${REPO_ROOT}/orchestrator"

if [ -z "$WORKER_ID" ]; then
    echo "Usage: $0 <worker_id>"
    echo "Worker IDs: engineer1, engineer2, engineer3, engineer4, qa, docs"
    exit 1
fi

# Worker configurations
declare -A WORKER_BRANCHES=(
    [engineer1]="feat/gateway-client"
    [engineer2]="feat/gateway-api"
    [engineer3]="feat/gateway-policies"
    [engineer4]="feat/gateway-audit"
    [qa]="feat/gateway-tests"
    [docs]="feat/gateway-docs"
)

declare -A WORKER_TASKS=(
    [engineer1]="ENGINEER_1_TASKS.md"
    [engineer2]="ENGINEER_2_TASKS.md"
    [engineer3]="ENGINEER_3_TASKS.md"
    [engineer4]="ENGINEER_4_TASKS.md"
    [qa]="QA_WORKER_TASKS.md"
    [docs]="DOCUMENTATION_ENGINEER_TASKS.md"
)

declare -A WORKER_DESCRIPTIONS=(
    [engineer1]="Gateway Client & Infrastructure Engineer"
    [engineer2]="Authorization API Engineer"
    [engineer3]="OPA Policies Engineer"
    [engineer4]="Audit & Monitoring Engineer"
    [qa]="QA & Testing Engineer"
    [docs]="Documentation Engineer"
)

BRANCH="${WORKER_BRANCHES[$WORKER_ID]}"
TASK_FILE="${WORKER_TASKS[$WORKER_ID]}"
DESCRIPTION="${WORKER_DESCRIPTIONS[$WORKER_ID]}"
TASK_PATH="${REPO_ROOT}/docs/gateway-integration/tasks/${TASK_FILE}"

echo "🚀 Launching worker: $WORKER_ID"
echo "   Role: $DESCRIPTION"
echo "   Branch: $BRANCH"
echo "   Task: $TASK_FILE"

# Create tmux session
SESSION_NAME="sark-worker-${WORKER_ID}"

# Kill existing session if present
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

# Create new tmux session
tmux new-session -d -s "$SESSION_NAME" -c "$REPO_ROOT"

# Set up the environment
tmux send-keys -t "$SESSION_NAME" "cd $REPO_ROOT" C-m
tmux send-keys -t "$SESSION_NAME" "clear" C-m

# Create banner
tmux send-keys -t "$SESSION_NAME" "cat <<'EOF'
╔════════════════════════════════════════════════════════════╗
║  SARK v1.1 Gateway Integration                             ║
║  Worker: $WORKER_ID
║  Role: $DESCRIPTION
╚════════════════════════════════════════════════════════════╝

📋 Your Task File:
   $TASK_PATH

🌿 Your Branch:
   $BRANCH

📚 Additional Resources:
   - Coordination: docs/gateway-integration/COORDINATION.md
   - Worker Assignments: docs/gateway-integration/WORKER_ASSIGNMENTS.md
   - Implementation Plan: IMPLEMENTATION_PLAN_v1.1_GATEWAY.md

⚡ Quick Start:
   1. Read your task file: cat $TASK_PATH
   2. Checkout your branch: git checkout -b $BRANCH
   3. Check dependencies in COORDINATION.md
   4. Begin implementation

🔧 Useful Commands:
   - View task: cat $TASK_PATH | less
   - Check status: git status
   - Run tests: pytest tests/
   - View orchestrator status: cd orchestrator && ./orchestrator.sh (option 4)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ready to start! Type your commands below.

EOF
" C-m

# Checkout or create branch
tmux send-keys -t "$SESSION_NAME" "git checkout main && git pull origin main" C-m
tmux send-keys -t "$SESSION_NAME" "git checkout -b $BRANCH 2>/dev/null || git checkout $BRANCH" C-m

# Create worker-specific helper script in session
tmux send-keys -t "$SESSION_NAME" "cat > /tmp/worker-${WORKER_ID}-helpers.sh <<'HELPERS'
#!/bin/bash
# Helper functions for worker $WORKER_ID

# Show task file
task() {
    cat $TASK_PATH | less
}

# Show coordination doc
coord() {
    cat ${REPO_ROOT}/docs/gateway-integration/COORDINATION.md | less
}

# Quick status
status() {
    echo \"Worker: $WORKER_ID\"
    echo \"Branch: \$(git branch --show-current)\"
    echo \"Files changed: \$(git status --short | wc -l)\"
    git status --short
}

# Run relevant tests
test() {
    pytest tests/ -v -k gateway
}

# Create PR
create_pr() {
    gh pr create \\
        --base main \\
        --head $BRANCH \\
        --title \"$DESCRIPTION\" \\
        --body \"See $TASK_FILE for details\"
}

echo \"Helper functions loaded:\"
echo \"  - task    : View your task file\"
echo \"  - coord   : View coordination doc\"
echo \"  - status  : Show current status\"
echo \"  - test    : Run gateway tests\"
echo \"  - create_pr : Create your PR\"
HELPERS
" C-m

tmux send-keys -t "$SESSION_NAME" "source /tmp/worker-${WORKER_ID}-helpers.sh" C-m

# Attach to session
echo ""
echo "✅ Worker session created: $SESSION_NAME"
echo ""
echo "To attach: tmux attach -t $SESSION_NAME"
echo "To detach: Ctrl+B then D"
echo "To kill: tmux kill-session -t $SESSION_NAME"
echo ""

# Auto-attach only if not running in background
# Check if stdout is a terminal (not redirected)
if [ -t 1 ]; then
    # Running interactively, attach
    tmux attach -t "$SESSION_NAME"
else
    # Running in background, don't attach
    echo "Session running in background. Use 'tmux attach -t $SESSION_NAME' to connect."
fi
