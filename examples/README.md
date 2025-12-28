# Czarina v0.7.0 Examples

This directory contains example files for Czarina v0.7.0 features.

## Files

### memories-example.md

Example memory file showing the proper structure for `.czarina/memories.md`.

**Demonstrates:**
- Architectural Core section (essential, always-loaded context)
- Project Knowledge section (session entries with learnings)
- Patterns and Decisions section (documented choices)
- Technical Debt tracking
- Environment-specific notes

**Usage:**
```bash
# Use as template when initializing memory
cp examples/memories-example.md .czarina/memories.md

# Edit to match your project
nano .czarina/memories.md

# Rebuild index after editing
czarina memory rebuild
```

### config-v0.7.0-full.json

Full-featured configuration example with all v0.7.0 features enabled.

**Includes:**
- Memory system configuration (with OpenAI embeddings)
- Agent rules configuration (auto-loading, custom mappings)
- 9 workers with different roles
- Per-worker memory and rules settings
- Worker dependencies
- Daemon and hopper configuration

**Usage:**
```bash
# Use as reference for complex projects
cat examples/config-v0.7.0-full.json

# Copy and customize
cp examples/config-v0.7.0-full.json .czarina/config.json
nano .czarina/config.json
```

**Best for:**
- Large projects with 5+ workers
- Teams wanting full v0.7.0 features
- Projects needing fine-grained control

### config-v0.7.0-minimal.json

Minimal configuration example with v0.7.0 features using defaults.

**Includes:**
- Memory enabled (uses defaults)
- Agent rules enabled (uses defaults)
- 3 workers with role fields
- Daemon enabled
- All other settings use defaults

**Usage:**
```bash
# Use as starting point for simple projects
cp examples/config-v0.7.0-minimal.json .czarina/config.json
nano .czarina/config.json
```

**Best for:**
- Small projects with 2-3 workers
- Quick starts
- Projects wanting v0.7.0 benefits with minimal configuration

## Quick Start with Examples

### Using Full Config

```bash
# 1. Copy config
cp examples/config-v0.7.0-full.json .czarina/config.json

# 2. Copy memory template
cp examples/memories-example.md .czarina/memories.md

# 3. Customize both files for your project
nano .czarina/config.json
nano .czarina/memories.md

# 4. Launch
czarina launch
```

### Using Minimal Config

```bash
# 1. Init with memory and rules
czarina init --with-memory --with-rules

# 2. This creates minimal config automatically
# Edit as needed
nano .czarina/config.json

# 3. Optionally use memory template
cp examples/memories-example.md .czarina/memories.md
nano .czarina/memories.md

# 4. Launch
czarina launch
```

## See Also

- [MEMORY_GUIDE.md](../MEMORY_GUIDE.md) - Memory system usage
- [AGENT_RULES.md](../AGENT_RULES.md) - Agent rules integration
- [MIGRATION_v0.7.0.md](../MIGRATION_v0.7.0.md) - Migration guide
- [QUICK_START.md](../QUICK_START.md) - Getting started
