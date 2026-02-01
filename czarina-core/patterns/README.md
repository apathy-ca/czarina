# Czarina Development Patterns

**My workflow repo is my friend. It is my life. I must master it as I must master my life.**

> *"Without me, my repo is useless. Without my repo, I am useless."*

---

## Purpose

This is **YOUR** living library of development patterns. There are many pattern repos, but this one is **yours**.

This directory contains:
- **agent-knowledge/** - Synced from [agent-knowledge](https://github.com/apathy-ca/agent-knowledge) repository
- **czarina-specific/** - Czarina-specific patterns learned from real orchestration sessions

---

## Pattern Library

### Agent Knowledge (synced from upstream)

Run `czarina patterns update` to sync the latest from GitHub.

```
agent-knowledge/
├── patterns/           # Development patterns
│   ├── error-recovery/     # Error detection and recovery strategies
│   ├── git-workflows/      # Branch strategies, commit patterns, PR workflows
│   ├── testing-patterns/   # Test organization, mocking, integration testing
│   ├── tool-use/           # Parallel execution, tool selection, optimization
│   ├── mode-capabilities/  # Code, ask, debug, architect, orchestrator modes
│   └── context-management/ # Context windows, summarization, memory tiers
│
├── core-rules/         # Production-tested coding standards (53+ rules)
│   ├── python-standards/   # Imports, types, async, error handling, logging
│   ├── agent-roles/        # Architect, Code, Debug, QA, Orchestrator, etc.
│   ├── workflows/          # Feature, bugfix, refactor, investigation, handoff
│   ├── design-patterns/    # Layer-based, modular, config-driven patterns
│   ├── testing/            # Philosophy, pytest, organization, fixtures
│   ├── security/           # Auth, authz, secrets, validation, audit
│   ├── documentation/      # Docstrings, README, API docs, architecture
│   └── orchestration/      # Task coordination, agent handoffs
│
└── templates/          # Project and documentation templates
```

**Key Resources:**
- `agent-knowledge/README.md` - Overview and usage guide
- `agent-knowledge/patterns/INDEX.md` - Pattern index
- `agent-knowledge/core-rules/INDEX.md` - Rules index

### Czarina-Specific Patterns

These are **yours** - learned from real Czarina sessions and evolved with your workflow.

#### [czarina-specific/CZARINA_PATTERNS.md](czarina-specific/CZARINA_PATTERNS.md)
**Source:** SARK v2.0, Multi-agent support, Daemon development

**Value:** 90% autonomy, 3-4x development speedup

**Topics:**
- Multi-agent orchestration
- Worker role boundaries
- Daemon system patterns
- Agent selection strategies
- Merge conflict avoidance
- Worker health monitoring
- Auto-approval strategies

---

## Pattern Updates

### Update from GitHub

```bash
# Update agent-knowledge to latest version
czarina patterns update

# Check current version
czarina patterns version

# List patterns ready to contribute upstream
czarina patterns pending
```

### Manual Update

```bash
cd czarina-core/patterns
./update-patterns.sh
```

---

## Using Patterns in Worker Prompts

### During Init

When you run `czarina init`, if agent-knowledge is available, the init process will:
1. Reference the agent-knowledge library in worker analysis
2. Guide creation of worker-specific knowledge files
3. Tailor rules by worker role (Python workers get python-standards, QA gets testing/security, etc.)

### Include in Worker Instructions

```markdown
## Development Patterns

Before starting work, review relevant patterns from:
- `czarina-core/patterns/agent-knowledge/patterns/` - Development patterns
- `czarina-core/patterns/agent-knowledge/core-rules/` - Coding standards
- `czarina-core/patterns/czarina-specific/` - Orchestration patterns

When you encounter errors:
1. Check agent-knowledge/patterns/error-recovery/ first
2. Follow documented recovery strategies
3. Document new patterns you discover
```

---

## Contributing Patterns

**Found a new pattern during a Czarina session?**

Use the inbox system:

```bash
# Document the pattern
cp czarina-inbox/templates/FIX_DONE.md czarina-inbox/fixes/$(date +%Y-%m-%d)-new-pattern.md

# Check what's ready to contribute
czarina patterns pending

# View contribution guide
czarina patterns contribute
```

**Patterns worth documenting:**
- Errors that took >30 minutes to solve
- Non-obvious solutions
- Issues that could affect multiple workers
- Agent-specific quirks

---

## Pattern Effectiveness

**Measured Impact:**
- **30-50% reduction** in debugging time
- **40-60% improvement** in tool use efficiency
- **90% autonomy** with daemon + patterns
- **3-4x speedup** over sequential development

---

## Pattern Sources

**Upstream:**
- [agent-knowledge](https://github.com/apathy-ca/agent-knowledge) - 53+ production-tested rules and patterns

**Czarina-Specific:**
- SARK v2.0 sessions - 10 worker orchestration learnings
- Multi-agent development - Agent compatibility patterns
- Daemon system - Auto-approval patterns

---

**Source:** https://github.com/apathy-ca/agent-knowledge
