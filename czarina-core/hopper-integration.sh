#!/usr/bin/env bash
# czarina-core/hopper-integration.sh
#
# Hopper CLI integration for Czarina.
# Uses hopper --local mode (markdown storage at ~/.hopper) — no server required.
#
# Hopper is a REQUIRED dependency of Czarina. All functions hard-fail if hopper
# is not installed. Run 'czarina validate' to check prerequisites before launching.
#
# Conventions:
#   - Every orchestration project gets a czarina tag: czarina
#   - Every orchestration project also gets a slug tag: <project-slug>
#   - Each worker task gets an additional tag: worker-<worker-id>
#   - Task IDs are persisted to .czarina/hopper-tasks.json for cross-command lookup
#
# Sourced by: agent-launcher.sh, closeout-project.sh
# Called from: czarina CLI (cmd_launch, cmd_status, cmd_closeout)

set -euo pipefail

# ============================================================================
# Prerequisite Check
# ============================================================================

# Hard-fail if hopper is not installed. Called once at entry points.
hopper_require() {
    if ! command -v hopper &>/dev/null; then
        echo "❌ hopper is required but not installed."
        echo "   Hopper is a required dependency of Czarina."
        echo "   Install: pip install hopper-cli"
        echo "   Docs:    https://github.com/jhenry/hopper"
        exit 1
    fi
}

# ============================================================================
# Task ID Store
# Persists hopper task IDs into .czarina/hopper-tasks.json
# Format: { "project_task_id": "task-xxx", "workers": { "worker-id": "task-yyy" } }
# ============================================================================

# Path to task ID store (requires CZARINA_DIR to be set by caller)
hopper_task_store() {
    echo "${CZARINA_DIR:-.czarina}/hopper-tasks.json"
}

# Initialise or reset the task store
hopper_task_store_init() {
    local store
    store=$(hopper_task_store)
    echo '{"project_task_id": null, "workers": {}}' > "$store"
}

# Save project-level task ID
hopper_store_project_task() {
    local task_id="$1"
    local store
    store=$(hopper_task_store)
    local tmp
    tmp=$(mktemp)
    jq --arg id "$task_id" '.project_task_id = $id' "$store" > "$tmp"
    mv "$tmp" "$store"
}

# Save a worker task ID
hopper_store_worker_task() {
    local worker_id="$1"
    local task_id="$2"
    local store
    store=$(hopper_task_store)
    local tmp
    tmp=$(mktemp)
    jq --arg w "$worker_id" --arg id "$task_id" '.workers[$w] = $id' "$store" > "$tmp"
    mv "$tmp" "$store"
}

# Read project-level task ID
hopper_get_project_task() {
    local store
    store=$(hopper_task_store)
    [[ -f "$store" ]] && jq -r '.project_task_id // empty' "$store" || echo ""
}

# Read a worker task ID
hopper_get_worker_task() {
    local worker_id="$1"
    local store
    store=$(hopper_task_store)
    [[ -f "$store" ]] && jq -r --arg w "$worker_id" '.workers[$w] // empty' "$store" || echo ""
}

# ============================================================================
# Task Creation
# ============================================================================

# Create the top-level orchestration task in hopper
# Usage: hopper_create_project_task <project-name> <project-slug> <version> <phase> <num-workers>
# Outputs: task ID on stdout
hopper_create_project_task() {
    local project_name="$1"
    local project_slug="$2"
    local version="$3"
    local phase="$4"
    local num_workers="$5"

    hopper_require

    local task_id
    task_id=$(hopper --local task add \
        "${project_name} v${version} phase ${phase}" \
        --description "Czarina orchestration: ${num_workers} worker(s)" \
        --priority high \
        --tag czarina \
        --tag "$project_slug" \
        --tag "phase-${phase}" \
        2>/dev/null \
        | grep -oP '(?<=Created task: )task-[a-f0-9]+' || true)

    if [[ -z "$task_id" ]]; then
        echo "❌ hopper: could not create project task" >&2
        exit 1
    fi

    echo "$task_id"
}

# Create a worker task in hopper, linked to the project task
# Usage: hopper_create_worker_task <worker-id> <description> <role> <project-slug> [<parent-task-id>]
# Outputs: task ID on stdout
hopper_create_worker_task() {
    local worker_id="$1"
    local description="$2"
    local role="$3"
    local project_slug="$4"
    local parent_task_id="${5:-}"
    local brief_file="${6:-}"  # Optional: path to .czarina/workers/<id>.md

    hopper_require

    # Map czarina roles to hopper priorities
    local priority="medium"
    case "$role" in
        architect|qa) priority="high" ;;
        code|implementation) priority="medium" ;;
        documentation|docs) priority="low" ;;
    esac

    local base_args=(
        "[${worker_id}] ${description}"
        --priority "$priority"
        --tag czarina
        --tag "$project_slug"
        --tag "worker-${worker_id}"
        --tag "role-${role}"
        --non-interactive
    )

    local task_id
    if [[ -n "$brief_file" && -f "$brief_file" ]]; then
        # Full worker brief stored as task body
        task_id=$(hopper --local task add "${base_args[@]}" \
            --brief-file "$brief_file" \
            2>/dev/null \
            | grep -oP '(?<=Created task: )task-[a-f0-9]+' || true)
    else
        # Fallback: one-liner description only
        task_id=$(hopper --local task add "${base_args[@]}" \
            --description "Role: ${role} | Project: ${project_slug}" \
            2>/dev/null \
            | grep -oP '(?<=Created task: )task-[a-f0-9]+' || true)
    fi

    if [[ -z "$task_id" ]]; then
        echo "❌ hopper: could not create task for worker ${worker_id}" >&2
        exit 1
    fi

    echo "$task_id"
}

# ============================================================================
# Status Transitions
# ============================================================================

# Mark a task in_progress
hopper_task_start() {
    local task_id="${1:?task_id required}"
    hopper --local task status "$task_id" in_progress --force
}

# Mark a task completed
hopper_task_complete() {
    local task_id="${1:?task_id required}"
    hopper --local task status "$task_id" completed --force
}

# Mark a task blocked
hopper_task_block() {
    local task_id="${1:?task_id required}"
    local reason="${2:-}"
    if [[ -n "$reason" ]]; then
        hopper --local task update "$task_id" --description "BLOCKED: ${reason}"
    fi
    hopper --local task status "$task_id" blocked --force
}

# Mark a task cancelled
hopper_task_cancel() {
    local task_id="${1:?task_id required}"
    hopper --local task status "$task_id" cancelled --force
}

# ============================================================================
# Status Query
# ============================================================================

# Print a summary table of all tasks for a project slug
# Usage: hopper_print_status <project-slug>
hopper_print_status() {
    local project_slug="$1"

    hopper_require

    local tasks
    tasks=$(hopper --json --local task list --tag "$project_slug" 2>/dev/null || echo "[]")

    if [[ "$tasks" == "[]" ]] || [[ -z "$tasks" ]]; then
        echo "   (no hopper tasks found for ${project_slug})"
        return 0
    fi

    local total open in_progress blocked completed cancelled
    total=$(echo "$tasks" | jq 'length')
    open=$(echo "$tasks" | jq '[.[] | select(.status=="open")] | length')
    in_progress=$(echo "$tasks" | jq '[.[] | select(.status=="in_progress")] | length')
    blocked=$(echo "$tasks" | jq '[.[] | select(.status=="blocked")] | length')
    completed=$(echo "$tasks" | jq '[.[] | select(.status=="completed")] | length')
    cancelled=$(echo "$tasks" | jq '[.[] | select(.status=="cancelled")] | length')

    echo "   Tasks: ${total} total  |  ✅ ${completed} done  |  🔄 ${in_progress} active  |  📋 ${open} open  |  🚫 ${blocked} blocked"
    echo ""

    # Print per-worker rows (tasks tagged worker-*)
    echo "$tasks" | jq -r '.[] | select(.tags | map(startswith("worker-")) | any) | [
        (.tags | map(select(startswith("worker-"))) | first | ltrimstr("worker-")),
        .status,
        .title
    ] | @tsv' 2>/dev/null | while IFS=$'\t' read -r worker status title; do
        local icon="📋"
        case "$status" in
            open)        icon="📋" ;;
            in_progress) icon="🔄" ;;
            completed)   icon="✅" ;;
            blocked)     icon="🚫" ;;
            cancelled)   icon="❌" ;;
        esac
        printf "   %s  %-20s  %s\n" "$icon" "$worker" "$title"
    done
}

# ============================================================================
# Full Orchestration Lifecycle Helpers
# ============================================================================

# Called by cmd_launch / launch scripts after workers are configured.
# Creates project task + one task per worker, persists all IDs.
# Usage: hopper_register_orchestration <czarina-dir> <config-json-path>
hopper_register_orchestration() {
    local czarina_dir="$1"
    local config_file="$2"

    hopper_require

    export CZARINA_DIR="$czarina_dir"

    local project_name project_slug version phase
    project_name=$(jq -r '.project.name' "$config_file")
    project_slug=$(jq -r '.project.slug' "$config_file")
    version=$(jq -r '.project.version // "unknown"' "$config_file")
    phase=$(jq -r '.project.phase // "1"' "$config_file")
    local num_workers
    num_workers=$(jq '.workers | length' "$config_file")

    echo "📬 Registering with hopper..."

    # Init task store
    hopper_task_store_init

    # Create project-level task
    local project_task_id
    if project_task_id=$(hopper_create_project_task \
            "$project_name" "$project_slug" "$version" "$phase" "$num_workers"); then
        hopper_store_project_task "$project_task_id"
        hopper_task_start "$project_task_id"
        echo "   ✅ Project task: $project_task_id"
    else
        echo "❌ Could not create project task in hopper"
        exit 1
    fi

    # Create one task per worker, loading full brief + any relevant lessons
    local workers_dir
    workers_dir="$(dirname "$config_file")/workers"

    while IFS= read -r worker_json; do
        local worker_id description role
        worker_id=$(echo "$worker_json" | jq -r '.id')
        description=$(echo "$worker_json" | jq -r '.description // .mission // .id')
        role=$(echo "$worker_json" | jq -r '.role // "code"')

        # Map role to lesson domain for injection query
        local domain
        case "$role" in
            architect)      domain="architecture" ;;
            qa|testing)     domain="testing" ;;
            documentation)  domain="general" ;;
            integration)    domain="orchestration" ;;
            *)              domain="python" ;;
        esac

        local brief_file="${workers_dir}/${worker_id}.md"
        local effective_brief_file="$brief_file"

        # Prepend relevant lessons to the brief if any high-confidence lessons exist
        if [[ -f "$brief_file" ]]; then
            local lessons_json
            lessons_json=$(hopper --json --local lesson list \
                --project "$project_slug" --domain "$domain" --confidence high \
                2>/dev/null || echo "[]")
            local lesson_count
            lesson_count=$(echo "$lessons_json" | jq 'length' 2>/dev/null || echo "0")

            if [[ "$lesson_count" -gt 0 ]]; then
                local combined_brief
                combined_brief=$(mktemp --suffix=".md")
                echo "## Lessons From Previous Work" >> "$combined_brief"
                echo "" >> "$combined_brief"
                echo "_High-confidence lessons filed by previous workers. Read before Task 1._" >> "$combined_brief"
                echo "" >> "$combined_brief"
                echo "$lessons_json" | jq -r '.[] | "### \(.title)\n\n\(.description // "")\n"' \
                    2>/dev/null >> "$combined_brief" || true
                echo "---" >> "$combined_brief"
                echo "" >> "$combined_brief"
                cat "$brief_file" >> "$combined_brief"
                effective_brief_file="$combined_brief"
                echo "   📚 Injected ${lesson_count} lesson(s) into [$worker_id] brief"
            fi
        fi

        local worker_task_id
        if worker_task_id=$(hopper_create_worker_task \
                "$worker_id" "$description" "$role" "$project_slug" \
                "$project_task_id" "$effective_brief_file"); then
            hopper_store_worker_task "$worker_id" "$worker_task_id"
            if [[ -f "$brief_file" ]]; then
                echo "   ✅ Worker task [$worker_id]: $worker_task_id (brief loaded)"
            else
                echo "   ✅ Worker task [$worker_id]: $worker_task_id"
            fi
        fi

        # Clean up temp file if created
        if [[ "$effective_brief_file" != "$brief_file" && -f "$effective_brief_file" ]]; then
            rm -f "$effective_brief_file"
        fi
    done < <(jq -c '.workers[]' "$config_file")
}

# Called when a worker starts — marks its hopper task in_progress
# Usage: hopper_worker_start <czarina-dir> <worker-id>
hopper_worker_start() {
    local czarina_dir="$1"
    local worker_id="$2"
    export CZARINA_DIR="$czarina_dir"

    local task_id
    task_id=$(hopper_get_worker_task "$worker_id")
    [[ -z "$task_id" ]] && return 0

    hopper_task_start "$task_id"
}

# Called at closeout — marks all open/in-progress tasks completed (or cancelled)
# Usage: hopper_closeout_orchestration <czarina-dir>
hopper_closeout_orchestration() {
    local czarina_dir="$1"
    export CZARINA_DIR="$czarina_dir"

    hopper_require

    local store
    store=$(hopper_task_store)
    if [[ ! -f "$store" ]]; then
        echo "⚠️  No hopper task store found at ${store} — skipping task closeout"
        return 0
    fi

    echo "📬 Closing hopper tasks..."

    # Complete all worker tasks
    while IFS= read -r entry; do
        local worker_id task_id
        worker_id=$(echo "$entry" | jq -r '.key')
        task_id=$(echo "$entry" | jq -r '.value')
        [[ -z "$task_id" || "$task_id" == "null" ]] && continue
        hopper_task_complete "$task_id"
        echo "   ✅ Completed [$worker_id]: $task_id"
    done < <(jq -c 'to_entries[]' < <(jq '.workers' "$store"))

    # Complete project task
    local project_task_id
    project_task_id=$(hopper_get_project_task)
    if [[ -n "$project_task_id" && "$project_task_id" != "null" ]]; then
        hopper_task_complete "$project_task_id"
        echo "   ✅ Completed project task: $project_task_id"
    fi
}
