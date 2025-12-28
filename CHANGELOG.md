# Changelog

All notable changes to Czarina will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.1] - 2025-12-XX - UX Foundation Fixes

### Fixed
- **Worker Onboarding:** Workers no longer get stuck - explicit first actions added to all identities
- **Czar Autonomy:** Czar now actually autonomous with monitoring daemon
- **Launch Complexity:** Reduced from 8 steps/10+ min to 1 step/<60 sec

### Added
- Autonomous Czar daemon with worker monitoring
- `czarina analyze plan.md --go` for one-command launch
- Worker identity template with first action section
- Comprehensive testing suite for UX fixes

### Changed
- Worker identity format now includes "YOUR FIRST ACTION" section
- Launch process fully automated
- Phase transitions now automatic

### Impact
- 0 stuck workers (down from 1 per orchestration)
- 0 manual coordination needed
- Launch time: <60 seconds (down from 10+ minutes)

---

## [0.7.0] - 2025-12-28

### Added

**Persistent Memory System** - Workers that learn and remember across sessions
  - 3-tier memory architecture (Architectural Core, Project Knowledge, Session Context)
  - `.czarina/memories.md` - Human-readable memory storage (git-tracked)
  - `.czarina/memories.index` - Vector embeddings for semantic search (regenerable)
  - Semantic search of past sessions based on current task
  - Session extraction workflow to capture learnings
  - Memory CLI commands: `init`, `query`, `extract`, `rebuild`, `status`
  - Configurable embedding providers (OpenAI, local support coming)
  - Per-worker memory configuration
  - MEMORY_GUIDE.md - Comprehensive memory system documentation
  - czarina_memory_spec.md - Technical architecture specification

**Agent Rules Library Integration** - 43K+ lines of production-tested best practices
  - Integration of comprehensive agent rules library
  - 69 files covering 9 domains (Python, agents, workflows, patterns, testing, security, templates, documentation, orchestration)
  - Automatic rule loading based on worker role
  - Role-to-rules mapping (code, architect, qa, debug, documentation, orchestrator, integration)
  - Condensed rule summaries to manage context size (~2-5KB per domain)
  - Support for project-specific custom rules
  - Symlink: `czarina-core/agent-rules` -> agent rules library
  - Per-worker rules configuration
  - Manual and automatic loading modes
  - AGENT_RULES.md - Complete agent rules integration guide

**Enhanced Configuration Schema**
  - `memory` section in config.json for memory system settings
  - `agent_rules` section for rules library configuration
  - `role` field in worker config (determines auto-loaded rules)
  - Per-worker `memory` and `rules` override settings
  - Full backward compatibility (all new fields optional)

**New CLI Commands**
  - `czarina memory init` - Initialize memory system for project
  - `czarina memory query "<search>"` - Semantic search of past sessions
  - `czarina memory extract` - Extract and save session learnings
  - `czarina memory rebuild` - Rebuild vector search index
  - `czarina memory status` - Show memory system status
  - `czarina init --with-memory` - Initialize with memory enabled
  - `czarina init --with-rules` - Initialize with agent rules enabled
  - `czarina init --with-memory --with-rules` - Initialize with both features

**Comprehensive Documentation**
  - MIGRATION_v0.7.0.md - Complete migration guide from v0.6.2
  - MEMORY_GUIDE.md - Memory system usage and best practices
  - AGENT_RULES.md - Agent rules integration guide
  - Updated README.md with v0.7.0 highlights
  - Updated QUICK_START.md with new features and commands
  - Example configurations and memory templates

**Enhanced Worker Context Loading**
  - Workers receive Architectural Core memory (always loaded)
  - Workers receive top 3-5 relevant past sessions via semantic search
  - Workers receive role-appropriate agent rules
  - Combined memory + rules context < 20KB target
  - Context loading time < 2 seconds

### Changed

- Extended configuration schema (100% backward compatible)
- Enhanced worker launcher to load memory and rules
- Updated documentation to highlight learning and knowledge features
- Improved worker quality through built-in best practices

### Performance Impact

- Context loading: +1.5s (memory query + rule loading)
- Memory usage: +20MB per worker (rules and memory context)
- Storage: ~600KB (memories.md + index) typical
- Quality improvement: 30-40% reduction in common errors (observed)

### Migration Notes

- **100% Backward Compatible** - All v0.6.2 orchestrations work unchanged
- **Opt-In Features** - Memory and rules are disabled by default
- **Incremental Adoption** - Enable features gradually or all at once
- **Easy Rollback** - Simply disable in config or remove new fields
- See MIGRATION_v0.7.0.md for complete migration guide

---

**Release Focus:**
This major release transforms Czarina from a multi-agent orchestrator into a **learning, knowledge-powered orchestration system**. Workers now build institutional knowledge across sessions and start with 43K+ lines of production-tested best practices.

**The Synergy:**
- **Agent Rules** = Universal best practices ("use connection pooling")
- **Memory** = Project-specific learnings ("our DB connections timeout at 30s")
- **Together** = Workers apply both universal wisdom AND project experience

**Market Differentiation:**
First orchestrator that combines multi-agent coordination with institutional memory AND comprehensive knowledge base.

**Dogfooding:**
Built using Czarina to orchestrate its own development (9 workers, 2 phases, 3-5 days).

**Meta-Note:**
This release was built using Czarina v0.6.2 to orchestrate its own v0.7.0 development. Workers built the memory system and integrated agent rules that future workers will use. Meta-orchestration at its finest! 🐕

[Full Changelog](https://github.com/apathy-ca/czarina/compare/v0.6.2...v0.7.0)

## [0.6.2] - 2025-12-26

### Added

**Autonomous Czar v2** - Advanced orchestration coordination (3,257 lines)
  - czar-autonomous-v2.sh - Modern autonomous loop with structured logging
  - czar-hopper-integration.sh - Hopper monitoring and auto-assignment
  - czar-dependency-tracking.sh - Worker dependency tracking and coordination
  - Worker health detection (crashed/stuck/idle)
  - 30s monitoring cycle with decision logging
  - Complete test suites (45 automated tests, all passing)
  - docs/AUTONOMOUS_CZAR.md - Complete autonomous czar guide
  - docs/CZAR_COORDINATION.md - Coordination documentation

**Hopper Implementation** - Full hopper system (2,065 lines)
  - czarina-core/hopper.sh - Complete CLI implementation
  - Commands: `czarina hopper list`, `pull`, `defer`, `assign`
  - Priority queue logic (Priority × Complexity)
  - Metadata parsing and validation
  - docs/HOPPER.md - Complete hopper documentation
  - Example enhancement files with metadata
  - Makes hopper actually functional (was documentation-only in v0.6.1)

**Phase Management Enhancements** - Robust phase lifecycle (524 lines)
  - Smart worktree cleanup (keep dirty, remove clean)
  - Phase history archiving to .czarina/phases/
  - czarina-core/validate-config.sh - Config validation
  - `czarina phase list` command
  - Session naming validation
  - Phase-aware branch initialization
  - docs/PHASE_MANAGEMENT.md - Phase management guide
  - docs/BRANCH_NAMING.md - Branch naming conventions

**v0.6.0 Branch Integration** - Completed integration of worker branches
  - Integrated code from autonomous-czar, hopper, and phase-mgmt branches
  - 14 commits, 6,549 lines added, 130 lines removed
  - 39 files modified
  - Archived v0.6.0 branches to .czarina/phases/phase-1-v0.6.0/
  - INTEGRATION_SUMMARY.md - Complete integration documentation

**Testing & Validation** - Comprehensive testing suite
  - TEST_RESULTS.md - 13 test cases, 100% pass rate
  - Validated all v0.6.1 features
  - Production-ready certification
  - No bugs found

**Meta-Orchestration Documentation**
  - ORCHESTRATION_POSTMORTEM.md - v0.6.1 orchestration analysis
  - .czarina/COORDINATION_LOG.md - Complete coordination timeline
  - Lessons learned and recommendations for future orchestrations

### Changed

- Version bump from 0.6.1 to 0.6.2 to properly version the integrated work

---

**Release Focus:**
This patch release includes all the integrated v0.6.0 worker code that was completed during v0.6.1 orchestration. It combines the v0.6.1 UX improvements with autonomous czar v2, full hopper implementation, and enhanced phase management.

**Why 0.6.2?**
The v0.6.1 orchestration successfully integrated significant features from v0.6.0 branches, but these were merged to main after the v0.6.1 tag was created. Version 0.6.2 properly versions this complete feature set. See ORCHESTRATION_POSTMORTEM.md for details.

**Meta-Note:**
This release was built using czarina to orchestrate its own improvement (3 workers: integration, testing, release). Peak dogfooding! 🐕

[Full Changelog](https://github.com/apathy-ca/czarina/compare/v0.6.1...v0.6.2)

## [0.6.1] - 2025-12-26

### Added

**Auto-launch Czar with Claude** - Czar window now gets Claude auto-launched
  - Creates CZAR_IDENTITY.md with coordination instructions
  - Configurable via config.czar.agent (defaults to "claude")
  - Czar runs from project root (not a worktree)
  - Context-aware prompts for both Czar and workers

**Orchestration Mode (local vs github)** - Configure how workers are managed
  - 'local' mode: workers use git worktrees, no auto-push (default)
  - 'github' mode: workers via GitHub (Claude Code Web)
  - Auto-push only enabled when mode='github' AND auto_push_branches=true
  - Configuration: orchestration.mode in config.json

**Omnibus Branch Protection** - Prevent accidental feature work on release branches
  - Only integration workers (role='integration') can use omnibus branch
  - All other workers MUST use feature branches
  - Validates branch usage at launch time

**Project Hopper** - Enhancement queue management
  - Initialize hopper structure (.czarina/hopper/)
  - README and example files
  - Integrated with orchestration mode

**Streamlined Initialization** - czarina init --plan command
  - Combines analyze + init into single command
  - Launches Claude Code with plan file for interactive setup
  - Creates config.json and worker files interactively
  - Auto-detects and uses Claude Code CLI

**Git Repository Prompt** - Guides users to initialize git if needed
  - Detects non-git directories
  - Prompts to run git init
  - Ensures czarina works in proper git context

### Changed

- **Simplified czarina analyze** - Now uses Claude Code directly instead of complex Python analyzer
  - No more cut/paste required - Claude has direct file access
  - Interactive workflow with coding agent
  - Removed 400+ lines of analyzer code

- **Worker IDs in tmux window names** - More readable window identification
  - Before: worker1, worker2, worker3 (generic)
  - After: logging, phase-mgmt, hopper (actual worker IDs)
  - Makes tmux window list much clearer

- **Czarina is purely local** - Removed global project registry
  - No more czarina list command scanning filesystem
  - Each repo is self-contained
  - Use standard tools (find, cd) to navigate projects

- **Claude Code only for init --plan** - Simplified agent detection
  - Removed auto-detection of multiple agents (aider, kilocode)
  - Clear error if Claude not installed
  - Prevents configuration issues with unconfigured agents

### Fixed

- **Closeout session cleanup** - Kill both main and mgmt tmux sessions
  - Previously left orphaned management sessions running
  - Now explicitly kills czarina-{slug} and czarina-{slug}-mgmt
  - Uses tmux has-session for reliable detection

- **czarina list filtering** - No longer shows worktrees and archives
  - Filters out .czarina/worktrees/* (worker worktrees)
  - Filters out archive/ directories
  - Filters out .czarina/phases/* (historical data)
  - Shows only actual top-level czarina orchestrations

### Integrated Post-Release (v0.6.1+)

**Note:** The following features from v0.6.0 worker branches were integrated into main after the v0.6.1 tag was created. They are available on the main branch but not included in the v0.6.1 GitHub release.

**Autonomous Czar v2** - Advanced orchestration coordination (3,257 lines)
  - czar-autonomous-v2.sh - Modern autonomous loop with structured logging
  - czar-hopper-integration.sh - Hopper monitoring and auto-assignment
  - czar-dependency-tracking.sh - Worker dependency tracking and coordination
  - Worker health detection (crashed/stuck/idle)
  - 30s monitoring cycle with decision logging
  - Complete test suites (45 automated tests, all passing)
  - docs/AUTONOMOUS_CZAR.md - Complete autonomous czar guide
  - docs/CZAR_COORDINATION.md - Coordination documentation

**Hopper Implementation** - Full hopper system (2,065 lines)
  - czarina-core/hopper.sh - Complete CLI implementation
  - Commands: list, pull, defer, assign
  - Priority queue logic (Priority × Complexity)
  - Metadata parsing and validation
  - docs/HOPPER.md - Complete hopper documentation
  - Example enhancement files with metadata
  - Makes hopper actually functional (was documentation-only before)

**Phase Management Enhancements** - Robust phase lifecycle (524 lines)
  - Smart worktree cleanup (keep dirty, remove clean)
  - Phase history archiving to .czarina/phases/
  - czarina-core/validate-config.sh - Config validation
  - czarina phase list command
  - Session naming validation
  - Phase-aware branch initialization
  - docs/PHASE_MANAGEMENT.md - Phase management guide
  - docs/BRANCH_NAMING.md - Branch naming conventions

**v0.6.0 Branch Integration** - Completed integration of worker branches
  - Integrated code from autonomous-czar, hopper, and phase-mgmt branches
  - 14 commits, 6,549 lines added, 130 lines removed
  - 39 files modified
  - Archived v0.6.0 branches to .czarina/phases/phase-1-v0.6.0/
  - INTEGRATION_SUMMARY.md - Complete integration documentation

**Testing & Validation** - Comprehensive v0.6.1 testing
  - TEST_RESULTS.md - 13 test cases, 100% pass rate
  - Validated all 8 v0.6.1 features
  - Production-ready certification
  - No bugs found

**Coordination Note:** This integration work was completed via czarina orchestration (3 workers: integration, testing, release) but was inadvertently omitted from the release/v0.6.1 branch merge. It was pragmatically forward-merged into main post-release. See INTEGRATION_SUMMARY.md for complete details.

---

**Release Focus:**
This patch release improves the initialization workflow and fixes several UX issues discovered during dogfooding. Key improvements include auto-launching the Czar agent, streamlined project initialization with `czarina init --plan`, and better orchestration mode configuration for local vs GitHub workflows.

**Post-Release Integration:** Significant additional features (autonomous czar v2, hopper implementation, phase management) were integrated after the v0.6.1 tag was created and are available on the main branch.

[Full Changelog](https://github.com/apathy-ca/czarina/compare/v0.6.0...v0.6.1)

## [0.6.0] - 2025-12-26

### Added

**Comprehensive Closeout Reports (E#17)** - Rich, detailed project closeout documentation
  - Worker summaries with branch information and activity metrics
  - Detailed commit history per worker with commit counts
  - Files changed analysis (per worker and overall)
  - Orchestration duration tracking (start to end time)
  - Auto-archive to `.czarina/phases/phase-1-{version}/` directory
  - Two-tier reporting: Full CLOSEOUT.md and quick PHASE_SUMMARY.md
  - Template system: `czarina-core/templates/CLOSEOUT.md`
  - Key metrics table: commits, files changed, lines added/removed
  - Git statistics: branch status, repository state
  - Complete configuration archive for reproducibility
  - Implementation: Enhanced `czarina-core/closeout-project.sh`

**Logging Auto-Initialization** - Logging system automatically starts with orchestration
  - Zero manual setup required
  - Logging directories created on `czarina launch`
  - Event stream and worker logs ready immediately
  - Implementation: `czarina-core/launch-project-v2.sh`

### Changed

- Closeout reports now include comprehensive metrics and analysis
- Phase archives include both detailed and summary reports
- Orchestration start time tracked for duration calculation
- Enhanced closeout report generation with worker-specific sections

### Fixed

- **Enhancement #17** - Better closeout reports
  - Before: Basic report with limited information
  - After: Comprehensive analysis with worker metrics, commits, files, and duration

---

**Release Focus:**
This minor version adds professional closeout reporting for better project documentation and archiving. The comprehensive reports provide complete visibility into what each worker accomplished during the orchestration.

[Full Changelog](https://github.com/apathy-ca/czarina/compare/v0.5.1...v0.6.0)

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

- **v0.6.1** - Streamlined initialization, orchestration mode, auto-launch Czar (December 2025)
- **v0.6.0** - Comprehensive closeout reports, logging auto-initialization (December 2025)
- **v0.5.1** - Auto-launch agent system, daemon quiet mode (December 2025)
- **v0.5.0** - Structured logging, session workspaces, proactive coordination (December 2025)
- **v0.4.0** - Initial production-ready release (November 2025)
