# Testing Patterns for AI-Assisted Development

**Purpose**: Specific testing patterns, strategies, and examples that work well with AI coding assistants.

**Status**: To be populated with patterns from agentic-dev-patterns repository.

## Overview

This directory will contain specific testing patterns and strategies that complement the comprehensive testing standards defined in core-rules. These patterns focus on practical approaches that have proven effective in AI-assisted development.

## Relationship to Core Rules

**Core Rules** define testing standards and requirements (the "what"):
- [Testing Standards](../../core-rules/testing/README.md) - Comprehensive testing documentation overview
- [Testing Policy](../../core-rules/testing/TESTING_POLICY.md) - When tests are required, philosophy, and core principles
- [Unit Testing](../../core-rules/testing/UNIT_TESTING.md) - Unit test principles and patterns
- [Integration Testing](../../core-rules/testing/INTEGRATION_TESTING.md) - Integration testing with Docker infrastructure
- [Mocking Strategies](../../core-rules/testing/MOCKING_STRATEGIES.md) - Mock object patterns and best practices
- [Coverage Standards](../../core-rules/testing/COVERAGE_STANDARDS.md) - Coverage requirements and tools

**Patterns** show AI-assisted testing strategies (the "how"):
- TDD patterns that work well with AI assistants
- Test generation strategies
- Mock creation patterns
- Test isolation techniques
- Automation patterns for test suites

## Planned Content

The following patterns are planned for this directory:

### AI-Assisted TDD Patterns
- Test-first development with AI coding assistants
- Iterative test refinement
- Test case generation strategies
- Edge case identification

### Test Generation Patterns
- Unit test creation workflows
- Integration test scaffolding
- Fixture generation
- Test data management

### Mocking Patterns for AI Development
- Mock object creation strategies
- Dependency injection patterns
- Test double selection
- Mock verification approaches

### Test Isolation Strategies
- Database isolation patterns
- External service mocking
- File system isolation
- Test cleanup automation

### Test Suite Automation
- CI/CD integration patterns
- Test execution optimization
- Parallel test execution
- Flaky test handling

## Value Proposition

Testing patterns from real AI-assisted development experience:
- Comprehensive test suite creation
- Zero production data pollution risk
- High coverage with minimal manual effort
- Fast test execution through proper isolation

## Contributing

When adding patterns to this directory:
1. Ensure they are based on real AI-assisted development experience
2. Include concrete examples with code snippets
3. Explain why the pattern works well with AI assistants
4. Cross-reference to relevant testing standards
5. Include both successful and unsuccessful approaches

## Related Core Rules

For testing standards, requirements, and comprehensive documentation, see:
- [Testing Standards](../../core-rules/testing/README.md) - Overview and quick reference
- [Testing Policy](../../core-rules/testing/TESTING_POLICY.md) - Requirements and philosophy
- [Unit Testing](../../core-rules/testing/UNIT_TESTING.md) - Unit test principles and patterns
- [Integration Testing](../../core-rules/testing/INTEGRATION_TESTING.md) - Integration test patterns
- [Mocking Strategies](../../core-rules/testing/MOCKING_STRATEGIES.md) - Mock object best practices
- [Coverage Standards](../../core-rules/testing/COVERAGE_STANDARDS.md) - Coverage requirements and tools

## Related Patterns

For error handling in tests, see:
- [Error Recovery Patterns](../error-recovery/README.md) - Error detection and recovery strategies
