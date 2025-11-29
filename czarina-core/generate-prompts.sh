#!/bin/bash
# Generate worker prompts with git workflow instructions
# Takes base prompt and injects git workflow with worker-specific variables

set -euo pipefail

# Usage: ./generate-prompts.sh <config.sh path> <template-dir> <output-dir>

if [ $# -lt 3 ]; then
    echo "Usage: $0 <config.sh> <template-dir> <output-dir>"
    echo ""
    echo "Example:"
    echo "  $0 ../projects/sark-v2-orchestration/config.sh ./templates/prompts ../projects/sark-v2-orchestration/prompts"
    exit 1
fi

CONFIG_FILE="$1"
TEMPLATE_DIR="$2"
OUTPUT_DIR="$3"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

# Get the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_WORKFLOW_TEMPLATE="$SCRIPT_DIR/templates/WORKER_GIT_WORKFLOW.md"

if [ ! -f "$GIT_WORKFLOW_TEMPLATE" ]; then
    echo "❌ Git workflow template not found: $GIT_WORKFLOW_TEMPLATE"
    exit 1
fi

# Source the config
source "$CONFIG_FILE"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        Worker Prompt Generation with Git Workflow         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Project: $PROJECT_NAME"
echo "Config: $CONFIG_FILE"
echo "Output: $OUTPUT_DIR"
echo ""

mkdir -p "$OUTPUT_DIR"

# Load git workflow template
GIT_WORKFLOW_CONTENT=$(<"$GIT_WORKFLOW_TEMPLATE")

PROMPTS_GENERATED=0

# Process each worker
for def in "${WORKER_DEFINITIONS[@]}"; do
    IFS='|' read -r worker_id branch task_file description <<< "$def"

    echo "→ Generating prompt for: $worker_id"
    echo "  Branch: $branch"
    echo "  Description: $description"

    # Find the source prompt file
    SOURCE_PROMPT="$TEMPLATE_DIR/$task_file"

    if [ ! -f "$SOURCE_PROMPT" ]; then
        echo "  ⚠️  Template not found: $SOURCE_PROMPT"
        echo "  ⏭️  Skipping"
        echo ""
        continue
    fi

    # Read the source prompt
    PROMPT_CONTENT=$(<"$SOURCE_PROMPT")

    # Create git workflow section with variable substitution
    GIT_SECTION="$GIT_WORKFLOW_CONTENT"
    GIT_SECTION="${GIT_SECTION//\{\{PROJECT_ROOT\}\}/$PROJECT_ROOT}"
    GIT_SECTION="${GIT_SECTION//\{\{WORKER_BRANCH\}\}/$branch}"
    GIT_SECTION="${GIT_SECTION//\{\{WORKER_ID\}\}/$worker_id}"
    GIT_SECTION="${GIT_SECTION//\{\{TASK_DESCRIPTION\}\}/$description}"

    # Determine output filename (preserve directory structure)
    OUTPUT_FILE="$OUTPUT_DIR/${task_file}"
    OUTPUT_FILE_DIR=$(dirname "$OUTPUT_FILE")
    mkdir -p "$OUTPUT_FILE_DIR"

    # Check if prompt already has git workflow section
    if grep -q "## 🔀 Git Workflow Instructions" "$SOURCE_PROMPT" 2>/dev/null; then
        echo "  ℹ️  Prompt already has git workflow section"
        echo "  Replacing existing section..."

        # Extract everything before the git workflow section
        BEFORE_GIT=$(sed '/## 🔀 Git Workflow Instructions/Q' "$SOURCE_PROMPT")

        # Combine: original content (before git section) + new git section
        cat > "$OUTPUT_FILE" <<EOF
$BEFORE_GIT

$GIT_SECTION
EOF
    else
        # No existing git section, append it
        cat > "$OUTPUT_FILE" <<EOF
$PROMPT_CONTENT

---

$GIT_SECTION
EOF
    fi

    echo "  ✅ Generated: $OUTPUT_FILE"
    PROMPTS_GENERATED=$((PROMPTS_GENERATED + 1))
    echo ""
done

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Summary                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  Prompts generated: $PROMPTS_GENERATED"
echo ""
echo "✅ Worker prompts ready with git workflow instructions!"
echo ""
