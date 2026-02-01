# Token-Based Planning for AI Development

## Overview

Token-based planning is the foundation of realistic AI development estimation. Unlike calendar-based planning, token budgets reflect actual work effort and account for the inherent unpredictability of AI development.

## Core Principle

**🚨 CRITICAL: All planning and estimates MUST be token-based, NOT calendar-based.**

### Why Tokens, Not Time?

AI development is **fundamentally unpredictable** in calendar time:
- ✅ Claude Code Pro stops without warning
- ✅ Complexity varies wildly between tasks
- ✅ "Just one more thing" syndrome is real
- ✅ Human availability fluctuates
- ✅ Integration issues appear unexpectedly

**Tokens are the only honest measure of effort.**

Tokens represent:
- Actual work performed by AI agents
- Measurable, trackable progress
- Effort independent of calendar time
- Reality-based estimation

## Token Effort Sizes

Use these standard effort classifications:

| Size | Token Range | Example | Typical Use |
|------|-------------|---------|-------------|
| **XS** | <100K | Bug fix, small feature | Quick fixes, minor improvements |
| **S** | 100K-500K | Feature enhancement | Single-file features, refactoring |
| **M** | 500K-2M | New feature | Multi-file features, new components |
| **L** | 2M-4M | Major feature | Complex features, integrations |
| **XL** | 4M-8M | Subsystem | New subsystems, major refactors |
| **XXL** | 8M+ | Version milestone | Complete versions, major releases |

**Example Usage**:
```markdown
**Effort**: M (800K-1.3M tokens)
**Effort**: L (2M-4M tokens)
**Effort**: XL (5M-8M tokens)
```

## Reality Check Multipliers

Adjust base estimates with reality multipliers based on complexity:

**🟢 Smooth Sailing (1.0x)**:
- Well-understood patterns
- Clear, complete requirements
- Existing similar code
- No integration complexity
- All dependencies known

**🟡 Normal Chaos (1.5x)**:
- Standard complexity
- Some unknowns
- Typical integration work
- Dependencies mostly known
- Common patterns

**🟠 Docker Networking (2.5x)**:
- Distributed systems
- Complex integration
- Multiple dependencies
- Infrastructure changes
- Network/timing issues

**🔴 Existential Debugging (4x)**:
- Novel research territory
- No existing patterns
- Completely new domain
- Unknown unknowns
- Experimental work

**Usage Example**:
```markdown
**Effort**: M (800K-1.3M tokens base)
**Reality Check**: 🟡 Normal Chaos (1.5x)
**Adjusted Estimate**: 1.2M-2M tokens
```

## Correct Planning Language

### ✅ Use Token Estimates

```markdown
**Effort**: M (1M-2M tokens)
**Estimated**: 3M-6M tokens with 1.5x reality multiplier
**Progress**: 1.5M / 3M-6M tokens (25-50% complete)
**Actual Spent**: 2.5M tokens (under budget!)
```

### ✅ Use Phase-Based Organization

```markdown
**Phase 1: Foundation** (500K-800K tokens)
- Build core infrastructure
- Create schemas
- Implement base services

**Phase 2: Integration** (300K-500K tokens)
- Connect to existing systems
- API layer
- Integration testing

**Phase 3: Polish** (200K-400K tokens)
- Error handling
- Performance optimization
- Documentation
```

### ✅ Track Progress in Tokens

```markdown
**Progress Summary**:
- Phase 1: 600K tokens spent ✅ COMPLETE
- Phase 2: 250K tokens spent (in progress, 50-80% complete)
- Phase 3: Not started
- **Total**: 850K / 1.5M-2.5M estimated (34-57% complete)
```

## Forbidden Planning Language

### ❌ NEVER Use Calendar Time

```markdown
❌ "This will take 2-3 weeks"
❌ "Week 1: Foundation"
❌ "Week 2: Integration"
❌ "Due date: December 15"
❌ "Timeline: 2 weeks"
❌ "Sprint: November 20-27"
❌ "ETA: Next Tuesday"
❌ "Should be done by Friday"
```

### ❌ NEVER Make Time Promises

```markdown
❌ "We can ship this next week"
❌ "This is a quick 2-day task"
❌ "Estimated completion: 3 weeks from now"
❌ "Delivery: End of month"
```

### ✅ Calendar References (When Allowed)

**ONLY acceptable for past events**:

```markdown
✅ **Completed**: 2025-12-22 (past tense)
✅ **Last Updated**: 2025-12-22 (timestamp)
✅ **Started**: 2025-12-20 (historical record)
```

**NEVER for future predictions**:
```markdown
❌ **Due**: 2025-12-25
❌ **ETA**: 2025-12-30
❌ **Deadline**: 2026-01-05
```

## Implementation Plan Structure

### Standard Header Format

All implementation plans MUST use this structure:

```markdown
# v1.2.0 - Feature Name

**Version**: v1.2.0
**Created**: 2025-12-20
**Status**: Planning / In Progress / Complete
**Effort**: M (800K-1.3M tokens base)
**Reality Check**: 🟡 Normal Chaos (1.5x)
**Adjusted Estimate**: 1.2M-2M tokens
**Theme**: Brief description

## Executive Summary
- **Goal**: What this version accomplishes
- **Why Now**: Motivation for this work
- **Key Insight**: Critical decision or approach

## Phase 1: Foundation (500K-800K tokens)
### 1.1 Component Name
[Implementation details]

### 1.2 Component Name
[Implementation details]

## Phase 2: Integration (400K-600K tokens)
### 2.1 Component Name
[Implementation details]

## Phase 3: Polish (300K-500K tokens)
### 3.1 Testing
### 3.2 Documentation
### 3.3 Optimization

## Success Metrics
- Metric 1
- Metric 2
- Metric 3
```

### Multi-Phase Project Structure

```markdown
## v1.2.0 Authentication System

**Total Effort**: L (2M-4M tokens base)
**Reality Check**: 🟡 Normal Chaos (1.5x)
**Adjusted Estimate**: 3M-6M tokens

### Phase 1: Foundation (1M-1.5M tokens)
- JWT service implementation
- Token validation
- Basic auth flow

### Phase 2: Integration (800K-1.2M tokens)
- API endpoints
- Middleware integration
- Session management

### Phase 3: Testing & Polish (500K-800K tokens)
- Comprehensive tests
- Error handling
- Rate limiting
- Documentation

### Progress Summary
- Phase 1: 1.2M tokens spent ✅ COMPLETE
- Phase 2: 400K tokens spent (in progress)
- Phase 3: Not started
- **Total**: 1.6M / 3M-6M estimated (27% complete)
```

## Progress Tracking

### Progress Update Format

```markdown
**Status Update** (2025-12-22):
- **Completed**: 2.5M tokens
- **Remaining**: 500K-3.5M tokens estimated
- **Current**: Phase 2 in progress
- **Status**: On track / 20% under budget / 15% over budget
```

### Token Efficiency Reporting

```markdown
**Efficiency Achievement**:
- **Estimated**: 3M-6M tokens
- **Actual**: 2.8M tokens
- **Result**: 7% under midpoint estimate
- **Why**: Clear requirements, no major rewrites
```

**Real Example from thesymposium**:
```markdown
**v0.4.15 Thread Detection**:
- **Estimated**: 500K-800K tokens
- **Actual**: ~200K tokens
- **Result**: 75% under budget!
- **Why**: Simpler than expected, good pattern reuse
```

## Completion Reporting

### Completion Document Structure

```markdown
# v1.2.0 - Authentication System COMPLETE ✅

**Completed**: 2025-12-22
**Estimated**: 3M-6M tokens
**Actual**: 2.8M tokens
**Efficiency**: On budget (47% of upper estimate)

## What Was Delivered
- JWT authentication system
- Login/logout endpoints
- Token refresh mechanism
- Comprehensive test suite (95% coverage)

## Deliverables
### 1. JWT Service ✅
- Token generation and validation
- Expiry handling
- Refresh token support
- File: `src/auth/jwt_service.py` (~300 lines)

### 2. API Endpoints ✅
- Login endpoint with rate limiting
- Logout endpoint
- Token refresh endpoint
- Files: `src/api/auth_routes.py` (~200 lines)

### 3. Tests ✅
- 23 unit tests
- 8 integration tests
- 95% code coverage
- File: `tests/test_auth.py` (~400 lines)

## Token Breakdown
- Phase 1 (Foundation): 1.2M tokens
- Phase 2 (Integration): 900K tokens
- Phase 3 (Polish): 700K tokens
- **Total**: 2.8M tokens

## What Went Well
- Clear requirements from planning phase
- Good pattern reuse from existing code
- Test-first approach caught issues early

## What Didn't Go Well
- Rate limiting took longer than expected (integration complexity)
- Had to refactor token storage approach mid-phase

## Lessons Learned
- Always spike integrations before estimating
- Reality multiplier of 1.5x was accurate for this type of work
- Token-first estimation helped manage scope
```

## Real-World Examples

### Example 1: Small Feature (S)

```markdown
## Add Password Reset Endpoint

**Effort**: S (200K-400K tokens)
**Reality Check**: 🟢 Smooth Sailing (1.0x)
**Adjusted**: 200K-400K tokens
**Actual**: 180K tokens
**Result**: 10% under budget
```

### Example 2: Medium Feature (M)

```markdown
## JWT Authentication System

**Effort**: M (800K-1.3M tokens)
**Reality Check**: 🟡 Normal Chaos (1.5x)
**Adjusted**: 1.2M-2M tokens
**Actual**: 2.8M tokens (with all 3 phases)
**Result**: On budget (midpoint estimate)
```

### Example 3: Large Project (XL)

```markdown
## v0.4.15 Thread Detection (Full Version)

**Effort**: M (800K-1.3M tokens)
**Reality Check**: 🟡 Normal Chaos (1.5x)
**Adjusted**: 1.2M-2M tokens

**Phase 1**: Thread Detection (300K-500K)
- **Actual**: ~150K tokens
- **Efficiency**: 50-70% under budget

**Phase 2**: MCP Integration (300K-500K)
- **Status**: DEFERRED to v0.4.17
- **Reason**: Hardware limitations discovered

**Total**: ~200K tokens spent
**Result**: 75% under original budget (Phase 2 deferred)
```

## Token Budget Breakdown

### Per-Component Budgeting

```markdown
### Phase 1: Foundation (500K-800K tokens)

**Component Breakdown**:
- Schema design: 50K-80K tokens
- Service implementation: 300K-500K tokens
- API layer: 80K-120K tokens
- Unit tests: 70K-100K tokens

**Total**: 500K-800K tokens
```

### Tracking Component Progress

```markdown
**Phase 1 Progress**:
- [x] Schema design: 60K tokens (complete)
- [x] Service implementation: 420K tokens (complete)
- [⏳] API layer: 90K / 80K-120K tokens (in progress)
- [ ] Unit tests: Not started

**Phase Total**: 570K / 500K-800K tokens (71-114% complete)
```

## Anti-Patterns (What NOT to Do)

### ❌ Don't: Use Time-Based Estimates

```markdown
# BAD
## Week 1: Foundation
- Day 1-2: Setup
- Day 3-4: Implementation
- Day 5: Testing

Due Date: December 25, 2025
```

**Why**: Time-based estimates ignore AI development realities and create false expectations.

### ❌ Don't: Estimate Without Reality Check

```markdown
# BAD
**Effort**: M (1M-2M tokens)
# (No reality check multiplier applied)
```

**Why**: Base estimates rarely account for real-world complexity. Always apply reality multiplier.

### ❌ Don't: Report Progress Without Token Counts

```markdown
# BAD
**Status**: About 50% done
**Progress**: Making good progress
```

**Why**: Vague progress reporting. Use concrete token counts.

### ❌ Don't: Skip Token Efficiency Reporting

```markdown
# BAD
# Work complete, no efficiency report
```

**Why**: Lessons learned from token efficiency inform future estimates.

## Best Practices

### ✅ Always Include Reality Multiplier

```markdown
# GOOD
**Effort**: M (800K-1.3M tokens)
**Reality Check**: 🟡 Normal Chaos (1.5x)
**Adjusted Estimate**: 1.2M-2M tokens
**Reason**: Integration with existing auth system, some unknowns
```

### ✅ Break Down Large Estimates

```markdown
# GOOD
**Total**: 3M-6M tokens

### Phase 1: 1M-1.5M tokens
- Component A: 400K-600K
- Component B: 400K-600K
- Testing: 200K-300K

### Phase 2: 800K-1.2M tokens
[Breakdown]

### Phase 3: 500K-800K tokens
[Breakdown]
```

### ✅ Track Actual vs. Estimated

```markdown
# GOOD
**Phase 1 Complete**:
- **Estimated**: 1M-1.5M tokens
- **Actual**: 1.2M tokens
- **Efficiency**: On budget (80% of upper estimate)
- **Lessons**: Existing patterns helped, integration was standard complexity
```

### ✅ Document Why Estimates Were Off

```markdown
# GOOD
**Phase 2 Over Budget**:
- **Estimated**: 800K-1.2M tokens
- **Actual**: 1.5M tokens
- **Reason**: Discovered additional integration requirements mid-phase
- **Lesson**: Next time, spike integrations before estimating
```

## Integration with Other Workflows

Token planning integrates with:

- **`PHASE_DEVELOPMENT.md`** - Phases have token budgets
- **`DOCUMENTATION_WORKFLOW.md`** - Track token usage in docs
- **`CLOSEOUT_PROCESS.md`** - Report token efficiency
- **`PR_REQUIREMENTS.md`** - Include token usage in PRs

## Checklist for AI Agents

### Before Creating Implementation Plan
- [ ] Effort estimated in tokens (XS/S/M/L/XL/XXL)
- [ ] Reality check multiplier selected and justified
- [ ] Organized into phases (not weeks/days)
- [ ] Each phase has token estimate
- [ ] No calendar deadlines mentioned
- [ ] Progress trackable in tokens
- [ ] Success criteria defined (not time-based)
- [ ] Component-level breakdown provided

### During Implementation
- [ ] Track tokens spent per phase
- [ ] Update progress in token terms
- [ ] Note when estimates are off (over/under)
- [ ] Document why estimates were inaccurate

### At Completion
- [ ] Report actual tokens vs. estimated
- [ ] Calculate efficiency percentage
- [ ] Document what went well (token-wise)
- [ ] Document what went poorly (token-wise)
- [ ] Extract lessons for future estimates

## Why This Matters

### Token Planning is Honest

- ✅ Reflects actual effort invested
- ✅ Accounts for unpredictability
- ✅ Measures what we can control
- ✅ Improves with data over time
- ✅ No false expectations

### Calendar Planning is Dishonest

- ❌ Assumes constant productivity
- ❌ Ignores Claude Code stops
- ❌ Creates false deadlines
- ❌ Leads to missed "commitments"
- ❌ Doesn't improve estimates

### Phases are Flexible

- ✅ Can be paused/resumed
- ✅ No artificial time pressure
- ✅ Progress is measurable
- ✅ Completion is clear
- ✅ Scope can adjust

## Summary

### Core Rules (Must Follow)

1. ✅ **Always use token estimates** - Never time estimates
2. ✅ **Apply reality multipliers** - Account for complexity
3. ✅ **Track actual tokens** - Compare to estimates
4. ✅ **Report efficiency** - Learn from variances
5. ✅ **Use phases, not sprints** - Objective-based, not calendar-based
6. ✅ **No calendar promises** - Only past dates allowed

### Token Effort Sizes

- **XS**: <100K | **S**: 100K-500K | **M**: 500K-2M
- **L**: 2M-4M | **XL**: 4M-8M | **XXL**: 8M+

### Reality Multipliers

- 🟢 **1.0x**: Smooth Sailing
- 🟡 **1.5x**: Normal Chaos
- 🟠 **2.5x**: Docker Networking
- 🔴 **4x**: Existential Debugging

### Remember

**"Tokens are honest. Calendars are wishful thinking."**

Plan with tokens. Track with tokens. Report with tokens. Learn from tokens.

---

**Source**: Extracted from [thesymposium](https://gitlab.henrynet.ca/symposium/thesymposium) `.kilocode/rules/TOKEN_BASED_PLANNING.md` and real project completion data.

**See Also**:
- `PHASE_DEVELOPMENT.md` - Phase-based development workflow
- `DOCUMENTATION_WORKFLOW.md` - Documentation standards
- `CLOSEOUT_PROCESS.md` - Token efficiency reporting
