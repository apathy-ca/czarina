# Worker: Dependencies
## Worker Dependency Enforcement System

**Stream:** 4
**Duration:** Week 2 (4 days, parallel with coordination)
**Branch:** `feat/dependency-enforcement`
**Agent:** Aider (recommended)
**Dependencies:** `foundation`

---

## Mission

Implement worker dependency enforcement so workers can wait for dependencies to complete before starting work. Make parallel vs sequential execution explicit and configurable.

## 🚀 YOUR FIRST ACTION

**Examine how dependencies are currently defined in config.json:**

```bash
# Check the current config schema
cat .czarina/config.json | jq '.workers[] | {id, dependencies}'

# Look for any existing dependency handling
grep -r "dependencies" czarina czarina-core/

# Review the foundation worker's logging to understand WORKER_COMPLETE events
cat czarina-core/logging.sh 2>/dev/null || echo "Logging system not yet implemented"
```

**Then:** Create the dependencies.sh script and start implementing the dependency parser (Task 1.1).

## Goals

- Workers respect dependency chains from config.json
- Configurable orchestration modes (parallel_spike vs sequential_dependencies)
- Workers can block waiting for dependency completion
- Clear status indication when workers are waiting
- Dependency graph visualization

---

## Tasks

### Task 1: Dependency Detection (1.5 days)

#### 1.1: Dependency Parser
**File:** `czarina-core/dependencies.sh` (NEW)

Parse dependencies from config.json:
```bash
get_worker_dependencies() {
  local worker_id="$1"
  jq -r ".workers[] | select(.id == \"$worker_id\") | .dependencies[]" \
    .czarina/config.json 2>/dev/null
}

check_dependencies_met() {
  local worker_id="$1"
  local deps=$(get_worker_dependencies "$worker_id")

  if [ -z "$deps" ]; then
    return 0  # No dependencies
  fi

  # Check each dependency
  for dep in $deps; do
    # Look for WORKER_COMPLETE event in dependency's log
    if ! grep -q "WORKER_COMPLETE" .czarina/logs/$dep.log 2>/dev/null; then
      echo "Waiting for dependency: $dep"
      return 1
    fi
  done

  return 0  # All dependencies met
}
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/dependencies.sh
git commit -m "feat(dependencies): Add dependency parsing and checking"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: dependency_parser" >> .czarina/logs/dependencies.log
```

#### 1.2: Dependency Graph
**File:** `czarina-core/dependencies.sh` (UPDATE)

Generate dependency graph:
```bash
generate_dependency_graph() {
  echo "digraph dependencies {"
  jq -r '.workers[] | "\(.id) -> \(.dependencies[])"' .czarina/config.json | \
    while read line; do
      echo "  $line;"
    done
  echo "}"
}

# Usage: czarina deps graph | dot -Tpng > deps.png
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/dependencies.sh
git commit -m "feat(dependencies): Add dependency graph generation"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: dependency_graph" >> .czarina/logs/dependencies.log
```

---

### Task 2: Orchestration Modes (1.5 days)

#### 2.1: Configuration Schema
**File:** `docs/CONFIGURATION.md` (UPDATE)

Add orchestration mode to config.json schema:
```json
{
  "orchestration": {
    "mode": "parallel_spike",  // or "sequential_dependencies"
    "allow_parallel_when_possible": true,
    "timeout_hours": 24
  }
}
```

**Modes:**
- `parallel_spike`: All workers start immediately (current behavior)
- `sequential_dependencies`: Workers wait for dependencies
- `hybrid`: Parallel where possible, sequential for dependencies

**COMMIT CHECKPOINT:**
```bash
git add docs/CONFIGURATION.md
git commit -m "docs(dependencies): Document orchestration mode configuration"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: orchestration_config" >> .czarina/logs/dependencies.log
```

#### 2.2: Mode Implementation
**File:** `czarina` (UPDATE)

Implement orchestration modes in launch:
```bash
launch_workers() {
  MODE=$(jq -r '.orchestration.mode // "parallel_spike"' .czarina/config.json)

  case "$MODE" in
    parallel_spike)
      # Current behavior: launch all workers immediately
      for worker in $(jq -r '.workers[].id' .czarina/config.json); do
        launch_worker "$worker"
      done
      ;;

    sequential_dependencies)
      # New behavior: check dependencies before launching
      for worker in $(jq -r '.workers[].id' .czarina/config.json); do
        launch_worker_with_deps "$worker"
      done
      ;;

    hybrid)
      # Launch independent workers immediately
      # Queue dependent workers
      launch_hybrid_mode
      ;;
  esac
}

launch_worker_with_deps() {
  local worker_id="$1"

  # Add dependency check to worker startup
  cat >> .czarina/worktrees/$worker_id/.worker-init << 'EOF'
# Check dependencies before starting
while ! check_dependencies_met "$WORKER_ID"; do
  echo "[$(date +%H:%M:%S)] 🚧 BLOCKED: Waiting for dependencies" >> "$WORKER_LOG"
  sleep 60
done
echo "[$(date +%H:%M:%S)] ✅ DEPENDENCIES_MET: Proceeding with work" >> "$WORKER_LOG"
EOF

  launch_worker "$worker_id"
}
```

**COMMIT CHECKPOINT:**
```bash
git add czarina
git commit -m "feat(dependencies): Implement orchestration mode execution"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: orchestration_modes" >> .czarina/logs/dependencies.log
```

---

### Task 3: Dependency Monitoring (1 day)

#### 3.1: Daemon Integration
**File:** `czarina-core/daemon.sh` (UPDATE)

Show dependency status in daemon output:
```bash
daemon_show_dependencies() {
  for worker in $(jq -r '.workers[].id' .czarina/config.json); do
    DEPS=$(get_worker_dependencies "$worker")

    if [ -n "$DEPS" ]; then
      echo "  Dependencies: $DEPS"

      for dep in $DEPS; do
        if grep -q "WORKER_COMPLETE" .czarina/logs/$dep.log 2>/dev/null; then
          echo "    ✅ $dep (complete)"
        else
          echo "    ⏳ $dep (waiting)"
        fi
      done
    fi
  done
}
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/daemon.sh
git commit -m "feat(dependencies): Add dependency status to daemon output"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: daemon_deps" >> .czarina/logs/dependencies.log
```

#### 3.2: CLI Commands
**File:** `czarina` (UPDATE)

Add dependency commands:
```bash
deps)
  case "$2" in
    graph)
      generate_dependency_graph
      ;;
    check)
      WORKER_ID="$3"
      if check_dependencies_met "$WORKER_ID"; then
        echo "✅ All dependencies met for $WORKER_ID"
      else
        echo "⏳ Waiting for dependencies:"
        get_worker_dependencies "$WORKER_ID" | while read dep; do
          if grep -q "WORKER_COMPLETE" .czarina/logs/$dep.log 2>/dev/null; then
            echo "  ✅ $dep"
          else
            echo "  ⏳ $dep"
          fi
        done
      fi
      ;;
    *)
      echo "Usage: czarina deps [graph|check <worker-id>]"
      ;;
  esac
  ;;
```

**COMMIT CHECKPOINT:**
```bash
git add czarina
git commit -m "feat(dependencies): Add CLI commands for dependency management"
echo "[$(date +%H:%M:%S)] 🎉 WORKER_COMPLETE: All dependency tasks done" >> .czarina/logs/dependencies.log
```

---

## Deliverables

- ✅ `czarina-core/dependencies.sh` (~200 lines)
- ✅ Updated `czarina` main script
- ✅ Updated `czarina-core/daemon.sh`
- ✅ Updated `docs/CONFIGURATION.md`
- ✅ CLI commands: `czarina deps graph`, `czarina deps check`

---

## Success Metrics

- [ ] Dependencies parsed correctly from config.json
- [ ] Workers wait for dependencies in sequential mode
- [ ] Parallel mode works as before
- [ ] Dependency graph generates correctly
- [ ] Daemon shows dependency status
- [ ] CLI commands functional

---

## Testing Plan

### Test 1: Sequential Mode
1. Create config with dependencies: qa → [security-1, security-2]
2. Set `orchestration.mode: "sequential_dependencies"`
3. Launch orchestration
4. Verify QA worker waits for security-1 and security-2

### Test 2: Parallel Mode
1. Set `orchestration.mode: "parallel_spike"`
2. Launch orchestration
3. Verify all workers start immediately

### Test 3: Dependency Graph
1. Run `czarina deps graph | dot -Tpng > graph.png`
2. Verify graph shows correct dependency relationships

---

## Integration Notes

Depends on:
- `foundation` - Needs logging system to detect WORKER_COMPLETE events

Works with:
- `coordination` - Czar can show dependency status
- All other workers benefit from dependency enforcement

---

## References

- Enhancement #6: Dependency Enforcement
- SARK v1.3.0 orchestration (QA worker ignored dependencies)
