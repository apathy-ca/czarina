# Using Czarina with GitHub Copilot

GitHub Copilot is AI pair programming integrated into VS Code and other IDEs. This guide shows how to use Czarina workers with Copilot.

## Prerequisites

- GitHub Copilot subscription (Individual, Business, or Enterprise)
- VS Code or supported IDE
- Copilot Chat extension installed

## Quick Start

### 1. Embed Orchestration

```bash
cd /path/to/your/project
czarina embed myproject
```

### 2. Open in VS Code

```bash
code /path/to/your/project
```

Or use the Czarina launcher:

```bash
./czarina-core/launch-agent.sh copilot engineer1
```

### 3. Load Worker Prompt in Copilot Chat

Open Copilot Chat (`Cmd+Shift+I` or click chat icon) and type:

```
#file:czarina-myproject/workers/engineer1.md

Read this worker prompt and follow it exactly. I am this worker.
```

Copilot will load the worker instructions and guide you through the tasks!

## Setup

### Install Copilot Extensions

1. Open VS Code
2. Go to Extensions (`Cmd+Shift+X`)
3. Install:
   - **GitHub Copilot** (required)
   - **GitHub Copilot Chat** (required for Czarina)
4. Sign in to GitHub when prompted

### Verify Copilot is Active

Check the bottom-right corner of VS Code:
- Look for the Copilot icon
- Should show status (active/inactive)
- Click to verify subscription

## Workflow Example

### 1. Open Project and Worker File

```bash
code /your/project
```

### 2. Find Your Worker File

- Press `Cmd+P` (Quick Open)
- Type: `czarina`
- Select: `czarina-myproject/workers/engineer1.md`
- Open the file to review your tasks

### 3. Open Copilot Chat

- Press `Cmd+Shift+I` or `Ctrl+Shift+I`
- Or click the chat icon in the sidebar

### 4. Reference Worker File

In Copilot Chat:

```
#file:czarina-myproject/workers/engineer1.md

I am Engineer 1 from the Czarina orchestration.
Follow the worker prompt above exactly.
What is my first task?
```

### 5. Start Working

Copilot will understand your role and guide you:

```
Based on your worker prompt, let's implement JWT authentication.
Show me the current auth structure.
```

### 6. Use Copilot Commands

Copilot Chat has useful slash commands:

```
/explain src/auth/middleware.js
/fix the token validation error
/tests for the JWT middleware
/doc add JSDoc comments
```

### 7. Make Commits

Use the Source Control panel or terminal:

```bash
git add .
git commit -m "feat(auth): implement JWT validation

- Add token validation middleware
- Create token refresh endpoint
- Add unit tests

🤖 Generated with Czarina Multi-Agent Orchestration"
git push
```

### 8. Create Pull Request

```bash
gh pr create --base main \
  --title "feat: Implement authentication" \
  --body "Completed Engineer 1 tasks for authentication system

🤖 Generated with Czarina Multi-Agent Orchestration"
```

## Copilot Chat Features

### File References

Reference files in chat with `#file:`:

```
#file:czarina-myproject/workers/engineer1.md
#file:src/auth/middleware.js
#file:tests/auth.test.js

Review my changes against the worker prompt
```

### Workspace Context

Use `@workspace` for full project awareness:

```
@workspace where is the authentication code?
@workspace show me all TODO comments
@workspace find security vulnerabilities
```

### Slash Commands

Useful commands for Czarina workflows:

- `/explain` - Understand code
- `/fix` - Fix errors
- `/tests` - Generate tests
- `/doc` - Add documentation
- `/clear` - Clear chat history

### Agent Selection (Copilot Extensions)

If you have Copilot Extensions enabled:

```
@github Find PRs related to authentication
@terminal explain this error
```

## Tips & Best Practices

### Keep Worker File Open

Split your editor:

1. Open worker file: `czarina-myproject/workers/engineer1.md`
2. Split editor: `Cmd+\` or `Ctrl+\`
3. Keep worker visible while coding

### Reference Worker Frequently

Remind Copilot of your role:

```
According to my worker prompt (#file:czarina-myproject/workers/engineer1.md),
I should implement error handling. Let's do that next.
```

### Use Inline Copilot + Chat

- **Inline suggestions**: Automatic as you type
- **Chat**: For complex questions and planning
- **Quick chat**: `Cmd+I` for inline questions

Both work together!

### Organize by Tasks

Create TODO comments from worker prompt:

```javascript
// TODO (Engineer 1): Implement JWT validation middleware
// TODO (Engineer 1): Add token refresh endpoint
// TODO (Engineer 1): Write unit tests for auth
```

Then ask Copilot:

```
@workspace show my TODOs
```

### Git Integration

VS Code's git features work perfectly with Czarina:

- **Source Control**: `Cmd+Shift+G`
- **Diff view**: Click changed files
- **Commit**: Type message and click checkmark
- **Branch**: Click branch name in status bar

## Multi-Worker Workflows

### Multiple VS Code Windows

Work on multiple workers simultaneously:

```bash
# Terminal 1
code /project --new-window

# Terminal 2
code /project --new-window
```

In each window, load different worker:

**Window 1:**
```
#file:czarina-myproject/workers/engineer1.md
I am Engineer 1
```

**Window 2:**
```
#file:czarina-myproject/workers/engineer2.md
I am Engineer 2
```

### Workspace Context

Use workspace context to see other workers' changes:

```
@workspace show recent commits by other workers
@workspace what PRs are open?
```

## Troubleshooting

### Copilot Not Finding Worker File

**Problem**: `#file:` doesn't autocomplete worker file

**Solution**:
1. Ensure workspace is the project root
2. Use relative path from root: `#file:czarina-myproject/workers/engineer1.md`
3. Open the file manually first: `Cmd+P` → search for file
4. Try typing full path

### Copilot Ignores Worker Instructions

**Problem**: Copilot doesn't follow worker prompt

**Solution**:
1. Re-reference the file in chat
2. Be more explicit: "Follow these instructions exactly"
3. Copy/paste worker prompt into chat if needed
4. Start fresh: `/clear` and reload worker prompt

### Can't Create PR

**Problem**: `gh` command not found

**Solution**:
```bash
# Install GitHub CLI
brew install gh        # macOS
winget install gh      # Windows
apt install gh         # Linux

# Authenticate
gh auth login
```

Or create PR via web:
```bash
git push
# Then open GitHub.com and create PR manually
```

### Subscription Issues

**Problem**: Copilot not active

**Solution**:
1. Check subscription: https://github.com/settings/copilot
2. Sign in to GitHub in VS Code
3. Click Copilot icon in status bar
4. Try: `Cmd+Shift+P` → "GitHub Copilot: Sign in"

## Advanced Usage

### VS Code Settings for Czarina

Add to `.vscode/settings.json`:

```json
{
  "github.copilot.enable": {
    "*": true,
    "markdown": true
  },
  "files.associations": {
    "czarina-*/workers/*.md": "markdown"
  },
  "search.exclude": {
    "czarina-*/config.json": true
  }
}
```

### Workspace Snippets

Create `.vscode/czarina.code-snippets`:

```json
{
  "Load Czarina Worker": {
    "prefix": "czw",
    "body": [
      "#file:czarina-${1:project}/workers/${2:engineer1}.md",
      "",
      "I am ${2:engineer1}. Follow the worker prompt above exactly."
    ],
    "description": "Load Czarina worker prompt in Copilot Chat"
  }
}
```

Type `czw` in chat for quick worker loading!

### Keyboard Shortcuts

Add to keyboard shortcuts (`Cmd+K Cmd+S`):

```json
[
  {
    "key": "cmd+shift+w",
    "command": "workbench.view.extension.copilot-chat",
    "when": "!inQuickOpen"
  }
]
```

### GitHub Actions Integration

Copilot can help with CI/CD:

```
@workspace generate a GitHub Action workflow for:
- Running tests on PR
- Building the project
- Deploying to staging
```

## Copilot vs Other Agents

### Copilot Advantages

- ✅ **Inline suggestions**: Real-time as you type
- ✅ **GitHub integration**: Native PR/issue support
- ✅ **IDE features**: Full VS Code power
- ✅ **@workspace**: Understands full project context
- ✅ **Enterprise support**: Available for orgs

### When to Use Copilot for Czarina

- GitHub-centric teams
- VS Code users
- When you want inline + chat AI
- Enterprise environments
- Real-time coding assistance

### When to Use Other Agents

- **Aider**: Full automation, CLI workflows
- **Cursor**: Alternative IDE with different UX
- **Claude Code**: Mobile access, web-based work

## Copilot Chat vs Copilot Workspace

### Copilot Chat (Current Approach)

- In-editor assistance
- File-by-file help
- Real-time coding
- ✅ **Works with Czarina today**

### Copilot Workspace (Future)

- Multi-file operations
- Task planning
- Autonomous execution
- ⏱️ **Czarina integration coming**

Workspace mode could enable fully autonomous Czarina workers in the future!

## Resources

- **Copilot Docs**: https://docs.github.com/copilot
- **VS Code Copilot**: https://code.visualstudio.com/docs/copilot
- **Copilot Chat**: https://docs.github.com/copilot/github-copilot-chat
- **Czarina Compatibility**: See `AGENT_COMPATIBILITY.md`

## Getting Help

For Czarina + Copilot issues:

1. Check this guide's Troubleshooting section
2. Review main `AGENT_COMPATIBILITY.md`
3. Run: `./agents/test-agents.sh`
4. Check Copilot docs: https://docs.github.com/copilot
5. Open issue in Czarina repo

---

**Happy orchestrating with GitHub Copilot!** 🚀💙
