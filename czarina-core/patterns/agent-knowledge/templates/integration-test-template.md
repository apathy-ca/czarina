# Integration Test Template

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This template provides comprehensive structure for writing integration tests that verify component interactions, database operations, API endpoints, and multi-service workflows.

## When to Use This Template

Use this template for:
- Testing interactions between multiple components
- Testing database operations with real database instances
- Testing API endpoints with real HTTP calls
- Testing external service integrations
- Testing complete user workflows

## Quick Start

Integration tests typically require:
1. Docker-compose for test infrastructure (databases, services)
2. Test data fixtures for realistic scenarios
3. Cleanup between tests to ensure isolation
4. Longer timeout allowances (< 10s per test)

---

## Python Integration Test Template (pytest + Docker)

### Docker Compose Setup

\`\`\`yaml
# docker-compose.test.yml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: test_user
      POSTGRES_PASSWORD: test_password
      POSTGRES_DB: test_db
    ports:
      - "5433:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U test_user"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7
    ports:
      - "6380:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  test_app:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      DATABASE_URL: postgresql+asyncpg://test_user:test_password@postgres:5432/test_db
      REDIS_URL: redis://redis:6379/0
      ENV: test
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: ["pytest", "tests/integration", "-v"]
\`\`\`

### conftest.py for Integration Tests

\`\`\`python
"""Integration test configuration and fixtures."""

import pytest
import asyncio
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from redis.asyncio import Redis

from src.[package_name].database import Base
from src.[package_name].config import settings


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
async def db_engine():
    """Create test database engine."""
    engine = create_async_engine(
        settings.database_url,
        echo=False,  # Set to True for SQL debugging
        pool_pre_ping=True,
    )

    # Create all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    yield engine

    # Drop all tables after tests
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()


@pytest.fixture
async def db_session(db_engine) -> AsyncGenerator[AsyncSession, None]:
    """Provide database session for tests with automatic rollback."""
    async_session = async_sessionmaker(
        db_engine, class_=AsyncSession, expire_on_commit=False
    )

    async with async_session() as session:
        async with session.begin():
            yield session
            # Rollback after test
            await session.rollback()


@pytest.fixture
async def redis_client() -> AsyncGenerator[Redis, None]:
    """Provide Redis client for tests."""
    client = Redis.from_url(settings.redis_url, decode_responses=True)
    yield client

    # Cleanup Redis data
    await client.flushdb()
    await client.close()


@pytest.fixture
async def test_data(db_session: AsyncSession):
    """Provide common test data."""
    # Create test records
    from src.[package_name].models import User, Resource

    user = User(email="test@example.com", name="Test User")
    db_session.add(user)
    await db_session.flush()

    resource = Resource(user_id=user.id, name="Test Resource", data={"key": "value"})
    db_session.add(resource)
    await db_session.flush()

    return {"user": user, "resource": resource}
\`\`\`

### Database Integration Test

\`\`\`python
"""Integration tests for database operations."""

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.[package_name].models import User, Resource
from src.[package_name].repositories import UserRepository


class TestUserRepository:
    """Integration tests for UserRepository."""

    @pytest.fixture
    def repository(self, db_session: AsyncSession) -> UserRepository:
        """Provide UserRepository instance."""
        return UserRepository(db_session)

    async def test_create_user_persists_to_database(
        self, repository: UserRepository, db_session: AsyncSession
    ) -> None:
        """Test that creating a user persists to database."""
        # Arrange
        user_data = {"email": "new@example.com", "name": "New User"}

        # Act
        user = await repository.create(user_data)
        await db_session.commit()

        # Assert
        stmt = select(User).where(User.id == user.id)
        result = await db_session.execute(stmt)
        db_user = result.scalar_one()

        assert db_user.email == "new@example.com"
        assert db_user.name == "New User"
        assert db_user.created_at is not None

    async def test_get_user_with_resources(
        self, repository: UserRepository, test_data: dict
    ) -> None:
        """Test retrieving user with related resources."""
        # Arrange
        user_id = test_data["user"].id

        # Act
        user = await repository.get_with_resources(user_id)

        # Assert
        assert user is not None
        assert user.email == "test@example.com"
        assert len(user.resources) == 1
        assert user.resources[0].name == "Test Resource"

    async def test_update_user_updates_database(
        self, repository: UserRepository, test_data: dict, db_session: AsyncSession
    ) -> None:
        """Test that updating user modifies database record."""
        # Arrange
        user_id = test_data["user"].id
        update_data = {"name": "Updated Name"}

        # Act
        updated_user = await repository.update(user_id, update_data)
        await db_session.commit()

        # Assert
        stmt = select(User).where(User.id == user_id)
        result = await db_session.execute(stmt)
        db_user = result.scalar_one()

        assert db_user.name == "Updated Name"
        assert updated_user.updated_at > updated_user.created_at

    async def test_delete_user_removes_from_database(
        self, repository: UserRepository, test_data: dict, db_session: AsyncSession
    ) -> None:
        """Test that deleting user removes from database."""
        # Arrange
        user_id = test_data["user"].id

        # Act
        await repository.delete(user_id)
        await db_session.commit()

        # Assert
        stmt = select(User).where(User.id == user_id)
        result = await db_session.execute(stmt)
        db_user = result.scalar_one_or_none()

        assert db_user is None

    async def test_transaction_rollback_on_error(
        self, repository: UserRepository, db_session: AsyncSession
    ) -> None:
        """Test that database transaction rolls back on error."""
        # Arrange
        initial_count_stmt = select(func.count()).select_from(User)
        result = await db_session.execute(initial_count_stmt)
        initial_count = result.scalar()

        # Act
        try:
            async with db_session.begin():
                user = User(email="test@example.com", name="Test")
                db_session.add(user)
                await db_session.flush()

                # Simulate error
                raise ValueError("Simulated error")
        except ValueError:
            pass

        # Assert
        result = await db_session.execute(initial_count_stmt)
        final_count = result.scalar()
        assert final_count == initial_count  # No new record
\`\`\`

### API Integration Test

\`\`\`python
"""Integration tests for API endpoints."""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from src.[package_name].main import app
from src.[package_name].models import User


class TestUserAPI:
    """Integration tests for User API endpoints."""

    @pytest.fixture
    async def client(self) -> AsyncClient:
        """Provide HTTP client for API testing."""
        async with AsyncClient(app=app, base_url="http://test") as client:
            yield client

    @pytest.fixture
    async def auth_token(self, db_session: AsyncSession) -> str:
        """Provide authentication token for protected endpoints."""
        # Create test user and generate token
        user = User(email="auth@example.com", name="Auth User")
        db_session.add(user)
        await db_session.commit()

        # Generate JWT token (implementation specific)
        from src.[package_name].auth import create_access_token

        token = create_access_token(user.id)
        return token

    async def test_create_user_returns_201(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        """Test creating user via API returns 201."""
        # Arrange
        user_data = {"email": "api@example.com", "name": "API User"}

        # Act
        response = await client.post("/api/v1/users", json=user_data)

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "api@example.com"
        assert data["name"] == "API User"
        assert "id" in data
        assert "created_at" in data

        # Verify database
        from sqlalchemy import select

        stmt = select(User).where(User.email == "api@example.com")
        result = await db_session.execute(stmt)
        db_user = result.scalar_one()
        assert db_user.name == "API User"

    async def test_get_user_returns_user_data(
        self, client: AsyncClient, test_data: dict, auth_token: str
    ) -> None:
        """Test retrieving user via API."""
        # Arrange
        user_id = test_data["user"].id
        headers = {"Authorization": f"Bearer {auth_token}"}

        # Act
        response = await client.get(f"/api/v1/users/{user_id}", headers=headers)

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(user_id)
        assert data["email"] == "test@example.com"

    async def test_update_user_modifies_record(
        self, client: AsyncClient, test_data: dict, auth_token: str, db_session: AsyncSession
    ) -> None:
        """Test updating user via API."""
        # Arrange
        user_id = test_data["user"].id
        update_data = {"name": "Updated via API"}
        headers = {"Authorization": f"Bearer {auth_token}"}

        # Act
        response = await client.patch(
            f"/api/v1/users/{user_id}", json=update_data, headers=headers
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated via API"

        # Verify database
        from sqlalchemy import select

        stmt = select(User).where(User.id == user_id)
        result = await db_session.execute(stmt)
        db_user = result.scalar_one()
        assert db_user.name == "Updated via API"

    async def test_unauthorized_access_returns_401(self, client: AsyncClient) -> None:
        """Test that accessing protected endpoint without auth returns 401."""
        # Act
        response = await client.get("/api/v1/users/123")

        # Assert
        assert response.status_code == 401

    async def test_validation_error_returns_422(self, client: AsyncClient) -> None:
        """Test that invalid data returns 422."""
        # Arrange
        invalid_data = {"email": "not-an-email", "name": ""}

        # Act
        response = await client.post("/api/v1/users", json=invalid_data)

        # Assert
        assert response.status_code == 422
        data = response.json()
        assert "detail" in data
        assert len(data["detail"]) > 0
\`\`\`

### Service Integration Test

\`\`\`python
"""Integration tests for service layer with multiple components."""

import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from redis.asyncio import Redis

from src.[package_name].services import UserService
from src.[package_name].models import User


class TestUserService:
    """Integration tests for UserService."""

    @pytest.fixture
    def service(self, db_session: AsyncSession, redis_client: Redis) -> UserService:
        """Provide UserService instance."""
        return UserService(db_session, redis_client)

    async def test_get_user_caches_result(
        self, service: UserService, test_data: dict, redis_client: Redis
    ) -> None:
        """Test that getting user caches result in Redis."""
        # Arrange
        user_id = test_data["user"].id
        cache_key = f"user:{user_id}"

        # Verify cache is empty
        cached = await redis_client.get(cache_key)
        assert cached is None

        # Act
        user = await service.get_user(user_id)

        # Assert
        assert user.id == user_id

        # Verify cache is populated
        cached = await redis_client.get(cache_key)
        assert cached is not None
        import json

        cached_data = json.loads(cached)
        assert cached_data["id"] == str(user_id)

    async def test_update_user_invalidates_cache(
        self, service: UserService, test_data: dict, redis_client: Redis
    ) -> None:
        """Test that updating user invalidates cache."""
        # Arrange
        user_id = test_data["user"].id
        cache_key = f"user:{user_id}"

        # Populate cache
        await service.get_user(user_id)
        assert await redis_client.get(cache_key) is not None

        # Act
        await service.update_user(user_id, {"name": "Updated"})

        # Assert
        cached = await redis_client.get(cache_key)
        assert cached is None  # Cache invalidated

    async def test_create_user_publishes_event(
        self, service: UserService, redis_client: Redis
    ) -> None:
        """Test that creating user publishes event."""
        # Arrange
        user_data = {"email": "event@example.com", "name": "Event User"}

        # Subscribe to events channel
        pubsub = redis_client.pubsub()
        await pubsub.subscribe("user:events")

        # Act
        user = await service.create_user(user_data)

        # Assert
        message = await pubsub.get_message(timeout=1.0)
        if message and message["type"] == "message":
            import json

            event_data = json.loads(message["data"])
            assert event_data["event"] == "user.created"
            assert event_data["user_id"] == str(user.id)

        await pubsub.unsubscribe("user:events")
\`\`\`

### External Service Integration Test

\`\`\`python
"""Integration tests for external service integration."""

import pytest
import httpx
from unittest.mock import patch

from src.[package_name].services import ExternalAPIService


class TestExternalAPIService:
    """Integration tests for external API service."""

    @pytest.fixture
    def service(self) -> ExternalAPIService:
        """Provide ExternalAPIService instance."""
        return ExternalAPIService(api_key="test_key", base_url="https://api.example.com")

    @pytest.mark.integration
    @pytest.mark.external
    async def test_fetch_data_from_real_api(self, service: ExternalAPIService) -> None:
        """Test fetching data from real external API.

        Note: Use sparingly, prefer mocked tests for CI/CD.
        Mark with @pytest.mark.external to skip in fast test runs.
        """
        # Act
        result = await service.fetch_data("test_id")

        # Assert
        assert result is not None
        assert "id" in result
        assert "data" in result

    async def test_retry_logic_on_transient_failures(
        self, service: ExternalAPIService
    ) -> None:
        """Test that service retries on transient failures."""
        # Arrange
        call_count = 0

        async def mock_request(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise httpx.RequestError("Transient error")
            return httpx.Response(200, json={"id": "123", "data": "success"})

        with patch.object(service.client, "get", side_effect=mock_request):
            # Act
            result = await service.fetch_data("test_id")

            # Assert
            assert result["data"] == "success"
            assert call_count == 3  # Retried 2 times before success
\`\`\`

## TypeScript/JavaScript Integration Test Template (Jest + Supertest)

### API Integration Test

\`\`\`typescript
/**
 * Integration tests for User API
 */

import request from 'supertest';
import { app } from '../src/app';
import { setupTestDatabase, cleanupTestDatabase } from './helpers/database';
import { createTestUser } from './helpers/factories';

describe('User API Integration', () => {
  beforeAll(async () => {
    await setupTestDatabase();
  });

  afterAll(async () => {
    await cleanupTestDatabase();
  });

  afterEach(async () => {
    // Clean data between tests
    await cleanupTestData();
  });

  describe('POST /api/v1/users', () => {
    it('should create user and return 201', async () => {
      // Arrange
      const userData = {
        email: 'test@example.com',
        name: 'Test User',
      };

      // Act
      const response = await request(app)
        .post('/api/v1/users')
        .send(userData)
        .expect(201);

      // Assert
      expect(response.body).toMatchObject({
        email: 'test@example.com',
        name: 'Test User',
      });
      expect(response.body.id).toBeDefined();
      expect(response.body.createdAt).toBeDefined();
    });

    it('should return 422 for invalid email', async () => {
      // Arrange
      const invalidData = {
        email: 'not-an-email',
        name: 'Test',
      };

      // Act
      const response = await request(app)
        .post('/api/v1/users')
        .send(invalidData)
        .expect(422);

      // Assert
      expect(response.body.errors).toBeDefined();
    });
  });

  describe('GET /api/v1/users/:id', () => {
    it('should return user data', async () => {
      // Arrange
      const user = await createTestUser();

      // Act
      const response = await request(app)
        .get(`/api/v1/users/${user.id}`)
        .expect(200);

      // Assert
      expect(response.body.id).toBe(user.id);
      expect(response.body.email).toBe(user.email);
    });

    it('should return 404 for non-existent user', async () => {
      // Act & Assert
      await request(app).get('/api/v1/users/999').expect(404);
    });
  });
});
\`\`\`

## Best Practices

### Test Isolation

✅ **Good:**
\`\`\`python
@pytest.fixture
async def db_session(db_engine):
    async with async_sessionmaker(db_engine)() as session:
        async with session.begin():
            yield session
            await session.rollback()  # Rollback after each test
\`\`\`

❌ **Bad:**
\`\`\`python
# Sharing state between tests
@pytest.fixture(scope="module")
def db_session():
    session = create_session()
    yield session  # No cleanup, state persists
\`\`\`

### Docker Cleanup

✅ **Good:**
\`\`\`bash
# Makefile
test-integration:
\tdocker-compose -f docker-compose.test.yml up -d
\tpytest tests/integration
\tdocker-compose -f docker-compose.test.yml down -v
\`\`\`

### Test Data Factories

✅ **Good:**
\`\`\`python
# tests/factories.py
class UserFactory:
    @staticmethod
    async def create(db_session, **kwargs):
        defaults = {
            "email": f"user{random.randint(1000, 9999)}@example.com",
            "name": "Test User",
        }
        defaults.update(kwargs)
        user = User(**defaults)
        db_session.add(user)
        await db_session.flush()
        return user
\`\`\`

## Related Templates

- [Unit Test Template](./unit-test-template.md)
- [Test Fixture Template](./test-fixture-template.md)
- [Python Project Template](./python-project-template.md)

## Related Documents

- [Integration Testing Standards](../core-rules/testing/INTEGRATION_TESTING.md)
- [Testing Policy](../core-rules/testing/TESTING_POLICY.md)
- [Docker Best Practices](../patterns/)

## References

This template synthesizes patterns from:
- Testing Worker: Integration testing patterns, Docker setup
- Foundation Worker: Database patterns, async testing
- Patterns Worker: Caching patterns, retry logic
- Security Worker: Authentication testing
