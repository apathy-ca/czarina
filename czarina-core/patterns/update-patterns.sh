#!/bin/bash
set -euo pipefail

# Czarina Pattern Updater
# Syncs the full agent-knowledge repository into czarina

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="${PATTERN_REPO_URL:-https://github.com/apathy-ca/agent-knowledge}"
TEMP_DIR=$(mktemp -d)
VERSION_FILE="$SCRIPT_DIR/.pattern-version"
TARGET_DIR="$SCRIPT_DIR/agent-knowledge"

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
        head -1 "$VERSION_FILE"
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
log_info "Current version: $CURRENT_VERSION"
echo ""

# Clone repository
log_info "Fetching agent-knowledge from $REPO_URL..."
if ! git clone --depth 1 --quiet "$REPO_URL" "$TEMP_DIR/agent-knowledge" 2>&1; then
    log_error "Failed to clone repository"
    exit 1
fi

REPO_DIR="$TEMP_DIR/agent-knowledge"

# Get new version (use git commit hash)
cd "$REPO_DIR"
NEW_VERSION=$(git rev-parse --short HEAD)

log_success "Fetched agent-knowledge (version: $NEW_VERSION)"
echo ""

# Check if update needed
if [[ "$CURRENT_VERSION" == "$NEW_VERSION" ]]; then
    log_success "Already up to date!"
    exit 0
fi

# Remove old agent-knowledge directory if it exists
if [[ -d "$TARGET_DIR" ]]; then
    log_info "Removing old agent-knowledge..."
    rm -rf "$TARGET_DIR"
fi

# Create target directory
mkdir -p "$TARGET_DIR"

# Directories to sync
DIRS_TO_SYNC=(
    "patterns"
    "core-rules"
    "templates"
    "meta"
)

# Files to sync from root
FILES_TO_SYNC=(
    "README.md"
    "CONTRIBUTING.md"
    "CHANGELOG.md"
)

log_info "Syncing agent-knowledge..."
echo ""

# Copy directories
for dir in "${DIRS_TO_SYNC[@]}"; do
    if [[ -d "$REPO_DIR/$dir" ]]; then
        cp -r "$REPO_DIR/$dir" "$TARGET_DIR/"
        item_count=$(find "$TARGET_DIR/$dir" -type f | wc -l)
        log_success "Synced: $dir/ ($item_count files)"
    else
        log_warn "Directory not found: $dir (skipping)"
    fi
done

# Copy root files
for file in "${FILES_TO_SYNC[@]}"; do
    if [[ -f "$REPO_DIR/$file" ]]; then
        cp "$REPO_DIR/$file" "$TARGET_DIR/"
        log_success "Synced: $file"
    fi
done

# Save version
save_version "$NEW_VERSION"

echo ""
log_success "Update complete!"
log_info "Updated from $CURRENT_VERSION → $NEW_VERSION"

# Show summary
echo ""
log_info "Agent-knowledge synced to: $TARGET_DIR"
echo ""
echo "  Contents:"
for dir in "${DIRS_TO_SYNC[@]}"; do
    if [[ -d "$TARGET_DIR/$dir" ]]; then
        echo "    - $dir/"
    fi
done

# Check for Czarina-specific patterns
if [[ -d "$SCRIPT_DIR/czarina-specific" ]]; then
    echo ""
    log_info "Czarina-specific patterns preserved in: czarina-specific/"
fi

echo ""
log_success "Patterns ready for use!"
