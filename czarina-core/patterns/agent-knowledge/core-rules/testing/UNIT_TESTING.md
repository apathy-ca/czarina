# Unit Testing Standards

Comprehensive unit testing patterns and best practices for agent development, extracted from SARK and thesymposium test suites.

## Overview

Unit tests verify individual components in complete isolation from external dependencies. They are fast, deterministic, and form the foundation of a robust test suite.

## Unit Test Characteristics

### Essential Properties

1. **Fast Execution**: < 100ms per test
2. **Complete Isolation**: No external dependencies (databases, APIs, file systems)
3. **Deterministic**: Same input always produces same output
4. **Single Responsibility**: Test one specific behavior per test
5. **Independent**: Can run in any order, no shared state

### What to Unit Test

**Always Unit Test**:
- Business logic functions
- Data validation logic
- Utility functions and helpers
- Class methods and instance behavior
- Edge case handling
- Error handling
- Input parsing and transformation
- Algorithm implementations

**Usually Don't Unit Test**:
- Database queries (use integration tests)
- External API calls (use integration tests)
- File I/O operations (use integration tests)
- Framework internals (already tested)
- Simple getters/setters (unless they have logic)

## Unit Test Organization

### Directory Structure

```
project/
├── src/
│   ├── services/
│   │   ├── auth/
│   │   │   ├── jwt.py
│   │   │   └── user_context.py
│   │   └── validation/
│   │       └── input_validator.py
│   └── utils/
│       └── helpers.py
└── tests/
    └── unit/
        ├── __init__.py
        ├── conftest.py              # Shared unit test fixtures
        ├── services/
        │   ├── __init__.py
        │   ├── auth/
        │   │   ├── __init__.py
        │   │   ├── test_jwt.py      # Tests for jwt.py
        │   │   └── test_user_context.py
        │   └── validation/
        │       ├── __init__.py
        │       └── test_input_validator.py
        └── utils/
            ├── __init__.py
            └── test_helpers.py
```

**Principles**:
- Mirror source code directory structure
- Use `test_*.py` naming convention
- Group related tests in same file
- Use `conftest.py` for shared fixtures

### Test Class Organization

Group related tests into classes with descriptive names:

```python
"""Comprehensive tests for JWT token handling and validation."""

from datetime import UTC, datetime, timedelta
from unittest.mock import patch
from uuid import UUID, uuid4

from fastapi import HTTPException
from jose import jwt
import pytest

from sark.services.auth.jwt import JWTHandler, get_current_user


class TestJWTHandler:
    """Test suite for JWTHandler class."""

    @pytest.fixture
    def handler(self):
        """Create a JWT handler instance for testing."""
        return JWTHandler(
            secret_key="test_secret_key_12345",
            algorithm="HS256",
            access_token_expire_minutes=30,
            refresh_token_expire_days=7,
        )

    @pytest.fixture
    def sample_user_data(self):
        """Sample user data for testing."""
        return {
            "user_id": uuid4(),
            "email": "test@example.com",
            "role": "user",
            "teams": ["team-alpha", "team-beta"],
        }

    # ===== Access Token Creation Tests =====

    def test_create_access_token_basic(self, handler, sample_user_data):
        """Test creating a basic access token."""
        token = handler.create_access_token(
            user_id=sample_user_data["user_id"],
            email=sample_user_data["email"],
            role=sample_user_data["role"],
        )

        assert isinstance(token, str)
        assert len(token) > 0

        # Decode to verify structure
        payload = jwt.decode(token, handler.secret_key, algorithms=[handler.algorithm])
        assert payload["sub"] == str(sample_user_data["user_id"])
        assert payload["email"] == sample_user_data["email"]
        assert payload["role"] == sample_user_data["role"]

    def test_create_access_token_with_teams(self, handler, sample_user_data):
        """Test creating access token with teams."""
        token = handler.create_access_token(
            user_id=sample_user_data["user_id"],
            email=sample_user_data["email"],
            role=sample_user_data["role"],
            teams=sample_user_data["teams"],
        )

        payload = jwt.decode(token, handler.secret_key, algorithms=[handler.algorithm])
        assert payload["teams"] == sample_user_data["teams"]

    # ===== Token Decoding Tests =====

    def test_decode_expired_token(self, handler, sample_user_data):
        """Test decoding an expired token raises HTTPException."""
        # Create a token that's already expired
        now = datetime.now(UTC)
        past = now - timedelta(hours=1)

        claims = {
            "sub": str(sample_user_data["user_id"]),
            "email": sample_user_data["email"],
            "role": sample_user_data["role"],
            "teams": [],
            "iat": past,
            "exp": past,  # Already expired
            "type": "access",
        }
        token = jwt.encode(claims, handler.secret_key, algorithm=handler.algorithm)

        with pytest.raises(HTTPException) as exc_info:
            handler.decode_token(token)

        assert exc_info.value.status_code == 401
        assert "Could not validate credentials" in exc_info.value.detail
```

**Key Patterns**:
- One test class per production class
- Descriptive class name: `Test<ClassName>`
- Fixtures for common setup
- Section comments to organize related tests
- Clear, descriptive test method names

## Test Naming Conventions

### Test Method Names

Use descriptive names that clearly state what is being tested:

**Format**: `test_<method>_<scenario>_<expected_result>`

**Examples**:

✅ **Good Names**:
```python
def test_create_access_token_basic(self):
def test_create_access_token_with_teams(self):
def test_decode_expired_token_raises_exception(self):
def test_validate_email_with_invalid_format_returns_false(self):
def test_rate_limit_blocks_requests_over_limit(self):
def test_hash_password_produces_different_hash_each_time(self):
```

❌ **Bad Names**:
```python
def test_token(self):
def test_validate(self):
def test_1(self):
def test_success(self):
def test_error_case(self):
```

### Test Docstrings

Every test must have a clear docstring:

```python
def test_create_access_token_basic(self, handler, sample_user_data):
    """Test creating a basic access token."""
    # Test implementation
```

**Docstring Format**:
- Start with "Test" verb
- Be concise but descriptive
- Explain what behavior is being verified
- No need to repeat implementation details

## AAA Pattern (Arrange-Act-Assert)

All unit tests must follow the AAA pattern for clarity and consistency.

### Structure

```python
def test_example(self):
    """Test description."""
    # Arrange - Set up test data and conditions
    input_value = "test_input"
    expected_output = "expected_result"

    # Act - Execute the code being tested
    result = function_under_test(input_value)

    # Assert - Verify the outcome
    assert result == expected_output
```

### Real Example

```python
def test_validate_email_with_valid_format(self):
    """Test email validation accepts valid email format."""
    # Arrange
    validator = EmailValidator()
    valid_email = "user@example.com"

    # Act
    result = validator.validate(valid_email)

    # Assert
    assert result is True
```

### Async Example

```python
@pytest.mark.asyncio
async def test_fetch_user_by_id_returns_user(self, user_service, sample_user):
    """Test fetching user by ID returns correct user."""
    # Arrange
    user_id = sample_user.id

    # Act
    result = await user_service.fetch_user_by_id(user_id)

    # Assert
    assert result.id == user_id
    assert result.email == sample_user.email
```

## Fixtures and Test Data

### Using pytest Fixtures

Fixtures provide reusable test setup and teardown:

```python
@pytest.fixture
def handler(self):
    """Create a JWT handler instance for testing."""
    return JWTHandler(
        secret_key="test_secret_key_12345",
        algorithm="HS256",
        access_token_expire_minutes=30,
        refresh_token_expire_days=7,
    )

@pytest.fixture
def sample_user_data(self):
    """Sample user data for testing."""
    return {
        "user_id": uuid4(),
        "email": "test@example.com",
        "role": "user",
        "teams": ["team-alpha", "team-beta"],
    }

def test_create_token(self, handler, sample_user_data):
    """Test token creation."""
    # Fixtures are automatically injected
    token = handler.create_access_token(**sample_user_data)
    assert token is not None
```

### Fixture Scopes

```python
# Function-scoped (default) - new instance per test
@pytest.fixture
def user():
    return User(name="test")

# Class-scoped - shared within test class
@pytest.fixture(scope="class")
def database():
    db = Database()
    yield db
    db.cleanup()

# Module-scoped - shared within module
@pytest.fixture(scope="module")
def config():
    return load_config()

# Session-scoped - shared across entire test session
@pytest.fixture(scope="session")
def global_config():
    return GlobalConfig()
```

### Fixture Cleanup

Use `yield` for fixtures that need cleanup:

```python
@pytest.fixture
async def db_session():
    """Mock database session for tests."""
    session = MagicMock()
    session.add = MagicMock()
    session.commit = AsyncMock()
    session.close = AsyncMock()

    yield session

    # Cleanup happens after test
    await session.close()
```

### Autouse Fixtures

Fixtures that run automatically for all tests:

```python
@pytest.fixture(autouse=True)
def mock_database(monkeypatch: pytest.MonkeyPatch) -> None:
    """Mock database initialization for all tests."""

    async def mock_init_db() -> None:
        """Mock database initialization."""
        pass

    monkeypatch.setattr("sark.db.session.init_db", mock_init_db)
```

## Assertion Strategies

### Basic Assertions

```python
# Equality
assert result == expected
assert result != unexpected

# Identity
assert result is None
assert result is not None

# Membership
assert item in collection
assert item not in collection

# Boolean
assert result
assert not result

# Type checking
assert isinstance(result, ExpectedType)

# Comparisons
assert value > 0
assert value >= 10
assert value < 100
```

### Exception Assertions

```python
# Assert exception is raised
with pytest.raises(ValueError):
    function_that_raises()

# Assert exception with specific message
with pytest.raises(ValueError, match="Invalid input"):
    function_that_raises()

# Capture exception for detailed inspection
with pytest.raises(HTTPException) as exc_info:
    handler.decode_token(invalid_token)

assert exc_info.value.status_code == 401
assert "Could not validate credentials" in exc_info.value.detail
```

### Approximate Assertions

```python
# Floating point comparisons
assert result == pytest.approx(3.14, rel=0.01)

# Time-based assertions with tolerance
expected_time = datetime.now(UTC) + timedelta(minutes=30)
assert abs((actual_time - expected_time).total_seconds()) < 5
```

### Collection Assertions

```python
# List/tuple assertions
assert len(results) == 3
assert results[0] == expected_first
assert all(isinstance(r, Result) for r in results)

# Dict assertions
assert "key" in result_dict
assert result_dict["key"] == "value"
assert set(result_dict.keys()) == {"key1", "key2", "key3"}

# Set assertions
assert result_set == {1, 2, 3}
assert result_set.issubset({1, 2, 3, 4})
```

## Parametrized Testing

Test the same logic with different inputs:

### Basic Parametrization

```python
@pytest.mark.parametrize("input,expected", [
    ("@cicero hello", "cicero"),
    ("@sophia test", "sophia"),
    ("@plato question", "plato"),
    ("no mention", None),
])
def test_extract_sage_mention(input, expected):
    """Test extracting sage mention from message."""
    result = extract_sage_mention(input)
    assert result == expected
```

### Multiple Parameters

```python
@pytest.mark.parametrize("email,is_valid", [
    ("user@example.com", True),
    ("user.name@example.co.uk", True),
    ("invalid.email", False),
    ("@example.com", False),
    ("user@", False),
    ("", False),
])
def test_email_validation(email, is_valid):
    """Test email validation with various formats."""
    validator = EmailValidator()
    assert validator.validate(email) == is_valid
```

### Parametrized Fixtures

```python
@pytest.fixture(params=["HS256", "HS384", "HS512"])
def algorithm(request):
    """Test with multiple JWT algorithms."""
    return request.param

def test_token_creation_with_various_algorithms(algorithm):
    """Test token creation works with different algorithms."""
    handler = JWTHandler(
        secret_key="test_key",
        algorithm=algorithm,
    )
    token = handler.create_access_token(user_id=uuid4(), email="test@test.com")
    assert token is not None
```

### Parametrize with IDs

```python
@pytest.mark.parametrize("input,expected", [
    ("valid-slug", True),
    ("invalid slug", False),
    ("invalid_slug!", False),
], ids=["valid", "spaces", "special_chars"])
def test_slug_validation(input, expected):
    """Test slug validation."""
    assert is_valid_slug(input) == expected
```

## Testing Async Code

### Basic Async Tests

```python
@pytest.mark.asyncio
async def test_async_function():
    """Test async function."""
    result = await async_function()
    assert result is not None
```

### Async Fixtures

```python
@pytest.fixture
async def async_client():
    """Create async client."""
    client = AsyncClient()
    yield client
    await client.close()

@pytest.mark.asyncio
async def test_with_async_fixture(async_client):
    """Test using async fixture."""
    response = await async_client.get("/endpoint")
    assert response.status_code == 200
```

### Testing Async Exceptions

```python
@pytest.mark.asyncio
async def test_async_function_raises_exception():
    """Test async function raises exception."""
    with pytest.raises(ValueError):
        await async_function_that_raises()
```

## Mock Objects and Mocking

### Using unittest.mock

```python
from unittest.mock import AsyncMock, MagicMock, patch

# Mock for sync functions
mock_obj = MagicMock()
mock_obj.method.return_value = "result"

# Mock for async functions
mock_async = AsyncMock()
mock_async.return_value = "result"
result = await mock_async()
```

### Common Mock Fixtures

From SARK `conftest.py`:

```python
@pytest.fixture
def mock_redis() -> MagicMock:
    """Mock Redis client for tests."""
    redis = MagicMock()
    redis.get = AsyncMock(return_value=None)
    redis.set = AsyncMock(return_value=True)
    redis.delete = AsyncMock(return_value=1)
    redis.exists = AsyncMock(return_value=0)
    redis.expire = AsyncMock(return_value=True)
    redis.keys = AsyncMock(return_value=[])
    redis.ping = AsyncMock(return_value=True)
    redis.close = AsyncMock()
    return redis

@pytest.fixture
async def db_session() -> AsyncMock:
    """Mock database session for tests."""
    session = MagicMock()
    session.add = MagicMock()
    session.commit = AsyncMock()
    session.flush = AsyncMock()
    session.execute = AsyncMock(
        return_value=MagicMock(
            scalars=MagicMock(return_value=MagicMock(all=MagicMock(return_value=[])))
        )
    )
    session.close = AsyncMock()
    session.rollback = AsyncMock()
    session.refresh = AsyncMock()

    yield session

    await session.close()
```

### Monkeypatch for Module-Level Mocking

```python
@pytest.fixture(autouse=True)
def mock_database(monkeypatch: pytest.MonkeyPatch) -> None:
    """Mock database initialization for all tests."""

    async def mock_init_db() -> None:
        """Mock database initialization."""
        pass

    monkeypatch.setattr("sark.db.session.init_db", mock_init_db)
```

### Patch Decorator

```python
from unittest.mock import patch

@patch("module.external_api_call")
def test_function_with_external_call(mock_api_call):
    """Test function that makes external API call."""
    # Arrange
    mock_api_call.return_value = {"status": "success"}

    # Act
    result = function_that_calls_api()

    # Assert
    assert result["status"] == "success"
    mock_api_call.assert_called_once()
```

See **MOCKING_STRATEGIES.md** for comprehensive mocking patterns.

## Edge Cases and Error Handling

### Test Edge Cases

```python
class TestInputValidation:
    """Test input validation edge cases."""

    def test_empty_string(self):
        """Test validation with empty string."""
        assert validate_input("") is False

    def test_none_value(self):
        """Test validation with None."""
        with pytest.raises(ValueError):
            validate_input(None)

    def test_very_long_string(self):
        """Test validation with string exceeding max length."""
        long_string = "x" * 10000
        assert validate_input(long_string) is False

    def test_special_characters(self):
        """Test validation with special characters."""
        assert validate_input("test@#$%") is False

    def test_unicode_characters(self):
        """Test validation with unicode characters."""
        assert validate_input("test\u00a0\u2028") is False

    def test_boundary_value_min(self):
        """Test validation at minimum boundary."""
        assert validate_input("x" * 1) is True

    def test_boundary_value_max(self):
        """Test validation at maximum boundary."""
        assert validate_input("x" * 255) is True

    def test_boundary_value_over_max(self):
        """Test validation just over maximum boundary."""
        assert validate_input("x" * 256) is False
```

### Test Error Conditions

```python
def test_division_by_zero(self):
    """Test function handles division by zero."""
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)

def test_invalid_type_raises_type_error(self):
    """Test function raises TypeError for invalid type."""
    with pytest.raises(TypeError):
        process_number("not a number")

def test_file_not_found_handled_gracefully(self):
    """Test function handles missing file gracefully."""
    result = read_config("nonexistent.json")
    assert result == {}  # Returns empty dict instead of raising
```

## Test Markers

Use pytest markers to categorize tests:

```python
@pytest.mark.unit
def test_unit_test():
    """Unit test marker."""
    pass

@pytest.mark.slow
def test_slow_operation():
    """Slow test marker (> 5 seconds)."""
    pass

@pytest.mark.skip(reason="Not implemented yet")
def test_future_feature():
    """Skip test temporarily."""
    pass

@pytest.mark.skipif(sys.platform == "win32", reason="Unix only")
def test_unix_specific():
    """Skip test on specific platform."""
    pass

@pytest.mark.xfail(reason="Known bug #123")
def test_known_bug():
    """Expected to fail."""
    pass
```

## Best Practices

### DO

✅ Write descriptive test names
✅ Use fixtures for common setup
✅ Follow AAA pattern consistently
✅ Test one behavior per test
✅ Mock all external dependencies
✅ Test edge cases and error conditions
✅ Keep tests simple and readable
✅ Use parametrize for similar test cases
✅ Add docstrings to every test
✅ Ensure tests are independent

### DON'T

❌ Test framework internals
❌ Test multiple behaviors in one test
❌ Use real databases or external services
❌ Share state between tests
❌ Write flaky tests
❌ Skip cleanup in fixtures
❌ Use production data
❌ Write overly complex tests
❌ Depend on test execution order
❌ Leave commented-out tests

## Common Patterns

### Testing Time-Dependent Code

```python
def test_timestamp_is_utc():
    """Test that timestamps are in UTC."""
    message = create_message()

    # Verify UTC timezone
    assert message.timestamp.tzinfo == timezone.utc

    # Verify recent timestamp with tolerance
    now = datetime.now(timezone.utc)
    assert (now - message.timestamp).total_seconds() < 1
```

### Testing Random Behavior

```python
def test_random_id_generation():
    """Test random ID generation produces unique IDs."""
    # Generate multiple IDs
    ids = {generate_random_id() for _ in range(100)}

    # Verify all unique
    assert len(ids) == 100

    # Verify format
    for id in ids:
        assert len(id) == 16
        assert id.isalnum()
```

### Testing State Changes

```python
def test_state_transition():
    """Test object transitions through states correctly."""
    # Arrange
    workflow = Workflow()
    assert workflow.state == State.PENDING

    # Act & Assert - test each transition
    workflow.start()
    assert workflow.state == State.RUNNING

    workflow.complete()
    assert workflow.state == State.COMPLETED
```

## Running Unit Tests

```bash
# Run all unit tests
pytest tests/unit/

# Run specific test file
pytest tests/unit/test_jwt.py

# Run specific test class
pytest tests/unit/test_jwt.py::TestJWTHandler

# Run specific test
pytest tests/unit/test_jwt.py::TestJWTHandler::test_create_access_token_basic

# Run with verbose output
pytest tests/unit/ -vv

# Run with coverage
pytest tests/unit/ --cov=src --cov-report=html

# Run only fast tests (exclude slow)
pytest tests/unit/ -m "not slow"

# Run with print output
pytest tests/unit/ -s
```

## References

- **TESTING_POLICY.md** - When tests are required
- **INTEGRATION_TESTING.md** - Integration testing patterns
- **MOCKING_STRATEGIES.md** - Detailed mocking strategies
- **COVERAGE_STANDARDS.md** - Coverage requirements and tools

## Examples

See SARK repository for comprehensive examples:
- `/home/jhenry/Source/sark/tests/unit/auth/test_jwt.py` - JWT testing (570 lines, 43+ tests)
- `/home/jhenry/Source/sark/tests/unit/auth/test_api_key.py` - API key testing
- `/home/jhenry/Source/sark/tests/conftest.py` - Common fixtures

---

**Last Updated**: 2025-12-26
**Extracted From**: SARK project and thesymposium
**Applicable To**: All agent development projects
