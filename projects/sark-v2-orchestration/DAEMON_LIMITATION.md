# Czar Daemon Limitation - Claude Code Approvals

## Issue Discovered

**Problem:** Claude Code's approval prompts do NOT respond to `tmux send-keys` commands.

**Testing:** 
- ✅ Works: Regular bash/shell prompts via tmux
- ❌ Fails: Claude Code approval UI prompts

**Impact:** The autonomous daemon cannot fully approve Claude Code workers without human intervention.

---

## Root Cause

Claude Code runs its own UI layer that intercepts keyboard input before tmux can inject keys. The approval prompts like:

```
Do you want to proceed?
❯ 1. Yes
  2. No, and tell Claude what to do differently
```

...are rendered by Claude Code's interface, not the shell, so `tmux send-keys` commands are ignored.

---

## Workarounds

### Option 1: Manual Approval (Current)
**Human approves all workers periodically**
- Check workers every 30-60 minutes
- Approve any pending prompts manually
- Daemon logs show which windows need attention

**Pros:** Simple, works immediately  
**Cons:** Not fully autonomous, human is bottleneck

### Option 2: Pre-Approved Mode
**Configure Claude Code to auto-approve for worker sessions**
- Check if Claude Code has "auto-approve" or "headless" mode
- Configure workers to run with minimal prompts
- Set up trusted directories in advance

**Pros:** True autonomy once configured  
**Cons:** Requires Claude Code configuration changes

### Option 3: Direct File Operations
**Workers write files directly instead of using Edit tool**
- Use Write tool (which may have fewer prompts)
- Or bypass Claude Code tools entirely
- Workers commit directly via git

**Pros:** Avoids approval prompts  
**Cons:** Loses Claude Code safety features

### Option 4: API/Programmatic Control
**If Claude Code exposes API for approvals**
- Use Claude Code CLI/API instead of tmux
- Programmatically approve via API calls
- Daemon calls API instead of send-keys

**Pros:** True automation  
**Cons:** Requires Claude Code API support

---

## Current Recommendation

**For Now: Hybrid Approach**

1. **Daemon handles what it can:**
   - Command approvals (bash, git, etc.)
   - Y/N prompts in shell
   - File system operations

2. **Human handles Claude Code prompts:**
   - Check workers every 30-60 min
   - Approve Claude Code prompts manually
   - Workers can work for extended periods between approvals

3. **Optimization:**
   - Pre-approve common directories
   - Configure Claude Code settings for less prompting
   - Workers batch operations to minimize approval requests

**Result:** ~70-80% autonomy (vs 100% goal)

---

## Long-Term Solution

**Work with Claude Code team to:**
1. Add auto-approve mode for trusted scenarios
2. Add headless/batch mode for orchestration
3. Add programmatic approval API
4. Add configuration for trusted directories/operations

**Or:**
- Build orchestration layer that doesn't rely on Claude Code UI
- Use Claude API directly for workers
- Custom orchestration framework

---

## Impact on SARK Sessions

**Session 2 & 3 Experience:**
- Daemon handled ~30+ approval attempts
- Most were ignored (Claude Code UI)
- Human had to approve manually
- Workers still productive, just not fully autonomous

**Actual Autonomy Achieved:**
- Target: 90-100%
- Reality: 70-80% (with periodic human approvals)
- Still much better than 0% (fully manual)

---

## Updated Files

The daemon scripts still work for:
- Shell command approvals
- Git operations
- File system checks
- Y/N prompts in bash

They just can't handle Claude Code's own UI prompts.

---

## Recommendation for Czarina Integration

**Document this limitation clearly:**
- Daemon provides ~70-80% autonomy
- Human approval needed for Claude Code prompts
- Check workers every 30-60 minutes
- Still valuable for reducing human load

**Consider alternative approaches:**
- API-based orchestration (no UI)
- Pre-configured trusted mode
- Different worker framework (non-Claude Code)

---

**Status:** Known limitation, workarounds available  
**Severity:** Medium (reduces autonomy but doesn't block)  
**Resolution:** Requires Claude Code feature addition or alternative approach

---

*Discovered: 2025-11-29 during Session 3*  
*Impact: Daemon cannot fully automate Claude Code worker approvals*
