# Phase Hopper Template

This document describes the phase hopper structure that gets created for each phase.

## Directory Structure

When a phase is started, the following structure is created:

```
.czarina/phases/phase-N-vX.Y.Z/
├── hopper/
│   ├── todo/          # Enhancement files ready to be assigned
│   ├── in-progress/   # Enhancement files currently being worked on
│   └── done/          # Completed enhancement files
└── planned/           # Original phase plan worker files
```

## Subdirectories

### `todo/`
- Contains enhancement files pulled from the project hopper
- Items here are ready to be assigned to idle workers
- Czar monitors this directory and suggests assignments

### `in-progress/`
- Contains enhancement files assigned to workers
- Files may include a comment indicating which worker is assigned
- Workers should move files here when they start working on them

### `done/`
- Contains completed enhancement files
- Archived at phase closeout
- Used for phase completion reports

## Workflow

1. **Phase Start**: Czar prompts to pull items from project hopper to phase todo/
2. **During Phase**: Czar monitors and assigns items from todo/ to workers
3. **Worker Completion**: Workers move files from in-progress/ to done/
4. **Phase Close**:
   - Completed items (done/) archived
   - Unfinished items (todo/, in-progress/) moved back to project hopper

## File Naming

Enhancement files in the phase hopper maintain their original names from the project hopper, for example:
- `enhancement-14.md`
- `bug-fix-dashboard.md`
- `feature-dark-mode.md`

## Integration with Planned Work

The phase hopper (`hopper/`) is separate from the planned work (`planned/`):
- `planned/` contains the original worker task files from phase planning
- `hopper/` contains additional work pulled from the project hopper
- This separation helps track planned vs emergent work
