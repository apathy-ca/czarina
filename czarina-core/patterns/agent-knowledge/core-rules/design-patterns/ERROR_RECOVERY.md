# Error Recovery Patterns for Agent Development

**Purpose**: Proven strategies for detecting, handling, and recovering from errors in AI agent systems.

**Value**: 30-50% reduction in debugging time through systematic error handling, resilient operations, and graceful degradation.

**Source**: SARK project (retry handlers, exponential backoff) + Czarina project (error recovery patterns) + TheSymposium (error handling)

---

## 🎯 Philosophy

**Good error recovery**:
- Detects errors early with clear context
- Retries transient failures intelligently
- Degrades gracefully on persistent failures
- Logs errors with actionable information
- Prevents cascading failures

**Bad error recovery**:
- Ignores errors or fails silently
- Retries indefinitely without backoff
- Crashes on recoverable errors
- Logs cryptic error messages
- Allows errors to cascade

---

## 📋 Table of Contents

1. [Retry with Exponential Backoff](#retry-with-exponential-backoff)
2. [Circuit Breaker Pattern](#circuit-breaker-pattern)
3. [Retry Configuration](#retry-configuration)
4. [Error Classification](#error-classification)
5. [Graceful Degradation](#graceful-degradation)
6. [Timeout Management](#timeout-management)
7. [Error Context Preservation](#error-context-preservation)
8. [Fallback Strategies](#fallback-strategies)
9. [Recovery Callbacks](#recovery-callbacks)
10. [Common Error Patterns](#common-error-patterns)
11. [Anti-Patterns](#anti-patterns)

---

## Retry with Exponential Backoff

### Overview

Intelligent retry mechanism with exponentially increasing delays between attempts.

### Implementation

**File Reference**: `sark/src/sark/services/audit/siem/retry_handler.py:29-139`

```python
import asyncio
from dataclasses import dataclass
from typing import Any, Callable, TypeVar
import structlog

logger = structlog.get_logger()
T = TypeVar("T")

@dataclass
class RetryConfig:
    """Configuration for retry behavior"""
    max_attempts: int = 3
    backoff_base: float = 2.0
    backoff_max: float = 60.0
    retryable_exceptions: tuple[type[Exception], ...] = (
        ConnectionError,
        TimeoutError,
        asyncio.TimeoutError,
    )

class RetryHandler:
    """Handles retry logic with exponential backoff"""

    def __init__(self, config: RetryConfig | None = None):
        """
        Initialize retry handler.

        Args:
            config: Retry configuration (uses defaults if None)
        """
        self.config = config or RetryConfig()
        self._logger = logger.bind(component="retry_handler")

    async def execute_with_retry(
        self,
        operation: Callable[[], Any],
        operation_name: str = "operation",
        on_retry: Callable[[int, Exception], None] | None = None,
    ) -> T:
        """
        Execute an async operation with retry logic.

        Args:
            operation: Async callable to execute
            operation_name: Name of operation for logging
            on_retry: Optional callback called on each retry

        Returns:
            Result of the operation

        Raises:
            Exception: The last exception if all retries exhausted
        """
        last_exception: Exception | None = None

        for attempt in range(1, self.config.max_attempts + 1):
            try:
                self._logger.debug(
                    "retry_attempt_start",
                    operation=operation_name,
                    attempt=attempt,
                    max_attempts=self.config.max_attempts,
                )

                result = await operation()

                if attempt > 1:
                    self._logger.info(
                        "retry_success",
                        operation=operation_name,
                        attempt=attempt,
                        total_attempts=attempt,
                    )

                return result

            except Exception as e:
                last_exception = e
                is_retryable = isinstance(e, self.config.retryable_exceptions)

                self._logger.warning(
                    "retry_attempt_failed",
                    operation=operation_name,
                    attempt=attempt,
                    max_attempts=self.config.max_attempts,
                    error_type=type(e).__name__,
                    error_message=str(e),
                    retryable=is_retryable,
                )

                # If not retryable or last attempt, raise immediately
                if not is_retryable or attempt >= self.config.max_attempts:
                    self._logger.error(
                        "retry_exhausted",
                        operation=operation_name,
                        total_attempts=attempt,
                        error_type=type(e).__name__,
                    )
                    raise

                # Call the on_retry callback if provided
                if on_retry:
                    try:
                        on_retry(attempt, e)
                    except Exception as callback_error:
                        self._logger.warning(
                            "retry_callback_error",
                            error=str(callback_error),
                        )

                # Calculate backoff delay with exponential increase
                backoff_delay = min(
                    self.config.backoff_base ** (attempt - 1),
                    self.config.backoff_max,
                )

                self._logger.info(
                    "retry_backoff",
                    operation=operation_name,
                    attempt=attempt,
                    backoff_seconds=backoff_delay,
                )

                await asyncio.sleep(backoff_delay)

        # This should never be reached, but just in case
        if last_exception:
            raise last_exception
        raise RuntimeError(
            f"Retry failed for {operation_name} with no exception recorded"
        )
```

### Exponential Backoff Calculation

```python
# Backoff formula: min(backoff_base ^ (attempt - 1), backoff_max)
# With backoff_base=2.0, backoff_max=60.0:

Attempt 1: min(2^0, 60) = 1 second
Attempt 2: min(2^1, 60) = 2 seconds
Attempt 3: min(2^2, 60) = 4 seconds
Attempt 4: min(2^3, 60) = 8 seconds
Attempt 5: min(2^4, 60) = 16 seconds
Attempt 6: min(2^5, 60) = 32 seconds
Attempt 7: min(2^6, 60) = 60 seconds (capped)
```

### Usage Example

```python
# Basic usage
retry_handler = RetryHandler(RetryConfig(max_attempts=5))

async def unreliable_api_call():
    response = await http_client.get("https://api.example.com/data")
    return response.json()

result = await retry_handler.execute_with_retry(
    unreliable_api_call,
    operation_name="fetch_api_data"
)

# With callback
def on_retry_callback(attempt: int, error: Exception):
    metrics.increment("api_retry", tags={"attempt": attempt})
    logger.warning(f"Retry attempt {attempt}: {error}")

result = await retry_handler.execute_with_retry(
    unreliable_api_call,
    operation_name="fetch_api_data",
    on_retry=on_retry_callback
)
```

### Best Practices

- **Set max attempts** - prevent infinite retries (3-5 typical)
- **Cap backoff delay** - avoid waiting too long (60s typical)
- **Classify exceptions** - only retry transient errors
- **Log all attempts** - debug level for attempts, error for exhaustion
- **Use callbacks** - track metrics, update UI, notify monitoring

**File Reference**: `sark/src/sark/services/audit/siem/retry_handler.py:45-139`

---

## Circuit Breaker Pattern

### Overview

Prevent cascading failures by failing fast when a service is known to be down.

### Implementation

```python
from enum import Enum
from datetime import datetime, timedelta
from typing import Callable, TypeVar

T = TypeVar("T")

class CircuitState(Enum):
    """Circuit breaker states"""
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Failing fast
    HALF_OPEN = "half_open"  # Testing recovery

@dataclass
class CircuitBreakerConfig:
    """Circuit breaker configuration"""
    failure_threshold: int = 5
    recovery_timeout: float = 60.0
    success_threshold: int = 2

class CircuitBreaker:
    """Circuit breaker for preventing cascading failures"""

    def __init__(self, config: CircuitBreakerConfig | None = None):
        """
        Initialize circuit breaker.

        Args:
            config: Circuit breaker configuration
        """
        self.config = config or CircuitBreakerConfig()
        self._state = CircuitState.CLOSED
        self._failure_count = 0
        self._success_count = 0
        self._last_failure_time: datetime | None = None
        self._logger = logger.bind(component="circuit_breaker")

    async def call(
        self,
        operation: Callable[[], T],
        operation_name: str = "operation"
    ) -> T:
        """
        Execute operation with circuit breaker protection.

        Args:
            operation: Async callable to execute
            operation_name: Operation name for logging

        Returns:
            Operation result

        Raises:
            CircuitBreakerOpenError: If circuit is open
            Exception: Original exception if operation fails
        """
        # Check circuit state
        if self._state == CircuitState.OPEN:
            if self._should_attempt_reset():
                self._state = CircuitState.HALF_OPEN
                self._logger.info("circuit_half_open", operation=operation_name)
            else:
                raise CircuitBreakerOpenError(
                    f"Circuit breaker is open for {operation_name}"
                )

        try:
            result = await operation()
            self._on_success(operation_name)
            return result

        except Exception as e:
            self._on_failure(operation_name, e)
            raise

    def _should_attempt_reset(self) -> bool:
        """Check if enough time has passed to attempt reset"""
        if self._last_failure_time is None:
            return False

        elapsed = (datetime.now() - self._last_failure_time).total_seconds()
        return elapsed >= self.config.recovery_timeout

    def _on_success(self, operation_name: str):
        """Handle successful operation"""
        if self._state == CircuitState.HALF_OPEN:
            self._success_count += 1
            if self._success_count >= self.config.success_threshold:
                self._state = CircuitState.CLOSED
                self._failure_count = 0
                self._success_count = 0
                self._logger.info("circuit_closed", operation=operation_name)
        else:
            # Reset failure count on success
            self._failure_count = 0

    def _on_failure(self, operation_name: str, error: Exception):
        """Handle failed operation"""
        self._failure_count += 1
        self._last_failure_time = datetime.now()

        if self._state == CircuitState.HALF_OPEN:
            # Failed during recovery attempt
            self._state = CircuitState.OPEN
            self._success_count = 0
            self._logger.warning(
                "circuit_opened_from_half_open",
                operation=operation_name,
                error=str(error)
            )
        elif self._failure_count >= self.config.failure_threshold:
            # Threshold reached, open circuit
            self._state = CircuitState.OPEN
            self._logger.error(
                "circuit_opened",
                operation=operation_name,
                failure_count=self._failure_count,
                threshold=self.config.failure_threshold
            )

    def get_state(self) -> dict:
        """Get current circuit breaker state"""
        return {
            "state": self._state.value,
            "failure_count": self._failure_count,
            "success_count": self._success_count,
            "last_failure": self._last_failure_time.isoformat() if self._last_failure_time else None,
        }

class CircuitBreakerOpenError(Exception):
    """Raised when circuit breaker is open"""
    pass
```

### Circuit Breaker States

```
State Transitions:

CLOSED → OPEN (failure_threshold failures)
  ↓
OPEN → HALF_OPEN (after recovery_timeout)
  ↓
HALF_OPEN → CLOSED (success_threshold successes)
HALF_OPEN → OPEN (any failure)
```

### Usage Example

```python
# Create circuit breaker for external service
circuit_breaker = CircuitBreaker(CircuitBreakerConfig(
    failure_threshold=5,
    recovery_timeout=60.0,
    success_threshold=2
))

async def call_external_service():
    try:
        return await circuit_breaker.call(
            lambda: http_client.get("https://external-api.com/data"),
            operation_name="external_api_call"
        )
    except CircuitBreakerOpenError:
        # Circuit is open, use fallback
        return get_cached_data()
```

### Best Practices

- **Set failure threshold** - based on service SLA (5-10 typical)
- **Set recovery timeout** - balance detection vs recovery (30-120s typical)
- **Monitor state changes** - alert on circuit opening
- **Provide fallbacks** - handle CircuitBreakerOpenError gracefully
- **Per-service circuits** - separate circuit breaker per dependency

---

## Retry Configuration

### Overview

Flexible retry configuration for different operation types.

### Configuration Examples

```python
# Quick operations (API calls)
QUICK_RETRY = RetryConfig(
    max_attempts=3,
    backoff_base=2.0,
    backoff_max=10.0,
    retryable_exceptions=(
        ConnectionError,
        TimeoutError,
        HTTPException,  # Assuming 5xx errors
    )
)

# Long operations (batch processing)
LONG_RETRY = RetryConfig(
    max_attempts=5,
    backoff_base=2.0,
    backoff_max=60.0,
    retryable_exceptions=(
        ConnectionError,
        TimeoutError,
    )
)

# Critical operations (no retries)
NO_RETRY = RetryConfig(
    max_attempts=1,
    retryable_exceptions=()
)

# Aggressive retry (user-facing operations)
AGGRESSIVE_RETRY = RetryConfig(
    max_attempts=7,
    backoff_base=1.5,  # Slower growth
    backoff_max=30.0,
    retryable_exceptions=(
        ConnectionError,
        TimeoutError,
        asyncio.TimeoutError,
        OSError,
    )
)
```

### Best Practices

- **Match operation type** - different configs for different operations
- **Consider user impact** - more retries for user-facing operations
- **Limit total time** - max_attempts * backoff_max should be reasonable
- **Document exceptions** - clearly list retryable error types
- **Environment-specific** - different configs for dev/staging/prod

---

## Error Classification

### Overview

Categorize errors to determine appropriate handling strategy.

### Implementation

```python
from enum import Enum

class ErrorCategory(Enum):
    """Error categories for handling strategy"""
    TRANSIENT = "transient"      # Retry
    PERMANENT = "permanent"      # Don't retry
    CLIENT_ERROR = "client_error"  # User fix needed
    RATE_LIMIT = "rate_limit"    # Backoff needed

def classify_error(error: Exception) -> ErrorCategory:
    """
    Classify error for handling strategy.

    Args:
        error: Exception to classify

    Returns:
        ErrorCategory for the error
    """
    # Transient errors (retryable)
    if isinstance(error, (ConnectionError, TimeoutError, asyncio.TimeoutError)):
        return ErrorCategory.TRANSIENT

    # HTTP errors
    if hasattr(error, "status_code"):
        status = error.status_code
        if 500 <= status < 600:
            return ErrorCategory.TRANSIENT
        elif status == 429:
            return ErrorCategory.RATE_LIMIT
        elif 400 <= status < 500:
            return ErrorCategory.CLIENT_ERROR

    # Default to permanent
    return ErrorCategory.PERMANENT

async def handle_with_classification(operation, operation_name: str):
    """Execute operation with error classification"""
    retry_handler = RetryHandler()

    try:
        return await retry_handler.execute_with_retry(
            operation,
            operation_name
        )
    except Exception as e:
        category = classify_error(e)

        if category == ErrorCategory.TRANSIENT:
            logger.error(f"Transient error in {operation_name}: {e}")
            # Already retried, now escalate
            raise
        elif category == ErrorCategory.PERMANENT:
            logger.error(f"Permanent error in {operation_name}: {e}")
            # Don't retry, fail immediately
            raise
        elif category == ErrorCategory.CLIENT_ERROR:
            logger.warning(f"Client error in {operation_name}: {e}")
            # Return error to user for correction
            return {"error": str(e), "type": "client_error"}
        elif category == ErrorCategory.RATE_LIMIT:
            logger.warning(f"Rate limited in {operation_name}")
            # Use longer backoff
            await asyncio.sleep(60)
            return await operation()
```

### Error Classification Matrix

| Error Type | Category | Action |
|-----------|----------|--------|
| ConnectionError | Transient | Retry with backoff |
| TimeoutError | Transient | Retry with backoff |
| HTTP 5xx | Transient | Retry with backoff |
| HTTP 429 | Rate Limit | Long backoff, then retry |
| HTTP 4xx | Client Error | Return to caller |
| ValueError | Permanent | Fail immediately |
| ValidationError | Client Error | Return to caller |

### Best Practices

- **Be specific** - classify narrowly for better handling
- **Log category** - include in error logs for debugging
- **Monitor by category** - track transient vs permanent failures
- **Update classification** - learn from production errors
- **Document decisions** - explain why each error is classified

---

## Graceful Degradation

### Overview

Maintain partial functionality when components fail.

### Implementation

```python
class ResilientService:
    """Service with graceful degradation"""

    def __init__(
        self,
        primary_client,
        secondary_client,
        cache_manager,
    ):
        self.primary = primary_client
        self.secondary = secondary_client
        self.cache = cache_manager

    async def get_data(self, key: str) -> dict:
        """
        Get data with multiple fallback layers.

        Fallback order:
        1. Primary service
        2. Secondary service
        3. Cache
        4. Default/mock data
        """
        # Layer 1: Primary service
        try:
            data = await self.primary.get(key)
            # Update cache on success
            self.cache.set(key, data, expire=300)
            return data
        except Exception as e:
            logger.warning(f"Primary service failed: {e}")

        # Layer 2: Secondary service
        try:
            data = await self.secondary.get(key)
            self.cache.set(key, data, expire=300)
            return data
        except Exception as e:
            logger.warning(f"Secondary service failed: {e}")

        # Layer 3: Cache
        cached = self.cache.get(key)
        if cached:
            logger.info(f"Serving from cache (degraded): {key}")
            return cached

        # Layer 4: Default data
        logger.error(f"All services failed for {key}, returning default")
        return self._get_default_data(key)

    def _get_default_data(self, key: str) -> dict:
        """Return safe default data when all else fails"""
        return {
            "key": key,
            "status": "degraded",
            "message": "Service temporarily unavailable",
            "timestamp": datetime.now().isoformat()
        }
```

### Degradation Strategies

```python
# Strategy 1: Feature flags
async def get_user_recommendations(user_id: str):
    if feature_flags.is_enabled("ml_recommendations"):
        try:
            return await ml_service.get_recommendations(user_id)
        except Exception:
            logger.warning("ML service down, falling back to simple recs")
            return get_popular_items()
    else:
        return get_popular_items()

# Strategy 2: Reduced functionality
async def search_with_degradation(query: str):
    try:
        # Full-text search with ML ranking
        return await advanced_search(query)
    except Exception:
        # Simple keyword match fallback
        return await basic_search(query)

# Strategy 3: Stale data acceptable
async def get_analytics():
    try:
        return await real_time_analytics()
    except Exception:
        # Serve 5-minute-old cached data
        return await get_cached_analytics(max_age=300)
```

### Best Practices

- **Document degradation** - users should know when degraded
- **Monitor degradation** - track how often fallbacks are used
- **Test fallbacks** - regularly test degraded modes
- **Communicate status** - include degradation in health checks
- **Time-bound degradation** - return to normal ASAP

---

## Timeout Management

### Overview

Combine retry logic with per-attempt timeouts.

### Implementation

**File Reference**: `sark/src/sark/services/audit/siem/retry_handler.py:141-196`

```python
class RetryHandler:
    # ... previous methods ...

    async def execute_with_timeout(
        self,
        operation: Callable[[], Any],
        timeout_seconds: float,
        operation_name: str = "operation",
    ) -> T:
        """
        Execute an async operation with a timeout.

        Args:
            operation: Async callable to execute
            timeout_seconds: Timeout in seconds
            operation_name: Name of operation for logging

        Returns:
            Result of the operation

        Raises:
            asyncio.TimeoutError: If operation exceeds timeout
        """
        try:
            return await asyncio.wait_for(operation(), timeout=timeout_seconds)
        except TimeoutError:
            self._logger.error(
                "operation_timeout",
                operation=operation_name,
                timeout_seconds=timeout_seconds,
            )
            raise

    async def execute_with_retry_and_timeout(
        self,
        operation: Callable[[], Any],
        timeout_seconds: float,
        operation_name: str = "operation",
        on_retry: Callable[[int, Exception], None] | None = None,
    ) -> T:
        """
        Execute operation with both retry logic and timeout.

        Args:
            operation: Async callable to execute
            timeout_seconds: Timeout in seconds for each attempt
            operation_name: Name of operation for logging
            on_retry: Optional callback called on each retry

        Returns:
            Result of the operation

        Raises:
            Exception: Last exception if all retries exhausted
            asyncio.TimeoutError: If operation exceeds timeout
        """
        async def operation_with_timeout() -> T:
            return await self.execute_with_timeout(
                operation,
                timeout_seconds,
                operation_name
            )

        return await self.execute_with_retry(
            operation_with_timeout,
            operation_name,
            on_retry
        )
```

### Timeout Examples

```python
# Example 1: Retry with per-attempt timeout
retry_handler = RetryHandler()
result = await retry_handler.execute_with_retry_and_timeout(
    operation=fetch_data,
    timeout_seconds=5.0,  # Each attempt times out after 5s
    operation_name="fetch_data"
)
# Total time: up to (5s timeout * 3 attempts) + backoff delays

# Example 2: Different timeouts per operation
TIMEOUT_CONFIG = {
    "quick": 1.0,
    "medium": 5.0,
    "slow": 30.0,
}

result = await retry_handler.execute_with_retry_and_timeout(
    operation=expensive_computation,
    timeout_seconds=TIMEOUT_CONFIG["slow"],
    operation_name="expensive_computation"
)
```

### Best Practices

- **Per-attempt timeouts** - each retry should timeout independently
- **Total operation timeout** - also set max total time
- **Operation-specific** - different timeouts for different operations
- **Monitor timeout rates** - high timeout rate indicates issues
- **Include in SLA** - timeouts part of service-level objectives

---

## Error Context Preservation

### Overview

Preserve error context for effective debugging.

### Implementation

```python
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

@dataclass
class ErrorContext:
    """Preserve error context for debugging"""
    operation: str
    timestamp: datetime = field(default_factory=datetime.now)
    error_type: str = ""
    error_message: str = ""
    stack_trace: str = ""
    attempt: int = 0
    parameters: dict[str, Any] = field(default_factory=dict)
    metadata: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict:
        """Convert to dictionary for logging"""
        return {
            "operation": self.operation,
            "timestamp": self.timestamp.isoformat(),
            "error_type": self.error_type,
            "error_message": self.error_message,
            "attempt": self.attempt,
            "parameters": self.parameters,
            "metadata": self.metadata,
        }

async def execute_with_context(
    operation: Callable,
    operation_name: str,
    **parameters
) -> Any:
    """Execute operation with error context preservation"""
    context = ErrorContext(
        operation=operation_name,
        parameters=parameters
    )

    try:
        result = await operation(**parameters)
        return result

    except Exception as e:
        import traceback

        context.error_type = type(e).__name__
        context.error_message = str(e)
        context.stack_trace = traceback.format_exc()

        # Log with full context
        logger.error("operation_failed", **context.to_dict())

        # Store for debugging
        await store_error_context(context)

        raise

# Usage
result = await execute_with_context(
    operation=process_user_data,
    operation_name="process_user_data",
    user_id="123",
    action="update",
    data={"name": "Alice"}
)
```

### Context to Preserve

1. **Operation details** - name, parameters, start time
2. **Error details** - type, message, stack trace
3. **Attempt number** - which retry attempt failed
4. **System state** - memory usage, queue depth, etc.
5. **User context** - user ID, request ID, session ID
6. **Environment** - service version, hostname, region

### Best Practices

- **Structured logging** - use JSON for easy parsing
- **Sanitize sensitive data** - remove passwords, tokens
- **Include request ID** - trace across services
- **Store for debugging** - persist to searchable store
- **Monitor patterns** - aggregate similar errors

---

## Fallback Strategies

### Overview

Provide alternative paths when primary operations fail.

### Common Fallback Patterns

```python
# Pattern 1: Service fallback
async def get_translation(text: str, target_lang: str) -> str:
    try:
        return await ai_translation_service(text, target_lang)
    except Exception:
        try:
            return await dictionary_translation_service(text, target_lang)
        except Exception:
            return f"[Translation unavailable: {text}]"

# Pattern 2: Data source fallback
async def get_user_profile(user_id: str) -> dict:
    # Try cache first
    cached = cache.get(f"user:{user_id}")
    if cached:
        return cached

    # Try primary database
    try:
        profile = await primary_db.get_user(user_id)
        cache.set(f"user:{user_id}", profile, expire=300)
        return profile
    except Exception:
        pass

    # Try replica database
    try:
        profile = await replica_db.get_user(user_id)
        cache.set(f"user:{user_id}", profile, expire=60)  # Shorter cache
        return profile
    except Exception:
        pass

    # Return default
    return {"user_id": user_id, "status": "unknown"}

# Pattern 3: Feature fallback
async def search_with_ai(query: str):
    if not ai_service_available():
        logger.info("AI service unavailable, using basic search")
        return basic_search(query)

    try:
        return await ai_search(query)
    except Exception as e:
        logger.error(f"AI search failed: {e}, falling back")
        return basic_search(query)
```

### Best Practices

- **Clear fallback chain** - document the order of fallbacks
- **Test all paths** - regularly test fallback scenarios
- **Log fallback usage** - monitor which fallbacks are used
- **Communicate degradation** - indicate when using fallback
- **Time-bound** - attempt to recover primary path

---

## Recovery Callbacks

### Overview

Execute callbacks during retry attempts for monitoring and user feedback.

### Implementation

```python
class RetryCallbacks:
    """Collection of retry callbacks"""

    @staticmethod
    def metrics_callback(operation_name: str):
        """Return callback that records metrics"""
        def callback(attempt: int, error: Exception):
            metrics.increment(
                "retry_attempt",
                tags={
                    "operation": operation_name,
                    "attempt": attempt,
                    "error_type": type(error).__name__
                }
            )
        return callback

    @staticmethod
    def notification_callback(user_id: str):
        """Return callback that notifies user"""
        def callback(attempt: int, error: Exception):
            if attempt >= 2:  # After first retry
                send_notification(
                    user_id,
                    f"Operation taking longer than expected (attempt {attempt})"
                )
        return callback

    @staticmethod
    def logging_callback(operation_name: str):
        """Return callback that logs retry attempts"""
        def callback(attempt: int, error: Exception):
            logger.warning(
                f"Retry {attempt} for {operation_name}: {error}"
            )
        return callback

# Usage
retry_handler = RetryHandler()
result = await retry_handler.execute_with_retry(
    operation=process_data,
    operation_name="process_data",
    on_retry=RetryCallbacks.metrics_callback("process_data")
)
```

### Best Practices

- **Lightweight callbacks** - don't add significant overhead
- **Error handling** - callbacks should not raise exceptions
- **Metrics tracking** - record retry rates and patterns
- **User communication** - inform users of delays
- **Circuit breaker integration** - callbacks can trigger circuit breaker

---

## Common Error Patterns

### Overview

Specific error scenarios and recovery strategies from real projects.

**Source**: Czarina project error recovery patterns

### Pattern: Docker Port Conflict

**Error**:
```
Error: failed to bind host port 0.0.0.0:11434: address already in use
```

**Recovery**:
```python
async def start_service_with_port_recovery(service_name: str, port: int):
    """Start service with automatic port conflict resolution"""
    try:
        await start_service(service_name, port)
    except OSError as e:
        if "address already in use" in str(e).lower():
            logger.warning(f"Port {port} in use, attempting recovery")

            # Find and stop conflicting process
            conflicting_pid = find_process_using_port(port)
            if conflicting_pid:
                logger.info(f"Stopping process {conflicting_pid} using port {port}")
                stop_process(conflicting_pid)
                await asyncio.sleep(2)  # Wait for port release

                # Retry
                await start_service(service_name, port)
            else:
                raise
        else:
            raise
```

### Pattern: Module Not Found

**Error**:
```
ModuleNotFoundError: No module named 'redis'
```

**Recovery**:
```python
def import_with_recovery(module_name: str):
    """Import module with automatic installation fallback"""
    try:
        return __import__(module_name)
    except ModuleNotFoundError:
        logger.warning(f"Module {module_name} not found, attempting install")

        # In development, auto-install
        if os.getenv("ENVIRONMENT") == "development":
            import subprocess
            subprocess.run(["pip", "install", module_name], check=True)
            return __import__(module_name)
        else:
            logger.error(
                f"Module {module_name} not found in production. "
                f"Add to requirements.txt and rebuild."
            )
            raise
```

### Pattern: Async Function Not Awaited

**Error**:
```
RuntimeWarning: coroutine 'function' was never awaited
```

**Recovery**:
```python
def ensure_awaited(func_or_coro):
    """Wrapper to ensure async functions are properly awaited"""
    import asyncio
    import inspect

    if asyncio.iscoroutine(func_or_coro):
        # Already a coroutine, just return it
        return func_or_coro
    elif inspect.iscoroutinefunction(func_or_coro):
        # Function that needs to be called
        async def wrapper(*args, **kwargs):
            return await func_or_coro(*args, **kwargs)
        return wrapper
    else:
        # Regular function
        return func_or_coro
```

### Best Practices for Common Errors

- **Document patterns** - maintain error recovery playbook
- **Automate recovery** - build self-healing into services
- **Monitor recurrence** - track how often each error occurs
- **Update handling** - improve recovery based on experience
- **Share knowledge** - team-wide error pattern documentation

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Infinite Retries

**Bad:**
```python
while True:
    try:
        return await operation()
    except Exception:
        continue  # Infinite loop
```

**Good:**
```python
retry_handler = RetryHandler(RetryConfig(max_attempts=3))
return await retry_handler.execute_with_retry(operation)
```

---

### ❌ Anti-Pattern 2: No Backoff

**Bad:**
```python
for attempt in range(3):
    try:
        return await operation()
    except Exception:
        pass  # Immediate retry hammers service
```

**Good:**
```python
for attempt in range(3):
    try:
        return await operation()
    except Exception:
        await asyncio.sleep(2 ** attempt)  # Exponential backoff
```

---

### ❌ Anti-Pattern 3: Silent Failures

**Bad:**
```python
try:
    await operation()
except Exception:
    pass  # Lost forever
```

**Good:**
```python
try:
    await operation()
except Exception as e:
    logger.error(f"Operation failed: {e}", exc_info=True)
    raise
```

---

### ❌ Anti-Pattern 4: Retry Non-Retryable Errors

**Bad:**
```python
# Retry everything, including client errors
for attempt in range(3):
    try:
        return await operation()
    except Exception:  # Catches ValueError, etc.
        continue
```

**Good:**
```python
# Only retry transient errors
config = RetryConfig(
    retryable_exceptions=(ConnectionError, TimeoutError)
)
```

---

### ❌ Anti-Pattern 5: Lost Error Context

**Bad:**
```python
try:
    await operation()
except Exception:
    logger.error("Operation failed")  # What operation? What error?
```

**Good:**
```python
try:
    await operation(user_id="123", action="update")
except Exception as e:
    logger.error(
        "Operation failed",
        operation="update_user",
        user_id="123",
        error=str(e),
        error_type=type(e).__name__
    )
```

---

## 🔗 Related Patterns

- [BATCH_OPERATIONS.md](BATCH_OPERATIONS.md) - Retry batch operations
- [CACHING_PATTERNS.md](CACHING_PATTERNS.md) - Cache as fallback
- [STREAMING_PATTERNS.md](STREAMING_PATTERNS.md) - Stream error recovery
- [TOOL_USE_PATTERNS.md](TOOL_USE_PATTERNS.md) - Tool error handling
- Cross-reference: `agent-rules/python/ERROR_HANDLING.md` (from foundation worker)

For specific error recovery patterns in AI-assisted development, see:
- [Error Recovery Patterns](../../patterns/error-recovery/README.md) - Common errors and recovery strategies
- [Detection Patterns](../../patterns/error-recovery/detection-patterns.md) - Recognizing error patterns
- [Recovery Strategies](../../patterns/error-recovery/recovery-strategies.md) - Systematic recovery approaches
- [Retry Patterns](../../patterns/error-recovery/retry-patterns.md) - Retry and backoff strategies
- [Fallback Patterns](../../patterns/error-recovery/fallback-patterns.md) - Graceful degradation patterns

---

## Related Patterns (Extended)

For detailed error recovery strategies and real-world examples, see:
- [Error Recovery Patterns](../../patterns/error-recovery/README.md) - Comprehensive error recovery strategies
- [Error Detection Patterns](../../patterns/error-recovery/detection-patterns.md) - Docker, Python, database, git errors
- [Recovery Strategies](../../patterns/error-recovery/recovery-strategies.md) - Step-by-step recovery procedures
- [Retry Patterns](../../patterns/error-recovery/retry-patterns.md) - Exponential backoff, circuit breakers
- [Fallback Patterns](../../patterns/error-recovery/fallback-patterns.md) - Graceful degradation strategies
- [Escalation Patterns](../../patterns/error-recovery/escalation-patterns.md) - When to escalate to humans

---

**Last Updated**: 2025-12-26
**Patterns**: 11 documented
**Source**: SARK (v2.0+), Czarina (v0.6.0), TheSymposium (v0.4.5)
**Lines of Code Analyzed**: ~800 lines

*"Fail gracefully, recover intelligently, learn constantly."*
