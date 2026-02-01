# Orchestrator Role (Czar) - Coordination

**Source:** Extracted from [Czarina](https://github.com/czarina) orchestration patterns
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

The **Orchestrator** role (also known as **Czar**) is responsible for coordinating multiple agents, monitoring progress, managing dependencies, and ensuring smooth workflow across all workers. The orchestrator doesn't do implementation work but instead enables and coordinates others.

**Core Principle:** The orchestrator orchestrates. Workers work. The orchestrator ensures workers have what they need to succeed.

## Monitoring Responsibilities

### Worker Status Tracking

Orchestrators monitor all worker progress:

```bash
# Check worker status across all branches

czarina status

# Output:
# Worker Status Report
# ==================
#
# foundation     ✅ COMPLETE   (1,150K tokens, 6 days)
# workflows      ✅ COMPLETE   (850K tokens, 6 days)
# patterns       🔄 IN_PROGRESS (420K tokens, 3 days)
# testing        ⏸️  WAITING    (deps: foundation)
# security       ⏸️  WAITING    (deps: foundation)
# templates      ⏸️  WAITING    (deps: all)
# qa             ⏸️  WAITING    (deps: all)
```

**Monitoring Tools:**
- Git branch status
- Event logs
- Worker status files
- Commit activity
- Token usage tracking

**From Czarina:** Orchestrator maintains bird's-eye view of entire project.

### Progress Monitoring

Track detailed progress for each worker:

```bash
# Monitor individual worker progress

czarina status foundation

# Output:
# Worker: foundation
# ==================
# Branch: feat/agent-rules-foundation
# Status: ✅ COMPLETE
# Started: 2025-12-20
# Completed: 2025-12-26
# Duration: 6 days
# Tokens: 1,150,000 / 1,200,000 (95%)
#
# Tasks:
# ✅ Create directory structure
# ✅ Extract CODING_STANDARDS.md
# ✅ Extract ASYNC_PATTERNS.md
# ✅ Extract ERROR_HANDLING.md
# ✅ Extract DEPENDENCY_INJECTION.md
# ✅ Extract TESTING_PATTERNS.md
# ✅ Extract SECURITY_PATTERNS.md
# ✅ Extract agent role definitions
# ✅ Create worker templates
#
# Latest Activity:
# 2025-12-26 14:32 - Worker complete, pushed branch
# 2025-12-26 12:15 - Checkpoint: All agent roles extracted
# 2025-12-26 09:43 - Checkpoint: Python standards complete
```

### Event Stream Monitoring

Orchestrators watch the event stream:

```bash
# Monitor real-time events

tail -f .czarina/events.log

# Events from workers:
# 2025-12-26T14:32:00Z foundation WORKER_COMPLETE tokens=1150000
# 2025-12-26T14:15:00Z foundation CHECKPOINT name=agent_roles_complete
# 2025-12-26T12:30:00Z workflows TASK_START task=GIT_WORKFLOW.md
# 2025-12-26T11:45:00Z patterns BLOCKED reason=waiting_for_foundation
```

**Event Types:**
- `WORKER_START` - Worker begins work
- `TASK_START` - Worker starts a task
- `CHECKPOINT` - Worker reaches milestone
- `TASK_COMPLETE` - Worker completes task
- `BLOCKED` - Worker blocked on dependency
- `ERROR` - Worker encounters error
- `WORKER_COMPLETE` - Worker finishes all work

## Worker Management Patterns

### Worker Lifecycle Management

Orchestrators manage the full worker lifecycle:

```python
# Worker lifecycle states

class WorkerState(Enum):
    """Worker lifecycle states."""
    PENDING = "pending"           # Defined but not started
    READY = "ready"               # Dependencies met, can start
    STARTING = "starting"         # Initialization in progress
    ACTIVE = "active"             # Currently working
    BLOCKED = "blocked"           # Waiting on dependency
    PAUSED = "paused"             # Temporarily suspended
    COMPLETE = "complete"         # All work finished
    FAILED = "failed"             # Encountered fatal error

class WorkerLifecycle:
    """Manage worker state transitions."""

    def __init__(self, worker_id: str):
        self.worker_id = worker_id
        self.state = WorkerState.PENDING

    def can_start(self, dependencies: list[str]) -> bool:
        """Check if worker can start.

        Args:
            dependencies: List of worker IDs this worker depends on

        Returns:
            True if all dependencies complete and worker ready
        """
        # Check all dependencies complete
        for dep_id in dependencies:
            dep_status = self.get_worker_status(dep_id)
            if dep_status != WorkerState.COMPLETE:
                logger.info(
                    "worker_blocked",
                    worker_id=self.worker_id,
                    dependency=dep_id,
                    dependency_status=dep_status,
                )
                return False

        return True

    def start_worker(self):
        """Start worker if dependencies met."""
        if self.state != WorkerState.READY:
            raise ValueError(f"Worker {self.worker_id} not ready to start")

        logger.info("worker_starting", worker_id=self.worker_id)
        self.state = WorkerState.STARTING

        # Create worker branch
        self._create_branch()

        # Launch worker agent
        self._launch_agent()

        self.state = WorkerState.ACTIVE
        logger.info("worker_active", worker_id=self.worker_id)
```

**From Czarina:** Orchestrator controls when workers start, not workers themselves.

### Dependency Resolution

Orchestrators resolve and track dependencies:

```python
# Dependency graph management

from collections import defaultdict, deque
from typing import Dict, List, Set

class DependencyGraph:
    """Manage worker dependencies and execution order."""

    def __init__(self):
        self.dependencies: Dict[str, List[str]] = defaultdict(list)
        self.dependents: Dict[str, List[str]] = defaultdict(list)

    def add_dependency(self, worker: str, depends_on: str):
        """Add dependency relationship.

        Args:
            worker: Worker that has the dependency
            depends_on: Worker that must complete first
        """
        self.dependencies[worker].append(depends_on)
        self.dependents[depends_on].append(worker)

    def get_execution_order(self) -> List[List[str]]:
        """Calculate execution order using topological sort.

        Returns:
            List of worker groups, each group can execute in parallel

        Example:
            [
                ['foundation', 'workflows'],  # Wave 1: No dependencies
                ['patterns', 'testing', 'security'],  # Wave 2: Depend on foundation
                ['templates'],  # Wave 3: Depends on all Wave 2
                ['qa'],  # Wave 4: Depends on all
            ]
        """
        # Calculate in-degrees
        in_degree = defaultdict(int)
        for worker, deps in self.dependencies.items():
            in_degree[worker] = len(deps)

        # Find workers with no dependencies
        waves = []
        current_wave = [w for w, d in in_degree.items() if d == 0]

        while current_wave:
            waves.append(sorted(current_wave))  # Sort for determinism

            # Next wave: workers whose dependencies are all complete
            next_wave = []
            for worker in current_wave:
                for dependent in self.dependents[worker]:
                    in_degree[dependent] -= 1
                    if in_degree[dependent] == 0:
                        next_wave.append(dependent)

            current_wave = next_wave

        return waves

    def can_start_worker(self, worker: str, completed: Set[str]) -> bool:
        """Check if worker can start.

        Args:
            worker: Worker to check
            completed: Set of completed worker IDs

        Returns:
            True if all dependencies are in completed set
        """
        dependencies = self.dependencies.get(worker, [])
        return all(dep in completed for dep in dependencies)
```

**Usage:**

```python
# Build dependency graph from worker definitions

graph = DependencyGraph()

# foundation: no dependencies
# workflows: no dependencies
# patterns: depends on foundation
graph.add_dependency('patterns', 'foundation')
# testing: depends on foundation
graph.add_dependency('testing', 'foundation')
# security: depends on foundation
graph.add_dependency('security', 'foundation')
# templates: depends on all
graph.add_dependency('templates', 'foundation')
graph.add_dependency('templates', 'workflows')
graph.add_dependency('templates', 'patterns')
graph.add_dependency('templates', 'testing')
graph.add_dependency('templates', 'security')
# qa: depends on all
graph.add_dependency('qa', 'templates')

# Get execution order
waves = graph.get_execution_order()
# [
#   ['foundation', 'workflows'],
#   ['patterns', 'security', 'testing'],
#   ['templates'],
#   ['qa']
# ]
```

## Daemon Automation

### Auto-Launch Workers

Orchestrator daemon automatically launches workers when ready:

```python
# Daemon worker management

import asyncio
from typing import Set

class OrchestratorDaemon:
    """Automated worker orchestration daemon."""

    def __init__(self, graph: DependencyGraph, auto_approve: bool = True):
        self.graph = graph
        self.auto_approve = auto_approve
        self.completed: Set[str] = set()
        self.active: Set[str] = set()
        self.failed: Set[str] = set()

    async def run(self):
        """Run orchestration daemon."""
        logger.info("daemon_started", auto_approve=self.auto_approve)

        while True:
            # Check for workers that can start
            ready_workers = self._find_ready_workers()

            for worker in ready_workers:
                if self.auto_approve:
                    await self._launch_worker(worker)
                else:
                    await self._request_approval(worker)

            # Check for completed workers
            await self._check_worker_status()

            # Check if all workers complete
            if self._all_workers_complete():
                logger.info("orchestration_complete")
                break

            # Sleep before next check
            await asyncio.sleep(30)  # Check every 30 seconds

    def _find_ready_workers(self) -> List[str]:
        """Find workers that can start.

        Returns:
            List of worker IDs ready to start
        """
        ready = []

        for worker in self.graph.dependencies.keys():
            # Skip if already started
            if worker in self.active or worker in self.completed:
                continue

            # Skip if dependencies not met
            if not self.graph.can_start_worker(worker, self.completed):
                continue

            ready.append(worker)

        return ready

    async def _launch_worker(self, worker: str):
        """Launch worker automatically."""
        logger.info("auto_launching_worker", worker=worker)

        # Create worktree
        await self._create_worktree(worker)

        # Launch agent
        await self._start_agent(worker)

        self.active.add(worker)

    async def _check_worker_status(self):
        """Check status of active workers."""
        for worker in list(self.active):
            status = await self._get_worker_status(worker)

            if status == WorkerState.COMPLETE:
                logger.info("worker_completed", worker=worker)
                self.active.remove(worker)
                self.completed.add(worker)

            elif status == WorkerState.FAILED:
                logger.error("worker_failed", worker=worker)
                self.active.remove(worker)
                self.failed.add(worker)
```

**From Czarina:** Daemon enables true autonomous orchestration.

### Quiet Mode

Daemon uses activity-based output:

```python
# Quiet mode - only output when there's activity

class QuietDaemon(OrchestratorDaemon):
    """Daemon with minimal output."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.last_status = {}

    async def run(self):
        """Run with quiet mode."""
        while True:
            current_status = await self._get_all_status()

            # Only output if status changed
            if current_status != self.last_status:
                self._print_status_update(current_status)
                self.last_status = current_status

            # Rest of daemon logic...
            await asyncio.sleep(30)

    def _print_status_update(self, status: dict):
        """Print status only when changed."""
        changes = []

        for worker, state in status.items():
            old_state = self.last_status.get(worker)
            if state != old_state:
                changes.append(f"{worker}: {old_state} → {state}")

        if changes:
            print(f"[{datetime.now()}] Status changes:")
            for change in changes:
                print(f"  {change}")
```

**Why Quiet Mode:**
- Reduces noise during long-running orchestrations
- Highlights actual changes
- Makes logs more readable
- Enables background running

## Status Tracking and Reporting

### Status Reports

Orchestrator generates status reports:

```python
# Generate status report

def generate_status_report(self) -> str:
    """Generate comprehensive status report.

    Returns:
        Formatted status report string
    """
    report = []
    report.append("=" * 60)
    report.append("ORCHESTRATION STATUS REPORT")
    report.append("=" * 60)
    report.append(f"Generated: {datetime.now()}")
    report.append("")

    # Overall progress
    total_workers = len(self.graph.dependencies)
    completed_count = len(self.completed)
    active_count = len(self.active)
    pending_count = total_workers - completed_count - active_count

    report.append("OVERVIEW")
    report.append("-" * 60)
    report.append(f"Total Workers:     {total_workers}")
    report.append(f"Completed:         {completed_count} ({completed_count/total_workers*100:.0f}%)")
    report.append(f"Active:            {active_count}")
    report.append(f"Pending:           {pending_count}")
    report.append("")

    # Completed workers
    if self.completed:
        report.append("COMPLETED WORKERS")
        report.append("-" * 60)
        for worker in sorted(self.completed):
            metrics = self._get_worker_metrics(worker)
            report.append(f"✅ {worker}")
            report.append(f"   Duration: {metrics['duration']}")
            report.append(f"   Tokens: {metrics['tokens']:,}")
            report.append("")

    # Active workers
    if self.active:
        report.append("ACTIVE WORKERS")
        report.append("-" * 60)
        for worker in sorted(self.active):
            progress = self._get_worker_progress(worker)
            report.append(f"🔄 {worker}")
            report.append(f"   Progress: {progress['completed']}/{progress['total']} tasks")
            report.append(f"   Latest: {progress['latest_activity']}")
            report.append("")

    # Pending workers
    pending = [
        w for w in self.graph.dependencies.keys()
        if w not in self.completed and w not in self.active
    ]
    if pending:
        report.append("PENDING WORKERS")
        report.append("-" * 60)
        for worker in sorted(pending):
            deps = self.graph.dependencies[worker]
            blocking = [d for d in deps if d not in self.completed]
            if blocking:
                report.append(f"⏸️  {worker}")
                report.append(f"   Blocked by: {', '.join(blocking)}")
            else:
                report.append(f"🟢 {worker}")
                report.append(f"   Ready to start")
            report.append("")

    report.append("=" * 60)
    return "\n".join(report)
```

### Metrics Collection

Track metrics across all workers:

```python
# Collect orchestration metrics

from dataclasses import dataclass
from datetime import datetime

@dataclass
class WorkerMetrics:
    """Metrics for a single worker."""
    worker_id: str
    start_time: datetime
    end_time: datetime | None
    tokens_used: int
    commits: int
    files_created: int
    files_modified: int
    tests_added: int

class MetricsCollector:
    """Collect metrics across all workers."""

    def __init__(self):
        self.worker_metrics: Dict[str, WorkerMetrics] = {}

    def collect_worker_metrics(self, worker_id: str) -> WorkerMetrics:
        """Collect metrics for a worker.

        Args:
            worker_id: Worker to collect metrics for

        Returns:
            WorkerMetrics with collected data
        """
        # Get git metrics
        commits = self._count_commits(worker_id)
        files_created = self._count_files_created(worker_id)
        files_modified = self._count_files_modified(worker_id)

        # Get test metrics
        tests_added = self._count_tests_added(worker_id)

        # Get token usage from logs
        tokens_used = self._get_token_usage(worker_id)

        # Get timing from event log
        start_time, end_time = self._get_timing(worker_id)

        return WorkerMetrics(
            worker_id=worker_id,
            start_time=start_time,
            end_time=end_time,
            tokens_used=tokens_used,
            commits=commits,
            files_created=files_created,
            files_modified=files_modified,
            tests_added=tests_added,
        )

    def generate_metrics_report(self) -> str:
        """Generate comprehensive metrics report."""
        # Collect metrics for all workers
        for worker_id in self.completed:
            self.worker_metrics[worker_id] = self.collect_worker_metrics(worker_id)

        # Generate report
        report = []
        report.append("ORCHESTRATION METRICS")
        report.append("=" * 60)

        # Per-worker metrics
        for worker_id, metrics in sorted(self.worker_metrics.items()):
            duration = (metrics.end_time - metrics.start_time).total_seconds() / 3600
            report.append(f"\n{worker_id}")
            report.append(f"  Duration: {duration:.1f} hours")
            report.append(f"  Tokens: {metrics.tokens_used:,}")
            report.append(f"  Commits: {metrics.commits}")
            report.append(f"  Files Created: {metrics.files_created}")
            report.append(f"  Files Modified: {metrics.files_modified}")
            report.append(f"  Tests Added: {metrics.tests_added}")

        # Aggregate metrics
        total_tokens = sum(m.tokens_used for m in self.worker_metrics.values())
        total_commits = sum(m.commits for m in self.worker_metrics.values())
        total_files = sum(
            m.files_created + m.files_modified
            for m in self.worker_metrics.values()
        )

        report.append("\nAGGREGATE METRICS")
        report.append(f"  Total Tokens: {total_tokens:,}")
        report.append(f"  Total Commits: {total_commits}")
        report.append(f"  Total Files: {total_files}")

        return "\n".join(report)
```

## Git Workflow Coordination

### Branch Management

Orchestrator manages worker branches:

```python
# Git branch coordination

class GitCoordinator:
    """Coordinate git operations across workers."""

    def __init__(self, repo_path: Path):
        self.repo_path = repo_path

    def create_worker_branch(self, worker_id: str, base_branch: str = "main"):
        """Create branch for worker.

        Args:
            worker_id: Worker identifier
            base_branch: Branch to base worker branch on
        """
        branch_name = f"feat/agent-rules-{worker_id}"

        logger.info(
            "creating_worker_branch",
            worker_id=worker_id,
            branch=branch_name,
            base=base_branch,
        )

        # Create branch from base
        subprocess.run(
            ["git", "checkout", "-b", branch_name, base_branch],
            cwd=self.repo_path,
            check=True,
        )

        # Push branch to remote
        subprocess.run(
            ["git", "push", "-u", "origin", branch_name],
            cwd=self.repo_path,
            check=True,
        )

    def get_branch_status(self, worker_id: str) -> dict:
        """Get status of worker branch.

        Returns:
            Dict with branch status information
        """
        branch_name = f"feat/agent-rules-{worker_id}"

        # Get commit count
        result = subprocess.run(
            ["git", "rev-list", "--count", branch_name],
            cwd=self.repo_path,
            capture_output=True,
            text=True,
        )
        commit_count = int(result.stdout.strip())

        # Get latest commit
        result = subprocess.run(
            ["git", "log", "-1", "--format=%H %s", branch_name],
            cwd=self.repo_path,
            capture_output=True,
            text=True,
        )
        latest_commit = result.stdout.strip()

        # Check if branch is ahead of main
        result = subprocess.run(
            ["git", "rev-list", "--count", f"main..{branch_name}"],
            cwd=self.repo_path,
            capture_output=True,
            text=True,
        )
        commits_ahead = int(result.stdout.strip())

        return {
            "branch": branch_name,
            "commits": commit_count,
            "latest_commit": latest_commit,
            "commits_ahead": commits_ahead,
        }
```

### Worktree Management

Orchestrator manages git worktrees for parallel work:

```bash
# Create isolated worktrees for each worker

czarina create-worktree foundation
# Creates: .czarina/worktrees/foundation
# Branch: feat/agent-rules-foundation

czarina create-worktree workflows
# Creates: .czarina/worktrees/workflows
# Branch: feat/agent-rules-workflows

# Workers work in isolation
# .czarina/worktrees/foundation/  ← foundation worker
# .czarina/worktrees/workflows/   ← workflows worker
```

**Benefits:**
- Workers don't interfere with each other
- No branch switching needed
- Clean separation of concerns
- Easy cleanup after completion

## How Orchestrators Delegate Work

### Worker Assignment

Orchestrator assigns work to appropriate agents:

```python
# Worker assignment logic

class WorkerAssignment:
    """Assign workers to appropriate agents."""

    AGENT_PREFERENCES = {
        # File creation work
        "foundation": "aider",
        "patterns": "aider",

        # Documentation work
        "workflows": "cursor",
        "templates": "cursor",

        # Testing work
        "testing": "aider",
        "security": "aider",

        # Integration work
        "qa": "aider",
    }

    def assign_agent(self, worker_id: str) -> str:
        """Assign appropriate agent for worker.

        Args:
            worker_id: Worker identifier

        Returns:
            Agent type to use (aider, cursor, etc.)
        """
        return self.AGENT_PREFERENCES.get(worker_id, "aider")

    def create_worker_identity(self, worker_id: str) -> str:
        """Create WORKER_IDENTITY.md for worker.

        Args:
            worker_id: Worker identifier

        Returns:
            Path to created identity file
        """
        agent = self.assign_agent(worker_id)
        branch = f"feat/agent-rules-{worker_id}"
        worktree = f".czarina/worktrees/{worker_id}"

        identity = f"""# Worker Identity: {worker_id}

You are the **{worker_id}** worker in this czarina orchestration.

## Your Role
{self._get_worker_role(worker_id)}

## Your Instructions
Full task list: $(pwd)/../workers/{worker_id}.md

## Quick Reference
- **Branch:** {branch}
- **Location:** {worktree}
- **Agent:** {agent}
- **Dependencies:** {self._get_dependencies(worker_id)}

## Your Mission
Read your full instructions at ../workers/{worker_id}.md and begin work.

Let's build this!
"""

        identity_path = Path(worktree) / "WORKER_IDENTITY.md"
        identity_path.write_text(identity)
        return str(identity_path)
```

## Daily Workflow Patterns

### Daily Standup

Orchestrator generates daily status:

```python
# Daily standup report

def generate_daily_standup(self) -> str:
    """Generate daily standup report.

    Returns:
        Formatted standup report
    """
    report = []
    report.append(f"DAILY STANDUP - {datetime.now().strftime('%Y-%m-%d')}")
    report.append("=" * 60)

    # Yesterday's progress
    yesterday_completed = self._get_completed_since_yesterday()
    if yesterday_completed:
        report.append("\nCOMPLETED YESTERDAY:")
        for worker in yesterday_completed:
            report.append(f"  ✅ {worker}")

    # Today's active work
    if self.active:
        report.append("\nACTIVE TODAY:")
        for worker in sorted(self.active):
            progress = self._get_worker_progress(worker)
            report.append(f"  🔄 {worker} - {progress['summary']}")

    # Blockers
    blocked = self._get_blocked_workers()
    if blocked:
        report.append("\nBLOCKED:")
        for worker, blocker in blocked.items():
            report.append(f"  ⚠️  {worker} - waiting on {blocker}")

    # Ready to start
    ready = self._find_ready_workers()
    if ready:
        report.append("\nREADY TO START:")
        for worker in ready:
            report.append(f"  🟢 {worker}")

    return "\n".join(report)
```

### Weekly Summary

Generate weekly progress summary:

```markdown
# Weekly Summary - Week of 2025-12-20

## Completed This Week
- ✅ foundation (1.15M tokens, 6 days)
- ✅ workflows (850K tokens, 6 days)

## Active
- 🔄 patterns (3 days in, 60% complete)

## Starting Next Week
- testing (waiting for patterns)
- security (waiting for patterns)

## Metrics
- Total tokens used: 2M / 5.8M budget (34%)
- Timeline: On schedule (Week 1 of 3)
- Workers completed: 2 / 7 (29%)

## Risks
- None identified

## Blockers
- None

## Next Week Plan
- Complete patterns worker
- Launch testing and security workers
- Begin integration planning
```

## Success Criteria

An orchestrator has succeeded when:

- ✅ All workers launched at appropriate times
- ✅ Dependencies resolved correctly
- ✅ No workers blocked unnecessarily
- ✅ Status monitoring comprehensive
- ✅ Metrics collected throughout
- ✅ Progress reports generated regularly
- ✅ All workers completed successfully
- ✅ Final integration coordinated
- ✅ Comprehensive closeout report produced
- ✅ Project delivered on time and within budget

## Anti-Patterns

### Micromanagement
❌ **Don't:** Tell workers how to do their work
✅ **Do:** Define what needs to be done, let workers decide how

### Ignoring Blockers
❌ **Don't:** Let workers stay blocked without intervention
✅ **Do:** Actively resolve dependencies and blockers

### Poor Communication
❌ **Don't:** Fail to keep stakeholders informed
✅ **Do:** Generate regular status reports and updates

### Premature Launching
❌ **Don't:** Launch workers before dependencies complete
✅ **Do:** Respect dependency graph, launch only when ready

### No Metrics
❌ **Don't:** Track progress informally
✅ **Do:** Collect comprehensive metrics throughout

## Related Roles

- [QA_ROLE.md](./QA_ROLE.md) - Final integration and closeout
- [ARCHITECT_ROLE.md](./ARCHITECT_ROLE.md) - Plans orchestration structure
- [CODE_ROLE.md](./CODE_ROLE.md) - Workers that orchestrator coordinates
- [AGENT_ROLES.md](./AGENT_ROLES.md) - Role taxonomy overview

## References

- [Czarina Documentation](https://github.com/czarina)
- <!-- Orchestration Plan - plans directory not included in this repository - plans directory not included in this repository -->
- [Worker Definitions](../../.czarina/workers/)
- <!-- Czarina README - internal orchestration directory -->
