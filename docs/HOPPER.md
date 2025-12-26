# Czarina Hopper System

The hopper system provides flexible work management within phase boundaries, enabling responsive handling of discovered work while maintaining structured phase planning.

## Overview

Czarina uses a **two-level hopper system**:

1. **Project Hopper** (`.czarina/hopper/`) - Long-term backlog
2. **Phase Hopper** (`.czarina/phases/phase-N/hopper/`) - Current phase scope

This separation allows you to:
- Capture enhancement ideas as they emerge
- Maintain a backlog without scope creep
- Dynamically assign work to idle workers
- Keep phases flexible within boundaries

## Architecture

```
.czarina/
├── hopper/                           # PROJECT HOPPER
│   ├── README.md                     # Documentation
│   ├── enhancement-13.md             # Enhancement files
│   ├── enhancement-14.md
│   └── feature-request-xyz.md
│
└── phases/
    └── phase-2-v0.6.0/
        ├── hopper/                   # PHASE HOPPER
        │   ├── todo/                 # Ready to assign
        │   ├── in-progress/          # Being worked on
        │   └── done/                 # Completed
        └── planned/                  # Original phase plan
            ├── worker-a.md
            └── worker-b.md
```

## Project Hopper

The project hopper serves as an inbox for all enhancement ideas, regardless of when they'll be implemented.

### Adding Items

**Method 1: Direct file creation**
```bash
vim .czarina/hopper/my-enhancement.md
```

**Method 2: Using the CLI**
```bash
czarina hopper add my-enhancement.md
```

This creates a template file with the recommended structure.

### Enhancement File Format

Enhancement files should include metadata to help with prioritization:

```markdown
# Enhancement #XX: Title

**Priority:** Low | Medium | High
**Complexity:** Small | Medium | Large
**Tags:** future, major-feature, bugfix, ux
**Suggested Phase:** v0.x.0
**Estimate:** X days

## Description
[What is this enhancement?]

## Problem
[What problem does it solve?]

## Solution
[How should it be implemented?]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Notes
[Additional context]
```

### Viewing the Project Hopper

```bash
# List all items in project hopper
czarina hopper list

# Same as above (project is default)
czarina hopper list project
```

Output shows:
- File names
- Titles
- Priority and complexity
- Tags (if present)

## Phase Hopper

The phase hopper contains work that's been pulled into the current phase scope.

### Structure

Each phase hopper has three subdirectories:

- **`todo/`** - Enhancement files ready to be assigned to workers
- **`in-progress/`** - Files currently being worked on
- **`done/`** - Completed enhancement files

### Viewing the Phase Hopper

```bash
# List items in current phase hopper
czarina hopper list phase
```

Shows counts and items in each subdirectory (todo, in-progress, done).

## Workflow

### Basic Flow

1. **Discovery**: Human discovers enhancement during dogfooding
2. **Capture**: Add to project hopper with `czarina hopper add`
3. **Assessment**: Czar monitors and evaluates for phase inclusion (v0.6.0+)
4. **Pull**: Item moved to phase hopper todo/ (v0.6.0+)
5. **Assignment**: Czar assigns to idle worker (v0.6.0+)
6. **Completion**: Worker moves to done/

### Current Status (v0.5.1)

**Available now:**
- ✅ Project hopper directory structure
- ✅ `czarina hopper add` - Add items to project hopper
- ✅ `czarina hopper list` - View project hopper items
- ✅ `czarina hopper list phase` - View phase hopper items

**Coming in v0.6.0:**
- 🔜 `czarina hopper pull` - Pull items from project to phase
- 🔜 `czarina hopper defer` - Move items back to project hopper
- 🔜 `czarina hopper assign` - Assign items to workers
- 🔜 Czar monitoring and automatic assessment
- 🔜 Phase integration (auto-pull at phase start)

## Commands Reference

### `hopper add`

Add an enhancement file to the project hopper.

```bash
czarina hopper add <filename.md>
```

**Example:**
```bash
czarina hopper add enhancement-15.md
```

Creates `.czarina/hopper/enhancement-15.md` with a template structure.

### `hopper list`

List items in the hopper(s).

```bash
# List project hopper (default)
czarina hopper list
czarina hopper list project

# List phase hopper
czarina hopper list phase
```

**Project hopper output:**
```
═══════════════════════════════════════════════════════════
📬 Project Hopper - Long-term Backlog
═══════════════════════════════════════════════════════════
Location: /path/to/.czarina/hopper

[1] enhancement-14.md
    Title: Two-Level Hopper System
    Priority: High | Complexity: Medium
    Tags: v0.6.0, workflow

Total: 1 item(s)
═══════════════════════════════════════════════════════════
```

**Phase hopper output:**
```
═══════════════════════════════════════════════════════════
📋 Phase Hopper - Current Phase Scope
═══════════════════════════════════════════════════════════
Location: /path/to/.czarina/phases/phase-2-v0.6.0/hopper

📝 TODO (2):
   ├─ enhancement-10.md
   │  Fix dashboard refresh
   └─ enhancement-11.md
      Add worker status icons

🔄 IN PROGRESS (1):
   ├─ enhancement-12.md
      Proactive coordination

✅ DONE (3)

═══════════════════════════════════════════════════════════
```

### Future Commands (v0.6.0+)

```bash
# Pull item into current phase
czarina hopper pull <file> --to-phase current

# Defer item back to project hopper
czarina hopper defer <file>

# Assign item to worker
czarina hopper assign <worker> <file>
```

## Use Cases

### 1. Dogfooding Discovery

You're testing czarina v0.5.1 and discover a bug:

```bash
# Capture the bug immediately
czarina hopper add bug-dashboard-refresh.md

# Edit with details
vim .czarina/hopper/bug-dashboard-refresh.md
```

The bug is now captured in the backlog. In v0.6.0+, the Czar will assess it for inclusion in the current phase.

### 2. Feature Requests

A user suggests a new feature:

```bash
czarina hopper add feature-dark-mode.md
```

Edit the file to add:
- Priority: Medium
- Complexity: Medium
- Suggested Phase: v0.7.0
- Tags: ux, enhancement

The Czar will see the "v0.7.0" tag and auto-defer it to the future.

### 3. Worker Finishes Early

In v0.6.0+, when a worker completes their planned tasks:

1. Czar detects idle worker
2. Checks phase hopper `todo/`
3. Assigns highest-priority item
4. Worker continues with emergent work

This maximizes worker utilization within the phase.

### 4. Phase Planning

At the start of a new phase (v0.6.0+):

```bash
czarina phase start v0.7.0
```

Czar prompts:
```
📬 Project hopper has 5 items. Pull any into v0.7.0?

High Priority:
  [1] bug-dashboard-refresh.md (Small)
  [2] enhancement-worker-status.md (Small)

Medium Priority:
  [3] feature-dark-mode.md (Medium)
  ...

Pull items [1,2] or [a]ll or [s]kip?
```

## Integration with Phases

### Phase Start (v0.6.0+)

When starting a phase:
1. Phase hopper directory is created
2. Czar reviews project hopper
3. High-priority, small items are suggested for inclusion
4. Human approves/rejects
5. Approved items moved to phase hopper `todo/`

### During Phase (v0.6.0+)

Czar monitors every 15 minutes:
- **Project hopper**: New items → assess for phase inclusion
- **Phase hopper**: Available work → assign to idle workers
- **Worker status**: Detect idle workers

### Phase Close

When closing a phase:
1. Completed items (in `done/`) archived with phase
2. Unfinished items (in `todo/` or `in-progress/`) moved back to project hopper
3. Closeout report shows planned vs emergent work completed

## Best Practices

### 1. Capture Everything

Don't filter ideas at capture time. Add them to the project hopper immediately:

```bash
czarina hopper add rough-idea.md
```

The Czar and phase planning process will handle prioritization.

### 2. Use Metadata

Always fill in Priority, Complexity, and Tags:

```markdown
**Priority:** High
**Complexity:** Small
**Tags:** bugfix, urgent
```

This helps the Czar make informed decisions.

### 3. Be Specific with Tags

Use tags to indicate:
- **Scope**: `future`, `v0.7.0`, `v1.0`
- **Type**: `bugfix`, `enhancement`, `feature`, `ux`, `refactor`
- **Effort**: `quick-win`, `major-feature`, `breaking-change`

### 4. Estimate Conservatively

If you mark something as "Small" complexity, make sure it really is small:
- **Small**: 1-4 hours, single file, no breaking changes
- **Medium**: 1-2 days, multiple files, some design needed
- **Large**: 3+ days, architectural changes, multiple components

### 5. Review Regularly

Periodically review the project hopper:

```bash
czarina hopper list
```

Update priorities and close obsolete items.

## Comparison to Traditional Backlogs

| Traditional Backlog | Czarina Hopper |
|---------------------|----------------|
| Single list | Two levels (project + phase) |
| Manual prioritization | Czar-assisted assessment |
| Static planning | Dynamic assignment |
| Scope creep risk | Phase boundaries enforced |
| Idle workers wait | Idle workers pull work |
| Rigid phases | Flexible within structure |

## Technical Details

### File Locations

- **Script**: `czarina-core/hopper.sh`
- **Integration**: `czarina` (main CLI, lines 878-893, 1530-1533)
- **Documentation**: `.czarina/hopper/README.md` (in-project)

### Dependencies

- Bash 4.0+ (for associative arrays in future versions)
- Standard Unix tools: `grep`, `sed`, `find`, `sort`

### Exit Codes

- `0` - Success
- `1` - Error (not in czarina project, file exists, etc.)

### Error Handling

The hopper commands gracefully handle:
- Not in a czarina project → Clear error message
- No phase active → Show friendly message
- File already exists → Prevent overwrite
- Empty hoppers → Show helpful next steps

## Future Enhancements

### v0.6.0 (Planned)

- Czar monitoring loop
- Auto-assessment logic (auto-include, auto-defer, ask-human)
- Pull/defer/assign commands
- Phase integration (start/close hooks)
- Worker idle detection

### v0.7.0+ (Ideas)

- Priority queue sorting
- Worker claiming (pull model)
- Hopper statistics and metrics
- Web UI for hopper management
- GitHub issue integration
- Automated tagging based on content

## Troubleshooting

### "Not in a czarina project"

The hopper commands require a `.czarina/` directory.

**Solution:** Run from within a czarina project, or initialize one:
```bash
czarina init
```

### "No active phase hopper found"

Phase hoppers are created when phases start. For now, they must be created manually.

**Solution:** Create the structure manually:
```bash
mkdir -p .czarina/phases/phase-1-v0.6.0/hopper/{todo,in-progress,done}
```

Or wait for v0.6.0 phase management integration.

### File already exists

The `hopper add` command won't overwrite existing files.

**Solution:** Choose a different filename, or edit the existing file directly:
```bash
vim .czarina/hopper/enhancement-15.md
```

## Examples

### Complete Workflow Example

```bash
# 1. Discover enhancement during dogfooding
czarina hopper add enhancement-dashboard-icons.md

# 2. Edit to add details
vim .czarina/hopper/enhancement-dashboard-icons.md

# 3. Review backlog
czarina hopper list

# 4. (v0.6.0+) Czar auto-assesses and pulls into phase
# [Czar sees: High priority + Small + Worker idle → Auto-include]

# 5. (v0.6.0+) Czar assigns to idle worker
czarina hopper assign worker-2 enhancement-dashboard-icons.md

# 6. Worker completes and commits
# Worker moves file to done/

# 7. Phase close
czarina phase close
# Unfinished items automatically deferred to project hopper
```

## See Also

- [Enhancement #14: Two-Level Hopper System](/tmp/enhancement_14.md) - Full specification
- [IMPROVEMENT_PLAN B3: Intelligent Work Queue](#) - Priority queue design
- [Czar Coordination](CZAR_COORDINATION.md) - Czar monitoring (v0.6.0+)
- [Phase Management](PHASES.md) - Phase lifecycle (v0.6.0+)

---

**Status:** Basic structure implemented (v0.5.1)
**Next:** Czar integration and phase management (v0.6.0)
