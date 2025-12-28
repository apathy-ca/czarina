# Worker: Foundation
## Structured Logging + Workspace Architecture

**Stream:** 1
**Duration:** Week 1 (1 week)
**Branch:** `feat/structured-logging-workspace`
**Agent:** Aider (recommended)
**Dependencies:** None

---

## Mission

Implement the foundational infrastructure for czarina v0.5.0: structured logging system and session workspace architecture. These are the building blocks for all other enhancements.

## 🚀 YOUR FIRST ACTION

**Create the structured logging infrastructure:**

```bash
# Create the logging script file
touch czarina-core/logging.sh

# Add the basic log directory structure and initialization function
# Start implementing czarina_log_init() as described in Task 1.1
```

**Then:** Implement the logging functions (czarina_log_worker, czarina_log_daemon, czarina_log_event) as per Task 1.1.

## Goals

- Workers can log to `.czarina/logs/<worker>.log`
- Event stream in JSON Lines format (`.czarina/logs/events.jsonl`)
- Session workspace structure (`.czarina/work/<session-id>/`)
- Worker artifacts captured (plans, completions, tasks)
- Clean separation of logs, status, and work artifacts

---

## Tasks

### Task 1: Structured Logging System (3 days)

#### 1.1: Log Directory Structure
**File:** `czarina-core/logging.sh` (NEW)

Create logging infrastructure:
```bash
.czarina/
├── logs/
│   ├── <worker-id>.log         # Human-readable worker logs
│   ├── orchestration.log       # Daemon + Czar events
│   └── events.jsonl            # Machine-readable event stream
```

**Functions to implement:**
```bash
czarina_log_init()              # Create log directories
czarina_log_worker()            # Log worker event
czarina_log_daemon()            # Log daemon event
czarina_log_event()             # Append to events.jsonl
czarina_log_parse_last()        # Get last log entry for worker
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/logging.sh
git commit -m "feat(foundation): Add structured logging infrastructure"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: logging_infrastructure" >> .czarina/logs/foundation.log
```

#### 1.2: Worker Log Helper
**File:** `.czarina/.worker-init` (UPDATE)

Add logging initialization to worker startup:
```bash
# Create worker log
WORKER_LOG="$CZARINA_DIR/logs/${WORKER_ID}.log"
mkdir -p "$CZARINA_DIR/logs"
touch "$WORKER_LOG"

# Log worker start
echo "[$(date +%H:%M:%S)] 🚀 WORKER_START: ${WORKER_ID}" >> "$WORKER_LOG"

# Export helper function
export WORKER_ID
export WORKER_LOG
cat >> ~/.bashrc << 'EOF'
czlog() {
  echo "[$(date +%H:%M:%S)] $*" >> "${WORKER_LOG:-/dev/null}"
}
EOF
source ~/.bashrc
```

**COMMIT CHECKPOINT:**
```bash
git add .czarina/.worker-init
git commit -m "feat(foundation): Add worker logging to initialization"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: worker_log_helper" >> .czarina/logs/foundation.log
```

#### 1.3: Event Stream Format
**File:** `docs/LOGGING.md` (NEW)

Document event types and format:
```markdown
# Czarina Logging System

## Event Types

### Worker Events
- WORKER_START
- TASK_START
- TASK_COMPLETE
- FILE_CREATE
- FILE_MODIFY
- TEST_RUN
- COMMIT
- CHECKPOINT
- WORKER_COMPLETE
- ERROR
- BLOCKED

### Daemon Events
- DAEMON_START
- DAEMON_ITERATION
- AUTO_APPROVE
- WORKER_DETECTED_IDLE

### Czar Events
- CZAR_START
- STATUS_REPORT
- INTEGRATION_READY

## Format

### Worker Logs (Human-Readable)
[HH:MM:SS] [EMOJI] EVENT_TYPE: description (key=value)

### Event Stream (Machine-Readable)
{"ts":"ISO8601","worker":"id","event":"TYPE","metadata":{}}
```

**COMMIT CHECKPOINT:**
```bash
git add docs/LOGGING.md
git commit -m "docs(foundation): Document logging system format and events"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: logging_docs" >> .czarina/logs/foundation.log
```

---

### Task 2: Workspace Architecture (3 days)

#### 2.1: Session Workspace Structure
**File:** `czarina-core/workspace.sh` (NEW)

Create workspace management functions:
```bash
.czarina/work/
├── session-<timestamp>/
│   ├── session.json
│   ├── workers/
│   │   ├── <worker-id>/
│   │   │   ├── plan.md
│   │   │   ├── tasks/
│   │   │   ├── completion.md
│   │   │   ├── commits.log
│   │   │   └── metrics.json
│   ├── integration/
│   ├── coordination/
│   └── CLOSEOUT.md
```

**Functions:**
```bash
czarina_workspace_init()        # Create session workspace
czarina_workspace_copy_plan()   # Copy worker definition to workspace
czarina_workspace_task()        # Create task artifact file
czarina_workspace_completion()  # Create completion report
czarina_workspace_metrics()     # Generate worker metrics
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/workspace.sh
git commit -m "feat(foundation): Add workspace management system"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: workspace_structure" >> .czarina/logs/foundation.log
```

#### 2.2: Launch Integration
**File:** `czarina` (UPDATE)

Integrate workspace creation into launch command:
```bash
# In czarina launch:
SESSION_ID="session-$(date +%Y-%m-%d-%H-%M)"
czarina_workspace_init "$SESSION_ID"

# Copy worker plans
for worker in $(jq -r '.workers[].id' .czarina/config.json); do
  czarina_workspace_copy_plan "$SESSION_ID" "$worker"
done

# Create session metadata
cat > .czarina/work/$SESSION_ID/session.json << EOF
{
  "session_id": "$SESSION_ID",
  "project": "$(jq -r '.project.name' .czarina/config.json)",
  "version": "$(jq -r '.project.version' .czarina/config.json)",
  "started": "$(date -Iseconds)",
  "status": "RUNNING"
}
EOF
```

**COMMIT CHECKPOINT:**
```bash
git add czarina
git commit -m "feat(foundation): Integrate workspace creation into launch"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: launch_integration" >> .czarina/logs/foundation.log
```

#### 2.3: Session Metadata
**File:** `czarina-core/session.sh` (NEW)

Session management utilities:
```bash
czarina_session_current()       # Get current session ID
czarina_session_update()        # Update session.json
czarina_session_list()          # List all sessions
czarina_session_status()        # Get session status
```

**COMMIT CHECKPOINT:**
```bash
git add czarina-core/session.sh
git commit -m "feat(foundation): Add session management utilities"
echo "[$(date +%H:%M:%S)] 💾 CHECKPOINT: session_management" >> .czarina/logs/foundation.log
```

---

### Task 3: Testing & Documentation (1 day)

#### 3.1: Test Logging System
**File:** `tests/test-logging.sh` (NEW)

Test cases:
- Log directory creation
- Worker log appending
- Event stream format
- Log parsing functions

#### 3.2: Test Workspace System
**File:** `tests/test-workspace.sh` (NEW)

Test cases:
- Session creation
- Worker plan copying
- Task artifact creation
- Metrics generation

#### 3.3: Update Documentation
**Files to update:**
- `README.md` - Add logging section
- `QUICK_START.md` - Mention log files
- `docs/ARCHITECTURE.md` (NEW) - System architecture

**COMMIT CHECKPOINT:**
```bash
git add tests/ docs/ README.md QUICK_START.md
git commit -m "feat(foundation): Add tests and documentation"
echo "[$(date +%H:%M:%S)] 🎉 WORKER_COMPLETE: All foundation tasks done" >> .czarina/logs/foundation.log
```

---

## Deliverables

- ✅ `czarina-core/logging.sh` (~200 lines)
- ✅ `czarina-core/workspace.sh` (~250 lines)
- ✅ `czarina-core/session.sh` (~150 lines)
- ✅ Updated `.czarina/.worker-init`
- ✅ Updated `czarina` main script
- ✅ `docs/LOGGING.md` (~300 lines)
- ✅ `docs/ARCHITECTURE.md` (~400 lines)
- ✅ Test files (~200 lines)

---

## Success Metrics

- [ ] Workers can log events successfully
- [ ] Event stream is valid JSON Lines
- [ ] Session workspace created on launch
- [ ] Worker plans copied to workspace
- [ ] All tests passing
- [ ] Documentation complete and accurate

---

## Integration Notes

This stream is a dependency for:
- `coordination` (needs logging to read worker status)
- `dependencies` (needs workspace for tracking)
- `qa` (needs everything for testing)

Independent workers can proceed in parallel:
- `ux-polish`
- `dashboard`

---

## References

- Enhancement #1: Structured Logging System (from analysis)
- Enhancement #2: Workspace Structure (from analysis)
- SARK v1.3.0 orchestration analysis (2025-12-24)
