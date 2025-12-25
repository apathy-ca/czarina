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
    "description": "Project description"
  }
}
```

### Workers Section

Each worker defines a parallel work stream with its own branch and agent.

```json
{
  "workers": [
    {
      "id": "worker-id",
      "agent": "aider",
      "branch": "feat/feature-name",
      "description": "Worker description",
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
- `branch` (required): Git branch for this worker's changes
- `description` (required): Human-readable description of worker's task
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

## Example Configuration

```json
{
  "project": {
    "name": "my-project",
    "slug": "my-project",
    "repository": "/home/user/projects/my-project",
    "orchestration_dir": ".czarina",
    "version": "1.0.0",
    "description": "My project description"
  },
  "orchestration": {
    "mode": "sequential_dependencies",
    "allow_parallel_when_possible": true,
    "timeout_hours": 48
  },
  "workers": [
    {
      "id": "foundation",
      "agent": "aider",
      "branch": "feat/core-infrastructure",
      "description": "Core infrastructure and utilities",
      "token_budget": 2000000,
      "dependencies": []
    },
    {
      "id": "api",
      "agent": "cursor",
      "branch": "feat/api-endpoints",
      "description": "REST API implementation",
      "token_budget": 1500000,
      "dependencies": ["foundation"]
    },
    {
      "id": "ui",
      "agent": "cursor",
      "branch": "feat/user-interface",
      "description": "User interface components",
      "token_budget": 1500000,
      "dependencies": ["foundation"]
    },
    {
      "id": "integration",
      "agent": "aider",
      "branch": "feat/integration-tests",
      "description": "End-to-end integration testing",
      "token_budget": 1000000,
      "dependencies": ["api", "ui"]
    }
  ],
  "daemon": {
    "enabled": true,
    "auto_approve": ["read", "write", "commit"]
  }
}
```

In this example:
- `foundation` has no dependencies and starts immediately
- `api` and `ui` both depend on `foundation` and will wait for it
- `integration` depends on both `api` and `ui` and waits for both
- With `sequential_dependencies` mode, this ensures correct execution order
