# Coverage Standards

Comprehensive code coverage requirements, tools, and best practices for agent development, extracted from SARK and thesymposium.

## Overview

Code coverage measures how much of your source code is executed during testing. While high coverage doesn't guarantee quality, it helps identify untested code and reduces the risk of bugs.

## Coverage Targets

### Minimum Requirements

**New Code**:
- **Line Coverage**: 80% minimum
- **Critical Paths**: 90% minimum
- **Bug Fixes**: Must include regression test

**Existing Code**:
- **Maintain or Improve**: Don't reduce coverage
- **No Coverage Regression**: PRs must not decrease overall coverage

**Project Targets** (from SARK):
- **Overall**: 85%+ code coverage
- **Auth Providers**: 90%+ coverage
- **Gateway**: 80%+ coverage
- **Services**: 85%+ coverage

### Coverage Types

**Line Coverage**:
- Percentage of code lines executed during tests
- Most common coverage metric
- Minimum 80% for new code

**Branch Coverage**:
- Percentage of conditional branches tested
- Includes if/else, loops, try/except
- Recommended for critical paths
- Ensures all code paths are tested

**Function Coverage**:
- Percentage of functions called in tests
- All new functions must be tested
- 100% for new code

**Statement Coverage**:
- Similar to line coverage
- Counts executed statements
- Minimum 80% for new code

## Coverage Configuration

### pytest-cov Configuration

Configure in `pyproject.toml`:

```toml
[tool.pytest.ini_options]
addopts = [
    "--strict-markers",
    "--strict-config",
    "--cov=src",                    # Coverage source directory
    "--cov-report=term-missing",    # Show missing lines in terminal
    "--cov-report=html",            # Generate HTML report
    "--cov-report=xml",             # Generate XML report for CI
    "--cov-branch",                 # Enable branch coverage
    "-vv",
]

[tool.coverage.run]
source = ["src"]                    # Source code to measure
omit = [
    "*/tests/*",                    # Exclude test files
    "*/test_*.py",                  # Exclude test files
    "*/__pycache__/*",              # Exclude cache
    "*/venv/*",                     # Exclude virtual env
]
branch = true                       # Enable branch coverage

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",             # Explicit exclusion
    "def __repr__",                 # String representations
    "raise AssertionError",         # Assertion errors
    "raise NotImplementedError",    # Abstract methods
    "if __name__ == .__main__.:",   # Main blocks
    "if TYPE_CHECKING:",            # Type checking blocks
    "class .*\\bProtocol\\):",      # Protocol classes
    "@(abc\\.)?abstractmethod",     # Abstract methods
]
show_missing = true                 # Show missing line numbers
precision = 2                       # Decimal precision
```

### .coveragerc Configuration

Alternative configuration in `.coveragerc`:

```ini
[run]
source = .
omit =
    */tests/*
    */venv/*
    */__pycache__/*

branch = true

[report]
exclude_lines =
    pragma: no cover
    def __repr__
    raise NotImplementedError
    if __name__ == .__main__:
    if TYPE_CHECKING:
    @abstractmethod

show_missing = true
precision = 2

[html]
directory = htmlcov
```

## Running Coverage

### Basic Commands

```bash
# Run tests with coverage
pytest --cov=src

# Show missing lines
pytest --cov=src --cov-report=term-missing

# Generate HTML report
pytest --cov=src --cov-report=html

# Generate XML report (for CI)
pytest --cov=src --cov-report=xml

# All reports at once
pytest --cov=src --cov-report=term-missing --cov-report=html --cov-report=xml

# Branch coverage
pytest --cov=src --cov-branch

# Coverage for specific directory
pytest tests/unit/ --cov=src/services

# Coverage for specific module
pytest tests/unit/test_auth.py --cov=src/services/auth
```

### Coverage Reports

**Terminal Report**:
```bash
pytest --cov=src --cov-report=term-missing

# Output:
----------- coverage: platform linux, python 3.11.0 -----------
Name                      Stmts   Miss Branch BrPart  Cover   Missing
---------------------------------------------------------------------
src/services/auth.py        150     12     45      3    91%   23-25, 67-68
src/services/user.py        200      8     30      0    95%   123, 145-150
---------------------------------------------------------------------
TOTAL                       350     20     75      3    93%
```

**HTML Report**:
```bash
pytest --cov=src --cov-report=html

# Open in browser
open htmlcov/index.html
```

Provides:
- Visual coverage highlights
- Line-by-line coverage details
- Branch coverage visualization
- Sortable coverage table

**XML Report** (for CI/CD):
```bash
pytest --cov=src --cov-report=xml

# Generates coverage.xml for tools like SonarQube, Codecov
```

### Coverage in CI/CD

**GitHub Actions Example**:

```yaml
- name: Run tests with coverage
  run: |
    pytest --cov=src --cov-report=xml --cov-report=term-missing

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v3
  with:
    file: ./coverage.xml
    fail_ci_if_error: true
```

## Coverage Tools

### pytest-cov

Primary coverage tool for pytest:

```bash
# Install
pip install pytest-cov

# Use in tests
pytest --cov=src
```

**Features**:
- Integrates with pytest
- Multiple report formats
- Branch coverage support
- Parallel execution support
- CI/CD integration

### coverage.py

Underlying coverage tool:

```bash
# Install
pip install coverage

# Run with coverage
coverage run -m pytest

# Generate report
coverage report

# Generate HTML
coverage html

# Combine coverage data
coverage combine

# Erase coverage data
coverage erase
```

### Codecov / Coveralls

Cloud coverage tracking:

**Codecov**:
```bash
# Install
pip install codecov

# Upload
codecov --token=YOUR_TOKEN
```

**Coveralls**:
```bash
# Install
pip install coveralls

# Upload
coveralls
```

## Coverage Best Practices

### DO

✅ **Aim for 80%+ coverage on new code**
✅ **Focus on critical paths** - Ensure high-risk code has 90%+ coverage
✅ **Use coverage to find gaps** - Identify untested code
✅ **Enable branch coverage** - Test all conditional paths
✅ **Review coverage reports regularly** - Track trends
✅ **Test edge cases** - Don't just achieve coverage, test thoroughly
✅ **Exclude generated code** - Don't waste effort on auto-generated files
✅ **Use coverage in CI/CD** - Enforce coverage requirements
✅ **Write meaningful tests** - Coverage without good tests is useless
✅ **Document exclusions** - Explain why code is excluded

### DON'T

❌ **Chase 100% coverage** - Diminishing returns, focus on quality
❌ **Write tests just for coverage** - Tests must have value
❌ **Ignore uncovered code** - Understand why it's untested
❌ **Skip critical paths** - Always test security/critical features
❌ **Fake coverage** - Don't write tests that just execute code
❌ **Over-exclude code** - Only exclude truly untestable code
❌ **Rely solely on coverage** - It's one metric among many
❌ **Compare coverage across projects** - Different projects have different needs
❌ **Decrease coverage in PRs** - Maintain or improve
❌ **Ignore branch coverage** - Line coverage alone is insufficient

## Coverage Exclusions

### Excluding Lines

```python
def function_with_exclusion():
    """Function with coverage exclusion."""
    try:
        risky_operation()
    except Exception:  # pragma: no cover
        # This exception handler is for safety only
        # and shouldn't occur in normal operation
        log_error()
        raise
```

### Excluding Blocks

```python
def debug_function():  # pragma: no cover
    """Debug function excluded from coverage."""
    print("Debug information")
    return debug_data


if __name__ == "__main__":  # pragma: no cover
    main()
```

### Excluding Branches

```python
def function_with_branch_exclusion():
    """Function with branch exclusion."""
    if TYPE_CHECKING:  # pragma: no cover
        from typing import TYPE_CHECKING
```

### Valid Exclusions

**Always Exclude**:
- `if __name__ == "__main__":` blocks
- `if TYPE_CHECKING:` blocks
- Abstract methods (`@abstractmethod`)
- Protocol classes
- Debug/logging-only code
- Unreachable safety code

**Sometimes Exclude**:
- String representations (`__repr__`, `__str__`)
- Defensive programming (should-never-happen cases)
- Platform-specific code
- Deprecated code paths

**Never Exclude**:
- Business logic
- Validation logic
- Error handling
- Security code
- Core functionality

## Interpreting Coverage Reports

### Understanding Metrics

**Stmts**: Total statements in file
**Miss**: Statements not executed
**Branch**: Total branches (if/else, etc.)
**BrPart**: Branches partially covered (one path tested, not both)
**Cover**: Coverage percentage
**Missing**: Line numbers not covered

Example:
```
Name                Stmts   Miss Branch BrPart  Cover   Missing
---------------------------------------------------------------
src/auth.py           150     12     45      3    91%   23-25, 67-68
```

- 150 total statements
- 12 statements not covered
- 45 branches (if/else, etc.)
- 3 branches partially covered (only one path tested)
- 91% coverage
- Lines 23-25 and 67-68 not tested

### Coverage Gaps

**High Priority Gaps** (fix immediately):
- Uncovered authentication logic
- Uncovered authorization checks
- Uncovered validation logic
- Uncovered error handling
- Uncovered critical business logic

**Medium Priority Gaps** (fix soon):
- Partially covered branches
- Uncovered utility functions
- Uncovered helper methods
- Uncovered configuration code

**Low Priority Gaps** (fix when convenient):
- Uncovered string representations
- Uncovered debug code
- Uncovered deprecated paths
- Edge case error handlers

## Coverage Improvement Strategies

### Identify Low Coverage Areas

```bash
# Find files with lowest coverage
coverage report --sort=cover

# Focus on specific low-coverage files
pytest tests/test_auth.py --cov=src/auth --cov-report=html
```

### Focus on Critical Paths

```python
# Before: Partial coverage
def validate_user(user_data):
    if not user_data:
        raise ValueError("No user data")

    if "email" not in user_data:
        raise ValueError("Email required")  # Not tested

    return True


# After: Full coverage
@pytest.mark.parametrize("user_data,expected_error", [
    (None, "No user data"),
    ({}, "Email required"),  # Now tested
    ({"name": "Test"}, "Email required"),  # Now tested
])
def test_validate_user_errors(user_data, expected_error):
    """Test validation errors."""
    with pytest.raises(ValueError, match=expected_error):
        validate_user(user_data)
```

### Add Branch Coverage Tests

```python
# Original test (only covers if-branch)
def test_process_with_flag_true():
    """Test process with flag=True."""
    result = process(flag=True)
    assert result == "processed"

# Add test for else-branch
def test_process_with_flag_false():
    """Test process with flag=False."""
    result = process(flag=False)
    assert result == "skipped"
```

### Test Error Paths

```python
# Add tests for exception paths
def test_function_handles_network_error():
    """Test function handles network errors."""
    with patch("requests.get") as mock_get:
        mock_get.side_effect = ConnectionError()

        result = fetch_data()

        assert result is None  # Graceful handling


def test_function_handles_timeout():
    """Test function handles timeouts."""
    with patch("requests.get") as mock_get:
        mock_get.side_effect = TimeoutError()

        result = fetch_data()

        assert result is None
```

## Coverage Anti-Patterns

### Bad: Testing for Coverage Only

```python
# ❌ Bad: Test just executes code without assertions
def test_function():
    """Test function."""
    function()  # No assertions!
```

```python
# ✅ Good: Test verifies behavior
def test_function():
    """Test function returns correct value."""
    result = function()
    assert result == expected_value
```

### Bad: Ignoring Branch Coverage

```python
# ❌ Bad: Only tests one branch
def test_conditional():
    """Test conditional."""
    result = conditional(True)
    assert result == "yes"
    # Missing test for False branch
```

```python
# ✅ Good: Tests both branches
@pytest.mark.parametrize("condition,expected", [
    (True, "yes"),
    (False, "no"),
])
def test_conditional(condition, expected):
    """Test conditional with both branches."""
    result = conditional(condition)
    assert result == expected
```

### Bad: Excessive Exclusions

```python
# ❌ Bad: Excluding testable code
def process_user(user):  # pragma: no cover
    """Process user."""
    # This should be tested!
    return user.email.lower()
```

```python
# ✅ Good: Test the code
def test_process_user():
    """Test user processing."""
    user = User(email="TEST@EXAMPLE.COM")
    result = process_user(user)
    assert result == "test@example.com"
```

## Coverage in Code Reviews

### PR Coverage Requirements

**Check in PR**:
- Overall coverage hasn't decreased
- New code has 80%+ coverage
- Critical paths have 90%+ coverage
- No unexplained coverage exclusions

**Review Comments**:
```markdown
## Coverage Analysis

**Overall**: 85% → 86% ✅
**New Code**: 92% ✅
**Changed Files**:
- `src/auth.py`: 88% → 94% ✅
- `src/user.py`: 95% → 93% ⚠️ (coverage decreased)

**Uncovered Lines**:
- `src/user.py:145-150`: Error handling not tested ❌

**Action Required**:
- Add tests for error handling in user.py
- Explain coverage decrease in user.py
```

## References

- **TESTING_POLICY.md** - Coverage requirements and policy
- **UNIT_TESTING.md** - Unit testing patterns
- **INTEGRATION_TESTING.md** - Integration testing coverage
- **MOCKING_STRATEGIES.md** - Mocking for coverage

## Examples

See SARK repository for examples:
- `/home/jhenry/Source/sark/pyproject.toml` - pytest-cov configuration (lines 229-285)
- `/home/jhenry/Source/sark/tests/` - Comprehensive test coverage examples

---

**Last Updated**: 2025-12-26
**Extracted From**: SARK project and thesymposium
**Applicable To**: All agent development projects
