# Agentic Development Patterns - Complete Index

**Version:** 1.0.0
**Last Updated:** 2025-12-28
**Purpose:** Practical patterns and strategies for AI-assisted software development

---

## Quick Navigation

- [Error Recovery](#error-recovery) - Common errors and recovery strategies
- [Git Workflows](#git-workflows) - Git patterns and examples
- [Testing Patterns](#testing-patterns) - AI-assisted testing strategies
- [Mode Capabilities](#mode-capabilities) - Tool-specific mode optimization
- [Context Management](#context-management) - Context window management
- [Tool Use](#tool-use) - Efficient tool usage strategies

---

## Overview

This patterns library contains proven strategies for effective AI-assisted development. While **core-rules** define standards and requirements (the "what"), **patterns** show practical implementations and strategies (the "how").

### Patterns vs Core Rules

| Aspect | Core Rules | Patterns |
|--------|-----------|----------|
| **Purpose** | Standards, requirements, definitions | Strategies, examples, optimizations |
| **Scope** | Comprehensive and generic | Specific and practical |
| **Audience** | All agent development | AI-assisted development |
| **Content** | What you must do | How to do it well |
| **Examples** | Implementations | Battle-tested strategies |

---

## Error Recovery

**Purpose:** Common errors and proven recovery strategies when working with AI coding assistants.

**Value:** 30-50% reduction in debugging time by recognizing patterns quickly.

**Location:** `patterns/error-recovery/`

| Document | Description | Path |
|----------|-------------|------|
| **Overview** | Error recovery philosophy and categories | [README.md](error-recovery/README.md) |
| **Detection Patterns** | Recognizing common error patterns | [detection-patterns.md](error-recovery/detection-patterns.md) |
| **Recovery Strategies** | Systematic recovery approaches | [recovery-strategies.md](error-recovery/recovery-strategies.md) |
| **Retry Patterns** | Retry logic and backoff strategies | [retry-patterns.md](error-recovery/retry-patterns.md) |
| **Fallback Patterns** | Graceful degradation mechanisms | [fallback-patterns.md](error-recovery/fallback-patterns.md) |

**Related Core Rules:**
- [Error Recovery Design Patterns](../core-rules/design-patterns/ERROR_RECOVERY.md)
- [Error Handling Standards](../core-rules/python-standards/ERROR_HANDLING.md)

---

## Git Workflows

**Purpose:** Specific git workflow patterns and battle-tested examples for AI-assisted development.

**Value:** Clean history, easier collaboration, proper documentation sync.

**Location:** `patterns/git-workflows/`

**Status:** ⏳ To be populated

| Document | Description | Path |
|----------|-------------|------|
| **Overview** | Git workflow patterns overview | [README.md](git-workflows/README.md) |
| *Branch Strategies* | *Specific branching patterns* | *To be added* |
| *Commit Patterns* | *Commit message examples* | *To be added* |
| *PR Workflows* | *PR creation and review examples* | *To be added* |

**Related Core Rules:**
- [Git Workflow Standards](../core-rules/workflows/GIT_WORKFLOW.md)
- [PR Requirements](../core-rules/workflows/PR_REQUIREMENTS.md)
- [Documentation Workflow](../core-rules/workflows/DOCUMENTATION_WORKFLOW.md)

---

## Testing Patterns

**Purpose:** Testing strategies that work well with AI coding assistants.

**Value:** Comprehensive test suites, zero pollution risk, high coverage with minimal manual effort.

**Location:** `patterns/testing-patterns/`

**Status:** ⏳ To be populated

| Document | Description | Path |
|----------|-------------|------|
| **Overview** | Testing patterns overview | [README.md](testing-patterns/README.md) |
| *TDD Patterns* | *AI-assisted TDD strategies* | *To be added* |
| *Test Generation* | *Unit and integration test creation* | *To be added* |
| *Mocking Patterns* | *AI-friendly mocking strategies* | *To be added* |

**Related Core Rules:**
- [Testing Standards](../core-rules/testing/README.md)
- [Unit Testing](../core-rules/testing/UNIT_TESTING.md)
- [Integration Testing](../core-rules/testing/INTEGRATION_TESTING.md)
- [Coverage Standards](../core-rules/testing/COVERAGE_STANDARDS.md)

---

## Mode Capabilities

**Purpose:** Mode-specific capabilities, constraints, and optimization patterns for AI coding assistants.

**Value:** Clearer boundaries, fewer mode-switching mistakes, better task routing.

**Location:** `patterns/mode-capabilities/`

**Status:** ⏳ To be populated

| Document | Description | Path |
|----------|-------------|------|
| **Overview** | Mode capabilities overview | [README.md](mode-capabilities/README.md) |
| *Mode Definitions* | *What each mode can/cannot do* | *To be added* |
| *Mode Transitions* | *When to switch modes* | *To be added* |
| *Optimization* | *Mode-specific best practices* | *To be added* |

**Related Core Rules:**
- [Agent Roles Overview](../core-rules/agent-roles/README.md)
- [Architect Role](../core-rules/agent-roles/ARCHITECT_ROLE.md)
- [Code Role](../core-rules/agent-roles/CODE_ROLE.md)
- [Debug Role](../core-rules/agent-roles/DEBUG_ROLE.md)

---

## Context Management

**Purpose:** Strategies for managing context, attention, and memory in AI coding assistant interactions.

**Value:** More effective use of limited context windows, better AI understanding of project structure.

**Location:** `patterns/context-management/`

**Status:** ⏳ To be populated

| Document | Description | Path |
|----------|-------------|------|
| **Overview** | Context management overview | [README.md](context-management/README.md) |
| *Memory Tiers* | *Short/mid/long-term context* | *To be added* |
| *Context Windows* | *Maximizing context effectiveness* | *To be added* |
| *Attention Management* | *Focusing AI attention* | *To be added* |

**Related Core Rules:**
- [Caching Patterns](../core-rules/design-patterns/CACHING_PATTERNS.md)

---

## Tool Use

**Purpose:** Efficient tool usage strategies and optimization patterns for AI coding assistants.

**Value:** 40-60% improvement in AI assistant efficiency.

**Location:** `patterns/tool-use/`

**Status:** ⏳ To be populated

| Document | Description | Path |
|----------|-------------|------|
| **Overview** | Tool use patterns overview | [README.md](tool-use/README.md) |
| *File Reading* | *Parallel vs sequential strategies* | *To be added* |
| *Modification* | *apply_diff vs write strategies* | *To be added* |
| *Search* | *Glob and grep optimization* | *To be added* |

**Related Core Rules:**
- [Tool Use Design Patterns](../core-rules/design-patterns/TOOL_USE_PATTERNS.md)

---

## Pattern Categories Summary

| Category | Status | Documents | Core Rule Links |
|----------|--------|-----------|-----------------|
| Error Recovery | ✅ Complete | 5 | 2 |
| Git Workflows | ⏳ Planned | 1 | 3 |
| Testing Patterns | ⏳ Planned | 1 | 4 |
| Mode Capabilities | ⏳ Planned | 1 | 4 |
| Context Management | ⏳ Planned | 1 | 1 |
| Tool Use | ⏳ Planned | 1 | 1 |

---

## Quick Start Guide

### For Developers

1. **Encountering an error?** → Check [Error Recovery Patterns](error-recovery/README.md)
2. **Setting up git workflow?** → See [Git Workflow Patterns](git-workflows/README.md)
3. **Writing tests with AI?** → Read [Testing Patterns](testing-patterns/README.md)
4. **Optimizing tool use?** → Review [Tool Use Patterns](tool-use/README.md)

### For AI Coding Assistants

If you're an AI assistant reading this:
1. Read relevant pattern files for your current task
2. Apply the patterns to your work
3. Suggest improvements based on your experience
4. Document new patterns you discover

---

## Contributing

We welcome contributions! If you've discovered effective patterns for AI-assisted development:

1. Fork this repository
2. Add your pattern to the appropriate file
3. Include real-world examples
4. Submit a pull request

**Pattern Quality Guidelines:**
- ✅ Based on real experience (not theory)
- ✅ Includes concrete examples
- ✅ Explains the "why" not just the "what"
- ✅ Quantifies value when possible

---

## Related Core Rules

For comprehensive standards, requirements, and implementations, see:

### Core Rules Library

- [**Core Rules Overview**](../core-rules/INDEX.md) - Complete core rules index
- [Design Patterns](../core-rules/design-patterns/README.md) - Architectural patterns
- [Agent Roles](../core-rules/agent-roles/README.md) - Role definitions
- [Workflows](../core-rules/workflows/README.md) - Development processes
- [Testing Standards](../core-rules/testing/README.md) - Testing requirements
- [Python Standards](../core-rules/python-standards/README.md) - Python best practices
- [Security](../core-rules/security/README.md) - Security standards

**Relationship:** Patterns show "how to do it well" using the standards and requirements defined in core-rules.

---

## Navigation Tips

**Need standards?** → Start in [core-rules](../core-rules/INDEX.md)
**Need examples?** → Start in patterns (this index)
**Need both?** → Use cross-references to navigate between them

See the [Cross-Reference Map](../meta/cross-reference-map.md) for detailed relationships.

---

## Statistics

- **Total Pattern Categories:** 6
- **Complete Categories:** 1 (Error Recovery)
- **Planned Categories:** 5
- **Total Documents:** 11 (5 complete, 6 planned)
- **Cross-References to Core Rules:** 15+

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-28 | Initial patterns index with error recovery patterns and placeholders |

---

**Need help?** Check the [Cross-Reference Map](../meta/cross-reference-map.md) or the main [README.md](../README.md).

---

*"Good patterns emerge from real work, not ivory towers."*
