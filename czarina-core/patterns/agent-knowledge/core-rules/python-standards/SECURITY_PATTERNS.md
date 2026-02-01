# Python Security Patterns

**Source:** Extracted from [SARK](https://github.com/sark) codebase analysis
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This document establishes security patterns for Python applications based on SARK's implementation. These patterns cover input validation, authentication, authorization, secret management, and security middleware to protect against common vulnerabilities.

## Input Validation with Pydantic

### Request Validation

Use Pydantic models for automatic input validation:

```python
from pydantic import BaseModel, Field, field_validator
from uuid import UUID

class ServerRegistrationRequest(BaseModel):
    """Server registration request with comprehensive validation.

    Pydantic automatically validates:
    - Type correctness
    - Field constraints (min/max length, patterns)
    - Required vs optional fields
    """

    name: str = Field(
        ...,
        min_length=1,
        max_length=255,
        description="Server name",
    )
    transport: str = Field(
        ...,
        pattern="^(http|stdio|sse)$",
        description="Transport protocol",
    )
    endpoint: str | None = Field(
        None,
        max_length=500,
        description="Server endpoint URL",
    )
    capabilities: list[str] = Field(
        default_factory=list,
        max_length=100,
        description="List of capability names",
    )
    metadata: dict[str, str] = Field(
        default_factory=dict,
        description="Additional metadata",
    )

    @field_validator("endpoint")
    @classmethod
    def validate_endpoint(cls, v: str | None, info) -> str | None:
        """Validate endpoint based on transport type.

        Args:
            v: Endpoint value
            info: Validation context with access to other fields

        Returns:
            Validated endpoint

        Raises:
            ValueError: If validation fails
        """
        transport = info.data.get("transport")

        if transport == "http" and not v:
            raise ValueError("endpoint required for http transport")

        if v and not (v.startswith("http://") or v.startswith("https://")):
            raise ValueError("endpoint must be http:// or https:// URL")

        return v

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Validate server name doesn't contain malicious characters.

        Args:
            v: Server name

        Returns:
            Validated name

        Raises:
            ValueError: If name contains forbidden characters
        """
        # Prevent injection attacks
        forbidden_chars = ["<", ">", "&", "'", '"', ";", "`", "|"]
        if any(char in v for char in forbidden_chars):
            raise ValueError(f"Name contains forbidden characters: {forbidden_chars}")

        return v.strip()
```

**Pattern Benefits:**
- Automatic type validation
- Clear validation errors
- Self-documenting API
- Prevents injection attacks at the input layer

### Field Validators for Security

Custom validators for security-sensitive fields:

```python
from pydantic import BaseModel, field_validator, Field
import re

class UserCreateRequest(BaseModel):
    """User creation request with security validation."""

    email: str = Field(..., max_length=255)
    password: str = Field(..., min_length=12, max_length=128)
    username: str = Field(..., min_length=3, max_length=50)

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        """Validate email format and prevent malicious input."""
        # Basic email validation
        email_pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        if not re.match(email_pattern, v):
            raise ValueError("Invalid email format")

        # Prevent email header injection
        if any(char in v for char in ["\n", "\r", "\0"]):
            raise ValueError("Email contains forbidden characters")

        return v.lower().strip()

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        """Validate password meets security requirements.

        Requirements:
        - At least 12 characters
        - Contains uppercase letter
        - Contains lowercase letter
        - Contains digit
        - Contains special character
        """
        if len(v) < 12:
            raise ValueError("Password must be at least 12 characters")

        if not re.search(r"[A-Z]", v):
            raise ValueError("Password must contain uppercase letter")

        if not re.search(r"[a-z]", v):
            raise ValueError("Password must contain lowercase letter")

        if not re.search(r"\d", v):
            raise ValueError("Password must contain digit")

        if not re.search(r"[!@#$%^&*(),.?\":{}|<>]", v):
            raise ValueError("Password must contain special character")

        return v

    @field_validator("username")
    @classmethod
    def validate_username(cls, v: str) -> str:
        """Validate username is alphanumeric with limited special chars."""
        # Allow only alphanumeric, underscore, and hyphen
        if not re.match(r"^[a-zA-Z0-9_-]+$", v):
            raise ValueError("Username can only contain letters, numbers, underscore, and hyphen")

        # Prevent SQL injection patterns
        sql_keywords = ["SELECT", "DROP", "INSERT", "UPDATE", "DELETE", "UNION"]
        if any(keyword in v.upper() for keyword in sql_keywords):
            raise ValueError("Username contains forbidden keywords")

        return v.strip()
```

## Injection Detection Pattern

### Prompt Injection Detection

Pattern for detecting malicious injection attempts:

```python
from dataclasses import dataclass, field
from enum import Enum
import re
from typing import Any

class InjectionSeverity(str, Enum):
    """Severity levels for injection detection."""

    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


@dataclass
class InjectionFinding:
    """Details of a detected injection pattern."""

    pattern_name: str
    severity: InjectionSeverity
    matched_text: str
    location: str  # Field where injection was found
    description: str


@dataclass
class InjectionDetectionResult:
    """Result of injection detection scan."""

    findings: list[InjectionFinding] = field(default_factory=list)
    risk_score: float = 0.0
    has_high_severity: bool = False

    def is_safe(self) -> bool:
        """Check if input is safe (no high/critical findings)."""
        return not self.has_high_severity


class PromptInjectionDetector:
    """Detects prompt injection attempts in user input.

    Scans input for common injection patterns:
    - System prompt override attempts
    - Role manipulation
    - Instruction injection
    - Context escape attempts
    """

    # Injection patterns with severity weights
    INJECTION_PATTERNS: list[tuple[str, InjectionSeverity, str, str]] = [
        # System prompt override
        (
            r"(?i)(ignore|disregard|forget)\s+(previous|above|all)\s+(instructions|prompts|rules)",
            InjectionSeverity.CRITICAL,
            "System prompt override attempt",
            r"ignore previous instructions",
        ),
        # Role manipulation
        (
            r"(?i)(you\s+are\s+now|act\s+as|pretend\s+to\s+be)\s+(an?|the)\s+\w+",
            InjectionSeverity.HIGH,
            "Role manipulation attempt",
            r"you are now a different assistant",
        ),
        # Instruction injection
        (
            r"(?i)(new\s+instructions?|system\s+message|override\s+mode)",
            InjectionSeverity.HIGH,
            "Instruction injection",
            r"new instructions:",
        ),
        # Context escape
        (
            r"(?i)(---\s*end|<\|endoftext\|>|<\|im_end\|>)",
            InjectionSeverity.MEDIUM,
            "Context escape attempt",
            r"--- end of context",
        ),
    ]

    def __init__(self):
        """Initialize detector with compiled patterns."""
        self._patterns = [
            (name, severity, desc, re.compile(pattern, re.IGNORECASE))
            for pattern, severity, desc, name in self.INJECTION_PATTERNS
        ]

    def detect(self, parameters: dict[str, Any]) -> InjectionDetectionResult:
        """Detect injection attempts in parameters.

        Args:
            parameters: Dictionary of parameters to scan

        Returns:
            InjectionDetectionResult with findings
        """
        result = InjectionDetectionResult()

        # Flatten nested dictionaries
        flat_params = self._flatten_dict(parameters)

        for location, value in flat_params.items():
            if not isinstance(value, str):
                continue

            # Check each pattern
            for pattern_name, severity, description, regex in self._patterns:
                match = regex.search(value)
                if match:
                    finding = InjectionFinding(
                        pattern_name=pattern_name,
                        severity=severity,
                        matched_text=match.group(0)[:100],  # Limit length
                        location=location,
                        description=description,
                    )
                    result.findings.append(finding)

                    # Update risk score (critical=1.0, high=0.7, medium=0.4, low=0.2)
                    severity_weights = {
                        InjectionSeverity.CRITICAL: 1.0,
                        InjectionSeverity.HIGH: 0.7,
                        InjectionSeverity.MEDIUM: 0.4,
                        InjectionSeverity.LOW: 0.2,
                    }
                    result.risk_score = max(
                        result.risk_score,
                        severity_weights[severity],
                    )

                    # Mark if high severity found
                    if severity in (InjectionSeverity.CRITICAL, InjectionSeverity.HIGH):
                        result.has_high_severity = True

        return result

    def _flatten_dict(self, d: dict, parent_key: str = "") -> dict[str, Any]:
        """Flatten nested dictionary for scanning.

        Args:
            d: Dictionary to flatten
            parent_key: Parent key prefix

        Returns:
            Flattened dictionary with dot-notation keys
        """
        items = []
        for k, v in d.items():
            new_key = f"{parent_key}.{k}" if parent_key else k
            if isinstance(v, dict):
                items.extend(self._flatten_dict(v, new_key).items())
            else:
                items.append((new_key, v))
        return dict(items)
```

## Secret Scanning with Redaction

### Secret Pattern Detection

Scan for accidentally exposed secrets:

```python
import re
from dataclasses import dataclass
from typing import Any

# Performance tuning
CHUNK_SIZE = 10000
MAX_STRING_LENGTH = 1_000_000

# Secret patterns with metadata (pattern, name, severity_weight)
SECRET_PATTERNS: list[tuple[str, str, float]] = [
    (r"sk-[a-zA-Z0-9]{20,}", "OpenAI API Key", 1.0),
    (r"ghp_[a-zA-Z0-9]{20,}", "GitHub Personal Access Token", 1.0),
    (r"AKIA[0-9A-Z]{16}", "AWS Access Key ID", 1.0),
    (r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", "API Key (UUID format)", 0.5),
    (r"-----BEGIN (?:RSA |EC |DSA )?PRIVATE KEY-----", "Private Key", 1.0),
    (r"(?i)password\s*[:=]\s*['\"]?([^'\"\\s]+)['\"]?", "Hardcoded Password", 0.8),
    (r"(?i)api[_-]?key\s*[:=]\s*['\"]?([a-zA-Z0-9_-]{20,})['\"]?", "API Key", 0.9),
]


@dataclass
class SecretFinding:
    """A detected secret in the input."""

    secret_type: string
    location: str
    redacted_value: str  # Partially redacted for logging
    severity: float


class SecretScanner:
    """Scans input for accidentally exposed secrets."""

    def __init__(self):
        """Initialize scanner with compiled patterns."""
        self._patterns = [
            (name, severity, re.compile(pattern))
            for pattern, name, severity in SECRET_PATTERNS
        ]

    def scan(self, data: dict[str, Any]) -> list[SecretFinding]:
        """Scan data for secrets.

        Args:
            data: Dictionary to scan

        Returns:
            List of findings
        """
        findings = []
        flat_data = self._flatten_dict(data)

        for location, value in flat_data.items():
            if not isinstance(value, str):
                continue

            # Skip very long strings (performance)
            if len(value) > MAX_STRING_LENGTH:
                continue

            for secret_type, severity, pattern in self._patterns:
                matches = pattern.finditer(value)
                for match in matches:
                    findings.append(
                        SecretFinding(
                            secret_type=secret_type,
                            location=location,
                            redacted_value=self._redact(match.group(0)),
                            severity=severity,
                        )
                    )

        return findings

    def redact_secrets(self, data: dict[str, Any]) -> dict[str, Any]:
        """Redact secrets from data.

        Args:
            data: Dictionary with potential secrets

        Returns:
            Dictionary with secrets redacted
        """
        result = {}
        for key, value in data.items():
            if isinstance(value, dict):
                result[key] = self.redact_secrets(value)
            elif isinstance(value, str):
                result[key] = self._redact_string(value)
            else:
                result[key] = value
        return result

    def _redact_string(self, s: str) -> str:
        """Redact secrets in a string."""
        for _, _, pattern in self._patterns:
            s = pattern.sub(lambda m: self._redact(m.group(0)), s)
        return s

    def _redact(self, secret: str) -> str:
        """Redact secret, showing only first/last chars.

        Args:
            secret: Secret string to redact

        Returns:
            Redacted string like "sk-***...***abc"
        """
        if len(secret) <= 8:
            return "***REDACTED***"

        return f"{secret[:3]}***...***{secret[-3:]}"

    def _flatten_dict(self, d: dict, parent_key: str = "") -> dict[str, Any]:
        """Flatten nested dictionary."""
        items = []
        for k, v in d.items():
            new_key = f"{parent_key}.{k}" if parent_key else k
            if isinstance(v, dict):
                items.extend(self._flatten_dict(v, new_key).items())
            else:
                items.append((new_key, v))
        return dict(items)
```

## Multi-Provider Authentication

### Authentication Middleware Pattern

**Example from SARK** (`src/sark/api/middleware/auth.py`):

```python
from collections.abc import Callable
from datetime import UTC, datetime
from typing import ClassVar

from fastapi import Request, Response, status
from fastapi.responses import JSONResponse
from jose import JWTError, jwt
from starlette.middleware.base import BaseHTTPMiddleware
import structlog

logger = structlog.get_logger(__name__)


class AuthenticationError(Exception):
    """Custom exception for authentication errors."""

    def __init__(self, message: str, status_code: int = status.HTTP_401_UNAUTHORIZED):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class AuthMiddleware(BaseHTTPMiddleware):
    """JWT authentication middleware.

    Extracts and validates JWT tokens from the Authorization header.
    Supports both RS256 (asymmetric) and HS256 (symmetric) algorithms.
    """

    # Public endpoints that don't require authentication
    PUBLIC_PATHS: ClassVar[set[str]] = {
        "/health",
        "/health/live",
        "/health/ready",
        "/metrics",
        "/docs",
        "/openapi.json",
        "/api/v1/auth/login",
        "/api/v1/auth/oidc/login",
        "/api/v1/auth/oidc/callback",
        "/api/v1/auth/refresh",
    }

    def __init__(self, app, settings=None):
        """Initialize the authentication middleware.

        Args:
            app: FastAPI application instance
            settings: Settings instance (defaults to get_settings())
        """
        super().__init__(app)
        self.settings = settings or get_settings()

        # Determine the JWT secret/key based on algorithm
        if self.settings.jwt_algorithm == "RS256":
            self.jwt_key = self.settings.jwt_public_key
            if not self.jwt_key:
                raise ValueError("JWT_PUBLIC_KEY must be set when using RS256 algorithm")
        else:  # HS256
            self.jwt_key = self.settings.jwt_secret_key or self.settings.secret_key

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Process the request and validate JWT token.

        Args:
            request: The incoming request
            call_next: The next middleware/route handler

        Returns:
            Response from the next handler or error response
        """
        # Skip authentication for public paths
        if self._is_public_path(request.url.path):
            return await call_next(request)

        try:
            # Extract and validate token
            token = self._extract_token(request)
            if not token:
                raise AuthenticationError("Missing authorization token")

            # Decode and validate JWT
            payload = self._decode_token(token)

            # Attach user context to request state
            request.state.user = self._extract_user_context(payload)

            logger.debug(
                "authentication_success",
                user_id=request.state.user.get("user_id"),
                path=request.url.path,
            )

            response = await call_next(request)
            return response

        except AuthenticationError as e:
            logger.warning(
                "authentication_failed",
                error=e.message,
                path=request.url.path,
                status_code=e.status_code,
            )
            return JSONResponse(
                status_code=e.status_code,
                content={
                    "detail": e.message,
                    "error_type": "authentication_error",
                },
            )

    def _is_public_path(self, path: str) -> bool:
        """Check if the path is public and doesn't require authentication."""
        # Exact match
        if path in self.PUBLIC_PATHS:
            return True

        # Prefix match for paths like /health/*
        return any(path.startswith(public_path) for public_path in self.PUBLIC_PATHS)

    def _extract_token(self, request: Request) -> str | None:
        """Extract JWT token from Authorization header.

        Returns:
            The extracted token or None if not found

        Raises:
            AuthenticationError: If the Authorization header format is invalid
        """
        auth_header = request.headers.get("Authorization")

        if not auth_header:
            return None

        # Expected format: "Bearer <token>"
        parts = auth_header.split()

        if len(parts) != 2:
            raise AuthenticationError(
                "Invalid authorization header format. Expected 'Bearer <token>'"
            )

        scheme, token = parts

        if scheme.lower() != "bearer":
            raise AuthenticationError(f"Invalid authorization scheme: {scheme}. Expected 'Bearer'")

        return token

    def _decode_token(self, token: str) -> dict:
        """Decode and validate JWT token.

        Args:
            token: The JWT token string

        Returns:
            The decoded token payload

        Raises:
            AuthenticationError: If token is invalid, expired, or verification fails
        """
        try:
            # Decode JWT token
            payload = jwt.decode(
                token,
                self.jwt_key,
                algorithms=[self.settings.jwt_algorithm],
                issuer=self.settings.jwt_issuer,
                audience=self.settings.jwt_audience,
                options={
                    "verify_signature": True,
                    "verify_exp": True,
                    "verify_iat": True,
                    "verify_iss": self.settings.jwt_issuer is not None,
                    "verify_aud": self.settings.jwt_audience is not None,
                },
            )

            # Additional expiry validation
            exp = payload.get("exp")
            if exp:
                exp_datetime = datetime.fromtimestamp(exp, tz=UTC)
                if datetime.now(UTC) >= exp_datetime:
                    raise AuthenticationError("Token has expired")

            return payload

        except jwt.ExpiredSignatureError:
            raise AuthenticationError("Token has expired") from None
        except jwt.JWTClaimsError as e:
            raise AuthenticationError(f"Invalid token claims: {e!s}") from None
        except JWTError as e:
            raise AuthenticationError(f"Invalid token: {e!s}") from None

    def _extract_user_context(self, payload: dict) -> dict:
        """Extract user context from JWT payload.

        Returns:
            Dictionary containing user context information

        Raises:
            AuthenticationError: If required claims are missing
        """
        user_context = {
            "user_id": payload.get("sub"),
            "email": payload.get("email"),
            "name": payload.get("name", payload.get("preferred_username")),
            "roles": payload.get("roles", []),
            "teams": payload.get("groups", payload.get("teams", [])),
            "permissions": payload.get("permissions", []),
            "_raw_payload": payload,
        }

        # Ensure user_id is present
        if not user_context["user_id"]:
            raise AuthenticationError("Token missing required 'sub' (subject) claim")

        return user_context
```

## Role-Based Access Control

### UserContext Pattern

**Example from SARK** (`src/sark/services/auth/user_context.py`):

```python
from uuid import UUID
from pydantic import BaseModel


class UserContext(BaseModel):
    """User context information extracted from authentication.

    Provides methods for checking permissions, roles, and team membership.
    """

    user_id: UUID
    email: str
    role: str
    teams: list[str]
    is_authenticated: bool = True
    is_admin: bool = False

    def has_role(self, role: str) -> bool:
        """Check if user has a specific role.

        Args:
            role: Role name to check

        Returns:
            True if user has the role or is admin
        """
        return self.role == role or self.is_admin

    def in_team(self, team: str) -> bool:
        """Check if user is a member of a specific team.

        Args:
            team: Team name to check

        Returns:
            True if user is in the team
        """
        return team in self.teams

    def has_any_team(self, teams: list[str]) -> bool:
        """Check if user is a member of any of the specified teams.

        Args:
            teams: List of team names

        Returns:
            True if user is in at least one team
        """
        return any(team in self.teams for team in teams)

    def to_dict(self) -> dict:
        """Convert to dictionary for logging/serialization.

        Returns:
            Dictionary representation (safe for logging)
        """
        return {
            "user_id": str(self.user_id),
            "email": self.email,
            "role": self.role,
            "teams": self.teams,
            "is_authenticated": self.is_authenticated,
            "is_admin": self.is_admin,
        }
```

### Authorization Dependencies

See [DEPENDENCY_INJECTION.md](./DEPENDENCY_INJECTION.md) for `require_role()`, `require_permission()`, and `require_team()` patterns.

## Security Best Practices

### Never Log Sensitive Data

```python
import structlog

logger = structlog.get_logger(__name__)


def process_payment(payment_data: dict):
    """Process payment with secure logging."""
    # BAD - logs sensitive data
    # logger.info("processing_payment", payment_data=payment_data)

    # GOOD - logs only safe identifiers
    logger.info(
        "processing_payment",
        payment_id=payment_data.get("id"),
        amount=payment_data.get("amount"),
        currency=payment_data.get("currency"),
        # Never log: card numbers, CVV, passwords, tokens
    )
```

### Constant-Time Comparison

Use constant-time comparison for secrets:

```python
import hmac


def verify_api_key(provided_key: str, stored_key: str) -> bool:
    """Verify API key using constant-time comparison.

    Prevents timing attacks that could reveal key information.

    Args:
        provided_key: Key provided by user
        stored_key: Expected key from database

    Returns:
        True if keys match
    """
    return hmac.compare_digest(provided_key, stored_key)


# BAD - vulnerable to timing attacks
def insecure_verify(provided: str, stored: str) -> bool:
    return provided == stored  # Exits early on first mismatch
```

### Rate Limiting

See [ASYNC_PATTERNS.md](./ASYNC_PATTERNS.md) for rate limiting implementation.

## Success Criteria

A security implementation follows these patterns when:

- Pydantic models validate all inputs
- Field validators prevent injection attacks
- Injection detection scans user inputs
- Secret scanner prevents accidental exposure
- Secrets are redacted in logs
- JWT authentication with proper validation
- Role-based access control implemented
- Middleware handles authentication
- UserContext pattern for authorization
- Constant-time comparison for secrets
- No sensitive data in logs
- Rate limiting prevents abuse
- HTTPS enforced in production
- Security headers configured

## Related Standards

- [CODING_STANDARDS.md](./CODING_STANDARDS.md) - General coding standards
- [DEPENDENCY_INJECTION.md](./DEPENDENCY_INJECTION.md) - Authorization dependencies
- [ERROR_HANDLING.md](./ERROR_HANDLING.md) - Security error handling
- [TESTING_PATTERNS.md](./TESTING_PATTERNS.md) - Security testing

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Pydantic Validation](https://docs.pydantic.dev/latest/concepts/validators/)
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/)
- [Python Security Best Practices](https://python.readthedocs.io/en/latest/library/security_warnings.html)
- [JWT Best Practices](https://datatracker.ietf.org/doc/html/rfc8725)
- [SARK Codebase](https://github.com/sark) - Source of extracted patterns
