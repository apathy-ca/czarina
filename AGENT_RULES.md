# Agent Rules Library Integration

**Status:** Active
**Version:** 1.0.0 (Agent Rules Library)
**Integration Date:** 2025-12-28
**Location:** `czarina-core/agent-rules/`

---

## Overview

Czarina now has direct access to the **Agent Rules Library**, a comprehensive collection of 43,873+ lines of production-tested best practices, patterns, and standards for building AI agents and agent-based systems.

The library was **created BY Czarina** (7-worker orchestration, 100% success rate) and is now integrated FOR Czarina - making it available to all workers for improved code quality, standardization, and best practices.

---

## What's Available

### 9 Domains, 53+ Rules

| Domain | Files | Description |
|--------|-------|-------------|
| **Python** | 7 rules | Coding standards, async patterns, error handling, dependency injection, testing, security |
| **Agents** | 9 rules | Role definitions (Architect, Code, Debug, QA, Orchestrator) and worker templates |
| **Workflows** | 6 rules | Git workflow, PR requirements, documentation, phase development, closeout |
| **Patterns** | 5 rules | Tool use, streaming, caching, batch operations, error recovery |
| **Testing** | 5 rules | Testing policy, unit/integration testing, coverage standards, mocking |
| **Security** | 5 rules | Authentication, authorization, secret management, injection prevention, audit logging |
| **Templates** | 13 templates | Project, documentation, and testing templates |
| **Documentation** | 5 rules | Documentation standards, API docs, architecture docs, changelogs |
| **Orchestration** | 1 rule | Multi-agent coordination patterns (Czarina-style) |

**Total:** 43,873 lines of documentation across 69 markdown files

---

## Quick Start

### 1. Browse the Library

```bash
# See complete index
cat czarina-core/agent-rules/INDEX.md

# Read the overview
cat czarina-core/agent-rules/README.md

# View usage guide
cat czarina-core/agent-rules/USAGE_GUIDE.md
```

### 2. Find What You Need

**For Workers:**
```bash
# Understand your role
cat czarina-core/agent-rules/agents/AGENT_ROLES.md
cat czarina-core/agent-rules/agents/CODE_ROLE.md      # Implementation tasks
cat czarina-core/agent-rules/agents/ARCHITECT_ROLE.md # Design/planning
cat czarina-core/agent-rules/agents/DEBUG_ROLE.md     # Troubleshooting
cat czarina-core/agent-rules/agents/QA_ROLE.md        # Testing/validation

# Worker templates
ls czarina-core/agent-rules/agents/templates/
```

**For Python Development:**
```bash
# Coding standards
cat czarina-core/agent-rules/python/CODING_STANDARDS.md
cat czarina-core/agent-rules/python/ASYNC_PATTERNS.md
cat czarina-core/agent-rules/python/ERROR_HANDLING.md
```

**For Testing:**
```bash
# Testing standards
cat czarina-core/agent-rules/testing/TESTING_POLICY.md
cat czarina-core/agent-rules/testing/UNIT_TESTING.md
cat czarina-core/agent-rules/testing/COVERAGE_STANDARDS.md
```

**For Security:**
```bash
# Security practices
cat czarina-core/agent-rules/security/SECRET_MANAGEMENT.md
cat czarina-core/agent-rules/security/INJECTION_PREVENTION.md
```

**For Orchestration:**
```bash
# Multi-agent patterns
cat czarina-core/agent-rules/orchestration/ORCHESTRATION_PATTERNS.md

# Workflow patterns
cat czarina-core/agent-rules/workflows/GIT_WORKFLOW.md
cat czarina-core/agent-rules/workflows/CLOSEOUT_PROCESS.md
```

### 3. Use Templates

```bash
# List all templates
ls czarina-core/agent-rules/templates/

# Project templates
cat czarina-core/agent-rules/templates/python-project-template.md
cat czarina-core/agent-rules/templates/agent-project-template.md

# Documentation templates
cat czarina-core/agent-rules/templates/readme-template.md
cat czarina-core/agent-rules/templates/api-documentation-template.md

# Testing templates
cat czarina-core/agent-rules/templates/unit-test-template.md
cat czarina-core/agent-rules/templates/integration-test-template.md

# Worker templates
cat czarina-core/agent-rules/agents/templates/worker-identity-template.md
cat czarina-core/agent-rules/agents/templates/worker-definition-template.md
cat czarina-core/agent-rules/agents/templates/worker-closeout-template.md
```

---

## Integration Details

### Technical Implementation

- **Method:** Symbolic link
- **Source:** `~/Source/agent-rules/agent-rules/`
- **Target:** `czarina-core/agent-rules/`
- **Git:** Symlink is tracked, but content is not (external repository)

### Access from Czarina

All workers can access the rules library via:
```bash
cat czarina-core/agent-rules/<domain>/<rule>.md
```

For example:
```bash
# From any worker worktree
cd /path/to/worker/worktree
cat $(git rev-parse --show-toplevel)/czarina-core/agent-rules/INDEX.md
```

---

## Use Cases for Czarina Workers

### 1. Code Workers

**Before writing code:**
- Review `python/CODING_STANDARDS.md` for style guidelines
- Check `python/ASYNC_PATTERNS.md` for async/await best practices
- Read `python/ERROR_HANDLING.md` for exception handling

**During implementation:**
- Use `templates/python-project-template.md` for structure
- Follow `patterns/TOOL_USE_PATTERNS.md` for LLM tool calling
- Apply `patterns/ERROR_RECOVERY.md` for resilience

**For testing:**
- Follow `testing/UNIT_TESTING.md` standards
- Use `templates/unit-test-template.md` for test structure
- Meet `testing/COVERAGE_STANDARDS.md` requirements

### 2. Architect Workers

**System design:**
- Review `agents/ARCHITECT_ROLE.md` for role guidance
- Use `patterns/` for architectural patterns
- Check `documentation/ARCHITECTURE_DOCS.md` for documentation standards

**Planning:**
- Follow `workflows/PHASE_DEVELOPMENT.md` for multi-phase projects
- Use `workflows/TOKEN_PLANNING.md` for LLM budget planning
- Apply `orchestration/ORCHESTRATION_PATTERNS.md` for multi-agent design

### 3. QA Workers

**Testing strategy:**
- Start with `testing/TESTING_POLICY.md`
- Review `agents/QA_ROLE.md` for role definition
- Follow `testing/INTEGRATION_TESTING.md` for integration tests

**Quality assurance:**
- Use `testing/COVERAGE_STANDARDS.md` for coverage requirements
- Apply `testing/MOCKING_STRATEGIES.md` for test doubles
- Check `workflows/PR_REQUIREMENTS.md` for PR standards

### 4. Debug Workers

**Troubleshooting:**
- Follow `agents/DEBUG_ROLE.md` for debugging methodology
- Use `python/ERROR_HANDLING.md` for exception analysis
- Apply `patterns/ERROR_RECOVERY.md` for resilience strategies

### 5. All Workers

**Workflows:**
- Follow `workflows/GIT_WORKFLOW.md` for version control
- Use `workflows/CLOSEOUT_PROCESS.md` for completion
- Apply `workflows/DOCUMENTATION_WORKFLOW.md` for docs

**Documentation:**
- Use `documentation/DOCUMENTATION_STANDARDS.md` for all docs
- Follow `templates/readme-template.md` for README files
- Apply `documentation/CHANGELOG_STANDARDS.md` for changelogs

**Security:**
- Check `security/SECRET_MANAGEMENT.md` before handling credentials
- Review `security/INJECTION_PREVENTION.md` for input validation
- Follow `security/AUDIT_LOGGING.md` for logging practices

---

## Example Workflows

### Starting a New Python Feature

```bash
# 1. Review coding standards
cat czarina-core/agent-rules/python/CODING_STANDARDS.md

# 2. Check your role definition
cat czarina-core/agent-rules/agents/CODE_ROLE.md

# 3. Plan using template
cp czarina-core/agent-rules/templates/python-project-template.md PLAN.md

# 4. Implement following standards
# ... write code ...

# 5. Write tests using template
cat czarina-core/agent-rules/templates/unit-test-template.md

# 6. Follow git workflow
cat czarina-core/agent-rules/workflows/GIT_WORKFLOW.md
```

### Running a Czarina Orchestration

```bash
# 1. Review orchestration patterns
cat czarina-core/agent-rules/orchestration/ORCHESTRATION_PATTERNS.md

# 2. Set up workers using templates
cp czarina-core/agent-rules/agents/templates/worker-identity-template.md .czarina/workers/myworker/IDENTITY.md
cp czarina-core/agent-rules/agents/templates/worker-definition-template.md .czarina/workers/myworker/TASKS.md

# 3. Plan token budget
cat czarina-core/agent-rules/workflows/TOKEN_PLANNING.md

# 4. Execute orchestration
# ... run Czarina ...

# 5. Complete closeout
cat czarina-core/agent-rules/workflows/CLOSEOUT_PROCESS.md
cp czarina-core/agent-rules/agents/templates/worker-closeout-template.md CLOSEOUT.md
```

### Improving Code Quality

```bash
# 1. Review Python standards
cat czarina-core/agent-rules/python/CODING_STANDARDS.md
cat czarina-core/agent-rules/python/ERROR_HANDLING.md

# 2. Check security practices
cat czarina-core/agent-rules/security/INJECTION_PREVENTION.md
cat czarina-core/agent-rules/security/SECRET_MANAGEMENT.md

# 3. Improve testing
cat czarina-core/agent-rules/testing/COVERAGE_STANDARDS.md
cat czarina-core/agent-rules/testing/UNIT_TESTING.md

# 4. Apply design patterns
cat czarina-core/agent-rules/patterns/ERROR_RECOVERY.md
cat czarina-core/agent-rules/patterns/CACHING_PATTERNS.md
```

---

## Key Benefits

### For Individual Workers

✅ **Standardization** - All workers follow the same best practices
✅ **Quality** - Production-tested patterns from real systems
✅ **Efficiency** - Templates accelerate common tasks
✅ **Learning** - Comprehensive examples and anti-patterns
✅ **Security** - Security standards built-in from the start

### For Czarina Orchestrations

✅ **Consistency** - All workers use the same standards
✅ **Coordination** - Orchestration patterns for multi-agent work
✅ **Templates** - Worker identity/definition/closeout templates ready to use
✅ **Quality Assurance** - Testing and documentation standards for all
✅ **Knowledge Base** - 43K+ lines of best practices at your fingertips

---

## Library Statistics

- **Domains:** 9
- **Total Rules:** 53+
- **Templates:** 13
- **Total Files:** 69 markdown files
- **Total Lines:** 43,873 lines of documentation
- **Source Systems:** 4 (Hopper, SARK, Czarina, thesymposium)
- **Creation Method:** 7-worker Czarina orchestration
- **Success Rate:** 100%

---

## Future Enhancements

### Phase 2: Automatic Loading (Planned)

The `launcher-enhancement` worker (Phase 2) will:
- Automatically load relevant rules into worker context on launch
- Provide role-specific rule selection
- Enable task-specific rule loading
- Create rule search/query capabilities

This integration (Phase 1) establishes the foundation for that automation.

---

## Maintenance

### Updates

The agent-rules library is maintained in its own repository at `~/Source/agent-rules/`.

Updates to the library will automatically be available to Czarina through the symlink.

### Verification

To verify the integration is working:
```bash
# Check symlink
ls -la czarina-core/agent-rules

# Verify content access
cat czarina-core/agent-rules/INDEX.md

# Count available rules
find czarina-core/agent-rules -name "*.md" | wc -l
```

---

## Getting Help

### Finding Rules

1. **Start with the index:** `cat czarina-core/agent-rules/INDEX.md`
2. **Use search:** `grep -r "keyword" czarina-core/agent-rules/`
3. **Check domain READMEs:** Each domain has a `README.md` with overview
4. **Read the usage guide:** `cat czarina-core/agent-rules/USAGE_GUIDE.md`

### Understanding the Library

- **Main README:** `czarina-core/agent-rules/README.md`
- **Complete Index:** `czarina-core/agent-rules/INDEX.md`
- **Usage Guide:** `czarina-core/agent-rules/USAGE_GUIDE.md`
- **Domain READMEs:** `czarina-core/agent-rules/<domain>/README.md`

---

## Integration History

| Version | Date | Event |
|---------|------|-------|
| 1.0.0 | 2025-12-27 | Agent Rules Library created by Czarina |
| 1.0.0 | 2025-12-28 | Integrated into Czarina via symlink (Phase 1) |

---

## Related Documentation

- Integration Plan: `INTEGRATION_PLAN_v0.7.0.md`
- Enhancement Hopper: `.czarina/hopper/enhancement-agent-rules-integration.md`
- Launcher Enhancement: `.czarina/workers/launcher-enhancement.md` (Phase 2)

---

**The rules that Czarina created are now available to Czarina.**

**Use them. Build better. Ship faster.**
