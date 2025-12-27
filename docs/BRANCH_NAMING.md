# Branch Naming Convention

## Overview

Czarina uses a structured branch naming convention to clearly identify phase ownership and prevent conflicts across multi-phase development.

## Format

### Worker Branches
```
cz<phase>/feat/<worker-id>
```

**Examples:**
- `cz1/feat/logging` - Phase 1, logging worker
- `cz1/feat/hopper` - Phase 1, hopper worker
- `cz2/feat/auth` - Phase 2, authentication worker

### Omnibus/Integration Branch
```
cz<phase>/release/v<version>
```

**Examples:**
- `cz1/release/v0.6.0` - Phase 1, version 0.6.0
- `cz2/release/v0.7.0` - Phase 2, version 0.7.0

## Benefits

1. **Clear Ownership** - `cz` prefix immediately identifies czarina-managed branches
2. **Phase Isolation** - Different phases use different prefixes (`cz1/`, `cz2/`)
3. **Easy Filtering** - `git branch | grep cz1/` shows all Phase 1 branches
4. **Safe Cleanup** - `git branch -D cz1/feat/*` removes only Phase 1 worker branches
5. **No Conflicts** - Multiple phases can coexist without branch name collisions

## Validation

Branch naming is automatically validated when:
- Initializing a new project (`czarina init`)
- Launching workers (`czarina launch`)

The validation script checks:
- Worker branches follow `cz<phase>/feat/<worker-id>` pattern
- Omnibus branch follows `cz<phase>/release/v<version>` pattern
- Phase number in branches matches config.json

## Migration

Existing projects can adopt this convention incrementally:
- New phases use the new convention
- Old branches remain unchanged
- Both conventions can coexist

## Examples

### Single Phase Project

```json
{
  "project": {
    "phase": 1,
    "omnibus_branch": "cz1/release/v0.6.0"
  },
  "workers": [
    {"id": "logging", "branch": "cz1/feat/logging"},
    {"id": "hopper", "branch": "cz1/feat/hopper"}
  ]
}
```

**Branches:**
- `cz1/feat/logging`
- `cz1/feat/hopper`
- `cz1/release/v0.6.0`

### Multi-Phase Project

**Phase 1 (v0.6.0):**
```
cz1/feat/logging
cz1/feat/hopper
cz1/release/v0.6.0
```

**Phase 2 (v0.7.0):**
```
cz2/feat/auth
cz2/feat/api
cz2/release/v0.7.0
```

All branches can exist simultaneously without conflicts.
