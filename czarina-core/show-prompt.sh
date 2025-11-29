#!/bin/bash
# Safe prompt viewer - handles filenames with special characters

if [ -z "$1" ]; then
    echo "Usage: $0 <worker_id>"
    echo ""
    echo "Available workers:"
    echo "  engineer1, engineer2, engineer3, engineer4, qa, docs"
    exit 1
fi

WORKER_ID=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="${SCRIPT_DIR}/prompts/${WORKER_ID}-prompt.md"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: Prompt file not found: $PROMPT_FILE"
    exit 1
fi

# Display the prompt safely
cat "$PROMPT_FILE"
