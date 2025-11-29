# 🎭 Czarina Worker Patterns

Czarina supports **any number of workers** - from 2 to 20+. Here are common patterns proven in production.

## 📊 Common Patterns

### Minimal (3 Workers)
**Use case**: Small features, tight budgets, simple projects

```bash
WORKER_DEFINITIONS=(
    "engineer|feat/v1.2.0-implementation|engineer_TASKS.txt|Feature Implementation"
    "qa|feat/v1.2.0-testing|qa_TASKS.txt|Testing & Validation"
    "docs|feat/v1.2.0-documentation|docs_TASKS.txt|Documentation"
)
```

**Roles**:
- Engineer: Builds the feature
- QA: Tests everything
- Docs: Documents usage

**Timeline**: 1-2 days
**Best for**: Bug fixes, minor features, documentation updates

---

### Standard (6 Workers) ⭐ **Recommended Default**
**Use case**: Medium features, balanced coverage, proven pattern

```bash
WORKER_DEFINITIONS=(
    "engineer1|feat/v1.1-backend|engineer1_TASKS.txt|Backend Implementation"
    "engineer2|feat/v1.1-frontend|engineer2_TASKS.txt|Frontend Implementation"
    "engineer3|feat/v1.1-integration|engineer3_TASKS.txt|System Integration"
    "qa|feat/v1.1-testing|qa_TASKS.txt|Testing & Validation"
    "docs|feat/v1.1-documentation|docs_TASKS.txt|Documentation & Guides"
    "devops|feat/v1.1-deployment|devops_TASKS.txt|Deployment & Infrastructure"
)
```

**Roles**:
- Engineers 1-3: Split work by layer/concern
- QA: Comprehensive testing
- Docs: User-facing documentation
- DevOps: Deployment, monitoring, CI/CD

**Timeline**: 3-5 days
**Best for**: Full features, API + UI, migrations

**Real example**: SARK v1.1 Gateway Integration (6 workers, 4 days)

---

### Extended (7 Workers) - **The Full Stack Pattern**
**Use case**: Complex features, complete coverage

```bash
WORKER_DEFINITIONS=(
    "architect|feat/v2.0-design|architect_TASKS.txt|Architecture & Design"
    "backend|feat/v2.0-api|backend_TASKS.txt|API Implementation"
    "frontend|feat/v2.0-ui|frontend_TASKS.txt|UI Implementation"
    "security|feat/v2.0-security|security_TASKS.txt|Security & Auth"
    "qa|feat/v2.0-testing|qa_TASKS.txt|Testing & Validation"
    "docs|feat/v2.0-documentation|docs_TASKS.txt|Documentation"
    "devops|feat/v2.0-infra|devops_TASKS.txt|Infrastructure"
)
```

**Timeline**: 5-7 days
**Best for**: Major features, production-critical systems

---

### Microservices (10+ Workers)
**Use case**: Multiple services, each worker = one service

```bash
WORKER_DEFINITIONS=(
    "svc-auth|feat/v3.0-auth-service|auth_TASKS.txt|Authentication Service"
    "svc-users|feat/v3.0-user-service|users_TASKS.txt|User Service"
    "svc-payments|feat/v3.0-payment-service|payments_TASKS.txt|Payment Service"
    "svc-notifications|feat/v3.0-notif-service|notif_TASKS.txt|Notification Service"
    "api-gateway|feat/v3.0-gateway|gateway_TASKS.txt|API Gateway"
    "shared-libs|feat/v3.0-shared|shared_TASKS.txt|Shared Libraries"
    "qa-integration|feat/v3.0-integration-tests|qa_int_TASKS.txt|Integration Testing"
    "qa-e2e|feat/v3.0-e2e-tests|qa_e2e_TASKS.txt|E2E Testing"
    "docs-api|feat/v3.0-api-docs|docs_api_TASKS.txt|API Documentation"
    "docs-arch|feat/v3.0-architecture|docs_arch_TASKS.txt|Architecture Docs"
    "devops-k8s|feat/v3.0-kubernetes|devops_k8s_TASKS.txt|Kubernetes Setup"
    "devops-monitoring|feat/v3.0-monitoring|devops_mon_TASKS.txt|Monitoring Setup"
)
```

**Timeline**: 7-10 days
**Best for**: Complex systems, platform work, v1 to v2 migrations

---

### Specialized Patterns

#### The "4+1+1" Pattern (SARK Gateway Example)
```
4 Engineers (models, API, policies, audit)
+ 1 QA
+ 1 Docs
= 6 workers total
```

#### The "3+3" Pattern (Frontend/Backend Split)
```
3 Frontend (components, state, styling)
+ 3 Backend (API, database, auth)
= 6 workers total
```

#### The "N+2" Pattern (Any Size)
```
N Engineers (core work)
+ 1 QA (testing)
+ 1 Docs (documentation)
= N+2 workers total
```

---

## 📛 Branch Naming Best Practices

### Always Include Version/Feature Identifier

**Bad**:
```bash
feat/backend
feat/testing
feat/docs
```

**Good**:
```bash
feat/v1.1-backend
feat/v1.1-testing
feat/v1.1-docs
```

**Better**:
```bash
feat/v1.1.0-backend
feat/v1.1.0-testing
feat/v1.1.0-docs
```

**Best** (descriptive):
```bash
feat/v1.1-gateway-backend
feat/v1.1-gateway-testing
feat/v1.1-gateway-docs
```

### Why Version Prefixes Matter

1. **Clarity**: Immediately know which feature/version branches belong to
2. **Git History**: Easy to filter branches by version
3. **PR Organization**: Group related PRs together
4. **Omnibus Naming**: Integration branch naturally named (e.g., `feat/v1.1-integration`)
5. **Parallel Versions**: Work on v1.1 and v2.0 simultaneously without confusion

### Common Patterns

**Semantic Versioning**:
- `feat/v1.2.0-*` - Full semver
- `feat/v1.2-*` - Minor version
- `feat/v1-*` - Major version

**Named Features**:
- `feat/auth-system-*` - By feature name
- `feat/gateway-integration-*` - By project name
- `feat/q4-2025-*` - By timeline

**SARK Example** (your pattern):
```bash
feat/gateway-client       # v1.1 Gateway Integration - Client
feat/gateway-api          # v1.1 Gateway Integration - API
feat/gateway-policies     # v1.1 Gateway Integration - Policies
# ...omnibus:
feat/gateway-integration  # v1.1 Gateway Integration - All combined
```

### Omnibus Branch Naming

The integration branch should match the feature identifier:

```bash
# If workers use v1.1-*:
export OMNIBUS_BRANCH="feat/v1.1-integration"

# If workers use gateway-*:
export OMNIBUS_BRANCH="feat/gateway-integration"

# If workers use auth-system-*:
export OMNIBUS_BRANCH="feat/auth-system-complete"
```

---

## 🎯 How to Choose

### Project Size Guide

| Workers | Project Complexity | Timeline | Cost |
|---------|-------------------|----------|------|
| 2-3 | Simple | 1-2 days | $ |
| 4-6 | Medium | 3-5 days | $$ |
| 7-10 | Complex | 5-7 days | $$$ |
| 10+ | Very Complex | 7-10 days | $$$$ |

### Decision Matrix

**Use 3 workers when**:
- ✅ Single component/service
- ✅ Clear scope
- ✅ Low risk
- ✅ Tight budget

**Use 6 workers when**:
- ✅ Multiple components
- ✅ Full stack work
- ✅ Production feature
- ✅ Balanced coverage needed

**Use 10+ workers when**:
- ✅ Microservices architecture
- ✅ Platform work
- ✅ Multiple independent concerns
- ✅ Parallel scaling needed

---

## 👤 The +1 Worker (Czar/You)

**Don't forget**: The Czar (you) is effectively worker #N+1!

With 6 workers:
- Worker 1-6: Doing the work
- Worker 7: Czar (orchestrating)

The Czar can be:
- **Fully Autonomous** (90% autonomous mode)
- **Semi-Autonomous** (monitoring + occasional decisions)
- **Manual** (traditional orchestration)

---

## 🔧 Configuration Examples

### Minimal Example (2 Workers)
```bash
WORKER_DEFINITIONS=(
    "dev|feat/implementation|dev_TASKS.txt|Implementation"
    "qa|feat/testing|qa_TASKS.txt|Testing"
)
```

### Maximum Tested (12 Workers)
*(We haven't tested beyond 12, but it should work!)*

```bash
# 4 Backend engineers
# 4 Frontend engineers
# 2 QA engineers
# 1 Docs engineer
# 1 DevOps engineer
```

### Theoretical Limit
**Unlimited** - Czarina has no hardcoded worker limit. Constraints are:
- Your machine resources (each worker = 1 tmux session)
- API rate limits (if using Claude API)
- Git merge complexity (more workers = more merge coordination)

**Practical limit**: 20 workers
**Tested limit**: 12 workers
**Recommended**: 3-6 workers

---

## 🎭 Role Definitions

Common worker roles you can mix and match:

### Engineering Roles
- `backend` - API, services, business logic
- `frontend` - UI, components, state management
- `mobile` - Mobile app development
- `architect` - System design, architecture decisions
- `data` - Data pipelines, ETL, analytics
- `ml` - Machine learning, models, training
- `security` - Security, auth, encryption

### Quality Roles
- `qa` - General testing
- `qa-integration` - Integration tests
- `qa-e2e` - End-to-end tests
- `qa-performance` - Load/performance testing
- `qa-security` - Security testing

### Operations Roles
- `devops` - Deployment, CI/CD
- `sre` - Reliability, monitoring
- `infra` - Infrastructure, cloud resources

### Documentation Roles
- `docs` - User documentation
- `docs-api` - API reference
- `docs-arch` - Architecture documentation
- `docs-tutorial` - Tutorials, guides

---

## 💡 Pro Tips

### Start Small, Scale Up
1. Begin with 3 workers (dev, qa, docs)
2. If workers finish early, add more work
3. Next project, use 4-6 workers
4. Find your optimal number

### Balance Concerns
- Too few workers: Bottlenecks, slow progress
- Too many workers: Merge conflicts, coordination overhead
- Sweet spot: Usually 4-6 workers

### Consider Dependencies
Order workers by dependencies:
1. Shared/foundation work first (models, schemas)
2. Core implementation next (APIs, services)
3. Integration work (combining components)
4. Testing after implementation
5. Docs last (documents the finished product)

### Use Bonus Tasks
- Primary tasks: Core feature work
- Bonus tasks: Enhancements, cleanup, polish
- Workers finish primary → Czar assigns bonus
- Maximizes productivity, zero idle time

---

## 📈 Scaling Strategies

### Horizontal Scaling (More Workers)
```
3 workers → 6 workers → 10 workers
(more parallelism)
```

### Vertical Scaling (Bonus Tasks)
```
Primary tasks → Bonus tasks → Advanced features
(deeper work per worker)
```

### Hybrid Scaling (Both)
```
6 workers × 2 task levels = 12 total task-workers
(maximum productivity)
```

---

## 🎯 Real-World Examples

### Example 1: E-commerce Feature (6 workers)
- Engineer 1: Product catalog backend
- Engineer 2: Shopping cart frontend
- Engineer 3: Checkout flow
- QA: Order flow testing
- Docs: User guide
- DevOps: Payment gateway setup

### Example 2: Authentication System (4 workers)
- Engineer 1: Auth service + JWT
- Engineer 2: Login UI
- QA: Security testing
- Docs: Integration guide

### Example 3: Data Pipeline (8 workers)
- Engineer 1: Data ingestion
- Engineer 2: Transformation service
- Engineer 3: Data validation
- Engineer 4: Output connectors
- QA 1: Data quality tests
- QA 2: Performance tests
- Docs: Pipeline documentation
- DevOps: Airflow/orchestration

---

**Bottom Line**: Czarina scales from 2 to 20+ workers. Start with our proven 6-worker pattern, then adapt to your needs!

*The +1 is you (Czar). Always. 😎*
