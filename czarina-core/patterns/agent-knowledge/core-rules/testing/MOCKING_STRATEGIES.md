# Mocking Strategies

Comprehensive mocking and stubbing patterns for agent development, extracted from SARK and thesymposium test suites.

## Overview

Mocking is the practice of replacing real dependencies with controlled substitutes during testing. Proper mocking enables fast, isolated unit tests while maintaining test reliability and clarity.

## When to Mock

### Always Mock in Unit Tests

- External APIs and web services
- Database connections and queries
- File system operations
- Network calls
- Time-dependent functions
- Random number generators (in some cases)
- Third-party libraries
- Message queues and event systems
- Email/SMS services
- Cloud services (S3, etc.)

### Never Mock in Integration Tests

- Database connections (use real test database)
- Cache systems (use real Redis/Memcached)
- Message queues (use real RabbitMQ/Kafka)
- Internal service integrations
- Configuration loading
- Application framework internals

### Sometimes Mock

- **Slow external services** - Mock in unit tests, use real in integration tests
- **Expensive operations** - Mock in unit tests, test with real in performance tests
- **Unreliable services** - Mock for consistency, test with real occasionally

## Mocking Tools and Libraries

### unittest.mock

Python's built-in mocking library:

```python
from unittest.mock import AsyncMock, MagicMock, Mock, patch, call
```

**MagicMock**: Auto-generates magic methods (`__str__`, `__len__`, etc.)
**Mock**: Basic mock object
**AsyncMock**: Mock for async functions
**patch**: Context manager/decorator for patching
**call**: Represents a call to a mock

### pytest-mock

pytest plugin providing `mocker` fixture:

```python
def test_with_mocker(mocker):
    """Test using pytest-mock."""
    mock_function = mocker.patch('module.function')
    mock_function.return_value = "mocked"
```

## Mock Object Patterns

### Basic Mock

```python
from unittest.mock import MagicMock

# Create mock
mock_obj = MagicMock()

# Set return value
mock_obj.method.return_value = "result"

# Use mock
result = mock_obj.method()
assert result == "result"

# Verify calls
mock_obj.method.assert_called_once()
```

### AsyncMock for Async Functions

```python
from unittest.mock import AsyncMock

# Create async mock
mock_async = AsyncMock()
mock_async.return_value = "result"

# Use in async code
async def test_function():
    result = await mock_async()
    assert result == "result"
    mock_async.assert_called_once()
```

### Mock with Side Effects

```python
# Return different values on successive calls
mock_obj.method.side_effect = ["first", "second", "third"]

assert mock_obj.method() == "first"
assert mock_obj.method() == "second"
assert mock_obj.method() == "third"

# Raise exception
mock_obj.method.side_effect = ValueError("Invalid input")

with pytest.raises(ValueError):
    mock_obj.method()
```

### Mock with Spec

Restrict mock to actual interface:

```python
from mymodule import RealClass

# Mock will only allow methods/attributes that exist on RealClass
mock_obj = MagicMock(spec=RealClass)

# This works if RealClass has this method
mock_obj.existing_method()

# This raises AttributeError
mock_obj.nonexistent_method()  # AttributeError
```

## Common Mock Fixtures

### Database Session Mock

From SARK `conftest.py`:

```python
@pytest.fixture
async def db_session() -> AsyncMock:
    """Mock database session for tests."""
    session = MagicMock()
    session.add = MagicMock()
    session.commit = AsyncMock()
    session.flush = AsyncMock()
    session.execute = AsyncMock(
        return_value=MagicMock(
            scalars=MagicMock(
                return_value=MagicMock(all=MagicMock(return_value=[]))
            )
        )
    )
    session.close = AsyncMock()
    session.rollback = AsyncMock()
    session.refresh = AsyncMock()

    yield session

    await session.close()
```

Usage:

```python
@pytest.mark.asyncio
async def test_with_db_session(db_session):
    """Test using mocked database session."""
    # Setup mock return value
    db_session.execute.return_value.scalars.return_value.all.return_value = [
        User(id=uuid4(), email="test@example.com")
    ]

    # Use session
    result = await db_session.execute("SELECT * FROM users")
    users = result.scalars().all()

    assert len(users) == 1
    assert users[0].email == "test@example.com"
```

### Redis Client Mock

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
    redis.mget = AsyncMock(return_value=[])
    redis.mset = AsyncMock(return_value=True)
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
```

### HTTP Client Mock

```python
@pytest.fixture
def mock_http_client():
    """Mock HTTP client for tests."""
    client = AsyncMock()

    # Mock response object
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {"status": "success"}
    mock_response.text = "response text"

    # Set as return value
    client.get = AsyncMock(return_value=mock_response)
    client.post = AsyncMock(return_value=mock_response)
    client.put = AsyncMock(return_value=mock_response)
    client.delete = AsyncMock(return_value=mock_response)

    return client
```

### External API Mock

```python
@pytest.fixture
def mock_external_api():
    """Mock external API service."""
    api = AsyncMock()
    api.fetch_user = AsyncMock(
        return_value={"id": "123", "name": "Test User"}
    )
    api.create_resource = AsyncMock(return_value={"id": "456", "status": "created"})
    api.health_check = AsyncMock(return_value=True)

    return api
```

## Patching Strategies

### Patch Decorator

```python
from unittest.mock import patch

@patch("module.external_function")
def test_with_patch(mock_function):
    """Test using patch decorator."""
    # Setup mock
    mock_function.return_value = "mocked result"

    # Call code that uses external_function
    result = my_function_that_calls_external()

    assert result == "expected"
    mock_function.assert_called_once_with("expected_arg")
```

### Patch Context Manager

```python
def test_with_patch_context():
    """Test using patch context manager."""
    with patch("module.external_function") as mock_function:
        mock_function.return_value = "mocked result"

        result = my_function_that_calls_external()

        assert result == "expected"
```

### Patch Multiple

```python
@patch("module.function_one")
@patch("module.function_two")
@patch("module.function_three")
def test_patch_multiple(mock_three, mock_two, mock_one):
    """Test patching multiple functions."""
    # Note: decorators apply bottom-up, so arguments are reversed
    mock_one.return_value = "one"
    mock_two.return_value = "two"
    mock_three.return_value = "three"

    result = my_function()

    assert result is not None
```

### Patch Object

```python
from unittest.mock import patch

class TestMyClass:
    """Test MyClass."""

    @patch.object(MyClass, "method_to_mock")
    def test_method(self, mock_method):
        """Test with mocked method."""
        mock_method.return_value = "mocked"

        obj = MyClass()
        result = obj.method_to_mock()

        assert result == "mocked"
```

### Monkeypatch (pytest)

pytest's `monkeypatch` fixture for patching:

```python
@pytest.fixture(autouse=True)
def mock_database(monkeypatch: pytest.MonkeyPatch) -> None:
    """Mock database initialization for all tests."""

    async def mock_init_db() -> None:
        """Mock database initialization."""
        pass

    # Patch module-level function
    monkeypatch.setattr("sark.db.session.init_db", mock_init_db)

    # Patch environment variable
    monkeypatch.setenv("DATABASE_URL", "mock://localhost")

    # Patch class method
    monkeypatch.setattr("sark.db.session.get_postgres_engine", lambda: MagicMock())
```

## Spy Pattern

Spy allows calling real method while recording calls:

```python
from unittest.mock import MagicMock

class TestWithSpy:
    """Test using spy pattern."""

    def test_spy_on_method(self):
        """Test spying on method calls."""
        obj = RealObject()

        # Wrap method to spy on it
        original_method = obj.method
        obj.method = MagicMock(side_effect=original_method)

        # Call method (executes real code)
        result = obj.method("arg")

        # Verify call while getting real result
        obj.method.assert_called_once_with("arg")
        assert result == "real result"
```

## Stub Pattern

Stubs provide predetermined responses:

```python
class StubEmailService:
    """Stub email service for testing."""

    def __init__(self):
        self.sent_emails = []

    async def send_email(self, to: str, subject: str, body: str):
        """Record email instead of sending."""
        self.sent_emails.append({
            "to": to,
            "subject": subject,
            "body": body,
        })
        return True


@pytest.fixture
def email_service():
    """Provide stub email service."""
    return StubEmailService()


@pytest.mark.asyncio
async def test_with_stub(email_service):
    """Test using stub."""
    # Use stub
    await email_service.send_email(
        to="test@example.com",
        subject="Test",
        body="Test body",
    )

    # Verify
    assert len(email_service.sent_emails) == 1
    assert email_service.sent_emails[0]["to"] == "test@example.com"
```

## Mock Verification

### Assert Called

```python
# Assert called at least once
mock_obj.method.assert_called()

# Assert called exactly once
mock_obj.method.assert_called_once()

# Assert called with specific arguments
mock_obj.method.assert_called_with("arg1", "arg2")

# Assert called once with specific arguments
mock_obj.method.assert_called_once_with("arg1", kwarg="value")

# Assert any call with arguments
mock_obj.method.assert_any_call("arg1")

# Assert never called
mock_obj.method.assert_not_called()
```

### Call Count

```python
# Check call count
assert mock_obj.method.call_count == 3

# Get call arguments
calls = mock_obj.method.call_args_list
assert len(calls) == 3
assert calls[0] == call("first")
assert calls[1] == call("second")
```

### Call Arguments

```python
# Get most recent call arguments
args, kwargs = mock_obj.method.call_args
assert args == ("arg1", "arg2")
assert kwargs == {"key": "value"}

# Check if called with
mock_obj.method.assert_called_with("arg1", key="value")
```

## Advanced Mocking Patterns

### Mocking Class Instances

```python
@patch("module.MyClass")
def test_mocked_class(MockClass):
    """Test with mocked class."""
    # Setup mock instance
    mock_instance = MockClass.return_value
    mock_instance.method.return_value = "result"

    # Code creates instance and calls method
    obj = MyClass()
    result = obj.method()

    # Verify
    MockClass.assert_called_once()
    mock_instance.method.assert_called_once()
```

### Mocking Properties

```python
class TestProperties:
    """Test mocking properties."""

    def test_mock_property(self):
        """Test mocking a property."""
        mock_obj = MagicMock()

        # Mock property getter
        type(mock_obj).my_property = PropertyMock(return_value="value")

        assert mock_obj.my_property == "value"
```

### Mocking Context Managers

```python
@pytest.mark.asyncio
async def test_async_context_manager():
    """Test mocking async context manager."""
    mock_cm = AsyncMock()

    # Setup enter/exit
    mock_cm.__aenter__.return_value = "resource"
    mock_cm.__aexit__.return_value = None

    async with mock_cm as resource:
        assert resource == "resource"

    mock_cm.__aenter__.assert_called_once()
    mock_cm.__aexit__.assert_called_once()
```

### Mocking Chained Calls

```python
def test_chained_calls():
    """Test mocking chained method calls."""
    mock_obj = MagicMock()

    # Setup chain: obj.method1().method2().method3()
    mock_obj.method1.return_value.method2.return_value.method3.return_value = "result"

    result = mock_obj.method1().method2().method3()
    assert result == "result"
```

### Partial Mocking

Mock only specific methods while keeping others real:

```python
from unittest.mock import patch

class MyClass:
    def real_method(self):
        return "real"

    def method_to_mock(self):
        return "real"


def test_partial_mock():
    """Test partial mocking of class."""
    obj = MyClass()

    # Patch only one method
    with patch.object(obj, "method_to_mock", return_value="mocked"):
        assert obj.method_to_mock() == "mocked"
        assert obj.real_method() == "real"
```

## Time Mocking

### Freezegun

```python
from freezegun import freeze_time
from datetime import datetime, UTC

@freeze_time("2025-01-15 12:00:00")
def test_with_frozen_time():
    """Test with frozen time."""
    now = datetime.now(UTC)
    assert now.year == 2025
    assert now.month == 1
    assert now.day == 15
```

### Manual Time Mocking

```python
@patch("module.datetime")
def test_mock_datetime(mock_datetime):
    """Test mocking datetime."""
    # Setup mock
    mock_now = datetime(2025, 1, 15, 12, 0, 0)
    mock_datetime.now.return_value = mock_now

    # Test code that uses datetime.now()
    result = function_that_uses_now()

    assert result.year == 2025
```

## Database Mocking Strategies

### Simple Query Mock

```python
@pytest.mark.asyncio
async def test_database_query(db_session):
    """Test with mocked database query."""
    # Setup mock query result
    mock_user = User(id=uuid4(), email="test@example.com")

    db_session.execute.return_value.scalars.return_value.all.return_value = [
        mock_user
    ]

    # Execute query
    result = await db_session.execute("SELECT * FROM users")
    users = result.scalars().all()

    # Verify
    assert len(users) == 1
    assert users[0].email == "test@example.com"
```

### Transaction Mock

```python
@pytest.mark.asyncio
async def test_transaction(db_session):
    """Test mocked database transaction."""
    # Mock transaction context manager
    transaction_mock = AsyncMock()
    db_session.begin = MagicMock(return_value=transaction_mock)

    async with db_session.begin():
        await db_session.execute("INSERT INTO users ...")

    transaction_mock.__aenter__.assert_called_once()
    transaction_mock.__aexit__.assert_called_once()
```

## HTTP Mocking

### httpx Mock

```python
import pytest
from httpx import AsyncClient, Response

@pytest.mark.asyncio
async def test_http_request(mocker):
    """Test HTTP request with mocked client."""
    # Mock response
    mock_response = Response(
        status_code=200,
        json={"status": "success"},
    )

    # Patch httpx.AsyncClient.get
    mocker.patch.object(
        AsyncClient,
        "get",
        return_value=mock_response,
    )

    # Make request
    async with AsyncClient() as client:
        response = await client.get("https://api.example.com")

    assert response.status_code == 200
    assert response.json() == {"status": "success"}
```

### pytest-httpx

```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_with_httpx_mock(httpx_mock):
    """Test using pytest-httpx."""
    # Setup mock response
    httpx_mock.add_response(
        url="https://api.example.com/users",
        json={"users": []},
        status_code=200,
    )

    # Make request
    async with AsyncClient() as client:
        response = await client.get("https://api.example.com/users")

    assert response.status_code == 200
    assert response.json() == {"users": []}
```

## Best Practices

### DO

✅ Mock external dependencies in unit tests
✅ Use `spec` parameter to prevent typos
✅ Verify mock was called correctly
✅ Reset mocks between tests (pytest does this automatically)
✅ Use fixtures for common mocks
✅ Mock at the boundary (where your code calls external code)
✅ Use AsyncMock for async functions
✅ Keep mocks simple and focused
✅ Document complex mock setups
✅ Use real services in integration tests

### DON'T

❌ Mock everything (makes tests brittle)
❌ Mock code under test
❌ Over-specify mock behavior
❌ Forget to verify mock calls
❌ Use mocks in integration tests
❌ Mock framework internals
❌ Create complex mock hierarchies
❌ Reuse mocks across unrelated tests
❌ Mock without understanding what you're mocking
❌ Use mocks as a substitute for proper design

## Common Patterns

### Repository Pattern Mock

```python
@pytest.fixture
def mock_user_repository():
    """Mock user repository."""
    repo = AsyncMock()
    repo.get_by_id = AsyncMock(return_value=None)
    repo.get_by_email = AsyncMock(return_value=None)
    repo.create = AsyncMock(return_value=User(...))
    repo.update = AsyncMock(return_value=User(...))
    repo.delete = AsyncMock(return_value=True)
    repo.list_all = AsyncMock(return_value=[])

    return repo
```

### Service Layer Mock

```python
@pytest.fixture
def mock_auth_service():
    """Mock authentication service."""
    service = AsyncMock()
    service.authenticate = AsyncMock(return_value=("user_id", "token"))
    service.validate_token = AsyncMock(return_value=True)
    service.refresh_token = AsyncMock(return_value="new_token")
    service.logout = AsyncMock(return_value=True)

    return service
```

## Testing with Mocks

### Example: Testing Service with Mocked Dependencies

```python
class UserService:
    def __init__(self, db_session, cache, email_service):
        self.db = db_session
        self.cache = cache
        self.email_service = email_service

    async def create_user(self, email: str, name: str):
        # Create user in database
        user = User(id=uuid4(), email=email, name=name)
        self.db.add(user)
        await self.db.commit()

        # Cache user
        await self.cache.set(f"user:{user.id}", user.email)

        # Send welcome email
        await self.email_service.send_welcome(user.email)

        return user


@pytest.mark.asyncio
async def test_create_user(db_session, mock_redis, mock_email_service):
    """Test user creation with mocked dependencies."""
    # Arrange
    service = UserService(db_session, mock_redis, mock_email_service)

    # Act
    user = await service.create_user("test@example.com", "Test User")

    # Assert
    assert user.email == "test@example.com"
    db_session.add.assert_called_once()
    db_session.commit.assert_called_once()
    mock_redis.set.assert_called_once()
    mock_email_service.send_welcome.assert_called_once_with("test@example.com")
```

## References

- **TESTING_POLICY.md** - When to use mocking
- **UNIT_TESTING.md** - Unit testing patterns
- **INTEGRATION_TESTING.md** - When NOT to mock
- **COVERAGE_STANDARDS.md** - Coverage with mocks

## Examples

See SARK repository for comprehensive examples:
- `/home/jhenry/Source/sark/tests/conftest.py` - Common mock fixtures
- `/home/jhenry/Source/sark/tests/integration/conftest.py` - Integration fixtures
- `/home/jhenry/Source/sark/tests/unit/auth/test_jwt.py` - Mocking in unit tests

---

**Last Updated**: 2025-12-26
**Extracted From**: SARK project and thesymposium
**Applicable To**: All agent development projects
