# Caching Patterns

Strategies for caching and reusing results to avoid redundant operations.

---

## When to Cache

### Mental Caching (Session Context)

**Pattern**: Remember information within a session to avoid re-reading.

**Good candidates for mental caching**:
- Project structure and layout
- File locations discovered through search
- Configuration values
- API patterns and conventions
- Test file locations

**Example**:
```
Session mental cache:
{
  "project_type": "FastAPI + OpenSearch",
  "api_dir": "backend/api/",
  "models_dir": "backend/models/",
  "services_dir": "backend/services/",
  "test_pattern": "tests/test_*.py",
  "control_script": "./control-script.sh"
}

Use this to navigate without repeated searches.
```

### File Content Caching

**Pattern**: Don't re-read unchanged files.

**Re-read when**:
- File was modified
- Stale information (>5 minutes)
- User explicitly requests
- Critical decision point

**Don't re-read when**:
- Just read in previous step
- Making decisions based on that read
- File unlikely to change (config, constants)

**Example**:
```
Just read config.py to get DATABASE_URL
→ Don't read it again 2 minutes later
→ Use the information from first read
```

---

## Context Retention

### Build Cumulative Understanding

**Pattern**: Each read builds on previous knowledge.

**First read** - Structure:
```python
# Read models/user.py
"User model has fields: id, email, password_hash"
```

**Second read** - Related code:
```python
# Read services/auth_service.py
"Auth service uses User model from first read"
"Methods: authenticate(), create_user(), validate_token()"
```

**Third read** - Integration:
```python
# Read api/auth_endpoints.py
"API uses auth_service methods we just learned about"
"Endpoints: POST /login, POST /register, GET /verify"
```

**Result**: Complete mental model without re-reading.

---

## Avoiding Redundant Reads

### Pattern: Read Once, Use Multiple Times

**Inefficient** ❌:
```
1. Read config.py to get API_KEY
   → Use API_KEY
2. Read config.py to get DATABASE_URL
   → Use DATABASE_URL
3. Read config.py to get CACHE_TTL
   → Use CACHE_TTL
```

**Efficient** ✅:
```
1. Read config.py once
   → Extract: API_KEY, DATABASE_URL, CACHE_TTL
   → Use all values as needed
```

### Pattern: Search Once, Reference Multiple Times

**Inefficient** ❌:
```
1. Search for "User class"
   → Find in models/user.py
2. Later: Search for "User class" again
   → Find in models/user.py (again)
```

**Efficient** ✅:
```
1. Search for "User class" once
   → Find in models/user.py
   → Remember location
2. Later: Directly reference models/user.py
```

---

## Cache Invalidation

### When to Invalidate Cache

**Invalidate when**:
- File was modified by you
- User reports unexpected behavior
- Errors suggest stale information
- Long time elapsed (>session)

**Example**:
```
Cached: User model has fields id, email

[Modify User model to add 'role' field]

Cache invalidated: Re-read to confirm changes
```

### Automatic Invalidation

**Pattern**: Track what you've modified.

```
Modified files this session:
- models/user.py (added role field)
- services/auth_service.py (updated authenticate)

Cached knowledge about these files is stale.
Next reference: Re-read to verify changes.
```

---

## Smart Re-Reading

### Pattern: Targeted Re-Reads

**Don't re-read entire file** if you only changed one function.

**Inefficient** ❌:
```
1. Read entire 500-line file
2. Modify one function
3. Re-read entire 500-line file
```

**Efficient** ✅:
```
1. Read entire file
2. Modify one function
3. Re-read just that function's line range to verify
```

### Pattern: Verify Critical Changes

**When to verify**:
- Syntax-sensitive changes
- Complex refactoring
- Multiple related changes
- User-reported issues

**Example**:
```python
# Made change to add parameter
def authenticate(username: str, password: str, mfa_token: str = None):
    ...

# Verify:
# - Function signature correct
# - All callers updated
# - Tests updated

Re-read:
- services/auth_service.py (function definition)
- api/auth_endpoints.py (callers)
- tests/test_auth.py (test cases)
```

---

## Session State Management

### Pattern: Maintain Session Context

**Track during session**:
```python
session_state = {
    "project_structure": {
        "backend": ["models/", "services/", "api/"],
        "tests": ["tests/"]
    },

    "key_files": {
        "config": "config.py",
        "main": "backend/api/main.py",
        "user_model": "backend/models/user.py"
    },

    "conventions": {
        "test_pattern": "test_*.py",
        "async_services": True,
        "type_hints": "required"
    },

    "recent_changes": [
        "models/user.py",
        "services/auth_service.py"
    ]
}
```

**Use this state** to make smart decisions about when to read vs. use cached knowledge.

---

## Preemptive Caching

### Pattern: Read Likely-Needed Files Early

**Scenario**: Implementing new feature

**Approach**:
```
1. Read all related files upfront (batch read)
2. Cache complete context
3. Make all changes based on cached context
4. Verify with targeted re-reads only
```

**Example**:
```python
# Implementing user profile feature

# Preemptive batch read:
files = [
    "models/user.py",           # Will need to modify
    "services/user_service.py",  # Will need to modify
    "api/user_endpoints.py",     # Will need to modify
    "tests/test_user.py"         # Will need to update
]

# Now have complete context cached
# Make all changes without re-reading
```

---

## Pattern Recognition

### Pattern: Learn Project Patterns

**Cache recognized patterns**:
```
Observed patterns in this project:

1. File naming:
   - Models: singular noun (user.py, post.py)
   - Services: model_service.py
   - API: model_endpoints.py
   - Tests: test_model.py

2. Code patterns:
   - Services use async/await
   - All services inherit from BaseService
   - Tests use pytest fixtures

3. Architecture:
   - 3-tier: Model → Service → API
   - OpenSearch for persistence
   - Redis for caching

Use these patterns to predict file locations and structure.
```

### Predictive Reading

**Use patterns to predict** what you'll need:

```
Task: Add new "Comment" model

Based on observed patterns, will need:
- models/comment.py (new)
- services/comment_service.py (new)
- api/comment_endpoints.py (new)
- tests/test_comment.py (new)

Also need to read:
- models/user.py (reference pattern)
- models/post.py (similar model)
- services/base_service.py (inheritance)

Batch read existing files for patterns,
then create new files following same patterns.
```

---

## Real-World Examples

### The Symposium: Identity Service Pattern

**Pattern observed**:
```python
# All identity operations follow pattern:
# 1. Read from OpenSearch
# 2. Process/transform
# 3. Cache in Redis
# 4. Return result

# Once learned, don't re-read for each operation
# Apply pattern to new operations
```

**Cached knowledge**:
```
Identity Service patterns:
- Index name: sage-identities
- ID format: sage_name (lowercase)
- Cache TTL: 300 seconds
- Error handling: Try cache first, then OpenSearch
```

---

## Best Practices

### Do's

- Build mental model of project
- Remember file locations
- Cache project conventions
- Track modified files
- Use patterns to predict structure
- Batch read for complete context

### Don'ts

- Don't re-read unchanged files
- Don't search for known locations
- Don't ignore patterns you've observed
- Don't forget what you just read
- Don't invalidate cache unnecessarily

---

## Cache Warmup Strategy

### Start of Session

**Warmup reads**:
```
1. Read project README (structure, conventions)
2. Read main entry point (architecture)
3. Read core configuration (settings)
4. Scan directory structure (organization)

Cache this foundation → Efficient session
```

---

## Related Patterns

- [Optimization Patterns](./optimization-patterns.md) - When to use cache
- [Batching Patterns](./batching-patterns.md) - Preemptive batch reads
- [Tool Selection](./tool-selection.md) - Read vs. search decisions

---

**Source**: The Symposium development
