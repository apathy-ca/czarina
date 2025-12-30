# Phase Completion Detection

Czarina includes a sophisticated phase completion detection system that automatically determines when all workers in a phase have completed their work.

## Overview

The `phase-completion-detector.sh` script checks multiple signals to determine if a phase is complete:

1. **Worker completion logs** - Checks for `WORKER_COMPLETE` event markers
2. **Git branch merge status** - Verifies branches are merged to the omnibus branch
3. **Worker status files** - Examines `worker-status.json` for completion status

## Usage

### Basic Usage

```bash
# Check current phase
./czarina-core/phase-completion-detector.sh --config-file .czarina/config.json

# Check specific phase
./czarina-core/phase-completion-detector.sh --config-file .czarina/config.json --phase 2

# Verbose output
./czarina-core/phase-completion-detector.sh --config-file .czarina/config.json --verbose

# JSON output (for automation)
./czarina-core/phase-completion-detector.sh --config-file .czarina/config.json --json
```

### Command Line Options

- `--config-file <path>` - Path to config.json (default: ./config.json)
- `--phase <number>` - Phase number to check (default: current phase from config)
- `--verbose` - Enable verbose diagnostic output
- `--json` - Output results in JSON format
- `--help` - Show help message

### Exit Codes

- `0` - Phase is complete
- `1` - Phase is not complete
- `2` - Error occurred (e.g., config file not found)

## Configuration

### Completion Modes

You can configure how strictly the detector checks for completion by setting `phase_completion_mode` in your `config.json`:

```json
{
  "project": {
    "name": "My Project",
    "phase": 1,
    ...
  },
  "phase_completion_mode": "any",
  "workers": [...]
}
```

#### Available Modes

**`any` (default, recommended)**
- Phase is complete if ANY completion signal is detected
- Most flexible mode - good for rapid iteration
- Worker is complete if:
  - Has `WORKER_COMPLETE` marker in logs, OR
  - Branch is merged to omnibus, OR
  - Status is "complete" in worker-status.json

**`strict`**
- Requires log marker AND either branch merged or status complete
- Good balance between safety and flexibility
- Worker is complete if:
  - Has `WORKER_COMPLETE` marker in logs, AND
  - (Branch is merged to omnibus OR status is "complete")

**`all`**
- Requires ALL completion signals
- Most conservative mode - use for critical releases
- Worker is complete if:
  - Has `WORKER_COMPLETE` marker in logs, AND
  - Branch is merged to omnibus, AND
  - Status is "complete" in worker-status.json

### Example Configuration

```json
{
  "project": {
    "name": "Example Project",
    "slug": "example",
    "version": "1.0.0",
    "phase": 1,
    "repository": "/path/to/project",
    "orchestration_dir": ".czarina"
  },
  "omnibus_branch": "release/v1.0",
  "phase_completion_mode": "any",
  "workers": [
    {
      "id": "backend",
      "role": "core",
      "branch": "feat/backend",
      "phase": 1,
      "description": "Backend implementation"
    },
    {
      "id": "frontend",
      "role": "core",
      "branch": "feat/frontend",
      "phase": 1,
      "description": "Frontend implementation"
    },
    {
      "id": "docs",
      "role": "technical",
      "branch": "feat/documentation",
      "phase": 1,
      "description": "Documentation"
    }
  ]
}
```

## Output Formats

### Text Output

```
Phase 1 is INCOMPLETE (1/3 workers)
Incomplete workers: frontend docs
```

### JSON Output

```json
{
  "phase": 1,
  "complete": false,
  "total_workers": 3,
  "completed_workers": 1,
  "incomplete_workers": [
    "frontend",
    "docs"
  ],
  "completion_mode": "any",
  "timestamp": "2025-12-29T22:30:00-05:00"
}
```

## Integration with Autonomous Daemon

The autonomous daemon uses the phase completion detector to automatically:

1. Monitor phase completion status
2. Trigger phase transitions when ready
3. Launch workers for the next phase
4. Archive completed phase data

The daemon calls the detector every monitoring cycle and takes action when a phase is detected as complete.

## Worker Completion Signals

### 1. Worker Completion Logs

Workers should log completion events using the czarina logging system:

```bash
source czarina-core/logging.sh
czarina_log_worker_complete
```

This creates a `WORKER_COMPLETE` marker in the worker's log file at `.czarina/logs/<worker-id>.log`.

### 2. Git Branch Merge Status

The detector checks if worker branches have been fully merged into the omnibus branch:

```bash
git log <omnibus-branch>..<worker-branch> --oneline
```

If this returns no commits, the branch is considered fully merged.

### 3. Worker Status File

The `worker-status.json` file (managed by `update-worker-status.sh`) contains current worker status:

```json
{
  "workers": {
    "backend": {
      "status": "complete",
      ...
    }
  }
}
```

Valid completion statuses: `"complete"` or `"completed"`

## Multi-Phase Support

The detector supports multiple phases by filtering workers based on their `phase` property:

```json
{
  "workers": [
    {
      "id": "foundation",
      "phase": 1,
      ...
    },
    {
      "id": "enhancement",
      "phase": 2,
      ...
    }
  ]
}
```

Workers without a `phase` property are assumed to be Phase 1 workers.

## Testing

A comprehensive test suite is included:

```bash
./czarina-core/test-phase-completion-detector.sh
```

The test suite validates:
- Script executability and help output
- Config file validation
- Text and JSON output formats
- Phase detection logic
- Verbose mode
- Integration with real project configs

## Troubleshooting

### "No workers found for phase X"

Check that your config.json has workers with `"phase": X` or no phase property (defaults to phase 1).

### "Omnibus branch does not exist"

Ensure the omnibus branch specified in config.json exists:

```bash
git branch -a | grep <omnibus-branch>
```

### All workers showing incomplete

Verify that:
1. Workers have logged `WORKER_COMPLETE` events
2. Worker branches exist and are merged
3. Worker status file is up to date

Run with `--verbose` to see detailed diagnostic output:

```bash
./czarina-core/phase-completion-detector.sh --config-file .czarina/config.json --verbose
```

## Implementation Notes

### Detection Algorithm

For each worker in the specified phase:

1. Check for `WORKER_COMPLETE` in `logs/<worker-id>.log`
2. Check if `<worker-branch>` is fully merged to `<omnibus-branch>`
3. Check if status is "complete" in `worker-status.json`
4. Apply completion mode logic to determine if worker is complete

Phase is complete when ALL workers are complete.

### Performance

The detector is designed to be fast:
- O(n) where n = number of workers in phase
- Minimal git operations (only branch comparison)
- No network calls
- Stateless (can be called repeatedly)

### Thread Safety

The detector is read-only and safe to call concurrently from multiple processes.

## See Also

- [Autonomous Daemon](../AUTONOMOUS_DAEMON.md) - Daemon that uses the phase detector
- [Logging System](../logging.sh) - Worker logging functions
- [Phase Management](../phase-close.sh) - Phase closeout and archival
