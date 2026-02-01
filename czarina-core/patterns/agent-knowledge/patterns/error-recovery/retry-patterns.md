# Retry Patterns

Strategies for automated retry logic and backoff in AI-assisted development.

---

## When to Retry vs. Fail Fast

### Retry Candidates

**Good candidates for retry**:
- Network timeouts
- Temporary service unavailability (503 Service Unavailable)
- Rate limiting (429 Too Many Requests)
- Database connection timeouts
- Lock conflicts (optimistic locking)
- Transient cloud service errors

**Example**:
```python
# Retry on transient network errors
for attempt in range(3):
    try:
        response = await http_client.get(url)
        return response
    except aiohttp.ClientError as e:
        if attempt < 2:
            await asyncio.sleep(2 ** attempt)  # Exponential backoff
            continue
        raise
```

### Fail Fast Candidates

**Should NOT retry**:
- Authentication errors (401, 403)
- Not found errors (404)
- Validation errors (400 Bad Request)
- Syntax errors
- Type errors
- Logical errors in code

**Example**:
```python
# Don't retry on validation errors
if response.status == 400:
    raise ValidationError("Invalid input")  # Fail immediately
```

---

## Exponential Backoff

### Basic Pattern

**Strategy**: Wait increasingly longer between retries to avoid overwhelming services.

```python
import asyncio
from typing import TypeVar, Callable

T = TypeVar('T')

async def retry_with_backoff(
    func: Callable[..., T],
    max_attempts: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 60.0
) -> T:
    """Retry function with exponential backoff."""
    for attempt in range(max_attempts):
        try:
            return await func()
        except Exception as e:
            if attempt == max_attempts - 1:
                raise

            # Calculate delay: 1s, 2s, 4s, 8s, etc.
            delay = min(base_delay * (2 ** attempt), max_delay)
            await asyncio.sleep(delay)
```

### With Jitter

**Enhancement**: Add randomness to prevent thundering herd.

```python
import random

async def retry_with_jitter(
    func: Callable[..., T],
    max_attempts: int = 3,
    base_delay: float = 1.0
) -> T:
    """Retry with exponential backoff and jitter."""
    for attempt in range(max_attempts):
        try:
            return await func()
        except Exception as e:
            if attempt == max_attempts - 1:
                raise

            # Add randomness: 50-150% of base delay
            delay = base_delay * (2 ** attempt)
            jittered_delay = delay * (0.5 + random.random())
            await asyncio.sleep(jittered_delay)
```

---

## Circuit Breaker Pattern

### Concept

**Purpose**: Stop retrying when service is clearly down to prevent cascading failures.

**States**:
- **Closed**: Normal operation, requests pass through
- **Open**: Service is down, fail fast without attempting
- **Half-Open**: Test if service recovered

### Implementation

```python
from datetime import datetime, timedelta
from enum import Enum

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

class CircuitBreaker:
    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: float = 60.0,
        expected_exception: type = Exception
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception

        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED

    async def call(self, func, *args, **kwargs):
        if self.state == CircuitState.OPEN:
            if self._should_attempt_reset():
                self.state = CircuitState.HALF_OPEN
            else:
                raise Exception("Circuit breaker is OPEN")

        try:
            result = await func(*args, **kwargs)
            self._on_success()
            return result
        except self.expected_exception as e:
            self._on_failure()
            raise

    def _on_success(self):
        self.failure_count = 0
        self.state = CircuitState.CLOSED

    def _on_failure(self):
        self.failure_count += 1
        self.last_failure_time = datetime.now()

        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN

    def _should_attempt_reset(self) -> bool:
        return (
            self.last_failure_time is not None and
            datetime.now() - self.last_failure_time >= timedelta(seconds=self.recovery_timeout)
        )
```

### Usage

```python
# Create circuit breaker for external service
db_breaker = CircuitBreaker(
    failure_threshold=5,
    recovery_timeout=60.0
)

# Use in application
try:
    result = await db_breaker.call(database.query, "SELECT * FROM users")
except Exception as e:
    logger.error(f"Database unavailable: {e}")
    # Use fallback or cached data
```

---

## Idempotency Considerations

### Idempotent Operations

**Safe to retry** (same result no matter how many times called):
- GET requests
- PUT requests with full object
- DELETE by ID
- Database reads
- Upserts with unique constraints

### Non-Idempotent Operations

**Dangerous to retry** (different result on each call):
- POST requests (creating resources)
- Incrementing counters
- Appending to lists
- Transfers between accounts

### Making Operations Idempotent

**Use idempotency keys**:
```python
async def create_resource(data: dict, idempotency_key: str):
    """Create resource with idempotency key to prevent duplicates."""
    # Check if already created
    existing = await db.get_by_idempotency_key(idempotency_key)
    if existing:
        return existing

    # Create new resource
    resource = await db.create(data, idempotency_key=idempotency_key)
    return resource
```

**Use transactions**:
```python
async def transfer_funds(from_account: str, to_account: str, amount: float):
    """Transfer funds atomically to allow safe retry."""
    async with db.transaction():
        # Both succeed or both fail
        await db.debit(from_account, amount)
        await db.credit(to_account, amount)
```

---

## Retry Budgets

### Concept

**Purpose**: Limit total retry attempts across system to prevent resource exhaustion.

### Implementation

```python
class RetryBudget:
    def __init__(self, max_retries_per_second: int = 10):
        self.max_retries = max_retries_per_second
        self.retry_count = 0
        self.window_start = datetime.now()

    def can_retry(self) -> bool:
        self._reset_if_new_window()
        return self.retry_count < self.max_retries

    def record_retry(self):
        self._reset_if_new_window()
        self.retry_count += 1

    def _reset_if_new_window(self):
        now = datetime.now()
        if now - self.window_start >= timedelta(seconds=1):
            self.retry_count = 0
            self.window_start = now
```

---

## Real-World Examples

### Container Startup Retry

```bash
# Wait for service to be ready before proceeding
wait_for_service() {
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -sf http://localhost:8000/health > /dev/null; then
            echo "Service is ready"
            return 0
        fi

        echo "Waiting for service... (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done

    echo "Service failed to start"
    return 1
}
```

### Database Connection Retry

```python
async def connect_with_retry(
    connection_string: str,
    max_attempts: int = 5
):
    """Connect to database with retry logic."""
    for attempt in range(max_attempts):
        try:
            conn = await asyncpg.connect(connection_string)
            logger.info("Database connected successfully")
            return conn
        except ConnectionRefusedError:
            if attempt == max_attempts - 1:
                raise

            delay = 2 ** attempt
            logger.warning(f"Connection failed, retrying in {delay}s...")
            await asyncio.sleep(delay)
```

---

## Best Practices

### Do's

- Use exponential backoff with jitter
- Set maximum retry limits
- Log retry attempts for debugging
- Make operations idempotent when possible
- Use circuit breakers for external services
- Implement timeout for each attempt

### Don'ts

- Don't retry indefinitely
- Don't use fixed delays (causes thundering herd)
- Don't retry on client errors (4xx)
- Don't ignore retry metrics
- Don't retry non-idempotent operations without safeguards

---

## Related Patterns

- [Detection Patterns](./detection-patterns.md) - When to trigger retry
- [Fallback Patterns](./fallback-patterns.md) - What to do when retries exhausted
- [Escalation Patterns](./escalation-patterns.md) - When to stop retrying

---

**Source**: The Symposium development (v0.4.5)
