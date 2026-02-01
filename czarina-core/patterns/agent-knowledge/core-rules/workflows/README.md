# Workflows - Development Workflow Patterns

## Overview

This directory contains comprehensive workflow patterns for AI agent development, extracted from battle-tested production systems ([thesymposium](https://gitlab.henrynet.ca/symposium/thesymposium) and [czarina](https://github.com/anthropics/czarina)).

These workflows ensure:
- **Quality**: Code review, testing, documentation synchronization
- **Efficiency**: Token-based planning, phase-based execution
- **Collaboration**: PR-based development, clear handoffs
- **Accountability**: Metrics tracking, closeout reporting

## Quick Reference

### For New Projects

**Start here**:
1. Read `GIT_WORKFLOW.md` - Understand git conventions
2. Read `DOCUMENTATION_WORKFLOW.md` - Set up documentation structure
3. Read `TOKEN_PLANNING.md` - Estimate your first phase
4. Read `PHASE_DEVELOPMENT.md` - Plan your work in phases

### For Active Development

**Daily workflow**:
1. Check `PR_REQUIREMENTS.md` - Before creating PRs
2. Follow `DOCUMENTATION_WORKFLOW.md` - Update docs with code
3. Track progress using `TOKEN_PLANNING.md` - Monitor token usage

### For Project Completion

**Closeout**:
1. Follow `CLOSEOUT_PROCESS.md` - Generate comprehensive report
2. Calculate efficiency metrics
3. Document lessons learned

## Files in This Directory

### 1. GIT_WORKFLOW.md
**Git commit standards, branching, and PR workflow**

**Key Concepts**:
- Conventional commits with extensive body text
- Branch naming conventions (feature/, fix/, docs/)
- PR-based development (NO direct commits to main)
- Multi-agent coordination with git worktrees

**When to read**: Starting any new project or feature

**Quickstart**:
```bash
# Create feature branch
git checkout -b feature/v1.2.0-authentication

# Make changes, commit with detailed message
git commit -m "feat(auth): Add JWT authentication

- Implemented JWT service
- Added login/logout endpoints
- Tests passing (23 tests)

Updated:
- VERSION: 1.2.0
- ROADMAP.md: Auth complete

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push and create PR
git push -u origin feature/v1.2.0-authentication
```

---

### 2. PR_REQUIREMENTS.md
**Pull request requirements and review process**

**Key Concepts**:
- Documentation as blocking requirement
- 4-step Czar review (docs, quality, architecture, completeness)
- When to update existing PR vs. create new PR
- Hotfix exception process

**When to read**: Before creating any PR

**Quickstart**:
```markdown
PR Checklist:
- [ ] Code complete and tested
- [ ] VERSION updated (if version changed)
- [ ] ROADMAP.md "Current State" updated
- [ ] Feature docs updated
- [ ] PR description complete
- [ ] Ready for Czar review
```

---

### 3. DOCUMENTATION_WORKFLOW.md
**Documentation synchronization and organization**

**Key Concepts**:
- 2-file core pattern (README.md + ROADMAP.md)
- VERSION file as single source of truth
- Mandatory documentation updates (same commit as code)
- Documentation directory structure

**When to read**: Setting up new project or fixing documentation drift

**Quickstart**:
```markdown
Core Documents (Never Stale):
1. README.md - "What is this?" (timeless)
2. ROADMAP.md - "Where are we going?" (current state)
3. VERSION - Version info
4. CHANGELOG.md - Release history (Czar maintains)

Mandatory Updates:
- VERSION (if version changes)
- ROADMAP.md (always - "Current State" section)
- Feature docs (for new features)
```

---

### 4. PHASE_DEVELOPMENT.md
**Phase-based development workflow**

**Key Concepts**:
- Phases not sprints (objective-based, not calendar-based)
- Token budgets per phase
- Phase documentation patterns
- Phase close vs. full closeout

**When to read**: Planning multi-phase projects

**Quickstart**:
```markdown
Phase Structure:
- Phase 1: Foundation (500K-800K tokens)
  - Core implementation
  - Basic tests

- Phase 2: Integration (400K-600K tokens)
  - API endpoints
  - Middleware

- Phase 3: Polish (300K-500K tokens)
  - Error handling
  - Documentation
  - Optimization
```

---

### 5. TOKEN_PLANNING.md
**Token-based estimation and budgeting**

**Key Concepts**:
- Token effort sizes (XS/S/M/L/XL/XXL)
- Reality check multipliers (1.0x - 4x)
- NEVER use calendar-based estimates
- Token efficiency reporting

**When to read**: Estimating any new work

**Quickstart**:
```markdown
Effort Sizes:
- XS: <100K | S: 100K-500K | M: 500K-2M
- L: 2M-4M | XL: 4M-8M | XXL: 8M+

Reality Multipliers:
- 🟢 1.0x: Smooth Sailing (clear requirements)
- 🟡 1.5x: Normal Chaos (standard complexity)
- 🟠 2.5x: Docker Networking (distributed systems)
- 🔴 4x: Existential Debugging (research territory)

Example:
Effort: M (800K-1.3M tokens)
Reality Check: 🟡 Normal Chaos (1.5x)
Adjusted: 1.2M-2M tokens
```

---

### 6. CLOSEOUT_PROCESS.md
**Project closeout and reporting**

**Key Concepts**:
- Phase close vs. full closeout
- Closeout report structure
- Metrics to track (commits, files, tokens, efficiency)
- Lessons learned documentation

**When to read**: Completing phases or projects

**Quickstart**:
```markdown
Closeout Checklist:
- [ ] All branches committed and pushed
- [ ] Tests passing
- [ ] CHANGELOG.md updated
- [ ] Documentation complete
- [ ] Closeout report generated
- [ ] Token efficiency calculated
- [ ] Recommendations documented
```

---

## Workflow Integration

These workflows integrate as a cohesive system:

```
┌─────────────────────────────────────────────────┐
│         Token Planning (TOKEN_PLANNING.md)      │
│  Estimate work in tokens, not time              │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│    Phase Development (PHASE_DEVELOPMENT.md)     │
│  Organize work into phases with token budgets   │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│         Git Workflow (GIT_WORKFLOW.md)          │
│  Branch per phase/feature, commit frequently    │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│  Documentation Workflow (DOCUMENTATION_WF.md)   │
│  Update VERSION + ROADMAP.md in same commit     │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│    PR Requirements (PR_REQUIREMENTS.md)         │
│  Create PR with docs, await Czar review         │
└────────────┬────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│   Closeout Process (CLOSEOUT_PROCESS.md)       │
│  Generate report, calculate efficiency          │
└─────────────────────────────────────────────────┘
```

## Common Workflows

### Starting a New Feature

1. **Plan** (TOKEN_PLANNING.md):
   - Estimate effort: `Effort: M (800K-1.3M tokens)`
   - Apply reality check: `🟡 Normal Chaos (1.5x)`
   - Adjusted estimate: `1.2M-2M tokens`

2. **Branch** (GIT_WORKFLOW.md):
   ```bash
   git checkout -b feature/v1.2.0-auth
   ```

3. **Develop & Document** (DOCUMENTATION_WORKFLOW.md):
   - Write code
   - Update VERSION (if needed)
   - Update ROADMAP.md "Current State"
   - Commit together

4. **Create PR** (PR_REQUIREMENTS.md):
   - Include all documentation updates
   - Clear PR description
   - Wait for Czar review

5. **Track Progress** (PHASE_DEVELOPMENT.md):
   - Update phase document with dated entries
   - Track tokens spent vs. budget

6. **Complete** (CLOSEOUT_PROCESS.md):
   - Report token efficiency
   - Document lessons learned

### Multi-Phase Project

1. **Plan Phases** (PHASE_DEVELOPMENT.md):
   ```markdown
   Phase 1: Foundation (500K-800K tokens)
   Phase 2: Integration (400K-600K tokens)
   Phase 3: Polish (300K-500K tokens)
   Total: 1.3M-2.2M tokens
   ```

2. **Execute Phase 1**:
   - Create branch
   - Develop features
   - Update docs
   - Create PR
   - Merge

3. **Close Phase 1** (CLOSEOUT_PROCESS.md):
   - Generate phase summary
   - Calculate token efficiency
   - Archive phase docs

4. **Repeat for Phases 2 & 3**

5. **Full Closeout**:
   - Generate comprehensive report
   - Overall efficiency metrics
   - Recommendations for next version

## Anti-Patterns (What NOT to Do)

### ❌ Don't Skip Documentation

```bash
# BAD
git commit -m "Add auth"
# (Forgot to update VERSION and ROADMAP.md)
```

**Why**: Documentation drift causes confusion and wasted effort.

**Fix**: Update docs in the SAME commit as code.

### ❌ Don't Use Time Estimates

```markdown
# BAD
Phase 1: Week 1
Phase 2: Week 2-3
Due: December 25
```

**Why**: Time estimates don't match AI development reality.

**Fix**: Use token estimates and phases.

### ❌ Don't Commit Directly to Main

```bash
# BAD
git checkout main
git commit -m "Quick fix"
git push
```

**Why**: Bypasses review, documentation requirements, quality gates.

**Fix**: Always use PRs.

### ❌ Don't Create Giant PRs

```bash
# BAD - 50 files changed, 5000 lines
git commit -m "Entire feature"
```

**Why**: Impossible to review, hard to debug.

**Fix**: Break into smaller, focused PRs per phase.

## Best Practices

### ✅ Commit Frequently with Good Messages

```bash
# GOOD
git commit -m "feat(auth): Implement JWT token generation

- Created jwt_service.py
- Token generation working
- 5 tests passing

Updated:
- ROADMAP.md: JWT service in progress"
```

### ✅ Update Docs in Same Commit

```bash
# GOOD - all documentation updated together
git add src/ docs/ VERSION ROADMAP.md
git commit -m "feat(auth): Complete authentication system

[Details]

Updated:
- VERSION: 1.2.0
- ROADMAP.md: Auth complete
- docs/AUTH_GUIDE.md: User guide"
```

### ✅ Use Token Estimates

```markdown
# GOOD
**Effort**: M (800K-1.3M tokens)
**Reality Check**: 🟡 Normal Chaos (1.5x)
**Adjusted**: 1.2M-2M tokens
**Progress**: 600K / 1.2M-2M (30-50% complete)
```

### ✅ Track Efficiency

```markdown
# GOOD
**Phase 1 Complete**:
- **Estimated**: 500K-800K tokens
- **Actual**: 650K tokens
- **Efficiency**: On budget (81% of upper)
- **Lesson**: Good pattern reuse helped
```

## Success Metrics

### Your Workflows Are Working If:

- ✅ Documentation always matches code
- ✅ Status reviews take <5 minutes
- ✅ No duplicate work planned
- ✅ Token estimates within 20% of actual
- ✅ All PRs have complete documentation
- ✅ Main branch always stable
- ✅ Clear history and traceability

### Your Workflows Are Failing If:

- ❌ Documentation out of sync with code
- ❌ Status unclear ("Is this done?")
- ❌ Duplicate work happens
- ❌ Token estimates wildly off
- ❌ PRs missing documentation
- ❌ Main branch breaks
- ❌ Unclear what happened when

## Getting Started

### New to These Workflows?

**Week 1: Foundation**
1. Read `GIT_WORKFLOW.md`
2. Read `DOCUMENTATION_WORKFLOW.md`
3. Set up your project structure
4. Practice commit messages

**Week 2: Planning**
1. Read `TOKEN_PLANNING.md`
2. Read `PHASE_DEVELOPMENT.md`
3. Estimate your first feature
4. Plan your phases

**Week 3: Execution**
1. Read `PR_REQUIREMENTS.md`
2. Implement your first feature
3. Create your first PR
4. Track token usage

**Week 4: Completion**
1. Read `CLOSEOUT_PROCESS.md`
2. Complete your first phase
3. Generate closeout report
4. Calculate efficiency

### Already Using These Workflows?

**Quick Refresh**:
- ✅ Committing with detailed messages?
- ✅ Updating docs in same commit?
- ✅ Using token estimates (not time)?
- ✅ Creating PRs (not direct commits)?
- ✅ Tracking token efficiency?

## Further Reading

### Related Documentation

- **Foundation Patterns**: `../foundation/` - Core patterns and principles
- **Code Patterns**: `../patterns/` - Code organization and architecture
- **Template Systems**: `../templates/` - Reusable templates for projects

### Source Projects

- **[thesymposium](https://gitlab.henrynet.ca/symposium/thesymposium)**: AI consciousness platform with mature workflows
- **[czarina](https://github.com/anthropics/czarina)**: Multi-agent orchestration system

## Contributing

These workflows are extracted from real production systems and continuously refined based on actual use.

**Improvements welcome**:
- Spotted an anti-pattern not documented?
- Found a better way to do something?
- Have real-world examples to add?

Document them! These patterns improve through use and feedback.

## Summary

### Core Principles

1. ✅ **Token-based planning** - Not calendar-based
2. ✅ **Phase-based execution** - Not sprint-based
3. ✅ **Documentation synchronization** - Same commit as code
4. ✅ **PR-based development** - No direct commits
5. ✅ **Metrics tracking** - Token efficiency, deliverables
6. ✅ **Continuous improvement** - Closeout reports drive learning

### Key Files

- `GIT_WORKFLOW.md` - Git conventions
- `PR_REQUIREMENTS.md` - PR review process
- `DOCUMENTATION_WORKFLOW.md` - Documentation standards
- `PHASE_DEVELOPMENT.md` - Phase organization
- `TOKEN_PLANNING.md` - Token estimation
- `CLOSEOUT_PROCESS.md` - Project closeout

### Remember

**These workflows exist to support quality, not create bureaucracy.**

They prevent:
- Documentation drift
- Unclear status
- Poor estimates
- Missing reviews
- Lost lessons

They enable:
- Clear communication
- Accurate planning
- Quality code
- Efficient collaboration
- Continuous improvement

**Use them. Refine them. Share improvements.**

---

**Last Updated**: 2025-12-26
**Source**: Extracted from production systems (thesymposium, czarina)
**Status**: Battle-tested and production-ready
