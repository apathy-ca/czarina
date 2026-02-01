# Conflict Resolution Patterns

**Purpose**: Strategies for preventing and resolving merge conflicts in AI-assisted development.

**Value**: Faster merges, fewer conflicts, less frustration, maintained code quality.

---

## Pattern: Conflict Prevention

### Problem
Merge conflicts waste time and can introduce bugs.

### Solution
**Prevent conflicts before they happen**:

### Prevention Strategies

**1. Communicate Early**
```markdown
Before starting work on shared files:
- Announce in team chat: "Working on payment_service.py"
- Check if others working on same file
- Coordinate changes if needed
```

**2. Keep Branches Short-Lived**
```bash
# Merge within 1-2 days
# Less time = less chance of conflicts
feat/email-verification: Created Monday, merged Tuesday
```

**3. Rebase on Main Daily**
```bash
# Keep feature branch updated
git checkout feat/email-verification
git fetch origin
git rebase origin/main
```

**4. Work on Different Files When Possible**
```bash
# Instead of both editing payment_service.py
Developer A: payment_service.py
Developer B: payment_model.py
```

### Impact
- 70-80% reduction in merge conflicts
- Faster PR merges
- Less context switching

---

## Pattern: AI-Assisted Conflict Resolution

### Problem
AI assistants can accidentally create conflicts or struggle to resolve them.

### Solution
**AI follows systematic conflict resolution process**:

```markdown
AI Conflict Resolution Workflow:

1. Detect Conflict
   AI: "Merge conflict detected in payment_service.py"

2. Analyze Both Versions
   AI: "Comparing changes:
        - Our branch: Changed validation logic
        - Main branch: Added logging to same function"

3. Propose Resolution
   AI: "These changes are compatible. I'll combine both:
        - Keep validation changes from our branch
        - Add logging from main branch
        - Result: Function has both improvements"

4. Show Diff and Confirm
   AI: "Proposed resolution:
        [show merged code]

        Does this correctly combine both changes?"

5. Test After Resolution
   AI: "Running tests to verify conflict resolution..."
```

### AI Should NOT
- ❌ Automatically resolve conflicts without showing user
- ❌ Delete code without understanding its purpose
- ❌ Choose arbitrary side (ours vs. theirs) blindly
- ❌ Skip testing after resolution

---

## Pattern: Understanding Conflict Markers

### Problem
Conflict markers are confusing to interpret.

### Solution
**Understand what each section means**:

```python
# Conflict markers in file
<<<<<<< HEAD (current branch)
def process_payment(self, amount: int):
    if amount <= 0:
        raise ValueError("Amount must be positive")
    return self.stripe.charge(amount)
=======
def process_payment(self, amount: int, currency: str = "USD"):
    if amount > 100000:
        raise ValueError("Amount too large")
    return self.stripe.charge(amount, currency)
>>>>>>> main (incoming changes)
```

### Interpretation

**HEAD (top section)**:
- Your branch's version
- Changes you made
- "Ours"

**main (bottom section)**:
- Other branch's version
- Changes from main/other branch
- "Theirs"

### Resolution Options

**Option 1: Keep HEAD (ours)**
```python
def process_payment(self, amount: int):
    if amount <= 0:
        raise ValueError("Amount must be positive")
    return self.stripe.charge(amount)
```

**Option 2: Keep main (theirs)**
```python
def process_payment(self, amount: int, currency: str = "USD"):
    if amount > 100000:
        raise ValueError("Amount too large")
    return self.stripe.charge(amount, currency)
```

**Option 3: Combine both** (usually best)
```python
def process_payment(self, amount: int, currency: str = "USD"):
    # Validation from HEAD
    if amount <= 0:
        raise ValueError("Amount must be positive")
    # Additional validation from main
    if amount > 100000:
        raise ValueError("Amount too large")
    # Currency parameter from main
    return self.stripe.charge(amount, currency)
```

---

## Pattern: Conflict Resolution Steps

### Problem
Don't know systematic process for resolving conflicts.

### Solution
**Follow consistent resolution process**:

```bash
# Step 1: Identify conflicts
git status
# Shows: both modified: src/services/payment_service.py

# Step 2: Open conflicted file
# Look for <<<<<<< HEAD markers

# Step 3: Understand both changes
# Read HEAD version (your changes)
# Read incoming version (their changes)
# Understand purpose of each

# Step 4: Resolve conflict
# Edit file to combine changes appropriately
# Remove conflict markers (<<<<<<<, =======, >>>>>>>)

# Step 5: Mark as resolved
git add src/services/payment_service.py

# Step 6: Test the resolution
pytest tests/test_payment_service.py

# Step 7: Continue merge/rebase
git rebase --continue
# or
git merge --continue
```

---

## Pattern: Testing After Conflict Resolution

### Problem
Resolved conflicts may introduce bugs even if code looks correct.

### Solution
**Always test after resolving conflicts**:

```bash
# After resolving conflict
git add src/services/payment_service.py

# Before continuing merge/rebase
# Run relevant tests
pytest tests/test_payment_service.py

# If tests pass
git rebase --continue

# If tests fail
# Re-examine conflict resolution
# Fix the issue
# Re-run tests
```

### Test Checklist

**Must test**:
- [ ] Unit tests for conflicted files
- [ ] Integration tests if multiple files affected
- [ ] Manual testing if critical functionality

**Don't merge if**:
- Tests failing after conflict resolution
- Uncertain about resolution correctness
- Haven't tested the changes

---

## Pattern: Abort and Retry

### Problem
Conflict resolution went wrong, need to start over.

### Solution
**Abort and retry with fresh perspective**:

```bash
# Abort current merge/rebase
git merge --abort
# or
git rebase --abort

# Return to clean state
git status  # Should show clean working directory

# Try alternative approach
# Option 1: Merge instead of rebase
git merge main

# Option 2: Get help
# Ask teammate to review conflict
# Pair program resolution

# Option 3: Pull latest and retry
git fetch origin
git pull origin main
# Resolve conflicts with fresh context
```

### When to Abort

**Abort if**:
- Too many conflicts (> 10 files)
- Uncertain about resolution
- Tests failing after resolution
- Lost context on what changes should do

**Better to abort and**:
- Get teammate help
- Update branch and retry
- Break into smaller changes

---

## Pattern: Preventing Binary File Conflicts

### Problem
Binary files (images, databases) can't be merged textually.

### Solution
**Avoid binary file conflicts through coordination**:

```bash
# Mark binary files in .gitattributes
*.db binary
*.sqlite binary
*.png binary
*.jpg binary

# Git won't attempt text merge on binary files
# Will require manual resolution (choose one version)
```

### Binary Conflict Resolution

```bash
# Choose our version
git checkout --ours path/to/file.png

# Choose their version
git checkout --theirs path/to/file.png

# Mark as resolved
git add path/to/file.png
```

---

## Pattern: Refactoring Conflicts

### Problem
Large refactoring creates many conflicts with other branches.

### Solution
**Coordinate refactoring to minimize conflicts**:

### Strategy 1: Merge All Branches First
```bash
# Before starting refactoring
# Merge all pending feature branches
# Then do refactoring on clean main
```

### Strategy 2: Incremental Refactoring
```bash
# Instead of big-bang refactoring
# Do small, incremental refactoring commits
# Easier for others to merge
```

### Strategy 3: Communicate Early
```markdown
Announcement: "Planning to refactor payment service tomorrow.
Please merge your payment-related PRs by EOD today, or we'll
coordinate on conflict resolution."
```

---

## Best Practices

### Do
- ✅ Prevent conflicts through communication
- ✅ Keep branches short-lived (< 2 days)
- ✅ Rebase on main daily
- ✅ Test after resolving conflicts
- ✅ Abort if resolution uncertain
- ✅ Combine both changes when compatible

### Don't
- ❌ Resolve conflicts without understanding both sides
- ❌ Blindly choose "ours" or "theirs"
- ❌ Skip testing after resolution
- ❌ Leave conflict markers in code
- ❌ Merge if uncertain about resolution
- ❌ Ignore conflicts and force push

---

## Conflict Resolution Checklist

**When Conflict Occurs**:
- [ ] Identify all conflicted files
- [ ] Understand changes in both versions
- [ ] Decide on resolution strategy (combine, keep one, custom)
- [ ] Edit files to resolve conflicts
- [ ] Remove all conflict markers
- [ ] Run tests on resolved files
- [ ] Mark files as resolved (git add)
- [ ] Complete merge/rebase
- [ ] Run full test suite
- [ ] Verify application works

**If Resolution Unclear**:
- [ ] Abort merge/rebase
- [ ] Ask for help/clarification
- [ ] Consider alternative approach
- [ ] Update branch and retry

---

## Common Conflict Scenarios

### Scenario 1: Same Function Modified
**Resolution**: Combine both changes if compatible, or redesign if contradictory

### Scenario 2: File Renamed in One Branch
**Resolution**: Apply changes to renamed file

### Scenario 3: File Deleted in One Branch
**Resolution**: If delete was intentional, keep deletion; otherwise restore and apply changes

### Scenario 4: Whitespace/Formatting Differences
**Resolution**: Choose consistent formatting, run linter

---

## Related Patterns

- [Branch Strategies](./branch-strategies.md) - Prevent conflicts with good branching
- [Commit Patterns](./commit-patterns.md) - Atomic commits reduce conflict scope
- [PR Workflows](./pr-workflows.md) - Fast PR merges reduce conflicts

---

## Related Core Rules

**See Also**:
- [Git Workflows](../../core-rules/workflows/git-workflows.md) - Conflict resolution standards

---

**Last Updated**: 2025-12-29
**Source**: The Symposium development patterns
**Impact**: 70-80% reduction in conflicts, faster resolution, fewer bugs

*"Prevent conflicts through communication, resolve conflicts through understanding."*
