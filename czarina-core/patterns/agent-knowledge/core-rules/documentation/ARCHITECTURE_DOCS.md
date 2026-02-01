# Architecture Documentation Standards

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This document defines standards for documenting system architecture, including high-level design, component interactions, data flows, and Architecture Decision Records (ADRs).

## Purpose of Architecture Documentation

Architecture documentation serves to:
- **Onboard new team members** quickly to system design
- **Facilitate technical decisions** by documenting context and rationale
- **Enable effective maintenance** by explaining system structure
- **Support system evolution** by tracking design decisions over time
- **Communicate with stakeholders** about system capabilities and constraints

## Core Architecture Documents

Every significant system should have:

### 1. ARCHITECTURE.md

**Purpose:** High-level system architecture overview

**Required Sections:**
- Executive Summary
- System Overview (diagram)
- Component Architecture
- Data Architecture
- Integration Architecture
- Security Architecture
- Deployment Architecture

**Full template:** [Architecture Documentation Template](../../templates/architecture-documentation-template.md)

### 2. Architecture Decision Records (ADRs)

**Purpose:** Document significant architectural decisions

**Location:** `docs/decisions/` or `docs/adr/`

**Format:** See [ADR Format](#adr-format) below

## Architecture Documentation Structure

### Executive Summary

Brief 2-3 sentence overview:
\`\`\`markdown
## Executive Summary

[PROJECT] is a [type] system that [primary purpose]. The architecture
follows a [pattern] approach with [key characteristics].
\`\`\`

### System Overview

High-level diagram showing main components:

\`\`\`mermaid
graph TD
    A[Client] --> B[API Gateway]
    B --> C[Service Layer]
    C --> D[Data Layer]
\`\`\`

**Include:**
- External actors
- Major system boundaries
- Key components
- Primary data flows

### Component Architecture

For each major component, document:

#### Component Description

\`\`\`markdown
### Component: User Service

**Responsibility:** Manages user accounts and authentication

**Technology Stack:**
- Language: Python 3.11
- Framework: FastAPI
- Database: PostgreSQL
- Cache: Redis

**Key Classes:**
- `UserService` - Business logic
- `UserRepository` - Data access
- `AuthService` - Authentication

**Dependencies:**
- Email Service (for notifications)
- Redis (for session storage)
\`\`\`

#### Component Diagram

\`\`\`mermaid
graph TD
    A[API Layer] --> B[Service Layer]
    B --> C[Repository Layer]
    C --> D[Database]
    B --> E[Cache Layer]
    E --> F[Redis]
\`\`\`

### Data Architecture

Document data models and relationships:

#### Entity Relationship Diagram

\`\`\`mermaid
erDiagram
    USER ||--o{ RESOURCE : owns
    USER {
        uuid id PK
        string email UK
        string name
        timestamp created_at
    }
    RESOURCE {
        uuid id PK
        uuid user_id FK
        string name
        jsonb data
        timestamp created_at
    }
\`\`\`

#### Data Flow Diagrams

**Write Path:**
\`\`\`mermaid
sequenceDiagram
    Client->>API: POST /users
    API->>Validation: Validate input
    Validation->>Service: Create user
    Service->>Database: Insert record
    Database-->>Service: User created
    Service->>Cache: Cache user
    Service->>Events: Publish user.created
    Service-->>API: Return user
    API-->>Client: 201 Created
\`\`\`

**Read Path:**
\`\`\`mermaid
sequenceDiagram
    Client->>API: GET /users/:id
    API->>Cache: Check cache
    alt Cache Hit
        Cache-->>API: Return cached data
    else Cache Miss
        API->>Database: Query user
        Database-->>API: Return user
        API->>Cache: Update cache
    end
    API-->>Client: 200 OK
\`\`\`

### Integration Architecture

Document external system integrations:

\`\`\`markdown
### External Integrations

| System | Protocol | Purpose | Authentication |
|--------|----------|---------|----------------|
| Payment Gateway | REST | Process payments | API Key |
| Email Service | SMTP | Send notifications | OAuth 2.0 |
| Analytics | GraphQL | Track events | JWT |
\`\`\`

**Integration Pattern:**
\`\`\`mermaid
graph LR
    A[Our System] -->|REST| B[External API]
    A -->|Webhook| C[Event Handler]
    C -->|Process| A
\`\`\`

### Security Architecture

Document security layers and controls:

\`\`\`mermaid
graph TD
    A[Network Security] --> B[TLS/SSL]
    B --> C[Authentication]
    C --> D[Authorization]
    D --> E[Data Encryption]
\`\`\`

**Security Controls:**
- **Authentication:** JWT tokens, OAuth 2.0
- **Authorization:** RBAC with resource ownership
- **Data Protection:** AES-256 at rest, TLS 1.3 in transit
- **Rate Limiting:** 60 req/min per user
- **Audit Logging:** All access logged to TimescaleDB

### Deployment Architecture

Document deployment topology:

\`\`\`mermaid
graph TB
    subgraph "Production Environment"
        LB[Load Balancer]
        LB --> APP1[App Instance 1]
        LB --> APP2[App Instance 2]
        LB --> APP3[App Instance 3]
        APP1 & APP2 & APP3 --> DB[(Database Primary)]
        DB -.Replication.-> DR[(Database Replica)]
        APP1 & APP2 & APP3 --> CACHE[Redis Cluster]
    end
\`\`\`

## Architecture Decision Records (ADRs)

### ADR Format

\`\`\`markdown
# ADR-001: [Decision Title]

**Status:** [Proposed | Accepted | Deprecated | Superseded by ADR-XXX]
**Date:** YYYY-MM-DD
**Deciders:** [Names/Roles]
**Technical Story:** [Issue/ticket reference]

## Context

What is the issue we're seeing that is motivating this decision or change?
What are the forces at play (technical, political, social, project)?
What constraints exist?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

### Positive

- Consequence 1
- Consequence 2

### Negative

- Consequence 1
- Consequence 2

### Neutral

- Consequence 1

## Alternatives Considered

### Alternative 1: [Name]

**Description:** [What is this alternative?]

**Pros:**
- Pro 1
- Pro 2

**Cons:**
- Con 1
- Con 2

**Why not chosen:** [Reason]

### Alternative 2: [Name]

[Same structure]

## References

- [Link to research]
- [Link to similar decisions]
- [Link to relevant documentation]

## Implementation Notes

[Optional: Notes about implementation details]

## Review Notes

[Optional: Notes from reviews or retrospectives]
\`\`\`

### ADR Example

\`\`\`markdown
# ADR-001: Use PostgreSQL for Primary Database

**Status:** Accepted
**Date:** 2025-01-01
**Deciders:** Architecture Team, Backend Team
**Technical Story:** #42

## Context

We need to select a primary database for our new application. The application
requires:
- ACID transactions for financial data
- Complex queries with joins
- JSON storage for flexible schemas
- Strong consistency guarantees
- Scalability to millions of records

We're a small team and need mature, well-supported technology.

## Decision

We will use PostgreSQL 15+ as our primary relational database.

## Consequences

### Positive

- ACID compliance ensures data integrity for financial transactions
- Rich feature set (JSONB, full-text search, PostGIS if needed)
- Excellent performance for our expected workload (< 1M records initially)
- Mature ecosystem with extensive tooling and support
- Strong community and documentation
- Free and open-source

### Negative

- Vertical scaling limitations (can be mitigated with read replicas)
- More complex than NoSQL for simple key-value scenarios
- Requires careful index management for optimal performance
- Connection pooling needed for high concurrency

### Neutral

- Will need to learn PostgreSQL-specific features (JSONB, etc.)
- Requires regular maintenance (VACUUM, ANALYZE)

## Alternatives Considered

### Alternative 1: MySQL

**Pros:**
- Widespread familiarity
- Good performance
- Mature ecosystem

**Cons:**
- Less feature-rich than PostgreSQL for our needs
- JSONB support not as advanced
- InnoDB has some limitations

**Why not chosen:** PostgreSQL's superior JSON support and feature set better
matches our requirements.

### Alternative 2: MongoDB

**Pros:**
- Flexible schema
- Horizontal scaling
- Good for unstructured data

**Cons:**
- Eventual consistency doesn't meet our requirements
- Weaker transaction support (improved in 4.0+ but still limited)
- Less suitable for complex queries with joins
- Team has less experience

**Why not chosen:** ACID compliance and strong consistency are critical
requirements that MongoDB doesn't fully satisfy for financial data.

### Alternative 3: DynamoDB

**Pros:**
- Fully managed
- Excellent scalability
- Pay-per-use pricing

**Cons:**
- Vendor lock-in (AWS only)
- Limited query flexibility
- More expensive at our scale
- Team unfamiliar with DynamoDB patterns

**Why not chosen:** Query flexibility and cost concerns, plus want to avoid
vendor lock-in early in project.

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [JSONB Performance Benchmarks](https://example.com/benchmarks)
- [Database Comparison Study](https://example.com/study)

## Implementation Notes

- Use PostgreSQL 15+ for best JSONB performance
- Set up connection pooling (PgBouncer) from day one
- Plan for read replicas when read traffic increases
- Use asyncpg driver for async Python applications

## Review Notes

**2025-02-01:** After 1 month in production, performance exceeds expectations.
JSONB queries perform well. No issues encountered.
\`\`\`

### When to Create an ADR

Create an ADR for decisions that:
- Affect system structure or architecture
- Have long-term impact
- Are difficult or expensive to reverse
- Involve tradeoffs between alternatives
- Need context for future team members

**Examples:**
- Choosing a database technology
- Selecting an authentication approach
- Deciding on deployment strategy
- Adopting a new framework
- Changing API versioning strategy

## Diagram Standards

### Diagram Types

#### 1. System Context Diagram
**Purpose:** Show system boundaries and external actors

\`\`\`mermaid
graph LR
    A[User] --> B[Our System]
    B --> C[External Service]
    B --> D[Database]
\`\`\`

#### 2. Component Diagram
**Purpose:** Show internal components and relationships

\`\`\`mermaid
graph TD
    A[API Layer] --> B[Service Layer]
    B --> C[Data Layer]
\`\`\`

#### 3. Sequence Diagram
**Purpose:** Show interactions over time

\`\`\`mermaid
sequenceDiagram
    Client->>Server: Request
    Server->>Database: Query
    Database-->>Server: Data
    Server-->>Client: Response
\`\`\`

#### 4. Entity Relationship Diagram
**Purpose:** Show data model

\`\`\`mermaid
erDiagram
    USER ||--o{ ORDER : places
    ORDER ||--|{ ITEM : contains
\`\`\`

### Diagram Best Practices

✅ **Do:**
- Keep diagrams simple and focused
- Use consistent notation
- Include legend if needed
- Update diagrams with code changes
- Use standard diagram types (C4, UML)

❌ **Don't:**
- Create overly complex diagrams
- Mix different abstraction levels
- Let diagrams become outdated
- Use custom notation without explanation

## Documentation Maintenance

### When to Update

**Always update when:**
- Adding new components
- Changing system boundaries
- Modifying data models
- Changing integration patterns
- Making architectural decisions

**Review periodically:**
- Quarterly: Verify accuracy
- After major releases: Update diagrams
- When onboarding: Get feedback

### Keeping Documentation Current

**Include in Definition of Done:**
- [ ] Architecture docs updated if design changed
- [ ] ADR created if significant decision made
- [ ] Diagrams updated if structure changed
- [ ] Integration docs updated if external systems changed

## Related Standards

- [Documentation Standards](./DOCUMENTATION_STANDARDS.md)
- [API Documentation Standards](./API_DOCUMENTATION.md)
- [README Template](./README_TEMPLATE.md)

## Templates

- [Architecture Documentation Template](../../templates/architecture-documentation-template.md)

## References

- [C4 Model](https://c4model.com/) - Architecture diagram standard
- [ADR GitHub Organization](https://adr.github.io/) - ADR resources
- [Arc42](https://arc42.org/) - Architecture documentation template

This document synthesizes patterns from:
- Foundation Worker: Component architecture patterns
- Patterns Worker: Design pattern documentation
- Security Worker: Security architecture documentation
- All Workers: Architecture decision practices
