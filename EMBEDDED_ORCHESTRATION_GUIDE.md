# Czarina Embedded Orchestration Guide

## Works With Any AI Coding Assistant! 🌍

Czarina embedded orchestration works with **Claude Code, Cursor, GitHub Copilot, Aider, and more!** Each agent can use its preferred workflow while following the same orchestration.

## The Problem with Remote Orchestration

When working remotely or with different AI assistants, you can't always access:
- The centralized orchestrator repository
- Complex launch scripts
- Dashboard monitors (though this still works!)
- tmux sessions

**You just want to tell your AI assistant: "You are Engineer 1" and have it work!**

## The Solution: Embedded Orchestration

Czarina can **embed orchestration directly into your project repository**, making it:
- ✅ Accessible from any AI coding assistant
- ✅ Self-contained (no external dependencies)
- ✅ Simple ("You are Engineer 1" just works!)
- ✅ Version-controlled with your code
- ✅ Shareable via git clone
- ✅ Agent-agnostic (use Claude, Cursor, Aider, Copilot, etc.)

## Quick Start

### Step 1: Embed Orchestration

From the Czarina orchestrator repo:

```bash
./czarina embed <project-name>
```

Example:
```bash
./czarina embed sark-v2
```

This creates in your project repo:
```
your-project/
├── WORKERS.md                    # Root-level discovery (for Claude)
├── czarina-<project>/            # Short name! (e.g., czarina-sark-v2)
│   ├── README.md                 # Orchestration guide
│   ├── START_WORKER.md           # Detailed worker instructions
│   ├── config.json               # Project configuration
│   ├── .worker-init              # Helper script
│   └── workers/
│       ├── engineer1.md          # Worker prompts (with git workflow!)
│       ├── engineer2.md
│       └── ...
└── (your actual code)
```

### Step 2: Commit & Push

```bash
git add czarina-* WORKERS.md
git commit -m "feat: Add Czarina orchestration"
git push
```

### Step 3: Use from Any AI Coding Assistant

Choose your preferred AI assistant and use the appropriate discovery pattern:

**Claude Code (Web or Desktop):**
```
You are Engineer 1
```

**Cursor or Windsurf:**
```
@czarina-<project>/workers/engineer1.md

Follow this prompt as the assigned worker.
```

**Aider:**
```bash
aider --read czarina-<project>/workers/engineer1.md
```

**GitHub Copilot:**
```
Read czarina-<project>/workers/engineer1.md and follow that worker prompt.
```

Your AI assistant will:
1. Find the worker prompt file
2. Read the complete task description
3. Follow the git workflow
4. Start working!

**See [AGENT_COMPATIBILITY.md](AGENT_COMPATIBILITY.md) for detailed setup for each agent.**

## The Magic: How It Works

### For Humans (Simple!)

**With Claude Code:**
```
You are Engineer 1
```

**With Cursor/Windsurf:**
```
@czarina-<project>/workers/engineer1.md
```

**With Aider:**
```bash
aider --read czarina-<project>/workers/engineer1.md
```

That's it!

### For AI Workers (Any Agent)

When given their worker identity:

1. **Discover orchestration**
   ```bash
   # Claude Code checks WORKERS.md automatically
   # Other agents: user provides direct file path
   cat WORKERS.md  # → Points to czarina-sark-v2/
   ```

2. **Find worker prompt**
   ```bash
   cat czarina-sark-v2/workers/engineer1.md
   ```

3. **Read full task**
   - Task description ✓
   - Deliverables ✓
   - Branch name ✓
   - Git workflow ✓
   - Dependencies ✓

4. **Execute** (same for all agents!)
   ```bash
   git checkout -b feat/my-component
   # work on deliverables
   git commit -m "feat(engineer1): implement X"
   gh pr create
   ```

**All agents follow the same git workflow, tracked by the same dashboard!**

## Directory Structure

```
your-project/
├── WORKERS.md                               ← "Start here!" for Claude
├── czarina-myproject/                       ← Orchestration (short name!)
│   ├── README.md                            ← How to use
│   ├── START_WORKER.md                      ← Detailed worker guide
│   ├── config.json                          ← Worker definitions
│   ├── .worker-init                         ← Helper script
│   ├── workers/                             ← Worker prompts
│   │   ├── engineer1.md                     ← Full task + git workflow
│   │   ├── engineer2.md
│   │   ├── qa1.md
│   │   └── ...
│   └── status/                              ← Runtime state (gitignored)
├── src/                                     ← Your actual code
└── tests/
```

## What Gets Embedded

### 1. WORKERS.md (Root Discovery)

```markdown
# Multi-Agent Orchestration

When told "You are Engineer 1":
1. List workers: ls czarina-myproject/workers/
2. Read prompt: cat czarina-myproject/workers/engineer1.md
3. Follow instructions exactly
```

**Location:** Project root
**Purpose:** Tell Claude where orchestration lives
**For:** Claude Code Web users

### 2. Worker Prompts

**Example:** `czarina-myproject/workers/engineer1.md`

```markdown
# ENGINEER-1: Component Implementation

## Task
Implement HTTP adapter component

## Deliverables
- src/adapters/http_adapter.py
- tests/test_http_adapter.py

## Git Workflow
Your branch: feat/v2-http-adapter

Steps:
1. git checkout -b feat/v2-http-adapter
2. Implement deliverables
3. git commit -m "feat(engineer1): implement HTTP adapter"
4. gh pr create --base main --head feat/v2-http-adapter

[Full git workflow with all details]
```

**Contains:**
- Complete task description
- Specific files to create
- Assigned branch name
- Full git workflow
- Commit conventions
- PR instructions
- Dependencies

**For:** The worker agent to follow

### 3. Helper Scripts

**`.worker-init`** - Displays worker info:
```bash
./czarina-myproject/.worker-init engineer1

# Shows:
# - Worker ID
# - Branch name
# - Full prompt
# - Next steps
```

**For:** Local development (optional)

## Usage Examples

### Example 1: Mobile Development

You're at the coffee shop with your tablet...

```
Human: "You are Engineer 2"

Claude:
  [reads WORKERS.md]
  [reads czarina-sark-v2/workers/engineer2.md]

  I'm Engineer 2 - HTTP Adapter implementation.
  My branch: feat/v2-http-adapter

  Let me start:

  $ git checkout -b feat/v2-http-adapter
  $ ls src/adapters/  # checking current state

  [begins implementing HTTP adapter...]
```

### Example 2: Team Handoff

**Monday - You:**
```bash
./czarina embed my-feature
git push
```

**Tuesday - Teammate (different location):**
```bash
git clone repo
cd repo

# In Claude Code Web
"You are QA 1"

# QA agent discovers tests to write, branch to use, starts working
```

### Example 3: Parallel Workers

**Your phone:**
```
"You are Engineer 1"
```

**Your laptop (different Claude session):**
```
"You are QA 1"
```

Both work in parallel, different branches, no conflicts!

## Complete Workflow Example

### Setup (Once)

```bash
# 1. In orchestrator repo - define project
cd ~/orchestrator/projects/
cp -r example-orchestration myproject-orchestration
cd myproject-orchestration

# 2. Edit config.sh
vim config.sh
# Define: project name, workers, branches, tasks

# 3. Create worker prompts
mkdir -p prompts
vim prompts/ENGINEER-1.md  # Task description
vim prompts/QA-1.md
# etc.

# 4. Embed into project
cd ~/orchestrator
./czarina embed myproject

# 5. Result in project repo
cd ~/myproject
ls czarina-myproject/  # orchestration embedded!
cat WORKERS.md         # discovery file created!

# 6. Commit
git add czarina-myproject/ WORKERS.md
git commit -m "feat: Add Czarina orchestration"
git push
```

## Multi-Agent Teams 🤝

One of Czarina's superpowers: **different workers can use different AI assistants!**

### Example Mixed-Agent Team

```
Engineer 1: Uses Claude Code (mobile-friendly, on the go)
Engineer 2: Uses Cursor (desktop IDE, complex refactoring)
QA 1: Uses Aider (CLI automation, test generation)
Docs 1: Uses GitHub Copilot (GitHub-integrated workflow)
```

**They all work together seamlessly because:**
- ✅ Same git workflow (branches, commits, PRs)
- ✅ Same file-based prompts (markdown)
- ✅ Same dashboard tracking (monitors git)
- ✅ No agent-specific APIs or dependencies

### How to Coordinate Mixed Teams

1. **Embed once** - All agents read the same orchestration
2. **Each picks their tool** - Worker chooses preferred AI assistant
3. **Follow same workflow** - All use git branches, conventional commits, PRs
4. **Monitor together** - Dashboard shows all workers regardless of agent

### Discovery Patterns by Agent

Share these patterns with your team:

| Agent | Discovery Pattern | Example |
|-------|------------------|---------|
| Claude Code | "You are Engineer 1" | Direct assignment |
| Cursor | @czarina-*/workers/engineer-1.md | File reference |
| Aider | aider --read czarina-*/workers/engineer-1.md | CLI parameter |
| Copilot | "Read czarina-*/workers/engineer-1.md" | Chat instruction |

**Everyone ends up reading the same worker prompt file!**

### Daily Use (Any Agent)

```
# You open repo on phone