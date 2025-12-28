# Migration Guide: v0.6.2 to v0.7.0

This guide helps you migrate your Czarina configuration from v0.6.2 to v0.7.0, which adds support for agent rules and memory systems.

## Overview

v0.7.0 introduces:
- **Agent Rules**: Automatic loading of role-specific agent rules
- **Memory System**: Context-aware memory retrieval for workers
- **Worker Roles**: Formal role definitions for rule loading
- **Enhanced Validation**: JSON Schema-based config validation

## Backward Compatibility

**Good news:** All v0.6.2 configurations work unchanged in v0.7.0!

New features are **optional** and disabled by default. You can:
1. Continue using your existing config.json unchanged
2. Gradually adopt new features as needed
3. Mix old and new configurations

## What's New

### 1. Global Agent Rules Configuration

Add a global `agent_rules` section to enable automatic rule loading:

```json
{
  "agent_rules": {
    "library_path": ".czarina/agent-rules",
    "mode": "auto",
    "condensed": true
  }
}
```

**Options:**
- `library_path` (string): Path to agent rules library (default: `.czarina/agent-rules`)
- `mode` (string): Rule loading mode - `"auto"`, `"manual"`, or `"disabled"` (default: `"auto"`)
- `condensed` (boolean): Use condensed rule format (default: `true`)

### 2. Global Memory Configuration

Add a global `memory` section to enable the memory system:

```json
{
  "memory": {
    "enabled": true,
    "embedding_provider": "openai",
    "embedding_model": "text-embedding-3-small",
    "similarity_threshold": 0.7,
    "max_results": 5
  }
}
```

**Options:**
- `enabled` (boolean): Enable memory system (default: `true`)
- `embedding_provider` (string): Provider - `"openai"`, `"anthropic"`, or `"local"` (default: `"openai"`)
- `embedding_model` (string): Model name (default: `"text-embedding-3-small"`)
- `similarity_threshold` (number): Min similarity 0-1 (default: `0.7`)
- `max_results` (integer): Max results to return (default: `5`)

### 3. Worker Role Field

Add a `role` field to workers to enable role-based rule loading:

```json
{
  "workers": [
    {
      "id": "backend",
      "agent": "claude",
      "role": "code",
      "branch": "feat/backend"
    }
  ]
}
```

**Available roles:**
- `code` - Code implementation
- `plan` - Architecture and planning
- `review` - Code review and quality
- `test` - Testing and QA
- `integration` - Integration and merging
- `research` - Research and exploration

### 4. Worker-Level Rules Configuration

Override global rules settings per worker:

```json
{
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "rules": {
        "enabled": true,
        "auto_load": true,
        "domains": ["python", "testing", "security"]
      }
    }
  ]
}
```

**Options:**
- `enabled` (boolean): Enable rules for this worker (default: `true`)
- `auto_load` (boolean): Auto-load based on role (default: `true`)
- `domains` (array): Specific rule domains to load

**Available domains:**
- `python`, `javascript`, `typescript`
- `testing`, `security`, `documentation`
- `performance`, `git`

### 5. Worker-Level Memory Configuration

Override global memory settings per worker:

```json
{
  "workers": [
    {
      "id": "research",
      "role": "research",
      "memory": {
        "enabled": true,
        "use_core": true,
        "search_on_start": true
      }
    }
  ]
}
```

**Options:**
- `enabled` (boolean): Enable memory for this worker (default: `true`)
- `use_core` (boolean): Use core memory system (default: `true`)
- `search_on_start` (boolean): Search memory on startup (default: `true`)

## Migration Strategies

### Strategy 1: No Changes (Recommended for Initial Upgrade)

**Action:** None - keep your existing config.json

**When to use:**
- First upgrade to v0.7.0
- Testing compatibility
- No immediate need for new features

**Result:** Everything works as before

### Strategy 2: Add Global Configurations

**Action:** Add global sections, keep workers unchanged

```json
{
  "project": { /* existing */ },

  "agent_rules": {
    "library_path": ".czarina/agent-rules",
    "mode": "auto",
    "condensed": true
  },

  "memory": {
    "enabled": true,
    "embedding_provider": "openai"
  },

  "workers": [ /* existing workers unchanged */ ]
}
```

**When to use:**
- Want to prepare infrastructure
- Testing new systems
- Gradual rollout

**Result:** Infrastructure ready, but workers don't use it yet

### Strategy 3: Add Worker Roles

**Action:** Add `role` field to workers

```json
{
  "workers": [
    {
      "id": "backend",
      "agent": "claude",
      "role": "code",  // NEW
      "branch": "feat/backend"
    },
    {
      "id": "qa",
      "agent": "aider",
      "role": "test",  // NEW
      "branch": "feat/testing"
    }
  ]
}
```

**When to use:**
- Using agent rules
- Want automatic role-based rule loading
- Formalizing worker responsibilities

**Result:** Workers can load role-specific rules

### Strategy 4: Full Feature Adoption

**Action:** Add all new configurations

```json
{
  "agent_rules": { /* global config */ },
  "memory": { /* global config */ },

  "workers": [
    {
      "id": "backend",
      "role": "code",
      "rules": {
        "enabled": true,
        "domains": ["python", "testing"]
      },
      "memory": {
        "enabled": true,
        "search_on_start": true
      }
    }
  ]
}
```

**When to use:**
- New projects
- Want all v0.7.0 features
- Need fine-grained control

**Result:** Full power of v0.7.0 features

## Step-by-Step Migration

### Step 1: Validate Current Config

```bash
# Install validator
cd .czarina
python3 schema/config-validator.py validate config.json

# Check what v0.7.0 features you're using
python3 schema/config-validator.py check-compat config.json
```

### Step 2: Choose Your Strategy

Based on your needs, pick one of the strategies above.

### Step 3: Update Config

Edit `.czarina/config.json` with your chosen changes.

### Step 4: Validate New Config

```bash
python3 schema/config-validator.py validate config.json
python3 schema/config-validator.py summary config.json
```

### Step 5: Test

```bash
# Start workers and verify new features work
./czarina-launch.sh
```

## Example Migrations

### Example 1: Simple Project

**Before (v0.6.2):**
```json
{
  "project": {
    "name": "my-app",
    "repository": "/home/user/my-app"
  },
  "workers": [
    {
      "id": "backend",
      "agent": "claude",
      "branch": "feat/backend"
    }
  ]
}
```

**After (v0.7.0 with roles):**
```json
{
  "project": {
    "name": "my-app",
    "repository": "/home/user/my-app"
  },
  "agent_rules": {
    "mode": "auto"
  },
  "workers": [
    {
      "id": "backend",
      "agent": "claude",
      "role": "code",
      "branch": "feat/backend",
      "rules": {
        "domains": ["python", "testing"]
      }
    }
  ]
}
```

### Example 2: Multi-Worker Project

**Before (v0.6.2):**
```json
{
  "project": { /* ... */ },
  "workers": [
    {
      "id": "api",
      "agent": "claude",
      "branch": "feat/api"
    },
    {
      "id": "ui",
      "agent": "cursor",
      "branch": "feat/ui"
    },
    {
      "id": "qa",
      "agent": "aider",
      "branch": "feat/qa",
      "dependencies": ["api", "ui"]
    }
  ]
}
```

**After (v0.7.0 with memory):**
```json
{
  "project": { /* ... */ },
  "memory": {
    "enabled": true,
    "embedding_provider": "openai"
  },
  "workers": [
    {
      "id": "api",
      "agent": "claude",
      "role": "code",
      "branch": "feat/api",
      "memory": {
        "enabled": true,
        "search_on_start": true
      }
    },
    {
      "id": "ui",
      "agent": "cursor",
      "role": "code",
      "branch": "feat/ui",
      "memory": {
        "enabled": true,
        "search_on_start": true
      }
    },
    {
      "id": "qa",
      "agent": "aider",
      "role": "test",
      "branch": "feat/qa",
      "dependencies": ["api", "ui"],
      "memory": {
        "enabled": true,
        "search_on_start": true
      }
    }
  ]
}
```

## Validation Tools

### Validate Configuration

```bash
python3 schema/config-validator.py validate .czarina/config.json
```

**Output:**
```
Validating: .czarina/config.json
✓ Valid configuration
```

### Get Configuration Summary

```bash
python3 schema/config-validator.py summary .czarina/config.json
```

**Output:**
```
Configuration: .czarina/config.json

Project: my-app
  Version: 1.0.0
  Repository: /home/user/my-app

Workers: 3
  - api
    Agent: claude
    Role: code
    Rules: configured
    Memory: configured
```

### Check Backward Compatibility

```bash
python3 schema/config-validator.py check-compat .czarina/config.json
```

**Output:**
```
Checking: .czarina/config.json
✗ Uses v0.7.0 features:
  - Global agent_rules configuration
  - Global memory configuration
  - Worker 'api': role field
```

## Common Issues

### Issue: Validation Fails

**Symptom:** Config validator reports errors

**Solution:**
1. Check JSON syntax (commas, quotes, brackets)
2. Verify required fields (project.name, project.repository, workers)
3. Check enum values match allowed options
4. Use examples as reference

### Issue: Rules Not Loading

**Symptom:** Worker doesn't load rules despite configuration

**Solution:**
1. Ensure global `agent_rules` section exists
2. Verify `mode` is not `"disabled"`
3. Check `library_path` points to valid directory
4. Add `role` field to worker
5. Verify worker `rules.enabled` is `true`

### Issue: Memory Not Working

**Symptom:** Memory searches return no results

**Solution:**
1. Ensure global `memory` section exists with `enabled: true`
2. Check embedding provider credentials configured
3. Verify worker `memory.enabled` is `true`
4. Ensure memory database is populated

## Reference

### Complete Schema

See `schema/config-schema.json` for full JSON Schema definition.

### Example Configurations

- `examples/config-basic.json` - v0.6.2 style config
- `examples/config-with-rules.json` - With agent rules
- `examples/config-with-memory.json` - With memory system
- `examples/config-full-featured.json` - All features enabled

### Documentation

- `docs/CONFIGURATION.md` - Full configuration reference
- `schema/config-validator.py` - Validation tool
- `agents/README.md` - Agent profiles documentation

## Getting Help

1. **Validation errors:** Run validator with your config
2. **Feature questions:** Check example configs
3. **Schema details:** See config-schema.json
4. **Issues:** File bug report with config + error output

## Next Steps

After migration:

1. **Test workers** - Verify they launch and work correctly
2. **Monitor rules** - Check that appropriate rules load
3. **Test memory** - Verify memory searches work
4. **Optimize** - Fine-tune thresholds and domains
5. **Document** - Update your project documentation

Happy migrating! 🚀
