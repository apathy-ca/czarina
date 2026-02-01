# Agent Roles and Worker Taxonomy

**Source:** Extracted from [Czarina](https://github.com/czarina) orchestration patterns
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This document defines the taxonomy of agent roles used in multi-agent orchestration. Agent roles provide clear boundaries, responsibilities, and collaboration patterns for autonomous agents working on software development projects.

**Key Principle:** Each role has a single, well-defined responsibility. Agents should know exactly what they should do, what they shouldn't do, and when to hand off to another role.

## Worker Organization Patterns

### Minimal Pattern (1-2 Workers)
**Use When:** Simple, single-domain tasks

```
project/
└── .czarina/
    └── workers/
        └── implementation.md
```

**Example:** Simple feature implementation with no external dependencies.

### Standard Pattern (3-5 Workers)
**Use When:** Most projects with multiple domains

```
project/
└── .czarina/
    └── workers/
        ├── architect.md      # Planning and design
        ├── code.md           # Implementation
        ├── debug.md          # Troubleshooting (if needed)
        └── qa.md             # Testing and integration
```

**Example:** Feature development with architecture, implementation, and QA phases.

### Extended Pattern (6-8 Workers)
**Use When:** Complex multi-domain projects

```
project/
└── .czarina/
    └── workers/
        ├── architect.md      # System design
        ├── frontend.md       # UI implementation
        ├── backend.md        # API implementation
        ├── database.md       # Schema and migrations
        ├── testing.md        # Test infrastructure
        ├── security.md       # Security review
        └── qa.md             # Integration and closeout
```

**Example:** Full-stack feature with multiple specialized workers.

### Microservices Pattern (8+ Workers)
**Use When:** Large orchestrations with parallel workstreams

```
project/
└── .czarina/
    └── workers/
        ├── foundation.md     # Core infrastructure
        ├── workflows.md      # Development patterns
        ├── patterns.md       # Design patterns
        ├── testing.md        # Test standards
        ├── security.md       # Security practices
        ├── templates.md      # Reusable templates
        └── qa.md             # Integration
```

**Example:** Agent rules library extraction (this project!).

## Worker Definition Format

Each worker must have a clearly defined role document:

```markdown
# Worker: <Name> - <Short Description>

## Role
Single sentence describing the worker's responsibility.

## Mission
Brief summary of what the worker will accomplish.

## Agent
Recommended agent type (aider, cursor, claude-code, etc.)

## Branch
Git branch name for this worker's work.

## Dependencies
List of workers that must complete before this worker starts.
- worker-id-1 - Why this dependency exists
- worker-id-2 - Why this dependency exists

## Budget
- **Tokens:** Estimated token usage
- **Duration:** Estimated calendar time

## Deliverables
Concrete list of files, features, or artifacts this worker will produce.

## Tasks
- [ ] Specific, actionable task 1
- [ ] Specific, actionable task 2
- [ ] Specific, actionable task 3

## Success Criteria
- [ ] Measurable success criterion 1
- [ ] Measurable success criterion 2
```

**From Czarina:** `agent-rules-extraction/.czarina/workers/foundation.md`

## Worker Categories

### Engineering Roles

#### Architect
**Responsibility:** Planning, design, and system architecture
**Produces:** Design documents, API specifications, architecture diagrams
**File Ownership:** `plans/`, `docs/architecture/`, design documents

See [ARCHITECT_ROLE.md](./ARCHITECT_ROLE.md) for details.

#### Code
**Responsibility:** Implementation of features and systems
**Produces:** Source code, unit tests, implementation documentation
**File Ownership:** `src/`, implementation files, module documentation

See [CODE_ROLE.md](./CODE_ROLE.md) for details.

#### Debug
**Responsibility:** Troubleshooting, error investigation, and fixes
**Produces:** Bug fixes, diagnostic reports, error pattern documentation
**File Ownership:** Bug fix commits, troubleshooting guides

See [DEBUG_ROLE.md](./DEBUG_ROLE.md) for details.

### Quality Roles

#### QA
**Responsibility:** Testing, integration, validation, and closeout
**Produces:** Integration tests, validation reports, closeout documentation
**File Ownership:** Integration tests, closeout reports, final documentation

See [QA_ROLE.md](./QA_ROLE.md) for details.

#### Testing (Specialized)
**Responsibility:** Test infrastructure and comprehensive test suites
**Produces:** Test frameworks, test data, coverage reports
**File Ownership:** `tests/`, test configuration, fixtures

### Operations Roles

#### Orchestrator (Czar)
**Responsibility:** Multi-agent coordination and monitoring
**Produces:** Status reports, dependency tracking, worker management
**File Ownership:** Orchestration configuration, logs, status reports

See [ORCHESTRATOR_ROLE.md](./ORCHESTRATOR_ROLE.md) for details.

#### DevOps
**Responsibility:** Deployment, infrastructure, and CI/CD
**Produces:** Deployment scripts, infrastructure configuration, pipelines
**File Ownership:** `.github/`, deployment configs, infrastructure code

### Documentation Roles

#### Documentation
**Responsibility:** User-facing documentation and guides
**Produces:** README files, tutorials, API documentation
**File Ownership:** `docs/`, README.md, user guides

#### Technical Writer
**Responsibility:** Comprehensive technical documentation
**Produces:** Architecture docs, integration guides, migration guides
**File Ownership:** Technical documentation, whitepapers

## Role-Based Organization Principles

### 1. Single Responsibility
Each worker has one clear job:
- **Architects** plan but don't implement
- **Code workers** implement but don't design architecture
- **QA workers** integrate and validate but don't build features
- **Debug workers** fix issues but don't add features

### 2. Clear Boundaries
Workers know what they own:

```
architect/
├── Owns: plans/*.md, design docs
├── Reads: requirements, constraints
└── Hands off to: code workers

code/
├── Owns: src/**/*.py, implementation
├── Reads: plans/*.md from architect
└── Hands off to: QA worker

qa/
├── Owns: integration, closeout
├── Reads: all worker outputs
└── Hands off to: main branch merge
```

**From Czarina:** Clear file ownership prevents conflicts and enables parallel work.

### 3. Dependency Management
Workers declare dependencies explicitly:

```markdown
## Dependencies
- foundation - Need Python standards before writing patterns
- workflows - Need workflow docs before creating templates
```

**Why:** Orchestrator can automatically sequence work and unblock workers.

### 4. Token-Based Planning
Each worker has a token budget:

```markdown
## Budget
- **Tokens:** 1,200,000 (800K-1.2M)
- **Duration:** 5-7 days
```

**Reality Check Multiplier:** Estimate tokens, then multiply by 1.5-2x for actual usage.

**From Czarina:** Token budgets enable realistic planning and prevent scope creep.

### 5. Branch Isolation
Each worker works on a dedicated branch:

```
feat/agent-rules-foundation    # foundation worker
feat/agent-rules-workflows     # workflows worker
feat/agent-rules-patterns      # patterns worker
feat/agent-rules-integration   # qa worker
```

**Why:** Enables parallel work, prevents conflicts, clean integration.

## Worker Lifecycle

### 1. Initialization
```bash
# Worker reads their identity file
cat WORKER_IDENTITY.md

# Worker reads their task definition
cat .czarina/workers/foundation.md

# Worker starts logging
source czarina-core/logging.sh
czarina_log_task_start "Task 1.1: Create directory structure"
```

### 2. Active Work
- Worker executes tasks in order
- Commits at logical checkpoints
- Logs progress to event stream
- Stays within their file ownership boundaries

### 3. Checkpointing
```bash
# After completing a logical unit of work
git add .
git commit -m "feat(foundation): Add Python coding standards

Extract CODING_STANDARDS.md from SARK patterns.

Checkpoint: Python standards complete
"
czarina_log_checkpoint "python_standards_complete"
```

### 4. Completion
```bash
# When all tasks complete
czarina_log_task_complete "Task 1.4: All Python standards extracted"
czarina_log_worker_complete

# Push branch
git push origin feat/agent-rules-foundation

# Notify orchestrator
echo "✅ Foundation worker complete" >> .czarina/events.log
```

### 5. Integration (by QA worker)
```bash
# QA worker merges all branches
git checkout feat/agent-rules-integration
git merge feat/agent-rules-foundation
git merge feat/agent-rules-workflows
# ... etc
```

## Role Selection Guide

### When to Use Architect Role
- ✅ Starting a new feature or system
- ✅ Designing APIs or data models
- ✅ Making architectural decisions
- ✅ Planning multi-phase development
- ❌ Implementing already-designed features
- ❌ Debugging existing code

### When to Use Code Role
- ✅ Implementing designed features
- ✅ Following established patterns
- ✅ Writing unit tests for new code
- ✅ Refactoring within existing design
- ❌ Making architecture decisions
- ❌ Designing new APIs

### When to Use Debug Role
- ✅ Investigating failing tests
- ✅ Fixing reported bugs
- ✅ Troubleshooting production issues
- ✅ Root cause analysis
- ❌ Adding new features
- ❌ Refactoring for improvement

### When to Use QA Role
- ✅ After all dependencies complete
- ✅ Integration testing needed
- ✅ Validation and closeout required
- ✅ Merging multiple worker branches
- ❌ During active development
- ❌ Before dependencies complete

### When to Use Orchestrator Role
- ✅ Coordinating multiple workers
- ✅ Managing dependencies
- ✅ Monitoring progress
- ✅ Automating worker launches
- ❌ Doing implementation work
- ❌ Making technical decisions

## Orchestration Patterns

### Sequential Pattern
Workers execute in order:
```
architect → code → qa
```

**Use When:** Each step depends on the previous step completing.

### Parallel Pattern
Workers execute simultaneously:
```
foundation ┐
workflows  ├→ qa
patterns   ┘
```

**Use When:** Workers have no dependencies and work on different domains.

### Dependency Pattern
Workers execute based on dependency graph:
```
foundation → patterns → templates → qa
         ↘ testing  ↗
         ↘ security ↗
```

**Use When:** Complex dependencies but some parallelism possible.

**From Czarina:** Dependency pattern enables maximum parallelism while respecting dependencies.

## Communication Patterns

### Asynchronous Communication
Workers communicate through artifacts:
- **Design docs** - Architect → Code
- **Source code** - Code → QA
- **Test results** - QA → Everyone
- **Closeout reports** - QA → Orchestrator

### Event Stream
Workers log events for orchestrator monitoring:
```bash
# Worker logs progress
czarina_log_task_start "Task 1.1: Design API"
czarina_log_checkpoint "api_designed"
czarina_log_task_complete "Task 1.1: Design API"
```

### Status Files
Workers update status for coordination:
```
.czarina/
├── status/
│   ├── foundation.status    # COMPLETE
│   ├── workflows.status     # IN_PROGRESS
│   └── qa.status            # WAITING
```

## Success Criteria

An agent role system is well-designed when:

- ✅ Each role has single, clear responsibility
- ✅ File ownership has no overlap between workers
- ✅ Dependencies are explicit and minimal
- ✅ Workers can execute in parallel where possible
- ✅ Integration points are well-defined
- ✅ Token budgets are realistic (with multipliers)
- ✅ Each worker can start autonomously
- ✅ Success criteria are measurable
- ✅ Closeout process is defined
- ✅ Handoff points are clear

## Related Roles

- [ARCHITECT_ROLE.md](./ARCHITECT_ROLE.md) - Planning and design responsibilities
- [CODE_ROLE.md](./CODE_ROLE.md) - Implementation responsibilities
- [DEBUG_ROLE.md](./DEBUG_ROLE.md) - Debugging and troubleshooting
- [QA_ROLE.md](./QA_ROLE.md) - Testing and integration
- [ORCHESTRATOR_ROLE.md](./ORCHESTRATOR_ROLE.md) - Multi-agent coordination

## References

- <!-- Czarina Orchestration Plan - plans directory not included in this repository - plans directory not included in this repository -->
- [Czarina Worker Examples](../../.czarina/workers/)
- <!-- Agent Rules Extraction - internal orchestration directory --> - Real-world orchestration example
