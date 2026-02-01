# Escalation Patterns

Knowing when to escalate from automated recovery to human intervention.

---

## Philosophy

**Good Escalation**:
- Knows its limits
- Escalates early when uncertain
- Provides context to humans
- Documents unresolved issues
- Learns from escalations

**Bad Escalation**:
- Tries everything before asking
- Escalates without context
- Makes unrecoverable changes first
- Doesn't document what was tried

---

## When to Escalate

### Immediate Escalation (No Retry)

**Escalate immediately for**:
- Data corruption detected
- Security issues (authentication bypass, unauthorized access)
- Compliance violations
- Unrecoverable errors (syntax errors, type errors)
- Configuration errors requiring human decision
- Ambiguous requirements

**Example**:
```python
async def process_payment(amount: float, account: str):
    """Process payment with security checks."""
    # Escalate on security issues
    if not await verify_account_ownership(account):
        await alert_security_team(
            severity="HIGH",
            issue="Unauthorized payment attempt",
            account=account
        )
        raise SecurityError("Account verification failed")

    # Escalate on suspicious activity
    if amount > LARGE_TRANSACTION_THRESHOLD:
        await request_manual_approval(amount, account)
        raise RequiresApprovalError("Large transaction requires approval")
```

### Escalate After Retry Exhausted

**Escalate when**:
- Maximum retry attempts reached
- All fallbacks failed
- Service down for extended period
- Circuit breaker repeatedly opening
- Resource exhaustion

**Example**:
```python
async def sync_data_with_escalation():
    """Sync data with escalation after retries."""
    max_attempts = 3

    for attempt in range(max_attempts):
        try:
            return await sync_data()
        except Exception as e:
            if attempt == max_attempts - 1:
                # Escalate after all retries failed
                await create_incident(
                    title="Data sync failed after retries",
                    description=f"Failed {max_attempts} attempts",
                    error=str(e),
                    severity="MEDIUM"
                )
                raise

            await asyncio.sleep(2 ** attempt)
```

### Escalate on Pattern Change

**Escalate when**:
- Error rate suddenly increases
- New error types appear
- Performance degrades unexpectedly
- Resource usage spikes

**Example**:
```python
class ErrorRateMonitor:
    def __init__(self):
        self.error_count = 0
        self.window_start = datetime.now()
        self.baseline_rate = 0.01  # 1% errors normal

    async def record_error(self, error: Exception):
        """Track errors and escalate on rate spike."""
        self.error_count += 1

        # Calculate error rate
        window_duration = (datetime.now() - self.window_start).total_seconds()
        error_rate = self.error_count / max(window_duration, 1)

        # Escalate if rate > 10x baseline
        if error_rate > self.baseline_rate * 10:
            await alert_on_call(
                severity="HIGH",
                message=f"Error rate spike: {error_rate:.2f}/s (baseline: {self.baseline_rate})",
                error_type=type(error).__name__
            )
```

---

## Automated vs. Manual Recovery

### Automated Recovery Suitable For

**Safe to automate**:
- Known error patterns with proven fixes
- Idempotent operations
- Service restarts (with safeguards)
- Cache clearing
- Resource cleanup
- Retry with backoff

**Example**:
```python
async def auto_recover_container(container_name: str):
    """Automatically recover failed container."""
    status = await docker.get_container_status(container_name)

    if status == "exited":
        logger.info(f"Auto-recovering {container_name}")
        await docker.start_container(container_name)
        await verify_container_health(container_name)
        return "recovered"

    if status == "unhealthy":
        logger.info(f"Restarting unhealthy {container_name}")
        await docker.restart_container(container_name)
        return "restarted"
```

### Manual Recovery Required For

**Requires human decision**:
- Data migration decisions
- Schema changes
- Breaking API changes
- Production deployment approvals
- Security incident response
- Architecture decisions

**Example**:
```python
async def handle_schema_conflict():
    """Schema changes require manual approval."""
    conflict = await detect_schema_conflict()

    if conflict:
        # Don't auto-migrate - could lose data
        await create_approval_request(
            title="Schema Migration Required",
            description=f"Conflicting schemas detected: {conflict}",
            options=[
                "Migrate with data preservation",
                "Recreate index (data loss)",
                "Manual resolution"
            ],
            approvers=["database-admin"]
        )
        raise SchemaConflictError("Manual approval required")
```

---

## Error Severity Classification

### Severity Levels

**CRITICAL** (Immediate escalation):
- Production outage
- Data loss
- Security breach
- Compliance violation

**HIGH** (Escalate within 15 minutes):
- Service degradation
- Repeated failures
- Resource exhaustion
- Error rate spike

**MEDIUM** (Escalate within 1 hour):
- Non-critical feature broken
- Performance degradation
- Elevated error rates
- Retry exhaustion

**LOW** (Log for review):
- Transient errors (recovered)
- Expected failures (rate limits)
- Non-critical warnings

**Example**:
```python
class IncidentManager:
    async def classify_and_escalate(self, error: Exception, context: dict):
        """Classify error severity and escalate appropriately."""
        severity = self._classify_severity(error, context)

        if severity == "CRITICAL":
            await self._page_on_call()
            await self._create_incident(severity, error, context)

        elif severity == "HIGH":
            await self._alert_team_channel()
            await self._create_incident(severity, error, context)

        elif severity == "MEDIUM":
            await self._create_ticket(error, context)

        else:  # LOW
            await self._log_error(error, context)

    def _classify_severity(self, error: Exception, context: dict) -> str:
        """Classify error severity."""
        # Critical: Data or security issues
        if isinstance(error, (DataCorruptionError, SecurityError)):
            return "CRITICAL"

        # Critical: Production outage
        if context.get("environment") == "production" and \
           isinstance(error, ServiceUnavailableError):
            return "CRITICAL"

        # High: Repeated failures
        if context.get("retry_count", 0) >= 3:
            return "HIGH"

        # Medium: Known recoverable errors
        if isinstance(error, (ConnectionError, TimeoutError)):
            return "MEDIUM"

        return "LOW"
```

---

## Providing Context for Escalation

### Essential Context

**Always include**:
- Error message and stack trace
- What was attempted (including retries)
- Current state of system
- Impact on users/services
- Relevant configuration
- Recent changes

**Example**:
```python
async def escalate_with_context(
    error: Exception,
    attempted_fixes: list[str],
    system_state: dict
):
    """Escalate with comprehensive context."""
    context = {
        "error": {
            "type": type(error).__name__,
            "message": str(error),
            "traceback": traceback.format_exc()
        },
        "recovery_attempts": attempted_fixes,
        "system_state": system_state,
        "environment": os.getenv("ENVIRONMENT"),
        "timestamp": datetime.now().isoformat(),
        "recent_changes": await get_recent_deployments(),
        "affected_services": await get_dependent_services(),
        "user_impact": await estimate_user_impact()
    }

    await create_incident(
        title=f"{type(error).__name__} requiring manual intervention",
        severity="HIGH",
        context=context
    )
```

---

## Documentation of Unresolved Issues

### Issue Documentation Template

**What to document**:
```python
async def document_unresolved_issue(error: Exception, context: dict):
    """Document issue for future reference."""
    issue = {
        "timestamp": datetime.now().isoformat(),
        "error_type": type(error).__name__,
        "error_message": str(error),

        # What happened
        "scenario": context.get("scenario"),
        "trigger": context.get("trigger"),

        # What was tried
        "attempted_fixes": context.get("attempted_fixes", []),
        "retry_count": context.get("retry_count", 0),

        # Why it failed
        "root_cause": context.get("root_cause", "Unknown"),
        "blockers": context.get("blockers", []),

        # Current state
        "system_state": context.get("system_state"),
        "workarounds": context.get("workarounds", []),

        # Next steps
        "requires": context.get("requires", "Manual investigation"),
        "assignee": context.get("assignee"),
        "priority": context.get("priority", "MEDIUM")
    }

    await save_to_knowledge_base(issue)
    return issue
```

---

## Learning from Escalations

### Post-Escalation Analysis

**After resolution**:
1. Document what worked
2. Update automation if applicable
3. Add to known error patterns
4. Improve detection
5. Update runbooks

**Example**:
```python
async def post_incident_review(incident_id: str):
    """Learn from escalation and improve automation."""
    incident = await get_incident(incident_id)

    if incident.resolution_method == "manual":
        # Check if we can automate this
        if incident.is_automatable():
            await create_automation_task(
                title=f"Automate recovery for {incident.error_type}",
                description=f"Manual fix: {incident.resolution}",
                priority="HIGH"
            )

        # Update error patterns
        await update_error_patterns({
            "pattern": incident.error_pattern,
            "automated_recovery": incident.is_automatable(),
            "manual_steps": incident.resolution_steps
        })

    # Update runbooks
    await update_runbook(
        error_type=incident.error_type,
        detection=incident.detection_method,
        recovery=incident.resolution
    )
```

---

## Real-World Examples

### The Symposium: Service Health Escalation

```python
class ServiceHealthMonitor:
    async def check_and_escalate(self, service_name: str):
        """Monitor service health and escalate issues."""
        health = await self.check_health(service_name)

        if health.status == "unhealthy":
            if health.consecutive_failures < 3:
                # Try auto-recovery
                logger.warning(f"{service_name} unhealthy, attempting recovery")
                await self.auto_recover(service_name)
            else:
                # Escalate after repeated failures
                await self.escalate_to_team(
                    service=service_name,
                    issue="Service repeatedly unhealthy",
                    failures=health.consecutive_failures,
                    last_error=health.last_error
                )
```

---

## Best Practices

### Do's

- Escalate early when uncertain
- Provide comprehensive context
- Document attempted solutions
- Classify severity appropriately
- Learn from escalations
- Update automation based on manual fixes

### Don'ts

- Don't escalate everything (reduces signal)
- Don't try every possible fix first
- Don't escalate without context
- Don't forget to document resolution
- Don't repeat manual fixes (automate them)

---

## Related Patterns

- [Detection Patterns](./detection-patterns.md) - What to escalate
- [Retry Patterns](./retry-patterns.md) - When retries become escalations
- [Fallback Patterns](./fallback-patterns.md) - Fallback before escalation

---

**Source**: The Symposium development (v0.4.5)
