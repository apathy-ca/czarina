# Enhancement File Examples

This directory contains example enhancement files demonstrating best practices for documenting work items in the Czarina hopper system.

## Overview

These examples show how to write well-structured enhancement files with proper metadata for optimal priority queue sorting and Czar decision-making.

## Examples Included

### 1. High Priority, Small Complexity: Dashboard Refresh Bug
**File:** `example-1-high-priority-small.md`

**Characteristics:**
- **Priority:** High (critical bug affecting UX)
- **Complexity:** Small (2-4 hours, single file change)
- **Tags:** bugfix, dashboard, ux
- **Sort Score:** 29 (highest priority)

**When to use this pattern:**
- Critical bugs blocking users
- Quick wins that provide immediate value
- Hot fixes needed in current phase
- Issues discovered during dogfooding

**Czar behavior:**
- Likely to **auto-include** in current phase
- Assigned to idle workers immediately
- High urgency, low effort = quick win

### 2. Medium Priority, Medium Complexity: Worker Status Icons
**File:** `example-2-medium-priority-medium.md`

**Characteristics:**
- **Priority:** Medium (improves UX, not critical)
- **Complexity:** Medium (1-2 days, multiple files)
- **Tags:** enhancement, ux, dashboard
- **Sort Score:** 18 (middle priority)

**When to use this pattern:**
- Feature enhancements
- UX improvements
- Non-critical functionality
- Incremental improvements

**Czar behavior:**
- May **ask human** for inclusion decision
- Consider phase progress (early = include, late = defer)
- Balance with worker availability

### 3. Low Priority, Large Complexity: Multi-Phase Planning
**File:** `example-3-low-priority-large.md`

**Characteristics:**
- **Priority:** Low (nice-to-have, future feature)
- **Complexity:** Large (1-2 weeks, architectural change)
- **Tags:** major-feature, future, architecture
- **Sort Score:** 7 (lowest priority)

**When to use this pattern:**
- Major new features
- Architectural changes
- Long-term roadmap items
- Research-heavy initiatives

**Czar behavior:**
- Likely to **auto-defer** to future phase
- Requires dedicated planning
- Not appropriate for opportunistic work

## Priority Queue Scoring

The hopper system sorts items by score:

```
Score = (Priority × 10) - Complexity

Priority Values:
- High: 3
- Medium: 2
- Low: 1

Complexity Values:
- Small: 1
- Medium: 2
- Large: 3
```

**Example Scores:**
- High + Small: (3 × 10) - 1 = **29** ← Highest priority
- High + Medium: (3 × 10) - 2 = **28**
- High + Large: (3 × 10) - 3 = **27**
- Medium + Small: (2 × 10) - 1 = **19**
- Medium + Medium: (2 × 10) - 2 = **18** ← Middle priority
- Medium + Large: (2 × 10) - 3 = **17**
- Low + Small: (1 × 10) - 1 = **9**
- Low + Medium: (1 × 10) - 2 = **8**
- Low + Large: (1 × 10) - 3 = **7** ← Lowest priority

## Metadata Fields Guide

### Required Fields

**Priority:** High | Medium | Low
- **High:** Critical bugs, blockers, urgent needs
- **Medium:** Important improvements, standard features
- **Low:** Nice-to-haves, future enhancements

**Complexity:** Small | Medium | Large
- **Small:** < 1 day, single file, minimal risk
- **Medium:** 1-3 days, multiple files, some design
- **Large:** > 3 days, architectural, significant risk

### Recommended Fields

**Tags:** comma-separated keywords
- Type: `bugfix`, `enhancement`, `feature`, `refactor`
- Area: `dashboard`, `ux`, `cli`, `core`, `docs`
- Scope: `future`, `breaking-change`, `quick-win`

**Suggested Phase:** Version number
- Current phase: `Current`, `v0.6.0`
- Future phases: `v0.7.0`, `v1.0.0`
- Signals deference preference to Czar

**Estimate:** Time estimate
- Helps with capacity planning
- Format: `2-4 hours`, `1-2 days`, `1-2 weeks`

## Enhancement File Structure

```markdown
# Enhancement #XXX: Clear, Concise Title

**Priority:** High | Medium | Low
**Complexity:** Small | Medium | Large
**Tags:** keyword1, keyword2, keyword3
**Suggested Phase:** vX.Y.Z
**Estimate:** time estimate

## Description
[One paragraph summary of the enhancement]

## Problem
[What problem does this solve?]
- Current behavior
- Pain points
- Impact

## Solution
[How to implement this]
- Approach
- Code examples
- Files affected

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Notes
[Additional context, considerations, etc.]

## Dependencies (if any)
- Enhancement #XXX
- Feature Y

## Testing (if applicable)
[How to test this enhancement]
```

## Using These Examples

### Copy as Templates

```bash
# Copy example as starting point
cp .czarina/hopper/examples/example-1-high-priority-small.md \
   .czarina/hopper/my-enhancement.md

# Edit with your content
vim .czarina/hopper/my-enhancement.md
```

### Test Hopper Commands

```bash
# Add examples to hopper
czarina hopper add example-1-high-priority-small.md

# View sorted by priority
czarina hopper list
# Output shows High priority items first:
# [1] 🔴 example-1-high-priority-small.md
# [2] 🟡 example-2-medium-priority-medium.md
# [3] 🟢 example-3-low-priority-large.md

# Pull into phase (if phase exists)
czarina hopper pull example-1-high-priority-small.md --to-phase current

# Assign to worker
czarina hopper assign worker-1 example-1-high-priority-small.md

# Defer back to backlog
czarina hopper defer example-1-high-priority-small.md
```

## Best Practices

### 1. Be Specific with Priority
- **Don't:** Mark everything as High priority
- **Do:** Reserve High for truly urgent/critical items

### 2. Estimate Complexity Accurately
- **Don't:** Underestimate complexity to game the queue
- **Do:** Be realistic about effort required

### 3. Use Tags Effectively
- **Don't:** Use vague tags like "improvement", "update"
- **Do:** Use specific tags: "bugfix", "dashboard", "ux"

### 4. Include Acceptance Criteria
- **Don't:** Leave acceptance criteria vague
- **Do:** Write clear, testable criteria

### 5. Document Dependencies
- **Don't:** Hide dependencies in description
- **Do:** Explicitly list dependencies in dedicated section

### 6. Write for Future You
- **Don't:** Assume you'll remember context
- **Do:** Document problem, solution, and reasoning clearly

## Common Patterns

### Quick Win (High + Small)
- Critical bug fixes
- Simple UX improvements
- Documentation updates
- Configuration changes

### Standard Enhancement (Medium + Medium)
- Feature additions
- UX improvements
- Performance optimizations
- Refactoring

### Strategic Initiative (Low + Large)
- Major features
- Architectural changes
- Infrastructure upgrades
- Research projects

## FAQ

**Q: Can I have High priority + Large complexity?**
A: Yes! Some critical features are both urgent and complex. Examples: security fixes, critical architecture changes.

**Q: Should I create enhancement files for every task?**
A: Create enhancement files for work that:
- May span multiple sessions
- Needs prioritization
- Could be deferred
- Requires documentation

For trivial tasks (typo fixes, etc.), just do them directly.

**Q: How do I know if Czar will auto-include or auto-defer?**
A: Generally:
- High + Small = auto-include (if worker idle)
- Low + Large = auto-defer
- Medium + Medium = ask human
- See docs/HOPPER.md for full decision logic

**Q: Can I change priority after creating the file?**
A: Yes! Edit the file and update the Priority field. The hopper list will re-sort automatically.

## See Also

- [Hopper System Documentation](../../docs/HOPPER.md)
- [Enhancement #14 Specification](/tmp/enhancement_14.md)
- [Czarina Development Patterns](../../czarina-core/patterns/CZARINA_PATTERNS.md)
