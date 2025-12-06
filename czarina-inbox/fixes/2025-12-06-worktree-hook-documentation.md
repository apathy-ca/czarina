# Fix: Update Documentation for Worktree-Based SessionStart Hooks

**Date:** 2025-12-06
**Status:** ✅ Documentation Update Needed
**Severity:** Medium (Documentation Drift)
**Component:** docs/BRANCH_BASED_WORKER_LOADING.md
**Discovered by:** The Symposium project (11-worker orchestration)

## What I Fixed (in The Symposium)

Updated SessionStart hook configuration to work correctly with git worktrees after discovering the documentation was outdated.

## Problem

After Czarina migrated to git worktrees (2025-12-05), the documentation still references the old branch-switching approach with `.czarina/load-worker-by-branch.sh`. This caused confusion:

1. **Docs say:** Put SessionStart hook at `.czarina/load-worker-by-branch.sh`
2. **Reality:** With worktrees, each worker has separate directory - hook should be in main repo only
3. **Result:** Script missing error on session start

## Why This Matters

The git worktree architecture changes where hooks should be placed:

### Old Approach (Branch-Switching)
- Single directory, switch branches
- Hook at `.czarina/load-worker-by-branch.sh` detects current branch
- Loads different prompts based on branch

### New Approach (Worktrees) ✅ Correct
- Multiple directories (main repo + worktrees)
- Hook in **main repo only** at `.claude/load-rules.sh`
- Workers DON'T need hooks (use `.czarina/.worker-init` instead)

## Correct Setup for Worktrees

### Main Repository (Czar)
```
.claude/
├── settings.local.json    # SessionStart hook config
├── load-rules.sh          # Loads Czar role + development rules
└── czar-rules.md          # Czar role definition
```

**Hook config:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "./.claude/load-rules.sh"
          }
        ]
      }
    ]
  }
}
```

**load-rules.sh:**
```bash
#!/bin/bash
CLAUDE_DIR=".claude"
RULES_DIR=".kilocode/rules"

# Load Czar role
cat "$CLAUDE_DIR/czar-rules.md"

# Load all development rules
for rule_file in "$RULES_DIR"/*.md; do
    cat "$rule_file"
done
```

### Worker Worktrees
```
.czarina/worktrees/worker-1/
├── .kilocode/              # Shared from main repo via worktree
│   └── rules/              # Workers get these automatically
└── [No .claude/ directory needed!]
```

**Workers initialize via:**
```bash
./.czarina/.worker-init <worker-id>
```

## Architecture Benefits

✅ **Clean Separation:**
- Czar = `.claude/` (hooks + role)
- Workers = `.czarina/workers/` (role definitions)
- Shared = `.kilocode/rules/` (development rules for everyone)

✅ **No Duplication:**
- Workers share rules via git worktree (not copies)
- No need for separate hooks in each worktree

✅ **No Confusion:**
- Czar has hooks, workers don't
- Workers can't accidentally load Czar rules

## Changes Made in The Symposium

1. **Removed:** `.czarina/load-worker-by-branch.sh` (wrong location)
2. **Created:** `.claude/load-rules.sh` (correct location)
3. **Updated:** `.claude/settings.local.json` to point to correct script
4. **Cleaned:** Removed incorrect `.claude/czar-rules.md` from all 11 worker worktrees

## Testing Evidence

Tested with The Symposium (11 workers):
- ✅ Main repo SessionStart hook loads correctly
- ✅ Workers share `.kilocode/rules/` from main repo
- ✅ No duplicate files in worker worktrees
- ✅ No errors on session start

## Documentation Updates Needed

### 1. docs/BRANCH_BASED_WORKER_LOADING.md
- [ ] Update title to "Worker Isolation with Git Worktrees"
- [ ] Remove `.czarina/load-worker-by-branch.sh` references
- [ ] Document correct hook location: `.claude/load-rules.sh`
- [ ] Show proper directory structure for worktrees
- [ ] Clarify: "Workers DON'T need hooks"

### 2. New Section Needed
Add explanation of:
- Why hook goes in main repo only
- How workers share `.kilocode/rules/` via worktree
- When to use `.worker-init` vs hooks

### 3. Template Updates
The `embed` command template should create:
- `.claude/load-rules.sh` (NOT `.czarina/load-worker-by-branch.sh`)
- Proper hook config in `.claude/settings.local.json`

## Follow-up Item

This completes the TODO from `czarina-inbox/fixes/2025-12-05-git-worktrees-fix.md`:
- [x] Update documentation to explain worktrees ← This addresses it

## Related Files

- `docs/BRANCH_BASED_WORKER_LOADING.md` - Needs update
- `czarina-core/templates/` - May need new templates
- `.czarina/.worker-init` - Current worker initialization (works correctly)

## Value

📚 **Updated docs prevent:**
- Confusion about hook placement
- Missing script errors
- Duplicate rule files in worktrees
- Incorrect architecture

🎯 **Developers get:**
- Clear worktree setup instructions
- Correct hook configuration
- Understanding of Czar vs Worker separation

## Example Project

See **The Symposium** for working reference:
- Repository: `/home/theseus/thesymposium`
- 11 workers in git worktrees
- Clean hook setup
- No errors, works perfectly

---

**Status:** Ready for documentation PR to Czarina repository
