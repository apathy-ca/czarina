# Agent Rules Templates

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This directory contains comprehensive, ready-to-use templates for various aspects of software development, agent orchestration, and project management. These templates synthesize best practices from the agent-rules extraction project across Python development, testing, documentation, and orchestration patterns.

## Template Categories

### Project Initialization Templates

Start new projects with established standards and best practices.

#### 1. [Python Project Template](./python-project-template.md)
Complete Python project structure including:
- Directory structure and file organization
- Configuration files (pyproject.toml, pytest.ini, .coveragerc)
- CI/CD setup (GitHub Actions)
- Development tooling (black, ruff, mypy)
- Environment management
- Testing infrastructure

**When to use:** Starting any Python application, library, or service.

**Quick Start:**
```bash
# Copy structure, replace [PROJECT_NAME], [PACKAGE_NAME], etc.
# Follow the template's customization guide
```

#### 2. [Agent Project Template](./agent-project-template.md)
AI agent application structure including:
- Agent architecture (base classes, roles)
- Tool registry and integration patterns
- Orchestration and coordination
- Prompt management
- Memory/context handling
- Multi-agent workflows

**When to use:** Building AI agent applications, tool-calling systems, or multi-agent orchestrations.

**Quick Start:**
```bash
# Start with Python Project Template
# Add agent-specific components from this template
```

#### 3. [Repository Structure Template](./repository-structure-template.md)
Standard repository organization including:
- GitHub configuration (.github/)
- Documentation structure (docs/)
- Issue and PR templates
- Version management (VERSION, CHANGELOG.md)
- Dependency management (dependabot)

**When to use:** Initializing any new repository or standardizing existing ones.

### Documentation Templates

Create comprehensive, consistent documentation.

#### 4. [README Template](./readme-template.md)
Comprehensive README structure for different project types:
- Libraries/Packages: Installation, API Reference, Examples
- Applications: Features, Configuration, Deployment
- Tools/CLI: Commands, Options, Usage
- Frameworks: Getting Started, Concepts, Guides

**When to use:** Every repository needs a README. Use this to ensure completeness.

**Sections to customize based on project type** (included in template).

#### 5. [API Documentation Template](./api-documentation-template.md)
Complete API documentation structure:
- REST API documentation
- GraphQL API documentation
- Python/TypeScript library API reference
- Error handling and rate limiting
- Webhooks and integrations

**When to use:** Documenting any API (REST, GraphQL, library).

#### 6. [Architecture Documentation Template](./architecture-documentation-template.md)
System architecture documentation:
- Component architecture
- Data architecture and flows
- Integration patterns
- Security architecture
- Deployment architecture
- Architecture Decision Records (ADRs)

**When to use:** Documenting system design, making architecture decisions, onboarding.

### Testing Templates

Write comprehensive, maintainable tests.

#### 7. [Unit Test Template](./unit-test-template.md)
Unit test patterns for Python and TypeScript:
- AAA pattern (Arrange-Act-Assert)
- Testing with mocks and fixtures
- Async testing
- Parametrized tests
- Pydantic model testing

**When to use:** Writing any unit test.

**Coverage target:** 80%+ for new code.

#### 8. [Integration Test Template](./integration-test-template.md)
Integration test patterns:
- Docker-compose setup
- Database integration testing
- API endpoint testing
- Service integration testing
- External service mocking

**When to use:** Testing component interactions, API endpoints, workflows.

**Performance target:** < 10s per integration test.

#### 9. [Test Fixture Template](./test-fixture-template.md)
Reusable test fixtures:
- Fixture scopes (function, class, module, session)
- Factory patterns
- Mock objects
- Configuration fixtures
- Temporary file handling

**When to use:** Creating reusable test setup code.

### Worker/Orchestration Templates

Coordinate multi-agent or multi-worker projects.

#### 10. [Worker Definition Template](./worker-definition-template.md)
Complete worker task definition:
- Role and mission
- Dependencies and budget
- Deliverables and tasks
- Success criteria
- Logging and checkpoints

**When to use:** Defining work for agent-based orchestration systems (e.g., Czarina).

**Source:** Foundation worker (czarina patterns)

#### 11. [Worker Identity Template](./worker-identity-template.md)
Concise worker identity file:
- Quick reference card
- Logging instructions
- Mission statement

**When to use:** Creating WORKER_IDENTITY.md files for orchestration systems.

**Source:** Foundation worker (czarina patterns)

#### 12. [Worker Closeout Template](./worker-closeout-template.md)
Comprehensive completion report:
- Executive summary
- Deliverables and metrics
- Timeline and budget
- Challenges and lessons learned
- Handoff to QA

**When to use:** Documenting worker completion in orchestration systems.

**Source:** Foundation worker (czarina patterns)

## Usage Guide

### For New Projects

1. **Choose Project Type:**
   - Python app/library → [Python Project Template](#1-python-project-template)
   - AI agent system → [Agent Project Template](#2-agent-project-template)
   - Any repository → [Repository Structure Template](#3-repository-structure-template)

2. **Set Up Documentation:**
   - Create README.md using [README Template](#4-readme-template)
   - Document APIs using [API Documentation Template](#5-api-documentation-template)
   - Document architecture using [Architecture Documentation Template](#6-architecture-documentation-template)

3. **Establish Testing:**
   - Set up test structure from project template
   - Write unit tests using [Unit Test Template](#7-unit-test-template)
   - Write integration tests using [Integration Test Template](#8-integration-test-template)
   - Create fixtures using [Test Fixture Template](#9-test-fixture-template)

### For Agent Orchestration

1. **Define Workers:**
   - Create worker definitions using [Worker Definition Template](#10-worker-definition-template)
   - Create worker identities using [Worker Identity Template](#11-worker-identity-template)

2. **Execute Work:**
   - Follow task lists in worker definitions
   - Log progress as specified
   - Commit at checkpoints

3. **Document Completion:**
   - Fill out closeout report using [Worker Closeout Template](#12-worker-closeout-template)
   - Hand off to QA/integration

### For Existing Projects

1. **Audit Current State:**
   - Compare against templates
   - Identify missing components

2. **Prioritize Improvements:**
   - Start with README (most visible)
   - Add missing tests (most valuable)
   - Document architecture (onboarding)

3. **Implement Incrementally:**
   - Don't try to do everything at once
   - Use templates as reference, not strict rules

## Template Customization

### Find and Replace

All templates use placeholders that should be replaced:

| Placeholder | Replace With | Example |
|-------------|--------------|---------|
| `[PROJECT_NAME]` | Your project name | `hopper` |
| `[PACKAGE_NAME]` | Python package name | `hopper_core` |
| `[DESCRIPTION]` | Project description | `AI agent orchestration framework` |
| `[AUTHOR_NAME]` | Your name | `Jane Developer` |
| `[AUTHOR_EMAIL]` | Your email | `jane@example.com` |
| `[ORG]` | GitHub org | `myorg` |
| `[REPO]` | Repository name | `myproject` |
| `[VERSION]` | Current version | `0.1.0` |

### Optional Sections

Many templates include optional sections marked with:
- "Optional:" prefix
- "If applicable" notes
- "Choose based on project type" guidance

Remove or adapt these based on your needs.

### Adding Project-Specific Content

Templates provide structure, not content. Add:
- Specific technical details
- Project-specific configurations
- Custom workflows or processes
- Domain-specific examples

## Template Relationships

### Project Setup Flow

```
Repository Structure Template
         ↓
Python/Agent Project Template
         ↓
Testing Templates (Unit/Integration/Fixture)
         ↓
Documentation Templates (README/API/Architecture)
```

### Orchestration Flow

```
Worker Definition Template
         ↓
Worker Identity Template
         ↓
[Work Execution]
         ↓
Worker Closeout Template
```

### Documentation Hierarchy

```
README Template (entry point)
    ├── API Documentation Template (technical reference)
    ├── Architecture Documentation Template (system design)
    └── Additional guides (as needed)
```

## Integration with Agent Rules

These templates reference and integrate with extracted agent rules:

### Python Development
- [Python Coding Standards](../core-rules/python-standards/CODING_STANDARDS.md)
- [Async Patterns](../core-rules/python-standards/ASYNC_PATTERNS.md)
- [Error Handling](../core-rules/python-standards/ERROR_HANDLING.md)
- [Testing Patterns](../core-rules/python-standards/TESTING_PATTERNS.md)
- [Security Patterns](../core-rules/python-standards/SECURITY_PATTERNS.md)

### Agent Development
- [Agent Roles](../core-rules/agent-roles/AGENT_ROLES.md)
- [Tool Use Patterns](../patterns/tool-use/README.md)
- [Error Recovery](../patterns/error-recovery/README.md)

### Workflows
- [Git Workflow](../core-rules/workflows/GIT_WORKFLOW.md)
- [Documentation Workflow](../core-rules/workflows/DOCUMENTATION_WORKFLOW.md)
- [PR Requirements](../core-rules/workflows/PR_REQUIREMENTS.md)
- [Token Planning](../core-rules/workflows/TOKEN_PLANNING.md)

### Testing
- [Testing Policy](../core-rules/testing/TESTING_POLICY.md)
- [Unit Testing Standards](../core-rules/testing/UNIT_TESTING.md)
- [Integration Testing Standards](../core-rules/testing/INTEGRATION_TESTING.md)
- [Coverage Standards](../core-rules/testing/COVERAGE_STANDARDS.md)

### Security
- [Authentication](../core-rules/security/AUTHENTICATION.md)
- [Authorization](../core-rules/security/AUTHORIZATION.md)
- [Secret Management](../core-rules/security/SECRET_MANAGEMENT.md)
- [Injection Prevention](../core-rules/security/INJECTION_PREVENTION.md)

## Best Practices

### When Using Templates

✅ **Do:**
- Customize templates for your specific needs
- Remove sections that don't apply
- Add project-specific content
- Keep templates updated as project evolves
- Use templates as living documents

❌ **Don't:**
- Copy templates blindly without customization
- Keep placeholder text in final documents
- Add unnecessary complexity
- Ignore templates completely
- Treat templates as immutable

### Template Maintenance

**For Template Authors:**
- Keep templates in sync with actual practices
- Update examples with real-world patterns
- Version templates and track changes
- Gather feedback from users
- Evolve based on lessons learned

**For Template Users:**
- Provide feedback on template clarity
- Suggest improvements based on usage
- Share successful customizations
- Report confusing or outdated sections

## Examples

### Example 1: New Python Library

```bash
# 1. Use Python Project Template
# 2. Focus on:
#    - API documentation (library users need this)
#    - Unit tests (critical for library quality)
#    - README with installation and examples
# 3. Remove:
#    - Deployment sections (not applicable)
#    - Integration tests (if pure library)
```

### Example 2: AI Agent Application

```bash
# 1. Start with Python Project Template
# 2. Add from Agent Project Template:
#    - Agent architecture components
#    - Tool registry
#    - Orchestration patterns
# 3. Add from Documentation Templates:
#    - README with agent capabilities
#    - Architecture showing agent interactions
```

### Example 3: Czarina Orchestration

```bash
# 1. Use Worker Definition Template for each worker
# 2. Create Worker Identity files
# 3. Execute work following task lists
# 4. Complete with Worker Closeout Template
# 5. QA integrates using closeout reports
```

## Version History

### v1.0.0 (2025-12-26)
- Initial template collection
- 12 comprehensive templates
- Integration with agent-rules
- Usage guide and examples

## Contributing

### Adding New Templates

1. Follow existing template structure:
   - Metadata header (Source, Version, Last Updated)
   - Overview and "When to Use"
   - Quick Start section
   - Detailed content
   - Best practices
   - Related documents
   - References

2. Add entry to this README:
   - Template category
   - Description
   - When to use
   - Cross-references

3. Test template:
   - Try using it for a real project
   - Gather feedback
   - Iterate

### Improving Existing Templates

1. Keep structure consistent
2. Update all affected templates
3. Version changes
4. Document in changelog

## Related Directories

- [Documentation Standards](../core-rules/documentation/) - Comprehensive documentation standards
- [Orchestration Rules](../core-rules/orchestration/) - Czarina orchestration patterns
- [Agent Rules](../core-rules/agent-roles/) - Agent role definitions
- [Python Standards](../core-rules/python-standards/) - Python coding standards
- [Testing Standards](../core-rules/testing/) - Testing best practices
- [Security Standards](../core-rules/security/README.md) - Security patterns
- [Workflow Standards](../core-rules/workflows/) - Development workflows
- [Design Patterns](../patterns/) - Implementation patterns

## Support

### Questions?

- Check template comments and examples
- Review related agent-rules documents
- Consult project-specific documentation
- Ask in team discussions

### Template Not Working?

1. Verify placeholders are replaced
2. Check related agent-rules for context
3. Adapt template to your specific needs
4. Consider if template is right fit for use case

## License

These templates are part of the agent-rules extraction project and follow the project's licensing.

---

**Remember:** Templates are starting points, not constraints. Adapt them to serve your project's needs while maintaining consistency with established patterns.
