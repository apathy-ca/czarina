# Python Coding Standards

**Source:** Extracted from [SARK](https://github.com/sark) codebase analysis
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This document establishes Python coding standards based on patterns extracted from the SARK codebase. These standards emphasize clarity, type safety, and maintainability for production-grade Python applications.

## File Organization

### Directory Structure

Use a **layered architecture** pattern to organize code by responsibility:

```
src/
├── models/          # Data models (SQLAlchemy ORM + Pydantic schemas)
├── api/             # API routers and middleware
├── services/        # Business logic layer
├── adapters/        # Protocol adapters (external integrations)
├── security/        # Security utilities
├── db/              # Database session management
├── config/          # Configuration management
└── utils/           # Utility functions
```

**Key Principles:**
- Separate concerns by layer (data, business logic, presentation)
- Keep adapters isolated from core business logic
- Security utilities in dedicated module
- Configuration centralized and typed

### Module `__init__.py` Pattern

Use `__init__.py` files to control public API and handle import flexibility:

**Example from SARK** (`src/sark/models/__init__.py`):

```python
"""Database models and schemas."""

# Support both package and test imports
try:
    from sark.models.audit import AuditEvent
    from sark.models.base import CapabilityBase, ResourceBase
    from sark.models.policy import Policy, PolicyType
except ModuleNotFoundError:
    from .audit import AuditEvent  # type: ignore
    from .base import CapabilityBase, ResourceBase  # type: ignore
    from .policy import Policy, PolicyType  # type: ignore

__all__ = [
    "AuditEvent",
    "CapabilityBase",
    "ResourceBase",
    "Policy",
    "PolicyType",
]
```

**Why This Pattern:**
- Enables both `from sark.models` and `from .models` imports
- Explicit `__all__` makes public API clear
- Type ignore comments acknowledge intentional flexibility
- Works in tests without complex path manipulation

## Naming Conventions

### Files

- **Use snake_case**: `rate_limiter.py`, `injection_detector.py`, `mcp_server.py`
- **Descriptive names**: Name should match the primary class or function
- **No abbreviations**: Prefer `authentication.py` over `auth.py` for modules

**Examples from SARK:**
```
✅ rate_limiter.py          (contains RateLimiter class)
✅ injection_detector.py    (contains PromptInjectionDetector class)
✅ policy_service.py        (contains PolicyService class)
❌ rl.py                     (abbreviation unclear)
❌ utils.py                  (too generic)
```

### Classes

- **PascalCase**: `RateLimiter`, `PromptInjectionDetector`, `PolicyService`
- **Pydantic models**: Describe schema intent with suffix
  - `ResourceSchema` - API request/response schema
  - `ServerRegistrationRequest` - Request-specific schema
  - `ServerResponse` - Response-specific schema
- **SQLAlchemy models**: Singular nouns without suffix
  - `User`, `Team`, `Policy` (not `Users`, `UserModel`)
- **Exception classes**: End with `Error`
  - `AdapterError`, `ValidationError`, `TimeoutError`

**Examples from SARK:**

```python
# Pydantic schemas
class ServerRegistrationRequest(BaseModel):
    """Server registration request schema."""
    name: str
    transport: str

class ServerResponse(BaseModel):
    """Server registration response."""
    id: UUID
    name: str

# SQLAlchemy models
class User(Base):
    """User database model."""
    __tablename__ = "users"
    id: Mapped[UUID]

# Exceptions
class AdapterError(Exception):
    """Base exception for all adapter errors."""
    pass

class ValidationError(AdapterError):
    """Raised when request validation fails."""
    pass
```

### Functions and Methods

- **Use snake_case**: `check_rate_limit()`, `create_policy()`, `get_capabilities()`
- **Async prefix**: Always use `async def` for async functions
  - `async def get_db()`, `async def invoke()`
- **Private methods**: Prefix with underscore `_flatten_dict()`, `_compile_patterns()`
- **Boolean returns**: Use `is_`, `has_`, `can_` prefixes
  - `is_admin()`, `has_role()`, `can_access()`

**Examples from SARK:**

```python
# Public async method
async def check_rate_limit(self, identifier: str) -> RateLimitInfo:
    """Check if request is within rate limit."""
    pass

# Public sync method
def has_role(self, role: str) -> bool:
    """Check if user has a specific role."""
    return role in self.roles

# Private helper
def _flatten_dict(self, d: dict, parent_key: str = "") -> dict:
    """Flatten nested dictionary for processing."""
    pass
```

### Variables

- **Use snake_case**: `rate_limit_info`, `discovery_config`, `user_context`
- **Constants**: `UPPER_SNAKE_CASE` with underscores for readability
  - `CHUNK_SIZE = 10000`
  - `MAX_STRING_LENGTH = 1_000_000`
- **Type hints**: Always provide type hints for variables with ambiguous types

**Examples from SARK:**

```python
# Regular variables
rate_limit_info: RateLimitInfo = await check_limit(user_id)
discovery_config = DiscoveryConfig(timeout=30)
user_context: UserContext = get_current_user(request)

# Constants (from secret_scanner.py)
CHUNK_SIZE = 10000
MAX_STRING_LENGTH = 1_000_000
```

## Import Organization

### Standard Order

Organize imports in three sections with blank lines between:

1. **Standard library imports**
2. **Third-party imports**
3. **First-party imports** (from your package)

**Example from SARK** (`src/sark/security/injection_detector.py`):

```python
# Standard library
from dataclasses import dataclass, field
from enum import Enum
from functools import lru_cache
import math
import re
from typing import TYPE_CHECKING, Any

# Third-party
import structlog

# Local imports with TYPE_CHECKING guard
if TYPE_CHECKING:
    from sark.security.config import InjectionDetectionConfig

logger = structlog.get_logger()
```

### TYPE_CHECKING Pattern

Use `TYPE_CHECKING` to avoid circular imports while maintaining type hints:

```python
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from sark.security.config import InjectionDetectionConfig

class PromptInjectionDetector:
    def __init__(self, config: "InjectionDetectionConfig | None" = None):
        # Note: String annotation "InjectionDetectionConfig"
        # avoids runtime import
        pass
```

**Why:**
- Prevents circular import errors
- Maintains full type checking in IDEs
- Import only happens during type checking, not runtime

### Tool Configuration

Use `ruff` for automatic import sorting:

**From SARK's `pyproject.toml`:**

```toml
[tool.ruff.lint.isort]
force-sort-within-sections = true
known-first-party = ["sark"]
```

## Type Hints and Annotations

### Comprehensive Type Hints

**Always provide type hints** for:
- Function parameters
- Return types
- Class attributes with non-obvious types
- Variables where type isn't clear from assignment

**Example from SARK** (`src/sark/services/rate_limiter.py`):

```python
async def check_rate_limit(
    self,
    identifier: str,
    limit: int | None = None,
) -> RateLimitInfo:
    """Check if request is within rate limit.

    Args:
        identifier: Unique identifier (e.g., "api_key:abc123")
        limit: Custom limit for this identifier (uses default if None)

    Returns:
        RateLimitInfo with rate limit status and metadata
    """
    pass
```

### Modern Union Syntax

Use Python 3.10+ union syntax with `|` operator:

```python
# ✅ Modern (Python 3.10+)
jwt_secret_key: str | None = None
policy_type: PolicyType | None = None
result: dict[str, Any] | list[str] = {}

# ❌ Old style (avoid)
from typing import Union, Optional
jwt_secret_key: Optional[str] = None
result: Union[dict, list] = {}
```

### Generic Types

Use proper generic types from `collections.abc`:

```python
from collections.abc import AsyncGenerator, Sequence, Mapping

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Get database session for main PostgreSQL database."""
    pass

def process_items(items: Sequence[str]) -> Mapping[str, int]:
    """Process items and return mapping."""
    return {item: len(item) for item in items}
```

**Why `collections.abc`:**
- More flexible than `typing.List`, `typing.Dict`
- Better for function parameters (accepts any sequence, not just list)
- PEP 585 recommendation for Python 3.9+

## Docstring Conventions

### Google-Style Docstrings

Use Google-style docstrings with clear sections:

**Full Example from SARK** (`src/sark/services/rate_limiter.py`):

```python
async def check_rate_limit(
    self,
    identifier: str,
    limit: int | None = None,
) -> RateLimitInfo:
    """Check if request is within rate limit.

    Uses sliding window algorithm with Redis sorted sets.
    Each request is stored with timestamp as score.

    Args:
        identifier: Unique identifier (e.g., "api_key:abc123", "user:uuid", "ip:1.2.3.4")
        limit: Custom limit for this identifier (uses default if None)

    Returns:
        RateLimitInfo with rate limit status and metadata

    Raises:
        ConnectionError: If Redis connection fails
        ValueError: If identifier is empty or invalid

    Example:
        >>> limiter = RateLimiter(redis_client)
        >>> info = await limiter.check_rate_limit("user:123", limit=100)
        >>> if not info.allowed:
        ...     raise HTTPException(429, "Rate limit exceeded")
    """
    pass
```

### Module-Level Docstrings

Provide comprehensive module documentation:

**Example from SARK** (`src/sark/adapters/base.py`):

```python
"""
Base protocol adapter interface for SARK v2.0.

This module defines the abstract base class that all protocol adapters must implement.
Adapters translate protocol-specific concepts into GRID's universal abstractions.

Version: 2.0.0
Status: Frozen for Week 1 (foundation phase)

Example:
    Implement a new adapter by subclassing ProtocolAdapter:

    >>> class MyAdapter(ProtocolAdapter):
    ...     protocol_name = "my-protocol"
    ...
    ...     async def discover_resources(self, config):
    ...         # Implementation
    ...         pass
"""
```

### Class Docstrings

Document class purpose, attributes, and usage:

```python
class RateLimiter:
    """Rate limiter using Redis sliding window algorithm.

    Tracks requests within a time window and enforces rate limits.
    Uses Redis sorted sets for efficient window management.

    Attributes:
        redis: Redis client for state storage
        window_seconds: Time window for rate limiting (default: 60)
        default_limit: Default requests per window (default: 100)

    Example:
        >>> limiter = RateLimiter(redis_client, window_seconds=60, default_limit=100)
        >>> info = await limiter.check_rate_limit("user:123")
        >>> print(f"Remaining: {info.remaining}")
    """
```

## Code Style

### Line Length

- **Maximum 100 characters** (SARK uses 100 in ruff config)
- Break long lines at logical points
- Use parentheses for implicit line continuation

```python
# ✅ Good - logical break points
result = await adapter.invoke(
    request=invocation_request,
    timeout=timeout_seconds,
    retry_attempts=3,
)

# ✅ Good - implicit continuation
if (
    user.has_role("admin")
    and resource.sensitivity_level == "high"
    and not user.is_suspended
):
    allow_access()

# ❌ Bad - line too long
result = await adapter.invoke(request=invocation_request, timeout=timeout_seconds, retry_attempts=3)
```

### Formatting Tools

Use **Black** and **Ruff** for consistent formatting:

**From SARK's `pyproject.toml`:**

```toml
[tool.black]
line-length = 100
target-version = ['py311']

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = [
    "E",      # pycodestyle errors
    "W",      # pycodestyle warnings
    "F",      # pyflakes
    "I",      # isort
    "N",      # pep8-naming
    "UP",     # pyupgrade
    "ASYNC",  # async best practices
    "S",      # bandit security
    "B",      # bugbear
    "A",      # builtins
    "C4",     # comprehensions
    "DTZ",    # datetime
    "RUF",    # ruff-specific
]
```

## Constants and Configuration

### Module-Level Constants

Define constants at module level with clear names:

**Example from SARK** (`src/sark/security/secret_scanner.py`):

```python
# Performance tuning
CHUNK_SIZE = 10000
MAX_STRING_LENGTH = 1_000_000

# Secret patterns with metadata
SECRET_PATTERNS: list[tuple[str, str, float]] = [
    (r"sk-[a-zA-Z0-9]{20,}", "OpenAI API Key", 1.0),
    (r"ghp_[a-zA-Z0-9]{20,}", "GitHub Personal Access Token", 1.0),
    (r"AKIA[0-9A-Z]{16}", "AWS Access Key ID", 1.0),
]
```

### Dataclass Constants

Use dataclasses for structured configuration:

```python
from dataclasses import dataclass, field

@dataclass
class SecurityConfig:
    """Security configuration settings."""

    max_login_attempts: int = 5
    session_timeout_seconds: int = 3600
    require_mfa: bool = False
    allowed_origins: list[str] = field(default_factory=lambda: ["https://app.example.com"])
```

## Success Criteria

A Python codebase follows these standards when:

- ✅ All files use consistent naming (snake_case for files, PascalCase for classes)
- ✅ Imports organized in three sections (stdlib, third-party, first-party)
- ✅ Type hints on all public functions and ambiguous variables
- ✅ Google-style docstrings on all public classes and functions
- ✅ Module-level docstrings explain purpose
- ✅ Constants use UPPER_SNAKE_CASE
- ✅ Line length ≤ 100 characters
- ✅ Black and Ruff pass with no warnings
- ✅ No star imports (`from module import *`)
- ✅ `__all__` defined in `__init__.py` files

## Related Standards

- [ASYNC_PATTERNS.md](./ASYNC_PATTERNS.md) - Async/await patterns
- [ERROR_HANDLING.md](./ERROR_HANDLING.md) - Exception handling
- [DEPENDENCY_INJECTION.md](./DEPENDENCY_INJECTION.md) - DI patterns
- [TESTING_PATTERNS.md](./TESTING_PATTERNS.md) - Testing standards
- [SECURITY_PATTERNS.md](./SECURITY_PATTERNS.md) - Security practices

## References

- [PEP 8 – Style Guide for Python Code](https://peps.python.org/pep-0008/)
- [PEP 257 – Docstring Conventions](https://peps.python.org/pep-0257/)
- [PEP 484 – Type Hints](https://peps.python.org/pep-0484/)
- [PEP 585 – Type Hinting Generics In Standard Collections](https://peps.python.org/pep-0585/)
- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
- [SARK Codebase](https://github.com/sark) - Source of extracted patterns
