# AI Coding Assistant Compatibility

Czarina works with **any AI coding assistant** that can read files and execute git commands. This document outlines compatibility across different AI agents.

## Compatibility Matrix

| AI Assistant | File Reading | Git Support | Discovery | Dashboard | Compatibility | Notes |
|--------------|--------------|-------------|-----------|-----------|---------------|-------|
| **Claude Code** | ✅ Native | ✅ Native | ✅ Auto | ✅ Works | **100%** | Primary tested agent |
| **Claude Desktop** | ✅ Native | ✅ Native | ✅ Script | ✅ Works | **100%** | Full desktop support |
| **GitHub Copilot** | ✅ Native | ✅ Native | ⚠️ Manual | ✅ Works | **95%** | Manual prompt loading |
| **Cursor** | ✅ Native | ✅ Native | ⚠️ Manual | ✅ Works | **95%** | Use @ to reference files |
| **Windsurf** | ✅ Native | ✅ Native | ⚠️ Manual | ✅ Works | **95%** | Similar to Cursor |
| **Aider** | ✅ Native | ✅ Native | ✅ CLI | ✅ Works | **98%** | Excellent CLI support |
| **Kilocode** | ✅ Native | ✅ Native | ✅ Auto | ✅ Works | **95%** | Autonomous with auto-approval |
| **Shelley** | ✅ Native | ✅ Native | ✅ Web | ✅ Works | **95%** | exe.dev native, subagents |
| **ChatGPT Code** | ✅ Native | ⚠️ Limited | ⚠️ Manual | ✅ Works | **85%** | Git via code interpreter |
| **Codeium** | ✅ Native | ✅ Native | ⚠️ Manual | ✅ Works | **95%** | Works in supported IDEs |
| **OpenAI o1** | ✅ Native | ⚠️ Limited | ⚠️ Manual | ✅ Works | **85%** | Limited shell access |

**Legend:**
- ✅ Works perfectly out of the box
- ⚠️ Needs minor adaptation or manual steps
- ❌ Not supported or requires significant workarounds

## Quick Start by Agent

### Claude Code (Web or Desktop)

**Setup:** None needed - fully supported!

**Usage:**
```
You are Engineer 1
```

**Discovery:** Automatic - Claude will find and read `czarina-*/workers/engineer-1.md`

**Best For:** Mobile, web-based work, quick iterations

---

### Cursor

**Setup:** Install Cursor IDE, clone your repo

**Usage:**
```
@czarina-<projectname>/workers/engineer-1.md

Follow this prompt exactly.
```

**Discovery:** Use @ symbol to reference worker files

**Best For:** Desktop development, IDE integration, familiar VS Code experience

**Tips:**
- Use `@` to reference files in the orchestration directory
- Cursor has excellent git integration
- Can work with multiple workers simultaneously in split views

---

### GitHub Copilot (Workspace or Chat)

**Setup:** GitHub Copilot subscription, VS Code or supported IDE

**Usage:**
```
Read czarina-<projectname>/workers/engineer-1.md and follow that prompt.
```

**Discovery:** Manual file reference in chat

**Best For:** GitHub-centric teams, VS Code users

**Tips:**
- Use Copilot Chat to load worker prompts
- Leverage `/` commands for file operations
- GitHub CLI (gh) works perfectly for PRs

---

### Windsurf

**Setup:** Install Windsurf, clone your repo

**Usage:**
```
@czarina-<projectname>/workers/engineer-1.md

I am this worker. Follow the prompt.
```

**Discovery:** Similar to Cursor, use file references

**Best For:** Teams using Windsurf IDE

---

### Aider

**Setup:** Install aider via pip

**Usage:**
```bash
# Launch aider with worker prompt
aider --read czarina-<projectname>/workers/engineer-1.md

# In aider session
/chat I am engineer-1. Follow the worker prompt you just read.
```

**Discovery:** CLI parameter `--read`

**Best For:** Terminal lovers, automation, CI/CD integration

**Tips:**
- Aider has excellent git integration
- Can be fully automated via scripts
- Great for batch operations

---

### ChatGPT Code Interpreter

**Setup:** ChatGPT Plus subscription with Code Interpreter enabled

**Usage:**
```
Read the file czarina-<projectname>/workers/engineer-1.md in this repository and follow that worker prompt exactly.
```

**Discovery:** Explicit file read instruction

**Best For:** Quick prototypes, Python-heavy tasks, data analysis workers

**Limitations:**
- Limited persistent git integration
- Better for analysis than long-running development
- May need to copy/paste worker prompts

---

### Kilocode

**Setup:** Install kilocode CLI

**Usage:**
```bash
# Launch with autonomous mode and auto-approval
kilocode --auto --yolo --workspace /path/to/workspace "Read WORKER_IDENTITY.md and begin tasks"

# Or use czarina launcher (auto-configured)
czarina launch  # If worker config specifies "agent": "kilocode"
```

**Discovery:** Prompt-based with auto-approval

**Best For:** Fully autonomous execution, CLI workflows, cost-effective Claude alternative

**Tips:**
- `--auto` enables autonomous mode (non-interactive)
- `--yolo` auto-approves all tool permissions
- `--workspace` sets the working directory
- Supports multiple AI providers (OpenAI, Anthropic, etc.)
- `--json` mode for programmatic control
- `--parallel` for parallel mode with automatic branching

---

### Shelley (exe.dev)

**Setup:** exe.dev VM with Shelley service running (default on exeuntu images)

**URL:** `https://<vmname>.exe.xyz:9999/`

**Usage:**
```bash
# In Shelley web UI, start a new conversation and send:
cd .czarina/worktrees/engineer-1 && cat WORKER_IDENTITY.md

# Then follow the instructions in the identity file
```

**Discovery:** Web-based conversation with file context

**Best For:** Cloud-based development, exe.dev environments, browser-accessible agent, subagent parallelism

**Autonomy:** 90-95% (high autonomy with auto-approved file/git operations)

**Tips:**
- Shelley has native bash/terminal access - git operations work seamlessly
- Use subagents for parallel subtasks within a single worker
- Shelley can browse the web and take screenshots for verification
- Conversation history persists in SQLite (`~/.config/shelley/shelley.db`)
- Supports multiple LLM models (Claude, GPT, Gemini)
- Use multiple browser tabs for parallel workers
- Worker prompts work best as markdown with clear task lists

**Launcher:**
```bash
# Use the shelley-worker launcher script
./agents/launchers/shelley-worker.sh \
  --worker-file .czarina/workers/engineer-1.md \
  --worktree .czarina/worktrees/engineer-1
```

**Requirements:**
- exe.dev VM (exeuntu image recommended)
- Shelley service running on port 9999
- Web browser access to `https://<vmname>.exe.xyz:9999/`

---

### Codeium

**Setup:** Codeium extension in your IDE

**Usage:**
```
Read czarina-<projectname>/workers/engineer-1.md and act as that worker.
```

**Discovery:** Manual file reference

**Best For:** Free alternative to Copilot, IDE users

---

## Agent-Specific Setup Notes

### For Auto-Discovery (Claude, Aider)

These agents support automatic worker discovery:

1. **Clone the repo** with embedded orchestration
2. **Say your role**: "You are Engineer 1"
3. **Start working** - agent automatically finds and loads prompt

### For Manual Discovery (Cursor, Copilot, Windsurf, etc.)

These agents need explicit file references:

1. **Clone the repo** with embedded orchestration
2. **Reference the file**: `@czarina-*/workers/engineer-1.md`
3. **Instruct to follow**: "I am this worker, follow this prompt"

## Common Adaptations

### Placeholder Replacements

When generating docs for specific agents, replace these placeholders:

| Placeholder | Claude Code | Cursor | GitHub Copilot | Aider |
|-------------|-------------|--------|----------------|-------|
| `{{AGENT_NAME}}` | Claude Code | Cursor | GitHub Copilot | Aider |
| `{{AGENT_TYPE}}` | AI coding assistant | IDE assistant | AI pair programmer | CLI assistant |
| `{{DISCOVERY_PATTERN}}` | "You are Engineer 1" | "@path/to/worker.md" | "Read path/to/worker.md" | "--read path/to/worker.md" |

### Agent-Specific Instructions

#### Claude Code
```markdown
## Quick Start
When starting a Claude Code session, simply say:
> "You are Engineer 1"

Claude will automatically discover and load your worker prompt.
```

#### Cursor
```markdown
## Quick Start
In Cursor, reference your worker file:
> @czarina-<project>/workers/engineer-1.md
>
> Follow this prompt as the assigned worker.
```

#### Aider
```markdown
## Quick Start
Launch aider with your worker prompt:
```bash
aider --read czarina-<project>/workers/engineer-1.md
```

## Troubleshooting by Agent

### Claude Code

**Issue:** Worker not found
- **Solution:** Ensure `czarina-*/workers/` directory exists in repo
- **Solution:** Try explicit path: "Read czarina-*/workers/engineer-1.md"

**Issue:** Git commands failing
- **Solution:** Check `.bash_allowed` file includes git commands
- **Solution:** Ensure you're in the project root directory

### Cursor

**Issue:** Can't find worker file with @
- **Solution:** Use full path from repo root
- **Solution:** Ensure workspace folder is the repo root

**Issue:** Git integration not working
- **Solution:** Cursor has native git - use Source Control panel
- **Solution:** Can also use terminal: Ctrl+`

### GitHub Copilot

**Issue:** Chat can't read files
- **Solution:** Use `#file:` syntax to reference files
- **Solution:** Copy/paste worker prompt into chat if needed

### Aider

**Issue:** Worker prompt not loading
- **Solution:** Use absolute path with `--read`
- **Solution:** Verify file exists: `ls czarina-*/workers/`

**Issue:** Git conflicts
- **Solution:** Aider auto-commits - configure with `--no-auto-commits` if needed

## Best Practices for Multi-Agent Teams

### Mixed Agent Teams

You can mix agents on the same project! Each worker can use their preferred tool:

- **Engineer 1** uses Claude Code (web, mobile friendly)
- **Engineer 2** uses Cursor (desktop, IDE integration)
- **QA 1** uses Aider (automation friendly)
- **Docs 1** uses GitHub Copilot (GitHub integrated)

**This works because:**
- All agents read the same markdown prompts
- All agents use standard git workflow
- Dashboard tracks progress via git (agent-agnostic)
- PRs integrate work regardless of which agent created them

### Recommendations by Use Case

| Use Case | Recommended Agent | Why |
|----------|-------------------|-----|
| **Mobile/Remote** | Claude Code | Web access, works on tablets/phones |
| **Desktop IDE** | Cursor, Windsurf | Full IDE experience, debugging tools |
| **Terminal Workflow** | Aider, Kilocode | CLI-native, automation friendly |
| **Fully Autonomous** | Kilocode, Windsurf | Auto-approval, autonomous mode |
| **GitHub Teams** | GitHub Copilot | Native GitHub integration |
| **Budget Conscious** | Codeium | Free tier available |
| **Quick Prototypes** | ChatGPT Code | Fast iteration, analysis tools |

## Testing with Different Agents

Want to test Czarina with your preferred agent?

1. **Clone a test repo** with embedded orchestration
2. **Try the discovery pattern** for your agent (see above)
3. **Read a worker file** manually to verify
4. **Create a test branch** following git workflow
5. **Make a small commit** to verify git integration
6. **Create a test PR** to verify PR workflow

If everything works, you're good to go! 🚀

## Contributing Agent Profiles

Tried Czarina with another AI assistant? Help us expand compatibility!

**Share:**
- Agent name and version
- Discovery pattern that worked
- Any special configuration needed
- Compatibility percentage (what works/doesn't)

Submit a PR to add your agent profile to this doc!

## Future Agent Support

Czarina's file-based architecture means it will work with **future AI coding assistants** automatically, as long as they can:

1. ✅ Read markdown files
2. ✅ Execute git commands
3. ✅ Create files and directories
4. ✅ Run bash/shell commands (optional but helpful)

No SDK required, no API integration needed. Just files, git, and markdown!

---

## Summary

**Czarina is agent-agnostic by design!**

It orchestrates through universal standards:
- 📄 Files (markdown prompts)
- 🔀 Git (branches, commits, PRs)
- 🖥️ Shell (standard Unix commands)

**You can use it with:**
- ✅ The agent you have now
- ✅ Different agents for different workers
- ✅ Future agents that don't exist yet

**Just pick your agent and go!** 🌍🤖
