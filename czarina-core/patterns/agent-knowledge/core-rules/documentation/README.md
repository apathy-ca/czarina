# Documentation Standards

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This directory contains comprehensive documentation standards covering all aspects of project documentation including READMEs, API documentation, architecture documentation, and changelogs.

## Core Principle

**Documentation is synchronized with code**: All documentation updates must happen in the same commit as code changes. Documentation must never become stale.

## Standards Documents

### [Documentation Standards](./DOCUMENTATION_STANDARDS.md)
**Purpose:** Comprehensive documentation standards

**Covers:**
- When to write documentation
- Documentation structure standards
- Inline documentation (docstrings, comments)
- Documentation workflow
- Quality standards

**Use when:** Establishing documentation practices, writing any documentation

### [API Documentation Standards](./API_DOCUMENTATION.md)
**Purpose:** Standards for documenting APIs

**Covers:**
- REST API documentation
- GraphQL API documentation
- Python/TypeScript library APIs
- Documentation generation
- Examples and testing

**Use when:** Documenting any API (REST, GraphQL, library)

### [Architecture Documentation Standards](./ARCHITECTURE_DOCS.md)
**Purpose:** Standards for architecture documentation

**Covers:**
- System architecture documentation
- Component interactions
- Architecture Decision Records (ADRs)
- Diagrams and visual documentation

**Use when:** Documenting system design, making architecture decisions

### [Changelog Standards](./CHANGELOG_STANDARDS.md)
**Purpose:** Standards for maintaining changelogs

**Covers:**
- Changelog format (Keep a Changelog)
- Semantic versioning
- Change categories
- Release workflow

**Use when:** Maintaining version history, preparing releases

### [README Template Reference](./README_TEMPLATE.md)
**Purpose:** Guide to using README template

**Covers:**
- Essential README sections
- Customization by project type
- Best practices
- Examples

**Links to:** [Full README Template](../../templates/readme-template.md)

## Quick Reference

### Core Documentation Files

Every project should have:

1. **README.md** - Project overview and getting started
2. **ROADMAP.md** - Development roadmap and planning
3. **VERSION** - Single source of truth for version number
4. **CHANGELOG.md** - Version history and changes
5. **LICENSE** - License information

### Documentation Workflow

\`\`\`mermaid
graph LR
    A[Make Code Changes] --> B[Update Documentation]
    B --> C[Commit Both Together]
    C --> D[Review]
    D --> E[Merge]
\`\`\`

**Key Rule:** Never commit code without updating related documentation in the same commit.

## Documentation Hierarchy

\`\`\`
README.md (Entry Point)
    ├── docs/API.md (API Reference)
    ├── docs/ARCHITECTURE.md (System Design)
    ├── docs/getting-started.md (Tutorials)
    ├── docs/CONTRIBUTING.md (Contribution Guide)
    └── docs/guides/ (Additional Guides)
\`\`\`

## When to Document

### Required Documentation

Must document:
- All public APIs (functions, classes, methods)
- Architecture changes
- Configuration changes
- User-facing features
- Breaking changes

### Optional Documentation

Should document:
- Complex internal logic
- Non-obvious decisions
- Performance-critical code
- Development setup

## Documentation Types

### 1. Code Documentation (Inline)

**Docstrings:**
\`\`\`python
def function(param: str) -> str:
    """One-line summary.

    Detailed description if needed.

    Args:
        param: Description

    Returns:
        Description

    Raises:
        ErrorType: When this occurs
    """
\`\`\`

**Comments:**
\`\`\`python
# Explain WHY, not WHAT
# Use binary search for O(log n) lookup
index = binary_search(items, target)
\`\`\`

### 2. README Documentation

- Project overview
- Quick start
- Installation
- Basic usage
- Links to detailed docs

See: [README Template](../../templates/readme-template.md)

### 3. API Documentation

- Endpoint/function reference
- Parameters and returns
- Examples
- Error handling

See: [API Documentation Standards](./API_DOCUMENTATION.md)

### 4. Architecture Documentation

- System design
- Component interactions
- Data flows
- Decision records

See: [Architecture Documentation Standards](./ARCHITECTURE_DOCS.md)

### 5. Guides and Tutorials

- Step-by-step instructions
- Common workflows
- Troubleshooting

### 6. Changelog

- Version history
- Changes by category
- Breaking changes
- Migration guides

See: [Changelog Standards](./CHANGELOG_STANDARDS.md)

## Documentation Quality Checklist

Before finalizing documentation:

- [ ] **Accuracy:** All information matches implementation
- [ ] **Completeness:** All required sections present
- [ ] **Clarity:** Clear, simple language
- [ ] **Examples:** Working, tested examples
- [ ] **Links:** All links functional
- [ ] **Formatting:** Consistent, readable formatting
- [ ] **Synchronization:** Updated with code changes

## Common Documentation Patterns

### 2-File Core Pattern

**Minimum documentation:**
1. README.md - Overview and quick start
2. ROADMAP.md - Development planning

\`\`\`markdown
# README.md
Overview, installation, basic usage, links to docs

# ROADMAP.md
Vision, phases, current status, future plans
\`\`\`

### VERSION File Pattern

**Single source of truth for version:**

\`\`\`
# VERSION file
1.2.3
\`\`\`

\`\`\`python
# Read in code
version = Path("VERSION").read_text().strip()
\`\`\`

### Documentation Synchronization Pattern

**Always update together:**

\`\`\`bash
# Good
git add src/feature.py
git add docs/API.md
git add CHANGELOG.md
git commit -m "feat: add new feature

Updates API documentation and changelog"

# Bad
git add src/feature.py
git commit -m "feat: add new feature"
# (Documentation update comes later or never)
\`\`\`

## Best Practices

### ✅ Do

- Update docs with code changes (same commit)
- Test all examples
- Use consistent terminology
- Link related documentation
- Keep documentation DRY (Don't Repeat Yourself)
- Write for your audience
- Use clear, simple language

### ❌ Don't

- Let documentation get stale
- Include untested examples
- Assume prior knowledge
- Use broken links
- Duplicate information unnecessarily
- Write only for experts
- Use overly technical jargon

## Documentation Tools

### Generation

- **Python:** Sphinx, pdoc, mkdocs
- **TypeScript:** TypeDoc, API Extractor
- **REST APIs:** OpenAPI/Swagger
- **Static Sites:** Jekyll, Hugo, Docusaurus

### Validation

- **Link Checking:** markdown-link-check
- **Spell Checking:** codespell, vale
- **Linting:** markdownlint

### Diagrams

- **Mermaid:** Diagrams in Markdown
- **PlantUML:** UML diagrams
- **Diagrams.net:** Visual diagrams

## Examples from Projects

### SARK Project

Excellent documentation:
- Comprehensive README
- Detailed API documentation
- Architecture diagrams
- Working examples

### Czarina Orchestration

Good patterns:
- Worker templates
- Structured logging
- Phase-based planning
- Closeout reports

## Integration with Templates

This directory provides standards; templates provide structure:

### Templates Directory

- [Python Project Template](../../templates/python-project-template.md)
- [README Template](../../templates/readme-template.md)
- [API Documentation Template](../../templates/api-documentation-template.md)
- [Architecture Documentation Template](../../templates/architecture-documentation-template.md)

**Use Together:**
1. Read standards (this directory)
2. Use templates (templates directory)
3. Customize for your project

## Related Standards

### Foundation Worker
- [Python Coding Standards](../python-standards/CODING_STANDARDS.md)
- [Testing Patterns](../python-standards/TESTING_PATTERNS.md)

### Workflows Worker
- [Documentation Workflow](../workflows/DOCUMENTATION_WORKFLOW.md)
- [Git Workflow](../workflows/GIT_WORKFLOW.md)
- [PR Requirements](../workflows/PR_REQUIREMENTS.md)

### Testing Worker
- [Testing Policy](../testing/TESTING_POLICY.md)

## Contributing to Documentation Standards

When improving these standards:

1. Update the relevant standard document
2. Update related templates if needed
3. Provide examples
4. Update this README if adding new standards

## Support

### Questions About Documentation?

1. Check relevant standard document
2. Review template examples
3. Look at example projects (SARK, Czarina)
4. Ask in team discussions

### Documentation Not Clear?

File an issue describing:
- Which document is unclear
- What needs clarification
- Suggested improvement

## Version History

### v1.0.0 (2025-12-26)
- Initial documentation standards
- Complete standard documents
- Integration with templates

---

**Remember:** Good documentation is code's best friend. Keep them synchronized!
