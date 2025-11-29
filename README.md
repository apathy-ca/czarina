# Multi-Agent Orchestration Projects

This repository contains multiple projects related to autonomous multi-agent orchestration for AI-powered software development.

## 📁 Repository Structure

```
.
├── czarina-core/              # Czarina orchestration framework (reusable)
├── projects/                  # Specific projects using Czarina
│   └── sark-v2-orchestration/ # SARK v2.0 development project
├── archive/                   # Legacy/completed files
└── README.md                  # This file
```

## 🎭 Czarina Core

**Location:** `czarina-core/`

Czarina is a **reusable framework** for orchestrating multiple AI coding agents (Claude Code, Aider, Cursor, etc.) working in parallel on complex software projects.

### Key Features
- Autonomous Czar monitoring and coordination
- Worker health detection (stuck/idle)
- Task injection and assignment
- Live dashboard for progress visualization
- Git orchestration and PR management
- Support for 2-20+ parallel workers

### Getting Started with Czarina

```bash
cd czarina-core/
cat README.md                    # Full framework documentation
cat docs/GETTING_STARTED.md     # Quick start guide
cat docs/CZAR_GUIDE.md          # How the autonomous Czar works
```

### Quick Launch

```bash
cd czarina-core/

# 1. Configure your project
cp config.example.sh config.sh
nano config.sh  # Set PROJECT_ROOT, worker definitions

# 2. Launch workers
./QUICKSTART.sh
```

See `czarina-core/docs/` for comprehensive documentation.

---

## 🚀 Projects

Active projects using the Czarina orchestration framework.

### SARK v2.0 Orchestration

**Location:** `projects/sark-v2-orchestration/`

An orchestrated development project implementing SARK v2.0 with 10 parallel engineers over 6-8 weeks.

#### Project Overview
- **Team Size:** 10 engineers (6 core, 2 QA, 2 docs)
- **Timeline:** 6-8 weeks (vs. 22-26 weeks sequential)
- **Speedup:** 3-4x faster delivery
- **Autonomy:** 90% autonomous with Czarina orchestration

#### Quick Start

```bash
cd projects/sark-v2-orchestration/

# 1. Initialize the project
./init_sark_v2.py

# 2. Start Week 1
./orchestrate_sark_v2.py start-week 1

# 3. Launch individual engineers
./orchestrate_sark_v2.py start engineer-1

# 4. Monitor progress
./orchestrate_sark_v2.py daily-report
```

See `projects/sark-v2-orchestration/README.md` for full documentation.

---

## 🗄️ Archive

**Location:** `archive/`

Contains legacy files, deprecated scripts, and completed project artifacts. These files are kept for historical reference but are not actively maintained.

---

## 🛠️ Creating a New Project

To create a new orchestrated project:

1. **Copy the Czarina framework configuration:**
   ```bash
   mkdir projects/my-new-project
   cp czarina-core/config.example.sh projects/my-new-project/config.sh
   ```

2. **Configure your project:**
   - Edit `config.sh` with your project details
   - Define workers and their roles
   - Set up your Git repository path

3. **Create worker prompts:**
   ```bash
   mkdir projects/my-new-project/prompts
   # Create prompt files for each worker
   ```

4. **Launch orchestration:**
   ```bash
   cd projects/my-new-project
   ../../czarina-core/QUICKSTART.sh
   ```

See `czarina-core/docs/WORKER_PATTERNS.md` for recommended team structures.

---

## 📖 Documentation

- **Czarina Framework:** `czarina-core/docs/`
  - [Getting Started](czarina-core/docs/GETTING_STARTED.md)
  - [Czar Guide](czarina-core/docs/CZAR_GUIDE.md)
  - [Agent Types](czarina-core/docs/AGENT_TYPES.md)
  - [Worker Patterns](czarina-core/docs/WORKER_PATTERNS.md)
  - [Distributed Workers](czarina-core/docs/DISTRIBUTED_WORKERS.md)
  - [Lessons Learned](czarina-core/docs/LESSONS_LEARNED.md)

- **SARK v2.0 Project:** `projects/sark-v2-orchestration/README.md`

---

## 📜 License

MIT License - see [LICENSE](LICENSE)

---

## 🤝 Contributing

Contributions are welcome! Areas of interest:

- **Framework improvements:** Auto PR review, work queues, web dashboard
- **New project templates:** Share your orchestration patterns
- **Documentation:** Help others succeed with multi-agent orchestration

---

## 🌟 Quick Links

| Resource | Location |
|----------|----------|
| Czarina Framework | `czarina-core/` |
| SARK v2.0 Project | `projects/sark-v2-orchestration/` |
| Legacy Files | `archive/` |
| Framework Docs | `czarina-core/docs/` |
| Getting Started | `czarina-core/docs/GETTING_STARTED.md` |

---

**Status:** Production-ready framework with active projects

*Built with ❤️ by humans and AI working together*
