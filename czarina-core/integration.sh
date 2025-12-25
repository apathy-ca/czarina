#!/bin/bash
# Integration Strategy Detection
# Analyzes worker branches and suggests integration approach
# Part of Czarina v0.5.0 - Autonomous Orchestration

set -uo pipefail

# Configuration
CZARINA_DIR="${1:-.czarina}"
CONFIG_FILE="${CZARINA_DIR}/config.json"
WORK_DIR="${CZARINA_DIR}/work"

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
PROJECT_SLUG=$(jq -r '.project.slug' "$CONFIG_FILE")
PROJECT_ROOT=$(jq -r '.project.repository' "$CONFIG_FILE")
PROJECT_NAME=$(jq -r '.project.name' "$CONFIG_FILE")
WORKER_COUNT=$(jq '.workers | length' "$CONFIG_FILE")

# Output file
INTEGRATION_REPORT="${WORK_DIR}/integration-strategy.md"
mkdir -p "$WORK_DIR"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONFLICT DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Detect potential conflicts between worker branches
detect_potential_conflicts() {
    local conflicts=0
    local conflict_details=""

    # Change to project root
    cd "$PROJECT_ROOT" || exit 1

    # Build a map of files changed by each worker
    declare -A file_workers

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
        worker_branch=$(jq -r ".workers[$i].branch" "$CONFIG_FILE")

        if [ "$worker_branch" = "null" ] || [ -z "$worker_branch" ]; then
            continue
        fi

        # Check if branch exists
        if ! git rev-parse --verify "$worker_branch" >/dev/null 2>&1; then
            continue
        fi

        # Get files changed in this branch
        changed_files=$(git diff --name-only main..."$worker_branch" 2>/dev/null || true)

        # Track which workers modified which files
        while IFS= read -r file; do
            if [ -n "$file" ]; then
                if [ -n "${file_workers[$file]:-}" ]; then
                    # File already modified by another worker - potential conflict
                    ((conflicts++))
                    conflict_details="${conflict_details}\n- \`${file}\` modified by: ${file_workers[$file]} AND ${worker_id}"
                    file_workers[$file]="${file_workers[$file]}, ${worker_id}"
                else
                    file_workers[$file]="$worker_id"
                fi
            fi
        done <<< "$changed_files"
    done

    echo "$conflicts"
    if [ $conflicts -gt 0 ]; then
        echo -e "$conflict_details"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DEPENDENCY ANALYSIS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Check for dependencies between workers
analyze_dependencies() {
    local has_dependencies=false

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
        worker_deps=$(jq -r ".workers[$i].dependencies[]?" "$CONFIG_FILE" 2>/dev/null || echo "")

        if [ -n "$worker_deps" ]; then
            has_dependencies=true
            break
        fi
    done

    if [ "$has_dependencies" = true ]; then
        echo "yes"
    else
        echo "no"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CHANGE SCOPE ANALYSIS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Analyze the scope of changes across all workers
analyze_change_scope() {
    cd "$PROJECT_ROOT" || exit 1

    local total_files=0
    local total_commits=0
    local max_files=0

    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_branch=$(jq -r ".workers[$i].branch" "$CONFIG_FILE")

        if [ "$worker_branch" = "null" ] || [ -z "$worker_branch" ]; then
            continue
        fi

        if ! git rev-parse --verify "$worker_branch" >/dev/null 2>&1; then
            continue
        fi

        files=$(git diff --name-only main..."$worker_branch" 2>/dev/null | wc -l || echo "0")
        commits=$(git rev-list --count main..."$worker_branch" 2>/dev/null || echo "0")

        total_files=$((total_files + files))
        total_commits=$((total_commits + commits))

        if [ $files -gt $max_files ]; then
            max_files=$files
        fi
    done

    echo "$total_files $total_commits $max_files"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STRATEGY DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Main integration strategy detection
detect_integration_strategy() {
    echo "🔀 Analyzing integration strategy for ${PROJECT_NAME}..."
    echo ""

    # Gather data
    conflict_data=$(detect_potential_conflicts)
    conflict_count=$(echo "$conflict_data" | head -1)
    conflict_details=$(echo "$conflict_data" | tail -n +2)

    has_deps=$(analyze_dependencies)
    scope_data=$(analyze_change_scope)
    total_files=$(echo "$scope_data" | cut -d' ' -f1)
    total_commits=$(echo "$scope_data" | cut -d' ' -f2)
    max_files=$(echo "$scope_data" | cut -d' ' -f3)

    # Decision factors
    local omnibus_score=0
    local sequential_score=0

    # Factor 1: Worker count (4+ workers favor omnibus)
    if [ $WORKER_COUNT -ge 4 ]; then
        ((omnibus_score+=2))
    else
        ((sequential_score+=2))
    fi

    # Factor 2: Conflicts (high conflicts favor omnibus for coordinated resolution)
    if [ $conflict_count -gt 5 ]; then
        ((omnibus_score+=3))
    elif [ $conflict_count -gt 0 ]; then
        ((omnibus_score+=1))
    else
        ((sequential_score+=2))
    fi

    # Factor 3: Dependencies (dependencies favor omnibus)
    if [ "$has_deps" = "yes" ]; then
        ((omnibus_score+=2))
    else
        ((sequential_score+=1))
    fi

    # Factor 4: Change scope (large scope favors omnibus)
    if [ $total_files -gt 50 ]; then
        ((omnibus_score+=2))
    elif [ $total_files -lt 20 ]; then
        ((sequential_score+=1))
    fi

    # Determine recommended strategy
    if [ $omnibus_score -gt $sequential_score ]; then
        strategy="OMNIBUS"
        reasoning="High integration complexity favors a single omnibus PR for coordinated review"
    elif [ $sequential_score -gt $omnibus_score ]; then
        strategy="SEQUENTIAL"
        reasoning="Independent changes favor sequential PRs for faster, isolated reviews"
    else
        strategy="HYBRID"
        reasoning="Consider a hybrid approach: group dependent workers, separate independent ones"
    fi

    # Generate report
    cat > "$INTEGRATION_REPORT" <<EOF
# Integration Strategy Recommendation

**Project**: ${PROJECT_NAME}
**Workers**: ${WORKER_COUNT}
**Generated**: $(date '+%Y-%m-%d %H:%M:%S')

---

## Recommended Strategy: **${strategy}**

${reasoning}

---

## Analysis

### Change Scope
- **Total files changed**: ${total_files}
- **Total commits**: ${total_commits}
- **Largest worker**: ${max_files} files

### Conflicts
- **Potential conflicts**: ${conflict_count}
$(if [ $conflict_count -gt 0 ]; then echo -e "\n${conflict_details}"; fi)

### Dependencies
- **Workers have dependencies**: ${has_deps}
$(if [ "$has_deps" = "yes" ]; then
    echo ""
    for ((i=0; i<WORKER_COUNT; i++)); do
        worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
        worker_deps=$(jq -r ".workers[$i].dependencies | join(\", \")" "$CONFIG_FILE" 2>/dev/null || echo "none")
        if [ "$worker_deps" != "none" ] && [ -n "$worker_deps" ]; then
            echo "  - \`${worker_id}\` depends on: ${worker_deps}"
        fi
    done
fi)

---

## Strategy Details

### ${strategy} Approach

EOF

    # Add strategy-specific recommendations
    if [ "$strategy" = "OMNIBUS" ]; then
        cat >> "$INTEGRATION_REPORT" <<EOF
**Omnibus PR** combines all worker branches into a single pull request.

**Advantages**:
- Coordinated review of all changes together
- Easier to resolve conflicts across workers
- Single CI/CD run for all changes
- Clear atomic deployment

**Process**:
1. Create integration branch: \`git checkout -b integrate/${PROJECT_SLUG}\`
2. Merge each worker branch in dependency order:
EOF
        for ((i=0; i<WORKER_COUNT; i++)); do
            worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
            worker_branch=$(jq -r ".workers[$i].branch" "$CONFIG_FILE")
            echo "   - \`git merge ${worker_branch}\`  # ${worker_id}" >> "$INTEGRATION_REPORT"
        done
        cat >> "$INTEGRATION_REPORT" <<EOF
3. Resolve any conflicts
4. Test thoroughly
5. Create single PR: integration branch → main

EOF

    elif [ "$strategy" = "SEQUENTIAL" ]; then
        cat >> "$INTEGRATION_REPORT" <<EOF
**Sequential PRs** merge each worker branch independently.

**Advantages**:
- Faster review of smaller, focused changes
- Independent deployment of features
- Easier rollback if issues arise
- Parallel review by different team members

**Process**:
1. Order PRs by dependencies (if any)
2. Create PRs in sequence:
EOF
        for ((i=0; i<WORKER_COUNT; i++)); do
            worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
            worker_branch=$(jq -r ".workers[$i].branch" "$CONFIG_FILE")
            worker_desc=$(jq -r ".workers[$i].description" "$CONFIG_FILE")
            echo "   - PR $((i+1)): \`${worker_branch}\` → main  # ${worker_desc}" >> "$INTEGRATION_REPORT"
        done
        cat >> "$INTEGRATION_REPORT" <<EOF
3. Review and merge each PR
4. Rebase subsequent PRs if needed

EOF

    else  # HYBRID
        cat >> "$INTEGRATION_REPORT" <<EOF
**Hybrid Approach** groups related workers while keeping independent ones separate.

**Process**:
1. Group workers with dependencies into omnibus PRs
2. Keep independent workers as separate PRs
3. Suggested grouping:
EOF

        # Group by dependencies
        for ((i=0; i<WORKER_COUNT; i++)); do
            worker_id=$(jq -r ".workers[$i].id" "$CONFIG_FILE")
            worker_deps=$(jq -r ".workers[$i].dependencies | join(\", \")" "$CONFIG_FILE" 2>/dev/null || echo "")

            if [ -n "$worker_deps" ]; then
                echo "   - Group: ${worker_id} + dependencies (${worker_deps})" >> "$INTEGRATION_REPORT"
            else
                echo "   - Independent: ${worker_id}" >> "$INTEGRATION_REPORT"
            fi
        done

        echo "" >> "$INTEGRATION_REPORT"
    fi

    # Add risk assessment
    cat >> "$INTEGRATION_REPORT" <<EOF

---

## Risk Assessment

**Conflict Risk**: $(if [ $conflict_count -gt 5 ]; then echo "🔴 HIGH"; elif [ $conflict_count -gt 0 ]; then echo "🟡 MEDIUM"; else echo "🟢 LOW"; fi)
**Dependency Risk**: $(if [ "$has_deps" = "yes" ]; then echo "🟡 MEDIUM"; else echo "🟢 LOW"; fi)
**Scope Risk**: $(if [ $total_files -gt 50 ]; then echo "🔴 HIGH"; elif [ $total_files -gt 20 ]; then echo "🟡 MEDIUM"; else echo "🟢 LOW"; fi)

---

## Next Steps

1. Review this strategy recommendation
2. Adjust based on team preferences and project needs
3. Follow the process outlined above
4. Run \`czarina closeout\` when integration is complete

---

*Generated by Czarina Integration Analyzer v0.5.0*
EOF

    echo "✅ Integration strategy report generated: $INTEGRATION_REPORT"
    echo ""
    echo "📋 Recommendation: ${strategy}"
    echo "   ${reasoning}"
    echo ""
    echo "📄 Full report: $INTEGRATION_REPORT"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN EXECUTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    detect_integration_strategy
fi
