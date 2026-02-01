# Authorization Security

## Overview

Authorization determines what authenticated users, services, and agents are allowed to do. While authentication verifies identity, authorization controls access to resources and operations. This document outlines security best practices for implementing robust authorization mechanisms in agent systems, extracted from production implementations in SARK.

## Core Principles

### Fail Secure (Default Deny)
- **Explicit Allow**: Resources are denied by default unless explicitly allowed by policy
- **Error Handling**: Deny access when policy evaluation fails or encounters errors
- **Missing Policies**: Treat undefined policies as denial

### Least Privilege
- **Minimal Permissions**: Grant only the minimum permissions needed for a task
- **Scope Limitation**: Restrict access to specific resources and operations
- **Time-Based Access**: Limit permission duration when appropriate

### Separation of Duties
- **Policy Engine Separation**: Use dedicated policy engine (Open Policy Agent)
- **Centralized Decisions**: Centralize authorization logic, avoid scattered checks
- **Audit Independence**: Audit logging separate from authorization decisions

### Defense in Depth
- **Multiple Checks**: Validate at gateway, middleware, and service layers
- **Context-Aware**: Consider user, resource, action, and environmental context
- **Dynamic Evaluation**: Re-evaluate permissions on each request

## Authorization Architecture

### Open Policy Agent (OPA) Integration

SARK uses **Open Policy Agent** as an external policy decision point, following the Policy-as-Code model.

**Architecture** (from `/home/jhenry/Source/sark/src/sark/services/policy/opa_client.py:41-70`):

```python
class OPAClient:
    """Client for interacting with Open Policy Agent."""

    def __init__(
        self,
        opa_url: str | None = None,
        timeout: float | None = None,
        cache: PolicyCache | None = None,
        cache_enabled: bool = True,
    ) -> None:
        self.opa_url = opa_url or settings.opa_url
        self.timeout = timeout or settings.opa_timeout_seconds
        self.policy_path = settings.opa_policy_path
        self.client = httpx.AsyncClient(timeout=self.timeout)

        # Initialize cache for performance
        if cache:
            self.cache = cache
        else:
            self.cache = get_policy_cache(enabled=cache_enabled)
```

**Benefits of OPA**:
- Decouples authorization logic from application code
- Enables policy updates without code deployment
- Provides a declarative policy language (Rego)
- Supports complex, context-aware decisions
- Facilitates compliance auditing

### Policy Evaluation Flow

1. **Request Context Assembly**: Gather user, action, resource, and context
2. **Cache Check**: Check if decision is cached (95%+ hit rate)
3. **OPA Query**: Query OPA with policy input if cache miss
4. **Decision Processing**: Extract allow/deny, reason, and filtered parameters
5. **Cache Update**: Cache decision with sensitivity-based TTL
6. **Audit Logging**: Log authorization decision (separate from this flow)

**Implementation** (from `opa_client.py:75-186`):

```python
async def evaluate_policy(
    self,
    auth_input: AuthorizationInput,
    use_cache: bool = True,
) -> AuthorizationDecision:
    """
    Evaluate authorization policy via OPA with caching.
    """
    user_id = auth_input.user.get("id", "unknown")
    action = auth_input.action

    # Determine resource identifier
    resource = "unknown"
    if auth_input.tool:
        resource = f"tool:{auth_input.tool.get('name', 'unknown')}"
    elif auth_input.server:
        resource = f"server:{auth_input.server.get('name', 'unknown')}"

    # Get sensitivity for cache optimization
    sensitivity = self._get_sensitivity(auth_input)

    # Try cache first
    if use_cache and self.cache.enabled:
        cached_decision = await self.cache.get(
            user_id=user_id,
            action=action,
            resource=resource,
            context=auth_input.context,
            sensitivity=sensitivity,
        )

        if cached_decision:
            return AuthorizationDecision(**cached_decision)

    # Cache miss - query OPA
    try:
        response = await self.client.post(
            f"{self.opa_url}{self.policy_path}",
            json={"input": auth_input.model_dump()},
        )
        response.raise_for_status()

        result = response.json()
        policy_result = result.get("result", {})

        decision = AuthorizationDecision(
            allow=policy_result.get("allow", False),
            reason=policy_result.get("audit_reason", "Policy evaluation completed"),
            filtered_parameters=policy_result.get("filtered_parameters"),
            audit_id=policy_result.get("audit_id"),
        )

        # Cache the decision
        if use_cache and self.cache.enabled:
            ttl_seconds = self._get_cache_ttl(auth_input)
            await self.cache.set(
                user_id=user_id,
                action=action,
                resource=resource,
                decision=decision.model_dump(),
                context=auth_input.context,
                ttl_seconds=ttl_seconds,
            )

        return decision

    except httpx.HTTPError as e:
        logger.error("opa_request_failed", error=str(e))
        # Fail closed - deny on error
        return AuthorizationDecision(
            allow=False,
            reason=f"Policy evaluation failed: {e!s}",
        )
```

## Authorization Patterns

### 1. Role-Based Access Control (RBAC)

**Use Case**: Assign permissions based on user roles

**Policy Structure**:

```rego
package mcp.gateway

import future.keywords.in

# Define roles and their capabilities
role_permissions := {
    "admin": ["*"],
    "developer": ["tool:invoke", "tool:list", "server:register", "server:list"],
    "user": ["tool:invoke", "tool:list"],
    "viewer": ["tool:list", "server:list"],
}

# Check if user's role has permission for action
allow {
    user_role := input.user.role
    action := input.action

    # Admin has all permissions
    user_role == "admin"
}

allow {
    user_role := input.user.role
    action := input.action
    permissions := role_permissions[user_role]

    # Check if action is in role's permissions
    action in permissions
}

allow {
    user_role := input.user.role
    permissions := role_permissions[user_role]

    # Wildcard permission grants all access
    "*" in permissions
}
```

**Implementation** (from `authorization.py:27-113`):

```python
async def authorize_gateway_request(
    user: UserContext,
    request: GatewayAuthorizationRequest,
) -> GatewayAuthorizationResponse:
    """Authorize Gateway request via OPA policy evaluation."""
    try:
        # Build OPA input
        opa_input = {
            "user": {
                "id": str(user.user_id),
                "roles": user.roles,
                "permissions": user.permissions,
                "email": user.email,
            },
            "action": request.action,
            "resource": {
                "server": request.server_name,
                "tool": request.tool_name,
                "sensitivity": request.sensitivity_level.value if request.sensitivity_level else "medium",
            },
            "parameters": request.parameters or {},
            "context": request.context or {},
        }

        # Query OPA
        opa_result = await evaluate_policy(
            policy_path="/v1/data/mcp/gateway/allow",
            input_data=opa_input,
        )

        # Extract decision
        allow = opa_result.get("result", {}).get("allow", False)
        reason = opa_result.get("result", {}).get("reason", "Policy evaluation completed")
        filtered_params = opa_result.get("result", {}).get("filtered_parameters")

        # Calculate cache TTL based on sensitivity
        cache_ttl = _get_cache_ttl(request.sensitivity_level)

        return GatewayAuthorizationResponse(
            allow=allow,
            reason=reason,
            filtered_parameters=filtered_params,
            cache_ttl=cache_ttl,
        )

    except Exception as e:
        logger.error("gateway_authorization_error", error=str(e))
        # Fail closed - deny on error
        return GatewayAuthorizationResponse(
            allow=False,
            reason=f"Authorization error: {e!s}",
            cache_ttl=0,
        )
```

### 2. Attribute-Based Access Control (ABAC)

**Use Case**: Make decisions based on attributes of user, resource, and environment

**Policy Example**:

```rego
package mcp.gateway

# Allow if user is owner of the resource
allow {
    input.user.id == input.resource.owner_id
}

# Allow if user is in a team that manages the resource
allow {
    user_teams := input.user.teams
    resource_teams := input.resource.managed_by_teams

    some team in user_teams
    team in resource_teams
}

# Allow high-sensitivity tools only during business hours
allow {
    input.resource.sensitivity_level == "high"
    input.user.role == "admin"

    # Check time constraint
    current_hour := time.clock(input.context.timestamp)[0]
    current_hour >= 8
    current_hour < 18
}

# Deny critical operations from untrusted networks
deny {
    input.resource.sensitivity_level == "critical"
    input.context.network_zone == "untrusted"
}
```

**Sensitivity-Based Access**:

```python
def _get_cache_ttl(sensitivity_level: SensitivityLevel | None) -> int:
    """
    Calculate cache TTL based on sensitivity level.
    Higher sensitivity = shorter cache TTL for dynamic re-evaluation.
    """
    if not sensitivity_level:
        return 300  # 5 minutes default

    ttl_map = {
        SensitivityLevel.PUBLIC: 3600,      # 1 hour
        SensitivityLevel.LOW: 1800,         # 30 minutes
        SensitivityLevel.MEDIUM: 300,       # 5 minutes
        SensitivityLevel.HIGH: 60,          # 1 minute
        SensitivityLevel.CRITICAL: 0,       # No caching
    }

    return ttl_map.get(sensitivity_level, 300)
```

### 3. Resource Ownership & Team-Based Access

**Policy Pattern**:

```rego
# Resource ownership check
is_resource_owner {
    input.user.id == input.resource.owner_id
}

# Team membership check
is_team_member {
    user_teams := input.user.teams
    resource_team := input.resource.team_id
    resource_team in user_teams
}

# Team manager check
is_team_manager {
    user_teams := input.user.teams
    managed_teams := input.resource.managed_by_teams

    some team in user_teams
    team in managed_teams
}

# Allow resource owners
allow {
    is_resource_owner
}

# Allow team members for read operations
allow {
    is_team_member
    input.action in ["read", "list"]
}

# Allow team managers for all operations
allow {
    is_team_manager
}
```

### 4. Agent-to-Agent (A2A) Authorization

**Use Case**: Control agent-to-agent communication and delegation

**Implementation** (from `authorization.py:116-206`):

```python
async def authorize_a2a_request(
    agent_context: AgentContext,
    request: A2AAuthorizationRequest,
) -> GatewayAuthorizationResponse:
    """Authorize agent-to-agent communication request."""
    try:
        # Enforce A2A-specific restrictions
        restriction_result = await _enforce_a2a_restrictions(agent_context, request)
        if not restriction_result["allow"]:
            return GatewayAuthorizationResponse(
                allow=False,
                reason=restriction_result["reason"],
                cache_ttl=0,
            )

        # Build OPA input for A2A authorization
        opa_input = {
            "source_agent": {
                "id": agent_context.agent_id,
                "type": agent_context.agent_type.value,
                "trust_level": agent_context.trust_level.value,
                "capabilities": agent_context.capabilities,
                "environment": agent_context.environment,
            },
            "target_agent": {
                "id": request.target_agent_id,
                "environment": request.target_environment,
            },
            "capability": request.capability,
            "parameters": request.parameters or {},
            "context": request.context or {},
        }

        # Query OPA for A2A authorization
        opa_result = await evaluate_policy(
            policy_path="/v1/data/mcp/a2a/allow",
            input_data=opa_input,
        )

        # Extract decision
        allow = opa_result.get("result", {}).get("allow", False)
        reason = opa_result.get("result", {}).get("reason", "A2A policy evaluation completed")

        # A2A requests get lower cache TTL for security
        cache_ttl = 60  # 1 minute

        return GatewayAuthorizationResponse(
            allow=allow,
            reason=reason,
            cache_ttl=cache_ttl,
        )

    except Exception as e:
        # Fail closed - deny on error
        return GatewayAuthorizationResponse(
            allow=False,
            reason=f"A2A authorization error: {e!s}",
            cache_ttl=0,
        )
```

**A2A Restrictions** (from `authorization.py:364-410`):

```python
async def _enforce_a2a_restrictions(
    agent_context: AgentContext,
    request: A2AAuthorizationRequest,
) -> dict[str, Any]:
    """
    Enforce A2A-specific restrictions.

    Restrictions:
    - Cross-environment communication (untrusted agents cannot cross environments)
    - Trust level validation
    - Capability checks
    """
    from sark.models.gateway import TrustLevel

    # Block cross-environment for untrusted agents
    if agent_context.trust_level == TrustLevel.UNTRUSTED:
        if agent_context.environment != request.target_environment:
            return {
                "allow": False,
                "reason": "Untrusted agents cannot communicate across environments",
            }

    # Check if agent has required capability
    if request.capability not in agent_context.capabilities:
        return {
            "allow": False,
            "reason": f"Agent lacks required capability: {request.capability}",
        }

    # Prevent delegation chains (agents calling agents calling agents)
    if request.context and request.context.get("delegation_depth", 0) > 2:
        return {
            "allow": False,
            "reason": "Maximum delegation depth exceeded",
        }

    return {
        "allow": True,
        "reason": "A2A restrictions passed",
    }
```

**A2A Policy Pattern**:

```rego
package mcp.a2a

# Trust level matrix
trust_levels := {
    "trusted": 3,
    "verified": 2,
    "sandboxed": 1,
    "untrusted": 0,
}

# Allow communication if source has equal or higher trust
allow {
    source_trust := trust_levels[input.source_agent.trust_level]
    target_trust := trust_levels[input.target_agent.trust_level]
    source_trust >= target_trust
}

# Allow if source has required capability
allow {
    input.capability in input.source_agent.capabilities
}

# Deny cross-environment for untrusted agents
deny {
    input.source_agent.trust_level == "untrusted"
    input.source_agent.environment != input.target_agent.environment
}
```

## Resource Filtering

### Server Filtering by Permission

**Use Case**: Show users only servers they can access

**Implementation** (from `authorization.py:208-270`):

```python
async def filter_servers_by_permission(
    user: UserContext,
    servers: list[GatewayServerInfo],
) -> list[GatewayServerInfo]:
    """
    Filter servers by user permissions.
    Batch evaluates OPA policies to determine which servers user can access.
    """
    try:
        authorized_servers = []

        for server in servers:
            # Build OPA input for server access
            opa_input = {
                "user": {
                    "id": str(user.user_id),
                    "roles": user.roles,
                    "permissions": user.permissions,
                },
                "action": "list",
                "resource": {
                    "type": "server",
                    "server": server.name,
                },
            }

            # Query OPA
            opa_result = await evaluate_policy(
                policy_path="/v1/data/mcp/gateway/allow",
                input_data=opa_input,
            )

            if opa_result.get("result", {}).get("allow", False):
                authorized_servers.append(server)

        logger.info(
            "servers_filtered_by_permission",
            total_servers=len(servers),
            authorized_servers=len(authorized_servers),
        )

        return authorized_servers

    except Exception as e:
        logger.error("server_filtering_error", error=str(e))
        # Fail closed - return empty list on error
        return []
```

### Tool Filtering by Permission

**Use Case**: Show users only tools they can invoke

**Implementation** (from `authorization.py:272-337`):

```python
async def filter_tools_by_permission(
    user: UserContext,
    tools: list[GatewayToolInfo],
) -> list[GatewayToolInfo]:
    """
    Filter tools by user permissions.
    Batch evaluates OPA policies to determine which tools user can invoke.
    """
    try:
        authorized_tools = []

        for tool in tools:
            # Build OPA input for tool access
            opa_input = {
                "user": {
                    "id": str(user.user_id),
                    "roles": user.roles,
                    "permissions": user.permissions,
                },
                "action": "invoke",
                "resource": {
                    "type": "tool",
                    "server": tool.server_name,
                    "tool": tool.name,
                    "sensitivity": tool.sensitivity_level.value if tool.sensitivity_level else "medium",
                },
            }

            # Query OPA
            opa_result = await evaluate_policy(
                policy_path="/v1/data/mcp/gateway/allow",
                input_data=opa_input,
            )

            if opa_result.get("result", {}).get("allow", False):
                authorized_tools.append(tool)

        return authorized_tools

    except Exception as e:
        logger.error("tool_filtering_error", error=str(e))
        # Fail closed - return empty list on error
        return []
```

## Performance Optimization

### Policy Decision Caching

**Cache Strategy**:
- **95%+ hit rate** target for common operations
- **Sensitivity-based TTL**: More sensitive = shorter cache
- **Stale-while-revalidate**: Serve stale while refreshing in background

**TTL Configuration** (from `opa_client.py:187-212`):

```python
def _get_cache_ttl(self, auth_input: AuthorizationInput) -> int:
    """Determine cache TTL based on request context."""
    sensitivity = self._get_sensitivity(auth_input)

    # Use optimized TTL settings
    if hasattr(self.cache, "use_optimized_ttl") and self.cache.use_optimized_ttl:
        return self.cache.OPTIMIZED_TTL.get(sensitivity, self.cache.OPTIMIZED_TTL["default"])

    # Fallback to legacy TTL settings
    ttl_map = {
        "critical": 60,
        "confidential": 120,
        "internal": 180,
        "public": 300,
    }
    return ttl_map.get(sensitivity, 120)
```

### Batch Evaluation

**Use Case**: Evaluate multiple authorization requests in parallel

**Implementation** (from `opa_client.py:297-414`):

```python
async def evaluate_policy_batch(
    self,
    auth_inputs: list[AuthorizationInput],
    use_cache: bool = True,
) -> list[AuthorizationDecision]:
    """
    Evaluate multiple authorization policies in a batch using Redis pipelining.

    This significantly reduces latency for bulk operations by:
    1. Checking cache for all requests in a single Redis round-trip
    2. Evaluating cache misses in parallel via OPA
    3. Caching results in a single Redis round-trip
    """
    if not auth_inputs:
        return []

    # Extract cache lookup parameters
    cache_requests = []
    for auth_input in auth_inputs:
        user_id = auth_input.user.get("id", "unknown")
        action = auth_input.action

        resource = "unknown"
        if auth_input.tool:
            resource = f"tool:{auth_input.tool.get('name', 'unknown')}"
        elif auth_input.server:
            resource = f"server:{auth_input.server.get('name', 'unknown')}"

        cache_requests.append((user_id, action, resource, auth_input.context))

    # Batch cache lookup
    cached_decisions = []
    if use_cache and self.cache.enabled and hasattr(self.cache, "get_batch"):
        cached_decisions = await self.cache.get_batch(cache_requests)
    else:
        cached_decisions = [None] * len(auth_inputs)

    # Identify cache misses
    misses = []
    miss_indices = []
    for i, cached_decision in enumerate(cached_decisions):
        if cached_decision is None:
            misses.append(auth_inputs[i])
            miss_indices.append(i)

    # Evaluate cache misses in parallel
    if misses:
        tasks = [self._evaluate_opa_policy(auth_input) for auth_input in misses]
        miss_results = await asyncio.gather(*tasks, return_exceptions=True)

        # Process results and cache them
        cache_entries = []
        for i, result in enumerate(miss_results):
            if isinstance(result, Exception):
                miss_decisions.append(
                    AuthorizationDecision(
                        allow=False,
                        reason=f"Evaluation error: {result!s}",
                    )
                )
            else:
                miss_decisions.append(result)

        # Batch cache update
        if use_cache and hasattr(self.cache, "set_batch"):
            await self.cache.set_batch(cache_entries)

    # Combine cached and fresh results
    decisions = []
    miss_iter = iter(miss_decisions)

    for cached_decision in cached_decisions:
        if cached_decision is None:
            decisions.append(next(miss_iter))
        else:
            decisions.append(AuthorizationDecision(**cached_decision))

    logger.info(
        "batch_policy_evaluation",
        total=len(auth_inputs),
        cache_hits=len(auth_inputs) - len(misses),
        cache_misses=len(misses),
        hit_rate=round(((len(auth_inputs) - len(misses)) / len(auth_inputs)) * 100, 2),
    )

    return decisions
```

### Cache Invalidation

**Scenarios Requiring Invalidation**:
- User role/permission changes
- Policy updates
- Resource ownership changes
- Team membership changes

**Implementation** (from `opa_client.py:555-576`):

```python
async def invalidate_cache(
    self,
    user_id: str | None = None,
    action: str | None = None,
    resource: str | None = None,
) -> int:
    """
    Invalidate cached policy decisions.

    Args:
        user_id: Invalidate for specific user (or all if None)
        action: Invalidate for specific action (or all if None)
        resource: Invalidate for specific resource (or all if None)

    Returns:
        Number of cache entries invalidated
    """
    return await self.cache.invalidate(
        user_id=user_id,
        action=action,
        resource=resource,
    )
```

## Common Authorization Vulnerabilities

### 1. Insecure Direct Object References (IDOR)

**Problem**: Accessing resources by ID without authorization check

**Mitigation**:
```python
# BAD: No authorization check
@router.get("/servers/{server_id}")
async def get_server(server_id: UUID):
    return await db.get_server(server_id)

# GOOD: Authorization before access
@router.get("/servers/{server_id}")
async def get_server(
    server_id: UUID,
    user: UserContext = Depends(get_current_user)
):
    # Check if user can access this specific server
    server = await db.get_server(server_id)

    decision = await opa_client.evaluate_policy(
        AuthorizationInput(
            user={"id": str(user.user_id), "role": user.role},
            action="server:read",
            server={"id": str(server_id), "owner_id": str(server.owner_id)},
            context={},
        )
    )

    if not decision.allow:
        raise HTTPException(status_code=403, detail=decision.reason)

    return server
```

### 2. Missing Authorization Checks

**Problem**: Implementing authentication but forgetting authorization

**Mitigation**:
- Use dependency injection to enforce authorization
- Apply authorization middleware globally
- Audit code for direct database access without checks

### 3. Privilege Escalation

**Problem**: Users can elevate their own privileges

**Mitigation**:
```rego
# Prevent users from modifying their own roles
deny {
    input.action == "user:update_role"
    input.user.id == input.resource.target_user_id
}

# Only admins can grant admin role
deny {
    input.action == "user:update_role"
    input.resource.new_role == "admin"
    input.user.role != "admin"
}
```

### 4. Confused Deputy Problem

**Problem**: Service performs action on behalf of user without proper delegation

**Mitigation**:
- Pass original user context through service calls
- Validate delegation chains
- Limit delegation depth
- Audit delegation paths

## Authorization Checklist

- [ ] Use centralized authorization system (OPA or similar)
- [ ] Implement default deny (fail closed) for all policies
- [ ] Validate authorization on every request, never cache user context
- [ ] Use sensitivity-based cache TTL for performance
- [ ] Implement batch evaluation for listing operations
- [ ] Filter resources based on user permissions before returning
- [ ] Log all authorization decisions with user and resource context
- [ ] Invalidate cache when roles/permissions change
- [ ] Test authorization with different user roles
- [ ] Test cross-tenant isolation (users can't access other tenants' data)
- [ ] Test privilege escalation attempts
- [ ] Document authorization policies in version control
- [ ] Monitor authorization denial rates for anomalies
- [ ] Implement circuit breaker for OPA failures
- [ ] Support both RBAC and ABAC patterns as needed

## References

- **SARK Gateway Authorization**: `/home/jhenry/Source/sark/src/sark/services/gateway/authorization.py`
- **SARK OPA Client**: `/home/jhenry/Source/sark/src/sark/services/policy/opa_client.py`
- **Open Policy Agent**: https://www.openpolicyagent.org/
- **OWASP Authorization Cheat Sheet**: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- **NIST ABAC Guide**: https://csrc.nist.gov/publications/detail/sp/800-162/final

## Next Steps

- Review **AUTHENTICATION.md** for verifying user identity
- Review **AUDIT_LOGGING.md** for tracking authorization decisions
- Review **INJECTION_PREVENTION.md** for securing policy inputs
