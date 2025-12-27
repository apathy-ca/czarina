# Enhancement #102: Worker Status Icons

**Priority:** Medium
**Complexity:** Medium
**Tags:** enhancement, ux, dashboard
**Suggested Phase:** v0.7.0
**Estimate:** 1-2 days

## Description

Add visual status icons to workers in the dashboard and status commands to make it easier to quickly identify worker states at a glance.

## Problem

**Current behavior:**
- Worker status shown as text: "working", "idle", "blocked"
- Requires reading text to understand state
- Not visually scannable in large orchestrations
- Harder to spot issues quickly

**Impact:**
- Slower issue identification
- Cognitive overhead when monitoring many workers
- Less professional appearance
- Accessibility concerns (color-blind users rely on text)

## Solution

Add status icons to worker displays:

**Status Icons:**
- 🟢 Idle - Worker available for assignment
- 🔵 Working - Worker actively executing tasks
- 🔴 Blocked - Worker waiting on dependencies
- ⚠️ Warning - Worker encountered non-fatal issues
- ❌ Error - Worker failed with errors
- ⏸️ Paused - Worker manually paused by user

**Implementation:**
```python
# In dashboard.py
STATUS_ICONS = {
    'idle': '🟢',
    'working': '🔵',
    'blocked': '🔴',
    'warning': '⚠️',
    'error': '❌',
    'paused': '⏸️'
}

def format_worker_status(worker):
    icon = STATUS_ICONS.get(worker.status, '❓')
    return f"{icon} {worker.id} - {worker.status}"
```

**Affected Files:**
- `czarina-core/dashboard.py` - Add icons to dashboard
- `czarina-core/czar.sh` - Add icons to status reports
- `czarina` - Add icons to `czarina status` command

## Acceptance Criteria

- [ ] Status icons appear in dashboard (all views)
- [ ] Status icons appear in `czarina status` output
- [ ] Icons appear in Czar status reports
- [ ] All 6 status states have unique icons
- [ ] Icons render correctly in both terminal and browser
- [ ] Accessibility: Text status still present (icon + text)
- [ ] Updated documentation shows icon meanings

## Notes

- Medium priority - improves UX but not critical
- Medium complexity - touches multiple files, needs consistency
- Consider accessibility in implementation
- Icons should enhance, not replace text labels

## Dependencies

- None (standalone enhancement)

## Future Enhancements

- Custom icon themes
- Configurable icon sets
- Animation for state transitions
- Color customization for accessibility

## Testing

```bash
# Test cases
1. Launch project with multiple workers
2. Verify each status state shows correct icon:
   - Start worker (🔵 working)
   - Complete work (🟢 idle)
   - Block on dependency (🔴 blocked)
   - Trigger error (❌ error)
3. Check dashboard, status command, and Czar reports
4. Verify text labels still present for accessibility
```
