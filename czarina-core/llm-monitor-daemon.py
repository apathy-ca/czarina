#!/usr/bin/env python3
"""
Czarina LLM Monitor Daemon
Event-driven intelligent worker monitoring using Claude Haiku

Watches worker activity via:
1. Log file updates (inotify events)
2. Periodic tmux pane scraping for stale workers
3. events.jsonl updates

On activity, analyzes worker state with Claude Haiku and takes action:
- Auto-approve prompts
- Send keystrokes
- Flag for human intervention
- Log all decisions

Usage: ./llm-monitor-daemon.py [project-dir]
"""

import os
import sys
import json
import time
import subprocess
import logging
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass

try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler
except ImportError:
    print("❌ Error: watchdog library not installed")
    print("   Install: pip install watchdog")
    sys.exit(1)

try:
    import anthropic
except ImportError:
    print("❌ Error: anthropic library not installed")
    print("   Install: pip install anthropic")
    sys.exit(1)


# ============================================================================
# CONFIGURATION
# ============================================================================

@dataclass
class MonitorConfig:
    """Configuration for LLM monitoring"""
    enabled: bool = True
    model: str = "claude-3-5-haiku-20241022"  # Fast and cheap
    check_interval: int = 30  # seconds between stale worker checks
    stale_threshold: int = 300  # 5 minutes = stale
    max_context_lines: int = 100  # lines of tmux to analyze
    auto_approve: bool = True  # auto-approve based on LLM recommendation
    log_all_decisions: bool = True
    api_key: Optional[str] = None


# ============================================================================
# WORKER STATE TRACKING
# ============================================================================

class WorkerState:
    """Track state of a worker"""

    def __init__(self, worker_id: str, window_num: int):
        self.worker_id = worker_id
        self.window_num = window_num
        self.last_activity = datetime.now()
        self.last_analysis = None
        self.status = "STARTING"
        self.consecutive_stuck_count = 0

    def update_activity(self):
        """Mark worker as having recent activity"""
        self.last_activity = datetime.now()
        self.consecutive_stuck_count = 0

    def is_stale(self, threshold_seconds: int) -> bool:
        """Check if worker hasn't had activity in threshold seconds"""
        return (datetime.now() - self.last_activity).seconds > threshold_seconds


# ============================================================================
# TMUX INTERFACE
# ============================================================================

class TmuxInterface:
    """Interface for interacting with tmux sessions"""

    def __init__(self, session_name: str):
        self.session_name = session_name

    def capture_pane(self, window: int, lines: int = 100) -> Optional[str]:
        """Capture last N lines from a tmux pane"""
        try:
            result = subprocess.run(
                ["tmux", "capture-pane", "-t", f"{self.session_name}:{window}",
                 "-p", "-S", f"-{lines}"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                return result.stdout
            return None
        except Exception as e:
            logging.error(f"Failed to capture tmux pane {window}: {e}")
            return None

    def send_keys(self, window: int, keys: str) -> bool:
        """Send keys to a tmux pane"""
        try:
            result = subprocess.run(
                ["tmux", "send-keys", "-t", f"{self.session_name}:{window}", keys],
                capture_output=True,
                timeout=5
            )
            return result.returncode == 0
        except Exception as e:
            logging.error(f"Failed to send keys to window {window}: {e}")
            return False

    def session_exists(self) -> bool:
        """Check if tmux session exists"""
        try:
            result = subprocess.run(
                ["tmux", "has-session", "-t", self.session_name],
                capture_output=True,
                timeout=5
            )
            return result.returncode == 0
        except:
            return False


# ============================================================================
# LLM ANALYZER
# ============================================================================

class WorkerAnalyzer:
    """Analyzes worker state using Claude Haiku"""

    def __init__(self, config: MonitorConfig):
        self.config = config
        self.client = anthropic.Anthropic(api_key=config.api_key)
        self.total_requests = 0
        self.total_cost = 0.0

    def analyze_worker(
        self,
        worker_id: str,
        terminal_output: str,
        last_event: Optional[str] = None,
        worker_prompt: Optional[str] = None
    ) -> Dict:
        """
        Analyze worker state using Claude Haiku

        Returns dict with:
        - status: working|stuck|waiting|complete|confused|error
        - action: approve|send_keys|intervene|none
        - keys: optional keys to send if action=send_keys
        - reasoning: explanation
        - confidence: 0-100
        """

        # Build context
        context_parts = [
            f"Worker ID: {worker_id}",
            f"Terminal output (last {len(terminal_output.splitlines())} lines):",
            "```",
            terminal_output,
            "```"
        ]

        if last_event:
            context_parts.insert(1, f"Last logged event: {last_event}")

        if worker_prompt:
            context_parts.insert(1, f"Worker's assigned task: {worker_prompt[:500]}...")

        prompt = "\n".join(context_parts)

        system_prompt = """You are an autonomous orchestration monitor analyzing AI coding agent activity.

Analyze the terminal output and determine:

1. **Status** (choose one):
   - working: Agent is actively coding, thinking, or making progress
   - stuck: Agent is waiting for approval or user input
   - waiting: Agent is waiting for external process (build, tests, etc.)
   - complete: Agent has finished and marked itself complete
   - confused: Agent is lost or asking questions it shouldn't
   - error: Agent encountered an error

2. **Action** (choose one):
   - approve: Send approval (Y, Enter, 2, etc.) to continue
   - send_keys: Send specific keystrokes (specify in 'keys' field)
   - intervene: Human intervention needed
   - none: Let agent continue working

3. **Keys** (if action=send_keys or approve):
   - Common: "Y", "C-m" (Enter), "2", "n", etc.
   - Use tmux key notation (C-m for Enter, C-c for Ctrl-C)

4. **Reasoning**: Brief explanation (1-2 sentences)

5. **Confidence**: 0-100 (how certain are you?)

Respond ONLY with valid JSON:
{
  "status": "working|stuck|waiting|complete|confused|error",
  "action": "approve|send_keys|intervene|none",
  "keys": "optional keys to send",
  "reasoning": "brief explanation",
  "confidence": 85
}"""

        try:
            self.total_requests += 1

            response = self.client.messages.create(
                model=self.config.model,
                max_tokens=500,
                system=system_prompt,
                messages=[{"role": "user", "content": prompt}]
            )

            # Calculate cost (Haiku pricing: $0.25/1M input, $1.25/1M output)
            input_tokens = response.usage.input_tokens
            output_tokens = response.usage.output_tokens
            cost = (input_tokens * 0.25 / 1_000_000) + (output_tokens * 1.25 / 1_000_000)
            self.total_cost += cost

            # Parse response
            result = json.loads(response.content[0].text)
            result['cost'] = cost
            result['tokens'] = {'input': input_tokens, 'output': output_tokens}

            logging.info(
                f"LLM Analysis for {worker_id}: "
                f"status={result['status']}, action={result['action']}, "
                f"cost=${cost:.4f}, confidence={result['confidence']}%"
            )

            return result

        except json.JSONDecodeError as e:
            logging.error(f"Failed to parse LLM response: {e}")
            logging.debug(f"Raw response: {response.content[0].text}")
            return {
                "status": "error",
                "action": "none",
                "reasoning": f"Failed to parse LLM response: {e}",
                "confidence": 0
            }
        except Exception as e:
            logging.error(f"LLM analysis failed: {e}")
            return {
                "status": "error",
                "action": "none",
                "reasoning": f"Analysis failed: {e}",
                "confidence": 0
            }


# ============================================================================
# ACTION EXECUTOR
# ============================================================================

class ActionExecutor:
    """Executes actions based on LLM recommendations"""

    def __init__(self, tmux: TmuxInterface, config: MonitorConfig, decisions_log: Path):
        self.tmux = tmux
        self.config = config
        self.decisions_log = decisions_log

    def execute(self, worker_id: str, window: int, analysis: Dict) -> bool:
        """Execute action from LLM analysis"""

        action = analysis.get('action', 'none')

        # Log decision
        self._log_decision(worker_id, analysis)

        if action == 'none':
            return True

        if action == 'intervene':
            logging.warning(
                f"🚨 Worker {worker_id} needs human intervention: "
                f"{analysis['reasoning']}"
            )
            return False

        # Auto-approve if enabled
        if not self.config.auto_approve:
            logging.info(
                f"⏸️  Auto-approve disabled, skipping action for {worker_id}: "
                f"{action}"
            )
            return False

        if action in ['approve', 'send_keys']:
            keys = analysis.get('keys', 'C-m')  # Default to Enter

            logging.info(
                f"⚡ Executing action for {worker_id}: "
                f"Sending '{keys}' - {analysis['reasoning']}"
            )

            success = self.tmux.send_keys(window, keys)

            if success:
                logging.info(f"✅ Action executed successfully for {worker_id}")
            else:
                logging.error(f"❌ Failed to execute action for {worker_id}")

            return success

        return False

    def _log_decision(self, worker_id: str, analysis: Dict):
        """Log decision to audit trail"""

        timestamp = datetime.now().isoformat()

        decision = {
            'timestamp': timestamp,
            'worker': worker_id,
            'status': analysis.get('status'),
            'action': analysis.get('action'),
            'keys': analysis.get('keys'),
            'reasoning': analysis.get('reasoning'),
            'confidence': analysis.get('confidence'),
            'cost': analysis.get('cost', 0),
            'tokens': analysis.get('tokens', {})
        }

        # Human-readable log
        with open(self.decisions_log, 'a') as f:
            f.write(
                f"[{timestamp}] {worker_id}: "
                f"status={decision['status']}, action={decision['action']}, "
                f"confidence={decision['confidence']}% - {decision['reasoning']}\n"
            )

        # Machine-readable JSON log
        json_log = self.decisions_log.parent / "llm-decisions.jsonl"
        with open(json_log, 'a') as f:
            f.write(json.dumps(decision) + '\n')


# ============================================================================
# FILE WATCHER
# ============================================================================

class LogFileEventHandler(FileSystemEventHandler):
    """Handles file system events for log files"""

    def __init__(self, monitor):
        self.monitor = monitor

    def on_modified(self, event):
        """Handle file modification events"""
        if event.is_directory:
            return

        # Check if it's a worker log or events.jsonl
        path = Path(event.src_path)

        if path.name == 'events.jsonl':
            self.monitor.on_events_update()
        elif path.name.endswith('.log') and path.name != 'orchestration.log':
            worker_id = path.stem
            self.monitor.on_worker_log_update(worker_id)


# ============================================================================
# MAIN MONITOR
# ============================================================================

class LLMMonitorDaemon:
    """Main LLM monitoring daemon"""

    def __init__(self, project_dir: Path):
        self.project_dir = project_dir
        self.config_file = project_dir / 'config.json'
        self.logs_dir = project_dir / 'logs'
        self.status_dir = project_dir / 'status'

        # Load configuration
        self.config = self._load_config()
        self.project_config = self._load_project_config()

        # Initialize components
        self.tmux = TmuxInterface(f"czarina-{self.project_config['project']['slug']}")
        self.analyzer = WorkerAnalyzer(self.config)
        self.executor = ActionExecutor(
            self.tmux,
            self.config,
            self.status_dir / 'llm-decisions.log'
        )

        # Worker tracking
        self.workers: Dict[str, WorkerState] = {}
        self._initialize_workers()

        # Setup logging
        self._setup_logging()

        logging.info("🤖 LLM Monitor Daemon initialized")
        logging.info(f"   Model: {self.config.model}")
        logging.info(f"   Workers: {len(self.workers)}")
        logging.info(f"   Auto-approve: {self.config.auto_approve}")

    def _load_config(self) -> MonitorConfig:
        """Load monitor configuration from config.json"""

        config = MonitorConfig()

        # Get API key from environment
        config.api_key = os.environ.get('ANTHROPIC_API_KEY')
        if not config.api_key:
            logging.warning("⚠️  ANTHROPIC_API_KEY not set, LLM monitoring disabled")
            config.enabled = False

        # Try to load from config.json
        if self.config_file.exists():
            try:
                with open(self.config_file) as f:
                    data = json.load(f)

                llm_config = data.get('llm_monitor', {})

                if 'enabled' in llm_config:
                    config.enabled = llm_config['enabled']
                if 'model' in llm_config:
                    config.model = llm_config['model']
                if 'check_interval' in llm_config:
                    config.check_interval = llm_config['check_interval']
                if 'auto_approve' in llm_config:
                    config.auto_approve = llm_config['auto_approve']

            except Exception as e:
                logging.warning(f"Failed to load LLM config: {e}")

        return config

    def _load_project_config(self) -> Dict:
        """Load project configuration"""
        with open(self.config_file) as f:
            return json.load(f)

    def _initialize_workers(self):
        """Initialize worker tracking from config"""
        workers_config = self.project_config.get('workers', [])

        for idx, worker in enumerate(workers_config):
            worker_id = worker['id']
            # Window numbering: 0=Czar, 1-9=Workers 1-9, 10+=mgmt session
            window_num = idx + 1  # Worker 1 is window 1, etc.
            self.workers[worker_id] = WorkerState(worker_id, window_num)

    def _setup_logging(self):
        """Setup logging configuration"""
        log_file = self.status_dir / 'llm-monitor.log'

        logging.basicConfig(
            level=logging.INFO,
            format='[%(asctime)s] [%(levelname)s] %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )

    def on_events_update(self):
        """Handle events.jsonl update"""
        # Read last event
        events_file = self.logs_dir / 'events.jsonl'
        if not events_file.exists():
            return

        try:
            with open(events_file) as f:
                lines = f.readlines()
                if lines:
                    last_event = json.loads(lines[-1])
                    worker_id = last_event.get('source') or last_event.get('worker')

                    if worker_id in self.workers:
                        self.workers[worker_id].update_activity()
                        logging.debug(f"Event for {worker_id}: {last_event.get('event')}")
        except Exception as e:
            logging.error(f"Failed to parse events.jsonl: {e}")

    def on_worker_log_update(self, worker_id: str):
        """Handle worker log update"""
        if worker_id in self.workers:
            self.workers[worker_id].update_activity()
            logging.debug(f"Log update for {worker_id}")

    def analyze_worker(self, worker_id: str):
        """Analyze a specific worker with LLM"""

        if not self.config.enabled:
            return

        worker = self.workers.get(worker_id)
        if not worker:
            return

        # Capture tmux output
        terminal_output = self.tmux.capture_pane(
            worker.window_num,
            self.config.max_context_lines
        )

        if not terminal_output:
            logging.warning(f"⚠️  No terminal output for {worker_id}")
            return

        # Get last event if available
        last_event = None
        events_file = self.logs_dir / 'events.jsonl'
        if events_file.exists():
            try:
                with open(events_file) as f:
                    for line in f:
                        event = json.loads(line)
                        if event.get('source') == worker_id or event.get('worker') == worker_id:
                            last_event = f"{event.get('event')}: {event.get('metadata', {})}"
            except:
                pass

        # Get worker prompt
        worker_prompt = None
        prompt_file = self.project_dir / 'workers' / f'{worker_id}.md'
        if prompt_file.exists():
            try:
                worker_prompt = prompt_file.read_text()[:1000]  # First 1000 chars
            except:
                pass

        # Analyze with LLM
        analysis = self.analyzer.analyze_worker(
            worker_id,
            terminal_output,
            last_event,
            worker_prompt
        )

        worker.last_analysis = analysis
        worker.status = analysis['status']

        # Execute action if needed
        if analysis['action'] != 'none':
            self.executor.execute(worker_id, worker.window_num, analysis)

        # Update stuck count
        if analysis['status'] in ['stuck', 'confused']:
            worker.consecutive_stuck_count += 1
            if worker.consecutive_stuck_count >= 3:
                logging.error(
                    f"🚨 Worker {worker_id} stuck {worker.consecutive_stuck_count} times in a row! "
                    "Human intervention likely needed."
                )
        else:
            worker.consecutive_stuck_count = 0

    def check_stale_workers(self):
        """Check for workers that haven't had recent activity"""

        for worker_id, worker in self.workers.items():
            if worker.is_stale(self.config.stale_threshold):
                if worker.status not in ['COMPLETE', 'STUCK']:
                    logging.info(f"🔍 Checking stale worker: {worker_id}")
                    self.analyze_worker(worker_id)

    def run(self):
        """Main daemon loop"""

        if not self.config.enabled:
            logging.error("❌ LLM monitoring is disabled (no API key or disabled in config)")
            return

        if not self.tmux.session_exists():
            logging.error(f"❌ Tmux session not found: {self.tmux.session_name}")
            logging.error("   Start the orchestration first with 'czarina launch'")
            return

        logging.info("🚀 Starting LLM monitor daemon...")
        logging.info(f"   Watching: {self.logs_dir}")
        logging.info(f"   Check interval: {self.config.check_interval}s")

        # Setup file watcher
        event_handler = LogFileEventHandler(self)
        observer = Observer()
        observer.schedule(event_handler, str(self.logs_dir), recursive=False)
        observer.start()

        try:
            last_check = time.time()

            while True:
                time.sleep(1)

                # Periodic stale worker check
                now = time.time()
                if now - last_check >= self.config.check_interval:
                    self.check_stale_workers()
                    last_check = now

                    # Log stats
                    logging.info(
                        f"📊 Stats: {self.analyzer.total_requests} requests, "
                        f"${self.analyzer.total_cost:.4f} total cost"
                    )

        except KeyboardInterrupt:
            logging.info("🛑 Stopping LLM monitor daemon...")
            observer.stop()
            observer.join()

            # Final stats
            logging.info(
                f"📊 Final stats: {self.analyzer.total_requests} requests, "
                f"${self.analyzer.total_cost:.4f} total cost"
            )


# ============================================================================
# ENTRY POINT
# ============================================================================

def main():
    """Main entry point"""

    # Get project directory
    if len(sys.argv) > 1:
        project_dir = Path(sys.argv[1])
    else:
        project_dir = Path('.czarina')

    if not project_dir.exists():
        print(f"❌ Project directory not found: {project_dir}")
        print("Usage: ./llm-monitor-daemon.py [project-dir]")
        sys.exit(1)

    # Create and run daemon
    daemon = LLMMonitorDaemon(project_dir)
    daemon.run()


if __name__ == '__main__':
    main()
