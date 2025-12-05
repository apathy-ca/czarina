# Feature: Improved Live Dashboard (v2)

**Date:** 2025-12-05
**Status:** ✅ Implemented
**Type:** Enhancement
**Component:** dashboard-v2.py

## Overview

Created a modernized dashboard with better display, .czarina/config.json support, and improved worker monitoring.

## Problem with Old Dashboard

The original `dashboard.py` had several issues:
1. Used old config.sh format (not .czarina/config.json)
2. Hardcoded for SARK project structure
3. Poor visual layout
4. Limited worker status detection
5. No worktree awareness

## New Features

### 1. Modern Configuration
- Reads `.czarina/config.json` instead of config.sh
- Auto-discovers project from current directory
- Works with any Czarina project

### 2. Better Visual Layout
```
┌─────────────────────────────────────────┐
│ 🎭 Czarina Dashboard - Project Name     │
│ 📁 /path/to/project                     │
│ ⏰ 2025-12-05 08:00:00                  │
└─────────────────────────────────────────┘

┌─ 👷 Workers ──────────────┬─ 📊 Status ─┐
│ Worker      Status  Git   │ Sessions: 2  │
│ worker1     🟢 Act  ✅ Cl │ Workers: 11  │
│ worker2     ⚪ Idle 📝 2M │   Active: 8  │
│ worker3     🟡 Wait ❌ Er │   Idle: 3    │
│ ...                       │              │
│                           │ 🟢 Daemon    │
│                           │   Active     │
│                           │              │
│                           │ 📁 Worktrees │
│                           │   11         │
└───────────────────────────┴──────────────┘

┌─────────────────────────────────────────┐
│ Commands: Ctrl+C to exit | Sessions:... │
└─────────────────────────────────────────┘
```

### 3. Worker Status Detection
Analyzes tmux pane output to determine:
- 🟢 **Active**: Working with aider, making changes
- ⚪ **Idle**: At command prompt
- ⚪ **Ready**: Waiting to start (shows startup message)
- 🟡 **Waiting**: Needs input (approval prompt)
- 🔴 **Error**: Error detected in output

### 4. Git Status per Worker
Shows git status for each worker's worktree:
- ✅ **Clean**: No changes
- 📝 **XM YA**: X modified files, Y added/untracked
- ❌ **No worktree**: Worktree doesn't exist
- ❌ **Git error**: Can't read git status

### 5. Daemon Monitoring
- Shows daemon running/stopped status
- Displays latest iteration number
- Updates in real-time

### 6. Auto-Discovery
- Finds czarina sessions by project slug
- Handles multiple session naming patterns
- Works with split sessions (czarina-memory-1, czarina-memory-2)

## Implementation

### Tech Stack
- **Rich library**: Beautiful terminal UI
- **Tmux integration**: Capture pane content
- **Git integration**: Check worktree status
- **Auto-refresh**: Updates every 3 seconds

### Architecture
```python
CzarinaDashboard
├── _find_sessions()         # Discover tmux sessions
├── _get_worker_status()     # Analyze worker pane
├── _get_git_status()        # Check worktree git
├── _get_daemon_status()     # Monitor daemon
├── generate_header()        # Top panel
├── generate_workers_table() # Worker grid
├── generate_status_panel()  # Right sidebar
└── run()                    # Live update loop
```

## Usage

```bash
# From project directory
cd ~/my-project
czarina dashboard

# From anywhere with project name
czarina dashboard my-project

# Press Ctrl+C to exit
```

## Value

✅ **Real-time Monitoring**: See all workers at once
✅ **Status at a Glance**: Color-coded worker states
✅ **Git Awareness**: Track changes per worker
✅ **Universal**: Works with any Czarina project
✅ **Better UX**: Clean, organized display

## Testing

Tested with:
- 11-worker orchestration (thesymposium)
- Multiple tmux sessions
- Git worktrees
- Daemon monitoring
- Various worker states

## Future Enhancements

- [ ] Token usage tracking per worker
- [ ] Task completion percentage
- [ ] Estimated time remaining
- [ ] Alert on stuck workers
- [ ] Export status to JSON
- [ ] Web-based dashboard option

## Metrics

- **Refresh Rate**: 3 seconds
- **Sessions Supported**: Unlimited
- **Workers Supported**: Unlimited
- **Performance**: <100ms render time
- **Dependencies**: Rich (auto-installed)
