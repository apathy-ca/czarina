#!/bin/bash
# Embed Czarina orchestration into a project repository
# This creates a self-contained orchestration directory in the project

set -euo pipefail

# Usage: ./embed-orchestration.sh <config.sh path> [--agent=<agent-id>]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path-to-config.sh> [--agent=<agent-id>]"
    echo ""
    echo "Options:"
    echo "  --agent=<agent-id>   Specify target AI agent (default: claude-code)"
    echo "                       Available: claude-code, cursor, copilot, aider, windsurf"
    echo ""
    echo "Example:"
    echo "  $0 ../projects/sark-v2-orchestration/config.sh"
    echo "  $0 ../projects/sark-v2-orchestration/config.sh --agent=cursor"
    exit 1
fi

CONFIG_FILE="$1"
AGENT_ID="claude-code"  # Default agent

# Parse optional --agent parameter
if [ $# -ge 2 ]; then
    for arg in "${@:2}"; do
        case $arg in
            --agent=*)
                AGENT_ID="${arg#*=}"
                shift
                ;;
            *)
                echo "Unknown option: $arg"
                exit 1
                ;;
        esac
    done
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates/embedded-orchestration"
AGENTS_DIR="$SCRIPT_DIR/../agents"

# Source the config
source "$CONFIG_FILE"

# Get project config dir
CONFIG_DIR="$(dirname "$CONFIG_FILE")"

# Load agent profile
PROFILE_LOADER="$AGENTS_DIR/profile-loader.py"
if [ ! -f "$PROFILE_LOADER" ]; then
    echo "❌ Agent profile loader not found: $PROFILE_LOADER"
    exit 1
fi

# Validate agent profile exists
if ! python3 "$PROFILE_LOADER" validate "$AGENT_ID" &>/dev/null; then
    echo "❌ Invalid or unknown agent: $AGENT_ID"
    echo ""
    echo "Available agents:"
    python3 "$PROFILE_LOADER" list
    exit 1
fi

# Load agent profile data
AGENT_PROFILE=$(python3 "$PROFILE_LOADER" load "$AGENT_ID")
AGENT_NAME=$(echo "$AGENT_PROFILE" | python3 -c "import sys, json; print(json.load(sys.stdin)['name'])")
AGENT_TYPE=$(echo "$AGENT_PROFILE" | python3 -c "import sys, json; print(json.load(sys.stdin)['type'])")
AGENT_DISCOVERY_INSTRUCTION=$(echo "$AGENT_PROFILE" | python3 -c "import sys, json; print(json.load(sys.stdin)['discovery']['instruction'])")

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        Embed Czarina Orchestration into Project           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Project: $PROJECT_NAME"
echo "Repository: $PROJECT_ROOT"
echo "Config: $CONFIG_FILE"
echo "Agent: $AGENT_NAME ($AGENT_ID)"
echo ""

if [ ! -d "$PROJECT_ROOT" ]; then
    echo "❌ Project root not found: $PROJECT_ROOT"
    exit 1
fi

if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "❌ Not a git repository: $PROJECT_ROOT"
    exit 1
fi

# Create project slug - use project dir name instead of full PROJECT_NAME for brevity
PROJECT_DIR_NAME=$(basename "$CONFIG_DIR" | sed 's/-orchestration$//')
PROJECT_SLUG="$PROJECT_DIR_NAME"

# Orchestration directory in the project
EMBED_DIR="$PROJECT_ROOT/czarina-$PROJECT_SLUG"

echo "📁 Creating orchestration directory: czarina-$PROJECT_SLUG"
mkdir -p "$EMBED_DIR/workers"
mkdir -p "$EMBED_DIR/status"

# Generate config.json
echo "📝 Generating config.json..."

# Build workers JSON array
WORKERS_JSON=""
for def in "${WORKER_DEFINITIONS[@]}"; do
    IFS='|' read -r worker_id branch task_file description <<< "$def"

    if [ -n "$WORKERS_JSON" ]; then
        WORKERS_JSON="$WORKERS_JSON,"
    fi

    WORKERS_JSON="$WORKERS_JSON
    {
      \"id\": \"$worker_id\",
      \"branch\": \"$branch\",
      \"task_file\": \"$task_file\",
      \"description\": \"$description\"
    }"
done

# Build checkpoints JSON array
CHECKPOINTS_JSON=""
if [ -n "${CHECKPOINTS:-}" ]; then
    for checkpoint in "${CHECKPOINTS[@]}"; do
        IFS='|' read -r checkpoint_id checkpoint_desc <<< "$checkpoint"

        if [ -n "$CHECKPOINTS_JSON" ]; then
            CHECKPOINTS_JSON="$CHECKPOINTS_JSON,"
        fi

        CHECKPOINTS_JSON="$CHECKPOINTS_JSON
    {
      \"id\": \"$checkpoint_id\",
      \"description\": \"$checkpoint_desc\"
    }"
    done
fi

# Build merge order
MERGE_ORDER=""
if [ -n "${OMNIBUS_MERGE_ORDER:-}" ]; then
    for worker in "${OMNIBUS_MERGE_ORDER[@]}"; do
        if [ -n "$MERGE_ORDER" ]; then
            MERGE_ORDER="$MERGE_ORDER, "
        fi
        MERGE_ORDER="$MERGE_ORDER\"$worker\""
    done
fi

# Write config.json
cat > "$EMBED_DIR/config.json" <<EOF
{
  "project": {
    "name": "$PROJECT_NAME",
    "slug": "$PROJECT_SLUG",
    "repository": "$PROJECT_ROOT",
    "orchestration_dir": "czarina-$PROJECT_SLUG"
  },
  "agent": {
    "id": "$AGENT_ID",
    "name": "$AGENT_NAME",
    "type": "$AGENT_TYPE"
  },
  "workers": [$WORKERS_JSON
  ],
  "omnibus": {
    "branch": "${OMNIBUS_BRANCH:-}",
    "merge_order": [$MERGE_ORDER]
  },
  "checkpoints": [$CHECKPOINTS_JSON
  ]
}
EOF

echo "  ✅ config.json created"

# Copy worker prompts with git workflow
echo ""
echo "📋 Copying worker prompts..."

WORKERS_COPIED=0
for def in "${WORKER_DEFINITIONS[@]}"; do
    IFS='|' read -r worker_id branch task_file description <<< "$def"

    # Find source prompt
    SOURCE_PROMPT="$CONFIG_DIR/$task_file"

    if [ ! -f "$SOURCE_PROMPT" ]; then
        echo "  ⚠️  Source prompt not found: $SOURCE_PROMPT"
        echo "      Skipping $worker_id"
        continue
    fi

    # Destination
    DEST_PROMPT="$EMBED_DIR/workers/${worker_id}.md"

    # Copy the prompt
    cp "$SOURCE_PROMPT" "$DEST_PROMPT"

    echo "  ✅ $worker_id → workers/${worker_id}.md"
    WORKERS_COPIED=$((WORKERS_COPIED + 1))
done

echo ""
echo "Copied $WORKERS_COPIED worker prompts"

# Copy helper scripts
echo ""
echo "🔧 Installing helper scripts..."

cp "$TEMPLATE_DIR/.worker-init" "$EMBED_DIR/.worker-init"
chmod +x "$EMBED_DIR/.worker-init"
echo "  ✅ .worker-init"

# Generate README with substitutions
echo ""
echo "📖 Generating README..."

# Build worker list for README
WORKER_LIST=""
for def in "${WORKER_DEFINITIONS[@]}"; do
    IFS='|' read -r worker_id branch task_file description <<< "$def"
    WORKER_LIST="$WORKER_LIST- **$worker_id** → \`$branch\` - $description\n"
done

# Generate README using a temp file for multi-line substitution
cp "$TEMPLATE_DIR/README.md" "$EMBED_DIR/README.md"
sed -i "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" "$EMBED_DIR/README.md"
sed -i "s|{{PROJECT_ROOT}}|$PROJECT_ROOT|g" "$EMBED_DIR/README.md"
sed -i "s|{{ORCHESTRATION_DIR}}|czarina-$PROJECT_SLUG|g" "$EMBED_DIR/README.md"

# Write worker list to temp file and use it
echo -e "$WORKER_LIST" > /tmp/czarina-worker-list.$$
sed -i "/{{WORKER_LIST}}/r /tmp/czarina-worker-list.$$" "$EMBED_DIR/README.md"
sed -i "/{{WORKER_LIST}}/d" "$EMBED_DIR/README.md"
rm -f /tmp/czarina-worker-list.$$

echo "  ✅ README.md"

# Generate START_WORKER.md using same approach
cp "$TEMPLATE_DIR/START_WORKER.md" "$EMBED_DIR/START_WORKER.md"
sed -i "s|{{PROJECT_SLUG}}|$PROJECT_SLUG|g" "$EMBED_DIR/START_WORKER.md"

echo -e "$WORKER_LIST" > /tmp/czarina-worker-list.$$
sed -i "/{{WORKER_LIST}}/r /tmp/czarina-worker-list.$$" "$EMBED_DIR/START_WORKER.md"
sed -i "/{{WORKER_LIST}}/d" "$EMBED_DIR/START_WORKER.md"
rm -f /tmp/czarina-worker-list.$$

echo "  ✅ START_WORKER.md"

# Create a simple discovery file at project root for Claude Code Web
echo ""
echo "📝 Creating root-level worker discovery..."

cat > "$PROJECT_ROOT/WORKERS.md" <<ROOTEOF
# 🎯 Multi-Agent Orchestration

This repository uses **Czarina** for multi-agent orchestration.

## Configured for: $AGENT_NAME

This orchestration is optimized for **$AGENT_NAME**.

### How to use with $AGENT_NAME

$AGENT_DISCOVERY_INSTRUCTION

**Worker files location:** \`czarina-$PROJECT_SLUG/workers/\`

### General Instructions (All Agents)

When a human tells you "You are Engineer 1" (or any worker), do this:

\`\`\`bash
# Step 1: Find your worker file
ls czarina-$PROJECT_SLUG/workers/

# Step 2: Read your specific prompt (example for engineer1)
cat czarina-$PROJECT_SLUG/workers/engineer1.md

# Step 3: Follow the instructions in that file exactly
\`\`\`

All worker prompts are in: \`czarina-$PROJECT_SLUG/workers/\`

## Available Workers

$(cat "$EMBED_DIR/config.json" | grep -A 4 '"workers"' | tail -n +2 | head -n -1)

## Quick Reference

Human says → You read:
- "Engineer 1" → \`czarina-$PROJECT_SLUG/workers/engineer1.md\`
- "Engineer 2" → \`czarina-$PROJECT_SLUG/workers/engineer2.md\`
- "QA 1" → \`czarina-$PROJECT_SLUG/workers/qa1.md\`
- "Docs 1" → \`czarina-$PROJECT_SLUG/workers/docs1.md\`

## Helper Script (Local)

\`\`\`bash
./czarina-$PROJECT_SLUG/.worker-init engineer1
\`\`\`

Shows your full prompt and branch info.

## More Info

See: \`czarina-$PROJECT_SLUG/README.md\`
ROOTEOF

echo "  ✅ WORKERS.md (at project root)"

# Add status/ to .gitignore
echo ""
echo "📝 Updating .gitignore..."

GITIGNORE="$PROJECT_ROOT/.gitignore"
if [ -f "$GITIGNORE" ]; then
    if ! grep -q "^czarina-.*/status/" "$GITIGNORE" 2>/dev/null; then
        echo "" >> "$GITIGNORE"
        echo "# Czarina orchestration runtime state" >> "$GITIGNORE"
        echo "czarina-*/status/" >> "$GITIGNORE"
        echo "  ✅ Added czarina-*/status/ to .gitignore"
    else
        echo "  ℹ️  .gitignore already configured"
    fi
else
    cat > "$GITIGNORE" <<EOF
# Czarina orchestration runtime state
czarina-*/status/
EOF
    echo "  ✅ Created .gitignore"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Summary                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  Orchestration directory: czarina-$PROJECT_SLUG/"
echo "  Worker prompts: $WORKERS_COPIED"
echo "  Location: $EMBED_DIR"
echo ""
echo "✅ Orchestration embedded successfully!"
echo ""
echo "📂 Directory structure:"
echo ""
tree -L 2 "$EMBED_DIR" 2>/dev/null || ls -la "$EMBED_DIR"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🤖 Configured for: $AGENT_NAME"
echo ""
echo "   $AGENT_DISCOVERY_INSTRUCTION"
echo ""
echo "   Workers are in: czarina-$PROJECT_SLUG/workers/"
echo ""
if [ "$AGENT_ID" = "claude-code" ]; then
echo "🎯 For Claude Code Web users:"
echo ""
echo "   Just say: \"You are Engineer 1\""
echo ""
echo "   Claude will:"
echo "   1. Auto-discover from: czarina-$PROJECT_SLUG/START_WORKER.md"
echo "   2. Load worker prompt from: czarina-$PROJECT_SLUG/workers/"
echo "   3. Follow git workflow and start working"
echo ""
fi
echo "🖥️  For local development:"
echo ""
echo "   ./czarina-$PROJECT_SLUG/.worker-init engineer-1"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Commit the orchestration: git add czarina-$PROJECT_SLUG && git commit"
echo "  2. Push to remote: git push"
echo "  3. Share repo with team"
echo "  4. They can start workers immediately!"
echo ""
