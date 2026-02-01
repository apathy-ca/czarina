# Architecture Documentation Template

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This template provides comprehensive architecture documentation structure including system design, component interactions, data flows, and architecture decision records (ADRs).

## When to Use This Template

Use this template for:
- New system architecture documentation
- Documenting existing system architecture
- Architecture decision records (ADRs)
- System design documentation
- Technical onboarding materials

---

# [PROJECT_NAME] Architecture

**Version:** [ARCHITECTURE_VERSION]
**Last Updated:** YYYY-MM-DD
**Status:** [Draft / Review / Approved / Deprecated]

## Executive Summary

[PROJECT_NAME] is [2-3 sentence high-level description of what the system does and its purpose].

### Key Architectural Characteristics

- **Style:** [Monolith / Microservices / Serverless / Event-Driven]
- **Deployment:** [Cloud / On-Premise / Hybrid]
- **Scale:** [Number of users / requests / data volume]
- **Key Requirements:** [Performance / Scalability / Reliability / Security]

## System Overview

### High-Level Architecture

\`\`\`
┌─────────────────────────────────────────────────────────┐
│                     External Clients                     │
│            (Web, Mobile, API Consumers)                  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   Load Balancer / CDN                    │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                     API Gateway                          │
│          (Authentication, Rate Limiting, Routing)        │
└─────┬──────────────┬──────────────┬─────────────────────┘
      │              │              │
      ▼              ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Service  │  │ Service  │  │ Service  │
│    A     │  │    B     │  │    C     │
└────┬─────┘  └────┬─────┘  └────┬─────┘
     │             │             │
     └─────────────┴─────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│              Shared Data / Message Layer                 │
│         (Database, Cache, Message Queue)                 │
└─────────────────────────────────────────────────────────┘
\`\`\`

### Key Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| API Gateway | [Technology] | Request routing, authentication, rate limiting |
| Service A | [Technology] | [Purpose] |
| Service B | [Technology] | [Purpose] |
| Database | [Technology] | Persistent data storage |
| Cache | [Technology] | High-performance data caching |
| Message Queue | [Technology] | Asynchronous task processing |

## Architecture Principles

### Core Principles

1. **[Principle 1 Name]**
   - Description: [What this principle means]
   - Rationale: [Why we follow this principle]
   - Implications: [How this affects design decisions]

2. **[Principle 2 Name]**
   - Description: Separation of concerns, modularity
   - Rationale: Improves maintainability and testability
   - Implications: Services are independently deployable

3. **[Principle 3 Name]**
   - Description: Security by design
   - Rationale: Security must be built-in, not bolted-on
   - Implications: All data encrypted, zero-trust architecture

### Design Constraints

- **Constraint 1:** [Description and rationale]
- **Constraint 2:** [Description and rationale]
- **Constraint 3:** [Description and rationale]

## Component Architecture

### Component: [Component Name]

#### Responsibility

[What this component is responsible for]

#### Technology Stack

- **Language:** [Language/Runtime]
- **Framework:** [Framework]
- **Database:** [Database]
- **Dependencies:** [Key dependencies]

#### Internal Architecture

\`\`\`
┌─────────────────────────────────────────┐
│          [Component Name]               │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────────┐  │
│  │       API / Interface Layer       │  │
│  └────────────┬─────────────────────┘  │
│               │                         │
│  ┌────────────▼─────────────────────┐  │
│  │      Business Logic Layer        │  │
│  └────────────┬─────────────────────┘  │
│               │                         │
│  ┌────────────▼─────────────────────┐  │
│  │        Data Access Layer         │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
\`\`\`

#### Key Classes/Modules

\`\`\`python
# Example for Python projects
from dataclasses import dataclass
from typing import Protocol


class ServiceInterface(Protocol):
    """Interface for [Component] service."""

    def process(self, input: Input) -> Output:
        """Process input and return output."""
        ...


@dataclass
class ComponentConfig:
    """Configuration for [Component]."""

    setting_1: str
    setting_2: int
    enable_feature: bool = False
\`\`\`

#### API Contracts

**Input:**
\`\`\`python
{
  "field1": "value",
  "field2": 123
}
\`\`\`

**Output:**
\`\`\`python
{
  "result": "value",
  "status": "success"
}
\`\`\`

#### Dependencies

- **Depends On:** [List of components this depends on]
- **Used By:** [List of components that use this]

#### Performance Characteristics

- **Latency:** [Target latency]
- **Throughput:** [Target throughput]
- **Resource Usage:** [CPU/Memory requirements]

## Data Architecture

### Data Model

#### Entity Relationship Diagram

\`\`\`
┌──────────────┐         ┌──────────────┐
│    User      │────────▶│   Account    │
├──────────────┤   1:1   ├──────────────┤
│ id           │         │ id           │
│ email        │         │ user_id      │
│ created_at   │         │ plan         │
└──────┬───────┘         └──────────────┘
       │ 1:N
       │
       ▼
┌──────────────┐
│   Resource   │
├──────────────┤
│ id           │
│ user_id      │
│ data         │
│ created_at   │
└──────────────┘
\`\`\`

#### Data Entities

**User Entity:**

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary Key | Unique identifier |
| `email` | string | Unique, Not Null | User email address |
| `created_at` | timestamp | Not Null | Account creation time |

**Resource Entity:**

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary Key | Unique identifier |
| `user_id` | UUID | Foreign Key | Owner user ID |
| `data` | JSONB | Not Null | Resource data |
| `created_at` | timestamp | Not Null | Creation time |

### Data Flow

#### Write Path

\`\`\`
Client Request
     │
     ▼
API Validation
     │
     ▼
Business Logic
     │
     ▼
Database Write ──▶ Event Publishing
     │                    │
     ▼                    ▼
Cache Update      Event Consumers
     │
     ▼
Response
\`\`\`

#### Read Path

\`\`\`
Client Request
     │
     ▼
Cache Check ──[Hit]──▶ Return from Cache
     │
  [Miss]
     │
     ▼
Database Query
     │
     ▼
Cache Update
     │
     ▼
Response
\`\`\`

### Data Storage Strategy

| Data Type | Storage | Rationale |
|-----------|---------|-----------|
| User Data | PostgreSQL | ACID compliance, relationships |
| Session Data | Redis | Fast access, TTL support |
| Events | Message Queue | Async processing, durability |
| Files | S3/Object Storage | Scalable, durable |
| Logs | TimescaleDB | Time-series optimization |

## Integration Architecture

### External Integrations

| System | Protocol | Purpose | Authentication |
|--------|----------|---------|----------------|
| [External System 1] | REST | [Purpose] | OAuth 2.0 |
| [External System 2] | gRPC | [Purpose] | API Key |
| [External System 3] | GraphQL | [Purpose] | JWT |

### Integration Patterns

#### Pattern: API Integration

\`\`\`
[Our System] ──HTTP/REST──▶ [External API]
     ▲                              │
     │                              │
     └──────Response / Webhook──────┘
\`\`\`

**Characteristics:**
- Request/Response pattern
- Synchronous communication
- Retry with exponential backoff
- Circuit breaker for fault tolerance

#### Pattern: Event-Driven Integration

\`\`\`
[Our System] ──Publish Event──▶ [Message Queue]
                                      │
                                      ├──▶ [Consumer 1]
                                      ├──▶ [Consumer 2]
                                      └──▶ [Consumer 3]
\`\`\`

**Characteristics:**
- Asynchronous communication
- Loose coupling
- Event sourcing
- At-least-once delivery

## Security Architecture

### Security Layers

\`\`\`
┌─────────────────────────────────────────────┐
│         Network Security (Firewall)         │
├─────────────────────────────────────────────┤
│     Transport Security (TLS/SSL)            │
├─────────────────────────────────────────────┤
│  Application Security (Authentication)      │
├─────────────────────────────────────────────┤
│   Authorization (RBAC/ABAC)                 │
├─────────────────────────────────────────────┤
│      Data Security (Encryption)             │
└─────────────────────────────────────────────┘
\`\`\`

### Authentication Flow

\`\`\`
1. Client ──Credentials──▶ Auth Service
2. Auth Service ──Validate──▶ User Database
3. Auth Service ──Generate──▶ JWT Token
4. Client ──JWT──▶ API Gateway
5. API Gateway ──Verify──▶ Continue to Service
\`\`\`

### Authorization Model

**Role-Based Access Control (RBAC):**

| Role | Permissions |
|------|-------------|
| Admin | Full access to all resources |
| User | Read/write own resources |
| Viewer | Read-only access |

**Resource Ownership:**
- Users can only access resources they own
- Admins can access all resources
- Sharing requires explicit permission grant

### Data Protection

- **At Rest:** AES-256 encryption for sensitive data
- **In Transit:** TLS 1.3 for all communications
- **In Use:** Sensitive data masked in logs
- **Backup:** Encrypted backups, 30-day retention

## Deployment Architecture

### Environment Strategy

| Environment | Purpose | Deployment Trigger |
|-------------|---------|-------------------|
| Development | Active development | Continuous (on commit) |
| Staging | Pre-production testing | On release branch |
| Production | Live system | Manual approval |

### Infrastructure Diagram

\`\`\`
┌─────────────────────────────────────────────────────────┐
│                    Region: us-east-1                     │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │         Availability Zone A                     │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │    │
│  │  │ Service  │  │ Service  │  │ Service  │     │    │
│  │  │  Pod 1   │  │  Pod 2   │  │  Pod 3   │     │    │
│  │  └──────────┘  └──────────┘  └──────────┘     │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │         Availability Zone B                     │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │    │
│  │  │ Service  │  │ Service  │  │ Service  │     │    │
│  │  │  Pod 4   │  │  Pod 5   │  │  Pod 6   │     │    │
│  │  └──────────┘  └──────────┘  └──────────┘     │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
└─────────────────────────────────────────────────────────┘
\`\`\`

### Scaling Strategy

- **Horizontal Scaling:** Auto-scale based on CPU/Memory
- **Vertical Scaling:** Upgrade instance types for databases
- **Database Scaling:** Read replicas for read-heavy workloads

### Disaster Recovery

- **RTO (Recovery Time Objective):** 4 hours
- **RPO (Recovery Point Objective):** 1 hour
- **Backup Strategy:** Daily full backups, hourly incremental
- **Multi-Region:** Active-passive in us-west-2

## Performance & Scalability

### Performance Targets

| Metric | Target | Current | Monitoring |
|--------|--------|---------|------------|
| API Response Time (p95) | < 200ms | 150ms | Datadog |
| API Response Time (p99) | < 500ms | 400ms | Datadog |
| Database Query Time (p95) | < 50ms | 30ms | PostgreSQL Logs |
| Throughput | 10,000 req/sec | 7,000 req/sec | Datadog |
| Uptime | 99.9% | 99.95% | StatusPage |

### Scalability Considerations

1. **Stateless Services:** All services are stateless for horizontal scaling
2. **Caching Strategy:** Multi-layer caching (CDN, Application, Database)
3. **Database Optimization:** Connection pooling, query optimization, indexing
4. **Async Processing:** Background jobs for heavy operations

### Bottleneck Analysis

| Component | Bottleneck | Mitigation |
|-----------|------------|------------|
| Database | Write throughput | Sharding, write-optimized schema |
| Cache | Memory limits | Distributed caching, eviction policies |
| API | CPU-bound tasks | Background processing, worker pools |

## Monitoring & Observability

### Observability Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| Metrics | Datadog / Prometheus | System and application metrics |
| Logs | ELK / Splunk | Centralized logging |
| Traces | Datadog APM / Jaeger | Distributed tracing |
| Alerts | PagerDuty | Incident management |

### Key Metrics

**System Metrics:**
- CPU, Memory, Disk, Network utilization
- Container health, pod restarts

**Application Metrics:**
- Request rate, error rate, duration
- Active connections, queue depth

**Business Metrics:**
- User sign-ups, active users
- API calls per customer, resource usage

### Alerting Strategy

| Alert Level | Response | Example |
|-------------|----------|---------|
| Critical | Immediate page | Service down, data loss |
| High | Page during business hours | High error rate, degraded performance |
| Medium | Slack notification | Elevated latency, warning thresholds |
| Low | Email | Informational, trends |

## Testing Strategy

### Test Pyramid

\`\`\`
        ┌─────┐
        │ E2E │          (Few, Slow, Expensive)
        └─────┘
       ┌───────┐
       │  INT  │         (Some, Medium)
       └───────┘
    ┌───────────┐
    │   UNIT    │        (Many, Fast, Cheap)
    └───────────┘
\`\`\`

### Test Coverage

| Test Type | Coverage Target | Automation |
|-----------|----------------|------------|
| Unit Tests | 85%+ | CI Pipeline |
| Integration Tests | Critical paths | CI Pipeline |
| E2E Tests | User journeys | Nightly |
| Performance Tests | Load scenarios | Weekly |
| Security Tests | OWASP Top 10 | Monthly |

## Architecture Decision Records (ADRs)

### ADR Template

Each significant architectural decision should be documented using this template:

\`\`\`markdown
# ADR-XXX: [Decision Title]

**Status:** [Proposed / Accepted / Deprecated / Superseded]
**Date:** YYYY-MM-DD
**Deciders:** [Names/Roles]

## Context

[Describe the forces at play, constraints, requirements]

## Decision

[Describe the decision that was made]

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

### Alternative 1
- Description
- Pros/Cons
- Why not chosen

### Alternative 2
- Description
- Pros/Cons
- Why not chosen

## References
- Link 1
- Link 2
\`\`\`

### Example ADRs

#### ADR-001: Use PostgreSQL for Primary Database

**Status:** Accepted
**Date:** 2025-01-01
**Deciders:** Architecture Team

**Context:**
Need a reliable, ACID-compliant database for core application data with complex relationships and transaction requirements.

**Decision:**
Use PostgreSQL as the primary relational database.

**Consequences:**

Positive:
- ACID compliance for data integrity
- Rich feature set (JSONB, full-text search, extensions)
- Strong community support and ecosystem
- Excellent performance for our workload

Negative:
- Vertical scaling limitations (mitigated by read replicas)
- More complex than NoSQL for simple key-value scenarios

**Alternatives Considered:**
- MySQL: Less feature-rich for our use cases
- MongoDB: Eventual consistency not suitable for financial transactions
- DynamoDB: Vendor lock-in, less flexible querying

## Evolution & Roadmap

### Current Architecture Version

**Version:** 2.0
**Date:** 2025-01-15

### Planned Evolution

#### Phase 1: Performance Optimization (Q1 2025)
- Implement caching layer
- Optimize database queries
- Add CDN for static assets

#### Phase 2: Scalability Enhancement (Q2 2025)
- Microservices decomposition
- Event-driven architecture
- Multi-region deployment

#### Phase 3: Advanced Features (Q3-Q4 2025)
- Machine learning pipeline
- Real-time analytics
- Advanced monitoring

### Technical Debt

| Item | Impact | Priority | Target Resolution |
|------|--------|----------|-------------------|
| Legacy authentication system | Medium | High | Q1 2025 |
| Monolithic database | High | Medium | Q2 2025 |
| Manual deployment process | Low | Low | Q3 2025 |

## Appendix

### Glossary

- **Term 1:** Definition
- **Term 2:** Definition
- **Term 3:** Definition

### References

- [Link to design docs]
- [Link to API documentation]
- [Link to operational runbooks]

### Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 2.0 | 2025-01-15 | Team | Microservices architecture |
| 1.0 | 2024-01-01 | Team | Initial architecture |

## Related Documents

- [API Documentation](./api-documentation-template.md)
- [README Template](./readme-template.md)
- [Repository Structure Template](./repository-structure-template.md)

## References

This template synthesizes patterns from:
- Foundation Worker: System architecture, component organization
- Patterns Worker: Design patterns, integration patterns
- Security Worker: Security architecture, threat modeling
- Workflows Worker: Documentation workflow, decision records
- Testing Worker: Testing strategy, quality metrics
