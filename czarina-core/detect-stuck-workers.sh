#!/bin/bash
# Detect Stuck Workers
# Returns list of workers that appear stuck (no activity for 2+ hours)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

STATUS_FILE="${ORCHESTRATOR_DIR}/status/worker-status.json"

# Update status first
"${SCRIPT_DIR}/update-worker-status.sh" > /dev/null 2>&1

# Check if status file exists
if [ ! -f "$STATUS_FILE" ]; then
    exit 0
fi

# Find workers with health="stuck" and session still active
jq -r '.workers | to_entries[] | select(.value.health == "stuck" and .value.session_active == true) | .key' "$STATUS_FILE" 2>/dev/null || true
