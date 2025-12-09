# Git Worktree Debugging Guide

**Problem:** Workers all working on the same branch in the same directory, stepping on each other
**Cause:** Git worktrees not being created during launch
**Solution:** Better error visibility and debugging

---

## How Worktrees Should Work

When you run `czarina launch`, each worker should get its own isolated workspace:

```
project/.czarina/worktrees/
├── gateway-http-sse/       ← Worker 1's isolated worktree (on feat/gateway-http-sse-transport)
├── gateway-stdio/          ← Worker 2's isolated worktree (on feat/gateway-stdio-transport)
├── integration/            ← Worker 3's isolated worktree (on feat/gateway-integration)
├── policy/                 ← Worker 4's isolated worktree (on feat/policy-validation)
└── qa/                     ← Worker 5's isolated worktree (on fix/auth-tests-and-coverage)
```

**Each worker** operates in their own worktree, allowing true parallel development without conflicts.

---

## Checking if Worktrees Were Created

### 1. List all worktrees
```bash
cd /path/to/project
git worktree list
```

**Expected output:**
```
/home/user/project                165a835 [main]
/home/user/project/.czarina/worktrees/gateway-http-sse  a1b2c3d [feat/gateway-http-sse-transport]
/home/user/project/.czarina/worktrees/gateway-stdio     e4f5g6h [feat/gateway-stdio-transport]
/home/user/project/.czarina/worktrees/integration       i7j8k9l [feat/gateway-integration]
/home/user/project/.czarina/worktrees/policy            m0n1o2p [feat/policy-validation]
/home/user/project/.czarina/worktrees/qa                q3r4s5t [fix/auth-tests-and-coverage]
```

**Problem - only one worktree:**
```
/home/user/project  165a835 [feat/policy-validation]
```

This means workers are NOT in isolated worktrees!

### 2. Check worktree directory
```bash
ls -la .czarina/worktrees/
```

**Expected:** 5 subdirectories (one per worker)
**Problem:** Directory empty or doesn't exist

---

## Common Causes & Fixes

### Cause 1: Branch Already Checked Out

**Error:**
```
fatal: 'feat/gateway-http-sse-transport' is already checked out at '/path/to/project'
```

**Fix:**
The launch script should switch to `main` before creating worktrees. Check launch output:
```
🔄 Preparing repository for multi-worker launch...
   Cleaning up stale worktrees...
   Switching from feat/policy-validation to main for worktree setup...
```

If this doesn't happen, manually switch:
```bash
git checkout main
czarina launch
```

### Cause 2: Branch Doesn't Exist Yet

**Error:**
```
fatal: invalid reference: feat/gateway-http-sse-transport
```

**Fix:**
Czarina should create branches automatically. Check if `init-embedded-branches.sh` ran:
```
🌿 Some worker branches don't exist yet. Initializing...
✅ Git branches initialized
```

If not, manually create branches:
```bash
git checkout -b feat/gateway-http-sse-transport
git checkout -b feat/gateway-stdio-transport
# ... etc for all workers
git checkout main
```

### Cause 3: Silent Errors (Fixed in v0.4.0)

**Before v0.4.0:**
Errors were suppressed with `2>/dev/null`, making it impossible to debug.

**After v0.4.0:**
You'll see explicit messages:
```
   • Worker 1: gateway-http-sse
      Creating worktree: .czarina/worktrees/gateway-http-sse on branch feat/gateway-http-sse-transport...
      ✅ Worktree created
```

Or if it fails:
```
   • Worker 1: gateway-http-sse
      Creating worktree: .czarina/worktrees/gateway-http-sse on branch feat/gateway-http-sse-transport...
      fatal: 'feat/gateway-http-sse-transport' is already checked out at '/path/to/project'
      ⚠️  Failed to create worktree, using main directory
      Run 'git worktree list' to debug
```

### Cause 4: Stale Worktree References

**Error:**
```
fatal: '.czarina/worktrees/gateway-http-sse' already exists
```

But the directory doesn't actually exist!

**Fix:**
```bash
git worktree prune
czarina launch
```

The launch script now does this automatically, but you can run it manually if needed.

---

## New Debug Output (v0.4.0+)

### Successful Worktree Creation
```
🚀 Launching Czarina Project
   Project: SARK v1.2.0
   Workers: 5

🔄 Preparing repository for multi-worker launch...
   Cleaning up stale worktrees...
   Switching from feat/policy-validation to main for worktree setup...

📱 Creating tmux session: czarina-sark

   • Worker 1: gateway-http-sse
      Creating worktree: .czarina/worktrees/gateway-http-sse on branch feat/gateway-http-sse-transport...
      ✅ Worktree created

   • Worker 2: gateway-stdio
      Creating worktree: .czarina/worktrees/gateway-stdio on branch feat/gateway-stdio-transport...
      ✅ Worktree created (new branch)

   • Worker 3: integration
      ↻ Reusing existing worktree: .czarina/worktrees/integration

   • Worker 4: policy
      ℹ  No branch specified, using main directory

✅ All workers launched!
```

### Failed Worktree Creation
```
   • Worker 1: gateway-http-sse
      Creating worktree: .czarina/worktrees/gateway-http-sse on branch feat/gateway-http-sse-transport...
      fatal: 'feat/gateway-http-sse-transport' is already checked out at '/home/user/project'
      ⚠️  Failed to create worktree, using main directory
      Run 'git worktree list' to debug
```

---

## Verifying Workers Are in Worktrees

### 1. Attach to tmux session
```bash
tmux attach -t czarina-sark
```

### 2. Check each window
Press `Ctrl+B` then `1`, `2`, `3`, etc. to switch windows

### 3. Look for worktree path in header
```
═══════════════════════════════════════════════════════════════
🤖 Worker 1
📋 ID: gateway-http-sse
📝 Role: Gateway HTTP and SSE transport implementation
🔧 Agent: aider
🌿 Branch: feat/gateway-http-sse-transport
📁 Worktree: /home/user/project/.czarina/worktrees/gateway-http-sse  ← Should be worktree!
═══════════════════════════════════════════════════════════════
```

**Problem:** If it shows `/home/user/project` (main directory) instead of worktree path

### 4. Check current directory
Inside the tmux window:
```bash
pwd
# Should show: /home/user/project/.czarina/worktrees/gateway-http-sse
# NOT: /home/user/project
```

---

## Manual Worktree Recovery

If worktrees weren't created, you can fix it manually:

### 1. Kill current session
```bash
czarina closeout
```

### 2. Clean up
```bash
cd /path/to/project
git checkout main
git worktree prune
rm -rf .czarina/worktrees/*
```

### 3. Relaunch
```bash
czarina launch
```

With v0.4.0+, you'll see exactly what's happening and why.

---

## Configuration Check

Make sure your `.czarina/config.json` has branches specified:

```json
{
  "workers": [
    {
      "id": "gateway-http-sse",
      "branch": "feat/gateway-http-sse-transport",  ← Must be specified!
      "agent": "aider",
      "description": "..."
    }
  ]
}
```

If `"branch"` is missing or `null`, worker will use main directory.

---

## Expected Workflow

1. **Launch:**
   ```bash
   czarina launch
   ```

2. **Czarina:**
   - Switches to main branch
   - Prunes stale worktrees
   - Creates worktree for each worker with a branch
   - Starts tmux session
   - Each window cd's into its worktree

3. **Workers:**
   - Each operates in isolated worktree
   - Can commit to their branch without conflicts
   - True parallel development!

---

## Improvements in v0.4.0

- ✅ **Removed `2>/dev/null`** - Errors now visible
- ✅ **Explicit success messages** - "✅ Worktree created"
- ✅ **Failure hints** - "Run 'git worktree list' to debug"
- ✅ **Reuse detection** - "↻ Reusing existing worktree"
- ✅ **Info messages** - "ℹ  No branch specified, using main directory"

---

## Still Having Issues?

1. **Check git version:**
   ```bash
   git --version
   # Worktrees require git 2.5+ (preferably 2.15+)
   ```

2. **Run with verbose output:**
   Look at the tmux launch output carefully - errors are now visible!

3. **Report issue:**
   Include output of:
   ```bash
   git worktree list
   ls -la .czarina/worktrees/
   cat .czarina/config.json
   ```

---

**Version:** 0.4.0
**Last Updated:** 2025-12-09
**Status:** ✅ Debugging Improved
