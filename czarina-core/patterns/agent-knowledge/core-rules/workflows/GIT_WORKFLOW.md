# Git Workflow for AI Agent Development

## Overview

This document defines the git workflow patterns for AI agent development, extracted from production use in thesymposium. These patterns ensure code quality, documentation synchronization, and effective collaboration between AI agents and human orchestrators.

## Core Principles

1. **PR-Based Development**: NO direct commits to main branch - ALL changes go through Pull Requests
2. **Documentation Synchronization**: Every commit MUST update relevant documentation
3. **Conventional Commits**: Structured commit messages with extensive context
4. **Branch Isolation**: One branch per feature/fix/worker
5. **Czar Review**: Human orchestrator reviews ALL PRs before merge

## Branch Strategy

### Protected Main Branch

The `main` branch is protected and requires:
- Pull Request for all changes
- Czar review and approval
- Documentation updates (blocking requirement)
- Passing tests (blocking requirement)

**Rule**: Never commit directly to main. This is a HARD rule with no exceptions.

### Branch Naming Conventions

#### Feature Branches
```
feature/<version>-<feature-name>
```

**Examples**:
- `feature/v0.4.11-service-agreements-phase1`
- `feature/v0.4.15-thread-detection`
- `feature/v1.2.0-user-authentication`

**When to use**: New feature implementation or enhancement

#### Fix Branches
```
fix/<issue-description>
```

**Examples**:
- `fix/opensearch-debian-builder`
- `fix/memory-leak-backend`
- `fix/cors-configuration`

**When to use**: Bug fixes, security patches, or corrections

#### Documentation Branches
```
docs/<doc-name>
```

**Examples**:
- `docs/documentation-redesign-2-files`
- `docs/api-reference-update`
- `docs/architecture-diagrams`

**When to use**: Documentation-only changes (rare, since docs usually change with code)

#### Version Branches
```
v<version>-<feature>
```

**Examples**:
- `v0.4.15-threading`
- `v1.2.0-authentication`

**When to use**: Major version development that spans multiple sub-features

#### Phase-Milestone Branches
```
<version>-<phase>/<tier>-<milestone>
```

**Examples**:
- `v0.4.5-phase1/tier2-week1`
- `v1.0.0-phase2/integration-testing`

**When to use**: Complex projects broken into phases with clear milestones

### Worker Branches (Czarina Orchestration)

In multi-agent orchestration, each worker gets an isolated branch:

```
worker/<worker-id>
feat/<project>-<worker-id>
```

**Examples**:
- `worker/architect`
- `worker/backend`
- `feat/agent-rules-foundation`
- `feat/agent-rules-patterns`

**Pattern**: Each worker operates in a git worktree on their dedicated branch, providing complete isolation.

## Commit Message Structure

### Format: Conventional Commits Extended

```
<type>(<scope>): <subject>

<detailed body>
- Bulleted explanations
- Technical details
- Impact analysis
- Implementation notes

New files:
- path/to/file1: Brief description
- path/to/file2: Brief description

Updated:
- path/to/file3: What changed
- VERSION: X.Y.Z (if applicable)
- ROADMAP.md: Current state updated

Docs: <documentation status>
CHANGELOG: <status>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Commit Types

| Type | Purpose | Example |
|------|---------|---------|
| `feat` | New features or capabilities | `feat(threading): Add thread search and navigation` |
| `fix` | Bug fixes | `fix(v0.4.16): Use host network mode for backend` |
| `docs` | Documentation-only changes | `docs: Update API reference for v0.4.15` |
| `refactor` | Code restructuring without behavior change | `refactor(memory): Simplify search interface` |
| `test` | Test additions or modifications | `test(threads): Add thread detection test suite` |
| `chore` | Maintenance tasks | `chore: Update dependencies to latest` |
| `perf` | Performance improvements | `perf(search): Optimize memory query indexing` |
| `style` | Code style/formatting changes | `style: Apply black formatter to backend` |
| `build` | Build system changes | `build: Update Docker base images` |
| `ci` | CI/CD configuration changes | `ci: Add GitLab pipeline for tests` |
| `merge` | Merge commits | `merge: Integrate feature/threading into main` |

### Scope

The scope indicates the area of the codebase affected:
- `(threading)`: Thread-related features
- `(v0.4.16)`: Version-specific work
- `(memory)`: Memory system
- `(backend)`: Backend services
- `(frontend)`: Frontend components
- `(docs)`: Documentation
- `(config)`: Configuration files

### Subject Line

- **Length**: 50-72 characters (hard limit: 100)
- **Capitalization**: Capitalize first word
- **Punctuation**: No period at the end
- **Voice**: Imperative mood ("Add feature" not "Added feature")
- **Clarity**: Specific and descriptive

**Good Examples**:
```
feat(v0.4.15): Add thread search and navigation functions
fix(network): Use host network mode for backend container
docs(api): Update memory interface documentation
```

**Bad Examples**:
```
Update stuff                    # Too vague
feat: added new feature.        # Wrong tense, has period
Fixed bug in the thing          # Not specific enough
```

### Detailed Body

The body should explain:
1. **What** changed (high-level summary)
2. **Why** the change was needed
3. **How** it was implemented (key decisions)
4. **Impact** on the system

Use bullet points for clarity:

**Example**:
```
feat(threading): Add thread search and navigation functions

Week 2 deliverables:
- search_thread() - Search for threads by topic with timeframe filtering
- get_thread_messages() - Retrieve all messages in a thread (chronological)
- get_thread_summary() - Generate thread metadata and key points
- Thread activity detection (_is_thread_active)
- Thread grouping and summary generation
- Integration tests (10 test cases)

New capabilities:
- Search threads by topic: 'Show me our thread about healthcare'
- Filter by timeframe: day/week/month/all
- Get thread summaries with key points
- Navigate thread history
- Detect active vs inactive threads

Test coverage:
- Thread search with multiple threads
- Timeframe filtering
- Thread message retrieval
- Thread summary generation
- Thread activity status
- Thread-aware memory search

Part of v0.4.15 Phase 1 Week 2: Thread-Aware Search (COMPLETE)
```

### File Listings

List new files and updated files for clarity:

```
New files:
- src/services/thread_service.py: Thread detection and grouping
- src/api/thread_routes.py: Thread search endpoints
- tests/test_thread_search.py: Thread search test suite
- docs/THREAD_DETECTION_GUIDE.md: User guide

Updated:
- src/services/memory_service.py: Thread-aware search integration
- VERSION: 0.4.15
- ROADMAP.md: Current state updated to Phase 1 Week 2 complete
- CHANGELOG.md: Added v0.4.15 release notes
```

### Documentation Status

Every commit should indicate documentation status:

```
Docs: Updated (VERSION, ROADMAP.md, THREAD_DETECTION_GUIDE.md)
CHANGELOG: Pending (Czar will update on merge)
```

or

```
Docs: Not required (internal refactoring only)
CHANGELOG: N/A
```

### Attribution

All AI-generated commits should include:

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Real-World Examples

### Example 1: Feature Implementation

```
feat(v0.4.16): Infrastructure modernization with OpenSearch node deployment

- Valkey 9.0: Open source Redis replacement (BSD license)
- RabbitMQ 4.2: Performance improvements (fresh start)
- Next.js 15.1.3 + React 18.3.1: Modern frontend stack
- OpenSearch node deployment: Support for remote OpenSearch 3.4.0 nodes
- Container rename: symposium-redis → symposium-valkey
- Hardware limitation: AMD FX-8350 lacks AVX2, OpenSearch 3.4 requires remote deployment

New files:
- docker-compose.opensearch-node.yml: Deploy OpenSearch 3.4.0 on remote machines
- opensearch-node-ctl.sh: Control script for remote nodes
- scripts/maintenance/migrate_opensearch_data_to_paragon.sh: Data migration utility
- docs/OPENSEARCH_NODE_DEPLOYMENT.md: Quick start guide
- docs/V0.4.16_OPENSEARCH_CLUSTER_EXPANSION.md: Cluster expansion guide
- docs/fixes/OPENSEARCH_3.4_KNN_CPU_COMPATIBILITY.md: Hardware limitation documentation

Updated:
- VERSION: 0.4.16
- CHANGELOG.md: Complete release notes for v0.4.16
- ROADMAP.md: Current state updated to v0.4.16 in progress
- symposium-ctl.sh: Updated Valkey container name mapping

Docs: Complete (VERSION, CHANGELOG.md, ROADMAP.md, 3 new docs)
CHANGELOG: Updated

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Example 2: Bug Fix

```
fix(v0.4.16): Use host network mode for backend to reach Paragon

- Backend container needs host network to reach Paragon (192.168.14.7)
- Docker bridge network isolates container from external IPs
- Host network mode allows backend to reach Paragon's OpenSearch cluster

Technical details:
- Changed docker-compose.yml backend network mode to 'host'
- Removed port mapping (not needed with host network)
- Backend can now resolve and connect to 192.168.14.7:9200

Fixes: Connection refused error to 192.168.14.7:9200

Docs: Not required (configuration fix only)
CHANGELOG: Pending

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Example 3: Documentation Update

```
docs(v0.4.15): Add thread detection implementation guide

- Created comprehensive guide for thread detection system
- Includes architecture diagrams and API examples
- Documents thread search, navigation, and summary functions
- Provides troubleshooting section for common issues

New files:
- docs/THREAD_DETECTION_GUIDE.md: Complete implementation guide (520 lines)

Updated:
- docs/00_INDEX.md: Added thread detection guide to index
- ROADMAP.md: Marked documentation as complete

Docs: Complete
CHANGELOG: N/A (documentation only)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Git Configuration

### Recommended Configuration

```ini
[core]
    repositoryformatversion = 0
    filemode = true
    bare = false
    logallrefupdates = true

[remote "origin"]
    url = git@gitlab.example.com:project/repo.git
    fetch = +refs/heads/*:refs/remotes/origin/*

[branch "main"]
    remote = origin
    merge = refs/heads/main

[user]
    name = Your Name
    email = your.email@example.com

[pull]
    rebase = false

[init]
    defaultBranch = main
```

### Useful Git Aliases

Add these to your `.gitconfig`:

```ini
[alias]
    # View commit log with graph
    lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit

    # View recent commits
    recent = log --oneline -10

    # Create feature branch
    fb = "!f() { git checkout -b feature/$1; }; f"

    # Create fix branch
    fixb = "!f() { git checkout -b fix/$1; }; f"

    # Show files changed in current branch vs main
    changed = diff --name-only main...HEAD

    # Show detailed diff vs main
    review = diff main...HEAD
```

## Pull Request Workflow

### 1. Create Feature Branch

```bash
# From main branch
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/v1.2.0-authentication
```

### 2. Develop and Commit

```bash
# Make changes
# ...

# Stage changes
git add .

# Commit with detailed message
git commit -m "feat(auth): Add JWT authentication system

- Implemented JWT token generation and validation
- Added login and logout endpoints
- Created user session management
- Added token refresh mechanism

New files:
- src/auth/jwt_service.py: JWT token handling
- src/api/auth_routes.py: Authentication endpoints
- tests/test_auth.py: Auth test suite (15 tests)

Updated:
- src/config/settings.py: Added JWT secret configuration
- VERSION: 1.2.0
- ROADMAP.md: Auth implementation complete

Docs: Complete (VERSION, ROADMAP.md)
CHANGELOG: Pending

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 3. Push Branch

```bash
git push -u origin feature/v1.2.0-authentication
```

### 4. Create Pull Request

Create PR with:
- **Title**: Same as commit subject (or summary of all commits)
- **Description**:
  - Link to planning document
  - Summary of changes
  - Testing performed
  - Documentation updated
  - Screenshots (if UI changes)

**Example PR Description**:
```markdown
## Summary
Implements JWT authentication system for v1.2.0.

## Changes
- JWT token generation and validation
- Login/logout endpoints
- User session management
- Token refresh mechanism

## Testing
- All 15 authentication tests passing
- Manual testing: login, logout, token refresh
- Security audit: token expiry, signature validation

## Documentation
- ✅ VERSION updated to 1.2.0
- ✅ ROADMAP.md current state updated
- ✅ Created AUTH_GUIDE.md
- ⏳ CHANGELOG.md (Czar will update on merge)

## Planning Document
See docs/V1.2.0_AUTHENTICATION_PLAN.md

## Related Issues
Closes #42
```

### 5. Czar Review

The Czar (human orchestrator) reviews for:
- **Documentation completeness**: VERSION, ROADMAP.md updated
- **Code quality**: Clean, maintainable code
- **Architecture alignment**: Follows project patterns
- **Test coverage**: Comprehensive tests
- **Security**: No vulnerabilities introduced

### 6. Address Feedback

```bash
# Make requested changes
# ...

# Commit changes
git commit -m "fix(auth): Address Czar review feedback

- Increased token expiry to 24 hours (was 1 hour)
- Added rate limiting to login endpoint
- Improved error messages for invalid credentials

Updated:
- src/auth/jwt_service.py: Token expiry configuration
- src/api/auth_routes.py: Rate limiting and error handling
- docs/AUTH_GUIDE.md: Updated with rate limiting info

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push updates
git push origin feature/v1.2.0-authentication
```

### 7. Merge (Czar Only)

**The Czar performs the merge**:

```bash
# Checkout main
git checkout main
git pull origin main

# Merge feature branch
git merge --no-ff feature/v1.2.0-authentication

# Update CHANGELOG.md
# (Czar manually updates CHANGELOG.md with release notes)

# Commit CHANGELOG update
git commit -m "chore(release): Update CHANGELOG.md for v1.2.0

Added:
- JWT authentication system
- Login/logout endpoints
- User session management
- Token refresh mechanism

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to main
git push origin main

# Tag release
git tag -a v1.2.0 -m "Release v1.2.0: Authentication System"
git push origin v1.2.0

# Delete feature branch (optional)
git branch -d feature/v1.2.0-authentication
git push origin --delete feature/v1.2.0-authentication
```

## Merge Strategies

### Feature Branches

Use `--no-ff` (no fast-forward) for feature merges to preserve history:

```bash
git merge --no-ff feature/v1.2.0-authentication
```

**Why**: Preserves the feature branch history and makes it clear when features were integrated.

### Hotfix Branches

Can use fast-forward for small hotfixes:

```bash
git merge fix/typo-in-readme
```

### Conflict Resolution

When conflicts occur:

```bash
# Attempt merge
git merge feature/v1.2.0-authentication

# Conflicts occur
# Auto-merging src/config/settings.py
# CONFLICT (content): Merge conflict in src/config/settings.py

# Resolve conflicts manually in affected files
# Look for conflict markers:
# <<<<<<< HEAD
# (main branch version)
# =======
# (feature branch version)
# >>>>>>> feature/v1.2.0-authentication

# After resolving, stage files
git add src/config/settings.py

# Complete merge
git commit -m "merge: Integrate v1.2.0 authentication into main

Resolved conflicts:
- src/config/settings.py: Merged JWT config with existing settings

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## Multi-Agent Coordination (Czarina Pattern)

### Worker Isolation with Git Worktrees

Each AI agent worker operates in an isolated git worktree:

```bash
# Create worktree for worker
git worktree add .czarina/worktrees/foundation worker/foundation

# Worker develops in isolation
cd .czarina/worktrees/foundation
# ... agent works here ...

# When complete, worker commits and pushes
git add .
git commit -m "feat(foundation): Complete core pattern extraction

- Extracted 15 core patterns from thesymposium
- Created 5 foundation documents
- Added cross-references between patterns

Docs: Complete
CHANGELOG: Pending

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git push origin worker/foundation
```

### Integration Branch (QA Worker)

A QA worker creates an omnibus integration branch:

```bash
# QA worker creates integration branch
git checkout -b cz1/release/v0.6.0

# Merge all worker branches
git merge --no-ff worker/foundation
git merge --no-ff worker/patterns
git merge --no-ff worker/workflows
git merge --no-ff worker/templates

# Resolve any conflicts
# ...

# Test integrated system
# ...

# Push integration branch
git push origin cz1/release/v0.6.0

# Create PR to main
# Czar reviews and merges
```

## Common Patterns

### Amending Last Commit

**Use sparingly** - only for typos or small fixes to the most recent commit:

```bash
# Fix typo
# ...

# Amend last commit
git add .
git commit --amend --no-edit

# Force push (ONLY if not pushed to main)
git push --force origin feature/v1.2.0-authentication
```

**WARNING**: Never amend commits that have been pushed to main or reviewed by others.

### Squashing Commits

For cleanup before PR merge:

```bash
# Interactive rebase
git rebase -i main

# In editor, mark commits to squash:
# pick abc123 feat(auth): Add JWT service
# squash def456 fix(auth): Fix token expiry
# squash ghi789 test(auth): Add auth tests

# Result: Single clean commit
```

### Cherry-Picking

To apply a specific commit to another branch:

```bash
# On target branch
git checkout main

# Cherry-pick commit
git cherry-pick abc123

# Resolve conflicts if any
# ...

# Commit
git commit
```

## Anti-Patterns (What NOT to Do)

### ❌ Direct Commits to Main

```bash
# NEVER DO THIS
git checkout main
git commit -m "Quick fix"
git push origin main
```

**Why**: Bypasses PR review, documentation requirements, and quality gates.

### ❌ Vague Commit Messages

```bash
# BAD
git commit -m "Update stuff"
git commit -m "Fix bug"
git commit -m "Changes"
```

**Why**: No context for future developers or Czar review.

### ❌ Missing Documentation Updates

```bash
# BAD - changed code but didn't update VERSION or ROADMAP.md
git commit -m "feat(auth): Add authentication"
# (VERSION still shows old version, ROADMAP.md not updated)
```

**Why**: Documentation drift causes confusion and wasted effort.

### ❌ Force Push to Main

```bash
# NEVER DO THIS
git push --force origin main
```

**Why**: Destroys history, breaks other developers' work.

### ❌ Committing Secrets

```bash
# NEVER DO THIS
git add .env
git add credentials.json
git commit -m "Add config"
```

**Why**: Security vulnerability, credentials exposed in git history.

### ❌ Giant Commits

```bash
# BAD - changed 50 files, 5000 lines
git commit -m "Implement entire feature"
```

**Why**: Impossible to review, hard to debug, difficult to revert.

## Best Practices

### ✅ Commit Frequently

Make small, logical commits as you work:

```bash
# Good progression
git commit -m "feat(auth): Add JWT service skeleton"
git commit -m "feat(auth): Implement token generation"
git commit -m "feat(auth): Add token validation"
git commit -m "test(auth): Add JWT service tests"
```

### ✅ Write for Future Developers

Your commit message should explain WHY and HOW, not just WHAT:

```bash
# GOOD
git commit -m "fix(auth): Use constant-time comparison for token validation

- Replaced == with secrets.compare_digest()
- Prevents timing attacks on token validation
- Security best practice for cryptographic comparisons

Reference: OWASP Authentication Cheat Sheet"
```

### ✅ Test Before Committing

```bash
# Run tests
pytest tests/

# If tests pass, commit
git add .
git commit -m "feat(auth): Add token refresh endpoint

All 23 auth tests passing."
```

### ✅ Keep Branches Updated

Regularly merge main into your feature branch:

```bash
git checkout feature/v1.2.0-authentication
git fetch origin
git merge origin/main

# Resolve conflicts
# ...

# Continue working
```

### ✅ Use .gitignore

Prevent committing unwanted files:

```gitignore
# .gitignore
__pycache__/
*.pyc
.env
.env.local
*.log
.DS_Store
node_modules/
dist/
build/
*.swp
.vscode/
.idea/
```

## Troubleshooting

### Accidentally Committed to Main

```bash
# If not pushed yet
git reset --soft HEAD~1  # Undo commit, keep changes
git checkout -b feature/my-feature  # Create proper branch
git commit  # Commit on feature branch

# If already pushed (requires Czar intervention)
# Contact Czar immediately
```

### Forgot to Update Documentation

```bash
# Amend last commit (if not pushed)
# Update VERSION and ROADMAP.md
git add VERSION ROADMAP.md
git commit --amend

# Or create follow-up commit (if already pushed)
git commit -m "docs: Update VERSION and ROADMAP.md for v1.2.0

- VERSION: Updated to 1.2.0
- ROADMAP.md: Current state updated with auth completion

Missed in previous commit: abc123"
```

### Merge Conflicts

```bash
# Pull latest main
git checkout feature/my-feature
git merge main

# Conflicts appear
# Edit files to resolve conflicts
# Remove conflict markers (<<<<<<<, =======, >>>>>>>)

# Stage resolved files
git add resolved-file.py

# Complete merge
git commit -m "merge: Integrate main into feature/my-feature

Resolved conflicts in resolved-file.py"
```

### Wrong Branch

```bash
# Made changes on main instead of feature branch
git stash  # Save changes
git checkout -b feature/my-feature  # Create proper branch
git stash pop  # Apply changes
git add .
git commit -m "feat: Proper commit on feature branch"
```

## Summary

### Core Rules (Must Follow)

1. ✅ **NO direct commits to main** - always use PRs
2. ✅ **Update documentation** in every commit (VERSION, ROADMAP.md)
3. ✅ **Use conventional commits** with detailed body text
4. ✅ **Czar reviews all PRs** - wait for approval
5. ✅ **Test before committing** - no broken commits
6. ✅ **Never commit secrets** - use .gitignore

### Key Patterns

- **Branch naming**: `feature/<version>-<name>`, `fix/<issue>`, `docs/<name>`
- **Commit format**: `<type>(<scope>): <subject>\n\n<detailed body>`
- **PR workflow**: Branch → Develop → Commit → Push → PR → Review → Merge
- **Multi-agent**: One branch per worker, QA integration branch
- **Czar responsibilities**: Review PRs, merge to main, update CHANGELOG.md

### Documentation Requirements

Every commit that completes work must update:
- `VERSION` file (if version changes)
- `ROADMAP.md` (Current State section)
- Phase/feature docs (if applicable)

Czar updates `CHANGELOG.md` during merge operation.

### Remember

Git is not just version control - it's your communication tool with future developers (including future AI agents). Write commits that you would want to read when debugging at 2 AM.

---

## Related Patterns

For specific implementation patterns and real-world examples, see:
- [Git Workflows](../../patterns/git-workflows/README.md) - Branch strategies, commit patterns, PR workflows
- [Git Workflow Patterns: Branch Strategies](../../patterns/git-workflows/branch-strategies.md) - Feature branches, worker branches
- [Git Workflow Patterns: Commit Patterns](../../patterns/git-workflows/commit-patterns.md) - Conventional commits, AI-generated messages
- [Git Workflow Patterns: PR Workflows](../../patterns/git-workflows/pr-workflows.md) - AI-generated PR descriptions
- [Git Workflow Patterns: Conflict Resolution](../../patterns/git-workflows/conflict-resolution.md) - Prevention and resolution strategies

---

**Source**: Extracted from [thesymposium](https://gitlab.henrynet.ca/symposium/thesymposium) production git history and workflow patterns.

**See Also**:
- `PR_REQUIREMENTS.md` - Detailed PR review criteria
- `DOCUMENTATION_WORKFLOW.md` - Documentation synchronization patterns
- `PHASE_DEVELOPMENT.md` - Phase-based development workflow

## Related Patterns

For specific git workflow patterns and examples, see:
- [Git Workflow Patterns](../../patterns/git-workflows/README.md) - Battle-tested patterns and examples
