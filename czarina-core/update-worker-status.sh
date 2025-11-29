#!/bin/bash
# Worker Status Update System
# Automatically updates worker status based on git activity
# Creates shared status JSON that workers can read

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

STATUS_FILE="${ORCHESTRATOR_DIR}/status/worker-status.json"
TEMP_FILE="${ORCHESTRATOR_DIR}/status/worker-status.tmp"

mkdir -p "${ORCHESTRATOR_DIR}/status"

# Initialize status structure
cat > "$TEMP_FILE" <<EOF
{
  "last_updated": "$(date -Iseconds)",
  "project": "$PROJECT_NAME",
  "workers": {
EOF

# Get worker info
workers=($(printf '%s\n' "${WORKER_DEFINITIONS[@]}" | cut -d'|' -f1))
worker_count=${#workers[@]}
current=0

cd "$PROJECT_ROOT"

for worker_def in "${WORKER_DEFINITIONS[@]}"; do
    IFS='|' read -r worker_id branch task_file description <<< "$worker_def"
    current=$((current + 1))

    # Get git info for this worker's branch
    if git show-ref --verify --quiet refs/heads/"$branch" 2>/dev/null; then
        # Branch exists locally

        # Get last commit info
        last_commit_msg=$(git log -1 --format=%s "$branch" 2>/dev/null || echo "No commits")
        last_commit_time=$(git log -1 --format=%ar "$branch" 2>/dev/null || echo "never")
        last_commit_hash=$(git log -1 --format=%h "$branch" 2>/dev/null || echo "")

        # Get files changed vs main
        files_changed=$(git diff --name-only main.."$branch" 2>/dev/null | wc -l)

        # Get commit count
        commit_count=$(git rev-list --count main.."$branch" 2>/dev/null || echo "0")

        # Determine status based on recent activity
        last_commit_epoch=$(git log -1 --format=%ct "$branch" 2>/dev/null || echo "0")
        current_epoch=$(date +%s)
        time_since=$((current_epoch - last_commit_epoch))

        if [ $last_commit_epoch -eq 0 ]; then
            status="pending"
            health="unknown"
        elif [ $time_since -lt 3600 ]; then
            # Active within last hour
            status="working"
            health="healthy"
        elif [ $time_since -lt 7200 ]; then
            # Active within last 2 hours
            status="working"
            health="slow"
        else
            # No activity for 2+ hours
            status="idle"
            health="stuck"
        fi

        # Check if PR exists
        pr_number=""
        pr_url=""
        if command -v gh &> /dev/null; then
            pr_info=$(gh pr list --head "$branch" --json number,url 2>/dev/null || echo "[]")
            pr_number=$(echo "$pr_info" | jq -r '.[0].number // ""' 2>/dev/null || echo "")
            pr_url=$(echo "$pr_info" | jq -r '.[0].url // ""' 2>/dev/null || echo "")
        fi

        # Check tmux session
        session_name="sark-worker-${worker_id}"
        if tmux has-session -t "$session_name" 2>/dev/null; then
            session_active="true"
        else
            session_active="false"
            health="crashed"
        fi

    else
        # Branch doesn't exist
        status="pending"
        health="unknown"
        last_commit_msg="No branch yet"
        last_commit_time="never"
        last_commit_hash=""
        files_changed=0
        commit_count=0
        pr_number=""
        pr_url=""
        session_active="false"
    fi

    # Write worker status to JSON
    cat >> "$TEMP_FILE" <<EOF
    "${worker_id}": {
      "status": "${status}",
      "health": "${health}",
      "description": "${description}",
      "branch": "${branch}",
      "session_active": ${session_active},
      "last_commit": {
        "message": $(echo "$last_commit_msg" | jq -Rs .),
        "hash": "${last_commit_hash}",
        "time_ago": "${last_commit_time}",
        "timestamp": ${last_commit_epoch}
      },
      "stats": {
        "files_changed": ${files_changed},
        "commits": ${commit_count}
      },
      "pr": {
        "number": "${pr_number}",
        "url": "${pr_url}"
      }
    }$([ $current -lt $worker_count ] && echo "," || echo "")
EOF
done

# Close JSON structure
cat >> "$TEMP_FILE" <<EOF
  }
}
EOF

# Validate JSON and move to final location
if jq empty "$TEMP_FILE" 2>/dev/null; then
    mv "$TEMP_FILE" "$STATUS_FILE"
    echo "✅ Worker status updated: $STATUS_FILE"
else
    echo "❌ Error: Generated invalid JSON"
    cat "$TEMP_FILE"
    exit 1
fi
