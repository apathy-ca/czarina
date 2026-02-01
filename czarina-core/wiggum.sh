#!/bin/bash
# Czarina Wiggum Mode - Iterative AI Worker Lifecycle
# Orchestrates disposable AI workers ("Ralphs") in isolated worktrees
# Architecture: Stateless Execution, Stateful Oversight
#
# Usage: wiggum.sh <czarina-dir> <task-prompt> [options]
#   Options:
#     --retries N          Max retry attempts (default: from config or 5)
#     --timeout N          Timeout in seconds per attempt (default: from config or 300)
#     --verify-command CMD Verification command (default: from config)
#     --agent-command CMD  Agent command (default: from config or "claude -p .czarina/mission_brief.md")

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Argument Parsing ───────────────────────────────────────────────

CZARINA_DIR="${1:-}"
TASK_PROMPT="${2:-}"

if [ -z "$CZARINA_DIR" ] || [ -z "$TASK_PROMPT" ]; then
    echo -e "${RED}Usage: wiggum.sh <czarina-dir> <task-prompt> [options]${NC}"
    exit 1
fi

shift 2

# Load config defaults
CONFIG_FILE="${CZARINA_DIR}/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Config file not found: ${CONFIG_FILE}${NC}"
    exit 1
fi

# Check for required tools
for tool in jq tmux git; do
    if ! command -v "$tool" &> /dev/null; then
        echo -e "${RED}Required tool not found: ${tool}${NC}"
        exit 1
    fi
done

PROJECT_ROOT=$(jq -r '.project.repository // empty' "$CONFIG_FILE")
if [ -z "$PROJECT_ROOT" ]; then
    PROJECT_ROOT=$(dirname "$CZARINA_DIR")
fi

# Read wiggum config with defaults
AGENT_COMMAND=$(jq -r '.wiggum.agent_command // "claude -p .czarina/mission_brief.md"' "$CONFIG_FILE")
SANDBOX_PREFIX=$(jq -r '.wiggum.sandbox_prefix // ".wiggum_sandboxes/"' "$CONFIG_FILE")
MAX_RETRIES=$(jq -r '.wiggum.default_retries // 5' "$CONFIG_FILE")
TIMEOUT_SECONDS=$(jq -r '.wiggum.timeout_seconds // 300' "$CONFIG_FILE")
VERIFY_COMMAND=$(jq -r '.wiggum.verify_command // empty' "$CONFIG_FILE")
MERGE_STRATEGY=$(jq -r '.wiggum.merge_strategy // "squash"' "$CONFIG_FILE")

# Read protected files into array
PROTECTED_FILES=()
while IFS= read -r line; do
    [ -n "$line" ] && PROTECTED_FILES+=("$line")
done < <(jq -r '.wiggum.protected_files[]? // empty' "$CONFIG_FILE")

# Override with CLI flags
while [ $# -gt 0 ]; do
    case "$1" in
        --retries)
            MAX_RETRIES="$2"; shift 2 ;;
        --timeout)
            TIMEOUT_SECONDS="$2"; shift 2 ;;
        --verify-command)
            VERIFY_COMMAND="$2"; shift 2 ;;
        --agent-command)
            AGENT_COMMAND="$2"; shift 2 ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    esac
done

# ─── State Management ───────────────────────────────────────────────

SANDBOX_DIR="${PROJECT_ROOT}/${SANDBOX_PREFIX}"
WISDOM_FILE="${CZARINA_DIR}/wiggum_wisdom.md"
HISTORY_FILE="${CZARINA_DIR}/wiggum_history.json"
CURRENT_BRANCH=$(cd "$PROJECT_ROOT" && git branch --show-current)

mkdir -p "$SANDBOX_DIR"
mkdir -p "${CZARINA_DIR}/status"

# Initialize wisdom file if it doesn't exist
if [ ! -f "$WISDOM_FILE" ]; then
    cat > "$WISDOM_FILE" <<'EOF'
# Wiggum Wisdom Registry

This file accumulates error logs and lessons from failed attempts.
The Czar uses this to brief each new Ralph on what NOT to do.

---

EOF
fi

# Initialize history file if it doesn't exist
if [ ! -f "$HISTORY_FILE" ]; then
    echo '{"attempts": [], "hashes": []}' > "$HISTORY_FILE"
fi

# ─── Helper Functions ────────────────────────────────────────────────

log_info() {
    echo -e "${BLUE}[Czar]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[Czar]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[Czar]${NC} $*"
}

log_error() {
    echo -e "${RED}[Czar]${NC} $*"
}

log_phase() {
    echo ""
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  $*${NC}"
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Compute a hash of all modified files in the worktree (relative to parent branch)
compute_diff_hash() {
    local worktree_dir="$1"
    cd "$worktree_dir"
    # Hash the actual diff content, not just filenames
    git diff "$CURRENT_BRANCH" -- . 2>/dev/null | sha256sum | cut -d' ' -f1
}

# Check if this hash has been seen in a previous failed attempt (cycle detection)
check_cycle() {
    local current_hash="$1"
    local attempt_num="$2"

    if [ -z "$current_hash" ] || [ "$current_hash" = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" ]; then
        # Empty diff hash - no changes were made
        log_warn "Ralph made no changes (empty diff)"
        return 1
    fi

    # Check against all previous hashes
    local prev_hashes
    prev_hashes=$(jq -r '.hashes[]' "$HISTORY_FILE" 2>/dev/null)

    if echo "$prev_hashes" | grep -qF "$current_hash"; then
        log_error "Cycle detected! Attempt #${attempt_num} produced identical changes to a previous failed attempt"
        log_error "Ralph has regressed to a known broken state - aborting"
        return 1
    fi

    return 0
}

# Record an attempt in the history
record_attempt() {
    local attempt_num="$1"
    local status="$2"
    local hash="$3"
    local message="$4"

    local tmp_file
    tmp_file=$(mktemp)
    jq --arg num "$attempt_num" \
       --arg status "$status" \
       --arg hash "$hash" \
       --arg msg "$message" \
       --arg ts "$(timestamp)" \
       '.attempts += [{"attempt": ($num|tonumber), "status": $status, "hash": $hash, "message": $msg, "timestamp": $ts}] | .hashes += [$hash]' \
       "$HISTORY_FILE" > "$tmp_file" && mv "$tmp_file" "$HISTORY_FILE"
}

# Append failure wisdom for future Ralphs
append_wisdom() {
    local attempt_num="$1"
    local error_log="$2"

    cat >> "$WISDOM_FILE" <<EOF

## Attempt #${attempt_num} - Failed at $(timestamp)

\`\`\`
${error_log}
\`\`\`

---

EOF
}

# Generate the mission brief for a Ralph
generate_mission_brief() {
    local worktree_dir="$1"
    local attempt_num="$2"

    local brief_dir="${worktree_dir}/.czarina"
    mkdir -p "$brief_dir"

    cat > "${brief_dir}/mission_brief.md" <<BRIEF_EOF
# Mission Brief - Attempt #${attempt_num}

## Directives

${TASK_PROMPT}

## Constraints

- **Timeout:** You have ${TIMEOUT_SECONDS} seconds to complete this task.
- **Protected files:** Do NOT modify these files: ${PROTECTED_FILES[*]:-none}
- **Working directory:** You are in a disposable worktree. Make your changes here.
- **Goal:** Make the changes described above and ensure all tests pass.
BRIEF_EOF

    # Append wisdom from previous failures if any exist
    if [ "$attempt_num" -gt 1 ] && [ -f "$WISDOM_FILE" ]; then
        cat >> "${brief_dir}/mission_brief.md" <<WISDOM_EOF

## The Wisdom (Lessons from Previous Attempts)

Previous attempts have failed. Learn from their mistakes:

$(cat "$WISDOM_FILE")

**Do NOT repeat the same mistakes. Try a different approach.**
WISDOM_EOF
    fi
}

# Revert any changes to protected files
revert_protected_files() {
    local worktree_dir="$1"

    if [ ${#PROTECTED_FILES[@]} -eq 0 ]; then
        return 0
    fi

    cd "$worktree_dir"
    local reverted=false
    for pf in "${PROTECTED_FILES[@]}"; do
        if git diff --name-only "$CURRENT_BRANCH" -- "$pf" 2>/dev/null | grep -q .; then
            log_warn "Reverting protected file: $pf"
            git checkout "$CURRENT_BRANCH" -- "$pf" 2>/dev/null || true
            reverted=true
        fi
    done

    if [ "$reverted" = true ]; then
        log_warn "Protected files were reverted"
    fi
}

# Clean up a worktree
cleanup_worktree() {
    local worktree_dir="$1"
    local branch_name="$2"

    cd "$PROJECT_ROOT"

    # Kill tmux session if running
    tmux kill-session -t "wiggum-ralph-${branch_name}" 2>/dev/null || true

    # Remove worktree
    if [ -d "$worktree_dir" ]; then
        git worktree remove --force "$worktree_dir" 2>/dev/null || {
            rm -rf "$worktree_dir"
            git worktree prune 2>/dev/null || true
        }
    fi

    # Delete the temporary branch
    git branch -D "$branch_name" 2>/dev/null || true
}

# ─── Main Wiggum Lifecycle Loop ──────────────────────────────────────

log_phase "Wiggum Mode Activated"
log_info "Task: ${TASK_PROMPT:0:80}..."
log_info "Max retries: $MAX_RETRIES"
log_info "Timeout: ${TIMEOUT_SECONDS}s per attempt"
log_info "Verify command: ${VERIFY_COMMAND:-<none>}"
log_info "Agent command: $AGENT_COMMAND"
log_info "Parent branch: $CURRENT_BRANCH"
echo ""

# Clean up stale worktrees before starting
git -C "$PROJECT_ROOT" worktree prune 2>/dev/null || true

ATTEMPT=0
SUCCESS=false

while [ $ATTEMPT -lt $MAX_RETRIES ]; do
    ATTEMPT=$((ATTEMPT + 1))
    BRANCH_NAME="wiggum/attempt-${ATTEMPT}"
    WORKTREE_DIR="${SANDBOX_DIR}/attempt-${ATTEMPT}"
    SESSION_NAME="wiggum-ralph-${ATTEMPT}"

    # ─── Phase 1: Isolation (Spawn) ─────────────────────────────

    log_phase "Attempt #${ATTEMPT} of ${MAX_RETRIES} - Phase 1: Spawn"
    log_info "Creating isolated worktree: ${WORKTREE_DIR}"

    cd "$PROJECT_ROOT"

    # Clean up if this attempt directory already exists (from a previous run)
    cleanup_worktree "$WORKTREE_DIR" "$BRANCH_NAME"

    # Create fresh worktree
    if ! git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "$CURRENT_BRANCH" 2>&1; then
        log_error "Failed to create worktree for attempt #${ATTEMPT}"
        record_attempt "$ATTEMPT" "spawn_failed" "" "Failed to create worktree"
        continue
    fi

    log_success "Worktree created on branch: $BRANCH_NAME"

    # ─── Phase 2: Context Injection (Brief) ─────────────────────

    log_phase "Attempt #${ATTEMPT} - Phase 2: Brief"
    log_info "Generating mission brief..."

    generate_mission_brief "$WORKTREE_DIR" "$ATTEMPT"
    log_success "Mission brief written to ${WORKTREE_DIR}/.czarina/mission_brief.md"

    # ─── Phase 3: Execution (Run) ───────────────────────────────

    log_phase "Attempt #${ATTEMPT} - Phase 3: Execute"
    log_info "Spawning Ralph in tmux session: $SESSION_NAME"

    # Create tmux session for the Ralph
    tmux new-session -d -s "$SESSION_NAME" -c "$WORKTREE_DIR" 2>/dev/null || {
        log_error "Failed to create tmux session"
        cleanup_worktree "$WORKTREE_DIR" "$BRANCH_NAME"
        record_attempt "$ATTEMPT" "tmux_failed" "" "Failed to create tmux session"
        continue
    }

    # Run the agent command inside tmux
    tmux send-keys -t "$SESSION_NAME" "cd ${WORKTREE_DIR} && ${AGENT_COMMAND}; echo 'WIGGUM_RALPH_DONE_\$?' > /tmp/wiggum_ralph_${ATTEMPT}_status" C-m

    # Watchdog: wait for completion or timeout
    log_info "Watchdog active (timeout: ${TIMEOUT_SECONDS}s)..."
    ELAPSED=0
    POLL_INTERVAL=5
    RALPH_STATUS_FILE="/tmp/wiggum_ralph_${ATTEMPT}_status"
    rm -f "$RALPH_STATUS_FILE"

    RALPH_FINISHED=false
    while [ $ELAPSED -lt $TIMEOUT_SECONDS ]; do
        sleep $POLL_INTERVAL
        ELAPSED=$((ELAPSED + POLL_INTERVAL))

        # Check if Ralph finished
        if [ -f "$RALPH_STATUS_FILE" ]; then
            RALPH_FINISHED=true
            break
        fi

        # Check if tmux session is still alive
        if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
            RALPH_FINISHED=true
            break
        fi

        # Progress indicator every 30 seconds
        if [ $((ELAPSED % 30)) -eq 0 ]; then
            log_info "  ...${ELAPSED}s elapsed"
        fi
    done

    if [ "$RALPH_FINISHED" = false ]; then
        log_warn "Timeout reached (${TIMEOUT_SECONDS}s) - terminating Ralph"
        tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
        ERROR_MSG="Attempt #${ATTEMPT}: Timed out after ${TIMEOUT_SECONDS}s"
        append_wisdom "$ATTEMPT" "$ERROR_MSG"
        record_attempt "$ATTEMPT" "timeout" "" "$ERROR_MSG"
        cleanup_worktree "$WORKTREE_DIR" "$BRANCH_NAME"
        continue
    fi

    log_success "Ralph yielded control"

    # Kill tmux session now that Ralph is done
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
    rm -f "$RALPH_STATUS_FILE"

    # ─── Phase 4: Verification (The Gate) ───────────────────────

    log_phase "Attempt #${ATTEMPT} - Phase 4: Verify"

    # Revert protected files first
    revert_protected_files "$WORKTREE_DIR"

    # 4a. Cycle Detection
    log_info "Running cycle detection..."
    DIFF_HASH=$(compute_diff_hash "$WORKTREE_DIR")

    if ! check_cycle "$DIFF_HASH" "$ATTEMPT"; then
        ERROR_MSG="Attempt #${ATTEMPT}: Cycle detected or no changes made (hash: ${DIFF_HASH:0:16})"
        append_wisdom "$ATTEMPT" "$ERROR_MSG"
        record_attempt "$ATTEMPT" "cycle_detected" "$DIFF_HASH" "$ERROR_MSG"
        cleanup_worktree "$WORKTREE_DIR" "$BRANCH_NAME"
        continue
    fi

    log_success "Cycle detection passed (unique changeset: ${DIFF_HASH:0:16}...)"

    # 4b. Test Suite
    if [ -n "$VERIFY_COMMAND" ]; then
        log_info "Running verification: $VERIFY_COMMAND"
        cd "$WORKTREE_DIR"

        VERIFY_LOG="${CZARINA_DIR}/status/wiggum_verify_${ATTEMPT}.log"
        if eval "$VERIFY_COMMAND" > "$VERIFY_LOG" 2>&1; then
            log_success "Verification passed!"
        else
            VERIFY_EXIT=$?
            log_error "Verification failed (exit code: $VERIFY_EXIT)"

            # Capture error output for wisdom
            ERROR_OUTPUT=$(tail -50 "$VERIFY_LOG" 2>/dev/null || echo "No output captured")
            ERROR_MSG="Attempt #${ATTEMPT}: Verification failed (exit ${VERIFY_EXIT})

Command: ${VERIFY_COMMAND}
Output (last 50 lines):
${ERROR_OUTPUT}"

            append_wisdom "$ATTEMPT" "$ERROR_MSG"
            record_attempt "$ATTEMPT" "verify_failed" "$DIFF_HASH" "Verification failed (exit ${VERIFY_EXIT})"
            cleanup_worktree "$WORKTREE_DIR" "$BRANCH_NAME"
            continue
        fi
    else
        log_warn "No verify_command configured - skipping test gate"
    fi

    # ─── Phase 5: Resolution (Success) ──────────────────────────

    log_phase "Attempt #${ATTEMPT} - Phase 5: Resolve (SUCCESS)"
    log_success "Ralph succeeded on attempt #${ATTEMPT}!"

    # Commit any uncommitted changes in the worktree
    cd "$WORKTREE_DIR"
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        log_info "Committing remaining changes..."
        git add -A
        git commit -m "wiggum: auto-commit from successful attempt #${ATTEMPT}" 2>/dev/null || true
    fi

    # Merge back to parent branch
    log_info "Merging changes to ${CURRENT_BRANCH} (strategy: ${MERGE_STRATEGY})..."
    cd "$PROJECT_ROOT"

    case "$MERGE_STRATEGY" in
        squash)
            git checkout "$CURRENT_BRANCH"
            git merge --squash "$BRANCH_NAME"
            git commit -m "wiggum: ${TASK_PROMPT:0:72}" 2>/dev/null || {
                # If nothing to commit after squash, the changes were already there
                log_warn "Nothing to commit after squash merge"
            }
            ;;
        merge)
            git checkout "$CURRENT_BRANCH"
            git merge "$BRANCH_NAME" -m "wiggum: merge attempt #${ATTEMPT} - ${TASK_PROMPT:0:60}"
            ;;
        rebase)
            git checkout "$CURRENT_BRANCH"
            git rebase "$BRANCH_NAME"
            ;;
    esac

    # Record success
    record_attempt "$ATTEMPT" "success" "$DIFF_HASH" "Succeeded on attempt #${ATTEMPT}"

    # Clean up
    cleanup_worktree "$WORKTREE_DIR" "$BRANCH_NAME"

    SUCCESS=true
    break
done

# ─── Final Report ────────────────────────────────────────────────────

echo ""
echo ""
if [ "$SUCCESS" = true ]; then
    log_phase "Wiggum Mode Complete - SUCCESS"
    log_success "Task completed on attempt #${ATTEMPT} of ${MAX_RETRIES}"
    log_success "Changes merged to branch: $CURRENT_BRANCH"
    echo ""
    echo -e "${GREEN}  Result: SUCCESS${NC}"
    echo -e "  Attempts: ${ATTEMPT}"
    echo -e "  Branch: ${CURRENT_BRANCH}"
    echo -e "  History: ${HISTORY_FILE}"
    echo ""
    exit 0
else
    log_phase "Wiggum Mode Complete - FAILED"
    log_error "All ${MAX_RETRIES} attempts exhausted"
    log_error "Review the wisdom registry for accumulated errors:"
    log_error "  ${WISDOM_FILE}"
    echo ""
    echo -e "${RED}  Result: FAILED${NC}"
    echo -e "  Attempts: ${MAX_RETRIES}"
    echo -e "  Wisdom: ${WISDOM_FILE}"
    echo -e "  History: ${HISTORY_FILE}"
    echo ""

    # Clean up sandbox directory if empty
    rmdir "$SANDBOX_DIR" 2>/dev/null || true

    exit 1
fi
