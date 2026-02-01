# Error Detection Patterns

Common error patterns and their recognition in AI-assisted development.

---

## Docker & Container Patterns

### Pattern: Port Already in Use

**Error**:
```
Error: failed to bind host port 0.0.0.0:11434: address already in use
```

**Root Cause**: Service already running or orphaned container

**Detection**:
- Port binding errors on container start
- Service fails to start without clear error
- Previous container not properly stopped

**Real Example** (The Symposium):
```bash
# Problem: Ollama port conflict
# Solution: Set SERVER_IP in .env
SERVER_IP=192.168.14.4  # Instead of 0.0.0.0
```

### Pattern: Volume Mount Not Working

**Error**:
```
File not found in container but exists on host
```

**Root Cause**: Volume not mounted or production mode doesn't mount source

**Detection**:
- Files exist on host but not in container
- Changes to code don't reflect in running container
- Hot reload not working

**Real Example** (The Symposium):
```yaml
# Production: No volume mount (baked into image)
# volumes:
#   - ./backend:/app  # Commented out

# Development: Volume mounted (hot reload)
volumes:
  - ./backend:/app  # Enabled in dev mode
```

---

## Python & Async Patterns

### Pattern: Module Not Found

**Error**:
```
ModuleNotFoundError: No module named 'redis'
```

**Root Cause**: Dependencies not installed or wrong Python environment

**Detection**:
- Import errors on module load
- Dependencies missing after container rebuild
- Package version mismatch

### Pattern: Async Function Not Awaited

**Error**:
```
RuntimeWarning: coroutine 'function' was never awaited
```

**Root Cause**: Forgot `await` keyword or called async function from sync context

**Detection**:
- RuntimeWarnings in logs
- Function returns coroutine object instead of value
- Code doesn't execute as expected

**Real Example**:
```python
# Wrong
result = service.get_identity("sage_name")  # Missing await

# Right
result = await service.get_identity("sage_name")
```

---

## Testing Patterns

### Pattern: Test Pollution

**Error**:
```
Tests modify production data
```

**Root Cause**: Tests use real database/services instead of mocks

**Detection**:
- Production data changes after test runs
- Test failures affect other tests
- Tests can't run in isolation

**Real Example** (The Symposium):
```python
# Unit test - mocked (safe)
@pytest.fixture
def mock_opensearch_client():
    client = MagicMock()
    client.index = MagicMock(return_value={"_version": 1})
    return client

# Integration test - isolated (safe)
@pytest.fixture
def sample_sage_name():
    return "test_sage"  # NOT "cicero"!
```

---

## Syntax Error Patterns

### Pattern: Unterminated String

**Error**:
```
SyntaxError: unterminated string literal (detected at line 497)
```

**Root Cause**: Line break in middle of f-string or quote mismatch

**Detection**:
- Python syntax errors on file load
- Editor shows unclosed string
- Line mentioned in error has broken string

**Real Example** (The Symposium):
```python
# Wrong - line break in f-string
f"""Last Updated: {identity['metadata
']['last_modified']}"""

# Right - single line
f"""Last Updated: {identity['metadata']['last_modified']}"""
```

### Pattern: Invalid Syntax (Line Break in Parameter)

**Error**:
```
SyntaxError: invalid syntax (line 477: d,)
```

**Root Cause**: Parameter name split across lines

**Detection**:
- Syntax error with unexpected character
- Orphaned characters in function signature
- Parameter list malformed

**Real Example**:
```python
# Wrong
async def get_pattern(
    self,
    pattern_i
d,  # Split across lines!
    sage_name: str
):

# Right
async def get_pattern(
    self,
    pattern_id: str,
    sage_name: str
):
```

---

## Import & Dependency Patterns

### Pattern: Missing Type Import

**Error**:
```
NameError: name 'List' is not defined
```

**Root Cause**: Forgot to import typing module

**Detection**:
- NameError for type hints
- IDE shows unresolved reference
- Type checker (mypy) errors

---

## Database Patterns

### Pattern: Index Not Found

**Error**:
```
opensearch_exceptions.NotFoundError: index_not_found_exception
```

**Root Cause**: Index doesn't exist or wrong index name

**Detection**:
- NotFoundError when querying database
- Index operations fail
- Fresh database without schema initialization

---

## Git & Version Control Patterns

### Pattern: Merge Conflict

**Error**:
```
CONFLICT (content): Merge conflict in file.py
```

**Root Cause**: Concurrent changes to same lines

**Detection**:
- Git merge/pull fails
- Conflict markers in file
- Git status shows "both modified"

---

## Performance Patterns

### Pattern: Slow Test Execution

**Symptom**: Tests take >10 seconds

**Root Cause**: Not using mocks, hitting real services

**Detection**:
- Test suite takes minutes instead of seconds
- Network activity during unit tests
- Database queries in test logs
- External API calls from tests

---

## Related Patterns

- [Recovery Strategies](./recovery-strategies.md) - How to fix detected errors
- [Retry Patterns](./retry-patterns.md) - Automated recovery approaches
- [Escalation Patterns](./escalation-patterns.md) - When to get human help

---

**Source**: The Symposium development (v0.4.5)
