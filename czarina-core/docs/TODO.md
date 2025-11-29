# Czarina - TODO List

This document tracks improvements and fixes needed for the Czarina orchestration framework.

## High Priority

### Fix Tmux Window Numbering for Human Readability
**Issue:** Currently, worker windows are numbered starting from 0, which is confusing for humans:
- Window 0: engineer1
- Window 1: engineer2
- Window 2: engineer3
- etc.

**Expected Behavior:** Engineers should map to their human-intuitive numbers:
- Window 0: monitoring/dashboard/control panel
- Window 1: engineer1
- Window 2: engineer2
- Window 3: engineer3
- etc.

**Impact:** Low technical impact, high human usability impact. Users expect Ctrl+b then "1" to go to Engineer 1, not Engineer 2.

**Files to Update:**
- `projects/sark-v2-orchestration/launch-session.sh` - Main launch script
- `czarina-core/launch-claude-workers.sh` - If still in use
- Any other launch scripts that create tmux windows

**Solution:**
1. Create window 0 as a "control" or "monitor" window first
2. Then create engineer1 on window 1, engineer2 on window 2, etc.
3. Alternative: Create monitoring/dashboard window, then use `tmux move-window` to reorder

**Example Fix:**
```bash
# Create session with monitoring window first (window 0)
tmux new-session -d -s "$SESSION_NAME" -n "monitor" -c "$SARK_DIR"

# Set up monitoring/control panel on window 0
tmux send-keys -t "$SESSION_NAME:monitor" "# Control Panel / Monitoring" C-m

# Now create engineer windows starting at 1
tmux new-window -t "$SESSION_NAME:1" -n "engineer1" -c "$SARK_DIR"
# engineer1 setup...

tmux new-window -t "$SESSION_NAME:2" -n "engineer2" -c "$SARK_DIR"
# engineer2 setup...
# etc.
```

**Assigned To:** _Unassigned_
**Priority:** Medium
**Effort:** 30 minutes

---

## Medium Priority

### Investigate .claudeignore Not Auto-Approving File Access
**Issue:** `.claudeignore` file with `**/*` pattern in `/home/jhenry/Source/GRID/.claudeignore` is not preventing permission prompts in all cases.

**Observed Behavior:**
- `.claudeignore` exists with pattern `**/*` to auto-approve all operations under GRID
- Claude Code still asks for permission when:
  - Launched with a file argument: `claude /path/to/file.md`
  - Trying to read from subdirectories like `sark-v2/`
- This happens even though operations are clearly under the GRID directory

**Expected Behavior:**
- All file reads, tool use, and operations under `/home/jhenry/Source/GRID/` should be auto-approved
- No permission prompts should appear for any GRID subdirectory access

**Impact:**
- User must manually approve permissions when launching workers/Czar
- Breaks automation for fully autonomous orchestration
- Reduces confidence in "hands-off" operation

**Possible Causes:**
1. `.claudeignore` pattern matching may not work as expected
2. File argument reads (`claude file.md`) might bypass `.claudeignore`
3. Claude Code may have different permission scopes (initial load vs. runtime)
4. Path resolution issues (relative vs. absolute paths)

**Investigation Steps:**
1. Test different `.claudeignore` patterns:
   - `/home/jhenry/Source/GRID/**/*`
   - `*`
   - Explicit directory listings
2. Check if `.claudeignore` applies to:
   - Initial file loads (claude file.md)
   - Runtime tool use (Bash, Read, Edit)
   - Both scenarios
3. Review Claude Code documentation for `.claudeignore` behavior
4. Test with absolute vs. relative paths

**Workaround:**
- Manually select "Yes, allow reading from X during this session" when prompted
- Accept that some manual intervention is needed at launch time

**Assigned To:** _Unassigned_
**Priority:** Medium
**Effort:** 1-2 hours investigation + potential bug report

_(Add future items here)_

---

## Low Priority

_(Add future items here)_

---

## Completed

_(Move completed items here with completion date)_

---

## Notes for Contributors

- This TODO list is for framework improvements, not project-specific tasks
- Please update the file when you complete items (move to "Completed" section)
- Add new items in the appropriate priority section
- Include enough context for someone unfamiliar with the issue to understand and fix it
