#!/bin/bash
# Claude Code Orchestrator - Multi-Agent Support Configuration

# === PROJECT CONFIGURATION ===

# Project root (the git repository being worked on)
export PROJECT_ROOT="/home/jhenry/Source/GRID/claude-orchestrator"

# Project name
export PROJECT_NAME="Czarina Multi-Agent Support"

# Orchestrator directory
export ORCHESTRATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === WORKER CONFIGURATION ===
# Define workers: worker_id|branch_name|task_file|description

export WORKER_DEFINITIONS=(
    "rebrand|feat/agent-agnostic-docs|prompts/REBRAND.md|Documentation Rebranding Specialist"
    "architect|feat/agent-profiles|prompts/ARCHITECT.md|Agent Profile System Architect"
    "integrator|feat/multi-agent-launcher|prompts/INTEGRATOR.md|Multi-Agent Integration Engineer"
)

# === OMNIBUS CONFIGURATION ===

export OMNIBUS_BRANCH="feat/multi-agent-support"
export OMNIBUS_MERGE_ORDER=("rebrand" "architect" "integrator")
export OMNIBUS_BASE_BRANCH="main"

# === CHECKPOINT CONFIGURATION ===

export CHECKPOINTS=(
    "phase1_rebrand|Phase 1: Documentation Rebranded"
    "phase2_profiles|Phase 2: Agent Profiles Complete"
    "phase3_launcher|Phase 3: Multi-Agent Launcher Working"
    "phase4_tested|Phase 4: Tested with Multiple Agents"
)

# === DIRECTORY STRUCTURE ===

export WORKERS_DIR="${ORCHESTRATOR_DIR}/workers"
export STATUS_DIR="${ORCHESTRATOR_DIR}/status"
export LOGS_DIR="${ORCHESTRATOR_DIR}/logs"
export PROMPTS_DIR="${ORCHESTRATOR_DIR}/prompts"

# === ORCHESTRATOR METADATA ===

export ORCHESTRATOR_VERSION="1.0.0"
export ORCHESTRATOR_NAME="Czarina Multi-Agent Support"

# Initialize workers
init_workers() {
    declare -gA WORKERS
    for def in "${WORKER_DEFINITIONS[@]}"; do
        IFS='|' read -r worker_id branch task_file description <<< "$def"
        WORKERS[$worker_id]="${branch}|${task_file}|${description}"
    done
}

# Initialize on source
init_workers

# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m'
