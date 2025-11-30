# Czarina Embedded Orchestration Guide

## The Problem with Remote Orchestration

When using Claude Code Web (mobile/browser), you can't access:
- The centralized orchestrator repository
- Complex launch scripts
- Dashboard monitors
- tmux sessions

**You just want to tell Claude: "You are Engineer 1" and have it work!**

## The Solution: Embedded Orchestration

Czarina can **embed orchestration directly into your project repository**, making it:
- ✅ Accessible from Claude Code Web
- ✅ Self-contained (no external dependencies)
- ✅ Simple ("You are Engineer 1" just works!)
- ✅ Version-controlled with your code
- ✅ Shareable via git clone

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

### Step 3: Use from Claude Code Web

On your phone/tablet/browser, open Claude Code Web in your project.

Just say:
```
You are Engineer 1
```

Claude will:
1. Check `WORKERS.md` for instructions
2. Read `czarina-<project>/workers/engineer1.md`
3. Follow the git workflow
4. Start working!

## The Magic: How It Works

### For Humans (You on Mobile)

Three words:
```
You are Engineer 1
```

That's it!

### For Workers (Claude Agents)

When told "You are Engineer 1":

1. **Discover orchestration**
   ```bash
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

4. **Execute**
   ```bash
   git checkout -b feat/my-component
   # work on deliverables
   git commit -m "feat(engineer1): implement X"
   gh pr create
   ```

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

### Daily Use (Claude Code Web)

```
# You open repo on phone