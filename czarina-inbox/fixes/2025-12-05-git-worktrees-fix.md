# Fix: Git Worktrees for Multi-Agent Parallelism

**Date:** 2025-12-05
**Status:** ✅ Fixed
**Severity:** Critical
**Component:** launch-project.sh

## Problem

When launching multiple workers, all tmux windows ended up on the same git branch despite being assigned different branches in the config. This prevented true multi-agent parallelism.

### Root Cause

The original launcher tried to checkout different branches in each tmux window:
```bash
tmux send-keys -t window1 "git checkout branch-1" C-m
tmux send-keys -t window2 "git checkout branch-2" C-m
```

**Issue:** All windows shared the same git repository working directory. Git only allows ONE branch to be checked out at a time in a given working tree. This created a race condition where the last `git checkout` command won, and all windows ended up on that branch.

### Symptoms

- All workers appeared to be on different branches in the UI
- But `git branch --show-current` showed the same branch in every window
- Workers couldn't work in parallel without conflicts
- The last-launched worker's branch became active everywhere

## Solution

Implemented **git worktrees** - Git's native feature for multiple working directories.

### Implementation

Each worker gets its own isolated worktree:
```
project/
├── .git/                    # Main git directory
├── .czarina/
│   └── worktrees/
│       ├── worker1/         # Isolated workspace on branch-1
│       ├── worker2/         # Isolated workspace on branch-2
│       └── worker3/         # Isolated workspace on branch-3
└── [main codebase]
```

### Code Changes

**launch-project.sh:**
1. Create `.czarina/worktrees/` directory
2. Switch main repo to `main` branch (prevents conflicts)
3. For each worker:
   ```bash
   git worktree add .czarina/worktrees/worker-id branch-name
   ```
4. Each tmux window cd's into its own worktree
5. Auto-prune stale worktrees on launch

**czarina CLI:**
- Add `.czarina/worktrees/` to `.gitignore`

## Value

✅ **True Parallelism**: 11 workers can now code simultaneously
✅ **No Conflicts**: Each worker has isolated filesystem
✅ **Automatic Setup**: Worktrees created on launch
✅ **Clean Shutdown**: Closeout command removes worktrees

## Testing

Verified with 11-worker orchestration:
- All 11 worktrees created successfully
- Each on correct branch
- Workers can commit independently
- No branch conflicts

## Lessons Learned

1. **Git Limitation**: Can't checkout multiple branches in same directory
2. **Worktrees Perfect**: Designed exactly for this use case
3. **Session Naming**: Shortened session names caused `status` command mismatch
4. **Cleanup Important**: Need proper worktree removal on closeout

## Related Files

- `czarina-core/launch-project.sh` - Worktree creation
- `czarina` - .gitignore updates
- `czarina-core/closeout-project.sh` - Worktree cleanup

## Follow-up

- [ ] Update documentation to explain worktrees
- [ ] Add worktree status to dashboard
- [ ] Consider auto-cleanup of abandoned worktrees
- [ ] Fix session name matching in status command

## Metrics

- **Impact**: Enables core multi-agent functionality
- **Effort**: ~2 hours to identify and fix
- **Files Changed**: 2
- **Lines Changed**: +208 -41
