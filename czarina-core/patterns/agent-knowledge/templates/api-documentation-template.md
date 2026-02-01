# API Documentation Template

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This template provides comprehensive API documentation structure for REST APIs, GraphQL APIs, and Python/TypeScript libraries.

## When to Use This Template

Use this template for:
- REST API documentation
- GraphQL API documentation
- Python library API documentation
- TypeScript/JavaScript library API documentation
- Internal API documentation

---

# [PROJECT_NAME] API Documentation

**Version:** [API_VERSION]
**Base URL:** `https://api.example.com/v1`
**Last Updated:** YYYY-MM-DD

## Overview

[PROJECT_NAME] provides [description of API purpose and capabilities].

### API Characteristics

- **Style:** REST / GraphQL / RPC
- **Data Format:** JSON / XML / Protocol Buffers
- **Authentication:** API Key / JWT / OAuth 2.0
- **Rate Limiting:** X requests per minute
- **Versioning:** URL-based / Header-based

## Quick Start

### Authentication

**API Key Authentication:**

\`\`\`bash
curl -H "Authorization: Bearer YOUR_API_KEY" \\
  https://api.example.com/v1/endpoint
\`\`\`

**JWT Authentication:**

\`\`\`bash
# Obtain token
curl -X POST https://api.example.com/v1/auth/login \\
  -H "Content-Type: application/json" \\
  -d '{"username": "user", "password": "pass"}'

# Use token
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \\
  https://api.example.com/v1/endpoint
\`\`\`

### Making Your First Request

\`\`\`bash
curl -H "Authorization: Bearer YOUR_API_KEY" \\
  https://api.example.com/v1/[resource]
\`\`\`

**Response:**

\`\`\`json
{
  "status": "success",
  "data": {
    "example": "value"
  }
}
\`\`\`

## REST API Reference

### Resource: [ResourceName]

#### List [Resources]

\`\`\`http
GET /v1/[resources]
\`\`\`

**Description:**
Retrieves a paginated list of [resources].

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | `1` | Page number for pagination |
| `per_page` | integer | No | `20` | Items per page (max: 100) |
| `sort` | string | No | `created_at` | Sort field |
| `order` | string | No | `desc` | Sort order (`asc` or `desc`) |
| `filter` | string | No | - | Filter expression |

**Example Request:**

\`\`\`bash
curl -H "Authorization: Bearer YOUR_API_KEY" \\
  "https://api.example.com/v1/resources?page=1&per_page=20&sort=name&order=asc"
\`\`\`

**Example Response:**

\`\`\`json
{
  "status": "success",
  "data": [
    {
      "id": "res_123",
      "name": "Example Resource",
      "created_at": "2025-01-15T10:30:00Z",
      "updated_at": "2025-01-15T10:30:00Z",
      "attributes": {
        "key": "value"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "pages": 5
  }
}
\`\`\`

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique resource identifier |
| `name` | string | Resource name |
| `created_at` | string (ISO 8601) | Creation timestamp |
| `updated_at` | string (ISO 8601) | Last update timestamp |

**Status Codes:**

| Code | Description |
|------|-------------|
| 200 | Success |
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Invalid or missing authentication |
| 403 | Forbidden - Insufficient permissions |
| 429 | Too Many Requests - Rate limit exceeded |
| 500 | Internal Server Error |

#### Get [Resource]

\`\`\`http
GET /v1/[resources]/:id
\`\`\`

**Description:**
Retrieves a specific [resource] by ID.

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Resource identifier |

**Example Request:**

\`\`\`bash
curl -H "Authorization: Bearer YOUR_API_KEY" \\
  https://api.example.com/v1/resources/res_123
\`\`\`

**Example Response:**

\`\`\`json
{
  "status": "success",
  "data": {
    "id": "res_123",
    "name": "Example Resource",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:00Z",
    "attributes": {
      "key": "value"
    }
  }
}
\`\`\`

**Status Codes:**

| Code | Description |
|------|-------------|
| 200 | Success |
| 404 | Not Found - Resource doesn't exist |
| 401 | Unauthorized |

#### Create [Resource]

\`\`\`http
POST /v1/[resources]
\`\`\`

**Description:**
Creates a new [resource].

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Resource name (max: 100 characters) |
| `description` | string | No | Resource description |
| `attributes` | object | No | Additional attributes |

**Example Request:**

\`\`\`bash
curl -X POST https://api.example.com/v1/resources \\
  -H "Authorization: Bearer YOUR_API_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{
    "name": "New Resource",
    "description": "A new example resource",
    "attributes": {
      "key": "value"
    }
  }'
\`\`\`

**Example Response:**

\`\`\`json
{
  "status": "success",
  "data": {
    "id": "res_124",
    "name": "New Resource",
    "description": "A new example resource",
    "created_at": "2025-01-15T11:00:00Z",
    "updated_at": "2025-01-15T11:00:00Z",
    "attributes": {
      "key": "value"
    }
  }
}
\`\`\`

**Status Codes:**

| Code | Description |
|------|-------------|
| 201 | Created successfully |
| 400 | Bad Request - Invalid data |
| 422 | Unprocessable Entity - Validation errors |

**Validation Errors:**

\`\`\`json
{
  "status": "error",
  "error": {
    "code": "validation_error",
    "message": "Validation failed",
    "details": [
      {
        "field": "name",
        "error": "Name is required"
      }
    ]
  }
}
\`\`\`

#### Update [Resource]

\`\`\`http
PATCH /v1/[resources]/:id
\`\`\`

**Description:**
Updates an existing [resource]. Only provided fields are updated.

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Resource identifier |

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | No | Resource name |
| `description` | string | No | Resource description |
| `attributes` | object | No | Additional attributes |

**Example Request:**

\`\`\`bash
curl -X PATCH https://api.example.com/v1/resources/res_123 \\
  -H "Authorization: Bearer YOUR_API_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{
    "name": "Updated Resource Name"
  }'
\`\`\`

**Example Response:**

\`\`\`json
{
  "status": "success",
  "data": {
    "id": "res_123",
    "name": "Updated Resource Name",
    "updated_at": "2025-01-15T11:30:00Z"
  }
}
\`\`\`

#### Delete [Resource]

\`\`\`http
DELETE /v1/[resources]/:id
\`\`\`

**Description:**
Deletes a [resource].

**Example Request:**

\`\`\`bash
curl -X DELETE https://api.example.com/v1/resources/res_123 \\
  -H "Authorization: Bearer YOUR_API_KEY"
\`\`\`

**Example Response:**

\`\`\`json
{
  "status": "success",
  "message": "Resource deleted successfully"
}
\`\`\`

## GraphQL API Reference

### Schema

\`\`\`graphql
type Query {
  resource(id: ID!): Resource
  resources(
    page: Int = 1
    perPage: Int = 20
    filter: ResourceFilter
  ): ResourceConnection
}

type Mutation {
  createResource(input: CreateResourceInput!): Resource
  updateResource(id: ID!, input: UpdateResourceInput!): Resource
  deleteResource(id: ID!): DeleteResult
}

type Resource {
  id: ID!
  name: String!
  description: String
  createdAt: DateTime!
  updatedAt: DateTime!
  attributes: JSON
}

input CreateResourceInput {
  name: String!
  description: String
  attributes: JSON
}

input ResourceFilter {
  name: String
  createdAfter: DateTime
}

type ResourceConnection {
  edges: [ResourceEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}
\`\`\`

### Example Queries

**Query Single Resource:**

\`\`\`graphql
query GetResource($id: ID!) {
  resource(id: $id) {
    id
    name
    description
    createdAt
    attributes
  }
}
\`\`\`

**Variables:**

\`\`\`json
{
  "id": "res_123"
}
\`\`\`

**Query Multiple Resources:**

\`\`\`graphql
query ListResources($page: Int, $perPage: Int, $filter: ResourceFilter) {
  resources(page: $page, perPage: $perPage, filter: $filter) {
    edges {
      node {
        id
        name
        createdAt
      }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
    totalCount
  }
}
\`\`\`

### Example Mutations

**Create Resource:**

\`\`\`graphql
mutation CreateResource($input: CreateResourceInput!) {
  createResource(input: $input) {
    id
    name
    createdAt
  }
}
\`\`\`

**Variables:**

\`\`\`json
{
  "input": {
    "name": "New Resource",
    "description": "Description here"
  }
}
\`\`\`

## Python Library API Reference

### Installation

\`\`\`bash
pip install [package-name]
\`\`\`

### Client Initialization

\`\`\`python
from [package_name] import Client

# Initialize client
client = Client(api_key="YOUR_API_KEY")

# With custom configuration
client = Client(
    api_key="YOUR_API_KEY",
    base_url="https://api.example.com/v1",
    timeout=30,
    max_retries=3
)
\`\`\`

### Core Classes

#### Client

\`\`\`python
class Client:
    """Main client for interacting with the API."""

    def __init__(
        self,
        api_key: str,
        base_url: str = "https://api.example.com/v1",
        timeout: int = 30,
        max_retries: int = 3
    ) -> None:
        """Initialize client.

        Args:
            api_key: API authentication key
            base_url: API base URL
            timeout: Request timeout in seconds
            max_retries: Maximum number of retry attempts
        """
        ...

    async def get_resource(self, resource_id: str) -> Resource:
        """Get a resource by ID.

        Args:
            resource_id: Resource identifier

        Returns:
            Resource object

        Raises:
            ResourceNotFoundError: If resource doesn't exist
            AuthenticationError: If authentication fails
            APIError: For other API errors
        """
        ...

    async def list_resources(
        self,
        page: int = 1,
        per_page: int = 20,
        filters: dict | None = None
    ) -> list[Resource]:
        """List resources with pagination.

        Args:
            page: Page number (1-indexed)
            per_page: Items per page (max: 100)
            filters: Optional filter dictionary

        Returns:
            List of Resource objects
        """
        ...
\`\`\`

#### Resource

\`\`\`python
from pydantic import BaseModel, Field
from datetime import datetime

class Resource(BaseModel):
    """Resource model."""

    id: str = Field(..., description="Unique identifier")
    name: str = Field(..., description="Resource name")
    description: str | None = Field(None, description="Resource description")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")
    attributes: dict | None = Field(None, description="Additional attributes")

    def update(self, **kwargs) -> None:
        """Update resource attributes.

        Args:
            **kwargs: Fields to update
        """
        ...

    async def delete(self) -> None:
        """Delete this resource."""
        ...
\`\`\`

### Usage Examples

**Synchronous Usage:**

\`\`\`python
from [package_name] import Client

client = Client(api_key="YOUR_API_KEY")

# Get resource
resource = client.get_resource("res_123")
print(resource.name)

# List resources
resources = client.list_resources(page=1, per_page=20)
for resource in resources:
    print(resource.name)

# Create resource
new_resource = client.create_resource(
    name="New Resource",
    description="Description"
)

# Update resource
new_resource.update(name="Updated Name")

# Delete resource
new_resource.delete()
\`\`\`

**Async Usage:**

\`\`\`python
import asyncio
from [package_name] import AsyncClient

async def main():
    async with AsyncClient(api_key="YOUR_API_KEY") as client:
        # Get resource
        resource = await client.get_resource("res_123")
        print(resource.name)

        # List resources
        resources = await client.list_resources(page=1, per_page=20)
        for resource in resources:
            print(resource.name)

asyncio.run(main())
\`\`\`

## Error Handling

### Error Response Format

\`\`\`json
{
  "status": "error",
  "error": {
    "code": "error_code",
    "message": "Human-readable error message",
    "details": {},
    "request_id": "req_abc123"
  }
}
\`\`\`

### Error Codes

| Code | HTTP Status | Description | Resolution |
|------|-------------|-------------|------------|
| `invalid_request` | 400 | Request format invalid | Check request format |
| `unauthorized` | 401 | Authentication failed | Check API key |
| `forbidden` | 403 | Insufficient permissions | Check account permissions |
| `not_found` | 404 | Resource not found | Verify resource ID |
| `validation_error` | 422 | Validation failed | Check input data |
| `rate_limit_exceeded` | 429 | Too many requests | Wait and retry |
| `internal_error` | 500 | Server error | Retry or contact support |

### Python Error Handling

\`\`\`python
from [package_name] import (
    Client,
    ResourceNotFoundError,
    ValidationError,
    RateLimitError,
    APIError
)

client = Client(api_key="YOUR_API_KEY")

try:
    resource = client.get_resource("res_123")
except ResourceNotFoundError:
    print("Resource not found")
except ValidationError as e:
    print(f"Validation error: {e.details}")
except RateLimitError:
    print("Rate limit exceeded, waiting...")
    time.sleep(60)
except APIError as e:
    print(f"API error: {e.message}")
\`\`\`

## Rate Limiting

### Rate Limits

| Plan | Requests per Minute | Requests per Hour |
|------|---------------------|-------------------|
| Free | 60 | 1,000 |
| Pro | 600 | 10,000 |
| Enterprise | Custom | Custom |

### Rate Limit Headers

\`\`\`http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1674567890
\`\`\`

### Handling Rate Limits

\`\`\`python
import time

def api_call_with_retry(client, func, *args, **kwargs):
    """Call API function with automatic retry on rate limit."""
    while True:
        try:
            return func(*args, **kwargs)
        except RateLimitError as e:
            wait_time = e.retry_after or 60
            print(f"Rate limited, waiting {wait_time} seconds...")
            time.sleep(wait_time)
\`\`\`

## Webhooks

### Webhook Events

| Event | Description |
|-------|-------------|
| `resource.created` | Resource was created |
| `resource.updated` | Resource was updated |
| `resource.deleted` | Resource was deleted |

### Webhook Payload

\`\`\`json
{
  "event": "resource.created",
  "timestamp": "2025-01-15T10:30:00Z",
  "data": {
    "id": "res_123",
    "name": "New Resource"
  }
}
\`\`\`

### Webhook Signature Verification

\`\`\`python
import hmac
import hashlib

def verify_webhook_signature(payload: bytes, signature: str, secret: str) -> bool:
    """Verify webhook signature.

    Args:
        payload: Request body bytes
        signature: X-Webhook-Signature header value
        secret: Webhook secret from dashboard

    Returns:
        True if signature is valid
    """
    expected = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
    return hmac.compare_digest(signature, expected)
\`\`\`

## Changelog

### v1.0.0 (2025-01-15)

- Initial API release
- Added resource CRUD operations
- Added authentication

## Related Documents

- [Architecture Documentation](./architecture-documentation-template.md)
- [README Template](./readme-template.md)
- [Security Best Practices](../core-rules/security/README.md)

## References

This template synthesizes patterns from:
- Foundation Worker: Python API patterns, Pydantic models
- Patterns Worker: Error handling, streaming patterns
- Security Worker: Authentication, authorization documentation
- Testing Worker: API testing documentation
