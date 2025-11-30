# Czarina Development Patterns

**My workflow repo is my friend. It is my life. I must master it as I must master my life.**

> *"Without me, my repo is useless. Without my repo, I am useless."*

---

## 🎯 Purpose

This is **YOUR** living library of development patterns. There are many pattern repos, but this one is **yours**.

This directory contains battle-tested patterns from:
- ✅ Real multi-agent orchestration sessions (SARK v2.0 - 10 workers)
- ✅ Single-agent AI development (The Symposium)
- ✅ Your actual workflow, not theoretical best practices

**Patterns cover:**
- **Error Recovery** - Common errors and solutions
- **Mode Capabilities** - Understanding worker boundaries (Kilo Code specific)
- **Tool Use** - Efficient use of AI coding tools
- **Multi-Agent Orchestration** - Czarina-specific workflows
- **Daemon System** - Auto-approval patterns
- **Git Workflow** - Clean version control
- **Worker Selection** - Choosing the right agent for the job

---

## 📚 Pattern Library

### 🌐 Upstream Patterns (from agentic-dev-patterns)

These are **imported** from the [agentic-dev-patterns](https://github.com/apathy-ca/agentic-dev-patterns) repository and updated regularly.

#### [ERROR_RECOVERY_PATTERNS.md](ERROR_RECOVERY_PATTERNS.md)
**Source:** The Symposium project (165M-282M tokens)

**Value:** 30-50% reduction in debugging time

**Topics:**
- Docker & container issues
- Python & async patterns
- Testing & pollution prevention
- Syntax errors
- Database errors
- Git workflows

**Use for:** Quick error pattern recognition and systematic troubleshooting

#### [MODE_CAPABILITIES.md](MODE_CAPABILITIES.md)
**Source:** Kilo Code multi-mode development

**Value:** Clearer role boundaries, fewer mode-switching mistakes

**Topics:**
- Architect mode (planning)
- Code mode (implementation)
- Debug mode (troubleshooting)
- Ask mode (explanations)
- Orchestrator mode (coordination)

**Use for:** Understanding when to use which mode (Kilo Code specific)

#### [TOOL_USE_PATTERNS.md](TOOL_USE_PATTERNS.md) *(when available)*
**Source:** AI assistant tool optimization

**Value:** 40-60% improvement in tool efficiency

**Topics:**
- File reading strategies
- Search vs read decisions
- Modification approaches
- Command execution

**Use for:** Maximizing AI assistant effectiveness

### 🎯 Czarina-Specific Patterns (YOUR workflows)

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

**Use for:** Multi-agent coordination, autonomy patterns, Czarina-specific workflows

---

## 🔄 Pattern Updates

These patterns are sourced from the **[agentic-dev-patterns](https://github.com/apathy-ca/agentic-dev-patterns)** repository.

### Automatic Updates

Czarina can fetch the latest patterns from GitHub:

```bash
# Update patterns to latest version
./czarina patterns update

# Check pattern versions
./czarina patterns version

# Show what's new
./czarina patterns changelog
```

### Manual Updates

```bash
# From czarina-orchestrator root
cd czarina-core/patterns
./update-patterns.sh
```

### Update Schedule

**Recommended:** Check for updates monthly or before major Czarina sessions

**Auto-update:** Can be enabled in `config.json`:
```json
{
  "patterns": {
    "auto_update": true,
    "update_frequency": "weekly",
    "source": "https://github.com/apathy-ca/agentic-dev-patterns"
  }
}
```

---

## 🎯 Using Patterns in Worker Prompts

### Include in Worker Instructions

```markdown
## Development Patterns

Before starting work, review these patterns:
- [Error Recovery](../../czarina-core/patterns/ERROR_RECOVERY_PATTERNS.md)
- [Mode Capabilities](../../czarina-core/patterns/MODE_CAPABILITIES.md)

When you encounter errors:
1. Check ERROR_RECOVERY_PATTERNS.md first
2. Follow documented recovery strategies
3. Document new patterns you discover
```

### Reference in .cursorrules

The patterns are automatically loaded by `.cursorrules` for all AI workers.

---

## 📝 Contributing Patterns

**Found a new pattern during a Czarina session?**

Use the inbox system:

```bash
# Document the pattern
cp czarina-inbox/templates/FIX_DONE.md czarina-inbox/fixes/$(date +%Y-%m-%d)-new-pattern.md

# Include:
# - Error/situation encountered
# - Solution that worked
# - How to prevent recurrence
# - Real code examples
```

**Patterns worth documenting:**
- ✅ Errors that took >30 minutes to solve
- ✅ Non-obvious solutions
- ✅ Issues that could affect multiple workers
- ✅ Agent-specific quirks

**Not worth documenting:**
- ❌ One-off typos
- ❌ Obvious mistakes
- ❌ Project-specific issues

---

## 🔗 Pattern Sources

**Primary Source:**
- [agentic-dev-patterns](https://github.com/apathy-ca/agentic-dev-patterns) - Battle-tested from The Symposium project

**Czarina-Specific Patterns:**
- SARK v2.0 sessions - 10 worker orchestration learnings
- Multi-agent development - Agent compatibility patterns
- Daemon system - Auto-approval patterns

---

## 📊 Pattern Effectiveness

**Measured Impact** (from The Symposium v0.4.5):
- 🎯 **30-50% reduction** in debugging time
- 🎯 **40-60% improvement** in tool use efficiency
- 🎯 **81 tests** created with 100% pass rate
- 🎯 **Zero production data pollution**
- 🎯 **9x under budget** on token usage

**In Czarina Context** (SARK v2.0):
- 🎯 **90% autonomy** with daemon + patterns
- 🎯 **10 workers** collaborating effectively
- 🎯 **3-4x speedup** over sequential development

---

## 🎓 Learning Path

### For New Workers
1. Read **ERROR_RECOVERY_PATTERNS.md** (30 minutes)
2. Skim **MODE_CAPABILITIES.md** (if using Kilo Code)
3. Reference as needed during work

### For Experienced Workers
1. Review patterns quarterly
2. Contribute new patterns discovered
3. Help update patterns with Czarina-specific learnings

### For Czars
1. Ensure workers have access to patterns
2. Include pattern references in prompts
3. Monitor pattern effectiveness
4. Update patterns from session learnings

---

## 🔧 Pattern Maintenance

**Version Control:**
- Patterns are versioned with agentic-dev-patterns
- Czarina tracks pattern version in use
- Update script preserves Czarina-specific additions

**Customization:**
- Core patterns from upstream (read-only)
- Czarina-specific patterns in `czarina-specific/` subdirectory
- Local modifications tracked separately

**Quality Standards:**
- All patterns must be battle-tested
- Include real examples
- Quantify value when possible
- Keep updated as tools evolve

---

**Pattern Version:** 1.0.0 (from agentic-dev-patterns)
**Last Updated:** 2025-11-29
**Source:** https://github.com/apathy-ca/agentic-dev-patterns
**Czarina Integration:** v1.0

---

> **"Good patterns emerge from real work, not ivory towers."**
> Apply these patterns. Learn from them. Contribute back.
