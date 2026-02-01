# Caching Patterns for Agent Development

**Purpose**: Proven patterns for implementing efficient caching strategies in AI agent systems.

**Value**: 10-100x performance improvement through intelligent caching, reduced latency, and lower infrastructure costs.

**Source**: SARK project (Redis/Valkey caching, rate limiting, distributed caching)

---

## 🎯 Philosophy

**Good caching**:
- Caches expensive operations strategically
- Invalidates stale data appropriately
- Handles cache failures gracefully
- Provides observability into cache performance
- Supports distributed environments

**Bad caching**:
- Caches everything indiscriminately
- Never invalidates cached data
- Fails hard when cache is unavailable
- Provides no cache metrics
- Causes consistency issues in distributed systems

---

## 📋 Table of Contents

1. [Cache Manager Pattern](#cache-manager-pattern)
2. [Connection Management](#connection-management)
3. [High Availability with Sentinel](#high-availability-with-sentinel)
4. [TTL-Based Caching](#ttl-based-caching)
5. [Rate Limiting with Cache](#rate-limiting-with-cache)
6. [Sliding Window Algorithm](#sliding-window-algorithm)
7. [Cache-Aside Pattern](#cache-aside-pattern)
8. [Fail-Open Strategy](#fail-open-strategy)
9. [Cache Metrics and Monitoring](#cache-metrics-and-monitoring)
10. [Anti-Patterns](#anti-patterns)

---

## Cache Manager Pattern

### Overview

Centralized cache connection management with graceful degradation.

### Implementation

**File Reference**: `sark/src/sark/cache.py:21-127`

```python
import logging
from typing import Any
import valkey
from valkey import Redis
from valkey.sentinel import Sentinel

logger = logging.getLogger(__name__)

class CacheManager:
    """Manager for Redis cache connections"""

    def __init__(self, config: RedisConfig):
        """
        Initialize cache manager.

        Args:
            config: Redis configuration
        """
        self.config = config
        self._client: Redis | None = None
        self._sentinel: Sentinel | None = None

        logger.info(
            f"Initialized CacheManager in {config.mode} mode: "
            f"host={config.host}, port={config.port}, "
            f"sentinel={config.sentinel_enabled}"
        )

    @property
    def client(self) -> Redis:
        """
        Get or create Redis client.

        Returns:
            Redis client instance

        Raises:
            ValueError: If configuration is invalid
        """
        if self._client is None:
            if self.config.sentinel_enabled:
                self._client = self._create_sentinel_client()
            else:
                self._client = self._create_direct_client()

            logger.info(
                f"Created Redis client: {self.config.host}:{self.config.port} "
                f"(sentinel={self.config.sentinel_enabled})"
            )

        return self._client

    def _create_direct_client(self) -> Redis:
        """
        Create a direct Redis client connection.

        Returns:
            Redis client instance
        """
        return valkey.Redis(
            host=self.config.host,
            port=self.config.port,
            db=self.config.database,
            password=self.config.password,
            max_connections=self.config.max_connections,
            ssl=self.config.ssl,
            decode_responses=True,  # Automatically decode to strings
            socket_connect_timeout=5,
            socket_keepalive=True,
            health_check_interval=30,
        )
```

### Key Features

1. **Lazy initialization** - client created on first access
2. **Configuration-based** - mode determined by config
3. **Connection pooling** - `max_connections` parameter
4. **Health checking** - automatic health check every 30s
5. **SSL support** - optional encrypted connections

### Best Practices

- **Decode responses** - set `decode_responses=True` for string handling
- **Socket timeouts** - always set `socket_connect_timeout`
- **Keepalive** - enable `socket_keepalive` for long-lived connections
- **Connection limits** - set `max_connections` based on load
- **Health checks** - enable automatic health checking

**File Reference**: `sark/src/sark/cache.py:64-82`

---

## Connection Management

### Overview

Safe connection lifecycle management with context manager support.

### Implementation

**File Reference**: `sark/src/sark/cache.py:306-362`

```python
class CacheManager:
    # ... previous methods ...

    def close(self):
        """Close Redis connection"""
        if self._client is not None:
            self._client.close()
            logger.info("Closed Redis connection")
            self._client = None

    def __enter__(self) -> "CacheManager":
        """Context manager entry"""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.close()

def create_cache_manager(config: RedisConfig | None = None) -> CacheManager | None:
    """
    Create a cache manager instance.

    Args:
        config: Redis configuration (if None, loads from environment)

    Returns:
        CacheManager instance if Redis is enabled, None otherwise
    """
    if config is None:
        from sark.config import get_config
        app_config = get_config()
        config = app_config.redis

    if not config.enabled:
        logger.info("Redis is not enabled")
        return None

    return CacheManager(config)

def verify_cache_connectivity(config: RedisConfig | None = None) -> bool:
    """
    Verify connectivity to Redis cache.

    Args:
        config: Redis configuration (if None, loads from environment)

    Returns:
        True if Redis is accessible, False otherwise
    """
    manager = create_cache_manager(config)
    if manager is None:
        return False

    try:
        return manager.health_check()
    finally:
        manager.close()
```

### Usage Example

```python
# Context manager usage (recommended)
with create_cache_manager() as cache:
    cache.set("key", "value", expire=300)
    value = cache.get("key")

# Manual lifecycle management
cache = create_cache_manager()
try:
    cache.set("key", "value")
finally:
    cache.close()

# Verify connectivity before app start
if not verify_cache_connectivity():
    logger.warning("Cache not available, running without cache")
```

### Best Practices

- **Always close connections** - use context manager or try/finally
- **Check availability** - verify connectivity during startup
- **Graceful degradation** - handle None return from factory
- **Resource cleanup** - ensure connections closed on shutdown
- **Connection reuse** - create manager once, reuse throughout app

---

## High Availability with Sentinel

### Overview

Redis Sentinel support for automatic failover and high availability.

### Implementation

**File Reference**: `sark/src/sark/cache.py:84-126`

```python
def _create_sentinel_client(self) -> Redis:
    """
    Create a Redis client using Sentinel for high availability.

    Returns:
        Redis client instance

    Raises:
        ValueError: If sentinel configuration is invalid
    """
    if not self.config.sentinel_hosts:
        raise ValueError(
            "VALKEY_SENTINEL_HOSTS must be set when sentinel is enabled"
        )

    if not self.config.sentinel_service_name:
        raise ValueError(
            "VALKEY_SENTINEL_SERVICE_NAME must be set when sentinel is enabled"
        )

    # Parse sentinel hosts (format: "host1:port1,host2:port2,host3:port3")
    sentinel_nodes = []
    for node in self.config.sentinel_hosts.split(","):
        parts = node.strip().split(":")
        if len(parts) != 2:
            raise ValueError(f"Invalid sentinel host format: {node}")
        host = parts[0]
        port = int(parts[1])
        sentinel_nodes.append((host, port))

    logger.info(f"Connecting to Redis Sentinel: {sentinel_nodes}")

    # Create Sentinel instance
    self._sentinel = Sentinel(
        sentinel_nodes,
        socket_timeout=5,
        password=self.config.password,
        ssl=self.config.ssl,
    )

    # Get master client
    return self._sentinel.master_for(
        self.config.sentinel_service_name,
        socket_timeout=5,
        db=self.config.database,
        decode_responses=True,
    )
```

### Configuration Example

```bash
# Environment variables for Sentinel
VALKEY_SENTINEL_ENABLED=true
VALKEY_SENTINEL_HOSTS=sentinel1:26379,sentinel2:26379,sentinel3:26379
VALKEY_SENTINEL_SERVICE_NAME=mymaster
VALKEY_PASSWORD=your_password
VALKEY_SSL=true
```

### Sentinel Benefits

1. **Automatic failover** - promotes replica to master on failure
2. **High availability** - multiple sentinel nodes monitor health
3. **Service discovery** - clients find current master automatically
4. **No single point of failure** - Sentinel ensemble is distributed
5. **Transparent to application** - same client interface

### Best Practices

- **Three+ sentinels** - minimum for quorum and HA
- **Distributed deployment** - sentinels on different hosts/zones
- **Monitor sentinel logs** - watch for failover events
- **Test failovers** - regularly practice failure scenarios
- **Set timeouts** - configure `socket_timeout` appropriately

---

## TTL-Based Caching

### Overview

Time-to-live based cache invalidation for temporal data.

### Implementation

**File Reference**: `sark/src/sark/cache.py:144-209`

```python
class CacheManager:
    # ... previous methods ...

    def set(
        self,
        key: str,
        value: str | bytes | int | float,
        expire: int | None = None
    ) -> bool:
        """
        Set value in cache.

        Args:
            key: Cache key
            value: Value to cache
            expire: Expiration time in seconds (optional)

        Returns:
            True if successful, False otherwise
        """
        try:
            return self.client.set(key, value, ex=expire)
        except Exception as e:
            logger.error(f"Error setting key '{key}' in cache: {e}")
            return False

    def get(self, key: str) -> str | None:
        """
        Get value from cache.

        Args:
            key: Cache key

        Returns:
            Cached value or None if not found
        """
        try:
            return self.client.get(key)
        except Exception as e:
            logger.error(f"Error getting key '{key}' from cache: {e}")
            return None

    def expire(self, key: str, seconds: int) -> bool:
        """
        Set expiration time for a key.

        Args:
            key: Cache key
            seconds: Expiration time in seconds

        Returns:
            True if successful, False otherwise
        """
        try:
            return self.client.expire(key, seconds)
        except Exception as e:
            logger.error(f"Error setting expiration for key '{key}': {e}")
            return False
```

### TTL Strategies

```python
# Short TTL for volatile data (5 minutes)
cache.set("api:response:latest", data, expire=300)

# Medium TTL for semi-static data (1 hour)
cache.set("user:profile:123", profile, expire=3600)

# Long TTL for static data (24 hours)
cache.set("config:app", config, expire=86400)

# No TTL for persistent cache (manual invalidation)
cache.set("app:version", "1.0.0")

# Update TTL on existing key
cache.expire("session:abc123", 1800)  # Extend to 30 minutes
```

### Best Practices

- **Match data volatility** - shorter TTL for frequently changing data
- **Add jitter** - randomize TTL slightly to prevent thundering herd
- **Monitor hit rates** - adjust TTL based on hit/miss ratio
- **Set default TTL** - always have a fallback expiration
- **Document TTL choices** - explain why each duration was chosen

---

## Rate Limiting with Cache

### Overview

Sliding window rate limiting using Redis sorted sets.

### Implementation

**File Reference**: `sark/src/sark/services/rate_limiter.py:23-129`

```python
from dataclasses import dataclass
import time
import valkey.asyncio as aioredis

@dataclass
class RateLimitInfo:
    """Rate limit information for a request"""
    allowed: bool
    limit: int
    remaining: int
    reset_at: int  # Unix timestamp
    retry_after: int | None = None  # Seconds until reset

class RateLimiter:
    """Redis-backed rate limiter using sliding window algorithm"""

    def __init__(
        self,
        redis_client: aioredis.Redis,
        default_limit: int = 1000,
        window_seconds: int = 3600,
    ):
        """
        Initialize rate limiter.

        Args:
            redis_client: Redis client instance
            default_limit: Default requests allowed per window
            window_seconds: Time window in seconds (default: 1 hour)
        """
        self.redis = redis_client
        self.default_limit = default_limit
        self.window_seconds = window_seconds

    async def check_rate_limit(
        self,
        identifier: str,
        limit: int | None = None,
    ) -> RateLimitInfo:
        """
        Check if request is within rate limit.

        Uses sliding window algorithm with Redis sorted sets.
        Each request is stored with timestamp as score.

        Args:
            identifier: Unique identifier (e.g., "api_key:abc123")
            limit: Custom limit for this identifier

        Returns:
            RateLimitInfo with rate limit status
        """
        limit = limit or self.default_limit
        current_time = time.time()
        window_start = current_time - self.window_seconds

        key = f"rate_limit:{identifier}"

        try:
            # Start pipeline for atomic operations
            pipe = self.redis.pipeline()

            # 1. Remove old entries outside the window
            pipe.zremrangebyscore(key, 0, window_start)

            # 2. Count current requests in window
            pipe.zcard(key)

            # 3. Add current request with timestamp as score
            pipe.zadd(key, {str(current_time): current_time})

            # 4. Set expiry on the key (cleanup)
            pipe.expire(key, self.window_seconds + 60)

            # Execute pipeline
            results = await pipe.execute()

            # Get count (before adding current request)
            current_count = results[1]

            # Calculate remaining and reset time
            allowed = current_count < limit
            remaining = max(0, limit - current_count - (1 if allowed else 0))
            reset_at = int(current_time + self.window_seconds)

            # If limited, calculate retry_after
            retry_after = None
            if not allowed:
                # Get oldest entry timestamp
                oldest_entries = await self.redis.zrange(
                    key, 0, 0, withscores=True
                )
                if oldest_entries:
                    oldest_timestamp = oldest_entries[0][1]
                    retry_after = int(
                        oldest_timestamp + self.window_seconds - current_time
                    )
                    retry_after = max(1, retry_after)

            return RateLimitInfo(
                allowed=allowed,
                limit=limit,
                remaining=remaining,
                reset_at=reset_at,
                retry_after=retry_after,
            )

        except Exception as e:
            logger.error(f"Rate limiter error for {identifier}: {e}")
            # Fail open - allow request if Redis is down
            return RateLimitInfo(
                allowed=True,
                limit=limit,
                remaining=limit,
                reset_at=int(current_time + self.window_seconds),
            )
```

### Usage Example

```python
# API endpoint with rate limiting
@app.post("/api/v1/analyze")
async def analyze(request: Request, redis: Redis = Depends(get_redis)):
    rate_limiter = RateLimiter(redis, default_limit=100, window_seconds=3600)

    # Extract identifier (API key, user ID, IP, etc.)
    api_key = request.headers.get("X-API-Key")
    identifier = f"api_key:{api_key}"

    # Check rate limit
    rate_info = await rate_limiter.check_rate_limit(identifier)

    if not rate_info.allowed:
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded",
            headers={
                "X-RateLimit-Limit": str(rate_info.limit),
                "X-RateLimit-Remaining": "0",
                "X-RateLimit-Reset": str(rate_info.reset_at),
                "Retry-After": str(rate_info.retry_after),
            }
        )

    # Add rate limit headers to response
    response.headers["X-RateLimit-Limit"] = str(rate_info.limit)
    response.headers["X-RateLimit-Remaining"] = str(rate_info.remaining)
    response.headers["X-RateLimit-Reset"] = str(rate_info.reset_at)

    # Process request
    return await process_analysis(request)
```

### Best Practices

- **Fail open** - allow requests if Redis is down (unless strict security)
- **Use pipeline** - atomic operations prevent race conditions
- **Include retry_after** - tell clients when to retry
- **Expose headers** - X-RateLimit-* headers for transparency
- **Per-resource limits** - different limits for different endpoints
- **Clean up old data** - expire keys to prevent memory growth

---

## Sliding Window Algorithm

### Overview

Precise rate limiting using sorted sets for sliding time windows.

### Implementation Details

**File Reference**: `sark/src/sark/services/rate_limiter.py:52-119`

The sliding window algorithm provides precise rate limiting:

```
Timeline:
  |---- Window (3600s) ----|
  ^                        ^
  window_start       current_time

Sorted Set (key="rate_limit:user123"):
  Score (timestamp)  |  Member (request ID)
  ------------------|-----------------------
  1640000000.123    |  "1640000000.123"
  1640000005.456    |  "1640000005.456"
  1640000010.789    |  "1640000010.789"
  ... (more recent requests)
  1640003600.000    |  "1640003600.000" (current)
```

### Algorithm Steps

1. **Remove expired entries** - `ZREMRANGEBYSCORE key 0 window_start`
2. **Count current requests** - `ZCARD key`
3. **Add new request** - `ZADD key current_time current_time`
4. **Set expiration** - `EXPIRE key window_seconds + 60`
5. **Check limit** - compare count to limit
6. **Calculate retry_after** - find oldest entry, calculate when it expires

### Advantages

- **Precise** - exact sliding window, not fixed intervals
- **Fair** - doesn't reset at interval boundaries
- **Efficient** - O(log N) operations with sorted sets
- **Scalable** - distributed across Redis cluster

### Best Practices

- **Atomic operations** - use pipeline for consistency
- **Cleanup old entries** - ZREMRANGEBYSCORE before each check
- **Set expiration** - keys auto-expire for garbage collection
- **Monitor memory** - large windows can consume memory
- **Consider alternatives** - token bucket for burstiness

---

## Cache-Aside Pattern

### Overview

Application manages cache explicitly with fallback to source of truth.

### Implementation

```python
class DataService:
    """Service with cache-aside pattern"""

    def __init__(self, cache: CacheManager, db: Database):
        self.cache = cache
        self.db = db

    async def get_user(self, user_id: str) -> dict:
        """
        Get user with cache-aside pattern.

        Flow:
        1. Try to get from cache
        2. If miss, get from database
        3. Store in cache for next time
        4. Return data
        """
        cache_key = f"user:{user_id}"

        # 1. Try cache first
        cached_data = self.cache.get(cache_key)
        if cached_data is not None:
            logger.debug("cache_hit", key=cache_key)
            return json.loads(cached_data)

        # 2. Cache miss - get from database
        logger.debug("cache_miss", key=cache_key)
        user = await self.db.get_user(user_id)

        if user is None:
            # Cache negative result to prevent repeated lookups
            self.cache.set(cache_key, "null", expire=60)
            return None

        # 3. Store in cache
        self.cache.set(
            cache_key,
            json.dumps(user),
            expire=3600  # 1 hour TTL
        )

        # 4. Return data
        return user

    async def update_user(self, user_id: str, updates: dict) -> dict:
        """
        Update user and invalidate cache.

        Flow:
        1. Update database
        2. Invalidate cache
        3. Optionally warm cache with new data
        """
        # 1. Update database
        user = await self.db.update_user(user_id, updates)

        # 2. Invalidate cache (write-through pattern)
        cache_key = f"user:{user_id}"
        self.cache.delete(cache_key)

        # 3. Optional: Warm cache with new data (write-behind pattern)
        # self.cache.set(cache_key, json.dumps(user), expire=3600)

        return user
```

### Cache Invalidation Strategies

```python
# Strategy 1: Delete on write (lazy reload)
async def update_item(item_id: str, data: dict):
    await db.update(item_id, data)
    cache.delete(f"item:{item_id}")  # Next read will reload

# Strategy 2: Write-through (immediate update)
async def update_item(item_id: str, data: dict):
    item = await db.update(item_id, data)
    cache.set(f"item:{item_id}", json.dumps(item), expire=3600)

# Strategy 3: Write-behind (async update)
async def update_item(item_id: str, data: dict):
    item = await db.update(item_id, data)
    # Queue cache update for background processing
    await cache_update_queue.put((f"item:{item_id}", item))
```

### Best Practices

- **Cache negative results** - prevent repeated DB lookups for missing data
- **Short TTL for negatives** - 60s typical for "not found" results
- **Invalidate on write** - always invalidate cache when data changes
- **Log cache hits/misses** - monitor cache effectiveness
- **Handle serialization** - use consistent JSON encoding

---

## Fail-Open Strategy

### Overview

Graceful degradation when cache is unavailable.

### Implementation

```python
class CacheManager:
    """Cache manager with fail-open strategy"""

    def get(self, key: str) -> str | None:
        """
        Get value from cache with error handling.

        Returns:
            Cached value or None if not found or error
        """
        try:
            return self.client.get(key)
        except Exception as e:
            logger.error(f"Error getting key '{key}' from cache: {e}")
            # Fail open - return None as if cache miss
            return None

    def set(
        self,
        key: str,
        value: str | bytes | int | float,
        expire: int | None = None
    ) -> bool:
        """
        Set value in cache with error handling.

        Returns:
            True if successful, False otherwise
        """
        try:
            return self.client.set(key, value, ex=expire)
        except Exception as e:
            logger.error(f"Error setting key '{key}' in cache: {e}")
            # Fail open - return False but don't raise
            return False

# Usage with fallback
async def get_data(key: str) -> dict:
    """Get data with cache, fallback to source"""
    # Try cache
    cached = cache.get(key)
    if cached:
        return json.loads(cached)

    # Cache miss or error - go to source
    data = await fetch_from_source(key)

    # Try to cache (fail silently if cache down)
    cache.set(key, json.dumps(data), expire=300)

    return data
```

### Fail-Open vs Fail-Closed

**Fail-Open (recommended for most cases)**:
- Cache errors don't block application
- Degrades to uncached performance
- Better availability, slightly worse performance

**Fail-Closed (for strict consistency)**:
- Cache errors cause request failures
- Prevents serving potentially stale data
- Better consistency, worse availability

### Best Practices

- **Default to fail-open** - unless strict consistency required
- **Log all errors** - monitor cache health
- **Alert on repeated failures** - detect cache outages
- **Metrics for fallback** - track cache miss vs cache error
- **Circuit breaker** - stop trying cache if persistent failures

---

## Cache Metrics and Monitoring

### Overview

Track cache performance and health for optimization.

### Implementation

```python
class CacheMetrics:
    """Track cache performance metrics"""

    def __init__(self):
        self.hits = 0
        self.misses = 0
        self.errors = 0
        self.sets = 0
        self.deletes = 0

    def record_hit(self):
        self.hits += 1

    def record_miss(self):
        self.misses += 1

    def record_error(self):
        self.errors += 1

    def record_set(self):
        self.sets += 1

    def record_delete(self):
        self.deletes += 1

    @property
    def hit_rate(self) -> float:
        total = self.hits + self.misses
        return (self.hits / total * 100) if total > 0 else 0

    def get_stats(self) -> dict:
        return {
            "hits": self.hits,
            "misses": self.misses,
            "errors": self.errors,
            "sets": self.sets,
            "deletes": self.deletes,
            "hit_rate": f"{self.hit_rate:.2f}%",
        }

# Instrumented cache wrapper
class InstrumentedCache:
    def __init__(self, cache: CacheManager):
        self.cache = cache
        self.metrics = CacheMetrics()

    def get(self, key: str):
        result = self.cache.get(key)
        if result is not None:
            self.metrics.record_hit()
        else:
            self.metrics.record_miss()
        return result

    def set(self, key: str, value, expire: int | None = None):
        success = self.cache.set(key, value, expire)
        if success:
            self.metrics.record_set()
        else:
            self.metrics.record_error()
        return success

# Periodic metrics reporting
async def report_cache_metrics(cache: InstrumentedCache):
    while True:
        await asyncio.sleep(60)  # Every minute
        stats = cache.metrics.get_stats()
        logger.info("cache_metrics", **stats)
```

### Key Metrics

- **Hit Rate** - percentage of requests served from cache
- **Miss Rate** - percentage requiring source lookup
- **Error Rate** - cache failures per request
- **Latency** - p50, p95, p99 cache operation times
- **Memory Usage** - current Redis memory consumption
- **Evictions** - keys evicted due to memory pressure

### Best Practices

- **Monitor hit rate** - target 80%+ for effective caching
- **Alert on error spike** - >1% errors indicates issues
- **Track per-key metrics** - identify hot keys
- **Log slow operations** - cache should be fast (<1ms typical)
- **Use Redis INFO** - built-in metrics for memory, connections

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Caching Without TTL

**Bad:**
```python
# Cached data never expires
cache.set("user:123", user_data)  # No expiration
```

**Good:**
```python
# Always set appropriate TTL
cache.set("user:123", user_data, expire=3600)
```

---

### ❌ Anti-Pattern 2: Not Invalidating on Update

**Bad:**
```python
# Update database but forget cache
await db.update_user(user_id, updates)
# Cache still has old data!
```

**Good:**
```python
# Always invalidate cache on update
await db.update_user(user_id, updates)
cache.delete(f"user:{user_id}")
```

---

### ❌ Anti-Pattern 3: Caching Large Objects

**Bad:**
```python
# Cache entire large object
cache.set("report:123", huge_report)  # 10MB report
```

**Good:**
```python
# Cache summary or key fields only
cache.set("report:123:summary", report_summary)
# Store full report in object storage
```

---

### ❌ Anti-Pattern 4: No Error Handling

**Bad:**
```python
# Crash on cache errors
value = cache.get(key)  # Raises exception if cache down
```

**Good:**
```python
# Graceful degradation
try:
    value = cache.get(key)
except Exception as e:
    logger.error(f"Cache error: {e}")
    value = None
```

---

### ❌ Anti-Pattern 5: Thundering Herd

**Bad:**
```python
# All requests refresh expired cache simultaneously
if not cache.get(key):
    data = expensive_operation()  # 1000 concurrent calls!
    cache.set(key, data)
```

**Good:**
```python
# Use locking or probabilistic early refresh
lock_key = f"{key}:lock"
if cache.get(key) is None:
    if cache.set(lock_key, "1", expire=10, nx=True):
        try:
            data = expensive_operation()
            cache.set(key, data, expire=300)
        finally:
            cache.delete(lock_key)
    else:
        # Another request is refreshing, wait briefly
        await asyncio.sleep(0.1)
```

---

## 🔗 Related Patterns

- [BATCH_OPERATIONS.md](BATCH_OPERATIONS.md) - Cache batch results
- [ERROR_RECOVERY.md](ERROR_RECOVERY.md) - Handle cache failures
- [STREAMING_PATTERNS.md](STREAMING_PATTERNS.md) - Cache stream checkpoints
- [TOOL_USE_PATTERNS.md](TOOL_USE_PATTERNS.md) - Cache tool responses
- Cross-reference: `agent-rules/python/ASYNC_PATTERNS.md` (from foundation worker)

---

**Last Updated**: 2025-12-26
**Patterns**: 9 documented
**Source**: SARK (v2.0+)
**Lines of Code Analyzed**: ~600 lines

*"The fastest operation is the one you don't have to do - cache wisely."*
