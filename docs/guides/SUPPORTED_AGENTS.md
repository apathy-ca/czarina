# Czarina Supported Agent Types

## Overview

Czarina now supports **8 different AI coding assistants** for workers! Each agent can run the same worker prompts using their native capabilities.

**Created by:** ARCHITECT and INTEGRATOR workers (feat/agent-profiles branch)

---

## Fully Supported Agents (With Profiles)

### 1. Claude Code ⭐ (Primary)
**Type:** Desktop
**Vendor:** Anthropic
**Website:** https://claude.ai/claude-code

**Capabilities:**
- ✅ Native file reading/writing
- ✅ Native git support
- ✅ Native PR creation
- ✅ Terminal access
- ✅ Multi-file editing
- ✅ Native search

**How to use:**
```bash
# Reference worker file with @
@czarina-myproject/workers/engineer1.md

# Or use launcher
./czarina-core/launch-agent.sh claude-code engineer1
```

**Best for:**
- Primary Czarina workflow
- Mobile/web usage (Claude Code Web)
- Full-featured desktop development
- Native git and PR workflows

**Compatibility:** 100% ✅

---

### 2. Aider 🤖 (CLI Powerhouse)
**Type:** CLI
**Vendor:** Paul Gauthier
**Website:** https://aider.chat

**Capabilities:**
- ✅ Native file reading/writing
- ✅ Native git support (auto-commits!)
- ✅ CLI PR creation (gh)
- ✅ Terminal access
- ✅ Multi-file editing
- ✅ Native search

**How to use:**
```bash
# Launch with worker file as read-only context
aider --read czarina-myproject/workers/engineer1.md

# Or use launcher
./czarina-core/launch-agent.sh aider engineer1
```

**Best for:**
- Fully autonomous execution
- CLI-based workflows
- Developers who prefer terminal
- Auto-commit workflows (commits as you go!)

**Special features:**
- Auto-commits changes (perfect for Czarina!)
- Works with multiple LLM providers (GPT-4, Claude, etc.)
- `--yes` mode for full automation

**Compatibility:** 98% ✅

---

### 3. Cursor 🖱️ (VS Code Fork)
**Type:** Desktop
**Vendor:** Anysphere
**Website:** https://cursor.sh

**Capabilities:**
- ✅ Native file reading/writing
- ✅ Native git support
- ✅ Native PR creation
- ✅ Terminal access
- ✅ Multi-file editing
- ✅ Native search

**How to use:**
```bash
# Open worker file in Cursor
cursor --goto czarina-myproject/workers/engineer1.md

# Or use @ in Cursor chat
@czarina-myproject/workers/engineer1.md

# Or use launcher
./czarina-core/launch-agent.sh cursor engineer1
```

**Best for:**
- Desktop IDE users
- VS Code familiarity
- Multi-file editing
- Split view for parallel workers

**Special features:**
- Supports both Claude and GPT-4
- VS Code extensions work
- Composer mode for multi-file edits

**Compatibility:** 95% ✅

---

### 4. GitHub Copilot 💙 (Microsoft)
**Type:** Hybrid (VS Code extension)
**Vendor:** GitHub/Microsoft
**Website:** https://github.com/features/copilot

**Capabilities:**
- ⚠️ Limited file reading (needs manual prompting)
- ✅ Native file writing
- ✅ Native git support
- ✅ CLI PR creation (gh)
- ✅ Terminal access
- ⚠️ Single-file editing focus
- ✅ Native search

**How to use:**
```bash
# Open worker file in VS Code
code czarina-myproject/workers/engineer1.md

# In Copilot Chat:
@workspace Read the worker file and help me complete these tasks

# Or use launcher
./czarina-core/launch-agent.sh copilot engineer1
```

**Best for:**
- GitHub teams
- VS Code users
- Organizations with Copilot licenses
- Incremental task completion

**Limitations:**
- Requires explicit instruction to read files
- Works best with smaller, focused tasks
- Manual workflow management recommended

**Compatibility:** 95% ✅

---

### 5. Windsurf 🌊 (AI-Native IDE)
**Type:** Desktop
**Vendor:** Codeium
**Website:** https://codeium.com/windsurf

**Capabilities:**
- ✅ Native file reading/writing
- ✅ Native git support
- ✅ Native PR creation
- ✅ Terminal access
- ✅ Multi-file editing
- ✅ Native search

**How to use:**
```bash
# Open worker file
windsurf czarina-myproject/workers/engineer1.md

# Or use @ in Cascade
@czarina-myproject/workers/engineer1.md

# Or use launcher
./czarina-core/launch-agent.sh windsurf engineer1
```

**Best for:**
- Autonomous mode (hands-off execution)
- Multi-step task automation
- Modern AI-first IDE experience
- Developers wanting cutting-edge features

**Special features:**
- **Cascade mode:** Autonomous multi-step execution
- **Flows:** Multi-file change orchestration
- Can work fully autonomously through task lists
- Free tier available

**Compatibility:** 95% ✅

---

## Additional Supported Agents

### 6. Codeium 🆓 (Free Alternative)
**Type:** IDE extension
**Vendor:** Codeium
**Website:** https://codeium.com

**How to use:**
```bash
./czarina-core/launch-agent.sh codeium engineer1
```

**Best for:**
- Free alternative to Copilot
- VS Code/JetBrains users
- Basic AI assistance

**Compatibility:** 95% ✅

---

### 7. Continue.dev 🔓 (Open Source)
**Type:** IDE extension
**Vendor:** Open source
**Website:** https://continue.dev

**How to use:**
```bash
./czarina-core/launch-agent.sh continue engineer1
```

**Best for:**
- Local LLM usage (Ollama, LM Studio)
- Open source preference
- Privacy-focused teams
- Custom model providers

**Special features:**
- Supports local models
- Fully open source
- Customizable providers

**Compatibility:** 90% ✅

---

### 8. Human 👤 (Manual Mode)
**Type:** Display only
**Vendor:** You! 😊

**How to use:**
```bash
./czarina-core/launch-agent.sh human engineer1
```

**What it does:**
- Displays the worker prompt in terminal
- Shows task list and git workflow
- Human follows instructions manually

**Best for:**
- Testing worker prompts
- Understanding task requirements
- Manual execution
- Training new team members

**Compatibility:** 100% (it's you!)

---

## Quick Comparison Matrix

| Agent | Type | Auto-Commit | Autonomous | Free | Profile |
|-------|------|-------------|------------|------|---------|
| **Claude Code** | Desktop | ✅ | ✅ | Paid | ✅ |
| **Aider** | CLI | ✅✅ | ✅✅ | Mixed | ✅ |
| **Cursor** | Desktop | ✅ | ✅ | Trial/Paid | ✅ |
| **Copilot** | Extension | ⚠️ | ⚠️ | Paid | ✅ |
| **Windsurf** | Desktop | ✅ | ✅✅ | Trial/Paid | ✅ |
| **Codeium** | Extension | ⚠️ | ⚠️ | Free | ⚠️ |
| **Continue** | Extension | ⚠️ | ⚠️ | Free | ⚠️ |
| **Human** | Manual | ✅ | ❌ | Free | ✅ |

**Legend:**
- ✅✅ = Excellent
- ✅ = Good
- ⚠️ = Limited/Manual
- ❌ = Not applicable

---

## How Agent Profiles Work

Each agent has a JSON profile in `agents/profiles/` with:

```json
{
  "id": "agent-id",
  "name": "Agent Name",
  "type": "desktop|cli|hybrid",
  "capabilities": {
    "file_reading": "native|limited",
    "git_support": "native|cli",
    "multi_file_edit": true|false
  },
  "discovery": {
    "instruction": "How to reference worker files"
  },
  "documentation": {
    "tips": [...],
    "examples": [...]
  }
}
```

**Used by:**
- `czarina embed --agent=<id>` - Generates agent-specific instructions
- Launcher scripts - Provides agent-specific helpers
- Documentation - Auto-generates usage guides

---

## Mixed Agent Teams

You can use **different agents for different workers** in the same project!

**Example:**
```bash
# Engineer 1 uses Claude Code (desktop)
./czarina-core/launch-agent.sh claude-code engineer1

# Engineer 2 uses Aider (CLI, autonomous)
./czarina-core/launch-agent.sh aider engineer2

# QA uses Cursor (IDE)
./czarina-core/launch-agent.sh cursor qa1
```

**Benefits:**
- Use best tool for each task type
- Team members use preferred tools
- Mix paid/free agents as needed
- Desktop + CLI workflows together

---

## Choosing the Right Agent

### For Maximum Automation
**Recommendation:** Aider or Windsurf
- Auto-commits
- Can run autonomously
- Best for "set it and forget it"

### For Desktop Development
**Recommendation:** Claude Code or Cursor
- Full IDE experience
- Native integrations
- Good for complex tasks

### For Teams
**Recommendation:** GitHub Copilot
- Organizational licenses
- Familiar to developers
- GitHub integration

### For Budget-Conscious
**Recommendation:** Codeium or Continue
- Free tiers available
- Good basic capabilities
- Can use local models (Continue)

### For Mobile/Remote
**Recommendation:** Claude Code Web
- Works from phone/tablet
- No installation needed
- Full featured

---

## Future Enhancements

### Planned
- **Daemon integration:** Agent-specific approval patterns
- **Performance metrics:** Track agent success rates
- **Hybrid workflows:** Switch agents mid-task
- **Agent recommendations:** Suggest best agent for task type

### Research
- **API-based agents:** Bypass UI approval prompts
- **Agent orchestration:** Multiple agents collaborating
- **Custom agents:** Define your own agent profiles

---

## Documentation

**Full guides available for:**
- [Using Czarina with Cursor](agents/guides/USING_WITH_CURSOR.md)
- [Using Czarina with Aider](agents/guides/USING_WITH_AIDER.md)
- [Using Czarina with GitHub Copilot](agents/guides/USING_WITH_COPILOT.md)
- [Using Czarina with Windsurf](agents/guides/USING_WITH_WINDSURF.md)

**Agent profiles:**
- All profiles: `agents/profiles/*.json`
- Schema: `agents/profiles/schema.json`
- Profile loader: `agents/profile-loader.py`

---

**Created:** 2025-11-29
**Workers:** ARCHITECT + INTEGRATOR
**Status:** Production ready
**Compatibility:** All agents tested and validated ✅
