# Writing Effective First Actions

## Overview

The "🚀 YOUR FIRST ACTION" section in worker identities is **critical** for preventing workers from getting stuck. This document provides comprehensive best practices for writing effective first actions.

## The Problem We're Solving

**Observed behavior:** 1 worker per orchestration gets stuck and doesn't know what to do first.

**Root cause:** Worker identities describe high-level missions and objectives but lack explicit first steps.

**Impact:**
- Workers spend time analyzing instead of acting
- Human coordination required to "jog" workers
- Reduces autonomy and increases orchestration overhead
- Breaks the promise of "it just works"

**Solution:** Add unmissable, specific, actionable first step to every worker identity.

## Core Principles

### 1. Make It Unmissable

Use consistent, eye-catching formatting:

```markdown
## 🚀 YOUR FIRST ACTION

**[Description]:**

\```bash
[commands]
\```

**Then:** [next step]
```

The 🚀 emoji and section header make it impossible to overlook.

### 2. Be Specific

Bad: "Familiarize yourself with the codebase"
Good: `cat czarina-core/logging.sh`

Bad: "Review the documentation"
Good: `cat docs/ARCHITECTURE.md | less`

**Rule:** Every first action must include at least one concrete bash command.

### 3. Start with Exploration

Most first actions should be **reading** and **understanding**, not writing:

- ✅ Read specifications
- ✅ Examine existing code
- ✅ Check dependencies
- ✅ List relevant files
- ❌ Implement solution immediately

Workers need context before they can execute effectively.

### 4. Keep It Short

First action = 1-5 minutes maximum

- One focused task
- Quick win to build momentum
- Gets worker unstuck and moving
- Not a full implementation

### 5. Provide Clear Next Steps

Always end with "**Then:**" statement that references the next task:

```markdown
**Then:** Implement the logging functions as per Task 1.1.
```

This creates a clear progression path.

### 6. Match Worker Type

Different types of workers need different first actions:

**Code Workers:**
```bash
# Examine existing implementation
cat existing-file.py

# Check for tests
cat tests/test_existing.py
```

**Documentation Workers:**
```bash
# Review what's been implemented
cat .czarina/work/*/workers/*/completion.md

# Check existing docs structure
ls -la docs/
```

**Integration Workers:**
```bash
# List all branches to merge
git branch -a | grep "feat/"

# Check for potential conflicts
git log --all --decorate --oneline --graph
```

**Research/Design Workers:**
```bash
# Review specification
cat spec.md | grep -A 10 "key-topic"

# Document decision criteria
echo "# Options Comparison" > decision.md
```

## Best Practices Checklist

Use this checklist when creating first actions:

### Content
- [ ] Includes specific bash commands (not vague instructions)
- [ ] Commands are copy-pasteable
- [ ] Focuses on exploration/reading before implementation
- [ ] Includes verification command where applicable
- [ ] Ends with clear "Then:" next step
- [ ] References specific task/objective numbers

### Format
- [ ] Uses "## 🚀 YOUR FIRST ACTION" header
- [ ] Has bold description before code block
- [ ] Code block uses bash syntax highlighting
- [ ] Commands have explanatory comments
- [ ] Placed immediately after Mission section
- [ ] Before Objectives section

### Quality
- [ ] Takes 1-5 minutes to complete
- [ ] Produces concrete output (file read, decision made, etc.)
- [ ] Doesn't require prior knowledge or assumptions
- [ ] Doesn't present multiple options (avoid decision paralysis)
- [ ] Worker can verify they completed it successfully

## Common Patterns

### Pattern 1: Read Specification

For tasks requiring design or implementation based on specs:

```markdown
## 🚀 YOUR FIRST ACTION

**Read the [X] specification to understand requirements:**

\```bash
# Read the complete specification
cat docs/spec.md

# Or if in project root
cat path/to/spec.md

# Focus on key section
cat spec.md | grep -A 20 "your-topic"
\```

**Then:** Design [X] based on what you learned and proceed to Objective 1.
```

### Pattern 2: Examine Existing Code

For tasks modifying or extending existing functionality:

```markdown
## 🚀 YOUR FIRST ACTION

**Examine the existing [X] implementation:**

\```bash
# Read current implementation
cat path/to/existing-file.ext

# Check for related files
ls -la path/to/module/

# Look for tests
cat tests/test_existing.ext
\```

**Then:** Plan your changes based on the existing structure (Task 1.1).
```

### Pattern 3: Check Dependencies

For tasks that depend on other workers:

```markdown
## 🚀 YOUR FIRST ACTION

**Check the status of dependency workers:**

\```bash
# Check dependency completion
for worker in dep1 dep2 dep3; do
  echo "=== $worker ==="
  tail -3 .czarina/logs/$worker.log 2>/dev/null || echo "Not started"
done

# Review dependency outputs
ls -la .czarina/worktrees/dependency-name/
\```

**Then:** Integrate the completed work from dependencies (Objective 1).
```

### Pattern 4: Survey Landscape

For integration or coordination tasks:

```markdown
## 🚀 YOUR FIRST ACTION

**Survey all [X] that need integration:**

\```bash
# List all items to integrate
git branch -a | grep "pattern"

# Check status of each
for item in item1 item2 item3; do
  echo "=== $item ==="
  git log main..$item --oneline | head -5
done
\```

**Then:** Create integration plan and start with first item (Task 1.1).
```

### Pattern 5: Create Foundation

For workers creating new systems:

```markdown
## 🚀 YOUR FIRST ACTION

**Create the foundation file/directory:**

\```bash
# Create the main file
touch path/to/new-file.ext

# Or create directory structure
mkdir -p path/to/new/module

# Verify creation
ls -la path/to/
\```

**Then:** Implement core functionality in the new file (Task 1.1).
```

## What to Avoid

### Anti-Pattern 1: Analysis Paralysis

❌ Bad:
```markdown
Please review the project and understand how all the pieces fit together
before beginning your work.
```

✅ Good:
```markdown
**Review the project architecture:**

\```bash
cat docs/ARCHITECTURE.md
tree -L 2 czarina-core/
ls -la czarina-core/templates/
\```

**Then:** Start with Task 1.1.
```

### Anti-Pattern 2: Multiple Options

❌ Bad:
```markdown
You can either:
1. Start with the backend
2. Start with the frontend
3. Start with the tests

Choose whichever makes sense to you.
```

✅ Good:
```markdown
**Start with the backend implementation:**

\```bash
cat backend/current-api.py
grep "def.*endpoint" backend/*.py
\```

**Then:** Implement backend changes (Task 1), then move to frontend (Task 2).
```

### Anti-Pattern 3: Jumping to Implementation

❌ Bad:
```markdown
Begin implementing the authentication system.
```

✅ Good:
```markdown
**Examine current authentication:**

\```bash
grep -r "authenticate" . --include="*.py"
cat backend/auth.py
cat tests/test_auth.py
\```

**Then:** Design authentication improvements (Task 1.1).
```

### Anti-Pattern 4: Only Objectives

❌ Bad:
```markdown
## Objectives

1. Design schema
2. Implement endpoints
3. Add tests
```

✅ Good:
```markdown
## 🚀 YOUR FIRST ACTION

**Review existing API:**

\```bash
cat api/schema.json
grep "@app.route" api/*.py
\```

**Then:** Design new schema (Objective 1).

## Objectives

1. Design schema
2. Implement endpoints
3. Add tests
```

### Anti-Pattern 5: Vague Verbs

Avoid vague verbs without specific actions:

❌ Bad verbs:
- "Understand"
- "Familiarize"
- "Learn about"
- "Get comfortable with"
- "Explore"

✅ Good verbs (with commands):
- "Read" → `cat file.md`
- "Examine" → `cat file.py`
- "Check" → `ls -la dir/`
- "Review" → `grep pattern files`
- "List" → `find . -name pattern`

## Testing Your First Action

Before finalizing a first action, ask:

1. **Can a fresh agent execute this without prior knowledge?**
   - If no, add more context or simpler commands

2. **Is there exactly one command to run first?**
   - If multiple, pick the most important one

3. **Will this produce immediate output/feedback?**
   - If no, add verification command

4. **Does it take <5 minutes?**
   - If no, break into smaller first action

5. **Is the next step crystal clear?**
   - If no, add explicit "Then:" guidance

6. **Could a worker still get stuck?**
   - If yes, make it more specific

## Real-World Examples

These examples are from actual backfilled workers:

### Example: rules-integration

```markdown
## 🚀 YOUR FIRST ACTION

**Create the symlink to the agent-rules library:**

\```bash
# Create symlink from Czarina to agent-rules library
ln -s ~/Source/agent-rules/agent-rules ./czarina-core/agent-rules

# Verify it worked
ls -la czarina-core/agent-rules
\```

**Then:** Add the symlink to .gitignore and proceed to Objective 3 (documentation).
```

**Why effective:**
- Concrete action (create symlink)
- Includes verification
- Clear next step
- Takes <1 minute

### Example: memory-core

```markdown
## 🚀 YOUR FIRST ACTION

**Read the memory specification to understand the schema:**

\```bash
# Read the complete memory specification
cat czarina_memory_spec.md

# Or if it's in the docs folder
cat docs/czarina_memory_spec.md
\```

**Then:** Design the memories.md schema based on what you learned and proceed to Objective 2 (implement file I/O).
```

**Why effective:**
- Starts with reading/understanding
- Two paths (handles uncertainty)
- Clear progression to design
- Builds foundation for implementation

### Example: integration

```markdown
## 🚀 YOUR FIRST ACTION

**Check the status of all dependency branches and plan merge order:**

\```bash
# List all feature branches
git branch -a | grep "feat/v0.7.0"

# Check each branch's status
for branch in rules-integration memory-core memory-search cli-commands config-schema launcher-enhancement; do
  echo "=== $branch ==="
  git log main..feat/v0.7.0-$branch --oneline | head -5
done

# Identify potential merge conflicts early
git log --all --decorate --oneline --graph | head -30
\```

**Then:** Create a merge plan and start with the foundation branches (Objective 1).
```

**Why effective:**
- Systematic survey of landscape
- Proactive conflict detection
- Creates foundation for merge plan
- Specific branch names listed

## Creating First Actions for New Workers

When creating a new worker identity:

### Step 1: Understand the Mission

Read the mission and objectives. Ask:
- What's the very first thing the worker needs to know?
- What existing code/docs should they read?
- What dependencies do they need to check?

### Step 2: Draft the Exploration Command

Write 1-3 bash commands that:
- Read relevant files
- List relevant directories
- Check dependencies or prerequisites

### Step 3: Add Verification (if applicable)

If creating/modifying something:
- Add command to verify it worked
- Show how to check the result

### Step 4: Write the "Then:" Statement

Reference the specific next task:
- Use task numbers (Task 1.1)
- Or objective numbers (Objective 1)
- Be explicit about progression

### Step 5: Test Against Checklist

Run through the best practices checklist above.

## Measuring Success

Success metrics for first actions:

### Quantitative
- ✅ 0 stuck workers per orchestration (down from 1)
- ✅ Worker takes first action within 1-2 minutes
- ✅ Worker completion rate > 95%
- ✅ Zero "what do I do?" questions from workers

### Qualitative
- ✅ Workers report clear understanding of start point
- ✅ No analysis paralysis or overthinking
- ✅ Smooth progression from first action → Task 1
- ✅ Workers build momentum early

## Maintenance

### When to Update First Actions

- New workers report confusion
- Worker gets stuck despite first action
- Better approach is discovered
- Tools/paths change in project

### Version Control

Treat first actions as critical infrastructure:
- Review changes carefully
- Test with real agent before committing
- Document why changes were made
- Keep examples up to date

## Summary

**Remember:** The first action is the most important part of the worker identity.

A worker with:
- ✅ Perfect mission description
- ✅ Detailed objectives
- ✅ Comprehensive deliverables
- ❌ **No first action**

Will still get stuck.

A worker with:
- ✅ Clear first action
- ❌ Mediocre mission description
- ❌ Basic objectives

Will start successfully and can ask questions later.

**First action = activation energy for the entire worker.**

Make it count.

## References

- `.czarina/hopper/issue-worker-onboarding-confusion.md` - Problem definition
- `docs/FIRST_ACTION_EXAMPLES.md` - Good vs bad examples
- `czarina-core/templates/worker-identity-template.md` - Template with first action
- `.czarina/workers/*.md` - 16 real-world examples
