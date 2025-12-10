# Phase Management

**Feature:** `czarina phase close`
**Version:** v0.4.0+
**Use Case:** Running multiple phases of work on the same codebase

---

## Problem

You want to run multiple groups of workers on the same codebase sequentially:
- Phase 1: v1.2.0 implementation (5 workers)
- Phase 2: v1.3.0 features (different workers)
- Phase 3: Bug fixes and polish (more workers)

But `czarina closeout` completely removes the project structure, requiring full re-initialization.

---

## Solution: Phase Close

`czarina phase close` closes the current phase but **preserves the project structure** for the next phase.

### What it Does

1. ✅ Stops all tmux sessions
2. ✅ Stops daemon
3. ✅ Archives phase state to `.czarina/phases/phase-TIMESTAMP/`
4. ✅ Cleans up worktrees
5. ✅ Clears worker status
6. ✅ **KEEPS** `.czarina/config.json` and worker prompts

### What it Preserves

- ✅ `.czarina/` directory structure
- ✅ `config.json` (you can edit for next phase)
- ✅ `workers/*.md` (you can edit or regenerate)
- ✅ Phase history in `phases/` directory

---

## Usage

### Basic Workflow

```bash
# Phase 1: v1.2.0 Gateway Implementation
czarina analyze docs/v1.2.0/plan.md --interactive --init
czarina launch
# ... workers do their work ...
czarina phase close

# Phase 2: v1.3.0 Security Features
czarina analyze docs/v1.3.0/plan.md --interactive --init
czarina launch
# ... new workers do their work ...
czarina phase close

# Phase 3: v1.4.0 Performance
czarina analyze docs/v1.4.0/plan.md --interactive --init
czarina launch
```

### From Project Directory

```bash
# Close current phase
czarina phase close

# Or specify project
czarina phase close sark
```

---

## What Gets Archived

Each phase is archived with timestamp:

```
.czarina/phases/
├── phase-2025-12-09_14-30-00/
│   ├── PHASE_SUMMARY.md         # Summary of this phase
│   ├── config.json              # Config snapshot
│   ├── workers/                 # Worker prompts snapshot
│   │   ├── gateway-http-sse.md
│   │   ├── gateway-stdio.md
│   │   ├── integration.md
│   │   ├── policy.md
│   │   └── qa.md
│   └── status/                  # Worker status (if any)
│       └── ...
└── phase-2025-12-10_09-15-00/
    └── ...
```

---

## Comparison: Phase Close vs Closeout

| Action | `phase close` | `closeout` |
|--------|---------------|------------|
| Stop tmux sessions | ✅ Yes | ✅ Yes |
| Stop daemon | ✅ Yes | ✅ Yes |
| Archive phase state | ✅ Yes | ✅ Yes |
| Remove worktrees | ✅ Yes | ✅ Yes |
| Keep .czarina/ | ✅ **YES** | ❌ **NO** |
| Keep config.json | ✅ **YES** | ❌ **NO** |
| Keep worker prompts | ✅ **YES** | ❌ **NO** |
| Next phase | ✅ Easy | ❌ Full re-init |

---

## Example: SARK Multi-Phase Development

### Phase 1: v1.2.0 - Gateway + Policy + Tests

```bash
cd ~/Source/sark
czarina analyze docs/v1.2.0/IMPLEMENTATION_PLAN.md --interactive --init
czarina launch

# Workers: gateway-http-sse, gateway-stdio, integration, policy, qa
# ... work happens for several days/weeks ...

# Phase complete
czarina phase close
```

**Result:**
- All workers stopped
- Worktrees cleaned up
- Phase archived to `.czarina/phases/phase-2025-12-09_14-30-00/`
- `.czarina/` structure intact

### Phase 2: v1.3.0 - Advanced Security

```bash
# Analyze new plan
czarina analyze docs/v1.3.0/IMPLEMENTATION_PLAN.md --interactive --init

# New workers: prompt-injection-detector, anomaly-detection, secret-scanner
czarina launch

# ... work happens ...

czarina phase close
```

**Result:**
- New phase archived to `.czarina/phases/phase-2025-12-20_10-00-00/`
- Ready for next phase

### Phase 3: v1.4.0 - Performance

```bash
czarina analyze docs/v1.4.0/IMPLEMENTATION_PLAN.md --interactive --init
czarina launch
# ... and so on
```

---

## Manual Phase Transition

If you don't want to re-analyze, you can manually edit config:

```bash
# Close current phase
czarina phase close

# Edit config for next phase
nano .czarina/config.json
# Update workers array with new workers

# Edit or create new worker prompts
nano .czarina/workers/new-worker.md

# Launch next phase
czarina launch
```

---

## Phase History

View previous phases:

```bash
ls -la .czarina/phases/
```

Each directory contains:
- `PHASE_SUMMARY.md` - What was in that phase
- `config.json` - Worker configuration snapshot
- `workers/*.md` - Worker prompt snapshots
- `status/` - Worker status at close time

---

## Best Practices

1. **Always close phases cleanly**
   - Run `czarina phase close` when phase is complete
   - Don't leave workers running between phases

2. **Archive meaningful names**
   - Phase directories are timestamped automatically
   - PHASE_SUMMARY.md describes the phase

3. **Review before next phase**
   - Check what worked well in archived phases
   - Reuse successful worker patterns

4. **Clean up old phases**
   - Periodically remove old phase archives
   - Keep relevant ones for reference

---

## Troubleshooting

### "No active sessions found"

Normal - phase was already closed or workers weren't launched.

### "Worktrees not removed"

Check manually:
```bash
git worktree list
git worktree prune
```

### Want to completely start over?

Use `closeout` instead:
```bash
czarina closeout
rm -rf .czarina/
czarina analyze new-plan.md --interactive --init
```

---

**Version:** v0.4.0
**Status:** ✅ Production Ready
