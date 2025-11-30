# ARCHITECT: Agent Profile System Architect

## Role
systems_architect

## Skills
python, json, bash, system-design, configuration-management

## Timeline
Phase 2 (1-2 hours)

## Priority
high

## Responsibilities
- Design and implement agent profile system
- Create profile definitions for multiple agents
- Build profile loading mechanism
- Integrate profiles with embed command

## Deliverables

### 1. Agent Profile System

**Directory structure:**
```
agents/
├── README.md                 # How agent profiles work
├── profiles/
│   ├── claude-code.json      # Claude Code profile
│   ├── cursor.json           # Cursor profile
│   ├── copilot.json          # GitHub Copilot profile
│   ├── aider.json            # Aider profile
│   └── windsurf.json         # Windsurf profile
└── profile-loader.py         # Profile loading utility
```

### 2. Profile Schema

Each agent profile should define:
```json
{
  "id": "agent-id",
  "name": "Display Name",
  "type": "web|desktop|cli",
  "discovery": {
    "pattern": "How to tell the agent which worker",
    "instruction": "User instruction text"
  },
  "capabilities": {
    "file_reading": "native|limited",
    "git_support": "native|limited",
    "pr_creation": "native|cli|manual"
  },
  "launch": {
    "command": "Optional launch command",
    "args": ["arg1", "arg2"]
  },
  "documentation": {
    "getting_started": "How to use Czarina with this agent",
    "tips": ["Tip 1", "Tip 2"]
  }
}
```

### 3. Profile Integration

Modify `czarina-core/embed-orchestration.sh` to:
- Accept `--agent` parameter (default: claude-code)
- Load agent profile
- Generate agent-specific documentation
- Substitute agent-specific placeholders

### 4. Profile Loader Utility

Create `agents/profile-loader.py`:
```python
#!/usr/bin/env python3
"""
Agent Profile Loader
Loads and validates agent profiles for multi-agent support
"""

def load_profile(agent_id):
    """Load an agent profile by ID"""
    pass

def list_profiles():
    """List all available agent profiles"""
    pass

def validate_profile(profile):
    """Validate profile against schema"""
    pass
```

### 5. Documentation

Create `agents/README.md`:
- Explain agent profile system
- Show how to add new agents
- Document profile schema
- Examples of using profiles

## Instructions

You are the **Agent Profile System Architect** working on making Czarina multi-agent compatible.

**Your Mission:** Design and implement a clean, extensible agent profile system that makes it easy to support any AI coding assistant.

**Working directory:** `/home/jhenry/Source/GRID/claude-orchestrator`

**Reference documents:**
- `AGENT_AGNOSTIC_ANALYSIS.md` - Implementation plan
- Existing embed script: `czarina-core/embed-orchestration.sh`

**Design Principles:**
1. **Simple by default** - Claude Code should work without changes
2. **Extensible** - Easy to add new agents
3. **Self-documenting** - Profiles explain their own usage
4. **Validation** - Catch errors early

## Success Criteria

- [ ] Agent profile schema defined
- [ ] 5+ agent profiles created (Claude Code, Cursor, Copilot, Aider, Windsurf)
- [ ] Profile loader implemented and tested
- [ ] embed-orchestration.sh supports --agent parameter
- [ ] Documentation complete
- [ ] Backward compatible (no --agent = Claude Code)

## Dependencies
- Requires: REBRAND worker (for templates)

## Git Workflow

**Your assigned branch:** `feat/agent-profiles`

### Setup
```bash
cd /home/jhenry/Source/GRID/claude-orchestrator
git checkout main
git pull origin main
git checkout -b feat/agent-profiles
```

### Working
```bash
# Create agent profiles
mkdir -p agents/profiles
# ... create files ...

# Test profile loading
python3 agents/profile-loader.py list
python3 agents/profile-loader.py load claude-code

# Commit
git add agents/
git commit -m "feat(agents): implement agent profile system"

git push -u origin feat/agent-profiles
```

### Commit Message Convention
```
feat(agents): <description>

Examples:
feat(agents): create agent profile schema
feat(agents): add claude-code and cursor profiles
feat(agents): implement profile loader utility
feat(agents): integrate profiles with embed command
```

### When Complete
```bash
gh pr create --base main --head feat/agent-profiles \
  --title "feat: Add agent profile system for multi-agent support" \
  --body "$(cat <<'EOF'
## Summary
- Designed agent profile system with JSON schema
- Created profiles for 5+ popular AI coding assistants
- Implemented profile loader utility
- Integrated with embed command via --agent flag

## Changes
- New: agents/ directory with profile system
- Modified: czarina-core/embed-orchestration.sh (accepts --agent)
- Profiles: claude-code, cursor, copilot, aider, windsurf

## Usage
```bash
./czarina embed myproject --agent=cursor
./czarina embed myproject --agent=copilot
./czarina embed myproject  # defaults to claude-code
```

## Testing
- [ ] All profiles validate against schema
- [ ] Profile loader lists all profiles
- [ ] embed command accepts --agent parameter
- [ ] Generated docs use agent-specific language
- [ ] Backward compatible (default = claude-code)

🤖 Generated with Czarina Multi-Agent Orchestration
EOF
)"
```

## Implementation Guide

### Step 1: Define Schema (30 min)
Start with `agents/profiles/schema.json` - the blueprint for all profiles.

### Step 2: Create Profiles (30 min)
Create one profile at a time:
1. claude-code.json (reference implementation)
2. cursor.json
3. copilot.json
4. aider.json
5. windsurf.json

### Step 3: Profile Loader (30 min)
Build `agents/profile-loader.py`:
- Load JSON files
- Validate against schema
- Provide utility functions

### Step 4: Integration (30 min)
Modify `czarina-core/embed-orchestration.sh`:
```bash
# Add parameter
AGENT="${1:-claude-code}"

# Load profile
PROFILE=$(python3 agents/profile-loader.py load "$AGENT")

# Use profile data for doc generation
AGENT_NAME=$(echo "$PROFILE" | jq -r '.name')
# ... etc
```

### Step 5: Test & Document (30 min)
- Test each profile
- Write agents/README.md
- Create examples

## Profile Example: Cursor

```json
{
  "id": "cursor",
  "name": "Cursor",
  "type": "desktop",
  "discovery": {
    "pattern": "Reference worker file directly",
    "instruction": "In Cursor, open: czarina-{project}/workers/engineer1.md"
  },
  "capabilities": {
    "file_reading": "native",
    "git_support": "native",
    "pr_creation": "native"
  },
  "launch": {
    "command": "cursor",
    "args": ["--goto", "{worker_file}"]
  },
  "documentation": {
    "getting_started": "Cursor works identically to Claude Code. Just open the worker file in your Cursor workspace.",
    "tips": [
      "Use Cmd/Ctrl+P to quickly open worker files",
      "Cursor's git integration works seamlessly with Czarina branches",
      "You can have multiple workers open in split view"
    ]
  }
}
```

## Quick Start Checklist

- [ ] Create branch: `feat/agent-profiles`
- [ ] Design profile schema
- [ ] Create 5+ agent profiles
- [ ] Build profile loader utility
- [ ] Integrate with embed command
- [ ] Write documentation
- [ ] Test with different agents
- [ ] Commit and push
- [ ] Create PR

**Let's build a clean, extensible agent system!** 🏗️🤖
