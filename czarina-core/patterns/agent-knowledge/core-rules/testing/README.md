# Testing Standards for Agent Development

Comprehensive testing standards, patterns, and best practices extracted from thesymposium and SARK projects.

## Overview

This directory contains comprehensive testing documentation for agent development projects. These standards ensure reliable, maintainable, and well-tested code across all agent implementations.

**Source Projects**:
- **thesymposium** - Testing policy, best practices, and patterns
- **SARK** - Unit testing, integration testing, mocking, and coverage
- **czarina** - Integration testing patterns

## Quick Reference

### Testing Pyramid

```
        /\
       /  \      E2E Tests (Few)
      /____\     - Full system integration
     /      \    - User workflows
    /________\   Integration Tests (Some)
   /          \  - Component interaction
  /____________\ - API contracts
 /              \ Unit Tests (Many)
/______________\ - Individual functions
                 - Business logic
```

### Coverage Targets

- **New Code**: 80% minimum
- **Critical Paths**: 90% minimum
- **Overall Project**: 85%+

### Test Speed Targets

- **Unit Tests**: < 100ms per test
- **Integration Tests**: < 10s per test
- **Load Tests**: > 30s per test

## Documentation Index

### [TESTING_POLICY.md](TESTING_POLICY.md)

**When to read**: Before starting any development work

**Covers**:
- When tests are required (pre-submission checklist)
- Testing philosophy and core principles
- Two-phase approach (flexible → strict)
- Test-first vs test-after guidance
- Testing exemptions and exceptions
- Coverage standards and requirements
- Test mode and safety requirements
- Pre-submission requirements

**Key Sections**:
- Testing requirements by project phase
- Mandatory vs optional tests
- Testing exemptions (when tests can be skipped)
- Success metrics and goals

### [UNIT_TESTING.md](UNIT_TESTING.md)

**When to read**: When writing unit tests for new code

**Covers**:
- Unit test characteristics and principles
- Test organization and structure
- Test naming conventions
- AAA pattern (Arrange-Act-Assert)
- Fixtures and test data
- Assertion strategies
- Parametrized testing
- Testing async code
- Mock objects basics

**Key Sections**:
- What to unit test (and what not to)
- Directory structure and organization
- Test class patterns
- Common testing patterns
- Running unit tests

### [INTEGRATION_TESTING.md](INTEGRATION_TESTING.md)

**When to read**: When testing component interactions

**Covers**:
- Integration test characteristics
- Docker-based testing infrastructure
- Test environment setup and teardown
- Complete workflow testing
- Multi-service integration patterns
- Performance and load testing
- Test data management
- Integration test fixtures

**Key Sections**:
- Docker Compose setup
- Database integration tests
- API endpoint testing
- Cache integration patterns
- Multi-service workflows
- Cleanup strategies

### [MOCKING_STRATEGIES.md](MOCKING_STRATEGIES.md)

**When to read**: When mocking dependencies in unit tests

**Covers**:
- When to mock (and when not to)
- Mock, MagicMock, and AsyncMock
- Common mock fixtures
- Patching strategies
- Spy and stub patterns
- Mock verification
- Advanced mocking techniques
- Time and database mocking

**Key Sections**:
- Mock vs real dependencies decision guide
- Common mock fixtures (DB, Redis, HTTP)
- Patching with decorators and context managers
- Mock verification and assertions
- Best practices and anti-patterns

### [COVERAGE_STANDARDS.md](COVERAGE_STANDARDS.md)

**When to read**: When checking test coverage

**Covers**:
- Coverage targets and requirements
- pytest-cov configuration
- Running coverage reports
- Coverage tools (pytest-cov, coverage.py)
- Coverage best practices
- Coverage exclusions
- Interpreting coverage reports
- Coverage improvement strategies

**Key Sections**:
- Minimum coverage requirements
- Configuration in pyproject.toml
- Terminal, HTML, and XML reports
- Coverage in CI/CD
- Valid exclusions
- Coverage anti-patterns

## Getting Started

### For New Projects

1. **Read TESTING_POLICY.md** - Understand requirements
2. **Setup test infrastructure**:
   ```bash
   # Install testing dependencies
   pip install pytest pytest-cov pytest-asyncio pytest-mock

   # Create test directory structure
   mkdir -p tests/{unit,integration,fixtures}
   ```
3. **Configure pytest** - Add configuration to `pyproject.toml`
4. **Write first unit test** - Follow UNIT_TESTING.md patterns
5. **Setup coverage** - Configure coverage targets

### For Existing Projects

1. **Assess current coverage**:
   ```bash
   pytest --cov=src --cov-report=html
   open htmlcov/index.html
   ```
2. **Identify gaps** - Focus on critical paths first
3. **Add missing tests** - Prioritize by risk and impact
4. **Refactor for testability** - Make code easier to test
5. **Enforce standards** - Add coverage checks to CI/CD

## Common Workflows

### Writing a New Feature

```bash
# 1. Write test first (TDD approach)
vim tests/unit/test_new_feature.py

# 2. Run test (should fail)
pytest tests/unit/test_new_feature.py

# 3. Implement feature
vim src/new_feature.py

# 4. Run test (should pass)
pytest tests/unit/test_new_feature.py

# 5. Add integration test if needed
vim tests/integration/test_new_feature_integration.py

# 6. Check coverage
pytest --cov=src/new_feature --cov-report=term-missing
```

### Fixing a Bug

```bash
# 1. Write failing test that reproduces bug
vim tests/unit/test_bug_fix.py
pytest tests/unit/test_bug_fix.py  # Should fail

# 2. Fix the bug
vim src/module.py

# 3. Verify test passes
pytest tests/unit/test_bug_fix.py  # Should pass

# 4. Run full test suite
pytest

# 5. Check coverage
pytest --cov=src --cov-report=term-missing
```

### Pre-Commit Checklist

```bash
# 1. Run all tests
pytest

# 2. Check coverage
pytest --cov=src --cov-report=term-missing

# 3. Verify coverage requirements met
# - New code: 80%+
# - Critical paths: 90%+
# - No coverage regression

# 4. Run linting
ruff check .
mypy src/

# 5. Commit
git add .
git commit -m "Add feature with tests"
```

## Testing Best Practices Summary

### The Golden Rules

1. **Write tests** - Every feature needs tests
2. **Test behavior, not implementation** - Tests should be resilient to refactoring
3. **Keep tests simple** - Tests should be easier to understand than code
4. **Fast feedback** - Unit tests must be fast
5. **Independent tests** - Tests should not depend on each other
6. **Mock external dependencies** - In unit tests only
7. **Use real services** - In integration tests
8. **Clean up** - Tests should not leave artifacts
9. **Meaningful assertions** - Verify actual behavior
10. **Document tests** - Use clear names and docstrings

### DO

✅ Follow AAA pattern (Arrange-Act-Assert)
✅ Write descriptive test names
✅ Test edge cases and error conditions
✅ Use fixtures for common setup
✅ Mock external dependencies in unit tests
✅ Use real services in integration tests
✅ Aim for 80%+ coverage on new code
✅ Run tests before committing
✅ Keep tests simple and readable
✅ Add regression tests for bugs

### DON'T

❌ Skip tests ("I'll add them later")
❌ Test implementation details
❌ Write flaky tests
❌ Share state between tests
❌ Use production data or services
❌ Write tests without assertions
❌ Mock everything
❌ Ignore failing tests
❌ Decrease coverage
❌ Write overly complex tests

## Running Tests

### Basic Commands

```bash
# Run all tests
pytest

# Run specific test type
pytest tests/unit/          # Unit tests only
pytest tests/integration/   # Integration tests only

# Run specific file
pytest tests/unit/test_auth.py

# Run specific test
pytest tests/unit/test_auth.py::TestAuth::test_login

# Run with coverage
pytest --cov=src --cov-report=html

# Run with markers
pytest -m unit              # Unit tests only
pytest -m integration       # Integration tests only
pytest -m "not slow"        # Exclude slow tests

# Verbose output
pytest -vv

# Show print statements
pytest -s

# Stop on first failure
pytest -x

# Run last failed tests
pytest --lf

# Parallel execution (requires pytest-xdist)
pytest -n auto
```

### Coverage Commands

```bash
# Terminal report with missing lines
pytest --cov=src --cov-report=term-missing

# HTML report
pytest --cov=src --cov-report=html
open htmlcov/index.html

# XML report (for CI/CD)
pytest --cov=src --cov-report=xml

# Branch coverage
pytest --cov=src --cov-branch

# Coverage for specific module
pytest tests/unit/test_auth.py --cov=src/auth
```

## Test Organization

### Recommended Structure

```
project/
├── src/
│   ├── __init__.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   └── user.py
│   └── utils/
│       ├── __init__.py
│       └── helpers.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py              # Shared fixtures
│   ├── unit/
│   │   ├── __init__.py
│   │   ├── conftest.py          # Unit test fixtures
│   │   ├── services/
│   │   │   ├── __init__.py
│   │   │   ├── test_auth.py
│   │   │   └── test_user.py
│   │   └── utils/
│   │       ├── __init__.py
│   │       └── test_helpers.py
│   ├── integration/
│   │   ├── __init__.py
│   │   ├── conftest.py          # Integration fixtures
│   │   ├── test_auth_flow.py
│   │   └── test_user_flow.py
│   └── fixtures/
│       ├── __init__.py
│       ├── integration_docker.py
│       └── docker-compose.integration.yml
├── pyproject.toml               # pytest & coverage config
└── README.md
```

## Configuration Examples

### pyproject.toml

```toml
[tool.pytest.ini_options]
minversion = "7.0"
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
asyncio_mode = "auto"
addopts = [
    "--strict-markers",
    "--strict-config",
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-report=html",
    "--cov-branch",
    "-vv",
]

markers = [
    "unit: Unit tests",
    "integration: Integration tests",
    "slow: Slow tests (> 5 seconds)",
]

[tool.coverage.run]
source = ["src"]
omit = ["*/tests/*", "*/test_*.py"]
branch = true

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise NotImplementedError",
    "if __name__ == .__main__.:",
    "if TYPE_CHECKING:",
    "@abstractmethod",
]
show_missing = true
precision = 2
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install -e ".[dev]"

      - name: Run tests
        run: |
          pytest --cov=src --cov-report=xml --cov-report=term-missing

      - name: Check coverage
        run: |
          coverage report --fail-under=80

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml
```

## Troubleshooting

### Common Issues

**Tests hang**:
- Missing `await` keywords
- Infinite loops
- Deadlocks in async code
- Check timeout settings

**Flaky tests**:
- Time-dependent code
- Shared state between tests
- Race conditions
- External service dependencies

**Import errors**:
- PYTHONPATH not set
- Missing `__init__.py` files
- Circular imports
- Run tests from project root

**Coverage too low**:
- Missing edge case tests
- Uncovered error handling
- Missing branch tests
- Check coverage report for gaps

## Learning Resources

### Internal Documentation

- **TESTING_POLICY.md** - Testing requirements
- **UNIT_TESTING.md** - Unit testing guide
- **INTEGRATION_TESTING.md** - Integration testing guide
- **MOCKING_STRATEGIES.md** - Mocking patterns
- **COVERAGE_STANDARDS.md** - Coverage requirements

### External Resources

- [pytest Documentation](https://docs.pytest.org/)
- [pytest-asyncio](https://pytest-asyncio.readthedocs.io/)
- [pytest-cov](https://pytest-cov.readthedocs.io/)
- [unittest.mock](https://docs.python.org/3/library/unittest.mock.html)
- [Python Testing Best Practices](https://docs.python-guide.org/writing/tests/)

### Example Repositories

- **SARK**: `/home/jhenry/Source/sark/tests/` - Comprehensive test examples
  - Unit tests: `tests/unit/auth/test_jwt.py`
  - Integration tests: `tests/integration/test_docker_infrastructure_example.py`
  - Fixtures: `tests/conftest.py`, `tests/fixtures/integration_docker.py`

- **thesymposium**: `/home/jhenry/Source/thesymposium/tests/` - Testing patterns
  - Testing policy: `.kilocode/rules/TESTING_POLICY.md`
  - Best practices: `docs/archive/development-history/2025-11/TESTING_BEST_PRACTICES.md`

## Support

### Getting Help

1. **Check documentation** - Review relevant testing guide
2. **Look at examples** - Check SARK test suite for patterns
3. **Search issues** - Problem might be documented
4. **Ask for help** - Open GitHub issue or discussion

### Contributing

Contributions to improve testing standards are welcome:

1. Propose changes via pull request
2. Include examples and rationale
3. Update relevant documentation
4. Add tests for new patterns

---

## Summary

This testing documentation provides:

✅ Clear testing requirements and policies
✅ Comprehensive unit testing patterns
✅ Integration testing with Docker infrastructure
✅ Mocking strategies and best practices
✅ Coverage standards and tools
✅ Real-world examples from production projects

**Remember**: Tests are not overhead—they're an investment in code quality, maintainability, and developer confidence.

---

## Related Patterns

For specific testing patterns and AI-assisted development strategies, see:
- [Testing Patterns](../../patterns/testing-patterns/README.md) - TDD and automation strategies for AI-assisted development

---

**Last Updated**: 2025-12-26
**Extracted From**: thesymposium, SARK, and czarina projects
**Maintained By**: Agent Development Team
**Applicable To**: All agent development projects
