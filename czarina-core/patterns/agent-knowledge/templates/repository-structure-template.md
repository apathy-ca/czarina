# Repository Structure Template

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This template provides a standard repository structure following best practices from the agent-rules extraction project.

## When to Use This Template

Use this template when:
- Initializing any new repository
- Standardizing an existing project structure
- Setting up documentation and workflow files
- Ensuring consistency across multiple repositories

## Standard Repository Structure

```
[REPOSITORY_NAME]/
├── .github/
│   ├── workflows/              # GitHub Actions CI/CD
│   │   ├── ci.yml
│   │   ├── release.yml
│   │   └── security-scan.yml
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── task.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── dependabot.yml
├── docs/                       # Documentation
│   ├── README.md               # Documentation index
│   ├── ROADMAP.md              # Development roadmap
│   ├── ARCHITECTURE.md         # System architecture
│   ├── API.md                  # API documentation
│   ├── CONTRIBUTING.md         # Contribution guidelines
│   └── diagrams/               # Architecture diagrams
├── src/                        # Source code (language-specific)
├── tests/                      # Test files
├── .env.example                # Environment variables template
├── .gitignore                  # Git ignore patterns
├── .gitattributes              # Git attributes
├── LICENSE                     # License file
├── README.md                   # Project overview
├── CHANGELOG.md                # Change history
├── VERSION                     # Version number (single source of truth)
└── [BUILD_CONFIG]              # Build configuration (pyproject.toml, package.json, etc.)
```

## Core Files

### README.md

```markdown
# [PROJECT_NAME]

[BRIEF_DESCRIPTION]

## Overview

[DETAILED_DESCRIPTION]

## Features

- Feature 1
- Feature 2
- Feature 3

## Quick Start

### Prerequisites

- Requirement 1
- Requirement 2

### Installation

\`\`\`bash
# Installation commands
\`\`\`

### Usage

\`\`\`bash
# Usage examples
\`\`\`

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [API Documentation](docs/API.md)
- [Contributing Guide](docs/CONTRIBUTING.md)
- [Roadmap](docs/ROADMAP.md)

## Development

### Setup Development Environment

\`\`\`bash
# Development setup commands
\`\`\`

### Running Tests

\`\`\`bash
# Test commands
\`\`\`

### Code Quality

\`\`\`bash
# Linting/formatting commands
\`\`\`

## License

[LICENSE_TYPE] - See [LICENSE](LICENSE) for details

## Contributing

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for contribution guidelines.

## Support

[SUPPORT_INFO]
```

### VERSION

```
0.1.0
```

Format: `MAJOR.MINOR.PATCH` following [Semantic Versioning](https://semver.org/)

### CHANGELOG.md

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure

## [0.1.0] - YYYY-MM-DD

### Added
- Initial release
- Feature descriptions

[Unreleased]: https://github.com/[ORG]/[REPO]/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/[ORG]/[REPO]/releases/tag/v0.1.0
```

### .gitignore (General)

```gitignore
# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
.env.*.local

# Logs
logs/
*.log

# Build artifacts
build/
dist/
*.egg-info/

# Dependencies (language-specific)
node_modules/
venv/
vendor/

# Test artifacts
.coverage
htmlcov/
.pytest_cache/

# Temporary files
tmp/
temp/
*.tmp
```

### .gitattributes

```gitattributes
# Auto detect text files and normalize line endings
* text=auto

# Source code
*.py text eol=lf
*.js text eol=lf
*.ts text eol=lf
*.jsx text eol=lf
*.tsx text eol=lf
*.json text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
*.toml text eol=lf

# Shell scripts
*.sh text eol=lf
*.bash text eol=lf

# Windows scripts
*.bat text eol=crlf
*.cmd text eol=crlf
*.ps1 text eol=crlf

# Documentation
*.md text eol=lf
*.txt text eol=lf

# Binary files
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.pdf binary
*.zip binary
*.tar binary
*.gz binary
```

## GitHub Configuration

### .github/PULL_REQUEST_TEMPLATE.md

```markdown
## Description

[Describe the changes in this PR]

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)
- [ ] Performance improvement
- [ ] Test coverage improvement

## Checklist

- [ ] My code follows the project's coding standards
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] I have updated the CHANGELOG.md

## Testing

[Describe how you tested these changes]

## Related Issues

Closes #[ISSUE_NUMBER]

## Additional Notes

[Any additional information]
```

### .github/ISSUE_TEMPLATE/bug_report.md

```markdown
---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

[Clear and concise description of the bug]

## To Reproduce

Steps to reproduce the behavior:
1. Go to '...'
2. Execute '...'
3. See error

## Expected Behavior

[What you expected to happen]

## Actual Behavior

[What actually happened]

## Environment

- OS: [e.g., Ubuntu 22.04]
- Version: [e.g., 1.0.0]
- Python/Node/etc Version: [e.g., 3.11]

## Additional Context

[Any additional information, logs, or screenshots]

## Error Output

\`\`\`
[Paste error output here]
\`\`\`
```

### .github/ISSUE_TEMPLATE/feature_request.md

```markdown
---
name: Feature Request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Feature Description

[Clear and concise description of the feature]

## Problem Statement

[What problem does this feature solve?]

## Proposed Solution

[Describe your proposed solution]

## Alternatives Considered

[Describe alternative solutions you've considered]

## Additional Context

[Any additional information, mockups, or examples]

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
```

### .github/dependabot.yml

```yaml
version: 2
updates:
  # Enable version updates for package ecosystem
  - package-ecosystem: "pip"  # or "npm", "cargo", "go", etc.
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    reviewers:
      - "[TEAM_OR_USERNAME]"
    labels:
      - "dependencies"
      - "automated"
```

## Documentation Structure

### docs/README.md

```markdown
# Documentation

## Overview

This directory contains comprehensive documentation for [PROJECT_NAME].

## Documentation Index

### Getting Started
- [Quick Start Guide](../README.md#quick-start)
- [Installation](../README.md#installation)

### Architecture & Design
- [Architecture Overview](ARCHITECTURE.md)
- [API Documentation](API.md)
- [Design Decisions](decisions/)

### Development
- [Contributing Guide](CONTRIBUTING.md)
- [Development Setup](../README.md#development)
- [Testing Guide](testing.md)

### Planning
- [Roadmap](ROADMAP.md)
- [Changelog](../CHANGELOG.md)

## Documentation Standards

- Keep documentation synchronized with code changes
- Update documentation in the same commit as code changes
- Use clear, concise language
- Include code examples where appropriate
- Keep diagrams up to date
```

### docs/ROADMAP.md

```markdown
# Roadmap

## Vision

[Long-term vision for the project]

## Current Status

**Version:** [CURRENT_VERSION]
**Status:** [Alpha/Beta/Stable]

## Phases

### Phase 1: Foundation (Token Budget: XXX,XXX)
**Status:** [In Progress/Complete]

- [x] Task 1
- [ ] Task 2
- [ ] Task 3

### Phase 2: Core Features (Token Budget: XXX,XXX)
**Status:** [Planned]

- [ ] Task 1
- [ ] Task 2

### Phase 3: Enhancement (Token Budget: XXX,XXX)
**Status:** [Planned]

- [ ] Task 1
- [ ] Task 2

## Completed Milestones

### v0.1.0 - Initial Release
- Feature 1
- Feature 2

## Future Considerations

- Future feature 1
- Future feature 2
```

### docs/CONTRIBUTING.md

```markdown
# Contributing to [PROJECT_NAME]

Thank you for your interest in contributing!

## Code of Conduct

[Link to code of conduct or inline it]

## How to Contribute

### Reporting Bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md)

### Suggesting Features

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md)

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Write/update tests
5. Update documentation
6. Commit using conventional commits
7. Push to your fork
8. Create a Pull Request

## Development Guidelines

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

\`\`\`
type(scope): subject

body

footer
\`\`\`

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Code Style

[Language-specific style guide]

### Testing

- Write tests for new features
- Ensure all tests pass before submitting PR
- Aim for 80%+ code coverage

### Documentation

- Update README.md for user-facing changes
- Update API.md for API changes
- Add inline documentation for complex code
- Update CHANGELOG.md

## Review Process

1. Automated CI checks must pass
2. Code review by maintainer(s)
3. Documentation review
4. Approval and merge

## Questions?

[Contact information or discussion forum]
```

## Related Documents

- [Documentation Workflow](../core-rules/workflows/DOCUMENTATION_WORKFLOW.md)
- [Git Workflow](../core-rules/workflows/GIT_WORKFLOW.md)
- [PR Requirements](../core-rules/workflows/PR_REQUIREMENTS.md)

## References

This template synthesizes patterns from:
- Workflows Worker: Git workflow, documentation workflow, PR requirements
- Foundation Worker: Project organization
- Security Worker: Security scanning, dependency management
