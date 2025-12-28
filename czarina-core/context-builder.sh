#!/bin/bash
# Czarina Context Builder
# Builds enriched context for workers (rules + memory)

# Load architectural core from memory system
load_memory_core() {
  local config_path="$1"
  local memory_file=".czarina/memories.md"

  # Check if memory is enabled in config
  local memory_enabled=$(jq -r '.memory.enabled // false' "$config_path" 2>/dev/null)

  if [ "$memory_enabled" != "true" ] || [ ! -f "$memory_file" ]; then
    echo ""
    return 0
  fi

  # Extract architectural core section from memories.md
  # This should be the always-loaded essentials (~2-4KB)
  if command -v python3 &> /dev/null; then
    python3 -c "
import re
import sys

try:
    with open('$memory_file', 'r') as f:
        content = f.read()

    # Look for ## Architectural Core section
    match = re.search(r'## Architectural Core\s*\n(.*?)(?=\n##|\Z)', content, re.DOTALL)
    if match:
        core = match.group(1).strip()
        # Limit to ~4KB
        if len(core) > 4096:
            core = core[:4096] + '...[truncated]'
        print(core)
except FileNotFoundError:
    pass
" 2>/dev/null
  fi
}

# Load agent rules for a specific role
load_agent_rules() {
  local role="$1"
  local config_path="$2"

  # Check if rules are enabled in config
  local rules_enabled=$(jq -r '.agent_rules.enabled // false' "$config_path" 2>/dev/null)

  if [ "$rules_enabled" != "true" ]; then
    echo ""
    return 0
  fi

  local rules_path=$(jq -r '.agent_rules.library_path // ".czarina/agent-rules"' "$config_path" 2>/dev/null)
  local condensed_mode=$(jq -r '.agent_rules.condensed // true' "$config_path" 2>/dev/null)

  # Map role to relevant rules domains
  local domains=""
  case "$role" in
    code|architect)
      domains="python agents workflows patterns"
      ;;
    qa|testing)
      domains="testing agents workflows"
      ;;
    documentation)
      domains="documentation templates"
      ;;
    integration)
      domains="workflows orchestration testing"
      ;;
    security)
      domains="security testing"
      ;;
    *)
      # Default: general agents and workflows
      domains="agents workflows"
      ;;
  esac

  # Load condensed versions of relevant domains
  if [ -d "$rules_path" ] && command -v python3 &> /dev/null; then
    python3 -c "
import os
import sys

rules_path = '$rules_path'
domains = '$domains'.split()
condensed = '$condensed_mode' == 'true'

output = []
total_size = 0
max_size = 5 * 1024  # 5KB max per domain

for domain in domains:
    domain_file = os.path.join(rules_path, f'{domain}.md')
    condensed_file = os.path.join(rules_path, 'quick-reference', f'{domain}-quick.md')

    # Try condensed version first if enabled
    target_file = condensed_file if (condensed and os.path.exists(condensed_file)) else domain_file

    if os.path.exists(target_file):
        try:
            with open(target_file, 'r') as f:
                content = f.read()

            # Limit each domain to max_size
            if len(content) > max_size:
                content = content[:max_size] + '...[truncated]'

            output.append(f'### Rules: {domain.capitalize()}')
            output.append(content)
            total_size += len(content)

            # Stop if we exceed 15KB total
            if total_size > 15 * 1024:
                break
        except:
            pass

print('\n\n'.join(output))
" 2>/dev/null
  fi
}

# Search for relevant memories based on task description
search_relevant_memories() {
  local task="$1"
  local config_path="$2"

  # Check if memory search is enabled
  local memory_enabled=$(jq -r '.memory.enabled // false' "$config_path" 2>/dev/null)

  if [ "$memory_enabled" != "true" ]; then
    echo ""
    return 0
  fi

  local max_results=$(jq -r '.memory.max_results // 5' "$config_path" 2>/dev/null)
  local similarity_threshold=$(jq -r '.memory.similarity_threshold // 0.7' "$config_path" 2>/dev/null)

  # Use memory search functionality (to be implemented by memory-search worker)
  # This is a placeholder that calls the memory search utility
  if [ -x "czarina-core/memory-search.sh" ]; then
    czarina-core/memory-search.sh query "$task" --max-results "$max_results" --threshold "$similarity_threshold" 2>/dev/null
  fi
}

# Build enriched worker context
build_worker_context() {
  local worker_id="$1"
  local role="$2"
  local task="$3"
  local config_path="$4"

  local context_file="/tmp/czarina-context-${worker_id}.md"

  {
    echo "# Enhanced Context for Worker: $worker_id"
    echo ""
    echo "This context includes project memory and agent rules to enhance your capabilities."
    echo ""

    # 1. Architectural Core from Memory
    local memory_core=$(load_memory_core "$config_path")
    if [ -n "$memory_core" ]; then
      echo "## Project Memory: Architectural Core"
      echo ""
      echo "$memory_core"
      echo ""
      echo "---"
      echo ""
    fi

    # 2. Role-specific Agent Rules
    local rules=$(load_agent_rules "$role" "$config_path")
    if [ -n "$rules" ]; then
      echo "## Agent Rules for Role: $role"
      echo ""
      echo "$rules"
      echo ""
      echo "---"
      echo ""
    fi

    # 3. Relevant Memories from Past Sessions
    local relevant_memories=$(search_relevant_memories "$task" "$config_path")
    if [ -n "$relevant_memories" ]; then
      echo "## Relevant Past Memories"
      echo ""
      echo "$relevant_memories"
      echo ""
      echo "---"
      echo ""
    fi

  } > "$context_file"

  # Return path to context file
  echo "$context_file"
}

# Get worker role from config
get_worker_role() {
  local worker_id="$1"
  local config_path="$2"

  jq -r ".workers[] | select(.id == \"$worker_id\") | .role // \"code\"" "$config_path" 2>/dev/null
}

# Get worker task/description from config
get_worker_task() {
  local worker_id="$1"
  local config_path="$2"

  jq -r ".workers[] | select(.id == \"$worker_id\") | .description // \"\"" "$config_path" 2>/dev/null
}

# Check if rules/memory are enabled for a specific worker
is_context_enhancement_enabled() {
  local worker_id="$1"
  local config_path="$2"

  # Check worker-level override first
  local worker_rules_enabled=$(jq -r ".workers[] | select(.id == \"$worker_id\") | .rules.enabled // null" "$config_path" 2>/dev/null)
  local worker_memory_enabled=$(jq -r ".workers[] | select(.id == \"$worker_id\") | .memory.enabled // null" "$config_path" 2>/dev/null)

  # Check global settings
  local global_rules=$(jq -r '.agent_rules.enabled // false' "$config_path" 2>/dev/null)
  local global_memory=$(jq -r '.memory.enabled // false' "$config_path" 2>/dev/null)

  # If either worker-level or global is enabled, return true
  if [ "$worker_rules_enabled" = "true" ] || [ "$worker_memory_enabled" = "true" ] || \
     [ "$global_rules" = "true" ] || [ "$global_memory" = "true" ]; then
    return 0  # enabled
  else
    return 1  # disabled
  fi
}
