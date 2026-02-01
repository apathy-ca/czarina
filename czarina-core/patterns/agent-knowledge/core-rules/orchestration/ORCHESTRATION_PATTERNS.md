# Orchestration Patterns

**Source:** Agent Rules Extraction - Templates Worker (from Czarina)
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This document describes comprehensive orchestration patterns for coordinating multiple agents or workers in complex projects, extracted from the Czarina orchestration system.

## Core Orchestration Concepts

### What is Orchestration?

**Orchestration** is the automated coordination of multiple independent workers (agents, processes, or tasks) to accomplish a larger goal while managing:
- **Dependencies:** Which workers must complete before others can start
- **Resources:** Token budgets, time allocations, file ownership
- **State:** Tracking worker progress and status
- **Integration:** Combining outputs from multiple workers
- **Quality:** Ensuring deliverables meet standards

### When to Use Orchestration

Use orchestration when:
- Project requires **multiple independent workers** with different specializations
- Workers have **dependencies** on each other's outputs
- Need to **parallelize work** where possible
- Want to **track progress** and **manage resources** systematically
- Project is too large for single worker/agent

**Examples:**
- Large feature development across multiple modules
- Documentation extraction from multiple sources
- Multi-phase refactoring projects
- Complex testing and QA workflows

## Orchestration Patterns

### 1. Sequential Orchestration

**Pattern:** Workers execute one after another in strict order.

\`\`\`
Worker A → Worker B → Worker C → Worker D
\`\`\`

**When to use:**
- Each worker depends on previous worker's complete output
- Linear workflow with no parallelization opportunity
- Simple dependency chain

**Example:**
\`\`\`yaml
workers:
  - id: foundation
    dependencies: []

  - id: workflows
    dependencies: [foundation]

  - id: qa
    dependencies: [workflows]
\`\`\`

**Pros:**
- Simple to understand and manage
- Clear execution order
- Easy to debug

**Cons:**
- Slower total execution time
- No parallelization benefits
- Blocks on slow workers

### 2. Parallel Orchestration

**Pattern:** Multiple workers execute simultaneously.

\`\`\`
       ┌─ Worker A ─┐
Start ─┼─ Worker B ─┤─ End
       └─ Worker C ─┘
\`\`\`

**When to use:**
- Workers are completely independent
- No shared resources or conflicts
- Want to minimize total execution time

**Example:**
\`\`\`yaml
workers:
  - id: patterns
    dependencies: []

  - id: testing
    dependencies: []

  - id: security
    dependencies: []
\`\`\`

**Pros:**
- Fastest total execution time
- Maximum resource utilization
- Independent failure isolation

**Cons:**
- More complex coordination
- Potential resource contention
- Harder to debug concurrent issues

### 3. Dependency-Based Orchestration (DAG)

**Pattern:** Workers execute based on dependency graph (Directed Acyclic Graph).

\`\`\`
       ┌─ Worker B ─┐
Worker A ┤            ├─ Worker E
       └─ Worker C ──┤
          Worker D ──┘
\`\`\`

**When to use:**
- Complex dependencies between workers
- Want parallelization where possible
- Need to optimize execution time while respecting dependencies

**Example:**
\`\`\`yaml
workers:
  - id: foundation
    dependencies: []

  - id: workflows
    dependencies: [foundation]

  - id: patterns
    dependencies: [foundation]

  - id: testing
    dependencies: [foundation]

  - id: security
    dependencies: [foundation]

  - id: templates
    dependencies: [foundation, workflows, patterns, testing, security]

  - id: qa
    dependencies: [templates]
\`\`\`

**Execution Waves:**
- **Wave 1:** foundation (1 worker)
- **Wave 2:** workflows, patterns, testing, security (4 workers in parallel)
- **Wave 3:** templates (1 worker)
- **Wave 4:** qa (1 worker)

**Pros:**
- Optimal parallelization
- Respects all dependencies
- Flexible and scalable

**Cons:**
- More complex to set up
- Requires dependency resolution
- Can have complex failure scenarios

### 4. Hub-and-Spoke Orchestration

**Pattern:** Central coordinator manages all worker interactions.

\`\`\`
    Worker A
        ↓
    Coordinator ← Worker C
        ↑
    Worker B
\`\`\`

**When to use:**
- Need central control and monitoring
- Workers need to share state
- Want single point of coordination

**Example:**
Czarina Czar (orchestrator) manages all workers:
- Launches workers when dependencies met
- Monitors progress via logs
- Integrates outputs (QA worker)

**Pros:**
- Central visibility
- Easy state management
- Simple worker interfaces

**Cons:**
- Coordinator is single point of failure
- Can become bottleneck
- More complex coordinator logic

## Worker Lifecycle

### States

Workers progress through defined states:

\`\`\`
PENDING → READY → STARTING → ACTIVE → COMPLETE
                                   ↓
                               BLOCKED
                                   ↓
                               FAILED
\`\`\`

#### PENDING
- Worker defined but dependencies not met
- Waiting for upstream workers to complete

#### READY
- All dependencies satisfied
- Ready to launch when resources available

#### STARTING
- Worker being initialized
- Environment setup, worktree creation

#### ACTIVE
- Worker executing tasks
- Making progress on deliverables

#### BLOCKED
- Worker encountered blocker
- Waiting for external input or issue resolution

#### COMPLETE
- All deliverables finished
- Output available for downstream workers

#### FAILED
- Worker encountered unrecoverable error
- Requires manual intervention

### State Transitions

**PENDING → READY:**
- Triggered when all dependencies reach COMPLETE state
- Automatic transition

**READY → STARTING:**
- Triggered by orchestrator launch command
- May wait for resource availability

**STARTING → ACTIVE:**
- Worker initialization complete
- First task started

**ACTIVE → BLOCKED:**
- Worker reports blocker
- External dependency or issue

**BLOCKED → ACTIVE:**
- Blocker resolved
- Worker resumes

**ACTIVE → COMPLETE:**
- All tasks finished
- All deliverables produced
- All success criteria met

**ACTIVE → FAILED:**
- Unrecoverable error
- Success criteria cannot be met

## Dependency Management

### Dependency Types

#### 1. Output Dependencies
Worker B needs output files from Worker A.

\`\`\`yaml
workers:
  - id: worker-a
    deliverables:
      - output/data.json

  - id: worker-b
    dependencies: [worker-a]
    inputs:
      - ../worker-a/output/data.json
\`\`\`

#### 2. Knowledge Dependencies
Worker B needs to understand patterns from Worker A.

\`\`\`yaml
workers:
  - id: patterns
    deliverables:
      - agent-rules/patterns/

  - id: templates
    dependencies: [patterns]
    references:
      - ../patterns/agent-rules/patterns/
\`\`\`

#### 3. Sequential Dependencies
Worker B must start after Worker A completes (timing constraint).

\`\`\`yaml
workers:
  - id: implementation
    deliverables: [src/]

  - id: testing
    dependencies: [implementation]
    reason: "Tests require implemented code"
\`\`\`

### Dependency Resolution

**Algorithm:**
1. Build dependency graph from worker definitions
2. Detect cycles (error if found - DAG required)
3. Topologically sort workers
4. Calculate execution waves
5. Launch workers wave by wave

**Example:**
\`\`\`python
def calculate_execution_order(workers):
    """Calculate execution order respecting dependencies."""
    # Build graph
    graph = {w.id: w.dependencies for w in workers}

    # Topological sort (Kahn's algorithm)
    in_degree = {w.id: len(w.dependencies) for w in workers}
    queue = [w.id for w in workers if len(w.dependencies) == 0]
    order = []

    while queue:
        current = queue.pop(0)
        order.append(current)

        # Reduce in-degree for dependent workers
        for worker in workers:
            if current in worker.dependencies:
                in_degree[worker.id] -= 1
                if in_degree[worker.id] == 0:
                    queue.append(worker.id)

    return order
\`\`\`

## Resource Management

### Token Budgets

**Pattern:** Allocate token budgets per worker to manage costs.

\`\`\`yaml
workers:
  - id: foundation
    budget:
      tokens: 150000
      duration: 2-3 days

  - id: templates
    budget:
      tokens: 700000  # Larger budget for synthesis
      duration: 3-4 days
\`\`\`

**Best Practices:**
- Use token budgets, not time estimates
- Apply reality multiplier (1.5x-2x) for estimates
- Track actual vs budgeted tokens
- Alert when approaching budget limits

### File Ownership

**Pattern:** Define which files each worker owns to prevent conflicts.

\`\`\`yaml
workers:
  - id: foundation
    owns:
      - agent-rules/python/**
      - agent-rules/agents/**

  - id: templates
    owns:
      - agent-rules/templates/**
      - agent-rules/documentation/**

  references:
      - agent-rules/python/**  # Read-only
      - agent-rules/agents/**  # Read-only
\`\`\`

**Conflict Resolution:**
- Workers should not modify files they don't own
- Shared files require coordination (rare)
- QA worker integrates all outputs

## Progress Monitoring

### Event-Driven Monitoring

**Pattern:** Workers emit events to central event stream.

**Event Types:**
\`\`\`yaml
events:
  - worker.started
  - worker.task_started
  - worker.checkpoint
  - worker.task_completed
  - worker.blocked
  - worker.complete
  - worker.failed
\`\`\`

**Event Format:**
\`\`\`json
{
  "timestamp": "2025-01-15T10:30:00Z",
  "worker_id": "foundation",
  "event_type": "worker.checkpoint",
  "data": {
    "checkpoint": "phase1_complete",
    "tasks_completed": 15,
    "tasks_remaining": 10
  }
}
\`\`\`

### Logging Pattern

**Structured Logging:**
\`\`\`bash
# Worker logs to structured file
czarina_log_task_start "Task 1.1: Extract Python standards"
czarina_log_checkpoint "python_standards_extracted"
czarina_log_task_complete "Task 1.1: Extract Python standards"
\`\`\`

**Log Locations:**
\`\`\`
.czarina/logs/
├── foundation.log
├── workflows.log
├── templates.log
└── events.log  # Aggregated events
\`\`\`

## Integration Patterns

### 1. Git Worktree Integration

**Pattern:** Each worker gets isolated git worktree on separate branch.

\`\`\`bash
# Create worktrees
git worktree add .czarina/worktrees/foundation feat/agent-rules-foundation
git worktree add .czarina/worktrees/workflows feat/agent-rules-workflows
git worktree add .czarina/worktrees/templates feat/agent-rules-templates
\`\`\`

**Benefits:**
- Complete isolation between workers
- No merge conflicts during work
- Clean branch history
- Easy to review individual worker output

### 2. QA Integration Pattern

**Pattern:** Dedicated QA worker merges and validates all outputs.

\`\`\`
Worker A ──┐
Worker B ──┤
Worker C ──┼──→ QA Worker ──→ main branch
Worker D ──┤
Worker E ──┘
\`\`\`

**QA Worker Responsibilities:**
- Merge all worker branches
- Resolve any conflicts
- Validate integration
- Ensure consistency
- Create final deliverable
- Generate closeout report

### 3. Handoff Pattern

**Pattern:** Workers provide handoff artifacts for downstream workers.

**Handoff Checklist:**
\`\`\`markdown
## Handoff to Downstream Workers

- [ ] All deliverables in branch
- [ ] README.md complete
- [ ] Known issues documented
- [ ] Integration notes provided
- [ ] Examples validated
- [ ] Dependencies listed
\`\`\`

## Automation Patterns

### Daemon Mode

**Pattern:** Orchestrator runs as daemon, automatically launching workers when ready.

\`\`\`bash
# Start daemon
czarina daemon start

# Workers launch automatically when dependencies met
# No manual intervention required
\`\`\`

**Features:**
- Auto-launch workers when dependencies satisfied
- Monitor progress continuously
- Alert on failures or blocks
- Generate status reports

### Approval Mode

**Pattern:** Orchestrator requires approval before launching workers.

\`\`\`bash
# Start in approval mode
czarina daemon start --approve

# For each ready worker:
# > Worker 'templates' is READY. Launch? [y/N]
\`\`\`

**When to use:**
- Development/testing
- High-value/high-risk workers
- Resource-constrained environments

## Best Practices

### ✅ Do

- **Define clear dependencies** - Explicit is better than implicit
- **Use token budgets** - Not time estimates
- **Monitor continuously** - Event-driven status tracking
- **Isolate workers** - Separate branches, clear file ownership
- **Document handoffs** - Clear integration notes
- **Track metrics** - Tokens used, tasks completed, efficiency

### ❌ Don't

- **Create circular dependencies** - Ensure DAG structure
- **Share mutable state** - Use file-based handoffs
- **Ignore failures** - Alert and handle proactively
- **Skip integration testing** - QA worker is critical
- **Estimate with time** - Use token budgets instead
- **Launch all workers simultaneously** - Respect dependencies

## Examples

### Example 1: Agent Rules Extraction

**Structure:**
\`\`\`yaml
foundation:
  dependencies: []
  outputs: [python/, agents/]

workflows:
  dependencies: [foundation]
  outputs: [workflows/]

patterns:
  dependencies: [foundation]
  outputs: [patterns/]

testing:
  dependencies: [foundation]
  outputs: [testing/]

security:
  dependencies: [foundation]
  outputs: [security/]

templates:
  dependencies: [foundation, workflows, patterns, testing, security]
  outputs: [templates/, documentation/, orchestration/, .hopper/]

qa:
  dependencies: [templates]
  outputs: [integrated agent-rules/]
\`\`\`

**Execution:**
- Wave 1: foundation
- Wave 2: workflows, patterns, testing, security (parallel)
- Wave 3: templates (synthesis)
- Wave 4: qa (integration)

### Example 2: Microservice Development

**Structure:**
\`\`\`yaml
api-design:
  dependencies: []
  outputs: [specs/api.yaml]

auth-service:
  dependencies: [api-design]
  outputs: [services/auth/]

user-service:
  dependencies: [api-design, auth-service]
  outputs: [services/user/]

integration-tests:
  dependencies: [auth-service, user-service]
  outputs: [tests/integration/]
\`\`\`

## Related Documents

- [Worker Coordination](#worker-coordination)
- [Daemon Automation](#daemon-patterns)
- [Status Monitoring](#status-monitoring)
- [Worker Templates](../../templates/worker-definition-template.md)

## References

This document extracts patterns from:
- Czarina orchestration system
- Foundation worker: Agent templates, orchestration patterns
- All workers: Coordination and integration practices
