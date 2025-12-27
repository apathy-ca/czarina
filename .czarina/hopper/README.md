# Project Hopper

This is the **project hopper** - the long-term backlog for enhancement ideas, feature requests, and discovered work.

## Purpose

The project hopper serves as an inbox for:
- Enhancement ideas discovered during dogfooding
- Feature requests from users
- Bug fixes that aren't urgent for the current phase
- Technical debt items
- Future improvements

## How It Works

### Adding Items

Humans can add items in two ways:

1. **Direct file creation:**
   ```bash
   vim .czarina/hopper/my-enhancement.md
   ```

2. **Via command:**
   ```bash
   czarina hopper add my-enhancement.md
   ```

### Item Lifecycle

1. **Project Hopper** (here) - Items land here first
2. **Phase Hopper** - Czar pulls items into current phase scope
3. **Worker Assignment** - Czar assigns items to idle workers
4. **Completion** - Items move to done when completed

### Enhancement File Format

Items should include metadata to help Czar make decisions:

```markdown
# Enhancement #XX: Title

**Priority:** Low | Medium | High
**Complexity:** Small | Medium | Large
**Tags:** future, major-feature, bugfix, ux
**Suggested Phase:** v0.x.0
**Estimate:** X days

## Description
[...]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

### Czar Monitoring

The Czar daemon monitors this directory every 15 minutes and:
- Assesses new items for inclusion in the current phase
- Auto-includes small, high-priority items if workers are idle
- Auto-defers large or future-tagged items
- Asks the human when uncertain

## Structure

```
.czarina/
├── hopper/                    # PROJECT HOPPER (you are here)
│   ├── README.md             # This file
│   └── *.md                  # Enhancement files
│
└── phases/
    └── phase-N-vX.Y.Z/
        └── hopper/           # PHASE HOPPER (active work)
            ├── todo/         # Ready to assign
            ├── in-progress/  # Assigned to workers
            └── done/         # Completed
```

## Commands

```bash
# List items in project hopper
czarina hopper list

# Pull item into current phase
czarina hopper pull <item> --to-phase current

# Defer item back to project hopper
czarina hopper defer <item>

# View Czar status and recommendations
czarina czar status
```
