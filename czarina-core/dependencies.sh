#!/usr/bin/env bash
# Czarina Dependency Management System
# Handles worker dependency parsing, checking, and graph generation

set -euo pipefail

# Get dependencies for a specific worker from config.json
# Usage: get_worker_dependencies <worker_id>
# Returns: List of dependency worker IDs (one per line)
get_worker_dependencies() {
  local worker_id="$1"
  jq -r ".workers[] | select(.id == \"$worker_id\") | .dependencies[]" \
    .czarina/config.json 2>/dev/null || true
}

# Check if all dependencies for a worker have been met
# Usage: check_dependencies_met <worker_id>
# Returns: 0 if all dependencies met, 1 otherwise
check_dependencies_met() {
  local worker_id="$1"
  local deps=$(get_worker_dependencies "$worker_id")

  if [ -z "$deps" ]; then
    return 0  # No dependencies
  fi

  # Check each dependency
  for dep in $deps; do
    # Look for WORKER_COMPLETE event in dependency's log
    if ! grep -q "WORKER_COMPLETE" .czarina/logs/$dep.log 2>/dev/null; then
      echo "Waiting for dependency: $dep"
      return 1
    fi
  done

  return 0  # All dependencies met
}
