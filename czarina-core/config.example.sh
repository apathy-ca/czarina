#!/bin/bash
# Czarina Configuration Example
# Copy this to config.sh and customize for your project

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PROJECT CONFIGURATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Absolute path to your project repository
export PROJECT_ROOT="/path/to/your/project"

# Project name (for display)
export PROJECT_NAME="Your Project Name"

# Orchestrator directory (usually auto-detected)
export ORCHESTRATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prompts directory
export PROMPTS_DIR="${ORCHESTRATOR_DIR}/prompts"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WORKER DEFINITIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Format: "worker_id|branch_name|task_file|description"
# - worker_id: Unique identifier (e.g., engineer1, qa, docs)
# - branch_name: Git branch for this worker (INCLUDE VERSION/FEATURE IDENTIFIER!)
# - task_file: Path to task specification file (relative to PROMPTS_DIR)
# - description: Human-readable description
#
# IMPORTANT: Use version/feature prefixes in branch names!
# Good: feat/v1.2-backend, feat/auth-system-api, feat/gateway-client
# Bad:  feat/backend, feat/api, feat/client

export WORKER_DEFINITIONS=(
    "engineer1|feat/v1.2-backend|engineer1_TASKS.txt|Backend Development"
    "engineer2|feat/v1.2-frontend|engineer2_TASKS.txt|Frontend Development"
    "engineer3|feat/v1.2-integration|engineer3_TASKS.txt|Integration Work"
    "qa|feat/v1.2-testing|qa_TASKS.txt|Testing & Validation"
    "docs|feat/v1.2-documentation|docs_TASKS.txt|Documentation"
)

# Alternative naming patterns:
# By semantic version:
#   "engineer1|feat/v1.2.0-backend|..."
#
# By feature name:
#   "engineer1|feat/auth-system-backend|..."
#
# By project name:
#   "engineer1|feat/gateway-client|..."  (like SARK example)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# OMNIBUS BRANCH CONFIGURATION (for final integration)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Name of the integration branch (merges all worker branches)
export OMNIBUS_BRANCH="feat/integration"

# Order to merge worker branches (respects dependencies)
export OMNIBUS_MERGE_ORDER=(
    "engineer1"  # Dependencies first
    "engineer2"
    "engineer3"
    "qa"         # Tests after implementation
    "docs"       # Docs last
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VISUAL STYLING (for terminal output)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m'  # No Color

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# OPTIONAL SETTINGS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Autonomous Czar check interval (seconds)
export CZAR_CHECK_INTERVAL=30

# Stuck worker threshold (seconds) - workers with no activity for this long are "stuck"
export STUCK_THRESHOLD=7200  # 2 hours

# Slow worker threshold (seconds) - workers with no activity are "slow"
export SLOW_THRESHOLD=3600   # 1 hour
