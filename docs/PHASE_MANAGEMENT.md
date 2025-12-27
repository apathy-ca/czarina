# Phase Management

Czarina uses phases to organize multi-step development efforts.

## Branch Naming Convention

**Format:**
- Worker branches: `cz<phase>/feat/<worker-id>`
- Omnibus branch: `cz<phase>/release/v<version>`

**Examples:**
```
cz1/feat/logging       # Phase 1, logging worker
cz1/feat/hopper        # Phase 1, hopper worker
cz1/release/v0.6.0     # Phase 1, omnibus/integration
```

**Benefits:**
- Clear czarina ownership (`cz` prefix)
- Phase isolation (`cz1/`, `cz2/`)
- Easy filtering: `git branch | grep cz1/`
- Easy cleanup: `git branch -D cz1/feat/*`

## Phase Lifecycle

### 1. Phase Start

```bash
czarina init --phase 1
czarina launch
```

Branches created automatically based on config.

### 2. During Phase

Workers work on their branches:
- `cz1/feat/logging`
- `cz1/feat/hopper`

QA worker integrates on omnibus:
- `cz1/release/v0.6.0`

### 3. Phase Close

```bash
# Smart cleanup (default)
czarina phase close

# Keep all worktrees
czarina phase close --keep-worktrees

# Force remove all worktrees (even with changes)
czarina phase close --force-clean
```

**Smart cleanup:**
- Clean worktrees (no changes) → Removed
- Dirty worktrees (uncommitted) → Kept + warning

**Phase data archived to:**
- `.czarina/phases/phase-N-vX.Y.Z/`
  - `config.json` - Phase configuration
  - `logs/` - Worker logs
  - `PHASE_SUMMARY.md` - Summary

### 4. Phase History

```bash
# List all phases
czarina phase list

# View phase summary
cat .czarina/phases/phase-1-v0.6.0/PHASE_SUMMARY.md
```

## Config Requirements

```json
{
  "project": {
    "phase": 1,                           // Phase number
    "omnibus_branch": "cz1/release/v0.6.0" // Omnibus branch
  },
  "workers": [
    {
      "id": "logging",
      "branch": "cz1/feat/logging"        // Follows naming convention
    }
  ]
}
```

**Validation:** Config is validated on init and launch.

## Session Naming (E#15)

**Slug requirements:**
- Only alphanumeric, hyphens, underscores
- **No dots** (tmux converts to underscores, causes issues)

```json
{
  "project": {
    "slug": "czarina-v0_6_0"  // ✅ Good (underscores)
    "slug": "czarina-v0.6.0"  // ❌ Bad (dots cause tmux issues)
  }
}
```

## Multi-Phase Projects

**Phase 1:**
- Branches: `cz1/feat/*`, `cz1/release/v0.6.0`
- Archive: `.czarina/phases/phase-1-v0.6.0/`

**Phase 2:**
- Branches: `cz2/feat/*`, `cz2/release/v0.7.0`
- Archive: `.czarina/phases/phase-2-v0.7.0/`

Phases are isolated - branches don't conflict.
