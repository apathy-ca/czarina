#!/bin/bash
# Czar Coordination Logic
# Proactive monitoring and coordination of workers
# Part of Czarina v0.5.0 - Autonomous Orchestration

set -uo pipefail  # Don't use -e - we want to continue on errors

# Configuration
CZARINA_DIR="${1:-.czarina}"
CONFIG_FILE="${CZARINA_DIR}/config.json"
LOGS_DIR="${CZARINA_DIR}/logs"
STATUS_DIR="${CZARINA_DIR}/status"
WORK_DIR="${CZARINA_DIR}/work"

# Ensure directories exist
mkdir -p "$LOGS_DIR" "$STATUS_DIR" "$WORK_DIR"

# Validate config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    echo "Usage: $0 <czarina-dir>"
    exit 1
fi

# Check for required tools
if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed"
    exit 1
fi

# Load project configuration
PROJECT_SLUG=$(jq -r '.project.slug' "$CONFIG_FILE")
PROJECT_ROOT=$(jq -r '.project.repository' "$CONFIG_FILE")
PROJECT_NAME=$(jq -r '.project.name' "$CONFIG_FILE")
WORKER_COUNT=$(jq '.workers | length' "$CONFIG_FILE")

# Czar log
CZAR_LOG="${LOGS_DIR}/czar.log"

# Logging function
czar_log() {
    local level=$1
    shift
    local message="$@"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$CZAR_LOG"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WORKER CHECKING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check all worker logs for status
czar_check_workers() {
    local worker_statuses="{"
    local first=true

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
        worker_log="${LOGS_DIR}/${worker_id}.log"

        # Get last log line
        if [ -f "$worker_log" ]; then
            last_line=$(tail -1 "$worker_log" 2>/dev/null || echo "")
            last_event=""

            # Extract event type from log line format: [timestamp] EVENT_TYPE
            if [[ "$last_line" =~ \]\ ([A-Z_]+) ]]; then
                last_event="${BASH_REMATCH[1]}"
            fi

            # Calculate time since last activity
            if [ -n "$last_line" ]; then
                log_time=$(stat -c %Y "$worker_log" 2>/dev/null || echo "0")
                current_time=$(date +%s)
                seconds_idle=$((current_time - log_time))
            else
                seconds_idle=9999
            fi

            # Determine status
            if [[ "$last_event" == "WORKER_COMPLETE" ]]; then
                status="complete"
            elif [ $seconds_idle -gt 1800 ]; then  # 30+ minutes
                status="stuck"
            elif [ $seconds_idle -gt 600 ]; then   # 10+ minutes
                status="idle"
            else
                status="active"
            fi
        else
            last_line="No log file"
            last_event=""
            seconds_idle=0
            status="not_started"
        fi

        # Build JSON object
        if [ "$first" = true ]; then
            first=false
        else
            worker_statuses="${worker_statuses},"
        fi

        worker_statuses="${worker_statuses}\"${worker_id}\":{\"status\":\"${status}\",\"last_event\":\"${last_event}\",\"idle_seconds\":${seconds_idle},\"last_line\":\"${last_line}\"}"
    done

    worker_statuses="${worker_statuses}}"

    # Save to status file
    echo "$worker_statuses" > "${STATUS_DIR}/worker-check.json"
    echo "$worker_statuses"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COMPLETION DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Detect when all workers are complete
czar_detect_completion() {
    local worker_check=$(czar_check_workers)
    local complete_count=0

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
        worker_status=$(echo "$worker_check" | jq -r ".${worker_id}.status")

        if [ "$worker_status" = "complete" ]; then
            ((complete_count++))
        fi
    done

    if [ $complete_count -eq $WORKER_COUNT ]; then
        czar_log "INFO" "🎉 All workers complete! ($complete_count/$WORKER_COUNT)"

        # Generate final status report
        czar_generate_status "FINAL"

        # Suggest integration strategy
        czar_suggest_integration

        return 0
    else
        czar_log "INFO" "Progress: $complete_count/$WORKER_COUNT workers complete"
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STATUS REPORTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Generate comprehensive status report
czar_generate_status() {
    local report_type="${1:-PERIODIC}"
    local session_id=$(date +%Y%m%d-%H%M%S)
    local report_dir="${WORK_DIR}/status-reports"
    local report_file="${report_dir}/status-${session_id}.md"

    mkdir -p "$report_dir"

    czar_log "INFO" "📊 Generating ${report_type} status report: $report_file"

    # Gather worker data
    local worker_check=$(czar_check_workers)

    # Count stats
    local active=0
    local idle=0
    local stuck=0
    local complete=0
    local not_started=0

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
        worker_status=$(echo "$worker_check" | jq -r ".${worker_id}.status")

        case "$worker_status" in
            active) ((active++));;
            idle) ((idle++));;
            stuck) ((stuck++));;
            complete) ((complete++));;
            not_started) ((not_started++));;
        esac
    done

    # Generate report
    cat > "$report_file" <<EOF
# Czarina Status Report - ${report_type}

**Project**: ${PROJECT_NAME}
**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Session**: ${session_id}

---

## Overall Progress

- ✅ Complete: $complete/$WORKER_COUNT
- 🔄 Active: $active/$WORKER_COUNT
- 💤 Idle: $idle/$WORKER_COUNT
- ⚠️ Stuck: $stuck/$WORKER_COUNT
- 🆕 Not Started: $not_started/$WORKER_COUNT

---

## Worker Details

EOF

    # Add individual worker status
    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
        worker_desc=$(jq -r ".workers[$i].description" "$CONFIG_FILE")
        worker_branch=$(jq -r ".workers[$i].branch" "$CONFIG_FILE")
        worker_status=$(echo "$worker_check" | jq -r ".${worker_id}.status")
        worker_event=$(echo "$worker_check" | jq -r ".${worker_id}.last_event")
        worker_idle=$(echo "$worker_check" | jq -r ".${worker_id}.idle_seconds")

        # Status emoji
        case "$worker_status" in
            active) status_emoji="🔄";;
            idle) status_emoji="💤";;
            stuck) status_emoji="⚠️";;
            complete) status_emoji="✅";;
            not_started) status_emoji="🆕";;
            *) status_emoji="❓";;
        esac

        # Format idle time
        if [ $worker_idle -lt 60 ]; then
            idle_str="${worker_idle}s"
        elif [ $worker_idle -lt 3600 ]; then
            idle_str="$((worker_idle / 60))m"
        else
            idle_str="$((worker_idle / 3600))h $((worker_idle % 3600 / 60))m"
        fi

        cat >> "$report_file" <<EOF
### ${status_emoji} Worker $((i+1)): ${worker_id}

- **Description**: ${worker_desc}
- **Branch**: \`${worker_branch}\`
- **Status**: ${worker_status}
- **Last Event**: ${worker_event}
- **Idle Time**: ${idle_str}

EOF

        # Add files changed count if branch exists
        if [ "$worker_branch" != "null" ] && [ -n "$worker_branch" ]; then
            cd "$PROJECT_ROOT" 2>/dev/null || true
            if git rev-parse --verify "$worker_branch" >/dev/null 2>&1; then
                files_changed=$(git diff --name-only main..."$worker_branch" 2>/dev/null | wc -l || echo "0")
                commits=$(git rev-list --count main..."$worker_branch" 2>/dev/null || echo "0")

                cat >> "$report_file" <<EOF
- **Files Changed**: ${files_changed}
- **Commits**: ${commits}

EOF
            fi
        fi
    done

    # Add recommendations if any workers are stuck
    if [ $stuck -gt 0 ]; then
        cat >> "$report_file" <<EOF

---

## ⚠️ Attention Required

**${stuck} worker(s) appear stuck** (no activity for 30+ minutes).

Recommended actions:
1. Check worker logs in: \`.czarina/logs/\`
2. Review tmux sessions
3. Consider manual intervention

EOF
    fi

    # Add next steps for final report
    if [ "$report_type" = "FINAL" ]; then
        cat >> "$report_file" <<EOF

---

## 🎉 Next Steps

All workers have completed their tasks!

1. Review integration strategy (see integration suggestion)
2. Test changes in each worker branch
3. Proceed with integration
4. Run closeout: \`czarina closeout\`

EOF
    fi

    cat >> "$report_file" <<EOF

---

*Generated by Czarina Czar v0.5.0*
EOF

    czar_log "INFO" "✅ Status report saved: $report_file"
    echo "$report_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INTEGRATION STRATEGY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Suggest integration strategy (calls integration.sh if available)
czar_suggest_integration() {
    local integration_script="${BASH_SOURCE[0]%/*}/integration.sh"

    if [ -f "$integration_script" ]; then
        czar_log "INFO" "🔀 Analyzing integration strategy..."
        bash "$integration_script" "$CZARINA_DIR"
    else
        czar_log "WARN" "Integration script not found: $integration_script"

        # Basic suggestion fallback
        if [ $WORKER_COUNT -ge 4 ]; then
            czar_log "INFO" "💡 Suggestion: Consider omnibus PR (${WORKER_COUNT} workers)"
        else
            czar_log "INFO" "💡 Suggestion: Consider sequential PRs (${WORKER_COUNT} workers)"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN COORDINATION LOOP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Main coordination loop - called periodically by daemon or manually
czar_coordinate() {
    czar_log "INFO" "🎭 Czar coordination cycle starting..."

    # 1. Check all workers
    czar_log "INFO" "Checking ${WORKER_COUNT} workers..."
    worker_check=$(czar_check_workers)

    # 2. Log summary
    local active=$(echo "$worker_check" | jq '[.[] | select(.status == "active")] | length')
    local idle=$(echo "$worker_check" | jq '[.[] | select(.status == "idle")] | length')
    local stuck=$(echo "$worker_check" | jq '[.[] | select(.status == "stuck")] | length')
    local complete=$(echo "$worker_check" | jq '[.[] | select(.status == "complete")] | length')

    czar_log "INFO" "Status: ${complete} complete, ${active} active, ${idle} idle, ${stuck} stuck"

    # 3. Alert on stuck workers
    if [ $stuck -gt 0 ]; then
        czar_log "WARN" "⚠️ ${stuck} worker(s) appear stuck - check logs"
    fi

    # 4. Check for completion
    if czar_detect_completion; then
        czar_log "INFO" "🎉 Orchestration complete!"
        return 0
    fi

    czar_log "INFO" "✅ Coordination cycle complete"
    return 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COMMAND DISPATCH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# If called directly, execute requested command
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    COMMAND="${2:-coordinate}"

    case "$COMMAND" in
        check)
            czar_check_workers | jq .
            ;;
        status)
            czar_generate_status "MANUAL"
            ;;
        completion)
            czar_detect_completion
            ;;
        coordinate)
            czar_coordinate
            ;;
        *)
            echo "Usage: $0 <czarina-dir> [check|status|completion|coordinate]"
            echo ""
            echo "Commands:"
            echo "  check       - Check all worker statuses"
            echo "  status      - Generate status report"
            echo "  completion  - Check if all workers complete"
            echo "  coordinate  - Run full coordination cycle (default)"
            exit 1
            ;;
    esac
fi
