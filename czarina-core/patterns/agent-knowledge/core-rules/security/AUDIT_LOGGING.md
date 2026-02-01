# Audit Logging

## Overview

Audit logging is the systematic recording of security-relevant events for accountability, forensic analysis, compliance, and threat detection. Comprehensive audit logs provide visibility into who did what, when, where, and why—enabling detection of security incidents, investigation of breaches, and demonstration of compliance with regulations. This document outlines security best practices for implementing robust audit logging in agent systems, extracted from production implementations in SARK.

## Core Principles

### Completeness
- **Log All Security Events**: Authentication, authorization, access, modifications
- **Include Context**: User, resource, action, timestamp, result, IP address
- **Capture Failures**: Failed login attempts, denied access, validation errors
- **System Events**: Configuration changes, server registration, policy updates

### Integrity
- **Immutable Storage**: Use append-only databases (TimescaleDB, write-once storage)
- **Tamper Detection**: Cryptographic signatures or checksums
- **Time Synchronization**: Use UTC timestamps with timezone awareness
- **Retention Policies**: Define retention periods based on compliance requirements

### Confidentiality
- **Access Controls**: Restrict audit log access to authorized personnel
- **Sensitive Data Handling**: Redact secrets, PII before logging
- **Encryption**: Encrypt audit logs at rest and in transit
- **Separation**: Store audit logs separately from application databases

### Availability
- **Reliable Storage**: Use fault-tolerant storage with backups
- **SIEM Integration**: Forward high-priority events to SIEM for real-time analysis
- **Performance**: Async logging to avoid blocking application threads
- **Monitoring**: Alert on logging failures or gaps

## Audit Architecture

### TimescaleDB for Time-Series Audit Data

**Use Case**: Store high-volume audit events with time-based queries and retention

**Implementation** (from `/home/jhenry/Source/sark/src/sark/models/audit.py`):

```python
class AuditEventType(str, Enum):
    """Audit event type enumeration."""

    SERVER_REGISTERED = "server_registered"
    SERVER_UPDATED = "server_updated"
    SERVER_DECOMMISSIONED = "server_decommissioned"
    TOOL_INVOKED = "tool_invoked"
    AUTHORIZATION_ALLOWED = "authorization_allowed"
    AUTHORIZATION_DENIED = "authorization_denied"
    POLICY_CREATED = "policy_created"
    POLICY_UPDATED = "policy_updated"
    POLICY_ACTIVATED = "policy_activated"
    USER_LOGIN = "user_login"
    USER_LOGOUT = "user_logout"
    SECURITY_VIOLATION = "security_violation"


class SeverityLevel(str, Enum):
    """Event severity level."""

    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class AuditEvent(Base):
    """Audit event model stored in TimescaleDB."""

    __tablename__ = "audit_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)

    # Temporal (TimescaleDB hypertable partitioned on this column)
    timestamp = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
        index=True
    )

    # Event classification
    event_type = Column(SQLEnum(AuditEventType), nullable=False, index=True)
    severity = Column(SQLEnum(SeverityLevel), nullable=False, default=SeverityLevel.LOW)

    # Actor information (WHO)
    user_id = Column(UUID(as_uuid=True), nullable=True, index=True)
    user_email = Column(String(255), nullable=True)

    # Subject information (WHAT)
    server_id = Column(UUID(as_uuid=True), nullable=True, index=True)
    tool_name = Column(String(255), nullable=True, index=True)

    # Authorization decision (RESULT)
    decision = Column(String(20), nullable=True)  # "allow" or "deny"
    policy_id = Column(UUID(as_uuid=True), nullable=True)

    # Context (WHERE/HOW)
    ip_address = Column(String(45), nullable=True)  # IPv6 max length
    user_agent = Column(String(500), nullable=True)
    request_id = Column(String(100), nullable=True, index=True)

    # Flexible details storage (WHY)
    details = Column(JSON, nullable=False, default=dict)

    # Retention metadata
    siem_forwarded = Column(DateTime(timezone=True), nullable=True)
```

**Key Features**:
- **Time-series partitioning**: Efficient queries by time range
- **Indexed columns**: Fast filtering by user, server, tool, request_id
- **JSON details**: Flexible storage for event-specific data
- **SIEM tracking**: Record when events forwarded to external SIEM

**TimescaleDB Hypertable Setup**:

```sql
-- Create hypertable partitioned by timestamp
SELECT create_hypertable('audit_events', 'timestamp');

-- Create retention policy (30 days)
SELECT add_retention_policy('audit_events', INTERVAL '30 days');

-- Create compression policy (events older than 7 days)
ALTER TABLE audit_events SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'event_type, severity'
);

SELECT add_compression_policy('audit_events', INTERVAL '7 days');

-- Create continuous aggregates for dashboards
CREATE MATERIALIZED VIEW audit_events_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', timestamp) AS hour,
    event_type,
    severity,
    decision,
    COUNT(*) as event_count
FROM audit_events
GROUP BY hour, event_type, severity, decision;
```

## Audit Service Implementation

### Core Logging Service

**Implementation** (from `/home/jhenry/Source/sark/src/sark/services/audit/audit_service.py`):

```python
class AuditService:
    """Service for capturing and processing audit events."""

    def __init__(self, db: AsyncSession) -> None:
        """Initialize audit service with TimescaleDB session."""
        self.db = db

    async def log_event(
        self,
        event_type: AuditEventType,
        severity: SeverityLevel = SeverityLevel.LOW,
        user_id: UUID | None = None,
        user_email: str | None = None,
        server_id: UUID | None = None,
        tool_name: str | None = None,
        decision: str | None = None,
        policy_id: UUID | None = None,
        ip_address: str | None = None,
        user_agent: str | None = None,
        request_id: str | None = None,
        details: dict[str, Any] | None = None,
    ) -> AuditEvent:
        """
        Log an audit event to TimescaleDB.

        Args:
            event_type: Type of audit event
            severity: Event severity level
            user_id: User ID associated with event
            user_email: User email
            server_id: MCP server ID
            tool_name: Tool name for tool invocations
            decision: Authorization decision (allow/deny)
            policy_id: Policy ID used for decision
            ip_address: Client IP address
            user_agent: Client user agent
            request_id: Request correlation ID
            details: Additional event details

        Returns:
            Created audit event
        """
        event = AuditEvent(
            timestamp=datetime.now(UTC),
            event_type=event_type,
            severity=severity,
            user_id=user_id,
            user_email=user_email,
            server_id=server_id,
            tool_name=tool_name,
            decision=decision,
            policy_id=policy_id,
            ip_address=ip_address,
            user_agent=user_agent,
            request_id=request_id,
            details=details or {},
        )

        self.db.add(event)
        await self.db.commit()
        await self.db.refresh(event)

        logger.info(
            "audit_event_logged",
            event_id=str(event.id),
            event_type=event_type,
            severity=severity,
            user_id=str(user_id) if user_id else None,
        )

        # If high severity, trigger SIEM forwarding
        if severity in (SeverityLevel.HIGH, SeverityLevel.CRITICAL):
            await self._forward_to_siem(event)

        return event
```

### Specialized Logging Methods

#### 1. Authorization Decisions

**Use Case**: Log all authorization allow/deny decisions

```python
async def log_authorization_decision(
    self,
    user_id: UUID,
    user_email: str,
    tool_name: str,
    decision: str,
    policy_id: UUID | None = None,
    server_id: UUID | None = None,
    ip_address: str | None = None,
    request_id: str | None = None,
    details: dict[str, Any] | None = None,
) -> AuditEvent:
    """Log an authorization decision (allow or deny)."""
    event_type = (
        AuditEventType.AUTHORIZATION_ALLOWED
        if decision == "allow"
        else AuditEventType.AUTHORIZATION_DENIED
    )

    severity = SeverityLevel.MEDIUM if decision == "deny" else SeverityLevel.LOW

    return await self.log_event(
        event_type=event_type,
        severity=severity,
        user_id=user_id,
        user_email=user_email,
        server_id=server_id,
        tool_name=tool_name,
        decision=decision,
        policy_id=policy_id,
        ip_address=ip_address,
        request_id=request_id,
        details=details,
    )
```

**What to Log**:
- User attempting access
- Resource being accessed (tool, server)
- Policy that made the decision
- Decision result (allow/deny)
- Reason for denial (if denied)
- IP address and user agent

**Example Usage**:

```python
# In authorization middleware
decision = await opa_client.evaluate_policy(auth_input)

await audit_service.log_authorization_decision(
    user_id=user.user_id,
    user_email=user.email,
    tool_name=request.tool_name,
    decision="allow" if decision.allow else "deny",
    policy_id=policy.id,
    server_id=request.server_id,
    ip_address=request.client.host,
    request_id=request.headers.get("X-Request-ID"),
    details={
        "reason": decision.reason,
        "risk_score": decision.risk_score if hasattr(decision, "risk_score") else None,
    },
)
```

#### 2. Tool Invocations

**Use Case**: Log all tool invocation attempts

```python
async def log_tool_invocation(
    self,
    user_id: UUID,
    user_email: str,
    server_id: UUID,
    tool_name: str,
    parameters: dict[str, Any] | None = None,
    ip_address: str | None = None,
    request_id: str | None = None,
) -> AuditEvent:
    """
    Log a tool invocation event.

    Note: Sensitive data in parameters should be filtered before logging.
    """
    return await self.log_event(
        event_type=AuditEventType.TOOL_INVOKED,
        severity=SeverityLevel.LOW,
        user_id=user_id,
        user_email=user_email,
        server_id=server_id,
        tool_name=tool_name,
        ip_address=ip_address,
        request_id=request_id,
        details={"parameters": parameters} if parameters else {},
    )
```

**Sensitive Parameter Filtering**:

```python
from sark.security.secret_scanner import SecretScanner

scanner = SecretScanner()

# Filter sensitive data before logging
parameters_safe = scanner.redact_secrets(request.parameters)

await audit_service.log_tool_invocation(
    user_id=user.user_id,
    user_email=user.email,
    server_id=request.server_id,
    tool_name=request.tool_name,
    parameters=parameters_safe,  # Redacted version
    ip_address=request.client.host,
    request_id=request_id,
)
```

#### 3. Security Violations

**Use Case**: Log prompt injection, unauthorized access, anomalies

```python
async def log_security_violation(
    self,
    user_id: UUID | None,
    user_email: str | None,
    violation_type: str,
    ip_address: str | None = None,
    details: dict[str, Any] | None = None,
) -> AuditEvent:
    """
    Log a security violation event.

    Args:
        violation_type: Type of security violation
            (e.g., "prompt_injection", "unauthorized_access", "rate_limit_exceeded")
    """
    return await self.log_event(
        event_type=AuditEventType.SECURITY_VIOLATION,
        severity=SeverityLevel.CRITICAL,
        user_id=user_id,
        user_email=user_email,
        ip_address=ip_address,
        details={"violation_type": violation_type, **(details or {})},
    )
```

**Example - Prompt Injection Detection**:

```python
# After detecting prompt injection
if detection_result.risk_score >= block_threshold:
    await audit_service.log_security_violation(
        user_id=user.user_id,
        user_email=user.email,
        violation_type="prompt_injection",
        ip_address=request.client.host,
        details={
            "risk_score": detection_result.risk_score,
            "patterns_detected": [f.pattern_name for f in detection_result.findings],
            "tool_name": request.tool_name,
            "action": "blocked",
            "request_id": request_id,
        },
    )
```

#### 4. Server Registration

**Use Case**: Log when new MCP servers are registered

```python
async def log_server_registration(
    self,
    user_id: UUID,
    user_email: str,
    server_id: UUID,
    server_name: str,
    details: dict[str, Any] | None = None,
) -> AuditEvent:
    """Log MCP server registration."""
    return await self.log_event(
        event_type=AuditEventType.SERVER_REGISTERED,
        severity=SeverityLevel.MEDIUM,
        user_id=user_id,
        user_email=user_email,
        server_id=server_id,
        details={"server_name": server_name, **(details or {})},
    )
```

## SIEM Integration

### Architecture

**Purpose**: Forward high-priority audit events to Security Information and Event Management (SIEM) systems for real-time correlation, alerting, and compliance.

**Supported SIEM Platforms**:
- Splunk
- Datadog
- Elasticsearch (ELK Stack)
- AWS CloudWatch
- Azure Sentinel

**Base SIEM Interface** (from `/home/jhenry/Source/sark/src/sark/services/audit/siem/base.py`):

```python
class SIEMConfig(BaseModel):
    """Base SIEM configuration."""

    enabled: bool = Field(default=True, description="Enable SIEM forwarding")
    verify_ssl: bool = Field(default=True, description="Verify SSL certificates")
    timeout_seconds: int = Field(default=30, ge=1, le=120)
    batch_size: int = Field(default=100, ge=1, le=1000)
    batch_timeout_seconds: int = Field(default=5, ge=1, le=60)
    retry_attempts: int = Field(default=3, ge=0, le=10)
    retry_backoff_base: float = Field(default=2.0, ge=1.0, le=10.0)
    retry_backoff_max: float = Field(default=60.0, ge=1.0, le=300.0)


class BaseSIEM(ABC):
    """Abstract base class for SIEM integrations."""

    def __init__(self, config: SIEMConfig) -> None:
        self.config = config
        self.metrics = SIEMMetrics()

    @abstractmethod
    async def send_event(self, event: AuditEvent) -> bool:
        """Send a single audit event to the SIEM."""
        pass

    @abstractmethod
    async def send_batch(self, events: list[AuditEvent]) -> bool:
        """Send a batch of audit events to the SIEM."""
        pass

    @abstractmethod
    async def health_check(self) -> SIEMHealth:
        """Check connectivity and health of the SIEM."""
        pass

    @abstractmethod
    def format_event(self, event: AuditEvent) -> dict[str, Any]:
        """Format an audit event for the specific SIEM."""
        pass
```

### Performance Features

**Batch Processing**:
- Group events into batches (default: 100 events)
- Flush batches on timeout (default: 5 seconds)
- Reduces network overhead and SIEM indexing load

**Retry Logic**:
- Exponential backoff (base: 2.0, max: 60 seconds)
- Configurable retry attempts (default: 3)
- Dead letter queue (DLQ) for failed events

**Circuit Breaker**:
- Opens after consecutive failures
- Prevents cascading failures
- Half-open state for gradual recovery

**Metrics Collection**:
```python
@dataclass
class SIEMMetrics:
    """Metrics for SIEM operations."""

    events_sent: int = 0
    events_failed: int = 0
    batches_sent: int = 0
    batches_failed: int = 0
    total_latency_ms: float = 0.0
    retry_count: int = 0
    last_success: datetime | None = None
    last_failure: datetime | None = None
    error_counts: dict[str, int] = field(default_factory=dict)

    @property
    def success_rate(self) -> float:
        """Calculate success rate as a percentage."""
        total = self.events_sent + self.events_failed
        if total == 0:
            return 0.0
        return (self.events_sent / total) * 100.0

    @property
    def average_latency_ms(self) -> float:
        """Calculate average latency."""
        if self.batches_sent == 0:
            return 0.0
        return self.total_latency_ms / self.batches_sent
```

### Forwarding Strategy

**Severity-Based Forwarding**:

```python
async def _forward_to_siem(self, event: AuditEvent) -> None:
    """Forward high-priority events to SIEM."""
    # Only forward HIGH and CRITICAL severity events
    if event.severity not in (SeverityLevel.HIGH, SeverityLevel.CRITICAL):
        return

    try:
        # Format event for SIEM
        formatted_event = siem.format_event(event)

        # Send asynchronously (non-blocking)
        asyncio.create_task(siem.send_event(formatted_event))

        # Mark as forwarded
        event.siem_forwarded = datetime.now(UTC)
        await self.db.commit()

    except Exception as e:
        logger.error(
            "siem_forwarding_failed",
            event_id=str(event.id),
            error=str(e),
        )
```

**Batch Forwarding** (for lower-priority events):

```python
# Background task to forward batches
async def forward_audit_batch():
    """Background task to forward audit events in batches."""
    while True:
        try:
            # Fetch events not yet forwarded to SIEM
            events = await db.query(AuditEvent).filter(
                AuditEvent.siem_forwarded.is_(None),
                AuditEvent.timestamp > datetime.now(UTC) - timedelta(hours=1),
            ).limit(100).all()

            if events:
                # Send batch
                success = await siem.send_batch(events)

                if success:
                    # Mark events as forwarded
                    for event in events:
                        event.siem_forwarded = datetime.now(UTC)
                    await db.commit()

        except Exception as e:
            logger.error("batch_forward_failed", error=str(e))

        # Wait before next batch
        await asyncio.sleep(60)
```

## What to Log

### Authentication Events

**Events**:
- Successful login
- Failed login attempts
- Password changes
- MFA enrollment/verification
- Session creation/destruction
- Logout

**Required Fields**:
- User ID and email
- Timestamp
- IP address
- User agent
- Authentication method (password, OAuth, API key)
- Success/failure reason

**Example**:
```python
await audit_service.log_event(
    event_type=AuditEventType.USER_LOGIN,
    severity=SeverityLevel.LOW,
    user_id=user.user_id,
    user_email=user.email,
    ip_address=request.client.host,
    user_agent=request.headers.get("User-Agent"),
    details={
        "auth_method": "oauth_gitlab",
        "mfa_verified": True,
    },
)
```

### Authorization Events

**Events**:
- Access granted
- Access denied
- Permission changes
- Role assignments
- Policy evaluations

**Required Fields**:
- User ID
- Resource (tool, server)
- Action attempted
- Decision (allow/deny)
- Policy ID
- Reason

### Data Access Events

**Events**:
- Tool invocations
- Database queries
- File access
- API calls
- Export operations

**Required Fields**:
- User ID
- Resource accessed
- Operation type (read, write, delete)
- Parameters (redacted)
- Result status

### Configuration Changes

**Events**:
- Server registration/updates
- Policy creation/modification
- User management
- System settings changes

**Required Fields**:
- User making change
- Resource changed
- Before/after values (redacted)
- Change reason (if provided)

### Security Events

**Events**:
- Prompt injection detected
- Unauthorized access attempts
- Suspicious patterns
- Rate limit violations
- Anomalous behavior

**Required Fields**:
- User ID (if known)
- Violation type
- Risk score
- Detection patterns
- Response action (blocked, alerted)

## Compliance Requirements

### SOC 2 Type II

**Requirements**:
- Log access to sensitive data
- Track authorization decisions
- Record configuration changes
- Retain logs for 1 year minimum
- Implement tamper-proof storage

**Audit Events**:
- All authentication attempts
- Authorization decisions
- Administrative actions
- Security violations

### GDPR

**Requirements**:
- Log access to personal data
- Track data subject requests (access, deletion)
- Record consent management
- Implement right to erasure for user data (not audit logs)

**Privacy Considerations**:
- Redact PII from logs (except user IDs)
- Anonymize logs after retention period
- Separate audit logs from operational logs

### HIPAA

**Requirements**:
- Log all PHI access
- Track who accessed what, when
- Audit log encryption at rest and in transit
- 6-year retention minimum
- Regular audit log reviews

### PCI-DSS

**Requirements**:
- Log all access to cardholder data
- Track privileged user actions
- Daily log review
- 1-year retention (3 months immediately available)
- Tamper-proof audit trail

## Audit Log Checklist

- [ ] Log all authentication events (success and failure)
- [ ] Log all authorization decisions (allow and deny)
- [ ] Log all tool invocations with parameters (redacted)
- [ ] Log all configuration changes
- [ ] Log all security violations
- [ ] Use UTC timestamps for all events
- [ ] Include request correlation IDs
- [ ] Redact secrets and PII before logging
- [ ] Store logs in immutable storage (TimescaleDB, S3)
- [ ] Implement log retention policies (30-365 days)
- [ ] Forward high-severity events to SIEM
- [ ] Monitor audit logging failures
- [ ] Restrict audit log access to authorized personnel
- [ ] Encrypt audit logs at rest and in transit
- [ ] Test audit log queries and analysis
- [ ] Document audit log schema and retention policies
- [ ] Implement automated alerting on critical events
- [ ] Perform regular audit log reviews

## References

- **SARK Audit Service**: `/home/jhenry/Source/sark/src/sark/services/audit/audit_service.py`
- **SARK Audit Models**: `/home/jhenry/Source/sark/src/sark/models/audit.py`
- **SARK SIEM Base**: `/home/jhenry/Source/sark/src/sark/services/audit/siem/base.py`
- **OWASP Logging Cheat Sheet**: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- **NIST SP 800-92**: Guide to Computer Security Log Management
- **TimescaleDB**: https://www.timescale.com/

## Next Steps

- Review **AUTHENTICATION.md** for logging authentication events
- Review **AUTHORIZATION.md** for logging authorization decisions
- Review **INJECTION_PREVENTION.md** for logging security violations
- Review **SECRET_MANAGEMENT.md** for redacting secrets from logs
