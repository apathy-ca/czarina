# Agent Knowledge

**Production-Tested Rules and Patterns for AI-Assisted Development**

A unified knowledge base combining standards, workflows, and battle-tested patterns for building reliable software with AI assistance.

Used by: **Hopper**, **Czarina**, **The Symposium**, and **SARK**

## Quick Start

- **New to AI development?** Start with [Core Rules Index](./core-rules/INDEX.md)
- **Looking for specific patterns?** Browse [Patterns Index](./patterns/INDEX.md)
- **Setting up a project?** Check [Templates](./templates/)
- **Contributing?** Read [Contributing Guide](./CONTRIBUTING.md)

## Structure

### Core Rules

Production-tested rules extracted from real projects ([Full Index](./core-rules/INDEX.md)):

- **[Python Standards](./core-rules/python-standards/)** - 7 rules, ~1,827 lines
  - Imports, type annotations, async/await, error handling, logging, testing, packaging

- **[Agent Roles](./core-rules/agent-roles/)** - 10 roles, ~11,485 lines
  - Architect, Code, Debug, QA, Orchestrator, Ask, Ops, Security, Docs, Coordination

- **[Workflows](./core-rules/workflows/)** - 7 workflows, ~3,062 lines
  - Feature, bugfix, refactor, investigation, handoff, recovery, git workflows

- **[Design Patterns](./core-rules/design-patterns/)** - 6 patterns, ~1,926 lines
  - Layer-based architecture, modular design, configuration over code, progressive complexity, comprehensive testing, memory patterns

- **[Testing](./core-rules/testing/)** - 6 rules, ~1,799 lines
  - Testing philosophy, pytest standards, test organization, fixtures and mocks, integration testing, coverage requirements

- **[Security](./core-rules/security/)** - 5 rules, ~4,155 lines
  - Authentication, authorization, secrets management, input validation, audit logging

- **[Documentation](./core-rules/documentation/)** - 6 rules, ~1,959 lines
  - Docstring standards, README structure, API documentation, architecture docs, changelog standards, inline comments

- **[Orchestration](./core-rules/orchestration/)** - 2 patterns, ~1,098 lines
  - Task coordination, agent handoffs

**Total:** 53+ rules across 9 domains, ~43,873 lines

### Patterns

Battle-tested patterns with quantified impact ([Full Index](./patterns/INDEX.md)):

- **[Error Recovery](./patterns/error-recovery/)** - 30-50% reduction in debugging time
  - Retry patterns, fallback strategies, circuit breakers, graceful degradation

- **[Tool Use](./patterns/tool-use/)** - 40-60% efficiency improvement
  - Parallel tool calls, tool selection, error handling, optimization strategies

- **[Mode Capabilities](./patterns/mode-capabilities/)** - Role-specific patterns
  - Code mode patterns, ask mode patterns, orchestrator patterns

- **[Context Management](./patterns/context-management/)** - Memory optimization
  - Context window strategies, summarization patterns, context handoff

- **[Git Workflows](./patterns/git-workflows/)** - Consistent version control
  - Branch strategies, commit patterns, PR workflows, conflict resolution

- **[Testing Patterns](./patterns/testing-patterns/)** - Comprehensive coverage
  - Test organization, mocking strategies, integration testing, coverage optimization

### Templates

Quick-start templates for common project types:
- [Project Templates](./templates/)

### Examples

Real-world examples and configurations:
- [Examples](./examples/)

## Usage

### In Hopper

```yaml
# hopper-config.yaml
knowledge:
  agent_knowledge_path: "../agent-knowledge"
  auto_sync: true
```

Hopper uses this knowledge base for:
- Task routing decisions
- Agent role definitions
- Workflow execution
- Pattern application

### In Czarina

```yaml
# .czarina/config.yaml
knowledge:
  agent_knowledge_path: "../agent-knowledge"
  load_on_startup: true
```

Czarina uses this knowledge base for:
- Worker coordination
- Phase management
- Quality standards
- Closeout learning extraction

### In The Symposium

```yaml
# Sage configuration
knowledge:
  base_path: "../agent-knowledge"
  index_patterns: true
```

The Symposium uses this knowledge base for:
- Agent collaboration patterns
- Knowledge sharing
- Learning extraction
- Pattern validation

### In SARK

```yaml
# SARK configuration
knowledge:
  agent_knowledge_path: "../agent-knowledge"
  security_rules: true
```

SARK uses this knowledge base for:
- Security validation
- Compliance checking
- Audit patterns
- Security best practices

## Core Principles

**Core Rules** define **what** you must do:
- Standards and requirements
- Role definitions
- Workflow structures
- Quality criteria

**Patterns** show **how** to do it well:
- Proven strategies
- Real-world examples
- Impact metrics
- Trade-offs and alternatives

## Contributing

This knowledge base grows through continuous learning extraction. See [CONTRIBUTING.md](./CONTRIBUTING.md) for:
- How to submit new patterns
- Pattern review process
- Documentation standards
- Quality requirements

### Continuous Improvement Cycle

```
Development Work
       ↓
  Learnings Captured
       ↓
  Analysis (LLM)
       ↓
  Pattern Proposed
       ↓
  Human Review
       ↓
  Merged to Knowledge Base
       ↓
  Used in Future Development
       ↓
  (cycle repeats)
```

This knowledge base is continuously updated via:
- **Czarina closeout learnings** - What did workers discover?
- **Hopper routing feedback** - What routing decisions worked?
- **Symposium Sage wisdom** - What patterns emerged?
- **SARK security learnings** - What security patterns proved effective?

See [Learning Extraction](./meta/learning-extraction.md) for details.

## Documentation

### Main Documentation
- [README](./README.md) - Overview and quick start
- [CONTRIBUTING](./CONTRIBUTING.md) - Contribution guidelines
- [CHANGELOG](./CHANGELOG.md) - Version history
- [Core Rules Index](./core-rules/INDEX.md) - Browse standards and rules
- [Patterns Index](./patterns/INDEX.md) - Browse proven patterns

### Meta Documentation
- [Cross-Reference Map](./meta/cross-reference-map.md) - Navigate between rules and patterns
- [Versioning Strategy](./meta/versioning.md) - Version bump guidelines
- [Pattern Template](./meta/pattern-template.md) - Template for new patterns
- [Learning Extraction](./meta/learning-extraction.md) - How learnings become patterns

### Archives
Historical documents and migration artifacts are preserved in [docs/archive/](./docs/archive/) for reference.

## License

MIT License - See [LICENSE](./LICENSE)

## Version

**Current version:** v1.0.0

See [CHANGELOG.md](./CHANGELOG.md) for version history and details.

## Credits

Built from production-tested knowledge extracted from real projects, including The Symposium distributed AI platform.

Maintained through continuous learning extraction from:
- **Hopper** - Task routing and agent orchestration
- **Czarina** - Multi-phase project coordination
- **The Symposium** - Distributed AI consciousness platform
- **SARK** - Security validation and compliance

Enhanced through systematic closeout learning analysis and pattern validation.
