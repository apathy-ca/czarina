# Tool Use Optimization Patterns

General strategies for optimizing AI coding assistant tool usage.

---

## Minimize Round Trips

### Principle

Each interaction with a tool has latency. Minimize the number of separate tool calls.

**Inefficient** ❌:
```
1. Read file A
2. Wait for response
3. Read file B
4. Wait for response
5. Read file C
6. Wait for response
```

**Efficient** ✅:
```
1. Read files A, B, and C in parallel
2. Wait for single response with all content
```

**Impact**: 3x faster by reducing from 3 round trips to 1.

---

## Choose the Right Tool

### File Reading Decision Tree

```
Need to read a file?
├─ Know exact file path?
│  └─ YES → Use read_file
│     └─ Multiple related files?
│        └─ YES → Batch read (up to 5 files)
│        └─ NO → Single read
└─ NO → Use search_files
   └─ Find files first, then batch read
```

### File Modification Decision Tree

```
Need to modify a file?
├─ Small targeted change (1-10 lines)?
│  └─ Use apply_diff or edit
├─ Adding new content to existing file?
│  └─ Use insert_content
├─ Complete section rewrite?
│  └─ Use apply_diff with larger context
└─ New file or complete rewrite?
   └─ Use write_to_file
```

### Search Decision Tree

```
Need to find code?
├─ Know the exact file?
│  └─ Use read_file (faster)
├─ Know general location (directory)?
│  └─ Use search_files with path filter
├─ Know file type?
│  └─ Use search_files with extension filter
└─ No idea where it is?
   └─ Use broad search_files, then narrow
```

---

## Understand Tool Capabilities

### Read File Capabilities

**What it can do**:
- Read multiple files in one call
- Read specific line ranges
- Read binary files (with appropriate handling)
- Follow symlinks

**What it cannot do**:
- Search within files (use grep/search instead)
- Filter content (read full file, process in context)
- Read directories (use list_directory)

### Search Capabilities

**What it can do**:
- Regex pattern matching
- File type filtering
- Path-based filtering
- Case-insensitive search
- Multi-line pattern matching

**What it cannot do**:
- Fuzzy matching (be specific)
- Natural language queries (use regex)
- Performance optimization on huge repos (be targeted)

---

## Avoid Redundant Operations

### Cache Read Results Mentally

**Inefficient** ❌:
```
1. Read config.py to check setting
2. Make decision based on setting
3. Read config.py again to verify
```

**Efficient** ✅:
```
1. Read config.py once
2. Make all decisions based on that read
3. Only re-read if file might have changed
```

### Don't Re-Search for Known Information

**Inefficient** ❌:
```
1. Search for "User class"
2. Find it in models/user.py
3. Later search for "User class" again
```

**Efficient** ✅:
```
1. Search for "User class" once
2. Remember it's in models/user.py
3. Use read_file(models/user.py) for future access
```

---

## Batch Related Operations

### Reading Related Files

**Pattern**: When analyzing a feature, read all related files together.

**Example**:
```
Analyzing user authentication?
Read together:
- models/user.py
- services/auth_service.py
- api/auth_endpoints.py
- tests/test_auth.py
```

**Benefit**: Complete context in one round trip.

### Making Related Changes

**Pattern**: When changes span multiple files, prepare all changes before applying.

**Inefficient** ❌:
```
1. Modify models/user.py
2. Test
3. Modify services/auth_service.py
4. Test
5. Modify api/auth_endpoints.py
6. Test
```

**Efficient** ✅:
```
1. Read all affected files
2. Plan all changes
3. Apply all changes in sequence
4. Test complete feature
```

---

## Use Appropriate Granularity

### File Reading Granularity

**Too Coarse** ❌:
```
Read entire 5000-line file when only need one function
```

**Too Fine** ❌:
```
Read file in 50-line chunks, making 20 separate reads
```

**Just Right** ✅:
```
Read specific line range containing the function
OR read whole file if under 1000 lines
```

### Search Granularity

**Too Broad** ❌:
```
Search for "user" (thousands of results)
```

**Too Narrow** ❌:
```
Search for exact line: "def authenticate_user(username: str, password: str) -> bool:"
(might miss if formatting differs)
```

**Just Right** ✅:
```
Search for "def authenticate_user" (specific enough, flexible enough)
```

---

## Leverage Context

### Build on Previous Tool Results

**Pattern**: Use information from one tool call to optimize the next.

**Example**:
```
1. search_files("API endpoint")
   → Finds: api/v1/users.py, api/v2/users.py
2. read_file([api/v1/users.py, api/v2/users.py])
   → Read both versions to compare
3. apply_diff to api/v2/users.py
   → Make targeted change based on comparison
```

### Maintain Mental Model

**Pattern**: Build understanding incrementally rather than repeatedly searching.

**Session Mental Model**:
```
Project structure discovered:
- API: api/
- Models: models/
- Services: services/
- Tests: tests/
- Config: config.py, .env

Key files:
- User model: models/user.py
- Auth service: services/auth_service.py
- Main API: api/main.py
```

Use this model to navigate efficiently without repeated searches.

---

## Command Execution Optimization

### Use Project Control Scripts

**Inefficient** ❌:
```bash
# Manual commands
docker-compose down
docker-compose build
docker-compose up -d
docker-compose logs -f
```

**Efficient** ✅:
```bash
# Project control script
./control-script.sh restart --build --logs
```

**Benefits**:
- One command instead of four
- Handles edge cases
- Consistent behavior
- Project-specific optimizations

### Chain Related Commands

**Inefficient** ❌:
```
1. Run: cd backend
2. Run: python -m pytest
3. Run: cd ..
```

**Efficient** ✅:
```
1. Run: cd backend && python -m pytest && cd ..
```

Or better:
```
1. Run: python -m pytest backend/
```

---

## Performance Considerations

### Parallel vs. Sequential

**Use Parallel When**:
- Operations are independent
- No data dependencies between them
- Order doesn't matter

**Use Sequential When**:
- Operations depend on each other
- Order matters
- Shared resource access

**Example**:
```
Parallel (independent):
- Read models/user.py
- Read models/post.py
- Read models/comment.py

Sequential (dependent):
- Create database migration
- Apply migration
- Verify migration
```

---

## Real-World Examples

### The Symposium: Feature Implementation

**Task**: Add new endpoint to API

**Optimized Approach**:
```
1. Batch read for context:
   - api/main.py (existing endpoints)
   - models/sage.py (data model)
   - services/sage_service.py (business logic)

2. Plan changes based on patterns observed

3. Sequential application:
   - Add endpoint to api/main.py
   - Add method to services/sage_service.py
   - Add test to tests/test_api.py

4. Single test run to verify all changes
```

**Result**: Complete feature in 4 tool operations instead of 10+.

---

## Best Practices

### Do's

- Batch read related files (up to 5)
- Use control scripts when available
- Build mental model of project structure
- Chain related commands
- Read whole small files (<1000 lines)
- Use specific search patterns

### Don'ts

- Don't read same file multiple times
- Don't search when you know the location
- Don't make changes without reading first
- Don't execute commands without verifying context
- Don't read huge files in entirety (use ranges)
- Don't use overly broad search patterns

---

## Related Patterns

- [Batching Patterns](./batching-patterns.md) - Combining operations
- [Parallel Execution](./parallel-execution.md) - Running concurrently
- [Tool Selection](./tool-selection.md) - Choosing the right tool

---

**Source**: The Symposium development
