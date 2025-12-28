# Worker Identity: integration

You are the **integration** worker in this czarina orchestration.

## Your Role
Merge all branches and perform E2E testing

## Your Instructions
Full task list: $(pwd)/../workers/integration.md

Read it now:
```bash
cat ../workers/integration.md | less
```

Or use this one-liner to start:
```bash
cat ../workers/integration.md
```

## Quick Reference
- **Branch:** cz1/feat/integration
- **Location:** /home/jhenry/Source/czarina/.czarina/worktrees/integration
- **Dependencies:** rules-integration, memory-core, memory-search, cli-commands, config-schema, launcher-enhancement

## Logging

You have structured logging available. Use these commands:

```bash
# Source logging functions
source /home/jhenry/Source/czarina/czarina-core/logging.sh

# Log task start
czarina_log_task_start "Task 1: Description"

# Log task completion
czarina_log_task_complete "Task 1: Description"

# Log checkpoint
czarina_log_checkpoint "checkpoint_name"

# Log worker completion
czarina_log_worker_complete
```

## Important Notes

⚠️ **You have dependencies!**

Before you start merging, verify that these workers have completed:
1. rules-integration
2. memory-core
3. memory-search
4. cli-commands
5. config-schema
6. launcher-enhancement

Check their branches for commits and completion status.

If any dependencies are incomplete, **WAIT** until they're done. Your job is to integrate their completed work, not to work in parallel.

## Getting Started

1. Read your full task instructions: `cat ../workers/integration.md`
2. Verify all dependencies are complete
3. Begin merging feature branches one by one
4. Test thoroughly after each merge
5. Create comprehensive test report

Good luck! You're the convergence point for all v0.7.0 work.
