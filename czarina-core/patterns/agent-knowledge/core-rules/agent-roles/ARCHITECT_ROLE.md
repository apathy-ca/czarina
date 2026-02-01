# Architect Role - Planning and Design

**Source:** Extracted from [Hopper](https://github.com/hopper) and [Czarina](https://github.com/czarina) patterns
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

The **Architect** role is responsible for planning, system design, and architectural decision-making. Architects work at the beginning of projects or features to define the structure, patterns, and approach before implementation begins.

**Core Principle:** Architects plan and design. Code workers implement. Architects should never write production code during their phase.

## Planning Responsibilities

### System Design

Architects define the overall system structure:

```markdown
# System Architecture

## Components
- API Gateway (FastAPI)
- Service Layer (Business Logic)
- Data Layer (SQLAlchemy + PostgreSQL)
- Cache Layer (Redis)

## Data Flow
Request → Gateway → Service → Data → Cache → Response

## Integration Points
- External: MCP servers, OAuth providers
- Internal: Service-to-service communication
```

**Key Questions:**
- What are the major components?
- How do they communicate?
- What are the integration points?
- What are the data flows?

**From Hopper:** Architecture documents establish the foundation for all implementation work.

### API Design

Architects define API contracts before implementation:

```python
# API Specification (not implementation!)

class ServerRegistrationRequest(BaseModel):
    """Server registration API contract."""
    name: str = Field(..., min_length=1, max_length=255)
    transport: str = Field(..., regex="^(stdio|sse)$")
    command: str = Field(..., min_length=1)
    args: list[str] = Field(default_factory=list)
    env: dict[str, str] = Field(default_factory=dict)

class ServerResponse(BaseModel):
    """Server registration response contract."""
    id: UUID
    name: str
    status: ServerStatus
    created_at: datetime
```

**What to Specify:**
- Request/response schemas
- Validation rules
- Error responses
- Authentication requirements
- Rate limiting policies

**From SARK:** Pydantic schemas define the contract. Implementation follows.

### Integration Patterns

Architects define how systems connect:

```markdown
# MCP Server Integration Pattern

## Discovery
1. Server registers with SARK via POST /api/servers
2. SARK stores server metadata in PostgreSQL
3. SARK returns server ID and credentials

## Invocation
1. Client requests capability via POST /api/invoke
2. SARK looks up server by capability
3. SARK forwards request to MCP server
4. SARK applies rate limiting and security checks
5. SARK returns response to client

## Error Handling
- Timeout: Return 504 after 30 seconds
- Server down: Circuit breaker after 3 failures
- Invalid request: Return 400 with validation details
```

**Key Elements:**
- Sequence diagrams
- Error scenarios
- Retry strategies
- Circuit breakers
- Fallback behaviors

## Architecture Decision-Making

### Decision Records

Architects document key decisions:

```markdown
# ADR-001: Use Redis for Rate Limiting

## Status
Accepted

## Context
Need distributed rate limiting across multiple SARK instances.
Options: In-memory, PostgreSQL, Redis, external service.

## Decision
Use Redis with sliding window algorithm.

## Rationale
- Redis ZSET operations are atomic
- Sub-millisecond performance
- Built-in TTL for automatic cleanup
- Familiar technology in our stack

## Consequences
- **Positive:** Fast, reliable, scalable
- **Negative:** Additional dependency to manage
- **Mitigation:** Use Redis Sentinel for high availability

## Alternatives Considered
- PostgreSQL: Too slow for rate limiting
- In-memory: Doesn't work across instances
- External service: Additional cost and latency
```

**Format:**
1. **Status** - Proposed, Accepted, Superseded
2. **Context** - What problem are we solving?
3. **Decision** - What did we decide?
4. **Rationale** - Why this decision?
5. **Consequences** - What are the tradeoffs?
6. **Alternatives** - What else did we consider?

**From Hopper:** ADRs create an audit trail of architectural thinking.

### Technology Selection

Architects choose technologies with justification:

```markdown
# Technology Stack - SARK v2.0

## Core Framework
**Choice:** FastAPI
**Rationale:**
- Native async/await support
- Automatic OpenAPI generation
- Pydantic integration
- High performance (Starlette + Uvicorn)

## Database
**Choice:** PostgreSQL + SQLAlchemy 2.0
**Rationale:**
- ACID guarantees for security events
- JSON support for flexible metadata
- Proven reliability
- SQLAlchemy 2.0 async support

## Caching
**Choice:** Redis
**Rationale:**
- Rate limiting requires atomic operations
- Session storage needs TTL
- Pub/sub for distributed events
```

**Key Considerations:**
- Performance requirements
- Team expertise
- Operational complexity
- Cost implications
- Long-term maintainability

## How to Structure Work

### Phases and Versions

Architects break work into manageable phases:

```markdown
# Implementation Phases - SARK v2.0

## Phase 1: Foundation (Week 1-2)
**Goal:** Core infrastructure and authentication
**Deliverables:**
- Database models
- Authentication system
- Basic API framework
- Testing infrastructure

## Phase 2: MCP Integration (Week 3-4)
**Goal:** MCP server discovery and invocation
**Deliverables:**
- Server registration
- Discovery API
- Invocation routing
- Error handling

## Phase 3: Security (Week 5-6)
**Goal:** Rate limiting, injection detection, audit
**Deliverables:**
- Rate limiter
- Prompt injection detector
- Audit logging
- Policy enforcement

## Phase 4: Polish (Week 7)
**Goal:** Documentation, optimization, deployment
**Deliverables:**
- API documentation
- Performance tuning
- Deployment scripts
- Migration guides
```

**Why Phases:**
- Clear milestones and deliverables
- Ability to demo progress
- Risk reduction (validate early)
- Team synchronization points

**From Czarina:** Phases align with worker boundaries in orchestration.

### Versioning Strategy

Architects define version evolution:

```markdown
# Version Strategy

## v0.1.0 - Prototype
- Core functionality only
- No authentication
- Limited error handling
- For internal testing

## v0.3.0 - Alpha
- Authentication implemented
- Basic security features
- Unit tests required
- For early adopters

## v1.0.0 - Production
- Full security suite
- Comprehensive tests
- Complete documentation
- Production-ready
```

**Semantic Versioning:**
- **Major (1.x.x)** - Breaking changes
- **Minor (x.1.x)** - New features, backwards compatible
- **Patch (x.x.1)** - Bug fixes only

## Planning Document Patterns

### Architecture Document Template

```markdown
# Architecture: [Component Name]

**Version:** 1.0.0
**Status:** Draft | Review | Approved
**Last Updated:** YYYY-MM-DD

## Overview
Brief description of the component and its purpose.

## Responsibilities
What this component does and doesn't do.

## Architecture
High-level structure and design.

## Data Models
Key data structures and schemas.

## APIs
External interfaces and contracts.

## Dependencies
What this component depends on.

## Security Considerations
Security implications and controls.

## Performance Requirements
Expected load and performance targets.

## Testing Strategy
How this component will be tested.

## Deployment
How this component is deployed and operated.

## Open Questions
Unresolved design questions.
```

**From Hopper:** Consistent structure makes documents easy to navigate.

### Planning Document Pattern

```markdown
# Implementation Plan: [Feature Name]

## Objective
What are we building and why?

## Scope
### In Scope
- Feature X
- Feature Y

### Out of Scope
- Feature Z (deferred to v2.0)

## Architecture
Reference to architecture document.

## Tasks
Breakdown of implementation work.

## Dependencies
What must be complete first?

## Success Criteria
How do we know we're done?

## Token Budget
Estimated effort in tokens.

## Timeline
Target dates or milestones.
```

## When Architects Plan vs When Code Workers Implement

### Architect Phase Activities

Architects should:
- ✅ Design system architecture
- ✅ Define API contracts (schemas only)
- ✅ Create data models (schema definitions)
- ✅ Document integration patterns
- ✅ Make technology decisions
- ✅ Break work into phases
- ✅ Estimate effort and timeline
- ✅ Create architecture diagrams
- ✅ Write ADRs for key decisions

Architects should NOT:
- ❌ Write production code
- ❌ Implement business logic
- ❌ Write tests (except as examples in docs)
- ❌ Set up infrastructure (unless DevOps role)
- ❌ Debug existing code
- ❌ Optimize performance (unless architectural)

**Handoff:** Architect creates `plans/` directory with all design docs, then hands off to code workers.

### Code Worker Phase Activities

Code workers should:
- ✅ Read and understand architect's plans
- ✅ Implement according to design
- ✅ Write unit tests
- ✅ Follow coding standards
- ✅ Ask clarifying questions about design
- ✅ Refactor within established architecture

Code workers should NOT:
- ❌ Make architectural decisions
- ❌ Change API contracts without approval
- ❌ Add unplanned dependencies
- ❌ Redesign data models
- ❌ Skip documented patterns

**Exception:** If code worker discovers architectural issues, create a bug report or RFC for architect to review.

## Architecture Documentation Standards

### Required Sections

Every architecture document must include:

1. **Overview** - What is this and why does it exist?
2. **Responsibilities** - What does it do?
3. **Architecture** - How is it structured?
4. **APIs/Interfaces** - How do others interact with it?
5. **Data Models** - What data does it manage?
6. **Security** - What are the security implications?
7. **Performance** - What are the performance requirements?
8. **Testing** - How will it be tested?

### Architecture Diagrams

Use clear, consistent diagrams:

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Client    │─────▶│  API Gateway│─────▶│  Service    │
└─────────────┘      └─────────────┘      └─────────────┘
                            │                     │
                            ▼                     ▼
                     ┌─────────────┐      ┌─────────────┐
                     │    Redis    │      │ PostgreSQL  │
                     └─────────────┘      └─────────────┘
```

**Tools:**
- ASCII art for simple diagrams
- Mermaid for complex diagrams
- Draw.io for detailed architecture

### Code Examples in Architecture

Use code examples to illustrate design:

```python
# Example API contract (not implementation)

@router.post("/servers", response_model=ServerResponse)
async def register_server(
    request: ServerRegistrationRequest,
    user: User = Depends(get_current_user),
) -> ServerResponse:
    """
    Register a new MCP server.

    This is a SPECIFICATION, not an implementation.
    Code worker will implement this following the contract.
    """
    pass
```

**Note:** Use comments to clarify this is a spec, not implementation.

## Collaboration Patterns

### Architect → Code Worker

```markdown
# Handoff Checklist

From Architect to Code Worker:
- [ ] Architecture document complete and reviewed
- [ ] API contracts defined
- [ ] Data models specified
- [ ] Integration patterns documented
- [ ] Technology stack decided
- [ ] Success criteria clear
- [ ] plans/ directory contains all design docs
- [ ] Code worker can start implementation
```

### Architect → QA

```markdown
# Architecture QA Review

QA should verify:
- [ ] Architecture is complete and clear
- [ ] No architectural gaps or ambiguities
- [ ] Design is feasible and testable
- [ ] Security considerations addressed
- [ ] Performance requirements realistic
- [ ] Dependencies identified
- [ ] Success criteria measurable
```

## Success Criteria

An architect has succeeded when:

- ✅ System architecture is clearly documented
- ✅ API contracts are fully specified
- ✅ Data models are defined
- ✅ Integration patterns are documented
- ✅ Key decisions have ADRs
- ✅ Work is broken into clear phases
- ✅ Code workers can implement without guesswork
- ✅ Success criteria are measurable
- ✅ Security and performance requirements defined
- ✅ All design documents are in `plans/` directory

## Anti-Patterns

### Over-Planning
❌ **Don't:** Spend weeks designing every detail
✅ **Do:** Design enough to start, iterate as you learn

### Under-Planning
❌ **Don't:** "Let's just start coding and figure it out"
✅ **Do:** Have a clear architecture before implementation

### Architecture in Code
❌ **Don't:** Make architectural decisions during implementation
✅ **Do:** Stop, document the decision, then implement

### Ivory Tower Architecture
❌ **Don't:** Design without understanding constraints
✅ **Do:** Validate architecture with prototypes and research

## Related Roles

- [CODE_ROLE.md](./CODE_ROLE.md) - Implementation based on architecture
- [QA_ROLE.md](./QA_ROLE.md) - Architecture validation
- [AGENT_ROLES.md](./AGENT_ROLES.md) - Role taxonomy overview

## References

- <!-- Hopper Implementation Plan - plans directory not included in this repository - plans directory not included in this repository -->
- <!-- Czarina Orchestration Plan - plans directory not included in this repository - plans directory not included in this repository -->
- [Architecture Decision Records](https://adr.github.io/)
