# Czarina Configuration Reference

This document describes the configuration options available in `.czarina/config.json`.

## Configuration Schema

### Project Section

```json
{
  "project": {
    "name": "project-name",
    "slug": "project-slug",
    "repository": "/path/to/repository",
    "orchestration_dir": ".czarina",
    "version": "1.0.0",
    "phase": 1,
    "omnibus_branch": "cz1/release/v1.0.0",
    "description": "Project description"
  }
}
```

**Project Properties:**
- `name` (required): Project name
- `slug` (required): URL-safe project identifier (no dots - use underscores instead)
- `repository` (required): Absolute path to git repository
- `orchestration_dir` (optional, default: ".czarina"): Directory for orchestration files
- `version` (required): Project version
- `phase` (optional, default: 1): Current development phase number
- `omnibus_branch` (optional): Integration/release branch for current phase (e.g., "cz1/release/v1.0.0")
- `description` (optional): Project description

### Workers Section

Each worker defines a parallel work stream with its own branch and agent.

```json
{
  "workers": [
    {
      "id": "worker-id",
      "agent": "aider",
      "branch": "cz1/feat/feature-name",
      "description": "Worker description",
      "phase": 1,
      "role": "feature",
      "versions": ["v1.0.0-worker"],
      "token_budget": 2000000,
      "dependencies": ["other-worker-id"]
    }
  ]
}
```

**Worker Properties:**
- `id` (required): Unique identifier for the worker
- `agent` (required): Agent type (aider, cursor, claude-code, etc.)
- `branch` (required): Git branch for this worker's changes (should follow naming convention: `cz<phase>/feat/<worker-id>`)
- `description` (required): Human-readable description of worker's task
- `phase` (optional, default: 1): Phase number this worker belongs to
- `role` (optional, default: "feature"): Worker role ("feature" or "integration")
- `versions` (optional): Version tags for this worker's output
- `token_budget` (optional): Maximum tokens for this worker
- `dependencies` (optional): Array of worker IDs that must complete before this worker starts

### Orchestration Section

Controls how workers are launched and coordinated.

```json
{
  "orchestration": {
    "mode": "parallel_spike",
    "allow_parallel_when_possible": true,
    "timeout_hours": 24
  }
}
```

**Orchestration Modes:**

- **`parallel_spike`** (default): All workers start immediately, regardless of dependencies
  - Fast execution
  - Workers proceed independently
  - Best for exploratory work or when dependencies are soft constraints
  - Current behavior if no mode is specified

- **`sequential_dependencies`**: Workers wait for their dependencies to complete before starting
  - Respects dependency chains from worker configuration
  - Workers block until all dependencies have finished
  - Guarantees work happens in correct order
  - Best for production releases or when dependency order is critical

- **`hybrid`**: Parallel execution where possible, sequential for dependencies
  - Workers with no dependencies start immediately
  - Workers with dependencies wait for them
  - Optimal balance of speed and correctness
  - Best for most production workflows

**Orchestration Properties:**
- `mode` (optional, default: "parallel_spike"): Orchestration mode
- `allow_parallel_when_possible` (optional, default: true): In sequential mode, allow independent workers to run in parallel
- `timeout_hours` (optional, default: 24): Maximum hours to wait for dependencies

### Daemon Section

Controls the background monitoring daemon.

```json
{
  "daemon": {
    "enabled": true,
    "auto_approve": ["read", "write", "commit"]
  }
}
```

**Daemon Properties:**
- `enabled` (optional, default: true): Enable background daemon monitoring
- `auto_approve` (optional): Array of operations to auto-approve

### Phase Completion Section (v0.7.2+)

Controls automatic phase completion detection and transitions.

```json
{
  "phase_completion_mode": "any"
}
```

**Phase Completion Modes:**

- **`any`** (default): Any completion signal indicates worker is complete
  - Use for: Flexible development, rapid iteration
  - Signals: Worker log marker OR branch merged OR status file

- **`all`**: All completion signals must be present
  - Use for: High confidence, multiple verification
  - Requires: Worker log marker AND branch merged AND status file

- **`strict`**: Log marker AND at least one other signal
  - Use for: Production releases, critical systems
  - Requires: Worker log marker AND (branch merged OR status file)

**Completion Signals:**

1. **Worker Log Marker**: Worker calls `czarina_log_worker_complete`
2. **Branch Merged**: Worker branch merged to omnibus branch
3. **Status File**: `status/worker-status.json` shows "complete"

**Phase Completion Properties:**
- `phase_completion_mode` (optional, default: "any"): How to detect worker completion

### Hopper Section

Controls the two-level hopper system for enhancement requests.

```json
{
  "hopper": {
    "enabled": true,
    "project_hopper": ".czarina/hopper",
    "phase_hopper": ".czarina-v1.0.0/phase-hopper",
    "czar_monitoring": {
      "enabled": false,
      "check_interval": 900
    }
  }
}
```

**Hopper Properties:**
- `enabled` (optional, default: false): Enable hopper system
- `project_hopper` (optional): Path to project-level hopper
- `phase_hopper` (optional): Path to phase-level hopper
- `czar_monitoring.enabled` (optional, default: false): Enable Czar monitoring of hopper
- `czar_monitoring.check_interval` (optional, default: 900): Check interval in seconds

### Wiggum Section (v0.9.0+)

Controls Wiggum Mode: iterative, fault-tolerant AI coding with disposable workers ("Ralphs").

```json
{
  "wiggum": {
    "agent_command": "claude -p .czarina/mission_brief.md",
    "sandbox_prefix": ".wiggum_sandboxes/",
    "default_retries": 5,
    "timeout_seconds": 300,
    "protected_files": ["czarina.toml", "go.mod", ".env"],
    "verify_command": "npm test",
    "merge_strategy": "squash"
  }
}
```

**Wiggum Properties:**
- `agent_command` (optional, default: `"claude -p .czarina/mission_brief.md"`): Command to invoke the AI agent inside the worktree
- `sandbox_prefix` (optional, default: `".wiggum_sandboxes/"`): Directory prefix for temporary worktrees
- `default_retries` (optional, default: 5): Maximum number of retry attempts before aborting
- `timeout_seconds` (optional, default: 300): Per-attempt timeout in seconds; kills the worker if exceeded
- `protected_files` (optional): Files the Czar will automatically revert if the worker modifies them
- `verify_command` (optional): Command to run for the verification gate (e.g., `npm test`, `go test ./...`)
- `merge_strategy` (optional, default: `"squash"`): How to merge successful changes back (`merge`, `squash`, or `rebase`)

**Wiggum Lifecycle:**
1. **Spawn** - Create isolated git worktree (`wiggum/attempt-{n}`)
2. **Brief** - Generate mission brief with task directives and accumulated wisdom from past failures
3. **Execute** - Run agent in detached tmux session with timeout watchdog
4. **Verify** - Cycle detection (diff hashing) + test suite execution
5. **Resolve** - Merge on success, destroy worktree + append wisdom on failure, retry

**Usage:**
```bash
czarina wiggum 'Fix the auth bug' --verify-command 'npm test'
czarina wiggum 'Add caching' --retries 3 --timeout 600
```

CLI flags override config values. See `examples/config-with-wiggum.json` for a complete example.

## Example Configurations

### Basic Single-Phase Configuration

```json
{
  "project": {
    "name": "my-project",
    "slug": "my-project-v1_0_0",
    "repository": "/home/user/projects/my-project",
    "orchestration_dir": ".czarina",
    "version": "1.0.0",
    "phase": 1,
    "omnibus_branch": "cz1/release/v1.0.0",
    "description": "My project description"
  },
  "phase_completion_mode": "any",
  "orchestration": {
    "mode": "sequential_dependencies",
    "allow_parallel_when_possible": true,
    "timeout_hours": 48
  },
  "workers": [
    {
      "id": "foundation",
      "agent": "aider",
      "branch": "cz1/feat/foundation",
      "description": "Core infrastructure and utilities",
      "phase": 1,
      "token_budget": 2000000,
      "dependencies": []
    },
    {
      "id": "api",
      "agent": "cursor",
      "branch": "cz1/feat/api",
      "description": "REST API implementation",
      "phase": 1,
      "token_budget": 1500000,
      "dependencies": ["foundation"]
    },
    {
      "id": "ui",
      "agent": "cursor",
      "branch": "cz1/feat/ui",
      "description": "User interface components",
      "phase": 1,
      "token_budget": 1500000,
      "dependencies": ["foundation"]
    },
    {
      "id": "integration",
      "agent": "aider",
      "branch": "cz1/release/v1.0.0",
      "description": "End-to-end integration testing",
      "phase": 1,
      "role": "integration",
      "token_budget": 1000000,
      "dependencies": ["api", "ui"]
    }
  ],
  "daemon": {
    "enabled": true,
    "auto_approve": ["read", "write", "commit"]
  },
  "hopper": {
    "enabled": true,
    "project_hopper": ".czarina/hopper",
    "phase_hopper": ".czarina-v1.0.0/phase-hopper"
  }
}
```

In this example:
- Phase 1 orchestration with branch naming convention `cz1/feat/*`
- `foundation` has no dependencies and starts immediately
- `api` and `ui` both depend on `foundation` and will wait for it
- `integration` depends on both `api` and `ui` and waits for both
- With `sequential_dependencies` mode, this ensures correct execution order
- Phase completion mode `any` allows flexible completion detection
- Integration worker uses omnibus branch `cz1/release/v1.0.0`

### Multi-Phase Configuration (v0.7.2+)

```json
{
  "project": {
    "name": "my-project",
    "slug": "my-project-v2_0_0",
    "repository": "/home/user/projects/my-project",
    "version": "2.0.0",
    "phase": 2,
    "omnibus_branch": "cz2/release/v2.0.0"
  },
  "phase_completion_mode": "strict",
  "workers": [
    {
      "id": "security",
      "agent": "claude",
      "branch": "cz2/feat/security",
      "description": "Security hardening features",
      "phase": 2,
      "dependencies": []
    },
    {
      "id": "performance",
      "agent": "claude",
      "branch": "cz2/feat/performance",
      "description": "Performance optimization",
      "phase": 2,
      "dependencies": []
    },
    {
      "id": "integration",
      "agent": "claude",
      "branch": "cz2/release/v2.0.0",
      "description": "Phase 2 integration and testing",
      "phase": 2,
      "role": "integration",
      "dependencies": ["security", "performance"]
    }
  ],
  "daemon": {
    "enabled": true
  }
}
```

In this multi-phase example:
- Phase 2 configuration (following Phase 1 completion)
- Branch naming uses `cz2/` prefix for phase isolation
- Strict completion mode for production release
- Security and performance workers run in parallel
- Integration worker merges to omnibus branch `cz2/release/v2.0.0`
- Automatic phase completion detection triggers when all workers done
