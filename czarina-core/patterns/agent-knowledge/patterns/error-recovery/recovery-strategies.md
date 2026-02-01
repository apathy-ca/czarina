# Recovery Strategies

Systematic approaches to recovering from detected errors.

---

## Docker & Container Recovery

### Port Conflict Recovery

**Recovery Strategy**:
1. Check what's using the port: `lsof -i :11434`
2. Check for orphaned containers: `docker ps -a | grep <service>`
3. Stop conflicting service: `docker stop <container>`
4. Or change port binding in docker-compose.yml

**Prevention**:
- Use specific IP bindings (192.168.x.x) instead of 0.0.0.0
- Always stop services cleanly
- Use control scripts that handle cleanup

### Volume Mount Recovery

**Recovery Strategy**:
1. Check docker-compose.yml for volume mounts
2. Verify production vs. development mode
3. Rebuild container if needed: `./control-script.sh restart --build`
4. Or switch to development mode: `./control-script.sh up --dev`

**Prevention**:
- Document which modes mount volumes
- Use development mode for testing
- Rebuild after adding new files

---

## Python & Async Recovery

### Module Not Found Recovery

**Recovery Strategy**:
1. Check if running in container: `docker exec <container> pip list`
2. Install missing package: Add to requirements.txt
3. Rebuild container: `./control-script.sh restart --build`
4. Or install in running container: `docker exec <container> pip install <package>`

**Prevention**:
- Always add dependencies to requirements.txt
- Use flexible version constraints (>=)
- Test in container, not host

### Async Function Recovery

**Recovery Strategy**:
1. Add `await` if in async context
2. Use `asyncio.run()` if in sync context
3. Check function signature (async def vs. def)

**Prevention**:
- Mark async functions clearly
- Use type hints
- Run linters (mypy, pylint)

---

## Testing Recovery

### Test Pollution Recovery

**Recovery Strategy**:
1. Use mocked dependencies for unit tests
2. Use test-prefixed indices for integration tests
3. Use test sage names (`test_sage` not `cicero`)
4. Add cleanup fixtures

**Prevention**:
- Always mock external dependencies
- Use test fixtures with cleanup
- Never use production identifiers in tests

---

## Syntax Error Recovery

### Unterminated String Recovery

**Recovery Strategy**:
1. Check line mentioned in error
2. Look for unclosed quotes
3. Check for line breaks in f-strings
4. Verify matching quote types

**Prevention**:
- Use linters (flake8, black)
- Keep f-strings on single lines
- Use triple quotes for multi-line strings

### Invalid Syntax Recovery

**Recovery Strategy**:
1. Check function signature
2. Look for orphaned characters
3. Rejoin split parameters

**Prevention**:
- Use code formatter (black)
- Enable editor auto-formatting
- Review diffs before committing

---

## Import & Dependency Recovery

### Missing Type Import Recovery

**Recovery Strategy**:
1. Add missing import: `from typing import List, Dict, Optional`
2. Check all type hints in file
3. Use modern syntax (Python 3.9+): `list[str]` instead of `List[str]`

**Prevention**:
- Import all types at top of file
- Use IDE with auto-import
- Run type checker (mypy)

---

## Database Recovery

### Index Not Found Recovery

**Recovery Strategy**:
1. Check if index exists: `curl localhost:9200/_cat/indices`
2. Create index if missing: Call `ensure_index_exists()`
3. Verify index name matches schema

**Prevention**:
- Always call `ensure_index_exists()` in service init
- Use constants for index names
- Document index schemas

---

## Git & Version Control Recovery

### Merge Conflict Recovery

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

## Performance Recovery

### Slow Test Recovery

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

## General Recovery Principles

### Root Cause Analysis

**Process**:
1. Read the error message carefully
2. Identify the specific line or component
3. Check recent changes
4. Verify assumptions
5. Test hypothesis

### Diagnostic Commands

**Common diagnostics**:
```bash
# Docker
docker ps -a
docker logs <container>
docker exec <container> <command>

# Python
pip list
python -m pytest -v
python -m mypy <file>

# Database
curl localhost:9200/_cat/indices
curl localhost:9200/_cluster/health

# Git
git status
git log --oneline -5
git diff
```

### Service Restoration

**Steps**:
1. Stop affected services
2. Clean up resources (ports, volumes, temp files)
3. Verify configuration
4. Restart services
5. Verify functionality
6. Monitor for errors

---

## Related Patterns

- [Detection Patterns](./detection-patterns.md) - Recognizing errors
- [Retry Patterns](./retry-patterns.md) - Automated recovery
- [Fallback Patterns](./fallback-patterns.md) - Alternative approaches
- [Escalation Patterns](./escalation-patterns.md) - When to get help

---

**Source**: The Symposium development (v0.4.5)
