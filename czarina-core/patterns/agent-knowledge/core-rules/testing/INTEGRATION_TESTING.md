# Integration Testing Standards

Comprehensive integration testing patterns and best practices for agent development, extracted from SARK, thesymposium, and czarina test suites.

## Overview

Integration tests verify that multiple components work together correctly with real dependencies. They test complete workflows, data flow between components, and interactions with external services like databases, caches, and APIs.

## Integration Test Characteristics

### Essential Properties

1. **Real Dependencies**: Use actual databases, caches, message queues
2. **Complete Workflows**: Test end-to-end user scenarios
3. **Moderate Speed**: < 10 seconds per test
4. **Component Interaction**: Verify data flows correctly between services
5. **Environment Isolation**: Tests don't affect production or each other

### What to Integration Test

**Always Integration Test**:
- API endpoint request/response cycles
- Database operations with real schema
- Authentication and authorization flows
- Message passing between services
- Multi-component workflows
- External service integrations
- Cache invalidation strategies
- Transaction rollback behavior

**Usually Don't Integration Test**:
- Individual function logic (use unit tests)
- Edge case input validation (use unit tests)
- Error message formatting (use unit tests)

## Integration Test Organization

### Directory Structure

```
project/
├── src/
└── tests/
    ├── unit/                    # Unit tests
    └── integration/             # Integration tests
        ├── __init__.py
        ├── conftest.py          # Integration test fixtures
        ├── auth/
        │   ├── __init__.py
        │   ├── test_ldap_integration.py
        │   ├── test_oidc_integration.py
        │   └── test_saml_integration.py
        ├── gateway/
        │   ├── __init__.py
        │   ├── test_gateway_e2e.py
        │   ├── test_policy_integration.py
        │   └── test_audit_integration.py
        ├── v2/                  # Next-gen features
        │   ├── __init__.py
        │   └── test_federation_flow.py
        └── fixtures/
            ├── __init__.py
            ├── integration_docker.py
            └── docker-compose.integration.yml
```

**Key Principles**:
- Separate from unit tests
- Group by feature or service
- Use Docker for real services
- Shared fixtures in `conftest.py`

### Test Class Organization

```python
"""
Example integration tests demonstrating Docker infrastructure usage.

Run with:
    pytest tests/integration/test_docker_infrastructure_example.py -v
"""

from uuid import uuid4
import pytest

# Import Docker fixtures - this enables all Docker services
pytest_plugins = ["tests.fixtures.integration_docker"]


@pytest.mark.integration
class TestPostgreSQLIntegration:
    """Test PostgreSQL database operations with real Docker container."""

    @pytest.mark.asyncio
    async def test_postgres_connection(self, postgres_connection):
        """Test that we can connect to PostgreSQL."""
        async with postgres_connection.acquire() as conn:
            result = await conn.fetchval("SELECT 1")
            assert result == 1

    @pytest.mark.asyncio
    async def test_create_table(self, postgres_connection):
        """Test table creation and basic operations."""
        async with postgres_connection.acquire() as conn:
            # Create table
            await conn.execute(
                """
                CREATE TEMPORARY TABLE test_servers (
                    id UUID PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    endpoint VARCHAR(500)
                )
            """
            )

            # Insert data
            test_id = uuid4()
            await conn.execute(
                """
                INSERT INTO test_servers (id, name, endpoint)
                VALUES ($1, $2, $3)
            """,
                test_id,
                "test-server",
                "http://example.com",
            )

            # Query data
            result = await conn.fetchrow(
                "SELECT * FROM test_servers WHERE id = $1", test_id
            )

            assert result["name"] == "test-server"
            assert result["endpoint"] == "http://example.com"
```

## Docker-Based Testing Infrastructure

### Docker Compose Setup

Create `docker-compose.integration.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: sark_test
      POSTGRES_USER: sark_test
      POSTGRES_PASSWORD: sark_test
    ports:
      - "5433:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U sark_test"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6380:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  timescaledb:
    image: timescale/timescaledb:latest-pg15
    environment:
      POSTGRES_DB: sark_audit_test
      POSTGRES_USER: sark_test
      POSTGRES_PASSWORD: sark_test
    ports:
      - "5434:5432"

  opa:
    image: openpolicyagent/opa:latest
    ports:
      - "8181:8181"
    command:
      - "run"
      - "--server"
      - "--log-level=debug"
```

### Docker Fixtures

Create `tests/fixtures/integration_docker.py`:

```python
"""Docker-based fixtures for integration testing infrastructure."""

from collections.abc import Generator
import httpx
import psycopg2
import pytest
import valkey

try:
    from pytest_docker.plugin import Services
except ImportError:
    pytest.skip("pytest-docker not installed", allow_module_level=True)


@pytest.fixture(scope="session")
def docker_compose_file(pytestconfig):
    """Path to docker-compose.yml file for integration tests."""
    return str(
        pytestconfig.rootdir / "tests" / "fixtures" / "docker-compose.integration.yml"
    )


@pytest.fixture(scope="session")
def postgres_service(docker_services: Services) -> Generator[dict, None, None]:
    """
    Start PostgreSQL Docker container and wait for it to be ready.

    Yields:
        Dictionary with PostgreSQL connection details
    """
    # Wait for PostgreSQL to be ready
    docker_services.wait_until_responsive(
        timeout=60.0,
        pause=0.5,
        check=lambda: is_postgres_responsive(
            docker_services.docker_ip, docker_services.port_for("postgres", 5432)
        ),
    )

    host = docker_services.docker_ip
    port = docker_services.port_for("postgres", 5432)

    postgres_config = {
        "host": host,
        "port": port,
        "database": "sark_test",
        "user": "sark_test",
        "password": "sark_test",
        "connection_string": f"postgresql://sark_test:sark_test@{host}:{port}/sark_test",
    }

    yield postgres_config


def is_postgres_responsive(host: str, port: int) -> bool:
    """Check if PostgreSQL is responsive."""
    try:
        conn = psycopg2.connect(
            host=host,
            port=port,
            user="sark_test",
            password="sark_test",
            database="sark_test",
            connect_timeout=2,
        )
        conn.close()
        return True
    except Exception:
        return False


@pytest.fixture
async def postgres_connection(postgres_service):
    """
    Provide async PostgreSQL connection for tests.

    Returns:
        Async connection pool
    """
    import asyncpg

    pool = await asyncpg.create_pool(
        host=postgres_service["host"],
        port=postgres_service["port"],
        user=postgres_service["user"],
        password=postgres_service["password"],
        database=postgres_service["database"],
        min_size=1,
        max_size=5,
    )

    yield pool

    await pool.close()
```

### Using Docker Fixtures

Enable Docker fixtures in test files:

```python
# At the top of your integration test file
pytest_plugins = ["tests.fixtures.integration_docker"]

@pytest.mark.integration
class TestMyFeature:
    """Integration tests for MyFeature."""

    @pytest.mark.asyncio
    async def test_with_real_database(self, postgres_connection):
        """Test using real PostgreSQL database."""
        async with postgres_connection.acquire() as conn:
            # Use real database connection
            result = await conn.fetchval("SELECT 1")
            assert result == 1
```

## Integration Test Fixtures

### Database Fixtures

From SARK `integration/conftest.py`:

```python
@pytest.fixture
async def test_db():
    """
    Provide test database session with automatic cleanup.

    In a real implementation, this would:
    1. Create test database connection
    2. Run migrations
    3. Provide session
    4. Cleanup after test
    """
    session = MagicMock()
    session.add = MagicMock()
    session.commit = AsyncMock()
    session.flush = AsyncMock()
    session.execute = AsyncMock()
    session.close = AsyncMock()

    yield session

    # Cleanup
    await session.close()


@pytest.fixture
async def initialized_db(postgres_connection):
    """
    Provide database with schema initialized.

    Creates all tables and returns connection pool.
    """
    async with postgres_connection.acquire() as conn:
        # Run migrations or create schema
        await run_migrations(conn)

    yield postgres_connection

    # Cleanup is handled by postgres_connection fixture
```

### Authentication Fixtures

```python
@pytest.fixture
def jwt_handler():
    """JWT handler for creating auth tokens."""
    return JWTHandler(
        secret_key="test-secret-key-for-integration-tests",
        algorithm="HS256",
        access_token_expire_minutes=30,
        refresh_token_expire_days=7,
    )


@pytest.fixture
def test_user():
    """Regular test user."""
    return User(
        id=uuid4(),
        email="test@example.com",
        full_name="Test User",
        hashed_password="hashed_password_here",
        role="developer",
        is_active=True,
        is_admin=False,
        extra_metadata={},
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@pytest.fixture
def admin_user():
    """Admin test user."""
    return User(
        id=uuid4(),
        email="admin@example.com",
        full_name="Admin User",
        hashed_password="hashed_password_here",
        role="admin",
        is_active=True,
        is_admin=True,
        extra_metadata={},
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@pytest.fixture
def test_user_token(jwt_handler, test_user):
    """Generate JWT for test user."""
    return jwt_handler.create_access_token(
        user_id=test_user.id,
        email=test_user.email,
        role=test_user.role,
    )


@pytest.fixture
def auth_headers(test_user_token):
    """Bearer token headers for authenticated requests."""
    return {"Authorization": f"Bearer {test_user_token}"}
```

### Service Fixtures

```python
@pytest.fixture
def test_server():
    """MCPServer instance for testing."""
    return MCPServer(
        id=uuid4(),
        name="test-server",
        description="Test MCP server",
        transport=TransportType.HTTP,
        endpoint="http://example.com/mcp",
        sensitivity_level=SensitivityLevel.MEDIUM,
        is_active=True,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@pytest.fixture
def sample_server_data():
    """Sample server registration payload."""
    return {
        "name": "test-server",
        "description": "Test MCP server",
        "transport": "http",
        "endpoint": "http://example.com/mcp",
        "sensitivity_level": "medium",
        "tools": [],
        "prompts": [],
        "resources": [],
    }
```

## Testing Complete Workflows

### API Endpoint Integration Tests

```python
@pytest.mark.integration
class TestServerRegistrationAPI:
    """Test server registration API endpoint."""

    @pytest.mark.asyncio
    async def test_register_server_success(
        self, client, auth_headers, sample_server_data
    ):
        """Test successful server registration."""
        # Arrange
        payload = sample_server_data

        # Act
        response = await client.post(
            "/api/v1/servers",
            json=payload,
            headers=auth_headers,
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "test-server"
        assert data["transport"] == "http"
        assert "id" in data

    @pytest.mark.asyncio
    async def test_register_server_unauthorized(self, client, sample_server_data):
        """Test server registration without authentication."""
        # Arrange
        payload = sample_server_data

        # Act
        response = await client.post("/api/v1/servers", json=payload)

        # Assert
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_register_server_invalid_data(self, client, auth_headers):
        """Test server registration with invalid data."""
        # Arrange
        invalid_payload = {"name": ""}  # Missing required fields

        # Act
        response = await client.post(
            "/api/v1/servers",
            json=invalid_payload,
            headers=auth_headers,
        )

        # Assert
        assert response.status_code == 422
```

### Database Integration Tests

```python
@pytest.mark.integration
class TestDatabaseOperations:
    """Test database operations with real database."""

    @pytest.mark.asyncio
    async def test_transaction_commit(self, postgres_connection):
        """Test transaction commit behavior."""
        async with postgres_connection.acquire() as conn:
            # Create temp table
            await conn.execute(
                """
                CREATE TEMPORARY TABLE test_commit (
                    id SERIAL PRIMARY KEY,
                    value TEXT
                )
            """
            )

            # Insert with transaction
            async with conn.transaction():
                await conn.execute(
                    "INSERT INTO test_commit (value) VALUES ($1)", "test_value"
                )

            # Verify data was committed
            result = await conn.fetchval("SELECT value FROM test_commit WHERE id = 1")
            assert result == "test_value"

    @pytest.mark.asyncio
    async def test_transaction_rollback(self, postgres_connection):
        """Test transaction rollback behavior."""
        async with postgres_connection.acquire() as conn:
            await conn.execute(
                """
                CREATE TEMPORARY TABLE test_rollback (
                    id SERIAL PRIMARY KEY,
                    value TEXT
                )
            """
            )

            # Test rollback on exception
            try:
                async with conn.transaction():
                    await conn.execute(
                        "INSERT INTO test_rollback (value) VALUES ($1)",
                        "should_rollback",
                    )
                    raise Exception("Test rollback")
            except Exception:
                pass

            # Verify no data was committed
            count = await conn.fetchval("SELECT COUNT(*) FROM test_rollback")
            assert count == 0
```

### Cache Integration Tests

```python
@pytest.mark.integration
class TestRedisIntegration:
    """Test Redis cache operations."""

    @pytest.mark.asyncio
    async def test_redis_set_get(self, clean_redis):
        """Test basic Redis set/get operations."""
        # Arrange
        key = "test_key"
        value = "test_value"

        # Act
        await clean_redis.set(key, value)
        result = await clean_redis.get(key)

        # Assert
        assert result == value

    @pytest.mark.asyncio
    async def test_redis_expiration(self, clean_redis):
        """Test Redis key expiration."""
        # Arrange
        key = "expiring_key"
        value = "value"
        expiration_seconds = 1

        # Act
        await clean_redis.set(key, value, ex=expiration_seconds)

        # Assert - key exists immediately
        exists = await clean_redis.exists(key)
        assert exists == 1

        # Assert - TTL is set
        ttl = await clean_redis.ttl(key)
        assert ttl > 0 and ttl <= expiration_seconds

    @pytest.mark.asyncio
    async def test_cache_and_database(self, postgres_connection, clean_redis):
        """Test caching layer with database operations."""
        # Create table and insert data
        async with postgres_connection.acquire() as conn:
            await conn.execute(
                """
                CREATE TEMPORARY TABLE test_cache_db (
                    id UUID PRIMARY KEY,
                    value TEXT
                )
            """
            )

            test_id = uuid4()
            await conn.execute(
                "INSERT INTO test_cache_db (id, value) VALUES ($1, $2)",
                test_id,
                "test-value",
            )

            # Query from database
            result = await conn.fetchrow(
                "SELECT * FROM test_cache_db WHERE id = $1", test_id
            )
            db_value = result["value"]

            # Cache the result
            cache_key = f"cache:item:{test_id}"
            await clean_redis.set(cache_key, db_value)

            # Retrieve from cache
            cached_value = await clean_redis.get(cache_key)

            assert cached_value == db_value
```

### Multi-Service Integration Tests

```python
@pytest.mark.integration
class TestAuthorizationFlow:
    """Test complete authorization flow with multiple services."""

    @pytest.mark.asyncio
    async def test_user_authentication_and_authorization(
        self,
        postgres_connection,
        clean_redis,
        opa_client,
        jwt_handler,
    ):
        """Test complete auth flow: login -> cache session -> authorize request."""
        # Step 1: Create user in database
        async with postgres_connection.acquire() as conn:
            user_id = uuid4()
            await conn.execute(
                """
                INSERT INTO users (id, email, role, is_active)
                VALUES ($1, $2, $3, $4)
            """,
                user_id,
                "test@example.com",
                "developer",
                True,
            )

        # Step 2: Generate JWT token
        token = jwt_handler.create_access_token(
            user_id=user_id,
            email="test@example.com",
            role="developer",
        )

        # Step 3: Cache session in Redis
        session_key = f"session:{user_id}"
        await clean_redis.set(session_key, token, ex=3600)

        # Step 4: Verify session exists
        cached_token = await clean_redis.get(session_key)
        assert cached_token == token

        # Step 5: Authorize request with OPA
        authz_result = await opa_client.evaluate_policy(
            policy="authz/allow",
            input_data={"user_id": str(user_id), "role": "developer", "action": "read"},
        )

        assert authz_result["result"] is True
```

## Test Environment Setup and Teardown

### Setup Patterns

```python
@pytest.fixture
async def initialized_db(postgres_connection):
    """Setup: Initialize database schema."""
    async with postgres_connection.acquire() as conn:
        # Run migrations
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id UUID PRIMARY KEY,
                email VARCHAR(255) UNIQUE NOT NULL,
                role VARCHAR(50) NOT NULL,
                is_active BOOLEAN DEFAULT true
            )
        """)

    yield postgres_connection

    # Teardown happens automatically when connection closes


@pytest.fixture
async def clean_redis(redis_connection):
    """Setup: Clean Redis before and after test."""
    # Pre-test cleanup
    await redis_connection.flushdb()

    yield redis_connection

    # Post-test cleanup
    await redis_connection.flushdb()
```

### Cleanup Patterns

```python
@pytest.fixture
async def test_data_cleanup(postgres_connection):
    """Ensure test data is cleaned up after test."""
    created_ids = []

    def track_id(id):
        created_ids.append(id)
        return id

    yield track_id

    # Cleanup all created records
    async with postgres_connection.acquire() as conn:
        for id in created_ids:
            await conn.execute("DELETE FROM test_table WHERE id = $1", id)
```

## Integration Test Data Management

### Test Data Fixtures

```python
@pytest.fixture
def test_dataset():
    """Provide consistent test dataset."""
    return {
        "users": [
            {"email": "user1@example.com", "role": "developer"},
            {"email": "user2@example.com", "role": "admin"},
            {"email": "user3@example.com", "role": "viewer"},
        ],
        "servers": [
            {"name": "server-1", "endpoint": "http://s1.example.com"},
            {"name": "server-2", "endpoint": "http://s2.example.com"},
        ],
    }


@pytest.mark.asyncio
async def test_with_dataset(postgres_connection, test_dataset):
    """Test using predefined dataset."""
    async with postgres_connection.acquire() as conn:
        # Insert test dataset
        for user in test_dataset["users"]:
            await conn.execute(
                "INSERT INTO users (id, email, role) VALUES ($1, $2, $3)",
                uuid4(),
                user["email"],
                user["role"],
            )

        # Run test
        count = await conn.fetchval("SELECT COUNT(*) FROM users")
        assert count == len(test_dataset["users"])
```

### Factory Patterns

```python
from faker import Faker

fake = Faker()


async def create_test_user(conn, **overrides):
    """Factory for creating test users."""
    user_data = {
        "id": uuid4(),
        "email": fake.email(),
        "full_name": fake.name(),
        "role": "developer",
        "is_active": True,
        **overrides,
    }

    await conn.execute(
        """
        INSERT INTO users (id, email, full_name, role, is_active)
        VALUES ($1, $2, $3, $4, $5)
    """,
        user_data["id"],
        user_data["email"],
        user_data["full_name"],
        user_data["role"],
        user_data["is_active"],
    )

    return user_data


@pytest.mark.asyncio
async def test_with_factory(postgres_connection):
    """Test using factory pattern."""
    async with postgres_connection.acquire() as conn:
        # Create test users
        user1 = await create_test_user(conn, role="admin")
        user2 = await create_test_user(conn, role="developer")

        # Run test
        admins = await conn.fetch("SELECT * FROM users WHERE role = 'admin'")
        assert len(admins) == 1
        assert admins[0]["email"] == user1["email"]
```

## Performance and Load Testing

### Performance Benchmarks

```python
@pytest.mark.integration
@pytest.mark.slow
class TestPerformance:
    """Performance tests using Docker services."""

    @pytest.mark.asyncio
    async def test_bulk_insert_performance(self, postgres_connection):
        """Test bulk insert performance."""
        import time

        async with postgres_connection.acquire() as conn:
            await conn.execute(
                """
                CREATE TEMPORARY TABLE test_bulk (
                    id SERIAL PRIMARY KEY,
                    value TEXT
                )
            """
            )

            # Bulk insert
            start = time.time()
            values = [(f"value_{i}",) for i in range(1000)]
            await conn.executemany(
                "INSERT INTO test_bulk (value) VALUES ($1)", values
            )
            duration = time.time() - start

            # Verify
            count = await conn.fetchval("SELECT COUNT(*) FROM test_bulk")
            assert count == 1000

            # Performance assertion
            assert duration < 1.0, f"Bulk insert took {duration}s, expected < 1.0s"

    @pytest.mark.asyncio
    async def test_redis_throughput(self, clean_redis):
        """Test Redis operation throughput."""
        import time

        start = time.time()

        # Perform 1000 operations
        for i in range(1000):
            await clean_redis.set(f"key_{i}", f"value_{i}")

        duration = time.time() - start

        # Performance assertion
        assert duration < 1.0, f"1000 ops took {duration}s, expected < 1.0s"
```

## Running Integration Tests

```bash
# Run all integration tests
pytest tests/integration/ -m integration

# Run specific integration test file
pytest tests/integration/test_auth_integration.py

# Run with Docker services
pytest tests/integration/ --docker-compose-up

# Run excluding slow tests
pytest tests/integration/ -m "integration and not slow"

# Run with verbose output
pytest tests/integration/ -vv

# Run with coverage
pytest tests/integration/ --cov=src --cov-report=html

# Run specific test class
pytest tests/integration/test_gateway_e2e.py::TestGatewayEndToEnd

# Show print output
pytest tests/integration/ -s

# Run with parallel execution (requires pytest-xdist)
pytest tests/integration/ -n auto
```

## Best Practices

### DO

✅ Use real services (databases, caches) via Docker
✅ Test complete workflows end-to-end
✅ Clean up test data after each test
✅ Use meaningful test data
✅ Test transaction behavior (commit/rollback)
✅ Verify data flow between components
✅ Test authentication and authorization flows
✅ Use fixtures for common setup
✅ Mark tests with `@pytest.mark.integration`
✅ Keep tests under 10 seconds

### DON'T

❌ Test individual function logic (use unit tests)
❌ Use production databases or services
❌ Share state between tests
❌ Leave test data in database
❌ Skip cleanup in fixtures
❌ Mock all dependencies (defeats purpose)
❌ Write tests that depend on execution order
❌ Use hard-coded IDs (use UUID generation)
❌ Test framework internals
❌ Write flaky tests dependent on timing

## Common Patterns

### Waiting for Async Completion

```python
async def wait_for_condition(check_fn, timeout=60):
    """Wait for condition to be true."""
    import asyncio

    start_time = asyncio.get_event_loop().time()

    while True:
        if asyncio.get_event_loop().time() - start_time > timeout:
            pytest.fail(f"Condition not met within {timeout}s")

        if await check_fn():
            return

        await asyncio.sleep(0.5)


@pytest.mark.asyncio
async def test_async_workflow(saga_coordinator):
    """Test workflow that completes asynchronously."""
    saga_id = await saga_coordinator.create_saga()

    # Wait for completion
    await wait_for_condition(
        lambda: saga_coordinator.is_complete(saga_id),
        timeout=60,
    )

    saga = await saga_coordinator.get_saga(saga_id)
    assert saga.status == "completed"
```

### Testing Idempotency

```python
@pytest.mark.asyncio
async def test_idempotent_operation(postgres_connection):
    """Test operation can be safely repeated."""
    async with postgres_connection.acquire() as conn:
        # Run operation twice
        for _ in range(2):
            await conn.execute(
                """
                INSERT INTO users (id, email)
                VALUES ($1, $2)
                ON CONFLICT (id) DO NOTHING
            """,
                uuid4(),
                "test@example.com",
            )

        # Verify only one record
        count = await conn.fetchval(
            "SELECT COUNT(*) FROM users WHERE email = $1",
            "test@example.com",
        )
        assert count == 1
```

## References

- **TESTING_POLICY.md** - When integration tests are required
- **UNIT_TESTING.md** - Unit testing patterns
- **MOCKING_STRATEGIES.md** - When to mock vs use real services
- **COVERAGE_STANDARDS.md** - Coverage requirements

## Examples

See SARK repository for comprehensive examples:
- `/home/jhenry/Source/sark/tests/integration/test_docker_infrastructure_example.py` - Docker infrastructure examples
- `/home/jhenry/Source/sark/tests/integration/gateway/test_gateway_e2e.py` - End-to-end workflow tests
- `/home/jhenry/Source/sark/tests/fixtures/integration_docker.py` - Docker fixture setup

---

**Last Updated**: 2025-12-26
**Extracted From**: SARK project, thesymposium, and czarina
**Applicable To**: All agent development projects
