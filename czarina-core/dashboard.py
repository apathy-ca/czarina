#!/usr/bin/env python3
"""
Claude Code Multi-Agent Orchestrator - Live Dashboard
Real-time monitoring of worker progress, PRs, and checkpoints
"""

import json
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

try:
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich.layout import Layout
    from rich.live import Live
    from rich.progress import Progress, SpinnerColumn, TextColumn
except ImportError:
    print("Installing required dependencies...")
    subprocess.run([sys.executable, "-m", "pip", "install", "rich"], check=True)
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich.layout import Layout
    from rich.live import Live


def load_config():
    """Load configuration from config.sh"""
    script_dir = Path(__file__).parent
    config_file = script_dir / "config.sh"

    # Read config values from shell script
    config = {}
    result = subprocess.run(
        ["bash", "-c", f"source {config_file} && echo PROJECT_ROOT=$PROJECT_ROOT && echo PROJECT_NAME=$PROJECT_NAME"],
        capture_output=True,
        text=True
    )

    for line in result.stdout.strip().split('\n'):
        if '=' in line:
            key, value = line.split('=', 1)
            config[key] = value

    # Get worker definitions
    result = subprocess.run(
        ["bash", "-c", f"source {config_file} && printf '%s\\n' \"${{WORKER_DEFINITIONS[@]}}\""],
        capture_output=True,
        text=True
    )

    workers = {}
    emojis = ["⚙️", "🔌", "📋", "📊", "🧪", "📚", "🔧", "🎯", "🚀", "💡"]
    for i, line in enumerate(result.stdout.strip().split('\n')):
        if line:
            parts = line.split('|')
            if len(parts) >= 2:
                worker_id = parts[0]
                branch = parts[1]
                workers[worker_id] = {
                    "branch": branch,
                    "emoji": emojis[i % len(emojis)]
                }

    return config, workers


class SarkDashboard:
    def __init__(self, orchestrator_dir: Path, repo_root: Path, project_name: str, workers: Dict):
        self.repo_root = repo_root
        self.orchestrator_dir = orchestrator_dir
        self.status_dir = self.orchestrator_dir / "status"
        self.status_file = self.status_dir / "master-status.json"
        self.console = Console()
        self.project_name = project_name
        self.workers = workers

    def load_status(self) -> Dict:
        """Load current status from JSON file"""
        if not self.status_file.exists():
            return self._create_default_status()

        with open(self.status_file) as f:
            return json.load(f)

    def _create_default_status(self) -> Dict:
        """Create default status structure"""
        return {
            "project": "SARK v1.1 Gateway Integration",
            "started": datetime.now().isoformat(),
            "phase": "initialization",
            "workers": {
                worker_id: {
                    "status": "pending",
                    "branch": info["branch"],
                    "pr": None,
                    "last_commit": None,
                    "files_changed": 0,
                }
                for worker_id, info in self.workers.items()
            },
            "checkpoints": {
                "day1_models": False,
                "day4_integration": False,
                "day7_testing": False,
                "day8_prs": False,
                "day9_validation": False,
                "day10_omnibus": False,
            },
        }

    def get_git_info(self, branch: str) -> Dict:
        """Get git information for a branch"""
        try:
            # Check if branch exists
            result = subprocess.run(
                ["git", "rev-parse", "--verify", branch],
                cwd=self.repo_root,
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                return {"exists": False}

            # Get last commit
            commit_info = subprocess.run(
                ["git", "log", "-1", "--pretty=format:%h|%s|%ar", branch],
                cwd=self.repo_root,
                capture_output=True,
                text=True,
            ).stdout.strip()

            # Get files changed (use two dots, not three)
            files_changed = subprocess.run(
                ["git", "diff", "--name-only", f"main..{branch}"],
                cwd=self.repo_root,
                capture_output=True,
                text=True,
            ).stdout.strip().split("\n")

            if commit_info:
                commit_hash, commit_msg, commit_time = commit_info.split("|", 2)
                return {
                    "exists": True,
                    "last_commit": commit_msg[:50],
                    "commit_hash": commit_hash,
                    "commit_time": commit_time,
                    "files_changed": len([f for f in files_changed if f]),
                }
        except Exception as e:
            return {"exists": False, "error": str(e)}

        return {"exists": False}

    def get_pr_info(self, branch: str) -> Optional[Dict]:
        """Get PR information for a branch"""
        try:
            result = subprocess.run(
                ["gh", "pr", "list", "--head", branch, "--json", "number,title,url,state,reviews"],
                cwd=self.repo_root,
                capture_output=True,
                text=True,
            )
            if result.returncode == 0 and result.stdout.strip():
                prs = json.loads(result.stdout)
                if prs:
                    pr = prs[0]
                    # Count approvals
                    approvals = sum(1 for r in pr.get("reviews", []) if r.get("state") == "APPROVED")
                    return {
                        "number": pr["number"],
                        "title": pr["title"],
                        "url": pr["url"],
                        "state": pr["state"],
                        "approvals": approvals,
                    }
        except Exception:
            pass
        return None

    def create_worker_table(self, status: Dict) -> Table:
        """Create worker status table"""
        table = Table(title="Worker Status", show_header=True, header_style="bold magenta")
        table.add_column("Worker", style="cyan", width=12)
        table.add_column("Status", width=12)
        table.add_column("Branch", style="blue", width=25)
        table.add_column("Files", justify="right", width=6)
        table.add_column("Last Commit", width=30)
        table.add_column("PR", width=15)

        for worker_id, info in self.workers.items():
            worker_status = status["workers"].get(worker_id, {})
            git_info = self.get_git_info(info["branch"])
            pr_info = self.get_pr_info(info["branch"])

            # Determine status icon
            if pr_info and pr_info["state"] == "MERGED":
                status_icon = "✅ Merged"
                status_style = "green"
            elif pr_info:
                status_icon = f"🔄 PR #{pr_info['number']}"
                status_style = "yellow"
            elif git_info.get("exists"):
                status_icon = "💻 Active"
                status_style = "cyan"
            else:
                status_icon = "⏸️  Pending"
                status_style = "dim"

            # Files changed
            files_count = str(git_info.get("files_changed", 0)) if git_info.get("exists") else "-"

            # Last commit
            last_commit = git_info.get("last_commit", "-") if git_info.get("exists") else "-"

            # PR status
            if pr_info:
                pr_status = f"👍 {pr_info['approvals']}"
                if pr_info["state"] == "MERGED":
                    pr_status = "✅ Merged"
            else:
                pr_status = "-"

            table.add_row(
                f"{info['emoji']} {worker_id}",
                f"[{status_style}]{status_icon}[/{status_style}]",
                info["branch"],
                files_count,
                last_commit,
                pr_status,
            )

        return table

    def create_checkpoint_panel(self, status: Dict) -> Panel:
        """Create checkpoint status panel"""
        checkpoints = status.get("checkpoints", {})

        checkpoint_text = []
        for checkpoint, done in checkpoints.items():
            icon = "✅" if done else "⏸️"
            day = checkpoint.split("_")[0].replace("day", "Day ")
            name = " ".join(checkpoint.split("_")[1:]).title()
            checkpoint_text.append(f"{icon} {day}: {name}")

        return Panel(
            "\n".join(checkpoint_text),
            title="Project Checkpoints",
            border_style="green",
        )

    def create_stats_panel(self, status: Dict) -> Panel:
        """Create statistics panel"""
        # Count workers by status
        total_workers = len(self.workers)
        active_workers = 0
        pr_workers = 0
        merged_workers = 0
        working_workers = 0  # Workers with commits

        for worker_id, info in self.workers.items():
            git_info = self.get_git_info(info["branch"])
            pr_info = self.get_pr_info(info["branch"])

            if pr_info and pr_info["state"] == "MERGED":
                merged_workers += 1
            elif pr_info:
                pr_workers += 1
            elif git_info.get("exists") and git_info.get("files_changed", 0) > 0:
                working_workers += 1
            elif git_info.get("exists"):
                active_workers += 1

        # Calculate progress (working + PR + merged = progress)
        progress_count = working_workers + pr_workers + merged_workers
        progress = (progress_count / total_workers) * 100

        stats = f"""
Total Workers: {total_workers}
Working: {working_workers} | PRs: {pr_workers} | Merged: {merged_workers}
Idle: {active_workers}

Work Progress: {progress:.1f}%
━━━━━━━━━━━━━━━━━━━━━
{'█' * int(progress / 5)}{'░' * (20 - int(progress / 5))}
        """

        return Panel(stats.strip(), title="Statistics", border_style="blue")

    def create_layout(self, status: Dict) -> Layout:
        """Create dashboard layout"""
        layout = Layout()

        # Create main vertical split - put header at top
        layout.split_column(
            Layout(name="top", ratio=1),
            Layout(name="bottom", size=1),  # Just 1 line for footer
        )

        # Split top into header and body
        layout["top"].split_column(
            Layout(name="header", size=4),  # Fixed size header
            Layout(name="body", ratio=1),   # Body takes remaining space
        )

        layout["top"]["header"].update(
            Panel(
                f"[bold cyan]{self.project_name}[/bold cyan] | "
                f"Started: {status.get('started', 'N/A')} | Phase: {status.get('phase', 'N/A')}",
                style="white on blue",
                title="[bold white]📊 Dashboard[/bold white]",
            )
        )

        layout["top"]["body"].split_row(
            Layout(name="workers", ratio=2),
            Layout(name="sidebar", ratio=1),
        )

        layout["top"]["body"]["workers"].update(self.create_worker_table(status))

        layout["top"]["body"]["sidebar"].split_column(
            Layout(self.create_stats_panel(status)),
            Layout(self.create_checkpoint_panel(status)),
        )

        layout["bottom"].update(
            "[dim]Ctrl+C: exit | Updates: 5s[/dim]"
        )

        return layout

    def run(self):
        """Run live dashboard"""
        try:
            with Live(self.create_layout(self.load_status()), refresh_per_second=0.2, console=self.console) as live:
                while True:
                    time.sleep(5)
                    status = self.load_status()
                    live.update(self.create_layout(status))
        except KeyboardInterrupt:
            self.console.print("\n[yellow]Dashboard stopped[/yellow]")


def main():
    # Load configuration
    config, workers = load_config()

    orchestrator_dir = Path(__file__).parent
    repo_root = Path(config.get("PROJECT_ROOT", "/home/jhenry/Source/GRID/sark"))
    project_name = config.get("PROJECT_NAME", "Project")

    dashboard = SarkDashboard(orchestrator_dir, repo_root, project_name, workers)
    dashboard.run()


if __name__ == "__main__":
    main()
