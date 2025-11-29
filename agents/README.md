# Czarina Agent Profiles

Multi-agent support for Czarina orchestration system.

## Overview

Czarina's agent profile system makes it easy to use any AI coding assistant with your orchestration workflows. Each agent profile defines how that AI assistant discovers worker files, what capabilities it has, and how to best use it with Czarina.

## Quick Start

### List Available Agents

```bash
python3 agents/profile-loader.py list
```

### Embed Orchestration for Specific Agent

```bash
# Default (Claude Code)
./czarina-core/embed-orchestration.sh projects/myproject/config.sh

# For Cursor
./czarina-core/embed-orchestration.sh projects/myproject/config.sh --agent=cursor

# For Aider
./czarina-core/embed-orchestration.sh projects/myproject/config.sh --agent=aider
```

### View Agent Profile

```bash
# See full profile JSON
python3 agents/profile-loader.py load claude-code

# See human-readable summary
python3 agents/profile-loader.py summary cursor
```

## Supported Agents

### Claude Code
- **Type:** Desktop
- **Best for:** Full-featured orchestration with native file/git support
- **Usage:** Reference worker files with `@filepath`
- **Profile:** [claude-code.json](profiles/claude-code.json)

### Cursor
- **Type:** Desktop
- **Best for:** VS Code users who want AI pair programming
- **Usage:** Open worker files directly or use `@` references
- **Profile:** [cursor.json](profiles/cursor.json)

### GitHub Copilot
- **Type:** Hybrid (VS Code extension)
- **Best for:** Developers already using VS Code with Copilot
- **Usage:** Open worker file, ask Copilot Chat to read and follow instructions
- **Profile:** [copilot.json](profiles/copilot.json)

### Aider
- **Type:** CLI
- **Best for:** Terminal-focused developers, automated git workflows
- **Usage:** `aider --read czarina-project/workers/engineer1.md`
- **Profile:** [aider.json](profiles/aider.json)

### Windsurf
- **Type:** Desktop
- **Best for:** Autonomous multi-step task execution with Cascade mode
- **Usage:** Reference worker files with `@` or open directly
- **Profile:** [windsurf.json](profiles/windsurf.json)

## Agent Profile Schema

Each agent profile is a JSON file that defines:

### Required Fields

```json
{
  "id": "agent-id",              // Unique identifier (lowercase-hyphenated)
  "name": "Display Name",         // Human-readable name
  "type": "web|desktop|cli|hybrid", // Platform type
  "discovery": {
    "pattern": "...",             // How agent references files
    "instruction": "..."          // User-facing instruction
  },
  "capabilities": {
    "file_reading": "native|limited|manual",
    "git_support": "native|cli|limited|manual",
    "pr_creation": "native|cli|manual"
  }
}
```

### Optional Fields

```json
{
  "vendor": "Company Name",
  "website": "https://...",
  "launch": {
    "command": "executable",
    "args": ["--flag", "value"]
  },
  "documentation": {
    "getting_started": "...",
    "tips": ["tip1", "tip2"],
    "limitations": ["..."],
    "examples": [...]
  },
  "config": {
    "prompt_style": "markdown|plain|structured",
    "max_context_files": 10,
    "prefers_single_file_prompts": false
  },
  "metadata": {
    "version": "1.0.0",
    "last_updated": "2024-11-29",
    "tested_with": "agent-version",
    "compatibility": ">=1.0.0"
  }
}
```

See [profiles/schema.json](profiles/schema.json) for the complete JSON Schema.

## Adding New Agents

### 1. Create Profile JSON

Create a new file in `agents/profiles/` named `{agent-id}.json`:

```bash
cd agents/profiles
cp claude-code.json my-agent.json
# Edit my-agent.json with your agent's details
```

### 2. Validate Profile

```bash
python3 agents/profile-loader.py validate my-agent
```

### 3. Test Integration

```bash
# Create test orchestration
./czarina-core/embed-orchestration.sh test-project/config.sh --agent=my-agent

# Verify generated files reference your agent correctly
cat test-project-repo/WORKERS.md
```

### 4. Submit Profile

- Ensure profile validates against schema
- Add agent to "Supported Agents" section in this README
- Include usage examples in profile's `documentation` section
- Test with real orchestration workflow
- Submit PR with profile and updated documentation

## Profile Loader API

The `profile-loader.py` utility provides both CLI and Python API:

### CLI Usage

```bash
# List all profiles
python3 profile-loader.py list

# Load profile JSON
python3 profile-loader.py load <agent-id>

# Validate single profile
python3 profile-loader.py validate <agent-id>

# Validate all profiles
python3 profile-loader.py validate-all

# Show human-readable summary
python3 profile-loader.py summary <agent-id>
```

### Python API

```python
from profile_loader import AgentProfileLoader

loader = AgentProfileLoader()

# List available agents
agents = loader.list_profiles()

# Load and validate profile
profile = loader.load_and_validate('cursor')

# Get summary
summary = loader.get_profile_summary('cursor')
print(summary)
```

## How Agent Profiles Work

### 1. Embed Command Integration

When you run `embed-orchestration.sh` with `--agent=<id>`:

1. Script loads the agent profile using `profile-loader.py`
2. Extracts agent-specific values (name, discovery instruction, etc.)
3. Generates `config.json` with agent metadata
4. Customizes `WORKERS.md` with agent-specific instructions
5. Outputs agent-appropriate usage guidance

### 2. Worker Discovery

Each agent has a different "discovery pattern":

| Agent | Discovery Pattern | Example |
|-------|------------------|---------|
| Claude Code | @ file reference | `@czarina-project/workers/engineer1.md` |
| Cursor | Direct file path or @ | Open file or use `@filename` |
| Copilot | Manual with @workspace | `@workspace Read worker file...` |
| Aider | CLI argument | `aider --read workers/engineer1.md` |
| Windsurf | @ reference or direct | `@workers/engineer1.md` or open file |

### 3. Capability Awareness

Profiles declare capabilities so documentation can be tailored:

- **Native file_reading**: Agent automatically reads referenced files
- **Limited file_reading**: Requires explicit instruction to read
- **Native git_support**: Built-in git commands
- **CLI git_support**: Uses terminal git commands
- **Native pr_creation**: Can create PRs directly
- **CLI pr_creation**: Uses `gh` CLI for PRs

## Design Principles

### 1. Simple by Default
Claude Code works without any `--agent` flag. The default experience is unchanged.

### 2. Extensible
Adding a new agent only requires creating a JSON file. No code changes needed.

### 3. Self-Documenting
Profiles contain their own documentation. The `embed` command uses this to generate agent-specific usage instructions.

### 4. Validated
JSON Schema validation catches errors early. All profiles must validate before use.

### 5. Backward Compatible
Existing workflows continue working. Agent selection is opt-in via `--agent` flag.

## Examples

### Example 1: Cursor Workflow

```bash
# Embed with Cursor support
./czarina-core/embed-orchestration.sh projects/myapp/config.sh --agent=cursor

# In the target repo
cd myapp-repo
cat WORKERS.md  # Shows Cursor-specific instructions

# In Cursor IDE
# Open: czarina-myapp/workers/engineer1.md
# Cursor reads the file and you can discuss the tasks
```

### Example 2: Aider CLI Workflow

```bash
# Embed with Aider support
./czarina-core/embed-orchestration.sh projects/myapp/config.sh --agent=aider

# Launch Aider with worker context
cd myapp-repo
aider --read czarina-myapp/workers/engineer1.md

# In Aider
# > Implement the first task from the worker file
# Aider reads the file and starts working
```

### Example 3: Multi-Agent Team

```bash
# Different team members can use different agents!

# Team lead uses Claude Code
./czarina-core/embed-orchestration.sh projects/myapp/config.sh --agent=claude-code

# Frontend dev uses Cursor
./czarina-core/embed-orchestration.sh projects/myapp/config.sh --agent=cursor

# Backend dev uses Aider
./czarina-core/embed-orchestration.sh projects/myapp/config.sh --agent=aider

# All work on their assigned workers, same git workflow, same orchestration
```

## Validation

### Validate All Profiles

```bash
python3 agents/profile-loader.py validate-all
```

Expected output:
```
✅ aider
✅ claude-code
✅ copilot
✅ cursor
✅ windsurf

✅ All 5 profiles are valid
```

### Common Validation Errors

**Missing required field:**
```
ValidationError: 'name' is a required property
```
→ Add the missing field to your profile

**Invalid enum value:**
```
ValidationError: 'tablet' is not one of ['web', 'desktop', 'cli', 'hybrid']
```
→ Use only allowed enum values from schema

**Invalid ID format:**
```
ValidationError: 'MyAgent' does not match '^[a-z][a-z0-9-]*$'
```
→ Use lowercase-hyphenated format for IDs

## Troubleshooting

### Profile Not Found

```bash
❌ Invalid or unknown agent: my-agent

Available agents:
  • aider
  • claude-code
  • copilot
  • cursor
  • windsurf
```

→ Check agent ID spelling, ensure profile file exists in `agents/profiles/`

### Profile Loader Missing

```bash
❌ Agent profile loader not found: /path/to/profile-loader.py
```

→ Ensure you're running from Czarina root directory with `agents/` folder

### Python Module Error

```bash
ModuleNotFoundError: No module named 'jsonschema'
```

→ Install required Python package: `pip install jsonschema`

## Contributing

To contribute a new agent profile:

1. **Research the agent** - Understand how it works, its capabilities, limitations
2. **Create profile** - Use `claude-code.json` as template
3. **Validate** - Run `profile-loader.py validate your-agent`
4. **Test** - Create a test orchestration and verify it works
5. **Document** - Add to "Supported Agents" section, include usage examples
6. **Submit PR** - Include profile, validation output, and testing notes

## Future Enhancements

Potential future additions to the agent profile system:

- **Auto-detection**: Detect which agent the user has installed
- **Profile versioning**: Support multiple versions of agent profiles
- **Template customization**: Agent-specific worker prompt templates
- **Capability checks**: Warn if worker requires capabilities the agent lacks
- **Performance hints**: Agent-specific optimization suggestions
- **Integration tests**: Automated testing across all supported agents

## License

Same license as Czarina project (MIT).

## See Also

- [WORKER_SETUP_GUIDE.md](../WORKER_SETUP_GUIDE.md) - Worker setup and git workflow
- [czarina-core/README.md](../czarina-core/README.md) - Core Czarina documentation
- [profiles/schema.json](profiles/schema.json) - Complete JSON Schema definition
