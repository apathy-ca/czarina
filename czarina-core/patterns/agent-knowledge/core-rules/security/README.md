# Security Best Practices for Agent Development

## Overview

This directory contains comprehensive security documentation for developing secure AI agent systems. The guidelines are extracted from production implementations in **SARK** (Symposium Agent Rules and Knowledge) and **thesymposium**, providing battle-tested patterns and practices.

## Security Documentation

### 1. [AUTHENTICATION.md](./AUTHENTICATION.md)

**Verifying Identity**

Covers authentication mechanisms for users, services, and agents:
- **JWT (JSON Web Tokens)**: Token-based authentication with access/refresh tokens
- **API Keys**: Service-to-service authentication with scoped permissions
- **Session Management**: Web session handling with security best practices
- **OAuth 2.0 / OpenID Connect**: Third-party authentication and SSO
- **Multi-Factor Authentication (MFA)**: TOTP, SMS, email verification

**Key Topics**:
- Token generation and validation
- Session lifecycle management
- CSRF protection for OAuth flows
- Secure cookie configuration
- Authentication vulnerabilities and mitigations

### 2. [AUTHORIZATION.md](./AUTHORIZATION.md)

**Controlling Access**

Covers authorization mechanisms using Open Policy Agent (OPA):
- **Role-Based Access Control (RBAC)**: Permission assignment by roles
- **Attribute-Based Access Control (ABAC)**: Context-aware policy decisions
- **Resource Ownership**: Team-based and user-based access control
- **Agent-to-Agent (A2A) Authorization**: Inter-agent communication policies
- **Policy Caching**: Performance optimization with sensitivity-based TTL

**Key Topics**:
- Policy evaluation flow
- OPA integration patterns
- Resource filtering by permissions
- Batch policy evaluation
- Authorization vulnerabilities (IDOR, privilege escalation)

### 3. [SECRET_MANAGEMENT.md](./SECRET_MANAGEMENT.md)

**Protecting Credentials**

Covers secure handling of secrets and credentials:
- **Environment Variables**: Configuration management with .env files
- **Encryption at Rest**: Fernet (AES-128) encryption for stored secrets
- **Secret Scanning**: Detecting accidentally exposed secrets
- **Secret Rotation**: Key rotation strategies and procedures
- **CI/CD Secrets**: GitHub Actions, Docker secrets, cloud secret managers

**Key Topics**:
- Never hardcode credentials
- Encryption key management
- AWS Secrets Manager / HashiCorp Vault integration
- What NOT to do (anti-patterns)
- Secret recovery procedures

### 4. [INJECTION_PREVENTION.md](./INJECTION_PREVENTION.md)

**Detecting and Preventing Attacks**

Covers injection attack prevention, especially prompt injection:
- **Prompt Injection Detection**: 20+ pattern-based detection rules
- **Risk Scoring System**: 0-100 risk scores with configurable thresholds
- **Response Actions**: BLOCK, ALERT, LOG based on risk level
- **SQL Injection Prevention**: Parameterized queries and ORM usage
- **Path Traversal Protection**: Safe file access patterns
- **Code Execution Prevention**: Avoiding eval/exec with user input

**Key Topics**:
- Instruction override detection
- Role manipulation prevention
- Data exfiltration blocking
- Encoding/obfuscation detection
- Automatic response handling

### 5. [AUDIT_LOGGING.md](./AUDIT_LOGGING.md)

**Recording Security Events**

Covers comprehensive audit logging for accountability and compliance:
- **TimescaleDB Architecture**: Time-series audit event storage
- **Event Types**: Authentication, authorization, tool invocation, security violations
- **SIEM Integration**: Splunk, Datadog, ELK forwarding
- **Compliance Requirements**: SOC 2, GDPR, HIPAA, PCI-DSS
- **Performance Optimization**: Batch forwarding, retry logic, circuit breakers

**Key Topics**:
- What to log (completeness)
- Immutable storage (integrity)
- Sensitive data redaction (confidentiality)
- SIEM forwarding strategies
- Retention policies

## Security Principles

### Defense in Depth

**Multiple Layers of Security**:
1. **Network Layer**: Firewalls, VPNs, network segmentation
2. **Application Layer**: Input validation, output encoding, CSRF tokens
3. **Authentication Layer**: MFA, strong passwords, session management
4. **Authorization Layer**: RBAC, ABAC, least privilege
5. **Data Layer**: Encryption at rest, encryption in transit
6. **Monitoring Layer**: Audit logging, SIEM, anomaly detection

### Fail Secure (Default Deny)

**Deny by Default, Allow Explicitly**:
- Authorization: Deny unless policy explicitly allows
- Authentication: Reject invalid tokens, expired sessions
- Injection Detection: Block high-risk patterns
- Error Handling: Return generic errors, log details

### Zero Trust

**Never Trust, Always Verify**:
- Authenticate every request
- Authorize every action
- Validate all input
- Encrypt all data in transit
- Monitor all activity

### Least Privilege

**Minimal Required Access**:
- Grant minimum permissions needed
- Scope API keys to specific actions
- Time-limit access tokens (15-30 minutes)
- Revoke access when no longer needed

## Threat Model

### Common Threats

1. **Credential Theft**
   - **Attack**: Stealing API keys, passwords, tokens
   - **Mitigation**: Encryption, secret scanning, rotation

2. **Unauthorized Access**
   - **Attack**: Bypassing authentication/authorization
   - **Mitigation**: MFA, policy enforcement, audit logging

3. **Prompt Injection**
   - **Attack**: Manipulating AI behavior through malicious prompts
   - **Mitigation**: Pattern detection, risk scoring, input validation

4. **Data Exfiltration**
   - **Attack**: Extracting sensitive data to external endpoints
   - **Mitigation**: Domain whitelisting, secret scanning, monitoring

5. **Privilege Escalation**
   - **Attack**: Elevating permissions beyond granted level
   - **Mitigation**: RBAC, policy validation, audit logging

6. **Session Hijacking**
   - **Attack**: Stealing or reusing valid sessions
   - **Mitigation**: Secure cookies, IP binding, session fingerprinting

7. **SQL Injection**
   - **Attack**: Manipulating database queries
   - **Mitigation**: Parameterized queries, ORM, input validation

8. **Code Injection**
   - **Attack**: Executing arbitrary code
   - **Mitigation**: Avoid eval/exec, sandboxed execution, input validation

## Security Checklist

### Authentication
- [ ] Use strong authentication methods (JWT, OAuth, MFA)
- [ ] Implement short-lived access tokens (15-30 minutes)
- [ ] Use HTTPS for all authentication endpoints
- [ ] Set secure cookie flags (HttpOnly, Secure, SameSite)
- [ ] Implement rate limiting on authentication endpoints
- [ ] Log all authentication events (success and failure)

### Authorization
- [ ] Use centralized authorization system (OPA)
- [ ] Implement default deny (fail closed) policies
- [ ] Validate authorization on every request
- [ ] Filter resources based on user permissions
- [ ] Log all authorization decisions
- [ ] Test cross-tenant isolation

### Secret Management
- [ ] Store all secrets in environment variables or secret managers
- [ ] Encrypt secrets at rest using strong encryption (AES-256)
- [ ] Implement secret scanning in CI/CD pipelines
- [ ] Rotate secrets regularly (30-180 days)
- [ ] Redact secrets from logs and error messages
- [ ] Use SSL/TLS for all secret transmission

### Injection Prevention
- [ ] Validate and sanitize all user inputs
- [ ] Use parameterized queries for SQL (never concatenation)
- [ ] Implement prompt injection detection on LLM inputs
- [ ] Set risk thresholds for automated responses
- [ ] Log all injection attempts
- [ ] Test with known attack patterns

### Audit Logging
- [ ] Log all authentication events
- [ ] Log all authorization decisions
- [ ] Log all security violations
- [ ] Use UTC timestamps
- [ ] Redact secrets and PII before logging
- [ ] Forward high-severity events to SIEM
- [ ] Implement log retention policies

## Implementation Guide

### Quick Start

1. **Authentication**: Start with JWT-based authentication
   ```python
   from sark.services.auth.jwt import JWTHandler

   jwt_handler = JWTHandler(
       secret_key=settings.secret_key,
       access_token_expire_minutes=30,
   )

   access_token = jwt_handler.create_access_token(
       user_id=user.id,
       email=user.email,
       role=user.role,
   )
   ```

2. **Authorization**: Integrate OPA for policy decisions
   ```python
   from sark.services.policy.opa_client import OPAClient

   opa_client = OPAClient()

   decision = await opa_client.evaluate_policy(
       AuthorizationInput(
           user={"id": user.id, "role": user.role},
           action="tool:invoke",
           tool={"name": "database_query", "sensitivity_level": "high"},
           context={},
       )
   )

   if not decision.allow:
       raise HTTPException(status_code=403, detail=decision.reason)
   ```

3. **Secret Management**: Use Fernet encryption
   ```python
   from sark.services.encryption import KeyEncryption

   encryption = KeyEncryption()

   # Encrypt before storage
   encrypted_key = encryption.encrypt(api_key)
   await db.save_api_key(user_id, encrypted_key)

   # Decrypt when needed
   api_key = encryption.decrypt(encrypted_key)
   ```

4. **Injection Detection**: Scan all LLM inputs
   ```python
   from sark.security.injection_detector import PromptInjectionDetector

   detector = PromptInjectionDetector()

   result = detector.detect(
       parameters=request.parameters,
       context={"user_id": user.id},
   )

   if result.risk_score >= 70:
       raise HTTPException(status_code=403, detail="Injection detected")
   ```

5. **Audit Logging**: Log all security events
   ```python
   from sark.services.audit import AuditService

   audit_service = AuditService(db)

   await audit_service.log_authorization_decision(
       user_id=user.id,
       user_email=user.email,
       tool_name=request.tool_name,
       decision="allow" if decision.allow else "deny",
       ip_address=request.client.host,
   )
   ```

### Integration Example

**Complete Secure Tool Invocation**:

```python
@router.post("/tools/invoke")
async def invoke_tool(
    request: ToolInvocationRequest,
    user: UserContext = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Securely invoke a tool with full security checks."""

    # 1. Injection Detection
    detector = PromptInjectionDetector()
    detection_result = detector.detect(request.parameters)

    if detection_result.risk_score >= 70:
        # Log security violation
        await audit_service.log_security_violation(
            user_id=user.user_id,
            violation_type="prompt_injection",
            details={"risk_score": detection_result.risk_score},
        )
        raise HTTPException(status_code=403, detail="Injection detected")

    # 2. Authorization Check
    decision = await opa_client.evaluate_policy(
        AuthorizationInput(
            user={"id": str(user.user_id), "role": user.role},
            action="tool:invoke",
            tool={"name": request.tool_name, "sensitivity_level": "medium"},
            context={},
        )
    )

    # 3. Log Authorization Decision
    await audit_service.log_authorization_decision(
        user_id=user.user_id,
        user_email=user.email,
        tool_name=request.tool_name,
        decision="allow" if decision.allow else "deny",
        ip_address=request.client.host,
    )

    if not decision.allow:
        raise HTTPException(status_code=403, detail=decision.reason)

    # 4. Redact Secrets from Parameters
    scanner = SecretScanner()
    safe_parameters = scanner.redact_secrets(request.parameters)

    # 5. Log Tool Invocation
    await audit_service.log_tool_invocation(
        user_id=user.user_id,
        user_email=user.email,
        server_id=request.server_id,
        tool_name=request.tool_name,
        parameters=safe_parameters,
        ip_address=request.client.host,
    )

    # 6. Invoke Tool
    result = await invoke_tool_safely(request)

    return result
```

## Common Vulnerabilities

### OWASP Top 10 for LLM Applications

1. **LLM01: Prompt Injection** → See [INJECTION_PREVENTION.md](./INJECTION_PREVENTION.md)
2. **LLM02: Insecure Output Handling** → See [INJECTION_PREVENTION.md](./INJECTION_PREVENTION.md)
3. **LLM03: Training Data Poisoning** → Not applicable to agent development
4. **LLM04: Model Denial of Service** → Rate limiting, resource quotas
5. **LLM05: Supply Chain Vulnerabilities** → Dependency scanning, SBOMs
6. **LLM06: Sensitive Information Disclosure** → See [SECRET_MANAGEMENT.md](./SECRET_MANAGEMENT.md)
7. **LLM07: Insecure Plugin Design** → See [AUTHORIZATION.md](./AUTHORIZATION.md)
8. **LLM08: Excessive Agency** → Least privilege, approval workflows
9. **LLM09: Overreliance** → Human-in-the-loop for critical actions
10. **LLM10: Model Theft** → API rate limiting, authentication

## Compliance Frameworks

### SOC 2 Type II
- **Controls**: Access control, encryption, audit logging, change management
- **Evidence**: Audit logs, authorization policies, authentication records
- **Documents**: [AUTHENTICATION.md](./AUTHENTICATION.md), [AUTHORIZATION.md](./AUTHORIZATION.md), [AUDIT_LOGGING.md](./AUDIT_LOGGING.md)

### GDPR
- **Requirements**: Data minimization, consent management, right to erasure, data breach notification
- **Implementation**: PII redaction, audit logging, secret management
- **Documents**: [SECRET_MANAGEMENT.md](./SECRET_MANAGEMENT.md), [AUDIT_LOGGING.md](./AUDIT_LOGGING.md)

### HIPAA
- **Requirements**: PHI encryption, access controls, audit trails, BAA agreements
- **Implementation**: Encryption at rest/transit, authorization, comprehensive logging
- **Documents**: [SECRET_MANAGEMENT.md](./SECRET_MANAGEMENT.md), [AUTHORIZATION.md](./AUTHORIZATION.md)

### PCI-DSS
- **Requirements**: Cardholder data encryption, access restriction, logging, vulnerability management
- **Implementation**: Encryption, RBAC, audit logging, injection prevention
- **Documents**: All security documents

## Additional Resources

### SARK Implementation References
- **SARK Repository**: Production-grade security implementations
- **thesymposium**: Authentication service and encryption utilities
- **OpenSearch Integration**: Credential storage with encryption

### External References
- **OWASP**: https://owasp.org/
- **NIST Cybersecurity Framework**: https://www.nist.gov/cyberframework
- **OWASP LLM Top 10**: https://owasp.org/www-project-top-10-for-large-language-model-applications/
- **Open Policy Agent**: https://www.openpolicyagent.org/
- **OWASP Cheat Sheet Series**: https://cheatsheetseries.owasp.org/

## Getting Help

### Security Issues
If you discover a security vulnerability:
1. **DO NOT** open a public GitHub issue
2. Report to security team via secure channel
3. Provide detailed description and reproduction steps
4. Allow time for investigation and patching

### Questions
For security-related questions:
- Review relevant documentation in this directory
- Consult SARK implementation examples
- Refer to OWASP guidelines
- Seek security team review for critical implementations

## License

These security guidelines are extracted from production systems and provided for educational and implementation reference. Adapt and customize based on your specific security requirements and threat model.

## Version

**Version**: 1.0
**Last Updated**: 2025-01-26
**Extracted From**: SARK (Symposium Agent Rules and Knowledge) and thesymposium
**Compliance**: SOC 2, GDPR, HIPAA, PCI-DSS considerations included
