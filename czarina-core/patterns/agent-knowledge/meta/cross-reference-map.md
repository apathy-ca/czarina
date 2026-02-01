# Cross-Reference Map

**Date**: 2025-12-29 (Validated)
**Purpose**: Map relationships between core-rules and patterns content for easy navigation.

This document provides a comprehensive map of how content in `core-rules/` relates to content in `patterns/`, enabling users to navigate between standards/requirements and practical implementation patterns.

---

## General Principle

**Core Rules** = What you must do (standards, requirements, definitions)
**Patterns** = How to do it well (proven strategies, examples, optimizations)

---

## Content Relationships

### Git Workflows

**Core Rules:**
- [Git Workflow](../core-rules/workflows/GIT_WORKFLOW.md) - General git workflow rules and standards
- [PR Requirements](../core-rules/workflows/PR_REQUIREMENTS.md) - Pull request review criteria
- [Documentation Workflow](../core-rules/workflows/DOCUMENTATION_WORKFLOW.md) - Documentation synchronization patterns

**Patterns:**
- [Git Workflow Patterns](../patterns/git-workflows/README.md) - Specific patterns and examples (to be populated)

**Relationship**: Core rules define the git workflow standards (PR-based development, conventional commits, documentation sync). Patterns will show specific examples, branch strategies, and commit message templates.

**Status**: ✅ Cross-referenced

---

### Testing

**Core Rules:**
- [Testing Standards](../core-rules/testing/README.md) - Comprehensive testing documentation overview
- [Testing Policy](../core-rules/testing/TESTING_POLICY.md) - When tests are required, philosophy, core principles
- [Unit Testing](../core-rules/testing/UNIT_TESTING.md) - Unit test principles and patterns
- [Integration Testing](../core-rules/testing/INTEGRATION_TESTING.md) - Integration testing with Docker
- [Mocking Strategies](../core-rules/testing/MOCKING_STRATEGIES.md) - Mock object patterns
- [Coverage Standards](../core-rules/testing/COVERAGE_STANDARDS.md) - Coverage requirements and tools

**Patterns:**
- [Testing Patterns](../patterns/testing-patterns/README.md) - TDD and automation strategies for AI-assisted development (to be populated)

**Relationship**: Core rules define comprehensive testing standards, requirements, and best practices. Patterns will show AI-assisted testing strategies, test generation workflows, and automation patterns.

**Status**: ✅ Cross-referenced

---

### Agent Roles / Mode Capabilities

**Core Rules:**
- [Agent Roles Overview](../core-rules/agent-roles/README.md) - Complete role taxonomy and worker organization
- [Architect Role](../core-rules/agent-roles/ARCHITECT_ROLE.md) - Planning and design role
- [Code Role](../core-rules/agent-roles/CODE_ROLE.md) - Implementation role
- [Debug Role](../core-rules/agent-roles/DEBUG_ROLE.md) - Troubleshooting role
- [QA Role](../core-rules/agent-roles/QA_ROLE.md) - Quality assurance role
- [Orchestrator Role](../core-rules/agent-roles/ORCHESTRATOR_ROLE.md) - Multi-task coordination role

**Patterns:**
- [Mode Capabilities](../patterns/mode-capabilities/README.md) - Tool-specific mode definitions and optimization (to be populated)

**Relationship**: Core rules define generic agent roles and their responsibilities (applicable across different AI assistants). Patterns will show tool-specific mode capabilities, constraints, and optimization techniques for specific AI coding assistants (Kilo Code, Claude Code, etc.).

**Status**: ✅ Cross-referenced

---

### Error Recovery

**Core Rules:**
- [Error Recovery Design Patterns](../core-rules/design-patterns/ERROR_RECOVERY.md) - Comprehensive retry patterns, circuit breakers, fallback strategies
- [Error Handling Standards](../core-rules/python-standards/ERROR_HANDLING.md) - Python error handling best practices

**Patterns:**
- [Error Recovery Patterns](../patterns/error-recovery/README.md) - Common errors and recovery strategies in AI-assisted development
- [Detection Patterns](../patterns/error-recovery/detection-patterns.md) - Recognizing error patterns
- [Recovery Strategies](../patterns/error-recovery/recovery-strategies.md) - Systematic recovery approaches
- [Retry Patterns](../patterns/error-recovery/retry-patterns.md) - Retry and backoff strategies
- [Fallback Patterns](../patterns/error-recovery/fallback-patterns.md) - Graceful degradation patterns

**Relationship**: Core rules provide comprehensive error recovery design patterns with implementations (retry handlers, circuit breakers, exponential backoff). Patterns provide specific common errors encountered in AI-assisted development and quick recovery strategies.

**Status**: ✅ Cross-referenced

---

### Context Management

**Core Rules:**
- [Design Patterns](../core-rules/design-patterns/README.md) - Overview (may include context-related patterns)
- [Caching Patterns](../core-rules/design-patterns/CACHING_PATTERNS.md) - May include context caching

**Patterns:**
- [Context Management](../patterns/context-management/README.md) - Context window management, attention strategies (to be populated)

**Relationship**: Core rules may include some caching and optimization patterns that relate to context. Patterns will provide specific strategies for managing context windows, attention, and memory in AI coding assistant interactions.

**Status**: ✅ Cross-referenced (placeholders established)

---

### Tool Usage

**Core Rules:**
- [Tool Use Design Patterns](../core-rules/design-patterns/TOOL_USE_PATTERNS.md) - Comprehensive tool usage patterns and optimization

**Patterns:**
- [Tool Use Patterns](../patterns/tool-use/README.md) - Specific AI assistant tool usage strategies (to be populated)

**Relationship**: Core rules define comprehensive tool use patterns with implementations. Patterns will provide specific strategies optimized for AI coding assistants (file reading strategies, search vs read, command execution).

**Status**: ⏳ To be cross-referenced when patterns content is added

---

### Python Standards

**Core Rules:**
- [Python Coding Standards](../core-rules/python-standards/CODING_STANDARDS.md) - Python code style and conventions
- [Async Patterns](../core-rules/python-standards/ASYNC_PATTERNS.md) - Asynchronous programming patterns
- [Error Handling](../core-rules/python-standards/ERROR_HANDLING.md) - Python error handling
- [Security Patterns](../core-rules/python-standards/SECURITY_PATTERNS.md) - Python security best practices
- [Testing Patterns](../core-rules/python-standards/TESTING_PATTERNS.md) - Python testing patterns
- [Dependency Injection](../core-rules/python-standards/DEPENDENCY_INJECTION.md) - DI patterns

**Patterns:**
- No specific patterns directory (Python standards are comprehensive)

**Relationship**: Python standards in core-rules are self-contained and comprehensive.

**Status**: N/A

---

### Security

**Core Rules:**
- [Security Overview](../core-rules/security/README.md) - Security standards overview
- [Authentication](../core-rules/security/AUTHENTICATION.md) - Authentication patterns
- [Authorization](../core-rules/security/AUTHORIZATION.md) - Authorization patterns
- [Injection Prevention](../core-rules/security/INJECTION_PREVENTION.md) - SQL/command injection prevention
- [Secret Management](../core-rules/security/SECRET_MANAGEMENT.md) - Secrets and credentials management
- [Audit Logging](../core-rules/security/AUDIT_LOGGING.md) - Security audit logging

**Patterns:**
- No specific patterns directory (Security standards are comprehensive)

**Relationship**: Security standards in core-rules are comprehensive and self-contained.

**Status**: N/A

---

### Documentation

**Core Rules:**
- [Documentation Standards](../core-rules/documentation/DOCUMENTATION_STANDARDS.md) - Documentation requirements
- [API Documentation](../core-rules/documentation/API_DOCUMENTATION.md) - API documentation patterns
- [Architecture Docs](../core-rules/documentation/ARCHITECTURE_DOCS.md) - Architecture documentation
- [Changelog Standards](../core-rules/documentation/CHANGELOG_STANDARDS.md) - Changelog format
- [README Template](../core-rules/documentation/README_TEMPLATE.md) - README structure

**Patterns:**
- No specific patterns directory (Documentation standards are comprehensive)

**Relationship**: Documentation standards in core-rules are comprehensive and include templates.

**Status**: N/A

---

### Design Patterns

**Core Rules:**
- [Design Patterns Overview](../core-rules/design-patterns/README.md) - All design patterns index
- [Batch Operations](../core-rules/design-patterns/BATCH_OPERATIONS.md) - Batch processing patterns
- [Caching Patterns](../core-rules/design-patterns/CACHING_PATTERNS.md) - Caching strategies
- [Streaming Patterns](../core-rules/design-patterns/STREAMING_PATTERNS.md) - Data streaming patterns
- [Tool Use Patterns](../core-rules/design-patterns/TOOL_USE_PATTERNS.md) - Tool usage optimization

**Patterns:**
- Various pattern directories provide specific examples and AI-assisted strategies

**Relationship**: Design patterns in core-rules provide comprehensive implementations. Patterns directories provide AI-assisted development-specific applications.

**Status**: Varies by pattern type

---

### Workflows

**Core Rules:**
- [Workflows Overview](../core-rules/workflows/README.md) - All workflows index
- [Git Workflow](../core-rules/workflows/GIT_WORKFLOW.md) - Git workflow standards
- [PR Requirements](../core-rules/workflows/PR_REQUIREMENTS.md) - Pull request review
- [Documentation Workflow](../core-rules/workflows/DOCUMENTATION_WORKFLOW.md) - Doc sync workflow
- [Phase Development](../core-rules/workflows/PHASE_DEVELOPMENT.md) - Phase-based development
- [Closeout Process](../core-rules/workflows/CLOSEOUT_PROCESS.md) - Project closeout
- [Token Planning](../core-rules/workflows/TOKEN_PLANNING.md) - Token budget planning

**Patterns:**
- [Git Workflows](../patterns/git-workflows/README.md) - Specific git patterns
- Other workflow patterns may be added

**Relationship**: Core rules define comprehensive workflow standards. Patterns provide specific examples and strategies.

**Status**: Git workflows ✅ cross-referenced, others to be added as needed

---

### Orchestration

**Core Rules:**
- [Orchestration Patterns](../core-rules/orchestration/ORCHESTRATION_PATTERNS.md) - Multi-agent orchestration patterns

**Patterns:**
- No specific patterns directory (Orchestration patterns are in core-rules)

**Relationship**: Orchestration patterns are comprehensive in core-rules.

**Status**: N/A

---

## Navigation Tips

### From Core Rules to Patterns

When reading core-rules documentation:
1. Look for "Related Patterns" sections at the end
2. These link to specific pattern directories
3. Patterns provide practical examples and AI-assisted strategies

### From Patterns to Core Rules

When reading patterns documentation:
1. Look for "Related Core Rules" sections
2. These link to comprehensive standards and requirements
3. Core rules provide the full context and implementation details

### Quick Reference

**Need standards and requirements?** → Start in `core-rules/`
**Need practical examples?** → Start in `patterns/`
**Need both?** → Use cross-references to navigate between them

---

## Maintenance

### When Adding New Content

**Adding to core-rules:**
1. Identify related patterns
2. Add "Related Patterns" section
3. Update this cross-reference map

**Adding to patterns:**
1. Identify related core rules
2. Add "Related Core Rules" section
3. Update this cross-reference map

### Validation

Periodically validate:
- All cross-references are bidirectional
- Links are not broken
- Relationships are clearly explained
- New content is properly cross-referenced

---

## Summary

**Total Cross-Referenced Areas**: 6
- ✅ Git Workflows
- ✅ Testing
- ✅ Agent Roles / Mode Capabilities
- ✅ Error Recovery
- ✅ Context Management (placeholders)
- ⏳ Tool Use (pending patterns content)

**Principle Upheld**: Clear separation between standards (core-rules) and strategies (patterns), with comprehensive bidirectional navigation.

---

**Last Updated**: 2025-12-29 (Validated)
**Maintained By**: harmonize-content worker
**Next Review**: When new content is added to either core-rules/ or patterns/
