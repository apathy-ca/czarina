# 🎭 Czarina

**Autonomous Multi-Agent Orchestration for Claude Code**

*"Taking the fallible human out of the loop"*

---

Czarina is an autonomous orchestration system that manages multiple AI coding agents working in parallel on complex software projects. Deploy 2-20+ workers (Claude Code, Aider, Cursor, GPT, or even humans!), walk away, and return to completed work.

## 🌟 What is Czarina?

Czarina orchestrates teams of AI coding agents like a symphony conductor. Each worker gets their own branch, tasks, and environment. The autonomous Czar monitors progress, assigns work, detects issues, and coordinates merges—all without human intervention.

**Agent-agnostic**: Works with Claude Code, Aider, Cursor, API-based agents, or humans
**Flexible scaling**: 3 workers for simple features, 6 for full-stack work, 12+ for microservices
**Real-world results**: 6 Claude Code workers implementing SARK v1.1 Gateway Integration in parallel with 90% autonomy

## ✨ Features

### v2.0 (Current)
- ✅ **Autonomous Czar** - Continuous monitoring and decision-making
- ✅ **Worker Coordination** - Shared status prevents duplication
- ✅ **Health Monitoring** - Auto-detect stuck/idle workers
- ✅ **Task Injection** - Reliable task delivery to workers
- ✅ **Live Dashboard** - Real-time progress visualization
- ✅ **Git Orchestration** - Branch management and PR coordination
- ✅ **Multiple Deployment** - HTML auto-launch, CLI, or tmux

### Coming in v2.1
- 🔄 Auto PR creation and review
- 🔄 Dependency tracking with notifications
- 🔄 Conflict detection before merge
- 🔄 Work queue with priorities

## 🚀 Quick Start

### Prerequisites
- Linux/WSL environment
- tmux installed
- Git configured
- GitHub CLI (`gh`) authenticated
- Claude Code API access

### 30-Second Setup

```bash
# Clone Czarina
git clone https://github.com/YOUR-ORG/czarina
cd czarina

# Configure your project
cp config.example.sh config.sh
nano config.sh  # Set PROJECT_ROOT, worker definitions

# Launch workers and autonomous Czar
./QUICKSTART.sh
# Choose option 2: Launch All Workers
# Choose option 3: Start Autonomous Czar

# Walk away! ☕
```

## 📊 How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                      AUTONOMOUS CZAR                        │
│  Monitors • Decides • Assigns • Coordinates • Reviews       │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   ┌────▼────┐        ┌────▼────┐        ┌────▼────┐
   │ Worker 1│        │ Worker 2│   ...  │ Worker 6│
   │ Engineer│        │ Engineer│        │   Docs  │
   └────┬────┘        └────┬────┘        └────┬────┘
        │                  │                   │
        │                  │                   │
   ┌────▼─────────────────▼───────────────────▼────┐
   │           Your Git Repository                 │
   │    feat/branch-1  feat/branch-2  ...          │
   └───────────────────────────────────────────────┘
```

**Worker Lifecycle**:
1. Launch → Worker gets task in tmux session
2. Work → Commits to feature branch
3. Idle → Czar detects, assigns bonus tasks
4. Stuck → Czar prompts for status
5. Done → Create PR, await review
6. Merge → Omnibus integration branch

## 🎯 Use Cases

### Perfect For:
- **Large features** requiring parallel work (APIs, UIs, docs, tests)
- **V1 to V2 migrations** with multiple concerns
- **Microservices** development (each worker = one service)
- **Full-stack features** (frontend, backend, tests, docs in parallel)
- **Team coordination** (Czar = tech lead, workers = engineers)

### Examples:
- ✅ Gateway Integration (6 workers: models, API, policies, audit, tests, docs)
- ✅ Authentication System (auth service, UI, policies, tests, docs)
- ✅ Data Pipeline (ingestion, transformation, storage, monitoring, docs)

## 📖 Documentation

- **[Quick Start Guide](GETTING_STARTED.md)** - Get up and running
- **[Agent Types](AGENT_TYPES.md)** - Claude, Aider, Cursor, API, or humans? Mix and match!
- **[Worker Patterns](WORKER_PATTERNS.md)** - 3, 6, or 12+ workers? Choose your pattern
- **[Configuration Guide](docs/CONFIG.md)** - Detailed setup
- **[Czar Guide](CZAR_GUIDE.md)** - How the autonomous Czar works
- **[Dashboard Guide](docs/DASHBOARD.md)** - Monitoring and visualization
- **[Phase Completion Detection](docs/PHASE_COMPLETION_DETECTION.md)** - Multi-phase automation
- **[Distributed Workers](DISTRIBUTED_WORKERS.md)** - SSH to remote build servers (v2.1+)
- **[Lessons Learned](LESSONS_LEARNED.md)** - Real-world insights
- **[Improvement Plan](IMPROVEMENT_PLAN.md)** - Roadmap and future features

## 🛠 Architecture

### Core Components

```
czarina/
├── czar-autonomous.sh              # Autonomous monitoring loop
├── inject-task.sh                  # Task delivery system
├── update-worker-status.sh         # Status tracking
├── phase-completion-detector.sh    # Phase completion detection
├── detect-*.sh                     # Health detection
├── dashboard.py                    # Live visualization
├── pr-manager.sh                   # PR orchestration
├── orchestrator.sh                 # Interactive control
└── config.sh                       # Project configuration
```

### Data Flow

```
Worker commits → Git → Status JSON → Czar → Decisions → Worker actions
                                  ↓
                              Dashboard (real-time)
```

## 📈 Success Metrics

**From SARK v1.1 Gateway Integration (6 workers)**:

| Metric | Before Czarina | With Czarina (6 workers) |
|--------|----------------|--------------------------|
| Workers deployed | 1 | 2-20+ (your choice) |
| Task accuracy | N/A | 95%+ |
| Human supervision | 100% | <10% |
| Stuck detection | Never | <2 hours |
| Work duplication | Common | <5% |
| Time to completion | Linear | Parallel (6x faster) |
| Scalability | N/A | 3→6→12+ workers |

**ROI**: Positive after 2-3 projects
**Tested patterns**: 3, 6, and 12 workers
**Recommended**: Start with 6, scale as needed

## 🎬 Video Demo

(Coming soon - watch Czarina orchestrate 6 workers in real-time)

## 🤝 Contributing

We welcome contributions! Czarina was born from real-world multi-agent orchestration needs.

### Priority Areas:
- Auto PR review (AI-powered code quality)
- Work queue system (task prioritization)
- Web dashboard (browser-based monitoring)
- Multi-project support (switch contexts easily)

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📜 License

MIT License - see [LICENSE](LICENSE)

## 🙏 Credits

**Created by**: The SARK team during v1.1 Gateway Integration
**Inspired by**: The vision of autonomous multi-agent collaboration
**Tested on**: Real production features, not toy examples

## 🌟 Star History

If Czarina helped you ship faster, give us a star! ⭐

## 💬 Community

- **Issues**: Bug reports and feature requests
- **Discussions**: Share your orchestration stories
- **Discord**: (Coming soon) Real-time help and tips

## 🔗 Related Projects

- [Claude Code](https://claude.ai/code) - The AI pair programmer
- [Aider](https://aider.chat) - AI pair programming in the terminal
- [Open Interpreter](https://openinterpreter.com) - LLMs as computer operators

## 🎭 The Name

**Czarina** (царица) - feminine form of Czar/Tsar, a ruler with absolute authority.

In Czarina, the autonomous Czar makes all orchestration decisions. You're just along for the ride. 😎

---

## Quick Links

- 📚 [Full Documentation](docs/)
- 🐛 [Report Bug](issues/new?template=bug_report.md)
- 💡 [Request Feature](issues/new?template=feature_request.md)
- 💬 [Join Discussion](discussions)

---

**Status**: ✅ Production-ready (v2.0)
**Workers**: Any number (2-20+, 6 recommended)
**Autonomy Level**: 90%
**The +1**: You're worker #N+1 (the Czar) 🎭

*Built with ❤️ by humans and AI working together*
