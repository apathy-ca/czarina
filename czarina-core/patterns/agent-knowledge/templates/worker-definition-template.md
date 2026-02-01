# Worker: [Worker Name] - [Short Description]

## Role
[Single sentence describing the worker's primary responsibility]

## Mission
[Brief 1-2 sentence summary of what the worker will accomplish]

## Agent
[Recommended agent type: aider, cursor, claude-code, etc.]

**Why this agent:**
- [Reason 1 - e.g., "Good at file creation"]
- [Reason 2 - e.g., "Handles documentation well"]

## Branch
`feat/[feature-name]-[worker-name]`

**Example:** `feat/agent-rules-foundation`

## Dependencies

[List workers that must complete before this worker can start]

- **[worker-id-1]** - [Why this dependency exists]
- **[worker-id-2]** - [Why this dependency exists]

**OR** if no dependencies:

None - Can start immediately

## Budget

- **Tokens:** [Estimated tokens] ([Lower bound]-[Upper bound])
- **Duration:** [Estimated days/weeks]

**Reality Check:** Multiply estimates by 1.5-2x for actual usage

## Deliverables

[Concrete list of files, features, or artifacts this worker will produce]

### Primary Deliverables
- [Deliverable 1] - [Description]
- [Deliverable 2] - [Description]
- [Deliverable 3] - [Description]

### Documentation
- [README.md or other documentation]
- [Usage examples]
- [Architecture notes]

### Testing
- [Unit tests]
- [Integration tests if applicable]

**Total Output:** [Estimated number of files, lines of code/documentation]

## Tasks

[Detailed, actionable task list organized by phase or category]

### Setup (Day 1)
- [ ] Read worker identity and instructions
- [ ] Review dependencies and prerequisites
- [ ] Set up logging
- [ ] Create branch and initial directory structure

### Phase 1: [Phase Name] (Days 2-3)
- [ ] [Specific task 1]
- [ ] [Specific task 2]
- [ ] [Specific task 3]
- [ ] Checkpoint: [Commit checkpoint description]

### Phase 2: [Phase Name] (Days 4-5)
- [ ] [Specific task 1]
- [ ] [Specific task 2]
- [ ] [Specific task 3]
- [ ] Checkpoint: [Commit checkpoint description]

### Phase 3: [Phase Name] (Days 6-7)
- [ ] [Specific task 1]
- [ ] [Specific task 2]
- [ ] Final checkpoint: [Commit checkpoint description]

### Completion
- [ ] All deliverables complete
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Branch pushed
- [ ] Worker completion logged
- [ ] Orchestrator notified

## Source Materials

[References to source code, documentation, or examples to analyze]

### Primary Sources
- [Repository or directory 1] - [What to extract]
- [Repository or directory 2] - [What to extract]

### Reference Materials
- [Documentation 1]
- [Pattern library 1]
- [Example project 1]

## File Ownership

[Define which files/directories this worker owns and can modify]

### Owned by This Worker
```
[directory-structure]
├── [path/to/owned/files]
├── [path/to/other/files]
```

### Read-Only (Reference Only)
```
[directory-structure]
├── [path/to/reference/files]
```

### Shared (Coordinate Changes)
```
[directory-structure]
├── [path/to/shared/files]  # Coordinate with [other-worker]
```

## Git Workflow

Branch: `feat/[feature-name]-[worker-name]`

### Commit Pattern

Use conventional commits:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `test` - Tests
- `refactor` - Code refactoring

### Checkpoints

Commit at logical checkpoints:
- [ ] After completing each phase
- [ ] After each major file or feature
- [ ] Before taking breaks
- [ ] At end of work session

### Completion

When all work is complete:
1. Final commit with all remaining changes
2. Push branch to remote
3. Log worker completion
4. Notify orchestrator
5. Wait for QA integration

## Logging

Use structured logging to track progress:

```bash
# Source logging functions
source $(git rev-parse --show-toplevel)/czarina-core/logging.sh

# Log task start
czarina_log_task_start "Task 1.1: [Description]"

# Log checkpoint (after commit)
czarina_log_checkpoint "[checkpoint_name]"

# Log task completion
czarina_log_task_complete "Task 1.1: [Description]"

# Log worker completion
czarina_log_worker_complete
```

**Important Events to Log:**
- Worker start
- Task starts
- Checkpoints (after commits)
- Task completions
- Blockers or issues
- Worker completion

## Pattern Library

[References to patterns and standards this worker should follow]

Before starting, review:
- [Pattern document 1]
- [Pattern document 2]
- [Standard document 1]

## Success Criteria

[Measurable criteria that define when this worker has succeeded]

### Completeness
- [ ] All deliverables created
- [ ] All tasks completed
- [ ] All files present in expected locations

### Quality
- [ ] All code follows coding standards
- [ ] All tests passing
- [ ] Documentation complete and accurate
- [ ] Examples validated

### Integration
- [ ] Branch pushed and accessible
- [ ] No merge conflicts with main
- [ ] Ready for QA integration
- [ ] Handoff artifacts complete

### Budget
- [ ] Within token budget
- [ ] Within timeline estimate
- [ ] No scope creep

## Collaboration

[How this worker interacts with other workers]

### Upstream Dependencies
- **[Worker 1]:** [What this worker needs from them]
- **[Worker 2]:** [What this worker needs from them]

### Downstream Dependents
- **[Worker 3]:** [What they need from this worker]
- **[Worker 4]:** [What they need from this worker]

### Handoff to QA
When complete, ensure:
- [ ] All deliverables in branch
- [ ] Documentation complete
- [ ] Known issues documented
- [ ] Integration notes provided

## Notes

[Any additional context, warnings, or important information]

- [Important note 1]
- [Important note 2]
- [Known challenges or gotchas]

## Example Usage

[Optional: Show how to use this worker definition]

### Quick Start

```bash
# Read your identity
cat WORKER_IDENTITY.md

# Read this full definition
cat .czarina/workers/[worker-name].md

# Start logging
source czarina-core/logging.sh
czarina_log_task_start "Setup"

# Begin work!
```

---

**Template Version:** 1.0.0
**Last Updated:** 2025-12-26
**Source:** Czarina orchestration patterns
