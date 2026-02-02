#!/usr/bin/env python3
"""
Czarina Learning Extraction System

Automatically extracts learnings from phase closeouts:
- Git statistics per worker
- Worker status and metrics
- Pattern detection (heuristic-based)
- Northbound flagging for agent-knowledge contribution

Design: agent-knowledge/meta/learning-extraction.md
"""

import json
import os
import re
import subprocess
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional, Any
import shutil


class LearningsExtractor:
    """
    Extracts learnings from a Czarina phase closeout.

    Output Structure:
    - .czarina/learnings/phase-{N}-closeout.json - Per-phase learnings
    - .czarina/learnings/northbound/ - Patterns flagged for contribution
    """

    def __init__(self, czarina_dir: Path, project_root: Path):
        """
        Initialize the extractor.

        Args:
            czarina_dir: Path to .czarina directory
            project_root: Path to project root (for git operations)
        """
        self.czarina_dir = Path(czarina_dir)
        self.project_root = Path(project_root)
        self.learnings_dir = self.czarina_dir / "learnings"
        self.northbound_dir = self.learnings_dir / "northbound"

    def extract(self, phase: str, version: str, enhanced: bool = False) -> Dict[str, Any]:
        """
        Extract learnings from the current phase.

        Args:
            phase: Phase number (e.g., "1")
            version: Version string (e.g., "0.7.0")
            enhanced: Whether to use LLM for enhanced analysis

        Returns:
            Dictionary containing extracted learnings
        """
        # Ensure directories exist
        self.learnings_dir.mkdir(parents=True, exist_ok=True)
        self.northbound_dir.mkdir(parents=True, exist_ok=True)

        # Load config and worker data
        config = self._load_config()
        workers = config.get("workers", [])
        project_name = config.get("project", {}).get("name", self.project_root.name)

        # Extract metrics
        git_stats = self._extract_git_stats(workers)
        worker_data = self._extract_worker_data()

        # Generate learnings
        learnings = self._generate_basic_learnings(workers, git_stats, worker_data)

        # Flag northbound patterns
        northbound = self._flag_northbound_patterns(learnings, phase)

        # Build output
        output = {
            "source": "czarina",
            "project": project_name,
            "phase": phase,
            "version": version,
            "extracted_at": datetime.utcnow().isoformat() + "Z",
            "extraction_mode": "enhanced" if enhanced else "basic",
            "metrics": {
                "workers": {
                    "total": len(workers),
                    "with_commits": len([w for w in git_stats.get("per_worker", {}).values() if w.get("commits", 0) > 0])
                },
                "git": git_stats
            },
            "learnings": learnings,
            "northbound_candidates": northbound,
            "raw_data": {
                "worker_count": len(workers),
                "worker_ids": [w.get("id", "unknown") for w in workers]
            }
        }

        return output

    def _load_config(self) -> Dict[str, Any]:
        """Load config.json if it exists."""
        config_file = self.czarina_dir / "config.json"
        if config_file.exists():
            try:
                with open(config_file) as f:
                    return json.load(f)
            except json.JSONDecodeError:
                pass
        return {}

    def _extract_git_stats(self, workers: List[Dict]) -> Dict[str, Any]:
        """
        Extract git statistics for worker branches.

        Args:
            workers: List of worker configurations

        Returns:
            Dictionary with git statistics
        """
        stats = {
            "total_commits": 0,
            "total_files_changed": 0,
            "lines_added": 0,
            "lines_removed": 0,
            "per_worker": {}
        }

        for worker in workers:
            worker_id = worker.get("id", "unknown")
            branch = worker.get("branch", f"feat/{worker_id}")

            worker_stats = self._get_branch_stats(branch)
            stats["per_worker"][worker_id] = worker_stats

            # Aggregate totals
            stats["total_commits"] += worker_stats.get("commits", 0)
            stats["total_files_changed"] += worker_stats.get("files_changed", 0)
            stats["lines_added"] += worker_stats.get("lines_added", 0)
            stats["lines_removed"] += worker_stats.get("lines_removed", 0)

        return stats

    def _get_branch_stats(self, branch: str) -> Dict[str, int]:
        """Get git statistics for a specific branch."""
        stats = {
            "commits": 0,
            "files_changed": 0,
            "lines_added": 0,
            "lines_removed": 0
        }

        try:
            # Check if branch exists
            result = subprocess.run(
                ["git", "rev-parse", "--verify", branch],
                cwd=self.project_root,
                capture_output=True,
                text=True
            )
            if result.returncode != 0:
                return stats

            # Get commit count (compared to main)
            result = subprocess.run(
                ["git", "rev-list", "--count", f"main..{branch}"],
                cwd=self.project_root,
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                stats["commits"] = int(result.stdout.strip() or 0)

            # Get diffstat (compared to main)
            result = subprocess.run(
                ["git", "diff", "--shortstat", f"main...{branch}"],
                cwd=self.project_root,
                capture_output=True,
                text=True
            )
            if result.returncode == 0 and result.stdout.strip():
                # Parse: "X files changed, Y insertions(+), Z deletions(-)"
                output = result.stdout.strip()

                files_match = re.search(r'(\d+) files? changed', output)
                if files_match:
                    stats["files_changed"] = int(files_match.group(1))

                insertions_match = re.search(r'(\d+) insertions?\(\+\)', output)
                if insertions_match:
                    stats["lines_added"] = int(insertions_match.group(1))

                deletions_match = re.search(r'(\d+) deletions?\(-\)', output)
                if deletions_match:
                    stats["lines_removed"] = int(deletions_match.group(1))

        except Exception:
            pass

        return stats

    def _extract_worker_data(self) -> Dict[str, Any]:
        """Extract data from worker status files and logs."""
        data = {
            "statuses": {},
            "logs_available": False
        }

        # Check for status files
        status_dir = self.czarina_dir / "status"
        if status_dir.exists():
            for status_file in status_dir.glob("*.json"):
                try:
                    with open(status_file) as f:
                        worker_id = status_file.stem
                        data["statuses"][worker_id] = json.load(f)
                except (json.JSONDecodeError, IOError):
                    pass

        # Check for logs
        logs_dir = self.czarina_dir / "logs"
        data["logs_available"] = logs_dir.exists() and any(logs_dir.iterdir()) if logs_dir.exists() else False

        return data

    def _generate_basic_learnings(self, workers: List[Dict], git_stats: Dict,
                                   worker_data: Dict) -> Dict[str, List]:
        """
        Generate learnings using heuristics (no LLM required).

        Args:
            workers: Worker configurations
            git_stats: Git statistics
            worker_data: Worker status/log data

        Returns:
            Dictionary with what_worked, what_didnt_work, patterns_observed
        """
        learnings = {
            "what_worked": [],
            "what_didnt_work": [],
            "patterns_observed": []
        }

        per_worker = git_stats.get("per_worker", {})
        total_commits = git_stats.get("total_commits", 0)

        # Pattern: All workers contributed
        workers_with_commits = len([w for w in per_worker.values() if w.get("commits", 0) > 0])
        if workers_with_commits == len(workers) and len(workers) > 1:
            learnings["what_worked"].append({
                "id": "ww-all-contributed",
                "description": "All workers made commits - good task distribution",
                "evidence": f"{workers_with_commits}/{len(workers)} workers committed",
                "confidence": "high",
                "generalizable": True
            })
        elif workers_with_commits < len(workers) and len(workers) > 1:
            idle_workers = len(workers) - workers_with_commits
            learnings["what_didnt_work"].append({
                "id": "wd-idle-workers",
                "description": f"{idle_workers} worker(s) made no commits",
                "evidence": f"Only {workers_with_commits}/{len(workers)} workers committed",
                "root_cause": "Possible blocking dependency or unclear scope",
                "confidence": "medium",
                "generalizable": True
            })

        # Pattern: Commit distribution
        if total_commits > 0 and len(per_worker) > 1:
            commits_list = [w.get("commits", 0) for w in per_worker.values()]
            max_commits = max(commits_list)
            min_commits = min(commits_list)

            if max_commits > 0 and min_commits > 0:
                ratio = max_commits / min_commits if min_commits > 0 else float('inf')
                if ratio <= 3:
                    learnings["what_worked"].append({
                        "id": "ww-balanced-load",
                        "description": "Commit load was relatively balanced across workers",
                        "evidence": f"Commit ratio (max/min): {ratio:.1f}",
                        "confidence": "medium",
                        "generalizable": True
                    })
                elif ratio > 5:
                    learnings["patterns_observed"].append({
                        "id": "po-unbalanced-load",
                        "name": "Unbalanced commit distribution",
                        "description": f"One worker committed {ratio:.1f}x more than another",
                        "frequency": "This phase",
                        "significance": "May indicate scope imbalance",
                        "generalizable": False
                    })

        # Pattern: High productivity
        if total_commits >= len(workers) * 5:
            learnings["what_worked"].append({
                "id": "ww-high-productivity",
                "description": "High commit frequency indicates good progress",
                "evidence": f"{total_commits} total commits, ~{total_commits/len(workers):.1f} per worker",
                "confidence": "medium",
                "generalizable": False
            })

        # Pattern: File changes indicate scope
        total_files = git_stats.get("total_files_changed", 0)
        if total_files > 0:
            avg_files_per_worker = total_files / len(workers) if workers else 0
            learnings["patterns_observed"].append({
                "id": "po-file-scope",
                "name": "File modification scope",
                "description": f"Workers modified ~{avg_files_per_worker:.1f} files on average",
                "frequency": "This phase",
                "significance": "Scope indicator",
                "generalizable": False
            })

        # Pattern: Lines of code
        lines_added = git_stats.get("lines_added", 0)
        lines_removed = git_stats.get("lines_removed", 0)
        if lines_added > 0 or lines_removed > 0:
            net_change = lines_added - lines_removed
            learnings["patterns_observed"].append({
                "id": "po-loc-change",
                "name": "Code volume",
                "description": f"+{lines_added}/-{lines_removed} lines (net: {'+' if net_change >= 0 else ''}{net_change})",
                "frequency": "This phase",
                "significance": "Size indicator",
                "generalizable": False
            })

        return learnings

    def _flag_northbound_patterns(self, learnings: Dict, phase: str) -> List[Dict]:
        """
        Identify patterns that should be contributed to agent-knowledge.

        Args:
            learnings: Extracted learnings
            phase: Current phase number

        Returns:
            List of northbound candidates
        """
        candidates = []

        # Check what_worked for generalizable patterns
        for item in learnings.get("what_worked", []):
            if item.get("generalizable", False) and item.get("confidence") == "high":
                candidates.append({
                    "pattern_id": item["id"],
                    "type": "what_worked",
                    "suggested_category": "orchestration",
                    "description": item["description"],
                    "evidence": item.get("evidence", ""),
                    "staging_file": f"northbound/phase-{phase}-{item['id']}.json"
                })

        # Check what_didnt_work for generalizable anti-patterns
        for item in learnings.get("what_didnt_work", []):
            if item.get("generalizable", False):
                candidates.append({
                    "pattern_id": item["id"],
                    "type": "anti_pattern",
                    "suggested_category": "error-recovery",
                    "description": item["description"],
                    "root_cause": item.get("root_cause", ""),
                    "staging_file": f"northbound/phase-{phase}-{item['id']}.json"
                })

        # Write staging files for candidates
        for candidate in candidates:
            staging_path = self.learnings_dir / candidate["staging_file"]
            staging_path.parent.mkdir(parents=True, exist_ok=True)
            with open(staging_path, 'w') as f:
                json.dump(candidate, f, indent=2)

        return candidates

    def write_learnings(self, output_path: Path, learnings: Dict):
        """
        Write learnings to JSON file.

        Args:
            output_path: Path to output file
            learnings: Learnings dictionary
        """
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'w') as f:
            json.dump(learnings, f, indent=2)

    def append_to_memory(self, memories_file: Path, learnings: Dict):
        """
        Append a summary of learnings to memories.md.

        Args:
            memories_file: Path to memories.md
            learnings: Learnings dictionary
        """
        if not memories_file.exists():
            return

        phase = learnings.get("phase", "?")
        version = learnings.get("version", "?")
        extracted_at = learnings.get("extracted_at", "")[:10]  # Date only

        summary = f"""

---

## Phase {phase} Learnings (v{version}) - {extracted_at}

### What Worked
"""
        for item in learnings.get("learnings", {}).get("what_worked", []):
            summary += f"- {item['description']}\n"

        summary += "\n### What Didn't Work\n"
        for item in learnings.get("learnings", {}).get("what_didnt_work", []):
            summary += f"- {item['description']}"
            if item.get("root_cause"):
                summary += f" (Root cause: {item['root_cause']})"
            summary += "\n"

        summary += "\n### Metrics\n"
        metrics = learnings.get("metrics", {})
        git = metrics.get("git", {})
        summary += f"- Workers: {metrics.get('workers', {}).get('total', 0)}\n"
        summary += f"- Commits: {git.get('total_commits', 0)}\n"
        summary += f"- Lines: +{git.get('lines_added', 0)}/-{git.get('lines_removed', 0)}\n"

        with open(memories_file, 'a') as f:
            f.write(summary)


def print_learnings_summary(learnings: Dict):
    """Print a human-readable summary of learnings."""
    print()
    print("📊 Learning Extraction Complete")
    print("=" * 40)

    metrics = learnings.get("metrics", {})
    git = metrics.get("git", {})
    workers = metrics.get("workers", {})

    print(f"   Workers: {workers.get('total', 0)} ({workers.get('with_commits', 0)} with commits)")
    print(f"   Commits: {git.get('total_commits', 0)}")
    print(f"   Files changed: {git.get('total_files_changed', 0)}")
    print(f"   Lines: +{git.get('lines_added', 0)}/-{git.get('lines_removed', 0)}")

    learnings_data = learnings.get("learnings", {})
    what_worked = learnings_data.get("what_worked", [])
    what_didnt = learnings_data.get("what_didnt_work", [])

    if what_worked:
        print()
        print("   ✅ What worked:")
        for item in what_worked[:3]:  # Show top 3
            print(f"      - {item['description']}")

    if what_didnt:
        print()
        print("   ⚠️  What didn't work:")
        for item in what_didnt[:3]:  # Show top 3
            print(f"      - {item['description']}")

    northbound = learnings.get("northbound_candidates", [])
    if northbound:
        print()
        print(f"   📤 {len(northbound)} pattern(s) flagged for northbound contribution")
        print("      Run 'czarina learnings northbound' to review")

    print()
