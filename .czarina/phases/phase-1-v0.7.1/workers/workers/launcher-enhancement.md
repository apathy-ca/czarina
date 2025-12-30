# Worker Identity: launcher-enhancement

**Role:** Code
**Agent:** Claude Code
**Branch:** feat/v0.7.0-launcher-enhancement
**Phase:** 2 (Integration)
**Dependencies:** config-schema, memory-search, rules-integration

## Mission

Enhance the agent launcher to automatically load agent rules and memory context when starting workers.

## 🚀 YOUR FIRST ACTION

**Examine the current agent launcher to understand its structure:**

```bash
# Read the agent launcher script
cat czarina-core/agent-launcher.sh

# Understand how workers are currently launched
grep -A 10 "load_worker_file" czarina-core/agent-launcher.sh

# Check which agent types are supported
grep "case.*agent.*in" czarina-core/agent-launcher.sh
```

**Then:** Plan the integration points for rules and memory loading, and proceed to Objective 1 (modify launcher).

## Objectives

1. Modify `czarina-core/agent-launcher.sh` to load enriched context
2. Implement role-to-rules mapping system
3. Load Architectural Core from memory on worker start
4. Query relevant memories based on worker task
5. Inject rules into worker context files
6. Handle all 9 supported agent types
7. Manage context size (<20KB total)

## Context

The agent launcher (`czarina-core/agent-launcher.sh`) currently:
- Loads worker identity from `.czarina/workers/<worker-id>.md`
- Launches the specified agent type (claude, aider, cursor, etc.)

After enhancement, it should:
- Load worker identity (existing)
- Load Architectural Core from memory (new)
- Load role-specific rules (new)
- Query for relevant memories (new)
- Combine all into enriched context (new)
- Launch agent with full context

## Worker Context Loading Logic

```python
def load_worker_context(worker_id, role, task):
    context = []

    # 1. Task-specific instructions (existing)
    context.append(load_worker_file(worker_id))

    # 2. Architectural Core (NEW - memory)
    memory_core = load_memory_core()
    context.append(memory_core)

    # 3. Role-specific rules (NEW - agent rules)
    rules = load_rules_for_role(role)
    context.append(rules)

    # 4. Relevant memories (NEW - memory search)
    relevant_memories = search_memories(task, top_k=5)
    context.append(relevant_memories)

    # 5. Custom project rules (optional)
    if project_has_custom_rules():
        context.append(load_custom_rules())

    return optimize_context(context, max_size=20KB)
```

## Role-to-Rules Mapping

```yaml
roles:
  code:
    - agents/CODE_ROLE.md
    - python/CODING_STANDARDS.md
    - patterns/TOOL_USE_PATTERNS.md

  architect:
    - agents/ARCHITECT_ROLE.md
    - patterns/TOOL_USE_PATTERNS.md
    - documentation/ARCHITECTURE_DOCS.md

  qa:
    - agents/QA_ROLE.md
    - testing/TESTING_POLICY.md
    - testing/INTEGRATION_TESTING.md

  documentation:
    - agents/DOCUMENTATION_ROLE.md
    - documentation/DOCUMENTATION_STANDARDS.md
```

## Deliverable

Enhanced launcher that:
- Loads rules based on worker role
- Loads memory (core + relevant search results)
- Manages context size
- Works with all 9 agent types

## Success Criteria

- [ ] Launcher loads role-specific rules automatically
- [ ] Launcher loads Architectural Core from memory
- [ ] Launcher queries relevant memories on start
- [ ] Context size stays <20KB
- [ ] All 9 agent types supported
- [ ] Performance <2s overhead
- [ ] Tested with real orchestration

## Notes

- **Phase 2, sequential** - depends on config-schema, memory-search, rules-integration
- This is the key integration point where everything comes together
- Create condensed "quick reference" versions of rules to manage size
- Consider: Load full rules as reference links, load condensed versions into context
- Reference: `INTEGRATION_PLAN_v0.7.0.md` section "Worker Context Loading"
