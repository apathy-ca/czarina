# Python Standards Library

**Source:** Extracted from [SARK](https://github.com/sark) codebase analysis
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This directory contains comprehensive Python coding standards extracted from the SARK codebase. These standards provide best practices for building production-grade Python applications with FastAPI, SQLAlchemy, and modern async patterns.

**What This Library Covers:**
- General coding conventions and style
- Async/await patterns for I/O operations
- Error handling and exception hierarchies
- Dependency injection for testability
- Testing patterns with pytest
- Security patterns for authentication and validation

## Standards Index

### 1. [CODING_STANDARDS.md](./CODING_STANDARDS.md)

**Foundational coding conventions and style guide**

Topics covered:
- File organization and directory structure
- Naming conventions (files, classes, functions, variables)
- Import organization and TYPE_CHECKING pattern
- Type hints and modern union syntax
- Docstring conventions (Google-style)
- Code formatting with Black and Ruff
- Constants and configuration patterns

**When to reference:**
- Starting a new Python project
- Establishing team coding standards
- Code review checklist
- Onboarding new developers

**Key patterns:**
- Layered architecture (models, services, api, adapters)
- `__init__.py` for public API control
- PascalCase for classes, snake_case for functions
- Comprehensive type hints on all public APIs

---

### 2. [ASYNC_PATTERNS.md](./ASYNC_PATTERNS.md)

**Async/await patterns for I/O operations**

Topics covered:
- When to use async vs sync
- Database session management with AsyncGenerator
- Global engine pattern with lazy initialization
- Service layer with async methods
- Streaming patterns with AsyncIterator
- Concurrent operations with asyncio.gather
- FastAPI lifecycle hooks
- Rate limiting with async

**When to reference:**
- Building async APIs with FastAPI
- Database operations with SQLAlchemy async
- Streaming responses
- Concurrent task execution
- Resource initialization and cleanup

**Key patterns:**
- `AsyncGenerator[AsyncSession, None]` for database sessions
- Global engine singleton with lazy initialization
- `AsyncIterator` for streaming
- `asyncio.gather` for parallel operations
- Lifespan context manager for startup/shutdown

---

### 3. [ERROR_HANDLING.md](./ERROR_HANDLING.md)

**Exception handling and error recovery**

Topics covered:
- Custom exception hierarchies
- Structured error context (to_dict pattern)
- Fail-open vs fail-closed patterns
- Database session rollback
- Structured logging with error context
- FastAPI exception handlers
- Retry mechanisms with exponential backoff
- Error enrichment as exceptions propagate

**When to reference:**
- Designing exception hierarchies
- Implementing error handling strategy
- Logging errors for debugging
- Building resilient services
- Creating API error responses

**Key patterns:**
- Base exception class with rich context
- Specialized exceptions (ValidationError, TimeoutError)
- `to_dict()` method for API responses
- Fail-open for non-critical services
- Automatic rollback in database sessions

---

### 4. [DEPENDENCY_INJECTION.md](./DEPENDENCY_INJECTION.md)

**Dependency injection for loose coupling**

Topics covered:
- Constructor injection for services
- Pydantic Settings with @lru_cache
- FastAPI Depends() pattern
- Type aliases for dependencies
- Dependency factories (require_role, require_permission)
- Lazy initialization patterns
- Global engine/client singletons
- Testing with dependency overrides

**When to reference:**
- Service layer design
- Configuration management
- Authentication and authorization
- Testing services in isolation
- Managing database sessions

**Key patterns:**
- Services accept AsyncSession in constructor
- Settings loaded once with @lru_cache
- Type aliases: `CurrentUser = Annotated[UserContext, Depends(get_current_user)]`
- Dependency factories for authorization
- Global singletons for connection pools

---

### 5. [TESTING_PATTERNS.md](./TESTING_PATTERNS.md)

**Testing with pytest and comprehensive coverage**

Topics covered:
- Test organization mirroring source structure
- Test class organization
- Fixture patterns (db_session, mock_redis)
- AsyncMock for async functions
- Parametric fixtures
- Pytest markers (asyncio, parametrize, skip)
- Contract testing (BaseAdapterTest)
- Test naming conventions
- Mocking best practices

**When to reference:**
- Writing unit tests
- Creating test fixtures
- Testing async code
- Mocking external dependencies
- Organizing test suites
- Contract testing for interfaces

**Key patterns:**
- `conftest.py` for shared fixtures
- `@pytest.mark.asyncio` for async tests
- `AsyncMock()` for async methods
- Factory fixtures for test data
- Contract tests for interface compliance

---

### 6. [SECURITY_PATTERNS.md](./SECURITY_PATTERNS.md)

**Security best practices and patterns**

Topics covered:
- Pydantic validation for input
- Field validators for security
- Injection detection pattern
- Secret scanning with redaction
- Multi-provider authentication
- Middleware-based auth
- Role-based access control
- UserContext pattern
- Secure logging practices

**When to reference:**
- API input validation
- Authentication implementation
- Authorization and RBAC
- Protecting against injection attacks
- Secret management
- Security audits

**Key patterns:**
- Pydantic field validators prevent injection
- JWT middleware for authentication
- UserContext for authorization
- Injection detector scans user input
- Secret scanner with redaction
- Constant-time comparison for secrets

---

## Quick Reference Guide

### When to Use Which Standard

| Task | Primary Standard | Supporting Standards |
|------|-----------------|---------------------|
| **Starting new project** | CODING_STANDARDS | All others |
| **Building FastAPI endpoints** | ASYNC_PATTERNS | DEPENDENCY_INJECTION, ERROR_HANDLING |
| **Database operations** | ASYNC_PATTERNS | ERROR_HANDLING, DEPENDENCY_INJECTION |
| **Service layer design** | DEPENDENCY_INJECTION | CODING_STANDARDS, ERROR_HANDLING |
| **Error handling strategy** | ERROR_HANDLING | CODING_STANDARDS, ASYNC_PATTERNS |
| **Writing tests** | TESTING_PATTERNS | DEPENDENCY_INJECTION, ASYNC_PATTERNS |
| **Authentication/Authorization** | SECURITY_PATTERNS | DEPENDENCY_INJECTION, ERROR_HANDLING |
| **Input validation** | SECURITY_PATTERNS | CODING_STANDARDS |
| **Configuration management** | DEPENDENCY_INJECTION | CODING_STANDARDS |
| **API documentation** | CODING_STANDARDS | All others |

### Common Workflows

#### Creating a New API Endpoint

1. **Define request/response models** (CODING_STANDARDS, SECURITY_PATTERNS)
   - Use Pydantic with field validators
   - Add security validation

2. **Create service layer** (DEPENDENCY_INJECTION, ASYNC_PATTERNS)
   - Constructor injection for dependencies
   - Async methods for I/O operations

3. **Implement endpoint** (ASYNC_PATTERNS, ERROR_HANDLING)
   - Use FastAPI Depends() for injection
   - Handle errors with custom exceptions

4. **Write tests** (TESTING_PATTERNS)
   - Unit tests for service layer
   - Integration tests for endpoint

#### Building a Service

1. **Design interface** (CODING_STANDARDS)
   - Clear method signatures
   - Comprehensive docstrings

2. **Implement with DI** (DEPENDENCY_INJECTION)
   - Accept dependencies in constructor
   - Use type hints

3. **Add error handling** (ERROR_HANDLING)
   - Custom exceptions
   - Proper logging

4. **Test thoroughly** (TESTING_PATTERNS)
   - Mock dependencies
   - Test error conditions

#### Securing an Endpoint

1. **Add input validation** (SECURITY_PATTERNS)
   - Pydantic models
   - Field validators

2. **Implement authentication** (SECURITY_PATTERNS, DEPENDENCY_INJECTION)
   - JWT middleware
   - Token validation

3. **Add authorization** (SECURITY_PATTERNS, DEPENDENCY_INJECTION)
   - UserContext pattern
   - require_role/require_permission dependencies

4. **Test security** (TESTING_PATTERNS, SECURITY_PATTERNS)
   - Test unauthorized access
   - Test injection attempts

## How Standards Relate to Each Other

```
                    CODING_STANDARDS
                           |
                    (Foundation for all)
                           |
        +------------------+------------------+
        |                  |                  |
  ASYNC_PATTERNS   DEPENDENCY_INJECTION   ERROR_HANDLING
        |                  |                  |
        +--------+---------+--------+---------+
                 |                  |
          TESTING_PATTERNS   SECURITY_PATTERNS
```

**Dependency Flow:**
- CODING_STANDARDS: Foundation referenced by all
- ASYNC_PATTERNS: Uses DEPENDENCY_INJECTION for sessions
- DEPENDENCY_INJECTION: Uses ERROR_HANDLING for validation
- ERROR_HANDLING: Uses CODING_STANDARDS for structure
- TESTING_PATTERNS: Uses all patterns to test them
- SECURITY_PATTERNS: Uses DEPENDENCY_INJECTION for auth

**Information Flow:**
- Start with CODING_STANDARDS for structure
- Apply ASYNC_PATTERNS for I/O operations
- Use DEPENDENCY_INJECTION for loose coupling
- Implement ERROR_HANDLING for resilience
- Follow SECURITY_PATTERNS for protection
- Validate with TESTING_PATTERNS

## Compliance Checklist

Use this checklist to verify adherence to standards:

### Code Quality
- [ ] Follows naming conventions (CODING_STANDARDS)
- [ ] Has comprehensive type hints (CODING_STANDARDS)
- [ ] Includes Google-style docstrings (CODING_STANDARDS)
- [ ] Passes Black and Ruff (CODING_STANDARDS)
- [ ] Imports organized correctly (CODING_STANDARDS)

### Architecture
- [ ] Uses constructor injection (DEPENDENCY_INJECTION)
- [ ] Services accept AsyncSession (ASYNC_PATTERNS, DEPENDENCY_INJECTION)
- [ ] Configuration uses Pydantic Settings (DEPENDENCY_INJECTION)
- [ ] Proper exception hierarchy (ERROR_HANDLING)
- [ ] Middleware for cross-cutting concerns (SECURITY_PATTERNS)

### Async Patterns
- [ ] All I/O operations are async (ASYNC_PATTERNS)
- [ ] Database sessions use AsyncGenerator (ASYNC_PATTERNS)
- [ ] Streaming uses AsyncIterator (ASYNC_PATTERNS)
- [ ] No blocking operations in async code (ASYNC_PATTERNS)
- [ ] Proper resource cleanup (ASYNC_PATTERNS)

### Error Handling
- [ ] Custom exceptions with context (ERROR_HANDLING)
- [ ] Structured logging (ERROR_HANDLING)
- [ ] Proper error propagation (ERROR_HANDLING)
- [ ] FastAPI exception handlers (ERROR_HANDLING)
- [ ] Database rollback on errors (ERROR_HANDLING)

### Testing
- [ ] Test structure mirrors source (TESTING_PATTERNS)
- [ ] Comprehensive fixtures (TESTING_PATTERNS)
- [ ] AsyncMock for async functions (TESTING_PATTERNS)
- [ ] Contract tests for interfaces (TESTING_PATTERNS)
- [ ] Descriptive test names (TESTING_PATTERNS)

### Security
- [ ] Input validation with Pydantic (SECURITY_PATTERNS)
- [ ] Authentication middleware (SECURITY_PATTERNS)
- [ ] Authorization dependencies (SECURITY_PATTERNS)
- [ ] No sensitive data in logs (SECURITY_PATTERNS)
- [ ] Injection detection (SECURITY_PATTERNS)

## Tools and Configuration

### Required Tools

```bash
# Install development dependencies
pip install black ruff pytest pytest-asyncio mypy

# Format code
black src/ tests/
ruff check src/ tests/ --fix

# Type checking
mypy src/

# Run tests
pytest tests/ -v
```

### Recommended pyproject.toml

```toml
[tool.black]
line-length = 100
target-version = ['py311']

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = [
    "E",      # pycodestyle errors
    "W",      # pycodestyle warnings
    "F",      # pyflakes
    "I",      # isort
    "N",      # pep8-naming
    "UP",     # pyupgrade
    "ASYNC",  # async best practices
    "S",      # bandit security
    "B",      # bugbear
    "A",      # builtins
    "C4",     # comprehensions
    "DTZ",    # datetime
    "RUF",    # ruff-specific
]

[tool.ruff.lint.isort]
force-sort-within-sections = true
known-first-party = ["your_package"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
markers = [
    "integration: Integration tests (slow)",
    "unit: Unit tests (fast)",
    "security: Security-related tests",
]

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
```

## Contributing to Standards

When proposing updates to these standards:

1. **Reference SARK examples** - All patterns should be grounded in real code
2. **Provide rationale** - Explain why the pattern is beneficial
3. **Include examples** - Show both good and bad approaches
4. **Update related standards** - Ensure consistency across documents
5. **Test the pattern** - Verify it works in practice

## Additional Resources

### Documentation
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy Async Documentation](https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [Pytest Documentation](https://docs.pytest.org/)

### Python Enhancement Proposals (PEPs)
- [PEP 8 – Style Guide for Python Code](https://peps.python.org/pep-0008/)
- [PEP 484 – Type Hints](https://peps.python.org/pep-0484/)
- [PEP 492 – Coroutines with async and await](https://peps.python.org/pep-0492/)
- [PEP 585 – Type Hinting Generics](https://peps.python.org/pep-0585/)

### Security Resources
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)

### Source
- [SARK Codebase](https://github.com/sark) - Original source of these patterns

## Version History

- **1.0.0** (2025-12-26) - Initial release
  - CODING_STANDARDS.md
  - ASYNC_PATTERNS.md
  - ERROR_HANDLING.md
  - DEPENDENCY_INJECTION.md
  - TESTING_PATTERNS.md
  - SECURITY_PATTERNS.md
  - README.md (this file)
