# Versioning Strategy

This document describes the versioning strategy for the Agent Knowledge repository.

## Semantic Versioning

We follow [Semantic Versioning 2.0.0](https://semver.org/):

Given a version number MAJOR.MINOR.PATCH:
- **MAJOR** version for incompatible/breaking changes
- **MINOR** version for new functionality in a backwards-compatible manner
- **PATCH** version for backwards-compatible bug fixes

## Version Bump Guidelines

### Major Version (X.0.0)

Bump major version when:
- Restructuring the repository layout (breaking navigation)
- Removing significant patterns or rules
- Changing the core organization system
- Making changes that require updates in consuming projects (Hopper, Czarina, The Symposium, SARK)
- Breaking existing APIs or interfaces

**Example:** v2.0.0 - Restructured repository into language-specific sections, breaking all existing paths

**Impact:** Requires updates in all consuming projects

**When to avoid:** Major version bumps are rare. Prefer backwards-compatible additions when possible.

### Minor Version (1.X.0)

Bump minor version when:
- Adding new patterns
- Adding new rules
- Adding new templates
- Significantly enhancing existing content
- Adding new categories or sections
- Adding new features that don't break existing functionality

**Example:** v1.1.0 - Added circuit breaker error recovery pattern

**Impact:** No changes required in consuming projects, but new functionality available

**Typical frequency:** Monthly to quarterly, depending on contribution rate

### Patch Version (1.0.X)

Bump patch version when:
- Fixing typos or errors
- Clarifying existing content
- Updating cross-references
- Minor formatting improvements
- Link fixes
- Documentation corrections
- Small bug fixes that don't add functionality

**Example:** v1.0.1 - Fixed broken links in git workflows documentation

**Impact:** No functional changes, just corrections

**Typical frequency:** As needed, could be weekly or daily

## Release Process

### 1. Update CHANGELOG.md

Move items from `[Unreleased]` section to new version section:

```markdown
## [1.1.0] - 2025-01-15

### Added
- Circuit breaker pattern for error recovery
- New examples for parallel tool calls

### Changed
- Enhanced context management documentation
- Updated cross-references in testing patterns

### Fixed
- Broken links in git workflows
- Typo in pytest standards
```

Add release date in `YYYY-MM-DD` format.

### 2. Update Version References

Update version in key files:

**README.md:**
```markdown
**Current version:** v1.1.0
```

**If applicable:**
- `.czarina/config.json` - Update version field
- Any other files that reference the version number

### 3. Create Git Tag

```bash
git tag -a v1.1.0 -m "Release v1.1.0: Added circuit breaker pattern"
git push origin v1.1.0
```

**Tag message format:**
- Concise summary of major changes
- Reference to CHANGELOG for details

### 4. Create GitHub Release

1. Go to GitHub repository releases page
2. Click "Create a new release"
3. Select the tag created above (v1.1.0)
4. Copy CHANGELOG entry to release notes
5. Add any additional context or highlights
6. Publish release

**Release notes should include:**
- Summary of changes
- Migration notes (if any breaking changes)
- Links to relevant PRs or issues
- Credits to contributors

### 5. Notify Consuming Projects

For minor and major versions, notify:
- Hopper maintainers
- Czarina maintainers
- The Symposium maintainers
- SARK maintainers

**Notification should include:**
- Version number
- Summary of changes
- Impact on their project (if any)
- Migration steps (if required)

## Version History

### v1.0.0 (2025-12-28) - Initial Release
- Merge of agent-rules and agentic-dev-patterns
- 53+ rules across 9 domains
- 6 pattern categories with impact metrics
- Comprehensive documentation and navigation

### Future Versions

Planned enhancements (subject to change):
- v1.1.0 - Additional error recovery patterns from Symposium learnings
- v1.2.0 - Enhanced security patterns from SARK
- v1.3.0 - New orchestration patterns from Czarina
- v2.0.0 - Major restructuring (if needed, not currently planned)

## Special Cases

### Pre-release Versions

For testing major changes before release:

```
v2.0.0-alpha.1
v2.0.0-beta.1
v2.0.0-rc.1
```

**When to use:**
- Major version changes that need validation
- Significant restructuring
- Breaking changes that need testing in consuming projects

**Process:**
1. Create pre-release tag
2. Test in consuming projects
3. Iterate based on feedback
4. Release final version when stable

### Hotfix Releases

For critical fixes that can't wait for regular release cycle:

```
v1.0.1 - Critical link fix
v1.0.2 - Security documentation update
```

**Process:**
1. Create fix on hotfix branch
2. Update CHANGELOG immediately
3. Tag and release without waiting
4. Notify consuming projects if urgent

## Deprecation Policy

When deprecating patterns or rules:

### Minor Version Deprecation
1. Mark as deprecated in documentation
2. Add deprecation notice with migration path
3. Keep content available for at least 2 minor versions
4. Document replacement pattern or rule

**Example:**
```markdown
> **DEPRECATED:** This pattern is deprecated as of v1.2.0.
> Use the updated pattern instead.
> This pattern will be removed in v2.0.0.
```

### Removal (Major Version)
1. Remove deprecated content
2. Update all cross-references
3. Document removal in CHANGELOG
4. Provide migration guide

## Quality Gates

Before releasing any version:

### All Versions
- [ ] CHANGELOG.md updated
- [ ] All links validated (no broken links)
- [ ] Version number updated in README.md
- [ ] Git tag created with proper format

### Minor and Major Versions
- [ ] All new patterns have evidence
- [ ] All new patterns have impact metrics
- [ ] Cross-references updated
- [ ] INDEX.md files updated
- [ ] Examples tested (if applicable)
- [ ] Consuming projects notified

### Major Versions
- [ ] Migration guide created
- [ ] Breaking changes documented
- [ ] Backwards compatibility assessed
- [ ] Consuming projects tested with changes
- [ ] Pre-release testing completed

## Version Naming Convention

**Tags:** `vX.Y.Z` (e.g., v1.2.3)

**Releases:** `X.Y.Z` (e.g., 1.2.3) with descriptive title

**Example:**
- Tag: `v1.1.0`
- Release: `1.1.0 - Circuit Breaker Pattern`

## Automation (Future)

Potential automation opportunities:
- Automatic CHANGELOG generation from PR labels
- Automatic version bumping based on commit messages
- Link validation in CI/CD
- Version consistency checks

These will be implemented as the repository matures and contribution rate increases.

## Questions?

For questions about versioning:
- Open an issue with the `question` label
- Reference this document
- Tag repository maintainers
