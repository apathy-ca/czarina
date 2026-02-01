# Testing Policy

Comprehensive testing policy and requirements for agent development, extracted from thesymposium testing standards.

## Overview

This document outlines when tests are required, testing philosophy, test-first vs test-after approaches, testing exemptions, and overall testing goals for agent development projects.

## Testing Philosophy

### Core Principles

1. **Tests are documentation** - Tests should clearly demonstrate how code is intended to work
2. **Fast feedback** - Tests should run quickly to enable rapid development
3. **Reliable** - Tests should be deterministic and not flaky
4. **Maintainable** - Tests should be easy to understand and update
5. **Comprehensive** - Critical paths must have test coverage

### Testing Pyramid

Tests should follow the testing pyramid structure, with many unit tests at the base, some integration tests in the middle, and few end-to-end tests at the top:

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

**Rationale**:
- Unit tests are fast, isolated, and easy to maintain
- Integration tests verify component interactions
- E2E tests validate complete user workflows
- More tests at the base provide faster feedback

## When Tests Are Required

### Phased Approach

Testing requirements evolve as projects mature. Projects should follow a two-phase approach:

#### Phase 1: Flexible Phase (Early Development)

**Goal**: Encourage development velocity while establishing baseline quality

**Requirements**:
- All new backend endpoints must have basic unit tests
- All critical frontend components should have basic unit tests
- Integration tests are encouraged but not strictly required
- Focus on building out core testing infrastructure

**Applicable When**:
- Project is in early development (pre-v0.3.2 or equivalent)
- Core features are still being established
- Testing infrastructure is being built

#### Phase 2: Strict Phase (Mature Development)

**Goal**: Ensure high reliability and stability for all new features

**Mandatory Requirements**:
1. **Unit Tests**: All new code contributions must include:
   - Coverage for all new functions, methods, and components
   - Minimum 80% code coverage for changed files
   - 90% code coverage for critical paths

2. **Integration Tests**: All new code contributions must include:
   - Coverage for primary user stories affected by changes
   - Tests for workflows that span multiple components
   - Verification of data flow between components

**Example Scenarios**:
- Change to chat memory → Integration test verifying memory retrieval in conversation
- New API endpoint → Unit tests for endpoint logic + integration test for full request/response
- Authentication changes → Unit tests for auth logic + integration test for auth flow

**CI/CD Enforcement**:
- All tests run automatically in CI/CD pipeline
- Pull requests blocked from merging if any tests fail
- Coverage checks enforced automatically

**Applicable When**:
- Project has reached maturity milestone (v0.3.2 or equivalent)
- Core features are stable
- Testing infrastructure is established

## Test Type Requirements

### Unit Tests

**Purpose**: Test individual components in isolation

**Required For**:
- All new functions and methods
- All new classes and modules
- Business logic changes
- Utility functions
- Data validation logic

**Characteristics**:
- Fast execution (< 100ms per test)
- No external dependencies
- Use mocks for dependencies
- Test one thing at a time

**Coverage Target**: 80%+ for new code, 90%+ for critical paths

### Integration Tests

**Purpose**: Test component interactions and workflows

**Required For**:
- New API endpoints (full request/response cycle)
- Changes affecting multiple components
- Data flow between services
- Message passing systems
- Authentication/authorization flows
- Database operations with real schema

**Characteristics**:
- Moderate execution time (< 10s per test)
- Use real infrastructure (databases, message queues, etc.)
- Test complete workflows
- Verify data flow between components

**Coverage Target**: All primary user stories and workflows

### Load/Performance Tests

**Purpose**: Test performance under load and stress

**Required For**:
- Performance-critical features
- Scalability requirements
- High-traffic endpoints
- Resource-intensive operations

**Characteristics**:
- Slow execution (> 30s per test)
- Test scalability and throughput
- Measure performance metrics
- Run manually or in CI schedules

**Coverage Target**: Critical performance paths identified during planning

## Test-First vs Test-After

### Recommended Approach

The project does not mandate strict Test-Driven Development (TDD) but encourages thoughtful testing approaches:

**Test-First (Recommended for)**:
- Complex business logic
- Critical security features
- Well-defined requirements
- API contract design
- Bug fixes (write failing test first, then fix)

**Benefits**:
- Forces clear thinking about requirements
- Results in more testable code design
- Catches edge cases early
- Serves as executable specification

**Test-After (Acceptable for)**:
- Exploratory development
- Prototyping new features
- Refactoring existing code
- Simple CRUD operations

**Requirements**:
- Tests must be written before PR submission
- Tests must achieve coverage requirements
- Tests must cover edge cases and error scenarios

### AAA Pattern (Always Required)

All tests must follow the Arrange-Act-Assert pattern:

```python
async def test_example(self):
    """Test description"""
    # Arrange - Set up test data and conditions
    user_id = "test_user"
    message = create_test_message(user_id)

    # Act - Execute the code being tested
    result = await process_message(message)

    # Assert - Verify the outcome
    assert result.status == "success"
    assert result.user_id == user_id
```

## Testing Exemptions

### When Tests May Be Skipped

Tests may be skipped or deferred in these specific scenarios:

1. **Temporary Prototypes**
   - Code explicitly marked as prototype/spike
   - Must be removed or properly tested before merging to main
   - Should be in separate feature branch

2. **Documentation-Only Changes**
   - README updates
   - Comment additions
   - Documentation fixes

3. **Configuration Files**
   - Environment configuration
   - Build configuration
   - CI/CD pipeline configuration (though pipeline tests themselves need validation)

4. **Generated Code**
   - Auto-generated migration files
   - Auto-generated API clients
   - Code generated by frameworks (if framework is well-tested)

### When Tests Cannot Be Skipped

Tests are **always required** for:

1. **Security-Sensitive Code**
   - Authentication
   - Authorization
   - Input validation
   - Cryptographic operations
   - Session management

2. **Data Integrity**
   - Database operations
   - Data migrations
   - Data validation
   - Business logic

3. **Public APIs**
   - REST endpoints
   - GraphQL resolvers
   - Message handlers
   - WebSocket handlers

4. **Critical User Paths**
   - User registration/login
   - Core feature workflows
   - Payment processing
   - Data export/import

## Coverage Standards

### Coverage Targets

**Minimum Requirements**:
- **New Code**: 80%+ coverage required
- **Critical Paths**: 90%+ coverage required
- **Bug Fixes**: Must include regression test

**Coverage Types**:
- **Line Coverage**: Minimum 80%
- **Branch Coverage**: Encouraged for critical paths
- **Function Coverage**: All new functions must be called in tests

### Coverage Exclusions

The following may be excluded from coverage requirements:

```python
# Excluded patterns
- Debug code: `if __name__ == "__main__":`
- Type checking: `if TYPE_CHECKING:`
- Abstract methods: `@abstractmethod`
- Unreachable code: `raise NotImplementedError`
- String representations: `def __repr__`
- Explicit no-cover: `# pragma: no cover`
```

### Coverage Reporting

Coverage must be:
- Measured for all PRs
- Reported in CI/CD
- Viewable in HTML reports
- Tracked over time

## Pre-Submission Requirements

### Testing Checklist

Before submitting any PR, contributors must verify:

- [ ] **All tests pass**: Full test suite runs successfully
- [ ] **Coverage meets requirements**: 80%+ for new code, 90%+ for critical paths
- [ ] **Tests are documented**: Each test has clear docstring
- [ ] **Tests are isolated**: Tests don't depend on each other
- [ ] **Tests are fast**: Unit tests < 100ms, integration tests < 10s
- [ ] **Edge cases covered**: Success, failure, and boundary scenarios tested
- [ ] **Mocks used appropriately**: External dependencies mocked in unit tests
- [ ] **Integration tests use real services**: Where applicable
- [ ] **Test names are descriptive**: Clearly indicate what is being tested
- [ ] **AAA pattern followed**: Arrange-Act-Assert structure used

### Test Quality Standards

Tests must meet these quality criteria:

1. **Clear Intent**: Test name and docstring clearly explain what is being tested
2. **Single Responsibility**: Each test verifies one specific behavior
3. **Repeatable**: Tests produce same results on every run
4. **Independent**: Tests can run in any order
5. **Fast**: Unit tests complete quickly for rapid feedback
6. **Complete**: Tests cover normal cases, edge cases, and error cases

## Testing Exceptions and Special Cases

### Flaky Tests

**Policy**: Flaky tests are not acceptable

**If a test is flaky**:
1. Investigate root cause immediately
2. Fix timing issues, race conditions, or test pollution
3. If unfixable quickly, mark with `@pytest.mark.flaky` and file issue
4. Remove flaky marker once fixed

**Common causes**:
- Time-dependent assertions
- Improper async/await usage
- Shared state between tests
- Inadequate test cleanup

### Slow Tests

**Policy**: Slow tests should be marked and skipped in standard runs

**Marking slow tests**:
```python
@pytest.mark.slow
def test_performance_intensive_operation(self):
    """Test that takes > 5 seconds"""
    ...
```

**Running slow tests**:
```bash
# Skip slow tests (default)
pytest -m "not slow"

# Run only slow tests
pytest -m slow
```

### External Dependencies

**Policy**: Tests must be runnable in any environment

**Unit Tests**:
- Must mock all external dependencies
- Must not require network access
- Must not require external services

**Integration Tests**:
- May use Docker containers for dependencies
- Must include setup/teardown for services
- Must verify service readiness before running
- Must clean up resources after running

## Testing Goals and Success Metrics

### Project-Level Goals

1. **Reliability**: Reduce production bugs through comprehensive testing
2. **Confidence**: Enable safe refactoring with good test coverage
3. **Documentation**: Tests serve as executable documentation
4. **Velocity**: Fast test suites enable rapid development
5. **Quality**: Maintain high code quality through automated verification

### Success Metrics

**Test Suite Health**:
- All tests passing in CI/CD
- Test execution time < 5 minutes for unit tests
- Test execution time < 15 minutes for full suite
- Zero flaky tests
- Coverage trends improving or stable

**Coverage Metrics**:
- Overall project coverage > 80%
- New code coverage > 80%
- Critical path coverage > 90%
- No coverage regressions

**Developer Experience**:
- Fast local test execution
- Clear test failure messages
- Easy to run specific tests
- Good fixture organization
- Comprehensive testing documentation

## Test Mode and Safety

### Test Isolation

**Requirement**: All tests must be completely isolated from production

**Implementation**:
- Use `test_mode=True` parameter where applicable
- Use test-specific databases/indices (e.g., `*-test` suffix)
- Automatic test resource creation and cleanup
- No production data pollution

**Safety Guarantees**:
- Tests never modify production data
- Test indices/databases are clearly marked
- Safe to delete test resources anytime
- Complete separation from production environment

## References

### Internal Documentation

- **UNIT_TESTING.md** - Unit testing patterns and practices
- **INTEGRATION_TESTING.md** - Integration testing standards
- **MOCKING_STRATEGIES.md** - Mocking and stubbing guidelines
- **COVERAGE_STANDARDS.md** - Coverage tools and requirements

### Related Resources

- pytest documentation: https://docs.pytest.org/
- pytest-asyncio: https://pytest-asyncio.readthedocs.io/
- Python testing best practices: https://docs.python-guide.org/writing/tests/

---

**Last Updated**: 2025-12-26
**Extracted From**: thesymposium project (v0.4.x)
**Applicable To**: All agent development projects
