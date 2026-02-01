# Changelog Standards

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This document defines standards for maintaining project changelogs following [Keep a Changelog](https://keepachangelog.com/) format and [Semantic Versioning](https://semver.org/).

## Format

### Base Structure

\`\`\`markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New features that have been added but not yet released

### Changed
- Changes to existing functionality

### Deprecated
- Features that will be removed in upcoming releases

### Removed
- Features that have been removed

### Fixed
- Bug fixes

### Security
- Security improvements or vulnerability fixes

## [1.0.0] - 2025-01-15

### Added
- Initial release
- Feature descriptions

[Unreleased]: https://github.com/org/repo/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/org/repo/releases/tag/v1.0.0
\`\`\`

## Change Categories

### Added
For new features and functionality.

**Examples:**
- Added user authentication system
- Added ability to export reports as PDF
- Added dark mode support
- Added `/api/v1/users` endpoint

### Changed
For changes to existing functionality.

**Examples:**
- Changed database connection pooling strategy
- Updated user interface for settings page
- Improved error messages for validation failures
- Upgraded dependencies to latest versions

### Deprecated
For features that will be removed in upcoming releases.

**Examples:**
- Deprecated `old_function()` in favor of `new_function()`
- Deprecated API v1 endpoints (will be removed in v3.0.0)
- Deprecated configuration option `legacy_mode`

**Include:**
- What is deprecated
- What to use instead
- When it will be removed

### Removed
For features that have been removed.

**Examples:**
- Removed support for Python 3.8
- Removed deprecated `/api/v1/legacy` endpoint
- Removed `old_config` option

**Include:**
- What was removed
- Why it was removed (if not obvious)
- Migration path (if applicable)

### Fixed
For bug fixes.

**Examples:**
- Fixed memory leak in background worker
- Fixed calculation error in discount function
- Fixed race condition in concurrent requests
- Fixed #123: Users unable to reset password

**Include:**
- What was fixed
- Issue number (if applicable)
- Impact of the bug (if significant)

### Security
For security improvements and vulnerability fixes.

**Examples:**
- Fixed SQL injection vulnerability in search endpoint
- Updated dependencies to address CVE-2025-12345
- Improved password hashing algorithm
- Added rate limiting to prevent brute force attacks

**Always include:**
- CVE numbers if applicable
- Severity (if known)
- Credit to reporter (if appropriate)

## Semantic Versioning

### Version Format: MAJOR.MINOR.PATCH

#### MAJOR version (X.0.0)
Increment when you make **incompatible API changes**.

**Examples:**
- Removing endpoints or functions
- Changing function signatures
- Removing configuration options
- Changing data formats (breaking)
- Database schema changes requiring migration

\`\`\`markdown
## [2.0.0] - 2025-01-15

### Changed
- **BREAKING:** Changed `User.get()` to return `Optional[User]` instead of raising exception

### Removed
- **BREAKING:** Removed deprecated `/api/v1/legacy` endpoint
- **BREAKING:** Removed support for Python 3.8
\`\`\`

#### MINOR version (x.Y.0)
Increment when you add functionality in a **backward-compatible manner**.

**Examples:**
- Adding new endpoints or functions
- Adding optional parameters
- Adding new features
- Deprecating features (not removing)

\`\`\`markdown
## [1.2.0] - 2025-01-15

### Added
- Added `/api/v1/export` endpoint for exporting data
- Added optional `format` parameter to `/api/v1/reports`

### Deprecated
- Deprecated `old_function()` in favor of `new_function()`
\`\`\`

#### PATCH version (x.y.Z)
Increment when you make **backward-compatible bug fixes**.

**Examples:**
- Fixing bugs
- Performance improvements
- Documentation fixes
- Dependency updates (security)

\`\`\`markdown
## [1.1.1] - 2025-01-15

### Fixed
- Fixed memory leak in background worker
- Fixed calculation error in tax calculation

### Security
- Updated requests library to address CVE-2025-12345
\`\`\`

## Pre-release Versions

For pre-release versions, append identifier:

- **Alpha:** `1.0.0-alpha.1`
- **Beta:** `1.0.0-beta.1`
- **Release Candidate:** `1.0.0-rc.1`

\`\`\`markdown
## [1.0.0-beta.1] - 2025-01-10

### Added
- Beta release for testing
- All planned features for 1.0.0 implemented

### Known Issues
- Issue 1: Description
- Issue 2: Description
\`\`\`

## Writing Good Changelog Entries

### ✅ Good Entries

**Clear and Specific:**
\`\`\`markdown
### Added
- Added ability to filter users by email domain
- Added export to CSV functionality for all reports
\`\`\`

**User-Focused:**
\`\`\`markdown
### Changed
- Improved search performance by 50% for large datasets
- Updated error messages to be more helpful and actionable
\`\`\`

**Include Context:**
\`\`\`markdown
### Fixed
- Fixed #456: Dashboard crashes when no data is available
- Fixed race condition in concurrent API requests that caused intermittent 500 errors
\`\`\`

### ❌ Bad Entries

**Too Vague:**
\`\`\`markdown
### Changed
- Updated code
- Fixed bugs
- Improved performance
\`\`\`

**Too Technical:**
\`\`\`markdown
### Changed
- Refactored UserRepository to use Repository pattern
- Changed database query optimization in get_users_with_resources()
\`\`\`

**Missing Context:**
\`\`\`markdown
### Fixed
- Fixed issue
- Updated dependency
\`\`\`

## Entry Format

### Basic Entry
\`\`\`markdown
- Added user authentication system
\`\`\`

### With Issue Reference
\`\`\`markdown
- Fixed #123: Users unable to reset password
\`\`\`

### With PR Reference
\`\`\`markdown
- Added CSV export functionality (#456)
\`\`\`

### With Breaking Change
\`\`\`markdown
- **BREAKING:** Removed deprecated `old_function()` (use `new_function()` instead)
\`\`\`

### With Migration Note
\`\`\`markdown
- **BREAKING:** Changed user authentication to use JWT tokens
  - Migration: Update client code to use Bearer token authentication
  - See: docs/migration/v2.0.0.md
\`\`\`

### With Security Note
\`\`\`markdown
- **SECURITY:** Fixed SQL injection in search endpoint (CVE-2025-12345)
  - Severity: High
  - Affected versions: 1.0.0 - 1.2.0
  - Thanks to @security-researcher for reporting
\`\`\`

## Workflow

### When to Update CHANGELOG.md

**Always update in same commit as changes:**
\`\`\`bash
git add src/feature.py
git add CHANGELOG.md
git commit -m "feat: add new feature

This commit adds...

Closes #123"
\`\`\`

### During Development

Add entries to `[Unreleased]` section:

\`\`\`markdown
## [Unreleased]

### Added
- Added new feature X
- Added endpoint Y

### Fixed
- Fixed bug in Z
\`\`\`

### When Releasing

1. **Decide version number** (based on changes)
2. **Update VERSION file**
3. **Update CHANGELOG.md:**
   - Rename `[Unreleased]` to new version
   - Add release date
   - Create new `[Unreleased]` section
   - Update comparison links

**Example:**
\`\`\`markdown
## [Unreleased]

## [1.2.0] - 2025-01-15

### Added
- Added new feature X

[Unreleased]: https://github.com/org/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/org/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/org/repo/releases/tag/v1.1.0
\`\`\`

4. **Create git tag:**
\`\`\`bash
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin v1.2.0
\`\`\`

## Complete Example

\`\`\`markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Work in progress features

## [2.0.0] - 2025-01-20

### Changed
- **BREAKING:** Updated authentication to use OAuth 2.0
  - Migration guide: docs/migration/v2.0.md
  - Old API keys will work until 2025-04-20
- Improved database query performance by 60%

### Removed
- **BREAKING:** Removed deprecated `/api/v1/legacy` endpoints
- Removed support for Python 3.8

### Added
- Added `/api/v2/users` endpoint with improved filtering
- Added dark mode support

### Fixed
- Fixed #456: Dashboard crashes with empty datasets
- Fixed race condition in concurrent webhook processing

### Security
- Updated dependencies to address CVE-2025-12345
- Improved rate limiting on authentication endpoints

## [1.2.1] - 2025-01-10

### Fixed
- Fixed memory leak in background worker (#445)
- Fixed incorrect tax calculation for international orders

### Security
- Updated requests library to 2.31.0 (CVE-2025-11111)

## [1.2.0] - 2025-01-05

### Added
- Added CSV export for all reports
- Added ability to filter users by email domain
- Added `/api/v1/export` endpoint

### Changed
- Improved search performance for large datasets
- Updated error messages to be more helpful

### Deprecated
- Deprecated `old_export_function()` (use `export_to_csv()` instead)
  - Will be removed in v2.0.0

## [1.1.0] - 2024-12-20

### Added
- Added user profile management
- Added email notifications for important events

### Changed
- Updated dashboard UI for better mobile experience

### Fixed
- Fixed #234: Users unable to update profile picture
- Fixed timezone handling in reports

## [1.0.0] - 2024-12-01

### Added
- Initial release
- User management system
- Report generation
- API endpoints for all core functionality

[Unreleased]: https://github.com/org/repo/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/org/repo/compare/v1.2.1...v2.0.0
[1.2.1]: https://github.com/org/repo/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/org/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/org/repo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/org/repo/releases/tag/v1.0.0
\`\`\`

## Automation

### Generate Changelog from Commits

Using conventional commits:

\`\`\`bash
# Generate changelog from git commits
git log --pretty=format:"- %s" v1.0.0..HEAD | grep "^- feat:" >> CHANGELOG.md
\`\`\`

### Changelog Generation Tools

**JavaScript/TypeScript:**
\`\`\`bash
npm install -g conventional-changelog-cli
conventional-changelog -p angular -i CHANGELOG.md -s
\`\`\`

**Python:**
\`\`\`bash
pip install auto-changelog
auto-changelog
\`\`\`

## Related Standards

- [Documentation Standards](./DOCUMENTATION_STANDARDS.md)
- [Git Workflow](../core-rules/workflows/GIT_WORKFLOW.md)
- [PR Requirements](../core-rules/workflows/PR_REQUIREMENTS.md)

## References

- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)

This document synthesizes patterns from:
- Workflows Worker: Version management, documentation workflow
- Foundation Worker: Release patterns
- All Workers: Changelog maintenance practices
