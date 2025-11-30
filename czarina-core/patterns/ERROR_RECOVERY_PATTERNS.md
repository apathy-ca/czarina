# Error Recovery Patterns for AI-Assisted Development

**Purpose**: Common errors and proven recovery strategies when working with AI coding assistants.

**Value**: 30-50% reduction in debugging time by recognizing patterns quickly.

---

## 🎯 Philosophy

**Good error recovery**:
- Recognizes patterns quickly
- Has systematic approaches
- Prevents recurrence
- Documents solutions

**Bad error recovery**:
- Tries random fixes
- Doesn't learn from mistakes
- Repeats same errors
- Wastes time

---

## 🐳 Docker & Container Patterns

### Pattern: Port Already in Use

**Error**:
```
Error: failed to bind host port 0.0.0.0:11434: address already in use
```

**Root Cause**: Service already running or orphaned container

**Recovery Strategy**:
1. Check what's using the port: `lsof -i :11434`
2. Check for orphaned containers: `docker ps -a | grep <service>`
3. Stop conflicting service: `docker stop <container>`
4. Or change port binding in docker-compose.yml

**Prevention**:
- Use specific IP bindings (192.168.x.x) instead of 0.0.0.0
- Always stop services cleanly
- Use control scripts that handle cleanup

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

**Recovery Strategy**:
1. Check docker-compose.yml for volume mounts
2. Verify production vs. development mode
3. Rebuild container if needed: `./control-script.sh restart --build`
4. Or switch to development mode: `./control-script.sh up --dev`

**Prevention**:
- Document which modes mount volumes
- Use development mode for testing
- Rebuild after adding new files

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

## 🐍 Python & Async Patterns

### Pattern: Module Not Found

**Error**:
```
ModuleNotFoundError: No module named 'redis'
```

**Root Cause**: Dependencies not installed or wrong Python environment

**Recovery Strategy**:
1. Check if running in container: `docker exec <container> pip list`
2. Install missing package: Add to requirements.txt
3. Rebuild container: `./control-script.sh restart --build`
4. Or install in running container: `docker exec <container> pip install <package>`

**Prevention**:
- Always add dependencies to requirements.txt
- Use flexible version constraints (>=)
- Test in container, not host

### Pattern: Async Function Not Awaited

**Error**:
```
RuntimeWarning: coroutine 'function' was never awaited
```

**Root Cause**: Forgot `await` keyword or called async function from sync context

**Recovery Strategy**:
1. Add `await` if in async context
2. Use `asyncio.run()` if in sync context
3. Check function signature (async def vs. def)

**Prevention**:
- Mark async functions clearly
- Use type hints
- Run linters (mypy, pylint)

**Real Example**:
```python
# Wrong
result = service.get_identity("sage_name")  # Missing await

# Right
result = await service.get_identity("sage_name")
```

---

## 🔍 Testing Patterns

### Pattern: Test Pollution

**Error**:
```
Tests modify production data
```

**Root Cause**: Tests use real database/services instead of mocks

**Recovery Strategy**:
1. Use mocked dependencies for unit tests
2. Use test-prefixed indices for integration tests
3. Use test sage names (`test_sage` not `cicero`)
4. Add cleanup fixtures

**Prevention**:
- Always mock external dependencies
- Use test fixtures with cleanup
- Never use production identifiers in tests

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

## 📝 Syntax Error Patterns

### Pattern: Unterminated String

**Error**:
```
SyntaxError: unterminated string literal (detected at line 497)
```

**Root Cause**: Line break in middle of f-string or quote mismatch

**Recovery Strategy**:
1. Check line mentioned in error
2. Look for unclosed quotes
3. Check for line breaks in f-strings
4. Verify matching quote types

**Prevention**:
- Use linters (flake8, black)
- Keep f-strings on single lines
- Use triple quotes for multi-line strings

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

**Recovery Strategy**:
1. Check function signature
2. Look for orphaned characters
3. Rejoin split parameters

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

## 🔧 Import & Dependency Patterns

### Pattern: Missing Type Import

**Error**:
```
NameError: name 'List' is not defined
```

**Root Cause**: Forgot to import typing module

**Recovery Strategy**:
1. Add missing import: `from typing import List, Dict, Optional`
2. Check all type hints in file
3. Use modern syntax (Python 3.9+): `list[str]` instead of `List[str]`

**Prevention**:
- Import all types at top of file
- Use IDE with auto-import
- Run type checker (mypy)

---

## 🗄️ Database Patterns

### Pattern: Index Not Found

**Error**:
```
opensearch_exceptions.NotFoundError: index_not_found_exception
```

**Root Cause**: Index doesn't exist or wrong index name

**Recovery Strategy**:
1. Check if index exists: `curl localhost:9200/_cat/indices`
2. Create index if missing: Call `ensure_index_exists()`
3. Verify index name matches schema

**Prevention**:
- Always call `ensure_index_exists()` in service init
- Use constants for index names
- Document index schemas

---

## 🔄 Git & Version Control Patterns

### Pattern: Merge Conflict

**Error**:
```
CONFLICT (content): Merge conflict in file.py
```

**Recovery Strategy**:
1. Open conflicted file
2. Look for `<<<<<<<`, `=======`, `>>>>>>>` markers
3. Choose correct version or merge manually
4. Remove conflict markers
5. Test the merged code
6. Commit: `git add <file> && git commit`

**Prevention**:
- Pull before starting work
- Commit frequently
- Use feature branches
- Communicate with team

---

## 📊 Performance Patterns

### Pattern: Slow Test Execution

**Symptom**: Tests take >10 seconds

**Root Cause**: Not using mocks, hitting real services

**Recovery Strategy**:
1. Profile tests: `pytest --durations=10`
2. Identify slow tests
3. Add mocks for external services
4. Use fixtures for expensive setup

**Prevention**:
- Mock all external dependencies
- Use in-memory databases for tests
- Parallelize test execution

---

## 🎓 Learning from Errors

### Meta-Pattern: Document New Errors

**When you encounter a new error**:
1. Note the error message
2. Document the root cause
3. Record the solution
4. Add to this file
5. Prevent recurrence

**Template**:
```markdown
### Pattern: [Error Name]

**Error**: [Exact error message]
**Root Cause**: [Why it happened]
**Recovery Strategy**: [Step-by-step fix]
**Prevention**: [How to avoid]
**Real Example**: [Code snippet]
```

---

## 🔗 Related Patterns

- [TOOL_USE_PATTERNS.md](TOOL_USE_PATTERNS.md) - Efficient tool usage
- [TESTING_PATTERNS.md](TESTING_PATTERNS.md) - Testing strategies
- [GIT_WORKFLOW_PATTERNS.md](GIT_WORKFLOW_PATTERNS.md) - Git discipline

---

**Last Updated**: 2025-11-29  
**Patterns**: 12 documented  
**Source**: The Symposium development (v0.4.5)

*"Every error is a pattern waiting to be recognized."*