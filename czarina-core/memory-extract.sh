#!/usr/bin/env bash
# Memory Extraction Workflow - Interactive session memory extraction
# Helps capture learnings at the end of a work session

set -euo pipefail

# Source the memory manager functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/memory-manager.sh"

# Colors for output
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'

#####################################
# Extraction Workflow Functions
#####################################

# Prompt for user input with a default value
# Args: $1 = prompt message, $2 = default value (optional)
prompt_input() {
    local prompt_msg="$1"
    local default_value="${2:-}"
    local input

    if [[ -n "$default_value" ]]; then
        read -r -p "$prompt_msg [$default_value]: " input
        echo "${input:-$default_value}"
    else
        read -r -p "$prompt_msg: " input
        echo "$input"
    fi
}

# Prompt for multi-line input until user enters empty line
# Args: $1 = prompt message
prompt_multiline() {
    local prompt_msg="$1"
    local lines=()
    local line

    echo "$prompt_msg"
    echo "(Enter items one per line, empty line to finish)"

    while true; do
        read -r line
        if [[ -z "$line" ]]; then
            break
        fi
        lines+=("$line")
    done

    printf '%s\n' "${lines[@]}"
}

# Interactive session extraction
extract_session() {
    log_message "$CYAN" "${BOLD}╔════════════════════════════════════════════════════════╗"
    log_message "$CYAN" "${BOLD}║   Czarina Memory Extraction - Session Summary         ║"
    log_message "$CYAN" "${BOLD}╚════════════════════════════════════════════════════════╝"
    echo ""

    if ! memory_file_exists; then
        log_message "$RED" "❌ Memory file not found. Run 'memory-manager.sh init' first."
        return 1
    fi

    # Get session date and description
    local today
    today=$(date +%Y-%m-%d)

    echo ""
    log_message "$BLUE" "Session Information:"
    local session_date
    session_date=$(prompt_input "Session date" "$today")

    local session_desc
    session_desc=$(prompt_input "Brief description" "Work Session")

    # What we did
    echo ""
    log_message "$BLUE" "What did you accomplish this session?"
    local what_we_did
    what_we_did=$(prompt_multiline "Accomplishments:")

    # What broke (optional)
    echo ""
    log_message "$BLUE" "Did anything break or go wrong? (optional)"
    echo "Press Enter to skip, or list issues:"
    local what_broke
    what_broke=$(prompt_multiline "Issues:")

    # Root cause (if things broke)
    local root_cause=""
    if [[ -n "$what_broke" ]]; then
        echo ""
        log_message "$BLUE" "What was the root cause?"
        read -r -p "Root cause: " root_cause
    fi

    # Resolution (if things broke)
    local resolution=""
    if [[ -n "$what_broke" ]]; then
        echo ""
        log_message "$BLUE" "How did you resolve it?"
        read -r -p "Resolution: " resolution
    fi

    # Prevention / Learnings
    echo ""
    log_message "$BLUE" "What did you learn? What should be remembered?"
    local prevention
    prevention=$(prompt_multiline "Key learnings:")

    # Build the session entry
    local session_content
    session_content=$(cat <<EOF
### Session: ${session_date} - ${session_desc}

#### What We Did
${what_we_did}
EOF
)

    if [[ -n "$what_broke" ]]; then
        session_content+=$(cat <<EOF


#### What Broke
${what_broke}
EOF
)
    fi

    if [[ -n "$root_cause" ]]; then
        session_content+=$(cat <<EOF


#### Root Cause
${root_cause}
EOF
)
    fi

    if [[ -n "$resolution" ]]; then
        session_content+=$(cat <<EOF


#### Resolution
${resolution}
EOF
)
    fi

    if [[ -n "$prevention" ]]; then
        session_content+=$(cat <<EOF


#### Prevention
${prevention}
EOF
)
    fi

    # Show preview
    echo ""
    log_message "$CYAN" "${BOLD}═══════════════════════════════════════════════════════"
    log_message "$CYAN" "${BOLD}Preview of session entry:"
    log_message "$CYAN" "${BOLD}═══════════════════════════════════════════════════════"
    echo ""
    echo "$session_content"
    echo ""
    log_message "$CYAN" "${BOLD}═══════════════════════════════════════════════════════"

    # Confirm and save
    echo ""
    local confirm
    read -r -p "Save this session to memories.md? (y/n): " confirm

    if [[ "$confirm" =~ ^[Yy] ]]; then
        # Save to temporary file and use memory-manager to append
        local temp_file
        temp_file=$(mktemp)
        echo "$session_content" > "$temp_file"

        memory_append_session "$session_content"

        rm "$temp_file"

        echo ""
        log_message "$GREEN" "✅ Session saved successfully!"
        log_message "$GREEN" "📝 Added to: $MEMORY_FILE"

        # Show updated stats
        echo ""
        memory_stats
    else
        log_message "$YELLOW" "⚠️  Session not saved."
    fi
}

# Quick extraction from command line arguments
# Useful for scripting
quick_extract() {
    local description="$1"
    local accomplishments="$2"

    local today
    today=$(date +%Y-%m-%d)

    local session_content
    session_content=$(cat <<EOF
### Session: ${today} - ${description}

#### What We Did
${accomplishments}
EOF
)

    memory_append_session "$session_content"
    log_message "$GREEN" "✅ Quick session saved: $description"
}

#####################################
# Template Generation
#####################################

# Generate a session template file for manual editing
generate_template() {
    local output_file="${1:-.czarina/session-template.md}"
    local today
    today=$(date +%Y-%m-%d)

    cat > "$output_file" <<'EOF'
### Session: YYYY-MM-DD - Brief Description

#### What We Did
- Task 1
- Task 2
- Task 3

#### What Broke
- Issue 1
- Issue 2

#### Root Cause
Explanation of why the issues occurred.

#### Resolution
How we fixed the issues.

#### Prevention
- Learning 1: What we should remember
- Learning 2: How to prevent this in the future
- TODO: Action items for next session

EOF

    # Replace the date placeholder
    sed -i "s/YYYY-MM-DD/$today/" "$output_file"

    log_message "$GREEN" "✅ Template created at: $output_file"
    log_message "$BLUE" "Edit the file, then run: memory-manager.sh append-session $output_file"
}

#####################################
# CLI Interface
#####################################

show_usage() {
    cat <<EOF
Memory Extraction - Interactive session memory extraction for Czarina

Usage: memory-extract.sh <command> [options]

Commands:
    extract              Interactive session extraction (recommended)
    quick <desc> <work>  Quick extraction with minimal prompts
    template [file]      Generate a session template file for manual editing
    help                 Show this help message

Examples:
    # Interactive extraction (recommended for end-of-session)
    memory-extract.sh extract

    # Quick extraction (for simple sessions)
    memory-extract.sh quick "Bug fix" "- Fixed authentication timeout issue"

    # Generate template for manual editing
    memory-extract.sh template

Environment Variables:
    CZARINA_MEMORY_FILE  Path to memories.md (default: .czarina/memories.md)

EOF
}

#####################################
# Main Entry Point
#####################################

main() {
    local command="${1:-extract}"

    case "$command" in
        extract)
            extract_session
            ;;
        quick)
            if [[ $# -lt 3 ]]; then
                log_message "$RED" "❌ Usage: memory-extract.sh quick <description> <accomplishments>"
                exit 1
            fi
            quick_extract "$2" "$3"
            ;;
        template)
            generate_template "${2:-.czarina/session-template.md}"
            ;;
        help|--help|-h)
            show_usage
            exit 0
            ;;
        *)
            log_message "$RED" "❌ Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
