# Agent Roles and Worker Taxonomy

**Version:** 1.0.0
**Last Updated:** 2025-12-26

---

## Overview

This directory defines the agent roles and worker taxonomy used in multi-agent software development orchestration. These patterns enable autonomous agents to work together effectively through clear role definitions, responsibilities, and collaboration patterns.

**Core Philosophy:** Each role has a single, well-defined responsibility. Agents know exactly what they should do, what they shouldn't do, and when to hand off to another role.

---

## Quick Start

### For New Orchestrations

1. **Choose Organization Pattern** - See [AGENT_ROLES.md](./AGENT_ROLES.md#worker-organization-patterns)
   - Minimal (1-2 workers) - Simple tasks
   - Standard (3-5 workers) - Most projects
   - Extended (6-8 workers) - Complex projects
   - Microservices (8+ workers) - Large orchestrations

2. **Select Roles** - See [Role Selection Guide](#role-selection-guide)
   - What roles do you need?
   - What are the dependencies?
   - How will they coordinate?

3. **Define Workers** - Use [Worker Templates](../../templates/)
   - Copy worker-definition-template.md
   - Fill in role-specific details
   - Define clear success criteria

4. **Launch Orchestration** - See [ORCHESTRATOR_ROLE.md](./ORCHESTRATOR_ROLE.md)
   - Set up dependency graph
   - Launch workers in order
   - Monitor progress

### For Workers

1. **Read Your Identity** - `WORKER_IDENTITY.md` in your worktree
2. **Read Your Role** - Appropriate role document in this directory
3. **Read Your Tasks** - `.czarina/workers/[your-worker-id].md`
4. **Start Working** - Follow your role's guidelines

---

## Role Definitions

### Engineering Roles

#### [Architect](./ARCHITECT_ROLE.md) - Planning and Design
**Responsibility:** System design, API specifications, architecture decisions

**Use When:**
- Starting a new feature or system
- Designing APIs or data models
- Making architectural decisions
- Planning multi-phase development

**Produces:**
- Architecture documents
- API specifications
- Design diagrams
- Technology decisions

---

#### [Code](./CODE_ROLE.md) - Implementation
**Responsibility:** Implementing features and writing production code

**Use When:**
- Implementing designed features
- Following established patterns
- Writing unit tests
- Refactoring within existing design

**Produces:**
- Source code
- Unit tests
- Implementation documentation

---

#### [Debug](./DEBUG_ROLE.md) - Troubleshooting
**Responsibility:** Investigating errors and fixing bugs

**Use When:**
- Investigating failing tests
- Fixing reported bugs
- Troubleshooting production issues
- Root cause analysis

**Produces:**
- Bug fixes
- Diagnostic reports
- Error pattern documentation
- Regression tests

---

### Quality Roles

#### [QA](./QA_ROLE.md) - Testing and Integration
**Responsibility:** Integration testing, validation, and closeout

**Use When:**
- After all dependencies complete
- Integration testing needed
- Validation and closeout required
- Merging multiple worker branches

**Produces:**
- Integration tests
- Validation reports
- Closeout documentation
- Final integration

---

### Operations Roles

#### [Orchestrator](./ORCHESTRATOR_ROLE.md) - Coordination (Czar)
**Responsibility:** Multi-agent coordination and monitoring

**Use When:**
- Coordinating multiple workers
- Managing dependencies
- Monitoring progress
- Automating worker launches

**Produces:**
- Status reports
- Dependency tracking
- Worker management
- Metrics and analytics

---

## Role Selection Guide

### Quick Decision Tree

```
Is this a new feature or existing code?
├─ NEW FEATURE
│  ├─ Do you have a clear design?
│  │  ├─ YES → Use CODE role
│  │  └─ NO → Use ARCHITECT role first
│  └─ Multiple workers needed?
│     ├─ YES → Use ORCHESTRATOR role
│     └─ NO → Single CODE worker
│
└─ EXISTING CODE
   ├─ Is it broken?
   │  ├─ YES → Use DEBUG role
   │  └─ NO → Use CODE role for enhancements
   └─ Ready for release?
      └─ YES → Use QA role
```

### Role Compatibility Matrix

| Current Role | Can Hand Off To | Should NOT Hand To |
|--------------|-----------------|-------------------|
| Architect | Code, Debug | QA (too early) |
| Code | Debug, QA | Architect (design phase over) |
| Debug | Code (for refactor), QA | Architect (unless design flaw) |
| QA | - (final role) | Any (QA is last) |
| Orchestrator | All workers | - (coordinates, doesn't execute) |

### When to Use Each Role

#### Use ARCHITECT When:
- ✅ Designing new systems or major features
- ✅ Defining API contracts
- ✅ Making technology decisions
- ✅ Creating integration patterns
- ❌ NOT for implementing already-designed features
- ❌ NOT for debugging existing code

#### Use CODE When:
- ✅ Implementing designed features
- ✅ Following established patterns
- ✅ Writing unit tests
- ✅ Refactoring within existing architecture
- ❌ NOT for making architectural decisions
- ❌ NOT for debugging (unless trivial)

#### Use DEBUG When:
- ✅ Tests are failing
- ✅ Bugs are reported
- ✅ Production issues occur
- ✅ Root cause analysis needed
- ❌ NOT for adding new features
- ❌ NOT for refactoring improvements

#### Use QA When:
- ✅ All dependencies complete
- ✅ Integration testing needed
- ✅ Ready for final validation
- ✅ Closeout report required
- ❌ NOT during active development
- ❌ NOT before dependencies complete

#### Use ORCHESTRATOR When:
- ✅ Multiple workers to coordinate
- ✅ Complex dependency graph
- ✅ Progress monitoring needed
- ✅ Automated workflow desired
- ❌ NOT for single-worker projects
- ❌ NOT for doing implementation work

---

## Orchestration Patterns Summary

### Sequential Pattern
**When:** Each step depends on the previous
```
architect → code → debug → qa
```

### Parallel Pattern
**When:** Workers have no dependencies
```
worker1 ┐
worker2 ├─→ qa
worker3 ┘
```

### Dependency Pattern
**When:** Some parallelism with dependencies
```
foundation → patterns → templates → qa
         ↘ testing  ↗
         ↘ security ↗
```

See [AGENT_ROLES.md](./AGENT_ROLES.md#orchestration-patterns) for details.

---

## Worker Templates

Use these templates to create consistent worker definitions:

### [Worker Definition Template](../../templates/worker-definition-template.md)
Complete template for defining a worker's role, tasks, and deliverables.

**Use for:** Creating new worker definitions in `.czarina/workers/`

### [Worker Identity Template](../../templates/worker-identity-template.md)
Template for worker identity files that guide agents.

**Use for:** Creating `WORKER_IDENTITY.md` in worker worktrees

### [Worker Closeout Template](../../templates/worker-closeout-template.md)
Template for worker closeout reports.

**Use for:** Documenting worker completion and handoff to QA

---

## File Organization

```
agents/
├── README.md                           # This file
├── AGENT_ROLES.md                      # Role taxonomy overview
├── ARCHITECT_ROLE.md                   # Planning and design role
├── CODE_ROLE.md                        # Implementation role
├── DEBUG_ROLE.md                       # Debugging role
├── QA_ROLE.md                          # Testing and integration role
├── ORCHESTRATOR_ROLE.md                # Coordination role (Czar)
└── templates/                          # Worker templates
    ├── worker-definition-template.md   # Worker task definition
    ├── worker-identity-template.md     # Worker identity file
    └── worker-closeout-template.md     # Worker completion report
```

---

## Key Principles

### 1. Single Responsibility
Each role has one clear job. No overlap or ambiguity.

### 2. Clear Boundaries
Workers know what they own and what they don't. File ownership is explicit.

### 3. Dependency Management
Dependencies are declared explicitly. Workers wait for dependencies before starting.

### 4. Autonomous Execution
Workers can start and complete their work without constant supervision.

### 5. Communication Through Artifacts
Workers communicate via files, logs, and git commits, not synchronous chat.

### 6. Quality Gates
QA role ensures quality before integration. No shortcuts to main branch.

---

## Common Workflows

### New Feature Development

```
1. ARCHITECT designs feature
   ├─ Creates plans/feature-design.md
   ├─ Defines API contracts
   └─ Specifies data models

2. CODE implements feature
   ├─ Reads plans/feature-design.md
   ├─ Implements according to spec
   └─ Writes unit tests

3. DEBUG fixes any issues
   ├─ Investigates test failures
   ├─ Fixes bugs
   └─ Adds regression tests

4. QA validates and integrates
   ├─ Runs integration tests
   ├─ Validates against specs
   └─ Merges to main
```

### Bug Fix Workflow

```
1. DEBUG investigates bug
   ├─ Reproduces issue
   ├─ Identifies root cause
   ├─ Implements fix
   └─ Adds regression test

2. QA validates fix
   ├─ Verifies bug is fixed
   ├─ Ensures no regressions
   └─ Approves for deployment
```

### Multi-Worker Orchestration

```
1. ORCHESTRATOR sets up coordination
   ├─ Defines dependency graph
   ├─ Creates worker definitions
   └─ Launches daemon

2. Workers execute in parallel
   ├─ Each on dedicated branch
   ├─ Progress logged to event stream
   └─ Dependencies auto-tracked

3. QA integrates all workers
   ├─ Merges all branches
   ├─ Resolves conflicts
   ├─ Validates integration
   └─ Generates closeout report
```

---

## Best Practices

### For All Roles

1. **Read Your Role Document** - Understand your responsibilities
2. **Follow Patterns** - Use established patterns and standards
3. **Communicate Through Artifacts** - Create clear documentation
4. **Commit Frequently** - Checkpoints enable rollback and collaboration
5. **Stay Within Scope** - Don't do other roles' work
6. **Ask When Unclear** - Create RFCs or ask orchestrator

### For Orchestrators

1. **Define Clear Boundaries** - No file ownership overlap
2. **Respect Dependencies** - Launch workers only when ready
3. **Monitor Progress** - Regular status checks
4. **Collect Metrics** - Track for continuous improvement
5. **Support Workers** - Remove blockers, provide resources

### For Workers

1. **Read Your Identity** - Know your mission
2. **Follow Your Role** - Don't make decisions outside your role
3. **Log Progress** - Help orchestrator monitor
4. **Commit Checkpoints** - Enable recovery and review
5. **Handoff Cleanly** - Prepare artifacts for next role

---

## Success Criteria

An agent role system is working well when:

- ✅ Each worker knows exactly what to do
- ✅ No overlap or conflict between workers
- ✅ Dependencies are clear and respected
- ✅ Workers can execute autonomously
- ✅ Integration is smooth and conflict-free
- ✅ Quality gates are enforced
- ✅ Progress is transparent
- ✅ Metrics show efficiency gains

---

## Related Documentation

### Within This Library
- [Python Coding Standards](../python-standards/CODING_STANDARDS.md)
- [Git Workflow](../workflows/GIT_WORKFLOW.md)
- [Testing Patterns](../python-standards/TESTING_PATTERNS.md)

### Orchestration Resources
- <!-- Czarina Documentation - internal orchestration directory -->
- <!-- Orchestration Plan - plans directory not included in this repository - plans directory not included in this repository -->
- [Worker Examples](../../.czarina/workers/)

### Real-World Examples
- <!-- Agent Rules Extraction - internal orchestration directory --> - This project!
- [SARK Implementation](https://github.com/sark)
- [Hopper Development](https://github.com/hopper)

---

## Version History

- **1.0.0** (2025-12-26) - Initial release
  - Complete role definitions
  - Worker templates
  - Orchestration patterns
  - Real-world examples from Czarina

---

## Contributing

To add or update role definitions:

1. Follow the structure of existing role documents
2. Include concrete examples from real projects
3. Add cross-references to related roles
4. Update this README's index
5. Submit for QA review

---

## License

These patterns are extracted from open-source projects and are provided
as-is for use in agent-driven software development.

---

## Related Patterns

For tool-specific mode capabilities and optimization, see:
- [Mode Capabilities](../../patterns/mode-capabilities/README.md) - Tool-specific mode definitions and optimization patterns

---

**Questions or Issues?**
- Review the role documents
- Check the templates
- Reference real-world examples
- Consult the orchestrator

**Last Updated:** 2025-12-26
**Maintainer:** Agent Rules Library Project
