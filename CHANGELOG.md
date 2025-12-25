# Changelog

All notable changes to Czarina will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

- **v0.5.0** - Structured logging, session workspaces, proactive coordination (December 2025)
- **v0.4.0** - Initial production-ready release (November 2025)
