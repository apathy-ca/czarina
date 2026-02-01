# Python Error Handling Patterns

**Source:** Extracted from [SARK](https://github.com/sark) codebase analysis
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This document establishes error handling patterns based on SARK's implementation. These patterns emphasize structured exceptions, graceful degradation, and comprehensive error context for debugging.

## Exception Hierarchy

### Custom Exception Base Class

Create a structured exception hierarchy with rich context:

**Example from SARK** (`src/sark/adapters/exceptions.py`):

```python
from typing import Any

class AdapterError(Exception):
    """Base exception for all adapter errors.

    Provides structured error information for API responses and logging.

    Attributes:
        message: Human-readable error description
        adapter_name: Name of adapter that raised the error
        resource_id: Identifier of resource involved (if applicable)
        details: Additional context as dictionary
    """

    def __init__(
        self,
        message: str,
        *,
        adapter_name: str | None = None,
        resource_id: str | None = None,
        details: dict[str, Any] | None = None,
    ):
        super().__init__(message)
        self.message = message
        self.adapter_name = adapter_name
        self.resource_id = resource_id
        self.details = details or {}

    def to_dict(self) -> dict[str, Any]:
        """Convert exception to dictionary for API responses.

        Returns:
            Dictionary with error type, message, and context
        """
        return {
            "error_type": self.__class__.__name__,
            "message": self.message,
            "adapter": self.adapter_name,
            "resource_id": self.resource_id,
            "details": self.details,
        }

    def __str__(self) -> str:
        """String representation with context."""
        parts = [self.message]
        if self.adapter_name:
            parts.append(f"adapter={self.adapter_name}")
        if self.resource_id:
            parts.append(f"resource={self.resource_id}")
        return " | ".join(parts)
```

### Specialized Exception Types

Create specific exceptions for different error categories:

**Example from SARK:**

```python
class ValidationError(AdapterError):
    """Raised when request validation fails.

    Attributes:
        validation_errors: List of specific validation failures
    """

    def __init__(
        self,
        message: str,
        *,
        validation_errors: list | None = None,
        **kwargs,
    ):
        super().__init__(message, **kwargs)
        self.validation_errors = validation_errors or []
        self.details["validation_errors"] = self.validation_errors


class ConnectionError(AdapterError):
    """Raised when connection to external service fails."""
    pass


class AuthenticationError(AdapterError):
    """Raised when authentication fails."""
    pass


class TimeoutError(AdapterError):
    """Raised when operation exceeds timeout."""

    def __init__(self, message: str, *, timeout_seconds: float, **kwargs):
        super().__init__(message, **kwargs)
        self.timeout_seconds = timeout_seconds
        self.details["timeout_seconds"] = timeout_seconds


class InvocationError(AdapterError):
    """Raised when capability invocation fails."""
    pass


class ResourceNotFoundError(AdapterError):
    """Raised when requested resource doesn't exist."""
    pass


class ProtocolError(AdapterError):
    """Raised when protocol-specific error occurs."""
    pass


class UnsupportedOperationError(AdapterError):
    """Raised when operation is not supported by adapter."""

    def __init__(
        self,
        message: str,
        *,
        operation: str,
        adapter_name: str,
        **kwargs,
    ):
        super().__init__(message, adapter_name=adapter_name, **kwargs)
        self.operation = operation
        self.details["operation"] = operation
```

### Exception Hierarchy Benefits

**Why this pattern:**
- ✅ Catch all adapter errors with `except AdapterError`
- ✅ Catch specific errors with `except ValidationError`
- ✅ Rich context for logging and debugging
- ✅ Structured data for API error responses
- ✅ Type-safe error handling

## Error Recovery Patterns

### Fail-Open Pattern for Non-Critical Services

Allow requests when non-critical services fail:

**Example from SARK** (`src/sark/services/rate_limiter.py`):

```python
async def check_rate_limit(
    self,
    identifier: str,
    limit: int | None = None,
) -> RateLimitInfo:
    """Check if request is within rate limit.

    Fails open if Redis is unavailable - allows request rather than blocking.

    Args:
        identifier: Unique identifier
        limit: Rate limit threshold

    Returns:
        RateLimitInfo with rate limit status
    """
    try:
        # Attempt rate limit check
        current_time = time.time()
        window_start = current_time - self.window_seconds

        pipeline = self.redis.pipeline()
        # ... rate limiting logic ...

        _, count, _, _ = await pipeline.execute()

        allowed = count < limit
        remaining = max(0, limit - count - 1)

        return RateLimitInfo(
            allowed=allowed,
            limit=limit,
            remaining=remaining,
            reset_at=int(current_time + self.window_seconds),
        )

    except Exception as e:
        # Log error but don't block request
        logger.error(
            "rate_limiter_error",
            identifier=identifier,
            error=str(e),
            exc_info=True,
        )

        # Fail open - allow request if Redis is down
        return RateLimitInfo(
            allowed=True,
            limit=limit,
            remaining=limit,
            reset_at=int(current_time + self.window_seconds),
        )
```

**When to Fail Open:**
- Rate limiting (security over availability)
- Metrics collection
- Caching layers
- Non-essential validations

**When to Fail Closed:**
- Authentication
- Authorization
- Data validation
- Financial transactions
- Critical security checks

### Database Session Rollback Pattern

Always rollback on exceptions to maintain data integrity:

**Example from SARK** (`src/sark/db/session.py`):

```python
from collections.abc import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Get database session with automatic rollback on errors.

    Pattern:
    - Commits on successful completion
    - Rolls back on any exception
    - Always closes session

    Yields:
        AsyncSession for database operations
    """
    session_factory = get_session_factory()
    async with session_factory() as session:
        try:
            yield session
            await session.commit()  # Success path
        except Exception:
            await session.rollback()  # Error path
            raise  # Re-raise after rollback
        finally:
            await session.close()  # Always cleanup
```

**Key Points:**
- Explicit rollback prevents partial commits
- Re-raise exception after rollback
- `finally` ensures cleanup even on exception
- Async context manager handles resource lifecycle

### Retry Mechanisms

**Configuration Pattern from SARK:**

```python
# /home/jhenry/Source/sark/src/sark/config/settings.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Application settings with retry configuration."""

    # Gateway retry settings
    gateway_retry_attempts: int = 3
    gateway_circuit_breaker_threshold: int = 5
    gateway_timeout_seconds: float = 5.0
    gateway_backoff_factor: float = 2.0
```

**Retry Implementation Example:**

```python
import asyncio
from typing import TypeVar, Callable

T = TypeVar("T")

async def retry_with_backoff(
    func: Callable[[], T],
    max_attempts: int = 3,
    backoff_factor: float = 2.0,
    exceptions: tuple = (Exception,),
) -> T:
    """Retry function with exponential backoff.

    Args:
        func: Async function to retry
        max_attempts: Maximum retry attempts
        backoff_factor: Backoff multiplier (2.0 = double each time)
        exceptions: Tuple of exceptions to catch and retry

    Returns:
        Result from successful function call

    Raises:
        Last exception if all retries fail
    """
    last_exception = None

    for attempt in range(max_attempts):
        try:
            return await func()
        except exceptions as e:
            last_exception = e
            if attempt < max_attempts - 1:
                wait_time = backoff_factor ** attempt
                logger.warning(
                    "retry_attempt",
                    attempt=attempt + 1,
                    max_attempts=max_attempts,
                    wait_time=wait_time,
                    error=str(e),
                )
                await asyncio.sleep(wait_time)
            else:
                logger.error(
                    "retry_exhausted",
                    attempts=max_attempts,
                    error=str(e),
                )

    raise last_exception


# Usage example
async def fetch_data():
    """Fetch data with retries."""
    return await retry_with_backoff(
        lambda: api_client.get("/data"),
        max_attempts=3,
        exceptions=(ConnectionError, TimeoutError),
    )
```

## Error Logging Patterns

### Structured Logging with Context

Use structured logging for error context:

**Example from SARK** (`src/sark/security/injection_detector.py`):

```python
import structlog

logger = structlog.get_logger()

def detect(self, parameters: dict[str, Any]) -> InjectionDetectionResult:
    """Detect prompt injection attempts.

    Logs warnings for detected patterns with full context.
    """
    result = InjectionDetectionResult()

    for location, value in parameters.items():
        for pattern_name, severity, description, regex in self._patterns:
            match = regex.search(value)
            if match:
                # Structured warning with context
                logger.warning(
                    "injection_pattern_detected",
                    pattern=pattern_name,
                    severity=severity.value,
                    location=location,
                    matched_text=match.group(0)[:50],  # First 50 chars
                )

                result.findings.append(
                    InjectionFinding(
                        pattern_name=pattern_name,
                        severity=severity,
                        matched_text=match.group(0)[:100],
                        location=location,
                        description=description,
                    )
                )

    logger.info(
        "injection_detection_complete",
        findings_count=len(result.findings),
        risk_score=result.risk_score,
        high_severity=result.has_high_severity,
    )

    return result
```

### Error Logging Levels

**Use appropriate log levels:**

```python
# ERROR - Unexpected failures requiring attention
logger.error(
    "database_connection_failed",
    host=db_host,
    error=str(e),
    exc_info=True,  # Include stack trace
)

# WARNING - Degraded functionality but not failure
logger.warning(
    "cache_miss",
    key=cache_key,
    fallback="database",
)

# INFO - Normal operation events
logger.info(
    "user_login",
    user_id=user.id,
    ip=request.client.host,
)

# DEBUG - Detailed diagnostic information
logger.debug(
    "query_executed",
    query=str(query),
    duration_ms=duration,
)
```

## FastAPI Error Handling

### Exception Handlers

Register global exception handlers:

```python
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse

app = FastAPI()

@app.exception_handler(AdapterError)
async def adapter_error_handler(
    request: Request,
    exc: AdapterError,
) -> JSONResponse:
    """Handle adapter exceptions with structured response.

    Returns:
        JSON response with error details and appropriate status code
    """
    logger.error(
        "adapter_error",
        path=request.url.path,
        error=exc.to_dict(),
        exc_info=True,
    )

    status_code = 500
    if isinstance(exc, ValidationError):
        status_code = 400
    elif isinstance(exc, AuthenticationError):
        status_code = 401
    elif isinstance(exc, ResourceNotFoundError):
        status_code = 404
    elif isinstance(exc, TimeoutError):
        status_code = 504

    return JSONResponse(
        status_code=status_code,
        content=exc.to_dict(),
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(
    request: Request,
    exc: HTTPException,
) -> JSONResponse:
    """Handle FastAPI HTTP exceptions."""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error_type": "HTTPException",
            "message": exc.detail,
            "status_code": exc.status_code,
        },
    )


@app.exception_handler(Exception)
async def general_exception_handler(
    request: Request,
    exc: Exception,
) -> JSONResponse:
    """Catch-all handler for unexpected exceptions.

    Prevents leaking internal details to clients.
    """
    logger.error(
        "unexpected_error",
        path=request.url.path,
        error=str(exc),
        exc_info=True,
    )

    return JSONResponse(
        status_code=500,
        content={
            "error_type": "InternalServerError",
            "message": "An unexpected error occurred",
        },
    )
```

### Validation Error Handling

**With Pydantic:**

```python
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    """Handle Pydantic validation errors with detailed messages."""
    errors = []
    for error in exc.errors():
        errors.append({
            "field": " -> ".join(str(loc) for loc in error["loc"]),
            "message": error["msg"],
            "type": error["type"],
        })

    logger.warning(
        "validation_error",
        path=request.url.path,
        errors=errors,
    )

    return JSONResponse(
        status_code=422,
        content={
            "error_type": "ValidationError",
            "message": "Request validation failed",
            "errors": errors,
        },
    )
```

## Error Context Patterns

### Context Managers for Error Handling

```python
from contextlib import asynccontextmanager
from typing import AsyncIterator

@asynccontextmanager
async def handle_adapter_errors(
    adapter_name: str,
    operation: str,
) -> AsyncIterator[None]:
    """Context manager for consistent adapter error handling.

    Args:
        adapter_name: Name of adapter for error context
        operation: Operation being performed

    Raises:
        AdapterError: With consistent structure and context

    Example:
        >>> async with handle_adapter_errors("http", "invoke"):
        ...     result = await http_client.post(url, json=data)
    """
    try:
        yield
    except ConnectionError as e:
        raise AdapterError(
            f"Connection failed during {operation}",
            adapter_name=adapter_name,
            details={"operation": operation, "original_error": str(e)},
        ) from e
    except TimeoutError as e:
        raise AdapterError(
            f"Timeout during {operation}",
            adapter_name=adapter_name,
            details={"operation": operation, "original_error": str(e)},
        ) from e
    except Exception as e:
        raise AdapterError(
            f"Unexpected error during {operation}",
            adapter_name=adapter_name,
            details={"operation": operation, "original_error": str(e)},
        ) from e
```

### Error Enrichment Pattern

Add context to exceptions as they propagate:

```python
async def invoke_capability(
    adapter: ProtocolAdapter,
    request: InvocationRequest,
) -> InvocationResult:
    """Invoke capability with error enrichment.

    Catches exceptions and enriches with request context.
    """
    try:
        return await adapter.invoke(request)
    except AdapterError as e:
        # Enrich existing adapter error
        e.details["request_id"] = request.id
        e.details["capability"] = request.capability_name
        raise
    except Exception as e:
        # Convert unknown exceptions to AdapterError
        raise InvocationError(
            f"Failed to invoke {request.capability_name}",
            adapter_name=adapter.protocol_name,
            resource_id=request.resource_id,
            details={
                "request_id": request.id,
                "capability": request.capability_name,
                "original_error": str(e),
            },
        ) from e
```

## Error Prevention Patterns

### Input Validation

Validate early to prevent errors:

```python
from pydantic import BaseModel, Field, field_validator

class ServerRegistrationRequest(BaseModel):
    """Server registration with validation."""

    name: str = Field(..., min_length=1, max_length=255)
    transport: str = Field(..., pattern="^(http|stdio|sse)$")
    endpoint: str | None = Field(None, max_length=500)

    @field_validator("endpoint")
    @classmethod
    def validate_endpoint(cls, v: str | None, info) -> str | None:
        """Validate endpoint based on transport type."""
        transport = info.data.get("transport")

        if transport == "http" and not v:
            raise ValueError("endpoint required for http transport")

        if v and not (v.startswith("http://") or v.startswith("https://")):
            raise ValueError("endpoint must be http:// or https:// URL")

        return v
```

### Type Guards

Use type guards to prevent type errors:

```python
from typing import TypeGuard

def is_valid_identifier(value: str | None) -> TypeGuard[str]:
    """Type guard for non-empty identifier strings.

    Args:
        value: String to validate

    Returns:
        True if value is non-empty string
    """
    return value is not None and isinstance(value, str) and len(value) > 0


def process_user(user_id: str | None) -> User:
    """Process user with type guard."""
    if not is_valid_identifier(user_id):
        raise ValueError("Invalid user_id")

    # TypeScript knows user_id is str here
    return fetch_user(user_id)
```

## Success Criteria

An error handling implementation follows these patterns when:

- ✅ Custom exception hierarchy with base class
- ✅ Exceptions include structured context (adapter_name, resource_id, details)
- ✅ `to_dict()` method for API responses
- ✅ Specific exception types for different error categories
- ✅ Fail-open pattern for non-critical services
- ✅ Database rollback on all exceptions
- ✅ Structured logging with error context
- ✅ FastAPI exception handlers registered
- ✅ Validation errors have detailed messages
- ✅ Error enrichment as exceptions propagate
- ✅ Type guards prevent runtime errors

## Related Standards

- [CODING_STANDARDS.md](./CODING_STANDARDS.md) - General coding standards
- [ASYNC_PATTERNS.md](./ASYNC_PATTERNS.md) - Error handling in async code
- [TESTING_PATTERNS.md](./TESTING_PATTERNS.md) - Testing error conditions
- [SECURITY_PATTERNS.md](./SECURITY_PATTERNS.md) - Security-related errors

## References

- [PEP 3134 – Exception Chaining and Embedded Tracebacks](https://peps.python.org/pep-3134/)
- [Python Exception Hierarchy](https://docs.python.org/3/library/exceptions.html#exception-hierarchy)
- [FastAPI Exception Handling](https://fastapi.tiangolo.com/tutorial/handling-errors/)
- [Structlog Documentation](https://www.structlog.org/)
- [SARK Codebase](https://github.com/sark) - Source of extracted patterns
