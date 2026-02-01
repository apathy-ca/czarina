# Agent Rules Library

**Version:** 1.0.0
**Status:** Production Ready
**Last Updated:** 2025-12-27

A comprehensive library of best practices, patterns, and standards for building AI agents and agent-based systems. Extracted from production systems including Hopper, SARK, Czarina, and thesymposium.

---

## Overview

The Agent Rules Library is a curated collection of 53+ rules, patterns, and templates covering all aspects of agent development:

- **Python Development** - Coding standards, async patterns, error handling
- **Agent Roles** - Specialized agent definitions (Architect, Code, Debug, QA, Orchestrator)
- **Workflows** - Git workflow, PR requirements, documentation, closeout processes
- **Design Patterns** - Tool use, streaming, caching, batch operations, error recovery
- **Testing** - Unit testing, integration testing, coverage standards, mocking
- **Security** - Authentication, authorization, secret management, injection prevention
- **Templates** - Project templates, documentation templates, testing templates
- **Documentation** - Standards for API docs, architecture docs, changelogs
- **Orchestration** - Multi-agent coordination patterns (Czarina-style)

---

## Quick Start

### 1. Browse the Library

Start with the [INDEX.md](INDEX.md) to see all available rules organized by category.

### 2. Choose Your Path

**Building a new agent?**
- Start with [agents/AGENT_ROLES.md](agent-roles/AGENT_ROLES.md) to understand role taxonomy
- Review [python/CODING_STANDARDS.md](python-standards/CODING_STANDARDS.md) for code quality
- Use [templates/agent-project-template.md](../templates/agent-project-template.md) to scaffold your project

**Improving an existing system?**
- Check [patterns/](../patterns/) for design patterns you can apply
- Review [security/](security/) for security hardening opportunities
- See [testing/](testing/) to improve test coverage

**Running an orchestration?**
- Study [orchestration/ORCHESTRATION_PATTERNS.md](orchestration/ORCHESTRATION_PATTERNS.md)
- Use worker templates in [agents/templates/](../templates/)
- Follow [workflows/CLOSEOUT_PROCESS.md](workflows/CLOSEOUT_PROCESS.md) for completion

**Integrating with Hopper?**
<!-- - Read <!-- ../.hopper/README.md - .hopper directory not included in this repository --> for integration guide - .hopper directory not included -->
<!-- - Check <!-- ../.hopper/modes/ - .hopper directory not included in this repository --> for mode-specific usage - .hopper directory not included -->

### 3. Apply the Rules

Each rule file contains:
- **Overview** - What the rule is and why it matters
- **Standards** - Concrete requirements and guidelines
- **Examples** - Code examples and use cases
- **Anti-patterns** - Common mistakes to avoid
- **Related Rules** - Cross-references to complementary rules

---

## Library Structure

```
agent-rules/
├── INDEX.md                 # Complete rule index (START HERE)
├── README.md                # This file
│
├── python/                  # Python development standards
│   ├── CODING_STANDARDS.md
│   ├── ASYNC_PATTERNS.md
│   ├── ERROR_HANDLING.md
│   ├── DEPENDENCY_INJECTION.md
│   ├── TESTING_PATTERNS.md
│   ├── SECURITY_PATTERNS.md
│   └── README.md
│
├── agents/                  # Agent role definitions
│   ├── AGENT_ROLES.md
│   ├── ARCHITECT_ROLE.md
│   ├── CODE_ROLE.md
│   ├── DEBUG_ROLE.md
│   ├── QA_ROLE.md
│   ├── ORCHESTRATOR_ROLE.md
│   ├── templates/
│   └── README.md
│
├── workflows/               # Development workflows
│   ├── GIT_WORKFLOW.md
│   ├── PR_REQUIREMENTS.md
│   ├── DOCUMENTATION_WORKFLOW.md
│   ├── PHASE_DEVELOPMENT.md
│   ├── TOKEN_PLANNING.md
│   ├── CLOSEOUT_PROCESS.md
│   └── README.md
│
├── patterns/                # Design patterns
│   ├── TOOL_USE_PATTERNS.md
│   ├── STREAMING_PATTERNS.md
│   ├── CACHING_PATTERNS.md
│   ├── BATCH_OPERATIONS.md
│   ├── ERROR_RECOVERY.md
│   └── README.md
│
├── testing/                 # Testing standards
│   ├── TESTING_POLICY.md
│   ├── UNIT_TESTING.md
│   ├── INTEGRATION_TESTING.md
│   ├── COVERAGE_STANDARDS.md
│   ├── MOCKING_STRATEGIES.md
│   └── README.md
│
├── security/                # Security practices
│   ├── AUTHENTICATION.md
│   ├── AUTHORIZATION.md
│   ├── SECRET_MANAGEMENT.md
│   ├── INJECTION_PREVENTION.md
│   ├── AUDIT_LOGGING.md
│   └── README.md
│
├── templates/               # Reusable templates
│   ├── python-project-template.md
│   ├── agent-project-template.md
│   ├── readme-template.md
│   ├── api-documentation-template.md
│   ├── unit-test-template.md
│   ├── integration-test-template.md
│   └── README.md
│
├── documentation/           # Documentation standards
│   ├── DOCUMENTATION_STANDARDS.md
│   ├── API_DOCUMENTATION.md
│   ├── ARCHITECTURE_DOCS.md
│   ├── CHANGELOG_STANDARDS.md
│   ├── README_TEMPLATE.md
│   └── README.md
│
└── orchestration/           # Multi-agent patterns
    ├── ORCHESTRATION_PATTERNS.md
    └── README.md
```

---

## Usage Scenarios

### Scenario 1: Starting a New Python Agent Project

```bash
# 1. Review the coding standards
cat agent-rules/python/CODING_STANDARDS.md

# 2. Choose an agent role
cat agent-rules/agents/AGENT_ROLES.md

# 3. Use the project template
cp agent-rules/templates/python-project-template.md my-agent/PROJECT_PLAN.md

# 4. Set up testing from the start
cat agent-rules/testing/TESTING_POLICY.md
```

### Scenario 2: Improving Code Quality

```bash
# Review Python standards
agent-rules/python/CODING_STANDARDS.md
agent-rules/python/ERROR_HANDLING.md
agent-rules/python/ASYNC_PATTERNS.md

# Check security
agent-rules/security/INJECTION_PREVENTION.md
agent-rules/security/SECRET_MANAGEMENT.md

# Improve testing
agent-rules/testing/COVERAGE_STANDARDS.md
agent-rules/testing/UNIT_TESTING.md
```

### Scenario 3: Running a Multi-Agent Orchestration

```bash
# Understand orchestration
cat agent-rules/orchestration/ORCHESTRATION_PATTERNS.md

# Set up workers
cp agent-rules/agents/templates/worker-definition-template.md workers/worker1.md
cp agent-rules/agents/templates/worker-identity-template.md workers/WORKER1_IDENTITY.md

# Plan token budgets
cat agent-rules/workflows/TOKEN_PLANNING.md

# Prepare closeout
cp agent-rules/agents/templates/worker-closeout-template.md CLOSEOUT.md
```

### Scenario 4: Integrating with Hopper

```bash
# Read integration guide
<!-- cat .hopper/README.md - .hopper directory not included -->

# Check mode-specific rules
<!-- cat .hopper/modes/research.md - .hopper directory not included -->
<!-- cat .hopper/modes/implementation.md - .hopper directory not included -->

# Configure Hopper to use rules
<!-- # (See .hopper/README.md for configuration) - .hopper directory not included -->
```

---

## Key Features

### ✅ Comprehensive Coverage

53+ rules covering all aspects of agent development from coding to deployment.

### ✅ Production-Tested

Extracted from real production systems with proven track records:
- **Hopper** - Multi-mode agent system
- **SARK** - Systematic Acknowledgment and Review Kit
- **Czarina** - Multi-agent orchestration framework
- **thesymposium** - Agent collaboration patterns

### ✅ Actionable Guidance

Every rule includes:
- Clear standards and requirements
- Concrete code examples
- Common anti-patterns to avoid
- Cross-references to related rules

### ✅ Template-Driven

13 reusable templates for:
- Project setup
- Documentation
- Testing
- Worker orchestration

### ✅ Well-Organized

9 logical domains make finding the right rule easy. Start with [INDEX.md](INDEX.md).

---

## Domain Overviews

### Python Development (`python/`)

Language-specific standards for Python agent development. Covers coding style, async patterns, error handling, dependency injection, testing, and security.

**Key Rules:**
- [CODING_STANDARDS.md](python-standards/CODING_STANDARDS.md) - Python style guide and best practices
- [ASYNC_PATTERNS.md](python-standards/ASYNC_PATTERNS.md) - Async/await patterns with asyncio
- [ERROR_HANDLING.md](python-standards/ERROR_HANDLING.md) - Exception handling strategies

### Agent Roles (`agents/`)

Specialized agent role definitions for different tasks. Includes templates for worker setup in orchestrations.

**Key Roles:**
- [ARCHITECT_ROLE.md](agent-roles/ARCHITECT_ROLE.md) - System design and planning
- [CODE_ROLE.md](agent-roles/CODE_ROLE.md) - Implementation tasks
- [ORCHESTRATOR_ROLE.md](agent-roles/ORCHESTRATOR_ROLE.md) - Multi-agent coordination

### Workflows (`workflows/`)

Development process patterns including git workflow, PR requirements, documentation practices, and project closeout.

**Key Workflows:**
- [GIT_WORKFLOW.md](workflows/GIT_WORKFLOW.md) - Branching and version control
- [PR_REQUIREMENTS.md](workflows/PR_REQUIREMENTS.md) - Pull request standards
- [CLOSEOUT_PROCESS.md](workflows/CLOSEOUT_PROCESS.md) - Project completion

### Design Patterns (`patterns/`)

Architectural patterns for agent systems including tool use, streaming, caching, and error recovery.

**Key Patterns:**
- [TOOL_USE_PATTERNS.md](../patterns/tool-use/README.md) - Effective LLM tool calling
- [ERROR_RECOVERY.md](../patterns/error-recovery/README.md) - Resilience strategies
- [CACHING_PATTERNS.md](../patterns/tool-use/caching-patterns.md) - Performance optimization

### Testing (`testing/`)

Comprehensive testing standards including unit testing, integration testing, coverage requirements, and mocking strategies.

**Key Standards:**
- [TESTING_POLICY.md](testing/TESTING_POLICY.md) - Overall testing philosophy
- [UNIT_TESTING.md](testing/UNIT_TESTING.md) - Unit test best practices
- [COVERAGE_STANDARDS.md](testing/COVERAGE_STANDARDS.md) - Coverage requirements

### Security (`security/`)

Security best practices for authentication, authorization, secret management, and protection against common vulnerabilities.

**Key Practices:**
- [SECRET_MANAGEMENT.md](security/SECRET_MANAGEMENT.md) - Secure credential handling
- [INJECTION_PREVENTION.md](security/INJECTION_PREVENTION.md) - Protection against injections
- [AUTHORIZATION.md](security/AUTHORIZATION.md) - Access control patterns

### Templates (`templates/`)

Reusable templates for projects, documentation, and testing. Use these as starting points for new work.

**Key Templates:**
- [agent-project-template.md](../templates/agent-project-template.md) - Agent project structure
- [readme-template.md](../templates/readme-template.md) - README structure
- [unit-test-template.md](../templates/unit-test-template.md) - Unit test template

### Documentation (`documentation/`)

Standards for creating and maintaining technical documentation including API docs, architecture docs, and changelogs.

**Key Standards:**
- [DOCUMENTATION_STANDARDS.md](./documentation/DOCUMENTATION_STANDARDS.md) - Overall documentation requirements
- [API_DOCUMENTATION.md](./documentation/API_DOCUMENTATION.md) - API documentation best practices

### Orchestration (`orchestration/`)

Multi-agent coordination patterns based on the Czarina framework for parallel agent work.

**Key Patterns:**
- [ORCHESTRATION_PATTERNS.md](orchestration/ORCHESTRATION_PATTERNS.md) - Czarina-style coordination

---

## Contributing

### Adding New Rules

1. **Choose the right domain** - Place the rule in the appropriate directory
2. **Follow the template** - Use the structure from existing rules
3. **Include examples** - Add concrete code examples
4. **Document anti-patterns** - Show what NOT to do
5. **Add cross-references** - Link to related rules
6. **Update the index** - Add your rule to [INDEX.md](INDEX.md)
7. **Update domain README** - Update the domain's README.md

### Improving Existing Rules

1. **Make it more actionable** - Add specific examples
2. **Add missing context** - Explain the "why" not just the "what"
3. **Fix errors** - Correct any mistakes or outdated information
4. **Add cross-references** - Link to complementary rules

### Submitting Changes

Follow the [PR_REQUIREMENTS.md](workflows/PR_REQUIREMENTS.md) for pull request standards.

---

## Integration

### Hopper Integration

<!-- Hopper can be configured to load these rules for context-aware assistance. See <!-- ../.hopper/README.md - .hopper directory not included in this repository --> for integration instructions. - .hopper directory not included -->

### Direct Usage

Reference rules directly in:
- Agent system prompts
- Documentation generation
- Code review checklists
- Project planning templates
- Orchestration setup

### As a Learning Resource

Use the library as:
- Training material for new team members
- Reference during code reviews
- Study guide for best practices
- Template source for new projects

---

## Statistics

- **Domains:** 9
- **Total Rules:** 53+
- **Templates:** 13
- **Total Documentation:** ~35,000 lines
- **Production Systems:** 4 (Hopper, SARK, Czarina, thesymposium)

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-12-27 | Initial release - Complete library extraction |

---

## License

This library is part of the Hopper project. See project license for details.

---

## Support

- **Index:** [INDEX.md](INDEX.md) - Find rules by category
<!-- - **Hopper Integration:** <!-- ../.hopper/README.md - .hopper directory not included in this repository --> - .hopper directory not included -->
- **Domain READMEs:** Each domain has a comprehensive README.md

---

**Ready to get started?** Check out the [INDEX.md](INDEX.md) to find the rules you need!
