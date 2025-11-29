#!/usr/bin/env python3
"""
SARK v2.0 Orchestrator Control Script

This script manages the 10-engineer parallel development effort for SARK v2.0.
It assigns tasks, monitors progress, detects blockers, and coordinates integration.

Usage:
    # Initialize project
    ./orchestrate_sark_v2.py init

    # Start a specific engineer
    ./orchestrate_sark_v2.py start engineer-1

    # Start all engineers for current week
    ./orchestrate_sark_v2.py start-week 1

    # Generate daily status report
    ./orchestrate_sark_v2.py daily-report

    # Check for blockers
    ./orchestrate_sark_v2.py check-blockers

    # Run integration tests
    ./orchestrate_sark_v2.py test-integration

    # Advance to next week
    ./orchestrate_sark_v2.py next-week
"""

import os
import sys
import json
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional

# Paths
ORCHESTRATOR_DIR = Path(__file__).parent
SARK_DIR = ORCHESTRATOR_DIR.parent / "sark"
CONFIG_FILE = ORCHESTRATOR_DIR / "configs" / "sark-v2.0-project.json"
STATUS_FILE = SARK_DIR / ".orchestrator" / "status.json"
PROMPTS_DIR = ORCHESTRATOR_DIR / "prompts" / "sark-v2"

class SARKOrchestrator:
    """Main orchestrator for SARK v2.0 development"""

    def __init__(self):
        self.config = self._load_config()
        self.status = self._load_status()
        self.project = self.config["project"]
        self.team = self.config["team"]
        self.phases = self.config["phases"]

    def _load_config(self) -> Dict:
        """Load project configuration"""
        with open(CONFIG_FILE) as f:
            return json.load(f)

    def _load_status(self) -> Dict:
        """Load current status"""
        if STATUS_FILE.exists():
            with open(STATUS_FILE) as f:
                return json.load(f)
        return None

    def _save_status(self):
        """Save current status"""
        STATUS_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(STATUS_FILE, 'w') as f:
            json.dump(self.status, f, indent=2)

    def initialize_project(self):
        """Initialize the project orchestration"""
        print("🚀 Initializing SARK v2.0 Orchestration")
        print("=" * 80)

        # Run the init script
        import subprocess
        subprocess.run([sys.executable, ORCHESTRATOR_DIR / "init_sark_v2.py"])

        print("\n✅ Project initialized!")
        print("\nNext steps:")
        print("  1. ./orchestrate_sark_v2.py start-week 1")
        print("  2. Monitor progress with: ./orchestrate_sark_v2.py daily-report")

    def start_engineer(self, engineer_id: str):
        """Start a specific engineer with their assigned tasks"""
        # Find engineer config
        engineer = next((e for e in self.team['engineers'] if e['id'] == engineer_id), None)
        if not engineer:
            print(f"❌ Engineer not found: {engineer_id}")
            return

        print(f"🚀 Starting {engineer_id}: {engineer['name']}")
        print("=" * 80)

        # Load engineer prompt
        prompt_file = PROMPTS_DIR / f"{engineer_id.upper()}.md"
        if not prompt_file.exists():
            prompt_file = PROMPTS_DIR / f"{engineer_id.upper()}-{engineer['role'].upper()}.md"

        if prompt_file.exists():
            print(f"\n📋 Loading prompt from: {prompt_file.name}")
            with open(prompt_file) as f:
                prompt = f.read()
            print("\n" + "=" * 80)
            print("ENGINEER PROMPT")
            print("=" * 80)
            print(prompt[:500] + "...\n[Truncated - see full prompt in file]")
        else:
            print(f"⚠️  No prompt file found: {prompt_file}")
            print("Creating engineer instructions from config...")
            prompt = self._generate_engineer_prompt(engineer)

        # Get current week tasks
        current_week = self.status['current_week']
        tasks = self._get_week_tasks(engineer_id, current_week)

        print(f"\n📝 Week {current_week} Tasks for {engineer_id}:")
        for i, task in enumerate(tasks, 1):
            print(f"  {i}. {task}")

        print(f"\n✅ {engineer_id} is ready to begin work!")
        print(f"\nTo run {engineer_id} in Claude Code:")
        print(f"  1. Open new Claude Code session in SARK directory")
        print(f"  2. Provide the prompt from: {prompt_file}")
        print(f"  3. Engineer will begin executing tasks autonomously")

    def _generate_engineer_prompt(self, engineer: Dict) -> str:
        """Generate a prompt for an engineer from config"""
        prompt = f"""# {engineer['id'].upper()}: {engineer['name']}

## Role
{engineer['role']}

## Skills
{', '.join(engineer['skills'])}

## Responsibilities
"""
        for resp in engineer['responsibilities']:
            prompt += f"- {resp}\n"

        prompt += "\n## Deliverables\n"
        for deliv in engineer['deliverables']:
            prompt += f"- {deliv}\n"

        prompt += "\n## Dependencies\n"
        if engineer['dependencies']:
            for dep in engineer['dependencies']:
                prompt += f"- Requires: {dep}\n"
        else:
            prompt += "- No dependencies\n"

        prompt += f"\n## Timeline\n{engineer['timeline']}\n"
        prompt += f"\n## Priority\n{engineer['priority']}\n"

        return prompt

    def _get_week_tasks(self, engineer_id: str, week: int) -> List[str]:
        """Get tasks for an engineer for a specific week"""
        # This would be more sophisticated in practice
        # For now, return tasks from the config based on timeline

        engineer = next((e for e in self.team['engineers'] if e['id'] == engineer_id), None)
        if not engineer:
            return []

        # Parse timeline (e.g., "weeks-1-to-3")
        timeline = engineer['timeline']
        if f"week-{week}" in timeline or f"weeks-{week}" in timeline:
            return engineer['responsibilities'][:3]  # First 3 responsibilities for that week

        return []

    def start_week(self, week_num: int):
        """Start all engineers assigned to a specific week"""
        print(f"🚀 Starting Week {week_num} of SARK v2.0 Development")
        print("=" * 80)

        # Find which phase this week belongs to
        current_phase = None
        for phase in self.phases:
            if phase['start_week'] <= week_num < phase['start_week'] + phase['duration_weeks']:
                current_phase = phase
                break

        if current_phase:
            print(f"\n📅 Phase {current_phase['phase']}: {current_phase['name']}")
            print(f"\nPhase Objectives:")
            for obj in current_phase['objectives']:
                print(f"  • {obj}")

        # Find engineers active this week
        active_engineers = []
        for engineer in self.team['engineers']:
            timeline = engineer['timeline']
            # Parse timeline to see if this week is included
            if f"week-{week_num}" in timeline or f"weeks-{week_num}" in timeline or \
               (f"to-{week_num}" in timeline) or (f"{week_num}-to" in timeline):
                active_engineers.append(engineer)

        print(f"\n👥 Active Engineers this week: {len(active_engineers)}")
        for eng in active_engineers:
            print(f"  • {eng['id']}: {eng['name']} ({eng['role']})")

        print(f"\n🎯 To start each engineer:")
        for eng in active_engineers:
            print(f"  ./orchestrate_sark_v2.py start {eng['id']}")

        # Update status
        if self.status:
            self.status['current_week'] = week_num
            self.status['current_phase'] = current_phase['phase'] if current_phase else 0
            self._save_status()

    def generate_daily_report(self):
        """Generate daily status report"""
        print("📊 SARK v2.0 Daily Status Report")
        print("=" * 80)
        print(f"Date: {datetime.now().strftime('%Y-%m-%d')}")
        print(f"Week: {self.status['current_week']}")
        print(f"Phase: {self.status['current_phase']}")
        print()

        # Engineer status
        print("👥 Engineer Status:")
        for eng_id, eng_status in self.status['engineers'].items():
            status_icon = "✅" if eng_status['status'] == "completed" else \
                         "🔄" if eng_status['status'] == "in_progress" else "⏸️"
            print(f"  {status_icon} {eng_id}: {eng_status['name']}")
            print(f"     Status: {eng_status['status']}")
            if eng_status['current_tasks']:
                print(f"     Current: {', '.join(eng_status['current_tasks'][:2])}")
            if eng_status['blockers']:
                print(f"     ⚠️  Blockers: {', '.join(eng_status['blockers'])}")

        # Milestones
        print("\n🎯 Milestone Status:")
        for milestone, status in self.status['milestones'].items():
            status_icon = "✅" if status == "completed" else \
                         "🔄" if status == "in_progress" else "⏸️"
            print(f"  {status_icon} {milestone}: {status}")

        # Check git for recent activity
        print("\n📝 Recent Git Activity:")
        try:
            import subprocess
            os.chdir(SARK_DIR)
            result = subprocess.run(
                ["git", "log", "--oneline", "--since=24.hours", "--all"],
                capture_output=True,
                text=True
            )
            commits = result.stdout.strip().split('\n')[:5]
            if commits and commits[0]:
                for commit in commits:
                    print(f"  • {commit}")
            else:
                print("  No commits in last 24 hours")
        except Exception as e:
            print(f"  Could not fetch git activity: {e}")

    def check_blockers(self):
        """Check for blockers across the team"""
        print("🚨 Blocker Check")
        print("=" * 80)

        blockers_found = False
        for eng_id, eng_status in self.status['engineers'].items():
            if eng_status['blockers']:
                blockers_found = True
                print(f"\n⚠️  {eng_id}: {eng_status['name']}")
                for blocker in eng_status['blockers']:
                    print(f"  • {blocker}")

        if not blockers_found:
            print("\n✅ No blockers reported!")
        else:
            print("\n💡 Action Required: Address blockers above")

    def run_integration_tests(self):
        """Run integration tests"""
        print("🧪 Running Integration Tests")
        print("=" * 80)

        os.chdir(SARK_DIR)
        import subprocess

        try:
            result = subprocess.run(
                ["pytest", "tests/integration/", "-v", "--tb=short"],
                capture_output=True,
                text=True
            )
            print(result.stdout)
            if result.returncode == 0:
                print("\n✅ All integration tests passed!")
            else:
                print("\n❌ Some integration tests failed")
                print(result.stderr)
        except Exception as e:
            print(f"❌ Could not run tests: {e}")

    def advance_week(self):
        """Advance to the next week"""
        current_week = self.status['current_week']
        next_week = current_week + 1

        print(f"📅 Advancing from Week {current_week} to Week {next_week}")
        print("=" * 80)

        # Check if current week milestone is complete
        milestone_key = f"week_{current_week}"
        if milestone_key in self.status['milestones']:
            milestone_status = self.status['milestones'][milestone_key]
            if milestone_status != "completed":
                print(f"⚠️  Warning: Week {current_week} milestone not marked complete")
                response = input("Continue anyway? (y/n): ")
                if response.lower() != 'y':
                    print("Cancelled.")
                    return

        # Update status
        self.status['current_week'] = next_week
        self._save_status()

        print(f"✅ Advanced to Week {next_week}")

        # Start next week
        self.start_week(next_week)


def main():
    parser = argparse.ArgumentParser(description="SARK v2.0 Orchestrator")
    subparsers = parser.add_subparsers(dest='command', help='Commands')

    # Init
    subparsers.add_parser('init', help='Initialize project orchestration')

    # Start engineer
    start_parser = subparsers.add_parser('start', help='Start a specific engineer')
    start_parser.add_argument('engineer_id', help='Engineer ID (e.g., engineer-1)')

    # Start week
    week_parser = subparsers.add_parser('start-week', help='Start all engineers for a week')
    week_parser.add_argument('week', type=int, help='Week number (1-8)')

    # Daily report
    subparsers.add_parser('daily-report', help='Generate daily status report')

    # Check blockers
    subparsers.add_parser('check-blockers', help='Check for blockers')

    # Run tests
    subparsers.add_parser('test-integration', help='Run integration tests')

    # Advance week
    subparsers.add_parser('next-week', help='Advance to next week')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    orchestrator = SARKOrchestrator()

    if args.command == 'init':
        orchestrator.initialize_project()
    elif args.command == 'start':
        orchestrator.start_engineer(args.engineer_id)
    elif args.command == 'start-week':
        orchestrator.start_week(args.week)
    elif args.command == 'daily-report':
        orchestrator.generate_daily_report()
    elif args.command == 'check-blockers':
        orchestrator.check_blockers()
    elif args.command == 'test-integration':
        orchestrator.run_integration_tests()
    elif args.command == 'next-week':
        orchestrator.advance_week()


if __name__ == "__main__":
    main()
