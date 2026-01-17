#!/bin/bash
# Validate czarina config.json

CONFIG_FILE="${1:-.czarina/config.json}"
AUTO_FIX="${2:-}"  # Pass --fix to auto-fix issues

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config not found: $CONFIG_FILE"
    exit 1
fi

echo "🔍 Validating config..."

# Check required fields
PHASE=$(jq -r '.project.phase // empty' "$CONFIG_FILE")
OMNIBUS=$(jq -r '.project.omnibus_branch // empty' "$CONFIG_FILE")

if [ -z "$PHASE" ]; then
    echo "⚠️  Warning: No phase number defined (defaulting to 1)"
    PHASE=1
fi

# Validate branch naming convention
WORKER_COUNT=$(jq -r '.workers | length' "$CONFIG_FILE")
ERRORS=0
BRANCH_ERRORS=0
OLD_PREFIX=""

for ((i=0; i<WORKER_COUNT; i++)); do
    worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
    worker_branch=$(jq -r ".workers[$i].branch" "$CONFIG_FILE")

    if [ "$worker_branch" = "null" ]; then
        continue
    fi

    # Check branch follows cz<phase>/ pattern
    if ! echo "$worker_branch" | grep -qE "^cz${PHASE}/"; then
        echo "❌ Worker $worker_id: Branch '$worker_branch' doesn't follow naming convention"
        echo "   Expected: cz${PHASE}/feat/$worker_id"
        ((ERRORS++))
        ((BRANCH_ERRORS++))

        # Detect old phase prefix for auto-fix
        if [ -z "$OLD_PREFIX" ]; then
            OLD_PREFIX=$(echo "$worker_branch" | grep -oE '^cz[0-9]+/')
        fi
    fi
done

# Validate omnibus branch
OMNIBUS_ERROR=0
if [ -n "$OMNIBUS" ]; then
    if ! echo "$OMNIBUS" | grep -qE "^cz${PHASE}/release/"; then
        echo "❌ Omnibus branch '$OMNIBUS' doesn't follow naming convention"
        echo "   Expected: cz${PHASE}/release/v<version>"
        ((ERRORS++))
        ((BRANCH_ERRORS++))
        OMNIBUS_ERROR=1

        # Detect old phase prefix from omnibus if not found yet
        if [ -z "$OLD_PREFIX" ]; then
            OLD_PREFIX=$(echo "$OMNIBUS" | grep -oE '^cz[0-9]+/')
        fi
    fi
else
    echo "⚠️  Warning: No omnibus branch defined"
fi

# Offer auto-fix for branch naming errors
if [ $BRANCH_ERRORS -gt 0 ] && [ -n "$OLD_PREFIX" ]; then
    NEW_PREFIX="cz${PHASE}/"
    echo ""
    echo "❌ Branch naming mismatch detected"
    echo "   Current phase: ${PHASE}"
    echo "   Found branches with: ${OLD_PREFIX}"
    echo "   Expected prefix: ${NEW_PREFIX}"
    echo ""
    echo "💡 Quick fix: sed -i 's|${OLD_PREFIX}|${NEW_PREFIX}|g' $CONFIG_FILE"
    echo ""

    # Interactive fix unless --fix flag passed
    if [ "$AUTO_FIX" = "--fix" ]; then
        echo "🔧 Auto-fixing branch names..."
        sed -i "s|${OLD_PREFIX}|${NEW_PREFIX}|g" "$CONFIG_FILE"
        echo "✅ Fixed $BRANCH_ERRORS branch name(s)"
        ERRORS=$((ERRORS - BRANCH_ERRORS))
        BRANCH_ERRORS=0
    else
        read -p "Fix automatically? (Y/n): " response
        if [ "$response" != "n" ] && [ "$response" != "N" ]; then
            sed -i "s|${OLD_PREFIX}|${NEW_PREFIX}|g" "$CONFIG_FILE"
            echo "✅ Fixed $BRANCH_ERRORS branch name(s)"
            ERRORS=$((ERRORS - BRANCH_ERRORS))
            BRANCH_ERRORS=0
        fi
    fi
fi

# Validate project slug (prevent tmux issues)
SLUG=$(jq -r '.project.slug' "$CONFIG_FILE")

if echo "$SLUG" | grep -qE '\.'; then
    echo "❌ Project slug contains dots: '$SLUG'"
    echo "   Tmux converts dots to underscores, causing session name mismatches"
    echo "   Suggested: '${SLUG//./_}'"
    ((ERRORS++))
fi

if echo "$SLUG" | grep -qE '[^a-zA-Z0-9_-]'; then
    echo "❌ Project slug contains invalid characters: '$SLUG'"
    echo "   Only alphanumeric, hyphens, and underscores allowed"
    echo "   Suggested: '$(echo "$SLUG" | sed 's/[^a-zA-Z0-9_-]/_/g')'"
    ((ERRORS++))
fi

# Validate agent availability
echo ""
echo "🤖 Checking agent availability..."

# Get unique agents used in config
AGENTS=$(jq -r '[.workers[].agent, .czar.agent // empty] | unique | .[]' "$CONFIG_FILE" 2>/dev/null | grep -v "^null$")

WARNINGS=0

for agent in $AGENTS; do
    case "$agent" in
        aider)
            if ! command -v aider &> /dev/null; then
                echo "❌ Agent '$agent' not found in PATH"
                echo "   Install: pip install aider-chat"
                ((ERRORS++))
            else
                echo "   ✅ $agent"
            fi
            ;;
        claude|claude-code)
            if ! command -v claude &> /dev/null; then
                echo "❌ Agent 'claude' not found in PATH"
                echo "   Install: npm install -g @anthropic-ai/claude-code"
                ((ERRORS++))
            else
                echo "   ✅ claude"
            fi
            ;;
        kilocode)
            if ! command -v kilocode &> /dev/null; then
                echo "❌ Agent '$agent' not found in PATH"
                echo "   Install from: https://github.com/kilocode/kilocode"
                ((ERRORS++))
            else
                echo "   ✅ $agent"
            fi
            ;;
        cursor|windsurf|copilot|github-copilot|chatgpt|chatgpt-code|codeium|claude-desktop)
            # These are manual/GUI agents - just note them
            echo "   ℹ️  $agent (manual launch required)"
            ;;
        *)
            if [ -n "$agent" ]; then
                echo "   ⚠️  Unknown agent type: $agent"
                ((WARNINGS++))
            fi
            ;;
    esac
done

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "❌ Validation failed with $ERRORS error(s)"
    echo ""
    echo "Branch Naming Convention:"
    echo "  Worker branches: cz<phase>/feat/<worker-id>"
    echo "  Omnibus branch:  cz<phase>/release/v<version>"
    echo "  Example:         cz1/feat/logging, cz1/release/v0.6.0"
    exit 1
fi

echo ""
echo "✅ Config validation passed"
