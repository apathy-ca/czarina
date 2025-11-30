# Embedded Orchestration - Feature Summary

## What We Built

**Goal:** Enable Claude Code Web users to orchestrate workers with just "You are Engineer 1"

**Solution:** Embed orchestration directly into the project repository.

## New Capabilities

### 1. `czarina embed` Command

```bash
./czarina embed <project>
```

**What it does:**
- Creates `czarina-<project>/` directory in project repo
- Copies all worker prompts (with git workflows)
- Generates `WORKERS.md` at repo root for discovery
- Sets up helper scripts
- Configures .gitignore

**Example:**
```bash
./czarina embed sark-v2
# Creates: ~/Source/GRID/sark/czarina-sark-v2/
```

### 2. Self-Contained Orchestration

**Structure created:**
```
your-project/
├── WORKERS.md                    ← Discovery file (Claude reads this first)
├── czarina-<project>/            ← Short, mobile-friendly name
│   ├── README.md
│   ├── START_WORKER.md
│   ├── config.json
│   ├── .worker-init              ← Helper script
│   └── workers/
│       ├── engineer1.md          ← Full prompt + git workflow
│       ├── engineer2.md
│       └── ...
└── src/                          ← Your code
```

**Everything workers need is in the repo!**

### 3. Natural Language Discovery

Workers can be launched with natural phrases:

```
"You are Engineer 1"    → loads engineer1.md
"you are engineer 2"    → loads engineer2.md
"You are QA 1"          → loads qa1.md
"qa 2"                  → loads qa2.md
```

The `.worker-init` script parses these and finds the right worker file.

### 4. Root-Level Discovery (WORKERS.md)

**File:** `WORKERS.md` at project root

**Purpose:** Tell Claude where to find orchestration

**Content:**
```markdown
# Multi-Agent Orchestration

When told "You are Engineer 1":
1. ls czarina-<project>/workers/
2. cat czarina-<project>/workers/engineer1.md
3. Follow instructions
```

**For:** Claude Code Web users (mobile/tablet/browser)

## User Experience

### Before (Complex)

```
Human on phone:
1. SSH to server
2. cd ~/orchestrator
3. tmux attach -t sark-v2
4. Navigate to right pane
5. Start Claude Desktop
6. Reference long prompt file path
7. Hope worker knows git workflow
```

### After (Simple)

```
Human on phone:
1. Open Claude Code Web in repo
2. Say: "You are Engineer 1"
3. Done!
```

## How It Works

### Setup (Once per Project)

```bash
# In orchestrator repo
./czarina embed my-project

# In project repo
cd ~/my-project
git add czarina-* WORKERS.md
git commit -m "feat: Add Czarina orchestration"
git push
```

### Usage (Daily)

**On mobile/tablet/browser:**
```
Open repo in Claude Code Web
Say: "You are Engineer 1"
```

**Claude's process:**
1. Reads `WORKERS.md` → learns about czarina-<project>/
2. Reads `czarina-<project>/workers/engineer1.md`
3. Extracts: task, branch, git workflow, deliverables
4. Creates branch: `git checkout -b feat/...`
5. Starts working on deliverables
6. Makes commits with proper conventions
7. Creates PR when done

## Files Created

### In Orchestrator Repo

```
czarina-core/
├── embed-orchestration.sh         ← Main embed script
└── templates/embedded-orchestration/
    ├── README.md                   ← Template for orchestration README
    ├── START_WORKER.md             ← Template for worker guide
    ├── .worker-init                ← Template for helper script
    └── config.json                 ← Template for config

czarina                             ← CLI (modified)
EMBEDDED_ORCHESTRATION_GUIDE.md     ← Usage guide
```

### In Project Repo (After Embedding)

```
your-project/
├── WORKERS.md                      ← Discovery (generated)
└── czarina-<project>/              ← Orchestration dir (generated)
    ├── README.md
    ├── START_WORKER.md
    ├── config.json
    ├── .worker-init
    └── workers/
        ├── engineer1.md            ← Copied from orchestrator
        ├── engineer2.md
        └── ...
```

## Key Features

### ✅ Mobile-Friendly

- Short directory names (czarina-sark-v2, not czarina-sark-v2-0-protocol...)
- Simple commands ("You are Engineer 1")
- No complex setup required
- Works in Claude Code Web

### ✅ Self-Contained

- All prompts in repo
- Git workflows included
- No external dependencies
- Version-controlled

### ✅ Discoverable

- WORKERS.md at root
- Natural language parsing
- Helper scripts for local use
- Clear documentation

### ✅ Collaborative

- Git clone just works
- Team members can start immediately
- Parallel work on different branches
- No coordination needed

## Example Workflows

### Workflow 1: Solo Developer on Mobile

```bash
# Setup (once)
./czarina embed my-feature
git push

# Daily (on phone)
"You are Engineer 1"
# ... work happens ...
# PR created automatically
```

### Workflow 2: Team Collaboration

```bash
# Lead dev
./czarina embed team-project
git push

# Engineer 1 (different location)
git clone repo
"You are Engineer 1"
# ... works on engineer1 tasks ...

# QA 1 (different location)
git clone repo
"You are QA 1"
# ... works on QA tasks ...

# All work in parallel, different branches
```

### Workflow 3: Mixed Local/Remote

```bash
# Desktop (using orchestrator dashboard)
./czarina dashboard my-project

# Phone (using embedded)
"You are Engineer 2"

# Both visible in dashboard!
```

## Benefits

### For Solo Developers

- ✅ Code from anywhere (phone, tablet, borrowed laptop)
- ✅ No setup on new devices
- ✅ Quick context switching
- ✅ Always have orchestration available

### For Teams

- ✅ Onboarding: git clone + "You are..." = productive
- ✅ Distributed work: everyone has same orchestration
- ✅ Version-controlled: orchestration evolves with code
- ✅ No central server needed

### For Czarina

- ✅ Two modes: centralized (dashboard) + embedded (mobile)
- ✅ Broader use cases
- ✅ Better DX (developer experience)
- ✅ More accessible

## Commands Summary

### Orchestrator Side

```bash
./czarina list                 # List projects
./czarina init <project>       # Initialize branches
./czarina embed <project>      # Embed into repo (NEW!)
./czarina dashboard <project>  # Monitor progress
./czarina launch <project>     # Launch workers (tmux)
./czarina status <project>     # Show config
```

### Project Side (After Embedding)

```bash
# Discovery
cat WORKERS.md

# List workers
ls czarina-<project>/workers/

# Read worker prompt
cat czarina-<project>/workers/engineer1.md

# Launch worker (local)
./czarina-<project>/.worker-init engineer1

# Or just say (Claude Code Web)
"You are Engineer 1"
```

## Testing

Tested with sark-v2 project:

```bash
./czarina embed sark-v2
# ✅ Created czarina-sark-v2/ in SARK repo
# ✅ Created WORKERS.md at repo root
# ✅ Copied 10 worker prompts
# ✅ Generated config.json
# ✅ Set up .worker-init script

./czarina-sark-v2/.worker-init engineer1
# ✅ Displayed worker info
# ✅ Showed branch: feat/v2-lead-architect
# ✅ Showed full prompt

./czarina-sark-v2/.worker-init "You are Engineer 2"
# ✅ Parsed natural language
# ✅ Found engineer2
# ✅ Displayed prompt
```

## Documentation

- **EMBEDDED_ORCHESTRATION_GUIDE.md** - Complete usage guide
  - Quick start
  - How it works
  - Directory structure
  - Examples
  - Troubleshooting

- **czarina-<project>/README.md** - In-repo guide (generated)
  - Project-specific instructions
  - Worker list
  - Helper commands

- **WORKERS.md** - Discovery file (generated)
  - Simple instructions for Claude
  - Points to worker prompts

## Next Steps (Optional)

Future enhancements:

1. **Auto-update** - Script to re-embed when prompts change
2. **Status tracking** - Track worker progress in embedded mode
3. **Web dashboard** - Static HTML dashboard (no server needed)
4. **Mobile app** - Native mobile app for monitoring
5. **PR templates** - Auto-generate PR templates from worker prompts

## Summary

**Czarina now supports two modes:**

1. **Centralized** (existing)
   - Full orchestrator repo
   - Dashboard monitoring
   - tmux sessions
   - Perfect for: desktop, team leads, monitoring

2. **Embedded** (NEW!)
   - Self-contained in project repo
   - "You are Engineer 1" command
   - Works in Claude Code Web
   - Perfect for: mobile, remote, solo work

**One orchestrator, two modes, maximum flexibility!** 🚀📱💻

---

**Commits:**
- First commit (64186b4): Git workflow automation + branch init
- Second commit (a485424): Embedded orchestration for Claude Code Web

**Status:** Complete, tested, documented, pushed to main ✅
