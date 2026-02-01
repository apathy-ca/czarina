# Commit Patterns

**Purpose**: Effective commit strategies for AI-assisted development.

**Value**: Clear history, easy rollback, better code review, understanding of changes over time.

---

## Pattern: Atomic Commits

### Problem
Large commits with multiple unrelated changes are hard to review and rollback.

### Solution
**One logical change per commit**:

```bash
# BAD (multiple unrelated changes)
git add .
git commit -m "Fix bug and add feature and update docs"

# GOOD (atomic commits)
git add src/services/payment.py
git commit -m "fix: Validate refund amount against original payment"

git add src/services/email.py
git commit -m "feat: Add email verification system"

git add docs/api/authentication.md
git commit -m "docs: Update authentication API documentation"
```

### Benefits
- Easy to understand each change
- Can revert specific changes
- Simpler code review
- Clear history

---

## Pattern: Conventional Commits

### Problem
Inconsistent commit messages make history hard to navigate.

### Solution
**Use conventional commit format**:

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks
- `style`: Code style changes (formatting)
- `perf`: Performance improvements

### Examples

```bash
# Simple commits
git commit -m "feat: Add email verification"
git commit -m "fix: Correct payment validation logic"
git commit -m "docs: Update API documentation"

# With scope
git commit -m "feat(auth): Add JWT token generation"
git commit -m "fix(payment): Validate refund amounts"
git commit -m "test(user): Add registration tests"

# With body
git commit -m "feat(email): Add verification system

- Generate verification tokens
- Send verification emails
- Add verification endpoint
- Update user model with verified flag"

# Breaking changes
git commit -m "feat(auth): Change to session-based authentication

BREAKING CHANGE: JWT authentication removed in favor of sessions.
All clients must update to use session cookies."
```

---

## Pattern: AI Commit Message Generation

### Problem
AI doesn't know project commit message conventions.

### Solution
**AI analyzes changes and generates conventional commit message**:

```markdown
AI Workflow:
1. Review changed files
2. Analyze nature of changes
3. Determine type (feat/fix/refactor/etc.)
4. Generate subject from main change
5. Add body with detailed changes
6. Present to user for approval

Example:
AI: "I've implemented email verification. Proposed commit message:

    feat(auth): Add email verification system

    - Add verification token generation
    - Implement verification email sending
    - Create email verification endpoint
    - Add email_verified field to User model
    - Add tests for verification flow

    Does this accurately describe the changes?"
```

---

## Pattern: Commit Frequency

### Problem
Too few commits lose granularity; too many commits clutter history.

### Solution
**Commit at natural checkpoints**:

### When to Commit

**Do commit**:
- ✅ After completing logical unit of work
- ✅ Before switching to different task
- ✅ After fixing a bug
- ✅ After tests pass
- ✅ Before taking a break
- ✅ After refactoring a component

**Don't commit**:
- ❌ In the middle of implementing a method
- ❌ With failing tests (unless documenting failure)
- ❌ With commented-out code
- ❌ With debug statements (remove first)
- ❌ Every single line change

### Checkpoint Examples

```markdown
Good commit points:
✅ Implemented User.verify_email() method → commit
✅ Added tests for verify_email() → commit
✅ Created API endpoint for verification → commit

Too granular:
❌ Added function signature → commit
❌ Added first line of function → commit
❌ Added second line of function → commit
```

---

## Pattern: Commit Amending

### Problem
Just committed but forgot to include a file or fix a typo in commit message.

### Solution
**Amend last commit** (only if not pushed):

```bash
# Forgot to stage a file
git add forgotten_file.py
git commit --amend --no-edit  # Add file to last commit

# Fix commit message typo
git commit --amend -m "fix: Correct payment validation (not 'validaton')"

# Both changes
git add forgotten_file.py
git commit --amend -m "fix: Correct payment validation logic"
```

### Rules for Amending

**Safe to amend**:
- ✅ Commit not pushed to remote
- ✅ Only you are working on branch
- ✅ Just made the commit (< 5 minutes ago)

**Never amend**:
- ❌ Commit already pushed (requires force push)
- ❌ Others working on same branch
- ❌ Commit on main/protected branch

---

## Pattern: Co-Authoring with AI

### Problem
AI assisted significantly with commit, want to attribute credit.

### Solution
**Add Co-authored-by footer**:

```bash
git commit -m "feat(search): Implement advanced search algorithm

Implemented binary search with optimized indexing for faster lookups.

Co-authored-by: Claude <noreply@anthropic.com>"
```

### When to Co-Author

**Add AI co-author when**:
- AI designed the algorithm
- AI wrote significant portion of code
- AI solved complex problem
- Organization policy requires attribution

**Skip co-author when**:
- AI just fixed typos
- Simple, routine changes
- You significantly modified AI's suggestion

---

## Pattern: Documentation Sync Commits

### Problem
Code changes without corresponding documentation updates cause drift.

### Solution
**Include documentation changes in same commit as code changes**:

```bash
# GOOD (code + docs together)
git add src/api/auth.py docs/api/authentication.md
git commit -m "feat(auth): Add JWT token refresh endpoint

- Implement POST /auth/refresh endpoint
- Add token validation and refresh logic
- Update API documentation with new endpoint"

# LESS IDEAL (separate commits okay, but same PR)
git commit -m "feat(auth): Add JWT token refresh endpoint"
git commit -m "docs(auth): Document token refresh endpoint"
```

### Documentation Change Types

**Always include in same commit**:
- API endpoint changes → API docs
- Configuration changes → README/setup docs
- New feature → Feature documentation
- Breaking changes → CHANGELOG + migration guide

---

## Pattern: Test Commits

### Problem
Should tests be in same commit as implementation or separate?

### Solution
**Depends on workflow**:

### Option 1: Tests with Implementation (Recommended)
```bash
git add src/services/user.py tests/test_user.py
git commit -m "feat(user): Add email verification

- Implement verify_email() method
- Add verification token generation
- Add tests for verification flow"
```

**Pros**: Atomic feature (implementation + tests together)
**Cons**: Larger commits

### Option 2: Tests Separate
```bash
git commit -m "feat(user): Add email verification method"
git commit -m "test(user): Add email verification tests"
```

**Pros**: Smaller, focused commits
**Cons**: Implementation without tests in one commit

### Recommendation
- Use Option 1 for small features (< 100 lines)
- Use Option 2 for large features (> 100 lines)
- Always in same PR either way

---

## Best Practices

### Do
- ✅ Use conventional commit format
- ✅ Make atomic commits (one logical change)
- ✅ Write clear, descriptive commit messages
- ✅ Include documentation with code changes
- ✅ Commit at natural checkpoints
- ✅ Let AI generate commit messages (review before using)

### Don't
- ❌ Commit broken code (unless explicitly documenting)
- ❌ Use vague messages ("fix stuff", "updates")
- ❌ Amend pushed commits (requires force push)
- ❌ Mix unrelated changes in one commit
- ❌ Commit commented-out code
- ❌ Commit sensitive data (.env files, credentials)

---

## Commit Message Template

```bash
# Configure Git to use template
echo "# Type: feat|fix|docs|refactor|test|chore|style|perf
# Scope: (optional) component name
# Subject: Concise description (50 chars max)
#
# Body: (optional) Detailed explanation
# - What changed
# - Why it changed
# - Any breaking changes
#
# Footer: (optional)
# Co-authored-by: Name <email>
# Closes #123" > ~/.gitmessage

git config --global commit.template ~/.gitmessage
```

---

## Related Patterns

- [Branch Strategies](./branch-strategies.md) - Branch organization
- [PR Workflows](./pr-workflows.md) - Pull request processes

---

## Related Core Rules

**See Also**:
- [Git Workflows](../../core-rules/workflows/git-workflows.md) - Commit standards

---

**Last Updated**: 2025-12-29
**Source**: The Symposium development patterns
**Impact**: Clear history, easy code review, better collaboration

*"Commit often, commit atomically, commit clearly."*
