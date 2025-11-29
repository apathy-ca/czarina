# 🤖 Agent Types - Beyond Claude Code

**Key Insight**: Czarina orchestrates **any AI coding agent**, not just Claude Code!

## Supported Agent Types

### 1. Claude Code (Default)
**What it is**: Official Anthropic coding interface
**How it works**: Browser-based or desktop app
**Czarina integration**: Tmux sessions with paste-buffer injection

```bash
WORKER_DEFINITIONS=(
    "engineer1|feat/v1.1-backend|engineer1_TASKS.txt|Backend|agent:claude-code"
)
```

**Pros**:
- ✅ Full context understanding
- ✅ Multi-file editing
- ✅ Interactive decision-making
- ✅ Great for complex tasks

**Cons**:
- ⚠️ Manual session management
- ⚠️ Requires human to press "send"

---

### 2. Aider
**What it is**: AI pair programming in the terminal
**How it works**: CLI-based, direct file editing
**Czarina integration**: Automated CLI commands

```bash
WORKER_DEFINITIONS=(
    "engineer1|feat/v1.1-backend|engineer1_TASKS.txt|Backend|agent:aider"
)
```

**Deployment**:
```bash
# Aider worker (fully automated!)
aider --yes --message "$(cat prompts/engineer1_TASKS.txt)" \
      --model claude-3-5-sonnet-20241022 \
      --git \
      --auto-commits
```

**Pros**:
- ✅ Fully automated (no human clicking)
- ✅ Direct git commits
- ✅ Terminal-based (scriptable)
- ✅ Works great with Czar

**Cons**:
- ⚠️ Less interactive than Claude Code
- ⚠️ Simpler task completion

---

### 3. Cursor
**What it is**: AI-powered VS Code fork
**How it works**: IDE with AI integration
**Czarina integration**: Possible with extensions/CLI

```bash
WORKER_DEFINITIONS=(
    "engineer1|feat/v1.1-backend|engineer1_TASKS.txt|Backend|agent:cursor"
)
```

**Pros**:
- ✅ Full IDE features
- ✅ Great UX
- ✅ Multi-file awareness

**Cons**:
- ⚠️ Harder to automate
- ⚠️ GUI-based

---

### 4. Continue.dev
**What it is**: Open-source AI code assistant
**How it works**: VS Code / JetBrains extension
**Czarina integration**: Via editor automation

**Pros**:
- ✅ Open source
- ✅ Multiple model support
- ✅ Local models possible

---

### 5. Open Interpreter
**What it is**: ChatGPT Code Interpreter locally
**How it works**: Python REPL + AI
**Czarina integration**: CLI automation

```bash
WORKER_DEFINITIONS=(
    "data|feat/v1.1-analytics|data_TASKS.txt|Data Analysis|agent:open-interpreter"
)
```

**Deployment**:
```bash
interpreter --model gpt-4 --auto_run --message "$(cat prompts/data_TASKS.txt)"
```

**Best for**:
- Data analysis
- Scripting tasks
- System automation

---

### 6. API-Based Agents (Custom)
**What it is**: Direct API calls to Claude/GPT/etc
**How it works**: Custom scripts calling AI APIs
**Czarina integration**: Full control

```bash
WORKER_DEFINITIONS=(
    "engineer1|feat/v1.1-backend|engineer1_TASKS.txt|Backend|agent:api-claude"
)
```

**Implementation**:
```python
# Custom API worker
import anthropic

client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

def run_worker(task_file, branch):
    task = open(task_file).read()

    response = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=8192,
        messages=[{"role": "user", "content": task}]
    )

    # Process response, make git commits, etc.
```

**Pros**:
- ✅ Full automation
- ✅ Complete control
- ✅ Cost tracking
- ✅ Custom behavior

**Cons**:
- ⚠️ You build the glue code

---

### 7. GPT Engineer
**What it is**: AI that generates entire codebases
**How it works**: Iterative generation
**Czarina integration**: CLI automation

**Best for**:
- New project scaffolding
- Boilerplate generation
- Initial architecture

---

### 8. Smol Developer
**What it is**: Minimal AI developer agent
**How it works**: Simple, focused tasks
**Czarina integration**: Easy CLI

**Best for**:
- Small, focused changes
- Quick fixes
- Simple features

---

### 9. AutoGPT / BabyAGI Style
**What it is**: Autonomous agents with task breakdown
**How it works**: Self-directed goal pursuit
**Czarina integration**: High-level task assignment

**Best for**:
- Complex, multi-step tasks
- When worker needs autonomy

---

### 10. Human Developers! 👤
**What it is**: Actual human engineers
**How it works**: Manual work on assigned branches
**Czarina integration**: Task assignment + monitoring

```bash
WORKER_DEFINITIONS=(
    "engineer1|feat/v1.1-backend|engineer1_TASKS.txt|Backend|agent:human"
    "engineer2|feat/v1.1-frontend|engineer2_TASKS.txt|Frontend|agent:claude-code"
    "qa|feat/v1.1-testing|qa_TASKS.txt|Testing|agent:aider"
)
```

**Why this matters**:
- ✅ Hybrid teams (humans + AI)
- ✅ Specialized tasks for humans
- ✅ Czar monitors both equally
- ✅ Humans on critical path, AI on parallel work

---

## Mixed Agent Teams

**The Power**: Combine different agents for optimal results!

### Example 1: Speed + Quality
```bash
WORKER_DEFINITIONS=(
    # Fast automation for boilerplate
    "scaffold|feat/v1.1-setup|scaffold_TASKS.txt|Project Setup|agent:gpt-engineer"

    # Quality for core logic
    "backend|feat/v1.1-api|backend_TASKS.txt|API Logic|agent:claude-code"

    # Automated testing
    "qa|feat/v1.1-tests|qa_TASKS.txt|Test Suite|agent:aider"

    # Human for docs
    "docs|feat/v1.1-docs|docs_TASKS.txt|Documentation|agent:human"
)
```

### Example 2: Cost Optimization
```bash
WORKER_DEFINITIONS=(
    # Expensive model for complex work
    "architect|feat/v2.0-design|arch_TASKS.txt|Architecture|agent:claude-opus"

    # Cheaper model for simple work
    "boilerplate|feat/v2.0-crud|crud_TASKS.txt|CRUD APIs|agent:gpt-3.5-turbo"

    # Free open source for automation
    "scripts|feat/v2.0-scripts|script_TASKS.txt|Build Scripts|agent:continue-local"
)
```

### Example 3: Specialization
```bash
WORKER_DEFINITIONS=(
    # Claude for general coding
    "backend|feat/v1.1-api|backend_TASKS.txt|Backend|agent:claude-code"

    # Codex for Python optimization
    "ml|feat/v1.1-models|ml_TASKS.txt|ML Models|agent:codex"

    # Human for security review
    "security|feat/v1.1-audit|security_TASKS.txt|Security|agent:human"
)
```

---

## Implementation Per Agent

### Aider (Fully Automated) ⭐

**Worker launcher**:
```bash
#!/bin/bash
# launch-aider-worker.sh

WORKER_ID=$1
BRANCH=$2
TASK_FILE=$3

cd $PROJECT_ROOT
git checkout -b $BRANCH 2>/dev/null || git checkout $BRANCH

# Run aider with task
aider \
    --yes \
    --model claude-3-5-sonnet-20241022 \
    --message "$(cat $TASK_FILE)" \
    --git \
    --auto-commits \
    --commit-prompt "feat($WORKER_ID): {description}"
```

**Czar integration**: Works perfectly! Aider auto-commits, Czar sees commits, all autonomous!

---

### API-Based (Fully Automated) ⭐⭐

**Worker script**:
```python
#!/usr/bin/env python3
# api-worker.py

import anthropic
import subprocess
import sys

def run_worker(task_file, branch):
    # Read task
    with open(task_file) as f:
        task = f.read()

    # Checkout branch
    subprocess.run(["git", "checkout", "-b", branch])

    # Call Claude API
    client = anthropic.Anthropic()
    response = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=8192,
        messages=[{"role": "user", "content": task}],
        tools=[...]  # Add file editing tools
    )

    # Process tool calls, edit files, commit
    # ... implementation ...

    # Commit results
    subprocess.run(["git", "add", "."])
    subprocess.run(["git", "commit", "-m", "feat: completed task"])

if __name__ == "__main__":
    run_worker(sys.argv[1], sys.argv[2])
```

**Czar integration**: Perfect! Fully autonomous, no human needed!

---

### Human Workers 👤

**Task delivery**:
```bash
# Email or Slack notification
./notify-human-worker.sh engineer1 "You have a new task: prompts/engineer1_TASKS.txt"
```

**Czar monitoring**:
- Checks commits (same as AI workers)
- Detects stuck humans (no commits in 4 hours)
- Sends reminders

**Why this works**:
- Czar doesn't care WHO is working
- Only cares THAT work is happening
- Monitors git activity, not the agent type

---

## Agent Selection Guide

| Agent | Automation | Cost | Quality | Speed | Best For |
|-------|------------|------|---------|-------|----------|
| Claude Code | Manual | $$$ | ⭐⭐⭐⭐⭐ | Medium | Complex features |
| Aider | Auto | $$ | ⭐⭐⭐⭐ | Fast | General coding |
| API Custom | Auto | $-$$$ | ⭐⭐⭐⭐ | Fast | Full control |
| GPT Engineer | Auto | $$ | ⭐⭐⭐ | Fast | Scaffolding |
| Cursor | Manual | $$ | ⭐⭐⭐⭐ | Medium | IDE users |
| Open Interp. | Auto | $ | ⭐⭐⭐ | Fast | Data/scripts |
| Human | Manual | $$$$ | ⭐⭐⭐⭐⭐ | Slow | Critical work |

---

## Configuration Format (v2.1+)

```bash
# Extended format with agent type
WORKER_DEFINITIONS=(
    # Format: "id|branch|task|description|agent:type"

    "engineer1|feat/v1.1-backend|e1.txt|Backend|agent:claude-code"
    "engineer2|feat/v1.1-frontend|e2.txt|Frontend|agent:aider"
    "engineer3|feat/v1.1-db|e3.txt|Database|agent:cursor"
    "qa|feat/v1.1-tests|qa.txt|Testing|agent:aider"
    "security|feat/v1.1-audit|sec.txt|Security|agent:human"
    "docs|feat/v1.1-docs|doc.txt|Docs|agent:claude-code"
)
```

**Agent launchers**:
```bash
case $AGENT_TYPE in
    claude-code)
        ./launch-claude-code-worker.sh $WORKER_ID $BRANCH $TASK_FILE
        ;;
    aider)
        ./launch-aider-worker.sh $WORKER_ID $BRANCH $TASK_FILE
        ;;
    api-claude)
        ./api-worker.py $TASK_FILE $BRANCH
        ;;
    human)
        ./notify-human-worker.sh $WORKER_ID $TASK_FILE
        ;;
esac
```

---

## The Big Insight

**Czarina doesn't care WHO or WHAT is doing the work!**

It only cares:
- ✅ Is work happening? (git commits)
- ✅ Is worker stuck? (no activity)
- ✅ Is worker idle? (finished, ready for more)

**This means**:
- Mix and match agents
- Human + AI hybrid teams
- Use the best tool for each job
- Full flexibility

---

## Future: Agent Marketplace

Imagine:
```bash
# Install agent plugins
czarina install-agent aider
czarina install-agent cursor
czarina install-agent gpt-engineer

# Use in config
WORKER_DEFINITIONS=(
    "engineer1|feat/v1.1-api|api.txt|API|agent:aider"
    "engineer2|feat/v1.1-ui|ui.txt|UI|agent:cursor"
)

# Czarina handles the rest!
```

---

## Bottom Line

**Czarina is agent-agnostic!**

- ✅ Claude Code (current default)
- ✅ Aider (easy to add)
- ✅ API-based agents (full control)
- ✅ ANY coding agent
- ✅ Even humans!

**The orchestration is the value**, not the specific agent.

Choose the best agent for each task. Mix and match. Czar doesn't care. 🎭

---

*This makes Czarina a **universal multi-agent orchestrator**, not just a Claude Code tool!*

**Killer positioning**: "Orchestrate ANY AI coding agent - Claude, GPT, Aider, Cursor, or even humans!"
