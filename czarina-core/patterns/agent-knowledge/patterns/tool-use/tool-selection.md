# Tool Selection Patterns

Choosing the appropriate tool for each task to maximize efficiency.

---

## Core Principle

**Right tool for the job**: Each tool is optimized for specific tasks. Using the wrong tool wastes time.

---

## File Reading vs. Search

### When to Use Read

**Use `read_file` when**:
- Know exact file path
- Need complete file content
- Reading multiple known files
- Following references from previous reads

**Example**:
```
Know the file: models/user.py
→ Use: read_file("models/user.py")
```

### When to Use Search

**Use `search_files` when**:
- Don't know which file contains code
- Looking for pattern across codebase
- Need to find all occurrences
- Exploring unfamiliar codebase

**Example**:
```
Looking for: "authenticate" function
Unknown location
→ Use: search_files(pattern="def authenticate")
→ Find: services/auth_service.py
→ Then: read_file("services/auth_service.py")
```

### Decision Tree

```
Need code/content?
├─ Know exact file path?
│  └─ YES → read_file
└─ NO → search_files first
   └─ Then read found files
```

---

## File Modification Tools

### Apply Diff / Edit

**When to use**:
- Small targeted changes (1-10 lines)
- Replacing specific code
- Modifying existing functions
- Updating configuration values

**Example**:
```python
# Change one parameter
OLD:
def authenticate(username: str, password: str):

NEW:
def authenticate(username: str, password: str, mfa_token: str = None):
```

**Advantages**:
- Precise
- Shows exactly what changed
- Less error-prone for small changes

### Insert Content

**When to use**:
- Adding new code to existing file
- Inserting new function
- Adding imports
- Appending to file

**Example**:
```python
# Add new method to existing class
INSERT at line 45:
    def validate_email(self, email: str) -> bool:
        """Validate email format."""
        return "@" in email and "." in email
```

**Advantages**:
- Clear insertion point
- Don't need surrounding context
- Good for additions

### Write to File

**When to use**:
- Creating new file
- Complete file rewrite
- File is very simple (<50 lines)
- Replacing entire file content

**Example**:
```python
# Create new file
write_to_file("models/comment.py", content="""
from datetime import datetime
from typing import Optional

class Comment:
    def __init__(self, text: str, author: str):
        self.text = text
        self.author = author
        self.created_at = datetime.now()
""")
```

**Advantages**:
- Clean slate
- No merge issues
- Complete control

### Decision Tree

```
Need to modify file?
├─ File exists?
│  ├─ YES → Change size?
│  │  ├─ Small (1-10 lines) → apply_diff/edit
│  │  ├─ Medium (10-50 lines) → apply_diff
│  │  └─ Large/Complete rewrite → write_to_file
│  └─ NO → write_to_file (new file)
```

---

## Command Execution

### Control Scripts vs. Raw Commands

**Use control scripts when**:
- Project provides them
- Complex setup needed
- Want consistent behavior
- Multiple steps required

**Example**:
```bash
# ✅ PREFERRED
./control-script.sh restart --build

# Instead of:
# ❌ MANUAL
docker-compose down
docker-compose build
docker-compose up -d
```

**Advantages**:
- One command vs. many
- Handles edge cases
- Project-specific logic
- Consistent across team

### Raw Commands

**Use raw commands when**:
- No control script exists
- Simple one-off operation
- Need specific flags
- Debugging

**Example**:
```bash
# Simple operations
ls -la
cat file.txt
docker ps

# Specific operations
git log --oneline -5
pytest -v -k "test_auth"
```

---

## Search Patterns

### Grep/Regex Search

**When to use**:
- Searching file contents
- Pattern matching
- Finding all occurrences
- Case-insensitive search

**Example**:
```bash
# Find all TODO comments
grep -r "TODO" src/

# Find function definitions
grep -r "def authenticate" .
```

### File Name Search

**When to use**:
- Finding files by name
- Locating specific file types
- Directory structure exploration

**Example**:
```bash
# Find all test files
find . -name "test_*.py"

# Find config files
find . -name "*.config.js"
```

### Full-Text Search

**When to use**:
- Complex patterns
- Multi-line patterns
- Context-aware search
- Fuzzy matching

**Example**:
```bash
# Find function and its usage
rg "def process_payment" -A 5
```

---

## Navigation Tools

### Direct Path Access

**When to use**:
- Know exact location
- Following documentation
- Using cached knowledge

**Example**:
```
read_file("/app/backend/services/auth_service.py")
```

### Directory Listing

**When to use**:
- Exploring structure
- Finding related files
- Understanding organization

**Example**:
```bash
ls -la backend/services/
# → See all service files
```

### Tree View

**When to use**:
- Understanding hierarchy
- New to project
- Documentation purposes

**Example**:
```bash
tree backend/ -L 2
```

---

## Testing Tools

### Unit Test Runner

**When to use**:
- Testing specific functionality
- Fast feedback
- Isolated tests

**Example**:
```bash
pytest tests/unit/test_auth.py
```

### Integration Test Runner

**When to use**:
- Testing components together
- Database interactions
- API testing

**Example**:
```bash
pytest tests/integration/ -v
```

### Full Test Suite

**When to use**:
- Pre-commit verification
- CI/CD pipeline
- Complete validation

**Example**:
```bash
pytest tests/
```

---

## Analysis Tools

### Static Analysis

**When to use**:
- Finding potential bugs
- Code quality checks
- Type checking

**Tools**:
```bash
# Type checking
mypy src/

# Linting
flake8 src/
pylint src/

# Security
bandit -r src/
```

### Dynamic Analysis

**When to use**:
- Performance profiling
- Memory analysis
- Runtime behavior

**Tools**:
```bash
# Profiling
python -m cProfile script.py

# Coverage
pytest --cov=src tests/
```

---

## Real-World Decision Examples

### Example 1: Finding Authentication Code

**Scenario**: Need to understand authentication

**Wrong approach** ❌:
```
1. List all files
2. Read each file to find auth code
3. Many wasted reads
```

**Right approach** ✅:
```
1. search_files("authenticate")
   → Find: services/auth_service.py
2. read_file("services/auth_service.py")
   → Get auth code directly
```

**Tool used**: Search first, then read

### Example 2: Adding New Function

**Scenario**: Add `validate_email` to User model

**Wrong approach** ❌:
```
1. read_file("models/user.py")
2. write_to_file("models/user.py", entire_new_content)
3. Risk of formatting issues
```

**Right approach** ✅:
```
1. read_file("models/user.py")
2. insert_content at appropriate line
3. Minimal, precise change
```

**Tool used**: Insert for addition

### Example 3: Project Setup

**Scenario**: Start development server

**Wrong approach** ❌:
```
cd backend
source venv/bin/activate
export ENV_VARS
docker-compose up -d
python main.py
```

**Right approach** ✅:
```
./start-dev.sh
```

**Tool used**: Control script

---

## Tool Capability Matrix

### File Operations

| Task | Tool | Speed | Precision |
|------|------|-------|-----------|
| Read known file | read_file | Fast | High |
| Find unknown file | search_files | Medium | Medium |
| Small edit | apply_diff | Fast | Very High |
| Large edit | write_to_file | Fast | High |
| Add content | insert_content | Fast | High |

### Search Operations

| Task | Tool | Scope | Performance |
|------|------|-------|-------------|
| Content search | grep/search | Files | Fast |
| Name search | find | Names | Very Fast |
| Pattern match | regex | Content | Medium |
| Fuzzy search | fuzzy finder | Both | Medium |

### Command Operations

| Task | Tool | Complexity | Reliability |
|------|------|------------|-------------|
| Simple command | direct | Low | High |
| Complex operation | script | High | Very High |
| Chain commands | && | Medium | High |
| Parallel commands | & | High | Medium |

---

## Best Practices

### Do's

- Use search when location unknown
- Use read when location known
- Use control scripts when available
- Use precise tools for small changes
- Use appropriate test runner
- Choose tool based on task size

### Don'ts

- Don't read when you should search
- Don't search when you know location
- Don't use write_to_file for small edits
- Don't use raw commands when scripts exist
- Don't use wrong analysis tool
- Don't over-complicate simple tasks

---

## Tool Selection Checklist

**Before using a tool, ask**:

1. **Do I know the exact location?**
   - Yes → read_file
   - No → search_files

2. **How big is the change?**
   - 1-10 lines → apply_diff/edit
   - 10-50 lines → apply_diff
   - Complete file → write_to_file

3. **Is there a control script?**
   - Yes → Use control script
   - No → Use raw command

4. **Is the operation independent?**
   - Yes → Can run in parallel
   - No → Run sequentially

5. **Do I need the full file?**
   - Yes → read_file
   - No → grep/search for specific content

---

## Related Patterns

- [Optimization Patterns](./optimization-patterns.md) - Tool efficiency
- [Batching Patterns](./batching-patterns.md) - Combining tool use
- [Parallel Execution](./parallel-execution.md) - Concurrent tool use

---

**Source**: The Symposium development
