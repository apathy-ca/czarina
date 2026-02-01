# Context Window Management

**Purpose**: Strategies for staying within context limits and managing large codebases effectively.

**Value**: Prevents context overflow, maintains focus, enables work on projects larger than context window.

---

## Understanding Context Windows

### What is a Context Window?

The context window is the total amount of text (measured in tokens) that an AI assistant can process in a single conversation:
- Input tokens: Your messages, file contents, tool results
- Output tokens: AI responses
- Total: Combined cannot exceed model limit

### Common Context Window Sizes

| Model | Context Window | Practical Limit |
|-------|---------------|-----------------|
| Claude 3.5 Sonnet | 200K tokens | ~150K usable |
| Claude 3 Opus | 200K tokens | ~150K usable |
| GPT-4 Turbo | 128K tokens | ~100K usable |
| GPT-4 | 8K-32K tokens | ~6K-25K usable |

**Note**: Always leave headroom for responses and tool outputs.

---

## Pattern: Selective File Reading

### Problem
Reading entire codebase exhausts context window before real work begins.

### Solution
**Read only what you need, when you need it**:

```
BAD (context wasteful):
- Read all 50 files in repository
- Read entire 5000-line file when you need one function
- Re-read files you've already seen

GOOD (context efficient):
- Read 3-5 most relevant files
- Read specific line ranges (offset + limit)
- Cache file content mentally, don't re-read
```

### Implementation

**Use targeted reads**:
```python
# Instead of reading entire file
Read: src/services/user_service.py

# Read specific section
Read: src/services/user_service.py (lines 100-150)
```

**Use search before reading**:
```bash
# Find relevant files first
Grep: "UserAuthentication" --type py
# Then read only matching files
```

### Impact
- 70-80% reduction in context usage
- Faster initial context loading
- More room for implementation work

---

## Pattern: Progressive Context Building

### Problem
Need to understand large system but can't read everything at once.

### Solution
**Build context progressively from general to specific**:

1. **Phase 1: Overview** (5-10% of context)
   - README, architecture docs
   - Directory structure (`tree -L 2`)
   - Main entry points

2. **Phase 2: Relevant Modules** (20-30% of context)
   - Files related to current task
   - Key interfaces/base classes
   - Configuration files

3. **Phase 3: Implementation Details** (30-40% of context)
   - Specific functions being modified
   - Related tests
   - Dependencies

4. **Phase 4: Work** (remaining context)
   - Actual implementation
   - Testing
   - Documentation

### Example Workflow

```markdown
Task: Add email verification to user registration

Phase 1 (Overview):
- Read: README.md
- Read: docs/architecture.md
- Run: tree src/ -L 2

Phase 2 (Relevant):
- Read: src/services/user_service.py
- Read: src/models/user.py
- Read: config/email.yaml

Phase 3 (Details):
- Read: src/services/user_service.py:register_user()
- Read: tests/test_user_service.py:test_register()
- Read: src/utils/email.py

Phase 4 (Work):
- Implement email verification
- Write tests
- Update documentation
```

---

## Pattern: Context Window Budgeting

### Problem
Don't know how much context is being used until it's too late.

### Solution
**Allocate context budget before starting work**:

| Activity | Context Budget | Notes |
|----------|---------------|-------|
| Initial exploration | 20-30% | Understanding codebase |
| Reading relevant files | 30-40% | Files needed for task |
| Tool outputs | 10-20% | Command results, search output |
| Implementation | 20-30% | Writing code, responses |
| Buffer | 10% | Safety margin |

### Monitoring

**Signs you're approaching limit**:
- Responses becoming slower
- AI mentioning context constraints
- Summaries instead of full responses
- Suggestions to start new conversation

**Action when near limit**:
1. Summarize key findings
2. Note current state
3. Start fresh conversation with summary
4. Continue work with clean context

---

## Pattern: Context Handoff

### Problem
Task spans multiple conversations due to context limits.

### Solution
**Create effective handoff summaries**:

```markdown
## Context Handoff: [Task Name]

### Completed
- [x] Read and understood user authentication system
- [x] Identified UserService.register_user() as modification point
- [x] Created email verification migration

### Current State
- File: src/services/user_service.py
- Function: register_user (line 145)
- Change: Adding email verification before user activation

### Next Steps
1. Modify register_user() to send verification email
2. Add email verification endpoint
3. Write tests for verification flow
4. Update API documentation

### Key Context
- Email service: src/utils/email.py (configured, working)
- User model: has 'email_verified' field (migration applied)
- Config: SMTP settings in config/email.yaml

### Code Snippet
\```python
# Current state (line 145-160)
def register_user(self, email: str, password: str):
    user = User(email=email, password_hash=hash_password(password))
    db.session.add(user)
    db.session.commit()
    return user
\```
```

### Impact
- Seamless continuation across conversations
- No need to re-read files
- Maintains momentum

---

## Pattern: Lazy Loading

### Problem
Reading files speculatively that might not be needed.

### Solution
**Read files just-in-time, not just-in-case**:

```
BAD (speculative):
- "Let me read all service files to understand the pattern"
- Reading files "in case they're relevant"
- Pre-loading common utilities

GOOD (just-in-time):
- "I need to modify user authentication, reading UserService now"
- Reading files when you know you need them
- Loading utilities when first referenced
```

### Implementation

**Ask before reading**:
```markdown
I see you need to modify the authentication flow. To proceed, I'll need to read:
- src/services/auth_service.py
- src/models/user.py

Shall I read these files now? (Will use ~15% of context window)
```

**Read incrementally**:
```markdown
Starting with auth_service.py to understand the flow...
[After reading and understanding]
Now I see it depends on TokenService, reading that next...
```

---

## Pattern: Context Cleanup

### Problem
Context fills with irrelevant information over long conversations.

### Solution
**Explicitly "forget" unnecessary information**:

```markdown
Early in conversation:
- Explored database schema (no longer needed)
- Read migration files (task complete)
- Reviewed error logs (issue resolved)

Request cleanup:
"We've moved past the database investigation phase. You can forget:
- Database schema details
- Migration file contents
- Previous error logs

Focus on: Implementing the new API endpoint"
```

### When to Clean Up

**Good times to clean up**:
- Completed investigation phase
- Moving to implementation
- Switching subtasks
- After fixing unrelated bugs

**What to keep**:
- Files currently being modified
- Active task context
- Recent decisions and rationale

---

## Pattern: Multi-File vs. Single-File Work

### Problem
Some tasks need many files, others need deep focus on one.

### Solution
**Match context usage to task type**:

### Multi-File Tasks (Spread Context)
**Characteristics**:
- Refactoring across files
- Implementing features touching multiple modules
- System-wide changes

**Strategy**:
- Read all relevant files upfront (30-40% context)
- Shallow understanding of each
- Work file-by-file with context

**Example**:
```
Task: Rename UserService to UserManager across codebase

Context allocation:
- Read all files importing UserService (35%)
- List of changes needed (10%)
- Work through each file (40%)
- Buffer (15%)
```

### Single-File Tasks (Deep Context)
**Characteristics**:
- Complex algorithm implementation
- Deep refactoring of one module
- New feature in isolated file

**Strategy**:
- Read only the target file (10-15% context)
- Read dependencies as needed (20%)
- Deep focus on implementation (50%)

**Example**:
```
Task: Implement complex search algorithm in SearchService

Context allocation:
- Read SearchService.py (15%)
- Read SearchAlgorithm interface (10%)
- Implementation work (60%)
- Testing (15%)
```

---

## Best Practices

### Do
- ✅ Monitor context usage throughout conversation
- ✅ Read files with specific purpose
- ✅ Use search before read for discovery
- ✅ Create handoff summaries for long tasks
- ✅ Clean up context when switching focus
- ✅ Budget context before starting work

### Don't
- ❌ Read files "just to see what's there"
- ❌ Re-read files you've already seen
- ❌ Load entire codebase upfront
- ❌ Ignore context warning signs
- ❌ Continue when context is exhausted

---

## Related Patterns

- [Summarization](./summarization.md) - When and how to summarize
- [Memory Tiers](./memory-tiers.md) - What to remember vs. forget
- [Tool Use - Optimization](../tool-use/optimization-patterns.md) - Efficient file reading

---

**Last Updated**: 2025-12-29
**Source**: The Symposium development patterns
**Impact**: 70-80% reduction in context usage, enables work on large codebases

*"Read what you need, when you need it."*
