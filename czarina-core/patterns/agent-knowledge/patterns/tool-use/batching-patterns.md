# Batching Patterns

Strategies for combining multiple operations to improve efficiency.

---

## Parallel File Reading

### Pattern: Read Related Files Together

**Rule**: Read up to 5 related files in one operation.

**Example**:
```xml
<read_file>
<args>
  <file><path>service1.py</path></file>
  <file><path>service2.py</path></file>
  <file><path>service3.py</path></file>
  <file><path>test_service.py</path></file>
</args>
</read_file>
```

**Benefits**:
- Single round trip instead of 4
- Complete context available immediately
- 4x latency reduction

### When to Batch Read

**Good candidates**:
- Model + Service + API endpoint
- Implementation + Tests
- Configuration files
- Related components in same feature
- Parent + Child classes

**Example - Authentication Feature**:
```python
# Batch read for complete context
files = [
    "models/user.py",
    "services/auth_service.py",
    "api/auth_endpoints.py",
    "middleware/auth_middleware.py",
    "tests/test_auth.py"
]
```

---

## Batch Modifications

### Pattern: Group Related Changes

**Inefficient** ❌:
```
1. Modify models/user.py
2. Wait for confirmation
3. Modify services/auth.py
4. Wait for confirmation
5. Modify api/endpoints.py
6. Wait for confirmation
```

**Efficient** ✅:
```
1. Plan all changes
2. Apply to models/user.py
3. Apply to services/auth.py
4. Apply to api/endpoints.py
5. Single test run for complete feature
```

### Atomic Feature Changes

**Pattern**: Make all changes for a feature together, test once.

**Example**:
```
Feature: Add user profile picture

Changes:
1. Update User model (add profile_pic field)
2. Update auth service (handle upload)
3. Update API endpoint (new route)
4. Update tests (test upload)

Apply all → Test complete feature
```

---

## Grouped Searches

### Pattern: Search Multiple Patterns at Once

**Inefficient** ❌:
```
1. Search for "class User"
2. Search for "def authenticate"
3. Search for "validate_token"
```

**Efficient** ✅:
```
1. Search for "class User|def authenticate|validate_token"
   (using regex OR)
```

Or use structured approach:
```
1. Search in specific directory once
2. Filter results for multiple patterns
```

### Directory-Based Batching

**Pattern**: Search entire feature directory once.

**Example**:
```bash
# Instead of multiple targeted searches
# Search the entire auth module once
search_files(
    pattern=".*",
    path="services/auth/"
)

# Then read relevant files found
```

---

## Combined Command Execution

### Pattern: Chain Related Commands

**Inefficient** ❌:
```bash
cd backend
source venv/bin/activate
python -m pytest
deactivate
cd ..
```

**Efficient** ✅:
```bash
cd backend && source venv/bin/activate && python -m pytest; cd ..
```

**Even Better** (using project scripts):
```bash
./run-tests.sh backend
```

### Build and Test Pipeline

**Pattern**: Combine build, test, and verify steps.

**Example**:
```bash
# Single pipeline command
docker-compose build && \
docker-compose up -d && \
docker-compose exec backend python -m pytest && \
docker-compose logs --tail=50
```

---

## Batch Context Loading

### Pattern: Load Full Feature Context

**Scenario**: Understanding a complex feature.

**Approach**:
```
1. Identify all files in feature
2. Batch read all related files:
   - Models
   - Services
   - API endpoints
   - Tests
   - Configuration

3. Build complete mental model
4. Make informed decisions
```

**Example - Payment Processing**:
```python
context_files = [
    # Core logic
    "services/payment_service.py",
    "models/payment.py",
    "models/transaction.py",

    # Integration
    "integrations/stripe_client.py",
    "integrations/paypal_client.py",

    # API
    "api/payment_endpoints.py",

    # Tests
    "tests/test_payment_service.py",
    "tests/test_payment_integration.py"
]

# Read all at once for complete context
```

---

## Batch Error Checking

### Pattern: Validate Multiple Conditions Together

**Inefficient** ❌:
```
1. Check syntax errors
2. Fix
3. Check type errors
4. Fix
5. Check linting
6. Fix
```

**Efficient** ✅:
```bash
# Run all checks at once
python -m py_compile *.py && \
mypy . && \
flake8 . && \
black --check .

# Fix all issues found
# Re-run complete validation
```

---

## Response Batching

### Pattern: Return Complete Information

**When providing analysis**, include all relevant information:

**Incomplete** ❌:
```
"The function is in models/user.py"
[User asks: What does it do?]
"It validates user credentials"
[User asks: How is it called?]
"It's called from auth_service.py"
```

**Complete** ✅:
```
"The function is in models/user.py:45-67

It validates user credentials by:
1. Checking password hash
2. Verifying account status
3. Logging attempt

Called from:
- auth_service.py:123
- api/auth_endpoints.py:89

Related functions:
- hash_password() in utils/crypto.py
- check_account_status() in models/user.py
```

---

## Batch Testing

### Pattern: Test Multiple Components

**Inefficient** ❌:
```
pytest tests/test_user.py
pytest tests/test_auth.py
pytest tests/test_api.py
```

**Efficient** ✅:
```bash
# Test entire feature module
pytest tests/test_user*.py tests/test_auth*.py

# Or test by marker
pytest -m "auth"
```

---

## Real-World Examples

### The Symposium: Sage Identity Feature

**Task**: Understand sage identity system

**Batched Approach**:
```python
# Single batch read for complete understanding
files = [
    # Core models
    "backend/models/sage_identity.py",
    "backend/models/sage_metadata.py",

    # Services
    "backend/services/identity_service.py",
    "backend/services/opensearch_service.py",

    # API
    "backend/api/sage_endpoints.py",

    # Tests
    "backend/tests/test_identity_service.py"
]

# Result: Complete understanding in one operation
```

---

## Batch Size Guidelines

### File Reading

**Optimal batch sizes**:
- **Small files (<100 lines)**: Batch up to 5 files
- **Medium files (100-500 lines)**: Batch up to 3 files
- **Large files (>500 lines)**: Batch up to 2 files
- **Huge files (>1000 lines)**: Read individually with line ranges

### Command Execution

**Chain length**:
- **Fast commands**: Chain up to 5
- **Slow commands**: Chain 2-3
- **Interactive commands**: Don't chain

**Example**:
```bash
# Good: Fast commands chained
git add . && git commit -m "message" && git push

# Bad: Slow commands chained
npm install && npm run build && npm test
# Better: Run separately so you can see progress
```

---

## Best Practices

### Do's

- Batch read related files (up to 5)
- Chain fast commands with &&
- Load complete feature context at once
- Provide complete information in responses
- Group similar searches
- Test related components together

### Don'ts

- Don't batch unrelated files
- Don't chain interactive commands
- Don't exceed 5 files per batch
- Don't batch if individual results needed separately
- Don't chain long-running commands

---

## Related Patterns

- [Optimization Patterns](./optimization-patterns.md) - General optimization
- [Parallel Execution](./parallel-execution.md) - Concurrent operations
- [Caching Patterns](./caching-patterns.md) - Reusing results

---

**Source**: The Symposium development
