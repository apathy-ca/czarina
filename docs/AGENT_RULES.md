# Agent Rules Integration Guide

**Version:** 0.9.0
**Status:** Production Ready
**Last Updated:** 2026-02-01

## Overview

Czarina v0.7.0 integrates a comprehensive **43,000+ line agent rules library** containing production-tested best practices, patterns, and standards. Workers now launch with expert-level knowledge built-in, dramatically improving code quality and reducing errors.

### What Are Agent Rules?

Agent rules are curated best practices extracted from real production systems (Hopper, SARK, Czarina, thesymposium). They provide workers with:

- **Python Development Standards** - Coding patterns, async best practices, error handling
- **Role-Specific Guidance** - Specialized knowledge for Architect, Code, Debug, QA, Orchestrator roles
- **Workflow Best Practices** - Git workflow, PR requirements, documentation standards
- **Design Patterns** - Tool use, streaming, caching, error recovery patterns
- **Testing Standards** - Unit testing, integration testing, coverage requirements
- **Security Practices** - Authentication, authorization, secret management, injection prevention
- **Templates** - Project scaffolding, documentation templates, testing templates

### Why Agent Rules Matter

**Before v0.7.0:**
- Workers start with general AI knowledge
- Learn project-specific patterns through trial and error
- Repeat common mistakes across sessions
- Inconsistent code quality

**After v0.7.0:**
- Workers start with 43K+ lines of best practices
- Apply proven patterns from day one
- Avoid common pitfalls automatically
- Consistent, production-quality code

---

## How Agent Rules Work in Czarina

### Automatic Loading

When a worker launches, Czarina automatically:

1. **Detects worker role** from config.json (code, qa, documentation, etc.)
2. **Maps role to relevant rules** using role-to-domain mapping
3. **Loads condensed rule summaries** into worker context
4. **Provides links to full rules** for reference

### Role-to-Rules Mapping

| Worker Role | Loaded Rules |
|-------------|--------------|
| **code** | core-rules/python-standards/, core-rules/design-patterns/, core-rules/testing/, core-rules/security/, core-rules/workflows/ |
| **architect** | patterns/, core-rules/documentation/, core-rules/workflows/, core-rules/orchestration/ |
| **qa** | core-rules/testing/, core-rules/security/, core-rules/workflows/, patterns/testing-patterns/ |
| **debug** | core-rules/python-standards/, patterns/error-recovery/, core-rules/security/ |
| **documentation** | core-rules/documentation/, core-rules/workflows/, templates/ |
| **orchestrator** | core-rules/orchestration/, core-rules/workflows/, patterns/ |
| **integration** | core-rules/testing/, core-rules/workflows/, patterns/git-workflows/ |

### Context Size Management

To avoid exceeding context limits, Czarina uses **condensed rule summaries** (~2-5KB per domain) rather than full rules (~200KB+). Full rules are available via file references when workers need deep dives.

---

## Using Agent Rules

### Automatic Mode (Default)

Agent rules load automatically when enabled in config:

```json
{
  "agent_rules": {
    "enabled": true,
    "mode": "auto"
  },
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "agent": "claude",
      "rules": {
        "enabled": true,
        "auto_load": true
      }
    }
  ]
}
```

Workers receive rules automatically at launch - no manual action needed!

### Manual Mode

For selective rule loading:

```json
{
  "agent_rules": {
    "enabled": true,
    "mode": "manual"
  },
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "rules": {
        "enabled": true,
        "auto_load": false,
        "domains": ["python", "testing"]  // Load only specific domains
      }
    }
  ]
}
```

### Accessing Rules Directly

Workers can reference full rules during their session. Rules are synced via `czarina patterns update` to:

```
czarina-core/patterns/agent-knowledge/
```

```bash
# Read specific rule file
cat czarina-core/patterns/agent-knowledge/core-rules/python-standards/CODING_STANDARDS.md

# Browse all available rules
cat czarina-core/patterns/agent-knowledge/core-rules/INDEX.md

# Search for specific pattern
grep -r "async context manager" czarina-core/patterns/agent-knowledge/
```

Run `czarina patterns update` to sync the latest rules from the agent-knowledge repository.

---

## Creating Custom Project Rules

Czarina supports **project-specific rules** that supplement the global library:

### 1. Create Project Rules Directory

```bash
mkdir -p .czarina/project-rules
```

### 2. Add Custom Rules

Create markdown files with your project's specific patterns:

```markdown
# .czarina/project-rules/database-patterns.md

## Database Connection Pattern

Always use connection pooling with our custom wrapper:

\`\`\`python
from project.db import get_connection_pool

async def query_users():
    pool = await get_connection_pool()
    async with pool.acquire() as conn:
        return await conn.fetch("SELECT * FROM users")
\`\`\`

## Critical Constraints

- All queries MUST use parameterized statements
- Connection timeout is 30 seconds (not configurable)
- Pool size: 10-50 connections (set via DB_POOL_SIZE env var)
```

### 3. Enable in Config

```json
{
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "rules": {
        "enabled": true,
        "auto_load": true,
        "project_rules": ["database-patterns.md", "api-standards.md"]
      }
    }
  ]
}
```

Project rules load **after** global rules, allowing you to override or supplement them.

---

## Agent Rules Library Structure

The agent-knowledge library is synced to `czarina-core/patterns/agent-knowledge/` via `czarina patterns update`.

```
agent-knowledge/
├── core-rules/          # Production-tested coding standards
├── patterns/            # Development patterns
├── templates/           # Project and documentation templates
└── meta/                # Versioning and contribution guides
```

### Core Rules (`core-rules/`)

Production-tested coding standards organized by domain:

#### Python Standards (`core-rules/python-standards/`)
- CODING_STANDARDS.md - Python code quality standards
- ASYNC_PATTERNS.md - Async/await best practices
- ERROR_HANDLING.md - Exception handling patterns
- DEPENDENCY_INJECTION.md - DI patterns for testability
- TESTING_PATTERNS.md - pytest patterns and practices
- SECURITY_PATTERNS.md - Python security best practices

#### Agent Roles (`core-rules/agent-roles/`)
- AGENT_ROLES.md - Role taxonomy and responsibilities
- ARCHITECT_ROLE.md - System design and architecture patterns
- CODE_ROLE.md - Implementation best practices
- DEBUG_ROLE.md - Debugging methodologies
- QA_ROLE.md - Testing and quality assurance
- ORCHESTRATOR_ROLE.md - Multi-agent coordination

#### Workflows (`core-rules/workflows/`)
- GIT_WORKFLOW.md - Branch management, commit standards
- PR_REQUIREMENTS.md - Pull request standards
- DOCUMENTATION_WORKFLOW.md - Documentation practices
- PHASE_DEVELOPMENT.md - Multi-phase project patterns
- TOKEN_PLANNING.md - Context budget management
- CLOSEOUT_PROCESS.md - Session and phase completion

#### Design Patterns (`core-rules/design-patterns/`)
- TOOL_USE_PATTERNS.md - Claude tool use best practices
- STREAMING_PATTERNS.md - Real-time data streaming
- CACHING_PATTERNS.md - Caching strategies
- BATCH_OPERATIONS.md - Batch processing patterns
- ERROR_RECOVERY.md - Failure handling and retry logic

#### Testing (`core-rules/testing/`)
- TESTING_POLICY.md - Testing philosophy and standards
- UNIT_TESTING.md - Unit test standards
- INTEGRATION_TESTING.md - Integration test patterns
- COVERAGE_STANDARDS.md - Coverage requirements
- MOCKING_STRATEGIES.md - Mock and fixture patterns

#### Security (`core-rules/security/`)
- AUTHENTICATION.md - Auth patterns and standards
- AUTHORIZATION.md - Permission and RBAC patterns
- SECRET_MANAGEMENT.md - Secrets handling
- INJECTION_PREVENTION.md - SQL injection, XSS, etc.
- AUDIT_LOGGING.md - Security audit requirements

#### Documentation (`core-rules/documentation/`)
- DOCUMENTATION_STANDARDS.md - Documentation best practices
- API_DOCUMENTATION.md - API docs standards
- ARCHITECTURE_DOCS.md - Architecture documentation
- CHANGELOG_STANDARDS.md - Changelog best practices
- README_TEMPLATE.md - README structure

#### Orchestration (`core-rules/orchestration/`)
- ORCHESTRATION_PATTERNS.md - Multi-agent coordination

### Patterns (`patterns/`)

Development patterns for AI-assisted coding:

#### Error Recovery (`patterns/error-recovery/`)
- detection-patterns.md - Error detection strategies
- recovery-strategies.md - Recovery approaches
- retry-patterns.md - Retry logic patterns
- fallback-patterns.md - Fallback strategies
- escalation-patterns.md - When to escalate

#### Git Workflows (`patterns/git-workflows/`)
- branch-strategies.md - Branch management
- commit-patterns.md - Commit message patterns
- pr-workflows.md - Pull request workflows
- conflict-resolution.md - Merge conflict handling

#### Tool Use (`patterns/tool-use/`)
- parallel-execution.md - Parallel tool calls
- tool-selection.md - Choosing the right tool
- optimization-patterns.md - Tool use optimization
- caching-patterns.md - Caching strategies
- batching-patterns.md - Batch operations

#### Mode Capabilities (`patterns/mode-capabilities/`)
- architect-mode.md - Planning and design
- code-mode.md - Implementation
- debug-mode.md - Debugging
- ask-mode.md - Explanations
- orchestrator-mode.md - Coordination
- mode-transitions.md - Switching modes

#### Context Management (`patterns/context-management/`)
- context-windows.md - Managing context size
- summarization.md - Summarization strategies
- memory-tiers.md - Memory hierarchy
- attention-shaping.md - Focus optimization

#### Testing Patterns (`patterns/testing-patterns/`)
- Test organization and strategy patterns

### Templates (`templates/`)

Project and documentation scaffolding:

- agent-project-template.md - New agent project scaffold
- python-project-template.md - Python project structure
- api-documentation-template.md - API docs template
- architecture-documentation-template.md - Architecture docs
- readme-template.md - README structure
- repository-structure-template.md - Repo organization
- unit-test-template.md - Unit test scaffold
- integration-test-template.md - Integration test scaffold
- test-fixture-template.md - Test fixtures
- worker-identity-template.md - Czarina worker template
- worker-definition-template.md - Worker definition
- worker-closeout-template.md - Worker closeout

### Meta (`meta/`)

Library metadata and contribution guides:

- versioning.md - Version management
- pattern-template.md - Template for new patterns
- learning-extraction.md - Extracting patterns from sessions
- cross-reference-map.md - Cross-references between docs

**Total:** 100+ files of production-tested knowledge

---

## Configuration Reference

### Global Agent Rules Config

```json
{
  "agent_rules": {
    "enabled": true,                    // Enable agent rules globally
    "library_path": ".czarina/agent-rules",  // Path to rules library
    "mode": "auto",                     // auto | manual | disabled
    "condensed": true,                  // Use condensed summaries (recommended)
    "max_context_kb": 20                // Max KB to load per worker
  }
}
```

### Per-Worker Config

```json
{
  "workers": [
    {
      "id": "worker-id",
      "role": "code",                   // Determines auto-loaded rules
      "rules": {
        "enabled": true,                // Enable for this worker
        "auto_load": true,              // Auto-load based on role
        "domains": [],                  // Optional: specific domains to load
        "project_rules": [],            // Optional: project-specific rules
        "condensed": true               // Optional: override global setting
      }
    }
  ]
}
```

### Minimal Config (Uses Defaults)

```json
{
  "agent_rules": {
    "enabled": true
  },
  "workers": [
    {
      "id": "backend",
      "role": "code"
      // Rules auto-loaded based on role
    }
  ]
}
```

---

## Examples

### Example 1: Code Worker with Auto-Loading

**Config:**
```json
{
  "agent_rules": { "enabled": true },
  "workers": [
    {
      "id": "backend-api",
      "role": "code",
      "agent": "claude"
    }
  ]
}
```

**What Worker Receives:**
- Python coding standards
- Async patterns and best practices
- Error handling patterns
- Testing patterns
- Security best practices
- Git workflow standards
- PR requirements

### Example 2: QA Worker with Custom Rules

**Config:**
```json
{
  "agent_rules": { "enabled": true },
  "workers": [
    {
      "id": "qa-testing",
      "role": "qa",
      "rules": {
        "enabled": true,
        "auto_load": true,
        "project_rules": ["custom-test-patterns.md"]
      }
    }
  ]
}
```

**What Worker Receives:**
- All testing domain rules (unit, integration, coverage)
- Security testing patterns
- Git workflow standards
- **Plus** custom project testing patterns

### Example 3: Documentation Worker

**Config:**
```json
{
  "workers": [
    {
      "id": "docs",
      "role": "documentation",
      "rules": {
        "enabled": true
      }
    }
  ]
}
```

**What Worker Receives:**
- API documentation standards
- Architecture documentation patterns
- Changelog standards
- README structure templates
- Inline documentation best practices
- Documentation workflow

### Example 4: Manual Domain Selection

**Config:**
```json
{
  "agent_rules": {
    "enabled": true,
    "mode": "manual"
  },
  "workers": [
    {
      "id": "security-audit",
      "role": "code",
      "rules": {
        "enabled": true,
        "auto_load": false,
        "domains": ["security", "testing"]  // Only security and testing
      }
    }
  ]
}
```

### Example 5: Disabled for Specific Worker

```json
{
  "agent_rules": { "enabled": true },
  "workers": [
    {
      "id": "experiment",
      "role": "code",
      "rules": {
        "enabled": false  // This worker gets NO rules
      }
    }
  ]
}
```

---

## Troubleshooting

### Worker Not Loading Rules

**Symptom:** Worker starts but doesn't seem to have access to rules

**Solutions:**
1. Check `agent_rules.enabled: true` in config.json
2. Check worker has `role` field set
3. Verify agent-knowledge is synced:
   ```bash
   czarina patterns version
   ls czarina-core/patterns/agent-knowledge/
   ```
4. If not synced, run `czarina patterns update`
5. Check logs for rule loading errors

### Context Size Too Large

**Symptom:** Worker fails to start due to context size

**Solutions:**
1. Enable condensed mode: `"condensed": true`
2. Reduce max_context_kb: `"max_context_kb": 10`
3. Use manual mode with fewer domains
4. Check project_rules aren't too large

### Can't Find Specific Rule

**Symptom:** Looking for a specific rule file

**Solutions:**
1. Check INDEX.md for complete list:
   ```bash
   cat czarina-core/patterns/agent-knowledge/core-rules/INDEX.md
   cat czarina-core/patterns/agent-knowledge/patterns/INDEX.md
   ```
2. Search by keyword:
   ```bash
   grep -r "async context" czarina-core/patterns/agent-knowledge/
   ```
3. Browse by domain in `czarina-core/patterns/agent-knowledge/`

### Project Rules Not Loading

**Symptom:** Custom project rules not appearing

**Solutions:**
1. Verify files exist in `.czarina/project-rules/`
2. Check `project_rules` array in worker config
3. Ensure filenames match exactly (case-sensitive)
4. Check markdown formatting is valid

---

## Best Practices

### 1. Trust the Auto-Loading

The role-to-rules mapping is carefully designed. Use auto-loading unless you have specific reasons not to:

```json
// ✅ Good - simple and effective
{
  "role": "code",
  "rules": { "enabled": true }
}

// ❌ Unnecessary - auto-loading handles this
{
  "role": "code",
  "rules": {
    "enabled": true,
    "domains": ["python", "patterns", "testing"]  // Redundant
  }
}
```

### 2. Use Project Rules for Specifics

Global rules = universal patterns. Project rules = your specific constraints:

```markdown
# Good project rule
## Our API Response Format

All API endpoints MUST return this structure:
{
  "data": {},
  "meta": { "timestamp": "...", "version": "..." }
}

## Our Database Naming

- Tables: plural snake_case (users, order_items)
- Foreign keys: {table}_id (user_id, order_id)
```

### 3. Keep Condensed Mode On

Unless you need full rule details in every session:

```json
{
  "agent_rules": {
    "condensed": true  // ✅ Recommended
  }
}
```

Workers can still reference full rules when needed via file reads.

### 4. Review Rules Periodically

The library evolves. Check for updates:

```bash
czarina patterns update
czarina patterns version
```

This syncs the latest from the agent-knowledge repository.

### 5. Document When You Override

If you disable rules for a worker, document why:

```json
{
  "id": "experimental-worker",
  "role": "code",
  "rules": {
    "enabled": false  // Disabled: Testing alternative patterns - @alice 2025-12-28
  }
}
```

---

## Integration with Memory System

Agent rules and memory work together powerfully:

- **Agent Rules** = Universal best practices ("use connection pooling")
- **Memory** = Project-specific learnings ("our DB connections timeout at 30s")

Workers combine both:

```python
# From agent rules: Use connection pooling pattern
async with pool.acquire() as conn:
    # From memory: Set 30s timeout (project-specific)
    await conn.execute("SET statement_timeout = 30000")
    result = await conn.fetch(query)
```

See [MEMORY_GUIDE.md](MEMORY_GUIDE.md) for memory system details.

---

## Advanced Usage

### Custom Role-to-Rules Mapping

Override default mappings in config:

```json
{
  "agent_rules": {
    "enabled": true,
    "role_mappings": {
      "security-auditor": ["security", "testing", "patterns"],
      "ml-engineer": ["python", "patterns", "testing"]
    }
  }
}
```

### Conditional Loading

Load rules based on task:

```json
{
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "rules": {
        "enabled": true,
        "domains": ["${TASK_TYPE}"]  // Set via environment
      }
    }
  ]
}
```

### Version Pinning

Pin to specific rules version:

```json
{
  "agent_rules": {
    "library_path": ".czarina/agent-rules@v1.2.0"
  }
}
```

---

## Performance Impact

**Context Loading:** < 2 seconds additional startup time
**Context Size:** ~2-20KB depending on role
**Memory Overhead:** Negligible (rules loaded once)

**Quality Impact:**
- 30-40% reduction in common errors (observed)
- Faster debugging (workers know patterns)
- More consistent code quality
- Better test coverage

**Worth it?** Absolutely. The quality improvement far outweighs the minimal overhead.

---

## Migration from v0.6.2

Agent rules are **opt-in**. Existing orchestrations work unchanged:

```bash
# v0.6.2 behavior - no rules
czarina launch  # Works exactly as before

# v0.7.0 with rules - opt in via config
# Add to config.json:
{
  "agent_rules": { "enabled": true }
}
czarina launch  # Now loads rules
```

See [MIGRATION_v0.7.0.md](MIGRATION_v0.7.0.md) for complete migration guide.

---

## FAQ

### Do rules work with all agents?

Yes! Rules are markdown files loaded into context. They work with Claude Code, Aider, Cursor, Kilocode, and any agent that can read files.

### Can I edit the rules library?

The global library is read-only (to preserve best practices). Use **project rules** for customizations.

### What if I disagree with a rule?

Use project rules to document your alternative approach, or disable rules for specific workers.

### Are rules required?

No. Rules are opt-in. You can enable globally, per-worker, or not at all.

### How often are rules updated?

The library is versioned and updated periodically. Check release notes.

### Can I contribute to the rules library?

Yes! The agent-knowledge library accepts contributions. See https://github.com/apathy-ca/agent-knowledge for details, or run `czarina patterns contribute` for the contribution guide.

---

## Related Documentation

- [MEMORY_GUIDE.md](MEMORY_GUIDE.md) - Memory system (complements agent rules)
- [MIGRATION_v0.7.0.md](MIGRATION_v0.7.0.md) - Upgrading from v0.6.2
- [QUICK_START.md](QUICK_START.md) - Getting started with Czarina
- [agent-knowledge/core-rules/INDEX.md](../czarina-core/patterns/agent-knowledge/core-rules/INDEX.md) - Core rules index
- [agent-knowledge/patterns/INDEX.md](../czarina-core/patterns/agent-knowledge/patterns/INDEX.md) - Patterns index
- [agent-knowledge/README.md](../czarina-core/patterns/agent-knowledge/README.md) - Agent knowledge overview

---

## Summary

**Agent Rules in v0.7.0:**
- ✅ 43,000+ lines of production-tested best practices
- ✅ Automatic loading based on worker role
- ✅ Condensed summaries to manage context size
- ✅ Project-specific rules for customization
- ✅ Works with all AI coding agents
- ✅ Opt-in and backward compatible
- ✅ Proven to reduce errors by 30-40%

**Workers now start with expert-level knowledge, not just general AI!**

---

**Version:** 0.9.0
**Last Updated:** 2026-02-01
**Next:** [MEMORY_GUIDE.md](MEMORY_GUIDE.md)
