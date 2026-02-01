# Code Role - Implementation

**Source:** Extracted from [Hopper](https://github.com/hopper), [Czarina](https://github.com/czarina), and [SARK](https://github.com/sark) patterns
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

The **Code** role is responsible for implementing features, writing production code, and creating unit tests. Code workers execute the plans and designs created by architects, following established patterns and standards.

**Core Principle:** Code workers implement. Architects design. Code workers should follow the architecture, not create it.

## Implementation Responsibilities

### Feature Implementation

Code workers implement features according to specifications:

```python
# Implementation based on architect's contract

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import uuid4

from sark.models import Server, ServerRegistrationRequest, ServerResponse
from sark.db import get_db
from sark.security import get_current_user, User

router = APIRouter()

@router.post("/servers", response_model=ServerResponse)
async def register_server(
    request: ServerRegistrationRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ServerResponse:
    """Register a new MCP server.

    Implements the server registration API defined in
    plans/mcp-integration-architecture.md
    """
    # Create server instance
    server = Server(
        id=uuid4(),
        name=request.name,
        transport=request.transport,
        command=request.command,
        args=request.args,
        env=request.env,
        owner_id=user.id,
    )

    # Save to database
    db.add(server)
    await db.commit()
    await db.refresh(server)

    # Return response
    return ServerResponse(
        id=server.id,
        name=server.name,
        status=server.status,
        created_at=server.created_at,
    )
```

**Key Practices:**
- Follow the API contract exactly
- Reference the architecture document
- Implement all validation rules
- Add comprehensive docstrings
- Include error handling

**From SARK:** Implementation matches the specification, no surprises.

### Business Logic

Code workers implement business logic in service layers:

```python
# Service layer implementation

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional
import structlog

from sark.models import Server, ServerStatus
from sark.adapters import ProtocolAdapter

logger = structlog.get_logger()

class ServerService:
    """Service for managing MCP servers.

    Implements server lifecycle management as specified in
    plans/server-management-design.md
    """

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_server_by_id(self, server_id: UUID) -> Optional[Server]:
        """Get server by ID.

        Args:
            server_id: Server UUID

        Returns:
            Server instance or None if not found
        """
        result = await self.db.execute(
            select(Server).where(Server.id == server_id)
        )
        return result.scalar_one_or_none()

    async def update_server_status(
        self,
        server_id: UUID,
        status: ServerStatus,
    ) -> Server:
        """Update server status with logging.

        Args:
            server_id: Server UUID
            status: New status

        Returns:
            Updated server

        Raises:
            ValueError: If server not found
        """
        server = await self.get_server_by_id(server_id)
        if not server:
            logger.error("server_not_found", server_id=server_id)
            raise ValueError(f"Server {server_id} not found")

        old_status = server.status
        server.status = status
        await self.db.commit()

        logger.info(
            "server_status_updated",
            server_id=server_id,
            old_status=old_status,
            new_status=status,
        )

        return server
```

**Key Practices:**
- Separate business logic from API routes
- Use dependency injection
- Add structured logging
- Raise appropriate exceptions
- Return typed results

### Unit Testing

Code workers write unit tests for all new code:

```python
# Unit tests for service layer

import pytest
from uuid import uuid4
from unittest.mock import AsyncMock, MagicMock

from sark.services import ServerService
from sark.models import Server, ServerStatus

@pytest.mark.asyncio
async def test_update_server_status_success():
    """Test successful server status update."""
    # Arrange
    server_id = uuid4()
    mock_db = AsyncMock()
    service = ServerService(db=mock_db)

    mock_server = MagicMock(spec=Server)
    mock_server.id = server_id
    mock_server.status = ServerStatus.ACTIVE

    service.get_server_by_id = AsyncMock(return_value=mock_server)

    # Act
    result = await service.update_server_status(
        server_id,
        ServerStatus.INACTIVE,
    )

    # Assert
    assert result.status == ServerStatus.INACTIVE
    mock_db.commit.assert_called_once()

@pytest.mark.asyncio
async def test_update_server_status_not_found():
    """Test server status update when server doesn't exist."""
    # Arrange
    server_id = uuid4()
    mock_db = AsyncMock()
    service = ServerService(db=mock_db)
    service.get_server_by_id = AsyncMock(return_value=None)

    # Act & Assert
    with pytest.raises(ValueError, match="not found"):
        await service.update_server_status(server_id, ServerStatus.INACTIVE)
```

**Key Practices:**
- Test happy path and error cases
- Use AAA pattern (Arrange, Act, Assert)
- Mock external dependencies
- Use descriptive test names
- Test edge cases

**From SARK:** Unit tests are part of implementation, not separate.

## Coding Standards Adherence

### Follow Python Standards

Code workers must follow established coding standards:

```python
# ✅ Good - Follows standards

from typing import Optional
from uuid import UUID
import structlog

logger = structlog.get_logger()

async def get_user_by_id(
    user_id: UUID,
    db: AsyncSession,
) -> Optional[User]:
    """Get user by ID.

    Args:
        user_id: User UUID
        db: Database session

    Returns:
        User instance or None if not found

    Example:
        >>> user = await get_user_by_id(user_id, db)
        >>> if user:
        ...     print(user.email)
    """
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    return result.scalar_one_or_none()
```

```python
# ❌ Bad - Violates standards

def getUserById(userId, db):  # Wrong naming, no types
    # No docstring
    result = db.execute(select(User).where(User.id == userId))  # Not async
    return result.scalar_one_or_none()
```

**Required Standards:**
- Type hints on all functions
- Google-style docstrings
- snake_case naming
- Async/await where appropriate
- Proper error handling

See [CODING_STANDARDS.md](../python-standards/CODING_STANDARDS.md) for complete standards.

### Pattern Adherence

Code workers follow established patterns:

```python
# ✅ Good - Follows dependency injection pattern

from fastapi import Depends
from sark.db import get_db
from sark.services import ServerService

@router.get("/servers/{server_id}")
async def get_server(
    server_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """Get server by ID following DI pattern."""
    service = ServerService(db)
    server = await service.get_server_by_id(server_id)
    if not server:
        raise HTTPException(404, "Server not found")
    return server
```

```python
# ❌ Bad - Creates dependencies directly

@router.get("/servers/{server_id}")
async def get_server(server_id: UUID):
    """Don't create database connections directly."""
    db = create_engine(...)  # Wrong - use dependency injection
    service = ServerService(db)
    return await service.get_server_by_id(server_id)
```

**Key Patterns:**
- Dependency injection for services
- Async patterns for I/O
- Error handling with custom exceptions
- Structured logging
- Circuit breakers for external calls

See [ASYNC_PATTERNS.md](../python-standards/ASYNC_PATTERNS.md) and [DEPENDENCY_INJECTION.md](../python-standards/DEPENDENCY_INJECTION.md).

## When to Write Code vs Plan

### Code Workers Should Code When:

- ✅ Architecture is documented and approved
- ✅ API contracts are defined
- ✅ Data models are specified
- ✅ Success criteria are clear
- ✅ Patterns are established
- ✅ Following existing design

### Code Workers Should NOT Code When:

- ❌ Architecture is unclear or missing
- ❌ API contract is undefined
- ❌ Major design decision needed
- ❌ Technology choice required
- ❌ Pattern doesn't exist yet

**If in doubt:** Ask the architect or create an RFC (Request for Comments).

### Escalation to Architect

When code workers encounter architectural issues:

```markdown
# RFC-001: Handle Circular Server Dependencies

## Problem
Current design doesn't handle circular dependencies between servers.
Server A depends on Server B, Server B depends on Server A.

## Impact
- Server startup fails
- No clear resolution path
- Blocks MCP integration

## Proposed Solutions
1. Dependency ordering (fail if circular)
2. Lazy initialization (start all, connect later)
3. Dependency injection (break circular refs)

## Recommendation
Option 2: Lazy initialization
- Matches FastAPI startup pattern
- Minimal code changes
- Handles all circular scenarios

## Decision Needed
Architect approval required before implementation.
```

**When to Create RFC:**
- Design ambiguity discovered
- Pattern doesn't fit use case
- Performance issue requires design change
- Security concern needs architectural decision

## File Ownership Patterns

### Code Worker File Ownership

Code workers own and modify:

```
src/
├── sark/
│   ├── api/           # API routes (owned by code worker)
│   ├── services/      # Business logic (owned by code worker)
│   ├── models/        # Implementation (owned by code worker)
│   └── adapters/      # Protocol adapters (owned by code worker)
tests/
└── unit/              # Unit tests (owned by code worker)
```

### Code Workers Should NOT Modify:

```
plans/                 # Architecture docs (owned by architect)
docs/architecture/     # Design docs (owned by architect)
tests/integration/     # Integration tests (owned by QA)
.czarina/              # Orchestration (owned by orchestrator)
```

**Exception:** Code workers can add clarifications to docs via PRs.

### Shared Ownership:

```
README.md              # Code workers update usage, architects update design
pyproject.toml         # Code workers add deps, architects approve major changes
```

## Code Review and Commit Patterns

### Commit Messages

Follow conventional commit format:

```bash
# ✅ Good commit messages

git commit -m "feat(servers): Add server registration API

Implement POST /api/servers endpoint per architecture spec.
Includes request validation, database persistence, and error handling.

Closes #123
"

git commit -m "fix(auth): Handle expired JWT tokens correctly

Update token validation to check expiry before claims.
Returns 401 with clear error message.

Fixes #456
"

git commit -m "test(servers): Add unit tests for server service

Test server creation, updates, and status transitions.
Coverage: 95% for server_service.py
"
```

```bash
# ❌ Bad commit messages

git commit -m "fixed bug"
git commit -m "WIP"
git commit -m "updates"
```

**Commit Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `refactor` - Code refactoring
- `test` - Test additions
- `docs` - Documentation
- `style` - Formatting changes
- `perf` - Performance improvements

### Checkpoint Commits

Code workers commit at logical checkpoints:

```bash
# After completing a feature module
git add src/sark/services/server_service.py tests/unit/test_server_service.py
git commit -m "feat(servers): Add ServerService with tests

Implement server lifecycle management.
All unit tests passing.

Checkpoint: Server service complete
"

# After completing API endpoint
git add src/sark/api/servers.py tests/unit/test_servers_api.py
git commit -m "feat(api): Add server registration endpoint

POST /api/servers with validation and error handling.

Checkpoint: Registration API complete
"
```

**Why Checkpoints:**
- Enables rollback to known-good state
- Helps QA understand progress
- Enables parallel code review
- Creates audit trail

### Self-Code Review

Before committing, code workers review their own code:

```python
# Self-review checklist
# □ Type hints on all functions
# □ Docstrings on public functions
# □ Error handling implemented
# □ Logging added for key operations
# □ Unit tests written and passing
# □ No debugging print statements
# □ No commented-out code
# □ Follows coding standards
# □ No security vulnerabilities
# □ Performance is acceptable
```

## What Code Workers Should NOT Do

### Don't Make Architecture Decisions

❌ **Don't:** Add new database without architect approval
❌ **Don't:** Change API contract unilaterally
❌ **Don't:** Introduce new design patterns
❌ **Don't:** Make technology stack changes

✅ **Do:** Create RFC and get architect approval

### Don't Skip Tests

❌ **Don't:** "I'll add tests later"
❌ **Don't:** "This is too simple to test"
❌ **Don't:** "Tests slow me down"

✅ **Do:** Write unit tests as you code

### Don't Over-Engineer

❌ **Don't:** Add abstraction "just in case"
❌ **Don't:** Implement features not in spec
❌ **Don't:** Optimize before measuring

✅ **Do:** Implement what's specified, simply

### Don't Work in Isolation

❌ **Don't:** Go silent for days
❌ **Don't:** Ignore architecture docs
❌ **Don't:** Skip code review

✅ **Do:** Commit checkpoints, ask questions, collaborate

## Collaboration Patterns

### Code Worker → Architect

```markdown
# When to engage architect:

- ❓ Design is unclear or ambiguous
- ❓ Pattern doesn't fit use case
- ❓ Need to make architectural decision
- ❓ Performance requires design change
- ❓ Security concern discovered
```

### Code Worker → Code Worker

```markdown
# When multiple code workers collaborate:

- 📝 Define clear file boundaries
- 📝 Use feature branches
- 📝 Commit frequently
- 📝 Communicate interface changes
- 📝 Run integration tests before pushing
```

### Code Worker → QA

```markdown
# Handoff to QA:

- ✅ All unit tests passing
- ✅ Code committed and pushed
- ✅ Documentation updated
- ✅ Known issues documented
- ✅ Integration points tested
```

## Success Criteria

A code worker has succeeded when:

- ✅ Feature implemented per specification
- ✅ All unit tests written and passing
- ✅ Coding standards followed
- ✅ Patterns adhered to
- ✅ Docstrings comprehensive
- ✅ Error handling implemented
- ✅ Logging added
- ✅ Code committed with good messages
- ✅ No architecture decisions made unilaterally
- ✅ Ready for QA integration testing

## Anti-Patterns

### Cowboy Coding
❌ **Don't:** Start coding without reading architecture
✅ **Do:** Read plans/, understand design, then implement

### Feature Creep
❌ **Don't:** Add "nice to have" features not in spec
✅ **Do:** Implement exactly what's specified

### Test Avoidance
❌ **Don't:** Skip tests because "QA will test it"
✅ **Do:** Write unit tests as part of implementation

### Premature Optimization
❌ **Don't:** Optimize before measuring performance
✅ **Do:** Make it work, measure, then optimize if needed

### Silent Struggle
❌ **Don't:** Spend days stuck without asking for help
✅ **Do:** Ask questions early, create RFCs when stuck

## Related Roles

- [ARCHITECT_ROLE.md](./ARCHITECT_ROLE.md) - Creates the plans you implement
- [QA_ROLE.md](./QA_ROLE.md) - Tests your implementation
- [DEBUG_ROLE.md](./DEBUG_ROLE.md) - Fixes bugs in code
- [AGENT_ROLES.md](./AGENT_ROLES.md) - Role taxonomy overview

## References

- [Python Coding Standards](../python-standards/CODING_STANDARDS.md)
- [Async Patterns](../python-standards/ASYNC_PATTERNS.md)
- [Dependency Injection](../python-standards/DEPENDENCY_INJECTION.md)
- [Testing Patterns](../python-standards/TESTING_PATTERNS.md)
- [SARK Codebase](https://github.com/sark) - Implementation examples
