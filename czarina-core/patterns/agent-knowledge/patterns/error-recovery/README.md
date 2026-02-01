# Error Recovery Patterns for AI-Assisted Development

**Purpose**: Common errors and proven recovery strategies when working with AI coding assistants.

**Value**: 30-50% reduction in debugging time by recognizing patterns quickly.

---

## Philosophy

**Good error recovery**:
- Recognizes patterns quickly
- Has systematic approaches
- Prevents recurrence
- Documents solutions

**Bad error recovery**:
- Tries random fixes
- Doesn't learn from mistakes
- Repeats same errors
- Wastes time

---

## Pattern Categories

### [Detection Patterns](./detection-patterns.md)
Identifying and recognizing common error patterns:
- Docker & Container errors
- Python & Async errors
- Syntax errors
- Import & Dependency errors
- Database errors
- Git & Version Control errors

### [Recovery Strategies](./recovery-strategies.md)
Systematic approaches to recovering from errors:
- Root cause analysis
- Step-by-step recovery procedures
- Diagnostic commands
- Service restoration

### [Retry Patterns](./retry-patterns.md)
Retry logic and backoff strategies:
- When to retry vs. fail fast
- Exponential backoff
- Circuit breaker patterns
- Idempotency considerations

### [Fallback Patterns](./fallback-patterns.md)
Graceful degradation and fallback mechanisms:
- Alternative approaches when primary fails
- Degraded mode operation
- Default values and safe modes
- Resource substitution

### [Escalation Patterns](./escalation-patterns.md)
Knowing when to escalate to human intervention:
- Automated vs. manual recovery
- Error severity classification
- When to ask for help
- Documentation of unresolved issues

---

## Learning from Errors

### Meta-Pattern: Document New Errors

**When you encounter a new error**:
1. Note the error message
2. Document the root cause
3. Record the solution
4. Add to this collection
5. Prevent recurrence

**Template**:
```markdown
### Pattern: [Error Name]

**Error**: [Exact error message]
**Root Cause**: [Why it happened]
**Recovery Strategy**: [Step-by-step fix]
**Prevention**: [How to avoid]
**Real Example**: [Code snippet]
```

---

## Related Patterns

- [Tool Use Patterns](../tool-use/README.md) - Efficient tool usage
- [Testing Patterns](../testing-patterns/README.md) - Testing strategies
- [Git Workflows](../git-workflows/README.md) - Git discipline

## Related Core Rules

For comprehensive error recovery design patterns and implementation, see:
- [Error Recovery Design Patterns](../../core-rules/design-patterns/ERROR_RECOVERY.md) - Retry patterns, circuit breakers, fallback strategies
- [Error Handling Standards](../../core-rules/python-standards/ERROR_HANDLING.md) - Python error handling best practices

---

## Related Core Rules

For error recovery principles and requirements, see:
- [Error Recovery](../../core-rules/design-patterns/ERROR_RECOVERY.md) - Core error recovery principles
- [Error Handling](../../core-rules/python-standards/ERROR_HANDLING.md) - Python error handling standards

**Note**: This patterns directory focuses on **HOW** to recover from specific errors (Docker, Python, database, git). The core-rules directory defines **WHAT** principles to follow for error recovery.

---

**Last Updated**: 2025-11-29
**Patterns**: 12 documented
**Source**: The Symposium development (v0.4.5)

*"Every error is a pattern waiting to be recognized."*
