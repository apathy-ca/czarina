#!/usr/bin/env bash
# Memory Manager - Core memory operations for Czarina
# Handles reading, writing, and validating memories.md

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

#####################################
# Configuration
#####################################

# Default paths
MEMORY_FILE="${CZARINA_MEMORY_FILE:-.czarina/memories.md}"
MEMORY_INDEX="${CZARINA_MEMORY_INDEX:-.czarina/memories.index}"

#####################################
# Core Functions
#####################################

# Print colored message
# Args: $1 = color, $2 = message
log_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}" >&2
}

# Check if memory file exists
memory_file_exists() {
    [[ -f "$MEMORY_FILE" ]]
}

# Initialize memory file with template
# Args: $1 = project name (optional)
memory_init() {
    local project_name="${1:-My Project}"

    if memory_file_exists; then
        log_message "$YELLOW" "⚠️  Memory file already exists at $MEMORY_FILE"
        return 1
    fi

    # Create .czarina directory if it doesn't exist
    mkdir -p "$(dirname "$MEMORY_FILE")"

    cat > "$MEMORY_FILE" <<EOF
# Project Memory: $project_name

## Architectural Core

### Component Dependencies
<!-- Document critical component relationships and load order here -->

### Known Couplings
<!-- Document explicit and implicit couplings discovered through development -->

### Constraints
<!-- Document critical constraints that must not be violated -->

### Technology Stack
<!-- Document key technologies, frameworks, and patterns in use -->

---

## Project Knowledge

<!-- Session entries are added here after each work session -->

---

## Patterns and Decisions

<!-- Document important architectural decisions and patterns -->

EOF

    log_message "$GREEN" "✅ Initialized memory file at $MEMORY_FILE"
    return 0
}

# Read the full architectural core section
# Returns: The architectural core content
memory_read_core() {
    if ! memory_file_exists; then
        log_message "$RED" "❌ Memory file not found at $MEMORY_FILE"
        return 1
    fi

    # Extract from "## Architectural Core" to the first "---"
    awk '/^## Architectural Core$/,/^---$/ {
        if ($0 !~ /^---$/) print
    }' "$MEMORY_FILE"
}

# Read all project knowledge (session entries)
# Returns: All session entries
memory_read_sessions() {
    if ! memory_file_exists; then
        log_message "$RED" "❌ Memory file not found at $MEMORY_FILE"
        return 1
    fi

    # Extract from "## Project Knowledge" to "## Patterns and Decisions" or EOF
    awk '/^## Project Knowledge$/,/^## Patterns and Decisions$/ {
        if ($0 !~ /^## Patterns and Decisions$/) print
    }' "$MEMORY_FILE"
}

# Read all patterns and decisions
# Returns: All patterns and decisions
memory_read_patterns() {
    if ! memory_file_exists; then
        log_message "$RED" "❌ Memory file not found at $MEMORY_FILE"
        return 1
    fi

    # Extract from "## Patterns and Decisions" to EOF
    awk '/^## Patterns and Decisions$/,0' "$MEMORY_FILE"
}

# Append a new session entry
# Args: $1 = session content (markdown formatted)
memory_append_session() {
    local session_content="$1"

    if ! memory_file_exists; then
        log_message "$RED" "❌ Memory file not found at $MEMORY_FILE"
        return 1
    fi

    # Create a temporary file
    local temp_file
    temp_file=$(mktemp)

    # Read the file and insert the session before "## Patterns and Decisions"
    awk -v session="$session_content" '
        /^## Patterns and Decisions$/ {
            print session
            print ""
        }
        { print }
    ' "$MEMORY_FILE" > "$temp_file"

    # Replace the original file
    mv "$temp_file" "$MEMORY_FILE"

    log_message "$GREEN" "✅ Session entry appended to $MEMORY_FILE"
    return 0
}

# Validate memory file format
# Returns: 0 if valid, 1 if invalid
memory_validate() {
    if ! memory_file_exists; then
        log_message "$RED" "❌ Memory file not found at $MEMORY_FILE"
        return 1
    fi

    local errors=0

    # Check for required sections
    if ! grep -q "^# Project Memory:" "$MEMORY_FILE"; then
        log_message "$RED" "❌ Missing required header: # Project Memory:"
        ((errors++))
    fi

    if ! grep -q "^## Architectural Core$" "$MEMORY_FILE"; then
        log_message "$RED" "❌ Missing required section: ## Architectural Core"
        ((errors++))
    fi

    if ! grep -q "^## Project Knowledge$" "$MEMORY_FILE"; then
        log_message "$RED" "❌ Missing required section: ## Project Knowledge"
        ((errors++))
    fi

    if ! grep -q "^## Patterns and Decisions$" "$MEMORY_FILE"; then
        log_message "$RED" "❌ Missing required section: ## Patterns and Decisions"
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        log_message "$GREEN" "✅ Memory file is valid"
        return 0
    else
        log_message "$RED" "❌ Memory file has $errors validation error(s)"
        return 1
    fi
}

# Get memory file statistics
memory_stats() {
    if ! memory_file_exists; then
        log_message "$RED" "❌ Memory file not found at $MEMORY_FILE"
        return 1
    fi

    local total_lines
    local session_count
    local pattern_count
    local file_size

    total_lines=$(wc -l < "$MEMORY_FILE")
    session_count=$(grep -c "^### Session:" "$MEMORY_FILE" || echo "0")
    pattern_count=$(grep -c "^### \[.*\]$" "$MEMORY_FILE" || echo "0")
    file_size=$(du -h "$MEMORY_FILE" | cut -f1)

    echo "Memory Statistics:"
    echo "  File: $MEMORY_FILE"
    echo "  Size: $file_size"
    echo "  Lines: $total_lines"
    echo "  Sessions: $session_count"
    echo "  Patterns: $pattern_count"
}

#####################################
# CLI Interface
#####################################

show_usage() {
    cat <<EOF
Memory Manager - Core memory operations for Czarina

Usage: memory-manager.sh <command> [options]

Commands:
    init [project-name]     Initialize a new memory file
    read-core              Read the architectural core section
    read-sessions          Read all session entries
    read-patterns          Read all patterns and decisions
    append-session <file>  Append a session entry from a file
    validate              Validate memory file format
    stats                 Show memory file statistics
    help                  Show this help message

Environment Variables:
    CZARINA_MEMORY_FILE    Path to memories.md (default: .czarina/memories.md)
    CZARINA_MEMORY_INDEX   Path to memories.index (default: .czarina/memories.index)

Examples:
    # Initialize memory for a new project
    memory-manager.sh init "My Project"

    # Read architectural core
    memory-manager.sh read-core

    # Validate memory file
    memory-manager.sh validate

    # Show statistics
    memory-manager.sh stats

EOF
}

#####################################
# Main Entry Point
#####################################

main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    local command="$1"
    shift

    case "$command" in
        init)
            memory_init "$@"
            ;;
        read-core)
            memory_read_core
            ;;
        read-sessions)
            memory_read_sessions
            ;;
        read-patterns)
            memory_read_patterns
            ;;
        append-session)
            if [[ $# -eq 0 ]]; then
                log_message "$RED" "❌ Missing session content file"
                exit 1
            fi
            local session_file="$1"
            if [[ ! -f "$session_file" ]]; then
                log_message "$RED" "❌ Session file not found: $session_file"
                exit 1
            fi
            memory_append_session "$(cat "$session_file")"
            ;;
        validate)
            memory_validate
            ;;
        stats)
            memory_stats
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
