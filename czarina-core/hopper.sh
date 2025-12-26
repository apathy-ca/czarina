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
    files=$(find "$hopper" -maxdepth 1 -name "*.md" ! -name "README.md" ! -name "*TEMPLATE*" -type f | sort)

    if [[ -z "$files" ]]; then
        echo "📭 No items in project hopper"
        echo ""
        echo "Add items with:"
        echo "  czarina hopper add <filename.md>"
        echo "  vim $hopper/<filename.md>"
        return 0
    fi

    local count=0
    while IFS= read -r file; do
        count=$((count + 1))
        local basename
        basename=$(basename "$file")

        # Try to extract metadata from file
        local priority complexity tags
        priority=$(grep -E "^\*\*Priority:\*\*" "$file" | sed 's/\*\*Priority:\*\* *//' | xargs || echo "?")
        complexity=$(grep -E "^\*\*Complexity:\*\*" "$file" | sed 's/\*\*Complexity:\*\* *//' | xargs || echo "?")
        tags=$(grep -E "^\*\*Tags:\*\*" "$file" | sed 's/\*\*Tags:\*\* *//' | xargs || echo "")

        # Get first line (title)
        local title
        title=$(head -n 1 "$file" | sed 's/^# *//')

        echo "[$count] $basename"
        echo "    Title: $title"
        echo "    Priority: $priority | Complexity: $complexity"
        if [[ -n "$tags" ]]; then
            echo "    Tags: $tags"
        fi
        echo ""
    done <<< "$files"

    echo "Total: $count item(s)"
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

    # TODO items
    echo "📝 TODO ($todo_count):"
    if [[ $todo_count -eq 0 ]]; then
        echo "   (none)"
    else
        find "$hopper/todo" -maxdepth 1 -name "*.md" -type f | sort | while read -r file; do
            local basename
            basename=$(basename "$file")
            local title
            title=$(head -n 1 "$file" | sed 's/^# *//')
            echo "   ├─ $basename"
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
            local title
            title=$(head -n 1 "$file" | sed 's/^# *//')
            echo "   ├─ $basename"
            echo "   │  $title"
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
  add <file.md>          Add an enhancement to the project hopper
  list [project|phase]   List items in hopper (default: project)
  pull <file> [--to-phase current]   Pull item from project to phase (TODO: Task 2)
  defer <file>           Defer item from phase to project (TODO: Task 2)
  assign <worker> <file> Assign item to worker (TODO: Task 2)

Examples:
  czarina hopper add enhancement-15.md
  czarina hopper list
  czarina hopper list phase
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
        pull|defer|assign)
            echo "❌ Command '$command' not yet implemented (coming in Task 2)"
            echo "   This feature will be available soon!"
            return 1
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
