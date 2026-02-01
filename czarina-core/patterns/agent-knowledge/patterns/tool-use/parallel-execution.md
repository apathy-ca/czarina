# Parallel Execution Patterns

Executing independent operations simultaneously for maximum efficiency.

---

## Core Principle

**When operations are independent**, execute them in parallel to minimize total time.

**Total time (sequential)**: T1 + T2 + T3 + T4
**Total time (parallel)**: max(T1, T2, T3, T4)

---

## Parallel File Reads

### Pattern: Read Multiple Files Simultaneously

**Sequential** ❌:
```
read service1.py    [1s]
read service2.py    [1s]
read service3.py    [1s]
Total: 3 seconds
```

**Parallel** ✅:
```
read [service1.py, service2.py, service3.py]  [1s]
Total: 1 second
```

### Implementation

Most AI coding assistants support batch file operations:

```xml
<read_file>
  <args>
    <file><path>models/user.py</path></file>
    <file><path>models/post.py</path></file>
    <file><path>models/comment.py</path></file>
  </args>
</read_file>
```

---

## When to Use Parallel Execution

### Independent Operations (Parallelize)

**Safe to run in parallel**:
- Reading different files
- Searching different directories
- Independent command executions
- Multiple API calls (non-mutating)
- Validation checks

**Example**:
```python
# These are independent, can run in parallel:
- Read models/user.py
- Read services/auth_service.py
- Search for "validate" in tests/
```

### Dependent Operations (Sequential)

**Must run sequentially**:
- Read file → Modify file
- Create resource → Use resource
- Install dependency → Import dependency
- Run migration → Query new schema

**Example**:
```python
# These depend on each other, must be sequential:
1. Create database table
2. Insert data into table
3. Query data from table
```

---

## Parallel Searches

### Pattern: Search Multiple Locations

**Sequential** ❌:
```
search "UserService" in services/
search "UserService" in api/
search "UserService" in tests/
Total: 3 operations
```

**Parallel** ✅:
```
search "UserService" in [services/, api/, tests/]
Total: 1 operation (with path filters)
```

Or use concurrent search if tool supports:
```
[
  search "UserService" in services/,
  search "UserService" in api/,
  search "UserService" in tests/
]
(All execute simultaneously)
```

---

## Parallel Command Execution

### Background Jobs

**Pattern**: Run independent commands in parallel.

```bash
# Sequential (slow)
npm run lint    # 10s
npm run test    # 30s
npm run build   # 20s
Total: 60s

# Parallel (fast)
npm run lint & npm run test & npm run build
wait
Total: ~30s (longest task)
```

### Concurrent Testing

```bash
# Test different modules in parallel
pytest tests/unit/ &
pytest tests/integration/ &
pytest tests/e2e/ &
wait

# Or use pytest-xdist for automatic parallelization
pytest -n auto
```

---

## Dependency Management

### Dependency Graph

**Pattern**: Execute in parallel respecting dependencies.

```
Task dependency graph:

    A
   / \
  B   C    (B and C can run in parallel after A)
   \ /
    D      (D waits for both B and C)
```

**Execution**:
```
1. Run A (alone)
2. Run B and C (parallel)
3. Wait for both to complete
4. Run D (alone)
```

### Example: Feature Implementation

```
Dependencies:
- Read files: All can be parallel
- Make changes: Must wait for reads
- Run tests: Must wait for changes

Execution:
1. Parallel read:
   - models/user.py
   - services/auth.py
   - api/endpoints.py

2. Sequential changes (depend on reads):
   - Modify models/user.py
   - Modify services/auth.py
   - Modify api/endpoints.py

3. Parallel tests (independent):
   - Unit tests
   - Integration tests
```

---

## Batching for Parallelism

### Pattern: Batch Read Then Process

**Approach**:
```
1. Identify all files needed
2. Batch read all in parallel
3. Process results simultaneously
```

**Example**:
```python
# Task: Understand authentication flow

# Step 1: Parallel read
files = await read_files([
    "models/user.py",
    "services/auth_service.py",
    "api/auth_endpoints.py",
    "middleware/auth_middleware.py"
])

# Step 2: Process all together
# - Identify auth flow
# - Find dependencies
# - Map function calls
```

---

## Real-World Examples

### The Symposium: Sage System Analysis

**Task**: Understand how sage identities work

**Parallel approach**:
```python
# Phase 1: Parallel read (all independent)
batch_read([
    "models/sage_identity.py",
    "services/identity_service.py",
    "services/opensearch_service.py",
    "api/sage_endpoints.py"
])

# Phase 2: Analyze (all data available)
- Map identity lifecycle
- Identify storage strategy
- Document API surface
```

**Time saved**: 4 seconds (4 files) → 1 second (batch)

---

## Parallel Analysis

### Pattern: Multi-Aspect Analysis

**When analyzing code**, check multiple aspects in parallel:

```
Analyze function for:
- Correctness (logic review)
- Performance (complexity analysis)
- Security (vulnerability scan)
- Style (code quality)

All can be done simultaneously on same code.
```

---

## Error Handling in Parallel Execution

### Fail-Fast vs. Fail-Slow

**Fail-Fast** (stop on first error):
```python
# Used when operations are critical
try:
    results = await parallel_execute([op1, op2, op3])
except FirstError as e:
    # Stop all operations
    raise
```

**Fail-Slow** (collect all errors):
```python
# Used when want to see all issues
results = await parallel_execute([op1, op2, op3])
errors = [r for r in results if r.is_error()]

if errors:
    # Report all errors together
    raise MultipleErrors(errors)
```

### Pattern: Parallel with Fallback

```python
# Try multiple sources in parallel, use first success
results = await parallel_execute([
    read_from_cache(),
    read_from_database(),
    read_from_api()
])

# Use first successful result
return next(r for r in results if r.success)
```

---

## Limits on Parallelism

### Don't Over-Parallelize

**Issues with too much parallelism**:
- Resource exhaustion
- Rate limiting
- Complexity
- Debugging difficulty

**Guidelines**:
- **File reads**: Up to 5 in parallel
- **Commands**: Up to 3 in parallel
- **API calls**: Respect rate limits
- **Searches**: 2-3 concurrent searches

### Example: Too Much Parallelism

**Bad** ❌:
```python
# Reading 20 files in one batch
read_files([file1, file2, ..., file20])
# May hit memory limits or timeout
```

**Better** ✅:
```python
# Read in batches of 5
batch1 = read_files([file1, file2, file3, file4, file5])
batch2 = read_files([file6, file7, file8, file9, file10])
# ...
```

---

## Parallelism Patterns by Task Type

### Code Reading

```
Independent (parallel):
- Different modules
- Different layers (model, service, API)
- Tests vs. implementation

Dependent (sequential):
- Base class before derived
- Dependencies before dependents
```

### Code Modification

```
Independent (parallel):
- Different files
- Different functions in same file (if tool supports)

Dependent (sequential):
- Same file modifications
- Interface change → Implementation update
```

### Testing

```
Independent (parallel):
- Unit tests (if isolated)
- Different test modules
- Different test categories

Dependent (sequential):
- Setup → Test → Teardown
- Integration tests (if shared state)
```

---

## Measuring Parallel Efficiency

### Speedup Formula

```
Speedup = Sequential Time / Parallel Time

Ideal speedup with N operations = N
Actual speedup usually < N due to overhead
```

**Example**:
```
Sequential: 4 file reads × 1s each = 4s
Parallel: 4 file reads at once = 1.2s
Speedup: 4s / 1.2s = 3.3x

(Not quite 4x due to overhead, but still excellent)
```

---

## Best Practices

### Do's

- Parallelize independent operations
- Batch file reads (up to 5)
- Run independent tests concurrently
- Use background jobs for independent commands
- Respect dependencies
- Handle errors appropriately

### Don'ts

- Don't parallelize dependent operations
- Don't exceed reasonable parallelism (5 files max)
- Don't ignore execution order when it matters
- Don't forget error handling
- Don't over-complicate simple sequential tasks

---

## Quick Decision Tree

```
Are operations independent?
├─ YES → Run in parallel
│  └─ How many operations?
│     ├─ 2-5 → Parallelize
│     └─ >5 → Batch into groups of 5
└─ NO → Run sequentially
   └─ Respect dependency order
```

---

## Related Patterns

- [Batching Patterns](./batching-patterns.md) - Grouping for parallel execution
- [Optimization Patterns](./optimization-patterns.md) - When to parallelize
- [Tool Selection](./tool-selection.md) - Which operations support parallel

---

**Source**: The Symposium development
