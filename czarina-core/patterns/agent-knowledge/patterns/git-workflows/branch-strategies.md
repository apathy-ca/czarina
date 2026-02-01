# Branch Strategies for AI-Assisted Development

**Purpose**: Effective branching patterns for AI coding assistants working with version control.

**Value**: Clean repository history, effective collaboration, easy rollback, clear feature isolation.

---

## Pattern: Feature Branch per Task

### Problem
Working directly on main branch makes it hard to isolate changes and collaborate.

### Solution
**Create dedicated branch for each feature/fix**:

```bash
# Pattern: <type>/<short-description>
git checkout -b feat/email-verification
git checkout -b fix/payment-validation
git checkout -b refactor/auth-service
git checkout -b docs/api-documentation
```

### Branch Naming Convention

**Types**:
- `feat/` - New features
- `fix/` - Bug fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation changes
- `test/` - Test additions/modifications
- `chore/` - Maintenance tasks

**Description**: Short, kebab-case, descriptive
- ✅ `feat/user-authentication`
- ✅ `fix/payment-overflow`
- ❌ `my-branch`
- ❌ `feat/new_feature_123`

### When to Create Branch

**Always**:
- Before implementing new feature
- Before fixing bug
- Before refactoring

**Never**:
- For tiny typo fixes (can commit to main if allowed)
- For investigating (use local changes, don't commit)

### Impact
- Clear feature isolation
- Easy code review
- Simple rollback if needed
- Clean git history

---

## Pattern: Worker-Specific Branches

### Problem
Multiple AI workers/agents working on different parts of same project.

### Solution
**Use worker-specific branch prefixes**:

```bash
# Pattern: <worker-name>/<type>/<description>
git checkout -b czarina/feat/orchestration
git checkout -b hopper/fix/routing
git checkout -b sage/docs/wisdom-system
```

### Workflow

```markdown
Project: Symposium v0.5

Workers:
- czarina (orchestrator) → czarina/* branches
- hopper (task router) → hopper/* branches
- sage (wisdom keeper) → sage/* branches
- code (implementer) → code/* branches

Example:
czarina/feat/phase-tracking
hopper/fix/priority-queue
sage/refactor/memory-tiers
code/feat/api-endpoints
```

### Benefits
- **Clear ownership**: Which worker made which changes
- **Parallel work**: Workers don't conflict
- **Easy review**: Group changes by worker
- **Rollback**: Can revert specific worker's changes

### Merging Strategy

```bash
# Workers merge to integration branch first
git checkout integration
git merge czarina/feat/phase-tracking  # Review czarina's work
git merge hopper/fix/priority-queue    # Review hopper's work

# After all workers complete and integration tested
git checkout main
git merge integration  # Merge all worker changes
```

---

## Pattern: Short-Lived Branches

### Problem
Long-lived branches accumulate merge conflicts and diverge from main.

### Solution
**Keep branches short-lived (< 2 days ideal, < 1 week maximum)**:

### Target Lifetimes

| Branch Type | Target Lifetime | Max Lifetime |
|-------------|----------------|--------------|
| Bug fix | < 4 hours | 1 day |
| Small feature | < 2 days | 1 week |
| Large feature | Break into smaller branches | 2 weeks |
| Refactoring | < 1 day | 3 days |

### Keeping Branches Short

**Strategy 1: Break large features down**
```bash
# Instead of:
git checkout -b feat/payment-system  # Too large

# Do this:
git checkout -b feat/payment-model       # Day 1
git checkout -b feat/payment-service     # Day 2
git checkout -b feat/payment-api         # Day 3
git checkout -b feat/payment-webhooks    # Day 4
```

**Strategy 2: Merge frequently**
```bash
# Work → Review → Merge → Repeat
Day 1: Create branch, implement, PR, merge
Day 2: New branch, implement, PR, merge
Day 3: New branch, implement, PR, merge
```

**Strategy 3: Rebase on main daily**
```bash
# Keep branch updated with main
git checkout feat/my-feature
git fetch origin
git rebase origin/main  # Replay feature changes on latest main
git push --force-with-lease  # Update remote branch
```

### Impact
- Fewer merge conflicts
- Easier code review (smaller changes)
- Faster feedback
- Lower risk

---

## Pattern: AI-Generated Branch Names

### Problem
AI assistant doesn't know what branch name to use.

### Solution
**Let AI suggest branch name based on task**:

```markdown
USER: "Add email verification to user registration"

AI: "I'll create a feature branch for this task. Suggested name:
     feat/email-verification

     Does this name work, or would you prefer a different one?"

USER: "That's good, proceed"

AI: [Creates branch feat/email-verification]
```

### Branch Name Generation

**From task description**:
```
"Fix payment validation bug" → fix/payment-validation
"Refactor authentication service" → refactor/auth-service
"Add user profile API" → feat/user-profile-api
"Update documentation for payments" → docs/payment-docs
"Add tests for email service" → test/email-service
```

**Rules for AI**:
1. Extract type from task (add=feat, fix=fix, etc.)
2. Extract 2-3 key words from description
3. Kebab-case the description
4. Keep under 30 characters
5. Ask user to confirm before creating

---

## Pattern: Branch Cleanup

### Problem
Accumulated merged branches clutter repository.

### Solution
**Delete branches after merging**:

```bash
# After PR merged
git checkout main
git pull origin main
git branch -d feat/email-verification  # Delete local branch
git push origin --delete feat/email-verification  # Delete remote branch

# Or let GitHub delete automatically after PR merge
```

### Automatic Cleanup

**GitHub Settings**:
- Enable "Automatically delete head branches" in repository settings
- Branches deleted after PR merge
- Can be restored if needed (within 30 days)

**Manual Cleanup**:
```bash
# List merged branches
git branch --merged main

# Delete all merged branches (except main/master)
git branch --merged main | grep -v "main\|master" | xargs git branch -d

# Delete remote tracking branches that no longer exist
git fetch --prune
```

### When NOT to Delete

**Keep branches**:
- Long-running release branches (v1.0, v2.0)
- Integration/staging branches
- Branches for deployed features (for rollback)

---

## Pattern: Branch Protection

### Problem
Accidental force pushes or direct commits to main break stability.

### Solution
**Protect important branches**:

### GitHub Branch Protection Rules

For `main` branch:
- ✅ Require pull request before merging
- ✅ Require status checks to pass (tests, linting)
- ✅ Require conversation resolution before merging
- ✅ Require signed commits (optional)
- ❌ Allow force pushes
- ❌ Allow deletions

For `integration` branch (if used):
- ✅ Require pull request before merging
- ✅ Require status checks to pass
- ✅ Allow force pushes (for rebasing)
- ❌ Allow deletions

For feature branches:
- ❌ No protections needed (can force push during development)

### AI Awareness

**AI should**:
- Never force push to protected branches
- Never commit directly to main
- Always create PR for protected branches
- Warn user if attempting protected operation

```markdown
AI: "I cannot push directly to main (protected branch).
     I'll create a pull request instead.

     Branch: feat/email-verification
     Target: main

     Shall I create the PR?"
```

---

## Pattern: Experimental Branches

### Problem
Want to try risky refactoring without affecting stable code.

### Solution
**Use experiment/ prefix for exploratory work**:

```bash
# Experimental branches - might be thrown away
git checkout -b experiment/new-architecture
git checkout -b experiment/performance-optimization
git checkout -b experiment/different-approach

# If experiment succeeds, rename to proper branch
git branch -m experiment/new-architecture feat/new-architecture

# If experiment fails, delete without mercy
git branch -D experiment/new-architecture
```

### Experiment Rules

**Clearly mark as experimental**:
- Use `experiment/` prefix
- Don't create PRs for experiments
- Keep local (don't push unless sharing)
- Delete immediately if failed
- Rename if successful

**AI workflow**:
```markdown
AI: "This refactoring is risky. I'll create an experimental branch
     to test the approach:

     experiment/refactor-payment-service

     If it works, we'll create a proper feature branch.
     If it fails, we'll delete it and try a different approach."
```

---

## Pattern: Integration Branch Strategy

### Problem
Multiple features being developed in parallel, need to test together before merging to main.

### Solution
**Use integration branch for combining multiple features**:

```mermaid
main ← integration ← feat/feature-a
                 ← feat/feature-b
                 ← feat/feature-c
```

### Workflow

```bash
# Create integration branch from main
git checkout main
git checkout -b integration

# Developers merge their features to integration
git checkout integration
git merge feat/email-verification
git merge feat/payment-processing
git merge feat/user-profiles

# Test integration branch
npm test
npm run e2e-tests

# If all tests pass, merge integration to main
git checkout main
git merge integration

# If tests fail, fix in feature branches and re-merge
```

### When to Use

**Good for**:
- Multiple related features developed in parallel
- Features with potential interactions
- Release branches for version releases

**Not needed for**:
- Single feature development
- Independent bug fixes
- Small changes

---

## Best Practices

### Do
- ✅ Use descriptive branch names with type prefix
- ✅ Create branch per feature/fix
- ✅ Keep branches short-lived (< 1 week)
- ✅ Delete branches after merging
- ✅ Protect main branch
- ✅ Let AI suggest branch names

### Don't
- ❌ Work directly on main/master
- ❌ Use vague branch names ("test", "my-branch")
- ❌ Keep branches alive for weeks
- ❌ Force push to protected branches
- ❌ Leave merged branches around
- ❌ Create branches for investigation

---

## Branch Strategy Checklist

**Starting New Work**:
- [ ] Determine branch type (feat/fix/refactor/etc.)
- [ ] Generate descriptive name
- [ ] Create branch from latest main
- [ ] Confirm branch name with user (if AI)

**During Development**:
- [ ] Keep branch focused on single feature/fix
- [ ] Rebase on main if branch gets stale (> 2 days)
- [ ] Commit frequently with good messages

**Before Merging**:
- [ ] Ensure tests pass
- [ ] Update documentation if needed
- [ ] Create pull request
- [ ] Request review if needed

**After Merging**:
- [ ] Delete feature branch
- [ ] Pull latest main
- [ ] Start new branch for next task

---

## Related Patterns

- [Commit Patterns](./commit-patterns.md) - Commit organization within branches
- [PR Workflows](./pr-workflows.md) - Pull request processes
- [Conflict Resolution](./conflict-resolution.md) - Handling merge conflicts

---

## Related Core Rules

**See Also**:
- [Git Workflows](../../core-rules/workflows/git-workflows.md) - Git standards and requirements

---

**Last Updated**: 2025-12-29
**Source**: The Symposium development, Czarina orchestration patterns
**Impact**: Clean repository history, effective collaboration, easy rollback

*"Branch for every feature, merge often, delete quickly."*
