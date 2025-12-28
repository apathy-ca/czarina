# Czarina Configuration Schema

This directory contains the JSON Schema definition and validation tools for Czarina configuration files.

## Files

- **config-schema.json** - JSON Schema (Draft-07) definition for config.json
- **config-validator.py** - Python validation tool with CLI

## Quick Start

### Validate a Configuration

```bash
python3 schema/config-validator.py validate .czarina/config.json
```

### Get Configuration Summary

```bash
python3 schema/config-validator.py summary .czarina/config.json
```

### Check Backward Compatibility

```bash
python3 schema/config-validator.py check-compat .czarina/config.json
```

## Schema Overview

The Czarina configuration schema defines:

### Required Sections

- **project** - Project metadata (name, repository, version)
- **workers** - Worker definitions (id, agent, branch, description)

### Optional Sections (v0.7.0+)

- **agent_rules** - Global agent rules configuration
- **memory** - Global memory system configuration
- **hopper** - Two-level hopper system configuration
- **orchestration** - Orchestration mode and timing
- **daemon** - Daemon monitoring configuration

### Worker Extensions (v0.7.0+)

Each worker can now include:

- **role** - Worker role (code, plan, review, test, integration, research)
- **rules** - Worker-level rules configuration
- **memory** - Worker-level memory configuration

## Examples

See the `examples/` directory for sample configurations:

- `config-basic.json` - v0.6.2 compatible config
- `config-with-rules.json` - With agent rules enabled
- `config-with-memory.json` - With memory system enabled
- `config-full-featured.json` - All v0.7.0 features enabled

## Validation Tool

### Installation

The validator requires Python 3.7+ and the `jsonschema` library:

```bash
pip install jsonschema
```

### Usage

```
python3 schema/config-validator.py <command> <config-path> [--schema <schema-path>]

Commands:
  validate       Validate config against schema
  summary        Show human-readable config summary
  check-compat   Check backward compatibility with v0.6.2
```

### Examples

```bash
# Validate current config
python3 schema/config-validator.py validate .czarina/config.json

# Get summary of config
python3 schema/config-validator.py summary .czarina/config.json

# Check if config uses v0.7.0 features
python3 schema/config-validator.py check-compat .czarina/config.json

# Validate with custom schema location
python3 schema/config-validator.py validate config.json --schema custom-schema.json
```

### Exit Codes

- **0** - Success (validation passed, or compat check shows v0.6.2 compatible)
- **1** - Failure (validation failed, or compat check shows v0.7.0 features used)

## Schema Features

### Type Safety

All fields have defined types and constraints:

```json
{
  "token_budget": {
    "type": "integer",
    "minimum": 0
  },
  "similarity_threshold": {
    "type": "number",
    "minimum": 0,
    "maximum": 1
  }
}
```

### Enum Validation

Enum fields validate against allowed values:

```json
{
  "role": {
    "enum": ["code", "plan", "review", "test", "integration", "research"]
  },
  "mode": {
    "enum": ["auto", "manual", "disabled"]
  }
}
```

### Pattern Validation

String fields can have regex patterns:

```json
{
  "id": {
    "type": "string",
    "pattern": "^[a-z0-9-]+$"
  },
  "version": {
    "type": "string",
    "pattern": "^\\d+\\.\\d+\\.\\d+$"
  }
}
```

### Default Values

Optional fields have documented defaults:

```json
{
  "orchestration_dir": {
    "type": "string",
    "default": ".czarina"
  }
}
```

## Backward Compatibility

The schema maintains **full backward compatibility** with v0.6.2:

- All v0.7.0 additions are **optional**
- Existing configs work without changes
- New features are opt-in

Use `check-compat` to verify which features your config uses:

```bash
python3 schema/config-validator.py check-compat .czarina/config.json
```

**v0.6.2 compatible output:**
```
✓ Backward compatible with v0.6.2
```

**v0.7.0 features detected:**
```
✗ Uses v0.7.0 features:
  - Global agent_rules configuration
  - Worker 'backend': role field
```

## Integration

### In Python

```python
from schema.config_validator import ConfigValidator

validator = ConfigValidator()

# Validate
config = validator.load_config(".czarina/config.json")
is_valid, errors = validator.validate_config(config)

if is_valid:
    print("Valid!")
else:
    for error in errors:
        print(error)

# Check compatibility
is_compat, features = validator.check_backward_compatibility(config)
```

### In Shell Scripts

```bash
#!/bin/bash

# Validate before launching workers
if python3 schema/config-validator.py validate .czarina/config.json; then
    echo "Config valid, launching workers..."
    ./czarina-launch.sh
else
    echo "Config validation failed!"
    exit 1
fi
```

### In CI/CD

```yaml
# .github/workflows/validate-config.yml
- name: Validate Czarina Config
  run: |
    pip install jsonschema
    python3 schema/config-validator.py validate .czarina/config.json
```

## Documentation

For full configuration reference and migration guides:

- [CONFIGURATION.md](../docs/CONFIGURATION.md) - Complete configuration reference
- [MIGRATION_v0.7.0.md](../docs/MIGRATION_v0.7.0.md) - Migration guide from v0.6.2

## Schema Changes

### v0.7.0 (Current)

**Added:**
- Global `agent_rules` section
- Global `memory` section
- Worker `role` field
- Worker `rules` configuration
- Worker `memory` configuration

**Maintained:**
- Full backward compatibility with v0.6.2
- All existing fields unchanged
- No breaking changes

### v0.6.2 (Previous)

Original schema with:
- Project section
- Workers section
- Orchestration section
- Daemon section

## Contributing

When modifying the schema:

1. Update `config-schema.json`
2. Update validation logic in `config-validator.py` if needed
3. Add/update examples in `examples/`
4. Update documentation in `docs/CONFIGURATION.md`
5. Update migration guide if adding breaking changes
6. Test validation with existing configs

## Support

For issues or questions:

1. Check [CONFIGURATION.md](../docs/CONFIGURATION.md) for field documentation
2. Review [MIGRATION_v0.7.0.md](../docs/MIGRATION_v0.7.0.md) for upgrade help
3. Validate your config with the validator tool
4. Check example configs for reference patterns
