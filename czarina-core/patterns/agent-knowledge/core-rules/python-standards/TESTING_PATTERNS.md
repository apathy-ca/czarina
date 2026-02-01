# Python Testing Patterns

**Source:** Extracted from [SARK](https://github.com/sark) codebase analysis
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This document establishes testing patterns for Python applications based on SARK's implementation. These patterns ensure comprehensive test coverage, maintainable test suites, and efficient test execution using pytest.

## Test Organization

### Directory Structure

Mirror the source code structure in your tests directory:

```
tests/
├── conftest.py              # Shared fixtures and configuration
├── adapters/
│   ├── conftest.py         # Adapter-specific fixtures
│   ├── test_http_adapter.py
│   ├── test_grpc_adapter.py
│   └── test_mcp_adapter.py
├── services/
│   ├── test_policy_service.py
│   ├── test_rate_limiter.py
│   └── auth/
│       ├── test_jwt.py
│       └── test_session.py
├── api/
│   ├── test_dependencies.py
│   └── routers/
│       ├── test_policy.py
│       └── test_servers.py
├── integration/
│   ├── conftest.py
│   └── test_full_workflow.py
└── performance/
    └── test_rate_limiting.py
```

**Key Principles:**
- Test directory mirrors `src/` structure
- One test file per source file
- Separate integration and unit tests
- `conftest.py` at each level for scoped fixtures

### Test File Naming

**Convention:**
- Test files: `test_<module_name>.py`
- Test classes: `Test<ClassName>`
- Test functions: `test_<function_name>_<scenario>`

**Example from SARK** (`tests/adapters/test_http_adapter.py`):

```python
"""
Test suite for HTTP adapter.

Tests cover:
- Authentication strategies
- OpenAPI discovery
- Capability invocation
- Rate limiting
- Circuit breaker
- Error handling
- Streaming support

Version: 2.0.0
Engineer: ENGINEER-2
"""


class TestNoAuthStrategy:
    """Test NoAuthStrategy."""

    def test_apply(self):
        """Test that no auth doesn't modify request."""
        pass

    @pytest.mark.asyncio
    async def test_refresh(self):
        """Test refresh does nothing."""
        pass


class TestBasicAuthStrategy:
    """Test BasicAuthStrategy."""

    def test_apply(self):
        """Test Basic Auth header is added."""
        pass

    def test_validate_config_valid(self):
        """Test valid config."""
        pass

    def test_validate_config_missing_username(self):
        """Test validation fails if username missing."""
        pass
```

## Test Class Organization

### Group Related Tests in Classes

Organize tests by the class or component they test:

**Example from SARK:**

```python
class TestCircuitBreaker:
    """Test CircuitBreaker functionality."""

    @pytest.mark.asyncio
    async def test_circuit_opens_after_failures(self):
        """Test circuit opens after threshold failures."""
        breaker = CircuitBreaker(failure_threshold=3, recovery_timeout=60.0)

        async def failing_func():
            raise Exception("Test error")

        # First 3 failures should go through
        for _ in range(3):
            with pytest.raises(Exception):
                await breaker.call(failing_func)

        assert breaker.state == "OPEN"

        # Next call should fail immediately
        with pytest.raises(InvocationError, match="Circuit breaker is OPEN"):
            await breaker.call(failing_func)

    @pytest.mark.asyncio
    async def test_circuit_closes_after_success(self):
        """Test circuit closes after successful call in HALF_OPEN state."""
        breaker = CircuitBreaker(failure_threshold=2, recovery_timeout=0.1)

        call_count = [0]

        async def flaky_func():
            call_count[0] += 1
            if call_count[0] <= 2:
                raise Exception("Test error")
            return "success"

        # Open the circuit
        for _ in range(2):
            with pytest.raises(Exception):
                await breaker.call(flaky_func)

        assert breaker.state == "OPEN"

        # Wait for recovery timeout
        await asyncio.sleep(0.2)

        # Next call should enter HALF_OPEN and succeed
        result = await breaker.call(flaky_func)
        assert result == "success"
        assert breaker.state == "CLOSED"
```

**Benefits:**
- Related tests grouped together
- Clear test organization
- Easy to find tests for specific functionality
- Shared setup via class-level fixtures

## Fixture Patterns

### Shared Fixtures in conftest.py

Define reusable fixtures in `conftest.py`:

**Example from SARK** (`tests/conftest.py`):

```python
"""Pytest configuration and fixtures."""

from unittest.mock import AsyncMock, MagicMock
import pytest


@pytest.fixture
async def db_session() -> AsyncMock:
    """Mock database session for tests.

    Provides a mock AsyncSession with common methods.
    Automatically closes after test completion.
    """
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


@pytest.fixture
def mock_redis() -> MagicMock:
    """Mock Redis client for tests.

    Provides a mock Redis client with common operations.
    """
    redis = MagicMock()
    redis.get = AsyncMock(return_value=None)
    redis.set = AsyncMock(return_value=True)
    redis.delete = AsyncMock(return_value=1)
    redis.exists = AsyncMock(return_value=0)
    redis.expire = AsyncMock(return_value=True)
    redis.keys = AsyncMock(return_value=[])
    redis.pipeline = MagicMock(
        return_value=MagicMock(
            execute=AsyncMock(return_value=[]),
            get=MagicMock(),
            set=MagicMock(),
            delete=MagicMock(),
        )
    )
    redis.ping = AsyncMock(return_value=True)
    redis.close = AsyncMock()

    return redis


@pytest.fixture
def opa_client() -> MagicMock:
    """Mock OPA client for tests."""
    client = MagicMock()
    client.evaluate_policy = AsyncMock()
    client.evaluate_policy_batch = AsyncMock(return_value=[])
    client.check_tool_access = AsyncMock()
    client.check_server_registration = AsyncMock()
    client.invalidate_cache = AsyncMock(return_value=0)
    client.get_cache_metrics = MagicMock(return_value={})
    client.get_cache_size = AsyncMock(return_value=0)
    client.close = AsyncMock()
    client.health_check = AsyncMock(return_value={"opa": True, "cache": True, "overall": True})
    client.authorize = AsyncMock(return_value=True)

    return client
```

### Autouse Fixtures for Common Setup

Use `autouse=True` for fixtures that should run for all tests:

```python
@pytest.fixture(autouse=True)
def mock_database(monkeypatch: pytest.MonkeyPatch) -> None:
    """Mock database initialization for all tests.

    Prevents actual database connections during test runs.
    """

    async def mock_init_db() -> None:
        """Mock database initialization."""
        pass

    monkeypatch.setattr("sark.db.session.init_db", mock_init_db)


@pytest.fixture(autouse=True)
def mock_db_engines(monkeypatch: pytest.MonkeyPatch) -> None:
    """Mock database engines to prevent connection attempts."""
    mock_engine = MagicMock()
    mock_engine.begin = AsyncMock()

    def mock_get_postgres_engine() -> MagicMock:
        return mock_engine

    monkeypatch.setattr("sark.db.session.get_postgres_engine", mock_get_postgres_engine)
```

### Parametric Fixtures

Create fixtures that accept parameters:

```python
@pytest.fixture
def create_user_context():
    """Factory fixture to create UserContext with custom attributes."""

    def _create(
        user_id: str = "test-user",
        email: str = "test@example.com",
        roles: list[str] | None = None,
        teams: list[str] | None = None,
    ) -> UserContext:
        return UserContext(
            data={
                "user_id": user_id,
                "email": email,
                "roles": roles or ["user"],
                "teams": teams or [],
                "permissions": [],
            }
        )

    return _create


# Usage
def test_admin_access(create_user_context):
    """Test admin access with custom user."""
    admin_user = create_user_context(roles=["admin"])
    assert admin_user.is_admin()

    regular_user = create_user_context(roles=["user"])
    assert not regular_user.is_admin()
```

## AsyncMock for Async Functions

### Using AsyncMock

Always use `AsyncMock` for async functions, not regular `MagicMock`:

**Example from SARK:**

```python
from unittest.mock import AsyncMock, MagicMock, patch

@pytest.mark.asyncio
async def test_discover_spec_direct_url():
    """Test discovering spec from direct URL."""
    openapi_spec = {
        "openapi": "3.0.0",
        "info": {"title": "Test API", "version": "1.0.0"},
        "paths": {}
    }

    with patch("httpx.AsyncClient") as mock_client_class:
        # Create AsyncMock for async context manager
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        # Create AsyncMock for async response
        mock_response = AsyncMock()
        mock_response.raise_for_status = MagicMock()  # Sync method
        mock_response.json.return_value = openapi_spec  # Sync return
        mock_client.get.return_value = mock_response  # Async method returns response

        discovery = OpenAPIDiscovery(
            base_url="https://api.example.com",
            spec_url="https://api.example.com/openapi.json"
        )

        spec = await discovery.discover_spec()

        assert spec == openapi_spec
        assert discovery.openapi_version == "3.0.0"
```

**Key Points:**
- Use `AsyncMock()` for async methods
- Use `MagicMock()` for sync methods
- Async context managers need `__aenter__` and `__aexit__` mocked
- Return values can be sync or async depending on the original method

## Pytest Markers

### Async Tests

Mark async tests with `@pytest.mark.asyncio`:

```python
import pytest

@pytest.mark.asyncio
async def test_async_function():
    """Test async function."""
    result = await some_async_function()
    assert result == expected_value
```

### Parametrize Tests

Use `@pytest.mark.parametrize` for data-driven tests:

```python
@pytest.mark.parametrize(
    "auth_type,expected_class",
    [
        ("none", NoAuthStrategy),
        ("basic", BasicAuthStrategy),
        ("bearer", BearerAuthStrategy),
        ("oauth2", OAuth2Strategy),
        ("api_key", APIKeyStrategy),
    ],
)
def test_create_auth_strategy(auth_type, expected_class):
    """Test auth strategy factory creates correct type."""
    config = {"type": auth_type}
    if auth_type == "basic":
        config.update({"username": "user", "password": "pass"})
    elif auth_type == "bearer":
        config.update({"token": "test-token"})
    elif auth_type == "oauth2":
        config.update({
            "token_url": "https://auth.example.com/token",
            "client_id": "client",
            "client_secret": "secret"
        })
    elif auth_type == "api_key":
        config.update({"api_key": "key123"})

    strategy = create_auth_strategy(config)
    assert isinstance(strategy, expected_class)
```

### Skip and XFail

Use markers to skip or mark expected failures:

```python
@pytest.mark.skip(reason="Feature not yet implemented")
def test_future_feature():
    """Test feature that will be implemented later."""
    pass


@pytest.mark.xfail(reason="Known bug in upstream library")
def test_known_issue():
    """Test that currently fails due to known issue."""
    assert buggy_function() == expected_value


@pytest.mark.skipif(sys.version_info < (3, 11), reason="Requires Python 3.11+")
def test_python311_feature():
    """Test feature that requires Python 3.11."""
    pass
```

### Custom Markers

Define custom markers in `pytest.ini` or `pyproject.toml`:

```toml
[tool.pytest.ini_options]
markers = [
    "integration: Integration tests (slow)",
    "unit: Unit tests (fast)",
    "security: Security-related tests",
    "adapter: Adapter tests",
]
```

**Usage:**

```python
@pytest.mark.integration
@pytest.mark.asyncio
async def test_full_workflow():
    """Integration test for complete workflow."""
    pass


@pytest.mark.unit
def test_validation():
    """Fast unit test for validation logic."""
    pass
```

**Run specific markers:**

```bash
# Run only unit tests
pytest -m unit

# Run everything except integration tests
pytest -m "not integration"

# Run security and adapter tests
pytest -m "security or adapter"
```

## Contract Testing Pattern

### BaseAdapterTest for Protocol Adapters

Create abstract test classes to ensure all adapters implement required functionality:

**Example Pattern:**

```python
from abc import ABC, abstractmethod
import pytest


class BaseAdapterTest(ABC):
    """Abstract base class for adapter tests.

    All adapter test classes should inherit from this to ensure
    consistent testing of adapter contract.
    """

    @abstractmethod
    @pytest.fixture
    def adapter(self):
        """Fixture that returns the adapter instance to test.

        Must be implemented by subclasses.
        """
        pass

    def test_protocol_name(self, adapter):
        """Test adapter has protocol_name property."""
        assert hasattr(adapter, "protocol_name")
        assert isinstance(adapter.protocol_name, str)
        assert len(adapter.protocol_name) > 0

    def test_protocol_version(self, adapter):
        """Test adapter has protocol_version property."""
        assert hasattr(adapter, "protocol_version")
        assert isinstance(adapter.protocol_version, str)

    @pytest.mark.asyncio
    async def test_discover_resources(self, adapter):
        """Test adapter can discover resources."""
        # This is a contract test - all adapters must implement
        resources = await adapter.discover_resources({})
        assert isinstance(resources, list)

    @pytest.mark.asyncio
    async def test_validate_request(self, adapter):
        """Test adapter can validate requests."""
        request = InvocationRequest(
            capability_id="test",
            principal_id="user-1",
            arguments={},
        )
        result = await adapter.validate_request(request)
        assert isinstance(result, bool)


class TestHTTPAdapter(BaseAdapterTest):
    """Test HTTPAdapter implementation."""

    @pytest.fixture
    def adapter(self):
        """Provide HTTPAdapter instance."""
        return HTTPAdapter(base_url="https://api.example.com")

    def test_http_specific_feature(self, adapter):
        """Test HTTP-specific functionality."""
        assert adapter.base_url == "https://api.example.com"


class TestGRPCAdapter(BaseAdapterTest):
    """Test GRPCAdapter implementation."""

    @pytest.fixture
    def adapter(self):
        """Provide GRPCAdapter instance."""
        return GRPCAdapter(endpoint="grpc://api.example.com:50051")

    def test_grpc_specific_feature(self, adapter):
        """Test gRPC-specific functionality."""
        assert adapter.endpoint.startswith("grpc://")
```

**Benefits:**
- Ensures all adapters implement the contract
- Reduces test duplication
- Easy to add new contract requirements
- Clear interface expectations

## Test Naming Conventions

### Descriptive Test Names

Use descriptive names that explain what is being tested:

**Pattern:** `test_<method>_<scenario>_<expected_outcome>`

**Examples from SARK:**

```python
def test_apply():
    """Test that no auth doesn't modify request."""
    pass

def test_validate_config_missing_username():
    """Test validation fails if username missing."""
    pass

def test_circuit_opens_after_failures():
    """Test circuit opens after threshold failures."""
    pass

def test_health_check_healthy():
    """Test health check returns True for healthy API."""
    pass

def test_health_check_unhealthy():
    """Test health check returns False for unhealthy API."""
    pass
```

### Naming Patterns

```python
# Testing success path
def test_create_policy_success():
    """Test policy creation succeeds with valid data."""
    pass

# Testing validation
def test_create_policy_missing_name():
    """Test policy creation fails when name is missing."""
    pass

# Testing error handling
def test_create_policy_database_error():
    """Test policy creation handles database errors gracefully."""
    pass

# Testing edge cases
def test_rate_limiter_exactly_at_limit():
    """Test rate limiter behavior when exactly at limit."""
    pass

# Testing state transitions
def test_circuit_breaker_transitions_to_half_open():
    """Test circuit breaker enters HALF_OPEN after recovery timeout."""
    pass
```

## Assertion Patterns

### Clear Assertions

Make assertions clear and specific:

```python
# Good - specific assertion with message
assert response.status_code == 200, f"Expected 200, got {response.status_code}"
assert user.email == "test@example.com"
assert len(policies) == 3

# Good - multiple related assertions
result = await service.create_policy(name="Test", type=PolicyType.PRIVACY)
assert result is not None
assert result.name == "Test"
assert result.policy_type == PolicyType.PRIVACY
assert result.id is not None

# Good - exception assertions with match
with pytest.raises(ValidationError, match="username is required"):
    validate_user_data({})

# Bad - unclear assertion
assert result  # What property of result are we checking?
assert x  # What is x supposed to be?
```

### Testing Exceptions

```python
import pytest

def test_validation_raises_error():
    """Test validation raises ValueError for invalid input."""
    with pytest.raises(ValueError):
        validate_input("")


def test_validation_error_message():
    """Test validation error has specific message."""
    with pytest.raises(ValueError, match="Name cannot be empty"):
        validate_input("")


def test_multiple_error_conditions():
    """Test different error conditions."""
    # Test missing username
    with pytest.raises(AuthenticationError, match="username"):
        BasicAuthStrategy(username="", password="pass")

    # Test missing password
    with pytest.raises(AuthenticationError, match="password"):
        BasicAuthStrategy(username="user", password="")
```

## Mocking Best Practices

### Patching

Use `patch` for external dependencies:

```python
from unittest.mock import patch, AsyncMock

@pytest.mark.asyncio
async def test_with_http_client():
    """Test function that makes HTTP requests."""
    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_response = AsyncMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"result": "success"}
        mock_client.get.return_value = mock_response

        result = await fetch_data("https://api.example.com/data")

        assert result == {"result": "success"}
        mock_client.get.assert_called_once_with("https://api.example.com/data")
```

### Verify Mock Calls

```python
def test_service_calls_database():
    """Test service interacts with database correctly."""
    mock_db = AsyncMock()
    service = PolicyService(db=mock_db)

    await service.create_policy(
        name="Test",
        description="Test policy",
        policy_type=PolicyType.PRIVACY,
        initial_content="content",
        created_by=user_id,
    )

    # Verify database interactions
    assert mock_db.add.call_count == 2  # Policy + PolicyVersion
    mock_db.flush.assert_called_once()
    mock_db.commit.assert_called_once()
    mock_db.refresh.assert_called_once()

    # Check call arguments
    policy_call = mock_db.add.call_args_list[0]
    assert isinstance(policy_call[0][0], Policy)
```

## Success Criteria

A test suite follows these patterns when:

- Test directory mirrors source structure
- Test files named `test_<module>.py`
- Test classes group related tests
- Shared fixtures in `conftest.py`
- `AsyncMock` used for async functions
- Tests marked with appropriate pytest markers
- Contract tests ensure interface compliance
- Test names are descriptive and follow conventions
- Assertions are clear and specific
- Mocks verify expected interactions
- Tests are isolated and independent
- Fast unit tests separate from slow integration tests

## Related Standards

- [CODING_STANDARDS.md](./CODING_STANDARDS.md) - General coding standards
- [ASYNC_PATTERNS.md](./ASYNC_PATTERNS.md) - Testing async code
- [DEPENDENCY_INJECTION.md](./DEPENDENCY_INJECTION.md) - Mocking dependencies
- [ERROR_HANDLING.md](./ERROR_HANDLING.md) - Testing error conditions

## References

- [Pytest Documentation](https://docs.pytest.org/)
- [Pytest AsyncIO](https://pytest-asyncio.readthedocs.io/)
- [unittest.mock Documentation](https://docs.python.org/3/library/unittest.mock.html)
- [Testing FastAPI Applications](https://fastapi.tiangolo.com/tutorial/testing/)
- [SARK Codebase](https://github.com/sark) - Source of extracted patterns
