# Czar Coordination & Dependency Tracking

## Overview

The Czar Coordination system manages dependencies between workers and orchestrates the integration of completed work. It implements basic dependency tracking (B4) to detect blocked workers, track progress, and suggest integration strategies.

## Architecture

### Components

1. **`czar-dependency-tracking.sh`** - Dependency tracking and coordination module
2. **`czar-autonomous-v2.sh`** - Main loop (calls `monitor_dependencies()`)
3. **`config.json`** - Worker dependency definitions
4. **`worker-status.json`** - Worker status and completion state

### Dependency Model

```
Worker Dependencies (from config.json):
┌─────────────┐
│  Worker A   │ (no dependencies)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Worker B   │ depends on: [A]
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Worker C   │ depends on: [A, B]
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Integration │ depends on: [A, B, C]
│   Worker    │ (merges all branches)
└─────────────┘
```

## Dependency Tracking

### Dependency States

A dependency is considered **met** if the dependency worker is in one of these states:

| State     | Met? | Rationale                                      |
|-----------|------|------------------------------------------------|
| `working` | ✓    | Work in progress, dependent can start          |
| `idle`    | ✓    | Work complete, ready for dependent             |
| `pending` | ✗    | Not yet started, dependent must wait           |
| `unknown` | ✗    | Status unclear, dependent should wait          |

### Worker Blocked States

A worker is considered **blocked by dependencies** if:

1. Worker status is `working` or `idle` (not `pending`)
2. At least one dependency is in `pending` or `unknown` state

Rationale:
- `pending` workers are not yet blocked, just not started
- `working`/`idle` workers waiting on `pending` dependencies are actively blocked

### Dependency Progress

For each worker with dependencies, track:

```
Progress: N/M
  N = number of dependencies met
  M = total number of dependencies
```

Example:
```
Worker: autonomous-czar
Dependencies: [logging, hopper]
Progress: 2/2 ✓ Ready to start
```

## Integration Readiness

### Criteria for Integration

A worker is **ready for integration** if ALL of these are true:

1. **Status**: `idle` (work completed)
2. **Dependencies**: All dependencies met (N/M where N == M)
3. **Commits**: Has commits on their branch (commits > 0)

### Integration Order

The Czar suggests integration order using topological sort based on dependencies:

```bash
Suggested Integration Order:
1. logging       (no dependencies)
2. phase-mgmt    (no dependencies)
3. hopper        (no dependencies)
4. autonomous-czar (depends on: logging, hopper)
5. qa            (depends on: all above)
```

**Algorithm**:
1. Workers with no dependencies go first
2. Workers with all dependencies met go next
3. Continue until all workers are ordered
4. Handle circular dependencies by breaking ties alphabetically

## Monitoring and Notifications

### Blocked Worker Detection

Every 30 seconds:

```bash
1. Get all workers from config
2. For each worker:
   a. Get status from worker-status.json
   b. Skip if status is "pending" (not yet blocked)
   c. Check if dependencies are met
   d. If not met AND worker is working/idle:
      • Log WORKER_DEPENDENCY_BLOCKED
      • Include blocked_by: list of unmet dependencies
      • Notification cooldown: 1 hour
```

**Notification Cooldown**: To avoid spam, only notify once per hour per worker.

### Integration Readiness Check

Every 15 minutes (iteration % 30 == 0):

```bash
1. Get all integration-ready workers
2. If any ready:
   a. Log INTEGRATION_READY with count and worker list
   b. Generate integration strategy report
   c. Log INTEGRATION_STRATEGY event
```

## Decision Logic

### 1. Dependency Blocking

```bash
# Detection
worker.status in ["working", "idle"]
AND any(dependency.status in ["pending", "unknown"])

# Action
• Log WORKER_DEPENDENCY_BLOCKED
• Include: worker, blocked_by (list of unmet deps)
• Severity: medium
• Cooldown: 1 hour per worker
```

### 2. Integration Ready

```bash
# Detection
worker.status == "idle"
AND all(dependencies.status not in ["pending", "unknown"])
AND worker.commits > 0

# Action
• Log INTEGRATION_READY
• Count ready workers
• Generate integration strategy
```

### 3. Integration Strategy

```bash
# Generated every 15 minutes if workers are ready

Strategy includes:
• Suggested integration order (topological sort)
• For each worker:
  - Position in order
  - Current status
  - Dependency progress (N/M)
  - Readiness indicators:
    ✓ Ready for integration
    ⏳ Not yet started
    🔄 Work in progress
    ⚠️ Blocked by: [list]
```

## Event Types

### Dependency Events

| Event Type                   | Description                          | Level   |
|------------------------------|--------------------------------------|---------|
| `WORKER_DEPENDENCY_BLOCKED`  | Worker blocked by unmet dependencies | DETECT  |
| `DEPENDENCY_NOT_READY`       | Specific dependency not ready        | DETECT  |
| `INTEGRATION_READY`          | Workers ready for integration        | INFO    |
| `INTEGRATION_STRATEGY`       | Integration strategy generated       | INFO    |

### Event Metadata

**WORKER_DEPENDENCY_BLOCKED**:
```json
{
  "worker": "autonomous-czar",
  "blocked_by": "logging hopper",
  "severity": "medium"
}
```

**INTEGRATION_READY**:
```json
{
  "count": "3",
  "workers": "logging phase-mgmt hopper"
}
```

## Configuration

### Defining Dependencies

In `.czarina/config.json`:

```json
{
  "workers": [
    {
      "id": "logging",
      "dependencies": []
    },
    {
      "id": "autonomous-czar",
      "dependencies": ["logging", "hopper"]
    },
    {
      "id": "qa",
      "role": "integration",
      "dependencies": ["logging", "phase-mgmt", "hopper", "autonomous-czar"]
    }
  ]
}
```

### Notification Cooldowns

```bash
# In czar-dependency-tracking.sh
DEPENDENCY_BLOCK_COOLDOWN=3600  # 1 hour between notifications
```

### Integration Check Interval

```bash
# In czar-autonomous-v2.sh
# Integration strategy: every 30 iterations
if [[ $((iteration % 30)) -eq 0 ]]; then
    # At 30s interval, this is every 15 minutes
    check_integration_readiness()
fi
```

## Usage

### View Dependency Status

```bash
# Source the dependency tracking module
source czarina-core/czar-dependency-tracking.sh

# Check if worker dependencies are met
check_worker_dependencies_met "autonomous-czar"
echo $?  # 0 if met, 1 if not met

# Get unmet dependencies
get_unmet_dependencies "autonomous-czar"
# Output: logging hopper

# Get dependency progress
get_dependency_progress "autonomous-czar"
# Output: 2/2 (or 0/2, 1/2, etc.)
```

### Check Integration Readiness

```bash
# Get workers ready for integration
get_integration_ready_workers
# Output: logging
#         phase-mgmt
#         hopper

# Get suggested integration order
suggest_integration_order
# Output: logging phase-mgmt hopper autonomous-czar qa

# Get full integration strategy report
get_integration_strategy
# Output: (formatted report - see example below)
```

### Integration Strategy Example

```
Integration Strategy:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Suggested Integration Order:

  1. logging (status: idle, deps: 0/0)
     ✓ Ready for integration

  2. phase-mgmt (status: idle, deps: 0/0)
     ✓ Ready for integration

  3. hopper (status: working, deps: 0/0)
     🔄 Work in progress

  4. autonomous-czar (status: working, deps: 2/2)
     Dependencies: logging hopper
     🔄 Work in progress

  5. qa (status: pending, deps: 0/4)
     Dependencies: logging phase-mgmt hopper autonomous-czar
     ⏳ Not yet started

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Autonomous Monitoring

The autonomous czar calls `monitor_dependencies(iteration)` on every cycle:

```bash
# Called from czar-autonomous-v2.sh
check_worker_health() {
    # ... worker health checks ...

    # Monitor hoppers (Task 2)
    monitor_hoppers "$idle_count" "${idle_worker_array[@]}"

    # Monitor dependencies (Task 3)
    monitor_dependencies "$iteration"

    # ... status summary ...
}
```

### What monitor_dependencies() Does

1. **Check for blocked workers** (every 30s):
   - Get list of blocked workers
   - For each blocked worker:
     - Get unmet dependencies
     - Check notification cooldown (1 hour)
     - Log `WORKER_DEPENDENCY_BLOCKED` if cooldown expired

2. **Check integration readiness** (every 15 minutes):
   - Get list of integration-ready workers
   - If any ready:
     - Log `INTEGRATION_READY` with count
     - Generate integration strategy
     - Log `INTEGRATION_STRATEGY`

## Integration Workflow

### Manual Integration

When workers are ready, the human operator or QA worker performs integration:

```bash
# 1. Check integration strategy
./czarina-core/czar-dependency-tracking.sh  # view strategy

# 2. For each ready worker (in suggested order):
cd .czarina/worktrees/<worker-id>
git checkout main
git pull
git merge --no-ff <worker-branch>
git push

# 3. Verify integration
./run-tests.sh
./build.sh

# 4. Mark as integrated (update status)
```

### Automated Integration (Future Enhancement)

Future versions could support automated integration:

- Detect integration-ready workers
- Automatically create merge commits in suggested order
- Run CI/CD tests
- Auto-merge if tests pass
- Notify human if conflicts or test failures

## Advanced Features (Future)

### Task-Level Dependencies

Currently tracks worker-level dependencies. Future enhancement:

```json
{
  "task_dependencies": {
    "autonomous-czar/hopper-monitoring": {
      "depends_on": [
        "logging/structured-events",
        "hopper/phase-hopper-api"
      ]
    }
  }
}
```

### Circular Dependency Detection

```bash
# Detect cycles in dependency graph
detect_circular_dependencies() {
    # DFS-based cycle detection
    # Returns: list of workers in cycle
}
```

### Smart Integration

```bash
# Determine if workers can be integrated in parallel
can_integrate_in_parallel() {
    # Check if workers have no dependency relationship
    # Returns: true if safe to merge simultaneously
}
```

## Testing

### Manual Testing

```bash
# 1. Source dependency tracking
source czarina-core/czar-dependency-tracking.sh

# 2. Test dependency checking
worker="autonomous-czar"
echo "Dependencies met: $(check_worker_dependencies_met "$worker" && echo YES || echo NO)"
echo "Unmet: $(get_unmet_dependencies "$worker")"
echo "Progress: $(get_dependency_progress "$worker")"

# 3. Test blocked worker detection
echo "Blocked workers:"
get_blocked_workers

# 4. Test integration readiness
echo "Ready for integration:"
get_integration_ready_workers

# 5. View integration strategy
get_integration_strategy
```

### Validating Decisions

```bash
# View dependency-related decisions
grep "DEPENDENCY\|INTEGRATION" .czarina/status/autonomous-decisions.log

# View in events.jsonl
grep '"event":".*DEPENDENCY\|INTEGRATION"' .czarina/logs/events.jsonl | jq

# Check worker status
jq '.workers[] | {id: .id, status: .status, dependencies: .dependencies}' .czarina/config.json
```

## Troubleshooting

### Worker Appears Blocked Incorrectly

```bash
# Check dependency status manually
for dep in $(get_worker_dependencies "worker-id"); do
    echo "$dep: $(get_worker_status "$dep")"
done

# Verify worker-status.json is up to date
cat .czarina/status/worker-status.json | jq '.last_updated'
```

### Integration Order Seems Wrong

```bash
# View dependency graph
for worker in $(get_worker_ids); do
    deps=$(get_worker_dependencies "$worker")
    echo "$worker -> [$deps]"
done

# Manually verify topological sort
suggest_integration_order
```

### Not Receiving Blocked Notifications

```bash
# Check notification cooldown
grep "WORKER_DEPENDENCY_BLOCKED" .czarina/status/autonomous-decisions.log | tail -5

# Verify worker is actually blocked
is_worker_blocked_by_dependencies "worker-id"
echo $?  # 0 = blocked, 1 = not blocked
```

## References

- **IMPROVEMENT_PLAN B4**: Dependency Tracking (basic implementation)
- **Enhancement #13**: Phase Management (integration phases)
- **IMPROVEMENT_PLAN A3/A4**: Autonomous Czar Loop (monitoring infrastructure)

## See Also

- `czar-autonomous-v2.sh` - Main autonomous czar loop
- `czar-dependency-tracking.sh` - Dependency tracking implementation
- `docs/AUTONOMOUS_CZAR.md` - Autonomous czar documentation
- `config.json` - Worker and dependency configuration
