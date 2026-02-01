# Documentation Workflow for AI Agent Development

## Overview

This document defines documentation standards and workflows for AI agent development projects. These patterns ensure documentation stays synchronized with code, prevents documentation drift, and maintains clear project status visibility.

## Core Principle

**🚨 CRITICAL: Documentation MUST be updated in the SAME commit as code changes.**

Documentation drift causes confusion, wasted effort, duplicate work, and hours of unnecessary investigation. This workflow prevents that pain.

## The Problem Documentation Solves

### What Happens Without Disciplined Documentation

**Scenario**: An AI agent completes a feature but doesn't update documentation.

**Timeline**:
1. **Day 1**: Agent implements authentication system, commits code
2. **Day 1**: Agent doesn't update VERSION or ROADMAP.md
3. **Day 3**: Czar reviews project status
4. **Day 3**: ROADMAP.md still shows auth as "In Progress"
5. **Day 3**: Czar spends 30 minutes investigating "what's actually done?"
6. **Day 4**: Another agent starts planning "auth implementation" (duplicate work)
7. **Day 5**: Human discovers auth was already done days ago
8. **Result**: Hours wasted, confusion, frustration

### What Happens With Disciplined Documentation

**Scenario**: Agent completes feature and updates docs in same commit.

**Timeline**:
1. **Day 1**: Agent implements auth, updates VERSION + ROADMAP.md in same commit
2. **Day 3**: Czar reviews project status by reading ROADMAP.md
3. **Day 3**: Status review takes 2 minutes - everything is current
4. **Day 4**: Next agent reads ROADMAP.md, sees auth complete, works on next feature
5. **Result**: No wasted time, clear status, efficient workflow

## The 2-File Core Documentation Pattern

Modern AI development projects should use a simplified 2-file core documentation structure, plus VERSION file and CHANGELOG.

### File 1: README.md (The Timeless Overview)

**Purpose**: "What is this project?"

**Audience**: New users, contributors, anyone discovering the project

**Update Frequency**: Rarely (only when core capabilities change)

**Length**: ~400-500 lines maximum

**Content**:
- Project name and tagline
- What the project does (high-level)
- Core features and capabilities
- Quick start guide
- Architecture overview (high-level)
- Links to detailed documentation
- Development setup basics

**What it does NOT include**:
- Current version details (use VERSION file)
- Current status (use ROADMAP.md)
- Detailed feature plans (use ROADMAP.md)
- Work-in-progress notes (use ROADMAP.md "Current State")

**Example Structure**:
```markdown
# Project Name
### Brief tagline

![Version Badge](link-to-version-from-VERSION-file)

## What is [Project]?
[Timeless overview - doesn't change with versions]

## Core Features
- Feature 1: Description
- Feature 2: Description
- Feature 3: Description

## Quick Start
[Getting started instructions]

## Architecture
[High-level architecture overview]

## Documentation
- [ROADMAP.md](ROADMAP.md) - Current status and future plans
- [Full Documentation](docs/) - Complete documentation index

## Development
[Development setup basics]

## License
[License information]
```

### File 2: ROADMAP.md (Current State + Future Plans)

**Purpose**: "Where are we? Where are we going?"

**Audience**: Developers, project managers, AI agents

**Update Frequency**: Every version/phase/feature completion

**Length**: As long as needed (1000+ lines is fine)

**Content**:
1. **Current State** section (top of file - always current)
2. **Detailed version plans** (near-term work)
3. **Long-term vision** (future versions)
4. **Completed work** (recent completions)

**Critical Pattern**: The "Current State" section at the top must ALWAYS be accurate.

**Example Structure**:
```markdown
# Project Name - Roadmap

**Last Updated**: 2025-12-22
**Current Version**: v1.2.0 Phase 1 (from VERSION file)

---

## 📍 Current State

### What We Just Finished (Latest 2-3 only)
- v1.2.0: Authentication System (Dec 22)
- v1.1.0: User Management (Dec 20)
- v1.0.5: Bug fixes and optimization (Dec 19)

### Current Work
- v1.2.0 Phase 2: Token refresh and session management (MR #45)
- Bug fix: Rate limiting on login endpoint (MR #46)

### Next Up
- v1.3.0: Authorization & Permissions
- v1.4.0: API Rate Limiting
- Performance optimization: Database query caching

### Known Issues
- Rate limiting not working on mobile app
- Session cookies expire too quickly (fix in progress)

---

## 🚀 Detailed Version Plans

### v1.3.0 - Authorization & Permissions ⏳ IN PROGRESS

**Started**: 2025-12-22
**Estimated Effort**: M (800K-1.2M tokens)
**Status**: 🟡 ACTIVE DEVELOPMENT

#### Core Features
- [ ] Role-based access control (RBAC)
- [ ] Permission management UI
- [ ] API endpoint protection
- [ ] Admin dashboard for permissions

#### Deliverables
- Role management system
- Permission middleware
- Admin UI components
- Comprehensive tests

---

### v1.2.0 - Authentication System ✅ COMPLETE

**Completed**: 2025-12-22
**Effort**: ~200K tokens (75% under 800K-1.2M estimate!)
**Status**: 🟢 RELEASED

#### Delivered Features ✅
- ✅ JWT authentication
- ✅ Login/logout endpoints
- ✅ Token refresh mechanism
- ✅ Session management

---

## 🗺️ Long-Term Vision

### v2.0 - Multi-tenancy (6-8 months)
[High-level overview]

### v3.0 - Enterprise Features (12+ months)
[High-level overview]
```

### File 3: VERSION (Single Source of Truth)

**Purpose**: Machine-readable version information

**Update Frequency**: Every version change

**Format**: Simple key=value pairs

**Content**:
```bash
CURRENT_VERSION=1.2.0
CURRENT_PHASE=Phase 2
CURRENT_STATUS=In Progress
LAST_COMPLETED=1.1.0
LAST_UPDATED=2025-12-22T10:30:00-05:00
LAST_UPDATED_UTC=2025-12-22T15:30:00Z
NEXT_VERSION=1.3.0
```

**Why**: Single source of truth prevents version number drift across documentation.

**Usage**: Reference in badges, scripts, and documentation.

### File 4: CHANGELOG.md (Release History)

**Purpose**: User-facing release notes

**Maintained By**: **Czar** (human orchestrator)

**Update Frequency**: On every merge to main (or at version completion for batch releases)

**Format**: [Keep a Changelog](https://keepachangelog.com/) format

**Content**:
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.2.0] - 2025-12-22

### Added
- **Authentication System**: JWT-based authentication with login/logout
  - Token generation and validation
  - Session management
  - Rate limiting on auth endpoints
  - Comprehensive test coverage (92%)

### Fixed
- **Session Management**: Fixed session cookie expiry timing
- **Rate Limiting**: Resolved rate limiting bypass on certain endpoints

### Changed
- **Token Expiry**: Increased from 1 hour to 24 hours based on user feedback

## [1.1.0] - 2025-12-20

### Added
- **User Management**: CRUD operations for users
  - User creation and deletion
  - Profile management
  - Admin user interface
```

**Critical**: Czar is responsible for keeping CHANGELOG.md current. It should NEVER be stale.

## Mandatory Documentation Updates

### The Iron Rule

**When ANY agent completes work, they MUST update:**

1. **VERSION file** (if version changed)
2. **ROADMAP.md** (always - "Current State" section)
3. **Feature docs** (if new feature or significant change)
4. **Code comments** (for complex logic)

**In the SAME commit as the code changes.**

**Czar updates CHANGELOG.md** during merge operation (or at version completion).

### When to Update VERSION

Update VERSION file when:
- ✅ Starting a new version
- ✅ Completing a version
- ✅ Changing version number
- ✅ Changing phase
- ✅ Changing status (In Progress → Complete)

**Do NOT update VERSION for**:
- ❌ Bug fixes within a version
- ❌ Feature additions within current version
- ❌ Documentation-only changes

### When to Update ROADMAP.md

**ALWAYS update ROADMAP.md** when:
- ✅ Completing any feature
- ✅ Completing any bug fix
- ✅ Completing a phase
- ✅ Completing a version
- ✅ Starting new work
- ✅ Discovering blockers
- ✅ Changing priorities

**Update the "Current State" section**:
- Move completed work to "What We Just Finished"
- Update "Current Work" to reflect reality
- Update "Next Up" if priorities changed
- Add/remove items from "Known Issues"

### Commit Message Pattern

```
<type>(<scope>): <subject>

<detailed body>
- Key changes
- Implementation notes

New files:
- path/to/file1: Description

Updated:
- VERSION: X.Y.Z (if changed)
- ROADMAP.md: Current state updated (what changed)
- docs/FEATURE_GUIDE.md: Added examples

Docs: Complete (VERSION, ROADMAP.md, FEATURE_GUIDE.md)
CHANGELOG: Pending (Czar will update)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Documentation Organization

### Directory Structure

```
project/
├── README.md                          # What is this?
├── ROADMAP.md                         # Where are we going?
├── VERSION                            # Version information
├── CHANGELOG.md                       # Release history (Czar maintains)
│
├── docs/
│   ├── 00_INDEX.md                   # Documentation index
│   ├── architecture/                 # System design docs
│   ├── user-guides/                  # End-user documentation
│   ├── api/                          # API documentation
│   ├── deployment/                   # Operations guides
│   │
│   ├── development/                  # AI agent workspace
│   │   ├── README.md                 # Workspace guidelines
│   │   ├── V1.2.0_PHASE_1.md        # Active work docs
│   │   └── NOTES_FEATURE.md         # Work notes
│   │
│   ├── ideas/                        # Feature proposals
│   │   ├── README.md                 # Ideas workflow
│   │   ├── auth-improvements.md     # Idea (any format)
│   │   └── archive/                  # Ingested ideas
│   │       └── 2025-12/
│   │           └── 2025-12-15_mobile-app.md
│   │
│   ├── fixes/                        # Active bug fixes
│   │   ├── README.md                 # Fix documentation guide
│   │   ├── RATE_LIMITING_FIX.md     # Current fix (< 1 month)
│   │   └── archive/                  # Stable fixes
│   │
│   └── archive/                      # Historical documentation
│       └── development-history/
│           └── 2025-12/
│               ├── V1.1.0_COMPLETION.md
│               └── V1.1.0_PLAN.md
│
└── .kilocode/                        # Development rules
    └── rules/                        # AI agent guidelines
```

### docs/development/ (AI Agent Workspace)

**Purpose**: Work-in-progress documentation for active development

**Use for**:
- ✅ Active version implementation (e.g., `V1.2.0_PHASE_1.md`)
- ✅ Ongoing bug investigations
- ✅ Work notes and scratch files
- ✅ Multi-session AI agent work
- ✅ Complex change planning

**Move when**:
- Version complete → `docs/archive/development-history/YYYY-MM/`
- Bug fixed → `docs/fixes/` (then archive after >1 month stable)
- Work complete → Extract to permanent docs, delete scratch

**Best Practices**:
1. Create work docs for anything taking >1 session
2. Update regularly with dated progress entries
3. Document decisions and rationale
4. Clean up when work is complete
5. Move to archive only when version complete

### docs/ideas/ (Feature Staging Area)

**Purpose**: Capture feature ideas before roadmap integration

**Workflow**:
1. **Capture**: Drop idea in `docs/ideas/` (any filename, any format)
2. **Review**: Weekly review of ideas
3. **Process**: Format, timestamp, decide
4. **Archive**: Move to `docs/ideas/archive/YYYY-MM/` with ingestion date
5. **Act**: Add to roadmap/tasks as appropriate

**Example**:
```
docs/ideas/
├── mobile-app.md                    # Raw idea (any format)
├── better-search.md                 # Raw idea
└── archive/
    └── 2025-12/
        ├── 2025-12-15_mobile-app.md      # Ingested (timestamped)
        └── 2025-12-18_ai-assistant.md    # Ingested
```

### docs/fixes/ (Active Bug Fixes)

**Purpose**: Currently active bug fixes and ongoing issues

**Use for**:
- ✅ Fixes being worked on
- ✅ Recently deployed fixes (< 1 month)
- ✅ Fixes requiring monitoring

**Move when**:
- Stable >1 month → `docs/fixes/archive/`

**Example**:
```
docs/fixes/
├── README.md
├── RATE_LIMITING_FIX.md          # Active (deployed 2 weeks ago)
├── SESSION_TIMEOUT_FIX.md        # Active (in progress)
└── archive/
    ├── AUTH_BUG_FIX.md           # Stable >1 month
    └── CACHE_INVALIDATION_FIX.md # Stable >1 month
```

### docs/archive/ (Historical Record)

**Purpose**: Completed work for historical reference

**Archive when**:
- ✅ Entire VERSION complete and in production
- ✅ All phases documented and verified
- ✅ Release notes published

**Example**:
```
docs/archive/
└── development-history/
    ├── 2025-11/
    │   ├── V1.0.0_PLAN.md
    │   └── V1.0.0_COMPLETION.md
    └── 2025-12/
        ├── V1.1.0_PLAN.md
        ├── V1.1.0_COMPLETION.md
        ├── V1.2.0_PLAN.md
        └── V1.2.0_COMPLETION.md
```

## Documentation Workflow Patterns

### Pattern 1: Starting New Feature Work

```markdown
# 1. Read current state
cat VERSION
cat ROADMAP.md  # Check "Current State" section

# 2. Create work doc (if multi-step or multi-session)
# In docs/development/
V1.3.0_AUTHORIZATION_PHASE_1.md

# 3. Begin implementation
# ... code changes ...

# 4. Update work doc with progress
# Add dated entries, decisions, blockers
```

### Pattern 2: Completing Feature Within Version

```markdown
# 1. Finish implementation
# ... complete code changes ...

# 2. Update ROADMAP.md "Current State"
## 📍 Current State

### What We Just Finished
- v1.3.0 Phase 1: RBAC implementation (Dec 23) ← ADDED

### Current Work
- v1.3.0 Phase 2: Permission UI (MR #48) ← UPDATED

# 3. Commit with documentation updates
git add .
git commit -m "feat(auth): Complete RBAC implementation

- Role-based access control working
- Middleware for permission checking
- Tests passing (95% coverage)

Updated:
- ROADMAP.md: Phase 1 complete, moved to 'Just Finished'
- docs/AUTH_GUIDE.md: Added RBAC examples

Docs: Complete
CHANGELOG: Pending"
```

### Pattern 3: Completing Entire Version

```markdown
# 1. Finish all version work
# ... all phases complete ...

# 2. Update VERSION file
CURRENT_VERSION=1.4.0        ← INCREMENT
CURRENT_PHASE=Phase 1
CURRENT_STATUS=In Progress
LAST_COMPLETED=1.3.0         ← UPDATE
LAST_UPDATED=2025-12-23T14:00:00-05:00  ← UPDATE
NEXT_VERSION=1.5.0           ← UPDATE

# 3. Update ROADMAP.md
## 📍 Current State

### What We Just Finished
- v1.3.0: Authorization & Permissions (Dec 23) ← ADDED

### Current Work
- v1.4.0 Phase 1: API Rate Limiting (MR #50) ← UPDATED

---

### v1.3.0 - Authorization & Permissions ✅ COMPLETE  ← UPDATED

**Completed**: 2025-12-23  ← ADDED
**Status**: 🟢 RELEASED    ← UPDATED

# 4. Create completion document
docs/V1.3.0_COMPLETION.md

# 5. Archive planning documents
mv docs/development/V1.3.0_*.md docs/archive/development-history/2025-12/

# 6. Commit all updates
git commit -m "feat(v1.3.0): Complete authorization system

- All phases complete
- VERSION updated (1.3.0 → 1.4.0)
- ROADMAP.md updated (v1.3.0 marked complete)
- Created V1.3.0_COMPLETION.md
- Archived planning docs

Docs: Complete
CHANGELOG: Pending (Czar will update)"
```

### Pattern 4: Bug Fix

```markdown
# 1. Fix the bug
# ... code changes ...

# 2. Update ROADMAP.md "Current State"
## 📍 Current State

### What We Just Finished
- Fixed: Rate limiting bypass vulnerability (Dec 23) ← ADDED

### Known Issues
- ~~Rate limiting bypass~~ ← FIXED (strikethrough)

# 3. Create fix documentation
docs/fixes/RATE_LIMITING_FIX.md

# 4. Commit with docs
git commit -m "fix(auth): Patch rate limiting bypass vulnerability

- Fixed bypass using alternate endpoint
- Added test to prevent regression
- Updated rate limit middleware

Updated:
- ROADMAP.md: Added to 'Just Finished', removed from 'Known Issues'
- docs/fixes/RATE_LIMITING_FIX.md: Documentation of fix

Docs: Complete
CHANGELOG: Pending"
```

### Pattern 5: Czar Updates CHANGELOG

**When**: On every merge to main (or at version completion for batch releases)

**Czar Process**:

```markdown
# 1. Review what was merged
git log v1.2.0..HEAD --oneline

# 2. Update CHANGELOG.md
## [1.3.0] - 2025-12-23

### Added
- **Authorization System**: Role-based access control
  - RBAC middleware with permission checking
  - Role management UI
  - Admin dashboard for permissions
  - Comprehensive tests (95% coverage)

### Fixed
- **Rate Limiting**: Patched bypass vulnerability on auth endpoints

### Changed
- **Session Duration**: Extended from 1 hour to 8 hours for better UX

# 3. Commit CHANGELOG update
git commit -m "docs(changelog): Update for v1.3.0 release

Added authorization system and rate limiting fix.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## File Naming Conventions

### Version Planning Documents

```
V{VERSION}_{FEATURE}_PLAN.md
V{VERSION}_PHASE_{N}.md
V{VERSION}_MIGRATION_GUIDE.md
```

**Examples**:
- `V1.3.0_AUTHORIZATION_PLAN.md`
- `V1.3.0_PHASE_1.md`
- `V2.0.0_MIGRATION_GUIDE.md`

### Version Completion Documents

```
V{VERSION}_COMPLETION.md
V{VERSION}_PHASE_{N}_COMPLETION.md
```

**Examples**:
- `V1.3.0_COMPLETION.md`
- `V1.3.0_PHASE_1_COMPLETION.md`

### Bug Fix Documents

```
{COMPONENT}_{ISSUE}_FIX.md
{FEATURE}_INVESTIGATION.md
```

**Examples**:
- `RATE_LIMITING_FIX.md`
- `AUTH_BYPASS_INVESTIGATION.md`
- `SESSION_TIMEOUT_FIX.md`

### Work Notes

```
NOTES_{TOPIC}.md
WIP_{FEATURE}.md
SCRATCH_{EXPERIMENT}.md
```

**Examples**:
- `NOTES_MIGRATION.md`
- `WIP_MOBILE_APP.md`
- `SCRATCH_REDIS_EXPERIMENT.md`

### Ideas (Before Ingestion)

```
any-filename-works.md
```

**Examples**:
- `better-auth.md`
- `mobile-app-idea.md`
- `performance-optimization.md`

### Ideas (After Ingestion)

```
YYYY-MM-DD_{DESCRIPTIVE_NAME}.md
```

**Examples**:
- `2025-12-23_mobile-app-proposal.md`
- `2025-12-20_redis-caching.md`

## Anti-Patterns (What NOT to Do)

### ❌ Don't: Update Docs Later

```bash
# BAD
git commit -m "feat(auth): Add authentication system"
# (Forgot to update VERSION and ROADMAP.md)

# ... 3 days later ...
# "Oh, I should update the docs"
```

**Why**: Documentation drift happens immediately. Update in the SAME commit.

### ❌ Don't: Assume Docs Are Current

```bash
# BAD - agent reads ROADMAP.md and assumes it's accurate
# Plans work based on outdated information
# Duplicates work already done
```

**Why**: Always verify docs are current by checking commit dates and git history.

### ❌ Don't: Create Version Docs in Root

```bash
# BAD
docs/
└── V1.3.0_PLAN.md  # Wrong location

# GOOD
docs/development/
└── V1.3.0_PLAN.md  # Correct - active work
```

**Why**: Keep active work separate from permanent documentation.

### ❌ Don't: Skip Intermediate Updates

```bash
# BAD - work on feature for 3 days, update docs at end
Day 1: Code changes
Day 2: Code changes
Day 3: Code changes + update docs

# GOOD - update docs with each meaningful commit
Day 1: Code changes + update ROADMAP ("started auth")
Day 2: Code changes + update ROADMAP ("auth login working")
Day 3: Code changes + update ROADMAP ("auth complete")
```

**Why**: Intermediate updates keep status accurate and visible.

### ❌ Don't: Archive Incomplete Work

```bash
# BAD
mv docs/development/V1.3.0_PLAN.md docs/archive/
# (Version not actually complete)
```

**Why**: Archive only when version is 100% complete and released.

### ❌ Don't: Leave Scratch Files Forever

```bash
# BAD
docs/development/
├── SCRATCH_IDEA.md           # From 3 months ago
├── NOTES_EXPERIMENT.md        # From 2 months ago
├── WIP_FEATURE.md            # From 1 month ago
└── V1.3.0_PLAN.md            # Current work
```

**Why**: Clean up scratch files when work is complete. Extract valuable info, delete the rest.

## Best Practices

### ✅ Update Documentation with Code

Every meaningful commit should include documentation updates:

```bash
# GOOD
git add src/ docs/ VERSION ROADMAP.md
git commit -m "feat(auth): Complete login endpoint

- JWT token generation working
- Rate limiting implemented
- Tests passing (23 tests, 95% coverage)

New files:
- src/auth/login.py
- tests/test_login.py
- docs/api/AUTH_API.md

Updated:
- ROADMAP.md: Login endpoint complete
- docs/AUTH_GUIDE.md: Added login examples

Docs: Complete
CHANGELOG: Pending"
```

### ✅ Use Clear, Dated Progress Entries

In work docs (`docs/development/`), use dated entries:

```markdown
# V1.3.0 Authorization System - Implementation Notes

## 2025-12-20: Started RBAC Implementation
- Created role model
- Implemented role-permission mapping
- Blocker: Need to decide on permission granularity

## 2025-12-21: Permission Middleware
- Implemented middleware for permission checking
- Added caching for performance
- Decision: Use hierarchical permissions (admin > editor > viewer)

## 2025-12-22: Testing Complete
- 23 tests passing
- Coverage: 95%
- Ready for PR
```

### ✅ Link Related Documentation

Cross-reference related docs:

```markdown
# V1.3.0 Authorization System

**Planning**: See `V1.3.0_AUTHORIZATION_PLAN.md`
**API Docs**: See `docs/api/AUTH_API.md`
**User Guide**: See `docs/user-guides/AUTHORIZATION.md`
**Related**: Depends on v1.2.0 Authentication (complete)
```

### ✅ Keep "Current State" Section Accurate

The ROADMAP.md "Current State" section is THE source of truth. Update it religiously:

```markdown
## 📍 Current State

### What We Just Finished (Latest 2-3 only)
- v1.3.0 Phase 1: RBAC (Dec 22) ← ADD IMMEDIATELY WHEN DONE
- v1.2.0: Authentication (Dec 20)

### Current Work
- v1.3.0 Phase 2: Permission UI (MR #48) ← ALWAYS ACCURATE

### Next Up
- v1.4.0: API Rate Limiting ← UPDATE AS PRIORITIES CHANGE
- v1.5.0: Audit Logging

### Known Issues
- Session cookies expire on mobile ← ADD/REMOVE AS DISCOVERED/FIXED
```

### ✅ Archive Only When Complete

Don't rush to archive. Archive when version is:
- ✅ 100% complete (all features)
- ✅ Tested and verified
- ✅ Deployed to production
- ✅ Release notes published
- ✅ Stable for at least a week

```bash
# GOOD - version v1.3.0 complete and stable
mv docs/development/V1.3.0_*.md docs/archive/development-history/2025-12/
```

## Checklist for AI Agents

### Before Starting Work
- [ ] Read VERSION file for current version
- [ ] Read ROADMAP.md "Current State" section
- [ ] Check `docs/development/` for active work
- [ ] Verify no duplicate work planned
- [ ] Understand current priorities

### During Work
- [ ] Create work doc in `docs/development/` (if multi-step)
- [ ] Update work doc with dated progress entries
- [ ] Document decisions and blockers
- [ ] Keep ROADMAP.md "Current Work" accurate

### Before Committing
- [ ] Code changes complete and tested
- [ ] VERSION updated (if version changed)
- [ ] ROADMAP.md "Current State" updated
- [ ] Feature docs updated (if new feature)
- [ ] Code comments added (for complex logic)
- [ ] Work doc updated (final status)
- [ ] All documentation in SAME commit

### After Completion
- [ ] ROADMAP.md marks work as complete
- [ ] Work moved to "What We Just Finished"
- [ ] Known issues updated (if fix)
- [ ] Completion doc created (if version complete)
- [ ] Planning docs archived (if version complete)
- [ ] Scratch files cleaned up

## Verification and Quality Checks

### Quick Status Check

```bash
# 1. Check VERSION file
cat VERSION

# 2. Check ROADMAP.md last update
head -5 ROADMAP.md | grep "Last Updated"

# 3. Check for recent completion docs
ls -lt docs/V*.md | head -5

# 4. Verify they're all recent (within days of each other)
```

### Red Flags (Documentation Drift)

⚠️ **Documentation is out of sync if**:
- ROADMAP.md last updated >1 week ago but code changed recently
- ROADMAP.md shows work "IN PROGRESS" that's actually complete
- Completion docs exist but ROADMAP.md doesn't reflect completion
- Planning docs in `docs/development/` for completed versions
- VERSION file doesn't match ROADMAP.md
- "Known Issues" lists issues that were fixed

### Fixing Documentation Drift

If you discover documentation drift:

```bash
# 1. Update VERSION (if needed)
# 2. Update ROADMAP.md to match reality
# 3. Create fix commit
git commit -m "docs: Fix documentation drift

- Updated VERSION to match actual version (1.3.0)
- Updated ROADMAP.md 'Current State' to match reality
- Moved completed work to 'Just Finished'
- Removed fixed issues from 'Known Issues'
- Archived old planning docs

Correcting documentation drift from [date range]."
```

## Integration with Other Workflows

This documentation workflow integrates with:

- **`GIT_WORKFLOW.md`** - Git commit standards and branch management
- **`PR_REQUIREMENTS.md`** - PR review requirements (docs are blocking)
- **`PHASE_DEVELOPMENT.md`** - Phase-based development patterns
- **`TOKEN_PLANNING.md`** - Token budget tracking and reporting

**The Hierarchy**:
1. **DOCUMENTATION_WORKFLOW.md** (This) - WHAT docs to maintain and HOW
2. **GIT_WORKFLOW.md** - HOW to commit documentation changes
3. **PR_REQUIREMENTS.md** - Documentation as PR requirement
4. **PHASE_DEVELOPMENT.md** - Phase documentation standards

## Success Metrics

### This System is Working If:

- ✅ ROADMAP.md "Current State" is always accurate (within hours)
- ✅ VERSION file matches actual project version
- ✅ Status reviews take <5 minutes (not 30+ minutes)
- ✅ No duplicate work gets planned
- ✅ New agents can understand status by reading docs
- ✅ No "wait, that's already done!" moments
- ✅ Czar review doesn't require "investigation"
- ✅ Documentation questions answered by reading files

### This System is Failing If:

- ❌ Documentation is days/weeks behind code
- ❌ Status reviews require investigating actual code
- ❌ Duplicate work gets planned
- ❌ "Is this done or not?" is a common question
- ❌ Hours wasted on confusion and status checks
- ❌ Documentation drift discovered repeatedly
- ❌ Agents don't trust documentation accuracy

## Summary

### Core Rules (Must Follow)

1. ✅ **Update documentation in SAME commit** as code changes
2. ✅ **VERSION + ROADMAP.md** must always be current
3. ✅ **ROADMAP.md "Current State"** is the source of truth
4. ✅ **Czar maintains CHANGELOG.md** (never stale)
5. ✅ **Archive only when complete** - not in progress
6. ✅ **Clean up scratch files** - extract and delete

### Key Patterns

- **2-File Core**: README.md (timeless) + ROADMAP.md (current state)
- **VERSION File**: Single source of truth for version info
- **Mandatory Updates**: Every commit updates docs
- **Dated Progress**: Work docs use dated entries
- **Archive When Complete**: Only archive finished versions
- **Czar Responsibility**: CHANGELOG.md always current

### Remember

Documentation is not separate from code - it's part of the deliverable. Incomplete documentation means incomplete work.

**Code without updated documentation is incomplete.**

---

**Source**: Extracted from [thesymposium](https://gitlab.henrynet.ca/symposium/thesymposium) `.kilocode/rules/` documentation workflow patterns.

**See Also**:
- `GIT_WORKFLOW.md` - Git commit and branch standards
- `PR_REQUIREMENTS.md` - Pull request documentation requirements
- `PHASE_DEVELOPMENT.md` - Phase-based development workflow
- `TOKEN_PLANNING.md` - Token budget tracking
