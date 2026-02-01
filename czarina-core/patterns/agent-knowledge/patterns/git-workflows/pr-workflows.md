# Pull Request Workflows

**Purpose**: Effective PR creation and review patterns for AI-assisted development.

**Value**: Quality code review, knowledge sharing, reduced bugs, better collaboration.

---

## Pattern: AI-Generated PR Descriptions

### Problem
AI doesn't know what information to include in PR description.

### Solution
**AI analyzes changes and generates comprehensive PR description**:

```markdown
## Summary
Add email verification system to user registration process.

## Changes
- **Backend**: Implemented email verification flow
  - Added `email_verified` field to User model
  - Created verification token generation and validation
  - Implemented email sending via EmailService
- **API**: Added verification endpoints
  - POST /auth/verify-email
  - POST /auth/resend-verification
- **Tests**: Added comprehensive test coverage
  - User model verification tests
  - Email service tests
  - API endpoint tests (8 new tests, all passing)

## Testing
- [x] Unit tests pass (8 new tests added)
- [x] Integration tests pass
- [x] Manual testing completed
  - Verified email sending works
  - Tested token validation
  - Confirmed user state updates

## Deployment Notes
- Database migration required: `migrations/20250129_add_email_verification.py`
- Environment variable needed: `SMTP_*` settings for email
- No breaking changes

## Related Issues
Closes #123

---

Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

### PR Description Template

```markdown
## Summary
[One paragraph describing what this PR does]

## Changes
[Bulleted list of specific changes, organized by area]

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Deployment Notes
[Any special deployment considerations]
[Database migrations]
[Environment variables]
[Breaking changes]

## Related Issues
[Issue references: Closes #XX, Relates to #YY]
```

---

## Pattern: PR Size Management

### Problem
Large PRs are hard to review and more likely to have bugs.

### Solution
**Keep PRs small and focused**:

### Target Sizes

| PR Size | Lines Changed | Files Changed | Review Time | Defect Rate |
|---------|--------------|---------------|-------------|-------------|
| Tiny | < 50 | 1-2 | 5-10 min | Very Low |
| Small | 50-200 | 2-5 | 15-30 min | Low |
| Medium | 200-500 | 5-10 | 30-60 min | Medium |
| Large | 500-1000 | 10-20 | 1-2 hours | High |
| Huge | > 1000 | > 20 | 2+ hours | Very High |

**Target**: Small to Medium PRs (< 500 lines)

### Breaking Large Changes Down

```bash
# Instead of one large PR:
PR: "Implement payment system" (1500 lines, 25 files)

# Break into smaller PRs:
PR1: "Add payment data model" (150 lines, 3 files)
PR2: "Implement payment service" (200 lines, 4 files)
PR3: "Add payment API endpoints" (180 lines, 5 files)
PR4: "Add payment webhooks" (150 lines, 3 files)
PR5: "Add payment tests" (200 lines, 5 files)
```

---

## Pattern: Self-Review Before Submission

### Problem
Submitting PR without reviewing own changes leads to obvious errors.

### Solution
**AI performs self-review before creating PR**:

```markdown
AI Self-Review Checklist:

Code Quality:
- [ ] No debug print statements
- [ ] No commented-out code
- [ ] Removed unnecessary imports
- [ ] Consistent formatting (ran linter)
- [ ] Type hints added where needed

Tests:
- [ ] All tests passing
- [ ] New tests added for new features
- [ ] Edge cases covered
- [ ] Test names descriptive

Documentation:
- [ ] Code comments for complex logic
- [ ] Docstrings for public methods
- [ ] README updated if needed
- [ ] API docs updated if needed

Security:
- [ ] No hardcoded secrets
- [ ] No sensitive data in commits
- [ ] Input validation added
- [ ] Authentication/authorization checked
```

---

## Pattern: Draft PRs for Work in Progress

### Problem
Want to share work in progress without implying it's ready for review.

### Solution
**Use draft PRs for work in progress**:

```bash
# Create draft PR
gh pr create --draft --title "WIP: Add email verification" --body "Work in progress"

# Continue working, pushing commits
git push

# When ready for review, mark as ready
gh pr ready
```

### When to Use Drafts

**Good for**:
- Sharing progress on long-running features
- Getting early feedback on approach
- Running CI/CD tests before final review
- Collaborative features with multiple contributors

**Not needed for**:
- Small bug fixes (just create regular PR)
- Quick features (complete before PR)

---

## Pattern: PR Review Checklist

### Problem
Reviewers don't know what to focus on.

### Solution
**Include review guidance in PR description**:

```markdown
## Review Focus Areas

**Please pay special attention to**:
- [ ] **Security**: Payment amount validation logic (payment_service.py:145-160)
- [ ] **Performance**: Database query optimization (payment_service.py:200-220)
- [ ] **Edge Cases**: Refund handling when payment is partially refunded

**Less critical**:
- Test file organization (can be improved later)
- Variable naming (mostly standard)

**Don't need to review**:
- Generated migration file (auto-generated)
- Mock data in tests (standard patterns)
```

---

## Pattern: Automated Checks Integration

### Problem
PR merged without tests running or linting passing.

### Solution
**Require status checks before merging**:

```yaml
# .github/workflows/pr-checks.yml
name: PR Checks

on: [pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: pytest
      - name: Run linting
        run: flake8
      - name: Type checking
        run: mypy src/

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Security scan
        run: bandit -r src/
```

### Required Checks

**Minimum**:
- ✅ All tests passing
- ✅ Linting passing
- ✅ No merge conflicts

**Recommended**:
- ✅ Type checking passing
- ✅ Test coverage > threshold
- ✅ Security scan passing
- ✅ Documentation generated

---

## Pattern: Merge Strategies

### Problem
Different merge strategies have different trade-offs.

### Solution
**Choose strategy based on context**:

### Merge Commit (Default)
```bash
git merge --no-ff feat/email-verification
```
**Pros**: Preserves full history, clear feature boundaries
**Cons**: More commits in history
**Use for**: Features, important changes

### Squash and Merge
```bash
git merge --squash feat/email-verification
```
**Pros**: Clean history (one commit per feature)
**Cons**: Loses individual commit history
**Use for**: Small features, bug fixes, cleanup

### Rebase and Merge
```bash
git rebase main
git checkout main
git merge feat/email-verification
```
**Pros**: Linear history, no merge commits
**Cons**: Rewrites history
**Use for**: Keeping main clean, small changes

### Recommendation
- Large features: Merge commit
- Small features/fixes: Squash and merge
- Hotfixes: Squash and merge

---

## Pattern: PR Dependencies

### Problem
PR depends on another PR that hasn't merged yet.

### Solution
**Create stacked PRs with clear dependencies**:

```markdown
Stack:
PR #101: Add payment model (base) → main
PR #102: Add payment service → PR #101
PR #103: Add payment API → PR #102

PR #102 Description:
**Depends on**: #101 (must merge first)
**Based on**: feat/payment-model branch

Review Notes:
- Only review new commits (service implementation)
- Model changes are in #101
- Will rebase after #101 merges
```

### Managing Stacked PRs

```bash
# Create base PR
git checkout -b feat/payment-model
# ... implement model ...
git push
gh pr create

# Create dependent PR
git checkout -b feat/payment-service
# ... implement service ...
git push
gh pr create --base feat/payment-model  # Base on feature branch, not main

# After base PR merges
git checkout feat/payment-service
git rebase main
gh pr edit --base main  # Change base to main
git push --force-with-lease
```

---

## Best Practices

### Do
- ✅ Keep PRs small (< 500 lines ideal)
- ✅ Write comprehensive PR descriptions
- ✅ Perform self-review before submission
- ✅ Add tests with code changes
- ✅ Link related issues
- ✅ Request specific reviewers when needed

### Don't
- ❌ Create huge PRs (> 1000 lines)
- ❌ Mix unrelated changes
- ❌ Submit PRs with failing tests
- ❌ Skip PR description
- ❌ Merge without review (unless hotfix)
- ❌ Force push to PR after review started (unless rebasing)

---

## PR Workflow Checklist

**Before Creating PR**:
- [ ] All tests passing locally
- [ ] Self-review completed
- [ ] Commits are clean and atomic
- [ ] Branch rebased on latest main (if needed)

**Creating PR**:
- [ ] Descriptive title
- [ ] Comprehensive description
- [ ] Link related issues
- [ ] Request reviewers
- [ ] Add labels (if used)

**During Review**:
- [ ] Address review comments
- [ ] Push requested changes
- [ ] Re-request review after changes
- [ ] Keep PR updated with main (rebase if needed)

**Before Merging**:
- [ ] All checks passing
- [ ] Review approved
- [ ] Conflicts resolved
- [ ] PR description updated if scope changed

---

## Related Patterns

- [Branch Strategies](./branch-strategies.md) - Branch organization
- [Commit Patterns](./commit-patterns.md) - Commit organization
- [Conflict Resolution](./conflict-resolution.md) - Handling merge conflicts

---

## Related Core Rules

**See Also**:
- [Git Workflows](../../core-rules/workflows/git-workflows.md) - PR requirements and standards

---

**Last Updated**: 2025-12-29
**Source**: The Symposium development patterns
**Impact**: Better code quality, faster reviews, effective collaboration

*"Small PRs, clear descriptions, passing tests."*
