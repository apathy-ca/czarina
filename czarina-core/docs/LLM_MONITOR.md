# LLM Monitor Daemon

**Event-driven intelligent worker monitoring using Claude Haiku**

The LLM Monitor Daemon provides autonomous, intelligent monitoring of your workers using AI analysis instead of dumb pattern matching.

---

## 🎯 What It Does

Instead of blindly pattern-matching for "Y/n" prompts, the LLM Monitor:

1. **Watches for activity** via log file updates (event-driven)
2. **Scrapes tmux output** when workers update or become stale
3. **Analyzes with Claude Haiku** to understand worker state
4. **Takes intelligent action** based on AI recommendations
5. **Logs all decisions** to comprehensive audit trail

---

## 🚀 Quick Start

### 1. Install Dependencies

```bash
pip install -r czarina-core/llm-monitor-requirements.txt
```

### 2. Set API Key

```bash
export ANTHROPIC_API_KEY="your-api-key"
```

### 3. Enable in Config

Add to your `.czarina/config.json`:

```json
{
  "project": { ... },
  "workers": [ ... ],
  "llm_monitor": {
    "enabled": true,
    "model": "claude-3-5-haiku-20241022",
    "check_interval": 30,
    "auto_approve": true
  }
}
```

### 4. Launch

The LLM monitor starts automatically when you launch:

```bash
czarina launch
```

It runs in a tmux window in the management session called `llm-monitor`.

---

## ⚙️ Configuration

### Full Configuration Schema

```json
{
  "llm_monitor": {
    "enabled": true,           // Enable LLM monitoring (default: false)
    "model": "claude-3-5-haiku-20241022",  // Model to use
    "check_interval": 30,      // Seconds between stale worker checks (default: 30)
    "stale_threshold": 300,    // Seconds before worker is "stale" (default: 300)
    "max_context_lines": 100,  // Lines of tmux to analyze (default: 100)
    "auto_approve": true,      // Auto-approve based on LLM (default: true)
    "log_all_decisions": true  // Log all decisions (default: true)
  }
}
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `enabled` | `false` | Enable LLM monitoring (requires `ANTHROPIC_API_KEY`) |
| `model` | `claude-3-5-haiku-20241022` | Claude model to use (Haiku recommended for speed/cost) |
| `check_interval` | `30` | Seconds between periodic stale worker checks |
| `stale_threshold` | `300` | Seconds of inactivity before analyzing worker |
| `max_context_lines` | `100` | Lines of tmux output to send to LLM |
| `auto_approve` | `true` | Automatically execute LLM recommendations |
| `log_all_decisions` | `true` | Log all LLM analyses (including "none" actions) |

---

## 📊 How It Works

### Event-Driven Architecture

```
┌─────────────────┐
│ Log File Update │
│  (inotify)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Worker Activity │
│   Detected      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────┐
│ Scrape Tmux     │───▶│ Claude Haiku │
│ (last 100 lines)│    │   Analysis   │
└─────────────────┘    └──────┬───────┘
                              │
                              ▼
                       ┌──────────────┐
                       │  JSON Result │
                       │  {           │
                       │   status,    │
                       │   action,    │
                       │   keys,      │
                       │   reasoning  │
                       │  }           │
                       └──────┬───────┘
                              │
         ┌────────────────────┴────────────────┐
         │                                     │
         ▼                                     ▼
  ┌─────────────┐                      ┌─────────────┐
  │ Execute     │                      │ Log Decision│
  │ Action      │                      │ to Audit    │
  │ (send keys) │                      │ Trail       │
  └─────────────┘                      └─────────────┘
```

### Triggers

**Event-Driven (instant response):**
- `.czarina/logs/events.jsonl` updates
- `.czarina/logs/{worker-id}.log` updates

**Periodic (every 30s):**
- Check for stale workers (no activity in 5 minutes)
- Analyze stale workers even if no log updates

---

## 🤖 LLM Analysis

### What the LLM Sees

For each worker, the LLM receives:

1. **Worker ID**: Which worker is being analyzed
2. **Terminal Output**: Last 100 lines from tmux pane
3. **Last Event** (if available): Most recent logged event
4. **Worker Prompt** (if available): First 1000 chars of worker's instructions

### LLM Response Format

The LLM returns structured JSON:

```json
{
  "status": "stuck",
  "action": "approve",
  "keys": "Y",
  "reasoning": "Worker waiting for Y/n prompt to continue",
  "confidence": 95
}
```

**Status Values:**
- `working`: Agent actively coding/thinking
- `stuck`: Waiting for approval
- `waiting`: Waiting for external process (build, tests, etc.)
- `complete`: Finished and marked complete
- `confused`: Lost or asking inappropriate questions
- `error`: Encountered an error

**Action Values:**
- `approve`: Send approval (Y, Enter, etc.)
- `send_keys`: Send specific keystrokes
- `intervene`: Human intervention needed
- `none`: Let agent continue

---

## 📝 Logging and Audit Trail

### Human-Readable Log

`.czarina/status/llm-decisions.log`:

```
[2026-01-16T14:30:15] security-fixes: status=stuck, action=approve, confidence=95% - Worker waiting for Y/n prompt to continue
[2026-01-16T14:31:42] gateway-http: status=working, action=none, confidence=88% - Agent actively implementing HTTP transport
[2026-01-16T14:35:20] test-coverage: status=confused, action=intervene, confidence=75% - Agent asking questions about test framework
```

### Machine-Readable Log

`.czarina/status/llm-decisions.jsonl`:

```json
{"timestamp":"2026-01-16T14:30:15","worker":"security-fixes","status":"stuck","action":"approve","keys":"Y","reasoning":"Worker waiting for Y/n prompt","confidence":95,"cost":0.0023,"tokens":{"input":450,"output":85}}
{"timestamp":"2026-01-16T14:31:42","worker":"gateway-http","status":"working","action":"none","keys":null,"reasoning":"Agent actively implementing","confidence":88,"cost":0.0019,"tokens":{"input":380,"output":72}}
```

### Daemon Log

`.czarina/status/llm-monitor.log`:

```
[2026-01-16 14:30:15] [INFO] 🤖 LLM Monitor Daemon initialized
[2026-01-16 14:30:15] [INFO]    Model: claude-3-5-haiku-20241022
[2026-01-16 14:30:15] [INFO]    Workers: 10
[2026-01-16 14:30:15] [INFO]    Auto-approve: True
[2026-01-16 14:30:15] [INFO] 🚀 Starting LLM monitor daemon...
[2026-01-16 14:30:16] [INFO] LLM Analysis for security-fixes: status=stuck, action=approve, cost=$0.0023, confidence=95%
[2026-01-16 14:30:16] [INFO] ⚡ Executing action for security-fixes: Sending 'Y' - Worker waiting for Y/n prompt
```

---

## 💰 Cost

**Claude Haiku Pricing:**
- Input: $0.25 per 1M tokens
- Output: $1.25 per 1M tokens

**Typical Analysis:**
- ~500 input tokens (100 lines terminal + context)
- ~100 output tokens (JSON response)
- **Cost per analysis: ~$0.002** (0.2 cents)

**Example Project (10 workers, 8 hours):**
- ~20 analyses per worker (event-driven + periodic)
- 200 total analyses
- **Total cost: ~$0.40**

Way cheaper than your time manually monitoring!

---

## 🔍 Monitoring the Monitor

### Check Daemon Status

```bash
# Attach to management session
tmux attach -t czarina-{project-slug}-mgmt

# Switch to llm-monitor window
Ctrl+b w  # then select "llm-monitor"
```

### View Logs

```bash
# Live monitoring
tail -f .czarina/status/llm-monitor.log

# Decisions only
tail -f .czarina/status/llm-decisions.log

# JSON analysis
jq . .czarina/status/llm-decisions.jsonl | less
```

### Cost Tracking

The daemon logs cumulative costs:

```
[14:45:30] [INFO] 📊 Stats: 42 requests, $0.0876 total cost
```

---

## 🛠️ Troubleshooting

### LLM Monitor Not Starting

**Check:**
1. `ANTHROPIC_API_KEY` is set
2. `llm_monitor.enabled: true` in config.json
3. Dependencies installed: `pip install -r czarina-core/llm-monitor-requirements.txt`

**View errors:**
```bash
cat .czarina/status/llm-monitor.log
```

### Workers Not Being Monitored

**Check:**
1. Tmux session exists: `tmux ls | grep czarina`
2. Workers are in expected windows (1-9 for main session)
3. Daemon can capture panes: `tmux capture-pane -t session:1 -p`

### High Costs

**Reduce by:**
1. Increase `check_interval` (fewer periodic checks)
2. Increase `stale_threshold` (analyze less often)
3. Reduce `max_context_lines` (less context to LLM)

---

## 🚀 Advanced Usage

### Disable Auto-Approve (Dry Run Mode)

Test the LLM monitor without taking action:

```json
{
  "llm_monitor": {
    "enabled": true,
    "auto_approve": false  // Only log recommendations, don't execute
  }
}
```

### Custom Model

Use a different Claude model:

```json
{
  "llm_monitor": {
    "enabled": true,
    "model": "claude-3-7-sonnet-20250219"  // More capable but slower/pricier
  }
}
```

### Integration with Autonomous Czar

The LLM Monitor works alongside the existing daemons:

- **czar-daemon.sh**: Pattern-matching auto-approver (fast, dumb)
- **autonomous-czar-daemon.sh**: Phase completion detector
- **llm-monitor-daemon.py**: Intelligent worker analysis (new!)

All three run concurrently. The LLM monitor handles intelligent intervention while pattern-matching handles simple cases.

---

## 📚 See Also

- [Daemon System](DAEMON_SYSTEM.md) - Pattern-matching auto-approver
- [Phase Management](../PHASE_MANAGEMENT.md) - Multi-phase orchestration
- [Configuration](../CONFIGURATION.md) - Full config schema

---

**Built for Czarina v0.7.3+**
