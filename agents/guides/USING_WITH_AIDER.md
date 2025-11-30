# Using Czarina with Aider

Aider is an AI pair programming tool in your terminal. It's perfect for fully autonomous Czarina workers and CLI-based workflows.

## Quick Start

### 1. Install Aider

```bash
# With pip
pip install aider-chat

# Or with pipx (recommended)
pipx install aider-chat
```

Verify installation:
```bash
aider --version
```

### 2. Embed Orchestration

```bash
cd /path/to/your/project
czarina embed myproject
```

### 3. Launch Aider with a Worker

Use the Czarina launcher:

```bash
./czarina-core/launch-agent.sh aider engineer1
```

Or use the Aider-specific helper:

```bash
./agents/launchers/aider-launcher.sh engineer1
```

Aider will start with your worker prompt loaded!

## Manual Setup

If you want to launch Aider manually:

```bash
cd /your/project

# Launch Aider with worker prompt
aider --read czarina-myproject/workers/engineer1.md \
      --model claude-3-5-sonnet-20241022 \
      --auto-commits
```

Then in the Aider session:

```
I am Engineer 1. Let's start with my first task.
```

## Aider Configuration

### Recommended Aider Flags for Czarina

```bash
aider \
  --read czarina-myproject/workers/engineer1.md \
  --model claude-3-5-sonnet-20241022 \
  --auto-commits \
  --commit-prompt "feat({worker_id}): {description}" \
  --yes \
  --git
```

**Flag explanations:**

- `--read <file>`: Load worker prompt into context
- `--model`: Specify AI model (Claude Sonnet recommended)
- `--auto-commits`: Automatically commit changes
- `--commit-prompt`: Template for commit messages
- `--yes`: Auto-confirm operations (for full automation)
- `--git`: Enable git integration

### .aider.conf.yml

Create a project-specific Aider config:

```yaml
# .aider.conf.yml
model: claude-3-5-sonnet-20241022
auto-commits: true
git: true
attribute-author: true
attribute-commit-message-author: true
commit-prompt: |
  feat({worker_id}): {description}

  🤖 Generated with Czarina Multi-Agent Orchestration
```

## Workflow Example

### 1. Start Aider Session

```bash
./czarina-core/launch-agent.sh aider engineer1
```

### 2. Aider Loads Your Worker Prompt

Aider reads the worker file and has context about:
- Your role and responsibilities
- Your assigned branch
- Your tasks and success criteria

### 3. Give Instructions

Since Aider has the worker prompt, you can give high-level instructions:

```
Let's implement the first task: JWT token validation middleware
```

### 4. Aider Works

Aider will:
- Read relevant files
- Make changes
- Create tests
- Auto-commit (if `--auto-commits` enabled)

### 5. Review Changes

```
/diff  # See what changed
/undo  # Undo last change if needed
/git   # Git status
```

### 6. Push and Create PR

```bash
# In Aider or after exiting
git push

gh pr create --base main --title "feat: JWT authentication" \
  --body "Implemented JWT token validation as Engineer 1"
```

## Aider Commands

### Essential Aider Commands

- `/help` - Show all commands
- `/add <files>` - Add files to chat context
- `/drop <files>` - Remove files from context
- `/ls` - List files in context
- `/git` - Git status
- `/diff` - Show pending changes
- `/undo` - Undo last change
- `/commit` - Commit current changes
- `/run <command>` - Run shell command
- `/exit` or `/quit` - Exit Aider

### Czarina-Specific Workflow

```bash
# Start session
/clear  # Clear chat history if continuing

# Review assignment
# (Worker prompt is already loaded)

# Add relevant files
/add src/auth/*.js

# Work on task
Implement JWT validation in src/auth/middleware.js

# Review
/diff

# Commit (auto-commits enabled) or manual:
/commit

# Check status
/git

# Exit when done
/exit
```

## Fully Autonomous Mode

For truly autonomous workers, use this configuration:

```bash
aider \
  --read czarina-myproject/workers/engineer1.md \
  --model claude-3-5-sonnet-20241022 \
  --auto-commits \
  --yes \
  --message "Complete all tasks in the worker prompt" \
  --no-pretty \
  --git
```

This runs Aider non-interactively! Perfect for CI/CD or batch processing.

### Autonomous Script

Create `run-worker-autonomous.sh`:

```bash
#!/bin/bash
WORKER_ID=$1

aider \
  --read "czarina-myproject/workers/${WORKER_ID}.md" \
  --model claude-3-5-sonnet-20241022 \
  --auto-commits \
  --yes \
  --message "You are ${WORKER_ID}. Complete all assigned tasks." \
  --git
```

Then run:

```bash
./run-worker-autonomous.sh engineer1
```

And walk away! Aider will work autonomously and commit progress.

## Tips & Best Practices

### Model Selection

Aider supports multiple models. For Czarina:

**Recommended:**
```bash
--model claude-3-5-sonnet-20241022  # Best balance
```

**Alternatives:**
```bash
--model gpt-4-turbo      # OpenAI alternative
--model claude-opus      # Maximum quality (expensive)
--model gpt-3.5-turbo    # Budget option
```

### Git Integration

Aider's git integration is excellent for Czarina:

- **Auto-commits**: Changes are automatically committed
- **Branch aware**: Works on your current branch
- **Diff support**: See changes before committing
- **Undo support**: Roll back mistakes

Make sure you're on the right branch before starting:

```bash
git checkout feat/my-worker-branch
aider --read czarina-myproject/workers/engineer1.md
```

### File Context Management

Aider works best with relevant files in context:

```bash
# Add specific files
/add src/auth/middleware.js src/auth/validation.js

# Add by pattern
/add src/**/*.js

# Drop files
/drop tests/

# List current context
/ls
```

### Cost Management

Monitor costs with:

```bash
aider --model claude-3-5-sonnet-20241022 --show-model-warnings
```

For budget work:
```bash
aider --model gpt-3.5-turbo  # Cheaper option
```

### Testing During Development

Run tests from Aider:

```bash
/run npm test
/run pytest
/run make test
```

Aider can see test results and fix failures!

## Multi-Worker Setup

### Running Multiple Workers Simultaneously

```bash
# Terminal 1: Engineer 1
cd project && aider --read czarina-myproject/workers/engineer1.md

# Terminal 2: Engineer 2
cd project && aider --read czarina-myproject/workers/engineer2.md

# Terminal 3: QA Worker
cd project && aider --read czarina-myproject/workers/qa1.md
```

Each Aider instance:
- Works on its own branch
- Has its own worker context
- Makes independent commits
- Can coordinate via git/PRs

### Tmux for Multi-Worker Management

```bash
#!/bin/bash
# launch-all-aider-workers.sh

tmux new-session -d -s czarina

tmux new-window -t czarina:1 -n "engineer1"
tmux send-keys -t czarina:1 "aider --read czarina-myproject/workers/engineer1.md" C-m

tmux new-window -t czarina:2 -n "engineer2"
tmux send-keys -t czarina:2 "aider --read czarina-myproject/workers/engineer2.md" C-m

tmux new-window -t czarina:3 -n "qa"
tmux send-keys -t czarina:3 "aider --read czarina-myproject/workers/qa1.md" C-m

tmux attach-session -t czarina
```

Now you have all workers running in tmux windows!

## Troubleshooting

### Aider Not Found

**Problem**: `command not found: aider`

**Solution**:
```bash
# Install with pip
pip install aider-chat

# Or pipx
pipx install aider-chat

# Verify
which aider
aider --version
```

### API Key Not Set

**Problem**: Aider complains about missing API key

**Solution**:
```bash
# For Claude
export ANTHROPIC_API_KEY="your-key-here"

# For OpenAI
export OPENAI_API_KEY="your-key-here"

# Make permanent in ~/.bashrc or ~/.zshrc
echo 'export ANTHROPIC_API_KEY="your-key"' >> ~/.bashrc
```

### Worker Prompt Not Loading

**Problem**: Aider doesn't follow worker instructions

**Solution**:
1. Verify file path: `ls czarina-myproject/workers/`
2. Use absolute path: `--read /full/path/to/worker.md`
3. Check file contents: `cat czarina-myproject/workers/engineer1.md`

### Git Conflicts

**Problem**: Merge conflicts when pushing

**Solution**:
```bash
# In Aider or after exiting
/exit  # Exit Aider first

git pull --rebase origin main
# Resolve conflicts
git add .
git rebase --continue

# Restart Aider
aider --read czarina-myproject/workers/engineer1.md
```

### Too Many Changes at Once

**Problem**: Aider makes too many changes

**Solution**:
1. Give more specific instructions
2. Add only relevant files to context: `/add src/auth/middleware.js`
3. Use `/diff` to review before committing
4. Use `/undo` to roll back
5. Disable auto-commits initially: remove `--auto-commits` flag

## Advanced Usage

### Custom Commit Messages

```bash
aider \
  --commit-prompt "feat(${WORKER_ID}): {description}

{details}

🤖 Generated with Czarina Multi-Agent Orchestration"
```

### Pre-commit Hooks Integration

Aider respects pre-commit hooks! If you have:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
```

Aider will run hooks before committing.

### Environment-Specific Workers

```bash
# Development
aider --read czarina-dev/workers/engineer1.md

# Staging
aider --read czarina-staging/workers/engineer1.md

# Production
aider --read czarina-prod/workers/engineer1.md
```

## Aider vs Other Agents

### Aider Advantages for Czarina

- ✅ **Full automation**: Can run completely autonomously
- ✅ **Terminal-native**: Perfect for CI/CD pipelines
- ✅ **Auto-commits**: Built-in git workflow
- ✅ **Cost-effective**: Efficient token usage
- ✅ **Scriptable**: Easy to automate

### When to Use Aider

- Autonomous worker execution
- CI/CD integration
- Terminal-based workflows
- Batch processing multiple tasks
- Cost-sensitive projects

### When to Use Other Agents

- **Cursor**: Complex IDE features, debugging
- **Claude Code**: Mobile access, exploratory work
- **GitHub Copilot**: In-editor suggestions

## Resources

- **Aider Website**: https://aider.chat
- **Aider Documentation**: https://aider.chat/docs/
- **GitHub**: https://github.com/paul-gauthier/aider
- **Czarina Compatibility**: See `AGENT_COMPATIBILITY.md`

## Getting Help

For Czarina + Aider issues:

1. Check this guide's Troubleshooting section
2. Run: `./agents/test-agents.sh`
3. Check Aider docs: https://aider.chat/docs/
4. Open issue in Czarina repo

---

**Happy autonomous orchestrating with Aider!** 🤖🚀
