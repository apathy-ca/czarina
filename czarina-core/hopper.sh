#!/usr/bin/env bash
# hopper.sh - Two-Level Hopper System for Czarina
#
# Provides commands for managing the project hopper (long-term backlog)
# and phase hoppers (current phase scope).

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find project root and .czarina directory
find_czarina_root() {
    local current_dir="$PWD"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/.czarina" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}

# Get project hopper path
get_project_hopper() {
    local root
    root=$(find_czarina_root)
    if [[ -z "$root" ]]; then
        echo "❌ Error: Not in a czarina project (no .czarina directory found)" >&2
        return 1
    fi
    echo "$root/.czarina/hopper"
}

# Get current phase hopper path
get_phase_hopper() {
    local root
    root=$(find_czarina_root)
    if [[ -z "$root" ]]; then
        echo "❌ Error: Not in a czarina project (no .czarina directory found)" >&2
        return 1
    fi

    # Look for phase directories
    local phases_dir="$root/.czarina/phases"
    if [[ ! -d "$phases_dir" ]]; then
        echo "❌ Error: No phases directory found" >&2
        return 1
    fi

    # Find the most recent phase directory
    local phase_dir
    phase_dir=$(find "$phases_dir" -maxdepth 1 -type d -name "phase-*" | sort -V | tail -n 1)

    if [[ -z "$phase_dir" ]]; then
        echo "❌ Error: No active phase found" >&2
        return 1
    fi

    echo "$phase_dir/hopper"
}

# ============================================================================
# Metadata Parsing Helpers
# ============================================================================

# Extract metadata field from enhancement file
extract_metadata() {
    local file="$1"
    local field="$2"

    if [[ ! -f "$file" ]]; then
        echo ""
        return 1
    fi

    grep -E "^\*\*${field}:\*\*" "$file" 2>/dev/null | \
        sed "s/\*\*${field}:\*\* *//" | \
        xargs || echo ""
}

# Get priority value (High=3, Medium=2, Low=1)
get_priority_value() {
    local priority="$1"
    case "${priority,,}" in
        high) echo 3 ;;
        medium) echo 2 ;;
        low) echo 1 ;;
        *) echo 0 ;;
    esac
}

# Get complexity value (Small=1, Medium=2, Large=3)
get_complexity_value() {
    local complexity="$1"
    case "${complexity,,}" in
        small) echo 1 ;;
        medium) echo 2 ;;
        large) echo 3 ;;
        *) echo 0 ;;
    esac
}

# Calculate sort score (higher priority first, then smaller complexity)
# Score = (priority * 10) - complexity
calculate_sort_score() {
    local file="$1"
    local priority complexity priority_val complexity_val

    priority=$(extract_metadata "$file" "Priority")
    complexity=$(extract_metadata "$file" "Complexity")

    priority_val=$(get_priority_value "$priority")
    complexity_val=$(get_complexity_value "$complexity")

    # Higher priority = higher score, lower complexity = higher score
    echo $(( (priority_val * 10) - complexity_val ))
}

# ============================================================================
# Hopper Management Commands
# ============================================================================

# hopper pull - Pull item from project hopper to phase hopper
hopper_pull() {
    local file="$1"
    local to_phase="${2:-current}"

    # Parse --to-phase flag if present
    if [[ "$file" == "--to-phase" ]]; then
        echo "❌ Usage: czarina hopper pull <file.md> [--to-phase current]"
        return 1
    fi

    if [[ "$2" == "--to-phase" ]]; then
        to_phase="${3:-current}"
    fi

    if [[ -z "$file" ]]; then
        echo "❌ Usage: czarina hopper pull <file.md> [--to-phase current]"
        return 1
    fi

    # Get project hopper
    local project_hopper
    project_hopper=$(get_project_hopper) || return 1

    # Get phase hopper
    local phase_hopper
    phase_hopper=$(get_phase_hopper 2>/dev/null || true)

    if [[ -z "$phase_hopper" ]] || [[ ! -d "$phase_hopper" ]]; then
        echo "❌ Error: No active phase hopper found"
        echo "   Phase hoppers are created when phases start."
        echo ""
        echo "   For now, create manually:"
        echo "   mkdir -p .czarina/phases/phase-1-vX.Y.Z/hopper/{todo,in-progress,done}"
        return 1
    fi

    # Ensure todo directory exists
    mkdir -p "$phase_hopper/todo"

    # Source and destination paths
    local source="$project_hopper/$file"
    local dest="$phase_hopper/todo/$file"

    # Check if source exists
    if [[ ! -f "$source" ]]; then
        echo "❌ Error: File not found in project hopper: $file"
        echo "   Location: $source"
        return 1
    fi

    # Check if destination already exists
    if [[ -f "$dest" ]]; then
        echo "❌ Error: File already exists in phase hopper: $file"
        echo "   Location: $dest"
        return 1
    fi

    # Move the file
    mv "$source" "$dest"

    echo "✅ Pulled into phase hopper: $file"
    echo "   From: $source"
    echo "   To:   $dest"
    echo ""
    echo "Next steps:"
    echo "  - Assign to worker: czarina hopper assign <worker> $file"
    echo "  - View phase hopper: czarina hopper list phase"
}

# hopper defer - Move item from phase hopper back to project hopper
hopper_defer() {
    local file="$1"

    if [[ -z "$file" ]]; then
        echo "❌ Usage: czarina hopper defer <file.md>"
        return 1
    fi

    # Get project hopper
    local project_hopper
    project_hopper=$(get_project_hopper) || return 1

    # Get phase hopper
    local phase_hopper
    phase_hopper=$(get_phase_hopper 2>/dev/null || true)

    if [[ -z "$phase_hopper" ]] || [[ ! -d "$phase_hopper" ]]; then
        echo "❌ Error: No active phase hopper found"
        return 1
    fi

    # Look for the file in todo, in-progress, or done
    local source=""
    for subdir in todo in-progress done; do
        if [[ -f "$phase_hopper/$subdir/$file" ]]; then
            source="$phase_hopper/$subdir/$file"
            break
        fi
    done

    if [[ -z "$source" ]]; then
        echo "❌ Error: File not found in phase hopper: $file"
        echo "   Checked: todo/, in-progress/, done/"
        return 1
    fi

    # Destination path
    local dest="$project_hopper/$file"

    # Check if destination already exists
    if [[ -f "$dest" ]]; then
        echo "❌ Error: File already exists in project hopper: $file"
        echo "   Location: $dest"
        return 1
    fi

    # Move the file
    mv "$source" "$dest"

    echo "✅ Deferred to project hopper: $file"
    echo "   From: $source"
    echo "   To:   $dest"
    echo ""
    echo "Item moved back to backlog for future phases."
}

# hopper assign - Assign item to worker
hopper_assign() {
    local worker="$1"
    local file="$2"

    if [[ -z "$worker" ]] || [[ -z "$file" ]]; then
        echo "❌ Usage: czarina hopper assign <worker-id> <file.md>"
        return 1
    fi

    # Get phase hopper
    local phase_hopper
    phase_hopper=$(get_phase_hopper 2>/dev/null || true)

    if [[ -z "$phase_hopper" ]] || [[ ! -d "$phase_hopper" ]]; then
        echo "❌ Error: No active phase hopper found"
        return 1
    fi

    # Ensure in-progress directory exists
    mkdir -p "$phase_hopper/in-progress"

    # Source and destination paths
    local source="$phase_hopper/todo/$file"
    local dest="$phase_hopper/in-progress/$file"

    # Check if source exists
    if [[ ! -f "$source" ]]; then
        echo "❌ Error: File not found in phase hopper todo/: $file"
        echo "   Location: $source"
        echo ""
        echo "   Make sure the file is in todo/ first."
        echo "   Pull from project: czarina hopper pull $file"
        return 1
    fi

    # Check if destination already exists
    if [[ -f "$dest" ]]; then
        echo "❌ Error: File already in progress: $file"
        echo "   Location: $dest"
        return 1
    fi

    # Move the file
    mv "$source" "$dest"

    # Add worker assignment comment to the file
    local temp_file="${dest}.tmp"
    {
        echo "<!-- Assigned to: $worker -->"
        echo "<!-- Assigned on: $(date '+%Y-%m-%d %H:%M:%S') -->"
        echo ""
        cat "$dest"
    } > "$temp_file"
    mv "$temp_file" "$dest"

    echo "✅ Assigned to worker: $worker"
    echo "   File: $file"
    echo "   Location: $dest"
    echo ""
    echo "Worker $worker can now work on this enhancement."
    echo "View status: czarina hopper list phase"
}

# ============================================================================
# Hopper Commands (Add & List)
# ============================================================================

# hopper add - Add an enhancement to the project hopper
hopper_add() {
    local file="$1"

    if [[ -z "$file" ]]; then
        echo "❌ Usage: czarina hopper add <file.md>"
        return 1
    fi

    local hopper
    hopper=$(get_project_hopper) || return 1

    # Ensure hopper directory exists
    mkdir -p "$hopper"

    # Determine target path
    local target="$hopper/$file"

    # Check if file already exists
    if [[ -f "$target" ]]; then
        echo "❌ Error: File already exists in project hopper: $file"
        echo "   Location: $target"
        return 1
    fi

    # Create a template enhancement file
    cat > "$target" <<'EOF'
# Enhancement: [Title Here]

**Priority:** Medium
**Complexity:** Medium
**Tags:**
**Suggested Phase:**
**Estimate:**

## Description

[Describe the enhancement, feature, or fix here]

## Problem

[What problem does this solve?]

## Solution

[How should this be implemented?]

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Notes

[Any additional notes or context]
EOF

    echo "✅ Created: $target"
    echo ""
    echo "Next steps:"
    echo "  1. Edit the file to add details"
    echo "  2. Czar will monitor and assess for phase inclusion"
    echo "  3. View with: czarina hopper list"
}

# hopper list - List items in hopper(s)
hopper_list() {
    local scope="${1:-project}"  # 'project' or 'phase'

    if [[ "$scope" == "project" ]]; then
        hopper_list_project
    elif [[ "$scope" == "phase" ]] || [[ "$scope" == "current" ]]; then
        hopper_list_phase
    else
        echo "❌ Usage: czarina hopper list [project|phase]"
        return 1
    fi
}

# List project hopper items
hopper_list_project() {
    local hopper
    hopper=$(get_project_hopper) || return 1

    echo "═══════════════════════════════════════════════════════════"
    echo "📬 Project Hopper - Long-term Backlog"
    echo "═══════════════════════════════════════════════════════════"
    echo "Location: $hopper"
    echo ""

    # Check if hopper exists and has files
    if [[ ! -d "$hopper" ]]; then
        echo "⚠️  Project hopper not initialized"
        echo "   Run: mkdir -p $hopper"
        return 0
    fi

    local files
    files=$(find "$hopper" -maxdepth 1 -name "*.md" ! -name "README.md" ! -name "*TEMPLATE*" -type f)

    if [[ -z "$files" ]]; then
        echo "📭 No items in project hopper"
        echo ""
        echo "Add items with:"
        echo "  czarina hopper add <filename.md>"
        echo "  vim $hopper/<filename.md>"
        return 0
    fi

    # Build array of files with scores for sorting
    declare -a file_scores
    while IFS= read -r file; do
        local score
        score=$(calculate_sort_score "$file")
        file_scores+=("$score:$file")
    done <<< "$files"

    # Sort by score (descending) and display
    local count=0
    for entry in $(printf '%s\n' "${file_scores[@]}" | sort -rn -t: -k1); do
        local file="${entry#*:}"
        count=$((count + 1))
        local basename
        basename=$(basename "$file")

        # Extract metadata using helper functions
        local priority complexity tags
        priority=$(extract_metadata "$file" "Priority")
        complexity=$(extract_metadata "$file" "Complexity")
        tags=$(extract_metadata "$file" "Tags")

        # Fallback if metadata not found
        [[ -z "$priority" ]] && priority="?"
        [[ -z "$complexity" ]] && complexity="?"

        # Get title (first line starting with #, skipping HTML comments)
        local title
        title=$(grep -m 1 "^# " "$file" | sed 's/^# *//')

        # Display with priority indicator
        local priority_icon=""
        case "${priority,,}" in
            high) priority_icon="🔴" ;;
            medium) priority_icon="🟡" ;;
            low) priority_icon="🟢" ;;
        esac

        echo "[$count] $priority_icon $basename"
        echo "    Title: $title"
        echo "    Priority: $priority | Complexity: $complexity"
        if [[ -n "$tags" ]]; then
            echo "    Tags: $tags"
        fi
        echo ""
    done

    echo "Total: $count item(s)"
    echo "Sorted by priority (High→Low) and complexity (Small→Large)"
    echo "═══════════════════════════════════════════════════════════"
}

# List phase hopper items
hopper_list_phase() {
    local hopper
    hopper=$(get_phase_hopper 2>/dev/null || true)

    if [[ -z "$hopper" ]] || [[ ! -d "$hopper" ]]; then
        echo "═══════════════════════════════════════════════════════════"
        echo "📋 Phase Hopper - Current Phase Scope"
        echo "═══════════════════════════════════════════════════════════"
        echo "⚠️  No active phase hopper found"
        echo ""
        echo "Phase hoppers are created when a phase starts."
        echo "Check project hopper instead:"
        echo "  czarina hopper list project"
        return 0
    fi

    echo "═══════════════════════════════════════════════════════════"
    echo "📋 Phase Hopper - Current Phase Scope"
    echo "═══════════════════════════════════════════════════════════"
    echo "Location: $hopper"
    echo ""

    # Ensure subdirectories exist
    mkdir -p "$hopper/todo" "$hopper/in-progress" "$hopper/done"

    # Count items in each subdirectory
    local todo_count in_progress_count done_count
    todo_count=$(find "$hopper/todo" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    in_progress_count=$(find "$hopper/in-progress" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    done_count=$(find "$hopper/done" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)

    # TODO items (sorted by priority)
    echo "📝 TODO ($todo_count):"
    if [[ $todo_count -eq 0 ]]; then
        echo "   (none)"
    else
        # Build priority-sorted list
        local todo_files
        todo_files=$(find "$hopper/todo" -maxdepth 1 -name "*.md" -type f)

        declare -a todo_scores
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            local score
            score=$(calculate_sort_score "$file")
            todo_scores+=("$score:$file")
        done <<< "$todo_files"

        # Sort and display
        for entry in $(printf '%s\n' "${todo_scores[@]}" | sort -rn -t: -k1); do
            local file="${entry#*:}"
            local basename
            basename=$(basename "$file")
            local title
            title=$(head -n 1 "$file" | sed 's/^# *//')

            # Get priority for icon
            local priority
            priority=$(extract_metadata "$file" "Priority")
            local priority_icon=""
            case "${priority,,}" in
                high) priority_icon="🔴" ;;
                medium) priority_icon="🟡" ;;
                low) priority_icon="🟢" ;;
            esac

            echo "   ├─ $priority_icon $basename"
            echo "   │  $title"
        done
    fi
    echo ""

    # IN PROGRESS items
    echo "🔄 IN PROGRESS ($in_progress_count):"
    if [[ $in_progress_count -eq 0 ]]; then
        echo "   (none)"
    else
        find "$hopper/in-progress" -maxdepth 1 -name "*.md" -type f | sort | while read -r file; do
            local basename
            basename=$(basename "$file")

            # Get title, skipping HTML comments
            local title
            title=$(grep -m 1 "^# " "$file" | sed 's/^# *//')

            # Get assigned worker from comment
            local worker
            worker=$(grep -m 1 "<!-- Assigned to:" "$file" | sed 's/<!-- Assigned to: \(.*\) -->/\1/' || echo "")

            echo "   ├─ $basename"
            if [[ -n "$worker" ]]; then
                echo "   │  $title (assigned to: $worker)"
            else
                echo "   │  $title"
            fi
        done
    fi
    echo ""

    # DONE items
    echo "✅ DONE ($done_count):"
    if [[ $done_count -eq 0 ]]; then
        echo "   (none)"
    else
        find "$hopper/done" -maxdepth 1 -name "*.md" -type f | sort | while read -r file; do
            local basename
            basename=$(basename "$file")
            local title
            title=$(head -n 1 "$file" | sed 's/^# *//')
            echo "   └─ $basename"
        done
    fi
    echo ""

    echo "═══════════════════════════════════════════════════════════"
}

# Main hopper command router
hopper_main() {
    if [[ $# -lt 1 ]]; then
        cat <<EOF
Usage: czarina hopper <command> [args]

Commands:
  add <file.md>                      Add an enhancement to the project hopper
  list [project|phase]               List items in hopper (default: project)
  pull <file> [--to-phase current]   Pull item from project to phase
  defer <file>                       Defer item from phase to project
  assign <worker> <file>             Assign item to worker

Examples:
  czarina hopper add enhancement-15.md
  czarina hopper list
  czarina hopper list phase
  czarina hopper pull enhancement-15.md --to-phase current
  czarina hopper assign worker-1 enhancement-15.md
  czarina hopper defer enhancement-15.md
EOF
        return 1
    fi

    local command="$1"
    shift

    case "$command" in
        add)
            hopper_add "$@"
            ;;
        list)
            hopper_list "$@"
            ;;
        pull)
            hopper_pull "$@"
            ;;
        defer)
            hopper_defer "$@"
            ;;
        assign)
            hopper_assign "$@"
            ;;
        *)
            echo "❌ Unknown hopper command: $command"
            echo "   Run 'czarina hopper' for usage"
            return 1
            ;;
    esac
}

# If script is run directly (not sourced), execute main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    hopper_main "$@"
fi
