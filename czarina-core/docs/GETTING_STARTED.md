# Getting Started with Czarina

This document is the framework-internal getting started guide.
For end-user documentation, see the repository root:

- **[README.md](../../README.md)** — Overview and installation
- **[QUICK_START.md](../../QUICK_START.md)** — Step-by-step guide
- **[docs/HOPPER.md](../../docs/HOPPER.md)** — Hopper integration (required)
- **[docs/CONFIGURATION.md](../../docs/CONFIGURATION.md)** — config.json reference

---

## Framework Overview

The `czarina-core/` directory contains the orchestration engine:

```
czarina-core/
├── agent-launcher.sh        # Launches AI agents in tmux windows
│                            # - Creates WORKER_IDENTITY.md per worker
│                            # - Builds hopper-first launch prompt
│                            # - Marks worker tasks in_progress via hopper
│
├── hopper-integration.sh    # Hopper task management
│                            # - hopper_register_orchestration()
│                            # - hopper_create_worker_task() with --brief-file
│                            # - hopper_print_status(), hopper_closeout_orchestration()
│
├── launch-project-v2.sh     # Main project launch script
│                            # - Sources hopper-integration.sh
│                            # - Calls hopper_register_orchestration before workers
│                            # - Creates tmux session and worker windows
│
├── closeout-project.sh      # Phase closeout
│                            # - Stops sessions and daemon
│                            # - Calls hopper_closeout_orchestration
│                            # - Archives to .czarina/phases/
│
├── validate-config.sh       # Pre-launch validation
│                            # - Checks hopper is installed (required)
│                            # - Checks all worker agents are available
│                            # - Validates config.json structure
│
├── context-builder.sh       # Optional enhanced context
│                            # - Loads agent-knowledge rules by role
│                            # - Loads project memory
│                            # - Builds .czarina-context.md in worktrees
│
├── daemon/                  # Auto-approval daemon
├── templates/               # Worker brief and config templates
├── docs/                    # Framework documentation (this directory)
└── tests/                   # Integration tests
    └── test-hopper-instruction-store.sh
```

## Key Design Decisions

**Hopper is required, not optional.** All soft-fail `hopper_available ||` guards
were removed in v1.0.0. Every function in `hopper-integration.sh` calls
`hopper_require` which exits 1 if hopper is not installed.

**Worker briefs live in Hopper.** When `launch-project-v2.sh` runs, it calls
`hopper_register_orchestration` which reads each `.czarina/workers/<id>.md` file
and stores its full content as a Hopper task body via `hopper --local task add
--brief-file`. Workers retrieve their brief with `hopper --local task get`.

**WORKER_IDENTITY.md is an orientation card, not the brief.** It contains the
worker's Hopper task ID and the exact command to retrieve their brief. This
survives git worktree deletion and session loss because the source of truth is
in Hopper, not the filesystem.

**Registration happens before workers start.** In `launch-project-v2.sh`, hopper
registration runs immediately after config validation, before the first
`create_worker_window` call. This ensures task IDs are available when
`create_worker_identity` runs inside the launch script.

## Running Tests

```bash
# From the czarina repo root
bash czarina-core/tests/test-hopper-instruction-store.sh

# With verbose output
bash czarina-core/tests/test-hopper-instruction-store.sh --verbose
```

Expected: 52 tests pass, 0 fail.
