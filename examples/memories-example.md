# Project Memory: Example Web Application

## Architectural Core

### Component Dependencies
- Frontend React app depends on backend API (must be running on port 8000)
- Backend Express server depends on PostgreSQL database
- Redis cache depends on backend startup (connection pooling initialized)
- Auth middleware must load before any protected routes
- Database migrations run automatically on server startup (via docker-compose)

### Known Couplings
- Frontend build embeds API URL at build time (not runtime configurable)
  - Changing backend port requires frontend rebuild
  - Affected files: frontend/.env, backend/config.js, nginx.conf
- UI re-renders can race with token refresh → intermittent auth failures
  - Workaround: debounce token refresh, add retry logic in API client
- Docker network mode affects RabbitMQ connection strings
  - bridge mode: use container name
  - host mode: use localhost

### Critical Constraints
- All API calls MUST use /api prefix for reverse proxy routing
- Database connection pool size: 10-50 (DB_POOL_SIZE env var, never hardcode)
- All database queries MUST be parameterized (no string interpolation)
- Worker processes: Must be odd number for quorum (3, 5, or 7)
- Session timeout: 30 minutes (adjustable via SESSION_TIMEOUT env)
- File uploads: Max 10MB (enforced in nginx and backend)

---

## Project Knowledge

### Session: 2025-12-15 - Database Migration Failure

**What We Did**
- Attempted to add full-text search indexes to articles table
- Migration ran successfully in dev environment
- Failed in staging with error: "text search configuration 'english' does not exist"

**Root Cause**
- Dev environment had postgresql-contrib package installed
- Staging environment was using base PostgreSQL image
- Migration assumed pg_trgm extension was available
- No extension availability check in migration

**Solution**
1. Updated Dockerfile to install postgresql-contrib
2. Added migration step: `CREATE EXTENSION IF NOT EXISTS pg_trgm`
3. Added extension dependency documentation to README
4. Created pre-migration checklist for extension requirements

**Prevention**
- ALWAYS check extension availability before using PostgreSQL features
- Maintain dev/staging environment parity checklist
- Test migrations on clean database, not just existing dev DB
- Document all extension dependencies in deployment docs

### Session: 2025-12-20 - Redis Connection Pool Exhaustion

**Problem**
App crashed in production with error: "Redis connection pool exhausted"
Load was normal (~100 requests/sec), well within capacity

**Root Cause**
- Default connection pool size was 10
- Background jobs were opening connections but not releasing them
- Proper cleanup only in happy path, not error path
- No connection timeout configured (connections held indefinitely)

**Solution**
1. Increased pool size to 50 (REDIS_POOL_SIZE=50 in .env)
2. Added try/finally blocks to ensure connection release in all paths
3. Implemented connection timeout (5 seconds)
4. Added connection pool metrics to monitoring dashboard

**Key Learning**
- ALWAYS use try/finally for resource cleanup (connections, files, locks)
- Monitor connection pool metrics in production
- Load test background job scenarios, not just API endpoints
- Set explicit timeouts for ALL external resources

### Session: 2025-12-22 - Authentication Token Refresh Race Condition

**Problem**
Users reported intermittent "Unauthorized" errors despite being logged in
Errors occurred randomly, couldn't reproduce consistently
Only happened during active usage, not on page load

**Investigation**
- Logs showed token expiry warnings during concurrent API calls
- Frontend made multiple parallel requests on user actions
- Each request independently checked token expiry
- Multiple simultaneous refresh attempts → race condition
- Second refresh invalidated first refresh's token

**Solution**
1. Implemented token refresh lock (only one refresh at a time)
2. Queue concurrent requests during refresh
3. Add 30-second buffer to token expiry check
4. Debounce token refresh checks (max once per 10 seconds)

**Code Pattern**
```javascript
let refreshPromise = null;

async function getValidToken() {
  if (tokenExpiresIn() > 30) return currentToken;
  
  if (!refreshPromise) {
    refreshPromise = refreshToken().finally(() => {
      refreshPromise = null;
    });
  }
  
  return refreshPromise;
}
```

**Remember**
- Concurrent operations on shared state need synchronization
- Add buffer time to expiry checks (don't wait until last second)
- Queue operations during state transitions
- Test race conditions with parallel request tools

---

## Patterns and Decisions

### Decision: REST vs GraphQL for API

**Context**
- Frontend team requested GraphQL for query flexibility
- Backend team had no GraphQL experience
- Current REST API working well, mature ecosystem

**Decision**
Stuck with REST for now, revisit GraphQL in 6 months

**Rationale**
1. Team has 3 years REST experience, 0 GraphQL experience
2. REST working well for current needs (mobile app + web frontend)
3. GraphQL adds complexity (schema, resolvers, N+1 queries)
4. Migration cost high (rewrite all endpoints)
5. No immediate pain point that GraphQL solves

**Revisit If**
- Frontend complexity grows significantly (many custom views)
- Need for flexible querying becomes critical
- Team gains GraphQL experience on side projects
- New hire with GraphQL expertise joins

**Date Decided:** 2025-11-10
**Participants:** Backend team, frontend team, architect

### Pattern: Error Response Format

**Format**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email address is invalid",
    "details": {
      "field": "email",
      "value": "not-an-email"
    }
  }
}
```

**Why This Format**
- Consistent across all endpoints (easy to parse on frontend)
- Machine-readable error codes (can map to user-friendly messages)
- Human-readable messages (useful in logs, debugging)
- Optional details for context-specific information

**Exceptions**
None - ALL errors use this format, even 500 Internal Server Error

**Implemented:** 2025-10-15

### Pattern: Database Naming Conventions

**Tables**
- Plural snake_case: `users`, `order_items`, `shopping_carts`

**Columns**
- Snake_case: `created_at`, `email_address`, `is_active`

**Foreign Keys**
- Format: `{table_singular}_id`
- Examples: `user_id`, `order_id`, `product_id`

**Indexes**
- Format: `idx_{table}_{columns}`
- Examples: `idx_users_email`, `idx_orders_user_id_created_at`

**Why**
- Consistent, predictable naming
- Easy to generate migrations
- Works well with ORM conventions
- Readable in raw SQL queries

**Enforced:** Schema linter in CI/CD

---

## Technical Debt

### TODO: Implement Database Index Versioning

**Problem**
OpenSearch rejected index mapping update in production (Session 2025-12-08)
Cannot change field types in existing indexes without recreation

**Proposed Solution**
- Implement index-per-version pattern: `articles_v1`, `articles_v2`
- Create migration path for breaking changes
- Maintain backward compatibility during transitions
- Auto-cleanup old indexes after migration complete

**Priority:** Medium
**Estimated Effort:** 2-3 days
**Assigned:** Backend team

### TODO: Add Connection Pool Metrics

**Problem**
Redis pool exhaustion not detected until crash (Session 2025-12-20)
No visibility into pool utilization

**Proposed Solution**
- Add metrics: pool_size, active_connections, idle_connections
- Alert when utilization > 80%
- Track connection acquisition latency
- Dashboard for pool health

**Priority:** High
**Estimated Effort:** 1 day
**Assigned:** DevOps team

---

## Environment-Specific Notes

### Production
- Database: PostgreSQL 14.5 (RDS instance)
- Redis: Elasticache 6.2
- Workers: 5 processes (odd number for quorum)
- Connection pool: 50 (learned from Session 2025-12-20)

### Staging
- Database: PostgreSQL 14.5 (docker)
- Redis: Redis 6.2 (docker)
- Workers: 3 processes
- Connection pool: 20

### Development
- Database: PostgreSQL 14.5 (docker-compose)
- Redis: Redis 6.2 (docker-compose)
- Workers: 1 process
- Connection pool: 10

**Critical:** Staging now has postgresql-contrib (learned from Session 2025-12-15)
