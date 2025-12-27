# Enhancement #101: Fix Dashboard Refresh Bug

**Priority:** High
**Complexity:** Small
**Tags:** bugfix, dashboard, ux
**Suggested Phase:** Current
**Estimate:** 2-4 hours

## Description

The dashboard does not automatically refresh when worker status changes. Users must manually refresh the browser to see updated worker status, which creates a poor user experience during active orchestration.

## Problem

**Current behavior:**
- Dashboard shows static worker status
- No automatic updates when workers change state
- Users miss important status changes
- Manual refresh required every few minutes

**Impact:**
- Poor user experience
- Missed notifications about worker issues
- Reduced visibility into orchestration progress

## Solution

Add a WebSocket connection or polling mechanism to auto-refresh dashboard:

**Option 1: Polling (simpler)**
```python
# Add to dashboard.py
def auto_refresh():
    while True:
        update_worker_status()
        time.sleep(5)  # Refresh every 5 seconds
```

**Option 2: WebSocket (better)**
- Implement WebSocket endpoint in dashboard
- Push updates when worker status changes
- More efficient than polling

**Recommendation:** Start with polling (simpler), migrate to WebSocket in future phase.

## Acceptance Criteria

- [ ] Dashboard updates worker status automatically every 5 seconds
- [ ] No manual refresh required
- [ ] Minimal CPU/network overhead
- [ ] Works in both terminal and browser dashboards
- [ ] Graceful fallback if refresh fails

## Notes

- This is a high-priority, small-complexity enhancement
- Should be pulled into current phase if workers are idle
- Addresses real user pain point discovered during dogfooding
- Quick win that improves UX significantly

## Testing

```bash
# Manual test
1. Launch czarina project
2. Open dashboard
3. Change worker status (start/stop worker)
4. Verify dashboard updates within 5 seconds without manual refresh
```
