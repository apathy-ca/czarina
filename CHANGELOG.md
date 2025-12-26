# Changelog

All notable changes to Czarina will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.1] - 2025-12-25

### Added

**Auto-Launch Agent System** - Agents automatically start in worker windows
  - Zero manual setup after `czarina launch`
  - Worker-specific instructions via `WORKER_IDENTITY.md`
  - Auto-approval configured for Claude and Aider
  - Configuration: `--no-auto-launch`, `--no-auto-approve` flags (planned)
  - Documentation: `czarina-core/docs/AUTO_LAUNCH.md`
  - Implementation: `czarina-core/agent-launcher.sh`
  - Integration in `czarina-core/launch-project-v2.sh`

**Daemon Quiet Mode** - Only outputs when workers have activity
  - Activity detection with 5-minute threshold
  - Silent iterations when all workers idle
  - Configuration: `DAEMON_ALWAYS_OUTPUT` flag (disable quiet mode)
  - Environment: `DAEMON_ACTIVITY_THRESHOLD` variable (default 300s)
  - Documentation: `czarina-core/docs/DAEMON.md`
  - Implementation: `daemon_has_recent_activity()` function

### Fixed

- **Enhancement #10** - Auto-launch agents (discovered in v0.5.0 dogfooding)
  - Before: Manual agent initialization required (18 steps for 6 workers)
  - After: Zero manual steps, agents auto-start with instructions

- **Enhancement #11** - Daemon spacing issue (discovered in v0.5.0 dogfooding)
  - Before: Daemon spammed blank lines every 2 minutes when idle
  - After: Daemon only outputs when workers are active (<5 min)

### Changed

- Daemon monitor loop checks for activity before outputting
- Silent iterations when no recent worker activity
- Worker launch process integrates agent-launcher when agent type is configured

---

**Discovered During Dogfooding:**
Both enhancements were discovered during czarina v0.5.0 meta-orchestration:
- #10: Human had to manually start agents in each window
- #11: Daemon spammed blank lines, pushing text off-screen

v0.5.1 completes the fixes for both issues.

[Full Changelog](https://github.com/apathy-ca/czarina/compare/v0.5.0...v0.5.1)

## [0.5.0] - 2025-12-24

### Added

**Structured Logging System**:
- Worker logs: `.czarina/logs/<worker>.log`
- Event stream: `.czarina/logs/events.jsonl`
- Orchestration log: `.czarina/logs/orchestration.log`
- Log parsing utilities in `czarina-core/logging.sh`
- Worker log functions: `czarina_log_worker`, `czarina_log_daemon`, `czarina_log_event`
- Event tracking with machine-readable JSONL format
- Historical audit trail for debugging and analysis

**Session Workspaces**:
- Session artifacts directory: `.czarina/work/<session-id>/`
- Worker plans, tasks, and completion reports
- Comprehensive closeout report generation
- Session metadata and metrics tracking
- Plan vs. actual comparison capabilities
- `czarina closeout` command for report generation

**Proactive Coordination**:
- Czar monitors workers automatically via `czarina-core/czar.sh`
- Periodic status reports (configurable interval)
- Automatic completion detection
- Integration strategy suggestions
- Enhanced daemon output with real-time worker activity
- Worker status monitoring and reporting

**Dependency Enforcement**:
- Worker dependency checking in `czarina-core/dependencies.sh`
- Orchestration modes: `parallel_spike`, `sequential_dependencies`
- Dependency graph generation and visualization
- CLI commands: `czarina deps graph`, `czarina deps check`
- Configuration via `orchestration.mode` in config.json
- Documentation in `docs/CONFIGURATION.md`

**UX Improvements**:
- Tmux windows show worker IDs instead of generic numbers (e.g., "backend" not "worker1")
- Worker definition template with commit checkpoints
- `czarina init worker` command for creating new workers
- Improved documentation and migration guide
- Better error messages and user feedback
- Enhanced command-line output formatting

**Dashboard**:
- Fixed non-functional dashboard rendering
- Live worker status monitoring
- Real-time metrics display (token usage, task progress)
- Color-coded status indicators
- Improved UI layout and responsiveness

**Documentation**:
- `docs/MIGRATION_v0.5.0.md` - Comprehensive migration guide
- `docs/CONFIGURATION.md` - Orchestration mode documentation
- Updated README with v0.5.0 features
- End-to-end integration tests in `tests/test-e2e.sh`

### Fixed

- Dashboard rendering issues preventing status display
- Generic tmux window naming (now shows actual worker IDs)
- Missing documentation for orchestration modes
- Lack of structured logging infrastructure

### Changed

- Enhanced daemon output format with worker activity indicators
- Improved worker initialization process
- Better separation of concerns in core modules
- More informative status reporting

## [0.4.0] - Previous Release

Initial production-ready release of Czarina.

### Features

- Multi-agent orchestration system
- Git worktree-based worker isolation
- Daemon system for 90% autonomy
- Support for 8+ AI coding agents
- Pattern library system
- Battle-tested with SARK v2.0 (10 workers)
- 3-4x speedup over sequential development
- CLI commands for project management
- Embedded `.czarina/` project structure

---

## Version History

- **v0.5.1** - Auto-launch agent system, daemon quiet mode (December 2025)
- **v0.5.0** - Structured logging, session workspaces, proactive coordination (December 2025)
- **v0.4.0** - Initial production-ready release (November 2025)
