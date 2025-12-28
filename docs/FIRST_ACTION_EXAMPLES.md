# First Action Examples

This document provides examples of good and bad first actions in worker identities, explaining what makes them effective or ineffective.

## The Problem

**Issue:** 1 worker per orchestration gets stuck and doesn't know what to do first.

**Root Cause:** Worker identities describe mission/objectives but don't have an explicit first step.

**Solution:** Add unmissable "🚀 YOUR FIRST ACTION" section with specific commands.

## Good First Actions ✅

### Example 1: rules-integration

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

**Why this is good:**
- ✅ **Specific command** - Exact bash command to run
- ✅ **Verifiable** - Includes a check command
- ✅ **Clear next step** - Says what to do after
- ✅ **Actionable** - Worker can execute immediately
- ✅ **Unambiguous** - No decision paralysis

### Example 2: memory-search

```markdown
## 🚀 YOUR FIRST ACTION

**Research and choose the embedding provider:**

\```bash
# Review the memory specification for embedding requirements
cat czarina_memory_spec.md | grep -A 10 "embedding"

# Check if OpenAI API key is available
echo $OPENAI_API_KEY

# Document your decision: create a brief comparison
\```

**Then:** Document your choice (OpenAI API vs local) with rationale and proceed to Objective 2 (implement vector indexing).
```

**Why this is good:**
- ✅ **Multiple specific commands** - Clear exploration steps
- ✅ **Research-oriented** - Appropriate for design task
- ✅ **Concrete output** - "Document your decision"
- ✅ **Clear next step** - Explicit progression
- ✅ **Decision guidance** - Helps worker understand what they're choosing

### Example 3: integration

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

**Why this is good:**
- ✅ **Systematic approach** - Loop through all dependencies
- ✅ **Conflict detection** - Proactive problem-finding
- ✅ **Planning step** - Sets up for successful execution
- ✅ **Specific commands** - Copy-pasteable
- ✅ **Context building** - Helps worker understand landscape

## Bad First Actions ❌

### Example 1: Too Vague

```markdown
## First Steps

Please review the project structure and familiarize yourself with the codebase before beginning.
```

**Why this is bad:**
- ❌ **No specific command** - What does "review" mean?
- ❌ **Analysis paralysis** - Where to start reviewing?
- ❌ **No verification** - How do you know when you're done?
- ❌ **No next step** - What comes after familiarization?
- ❌ **Passive voice** - Not action-oriented

**How to fix:**
```markdown
## 🚀 YOUR FIRST ACTION

**Review the project structure:**

\```bash
# List the main directories
tree -L 2 .

# Read the architecture overview
cat docs/ARCHITECTURE.md

# Identify the files you'll be modifying
ls -la czarina-core/
\```

**Then:** Read your detailed task list at ../workers/your-worker-id.md and begin Task 1.1.
```

### Example 2: Too Many Choices

```markdown
## Getting Started

You can either:
1. Start by reading the documentation
2. Explore the codebase to understand the structure
3. Look at existing examples
4. Review the test suite

Choose whichever approach feels most comfortable to you.
```

**Why this is bad:**
- ❌ **Decision paralysis** - Which option to choose?
- ❌ **No specific commands** - All options are vague
- ❌ **No guidance** - "Most comfortable" is subjective
- ❌ **Wastes time** - Worker has to decide before acting
- ❌ **Inconsistent** - Different workers will do different things

**How to fix:**
```markdown
## 🚀 YOUR FIRST ACTION

**Understand the existing test structure:**

\```bash
# Read the test documentation
cat docs/TESTING.md

# Examine the current test suite
ls -la tests/

# Run existing tests to see baseline
pytest tests/ -v
\```

**Then:** Design your new tests based on the existing patterns (Task 1.1).
```

### Example 3: Jumps to Execution

```markdown
## Start Coding

Begin implementing the new authentication system as described in the objectives.
```

**Why this is bad:**
- ❌ **No exploration phase** - Goes straight to coding
- ❌ **No specific command** - "Implement" is not actionable
- ❌ **No context building** - Doesn't understand existing code
- ❌ **High risk** - Likely to make wrong assumptions
- ❌ **No verification** - How to check if on right track?

**How to fix:**
```markdown
## 🚀 YOUR FIRST ACTION

**Examine the current authentication system:**

\```bash
# Find existing auth code
grep -r "authenticate" . --include="*.py"

# Read the current implementation
cat backend/auth.py

# Check for any existing tests
cat tests/test_auth.py
\```

**Then:** Design your authentication improvements based on what exists (Task 1.1).
```

### Example 4: Only Objectives, No Action

```markdown
## Objectives

1. Design the new API schema
2. Implement the endpoints
3. Add tests
4. Update documentation
```

**Why this is bad:**
- ❌ **No first action** - Just a list of objectives
- ❌ **Assumes knowledge** - Worker doesn't know where to start
- ❌ **No prioritization** - Which objective first?
- ❌ **No commands** - What to actually type?
- ❌ **Leads to stuckness** - This is the pattern that causes the 1-per-orchestration stuck worker

**How to fix:**
```markdown
## 🚀 YOUR FIRST ACTION

**Review the existing API structure:**

\```bash
# Read the current API schema
cat api/schema.json

# Check existing endpoints
grep -r "@app.route" api/

# Review API documentation
cat docs/API.md
\```

**Then:** Design your new schema based on existing patterns (Objective 1).

## Objectives

1. Design the new API schema
2. Implement the endpoints
3. Add tests
4. Update documentation
```

## First Action Template

Use this template when creating new worker identities:

```markdown
## 🚀 YOUR FIRST ACTION

**[Brief description of what to do]:**

\```bash
# [Comment explaining first command]
[specific command 1]

# [Comment explaining verification]
[verification command]

# [Optional: additional exploration]
[exploration command]
\```

**Then:** [What to do after completing this action - reference to next task].
```

## Best Practices

### 1. Make it Visual

Use the 🚀 emoji to make the section unmissable.

### 2. Start with Exploration

Most first actions should be **reading** and **understanding** before coding:
- Read specifications
- Examine existing code
- Check dependencies
- Review documentation

### 3. Be Command-Specific

Always include actual bash commands, not vague instructions:
- ✅ `cat czarina-core/logging.sh`
- ❌ "Review the logging system"

### 4. Include Verification

Add a command to verify the action succeeded:
- Creating file: `ls -la <filepath>`
- Installing package: `pip list | grep <package>`
- Symlink: `ls -la <symlink>`

### 5. Provide Clear Next Steps

End with "**Then:**" statement:
- ✅ "Then: Implement the logging functions as per Task 1.1"
- ❌ "Continue with your work"

### 6. Keep it Short

First action should be 1-5 minutes max:
- One focused exploration or setup task
- Not a full implementation
- Gets worker unstuck and moving

### 7. Match Task Type

- **Code tasks**: Explore existing code structure
- **Documentation tasks**: Read what's been implemented
- **Integration tasks**: Check all branches to merge
- **Design tasks**: Research options and document decision

## Anti-Patterns to Avoid

1. ❌ **Starting with objectives** - That's not a first action
2. ❌ **"Get familiar with..."** - Too vague
3. ❌ **Multiple options** - Causes decision paralysis
4. ❌ **No commands** - Must have concrete bash/commands
5. ❌ **Jumping to implementation** - Should start with exploration
6. ❌ **No next step** - Worker needs guidance on what's after

## Success Metrics

A good first action should result in:
- ✅ Worker takes action within 1 minute of reading identity
- ✅ Worker produces concrete output (file read, decision made, etc.)
- ✅ Worker knows exactly what to do next
- ✅ Worker doesn't ask "what do I do?" or sit idle
- ✅ 0 stuck workers per orchestration (down from 1)

## References

- `.czarina/hopper/issue-worker-onboarding-confusion.md` - Original problem definition
- `czarina-core/templates/worker-identity-template.md` - Standard template
- `.czarina/workers/*.md` - Real-world examples of first actions
