# Test Fixture Template

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This template provides comprehensive patterns for creating test fixtures - reusable setup code, test data, and mock objects that can be shared across multiple tests.

## When to Use This Template

Use this template for:
- Creating reusable test setup code
- Defining shared test data across multiple tests
- Building mock objects and factories
- Setting up complex test environments
- Managing test lifecycle (setup/teardown)

## Quick Start

Fixtures reduce code duplication and make tests more maintainable by centralizing common setup logic.

---

## Python Fixture Template (pytest)

### Basic Fixtures

\`\`\`python
"""Common test fixtures."""

import pytest
from typing import Any


@pytest.fixture
def sample_data() -> dict[str, Any]:
    """Provide sample test data.

    Returns:
        Dictionary with common test data
    """
    return {
        "name": "Test Item",
        "value": 42,
        "active": True,
        "tags": ["test", "sample"],
    }


@pytest.fixture
def sample_list() -> list[dict[str, Any]]:
    """Provide list of sample items."""
    return [
        {"id": 1, "name": "Item 1", "value": 10},
        {"id": 2, "name": "Item 2", "value": 20},
        {"id": 3, "name": "Item 3", "value": 30},
    ]
\`\`\`

### Fixture Scopes

\`\`\`python
"""Fixtures with different scopes."""

import pytest


@pytest.fixture(scope="function")
def function_fixture():
    """Run before each test function (default scope).

    Useful for: Test data that needs to be fresh for each test
    """
    print("Setup for function")
    yield "function_data"
    print("Teardown for function")


@pytest.fixture(scope="class")
def class_fixture():
    """Run once per test class.

    Useful for: Expensive setup shared by class methods
    """
    print("Setup for class")
    yield "class_data"
    print("Teardown for class")


@pytest.fixture(scope="module")
def module_fixture():
    """Run once per module.

    Useful for: Database connections, external service clients
    """
    print("Setup for module")
    client = create_expensive_client()
    yield client
    print("Teardown for module")
    client.close()


@pytest.fixture(scope="session")
def session_fixture():
    """Run once per test session.

    Useful for: Docker containers, test databases
    """
    print("Setup for session")
    container = start_test_container()
    yield container
    print("Teardown for session")
    stop_test_container(container)
\`\`\`

### Fixture Dependencies

\`\`\`python
"""Fixtures that depend on other fixtures."""

import pytest
from sqlalchemy.ext.asyncio import AsyncSession


@pytest.fixture
async def db_session() -> AsyncSession:
    """Provide database session."""
    session = create_async_session()
    yield session
    await session.close()


@pytest.fixture
async def test_user(db_session: AsyncSession):
    """Create test user in database.

    Depends on: db_session fixture
    """
    from src.models import User

    user = User(email="test@example.com", name="Test User")
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    yield user

    # Cleanup
    await db_session.delete(user)
    await db_session.commit()


@pytest.fixture
async def test_resource(db_session: AsyncSession, test_user):
    """Create test resource owned by test user.

    Depends on: db_session, test_user fixtures
    """
    from src.models import Resource

    resource = Resource(
        user_id=test_user.id, name="Test Resource", data={"key": "value"}
    )
    db_session.add(resource)
    await db_session.commit()
    await db_session.refresh(resource)
    yield resource

    # Cleanup
    await db_session.delete(resource)
    await db_session.commit()
\`\`\`

### Factory Fixtures

\`\`\`python
"""Factory fixtures for creating test objects."""

import pytest
from typing import Callable
from uuid import uuid4


@pytest.fixture
def user_factory(db_session):
    """Provide factory function for creating users.

    Returns:
        Callable that creates User instances
    """

    async def _create_user(**kwargs):
        from src.models import User

        defaults = {
            "email": f"user{uuid4().hex[:8]}@example.com",
            "name": "Test User",
            "is_active": True,
        }
        defaults.update(kwargs)

        user = User(**defaults)
        db_session.add(user)
        await db_session.flush()
        await db_session.refresh(user)
        return user

    return _create_user


@pytest.fixture
def resource_factory(db_session, user_factory):
    """Provide factory function for creating resources."""

    async def _create_resource(user=None, **kwargs):
        if user is None:
            user = await user_factory()

        defaults = {
            "user_id": user.id,
            "name": f"Resource {uuid4().hex[:8]}",
            "data": {},
        }
        defaults.update(kwargs)

        from src.models import Resource

        resource = Resource(**defaults)
        db_session.add(resource)
        await db_session.flush()
        await db_session.refresh(resource)
        return resource

    return _create_resource


# Usage in test:
async def test_user_with_multiple_resources(user_factory, resource_factory):
    """Example using factory fixtures."""
    user = await user_factory(name="Custom Name")
    resource1 = await resource_factory(user=user, name="Resource 1")
    resource2 = await resource_factory(user=user, name="Resource 2")

    assert len(user.resources) == 2
\`\`\`

### Mock Fixtures

\`\`\`python
"""Mock object fixtures."""

import pytest
from unittest.mock import Mock, AsyncMock, MagicMock


@pytest.fixture
def mock_database():
    """Provide mock database client."""
    mock_db = Mock()
    mock_db.query.return_value = []
    mock_db.execute.return_value = {"rows_affected": 1}
    return mock_db


@pytest.fixture
def mock_http_client():
    """Provide mock HTTP client with common responses."""
    mock_client = AsyncMock()

    # Configure default successful response
    mock_client.get.return_value = Mock(
        status_code=200, json=lambda: {"status": "success", "data": {}}
    )

    mock_client.post.return_value = Mock(
        status_code=201, json=lambda: {"status": "created", "id": "123"}
    )

    return mock_client


@pytest.fixture
def mock_cache():
    """Provide mock cache with in-memory storage."""

    class MockCache:
        def __init__(self):
            self._store = {}

        async def get(self, key: str):
            return self._store.get(key)

        async def set(self, key: str, value: Any, ttl: int = None):
            self._store[key] = value

        async def delete(self, key: str):
            self._store.pop(key, None)

        async def clear(self):
            self._store.clear()

    return MockCache()


@pytest.fixture
def mock_external_api():
    """Provide mock for external API service."""
    mock_api = AsyncMock()

    # Configure common method returns
    mock_api.fetch_data.return_value = {
        "id": "test_id",
        "data": {"field": "value"},
    }

    mock_api.create_resource.return_value = {"id": "new_id", "status": "created"}

    mock_api.update_resource.return_value = {"id": "updated_id", "status": "updated"}

    return mock_api
\`\`\`

### Configuration Fixtures

\`\`\`python
"""Configuration fixtures for different test scenarios."""

import pytest
from src.config import Settings


@pytest.fixture
def test_settings():
    """Provide test configuration settings."""
    return Settings(
        app_name="test_app",
        app_env="test",
        database_url="postgresql://test:test@localhost:5433/test_db",
        redis_url="redis://localhost:6380/0",
        log_level="DEBUG",
        secret_key="test_secret_key",
    )


@pytest.fixture
def production_like_settings():
    """Provide production-like configuration for integration tests."""
    return Settings(
        app_name="test_app",
        app_env="production",
        database_url="postgresql://test:test@localhost:5433/prod_test_db",
        redis_url="redis://localhost:6380/1",
        log_level="INFO",
        secret_key="prod_test_secret",
        enable_rate_limiting=True,
        enable_caching=True,
    )


@pytest.fixture
def feature_flag_settings():
    """Provide settings with specific feature flags enabled."""
    return Settings(
        app_name="test_app",
        feature_new_ui=True,
        feature_beta_api=True,
        feature_experimental=False,
    )
\`\`\`

### Parametrized Fixtures

\`\`\`python
"""Parametrized fixtures for testing multiple scenarios."""

import pytest


@pytest.fixture(params=["sqlite", "postgresql", "mysql"])
def database_url(request):
    """Provide different database URLs for testing."""
    urls = {
        "sqlite": "sqlite+aiosqlite:///:memory:",
        "postgresql": "postgresql+asyncpg://test:test@localhost:5433/test",
        "mysql": "mysql+aiomysql://test:test@localhost:3307/test",
    }
    return urls[request.param]


@pytest.fixture(params=[1, 10, 100, 1000])
def batch_size(request):
    """Provide different batch sizes for testing."""
    return request.param


@pytest.fixture(params=["admin", "user", "guest"])
def user_role(request):
    """Provide different user roles for testing."""
    return request.param


# Usage: Test will run 3 times with different roles
def test_access_control(user_role):
    """Test access control for different user roles."""
    permissions = get_permissions(user_role)
    if user_role == "admin":
        assert "delete" in permissions
    elif user_role == "user":
        assert "read" in permissions and "write" in permissions
    else:  # guest
        assert permissions == ["read"]
\`\`\`

### Async Fixtures

\`\`\`python
"""Async fixture patterns."""

import pytest
import asyncio
from typing import AsyncGenerator


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
async def async_resource() -> AsyncGenerator:
    """Provide async resource with proper cleanup."""
    # Async setup
    resource = await create_async_resource()
    await resource.initialize()

    yield resource

    # Async teardown
    await resource.cleanup()
    await resource.close()


@pytest.fixture
async def async_context_manager():
    """Provide async context manager."""
    async with create_async_context() as context:
        await context.setup()
        yield context
        # Cleanup happens automatically via context manager
\`\`\`

### Temporary File Fixtures

\`\`\`python
"""Fixtures for temporary files and directories."""

import pytest
from pathlib import Path
import tempfile
import shutil


@pytest.fixture
def temp_dir():
    """Provide temporary directory."""
    temp_path = Path(tempfile.mkdtemp())
    yield temp_path
    shutil.rmtree(temp_path)


@pytest.fixture
def temp_file():
    """Provide temporary file."""
    fd, temp_path = tempfile.mkstemp()
    yield Path(temp_path)
    Path(temp_path).unlink()


@pytest.fixture
def sample_json_file(temp_dir):
    """Provide temporary JSON file with sample data."""
    import json

    data = {"name": "Test", "value": 42, "items": ["a", "b", "c"]}

    file_path = temp_dir / "sample.json"
    file_path.write_text(json.dumps(data, indent=2))

    yield file_path


@pytest.fixture
def sample_csv_file(temp_dir):
    """Provide temporary CSV file with sample data."""
    import csv

    file_path = temp_dir / "sample.csv"

    with file_path.open("w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["id", "name", "value"])
        writer.writerow([1, "Item 1", 10])
        writer.writerow([2, "Item 2", 20])
        writer.writerow([3, "Item 3", 30])

    yield file_path
\`\`\`

### Environment Variable Fixtures

\`\`\`python
"""Fixtures for managing environment variables."""

import pytest
import os


@pytest.fixture
def env_vars():
    """Provide environment variables with automatic cleanup."""
    original_env = os.environ.copy()

    # Set test environment variables
    test_env = {
        "DATABASE_URL": "postgresql://test:test@localhost:5433/test",
        "REDIS_URL": "redis://localhost:6380/0",
        "SECRET_KEY": "test_secret",
        "LOG_LEVEL": "DEBUG",
    }

    os.environ.update(test_env)

    yield test_env

    # Restore original environment
    os.environ.clear()
    os.environ.update(original_env)


@pytest.fixture
def clean_env():
    """Provide clean environment (no variables set)."""
    original_env = os.environ.copy()
    os.environ.clear()

    yield

    # Restore original environment
    os.environ.clear()
    os.environ.update(original_env)
\`\`\`

## TypeScript/JavaScript Fixture Template (Jest)

### Basic Fixtures

\`\`\`typescript
/**
 * Common test fixtures and setup
 */

import { setupTestDatabase, cleanupTestDatabase } from './database';

// Module-level setup/teardown
beforeAll(async () => {
  await setupTestDatabase();
});

afterAll(async () => {
  await cleanupTestDatabase();
});

// Function-level setup/teardown
beforeEach(async () => {
  await cleanTestData();
});

afterEach(async () => {
  jest.clearAllMocks();
});

// Fixture functions
export const sampleData = {
  user: {
    email: 'test@example.com',
    name: 'Test User',
  },
  resource: {
    name: 'Test Resource',
    data: { key: 'value' },
  },
};

export const createTestUser = async () => {
  const user = await User.create({
    email: `user${Date.now()}@example.com`,
    name: 'Test User',
  });
  return user;
};

export const createTestResource = async (userId?: string) => {
  const user = userId ? await User.findById(userId) : await createTestUser();

  const resource = await Resource.create({
    userId: user.id,
    name: 'Test Resource',
    data: {},
  });

  return resource;
};
\`\`\`

### Factory Pattern

\`\`\`typescript
/**
 * Factory fixtures for creating test data
 */

import { Factory } from './factory';
import { User, Resource } from '../src/models';

export const userFactory = new Factory<User>({
  email: () => `user${Date.now()}@example.com`,
  name: () => 'Test User',
  isActive: () => true,
  createdAt: () => new Date(),
});

export const resourceFactory = new Factory<Resource>({
  name: () => `Resource ${Date.now()}`,
  data: () => ({}),
  userId: async () => {
    const user = await userFactory.create();
    return user.id;
  },
});

// Usage in tests:
describe('User Tests', () => {
  it('should create user', async () => {
    const user = await userFactory.create({ name: 'Custom Name' });
    expect(user.name).toBe('Custom Name');
  });

  it('should create multiple users', async () => {
    const users = await userFactory.createMany(5);
    expect(users).toHaveLength(5);
  });
});
\`\`\`

## Best Practices

### Fixture Naming

✅ **Good:**
\`\`\`python
@pytest.fixture
def authenticated_user():
    """Clear, descriptive name."""
    ...

@pytest.fixture
def mock_payment_gateway():
    """Indicates it's a mock."""
    ...
\`\`\`

❌ **Bad:**
\`\`\`python
@pytest.fixture
def data():  # Too generic
    ...

@pytest.fixture
def fixture1():  # Meaningless name
    ...
\`\`\`

### Fixture Scope Selection

✅ **Good:**
\`\`\`python
@pytest.fixture(scope="session")  # Expensive, reusable
def docker_container():
    ...

@pytest.fixture(scope="function")  # Needs fresh state
def db_transaction():
    ...
\`\`\`

❌ **Bad:**
\`\`\`python
@pytest.fixture(scope="session")  # State persists!
def mutable_state():
    return {"count": 0}  # Tests will interfere with each other
\`\`\`

### Fixture Dependencies

✅ **Good:**
\`\`\`python
@pytest.fixture
def database():
    return Database()

@pytest.fixture
def user_repository(database):  # Clear dependency
    return UserRepository(database)
\`\`\`

❌ **Bad:**
\`\`\`python
@pytest.fixture
def user_repository():
    database = Database()  # Hidden dependency
    return UserRepository(database)
\`\`\`

### Fixture Cleanup

✅ **Good:**
\`\`\`python
@pytest.fixture
async def resource():
    res = await create_resource()
    yield res
    await res.cleanup()  # Guaranteed cleanup
\`\`\`

❌ **Bad:**
\`\`\`python
@pytest.fixture
async def resource():
    res = await create_resource()
    return res  # No cleanup, leaks resources
\`\`\`

## Common Fixture Patterns

### Database Transaction Fixture

\`\`\`python
@pytest.fixture
async def db_transaction(db_session):
    """Wrap test in transaction that rolls back."""
    async with db_session.begin():
        yield db_session
        await db_session.rollback()
\`\`\`

### Mocked Time Fixture

\`\`\`python
@pytest.fixture
def frozen_time():
    """Freeze time for consistent testing."""
    from unittest.mock import patch
    import datetime

    frozen = datetime.datetime(2025, 1, 15, 12, 0, 0)

    with patch("datetime.datetime") as mock_datetime:
        mock_datetime.now.return_value = frozen
        mock_datetime.utcnow.return_value = frozen
        yield frozen
\`\`\`

### Captured Logs Fixture

\`\`\`python
@pytest.fixture
def captured_logs(caplog):
    """Capture logs for assertion."""
    import logging

    caplog.set_level(logging.INFO)
    yield caplog
\`\`\`

## Related Templates

- [Unit Test Template](./unit-test-template.md)
- [Integration Test Template](./integration-test-template.md)
- [Python Project Template](./python-project-template.md)

## Related Documents

- [Testing Patterns](../core-rules/python-standards/TESTING_PATTERNS.md)
- [Mocking Strategies](../core-rules/testing/README.md#mocking)
- [Testing Policy](../core-rules/testing/TESTING_POLICY.md)

## References

This template synthesizes patterns from:
- Testing Worker: Fixture patterns, test organization
- Foundation Worker: Python testing patterns, async fixtures
- Patterns Worker: Factory patterns
