# Phase-Based Development Workflow

## Overview

Phase-based development organizes work into logical, sequential phases rather than calendar-based sprints. This approach aligns with token-based planning and allows flexible, pausable development that adapts to AI agent capabilities.

## Core Principle

**Work is organized into PHASES (not weeks/sprints) with token budgets (not time estimates).**

This matches the reality of AI development: unpredictable in calendar time, but measurable in token consumption.

## What is a Phase?

A **phase** is a logical grouping of work that:
- Accomplishes a specific objective
- Can be completed and tested independently
- Has a defined token budget
- Can be paused and resumed without time pressure
- Delivers incremental value

**Phases are NOT**:
- ❌ Calendar-based ("Week 1", "Sprint 3")
- ❌ Time-boxed ("2-3 weeks")
- ❌ Deadline-driven ("Due December 15")

**Phases ARE**:
- ✅ Objective-based ("Foundation", "Integration", "Polish")
- ✅ Token-budgeted ("500K-800K tokens")
- ✅ Deliverable-focused ("Working auth system")
- ✅ Pausable/resumable ("Complete when done")

## Phase Structure

### Typical Version Structure

A version is broken into multiple phases:

```
v1.2.0 - Authentication System (Total: 2M-3M tokens)
├── Phase 1: Foundation (500K-800K tokens)
│   ├── JWT service implementation
│   ├── Token validation
│   └── Basic authentication flow
│
├── Phase 2: Integration (400K-600K tokens)
│   ├── Login/logout endpoints
│   ├── Middleware integration
│   └── Session management
│
└── Phase 3: Polish (300K-500K tokens)
    ├── Error handling
    ├── Rate limiting
    ├── Comprehensive tests
    └── Documentation
```

### Phase Characteristics

**Good Phase Definition**:
- Clear objective (what success looks like)
- Self-contained (minimal dependencies on incomplete work)
- Testable (can verify it works)
- Documented (clear deliverables)
- Budgeted (token estimate with reality check)

**Bad Phase Definition**:
- Vague objective ("Make progress on auth")
- Time-based ("Week 1 tasks")
- Dependent on unknown work ("When backend is ready...")
- Untestable ("Some improvements")

## Phase Documentation

### Phase Document Structure

**One file per phase** (in `docs/development/` while active):

```markdown
# V1.2.0 - Phase 1: Foundation

**Status**: In Progress
**Started**: 2025-12-22
**Token Budget**: 500K-800K tokens
**Tokens Spent**: ~250K tokens (50% complete)

## Objectives
- Implement JWT service with token generation and validation
- Create basic authentication flow
- Establish testing patterns for auth system

## Deliverables
- [ ] JWT service (generate, validate, refresh)
- [ ] Token expiry handling
- [x] Test framework setup (COMPLETE)
- [ ] Integration with user model

## Progress Updates

### 2025-12-22: Started JWT Implementation
- Created jwt_service.py skeleton
- Implemented token generation with PyJWT
- Added basic validation
- Next: Expiry handling and refresh tokens

### 2025-12-23: Token Validation Complete
- Implemented expiry checking
- Added signature validation
- Created test suite (15 tests, all passing)
- Next: Refresh token mechanism

## Technical Decisions
- **JWT Library**: Chose PyJWT over python-jose (better maintained, simpler API)
- **Token Expiry**: 24 hours for access tokens, 30 days for refresh
- **Secret Storage**: Environment variable (JWT_SECRET)

## Completion Summary
(Added when phase complete)
```

### Integration with Core Docs

**When starting a phase**:
1. Create phase document in `docs/development/V{VERSION}_PHASE_{N}.md`
2. Update ROADMAP.md "Current Work" section
3. Link from version implementation plan (if it exists)

**During phase**:
1. Add dated progress updates to phase document
2. Mark deliverables as complete
3. Document technical decisions
4. Update ROADMAP.md as milestones are reached

**When completing a phase**:
1. Add completion summary to phase document
2. Update ROADMAP.md "What We Just Finished"
3. Move to next phase or complete version

**When version complete**:
1. Archive all phase documents to `docs/archive/development-history/YYYY-MM/`
2. Update VERSION file
3. Update ROADMAP.md to mark version complete

## Phase Management (Czarina Orchestration)

In multi-agent orchestration, phases represent distinct groups of workers working sequentially.

### Phase Close vs. Closeout

**Phase Close** (`czarina phase close`):
- ✅ Stops all worker sessions
- ✅ Archives phase state
- ✅ **Preserves** `.czarina/` structure
- ✅ Ready for next phase immediately

**Closeout** (`czarina closeout`):
- ✅ Stops all worker sessions
- ✅ Archives final state
- ❌ **Removes** `.czarina/` structure
- ❌ Requires full re-initialization

| Action | Phase Close | Closeout |
|--------|-------------|----------|
| Stop tmux sessions | ✅ | ✅ |
| Archive state | ✅ | ✅ |
| Keep .czarina/ | ✅ **YES** | ❌ **NO** |
| Next phase | ✅ Easy | ❌ Full re-init |

### Multi-Phase Workflow

```bash
# Phase 1: Foundation
czarina analyze docs/v1.2.0/plan.md --interactive --init
czarina launch
# ... workers work ...
czarina phase close

# Phase 2: Integration
czarina analyze docs/v1.3.0/plan.md --interactive --init
czarina launch
# ... new workers work ...
czarina phase close

# Phase 3: Polish
czarina analyze docs/v1.4.0/plan.md --interactive --init
czarina launch
# ... final workers work ...
czarina closeout  # Final closeout when all done
```

### Phase Archives

Each phase is archived with timestamp:

```
.czarina/phases/
├── phase-2025-12-20_14-30-00/
│   ├── PHASE_SUMMARY.md         # What was done
│   ├── config.json              # Worker config snapshot
│   ├── workers/                 # Worker prompts
│   └── logs/                    # Phase logs
├── phase-2025-12-22_09-15-00/
│   └── ...
└── phase-2025-12-23_16-00-00/
    └── ...
```

## Phase Planning Patterns

### Pattern 1: Sequential Phases (Most Common)

Phases build on each other sequentially:

```
Phase 1: Foundation → Phase 2: Integration → Phase 3: Polish
```

**When to use**: Standard feature development

**Example**:
- Phase 1: Core authentication logic
- Phase 2: API endpoint integration
- Phase 3: Error handling and tests

### Pattern 2: Parallel-Ready Phases

Phases can be worked on independently if needed:

```
Phase 1: Backend API
Phase 2: Frontend UI    } Can be parallel if dependencies are minimal
Phase 3: Integration
```

**When to use**: When teams/agents can work independently

**Example**:
- Phase 1: Backend auth endpoints
- Phase 2: Frontend login UI (uses mock backend initially)
- Phase 3: Integration testing

### Pattern 3: Exploration → Implementation

Early phase is research/exploration, later phases implement:

```
Phase 1: Research & Spike → Phase 2: Implementation → Phase 3: Optimization
```

**When to use**: Novel features or unknown territory

**Example**:
- Phase 1: Research OAuth providers, spike integration
- Phase 2: Implement chosen OAuth provider
- Phase 3: Add additional providers, optimize

## Phase Transition Checklist

### Before Starting New Phase

- [ ] Previous phase complete (or intentionally paused)
- [ ] Previous phase documented (completion summary)
- [ ] ROADMAP.md updated (phase moved to "Just Finished")
- [ ] New phase objectives defined
- [ ] New phase token budget estimated
- [ ] Dependencies identified and resolved
- [ ] New phase document created in `docs/development/`

### During Phase

- [ ] Weekly progress updates in phase document
- [ ] Deliverables marked as complete
- [ ] Technical decisions documented
- [ ] ROADMAP.md "Current Work" accurate
- [ ] Blockers noted and addressed

### Before Closing Phase

- [ ] All deliverables complete (or deferred with reason)
- [ ] Tests passing
- [ ] Completion summary written
- [ ] ROADMAP.md updated
- [ ] Token usage recorded (vs. budget)
- [ ] Lessons learned documented

### Closing Phase (Czarina)

```bash
# Archive current phase
czarina phase close

# Result:
# - Workers stopped
# - State archived to .czarina/phases/phase-TIMESTAMP/
# - Ready for next phase
```

## Real-World Example: v0.4.15 Thread Detection

**From thesymposium project:**

```markdown
## v0.4.15 - Conversation Threading

**Total Effort**: 500K-800K tokens base
**Reality Check**: 🟡 Normal Chaos (1.5x)
**Adjusted Estimate**: 750K-1.2M tokens
**Actual**: ~200K tokens (75% under budget!)

### Phase 1: Thread Detection (300K-500K tokens)
**Objective**: Detect and group conversation threads
**Deliverables**:
- Thread metadata schema
- Thread detection service
- Thread-aware search
- Integration tests

**Result**: Complete in ~150K tokens

### Phase 2: MCP Integration (300K-500K tokens)
**Status**: DEFERRED to v0.4.17
**Reason**: Hardware limitations discovered (AVX2 requirement)

### Lessons Learned
- Thread detection was simpler than expected (75% under budget)
- Hardware discovery changed priorities (Phase 2 deferred)
- Phase-based approach allowed flexibility to defer Phase 2
```

## Token Budget Tracking by Phase

Each phase has a token budget tracked throughout:

**Planning**:
```markdown
Phase 1: Foundation (500K-800K tokens base)
Reality Check: 🟡 Normal Chaos (1.5x)
Adjusted: 750K-1.2M tokens
```

**During Work**:
```markdown
Phase 1: Foundation
Progress: 600K / 750K-1.2M tokens (50-80% complete)
```

**Completion**:
```markdown
Phase 1: Foundation ✅ COMPLETE
Estimated: 750K-1.2M tokens
Actual: 650K tokens
Efficiency: 13% under budget
```

## Anti-Patterns (What NOT to Do)

### ❌ Don't: Use Calendar-Based Phases

```markdown
# BAD
Phase 1: Week 1 (Dec 20-27)
Phase 2: Week 2 (Dec 28-Jan 4)
```

**Why**: Calendar dates don't match AI development reality. Use objective-based phases with token budgets.

### ❌ Don't: Create Overly Large Phases

```markdown
# BAD
Phase 1: Complete Entire Authentication System (3M-5M tokens)
```

**Why**: Too large to track, test, or review effectively. Break into smaller phases (Foundation, Integration, Polish).

### ❌ Don't: Archive Incomplete Phases

```markdown
# BAD
# Phase not actually complete, but moved to archive
mv docs/development/V1.2.0_PHASE_1.md docs/archive/
```

**Why**: Archive only when phase is 100% complete. Keep in `docs/development/` until done.

### ❌ Don't: Skip Phase Documentation

```markdown
# BAD
# No phase document, just code changes
git commit -m "Working on auth stuff"
```

**Why**: Loses context, decisions, and progress visibility. Always document phases.

### ❌ Don't: Mix Multiple Phases in One Document

```markdown
# BAD
# V1.2.0_EVERYTHING.md covering Phases 1-3
```

**Why**: Hard to track individual phase progress. Use one file per phase.

## Best Practices

### ✅ Clear Phase Objectives

```markdown
# GOOD
## Phase 1: Foundation
**Objective**: Implement working JWT authentication with token generation,
validation, and basic testing. Success = user can authenticate and receive
valid JWT token.
```

### ✅ Token-Based Estimates

```markdown
# GOOD
**Estimated**: 500K-800K tokens (M-sized effort)
**Reality Check**: 🟡 Normal Chaos (1.5x multiplier)
**Adjusted**: 750K-1.2M tokens
```

### ✅ Dated Progress Updates

```markdown
# GOOD
### 2025-12-22: JWT Implementation Started
- Created jwt_service.py
- Token generation working
- 5 tests passing
- Next: Validation and expiry

### 2025-12-23: Validation Complete
- All validation working
- 15 tests passing
- Next: Refresh tokens
```

### ✅ Document Decisions

```markdown
# GOOD
## Technical Decisions

### JWT vs. Session Cookies
**Decision**: Use JWT tokens
**Reason**: Stateless, works with microservices, easier scaling
**Trade-off**: Larger payload size (acceptable for our use case)
```

### ✅ Completion Summaries

```markdown
# GOOD
## Completion Summary
**Completed**: 2025-12-23
**Token Usage**: 650K / 750K-1.2M estimated (13% under budget)

**Delivered**:
- ✅ JWT service with generation, validation, refresh
- ✅ 23 tests (95% coverage)
- ✅ Integration with user model
- ✅ Documentation complete

**Lessons Learned**:
- PyJWT was easier to use than expected (saved ~100K tokens)
- Environment variable management needs improvement (for next phase)
- Test-first approach worked well (caught 3 bugs early)

**Next Phase**: Integration (400K-600K tokens)
```

## Integration with Other Workflows

Phase-based development integrates with:

- **`TOKEN_PLANNING.md`** - Token budgets per phase
- **`DOCUMENTATION_WORKFLOW.md`** - Phase documentation standards
- **`GIT_WORKFLOW.md`** - Commit messages reference phases
- **`PR_REQUIREMENTS.md`** - PRs marked with phase completion

## Summary

### Core Principles

1. ✅ **Phases, not sprints** - Objective-based, not calendar-based
2. ✅ **Token budgets** - Not time estimates
3. ✅ **One file per phase** - In `docs/development/` while active
4. ✅ **Dated updates** - Track progress with timestamps
5. ✅ **Completion summaries** - Document what worked
6. ✅ **Archive when done** - Only complete phases move to archive

### Phase Lifecycle

```
1. Plan Phase → 2. Create Doc → 3. Implement → 4. Track Progress → 5. Complete → 6. Archive
```

### Remember

Phases are your unit of organization. They're flexible, pausable, and match the reality of AI development: unpredictable in time, measurable in tokens.

**Calendar dates fail. Token budgets work. Plan accordingly.**

---

**Source**: Extracted from [thesymposium](https://gitlab.henrynet.ca/symposium/thesymposium) `.kilocode/rules/PHASE_DOCUMENTATION_RULE.md` and [czarina](https://github.com/anthropics/czarina) `docs/workflows/PHASE_MANAGEMENT.md`.

**See Also**:
- `TOKEN_PLANNING.md` - Token estimation and budgeting
- `DOCUMENTATION_WORKFLOW.md` - Phase documentation standards
- `GIT_WORKFLOW.md` - Git workflow patterns
- `CLOSEOUT_PROCESS.md` - Project/phase closeout procedures
