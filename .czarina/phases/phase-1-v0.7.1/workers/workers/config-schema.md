# Worker Identity: config-schema

**Role:** Code
**Agent:** Claude Code
**Branch:** feat/v0.7.0-config-schema
**Phase:** 2 (Integration)
**Dependencies:** rules-integration, memory-core

## Mission

Extend the config.json schema to support agent rules and memory system configuration.

## 🚀 YOUR FIRST ACTION

**Examine the current config.json schema structure:**

```bash
# Read the existing schema file
cat schema/config-schema.json | jq '.'

# Check example configs to understand current usage
cat .czarina/config.json | jq '.'

# Review rules-integration output to understand what needs to be configured
ls -la czarina-core/agent-rules/
```

**Then:** Plan the schema extensions for rules and memory sections (Objective 1).

## Objectives

1. Extend config.json schema with `rules` section (global config)
2. Extend config.json schema with `memory` section (global config)
3. Add worker-level `role` field for rule loading
4. Add worker-level `rules` configuration (per-worker overrides)
5. Add worker-level `memory` configuration (per-worker overrides)
6. Update schema validation
7. Create migration guide for existing configs

## Context

Current config.json structure:
```json
{
  "project": { ... },
  "orchestration": { ... },
  "workers": [ ... ],
  "daemon": { ... }
}
```

## New Schema Extensions

**Global Configuration:**
```json
{
  "agent_rules": {
    "library_path": ".czarina/agent-rules",
    "mode": "auto",  // auto, manual, disabled
    "condensed": true
  },
  "memory": {
    "enabled": true,
    "embedding_provider": "openai",
    "embedding_model": "text-embedding-3-small",
    "similarity_threshold": 0.7,
    "max_results": 5
  }
}
```

**Worker-Level Configuration:**
```json
{
  "id": "backend",
  "role": "code",  // NEW: enables rule loading
  "agent": "claude",
  "branch": "feat/backend",
  "rules": {  // NEW: rules configuration
    "enabled": true,
    "auto_load": true,
    "domains": ["python", "testing", "security"]
  },
  "memory": {  // NEW: memory configuration
    "enabled": true,
    "use_core": true,
    "search_on_start": true
  }
}
```

## Deliverable

Extended config schema with:
- Global rules and memory configuration
- Worker-level role field
- Worker-level rules and memory overrides
- Backward compatibility maintained
- Migration guide for existing projects

## Success Criteria

- [ ] Schema extended with new fields
- [ ] Validation updated to handle new fields
- [ ] Backward compatibility verified
- [ ] Migration guide written
- [ ] Example configs created
- [ ] Documentation updated

## Notes

- **Phase 2, sequential** - depends on rules-integration and memory-core
- Must maintain backward compatibility (v0.6.2 configs still work)
- New fields should be optional with smart defaults
- Config changes needed before launcher-enhancement can use them
- Reference: `INTEGRATION_PLAN_v0.7.0.md` section "Configuration Schema"
