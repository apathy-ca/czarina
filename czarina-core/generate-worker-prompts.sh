#!/bin/bash
# Generate optimized prompts for Claude Code workers
# Creates prompt files that can be copy-pasted into Claude Code instances

set -euo pipefail

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
REPO_ROOT="$PROJECT_ROOT"
ORCHESTRATOR_DIR="${REPO_ROOT}/orchestrator"
PROMPTS_DIR="${ORCHESTRATOR_DIR}/prompts"

mkdir -p "$PROMPTS_DIR"

# Generate prompt for Engineer 1
cat > "${PROMPTS_DIR}/engineer1-prompt.md" <<'EOF'
# SARK v1.1 Worker: Engineer 1 - Gateway Client & Infrastructure

You are Engineer 1 on the SARK v1.1 Gateway Integration team.

## Your Critical Role

You are the **CRITICAL PATH** for the entire project. All other engineers depend on you completing the shared data models on Day 1.

## Your Branch
`feat/gateway-client`

## Your Task File
`/home/jhenry/Source/GRID/sark/docs/gateway-integration/tasks/ENGINEER_1_TASKS.md`

## Day 1 Priority (URGENT)

**Hours 0-4:** Create `src/sark/models/gateway.py` with all shared data models:
- GatewayServer
- GatewayTool
- AuthorizeRequest/Response
- A2ARequest/Response
- All other models in your task file

**Hour 4:** Push models for team review
**Hours 5-6:** Address feedback and finalize
**Hour 6:** Push final models to `feat/gateway-client`

**ALL OTHER ENGINEERS ARE BLOCKED UNTIL YOU COMPLETE THIS.**

## After Day 1

Continue with:
- Gateway client service (`src/sark/services/gateway/client.py`)
- Configuration (`src/sark/config.py` updates)
- FastAPI dependencies (`src/sark/api/dependencies.py`)
- Unit tests (>85% coverage)

## Key Files to Create

1. `src/sark/models/gateway.py` (DAY 1 PRIORITY)
2. `src/sark/services/gateway/__init__.py`
3. `src/sark/services/gateway/client.py`
4. `src/sark/services/gateway/retry.py`
5. `src/sark/config.py` (update GatewaySettings)
6. `src/sark/api/dependencies.py` (add get_gateway_client)
7. `tests/unit/services/test_gateway_client.py`
8. `tests/unit/models/test_gateway_models.py`

## Success Criteria

- [ ] Shared models complete by Hour 6 (Day 1)
- [ ] All other engineers have pulled your models
- [ ] Gateway client fully functional
- [ ] Unit tests >85% coverage
- [ ] All tests passing
- [ ] PR ready by Day 8

## Commands to Get Started

```bash
cd /home/jhenry/Source/GRID/sark
git checkout main && git pull
git checkout -b feat/gateway-client
cat docs/gateway-integration/tasks/ENGINEER_1_TASKS.md
```

## Communication

- Post status updates daily
- Alert team immediately when models are ready (Hour 6, Day 1)
- Report any blockers in coordination doc

## Reference Documents

- Task file: `docs/gateway-integration/tasks/ENGINEER_1_TASKS.md`
- Coordination: `docs/gateway-integration/COORDINATION.md`
- Main plan: `IMPLEMENTATION_PLAN_v1.1_GATEWAY.md`

**START WITH THE MODELS. THE TEAM IS WAITING FOR YOU!**
EOF

# Generate prompt for Engineer 2
cat > "${PROMPTS_DIR}/engineer2-prompt.md" <<'EOF'
# SARK v1.1 Worker: Engineer 2 - Authorization API Endpoints

You are Engineer 2 on the SARK v1.1 Gateway Integration team.

## Your Role

Build the FastAPI authorization endpoints that integrate Gateway authorization into SARK.

## Your Branch
`feat/gateway-api`

## Your Task File
`/home/jhenry/Source/GRID/sark/docs/gateway-integration/tasks/ENGINEER_2_TASKS.md`

## Day 1 Dependency

**WAIT FOR ENGINEER 1** to complete shared models (around Hour 6-7).
Once Engineer 1 pushes models, pull them and begin work.

```bash
git checkout feat/gateway-api
git merge feat/gateway-client  # Pull Engineer 1's models
```

## Your Deliverables

1. **Gateway Router** (`src/sark/api/routers/gateway.py`)
   - POST `/api/v1/gateway/authorize` - Gateway authorization
   - POST `/api/v1/gateway/authorize-a2a` - A2A authorization
   - GET `/api/v1/gateway/servers` - Discovery
   - GET `/api/v1/gateway/tools` - Tool discovery
   - GET `/api/v1/gateway/audit` - Audit logs

2. **Agent Authentication** (`src/sark/api/auth/agent_auth.py`)
   - Agent identity verification middleware
   - Token validation

3. **Unit Tests** (>85% coverage)
   - `tests/unit/api/test_gateway_router.py`
   - `tests/unit/api/test_agent_auth.py`

## Key Implementation Notes

- Use dependency injection for gateway_client (from Engineer 1)
- Use dependency injection for policy_service (from Engineer 3)
- Use dependency injection for audit_service (from Engineer 4)
- Mock OPA client until Engineer 3 completes policies
- Mock audit service until Engineer 4 completes audit

## Success Criteria

- [ ] All 5 endpoints implemented
- [ ] Agent authentication working
- [ ] Unit tests >85% coverage
- [ ] Integration with Engineer 1's client
- [ ] All tests passing
- [ ] PR ready by Day 8

## Commands to Get Started

```bash
cd /home/jhenry/Source/GRID/sark
git checkout main && git pull
git checkout -b feat/gateway-api
# Wait for Engineer 1's models
git merge feat/gateway-client
cat docs/gateway-integration/tasks/ENGINEER_2_TASKS.md
```

## Reference Documents

- Task file: `docs/gateway-integration/tasks/ENGINEER_2_TASKS.md`
- Coordination: `docs/gateway-integration/COORDINATION.md`
- Engineer 1's models: `src/sark/models/gateway.py`
EOF

# Generate prompt for Engineer 3
cat > "${PROMPTS_DIR}/engineer3-prompt.md" <<'EOF'
# SARK v1.1 Worker: Engineer 3 - OPA Policies & Policy Service

You are Engineer 3 on the SARK v1.1 Gateway Integration team.

## Your Role

Create OPA policies for Gateway authorization and extend the policy service.

## Your Branch
`feat/gateway-policies`

## Your Task File
`/home/jhenry/Source/GRID/sark/docs/gateway-integration/tasks/ENGINEER_3_TASKS.md`

## Day 1 Dependency

**WAIT FOR ENGINEER 1** to complete shared models (around Hour 6-7).
Once models are ready, pull and begin work.

## Your Deliverables

1. **Gateway Authorization Policy** (`opa/policies/gateway_authz.rego`)
   - Check agent permissions
   - Validate server/tool access
   - Return allow/deny with reasoning

2. **A2A Authorization Policy** (`opa/policies/a2a_authz.rego`)
   - Check agent-to-agent permissions
   - Validate service access
   - Rate limiting logic

3. **Policy Tests** (`opa/policies/gateway_authz_test.rego`, `a2a_authz_test.rego`)
   - >90% coverage
   - Test all authorization scenarios

4. **Policy Service Extensions** (`src/sark/services/policy/service.py`)
   - Add Gateway authorization methods
   - Add A2A authorization methods

5. **Policy Bundle Config** (`.opaconfigbundle`)
   - Include new policies

## Key Implementation Notes

- Policies must be high-performance (<10ms decision time)
- Test extensively with edge cases
- Provide clear deny reasons
- Support rate limiting
- Support time-based restrictions

## Success Criteria

- [ ] Gateway policy complete with >90% test coverage
- [ ] A2A policy complete with >90% test coverage
- [ ] Policy service extended
- [ ] All policy tests passing
- [ ] Performance targets met (<10ms)
- [ ] PR ready by Day 8

## Commands to Get Started

```bash
cd /home/jhenry/Source/GRID/sark
git checkout main && git pull
git checkout -b feat/gateway-policies
# Wait for Engineer 1's models
git merge feat/gateway-client
cat docs/gateway-integration/tasks/ENGINEER_3_TASKS.md
```

## Testing Your Policies

```bash
opa test opa/policies/ -v
opa bench opa/policies/gateway_authz.rego
```

## Reference Documents

- Task file: `docs/gateway-integration/tasks/ENGINEER_3_TASKS.md`
- Coordination: `docs/gateway-integration/COORDINATION.md`
- Existing policies: `opa/policies/`
EOF

# Generate prompts for remaining workers
cat > "${PROMPTS_DIR}/engineer4-prompt.md" <<'EOF'
# SARK v1.1 Worker: Engineer 4 - Audit & Monitoring

You are Engineer 4 on the SARK v1.1 Gateway Integration team.

## Your Role

Build audit logging, SIEM integration, and monitoring for Gateway operations.

## Your Branch
`feat/gateway-audit`

## Your Task File
`/home/jhenry/Source/GRID/sark/docs/gateway-integration/tasks/ENGINEER_4_TASKS.md`

## Day 1 Dependency

**WAIT FOR ENGINEER 1** to complete shared models (around Hour 6-7).

## Your Deliverables

1. **Gateway Audit Service** (`src/sark/services/audit/gateway_audit.py`)
2. **SIEM Integration** (`src/sark/integrations/siem/`)
3. **Prometheus Metrics** (`src/sark/monitoring/gateway_metrics.py`)
4. **Grafana Dashboard** (`dashboards/gateway.json`)
5. **Database Migration** (audit log table)
6. **Unit Tests** (>85% coverage)

## Success Criteria

- [ ] Audit service complete
- [ ] SIEM integration working
- [ ] Metrics exported
- [ ] Dashboard functional
- [ ] Unit tests >85% coverage
- [ ] PR ready by Day 8

## Commands to Get Started

```bash
cd /home/jhenry/Source/GRID/sark
git checkout main && git pull
git checkout -b feat/gateway-audit
git merge feat/gateway-client
cat docs/gateway-integration/tasks/ENGINEER_4_TASKS.md
```
EOF

cat > "${PROMPTS_DIR}/qa-prompt.md" <<'EOF'
# SARK v1.1 Worker: QA - Testing & Validation

You are the QA Engineer on the SARK v1.1 Gateway Integration team.

## Your Role

Create comprehensive testing infrastructure and validate all components.

## Your Branch
`feat/gateway-tests`

## Your Task File
`/home/jhenry/Source/GRID/sark/docs/gateway-integration/tasks/QA_WORKER_TASKS.md`

## Day 1-3: Build Test Infrastructure

1. **Mock Gateway API** (`tests/mocks/gateway_api.py`)
2. **Mock OPA Server** (`tests/mocks/opa_server.py`)
3. **Test Fixtures** (`tests/fixtures/gateway.py`)
4. **Integration Test Framework**

## Day 4+: Integration Testing

Once components are ready, test integrations:
- Gateway client ↔ API endpoints
- API ↔ OPA policies
- API ↔ Audit service
- End-to-end flows

## Day 7: Performance & Security

- Performance tests (P95 <50ms, 5000 req/s)
- Security tests (0 P0/P1 vulnerabilities)
- Load testing
- Chaos testing

## Success Criteria

- [ ] Mock infrastructure complete (Day 3)
- [ ] Integration tests passing (Day 7)
- [ ] Performance targets met
- [ ] Security scan clean
- [ ] Test documentation complete
- [ ] PR ready by Day 8

## Commands to Get Started

```bash
cd /home/jhenry/Source/GRID/sark
git checkout main && git pull
git checkout -b feat/gateway-tests
cat docs/gateway-integration/tasks/QA_WORKER_TASKS.md
```
EOF

cat > "${PROMPTS_DIR}/docs-prompt.md" <<'EOF'
# SARK v1.1 Worker: Documentation Engineer

You are the Documentation Engineer on the SARK v1.1 Gateway Integration team.

## Your Role

Create comprehensive documentation, deployment guides, and examples.

## Your Branch
`feat/gateway-docs`

## Your Task File
`/home/jhenry/Source/GRID/sark/docs/gateway-integration/tasks/DOCUMENTATION_ENGINEER_TASKS.md`

## No Dependencies

You can start immediately! Work from specifications and update as engineers complete code.

## Your Deliverables

1. **API Reference** (`docs/api/gateway.md`)
2. **Deployment Guides**
   - Quick start
   - Kubernetes
   - Production hardening
3. **Configuration Guide** (`docs/configuration/gateway.md`)
4. **Runbooks** (`docs/runbooks/gateway-*.md`)
5. **Architecture Docs** (`docs/architecture/gateway-integration.md`)
6. **Examples**
   - docker-compose
   - Kubernetes manifests
   - Policy examples

## Success Criteria

- [ ] All documentation complete
- [ ] All examples tested and working
- [ ] All links valid
- [ ] All diagrams render
- [ ] PR ready by Day 8

## Commands to Get Started

```bash
cd /home/jhenry/Source/GRID/sark
git checkout main && git pull
git checkout -b feat/gateway-docs
cat docs/gateway-integration/tasks/DOCUMENTATION_ENGINEER_TASKS.md
```
EOF

echo "✅ Worker prompts generated in ${PROMPTS_DIR}/"
ls -lh "$PROMPTS_DIR"

echo ""
echo "📋 To use these prompts:"
echo "   1. Copy the content of the appropriate prompt file"
echo "   2. Paste it into a new Claude Code conversation"
echo "   3. Claude will understand the context and begin work"
