# Czarina Configuration Reference

This document describes the configuration options available in `.czarina/config.json`.

For migration from v0.6.2 to v0.7.0, see [MIGRATION_v0.7.0.md](MIGRATION_v0.7.0.md).

## Configuration Schema

Full JSON Schema definition: `schema/config-schema.json`

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

### Agent Rules Section (v0.7.0+)

Global configuration for agent rules system. **Optional** - if not specified, rules are disabled.

```json
{
  "agent_rules": {
    "library_path": ".czarina/agent-rules",
    "mode": "auto",
    "condensed": true
  }
}
```

**Agent Rules Properties:**
- `library_path` (optional, default: ".czarina/agent-rules"): Path to agent rules library
- `mode` (optional, default: "auto"): Rule loading mode
  - `"auto"`: Automatically load rules based on worker role and context
  - `"manual"`: Only load explicitly specified rules
  - `"disabled"`: Disable rule loading
- `condensed` (optional, default: true): Use condensed rule format for efficiency

### Memory Section (v0.7.0+)

Global configuration for memory system. **Optional** - if not specified, memory is disabled.

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

**Memory Properties:**
- `enabled` (optional, default: true): Enable memory system
- `embedding_provider` (optional, default: "openai"): Embedding provider
  - `"openai"`: OpenAI embeddings
  - `"anthropic"`: Anthropic embeddings (future)
  - `"local"`: Local embedding model
- `embedding_model` (optional, default: "text-embedding-3-small"): Model name
- `similarity_threshold` (optional, default: 0.7): Minimum similarity score (0-1)
- `max_results` (optional, default: 5): Maximum number of results to return

### Workers Section

Each worker defines a parallel work stream with its own branch and agent.

```json
{
  "workers": [
    {
      "id": "worker-id",
      "agent": "aider",
      "role": "code",
      "branch": "feat/feature-name",
      "description": "Worker description",
      "versions": ["v1.0.0-worker"],
      "token_budget": 2000000,
      "dependencies": ["other-worker-id"],
      "rules": {
        "enabled": true,
        "auto_load": true,
        "domains": ["python", "testing"]
      },
      "memory": {
        "enabled": true,
        "use_core": true,
        "search_on_start": true
      }
    }
  ]
}
```

**Worker Properties:**
- `id` (required): Unique identifier for the worker
- `agent` (required): Agent type (aider, cursor, claude-code, etc.)
- `branch` (required): Git branch for this worker's changes
- `description` (required): Human-readable description of worker's task
- `role` (optional, v0.7.0+): Worker role for rule loading
  - `"code"`: Code implementation
  - `"plan"`: Architecture and planning
  - `"review"`: Code review and quality
  - `"test"`: Testing and QA
  - `"integration"`: Integration and merging
  - `"research"`: Research and exploration
- `versions` (optional): Version tags for this worker's output
- `token_budget` (optional): Maximum tokens for this worker
- `dependencies` (optional): Array of worker IDs that must complete before this worker starts
- `merges` (optional): Array of worker branches to merge (for integration workers)
- `rules` (optional, v0.7.0+): Worker-level rules configuration
  - `enabled` (optional, default: true): Enable rules for this worker
  - `auto_load` (optional, default: true): Auto-load rules based on role
  - `domains` (optional): Specific rule domains to load
    - Available: `"python"`, `"javascript"`, `"typescript"`, `"testing"`, `"security"`, `"documentation"`, `"performance"`, `"git"`
- `memory` (optional, v0.7.0+): Worker-level memory configuration
  - `enabled` (optional, default: true): Enable memory for this worker
  - `use_core` (optional, default: true): Use core memory system
  - `search_on_start` (optional, default: true): Search memory when worker starts

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

## Example Configurations

### Basic Configuration (v0.6.2 compatible)

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
  "workers": [
    {
      "id": "backend",
      "agent": "claude",
      "branch": "feat/backend",
      "description": "Backend implementation",
      "token_budget": 2000000
    },
    {
      "id": "frontend",
      "agent": "cursor",
      "branch": "feat/frontend",
      "description": "Frontend implementation",
      "token_budget": 1500000
    }
  ],
  "orchestration": {
    "mode": "local"
  },
  "daemon": {
    "enabled": true,
    "auto_approve": ["read", "write", "commit"]
  }
}
```

### Configuration with Agent Rules (v0.7.0+)

```json
{
  "project": {
    "name": "my-project",
    "repository": "/home/user/projects/my-project",
    "version": "1.0.0"
  },
  "agent_rules": {
    "library_path": ".czarina/agent-rules",
    "mode": "auto",
    "condensed": true
  },
  "workers": [
    {
      "id": "backend",
      "agent": "claude",
      "role": "code",
      "branch": "feat/backend",
      "description": "Backend API implementation",
      "token_budget": 2000000,
      "rules": {
        "enabled": true,
        "auto_load": true,
        "domains": ["python", "testing", "security"]
      }
    },
    {
      "id": "qa",
      "agent": "aider",
      "role": "test",
      "branch": "feat/testing",
      "description": "QA and testing",
      "token_budget": 1000000,
      "dependencies": ["backend"],
      "rules": {
        "enabled": true,
        "domains": ["testing", "security"]
      }
    }
  ],
  "orchestration": {
    "mode": "sequential_dependencies"
  }
}
```

### Full-Featured Configuration (v0.7.0+)

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
  "agent_rules": {
    "library_path": ".czarina/agent-rules",
    "mode": "auto",
    "condensed": true
  },
  "memory": {
    "enabled": true,
    "embedding_provider": "openai",
    "embedding_model": "text-embedding-3-small",
    "similarity_threshold": 0.7,
    "max_results": 5
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
      "role": "code",
      "branch": "feat/core-infrastructure",
      "description": "Core infrastructure and utilities",
      "token_budget": 2000000,
      "dependencies": [],
      "rules": {
        "enabled": true,
        "auto_load": true,
        "domains": ["python", "testing"]
      },
      "memory": {
        "enabled": true,
        "use_core": true,
        "search_on_start": true
      }
    },
    {
      "id": "api",
      "agent": "cursor",
      "role": "code",
      "branch": "feat/api-endpoints",
      "description": "REST API implementation",
      "token_budget": 1500000,
      "dependencies": ["foundation"],
      "rules": {
        "enabled": true,
        "domains": ["python", "security", "performance"]
      },
      "memory": {
        "enabled": true,
        "search_on_start": true
      }
    },
    {
      "id": "ui",
      "agent": "cursor",
      "role": "code",
      "branch": "feat/user-interface",
      "description": "User interface components",
      "token_budget": 1500000,
      "dependencies": ["foundation"],
      "rules": {
        "enabled": true,
        "domains": ["javascript", "typescript", "performance"]
      },
      "memory": {
        "enabled": true,
        "search_on_start": true
      }
    },
    {
      "id": "integration",
      "agent": "aider",
      "role": "test",
      "branch": "feat/integration-tests",
      "description": "End-to-end integration testing",
      "token_budget": 1000000,
      "dependencies": ["api", "ui"],
      "rules": {
        "enabled": true,
        "domains": ["testing", "security"]
      },
      "memory": {
        "enabled": true,
        "search_on_start": true
      }
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
- All workers have agent rules enabled with role-specific domains
- Memory system is enabled globally and for all workers

## Validation

### Validate Your Configuration

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

## See Also

- [Migration Guide](MIGRATION_v0.7.0.md) - Migrating from v0.6.2 to v0.7.0
- [JSON Schema](../schema/config-schema.json) - Full schema definition
- [Example Configs](../examples/) - Additional example configurations
