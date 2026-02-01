# API Documentation Standards

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This document defines standards for documenting APIs including REST APIs, GraphQL APIs, and programmatic library APIs.

## Core Principles

1. **Completeness:** Every public API endpoint/function must be documented
2. **Accuracy:** Documentation must match implementation exactly
3. **Examples:** Every non-trivial API must include working examples
4. **Synchronization:** API docs update with API changes (same commit)

## REST API Documentation

### Required Documentation

For each endpoint, document:

#### 1. Endpoint Definition

\`\`\`http
METHOD /path/to/endpoint
\`\`\`

**Elements:**
- HTTP method (GET, POST, PUT, PATCH, DELETE)
- Full path including path parameters
- Description of what the endpoint does

#### 2. Authentication

Document authentication requirements:
- Authentication method (Bearer token, API Key, OAuth)
- Required scopes or permissions
- Example authentication header

**Example:**
\`\`\`bash
curl -H "Authorization: Bearer YOUR_API_KEY" \\
  https://api.example.com/v1/resources
\`\`\`

#### 3. Parameters

Document all parameters in tables:

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string (UUID) | Yes | Resource identifier |

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | `1` | Page number (1-indexed) |
| `per_page` | integer | No | `20` | Items per page (max: 100) |
| `sort` | string | No | `created_at` | Sort field |
| `order` | string | No | `desc` | Sort order (`asc` or `desc`) |

**Request Body:**

| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| `name` | string | Yes | max length: 100 | Resource name |
| `email` | string | Yes | valid email format | User email |
| `age` | integer | No | min: 0, max: 150 | User age |

#### 4. Request Examples

Provide complete, working examples:

\`\`\`bash
# cURL example
curl -X POST https://api.example.com/v1/users \\
  -H "Authorization: Bearer YOUR_API_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{
    "name": "Jane Doe",
    "email": "jane@example.com",
    "age": 30
  }'
\`\`\`

\`\`\`python
# Python example
import requests

response = requests.post(
    "https://api.example.com/v1/users",
    headers={"Authorization": f"Bearer {API_KEY}"},
    json={
        "name": "Jane Doe",
        "email": "jane@example.com",
        "age": 30
    }
)

data = response.json()
print(f"Created user: {data['id']}")
\`\`\`

\`\`\`typescript
// TypeScript example
const response = await fetch('https://api.example.com/v1/users', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${API_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    name: 'Jane Doe',
    email: 'jane@example.com',
    age: 30,
  }),
});

const data = await response.json();
console.log(`Created user: ${data.id}`);
\`\`\`

#### 5. Response Documentation

Document all possible responses:

**Success Response (201 Created):**
\`\`\`json
{
  "status": "success",
  "data": {
    "id": "usr_abc123",
    "name": "Jane Doe",
    "email": "jane@example.com",
    "age": 30,
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:00Z"
  }
}
\`\`\`

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique user identifier |
| `name` | string | User's full name |
| `email` | string | User's email address |
| `created_at` | string (ISO 8601) | Creation timestamp |

#### 6. Error Responses

Document all error scenarios:

**Error Response (400 Bad Request):**
\`\`\`json
{
  "status": "error",
  "error": {
    "code": "validation_error",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "error": "Invalid email format"
      }
    ]
  }
}
\`\`\`

**Status Codes:**

| Code | Description | When it occurs |
|------|-------------|----------------|
| 200 | OK | Successful GET/PUT/PATCH request |
| 201 | Created | Successful POST request |
| 204 | No Content | Successful DELETE request |
| 400 | Bad Request | Invalid request format or parameters |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 422 | Unprocessable Entity | Validation errors |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

### API Versioning

Document versioning strategy:

**URL-based versioning:**
\`\`\`
/v1/users
/v2/users
\`\`\`

**Header-based versioning:**
\`\`\`http
GET /users
Accept-Version: v1
\`\`\`

**Version Compatibility:**
- Document breaking vs non-breaking changes
- Provide migration guides between versions
- Specify deprecation timeline

### Rate Limiting

Document rate limits:

**Limits:**

| Plan | Requests/Minute | Requests/Hour | Requests/Day |
|------|-----------------|---------------|--------------|
| Free | 60 | 1,000 | 10,000 |
| Pro | 600 | 10,000 | 100,000 |
| Enterprise | Custom | Custom | Custom |

**Headers:**
\`\`\`http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1674567890
\`\`\`

**Rate Limit Exceeded (429):**
\`\`\`json
{
  "status": "error",
  "error": {
    "code": "rate_limit_exceeded",
    "message": "Rate limit exceeded",
    "retry_after": 60
  }
}
\`\`\`

## GraphQL API Documentation

### Schema Documentation

Document GraphQL schema with descriptions:

\`\`\`graphql
"""
User type represents a user account in the system
"""
type User {
  """Unique user identifier"""
  id: ID!

  """User's email address"""
  email: String!

  """User's full name"""
  name: String!

  """Account creation timestamp"""
  createdAt: DateTime!

  """Resources owned by this user"""
  resources(
    """Number of items per page (max: 100)"""
    perPage: Int = 20

    """Page number (1-indexed)"""
    page: Int = 1
  ): ResourceConnection!
}

"""
Input type for creating a new user
"""
input CreateUserInput {
  """User's email address (must be unique)"""
  email: String!

  """User's full name"""
  name: String!
}
\`\`\`

### Query/Mutation Documentation

**Query Example:**
\`\`\`graphql
"""
Get a user by ID
"""
query GetUser($id: ID!) {
  user(id: $id) {
    id
    name
    email
  }
}
\`\`\`

**Mutation Example:**
\`\`\`graphql
"""
Create a new user
"""
mutation CreateUser($input: CreateUserInput!) {
  createUser(input: $input) {
    id
    name
    email
    createdAt
  }
}
\`\`\`

**Variables:**
\`\`\`json
{
  "input": {
    "email": "jane@example.com",
    "name": "Jane Doe"
  }
}
\`\`\`

### Error Handling

Document GraphQL errors:

\`\`\`json
{
  "errors": [
    {
      "message": "User not found",
      "path": ["user"],
      "extensions": {
        "code": "NOT_FOUND",
        "userId": "usr_123"
      }
    }
  ]
}
\`\`\`

## Python Library API Documentation

### Module Documentation

Document modules with docstrings:

\`\`\`python
"""User management module.

This module provides functionality for creating, updating, and managing users
in the system. It includes the User model, UserRepository for data access, and
UserService for business logic.

Typical usage example:

    from myapp.users import UserService

    service = UserService(db_session)
    user = await service.create_user("jane@example.com", "Jane Doe")
"""
\`\`\`

### Class Documentation

\`\`\`python
class UserService:
    """Service for user management operations.

    This service provides high-level operations for user management including
    creation, updating, deletion, and querying. It handles business logic,
    validation, and coordinates with the data layer.

    Attributes:
        repository: UserRepository instance for data access
        cache: Redis cache client for caching user data

    Example:
        >>> service = UserService(db_session, redis_client)
        >>> user = await service.create_user("jane@example.com", "Jane")
        >>> print(user.id)
        'usr_abc123'
    """

    def __init__(
        self,
        repository: UserRepository,
        cache: Redis
    ) -> None:
        """Initialize UserService.

        Args:
            repository: Repository for user data access
            cache: Redis client for caching
        """
        self.repository = repository
        self.cache = cache
\`\`\`

### Method Documentation

\`\`\`python
async def create_user(
    self,
    email: str,
    name: str,
    *,
    is_active: bool = True
) -> User:
    """Create a new user.

    Creates a new user with the provided email and name. The email must be
    unique in the system. The user is created as active by default.

    Args:
        email: User's email address (must be unique)
        name: User's full name
        is_active: Whether user account is active. Defaults to True.

    Returns:
        Created User instance with generated ID and timestamps

    Raises:
        ValueError: If email is invalid or already exists
        ValidationError: If name is empty or exceeds maximum length

    Example:
        >>> user = await service.create_user(
        ...     email="jane@example.com",
        ...     name="Jane Doe"
        ... )
        >>> print(user.id)
        'usr_abc123'

    Note:
        This method automatically sends a welcome email to the user.
    """
    # Implementation...
\`\`\`

### Type Hints

Always provide complete type hints:

\`\`\`python
from typing import Optional, List, Dict, Any, Union
from decimal import Decimal

async def calculate_price(
    items: List[Item],
    discount: Optional[Decimal] = None,
    options: Dict[str, Any] = {}
) -> Decimal:
    """Calculate total price with optional discount."""
    ...
\`\`\`

## TypeScript/JavaScript Library API Documentation

### Interface Documentation

\`\`\`typescript
/**
 * Configuration options for the API client.
 *
 * @example
 * ```ts
 * const config: ClientConfig = {
 *   apiKey: process.env.API_KEY,
 *   baseUrl: 'https://api.example.com',
 *   timeout: 30000,
 * };
 * ```
 */
export interface ClientConfig {
  /**
   * API authentication key
   * @required
   */
  apiKey: string;

  /**
   * Base URL for API requests
   * @default "https://api.example.com/v1"
   */
  baseUrl?: string;

  /**
   * Request timeout in milliseconds
   * @default 30000
   */
  timeout?: number;

  /**
   * Maximum number of retry attempts
   * @default 3
   */
  maxRetries?: number;
}
\`\`\`

### Function Documentation

\`\`\`typescript
/**
 * Create a new user in the system.
 *
 * This function creates a new user with the provided email and name.
 * The email must be unique in the system.
 *
 * @param email - User's email address (must be unique)
 * @param name - User's full name
 * @param options - Additional user options
 * @returns Promise resolving to the created User object
 * @throws {ValidationError} If email is invalid
 * @throws {ConflictError} If email already exists
 * @throws {APIError} For other API errors
 *
 * @example
 * ```ts
 * const user = await createUser('jane@example.com', 'Jane Doe');
 * console.log(user.id); // 'usr_abc123'
 * ```
 *
 * @see {@link User} for the return type structure
 * @see {@link updateUser} for updating user information
 */
export async function createUser(
  email: string,
  name: string,
  options?: CreateUserOptions
): Promise<User> {
  // Implementation...
}
\`\`\`

## Documentation Generation

### Automated Documentation

**Python (Sphinx):**
\`\`\`bash
# Generate API docs
sphinx-apidoc -o docs/api src/
sphinx-build docs build/html
\`\`\`

**TypeScript (TypeDoc):**
\`\`\`bash
# Generate API docs
typedoc --out docs/api src/
\`\`\`

**OpenAPI/Swagger:**
\`\`\`python
# FastAPI automatically generates OpenAPI docs
from fastapi import FastAPI

app = FastAPI(
    title="My API",
    description="API for managing users and resources",
    version="1.0.0"
)

# Docs available at:
# - /docs (Swagger UI)
# - /redoc (ReDoc)
# - /openapi.json (OpenAPI schema)
\`\`\`

### Documentation Testing

**Test Examples:**
\`\`\`python
# Doctest in Python
def add(a: int, b: int) -> int:
    """Add two numbers.

    >>> add(2, 3)
    5
    >>> add(-1, 1)
    0
    """
    return a + b

# Run doctests
python -m doctest module.py
\`\`\`

**Test API Documentation:**
\`\`\`python
import pytest
from docs.examples import example_create_user

def test_documentation_example():
    """Verify documentation examples are accurate."""
    # Run example from documentation
    result = example_create_user()

    # Verify it works as documented
    assert result.email == "jane@example.com"
    assert result.name == "Jane Doe"
\`\`\`

## Best Practices

### ✅ Do

- Document all public APIs
- Include working examples
- Keep examples up to date
- Test documentation examples
- Document errors and exceptions
- Provide migration guides for breaking changes
- Use consistent terminology
- Link related documentation

### ❌ Don't

- Document internal/private APIs (unless needed)
- Include examples that don't work
- Forget to update docs when API changes
- Use ambiguous language
- Assume prior knowledge
- Document obvious behavior
- Copy-paste without verification

## Templates

For complete API documentation templates, see:
- [API Documentation Template](../../templates/api-documentation-template.md) - Comprehensive template
- [README Template](../../templates/readme-template.md) - For API overview

## Examples from Projects

### SARK API Documentation

Excellent example of:
- Complete endpoint documentation
- Working examples in multiple languages
- Error handling documentation
- Authentication documentation

### Czarina API

Good example of:
- Worker API documentation
- Tool registry documentation
- Event-driven API documentation

## Related Standards

- [Documentation Standards](./DOCUMENTATION_STANDARDS.md)
- [Architecture Documentation](./ARCHITECTURE_DOCS.md)
- [Python Coding Standards](../python-standards/CODING_STANDARDS.md)

## References

This document synthesizes patterns from:
- Foundation Worker: API documentation patterns, docstring standards
- Patterns Worker: API design patterns
- Security Worker: Authentication/authorization documentation
- Testing Worker: API testing documentation
