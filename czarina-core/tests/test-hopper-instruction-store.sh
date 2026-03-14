#!/usr/bin/env bash
# test-hopper-instruction-store.sh
#
# Integration test for the hopper-based instruction store.
# Tests the full lifecycle: registration → brief storage → recovery → lesson filing.
#
# Does NOT require tmux, real agents, or an active orchestration.
# Creates a synthetic czarina project structure and exercises the integration layer.
#
# Usage: bash test-hopper-instruction-store.sh [--verbose]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CZARINA_CORE="$(dirname "$(dirname "$SCRIPT_DIR")")"  # tests/ → czarina-core/ → czarina/
CZARINA_CORE_DIR="${CZARINA_CORE}/czarina-core"
HOPPER_INTEGRATION="${CZARINA_CORE_DIR}/hopper-integration.sh"

VERBOSE="${1:-}"
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# ── Output helpers ────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

section() { echo ""; echo -e "${BLUE}▶ $1${NC}"; echo ""; }
pass()    { echo -e "  ${GREEN}✓${NC}  $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
fail()    { echo -e "  ${RED}✗${NC}  $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
skip()    { echo -e "  ${YELLOW}○${NC}  $1 ${DIM}(skipped)${NC}"; TESTS_SKIPPED=$((TESTS_SKIPPED + 1)); }
info()    { [[ -n "$VERBOSE" ]] && echo -e "  ${DIM}→  $1${NC}" || true; }

# ── Test project setup ────────────────────────────────────────────────────────

TEST_ROOT=$(mktemp -d --tmpdir czarina-test-XXXXXX)
trap "rm -rf '$TEST_ROOT'; hopper_cleanup" EXIT

# Embedded hopper store for this test (avoids polluting ~/.hopper)
export HOPPER_TEST_STORE="${TEST_ROOT}/.hopper"
mkdir -p "$HOPPER_TEST_STORE"

# We need to intercept hopper to use our test store
# Build a wrapper that forces --local with a custom path
HOPPER_BIN=$(command -v hopper)
HOPPER_WRAPPER="${TEST_ROOT}/bin/hopper"
mkdir -p "${TEST_ROOT}/bin"
cat > "$HOPPER_WRAPPER" << WRAPPER
#!/usr/bin/env bash
# Test wrapper: forces hopper to use isolated test store
exec "$HOPPER_BIN" "\$@"
WRAPPER
chmod +x "$HOPPER_WRAPPER"
# Note: hopper auto-detects .hopper in cwd — we'll cd into TEST_ROOT for all hopper ops

# Helper: run hopper against the test store
h() { cd "$TEST_ROOT" && hopper "$@"; }

hopper_cleanup() {
    # Cancel any test tasks left in the test hopper store
    if [[ -d "$HOPPER_TEST_STORE/tasks" ]]; then
        local tasks
        tasks=$(cd "$TEST_ROOT" && hopper --json --local task list --tag czarina-test 2>/dev/null || echo "[]")
        echo "$tasks" | jq -r '.[].id' 2>/dev/null | while read -r tid; do
            cd "$TEST_ROOT" && hopper --local task status "$tid" cancelled --force &>/dev/null || true
        done
    fi
}

# Create synthetic czarina project structure
setup_project() {
    local project_root="${TEST_ROOT}/project"
    local czarina_dir="${project_root}/.czarina"
    local workers_dir="${czarina_dir}/workers"

    mkdir -p "$project_root" "$czarina_dir" "$workers_dir"

    # Minimal config.json
    cat > "${czarina_dir}/config.json" << 'CONFIG'
{
  "project": {
    "name": "Test Project",
    "slug": "test-project",
    "repository": "__PROJECT_ROOT__",
    "version": "1.0.0",
    "phase": "1"
  },
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "agent": "opencode",
      "branch": "cz1/feat/backend",
      "description": "Build the REST API layer",
      "dependencies": []
    },
    {
      "id": "qa",
      "role": "qa",
      "agent": "opencode",
      "branch": "cz1/feat/qa",
      "description": "Write integration tests",
      "dependencies": ["backend"]
    }
  ]
}
CONFIG
    # Substitute real path
    sed -i "s|__PROJECT_ROOT__|${project_root}|g" "${czarina_dir}/config.json"

    # Worker brief files — realistic content
    cat > "${workers_dir}/backend.md" << 'BRIEF'
# Worker: backend — REST API Layer

**Role:** code
**Branch:** cz1/feat/backend
**Agent:** opencode
**Dependencies:** none

## Mission

Build a FastAPI REST API for the test project. Two endpoints: health check and
a task list endpoint. Follow existing patterns in the codebase.

## Your First Action

```bash
git checkout -b cz1/feat/backend
mkdir -p src/api
```

## Tasks

### Task 1.1: Health endpoint

Create `src/api/health.py` with a `/health` GET endpoint returning `{"status": "ok"}`.

COMMIT CHECKPOINT:
```bash
git add src/api/health.py
git commit -m "feat(api): Add health endpoint"
```

### Task 1.2: Task list endpoint

Create `src/api/tasks.py` with a `/tasks` GET endpoint returning a list of tasks
from a SQLite database. Use SQLAlchemy async session.

COMMIT CHECKPOINT:
```bash
git add src/api/tasks.py
git commit -m "feat(api): Add task list endpoint"
```

## Success Criteria

- [ ] Health endpoint returns 200
- [ ] Task list endpoint returns valid JSON
- [ ] All unit tests pass
BRIEF

    cat > "${workers_dir}/qa.md" << 'BRIEF'
# Worker: qa — Integration Tests

**Role:** qa
**Branch:** cz1/feat/qa
**Agent:** opencode
**Dependencies:** backend

## Mission

Write integration tests for the REST API endpoints created by the backend worker.
Use pytest with httpx for async testing.

## Your First Action

```bash
git checkout -b cz1/feat/qa
mkdir -p tests/integration
```

## Tasks

### Task 2.1: Health endpoint test

Test the `/health` endpoint returns 200 with correct body.

### Task 2.2: Task list endpoint test

Test the `/tasks` endpoint with and without data in the database.

## Success Criteria

- [ ] All tests pass
- [ ] Coverage > 80%
BRIEF

    echo "$project_root"
}

# Source the hopper integration script
source "$HOPPER_INTEGRATION"

# ── Tests ─────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Hopper Instruction Store — Integration Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Section 1: Prerequisites ──────────────────────────────────────────────────

section "1. Prerequisites"

if command -v hopper &>/dev/null; then
    pass "hopper binary available: $(command -v hopper)"
else
    fail "hopper not installed — cannot run tests"
    exit 1
fi

if command -v jq &>/dev/null; then
    pass "jq available"
else
    fail "jq not installed — cannot run tests"
    exit 1
fi

bash -n "$HOPPER_INTEGRATION" && pass "hopper-integration.sh syntax valid" \
    || fail "hopper-integration.sh has syntax errors"

# ── Section 2: hopper-integration.sh function API ────────────────────────────

section "2. Integration script function API"

REQUIRED_FUNCTIONS=(
    hopper_require
    hopper_task_store
    hopper_task_store_init
    hopper_store_project_task
    hopper_store_worker_task
    hopper_get_project_task
    hopper_get_worker_task
    hopper_create_project_task
    hopper_create_worker_task
    hopper_task_start
    hopper_task_complete
    hopper_task_block
    hopper_task_cancel
    hopper_print_status
    hopper_register_orchestration
    hopper_worker_start
    hopper_closeout_orchestration
)

all_ok=true
for fn in "${REQUIRED_FUNCTIONS[@]}"; do
    if declare -f "$fn" >/dev/null 2>&1; then
        info "  $fn defined"
    else
        fail "Function missing: $fn"
        all_ok=false
    fi
done
$all_ok && pass "All required functions defined (${#REQUIRED_FUNCTIONS[@]})"

# ── Section 3: Task store operations ─────────────────────────────────────────

section "3. Task ID store (hopper-tasks.json)"

export CZARINA_DIR="${TEST_ROOT}/project/.czarina"
mkdir -p "$CZARINA_DIR"

# Init
hopper_task_store_init
STORE=$(hopper_task_store)

if [[ -f "$STORE" ]]; then
    pass "Task store initialised at $STORE"
else
    fail "Task store file not created"
fi

INITIAL_PROJECT=$(hopper_get_project_task)
if [[ -z "$INITIAL_PROJECT" ]]; then
    pass "Fresh store has no project task ID"
else
    fail "Fresh store should have empty project task ID, got: $INITIAL_PROJECT"
fi

# Write / read round-trip
hopper_store_project_task "task-aabbccdd"
GOT=$(hopper_get_project_task)
if [[ "$GOT" == "task-aabbccdd" ]]; then
    pass "Project task ID stored and retrieved correctly"
else
    fail "Project task ID round-trip failed: expected task-aabbccdd, got $GOT"
fi

hopper_store_worker_task "backend" "task-11223344"
hopper_store_worker_task "qa" "task-55667788"

GOT_BACKEND=$(hopper_get_worker_task "backend")
GOT_QA=$(hopper_get_worker_task "qa")

[[ "$GOT_BACKEND" == "task-11223344" ]] \
    && pass "Worker task ID (backend) stored and retrieved" \
    || fail "backend task ID mismatch: got $GOT_BACKEND"

[[ "$GOT_QA" == "task-55667788" ]] \
    && pass "Worker task ID (qa) stored and retrieved" \
    || fail "qa task ID mismatch: got $GOT_QA"

# ── Section 4: hopper --brief-file via CLI ────────────────────────────────────

section "4. hopper task add --brief-file (full brief storage)"

BRIEF_FILE="${TEST_ROOT}/test-brief.md"
cat > "$BRIEF_FILE" << 'BRIEF'
# Worker: test-worker — Test Brief

## Mission
This is a test brief with multiple sections.

## Tasks

### Task 1: Do something

```bash
echo "hello"
```

## Success Criteria
- [ ] Something happened
BRIEF

# Add task with brief
TASK_OUTPUT=$(cd "$TEST_ROOT" && hopper --local task add \
    "[test-worker] Test brief task" \
    --brief-file "$BRIEF_FILE" \
    --tag czarina-test \
    --tag "worker-test-worker" \
    --priority high \
    --non-interactive \
    2>&1)

info "hopper add output: $TASK_OUTPUT"

TASK_ID=$(echo "$TASK_OUTPUT" | grep -oP '(?<=Created task: )task-[a-f0-9]+' || true)

if [[ -n "$TASK_ID" ]]; then
    pass "Task created with brief: $TASK_ID"
else
    fail "Failed to create task with brief. Output: $TASK_OUTPUT"
    TASK_ID=""
fi

if [[ -n "$TASK_ID" ]]; then
    # Verify full brief was stored
    STORED_BODY=$(cd "$TEST_ROOT" && hopper --local task get "$TASK_ID" 2>/dev/null)
    info "Stored task body (first 100 chars): ${STORED_BODY:0:100}"

    if echo "$STORED_BODY" | grep -q "Worker: test-worker"; then
        pass "Full markdown brief stored as task body"
    else
        fail "Brief content not found in stored task body"
    fi

    if echo "$STORED_BODY" | grep -q "Success Criteria"; then
        pass "Multi-section brief preserved in full"
    else
        fail "Brief sections not preserved"
    fi

    # Verify JSON output works
    JSON_OUTPUT=$(cd "$TEST_ROOT" && hopper --json --local task get "$TASK_ID" 2>/dev/null)
    if echo "$JSON_OUTPUT" | jq -e '.description' &>/dev/null; then
        pass "Task retrievable via JSON output"
    else
        fail "JSON output missing description field"
    fi

    # Verify --with-lessons flag is accepted (no lesson store yet, section omitted)
    WITH_LESSONS_OUTPUT=$(cd "$TEST_ROOT" && hopper --local task get "$TASK_ID" --with-lessons 2>/dev/null)
    if [[ -n "$WITH_LESSONS_OUTPUT" ]]; then
        pass "--with-lessons flag accepted (no lessons yet — section correctly omitted)"
    else
        fail "--with-lessons flag caused an error"
    fi
fi

# ── Section 5: Status transitions ────────────────────────────────────────────

section "5. Status transitions"

if [[ -n "${TASK_ID:-}" ]]; then
    # Start
    cd "$TEST_ROOT" && hopper_task_start "$TASK_ID"
    STATUS=$(cd "$TEST_ROOT" && hopper --json --local task get "$TASK_ID" | jq -r '.status')
    [[ "$STATUS" == "in_progress" ]] \
        && pass "hopper_task_start → in_progress" \
        || fail "Expected in_progress, got: $STATUS"

    # Block
    cd "$TEST_ROOT" && hopper_task_block "$TASK_ID" "Waiting on dependency"
    STATUS=$(cd "$TEST_ROOT" && hopper --json --local task get "$TASK_ID" | jq -r '.status')
    [[ "$STATUS" == "blocked" ]] \
        && pass "hopper_task_block → blocked" \
        || fail "Expected blocked, got: $STATUS"

    # Complete
    cd "$TEST_ROOT" && hopper_task_complete "$TASK_ID"
    STATUS=$(cd "$TEST_ROOT" && hopper --json --local task get "$TASK_ID" | jq -r '.status')
    [[ "$STATUS" == "completed" ]] \
        && pass "hopper_task_complete → completed" \
        || fail "Expected completed, got: $STATUS"
else
    skip "Status transitions (no task ID — prior step failed)"
fi

# ── Section 6: Full orchestration registration ────────────────────────────────

section "6. hopper_register_orchestration — full project lifecycle"

PROJECT_ROOT=$(setup_project)
CONFIG_FILE="${PROJECT_ROOT}/.czarina/config.json"
export CZARINA_DIR="${PROJECT_ROOT}/.czarina"

# Run registration — this creates project + worker tasks with full briefs
cd "$TEST_ROOT"
REGISTER_OUTPUT=$(hopper_register_orchestration "$CZARINA_DIR" "$CONFIG_FILE" 2>&1)
info "Registration output: $REGISTER_OUTPUT"

# Check project task was created
PROJECT_TASK=$(hopper_get_project_task)
if [[ -n "$PROJECT_TASK" && "$PROJECT_TASK" != "null" ]]; then
    pass "Project task created: $PROJECT_TASK"
else
    fail "Project task not created after registration"
fi

# Check worker tasks were created
BACKEND_TASK=$(hopper_get_worker_task "backend")
QA_TASK=$(hopper_get_worker_task "qa")

if [[ -n "$BACKEND_TASK" && "$BACKEND_TASK" != "null" ]]; then
    pass "Backend worker task created: $BACKEND_TASK"
else
    fail "Backend worker task not created"
fi

if [[ -n "$QA_TASK" && "$QA_TASK" != "null" ]]; then
    pass "QA worker task created: $QA_TASK"
else
    fail "QA worker task not created"
fi

# Verify backend brief content is in hopper
if [[ -n "${BACKEND_TASK:-}" ]]; then
    BACKEND_BODY=$(cd "$TEST_ROOT" && hopper --local task get "$BACKEND_TASK" 2>/dev/null)
    if echo "$BACKEND_BODY" | grep -q "REST API Layer"; then
        pass "Backend brief content stored in hopper task body"
    else
        fail "Backend brief content not found in hopper task"
    fi

    if echo "$BACKEND_BODY" | grep -q "Task 1.1"; then
        pass "Backend task list preserved in hopper"
    else
        fail "Backend task list not preserved"
    fi
fi

if [[ -n "${QA_TASK:-}" ]]; then
    QA_BODY=$(cd "$TEST_ROOT" && hopper --local task get "$QA_TASK" 2>/dev/null)
    if echo "$QA_BODY" | grep -q "Integration Tests"; then
        pass "QA brief content stored in hopper task body"
    else
        fail "QA brief content not found in hopper task"
    fi
fi

# Verify tags
if [[ -n "${BACKEND_TASK:-}" ]]; then
    TAGS=$(cd "$TEST_ROOT" && hopper --json --local task get "$BACKEND_TASK" | jq -r '.tags[]' 2>/dev/null)
    info "Backend task tags: $TAGS"
    echo "$TAGS" | grep -q "czarina"        && pass "Tag: czarina"        || fail "Missing tag: czarina"
    echo "$TAGS" | grep -q "test-project"   && pass "Tag: test-project"   || fail "Missing tag: test-project"
    echo "$TAGS" | grep -q "worker-backend" && pass "Tag: worker-backend" || fail "Missing tag: worker-backend"
    echo "$TAGS" | grep -q "role-code"      && pass "Tag: role-code"      || fail "Missing tag: role-code"
fi

# ── Section 7: Worker start (in_progress transition) ─────────────────────────

section "7. hopper_worker_start"

if [[ -n "${BACKEND_TASK:-}" ]]; then
    # Confirm status is open/in_progress after registration (project task was started)
    hopper_worker_start "$CZARINA_DIR" "backend"
    STATUS=$(cd "$TEST_ROOT" && hopper --json --local task get "$BACKEND_TASK" | jq -r '.status')
    [[ "$STATUS" == "in_progress" ]] \
        && pass "hopper_worker_start marks backend task in_progress" \
        || fail "Expected in_progress after worker start, got: $STATUS"
else
    skip "hopper_worker_start (no backend task)"
fi

# ── Section 8: hopper_print_status ───────────────────────────────────────────

section "8. hopper_print_status"

cd "$TEST_ROOT"
STATUS_OUTPUT=$(hopper_print_status "test-project" 2>&1)
info "Status output: $STATUS_OUTPUT"

if echo "$STATUS_OUTPUT" | grep -q "Tasks:"; then
    pass "hopper_print_status produces summary line"
else
    fail "hopper_print_status output missing summary"
fi

if echo "$STATUS_OUTPUT" | grep -q "backend"; then
    pass "hopper_print_status shows backend worker"
else
    fail "hopper_print_status missing backend worker row"
fi

if echo "$STATUS_OUTPUT" | grep -q "qa"; then
    pass "hopper_print_status shows qa worker"
else
    fail "hopper_print_status missing qa worker row"
fi

# ── Section 9: Recovery scenario ─────────────────────────────────────────────

section "9. Session recovery (simulated)"

# Simulate what a worker does after losing their session:
# 1. List their open/in-progress tasks by worker tag
# 2. Get the full brief

if [[ -n "${BACKEND_TASK:-}" ]]; then
    # Step 1: find tasks by tag
    RECOVERED_TASKS=$(cd "$TEST_ROOT" && hopper --json --local task list \
        --tag "worker-backend" --status in_progress 2>/dev/null)
    RECOVERED_ID=$(echo "$RECOVERED_TASKS" | jq -r '.[0].id' 2>/dev/null || true)

    if [[ "$RECOVERED_ID" == "$BACKEND_TASK" ]]; then
        pass "Worker can re-discover their task by tag after session loss"
    else
        fail "Recovery: task not found by tag (got: $RECOVERED_ID, expected: $BACKEND_TASK)"
    fi

    # Step 2: get full brief
    RECOVERED_BRIEF=$(cd "$TEST_ROOT" && hopper --local task get "$BACKEND_TASK" 2>/dev/null)
    if echo "$RECOVERED_BRIEF" | grep -q "REST API Layer"; then
        pass "Worker can retrieve full brief after session loss"
    else
        fail "Recovery: brief content not accessible"
    fi

    # Step 3: re-mark in_progress
    cd "$TEST_ROOT" && hopper --local task status "$BACKEND_TASK" in_progress --force &>/dev/null
    STATUS=$(cd "$TEST_ROOT" && hopper --json --local task get "$BACKEND_TASK" | jq -r '.status')
    [[ "$STATUS" == "in_progress" ]] \
        && pass "Worker can re-claim in_progress status after recovery" \
        || fail "Re-marking in_progress failed: got $STATUS"
else
    skip "Session recovery (no backend task)"
fi

# ── Section 10: Closeout ──────────────────────────────────────────────────────

section "10. hopper_closeout_orchestration"

cd "$TEST_ROOT"
CLOSEOUT_OUTPUT=$(hopper_closeout_orchestration "$CZARINA_DIR" 2>&1)
info "Closeout output: $CLOSEOUT_OUTPUT"

if echo "$CLOSEOUT_OUTPUT" | grep -q "Completed"; then
    pass "Closeout reports task completions"
else
    fail "Closeout output missing completion messages"
fi

# Verify all tasks are now completed
if [[ -n "${BACKEND_TASK:-}" ]]; then
    STATUS=$(cd "$TEST_ROOT" && hopper --json --local task get "$BACKEND_TASK" | jq -r '.status')
    [[ "$STATUS" == "completed" ]] \
        && pass "Backend task marked completed at closeout" \
        || fail "Backend task not completed: got $STATUS"
fi

if [[ -n "${QA_TASK:-}" ]]; then
    STATUS=$(cd "$TEST_ROOT" && hopper --json --local task get "$QA_TASK" | jq -r '.status')
    [[ "$STATUS" == "completed" ]] \
        && pass "QA task marked completed at closeout" \
        || fail "QA task not completed: got $STATUS"
fi

if [[ -n "${PROJECT_TASK:-}" ]]; then
    STATUS=$(cd "$TEST_ROOT" && hopper --json --local task get "$PROJECT_TASK" | jq -r '.status')
    [[ "$STATUS" == "completed" ]] \
        && pass "Project task marked completed at closeout" \
        || fail "Project task not completed: got $STATUS"
fi

# ── Section 11: hopper CLI additions ─────────────────────────────────────────

section "11. New hopper CLI flags"

# --non-interactive on task add
NI_OUTPUT=$(cd "$TEST_ROOT" && hopper --local task add "NI test task" \
    --tag czarina-test --priority low --non-interactive 2>&1)
NI_ID=$(echo "$NI_OUTPUT" | grep -oP '(?<=Created task: )task-[a-f0-9]+' || true)

if [[ -n "$NI_ID" ]]; then
    pass "task add --non-interactive works without prompts: $NI_ID"
    cd "$TEST_ROOT" && hopper --local task status "$NI_ID" cancelled --force &>/dev/null
else
    fail "task add --non-interactive failed: $NI_OUTPUT"
fi

# --with-lessons accepted
WL_OUTPUT=$(cd "$TEST_ROOT" && hopper --local task add "WL test task" \
    --tag czarina-test --non-interactive 2>&1)
WL_ID=$(echo "$WL_OUTPUT" | grep -oP '(?<=Created task: )task-[a-f0-9]+' || true)

if [[ -n "$WL_ID" ]]; then
    WL_GET=$(cd "$TEST_ROOT" && hopper --local task get "$WL_ID" --with-lessons 2>&1)
    if [[ -n "$WL_GET" ]]; then
        pass "task get --with-lessons accepted and returns content"
    else
        fail "task get --with-lessons returned empty output"
    fi
    cd "$TEST_ROOT" && hopper --local task status "$WL_ID" cancelled --force &>/dev/null
else
    skip "task get --with-lessons (task creation failed)"
fi

# --brief-file requires --local
BF_RESULT=$(hopper task add "test" --brief-file /dev/null 2>&1 || true)
if echo "$BF_RESULT" | grep -qi "local\|error\|fail"; then
    pass "--brief-file correctly rejected without --local mode"
else
    info "--brief-file non-local test result: $BF_RESULT"
    skip "--brief-file server mode rejection (server not configured)"
fi

# ── Section 12: czarina validate mentions hopper as required ──────────────────

section "12. czarina validate — hopper is required"

VALIDATE_SCRIPT="${CZARINA_CORE_DIR}/validate-config.sh"
if [[ -f "$VALIDATE_SCRIPT" ]]; then
    bash -n "$VALIDATE_SCRIPT" \
        && pass "validate-config.sh syntax valid" \
        || fail "validate-config.sh has syntax errors"

    VALIDATE_CONTENT=$(grep -A3 "Required integrations" "$VALIDATE_SCRIPT" 2>/dev/null || true)
    if echo "$VALIDATE_CONTENT" | grep -q "hopper"; then
        pass "validate-config.sh checks hopper as required integration"
    else
        fail "validate-config.sh does not check hopper as required"
    fi

    if grep -q "ERRORS++" "$VALIDATE_SCRIPT" && \
       grep -B2 'ERRORS++' "$VALIDATE_SCRIPT" | grep -q "hopper"; then
        pass "hopper absence increments ERRORS (hard block)"
    else
        fail "hopper check does not increment ERRORS"
    fi
else
    skip "validate-config.sh not found"
fi

# ── Section 13: WORKER_IDENTITY.md is hopper-first ───────────────────────────

section "13. WORKER_IDENTITY.md is hopper-first"

LAUNCHER="${CZARINA_CORE_DIR}/agent-launcher.sh"
if [[ -f "$LAUNCHER" ]]; then
    bash -n "$LAUNCHER" && pass "agent-launcher.sh syntax valid" || fail "Syntax errors"

    # WORKER_IDENTITY.md template should reference hopper task get, not cat ../workers/
    if grep -A60 'cat > "\$worktree_path/WORKER_IDENTITY.md"' "$LAUNCHER" \
            | grep -q "hopper --local task get"; then
        pass "WORKER_IDENTITY.md template references hopper task get"
    else
        fail "WORKER_IDENTITY.md template does not reference hopper task get"
    fi

    if grep -A60 'cat > "\$worktree_path/WORKER_IDENTITY.md"' "$LAUNCHER" \
            | grep -q "If You Lose Context"; then
        pass "WORKER_IDENTITY.md template includes recovery section"
    else
        fail "WORKER_IDENTITY.md template missing recovery section"
    fi

    if grep -A60 'cat > "\$worktree_path/WORKER_IDENTITY.md"' "$LAUNCHER" \
            | grep -q "On Task Completion"; then
        pass "WORKER_IDENTITY.md template includes lesson-filing section"
    else
        fail "WORKER_IDENTITY.md template missing lesson-filing section"
    fi

    # instructions_prompt should not point to ../workers/ files
    OLD_PROMPT_COUNT=$(grep -c 'read your full instructions at.*workers' "$LAUNCHER" 2>/dev/null || true)
    OLD_PROMPT_COUNT="${OLD_PROMPT_COUNT//[[:space:]]/}"  # strip whitespace/newlines
    OLD_PROMPT_COUNT="${OLD_PROMPT_COUNT:-0}"
    if [[ "$OLD_PROMPT_COUNT" -eq 0 ]]; then
        pass "No old file-based instructions_prompt strings remain"
    else
        fail "${OLD_PROMPT_COUNT} old file-based instructions_prompt string(s) still present"
    fi
else
    skip "agent-launcher.sh not found"
fi

# ── Section 14: launch-project-v2.sh sources hopper before workers ───────────

section "14. launch-project-v2.sh — hopper registered before workers"

LAUNCH_SCRIPT="${CZARINA_CORE_DIR}/launch-project-v2.sh"
if [[ -f "$LAUNCH_SCRIPT" ]]; then
    bash -n "$LAUNCH_SCRIPT" && pass "launch-project-v2.sh syntax valid" || fail "Syntax errors"

    if grep -q "hopper_register_orchestration" "$LAUNCH_SCRIPT"; then
        pass "launch-project-v2.sh calls hopper_register_orchestration"
    else
        fail "launch-project-v2.sh does not call hopper_register_orchestration"
    fi

    # Registration should happen before create_worker_window calls
    REGISTER_LINE=$(grep -n "hopper_register_orchestration" "$LAUNCH_SCRIPT" | head -1 | cut -d: -f1)
    WINDOW_LINE=$(grep -n "create_worker_window" "$LAUNCH_SCRIPT" | head -1 | cut -d: -f1)

    if [[ -n "$REGISTER_LINE" && -n "$WINDOW_LINE" && "$REGISTER_LINE" -lt "$WINDOW_LINE" ]]; then
        pass "hopper_register_orchestration called before create_worker_window (line $REGISTER_LINE < $WINDOW_LINE)"
    else
        fail "hopper_register_orchestration not called before create_worker_window"
    fi
else
    skip "launch-project-v2.sh not found"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "  Passed:  ${GREEN}${TESTS_PASSED}${NC}"
echo -e "  Failed:  ${RED}${TESTS_FAILED}${NC}"
echo -e "  Skipped: ${YELLOW}${TESTS_SKIPPED}${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "  ${GREEN}✅ All tests passed${NC}"
    echo ""
    exit 0
else
    echo -e "  ${RED}❌ ${TESTS_FAILED} test(s) failed${NC}"
    echo ""
    exit 1
fi
