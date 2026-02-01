# Changelog

All notable changes to Czarina will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.0] - 2026-01-27

### Added

**Wiggum Mode - Iterative Fault-Tolerant AI Workers**
  - `czarina wiggum` command for autonomous, retry-based AI coding tasks
  - Disposable workers ("Ralphs") execute in isolated git worktrees
  - Cumulative "Wisdom" registry briefs each new attempt on past failures
  - Cycle detection via diff hashing prevents regression loops
  - Configurable timeout watchdog kills stalled workers
  - Protected files auto-reverted if modified by Ralph
  - Verification gate runs user-defined test commands between attempts
  - Squash/merge/rebase strategies for merging successful changes
  - Plan generator (`czarina plan`) suggests Wiggum Mode for test-driven tasks
  - Init system (`czarina init`) generates wiggum config when plan uses it
  - Example config: `examples/config-with-wiggum.json`

**AI-Powered Orchestration Setup**
  - `czarina init` now launches Claude Code to analyze plans and create orchestration
  - Works with any plan format (not just pre-formatted worker sections)
  - AI determines optimal worker breakdown, phases, and dependencies
  - Comprehensive context provided: docs, templates, examples, agent-knowledge

**Agent Knowledge Integration**
  - Integration with agent-knowledge library (43K+ lines of best practices)
  - Auto-detects agent-knowledge at `../agent-knowledge/`
  - Public repository: https://github.com/apathy-ca/agent-knowledge
  - Includes: Python standards, design patterns, testing, security, workflows, templates

**Custom Knowledge Files Per Worker**
  - Init agent creates `<worker-id>-knowledge.md` for each worker
  - AI browses agent-knowledge and extracts relevant rules/patterns
  - Tailored to worker's role and specific tasks (~10KB per worker)
  - Python backend workers get Python/API/testing patterns
  - QA workers get testing/security/validation patterns
  - Solves context overflow without runtime complexity

### Changed

**Simplified Init Command**
  - Removed `--assist` flag (init always uses AI now)
  - Updated usage documentation and examples
  - Init complements `czarina plan` for end-to-end workflow

**Worker Identity Template**
  - Added Knowledge Base section pointing to custom knowledge file
  - Workers instructed to read knowledge before starting work

### Fixed

**F-string Syntax Errors**
  - Built conditional prompt sections outside f-string to avoid backslash issues
  - Ensures compatibility across Python versions

## [0.8.0] - 2026-01-18

### Changed

**Major CLI Simplification** - Streamlined interface for clarity and maintainability
  - Reduced command count from 28 to 8 core commands (71% reduction)
  - Removed commands: `analyze`, `daemon`, `hopper`, `memory`, `patterns`, `deps`
  - Removed 903 lines of code (~53% reduction in CLI complexity)
  - Single golden path for orchestration workflow
  - Core commands: init, launch, closeout, phase (set/close/list), status, dashboard, version

**Integrated from v0.7.3** - LLM monitoring and validation enhancements
  - Kept `czarina phase set` command for phase management
  - Integrated LLM monitor daemon (launched via `czarina launch`, not separate CLI command)
  - Enhanced validation system with agent availability checking
  - All LLM monitor features available through launch script integration

### Added

**User Experience Improvements**
  - Display version and phase in `czarina status` and `czarina launch` outputs
  - Helpful error messages when config.json is missing (no more Python tracebacks)
  - Clear guidance for next steps in error messages

**Parser Enhancements**
  - Support for bracket notation in dependencies: `[]` and `[worker1, worker2]`
  - Automatic phase field added to workers during `czarina init`

### Fixed

**Phase Management**
  - `phase-close.sh` now completes all 5 cleanup steps reliably
  - Added error guards (`set +e`/`set -e`) to prevent early exit
  - Improved tmux session cleanup loop robustness
  - Workers directory and config.json properly removed after phase close
  - Worktrees cleaned up correctly with `--force` option support

**Configuration**
  - Dependencies no longer stored as strings like `"[worker1]"`
  - Phase field now properly set on workers for launch filtering

### Testing

**Real-World Validation** - HLDemo multi-phase project
  - 3 phases, 17 workers total (10 + 4 + 3)
  - Full React application with 34 chapters produced
  - All phase transitions tested successfully
  - See `examples/HLDEMO_WORKFLOW.md` for detailed example

### Benefits
  - Clearer workflow with less decision paralysis
  - Fewer edge cases and potential bugs
  - Easier to learn and maintain
  - Advanced features (LLM monitor) integrated seamlessly without CLI bloat
  - Robust phase management for multi-phase projects

### Migration Guide
  - `czarina daemon start` → LLM monitor now auto-launches with `czarina launch` (configure in config.json)
  - `czarina analyze` → Use `czarina init <plan.md>` for automated setup
  - `czarina hopper`, `czarina memory`, `czarina patterns`, `czarina deps` → Removed (specialized workflows)

---

## [0.7.3] - 2026-01-16

### Added

**LLM-Powered Intelligent Monitoring** - AI-driven worker analysis using Claude Haiku
  - `czarina-core/llm-monitor-daemon.py` (735 lines) - Event-driven intelligent worker monitoring
  - Real-time analysis of worker terminal output using Claude Haiku
  - Event-driven architecture with `watchdog` for instant log-based triggers
  - Intelligent action execution (auto-approve, send keys, flag for intervention)
  - Comprehensive decision audit trail (human + machine readable)
  - Cost tracking (~$0.002 per analysis, ~$0.40 per 8-hour orchestration)
  - Configuration via `llm_monitor` section in config.json
  - Full documentation: `czarina-core/docs/LLM_MONITOR.md`

**Enhanced Validation System**
  - Agent availability checking before launch (validates aider, claude, kilocode are installed)
  - Auto-fix for branch naming mismatches with interactive prompt
  - `czarina phase set <number>` - Set phase and auto-update all branch names
  - Improved error messages with actionable quick-fix suggestions
  - `--fix` flag for non-interactive auto-fixing

**UX Improvements**
  - Better output formatting in validation with clear window numbering
  - Fixed worker 10+ appearing in main session (now correctly in mgmt session)
  - Enhanced launch output showing explicit window assignments

### Changed
  - `validate-config.sh` - Added agent availability checks and auto-fix prompts
  - `launch-project-v2.sh` - Fixed MAX_WORKERS_IN_MAIN enforcement, added LLM monitor integration
  - `czarina` CLI - Added `phase set` command, updated help text

### Fixed
  - Worker 10+ now correctly placed in management session instead of main session (windows 0-9 limit)
  - Branch naming validation now offers interactive fix instead of just failing

---

## [0.7.2] - 2026-01-XX

### Added

**Automated Multi-Phase Orchestration** - Seamless phase transitions with full automation
  - `czarina-core/phase-completion-detector.sh` (361 lines) - Multi-signal completion detection
  - `test-phase-completion-detector.sh` (299 lines) - Comprehensive test suite (100% coverage)
  - Automatic phase completion detection via daemon monitoring
  - Multi-signal detection (worker logs, git branches, status files)
  - Three completion modes: `any` (default), `strict`, `all`
  - Automatic phase archival with complete state preservation
  - Phase state tracking in `status/phase-state.json`
  - Decision logging (human-readable and JSON formats)
  - Smart phase initialization with auto-detection
  - Complete phase history in `.czarina/phases/phase-N-vX.Y.Z/`
  - Phase summary auto-generation

**Enhanced Phase Commands**
  - Phase completion check: `./czarina-core/phase-completion-detector.sh --verbose`
  - JSON output for scripting: `--json` flag
  - Exit codes: 0=complete, 1=incomplete, 2=error
  - Smart `czarina init` - auto-detects closed phases, no `--force` needed

**Configuration Enhancements**
  - `project.phase` - Current phase number (integer, ≥ 1)
  - `project.omnibus_branch` - Integration branch for phase (e.g., "cz1/release/v1.0.0")
  - `phase_completion_mode` - Completion detection mode (any/strict/all)
  - `workers[].phase` - Phase number for each worker
  - `workers[].role` - Worker role (feature/integration)
  - Phase-aware branch naming convention: `cz<phase>/feat/<worker-id>`

**Autonomous Daemon Integration**
  - 5-minute phase completion check intervals
  - Worker health monitoring (active/idle/stuck/complete states)
  - Automatic phase detection and archival
  - Complete decision audit trail
  - Machine-readable event stream (`logs/events.jsonl`)
  - Human-readable decision log (`status/autonomous-decisions.log`)

**Phase Archive Structure**
  - Configuration snapshot (`config.json`)
  - Phase summary document (`PHASE_SUMMARY.md`)
  - Complete worker logs (`logs/workers/*.log`)
  - Event stream (`logs/events.jsonl`)
  - Worker status snapshots (`status/worker-status.json`)
  - Worker prompt snapshots (`workers/*.md`)
  - Phase state at completion (`status/phase-state.json`)

**Comprehensive Documentation**
  - `docs/MULTI_PHASE_ORCHESTRATION.md` - Complete multi-phase guide (900+ lines)
  - `docs/troubleshooting/PHASE_TRANSITIONS.md` - Troubleshooting guide (800+ lines)
  - Updated `docs/CONFIGURATION.md` with phase configuration schema
  - Updated `QUICK_START.md` with multi-phase examples
  - `RELEASE_NOTES_v0.7.2.md` - Detailed release documentation

### Changed

- Enhanced `czarina init` with smart phase detection
- Enhanced `autonomous-czar-daemon.sh` with phase completion monitoring
- Updated configuration schema with phase-aware fields
- Improved phase archival to include complete audit trail
- Worker health detection thresholds (idle: 10min, stuck: 30min)

### Performance Impact

- Phase detection overhead: <1 second
- Archive creation: <5 seconds
- Daemon check interval: 5 minutes
- Zero performance impact on workers during operation

### Migration Notes

- **100% Backward Compatible** - All v0.7.1 orchestrations work unchanged
- **Opt-In Features** - Multi-phase features enabled by adding phase config
- **No Breaking Changes** - Existing configs, commands work as before
- **Incremental Adoption** - Add phase fields when ready for multi-phase workflows
- See MIGRATION_v0.7.2.md for complete migration guide

---

**Release Focus:**
Automated multi-phase orchestration with intelligent completion detection and seamless phase transitions. Perfect for long-running projects with multiple release cycles, complex orchestrations requiring phased rollout, and projects needing complete audit trails.

**Key Innovation:**
Multi-signal completion detection with flexible modes eliminates guesswork about when phases are done. Automatic archival preserves complete development history for every phase.

**Use Cases:**
- Sequential feature development across multiple releases
- Long-running projects with clear phase boundaries
- Compliance-driven development requiring audit trails
- Complex orchestrations with 5+ sequential phases

**Dogfooding:**
Built using Czarina to orchestrate its own v0.7.2 development (3 workers: phase-detection, phase-transition, documentation). Meta-orchestration continues!

[Full Changelog](https://github.com/apathy-ca/czarina/compare/v0.7.1...v0.7.2)

---

## [0.7.1] - 2025-12-29 - UX Foundation Fixes

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

[Full Changelog](https://github.com/apathy-ca/czarina/compare/v0.7.0...v0.7.1)

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
