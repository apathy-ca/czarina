# Python Async Patterns

**Source:** Extracted from [SARK](https://github.com/sark) codebase analysis
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This document establishes async/await patterns for Python applications based on SARK's implementation. These patterns ensure proper async operation handling, resource management, and concurrent execution.

## Fundamental Principles

### When to Use Async

**Use async for:**
- ✅ All I/O operations (database, network, file system)
- ✅ API endpoints and handlers
- ✅ Service layer methods that perform I/O
- ✅ Operations that can be parallelized
- ✅ Streaming data processing

**Don't use async for:**
- ❌ Pure computation with no I/O
- ❌ Simple utility functions
- ❌ Synchronous library wrappers (use sync version or run_in_executor)

### Async Function Declaration

Always use explicit `async def` for asynchronous functions:

```python
# ✅ Correct - explicit async
async def get_user(user_id: UUID) -> User:
    """Fetch user from database."""
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one()

# ❌ Incorrect - missing async
def get_user(user_id: UUID) -> User:
    result = await db.execute(...)  # SyntaxError!
    return result.scalar_one()
```

## Database Async Patterns

### Session Management with AsyncGenerator

Use `AsyncGenerator` for database session lifecycle management:

**Example from SARK** (`src/sark/db/session.py`):

```python
from collections.abc import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Get database session for main PostgreSQL database.

    Automatically commits on success, rolls back on exception.
    Always closes session in finally block.
    """
    session_factory = get_session_factory()
    async with session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
```

**Key Points:**
- `AsyncGenerator[AsyncSession, None]` type hint is explicit
- `async with` ensures cleanup even on exceptions
- Commit happens automatically on success
- Rollback on any exception preserves data integrity
- `finally` block guarantees session closure

### Global Engine Pattern with Lazy Initialization

Create database engines once and reuse across the application:

**Example from SARK** (`src/sark/db/session.py`):

```python
from sqlalchemy.ext.asyncio import AsyncEngine, create_async_engine

_postgres_engine: AsyncEngine | None = None

def get_postgres_engine() -> AsyncEngine:
    """Get or create PostgreSQL engine with optimized connection pooling.

    Engine is created once and cached globally.
    Thread-safe for async applications.
    """
    global _postgres_engine
    if _postgres_engine is None:
        settings = get_settings()
        _postgres_engine = create_async_engine(
            settings.postgres_dsn,
            pool_size=settings.postgres_pool_size,           # Default: 20
            max_overflow=settings.postgres_max_overflow,     # Default: 40
            pool_timeout=settings.postgres_pool_timeout,     # Default: 30.0
            pool_recycle=settings.postgres_pool_recycle,     # Default: 3600
            pool_pre_ping=settings.postgres_pool_pre_ping,   # Default: True
            echo=settings.debug,                             # SQL logging in debug mode
        )
    return _postgres_engine
```

**Why This Pattern:**
- Single engine instance across application
- Connection pooling prevents resource exhaustion
- `pool_pre_ping` detects stale connections
- `pool_recycle` prevents connection timeout issues
- Lazy initialization delays creation until first use

### Service Layer with Async Methods

Service classes accept async session and expose async methods:

**Example from SARK** (`src/sark/services/policy/policy_service.py`):

```python
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

class PolicyService:
    """Service for managing policies."""

    def __init__(self, db: AsyncSession) -> None:
        """Initialize policy service.

        Args:
            db: Active database session (injected)
        """
        self.db = db

    async def create_policy(
        self,
        name: str,
        description: str,
        policy_type: PolicyType,
        initial_content: str,
        created_by: UUID,
    ) -> Policy:
        """Create a new policy with initial version.

        Args:
            name: Policy name
            description: Policy description
            policy_type: Type of policy (privacy, security, etc.)
            initial_content: Initial policy content
            created_by: UUID of user creating the policy

        Returns:
            Created policy instance with ID populated
        """
        # Create policy
        policy = Policy(
            name=name,
            description=description,
            policy_type=policy_type,
            created_by=created_by,
        )
        self.db.add(policy)
        await self.db.flush()  # Get policy.id without committing

        # Create initial version
        version = PolicyVersion(
            policy_id=policy.id,
            content=initial_content,
            version=1,
            created_by=created_by,
        )
        self.db.add(version)

        await self.db.commit()
        await self.db.refresh(policy)  # Load relationships

        return policy
```

**Pattern Benefits:**
- Constructor takes session (dependency injection)
- Methods are async and await database operations
- `flush()` gets ID without committing transaction
- `commit()` persists all changes atomically
- `refresh()` loads relationships after commit

## Streaming Patterns

### AsyncIterator for Streaming Responses

Use `AsyncIterator` for streaming data:

**Example from SARK** (`src/sark/adapters/base.py`):

```python
from collections.abc import AsyncIterator
from typing import Any

async def invoke_streaming(
    self,
    request: InvocationRequest,
) -> AsyncIterator[Any]:
    """Invoke a capability with streaming response support.

    Yields:
        Response chunks as they become available

    Raises:
        UnsupportedOperationError: If streaming is not supported

    Example:
        >>> async for chunk in adapter.invoke_streaming(request):
        ...     print(chunk)
        ...     await process_chunk(chunk)
    """
    # Implementation yields chunks as they arrive
    async for chunk in stream_source:
        # Process chunk
        processed = await transform(chunk)
        yield processed
```

**Usage Pattern:**

```python
async def consume_stream(adapter, request):
    """Consume streaming response."""
    async for chunk in adapter.invoke_streaming(request):
        await handle_chunk(chunk)
        # Can break early if needed
        if should_stop:
            break
```

**Key Points:**
- Return type is `AsyncIterator[T]`
- Use `async for` to consume
- Can break early to stop stream
- Resources cleaned up automatically

## Concurrent Operations

### Sequential Batch Processing

Process items one at a time with error isolation:

**Example from SARK** (`src/sark/adapters/base.py`):

```python
async def invoke_batch(
    self,
    requests: list[InvocationRequest],
) -> list[InvocationResult]:
    """Invoke multiple capabilities in a batch operation.

    Processes requests sequentially. If one fails, continues with the rest.

    Args:
        requests: List of invocation requests

    Returns:
        List of results (same order as requests)
    """
    results = []
    for request in requests:
        try:
            result = await self.invoke(request)
            results.append(result)
        except Exception as e:
            # If one fails, still try the rest
            results.append(
                InvocationResult(
                    success=False,
                    error=str(e),
                    metadata={"batch_index": len(results)},
                    duration_ms=0.0,
                )
            )
    return results
```

### Parallel Execution with asyncio.gather

Execute multiple async operations concurrently:

```python
import asyncio

async def fetch_user_data(user_id: UUID) -> dict:
    """Fetch all user data in parallel."""
    # Gather runs all tasks concurrently
    profile, settings, permissions = await asyncio.gather(
        fetch_profile(user_id),
        fetch_settings(user_id),
        fetch_permissions(user_id),
        return_exceptions=False,  # Raise first exception
    )

    return {
        "profile": profile,
        "settings": settings,
        "permissions": permissions,
    }
```

**With Error Handling:**

```python
async def fetch_user_data_safe(user_id: UUID) -> dict:
    """Fetch user data with graceful error handling."""
    results = await asyncio.gather(
        fetch_profile(user_id),
        fetch_settings(user_id),
        fetch_permissions(user_id),
        return_exceptions=True,  # Return exceptions instead of raising
    )

    # Handle results and exceptions
    profile = results[0] if not isinstance(results[0], Exception) else None
    settings = results[1] if not isinstance(results[1], Exception) else {}
    permissions = results[2] if not isinstance(results[2], Exception) else []

    return {
        "profile": profile,
        "settings": settings,
        "permissions": permissions,
    }
```

### Parallel with Timeout

Use `asyncio.wait_for` for timeouts:

```python
async def fetch_with_timeout(user_id: UUID, timeout: float = 5.0) -> User:
    """Fetch user with timeout.

    Args:
        user_id: User identifier
        timeout: Maximum seconds to wait

    Raises:
        asyncio.TimeoutError: If operation exceeds timeout
    """
    try:
        return await asyncio.wait_for(
            fetch_user(user_id),
            timeout=timeout,
        )
    except asyncio.TimeoutError:
        logger.error("fetch_timeout", user_id=user_id, timeout=timeout)
        raise
```

## Event Loop Management

### FastAPI Lifecycle Hooks

Use startup and shutdown events for initialization and cleanup:

**Example from SARK** (`src/sark/api/main.py`):

```python
from fastapi import FastAPI

app = FastAPI()

@app.on_event("startup")
async def startup_event() -> None:
    """Initialize application on startup.

    Runs once when application starts.
    Ideal for:
    - Database connection pool initialization
    - Cache warming
    - Background task scheduling
    """
    logger.info("application_startup", app_name=settings.app_name)
    await init_db()
    logger.info("database_initialized")

@app.on_event("shutdown")
async def shutdown_event() -> None:
    """Cleanup on shutdown.

    Runs once when application shuts down.
    Ideal for:
    - Closing database connections
    - Flushing buffers
    - Cleanup of background tasks
    """
    logger.info("application_shutdown")
    await cleanup_resources()
```

**Modern Alternative (FastAPI 0.109+):**

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    # Startup
    logger.info("application_startup")
    await init_db()

    yield  # Application runs

    # Shutdown
    logger.info("application_shutdown")
    await cleanup_resources()

app = FastAPI(lifespan=lifespan)
```

### Avoid Blocking the Event Loop

**Never** use blocking operations in async code:

```python
# ❌ BAD - blocks event loop
async def bad_example():
    time.sleep(5)  # Blocks entire event loop!
    return "done"

# ✅ GOOD - uses async sleep
async def good_example():
    await asyncio.sleep(5)  # Yields control to event loop
    return "done"

# ✅ GOOD - runs blocking code in executor
import concurrent.futures

executor = concurrent.futures.ThreadPoolExecutor()

async def good_example_blocking():
    loop = asyncio.get_event_loop()
    result = await loop.run_in_executor(
        executor,
        blocking_function,  # Runs in thread pool
        arg1,
        arg2,
    )
    return result
```

## Advanced Patterns

### Lazy Async Initialization

Initialize expensive resources only when needed:

**Example from SARK** (`src/sark/security/injection_detector.py`):

```python
class PromptInjectionDetector:
    """Detects prompt injection attempts."""

    def __init__(self, config: InjectionDetectionConfig | None = None):
        """Initialize detector.

        Compiles patterns immediately, but defers normalizer initialization.
        """
        if config is None:
            from sark.security.config import get_injection_config
            config = get_injection_config()

        self.config = config
        self._patterns = self._compile_patterns()  # Eager
        self._normalizer = None  # Lazy

    def detect(self, parameters: dict[str, Any]) -> InjectionDetectionResult:
        """Detect injection attempts.

        Initializes normalizer on first use.
        """
        # Lazy initialization
        if self._normalizer is None:
            from sark.security.text_normalizer import get_normalizer
            self._normalizer = get_normalizer()

        # Use normalizer
        normalized = self._normalizer.normalize(text)
        return self._check_patterns(normalized)
```

**Benefits:**
- Constructor is fast
- Expensive initialization only if needed
- Resources not wasted if feature unused

### Context Manager for Async Resources

Use async context managers for resource management:

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def get_redis_connection():
    """Get Redis connection with automatic cleanup."""
    pool = await aioredis.create_pool("redis://localhost")
    try:
        yield pool
        # Connection used here
    finally:
        pool.close()
        await pool.wait_closed()

# Usage
async def use_redis():
    async with get_redis_connection() as redis:
        await redis.set("key", "value")
        value = await redis.get("key")
    # Redis connection automatically closed
```

### Async Property Pattern

Create async properties using methods:

```python
class UserService:
    """User service with async data fetching."""

    def __init__(self, user_id: UUID):
        self.user_id = user_id
        self._profile_cache = None

    async def get_profile(self) -> UserProfile:
        """Get user profile (async property pattern)."""
        if self._profile_cache is None:
            self._profile_cache = await self._fetch_profile()
        return self._profile_cache

    async def _fetch_profile(self) -> UserProfile:
        """Fetch profile from database."""
        # Database fetch logic
        pass

# Usage
service = UserService(user_id)
profile = await service.get_profile()  # Fetches and caches
profile2 = await service.get_profile()  # Returns cached
```

## Rate Limiting with Async

**Example from SARK** (`src/sark/services/rate_limiter.py`):

```python
from dataclasses import dataclass
import time

@dataclass
class RateLimitInfo:
    """Rate limit check result."""
    allowed: bool
    limit: int
    remaining: int
    reset_at: int

class RateLimiter:
    """Rate limiter using Redis sliding window."""

    def __init__(
        self,
        redis,
        window_seconds: int = 60,
        default_limit: int = 100,
    ):
        self.redis = redis
        self.window_seconds = window_seconds
        self.default_limit = default_limit

    async def check_rate_limit(
        self,
        identifier: str,
        limit: int | None = None,
    ) -> RateLimitInfo:
        """Check if request is within rate limit.

        Uses sliding window algorithm with Redis sorted sets.

        Args:
            identifier: Unique identifier (e.g., "user:123", "ip:1.2.3.4")
            limit: Custom limit (uses default if None)

        Returns:
            RateLimitInfo with rate limit status
        """
        limit = limit or self.default_limit
        current_time = time.time()
        window_start = current_time - self.window_seconds

        # Use pipeline for atomic operations
        pipeline = self.redis.pipeline()

        # Remove old entries
        pipeline.zremrangebyscore(
            f"rate:{identifier}",
            "-inf",
            window_start,
        )

        # Count requests in window
        pipeline.zcard(f"rate:{identifier}")

        # Add current request
        pipeline.zadd(
            f"rate:{identifier}",
            {str(current_time): current_time},
        )

        # Set expiration
        pipeline.expire(
            f"rate:{identifier}",
            self.window_seconds,
        )

        # Execute pipeline
        _, count, _, _ = await pipeline.execute()

        allowed = count < limit
        remaining = max(0, limit - count - 1)
        reset_at = int(current_time + self.window_seconds)

        return RateLimitInfo(
            allowed=allowed,
            limit=limit,
            remaining=remaining,
            reset_at=reset_at,
        )
```

**Key Patterns:**
- Redis pipeline for atomic operations
- Sliding window algorithm
- Automatic cleanup of old entries
- Graceful degradation on errors

## Common Pitfalls

### Pitfall 1: Forgetting await

```python
# ❌ BAD - missing await
async def bad():
    user = get_user(user_id)  # Returns coroutine, not User!
    print(user.name)  # AttributeError

# ✅ GOOD
async def good():
    user = await get_user(user_id)
    print(user.name)
```

### Pitfall 2: Using sync libraries in async code

```python
# ❌ BAD - blocks event loop
import requests
async def bad():
    response = requests.get("https://api.example.com")  # Blocks!
    return response.json()

# ✅ GOOD - use async HTTP client
import httpx
async def good():
    async with httpx.AsyncClient() as client:
        response = await client.get("https://api.example.com")
        return response.json()
```

### Pitfall 3: Not handling AsyncGenerator cleanup

```python
# ❌ BAD - session not closed on exception
async def bad():
    async for item in get_db():  # Wrong usage!
        process(item)

# ✅ GOOD - use dependency injection
from fastapi import Depends

@router.get("/users")
async def get_users(db: AsyncSession = Depends(get_db)):
    # db automatically managed by FastAPI
    users = await db.execute(select(User))
    return users.scalars().all()
```

## Testing Async Code

See [TESTING_PATTERNS.md](./TESTING_PATTERNS.md) for comprehensive testing patterns.

**Quick Example:**

```python
import pytest

@pytest.mark.asyncio
async def test_async_function():
    """Test async function."""
    result = await async_function()
    assert result == expected
```

## Success Criteria

An async codebase follows these patterns when:

- ✅ All I/O operations use async/await
- ✅ Database sessions use AsyncGenerator pattern
- ✅ Services accept AsyncSession in constructor
- ✅ Streaming uses AsyncIterator
- ✅ Concurrent operations use asyncio.gather
- ✅ No blocking operations in async functions
- ✅ Proper resource cleanup with async context managers
- ✅ FastAPI lifecycle hooks for initialization
- ✅ All async functions have proper type hints
- ✅ Tests use @pytest.mark.asyncio

## Related Standards

- [CODING_STANDARDS.md](./CODING_STANDARDS.md) - General coding standards
- [ERROR_HANDLING.md](./ERROR_HANDLING.md) - Exception handling in async code
- [DEPENDENCY_INJECTION.md](./DEPENDENCY_INJECTION.md) - DI with async
- [TESTING_PATTERNS.md](./TESTING_PATTERNS.md) - Testing async code

## References

- [PEP 492 – Coroutines with async and await syntax](https://peps.python.org/pep-0492/)
- [PEP 525 – Asynchronous Generators](https://peps.python.org/pep-0525/)
- [asyncio — Asynchronous I/O](https://docs.python.org/3/library/asyncio.html)
- [SQLAlchemy Async](https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html)
- [FastAPI Async](https://fastapi.tiangolo.com/async/)
- [SARK Codebase](https://github.com/sark) - Source of extracted patterns
