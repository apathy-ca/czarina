# Using Czarina with Windsurf

Windsurf is an AI-powered IDE that provides seamless AI assistance for coding. This guide shows how to use Czarina's multi-agent orchestration with Windsurf.

## Quick Start

### 1. Embed Orchestration

```bash
cd /path/to/your/project
czarina embed myproject
```

### 2. Launch Windsurf with a Worker

Use the Czarina launcher:

```bash
./czarina-core/launch-agent.sh windsurf engineer1
```

Or use the Windsurf-specific helper:

```bash
./agents/launchers/windsurf-launcher.sh engineer1
```

### 3. In Windsurf: Reference the Worker File

Once Windsurf opens, reference your worker file:

```
@czarina-myproject/workers/engineer1.md

I am this worker. Follow the prompt exactly.
```

Windsurf will load the worker prompt and guide you through your tasks!

## Manual Setup

If you prefer manual setup:

1. **Open Windsurf:**
   ```bash
   windsurf /path/to/your/project
   ```

2. **Find your worker file:**
   - Use Quick Open: `Cmd+P` (Mac) or `Ctrl+P` (Windows/Linux)
   - Type: `czarina-`
   - Select your worker file (e.g., `engineer1.md`)

3. **Load the worker prompt:**
   - In Windsurf AI Chat, type: `@czarina-myproject/workers/engineer1.md`
   - Add: "I am this worker. Follow the instructions exactly."

4. **Start working!**
   - Windsurf will use the worker context
   - Follow the git workflow in the worker file
   - Make commits on your assigned branch

## Workflow Example

### 1. Launch Windsurf as Worker

```bash
./czarina-core/launch-agent.sh windsurf engineer1
```

### 2. In Windsurf AI Chat

```
@czarina-myproject/workers/engineer1.md

I am Engineer 1. What's my assignment?
```

### 3. Review Tasks

Windsurf will parse your worker file and show:
- Your assigned branch
- Your tasks and deliverables
- Success criteria

### 4. Start Implementation

```
Let's start with implementing the JWT authentication middleware.
Show me the current auth structure.
```

### 5. Use Windsurf Features

Windsurf provides powerful AI features:

- **AI Chat**: Full conversational coding
- **Inline Edits**: AI-powered code suggestions
- **Multi-file Awareness**: Understands project context
- **Git Integration**: Built-in version control

### 6. Make Commits

Use the integrated Source Control or terminal:

```bash
git add .
git commit -m "feat(auth): implement JWT validation

- Add token validation middleware
- Create token refresh endpoint
- Add comprehensive tests

🤖 Generated with Czarina Multi-Agent Orchestration"
git push
```

### 7. Create Pull Request

```bash
gh pr create --base main --title "feat: Authentication system" \
  --body "$(cat <<'EOF'
## Summary
Implemented JWT-based authentication system as Engineer 1

## Changes
- JWT validation middleware
- Token refresh endpoint
- Unit and integration tests

## Testing
- ✅ All tests passing
- ✅ Manual testing complete

🤖 Generated with Czarina Multi-Agent Orchestration
EOF
)"
```

## Windsurf Features

### AI Chat

Windsurf's AI Chat is context-aware:

```
@czarina-myproject/workers/engineer1.md
@src/auth/middleware.js
@tests/auth.test.js

Review my implementation against the worker requirements
```

### File References

Use `@` to reference files:

```
@package.json - Check dependencies
@src/config/auth.js - Review auth config
@czarina-myproject/workers/engineer1.md - Reference worker prompt
```

### Inline AI

Windsurf can edit code inline:

1. Select code
2. Press AI shortcut (varies by OS)
3. Ask for changes
4. Accept or reject suggestions

### Multi-file Operations

Ask for changes across multiple files:

```
Update all files to use the new authentication middleware.
Make sure to update imports and add error handling.
```

Windsurf will modify multiple files intelligently!

## Tips & Best Practices

### Keep Worker File Visible

Split your editor for easy reference:

1. Open worker file: `czarina-myproject/workers/engineer1.md`
2. Split editor: `Cmd+\` or `Ctrl+\`
3. Keep worker prompt visible while coding

### Reference Worker Frequently

Remind Windsurf of your context:

```
According to my worker prompt (@czarina-myproject/workers/engineer1.md),
I need to add error handling next. Let's implement that.
```

### Use Chat + Inline Together

- **Chat**: For planning and complex questions
- **Inline**: For quick edits and suggestions
- Both work seamlessly together

### Git Workflow

Windsurf has excellent git integration:

- **Source Control Panel**: View changes, stage, commit
- **Branch Management**: Switch branches easily
- **Diff View**: Review changes before committing
- **Terminal**: Built-in for git commands

Check your branch before starting:

```bash
git branch --show-current  # Verify you're on the right branch
```

### Project Understanding

Windsurf understands your project:

```
Where should I add the new authentication tests?
What's the project's error handling pattern?
Show me how other middleware is implemented.
```

## Multi-Worker Workflows

### Multiple Windsurf Windows

Work on multiple workers:

```bash
# Terminal 1: Engineer 1
windsurf /project /project/czarina-myproject/workers/engineer1.md

# Terminal 2: Engineer 2
windsurf /project /project/czarina-myproject/workers/engineer2.md
```

Each window acts as a different worker!

### Coordinate Between Workers

In each Windsurf window:

```
Check what Engineer 2 is working on.
Do my changes conflict with the QA worker's tests?
```

Windsurf can read git history and see other workers' changes!

## Troubleshooting

### Worker File Not Found

**Problem**: Windsurf can't find the worker file with `@`

**Solution**:
1. Verify file exists: `ls czarina-*/workers/`
2. Use full path from project root
3. Check workspace folder is correct
4. Try `Cmd+P` / `Ctrl+P` to find manually

### Windsurf Not Following Instructions

**Problem**: Windsurf ignores worker prompt

**Solution**:
1. Re-reference: `@czarina-myproject/workers/engineer1.md`
2. Be explicit: "Follow these instructions exactly"
3. Keep worker file open in split pane
4. Reference specific sections: "My worker prompt says to..."

### Git Issues

**Problem**: Can't commit or push

**Solution**:
1. Use Source Control panel in Windsurf
2. Or use integrated terminal: `Ctrl+` `
3. Verify you're on correct branch
4. Check git credentials are configured

### Multiple Workers Confusion

**Problem**: Mixed up between different workers

**Solution**:
1. Use separate Windsurf windows for each worker
2. Keep worker files visible in each window
3. Check current branch in status bar
4. Use different themes/layouts per window

## Advanced Usage

### Workspace Configuration

Create `.windsurf/settings.json`:

```json
{
  "ai.model": "claude-3-sonnet",
  "files.associations": {
    "czarina-*/workers/*.md": "markdown"
  },
  "search.exclude": {
    "czarina-*/config.json": true
  }
}
```

### Custom AI Prompts

Create project-specific AI instructions:

Create `.windsurf/ai-instructions.md`:

```markdown
# Czarina Multi-Agent Context

This project uses Czarina orchestration:
- Worker prompts are in czarina-*/workers/
- Each worker has an assigned branch
- Follow git workflow in worker prompts
- Include Czarina footer in commits
```

Windsurf will automatically use this context!

### Keyboard Shortcuts

Set up Windsurf shortcuts for Czarina:

- Quick Open Worker: Custom shortcut to filter `czarina-*`
- Reference Worker: Macro to insert `@czarina-`
- Git Commit with Footer: Template for commits

### Templates

Create commit message template:

`.gitmessage`:
```
feat(component): brief description

- Detailed change 1
- Detailed change 2

🤖 Generated with Czarina Multi-Agent Orchestration
```

Configure git:
```bash
git config commit.template .gitmessage
```

## Windsurf vs Other Agents

### Windsurf Advantages

- ✅ Modern AI-first IDE
- ✅ Excellent multi-file awareness
- ✅ Natural AI chat integration
- ✅ Good git integration
- ✅ Clean, focused interface

### When to Use Windsurf for Czarina

- You prefer Windsurf over other IDEs
- Modern AI-assisted development
- Multi-file refactoring
- Desktop development workflows
- Visual git management

### When to Use Other Agents

- **Claude Code**: Mobile/web access
- **Aider**: Full automation, CLI workflows
- **Cursor**: If you prefer Cursor's features
- **GitHub Copilot**: GitHub-native teams

## Resources

- **Windsurf Website**: [Check Windsurf documentation]
- **Czarina Repo**: Main README for updates
- **Agent Compatibility**: See `AGENT_COMPATIBILITY.md`

## Getting Help

For Czarina + Windsurf issues:

1. Check this guide's Troubleshooting section
2. Review main `AGENT_COMPATIBILITY.md`
3. Run test suite: `./agents/test-agents.sh`
4. Check Windsurf documentation
5. Open issue in Czarina repository

## Comparison: Windsurf vs Cursor

Both are excellent AI IDEs. Key differences:

| Feature | Windsurf | Cursor |
|---------|----------|---------|
| AI Model | Various | GPT-4, Claude |
| Interface | Windsurf-specific | VS Code-based |
| File References | `@` syntax | `@` syntax |
| Git Integration | Built-in | Built-in |
| Czarina Support | ✅ Full | ✅ Full |

**Both work great with Czarina!** Choose based on your preference.

## Example Project Structure

Here's how a Czarina project looks in Windsurf:

```
myproject/
├── czarina-myproject/          # Orchestration
│   ├── workers/
│   │   ├── engineer1.md        # ← Reference with @
│   │   ├── engineer2.md
│   │   └── qa1.md
│   ├── config.json
│   └── .worker-init
├── src/
│   └── ... (your code)
├── tests/
│   └── ... (your tests)
└── .windsurf/
    ├── settings.json
    └── ai-instructions.md      # Optional context
```

In Windsurf, reference workers easily:
```
@czarina-myproject/workers/engineer1.md
```

---

**Happy orchestrating with Windsurf!** 🌊🚀
