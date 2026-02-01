# Orchestration Rules

**Source:** Agent Rules Extraction - Templates Worker (from Czarina)
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This directory contains orchestration patterns and rules extracted from the Czarina orchestration system for coordinating multiple agents or workers in complex projects.

## What is Orchestration?

**Orchestration** is the automated coordination of multiple independent workers (agents, processes, or tasks) to accomplish a larger goal. It manages:

- **Dependencies:** Worker execution order and prerequisites
- **Resources:** Token budgets, time allocations, file ownership
- **State:** Worker progress tracking and monitoring
- **Integration:** Combining outputs from multiple workers
- **Quality:** Ensuring deliverables meet standards

## Documents in This Directory

### [Orchestration Patterns](./ORCHESTRATION_PATTERNS.md)
**Purpose:** Comprehensive orchestration patterns

**Covers:**
- Sequential, Parallel, and DAG orchestration
- Worker lifecycle and state management
- Dependency resolution
- Resource management
- Progress monitoring
- Integration patterns

**Use when:** Designing multi-worker orchestration, understanding Czarina patterns

## Core Concepts

### Workers

Independent units of work with:
- **ID:** Unique identifier
- **Role:** Specific responsibility
- **Dependencies:** Other workers that must complete first
- **Deliverables:** Concrete outputs
- **Budget:** Token and time allocations

### Dependencies

Relationships between workers:
- **Output Dependencies:** Worker B needs files from Worker A
- **Knowledge Dependencies:** Worker B needs to understand Worker A's patterns
- **Sequential Dependencies:** Worker B must start after Worker A

### Execution Waves

Groups of workers that can execute in parallel:
\`\`\`
Wave 1: foundation
Wave 2: workflows, patterns, testing, security (parallel)
Wave 3: templates
Wave 4: qa
\`\`\`

### State Management

Workers progress through states:
\`\`\`
PENDING → READY → STARTING → ACTIVE → COMPLETE
                                   ↓
                               BLOCKED
                                   ↓
                               FAILED
\`\`\`

## Quick Start: Czarina Orchestration

### 1. Define Workers

Create worker definitions for each unit of work:

\`\`\`yaml
# .czarina/workers/foundation.md
worker:
  id: foundation
  role: Extract Python and agent standards
  dependencies: []
  budget:
    tokens: 150000
  deliverables:
    - agent-rules/python/
    - agent-rules/agents/
\`\`\`

### 2. Create Worktrees

Set up isolated git worktrees:

\`\`\`bash
git worktree add .czarina/worktrees/foundation feat/agent-rules-foundation
git worktree add .czarina/worktrees/workflows feat/agent-rules-workflows
\`\`\`

### 3. Launch Workers

Start orchestration:

\`\`\`bash
# Daemon mode (automatic)
czarina daemon start

# Approval mode (manual control)
czarina daemon start --approve
\`\`\`

### 4. Monitor Progress

Track worker progress:

\`\`\`bash
# Check status
czarina status

# View logs
tail -f .czarina/logs/events.log
\`\`\`

### 5. Integration

QA worker integrates all outputs:

\`\`\`bash
# QA worker merges all branches
# Validates integration
# Creates final deliverable
\`\`\`

## Orchestration Patterns

### Sequential

Workers execute one after another:
\`\`\`
A → B → C → D
\`\`\`

**Use when:** Linear dependencies, no parallelization opportunity

### Parallel

Workers execute simultaneously:
\`\`\`
   ┌─ A ─┐
Start ┼─ B ─┤ End
   └─ C ─┘
\`\`\`

**Use when:** Independent workers, maximize speed

### DAG (Dependency Graph)

Workers execute based on dependency graph:
\`\`\`
      ┌─ B ─┐
A ──┤      ├── E
      └─ C ─┤
         D ─┘
\`\`\`

**Use when:** Complex dependencies, optimal parallelization

## Worker Templates

Use these templates to define workers:

- [Worker Definition Template](../../templates/worker-definition-template.md)
- [Worker Identity Template](../../templates/worker-identity-template.md)
- [Worker Closeout Template](../../templates/worker-closeout-template.md)

## Best Practices

### ✅ Do

- Define clear, explicit dependencies
- Use token budgets (not time estimates)
- Monitor progress continuously
- Isolate workers (separate branches)
- Document handoffs clearly
- Track metrics (tokens, tasks, efficiency)

### ❌ Don't

- Create circular dependencies
- Share mutable state between workers
- Ignore failures
- Skip integration testing
- Estimate with calendar time
- Launch all workers simultaneously

## Resource Management

### Token Budgets

Allocate tokens per worker:
\`\`\`yaml
worker:
  budget:
    tokens: 150000  # Estimated
    reality_multiplier: 1.5  # 225K actual
\`\`\`

### File Ownership

Define file ownership to prevent conflicts:
\`\`\`yaml
worker:
  owns:
    - agent-rules/python/**
  references:
    - agent-rules/agents/**  # Read-only
\`\`\`

## Progress Monitoring

### Event-Driven

Workers emit events:
\`\`\`
worker.started
worker.task_started
worker.checkpoint
worker.task_completed
worker.complete
\`\`\`

### Structured Logging

Use structured logging functions:
\`\`\`bash
czarina_log_task_start "Task 1.1: Extract standards"
czarina_log_checkpoint "standards_extracted"
czarina_log_task_complete "Task 1.1: Extract standards"
\`\`\`

## Integration Patterns

### Git Worktree

Each worker gets isolated worktree:
- Separate branch per worker
- No merge conflicts during work
- Clean branch history
- Easy to review individual output

### QA Integration

Dedicated QA worker integrates all outputs:
- Merges all worker branches
- Resolves conflicts
- Validates integration
- Creates final deliverable

## Examples

### Agent Rules Extraction

7 workers with dependencies:
1. **foundation** (wave 1)
2. **workflows, patterns, testing, security** (wave 2, parallel)
3. **templates** (wave 3)
4. **qa** (wave 4)

### Microservice Development

4 workers:
1. **api-design** (defines interfaces)
2. **auth-service, user-service** (parallel, depend on API design)
3. **integration-tests** (depends on both services)

## Automation

### Daemon Mode

Orchestrator runs automatically:
- Launches workers when dependencies met
- Monitors progress
- Alerts on failures
- No manual intervention

### Approval Mode

Orchestrator requires approval:
- Asks before launching each worker
- Useful for development/testing
- Provides manual control points

## Related Resources

### Templates
- [Worker Definition Template](../../templates/worker-definition-template.md)
- [Worker Identity Template](../../templates/worker-identity-template.md)
- [Worker Closeout Template](../../templates/worker-closeout-template.md)

### Standards
- [Documentation Standards](../documentation/DOCUMENTATION_STANDARDS.md)
- [Git Workflow](../workflows/GIT_WORKFLOW.md)
- [PR Requirements](../workflows/PR_REQUIREMENTS.md)

### Agent Roles
- [Agent Roles](../agent-roles/AGENT_ROLES.md)
- [Orchestrator Role](../agent-roles/ORCHESTRATOR_ROLE.md)
- [QA Role](../agent-roles/QA_ROLE.md)

## Use Cases

### When to Use Orchestration

Use orchestration when:
- Project requires multiple specialized workers
- Workers have dependencies
- Want to parallelize work
- Need systematic progress tracking
- Managing resource budgets
- Project too large for single worker

### When NOT to Use Orchestration

Don't use orchestration when:
- Single, straightforward task
- No dependencies or parallelization
- Overhead exceeds benefits
- Simple linear workflow sufficient

## Support

### Getting Started

1. Read [Orchestration Patterns](./ORCHESTRATION_PATTERNS.md)
2. Review worker templates
3. Define your workers
4. Set up worktrees
5. Launch orchestration

### Questions?

- Check orchestration patterns document
- Review worker templates and examples
- Look at Czarina implementation
- Consult with team

## Version History

### v1.0.0 (2025-12-26)
- Initial orchestration rules
- Extracted from Czarina
- Comprehensive patterns and examples

---

**Orchestration enables systematic coordination of complex, multi-worker projects while maximizing parallelization and maintaining quality.**
