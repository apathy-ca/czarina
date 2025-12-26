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
