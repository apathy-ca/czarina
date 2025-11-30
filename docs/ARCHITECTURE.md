# Czarina Architecture

Complete visual guide to Czarina's architecture, workflows, and system design.

---

## 🏗️ System Architecture

```mermaid
graph TB
    subgraph "Czarina Orchestration"
        Czar[🎭 Czar<br/>Autonomous Monitor]
        Daemon[⚡ Daemon<br/>Auto-Approver]

        W1[👷 Worker 1<br/>Claude Code]
        W2[👷 Worker 2<br/>Aider]
        W3[👷 Worker 3<br/>Cursor]
        Wn[👷 Worker N<br/>Any Agent]

        Czar -->|monitors| W1
        Czar -->|monitors| W2
        Czar -->|monitors| W3
        Czar -->|monitors| Wn

        Daemon -->|auto-approves| W1
        Daemon -->|auto-approves| W2
        Daemon -->|auto-approves| W3
        Daemon -->|auto-approves| Wn

        W1 -->|PRs| Git[📦 Git Repository]
        W2 -->|PRs| Git
        W3 -->|PRs| Git
        Wn -->|PRs| Git
    end

    Human[👤 Human] -.->|occasional<br/>intervention| Czar
    Human -.->|reviews PRs| Git

    style Czar fill:#e1f5ff
    style Daemon fill:#fff3e0
    style Git fill:#e8f5e9
```

**Components:**
- **Czar** - Autonomous coordinator monitoring all workers
- **Daemon** - Auto-approval system (90% autonomy)
- **Workers** - AI coding agents (any tool)
- **Git** - Version control and integration point
- **Human** - Sets goals, reviews results

---

## 🔄 Workflow Sequence

```mermaid
sequenceDiagram
    participant H as 👤 Human
    participant C as 🎭 Czar
    participant D as ⚡ Daemon
    participant W1 as 👷 Worker 1
    participant W2 as 👷 Worker 2
    participant G as 📦 Git

    H->>C: Launch orchestration
    C->>W1: Start with task
    C->>W2: Start with task

    W1->>W1: Working...
    W2->>W2: Working...

    D->>W1: Auto-approve file edits
    D->>W2: Auto-approve file edits

    W1->>G: Create PR
    W2->>G: Create PR

    C->>C: Monitor progress
    C->>H: Alert if stuck

    H->>G: Review & merge PRs
```

**Flow:**
1. Human launches orchestration
2. Czar starts workers with tasks
3. Workers code independently
4. Daemon auto-approves operations
5. Workers create PRs
6. Czar monitors and alerts
7. Human reviews and merges

---

## 📁 Repository Structure

```mermaid
graph LR
    Root[📁 czarina-orchestrator]

    Root --> Core[📁 czarina-core<br/>Framework & CLI]
    Root --> Inbox[📁 czarina-inbox<br/>Improvements & Feedback]
    Root --> Agents[📁 agents<br/>Agent Profiles]
    Root --> Projects[📁 projects<br/>Active Projects]
    Root --> Docs[📁 docs<br/>Documentation]
    Root --> Archive[📁 archive<br/>Legacy Files]

    Core --> CoreDocs[📁 docs<br/>Framework Docs]
    Core --> Daemon[📁 daemon<br/>Auto-Approval]
    Core --> Templates[📁 templates<br/>Project Templates]

    Inbox --> Fixes[💾 fixes]
    Inbox --> Feedback[💬 feedback]
    Inbox --> Sessions[📝 sessions]

    Projects --> SARK[📁 sark-v2<br/>10 Worker Project]
    Projects --> MultiAgent[📁 multi-agent-support<br/>Agent Refactor]

    Docs --> Guides[📁 guides]
    Docs --> Analysis[📁 analysis]

    style Root fill:#e1f5ff
    style Core fill:#fff3e0
    style Inbox fill:#e8f5e9
```

---

## 🤖 Agent Compatibility

```mermaid
graph TB
    subgraph "Agent Compatibility"
        CC[Claude Code<br/>⭐⭐⭐⭐⭐<br/>Daemon: 70-80%]
        Aider[Aider<br/>⭐⭐⭐⭐⭐<br/>Daemon: 95-98%]
        Cursor[Cursor<br/>⭐⭐⭐⭐⭐<br/>Daemon: 80-90%]
        Wind[Windsurf<br/>⭐⭐⭐⭐⭐<br/>Daemon: 85-95%]
        Copilot[GitHub Copilot<br/>⭐⭐⭐⭐☆<br/>Daemon: 70-80%]
        Continue[Continue.dev<br/>⭐⭐⭐⭐☆<br/>Daemon: 75-85%]
        Human[Human<br/>⭐⭐⭐⭐⭐<br/>Daemon: N/A]
    end

    CC -.->|Best for| Desktop[Desktop UI]
    Aider -.->|Best for| Automation[Full Automation]
    Cursor -.->|Best for| VSCode[VS Code Users]
    Wind -.->|Best for| AINative[AI-Native IDE]

    style Aider fill:#c8e6c9
    style CC fill:#e1f5ff
    style Cursor fill:#fff3e0
```

---

## 🏗️ Project Creation Flow

```mermaid
graph LR
    A[czarina init<br/>in project] --> B[Edit<br/>config.json]
    B --> C[Create worker<br/>prompts]
    C --> D[czarina launch]
    D --> E[🎉 Workers<br/>Active!]

    style A fill:#e1f5ff
    style E fill:#c8e6c9
```

---

## 📖 Documentation Navigation

```mermaid
graph TB
    Start[🎯 Start Here] --> Beginner{New to<br/>Czarina?}

    Beginner -->|Yes| Getting[📘 Getting Started]
    Beginner -->|No| Advanced[📚 Advanced Topics]

    Getting --> Overview[Czarina Overview]
    Getting --> Setup[Worker Setup]
    Getting --> FirstProject[Create First Project]

    Advanced --> Daemon[⚡ Daemon System]
    Advanced --> Agents[🤖 Agent Types]
    Advanced --> Patterns[🏗️ Worker Patterns]

    FirstProject --> Launch[🚀 Launch!]
    Daemon --> Launch
    Patterns --> Launch

    style Start fill:#e1f5ff
    style Launch fill:#c8e6c9
    style Getting fill:#fff3e0
```

---

## 🎭 Czar Components

### Autonomous Coordinator
**Responsibilities:**
- Monitor all worker sessions
- Detect stuck/idle workers
- Inject tasks and guidance
- Provide real-time dashboard
- Manage Git workflow

### Implementation
- Tmux session monitoring
- Git status checking
- Alert system (JSON)
- Health detection
- Task injection

---

## ⚡ Daemon System

### Auto-Approval Flow
**Process:**
1. Watch worker tmux sessions
2. Detect approval prompts
3. Auto-approve (read/write/commit)
4. Verify approval worked
5. Alert if stuck

### Autonomy Levels
- **Aider:** 95-98% (best)
- **Windsurf:** 85-95%
- **Cursor:** 80-90%
- **Claude Code:** 70-80%
- **Copilot:** 70-80%
- **Continue.dev:** 75-85%

---

## 🔀 Git Workflow

### Branch Strategy
```
main
├── feat/worker1-backend
├── feat/worker2-frontend
├── feat/worker3-tests
└── feat/workerN-task
```

### Integration Process
1. Each worker: own branch
2. Work independently
3. Create PR when done
4. Human reviews
5. Merge to main

---

## 📊 Pattern Library

### Error Recovery
- **Location:** `czarina-core/patterns/ERROR_RECOVERY_PATTERNS.md`
- **Benefit:** 30-50% faster debugging
- **Auto-updates:** `czarina patterns update`

### Czarina-Specific
- **Location:** `czarina-core/patterns/czarina-specific/CZARINA_PATTERNS.md`
- **Focus:** Multi-agent coordination
- **Community:** Backchannel contributions

---

## 🏛️ System Design Principles

### Agent-Agnostic
**Universal Standards:**
- 📄 Files (markdown prompts)
- 🔀 Git (branches, PRs)
- 🖥️ Shell (standard commands)

**Not Used:**
- ❌ Agent-specific APIs
- ❌ Proprietary formats
- ❌ Vendor SDKs

### Embedded Orchestration
**`.czarina/` directory:**
```
.czarina/
├── config.json           # Worker configuration
├── workers/              # Worker prompts
│   ├── backend.md
│   ├── frontend.md
│   └── tests.md
├── status/               # Runtime logs (gitignored)
└── README.md             # Quick reference
```

**Benefits:**
- Version-controlled with project
- Portable across machines
- Shareable with team
- No external dependencies

---

## 🎯 Scale Testing: SARK v2.0

### Configuration
- **Workers:** 10 (6 engineers, 2 QA, 2 docs)
- **Timeline:** 6-8 weeks
- **Speedup:** 3-4x
- **Autonomy:** 90%

### Results
- ✅ Clean git workflow
- ✅ Minimal conflicts
- ✅ High-quality PRs
- ✅ 90% autonomous operation
- ✅ Alert system caught all stuck workers

---

## 🔮 Future Architecture

### Planned Enhancements
- Web dashboard (real-time monitoring)
- Enhanced alert integrations
- More agent profiles
- Advanced coordination patterns
- Multi-machine support

---

**See Also:**
- [README.md](../README.md) - Main overview
- [QUICK_START.md](../QUICK_START.md) - Getting started
- [czarina-core/docs/](../czarina-core/docs/) - Framework docs
