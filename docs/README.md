# Czarina Documentation

Central documentation hub for the Czarina multi-agent orchestration system.

---

## 📚 Documentation Structure

```
docs/
├── guides/           # User guides and tutorials
├── architecture/     # Architecture decisions and diagrams
├── integration/      # Integration and migration documentation
└── analysis/         # Analysis reports and summaries
```

---

## 🎯 Quick Navigation

### New to Czarina?
1. **[Getting Started](../czarina-core/docs/GETTING_STARTED.md)** - Start here!
2. **[Czarina Overview](guides/CZARINA_README.md)** - Understand the framework
3. **[Supported Agents](guides/SUPPORTED_AGENTS.md)** - Choose your AI agents

### Setting Up Projects
1. **[Worker Setup Guide](guides/WORKER_SETUP_GUIDE.md)** - Configure workers
2. **[Workers Overview](guides/WORKERS.md)** - Worker patterns
3. **[Embedded Orchestration Guide](guides/EMBEDDED_ORCHESTRATION_GUIDE.md)** - Embedded mode

### Advanced Topics
1. **[Daemon System](../czarina-core/docs/DAEMON_SYSTEM.md)** - Autonomous approval system
2. **[Daemon Limitations](../czarina-core/docs/DAEMON_LIMITATIONS.md)** - Known issues
3. **[Agent Types](../czarina-core/docs/AGENT_TYPES.md)** - Agent compatibility

---

## 📂 Guides

User-focused documentation and tutorials:

| Document | Description |
|----------|-------------|
| [CZARINA_README.md](guides/CZARINA_README.md) | Comprehensive framework overview |
| [SUPPORTED_AGENTS.md](guides/SUPPORTED_AGENTS.md) | All supported AI agents (Claude Code, Aider, etc.) |
| [WORKER_SETUP_GUIDE.md](guides/WORKER_SETUP_GUIDE.md) | How to configure and launch workers |
| [WORKERS.md](guides/WORKERS.md) | Worker patterns and best practices |
| [EMBEDDED_ORCHESTRATION_GUIDE.md](guides/EMBEDDED_ORCHESTRATION_GUIDE.md) | Embedded orchestration mode |
| [EMBEDDED_SUMMARY.md](guides/EMBEDDED_SUMMARY.md) | Embedded mode quick reference |

---

## 🏗️ Architecture

Design decisions and system architecture:

| Document | Description |
|----------|-------------|
| *(Coming soon)* | Architecture diagrams and decisions |

**Note:** Core architecture docs are in `czarina-core/docs/`

---

## 🔗 Integration

Integration guides and migration documentation:

| Document | Description |
|----------|-------------|
| [INTEGRATION_PLAN.md](integration/INTEGRATION_PLAN.md) | Integration planning and strategy |

---

## 📊 Analysis

Analysis reports, summaries, and status documents:

| Document | Description |
|----------|-------------|
| [CZAR_INTEGRATION_ANALYSIS.md](analysis/CZAR_INTEGRATION_ANALYSIS.md) | Czar integration analysis |
| [DAEMON_INTEGRATION_COMPLETE.md](analysis/DAEMON_INTEGRATION_COMPLETE.md) | Daemon integration summary |
| [IMPROVEMENTS_SUMMARY.md](analysis/IMPROVEMENTS_SUMMARY.md) | General improvements summary |
| [REORGANIZATION_SUMMARY.md](analysis/REORGANIZATION_SUMMARY.md) | Repository reorganization notes |
| [SARK_DAEMON_IMPROVEMENTS.md](analysis/SARK_DAEMON_IMPROVEMENTS.md) | SARK daemon improvements analysis |
| [SARK_IMPROVEMENTS_SUMMARY.md](analysis/SARK_IMPROVEMENTS_SUMMARY.md) | SARK improvements quick reference |
| [WORKER_STATUS_CHECK.md](analysis/WORKER_STATUS_CHECK.md) | Worker status analysis |

---

## 🎓 Learning Path

### Beginner
1. Read [Getting Started](../czarina-core/docs/GETTING_STARTED.md)
2. Review [Czarina Overview](guides/CZARINA_README.md)
3. Follow [Worker Setup Guide](guides/WORKER_SETUP_GUIDE.md)
4. Launch your first project!

### Intermediate
1. Study [Worker Patterns](guides/WORKERS.md)
2. Explore [Supported Agents](guides/SUPPORTED_AGENTS.md)
3. Try [Embedded Orchestration](guides/EMBEDDED_ORCHESTRATION_GUIDE.md)
4. Review [Integration Planning](integration/INTEGRATION_PLAN.md)

### Advanced
1. Master [Daemon System](../czarina-core/docs/DAEMON_SYSTEM.md)
2. Understand [Daemon Limitations](../czarina-core/docs/DAEMON_LIMITATIONS.md)
3. Read [SARK Improvements](analysis/SARK_DAEMON_IMPROVEMENTS.md)
4. Study [Agent Types](../czarina-core/docs/AGENT_TYPES.md)

---

## 📝 Contributing Documentation

**Found something missing or incorrect?**

Use the inbox system:
```bash
# For documentation feedback
cp czarina-inbox/templates/FEEDBACK.md czarina-inbox/feedback/$(date +%Y-%m-%d)-doc-feedback.md

# For documentation bugs
cp czarina-inbox/templates/BUG_REPORT.md czarina-inbox/bugs/$(date +%Y-%m-%d)-doc-bug.md
```

See [czarina-inbox/README.md](../czarina-inbox/README.md) for details.

---

## 🔍 Finding Documentation

**Can't find what you're looking for?**

```bash
# Search all documentation
grep -r "search term" ~/Source/GRID/claude-orchestrator/docs/
grep -r "search term" ~/Source/GRID/claude-orchestrator/czarina-core/docs/

# List all markdown files
find ~/Source/GRID/claude-orchestrator -name "*.md" | grep -E "(docs|guides)"
```

---

## 📋 Documentation Standards

All documentation in this repository follows the rules defined in [`.cursorrules`](../.cursorrules).

**Key principles:**
- Clear purpose and audience
- Mermaid diagrams for complex concepts
- Working examples and code snippets
- Links to related documentation
- Regular updates as code changes

---

**Last Updated:** 2025-11-29
**Maintained By:** Czarina contributors and AI Czars
**Status:** Active and growing
