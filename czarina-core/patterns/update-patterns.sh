#!/bin/bash
set -euo pipefail

# Czarina Pattern Updater
# Downloads latest patterns from agentic-dev-patterns repository

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="${PATTERN_REPO_URL:-https://github.com/apathy-ca/agentic-dev-patterns}"
TEMP_DIR=$(mktemp -d)
VERSION_FILE="$SCRIPT_DIR/.pattern-version"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Check if git is available
if ! command -v git &> /dev/null; then
    log_error "git is not installed. Please install git to update patterns."
    exit 1
fi

# Get current version
get_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    else
        echo "unknown"
    fi
}

# Save new version
save_version() {
    local version=$1
    echo "$version" > "$VERSION_FILE"
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$VERSION_FILE"
}

log_info "Czarina Pattern Updater"
echo ""

# Show current version
CURRENT_VERSION=$(get_current_version)
log_info "Current pattern version: $CURRENT_VERSION"
echo ""

# Clone repository
log_info "Fetching latest patterns from $REPO_URL..."
if ! git clone --depth 1 "$REPO_URL" "$TEMP_DIR/agentic-dev-patterns" 2>&1 | grep -v "Cloning into"; then
    log_error "Failed to clone pattern repository"
    exit 1
fi

REPO_DIR="$TEMP_DIR/agentic-dev-patterns"

# Get new version (use git commit hash)
cd "$REPO_DIR"
NEW_VERSION=$(git rev-parse --short HEAD)

log_success "Fetched patterns (version: $NEW_VERSION)"
echo ""

# Check if update needed
if [[ "$CURRENT_VERSION" == "$NEW_VERSION" ]]; then
    log_success "Patterns are already up to date!"
    exit 0
fi

# Patterns to copy
PATTERNS=(
    "ERROR_RECOVERY_PATTERNS.md"
    "MODE_CAPABILITIES.md"
    "TOOL_USE_PATTERNS.md"
)

# Copy patterns
log_info "Updating patterns..."
for pattern in "${PATTERNS[@]}"; do
    if [[ -f "$REPO_DIR/$pattern" ]]; then
        cp "$REPO_DIR/$pattern" "$SCRIPT_DIR/"
        log_success "Updated: $pattern"
    else
        log_warn "Pattern not found: $pattern (skipping)"
    fi
done

# Save version
save_version "$NEW_VERSION"

echo ""
log_success "Pattern update complete!"
log_info "Updated from $CURRENT_VERSION → $NEW_VERSION"

# Show what changed
echo ""
log_info "Updated patterns:"
for pattern in "${PATTERNS[@]}"; do
    if [[ -f "$SCRIPT_DIR/$pattern" ]]; then
        echo "  - $pattern"
    fi
done

# Check for Czarina-specific patterns
if [[ -d "$SCRIPT_DIR/czarina-specific" ]]; then
    echo ""
    log_info "Czarina-specific patterns preserved:"
    ls -1 "$SCRIPT_DIR/czarina-specific/"*.md 2>/dev/null | xargs -n1 basename || true
fi

echo ""
log_success "Patterns ready for use by Czarina workers!"
