# Structured Logging System

## Overview

Czarina uses structured logging to track orchestration activity.

**Logs generated:**
- `.czarina/logs/orchestration.log` - Overall orchestration
- `.czarina/logs/<worker-id>.log` - Per-worker activity (human-readable)
- `.czarina/logs/events.jsonl` - Machine-readable event stream
- `.czarina/worker-status.json` - Derived worker status (auto-generated)

## For Workers

### Logging Functions

```bash
# Source logging (usually already available)
source czarina-core/logging.sh

# Log task progress
czarina_log_task_start "Task 1.1: Implement feature X"
czarina_log_checkpoint "feature_x_implemented"
czarina_log_task_complete "Task 1.1: Implement feature X"

# When completely done
czarina_log_worker_complete
```

### Auto-Logging

Git commits are automatically logged via hooks. No action needed.

## For Czar

Worker status is automatically derived from logs:

```bash
# Extract current status
./czarina-core/extract-worker-status.sh

# View status
cat .czarina/worker-status.json
```

## Event Stream Format

Each line in `events.jsonl` is a JSON object:

```json
{"ts":"2025-12-26T10:30:00Z","event":"TASK_START","worker":"logging","meta":{"task":"Task 1.1"}}
{"ts":"2025-12-26T11:00:00Z","event":"CHECKPOINT","worker":"logging","meta":{"checkpoint":"logging_active"}}
{"ts":"2025-12-26T11:30:00Z","event":"TASK_COMPLETE","worker":"logging","meta":{"task":"Task 1.1"}}
```

**Event types:**
- `ORCHESTRATION_START` - Orchestration began
- `WORKER_START` - Worker initialized
- `TASK_START` - Worker started task
- `CHECKPOINT` - Milestone reached (usually commit)
- `TASK_COMPLETE` - Task finished
- `WORKER_COMPLETE` - Worker done with all tasks
