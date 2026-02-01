# Architect Mode

**Purpose**: Plan, design, and strategize before implementation.

**Value**: Well-designed solutions reduce implementation time by 30-50% and prevent costly refactoring.

**Best For**: Complex features, system redesigns, technical specifications, effort estimation.

---

## Capabilities

### Can Do

- Create implementation plans
- Design system architecture
- Break down complex problems into manageable pieces
- Create technical specifications and design documents
- Analyze requirements and constraints
- Propose and evaluate multiple solutions
- Create diagrams, flowcharts, and visual specifications
- Estimate effort, complexity, and risk
- Document design decisions and trade-offs
- Create task breakdowns for implementation

### Cannot Do

- Write or modify actual code files
- Execute commands or run tests
- Deploy changes or modify production
- Modify configuration files directly
- Make direct changes to any source code

---

## Allowed File Patterns

**Can Create/Modify**:
- `*.md` (Markdown documentation)
- `*.txt` (Text files)
- `*.mermaid` (Diagrams and flowcharts)
- Design documents and specifications

**Cannot Touch**:
- Source code (`.js`, `.py`, `.ts`, `.go`, `.java`, etc.)
- Configuration files (unless they're documentation)
- Binary files
- Generated files

---

## When to Use Architect Mode

### Start with Architect When

- **Starting a new feature**: Understand requirements and design before coding
- **Planning a refactor**: Map out changes and impact before touching code
- **Designing architecture**: Make structural decisions visible
- **Breaking down complex tasks**: Create implementation subtasks
- **Creating specifications**: Document what needs to be built
- **Evaluating trade-offs**: Compare different approaches

### Example Situations

**Scenario 1: New microservice**
- Task: Add user authentication service to existing monolith
- Architect steps:
  1. Analyze current architecture and constraints
  2. Design new service (API, database schema, dependencies)
  3. Document integration points
  4. Create implementation plan with subtasks
  5. Switch to Code mode to implement

**Scenario 2: Large refactor**
- Task: Refactor authentication module for better testability
- Architect steps:
  1. Document current behavior and tests
  2. Design new structure
  3. Identify breaking changes
  4. Create migration strategy
  5. Switch to Code mode to refactor

**Scenario 3: Complex feature**
- Task: Add multi-tenant support to SaaS application
- Architect steps:
  1. List all affected components
  2. Design tenant isolation strategy
  3. Plan database schema changes
  4. Create implementation phases
  5. Switch to Code mode for each phase

---

## Input Requirements

For Architect mode to be most effective, provide:

1. **Business Requirements**: What problem are we solving?
2. **Constraints**: Technical, performance, time constraints
3. **Existing Context**: Current architecture, tech stack, team capabilities
4. **Scope**: What's in/out of scope
5. **Success Criteria**: How do we know it works?

---

## Output to Expect

Architect mode produces:

1. **Implementation Plan**: Step-by-step approach to solution
2. **Technical Design**: Architecture, data flow, component interaction
3. **Specifications**: What each component does and its interface
4. **Risk Assessment**: What could go wrong and mitigation strategies
5. **Effort Estimates**: How long each phase takes
6. **Task Breakdown**: Concrete subtasks for implementation

---

## Design Document Template

When creating design documents, use this structure:

```markdown
# Design: [Feature Name]

## Overview
Brief summary of what we're building and why.

## Requirements
What must the solution do?

## Constraints
Technical, performance, or other constraints.

## Proposed Solution
How we'll build it.

## Architecture
Diagrams and component descriptions.

## Data Model
Schemas, relationships, storage.

## Integration Points
How it connects to existing systems.

## Implementation Plan
1. Phase 1: [tasks]
2. Phase 2: [tasks]
3. Phase 3: [tasks]

## Risk Assessment
What could go wrong?

## Alternatives Considered
Other approaches and why we chose this one.

## Effort Estimate
Rough time estimates per phase.
```

---

## Common Design Patterns

### Pattern: Breaking Down Features

**When**: Large feature seems overwhelming
**How**:
1. List all major components
2. Identify dependencies between components
3. Create implementation order (dependencies first)
4. Estimate each subtask
5. Switch to Code mode for implementation

**Example**:
- Feature: "Add search functionality"
- Components: Search UI, Search API, Database indices, Search algorithm
- Order: Database indices → Search algorithm → Search API → UI
- Subtasks: Clear implementation sequence

### Pattern: Evaluation Decision Tree

**When**: Multiple architectural approaches exist
**How**:
1. List evaluation criteria
2. Score each approach against criteria
3. Document trade-offs
4. Make explicit decision
5. Document why (for future reference)

**Example**:
```
Authentication approach:
- JWT (stateless, good for microservices, harder to revoke)
- Sessions (stateful, simple, requires shared cache)
- OAuth (complex, good for multiple apps, overkill for single service)

Criteria: Security, simplicity, scalability, revocation speed
Decision: JWT + Redis revocation list (compromise approach)
```

### Pattern: Risk Assessment

**When**: Solution involves significant changes
**How**:
1. List potential failure points
2. Estimate probability and impact
3. Plan mitigations
4. Identify rollback strategies
5. Document unknowns

---

## When to Switch Modes

### Switch to Code Mode When

- Design is complete and validated
- Implementation plan is clear
- Ready to write actual code
- Need to execute changes

**Example transition**:
```
Architecture design is complete. I've documented:
- Service interfaces (AuthService, UserService, DataService)
- Database schema and migrations
- API contracts and response formats
- Implementation order and dependencies

Next: Switch to Code mode to implement the three services.
```

### Switch to Ask Mode When

- Need to understand existing code before designing
- Need to learn about a technology
- Need clarification on requirements
- Want to explore options without implementing

**Example transition**:
```
Before finalizing architecture, I need to understand the current
authentication system better. Switching to Ask mode to analyze
the existing code and explain current patterns.
```

### Switch to Orchestrator Mode When

- Design spans multiple teams or phases
- Need to coordinate across multiple modes
- Complex dependencies between phases
- Project takes multiple days/weeks

**Example transition**:
```
This refactor is too large for single-mode work:
- Phase 1: Design (Architect)
- Phase 2: Implement services (Code)
- Phase 3: Migrate data (Code + Debug)
- Phase 4: Deprecate old system (Code)
- Phase 5: Monitor and verify (Debug)

Switching to Orchestrator mode to manage the workflow.
```

---

## Anti-Patterns

### Anti-Pattern: Design Paralysis

**Problem**: Spending weeks designing without implementing
**Why it happens**: Trying to design everything perfectly upfront
**Solution**: Design enough to start coding, iterate and refine

**Good approach**: 80% design confidence → switch to Code

### Anti-Pattern: Design Without Context

**Problem**: Designing in isolation without understanding current system
**Why it happens**: Starting Architect without reading existing code
**Solution**: Analyze existing code first (Ask mode) → then design (Architect)

### Anti-Pattern: Ignoring Constraints

**Problem**: Designing theoretical solutions that can't be implemented
**Why it happens**: Not fully understanding constraints
**Solution**: Explicitly list all constraints, validate design against them

### Anti-Pattern: Over-Specifying

**Problem**: Designing every detail including things for Code mode to decide
**Why it happens**: Trying to remove all ambiguity upfront
**Solution**: Architect decides architecture, Code decides implementation details

---

## Interaction with Other Modes

### With Code Mode

**Flow**: Architect designs → Code implements
- Architect provides: Design spec, task list, implementation order
- Code provides: Implementation feedback, discovered complexities
- Note: Code may deviate from design based on implementation realities (OK!)

### With Debug Mode

**Flow**: Code encounters issue → Debug investigates → Architect redesigns?
- If issue reveals design flaw: Architect redesigns, Code re-implements
- If issue is implementation bug: Debug identifies, Code fixes

### With Ask Mode

**Flow**: Architect uncertain → Ask explains → Architect decides
- Ask clarifies requirements, technology, existing code
- Architect uses clarity to make design decisions

### With Orchestrator Mode

**Flow**: Orchestrator delegates design work to Architect
- Orchestrator: Manages overall project coordination
- Architect: Handles design aspects within larger project

---

## Key Principles

1. **Design Enough, But Not Too Much**: Aim for 80% clarity, not 100% specification
2. **Document Decisions**: Future-you will thank you for explaining why
3. **Validate Against Reality**: Check design assumptions against actual code
4. **Stay Flexible**: Design is a guide, not a prison
5. **Communicate Trade-offs**: Acknowledge what you're giving up and gaining

---

## Related Patterns

- [Mode Transitions](./mode-transitions.md) - When to switch from Architect
- [Code Mode](./code-mode.md) - What Code mode does after design
- [Ask Mode](./ask-mode.md) - Understanding before designing
- [Orchestrator Mode](./orchestrator-mode.md) - Coordinating large designs

---

**Last Updated**: 2025-12-28
**Applicability**: Architect-focused development workflows
**Source**: MODE_CAPABILITIES.md from agentic-dev-patterns

*"An hour of planning saves ten hours of coding."*
