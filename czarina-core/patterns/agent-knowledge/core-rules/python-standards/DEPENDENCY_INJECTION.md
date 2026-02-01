# Python Dependency Injection Patterns

**Source:** Extracted from [SARK](https://github.com/sark) codebase analysis
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This document establishes dependency injection (DI) patterns for Python applications based on SARK's implementation. These patterns promote loose coupling, testability, and clean separation of concerns through constructor injection, FastAPI's Depends mechanism, and configuration management.

## Core Principles

### What is Dependency Injection

Dependency injection is a design pattern where dependencies are provided to a component rather than the component creating them itself.

**Benefits:**
- Testability: Easy to mock dependencies in tests
- Loose coupling: Components depend on interfaces, not implementations
- Flexibility: Easy to swap implementations
- Configuration: Centralized dependency management

**SARK uses DI for:**
- Database sessions (AsyncSession)
- Configuration (Settings via Pydantic)
- Authentication (UserContext via middleware)
- External clients (Redis, OPA, Kong)
- Service layer dependencies

## Constructor Injection Pattern

### Service Layer with Injected Dependencies

Services accept dependencies through constructor parameters:

**Example from SARK** (`src/sark/services/policy/policy_service.py`):

```python
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

class PolicyService:
    """Service for managing policies with injected database session."""

    def __init__(self, db: AsyncSession) -> None:
        """Initialize policy service.

        Args:
            db: Active database session (injected by caller)
        """
        self.db = db

    async def create_policy(
        self,
        name: str,
        description: str,
        policy_type: PolicyType,
        initial_content: str,
        created_by: UUID,
    ) -> Policy:
        """Create a new policy with initial version."""
        policy = Policy(
            name=name,
            description=description,
            policy_type=policy_type,
            created_by=created_by,
        )
        self.db.add(policy)
        await self.db.flush()  # Get policy.id without committing

        # Create initial version
        version = PolicyVersion(
            policy_id=policy.id,
            content=initial_content,
            version=1,
            created_by=created_by,
        )
        self.db.add(version)
        await self.db.commit()
        await self.db.refresh(policy)

        return policy

    async def get_policy(self, policy_id: UUID) -> Policy | None:
        """Get policy by ID."""
        result = await self.db.execute(
            select(Policy).where(Policy.id == policy_id)
        )
        return result.scalar_one_or_none()
```

**Pattern Benefits:**
- Session is injected, not created
- Service doesn't know about session lifecycle
- Easy to test with mock session
- Transaction boundaries controlled by caller

### Usage in API Routes

```python
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sark.db.session import get_db

router = APIRouter()

@router.post("/policies/")
async def create_policy(
    request: PolicyCreateRequest,
    db: AsyncSession = Depends(get_db),
) -> PolicyResponse:
    """Create new policy endpoint.

    Dependencies injected by FastAPI:
    - db: Database session from get_db dependency
    """
    # Instantiate service with injected session
    service = PolicyService(db)

    # Use service
    policy = await service.create_policy(
        name=request.name,
        description=request.description,
        policy_type=request.policy_type,
        initial_content=request.content,
        created_by=request.created_by,
    )

    return PolicyResponse.from_orm(policy)
```

## Pydantic Settings Pattern

### Configuration with @lru_cache

Use Pydantic Settings with `@lru_cache` for singleton configuration:

**Example from SARK** (`src/sark/config.py`):

```python
from dataclasses import dataclass
from enum import Enum
import os


class ServiceMode(str, Enum):
    """Service deployment mode."""

    MANAGED = "managed"  # Service deployed via Docker Compose
    EXTERNAL = "external"  # Service hosted externally


@dataclass
class PostgreSQLConfig:
    """PostgreSQL database configuration."""

    enabled: bool
    mode: ServiceMode
    host: str
    port: int
    database: str
    user: str
    password: str
    pool_size: int
    max_overflow: int
    ssl_mode: str

    @property
    def connection_string(self) -> str:
        """Generate PostgreSQL connection string."""
        ssl_param = f"?sslmode={self.ssl_mode}" if self.ssl_mode != "disable" else ""
        return (
            f"postgresql://{self.user}:{self.password}@"
            f"{self.host}:{self.port}/{self.database}{ssl_param}"
        )

    @classmethod
    def from_env(cls) -> "PostgreSQLConfig":
        """Load PostgreSQL configuration from environment variables."""
        mode = ServiceMode(os.getenv("POSTGRES_MODE", "managed"))

        # Default values depend on mode
        if mode == ServiceMode.MANAGED:
            default_host = "database"  # Docker Compose service name
            default_port = 5432
        else:
            default_host = os.getenv("POSTGRES_HOST", "localhost")
            default_port = int(os.getenv("POSTGRES_PORT", "5432"))

        return cls(
            enabled=os.getenv("POSTGRES_ENABLED", "false").lower() == "true",
            mode=mode,
            host=os.getenv("POSTGRES_HOST", default_host),
            port=int(os.getenv("POSTGRES_PORT", str(default_port))),
            database=os.getenv("POSTGRES_DB", "sark"),
            user=os.getenv("POSTGRES_USER", "sark"),
            password=os.getenv("POSTGRES_PASSWORD", "sark"),
            pool_size=int(os.getenv("POSTGRES_POOL_SIZE", "5")),
            max_overflow=int(os.getenv("POSTGRES_MAX_OVERFLOW", "10")),
            ssl_mode=os.getenv("POSTGRES_SSL_MODE", "disable"),
        )


@dataclass
class AppConfig:
    """Main application configuration."""

    environment: str
    debug: bool
    log_level: str
    postgres: PostgreSQLConfig
    redis: RedisConfig
    kong: KongConfig

    @classmethod
    def from_env(cls) -> "AppConfig":
        """Load complete application configuration from environment variables."""
        return cls(
            environment=os.getenv("ENVIRONMENT", "development"),
            debug=os.getenv("DEBUG", "false").lower() == "true",
            log_level=os.getenv("LOG_LEVEL", "INFO"),
            postgres=PostgreSQLConfig.from_env(),
            redis=RedisConfig.from_env(),
            kong=KongConfig.from_env(),
        )

    def validate(self) -> list[str]:
        """Validate configuration and return list of errors."""
        errors = []

        # Validate PostgreSQL configuration
        if self.postgres.enabled and self.postgres.mode == ServiceMode.EXTERNAL:
            if not self.postgres.host or self.postgres.host == "database":
                errors.append("POSTGRES_HOST must be set when using external PostgreSQL")
            if self.postgres.password == "sark" and self.environment == "production":
                errors.append("POSTGRES_PASSWORD must be changed in production")

        return errors


# Global configuration instance (lazy-loaded)
_config: AppConfig | None = None


def get_config() -> AppConfig:
    """Get the global configuration instance.

    Singleton pattern - creates config once and reuses.
    Thread-safe for async applications.

    Returns:
        AppConfig: The application configuration

    Raises:
        ValueError: If configuration validation fails
    """
    global _config
    if _config is None:
        _config = AppConfig.from_env()
        errors = _config.validate()
        if errors:
            raise ValueError("Configuration validation failed:\n" + "\n".join(errors))
    return _config


def reset_config() -> None:
    """Reset the global configuration (useful for testing)."""
    global _config
    _config = None
```

**Pattern Benefits:**
- Configuration loaded once at startup
- Type-safe with dataclasses
- Environment-based configuration
- Validation at load time
- Easy to reset for testing

## FastAPI Depends Pattern

### Type Aliases for Dependencies

Create type aliases for cleaner annotations:

**Example from SARK** (`src/sark/api/dependencies.py`):

```python
from typing import Annotated
from fastapi import Depends

# Type aliases for cleaner annotations
CurrentUser = Annotated[UserContext, Depends(get_current_user)]
```

**Usage:**

```python
from sark.api.dependencies import CurrentUser

@router.get("/profile")
async def get_profile(user: CurrentUser) -> UserProfile:
    """Get user profile.

    Args:
        user: Current authenticated user (injected via CurrentUser type alias)
    """
    return UserProfile(
        user_id=user.user_id,
        email=user.email,
        name=user.name,
    )
```

### Database Session Dependency

**Pattern from SARK** (`src/sark/db/session.py`):

```python
from collections.abc import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, AsyncEngine, create_async_engine

_postgres_engine: AsyncEngine | None = None


def get_postgres_engine() -> AsyncEngine:
    """Get or create PostgreSQL engine with optimized connection pooling.

    Engine is created once and cached globally.
    Thread-safe for async applications.
    """
    global _postgres_engine
    if _postgres_engine is None:
        settings = get_settings()
        _postgres_engine = create_async_engine(
            settings.postgres_dsn,
            pool_size=settings.postgres_pool_size,           # Default: 20
            max_overflow=settings.postgres_max_overflow,     # Default: 40
            pool_timeout=settings.postgres_pool_timeout,     # Default: 30.0
            pool_recycle=settings.postgres_pool_recycle,     # Default: 3600
            pool_pre_ping=settings.postgres_pool_pre_ping,   # Default: True
            echo=settings.debug,                             # SQL logging in debug mode
        )
    return _postgres_engine


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Get database session for main PostgreSQL database.

    Automatically commits on success, rolls back on exception.
    Always closes session in finally block.

    Yields:
        AsyncSession for database operations
    """
    session_factory = get_session_factory()
    async with session_factory() as session:
        try:
            yield session
            await session.commit()  # Auto-commit on success
        except Exception:
            await session.rollback()  # Auto-rollback on error
            raise
        finally:
            await session.close()  # Always cleanup
```

**Usage:**

```python
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sark.db.session import get_db

@router.get("/users/{user_id}")
async def get_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> User:
    """Get user by ID.

    Dependencies:
        db: Database session (injected by FastAPI)
    """
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

## Dependency Factories

### Role-Based Access Control Factory

Create dependency factories for authorization:

**Example from SARK** (`src/sark/api/dependencies.py`):

```python
from typing import Annotated
from fastapi import Depends, HTTPException, status
import structlog

logger = structlog.get_logger(__name__)


def require_role(required_role: str):
    """Dependency factory to require a specific role.

    Args:
        required_role: The role required to access the endpoint

    Returns:
        Dependency function that validates the role

    Usage:
        @router.get("/admin-only")
        async def admin_endpoint(
            user: Annotated[UserContext, Depends(require_role("admin"))]
        ):
            return {"message": "Admin access granted"}
    """

    def _check_role(user: Annotated[UserContext, Depends(get_current_user)]) -> UserContext:
        if not user.has_role(required_role):
            logger.warning(
                "role_access_denied",
                user_id=user.user_id,
                required_role=required_role,
                user_roles=user.roles,
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role '{required_role}' required for this operation",
            )
        return user

    return _check_role


def require_permission(required_permission: str):
    """Dependency factory to require a specific permission.

    Args:
        required_permission: The permission required to access the endpoint

    Returns:
        Dependency function that validates the permission

    Usage:
        @router.post("/servers/")
        async def create_server(
            user: Annotated[UserContext, Depends(require_permission("servers:write"))]
        ):
            return {"message": "Server created"}
    """

    def _check_permission(user: Annotated[UserContext, Depends(get_current_user)]) -> UserContext:
        if not user.has_permission(required_permission):
            logger.warning(
                "permission_access_denied",
                user_id=user.user_id,
                required_permission=required_permission,
                user_permissions=list(user.permissions),
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission '{required_permission}' required for this operation",
            )
        return user

    return _check_permission


def require_team(required_team: str):
    """Dependency factory to require membership in a specific team.

    Args:
        required_team: The team required to access the endpoint

    Returns:
        Dependency function that validates team membership

    Usage:
        @router.get("/team/security/resources")
        async def team_resources(
            user: Annotated[UserContext, Depends(require_team("security"))]
        ):
            return {"resources": []}
    """

    def _check_team(user: Annotated[UserContext, Depends(get_current_user)]) -> UserContext:
        if not user.in_team(required_team):
            logger.warning(
                "team_access_denied",
                user_id=user.user_id,
                required_team=required_team,
                user_teams=user.teams,
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Team membership '{required_team}' required for this operation",
            )
        return user

    return _check_team
```

### User Context Extraction

**Example from SARK** (`src/sark/api/dependencies.py`):

```python
from fastapi import Request, HTTPException, status


class UserContext:
    """User context extracted from JWT token.

    Attributes:
        user_id: Unique user identifier
        email: User email address
        name: User display name
        roles: List of user roles
        teams: List of teams/groups user belongs to
        permissions: List of permissions granted to user
    """

    def __init__(self, data: dict):
        """Initialize user context from decoded JWT payload."""
        self.user_id: str = data.get("user_id", "")
        self.email: str | None = data.get("email")
        self.name: str | None = data.get("name")
        self.roles: list[str] = data.get("roles", [])
        self.teams: list[str] = data.get("teams", [])
        self.permissions: set[str] = set(data.get("permissions", []))

    def has_role(self, role: str) -> bool:
        """Check if user has a specific role."""
        return role in self.roles

    def has_permission(self, permission: str) -> bool:
        """Check if user has a specific permission."""
        return permission in self.permissions

    def is_admin(self) -> bool:
        """Check if user has admin role."""
        return self.has_role("admin")

    def in_team(self, team: str) -> bool:
        """Check if user belongs to a specific team."""
        return team in self.teams


def get_current_user(request: Request) -> UserContext:
    """FastAPI dependency to extract current authenticated user.

    Args:
        request: The incoming request (injected by FastAPI)

    Returns:
        UserContext object containing user information

    Raises:
        HTTPException: If user context is not available (unauthenticated)

    Usage:
        @router.get("/protected")
        async def protected_route(
            user: Annotated[UserContext, Depends(get_current_user)]
        ):
            return {"user_id": user.user_id}
    """
    if not hasattr(request.state, "user"):
        logger.error(
            "user_context_missing",
            path=request.url.path,
            message="User context not found in request state. Is auth middleware enabled?",
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
        )

    user_data = request.state.user
    return UserContext(user_data)
```

## Lazy Initialization Patterns

### Lazy Resource Initialization

Defer expensive initialization until first use:

```python
class PromptInjectionDetector:
    """Detects prompt injection attempts with lazy initialization."""

    def __init__(self, config: InjectionDetectionConfig | None = None):
        """Initialize detector.

        Compiles patterns immediately, but defers normalizer initialization.
        """
        if config is None:
            from sark.security.config import get_injection_config
            config = get_injection_config()

        self.config = config
        self._patterns = self._compile_patterns()  # Eager - fast operation
        self._normalizer = None  # Lazy - deferred until needed

    def detect(self, parameters: dict[str, Any]) -> InjectionDetectionResult:
        """Detect injection attempts.

        Initializes normalizer on first use.
        """
        # Lazy initialization
        if self._normalizer is None:
            from sark.security.text_normalizer import get_normalizer
            self._normalizer = get_normalizer()

        # Use normalizer
        normalized = self._normalizer.normalize(text)
        return self._check_patterns(normalized)

    def _compile_patterns(self) -> list:
        """Compile regex patterns eagerly (fast operation)."""
        return [re.compile(pattern) for pattern in self.config.patterns]
```

**Benefits:**
- Fast constructor
- Expensive resources created only if used
- No wasted initialization

### Lazy Configuration Loading

```python
from functools import lru_cache
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from sark.security.config import InjectionDetectionConfig


@lru_cache(maxsize=1)
def get_injection_config() -> "InjectionDetectionConfig":
    """Get injection detection configuration.

    Uses lru_cache to ensure config is loaded only once.
    TYPE_CHECKING prevents circular imports.

    Returns:
        InjectionDetectionConfig singleton instance
    """
    from sark.security.config import InjectionDetectionConfig

    return InjectionDetectionConfig.from_env()
```

## Global Engine/Client Patterns

### Database Engine Singleton

**Example from SARK** (`src/sark/db/session.py`):

```python
from sqlalchemy.ext.asyncio import AsyncEngine, create_async_engine

# Global engine instance (module-level)
_postgres_engine: AsyncEngine | None = None


def get_postgres_engine() -> AsyncEngine:
    """Get or create PostgreSQL engine with optimized connection pooling.

    Engine is created once and cached globally.
    Thread-safe for async applications.

    Returns:
        Singleton AsyncEngine instance
    """
    global _postgres_engine
    if _postgres_engine is None:
        settings = get_settings()
        _postgres_engine = create_async_engine(
            settings.postgres_dsn,
            pool_size=20,
            max_overflow=40,
            pool_timeout=30.0,
            pool_recycle=3600,
            pool_pre_ping=True,
            echo=settings.debug,
        )
    return _postgres_engine
```

**Why This Pattern:**
- Single connection pool across application
- Prevents connection exhaustion
- Lazy initialization
- Thread-safe for async

### Redis Client Singleton

```python
import redis.asyncio as aioredis

_redis_client: aioredis.Redis | None = None


async def get_redis_client() -> aioredis.Redis:
    """Get or create Redis client.

    Returns:
        Singleton Redis client instance
    """
    global _redis_client
    if _redis_client is None:
        settings = get_settings()
        _redis_client = await aioredis.from_url(
            settings.redis_url,
            encoding="utf-8",
            decode_responses=True,
            max_connections=50,
        )
    return _redis_client


async def close_redis_client() -> None:
    """Close Redis client connection."""
    global _redis_client
    if _redis_client is not None:
        await _redis_client.close()
        _redis_client = None
```

## Testing with Dependency Injection

### Overriding Dependencies in Tests

```python
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock

def test_create_policy_endpoint():
    """Test policy creation with mocked database."""
    # Create mock session
    mock_db = AsyncMock()
    mock_db.add = MagicMock()
    mock_db.commit = AsyncMock()

    # Override get_db dependency
    app.dependency_overrides[get_db] = lambda: mock_db

    try:
        client = TestClient(app)
        response = client.post(
            "/policies/",
            json={"name": "Test Policy", "type": "privacy"},
        )

        assert response.status_code == 201
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
    finally:
        # Clean up override
        app.dependency_overrides.clear()
```

### Service Testing with Constructor Injection

```python
import pytest
from unittest.mock import AsyncMock, MagicMock

@pytest.mark.asyncio
async def test_policy_service_create():
    """Test PolicyService.create_policy with mock session."""
    # Create mock session
    mock_db = AsyncMock()
    mock_db.add = MagicMock()
    mock_db.flush = AsyncMock()
    mock_db.commit = AsyncMock()
    mock_db.refresh = AsyncMock()

    # Inject mock into service
    service = PolicyService(db=mock_db)

    # Test service method
    policy = await service.create_policy(
        name="Test Policy",
        description="Test description",
        policy_type=PolicyType.PRIVACY,
        initial_content="content",
        created_by=UUID("12345678-1234-5678-1234-567812345678"),
    )

    # Verify interactions
    assert mock_db.add.call_count == 2  # Policy + PolicyVersion
    mock_db.flush.assert_called_once()
    mock_db.commit.assert_called_once()
```

## Success Criteria

A dependency injection implementation follows these patterns when:

- Constructor injection for services (accept AsyncSession, not create it)
- Pydantic Settings with @lru_cache for configuration
- FastAPI Depends() for route-level injection
- Type aliases for common dependencies (CurrentUser)
- Dependency factories for authorization (require_role, require_permission)
- Lazy initialization for expensive resources
- Global singletons for engines/clients (with thread-safe creation)
- Configuration loaded from environment variables
- Dependencies are interfaces, not concrete implementations
- Easy to override dependencies in tests
- No circular dependencies (use TYPE_CHECKING)

## Related Standards

- [CODING_STANDARDS.md](./CODING_STANDARDS.md) - General coding standards
- [ASYNC_PATTERNS.md](./ASYNC_PATTERNS.md) - Async database sessions
- [TESTING_PATTERNS.md](./TESTING_PATTERNS.md) - Testing with mocks
- [SECURITY_PATTERNS.md](./SECURITY_PATTERNS.md) - Authentication/authorization
- [ERROR_HANDLING.md](./ERROR_HANDLING.md) - Error handling in DI

## References

- [FastAPI Dependency Injection](https://fastapi.tiangolo.com/tutorial/dependencies/)
- [Pydantic Settings](https://docs.pydantic.dev/latest/concepts/pydantic_settings/)
- [SQLAlchemy Async Sessions](https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html)
- [Dependency Injection in Python](https://python-dependency-injector.ets-labs.org/)
- [SARK Codebase](https://github.com/sark) - Source of extracted patterns
