# Agent Rules Library - Complete Index

**Version:** 1.0.0
**Last Updated:** 2025-12-27
**Total Rules:** 53 rules across 9 domains

---

## Quick Navigation

- [Python Development](#python-development) (7 rules)
- [Agent Roles](#agent-roles) (9 rules)
- [Workflow Patterns](#workflow-patterns) (6 rules)
- [Design Patterns](#design-patterns) (5 rules)
- [Testing Standards](#testing-standards) (5 rules)
- [Security Practices](#security-practices) (5 rules)
- [Templates](#templates) (13 templates)
- [Documentation Standards](#documentation-standards) (5 rules)
- [Orchestration](#orchestration) (1 rule)

---

## Python Development

Comprehensive Python coding standards and patterns for agent development.

**Location:** `agent-rules/python/`

| Rule | Description | Path |
|------|-------------|------|
| **Coding Standards** | Python style guide, naming conventions, and best practices | [CODING_STANDARDS.md](python-standards/CODING_STANDARDS.md) |
| **Async Patterns** | Asynchronous programming patterns with asyncio | [ASYNC_PATTERNS.md](python-standards/ASYNC_PATTERNS.md) |
| **Error Handling** | Exception handling strategies and patterns | [ERROR_HANDLING.md](python-standards/ERROR_HANDLING.md) |
| **Dependency Injection** | Service container and dependency management | [DEPENDENCY_INJECTION.md](python-standards/DEPENDENCY_INJECTION.md) |
| **Testing Patterns** | Python testing patterns with pytest | [TESTING_PATTERNS.md](python-standards/TESTING_PATTERNS.md) |
| **Security Patterns** | Python security best practices | [SECURITY_PATTERNS.md](python-standards/SECURITY_PATTERNS.md) |
| **README** | Python domain overview | [README.md](python-standards/README.md) |

---

## Agent Roles

Specialized agent role definitions for different development tasks.

**Location:** `agent-rules/agents/`

| Role | Description | Path |
|------|-------------|------|
| **Agent Roles Overview** | Taxonomy of agent roles and responsibilities | [AGENT_ROLES.md](agent-roles/AGENT_ROLES.md) |
| **Architect Role** | System design and architecture planning | [ARCHITECT_ROLE.md](agent-roles/ARCHITECT_ROLE.md) |
| **Code Role** | Implementation and coding tasks | [CODE_ROLE.md](agent-roles/CODE_ROLE.md) |
| **Debug Role** | Debugging and troubleshooting | [DEBUG_ROLE.md](agent-roles/DEBUG_ROLE.md) |
| **QA Role** | Testing, validation, and quality assurance | [QA_ROLE.md](agent-roles/QA_ROLE.md) |
| **Orchestrator Role** | Multi-agent coordination (Czar pattern) | [ORCHESTRATOR_ROLE.md](agent-roles/ORCHESTRATOR_ROLE.md) |
| **Worker Identity Template** | Template for worker identity files | [templates/worker-identity-template.md](../templates/worker-identity-template.md) |
| **Worker Definition Template** | Template for worker task definitions | [templates/worker-definition-template.md](../templates/worker-definition-template.md) |
| **Worker Closeout Template** | Template for worker completion reports | [templates/worker-closeout-template.md](../templates/worker-closeout-template.md) |

---

## Workflow Patterns

Development workflows and process standards.

**Location:** `agent-rules/workflows/`

| Workflow | Description | Path |
|----------|-------------|------|
| **Git Workflow** | Branching strategy, commits, and version control | [GIT_WORKFLOW.md](workflows/GIT_WORKFLOW.md) |
| **PR Requirements** | Pull request standards and review process | [PR_REQUIREMENTS.md](workflows/PR_REQUIREMENTS.md) |
| **Documentation Workflow** | Documentation creation and maintenance | [DOCUMENTATION_WORKFLOW.md](workflows/DOCUMENTATION_WORKFLOW.md) |
| **Phase Development** | Multi-phase project development process | [PHASE_DEVELOPMENT.md](workflows/PHASE_DEVELOPMENT.md) |
| **Token Planning** | LLM token budget planning and management | [TOKEN_PLANNING.md](workflows/TOKEN_PLANNING.md) |
| **Closeout Process** | Project completion and handoff procedures | [CLOSEOUT_PROCESS.md](workflows/CLOSEOUT_PROCESS.md) |

---

## Design Patterns

Architectural patterns for agent systems.

**Location:** `agent-rules/patterns/`

| Pattern | Description | Path |
|---------|-------------|------|
| **Tool Use Patterns** | Effective LLM tool calling strategies | [TOOL_USE_PATTERNS.md](design-patterns/TOOL_USE_PATTERNS.md) |
| **Streaming Patterns** | Real-time data streaming and processing | [STREAMING_PATTERNS.md](design-patterns/STREAMING_PATTERNS.md) |
| **Caching Patterns** | Caching strategies for performance | [CACHING_PATTERNS.md](design-patterns/CACHING_PATTERNS.md) |
| **Batch Operations** | Efficient batch processing patterns | [BATCH_OPERATIONS.md](design-patterns/BATCH_OPERATIONS.md) |
| **Error Recovery** | Resilience and error recovery strategies | [ERROR_RECOVERY.md](design-patterns/ERROR_RECOVERY.md) |

---

## Testing Standards

Comprehensive testing policies and methodologies.

**Location:** `agent-rules/testing/`

| Standard | Description | Path |
|----------|-------------|------|
| **Testing Policy** | Overall testing philosophy and requirements | [TESTING_POLICY.md](testing/README.md) |
| **Unit Testing** | Unit test standards and best practices | [UNIT_TESTING.md](testing/UNIT_TESTING.md) |
| **Integration Testing** | Integration test strategies | [INTEGRATION_TESTING.md](testing/INTEGRATION_TESTING.md) |
| **Coverage Standards** | Code coverage requirements and tools | [COVERAGE_STANDARDS.md](testing/COVERAGE_STANDARDS.md) |
| **Mocking Strategies** | Test doubles and mocking patterns | [MOCKING_STRATEGIES.md](testing/README.md#mocking) |

---

## Security Practices

Security standards and implementation guidelines.

**Location:** `agent-rules/security/`

| Practice | Description | Path |
|----------|-------------|------|
| **Authentication** | User authentication patterns | [AUTHENTICATION.md](security/AUTHENTICATION.md) |
| **Authorization** | Access control and permissions | [AUTHORIZATION.md](security/AUTHORIZATION.md) |
| **Secret Management** | Secure credential and secret handling | [SECRET_MANAGEMENT.md](security/SECRET_MANAGEMENT.md) |
| **Injection Prevention** | Protection against injection attacks | [INJECTION_PREVENTION.md](security/INJECTION_PREVENTION.md) |
| **Audit Logging** | Security event logging and monitoring | [AUDIT_LOGGING.md](security/AUDIT_LOGGING.md) |

---

## Templates

Reusable templates for projects, documentation, and testing.

**Location:** `agent-rules/templates/`

### Project Templates

| Template | Description | Path |
|----------|-------------|------|
| **Python Project** | Python project structure and setup | [python-project-template.md](../templates/python-project-template.md) |
| **Agent Project** | Agent-based project template | [agent-project-template.md](../templates/agent-project-template.md) |
| **Repository Structure** | Standard repository organization | [repository-structure-template.md](../templates/repository-structure-template.md) |

### Documentation Templates

| Template | Description | Path |
|----------|-------------|------|
| **README Template** | Comprehensive README structure | [readme-template.md](../templates/readme-template.md) |
| **API Documentation** | API documentation format | [api-documentation-template.md](../templates/api-documentation-template.md) |
| **Architecture Docs** | Architecture documentation template | [architecture-documentation-template.md](../templates/architecture-documentation-template.md) |

### Testing Templates

| Template | Description | Path |
|----------|-------------|------|
| **Unit Test** | Unit test structure and patterns | [unit-test-template.md](../templates/unit-test-template.md) |
| **Integration Test** | Integration test template | [integration-test-template.md](../templates/integration-test-template.md) |
| **Test Fixture** | Test fixture and data template | [test-fixture-template.md](../templates/test-fixture-template.md) |

### Worker Templates

| Template | Description | Path |
|----------|-------------|------|
| **Worker Identity** | Worker identity file template | [worker-identity-template.md](../templates/worker-identity-template.md) |
| **Worker Definition** | Worker task definition template | [worker-definition-template.md](../templates/worker-definition-template.md) |
| **Worker Closeout** | Worker completion report template | [worker-closeout-template.md](../templates/worker-closeout-template.md) |

---

## Documentation Standards

Standards for creating and maintaining documentation.

**Location:** `agent-rules/documentation/`

| Standard | Description | Path |
|----------|-------------|------|
| **Documentation Standards** | Overall documentation philosophy and requirements | [DOCUMENTATION_STANDARDS.md](documentation/DOCUMENTATION_STANDARDS.md) |
| **API Documentation** | API documentation best practices | [API_DOCUMENTATION.md](documentation/API_DOCUMENTATION.md) |
| **Architecture Docs** | Architecture documentation guidelines | [ARCHITECTURE_DOCS.md](documentation/ARCHITECTURE_DOCS.md) |
| **Changelog Standards** | Changelog format and maintenance | [CHANGELOG_STANDARDS.md](documentation/CHANGELOG_STANDARDS.md) |
| **README Template** | README structure template | [README_TEMPLATE.md](documentation/README_TEMPLATE.md) |

---

## Orchestration

Multi-agent orchestration patterns.

**Location:** `agent-rules/orchestration/`

| Pattern | Description | Path |
|---------|-------------|------|
| **Orchestration Patterns** | Czarina-style multi-agent coordination | [ORCHESTRATION_PATTERNS.md](orchestration/ORCHESTRATION_PATTERNS.md) |

---

## Using This Index

### Finding Rules by Topic

1. **Browse by category** - Use the navigation links at the top
2. **Search by keyword** - Use your editor's search function (Ctrl+F / Cmd+F)
3. **Check domain READMEs** - Each domain has a README.md with detailed overviews

### Understanding the Organization

The library is organized into 9 domains:

- **python/** - Language-specific coding standards
- **agents/** - Role-based agent definitions
- **workflows/** - Development process patterns
- **patterns/** - Architectural design patterns
- **testing/** - Testing methodologies and standards
- **security/** - Security best practices
- **templates/** - Reusable project and documentation templates
- **documentation/** - Documentation creation standards
- **orchestration/** - Multi-agent coordination patterns

### Quick Start

1. **New to the library?** Start with [agent-rules/README.md](README.md)
2. **Building a Python agent?** Check [python/CODING_STANDARDS.md](python-standards/CODING_STANDARDS.md)
3. **Setting up a project?** Use [templates/agent-project-template.md](../templates/agent-project-template.md)
4. **Running an orchestration?** See [orchestration/ORCHESTRATION_PATTERNS.md](orchestration/ORCHESTRATION_PATTERNS.md)
<!-- 5. **Integrating with Hopper?** Read .hopper/README.md - .hopper directory not included in this repository -->

---

## Statistics

- **Total Domains:** 9
- **Total Rules:** 53
- **Total Templates:** 13 (included in rule count)
- **Total Files:** 63 (including READMEs)
- **Lines of Documentation:** ~35,000+

---

## Contributing

To add new rules or update existing ones:

1. Follow the [DOCUMENTATION_STANDARDS.md](documentation/DOCUMENTATION_STANDARDS.md)
2. Place new rules in the appropriate domain directory
3. Update this INDEX.md with the new rule
4. Update the domain README.md
5. Submit a pull request following [PR_REQUIREMENTS.md](workflows/PR_REQUIREMENTS.md)

---

## Related Patterns

For practical implementation patterns and AI-assisted development strategies, see:

### Patterns Library

- [**Patterns Overview**](../patterns/INDEX.md) - Complete patterns index
- [Error Recovery Patterns](../patterns/error-recovery/README.md) - Common errors and recovery strategies
- [Git Workflow Patterns](../patterns/git-workflows/README.md) - Specific git patterns and examples
- [Testing Patterns](../patterns/testing-patterns/README.md) - AI-assisted testing strategies
- [Mode Capabilities](../patterns/mode-capabilities/README.md) - Tool-specific mode optimization
- [Context Management](../patterns/context-management/README.md) - Context window management
- [Tool Use Patterns](../patterns/tool-use/README.md) - Efficient tool usage strategies

**Relationship:** Core rules define standards and requirements (the "what"). Patterns show proven strategies and examples (the "how").

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-27 | Initial release - Complete agent rules library extraction |
| 1.1.0 | 2025-12-28 | Added cross-references to patterns library |

---

<!-- **Need help?** Check the main README.md or the .hopper integration guide - .hopper directory not included in this repository -->
