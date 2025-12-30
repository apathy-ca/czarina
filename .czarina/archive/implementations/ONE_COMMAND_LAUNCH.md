# One-Command Launch

## Overview

The `czarina analyze --go` feature enables fully automated orchestration setup from implementation plans.

**Before:** 8 manual steps, 10+ minutes
**After:** 1 command, <60 seconds

## Quick Start

```bash
# Preview what would be created
czarina analyze IMPLEMENTATION_PLAN.md --dry-run

# Create orchestration automatically
czarina analyze IMPLEMENTATION_PLAN.md --go

# Launch workers
czarina launch
```

## How It Works

1. **Parse Plan:** Extracts project metadata and worker definitions from markdown
2. **Generate Config:** Creates `.czarina/config.json` with project structure
3. **Create Workers:** Generates worker identity files in `.czarina/workers/`
4. **Ready to Launch:** Everything configured, just run `czarina launch`

## Plan Format Requirements

Your implementation plan must follow this structure:

### Project Metadata

```markdown
# Project Name v1.0.0 Implementation Plan

**Version:** 1.0.0
**Objective:** Brief description of what this project does
```

### Worker Definitions

Workers can use either format:

**Format 1: Heading + Bold Fields (v0.7.1 style)**
```markdown
### Worker 1: `worker-id`
**Role:** Code
**Agent:** Claude Code
**Branch:** cz1/feat/worker-id
**Dependencies:** None

**Mission:** What this worker needs to accomplish

**First Action:** The very first thing the worker should do

**Tasks:**
1. First task
2. Second task
3. Third task

**Deliverable:** What will be produced
```

**Format 2: Heading + Bullet Points (v0.7.0 style)**
```markdown
#### Worker 5: `worker-id`
- **Role:** Code
- **Agent:** Claude Code
- **Branch:** feat/v1.0.0-worker-id
- **Dependencies:** other-worker-1, other-worker-2
- **Tasks:**
  - First task
  - Second task
- **Deliverable:** What will be produced
```

Both formats are supported and can be mixed in the same plan.

### Field Details

- **Worker ID:** Must be lowercase with dashes (e.g., `memory-core`, `config-schema`)
- **Role:** code, qa, documentation, etc.
- **Agent:** claude, aider, or other
- **Dependencies:** Comma-separated worker IDs, or "None"
- **Tasks:** Numbered list or bullet points
- **Deliverable/Deliverables:** Brief description of output

## Examples

### Dry Run
```bash
$ czarina analyze IMPLEMENTATION_PLAN_v0.7.1.md --dry-run

🔍 Czarina Project Analysis
============================================================

📄 Input Plan: IMPLEMENTATION_PLAN_v0.7.1.md

🤖 Automated orchestration setup mode
   (DRY RUN - no files will be written)

📖 Parsing plan file...
   ✅ Found project: Czarina
   ✅ Version: 0.7.1
   ✅ Workers: 5

📋 Orchestration structure:

   Project: Czarina v0.7.1
   Workers: 5
     - worker-onboarding-fix (code)
     - autonomous-czar-daemon (code)
     - one-command-launch (code)
     - integration-testing (qa)
     - documentation-and-release (documentation)

============================================================
DRY RUN COMPLETE - No files written
```

### Full Launch
```bash
$ czarina analyze IMPLEMENTATION_PLAN_v0.7.1.md --go

🔍 Czarina Project Analysis
============================================================

📄 Input Plan: IMPLEMENTATION_PLAN_v0.7.1.md

🤖 Automated orchestration setup mode

📖 Parsing plan file...
   ✅ Found project: Czarina
   ✅ Version: 0.7.1
   ✅ Workers: 5

📁 Creating .czarina directory structure...
   ✅ Created .czarina/
   ✅ Created .czarina/workers/

📝 Generating config.json...
   ✅ Written to .czarina/config.json

📝 Generating worker identities...
   ✅ Created worker-onboarding-fix.md
   ✅ Created autonomous-czar-daemon.md
   ✅ Created one-command-launch.md
   ✅ Created integration-testing.md
   ✅ Created documentation-and-release.md

============================================================
✅ Orchestration setup complete!

📋 Next step:
   Launch the orchestration:
      czarina launch

============================================================
```

## Implementation Details

### Parser Functions

- `parse_plan(plan_file)` - Main entry point, returns structured plan data
- `parse_plan_metadata(content)` - Extracts project name, version, description
- `parse_worker_from_section(section, num)` - Parses individual worker definitions
- `generate_config_from_plan(plan_data, root)` - Creates config.json structure
- `generate_worker_identity(worker, context)` - Creates worker markdown files

### Generated Files

**`.czarina/config.json`**
```json
{
  "project": {
    "name": "Project Name",
    "slug": "project_name",
    "version": "1.0.0",
    "phase": 1,
    "description": "Project description",
    "repository": "/path/to/repo",
    "orchestration_dir": ".czarina"
  },
  "orchestration": {
    "mode": "local",
    "auto_push_branches": false
  },
  "omnibus_branch": "cz1/release/v1.0.0",
  "workers": [
    {
      "id": "worker-id",
      "role": "code",
      "agent": "claude",
      "branch": "cz1/feat/worker-id",
      "description": "Brief description",
      "dependencies": []
    }
  ],
  "daemon": {
    "enabled": true,
    "auto_approve": ["read", "write", "commit"]
  }
}
```

**`.czarina/workers/worker-id.md`**
```markdown
# Worker Identity: worker-id

**Role:** Code
**Agent:** Claude
**Branch:** cz1/feat/worker-id
**Phase:** 1
**Dependencies:** None

## Mission

What this worker needs to accomplish

## 🚀 YOUR FIRST ACTION

The very first thing to do

## Objectives

1. First task
2. Second task
3. Third task

## Deliverables

Complete implementation of: Brief description

## Success Criteria

- [ ] All objectives completed
- [ ] Code committed to branch
- [ ] Tests passing (if applicable)
- [ ] Documentation updated
```

## Tips

1. **Start with --dry-run** to preview what will be created
2. **Use clear worker IDs** (lowercase, dashes, descriptive)
3. **Include First Action** to avoid workers getting stuck
4. **Specify dependencies** to enable proper sequencing
5. **Break down tasks** into clear, actionable items

## Troubleshooting

**No workers found:**
- Ensure workers use `### Worker N:` or `#### Worker N:` headers
- Worker IDs must be in backticks or immediately after the colon

**Missing fields:**
- Required: Worker ID, Role, Agent
- Optional: Mission, First Action, Tasks, Dependencies, Deliverable
- Parser handles both bold fields and bullet points

**Wrong dependencies:**
- Use comma-separated worker IDs
- Use "None" for no dependencies (not empty string)

## Comparison: Before vs After

### Before (Manual Process)
1. Read plan manually
2. Create `.czarina/` directory
3. Create `config.json` by hand
4. Create each worker markdown file
5. Ensure branch naming conventions
6. Verify dependencies
7. Test configuration
8. Launch workers

**Time:** 10+ minutes per orchestration

### After (Automated)
```bash
czarina analyze plan.md --go
czarina launch
```

**Time:** <60 seconds
