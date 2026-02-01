# Pull Request Requirements for AI Agent Development

## Overview

This document defines Pull Request (PR) requirements and review processes for AI agent development projects. These patterns ensure code quality, documentation synchronization, and effective collaboration between AI agents and human orchestrators (Czars).

## Core Principle

**🚨 CRITICAL: ALL work goes through Pull Requests to main branch. NO direct commits to main.**

This is a non-negotiable rule with NO exceptions (except approved emergency hotfixes).

## Why Pull Requests?

### The Problem PRs Solve

✅ **Quality Gates**:
- Code gets reviewed before merging
- Documentation gets checked for completeness
- Tests must pass before integration
- Bad commits can be blocked
- History is clear and traceable

✅ **Prevents Documentation Drift**:
- Forces synchronization between code and docs
- Catches missing updates before they hit main
- Maintains single source of truth

✅ **Architecture Protection**:
- Czar reviews align with project direction
- Tech debt is caught early
- Patterns are enforced consistently

### The Pain of Direct Commits

❌ **Quality Issues**:
- Bad code hits main and breaks things
- Documentation never gets updated
- Mistakes cascade to production
- No one catches architectural issues
- Zero accountability

❌ **Maintenance Nightmares**:
- Unclear what changed and why
- No review trail for debugging
- Broken builds on main branch
- Impossible to roll back safely

## PR Workflow

### Step 1: Create Feature Branch

Always start from an up-to-date main branch:

```bash
# Update main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/v1.2.0-authentication
```

**Branch Naming Conventions** (see `GIT_WORKFLOW.md` for details):
- `feature/<version>-<feature-name>` - New features
- `fix/<issue-description>` - Bug fixes
- `docs/<doc-name>` - Documentation updates
- `refactor/<component-name>` - Code restructuring
- `test/<test-name>` - Test additions

### Step 2: Develop with Discipline

**While developing**:
- ✅ Commit frequently (small, logical commits)
- ✅ Write tests as you go
- ✅ Update documentation in the same commits
- ✅ Run tests locally
- ✅ Keep commits clean and focused

**Code quality**:
- Follow existing code patterns
- Add comments for complex logic
- Handle errors comprehensively
- Include logging for debugging
- Consider performance implications

### Step 3: Update Documentation (MANDATORY)

**BEFORE creating PR**, ensure these are updated:

#### Required Documentation Updates

**1. VERSION File** (if version changes):
```bash
CURRENT_VERSION=1.2.0
CURRENT_PHASE=Phase 1
CURRENT_STATUS=In Progress
LAST_COMPLETED=1.1.0
LAST_UPDATED=2025-12-22T10:30:00-05:00
LAST_UPDATED_UTC=2025-12-22T15:30:00Z
NEXT_VERSION=1.3.0
```

**2. ROADMAP.md** (always update "Current State" section):
```markdown
## 📍 Current State

### What We Just Finished
- v1.2.0: Authentication System (Dec 22)
- v1.1.0: User Management (Dec 20)

### Current Work
- Testing v1.2.0 - Authentication integration complete

### Next Up
- v1.3.0: Authorization & Permissions
```

**3. Phase Documentation** (if multi-phase work):
- Update phase status
- Mark completed milestones
- Document any blockers

**4. Feature Documentation**:
- User guides for user-facing features
- API documentation for new endpoints
- Architecture docs for system changes
- README files for new directories

**5. Code Documentation**:
- Clear comments explaining WHY, not just WHAT
- Docstrings for public functions/classes
- Examples in docstrings where helpful

**Note**: Czar updates CHANGELOG.md during merge operation (or at version completion for batch releases).

### Step 4: Self-Review

Before pushing, review your own code:

```bash
# View all changes vs main
git diff main...HEAD

# Review commit history
git log main...HEAD --oneline

# Check documentation updates
git diff main...HEAD VERSION ROADMAP.md
```

**Self-review checklist**:
- [ ] All changes are intentional
- [ ] No debug code or console.log statements
- [ ] No commented-out code
- [ ] No sensitive data (credentials, keys)
- [ ] Documentation is updated
- [ ] Tests are included
- [ ] Commit messages are clear

### Step 5: Push to Origin

```bash
# Push feature branch
git push -u origin feature/v1.2.0-authentication
```

### Step 6: Create Pull Request

#### PR Title Format

Use conventional commit format:

```
<type>(<scope>): <description>
```

**Examples**:
```
feat(auth): Add JWT authentication system
fix(memory): Resolve search timeout issues
docs(api): Complete API reference for v1.2
refactor(cache): Optimize cache invalidation
test(integration): Add auth integration tests
```

#### PR Description Template

```markdown
## Summary
[Clear explanation of what this PR does]

## Motivation
[Why this change is needed - context and background]

## Changes
- [List major changes]
- [Organized by component or feature]
- [Enough detail for reviewer understanding]

## Testing
- [What was tested]
- [How to verify the changes work]
- [Test coverage information]

## Documentation
- ✅ VERSION updated to [version]
- ✅ ROADMAP.md current state updated
- ✅ [Feature docs] created/updated
- ✅ Code comments added
- ⏳ CHANGELOG.md (Czar will update)

## Breaking Changes
[List any breaking changes, or "None"]

## Related Issues
[Links to related PRs, issues, or planning documents]

## Planning Document
See [link to planning document]
```

#### PR Description Example

```markdown
## Summary
Implements JWT-based authentication system for v1.2.0, including login, logout, token refresh, and session management.

## Motivation
Users need secure authentication to access protected resources. JWT tokens provide stateless authentication suitable for our microservices architecture.

## Changes
- JWT token generation and validation service
- Login endpoint with credential validation
- Logout endpoint with token revocation
- Token refresh mechanism (24-hour expiry)
- User session management
- Rate limiting on authentication endpoints
- Comprehensive error handling

## Testing
**Unit Tests** (15 tests):
- Token generation and validation
- Expiry handling
- Signature validation
- Malformed token handling

**Integration Tests** (8 tests):
- Login/logout flow
- Token refresh
- Rate limiting
- Error responses

**Manual Testing**:
- Tested complete auth flow in development
- Verified token expiry and refresh
- Confirmed rate limiting works
- Checked error messages are user-friendly

**Coverage**: 92% for new authentication code

## Documentation
- ✅ VERSION updated to 1.2.0
- ✅ ROADMAP.md current state updated (auth complete)
- ✅ Created docs/AUTH_GUIDE.md (user guide)
- ✅ Created docs/AUTH_API.md (API reference)
- ✅ Code comments for JWT configuration
- ⏳ CHANGELOG.md (Czar will update at version completion)

## Breaking Changes
None - this is a new feature, no existing APIs affected.

## Related Issues
Closes #42: Implement user authentication
Related to #43: Will enable authorization system

## Planning Document
See docs/V1.2.0_AUTHENTICATION_PLAN.md
```

### Step 7: Czar Review

The Czar (human orchestrator) reviews every PR using a four-step checklist:

#### 1. Documentation Review (HARD BLOCK)

**Czar checks**:
- ✅ VERSION file updated (if version changed)
- ✅ ROADMAP.md "Current State" updated
- ✅ Phase docs updated (if applicable)
- ✅ Feature documentation complete
- ✅ Code comments clear and helpful
- ✅ API docs updated (if endpoints changed)
- ✅ README files updated (if structure changed)

**Result**:
- ✅ All checked? → Proceed to quality review
- 🚫 Any missing? → **REQUEST CHANGES** (must update docs)

**Example rejection**:
```
🚫 REQUEST CHANGES

Documentation is incomplete:
- ROADMAP.md not updated (still shows v1.1.0 as current)
- Missing user guide (docs/AUTH_GUIDE.md)
- API endpoints not documented

Please update these and resubmit.
```

#### 2. Quality Review (HARD BLOCK)

**Czar checks**:
- ✅ **Builds successfully** (Czar tests this locally)
- ✅ All tests pass
- ✅ Code coverage acceptable (>80% for new code)
- ✅ No obvious bugs in code review
- ✅ Error handling comprehensive
- ✅ Logging/debugging info present
- ✅ Performance acceptable

**Critical**: Czar builds and tests the PR branch before approving. Never merge untested code.

**Result**:
- ✅ All good? → Proceed to architecture review
- 🚫 Issues found? → **REQUEST CHANGES** (must fix)

**Example rejection**:
```
🚫 REQUEST CHANGES

Quality issues found:
- Build fails: Missing dependency 'pyjwt' in requirements.txt
- 2 integration tests failing:
  - test_auth.py::test_token_refresh FAILED
  - test_auth.py::test_rate_limiting FAILED
- No error handling for database connection failures

Please fix and push updates.
```

#### 3. Architecture Review (SOFT BLOCK)

**Czar checks**:
- ✅ Follows existing patterns in codebase
- ✅ Doesn't break existing dependencies
- ✅ Aligns with project roadmap
- ✅ No unnecessary complexity or tech debt
- ✅ Scalability considered
- ✅ Security implications reviewed

**Result**:
- ✅ All good? → Proceed to completeness review
- ⚠️ Concerns? → **REQUEST CHANGES** with discussion

**Example feedback**:
```
🚠 REQUEST CHANGES

Architectural concerns:
- JWT secret is hardcoded in config.py - should use environment variable
- Token storage in memory won't scale - consider Redis for session store
- Password hashing uses MD5 - should use bcrypt or Argon2

Let's discuss these in PR comments. These are important security/scalability issues.
```

#### 4. Completeness Review (HARD BLOCK)

**Czar checks**:
- ✅ Feature fully implemented (not partial)
- ✅ All use cases covered
- ✅ Edge cases handled
- ✅ Error cases tested
- ✅ Documentation complete
- ✅ Tests comprehensive

**Result**:
- ✅ Complete? → **APPROVE**
- 🚫 Incomplete? → **REQUEST CHANGES** (complete the work)

**Example rejection**:
```
🚫 REQUEST CHANGES

Work appears incomplete:
- Only happy path tested (no error case tests)
- No handling for expired passwords
- Documentation mentions "TODO: add examples"
- Missing logout functionality (only login implemented)

Please complete all planned features before resubmitting.
```

### Step 8: Address Feedback

If Czar requests changes:

1. **Read feedback carefully** - understand what's needed
2. **Make the changes** in your feature branch
3. **Commit with clear messages**:
   ```bash
   git commit -m "fix(auth): Address Czar review feedback

   - Added pyjwt to requirements.txt
   - Fixed token refresh test (adjusted expiry logic)
   - Added error handling for database connections
   - Updated AUTH_GUIDE.md with examples

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```
4. **Push updates**:
   ```bash
   git push origin feature/v1.2.0-authentication
   ```
5. **Comment on PR**: "Ready for re-review - addressed all feedback"
6. **Wait for re-review** - Czar will review again

**Do NOT**:
- ❌ Argue about feedback in comments
- ❌ Ignore requested changes
- ❌ Create a new PR instead of fixing
- ❌ Take feedback personally

### Step 9: Approval and Merge

Once Czar approves:

```
✅ APPROVED

All checks passed:
- ✅ Documentation complete (VERSION, ROADMAP.md, AUTH_GUIDE.md)
- ✅ Build tested and passes
- ✅ All 23 tests passing
- ✅ Architecture sound
- ✅ Work complete

Merging to main!
```

**Czar then**:
1. Merges PR to main (with `--no-ff` for feature branches)
2. Updates CHANGELOG.md (if immediate update, or defers to version completion)
3. Deletes feature branch
4. Verifies main branch builds
5. Tags release (if applicable)

**Agent does NOT merge** - always wait for Czar to merge.

## PR Review Checklist for Agents

### Before Creating PR
- [ ] Code is complete (not work-in-progress)
- [ ] All tests pass locally
- [ ] Documentation is updated (VERSION, ROADMAP.md, feature docs)
- [ ] No debug code or temporary files
- [ ] No sensitive data committed
- [ ] Commits are clean and logical
- [ ] Branch is up to date with main
- [ ] Self-review completed

### In PR Description
- [ ] Clear title with conventional commit format
- [ ] Summary explains what this does
- [ ] Motivation explains why this is needed
- [ ] Changes listed and organized
- [ ] Testing approach described
- [ ] Documentation updates listed
- [ ] Breaking changes noted (or "None")
- [ ] Related issues/PRs linked
- [ ] Planning document referenced

### Ready for Review
- [ ] All tests passing
- [ ] CI/CD checks green (if applicable)
- [ ] Documentation complete
- [ ] Code reviewed by you first
- [ ] No obvious issues
- [ ] Ready for Czar review

## Common PR Scenarios

### Scenario 1: New Feature

**What you do**:
1. Create `feature/v1.2.0-auth` branch
2. Implement feature completely
3. Write comprehensive tests (unit + integration)
4. Update VERSION (if version changes)
5. Update ROADMAP.md (current state)
6. Create feature documentation (user guide, API docs)
7. Add code comments for complex logic
8. Create PR with all documentation updated

**What Czar checks**:
- Is feature fully implemented?
- Are docs comprehensive and accurate?
- Are tests thorough (happy path + error cases)?
- Does it align with roadmap and architecture?

### Scenario 2: Bug Fix

**What you do**:
1. Create `fix/memory-search-timeout` branch
2. Fix the bug
3. Create test that reproduces bug and verifies fix
4. Update ROADMAP.md (add to "Recent Fixes" or "Current Work")
5. Add code comments explaining the fix
6. Create PR

**What Czar checks**:
- Does fix actually work?
- Is there a test preventing regression?
- Are docs updated (at minimum ROADMAP.md)?
- Is this a complete fix or temporary workaround?

### Scenario 3: Documentation Update

**What you do**:
1. Create `docs/api-reference-update` branch
2. Update documentation
3. Verify examples are correct
4. Create PR with before/after explanation

**What Czar checks**:
- Are docs accurate (match implementation)?
- Are examples correct and helpful?
- Is it comprehensive?
- Good formatting and clarity?

### Scenario 4: Refactoring

**What you do**:
1. Create `refactor/memory-service` branch
2. Refactor code (no behavior changes)
3. Ensure ALL tests still pass (100%)
4. Update code comments if logic changed
5. Create PR explaining refactoring purpose

**What Czar checks**:
- Do tests still pass (proving no behavior change)?
- Is refactoring an improvement?
- Are comments updated?
- No hidden behavior changes?

## When to Update Existing PR vs Create New PR

### ✅ UPDATE Existing PR When:

1. **Czar requested changes** - Fix in same PR
2. **You found bug before review** - Fix in same PR
3. **Related to same feature** - Keep in same PR
4. **PR is still open and not approved** - Safe to update

**Example**:
```bash
# PR #42 open, Czar said "fix the tests"
git checkout feature/v1.2.0-auth  # ✅ SAME BRANCH
# Fix the tests
git commit -m "test(auth): Fix failing token refresh test"
git push origin feature/v1.2.0-auth  # ✅ UPDATE EXISTING
# Comment on PR: "Tests fixed, ready for re-review"
```

### ✅ CREATE NEW PR When:

1. **PR is already merged** - ALWAYS create new PR
2. **PR is approved but not merged** - Create new PR (don't change approved work)
3. **Different bug/feature** - Each distinct issue gets its own PR
4. **Unrelated to existing PR** - Don't mix concerns

**Example**:
```bash
# PR #42 merged yesterday, found new bug
git checkout -b fix/auth-json-parsing  # ✅ NEW BRANCH
# Fix the bug
git commit -m "fix(auth): Handle nested JSON in token payload"
git push origin fix/auth-json-parsing
# Create NEW PR #43
```

### ❌ NEVER Update Existing PR After:

1. **Czar has merged it** - PR is closed, create new one
2. **Czar has approved it** - Don't change approved work
3. **It's been closed** - Create fresh PR

**The Rule**: Once Czar merges a PR, that branch is DONE. Any new work = NEW PR.

This prevents:
- Confusion about what's merged vs pending
- Reopening closed PRs
- Mixing reviewed code with new code
- Breaking git history

## Czar Approval Patterns

### When Czar Approves ✅

```
✅ APPROVED

All checks passed:
- ✅ Documentation complete
- ✅ Build verified and passes
- ✅ All tests passing (coverage: 92%)
- ✅ Architecture sound
- ✅ Work complete and comprehensive

Ready to merge!
```

**What happens next**:
1. Czar merges PR to main
2. Czar updates CHANGELOG.md (immediately or at version completion)
3. Czar deletes feature branch
4. Czar verifies main still builds
5. Czar tags release (if applicable)

### When Czar Requests Changes 🚫

```
🚫 REQUEST CHANGES

Issues found:
- [Specific issue 1]
- [Specific issue 2]
- [Specific issue 3]

Please fix these and push updates. I'll re-review when ready.
```

**What you do**:
1. Fix the issues in your feature branch
2. Commit and push updates
3. Comment "Ready for re-review"
4. Czar re-reviews

### When Czar Rejects ❌

```
❌ REJECTED

This PR has fundamental issues:
- [Major blocker]
- [Architectural concern]
- [Significant scope mismatch]

Please address these. This may require closing and starting over with a new approach.
```

**What you do**:
1. Understand the fundamental issues
2. Decide: fix or restart?
3. If restarting: close PR, create new branch with revised approach
4. If fixing: make substantial changes and resubmit

## Special Cases

### Hotfix Exception (Production Emergencies)

**Only for critical production issues:**

```bash
# Create hotfix branch
git checkout -b hotfix/critical-security-issue

# Fix the issue
# ... make changes ...

# Test thoroughly
# ... run tests ...

# Create PR with [HOTFIX] tag
git push origin hotfix/critical-security-issue
# PR title: "[HOTFIX] fix(auth): Patch critical JWT vulnerability"
```

**Hotfix criteria**:
- 🚨 Production-breaking bug
- 🚨 Security vulnerability
- 🚨 Data loss prevention
- 🚨 Critical user-facing issue

**Hotfix process**:
1. Czar fast-tracks review (within 2 hours)
2. Tests must still pass
3. Documentation can be updated in follow-up PR (within 24 hours)
4. Czar merges immediately after verification

**Hotfixes bypass some review but NOT testing or critical documentation.**

### Large Multi-Phase Features

For complex features spanning multiple phases:

```
Phase 1 PR: Foundation
- Czar reviews and merges

Phase 2 PR: Integration
- Czar reviews and merges

Phase 3 PR: Polish
- Czar reviews and merges
```

**Why separate PRs**:
- Easier to review in chunks
- Less rework needed
- Can deploy incrementally
- Clearer history

### Batch Bugfix Strategy

For active development with many small fixes:

**Pattern**:
1. Create PR for each bug fix
2. Czar reviews and merges
3. **SKIP CHANGELOG update** (deferred to version completion)
4. Note in commit: `CHANGELOG: deferred to v1.2.0 completion`
5. At version completion: Czar batches all fixes into one CHANGELOG entry

**Example**:
```bash
# Fix 1
git commit -m "fix(auth): Handle expired tokens correctly

CHANGELOG: deferred to v1.2.0 completion"

# Fix 2
git commit -m "fix(auth): Add rate limiting to login endpoint

CHANGELOG: deferred to v1.2.0 completion"

# At version completion, Czar updates CHANGELOG once:
# v1.2.0 - 2025-12-22
# Fixed:
# - Expired token handling
# - Rate limiting on login
# - ... (all fixes in batch)
```

**Benefits**:
- Less overhead during development
- Better, more coherent release notes
- Easier to understand what shipped as a unit

### Czar Rebase Authority

**Czar can rebase** for minor conflicts:

```bash
# Simple VERSION/CHANGELOG conflicts
git checkout feature/v1.2.0-auth
git rebase main
git push --force origin feature/v1.2.0-auth
# Then merge
```

**When Czar rebases**:
- ✅ Minor conflicts (VERSION, CHANGELOG)
- ✅ Simple, focused changes
- ✅ Build already verified
- ✅ Just syncing with latest main

**When Czar requests agent rebase**:
- ❌ Complex code conflicts
- ❌ Architectural changes
- ❌ Large feature work
- ❌ Uncertain about conflict resolution

## Anti-Patterns (What NOT to Do)

### ❌ Direct Commits to Main

```bash
# NEVER DO THIS
git checkout main
git commit -m "Quick fix"
git push origin main
```

**Why**: Bypasses review, documentation requirements, quality gates. Always use PRs.

### ❌ Work-In-Progress PRs

```bash
# BAD
git push origin feature/incomplete-work
# Create PR with title: "WIP: Auth system (not done)"
```

**Why**: PRs should be complete work ready for review, not progress updates.

### ❌ Giant PRs

```bash
# BAD - changed 50 files, 5000 lines
git commit -m "Implement entire feature"
# Create PR
```

**Why**: Impossible to review thoroughly, hard to debug, difficult to revert. Break into phases.

### ❌ Skipping Documentation

```bash
# BAD
git commit -m "feat(auth): Add authentication"
# (VERSION still shows old version, ROADMAP.md not updated)
# Create PR
```

**Why**: Documentation drift. Czar will reject immediately.

### ❌ Ignoring Test Failures

```bash
# BAD
# Tests failing locally
git push origin feature/auth
# Create PR anyway
```

**Why**: Wastes Czar's time, shows lack of discipline. Fix tests before PR.

### ❌ Merging Own PRs

```bash
# BAD - agent merges own PR
git checkout main
git merge feature/my-feature
git push origin main
```

**Why**: Bypasses Czar review. Only Czar merges to main.

### ❌ Arguing with Feedback

```
# BAD - in PR comments
Agent: "I disagree with this feedback. My approach is better."
```

**Why**: Czar's feedback is based on project standards and architecture. Discuss respectfully or implement as requested.

## Best Practices

### ✅ Make Small, Focused PRs

Each PR should address ONE feature/fix/improvement:

```bash
# GOOD - focused PRs
PR #1: feat(auth): Add login endpoint
PR #2: feat(auth): Add logout endpoint
PR #3: feat(auth): Add token refresh

# Better than one giant PR with all three
```

### ✅ Update Documentation in Same PR

```bash
# GOOD - docs updated with code
git commit -m "feat(auth): Add login endpoint

- JWT token generation
- Credential validation
- Rate limiting

New files:
- src/auth/login.py
- docs/AUTH_API.md (API documentation)
- tests/test_login.py

Updated:
- VERSION: 1.2.0
- ROADMAP.md: Auth login complete"
```

### ✅ Write Comprehensive PR Descriptions

Include:
- Summary (what this does)
- Motivation (why it's needed)
- Changes (what was modified)
- Testing (how it was verified)
- Documentation (what was updated)
- Breaking changes (if any)

### ✅ Respond Quickly to Feedback

When Czar requests changes:
- Fix within 24 hours
- Push updates
- Comment when ready
- Don't let PRs go stale

### ✅ Test Locally Before PR

```bash
# GOOD - test before pushing
pytest tests/
# All tests pass

git push origin feature/auth
# Create PR
```

### ✅ Keep Branch Updated

Regularly merge main into your feature branch:

```bash
git checkout feature/auth
git fetch origin
git merge origin/main
# Resolve conflicts
git push origin feature/auth
```

## Integration with Other Workflows

This PR workflow integrates with:

- **`GIT_WORKFLOW.md`** - Git commit standards and branch naming
- **`DOCUMENTATION_WORKFLOW.md`** - Documentation synchronization requirements
- **`PHASE_DEVELOPMENT.md`** - Phase-based development process
- **`TOKEN_PLANNING.md`** - Token budget tracking through phases

**The Hierarchy**:
1. **PR_REQUIREMENTS.md** (This) - HOW we do PRs and reviews
2. **GIT_WORKFLOW.md** - HOW we use git (commits, branches)
3. **DOCUMENTATION_WORKFLOW.md** - WHAT docs must be updated
4. **PHASE_DEVELOPMENT.md** - HOW we organize work into phases

## Timeline Expectations

### Czar Review SLA

- ⏱️ **Initial review**: Within 24 hours of PR creation
- ⏱️ **Re-review after changes**: Within 12 hours of update
- ⏱️ **Approval and merge**: Immediately after approval

### Agent Expectations

- 🎯 **Fix feedback**: Within 24 hours of request
- 🎯 **Complete work**: Before creating PR (no WIP)
- 🎯 **Respond to questions**: In PR comments promptly
- 🎯 **Expect iteration**: Reviews are normal, not criticism

## Success Metrics

### This System is Working If:

- ✅ Documentation is always current with code
- ✅ Tests always pass on main branch
- ✅ Code quality is consistently high
- ✅ Bad commits are caught before merge
- ✅ Main branch is always stable and deployable
- ✅ No regressions from merges
- ✅ Clear history and traceability

### This System is Failing If:

- ❌ Docs still get out of sync with code
- ❌ Tests fail after merge to main
- ❌ Code quality degrades over time
- ❌ Bugs make it to main branch
- ❌ Review process becomes bottleneck
- ❌ Agents complain about process overhead

## Getting Help

**If you have questions about**:
- PR process → Read this document
- Git workflow → See `GIT_WORKFLOW.md`
- Documentation requirements → See `DOCUMENTATION_WORKFLOW.md`
- Commit standards → See `GIT_WORKFLOW.md`

**If Czar rejects your PR**:
- Read the feedback carefully
- Ask clarifying questions in PR comments
- Fix the issues thoroughly
- Resubmit for review when ready

**If you think the process is broken**:
- Discuss with human project owner
- Suggest specific improvements
- Provide concrete examples
- Rules can be refined based on experience

## Summary

### Core Rules (Must Follow)

1. ✅ **NO direct commits to main** - ALWAYS use PRs
2. ✅ **Update documentation** in same PR (VERSION, ROADMAP.md, feature docs)
3. ✅ **All tests must pass** - test locally before PR
4. ✅ **Czar reviews ALL PRs** - wait for approval before merge
5. ✅ **Czar merges** - agents NEVER merge their own PRs
6. ✅ **Complete work only** - no WIP PRs

### PR Workflow Quick Reference

```
1. Create feature branch from main
2. Develop (code + tests + docs together)
3. Self-review changes
4. Push to origin
5. Create PR with clear description
6. Czar reviews:
   - Documentation (HARD BLOCK)
   - Quality (HARD BLOCK)
   - Architecture (SOFT BLOCK)
   - Completeness (HARD BLOCK)
7. Address feedback or get approved
8. Czar merges to main
9. Done!
```

### Remember

Pull Requests are not bureaucracy - they're your **quality gate**, your **documentation enforcer**, and your **collaboration tool**. Embrace the process, and the codebase stays healthy.

---

**Source**: Extracted from [thesymposium](https://gitlab.henrynet.ca/symposium/thesymposium) `.kilocode/rules/PULL_REQUEST_REQUIREMENTS.md` and `CZAR_PR_REVIEW_PROCESS.md`.

**See Also**:
- `GIT_WORKFLOW.md` - Git commit and branch standards
- `DOCUMENTATION_WORKFLOW.md` - Documentation synchronization
- `PHASE_DEVELOPMENT.md` - Phase-based development
- `CLOSEOUT_PROCESS.md` - Project closeout procedures
