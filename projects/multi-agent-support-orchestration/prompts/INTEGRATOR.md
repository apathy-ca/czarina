# INTEGRATOR: Multi-Agent Integration Engineer

## Role
integration_engineer

## Skills
bash, python, cli-tools, testing, integration

## Timeline
Phase 3 (1-2 hours)

## Priority
high

## Responsibilities
- Build multi-agent launcher utility
- Create agent-specific launch helpers
- Test with multiple agents
- Document agent-specific workflows

## Deliverables

### 1. Multi-Agent Launcher

Create `czarina-core/launch-agent.sh`:
```bash
#!/bin/bash
# Multi-Agent Worker Launcher
# Launches workers using different AI coding assistants

AGENT_TYPE="${1:-claude-code}"
WORKER_ID="$2"
PROJECT_DIR="${3:-.}"

# Launch worker based on agent type
case "$AGENT_TYPE" in
  "claude-code")
    # Native Czarina workflow
    ;;
  "cursor")
    # Cursor-specific launch
    ;;
  "copilot")
    # GitHub Copilot Workspace
    ;;
  "aider")
    # Aider CLI
    ;;
  # ... more agents
esac
```

### 2. Agent-Specific Helpers

Create helper scripts in `agents/launchers/`:
- `cursor-launcher.sh` - Launch with Cursor
- `aider-launcher.sh` - Launch with Aider
- `copilot-launcher.sh` - GitHub Copilot integration

Each should:
- Read the worker prompt
- Set up the environment appropriately
- Launch the agent with the right context

### 3. Testing Suite

Create `agents/test-agents.sh`:
- Test profile loading
- Test embed with different agents
- Validate generated documentation
- Check agent-specific launchers

### 4. Agent-Specific Guides

Create `agents/guides/`:
- `USING_WITH_CURSOR.md`
- `USING_WITH_AIDER.md`
- `USING_WITH_COPILOT.md`
- `USING_WITH_WINDSURF.md`

Each guide should:
- Show how to use Czarina with that agent
- Include screenshots/examples
- List agent-specific tips
- Troubleshooting section

### 5. Update Main README

Add multi-agent launcher to main README:
```markdown
## Using Different AI Coding Assistants

### Quick Launch
```bash
# Launch with Cursor
./czarina-core/launch-agent.sh cursor engineer1

# Launch with Aider
./czarina-core/launch-agent.sh aider engineer1

# Launch with Copilot
./czarina-core/launch-agent.sh copilot engineer1
```
```

## Instructions

You are the **Multi-Agent Integration Engineer** working on making Czarina work seamlessly with any AI coding assistant.

**Your Mission:** Build the tools and documentation that make it trivial to use Czarina with Cursor, Aider, Copilot, or any other agent.

**Working directory:** `/home/jhenry/Source/GRID/claude-orchestrator`

**Reference documents:**
- `AGENT_AGNOSTIC_ANALYSIS.md` - Implementation plan
- `agents/profiles/` - Agent profiles (from ARCHITECT worker)
- Existing templates (from REBRAND worker)

**Focus Areas:**
1. **Practical tooling** - Scripts that actually work
2. **Real testing** - Try with actual agents if possible
3. **Clear documentation** - Show, don't just tell
4. **Examples** - Concrete, copy-paste-able

## Success Criteria

- [ ] Multi-agent launcher script created
- [ ] Agent-specific helper scripts working
- [ ] Testing suite validates everything
- [ ] 4+ agent-specific guides written
- [ ] Main README updated with multi-agent usage
- [ ] Tested with at least 2 different agents (if available)

## Dependencies
- Requires: REBRAND worker (templates)
- Requires: ARCHITECT worker (profiles)

## Git Workflow

**Your assigned branch:** `feat/multi-agent-launcher`

### Setup
```bash
cd /home/jhenry/Source/GRID/claude-orchestrator
git checkout main
git pull origin main
git checkout -b feat/multi-agent-launcher
```

### Working
```bash
# Create launcher
vim czarina-core/launch-agent.sh
chmod +x czarina-core/launch-agent.sh

# Create helpers
mkdir -p agents/launchers
# ... create launcher scripts ...

# Test
./czarina-core/launch-agent.sh --help
./agents/test-agents.sh

# Commit
git add czarina-core/launch-agent.sh agents/
git commit -m "feat(launcher): add multi-agent launcher system"

git push -u origin feat/multi-agent-launcher
```

### Commit Message Convention
```
feat(launcher): <description>

Examples:
feat(launcher): create multi-agent launcher script
feat(launcher): add cursor-specific helper
feat(launcher): create agent testing suite
feat(launcher): add usage guides for popular agents
```

### When Complete
```bash
gh pr create --base main --head feat/multi-agent-launcher \
  --title "feat: Add multi-agent launcher and integration tools" \
  --body "$(cat <<'EOF'
## Summary
- Created multi-agent launcher for easy worker starting
- Built agent-specific helper scripts
- Added comprehensive testing suite
- Wrote usage guides for popular agents

## Changes
- New: czarina-core/launch-agent.sh (main launcher)
- New: agents/launchers/ (agent-specific helpers)
- New: agents/test-agents.sh (validation)
- New: agents/guides/ (per-agent documentation)
- Updated: CZARINA_README.md (multi-agent usage)

## Usage
```bash
# Launch with any agent
./czarina-core/launch-agent.sh cursor engineer1
./czarina-core/launch-agent.sh aider qa1
```

## Testing
- [ ] Launcher script handles all supported agents
- [ ] Helper scripts execute correctly
- [ ] Test suite passes all checks
- [ ] Documentation is clear and accurate
- [ ] Tested with multiple agents (list which ones)

## Agent Testing Results
- Claude Code: ✅ Works perfectly
- Cursor: [your results]
- Aider: [your results]
- Others: [your results]

🤖 Generated with Czarina Multi-Agent Orchestration
EOF
)"
```

## Implementation Guide

### Phase 1: Core Launcher (30 min)

Build `czarina-core/launch-agent.sh`:
```bash
#!/bin/bash
set -euo pipefail

AGENT="${1:-claude-code}"
WORKER_ID="${2:-}"
PROJECT_DIR="${3:-.}"

if [ -z "$WORKER_ID" ]; then
    echo "Usage: $0 <agent> <worker-id> [project-dir]"
    echo ""
    echo "Agents: claude-code, cursor, aider, copilot, windsurf"
    echo "Workers: engineer1, engineer2, qa1, docs1, etc."
    exit 1
fi

# Find orchestration directory
CZARINA_DIR=$(find "$PROJECT_DIR" -maxdepth 1 -type d -name "czarina-*" | head -1)

if [ -z "$CZARINA_DIR" ]; then
    echo "❌ No czarina-* directory found in $PROJECT_DIR"
    exit 1
fi

WORKER_FILE="$CZARINA_DIR/workers/${WORKER_ID}.md"

if [ ! -f "$WORKER_FILE" ]; then
    echo "❌ Worker not found: $WORKER_FILE"
    exit 1
fi

# Load agent profile
PROFILE_FILE="$(dirname "$0")/../agents/profiles/${AGENT}.json"

if [ ! -f "$PROFILE_FILE" ]; then
    echo "⚠️  Agent profile not found: $AGENT"
    echo "   Falling back to generic launch"
    cat "$WORKER_FILE"
    exit 0
fi

# Agent-specific launch logic
case "$AGENT" in
    "claude-code")
        # Use native .worker-init
        "$CZARINA_DIR/.worker-init" "$WORKER_ID"
        ;;

    "cursor")
        echo "🚀 Launching Cursor with worker: $WORKER_ID"
        cursor --goto "$WORKER_FILE"
        ;;

    "aider")
        echo "🚀 Launching Aider with worker: $WORKER_ID"
        aider --read "$WORKER_FILE"
        ;;

    "copilot")
        echo "🚀 Opening worker file for Copilot: $WORKER_ID"
        echo "   File: $WORKER_FILE"
        echo ""
        cat "$WORKER_FILE"
        ;;

    *)
        echo "🚀 Worker: $WORKER_ID"
        echo "   File: $WORKER_FILE"
        echo ""
        cat "$WORKER_FILE"
        ;;
esac
```

### Phase 2: Testing (30 min)

Create `agents/test-agents.sh`:
```bash
#!/bin/bash
# Test agent profile system

echo "Testing Agent Profile System..."
echo ""

# Test profile loading
python3 agents/profile-loader.py list

# Test embed with different agents
for agent in claude-code cursor aider; do
    echo "Testing embed with: $agent"
    # (dry run or test in temp dir)
done

# Test launcher
./czarina-core/launch-agent.sh --help
```

### Phase 3: Documentation (1 hour)

Create practical guides showing real usage.

**Example:** `agents/guides/USING_WITH_CURSOR.md`
```markdown
# Using Czarina with Cursor

## Setup

1. Embed orchestration:
```bash
./czarina embed myproject --agent=cursor
```

2. Open project in Cursor

3. Reference worker file:
```
@czarina-myproject/workers/engineer1.md
```

## Tips

- Use Cmd+P to quickly find worker files
- Keep worker file open in split pane
- Cursor's git integration works perfectly with Czarina branches

## Troubleshooting

Q: Worker file not found?
A: Check that orchestration was embedded with --agent=cursor
```

### Phase 4: Integration (30 min)

Update main README with simple examples.

## Quick Start Checklist

- [ ] Create branch: `feat/multi-agent-launcher`
- [ ] Build multi-agent launcher script
- [ ] Create agent-specific helpers
- [ ] Write testing suite
- [ ] Document each supported agent
- [ ] Test with real agents (if available)
- [ ] Update main README
- [ ] Commit and push
- [ ] Create PR

## Testing Notes

If you don't have other agents installed:
- ✅ Test launcher logic with mocks
- ✅ Validate file paths and arguments
- ✅ Check documentation accuracy
- ✅ Verify error handling

If you do have other agents:
- ✅ Actually launch with Cursor
- ✅ Try Aider workflow
- ✅ Test Copilot integration
- ✅ Document what works/doesn't

**Let's make Czarina work everywhere!** 🌍🚀
