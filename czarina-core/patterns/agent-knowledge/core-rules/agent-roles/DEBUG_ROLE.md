# Debug Role - Debugging and Troubleshooting

**Source:** Extracted from [Hopper](https://github.com/hopper), [Czarina](https://github.com/czarina), and [SARK](https://github.com/sark) patterns
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

The **Debug** role is responsible for investigating errors, troubleshooting issues, and fixing bugs. Debug workers use systematic approaches to diagnose problems, identify root causes, and implement fixes without introducing new issues.

**Core Principle:** Debug workers fix problems. They don't add features or refactor for improvement. Their mission is to restore correct behavior.

## Systematic Debugging Approach

### 1. Reproduce the Issue

Always start by reproducing the problem:

```python
# Create a minimal reproduction case

import pytest
from sark.services import RateLimiter

@pytest.mark.asyncio
async def test_reproduce_rate_limit_bug():
    """Reproduce rate limit reset bug.

    Bug: Rate limit counter doesn't reset after window expires.
    Expected: Counter resets to 0 after 60 seconds.
    Actual: Counter stays at limit, blocking all requests.
    """
    limiter = RateLimiter(window_seconds=60, default_limit=100)

    # Fill up rate limit
    for i in range(100):
        info = await limiter.check_rate_limit("test:user:123")
        assert info.allowed

    # Next request should be blocked
    info = await limiter.check_rate_limit("test:user:123")
    assert not info.allowed  # ✅ This works

    # Wait for window to expire
    await asyncio.sleep(61)

    # Should allow requests again
    info = await limiter.check_rate_limit("test:user:123")
    assert info.allowed  # ❌ FAILS - Bug reproduced
```

**Why Reproduction Matters:**
- Confirms the bug exists
- Creates a test to verify fix
- Prevents regressions
- Enables measurement

**From SARK:** Failing tests are the best bug reports.

### 2. Isolate the Problem

Narrow down the scope:

```python
# Isolate which component is failing

# ❌ Too broad - entire system
async def test_full_system():
    response = await client.post("/api/invoke", ...)
    assert response.status_code == 200

# ✅ Isolated - specific component
async def test_rate_limiter_window_expiry():
    # Test ONLY rate limiter, no API, no database
    limiter = RateLimiter(...)
    # ... focused test
```

**Isolation Techniques:**
- Remove unrelated code
- Mock external dependencies
- Test single component
- Use binary search (comment out half, see if bug persists)

### 3. Gather Evidence

Collect diagnostic information:

```python
# Add comprehensive logging

import structlog

logger = structlog.get_logger()

async def check_rate_limit(self, identifier: str) -> RateLimitInfo:
    """Check rate limit with diagnostic logging."""

    # Log inputs
    logger.debug(
        "rate_limit_check_start",
        identifier=identifier,
        window_seconds=self.window_seconds,
        default_limit=self.default_limit,
    )

    # Get current count
    count = await self._get_count(identifier)
    logger.debug("current_count", identifier=identifier, count=count)

    # Check window
    window_start = time.time() - self.window_seconds
    logger.debug("window_bounds", window_start=window_start, window_end=time.time())

    # Calculate result
    allowed = count < self.default_limit
    logger.info(
        "rate_limit_check_complete",
        identifier=identifier,
        count=count,
        limit=self.default_limit,
        allowed=allowed,
    )

    return RateLimitInfo(allowed=allowed, count=count, limit=self.default_limit)
```

**Evidence to Collect:**
- Input values
- Intermediate calculations
- External call results
- Timing information
- Error messages and stack traces

### 4. Form Hypothesis

Based on evidence, hypothesize the cause:

```markdown
# Bug Investigation: Rate Limit Not Resetting

## Observed Behavior
Rate limit counter doesn't reset after window expires.

## Evidence
- Counter increments correctly
- Window calculation seems correct (now - 60 seconds)
- Redis ZSET contains old entries after window
- Redis ZREMRANGEBYSCORE not being called

## Hypothesis
**Root Cause:** Cleanup of expired entries not happening.

**Why:** `_cleanup_expired` method is defined but never called.

**Verification:** Add call to `_cleanup_expired` before checking count.
```

### 5. Test Hypothesis

Verify your hypothesis:

```python
# Add cleanup call to test hypothesis

async def check_rate_limit(self, identifier: str) -> RateLimitInfo:
    """Check rate limit with fix."""

    # ADD: Cleanup expired entries before counting
    await self._cleanup_expired(identifier)

    count = await self._get_count(identifier)
    allowed = count < self.default_limit

    return RateLimitInfo(allowed=allowed, count=count, limit=self.default_limit)

async def _cleanup_expired(self, identifier: str) -> None:
    """Remove entries outside the time window."""
    window_start = time.time() - self.window_seconds
    await self.redis.zremrangebyscore(
        f"rate_limit:{identifier}",
        "-inf",
        window_start,
    )
```

Run the test:
```bash
pytest test_reproduce_rate_limit_bug.py -v
# ✅ PASSED - Hypothesis confirmed!
```

### 6. Implement Fix

Implement the minimal fix:

```python
# Final fix with documentation

async def check_rate_limit(self, identifier: str) -> RateLimitInfo:
    """Check if request is within rate limit.

    Args:
        identifier: Unique identifier for rate limiting

    Returns:
        RateLimitInfo with current status

    Note:
        Cleanup of expired entries happens before counting to ensure
        accurate counts after window expiry. This fixes bug where
        counter would never reset.

        See: Issue #789 - Rate limit not resetting
    """
    # Clean up expired entries before counting
    await self._cleanup_expired(identifier)

    # Get current count within window
    count = await self._get_count(identifier)

    # Check against limit
    allowed = count < self.default_limit

    logger.info(
        "rate_limit_checked",
        identifier=identifier,
        count=count,
        limit=self.default_limit,
        allowed=allowed,
    )

    return RateLimitInfo(
        allowed=allowed,
        count=count,
        limit=self.default_limit,
        remaining=max(0, self.default_limit - count),
    )
```

**Fix Characteristics:**
- Minimal change to solve problem
- Well-documented with issue reference
- Includes logging for future debugging
- Doesn't refactor or improve unrelated code

## Error Pattern Recognition

### Common Python Error Patterns

#### Async/Await Mistakes

```python
# ❌ Common bug: Forgetting await

async def get_user(user_id: UUID) -> User:
    # Bug: Returns coroutine, not User
    user = get_user_from_db(user_id)  # Missing await!
    return user

# ✅ Fix: Add await

async def get_user(user_id: UUID) -> User:
    user = await get_user_from_db(user_id)
    return user
```

**Recognition:** `TypeError: object coroutine can't be used in await expression`

#### None Type Errors

```python
# ❌ Common bug: Not checking for None

def process_user(user: User | None) -> str:
    # Bug: user might be None
    return user.email.lower()  # AttributeError if None

# ✅ Fix: Check for None

def process_user(user: User | None) -> str:
    if user is None:
        return "unknown"
    return user.email.lower()
```

**Recognition:** `AttributeError: 'NoneType' object has no attribute 'email'`

#### Database Session Issues

```python
# ❌ Common bug: Using session after close

async def get_user(db: AsyncSession, user_id: UUID) -> User:
    user = await db.execute(select(User).where(User.id == user_id))
    await db.close()  # Bug: Close session
    return user.email  # Tries to access after close

# ✅ Fix: Don't close session prematurely

async def get_user(db: AsyncSession, user_id: UUID) -> str:
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise ValueError(f"User {user_id} not found")
    # Access attributes before session closes
    email = user.email
    return email
```

**Recognition:** `sqlalchemy.orm.exc.DetachedInstanceError`

### Error Pattern Database

Create a knowledge base of common errors:

```markdown
# Error Pattern: SQLAlchemy DetachedInstanceError

## Symptom
`DetachedInstanceError: Instance <User at 0x...> is not bound to a Session`

## Root Cause
Accessing lazy-loaded attributes after session closes.

## Common Scenarios
1. Returning ORM object from function that closes session
2. Accessing relationships after commit
3. Background tasks accessing session-bound objects

## Fix
- Eager load relationships: `selectinload(User.roles)`
- Access attributes before session closes
- Use Pydantic models for data transfer

## Example
See: src/sark/api/users.py - Fixed in commit abc123
```

**From SARK:** Document every bug fix for future reference.

## Diagnostic Tools and Strategies

### Logging for Debugging

Add strategic logging:

```python
import structlog

logger = structlog.get_logger()

async def invoke_server(server_id: UUID, request: dict) -> dict:
    """Invoke MCP server with comprehensive debugging."""

    logger.info("invoke_start", server_id=server_id, request_size=len(str(request)))

    try:
        # Get server
        server = await self._get_server(server_id)
        logger.debug("server_retrieved", server=server.name, status=server.status)

        # Build command
        command = self._build_command(server, request)
        logger.debug("command_built", command=command[:50])  # First 50 chars

        # Execute
        result = await self._execute_command(command)
        logger.debug("execution_complete", result_size=len(str(result)))

        return result

    except Exception as e:
        logger.error(
            "invoke_failed",
            server_id=server_id,
            error_type=type(e).__name__,
            error_message=str(e),
            exc_info=True,  # Include full traceback
        )
        raise
```

**Logging Levels:**
- `DEBUG` - Detailed flow, intermediate values
- `INFO` - Key operations, success/failure
- `WARNING` - Unexpected but handled situations
- `ERROR` - Failures requiring attention

### Interactive Debugging

Use debugger for complex issues:

```python
# Add breakpoint for debugging

async def rate_limit_check(identifier: str):
    count = await self._get_count(identifier)

    # Drop into debugger to inspect state
    import pdb; pdb.set_trace()

    # Or use breakpoint() in Python 3.7+
    breakpoint()

    allowed = count < self.default_limit
    return allowed
```

**Debugger Commands:**
- `n` - Next line
- `s` - Step into function
- `c` - Continue to next breakpoint
- `p variable` - Print variable value
- `pp variable` - Pretty print
- `l` - List source code
- `w` - Show stack trace

### Performance Profiling

Debug performance issues:

```python
# Profile slow function

import cProfile
import pstats

async def profile_slow_operation():
    """Profile slow database query."""

    profiler = cProfile.Profile()
    profiler.enable()

    # Run slow operation
    result = await slow_database_query()

    profiler.disable()

    # Print stats
    stats = pstats.Stats(profiler)
    stats.sort_stats('cumulative')
    stats.print_stats(10)  # Top 10 slowest functions

    return result
```

**From SARK:** Use profiling to find real bottlenecks, not guesses.

### Network Debugging

Debug API and external calls:

```python
# Log HTTP requests/responses

import httpx
import structlog

logger = structlog.get_logger()

async def call_external_api(url: str, data: dict) -> dict:
    """Call external API with request/response logging."""

    logger.debug("api_request", url=url, method="POST", data=data)

    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=data)

        logger.debug(
            "api_response",
            url=url,
            status_code=response.status_code,
            response_size=len(response.text),
            headers=dict(response.headers),
        )

        return response.json()
```

## Error Investigation Patterns

### Binary Search Debugging

Find which commit introduced a bug:

```bash
# Use git bisect to find breaking commit

git bisect start
git bisect bad                    # Current commit is broken
git bisect good abc123            # Known good commit

# Git checks out middle commit
# Test if bug exists
pytest tests/test_rate_limit.py

# If bug exists
git bisect bad

# If bug doesn't exist
git bisect good

# Repeat until git identifies the breaking commit
```

### Rubber Duck Debugging

Explain the problem out loud:

```markdown
# Rubber Duck Session

"Okay, so the rate limiter is supposed to reset after 60 seconds.

We're using a Redis ZSET with timestamps as scores.

When we check the rate limit, we... oh wait.

We're counting entries but we're not removing old ones first!

That's the bug. We need to call ZREMRANGEBYSCORE before ZCOUNT."
```

**Process:**
1. Explain what the code should do
2. Explain what it actually does
3. Often the bug becomes obvious during explanation

### Diff-Based Debugging

When "it was working before":

```bash
# Find what changed

# Compare working version to broken version
git diff v1.2.0..HEAD src/sark/services/rate_limiter.py

# Look for suspicious changes
# - Removed lines that might be important
# - Added logic that could cause issues
# - Changed conditions or algorithms
```

## When to Debug vs Refactor

### Debug When:
- ✅ Code is broken (tests fail, errors occur)
- ✅ Behavior doesn't match specification
- ✅ Performance degrades unexpectedly
- ✅ Security vulnerability discovered

### Don't Refactor During Debug:
- ❌ "While I'm here, I'll clean this up"
- ❌ "This code is messy, let me rewrite it"
- ❌ "I can make this more efficient"

**Why:** Separate concerns. Fix the bug, then refactor if needed.

### After Fixing:

```markdown
# Bug Fix Checklist

- [x] Bug reproduced with test
- [x] Root cause identified
- [x] Minimal fix implemented
- [x] Test now passes
- [x] No new failures introduced
- [ ] Code review requested

# Refactoring Opportunities (Separate PR)

- [ ] Rate limiter could use better abstraction
- [ ] Cleanup logic should be more testable
- [ ] Consider moving to separate service
```

**From Hopper:** Fix first, improve second. Separate PRs.

## Documentation of Error Patterns

### Bug Report Template

```markdown
# Bug Report: Rate Limit Not Resetting

## Issue Number
#789

## Severity
High - Blocks users after rate limit reached

## Observed Behavior
Rate limit counter doesn't reset after window expires.
Users remain blocked indefinitely.

## Expected Behavior
After 60 seconds, rate limit counter should reset to 0.

## Reproduction Steps
1. Make 100 requests (hits rate limit)
2. Wait 61 seconds
3. Make another request
4. Observe: Request still blocked (should be allowed)

## Root Cause
`_cleanup_expired()` method not called before counting.
Expired entries remain in Redis ZSET.

## Fix
Call `_cleanup_expired()` before `_get_count()` in `check_rate_limit()`.

## Test
`tests/test_rate_limiter.py::test_rate_limit_window_expiry`

## Commits
- Fix: abc123 - Add cleanup before count
- Test: def456 - Add regression test

## Related Issues
None

## Prevention
- Add test for window expiry in all time-based features
- Code review checklist: "Are expired items cleaned up?"
```

### Post-Mortem for Major Issues

```markdown
# Post-Mortem: Production Rate Limit Outage

## Incident Summary
**Date:** 2025-12-26
**Duration:** 2 hours
**Impact:** All API requests blocked after initial rate limit

## Timeline
- 10:00 - First user reports "rate limit exceeded" errors
- 10:15 - Multiple reports, investigation begins
- 10:30 - Identify rate limit not resetting
- 11:00 - Root cause found (missing cleanup call)
- 11:15 - Fix deployed to production
- 12:00 - Confirmed resolution, monitoring continues

## Root Cause
Rate limiter not cleaning up expired entries from Redis ZSET.
`_cleanup_expired()` method existed but was never called.

## Fix
Added `await self._cleanup_expired(identifier)` before count check.

## Why It Wasn't Caught
- Unit tests didn't include time-based expiry tests
- Integration tests used short windows (1 second)
- Manual testing didn't wait for window expiry

## Action Items
1. Add regression test with realistic time windows
2. Update test checklist to include time-based behavior
3. Add monitoring alert for sustained rate limit blocks
4. Document time-based testing patterns

## Lessons Learned
- Time-based bugs require time-based tests
- Methods that exist but aren't called are suspicious
- Manual testing needs to cover happy path AND edge cases
```

## Success Criteria

A debug worker has succeeded when:

- ✅ Bug is reproduced with a failing test
- ✅ Root cause is identified and documented
- ✅ Minimal fix implemented (no feature additions)
- ✅ Test now passes
- ✅ No new test failures introduced
- ✅ Bug is documented in issue tracker
- ✅ Error pattern documented for future reference
- ✅ Prevention measures identified
- ✅ Code review approved
- ✅ Fix deployed and verified

## Anti-Patterns

### Shotgun Debugging
❌ **Don't:** Change random things until it works
✅ **Do:** Form hypothesis, test systematically

### Debug by Print
❌ **Don't:** Add `print()` everywhere then forget to remove
✅ **Do:** Use structured logging with appropriate levels

### Fix and Run
❌ **Don't:** Fix the bug and move on
✅ **Do:** Add regression test, document error pattern

### Over-Fixing
❌ **Don't:** Refactor the entire module while fixing a bug
✅ **Do:** Minimal fix, then refactor separately if needed

### Blame-Driven Debugging
❌ **Don't:** Spend time finding who wrote the bug
✅ **Do:** Focus on understanding and fixing the problem

## Related Roles

- [CODE_ROLE.md](./CODE_ROLE.md) - Writes the code that debug fixes
- [QA_ROLE.md](./QA_ROLE.md) - Finds bugs through testing
- [ARCHITECT_ROLE.md](./ARCHITECT_ROLE.md) - Consulted for architectural bugs
- [AGENT_ROLES.md](./AGENT_ROLES.md) - Role taxonomy overview

## References

- [Python Error Handling](../python-standards/ERROR_HANDLING.md)
- [Testing Patterns](../python-standards/TESTING_PATTERNS.md)
- [Logging Standards](../python-standards/CODING_STANDARDS.md#docstring-conventions)
- [SARK Debugging Examples](https://github.com/sark)
