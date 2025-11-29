# Claude Code Orchestrator - WSL Guide

## ✅ WSL Compatibility

The orchestrator is **fully compatible with WSL** (Windows Subsystem for Linux).

All fixes have been applied to work seamlessly in WSL environments.

## 🚀 Quick Start in WSL

```bash
cd /home/jhenry/Source/GRID/claude-orchestrator
./QUICKSTART.sh
```

Choose option **2** to launch all workers in tmux.

## 📊 Working with Tmux in WSL

### List Worker Sessions

```bash
tmux ls
```

You'll see:
```
sark-worker-engineer1: 1 windows (created Thu Nov 27 22:50:12 2025)
sark-worker-engineer2: 1 windows (created Thu Nov 27 22:50:13 2025)
sark-worker-engineer3: 1 windows (created Thu Nov 27 22:50:14 2025)
sark-worker-engineer4: 1 windows (created Thu Nov 27 22:50:15 2025)
sark-worker-qa: 1 windows (created Thu Nov 27 22:50:16 2025)
sark-worker-docs: 1 windows (created Thu Nov 27 22:50:17 2025)
```

### Attach to a Worker

```bash
tmux attach -t sark-worker-engineer1
```

You'll see a banner with:
- Worker role and task
- Branch name
- Task file location
- Helper commands
- Ready bash prompt

### Detach from Worker

While inside a tmux session, press:
```
Ctrl+B, then D
```

The worker session keeps running in the background.

### Kill a Worker Session

```bash
tmux kill-session -t sark-worker-engineer1
```

## 💡 Recommended WSL Setup

### Option 1: Windows Terminal with Multiple Tabs

1. **Tab 1:** Dashboard
   ```bash
   cd /home/jhenry/Source/GRID/claude-orchestrator
   ./dashboard.py
   ```

2. **Tab 2:** Worker access
   ```bash
   cd /home/jhenry/Source/GRID/claude-orchestrator
   tmux attach -t sark-worker-engineer1
   # Detach with Ctrl+B, D
   # Then attach to another: tmux attach -t sark-worker-engineer2
   ```

3. **Tab 3:** Orchestrator commands
   ```bash
   cd /home/jhenry/Source/GRID/claude-orchestrator
   # Available when needed:
   # ./pr-manager.sh
   # ./orchestrator.sh
   # ./validate.sh
   ```

### Option 2: Tmux Panes

Create a tmux window with multiple panes:

```bash
# Create new tmux session for monitoring
tmux new -s orchestrator

# Split window horizontally
Ctrl+B, "

# Split top pane vertically
Ctrl+B, %

# Navigate between panes
Ctrl+B, arrow keys

# In pane 1: Dashboard
./dashboard.py

# In pane 2: Worker access
tmux attach -t sark-worker-engineer1

# In pane 3: Commands
# Ready for orchestrator commands
```

## 🎯 Workflow in WSL

### Day 1: Launch

```bash
cd /home/jhenry/Source/GRID/claude-orchestrator
./QUICKSTART.sh
# Choose option 2

# In another terminal/tab:
./dashboard.py
```

### Day 2-7: Monitor

```bash
# Check dashboard occasionally
# Dashboard shows all worker progress

# Attach to specific worker if needed
tmux attach -t sark-worker-engineer1
```

### Day 8: PR Management

```bash
./pr-manager.sh
# Option 1: Check all PRs
# Option 3: Auto-review all
# Option 4: Create omnibus branch
```

### Day 10: Merge

```bash
./pr-manager.sh
# Option 5: Create omnibus PR
# Option 6: Merge to main
```

## 🔧 Troubleshooting in WSL

### "command not found" errors

The orchestrator no longer uses GUI-specific commands like `gnome-terminal`.
Everything works in pure terminal mode.

### Tmux sessions not visible

```bash
# Check if tmux server is running
tmux ls

# If no sessions, workers may not have started
./QUICKSTART.sh
# Choose option 2 again
```

### Can't attach to worker

```bash
# Make sure session exists
tmux ls | grep sark-worker

# Attach explicitly
tmux attach -t sark-worker-engineer1
```

### Dashboard not showing colors

Install/update dependencies:
```bash
pip3 install --upgrade rich
./dashboard.py
```

## 📝 WSL-Specific Notes

### File Permissions

If you get permission errors:
```bash
chmod +x *.sh *.py
```

### Line Endings

If scripts fail with "bad interpreter":
```bash
dos2unix *.sh
# Or:
sed -i 's/\r$//' *.sh
```

### Git Configuration

Make sure git is configured in WSL:
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

## ✅ Verification

Run validation to ensure everything works:

```bash
./validate.sh
```

All checks should pass:
- ✅ All required files exist
- ✅ Scripts are executable
- ✅ Task files present
- ✅ Git configured
- ✅ Dependencies installed

## 🎸 Ready to Go

The orchestrator is **fully tested and working in WSL**.

Launch workers, monitor progress, manage PRs - all from WSL!

```bash
cd /home/jhenry/Source/GRID/claude-orchestrator
./QUICKSTART.sh
```

Choose option 2, and start vibecoding! 🎉

---

**Tested on:** WSL 2
**Status:** ✅ Fully Compatible
**Last Updated:** November 27, 2025
