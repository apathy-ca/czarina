#!/bin/bash
# Validate czarina config.json

CONFIG_FILE="${1:-.czarina/config.json}"

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
    fi
done

# Validate omnibus branch
if [ -n "$OMNIBUS" ]; then
    if ! echo "$OMNIBUS" | grep -qE "^cz${PHASE}/release/"; then
        echo "❌ Omnibus branch '$OMNIBUS' doesn't follow naming convention"
        echo "   Expected: cz${PHASE}/release/v<version>"
        ((ERRORS++))
    fi
else
    echo "⚠️  Warning: No omnibus branch defined"
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

echo "✅ Config validation passed"
