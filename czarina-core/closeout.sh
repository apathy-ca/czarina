#!/bin/bash
# Closeout Report Generation
# Generates comprehensive CLOSEOUT.md report for orchestration session
# Part of Czarina v0.5.0 - Autonomous Orchestration

set -uo pipefail

# Configuration
CZARINA_DIR="${1:-.czarina}"
CONFIG_FILE="${CZARINA_DIR}/config.json"
WORK_DIR="${CZARINA_DIR}/work"
LOGS_DIR="${CZARINA_DIR}/logs"

# Validate config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

# Check for required tools
if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed"
    exit 1
fi

# Load project configuration
PROJECT_NAME=$(jq -r '.project.name' "$CONFIG_FILE")
PROJECT_VERSION=$(jq -r '.project.version' "$CONFIG_FILE")
PROJECT_SLUG=$(jq -r '.project.slug' "$CONFIG_FILE")
PROJECT_ROOT=$(jq -r '.project.repository' "$CONFIG_FILE")
WORKER_COUNT=$(jq '.workers | length' "$CONFIG_FILE")

# Get orchestrator directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/templates/CLOSEOUT.md.template"
METRICS_SCRIPT="${SCRIPT_DIR}/metrics.sh"
CZAR_SCRIPT="${SCRIPT_DIR}/czar.sh"

# Session metadata
SESSION_ID=$(date +%Y%m%d-%H%M%S)
START_TIME=$(stat -c %y "$CONFIG_FILE" 2>/dev/null | cut -d'.' -f1 || date '+%Y-%m-%d %H:%M:%S')
END_TIME=$(date '+%Y-%m-%d %H:%M:%S')
CZARINA_VERSION="0.5.0"

# Output file
OUTPUT_FILE="${WORK_DIR}/CLOSEOUT.md"
mkdir -p "$WORK_DIR"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DATA GATHERING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Calculate duration
calculate_duration() {
    local start=$(stat -c %Y "$CONFIG_FILE" 2>/dev/null || echo "0")
    local end=$(date +%s)
    local duration=$((end - start))

    if [ $duration -lt 3600 ]; then
        echo "$((duration / 60)) minutes"
    elif [ $duration -lt 86400 ]; then
        echo "$((duration / 3600)) hours $((duration % 3600 / 60)) minutes"
    else
        echo "$((duration / 86400)) days $((duration % 86400 / 3600)) hours"
    fi
}

# Gather session metadata
gather_session_metadata() {
    DURATION=$(calculate_duration)

    # Determine outcome
    if [ -f "$CZAR_SCRIPT" ]; then
        worker_check=$(bash "$CZAR_SCRIPT" "$CZARINA_DIR" check 2>/dev/null || echo "{}")
        completed=$(echo "$worker_check" | jq '[.[] | select(.status == "complete")] | length' 2>/dev/null || echo "0")

        if [ "$completed" -eq "$WORKER_COUNT" ]; then
            OUTCOME="✅ SUCCESS - All workers completed"
        else
            OUTCOME="⚠️ PARTIAL - $completed/$WORKER_COUNT workers completed"
        fi
    else
        OUTCOME="❓ UNKNOWN"
    fi
}

# Gather worker summaries
gather_worker_summaries() {
    WORKER_SUMMARIES=""

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
        worker_desc=$(jq -r ".workers[$i].description" "$CONFIG_FILE")
        worker_branch=$(jq -r ".workers[$i].branch" "$CONFIG_FILE")

        # Get worker status
        if [ -f "$CZAR_SCRIPT" ]; then
            worker_check=$(bash "$CZAR_SCRIPT" "$CZARINA_DIR" check 2>/dev/null || echo "{}")
            worker_status=$(echo "$worker_check" | jq -r ".${worker_id}.status" 2>/dev/null || echo "unknown")
        else
            worker_status="unknown"
        fi

        # Get metrics
        if [ -f "$METRICS_SCRIPT" ]; then
            commits=$(bash "$METRICS_SCRIPT" "$CZARINA_DIR" "$worker_id" commits 2>/dev/null || echo "0")
            files=$(bash "$METRICS_SCRIPT" "$CZARINA_DIR" "$worker_id" files 2>/dev/null || echo "0")
            tasks=$(bash "$METRICS_SCRIPT" "$CZARINA_DIR" "$worker_id" tasks 2>/dev/null || echo "0")
        else
            commits=0
            files=0
            tasks=0
        fi

        # Status emoji
        case "$worker_status" in
            complete) status_emoji="✅";;
            active) status_emoji="🔄";;
            idle) status_emoji="💤";;
            stuck) status_emoji="⚠️";;
            *) status_emoji="❓";;
        esac

        WORKER_SUMMARIES="${WORKER_SUMMARIES}
### ${status_emoji} Worker $((i+1)): ${worker_id}

**Description**: ${worker_desc}
**Branch**: \`${worker_branch}\`
**Status**: ${worker_status}

**Deliverables**:
- Commits: ${commits}
- Files changed: ${files}
- Tasks completed: ${tasks}
"

        # Add git diff stats if branch exists
        if [ "$worker_branch" != "null" ] && [ -n "$worker_branch" ]; then
            cd "$PROJECT_ROOT" 2>/dev/null || true
            if git rev-parse --verify "$worker_branch" >/dev/null 2>&1; then
                # Get insertions/deletions
                diff_stats=$(git diff --shortstat main..."$worker_branch" 2>/dev/null || echo "")
                if [ -n "$diff_stats" ]; then
                    WORKER_SUMMARIES="${WORKER_SUMMARIES}
**Changes**: ${diff_stats}
"
                fi

                # List key files changed
                key_files=$(git diff --name-only main..."$worker_branch" 2>/dev/null | head -10 || echo "")
                if [ -n "$key_files" ]; then
                    WORKER_SUMMARIES="${WORKER_SUMMARIES}
**Key Files**:
\`\`\`
${key_files}
\`\`\`
"
                fi
            fi
        fi

        WORKER_SUMMARIES="${WORKER_SUMMARIES}
---
"
    done
}

# Gather integration results
gather_integration_results() {
    INTEGRATION_RESULTS="Integration has not been performed yet."

    # Check if integration strategy was generated
    INTEGRATION_STRATEGY_FILE="${WORK_DIR}/integration-strategy.md"
    if [ -f "$INTEGRATION_STRATEGY_FILE" ]; then
        strategy=$(grep "Recommended Strategy:" "$INTEGRATION_STRATEGY_FILE" | cut -d'*' -f2 | cut -d'*' -f1 || echo "Unknown")
        INTEGRATION_RESULTS="**Recommended Strategy**: ${strategy}

See full integration strategy: [integration-strategy.md](./integration-strategy.md)
"
    else
        # Generate integration strategy
        if [ -f "${SCRIPT_DIR}/integration.sh" ]; then
            bash "${SCRIPT_DIR}/integration.sh" "$CZARINA_DIR" >/dev/null 2>&1 || true
            if [ -f "$INTEGRATION_STRATEGY_FILE" ]; then
                strategy=$(grep "Recommended Strategy:" "$INTEGRATION_STRATEGY_FILE" | cut -d'*' -f2 | cut -d'*' -f1 || echo "Unknown")
                INTEGRATION_RESULTS="**Recommended Strategy**: ${strategy}

See full integration strategy: [integration-strategy.md](./integration-strategy.md)
"
            fi
        fi
    fi
}

# Analyze successes and issues
analyze_successes_and_issues() {
    SUCCESSES=""
    ISSUES=""

    # Count completed workers
    if [ -f "$CZAR_SCRIPT" ]; then
        worker_check=$(bash "$CZAR_SCRIPT" "$CZARINA_DIR" check 2>/dev/null || echo "{}")
        completed=$(echo "$worker_check" | jq '[.[] | select(.status == "complete")] | length' 2>/dev/null || echo "0")
        stuck=$(echo "$worker_check" | jq '[.[] | select(.status == "stuck")] | length' 2>/dev/null || echo "0")

        if [ "$completed" -eq "$WORKER_COUNT" ]; then
            SUCCESSES="${SUCCESSES}- All ${WORKER_COUNT} workers completed their tasks
"
        elif [ "$completed" -gt 0 ]; then
            SUCCESSES="${SUCCESSES}- ${completed}/${WORKER_COUNT} workers completed successfully
"
        fi

        if [ "$stuck" -gt 0 ]; then
            ISSUES="${ISSUES}- ${stuck} worker(s) appeared stuck during execution
"
        fi
    fi

    # Count total commits
    total_commits=0
    total_files=0
    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")

        if [ -f "$METRICS_SCRIPT" ]; then
            commits=$(bash "$METRICS_SCRIPT" "$CZARINA_DIR" "$worker_id" commits 2>/dev/null || echo "0")
            files=$(bash "$METRICS_SCRIPT" "$CZARINA_DIR" "$worker_id" files 2>/dev/null || echo "0")
            total_commits=$((total_commits + commits))
            total_files=$((total_files + files))
        fi
    done

    if [ $total_commits -gt 0 ]; then
        SUCCESSES="${SUCCESSES}- Generated ${total_commits} commits across all workers
"
    fi

    if [ $total_files -gt 0 ]; then
        SUCCESSES="${SUCCESSES}- Modified ${total_files} files with coordinated changes
"
    fi

    # Check for daemon logs
    DAEMON_LOG="${CZARINA_DIR}/status/daemon.log"
    if [ -f "$DAEMON_LOG" ]; then
        auto_approvals=$(grep -c "Auto-approved" "$DAEMON_LOG" 2>/dev/null || echo "0")
        if [ $auto_approvals -gt 0 ]; then
            SUCCESSES="${SUCCESSES}- Daemon auto-approved ${auto_approvals} requests autonomously
"
        fi
    fi

    # Default messages if empty
    if [ -z "$SUCCESSES" ]; then
        SUCCESSES="- Session was created and configured successfully
- Workers were set up with proper branching structure
"
    fi

    if [ -z "$ISSUES" ]; then
        ISSUES="- No significant issues detected during orchestration
"
    fi
}

# Generate performance metrics
generate_performance_metrics() {
    PERFORMANCE=""

    # Calculate average completion time
    total_duration_sec=$(stat -c %Y "$CONFIG_FILE" 2>/dev/null || echo "0")
    current_time=$(date +%s)
    duration_sec=$((current_time - total_duration_sec))

    if [ $duration_sec -gt 0 ] && [ "$WORKER_COUNT" -gt 0 ]; then
        avg_time_per_worker=$((duration_sec / WORKER_COUNT))
        PERFORMANCE="${PERFORMANCE}**Time Metrics**:
- Total duration: $(calculate_duration)
- Average per worker: $((avg_time_per_worker / 60)) minutes

"
    fi

    # Throughput metrics
    total_commits=0
    total_files=0

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")

        if [ -f "$METRICS_SCRIPT" ]; then
            commits=$(bash "$METRICS_SCRIPT" "$CZARINA_DIR" "$worker_id" commits 2>/dev/null || echo "0")
            files=$(bash "$METRICS_SCRIPT" "$CZARINA_DIR" "$worker_id" files 2>/dev/null || echo "0")
            total_commits=$((total_commits + commits))
            total_files=$((total_files + files))
        fi
    done

    PERFORMANCE="${PERFORMANCE}**Throughput**:
- Total commits: ${total_commits}
- Total files changed: ${total_files}
- Commits per worker: $((total_commits / (WORKER_COUNT > 0 ? WORKER_COUNT : 1)))
- Files per worker: $((total_files / (WORKER_COUNT > 0 ? WORKER_COUNT : 1)))

"

    # Efficiency assessment
    if [ -f "$CZAR_SCRIPT" ]; then
        worker_check=$(bash "$CZAR_SCRIPT" "$CZARINA_DIR" check 2>/dev/null || echo "{}")
        completed=$(echo "$worker_check" | jq '[.[] | select(.status == "complete")] | length' 2>/dev/null || echo "0")
        completion_rate=$((completed * 100 / (WORKER_COUNT > 0 ? WORKER_COUNT : 1)))

        PERFORMANCE="${PERFORMANCE}**Efficiency**:
- Completion rate: ${completion_rate}%
- Workers completed: ${completed}/${WORKER_COUNT}
"
    fi
}

# Generate recommendations
generate_recommendations() {
    RECOMMENDATIONS=""

    # Check completion rate
    if [ -f "$CZAR_SCRIPT" ]; then
        worker_check=$(bash "$CZAR_SCRIPT" "$CZARINA_DIR" check 2>/dev/null || echo "{}")
        completed=$(echo "$worker_check" | jq '[.[] | select(.status == "complete")] | length' 2>/dev/null || echo "0")
        stuck=$(echo "$worker_check" | jq '[.[] | select(.status == "stuck")] | length' 2>/dev/null || echo "0")

        if [ "$completed" -lt "$WORKER_COUNT" ]; then
            RECOMMENDATIONS="${RECOMMENDATIONS}- **Incomplete workers**: Review and complete remaining workers before next orchestration
"
        fi

        if [ "$stuck" -gt 0 ]; then
            RECOMMENDATIONS="${RECOMMENDATIONS}- **Stuck workers**: Investigate why workers got stuck (check logs in \`.czarina/logs/\`)
- Consider adding more explicit task breakdowns to prevent worker confusion
"
        fi
    fi

    # Check for dependencies
    has_deps=$(jq '[.workers[] | select(.dependencies | length > 0)] | length' "$CONFIG_FILE")
    if [ "$has_deps" -gt 0 ]; then
        RECOMMENDATIONS="${RECOMMENDATIONS}- **Dependencies**: Workers with dependencies were used. Consider evaluating if dependency order was respected.
"
    fi

    # General recommendations
    RECOMMENDATIONS="${RECOMMENDATIONS}- **Status reports**: Review status reports in \`.czarina/work/status-reports/\` for insights
- **Integration**: Follow the integration strategy in \`integration-strategy.md\`
- **Testing**: Thoroughly test each worker's changes before final integration
- **Documentation**: Update project documentation to reflect changes made
"

    # Learning recommendations
    total_files=0
    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
        if [ -f "$METRICS_SCRIPT" ]; then
            files=$(bash "$METRICS_SCRIPT" "$CZARINA_DIR" "$worker_id" files 2>/dev/null || echo "0")
            total_files=$((total_files + files))
        fi
    done

    if [ $total_files -gt 100 ]; then
        RECOMMENDATIONS="${RECOMMENDATIONS}- **Large changeset**: Consider breaking down future orchestrations into smaller phases
"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# REPORT GENERATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Render template
render_template() {
    local template_content

    if [ -f "$TEMPLATE" ]; then
        template_content=$(cat "$TEMPLATE")
    else
        echo "⚠️ Template not found: $TEMPLATE"
        echo "Using basic template..."
        template_content="# Czarina Closeout Report

## Project: {{PROJECT_NAME}}

Session: {{SESSION_ID}}
Duration: {{DURATION}}

{{WORKER_SUMMARIES}}
"
    fi

    # Calculate summary stats
    total_commits=0
    total_files=0
    total_tasks=0

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
        if [ -f "$METRICS_SCRIPT" ]; then
            commits=$(bash "$METRICS_SCRIPT" "$CZARINA_DIR" "$worker_id" commits 2>/dev/null || echo "0")
            files=$(bash "$METRICS_SCRIPT" "$CZARINA_DIR" "$worker_id" files 2>/dev/null || echo "0")
            tasks=$(bash "$METRICS_SCRIPT" "$CZARINA_DIR" "$worker_id" tasks 2>/dev/null || echo "0")
            total_commits=$((total_commits + commits))
            total_files=$((total_files + files))
            total_tasks=$((total_tasks + tasks))
        fi
    done

    if [ -f "$CZAR_SCRIPT" ]; then
        worker_check=$(bash "$CZAR_SCRIPT" "$CZARINA_DIR" check 2>/dev/null || echo "{}")
        completed=$(echo "$worker_check" | jq '[.[] | select(.status == "complete")] | length' 2>/dev/null || echo "0")
    else
        completed=0
    fi

    SUMMARY="Orchestrated ${WORKER_COUNT} workers across ${total_files} files with ${total_commits} commits.
Completed ${completed}/${WORKER_COUNT} workers successfully."

    # Replace placeholders
    template_content="${template_content//\{\{PROJECT_NAME\}\}/$PROJECT_NAME}"
    template_content="${template_content//\{\{PROJECT_VERSION\}\}/$PROJECT_VERSION}"
    template_content="${template_content//\{\{SESSION_ID\}\}/$SESSION_ID}"
    template_content="${template_content//\{\{START_TIME\}\}/$START_TIME}"
    template_content="${template_content//\{\{END_TIME\}\}/$END_TIME}"
    template_content="${template_content//\{\{DURATION\}\}/$DURATION}"
    template_content="${template_content//\{\{OUTCOME\}\}/$OUTCOME}"
    template_content="${template_content//\{\{SUMMARY\}\}/$SUMMARY}"
    template_content="${template_content//\{\{WORKER_COUNT\}\}/$WORKER_COUNT}"
    template_content="${template_content//\{\{COMPLETED_COUNT\}\}/$completed}"
    template_content="${template_content//\{\{TASKS_COMPLETE\}\}/$total_tasks}"
    template_content="${template_content//\{\{TASKS_TOTAL\}\}/N/A}"
    template_content="${template_content//\{\{FILES_CHANGED\}\}/$total_files}"
    template_content="${template_content//\{\{TESTS_ADDED\}\}/N/A}"
    template_content="${template_content//\{\{COMMIT_COUNT\}\}/$total_commits}"
    template_content="${template_content//\{\{WORKER_SUMMARIES\}\}/$WORKER_SUMMARIES}"
    template_content="${template_content//\{\{INTEGRATION_RESULTS\}\}/$INTEGRATION_RESULTS}"
    template_content="${template_content//\{\{SUCCESSES\}\}/$SUCCESSES}"
    template_content="${template_content//\{\{ISSUES\}\}/$ISSUES}"
    template_content="${template_content//\{\{PERFORMANCE\}\}/$PERFORMANCE}"
    template_content="${template_content//\{\{RECOMMENDATIONS\}\}/$RECOMMENDATIONS}"
    template_content="${template_content//\{\{REPORT_TIME\}\}/$END_TIME}"
    template_content="${template_content//\{\{CZARINA_VERSION\}\}/$CZARINA_VERSION}"

    echo "$template_content"
}

# Main function
czarina_closeout_generate() {
    echo "📊 Generating closeout report for ${PROJECT_NAME}..."
    echo ""

    # Gather all data
    echo "  • Gathering session metadata..."
    gather_session_metadata

    echo "  • Analyzing worker summaries..."
    gather_worker_summaries

    echo "  • Checking integration results..."
    gather_integration_results

    echo "  • Analyzing successes and issues..."
    analyze_successes_and_issues

    echo "  • Calculating performance metrics..."
    generate_performance_metrics

    echo "  • Generating recommendations..."
    generate_recommendations

    # Render template
    echo "  • Rendering report..."
    render_template > "$OUTPUT_FILE"

    echo ""
    echo "✅ Closeout report generated: $OUTPUT_FILE"
    echo ""
    echo "📋 Summary:"
    echo "   • Duration: $DURATION"
    echo "   • Outcome: $OUTCOME"
    echo "   • Workers: ${WORKER_COUNT}"
    echo ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN EXECUTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    czarina_closeout_generate
fi
