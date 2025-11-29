# Using Czarina with Cursor

Cursor is an AI-powered IDE built on VS Code. This guide shows you how to use Czarina's multi-agent orchestration with Cursor.

## Quick Start

### 1. Embed Orchestration

First, embed Czarina orchestration into your project:

```bash
cd /path/to/your/project
czarina embed myproject
```

This creates a `czarina-myproject/` directory with worker definitions.

### 2. Launch Cursor with a Worker

Use the Czarina launcher:

```bash
./czarina-core/launch-agent.sh cursor engineer1
```

Or use the Cursor-specific helper:

```bash
./agents/launchers/cursor-launcher.sh engineer1
```

### 3. In Cursor: Reference the Worker File

Once Cursor opens, use the `@` symbol to reference your worker file:

```
@czarina-myproject/workers/engineer1.md

Follow this prompt exactly as the assigned worker.
```

Cursor will load the worker prompt into context and you can start working!

## Manual Setup (Without Launcher)

If you prefer to set up manually:

1. **Open your project in Cursor:**
   ```bash
   cursor /path/to/your/project
   ```

2. **Find your worker file:**
   - Press `Cmd+P` (Mac) or `Ctrl+P` (Windows/Linux)
   - Type: `czarina-`
   - Select your worker file (e.g., `engineer1.md`)

3. **Load the worker prompt:**
   - In Cursor Chat, type: `@czarina-myproject/workers/engineer1.md`
   - Add instruction: "I am this worker. Follow the prompt exactly."

4. **Start working!**
   - Cursor will use the worker prompt to guide its responses
   - Follow the git workflow specified in the worker file
   - Make commits on your assigned branch

## Tips & Best Practices

### Keep Worker File Visible

Open the worker file in a split pane for easy reference:

1. Press `Cmd+P` / `Ctrl+P`
2. Type your worker file name
3. Press `Cmd+\` / `Ctrl+\` to split editor
4. Keep the worker prompt visible while coding

### Use @ for File References

Cursor's `@` syntax is perfect for Czarina:

```
@czarina-myproject/workers/engineer1.md - Reference worker prompt
@src/api/users.js - Reference code files
@README.md - Reference documentation
```

### Git Integration

Cursor has excellent git integration:

- **Source Control Panel**: `Cmd+Shift+G` / `Ctrl+Shift+G`
- **View branches**: Click branch name in status bar
- **Commit**: Stage changes in Source Control panel
- **Push**: Use the sync button or terminal

All Czarina git workflows work perfectly in Cursor!

### Terminal Access

Cursor has an integrated terminal:

- Open terminal: `Ctrl+` ` (backtick)
- Run git commands directly
- Use `gh pr create` for pull requests
- Monitor other workers with `git log`

### Multi-Worker Workflows

Working with multiple workers? Open multiple Cursor windows:

```bash
# Terminal 1
cursor /project --goto czarina-myproject/workers/engineer1.md

# Terminal 2
cursor /project --goto czarina-myproject/workers/engineer2.md
```

Each window can act as a different worker!

## Workflow Example

Here's a complete workflow for a Czarina worker in Cursor:

### 1. Launch as Worker

```bash
cd /your/project
./czarina-core/launch-agent.sh cursor engineer1
```

### 2. In Cursor Chat

```
@czarina-myproject/workers/engineer1.md

I am Engineer 1. What's my first task?
```

### 3. Review Your Assignment

Cursor will parse the worker file and tell you:
- Your assigned branch
- Your tasks
- Your success criteria

### 4. Start Working

```
Let's start with task 1. Show me the current state of the authentication system.
```

### 5. Make Changes

Cursor will help you make changes according to the worker prompt.

### 6. Commit Your Work

In the terminal or Source Control panel:

```bash
git add .
git commit -m "feat(auth): implement JWT token validation

- Add token validation middleware
- Create token refresh endpoint
- Add unit tests for auth functions

🤖 Generated with Czarina Multi-Agent Orchestration"
git push
```

### 7. Create Pull Request

```bash
gh pr create --base main --title "feat: Implement authentication system" \
  --body "$(cat <<'EOF'
## Summary
Implemented JWT-based authentication system

## Changes
- JWT token validation middleware
- Token refresh endpoint
- Unit tests for auth functions

## Testing
- ✅ All tests passing
- ✅ Manual testing complete

🤖 Generated with Czarina Multi-Agent Orchestration
EOF
)"
```

## Troubleshooting

### Worker File Not Found

**Problem**: Cursor can't find the worker file with `@`

**Solution**:
1. Check the file exists: `ls czarina-*/workers/`
2. Use full path from project root
3. Make sure Cursor's workspace is the project root
4. Try `Cmd+P` to find the file manually

### Cursor Ignoring Worker Prompt

**Problem**: Cursor doesn't follow the worker instructions

**Solution**:
1. Re-reference the file: `@czarina-myproject/workers/engineer1.md`
2. Be explicit: "Follow the instructions in this worker file exactly"
3. Keep the worker file open in a split pane as a reminder
4. Reference specific sections: "According to my worker prompt, I should work on..."

### Git Integration Not Working

**Problem**: Can't commit or push from Cursor

**Solution**:
1. Cursor has native git support - use the Source Control panel
2. Or use the integrated terminal: `Ctrl+` `
3. Make sure you're on the correct branch
4. Check git credentials are configured

### Multiple Workers Conflict

**Problem**: Working on multiple workers and getting confused

**Solution**:
1. Use separate Cursor windows for each worker
2. Keep worker files visible in each window
3. Check current branch in status bar
4. Use `git branch --show-current` to verify

## Advanced Usage

### Custom Keyboard Shortcuts

Set up shortcuts for common Czarina tasks:

1. Open Cursor Settings (`Cmd+,`)
2. Search for "Keyboard Shortcuts"
3. Add custom shortcuts:
   - "Show worker file" → Quick Open with filter
   - "Reference worker" → Insert `@czarina-` text

### Cursor Rules

Create a `.cursorrules` file in your project:

```
# Czarina Multi-Agent Orchestration

When working as a Czarina worker:
1. Always reference the worker file in czarina-*/workers/
2. Follow git workflow exactly as specified
3. Include Czarina footer in commit messages
4. Work only on assigned branch
5. Coordinate with other workers via PRs
```

This helps Cursor understand the Czarina context automatically!

### Workspace Settings

Add to `.vscode/settings.json` (Cursor uses VS Code settings):

```json
{
  "files.associations": {
    "czarina-*/workers/*.md": "markdown"
  },
  "search.exclude": {
    "czarina-*/config.json": true
  }
}
```

## Cursor vs Other Agents

### Cursor Advantages

- ✅ Full IDE experience with debugging, extensions, etc.
- ✅ Great UX and responsiveness
- ✅ Excellent multi-file awareness
- ✅ Native git integration
- ✅ Can use VS Code extensions

### When to Use Cursor for Czarina

- Desktop development workflows
- Complex refactoring across many files
- When you need debugging tools
- If you prefer IDE over terminal/web
- Multi-file code generation

### When to Use Other Agents

- **Claude Code**: Mobile/tablet work, web-based access
- **Aider**: Full automation, CLI workflows, CI/CD
- **GitHub Copilot**: GitHub-native teams, in-editor suggestions

## Resources

- **Cursor Website**: https://cursor.sh
- **Cursor Documentation**: https://docs.cursor.com
- **Czarina Repo**: Check the main README for updates
- **Agent Compatibility**: See `AGENT_COMPATIBILITY.md`

## Getting Help

If you encounter issues with Czarina + Cursor:

1. Check this guide's Troubleshooting section
2. Review the main `AGENT_COMPATIBILITY.md`
3. Run the test suite: `./agents/test-agents.sh`
4. Open an issue in the Czarina repository

---

**Happy orchestrating with Cursor!** 🚀
