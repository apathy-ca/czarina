# Fallback Patterns

Graceful degradation and fallback mechanisms when primary approaches fail.

---

## Philosophy

**Fallback Goals**:
- Maintain partial functionality
- Provide degraded service rather than total failure
- Use cached or default data when live data unavailable
- Fail gracefully with useful error messages

**When to Use Fallbacks**:
- External service is down
- Primary data source unavailable
- Resource limits exceeded
- Performance degradation detected

---

## Alternative Data Sources

### Cache Fallback

**Pattern**: Use cached data when live source fails.

```python
async def get_user_data(user_id: str) -> dict:
    """Get user data with cache fallback."""
    try:
        # Try primary source
        data = await api.fetch_user(user_id)
        await cache.set(f"user:{user_id}", data, ttl=300)
        return data
    except Exception as e:
        logger.warning(f"API failed, using cache: {e}")

        # Fallback to cache
        cached = await cache.get(f"user:{user_id}")
        if cached:
            return cached

        # Ultimate fallback
        raise ServiceUnavailableError("User data unavailable")
```

### Stale Data Fallback

**Pattern**: Accept stale data rather than no data.

```python
async def get_metrics(metric_name: str, max_age_seconds: int = 300) -> dict:
    """Get metrics, accepting stale data if fresh unavailable."""
    try:
        # Try to get fresh data
        return await metrics_service.get_current(metric_name)
    except Exception:
        # Accept stale data
        stale = await cache.get(metric_name, max_age=max_age_seconds)
        if stale:
            logger.info(f"Using stale metrics data (age: {stale.age}s)")
            return stale

        raise
```

---

## Degraded Mode Operation

### Feature Toggle Fallback

**Pattern**: Disable non-critical features when resources limited.

```python
class FeatureFlags:
    def __init__(self):
        self.enabled_features = {
            "analytics": True,
            "recommendations": True,
            "advanced_search": True,
        }

    async def check_system_health(self):
        """Disable features if system under stress."""
        health = await system.get_health_metrics()

        if health.cpu_usage > 80:
            logger.warning("High CPU, disabling non-critical features")
            self.enabled_features["recommendations"] = False
            self.enabled_features["advanced_search"] = False

        if health.memory_usage > 90:
            logger.warning("High memory, disabling analytics")
            self.enabled_features["analytics"] = False

async def search(query: str, features: FeatureFlags) -> list:
    """Search with feature fallbacks."""
    # Basic search always works
    results = await basic_search(query)

    # Advanced features only if enabled
    if features.enabled_features["advanced_search"]:
        results = await enhance_results(results)

    if features.enabled_features["recommendations"]:
        results = await add_recommendations(results)

    return results
```

### Read-Only Mode

**Pattern**: Allow reads when writes fail.

```python
class Database:
    def __init__(self):
        self.read_only = False

    async def write(self, data: dict):
        """Write to database with read-only fallback."""
        if self.read_only:
            raise ReadOnlyModeError("Database in read-only mode")

        try:
            await self._write_to_primary(data)
        except Exception as e:
            logger.error(f"Write failed, entering read-only mode: {e}")
            self.read_only = True
            raise

    async def read(self, query: str):
        """Reads always work, even in read-only mode."""
        try:
            return await self._query_primary(query)
        except Exception:
            # Fallback to replica
            return await self._query_replica(query)
```

---

## Default Values and Safe Modes

### Configuration Defaults

**Pattern**: Use safe defaults when configuration fails to load.

```python
class Config:
    DEFAULTS = {
        "max_connections": 10,
        "timeout_seconds": 30,
        "retry_attempts": 3,
        "cache_ttl": 300,
    }

    @classmethod
    def load(cls, config_file: str) -> dict:
        """Load config with fallback to defaults."""
        try:
            with open(config_file) as f:
                config = json.load(f)
                logger.info(f"Loaded config from {config_file}")
                return {**cls.DEFAULTS, **config}
        except FileNotFoundError:
            logger.warning(f"Config file not found, using defaults")
            return cls.DEFAULTS.copy()
        except json.JSONDecodeError as e:
            logger.error(f"Invalid config file: {e}, using defaults")
            return cls.DEFAULTS.copy()
```

### Empty/Null Object Pattern

**Pattern**: Return empty but valid object instead of None.

```python
class EmptySearchResults:
    """Null object pattern for search results."""
    def __init__(self):
        self.results = []
        self.total = 0
        self.took_ms = 0

    def is_empty(self) -> bool:
        return True

async def search(query: str) -> SearchResults:
    """Search with empty results fallback."""
    try:
        return await search_service.query(query)
    except Exception as e:
        logger.error(f"Search failed: {e}")
        return EmptySearchResults()

# Usage - no None checks needed
results = await search("test")
for result in results.results:  # Safe even when empty
    print(result)
```

---

## Resource Substitution

### Alternative Service Provider

**Pattern**: Switch to backup service when primary fails.

```python
class MultiProviderService:
    def __init__(self):
        self.providers = [
            PrimaryProvider(),
            BackupProvider(),
            FallbackProvider(),
        ]

    async def execute(self, request: dict):
        """Try providers in order until one succeeds."""
        last_error = None

        for provider in self.providers:
            try:
                return await provider.process(request)
            except Exception as e:
                logger.warning(f"{provider.name} failed: {e}")
                last_error = e
                continue

        # All providers failed
        raise AllProvidersFailedError(
            f"All providers failed. Last error: {last_error}"
        )
```

### Local Fallback

**Pattern**: Use local resources when remote unavailable.

```python
async def get_model_response(prompt: str) -> str:
    """Get AI response with local fallback."""
    try:
        # Try cloud API
        return await cloud_api.generate(prompt)
    except Exception as e:
        logger.warning(f"Cloud API failed, using local model: {e}")

        # Fallback to local model
        return await local_model.generate(prompt)
```

---

## Graceful Error Messages

### User-Friendly Fallback

**Pattern**: Show helpful message instead of cryptic error.

```python
async def display_user_profile(user_id: str):
    """Display profile with graceful fallback."""
    try:
        profile = await get_user_profile(user_id)
        return render_profile(profile)
    except UserNotFoundError:
        return {
            "message": "User not found",
            "suggestion": "Please check the user ID and try again"
        }
    except ServiceUnavailableError:
        return {
            "message": "Profile temporarily unavailable",
            "suggestion": "Please try again in a few moments",
            "cached_data": await get_cached_profile(user_id)
        }
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return {
            "message": "Something went wrong",
            "suggestion": "Please contact support if this persists"
        }
```

---

## Circuit Breaker Integration

### Fallback on Open Circuit

**Pattern**: Use fallback when circuit breaker is open.

```python
async def get_recommendations(user_id: str) -> list:
    """Get recommendations with fallback when circuit open."""
    try:
        return await circuit_breaker.call(
            recommendations_service.get,
            user_id
        )
    except CircuitOpenError:
        logger.info("Recommendations service unavailable, using fallback")

        # Fallback strategies in priority order
        # 1. Cached recommendations
        cached = await cache.get(f"rec:{user_id}")
        if cached:
            return cached

        # 2. Popular items (good enough)
        return await get_popular_items()

        # 3. Empty list (degraded but functional)
        # return []
```

---

## Real-World Examples

### The Symposium: Identity Service Fallback

```python
async def get_sage_identity(sage_name: str):
    """Get sage identity with fallback chain."""
    try:
        # Try OpenSearch (primary)
        return await opensearch.get_identity(sage_name)
    except NotFoundError:
        # Try creating default identity
        logger.info(f"Identity not found, creating default for {sage_name}")
        return await create_default_identity(sage_name)
    except ConnectionError:
        # Use cached identity
        cached = await redis.get(f"identity:{sage_name}")
        if cached:
            logger.warning("Using cached identity (OpenSearch unavailable)")
            return cached

        # Ultimate fallback: minimal identity
        return {
            "sage_name": sage_name,
            "status": "unknown",
            "note": "Operating with degraded identity service"
        }
```

---

## Best Practices

### Do's

- Provide multiple fallback levels
- Log when using fallbacks (for debugging)
- Cache data proactively for fallback use
- Make fallback behavior configurable
- Test fallback paths regularly
- Document degraded mode behavior

### Don'ts

- Don't hide errors completely (log them)
- Don't use stale data without indicating it
- Don't make fallback behavior too complex
- Don't forget to return to primary when available
- Don't use fallbacks for errors that need fixing

---

## Related Patterns

- [Retry Patterns](./retry-patterns.md) - When to retry vs. fallback
- [Detection Patterns](./detection-patterns.md) - Triggering fallbacks
- [Escalation Patterns](./escalation-patterns.md) - When fallbacks aren't enough

---

**Source**: The Symposium development (v0.4.5)
