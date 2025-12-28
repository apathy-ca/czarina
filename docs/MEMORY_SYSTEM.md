# Czarina Memory System

**Version:** 0.7.0 (MVP)
**Status:** Implemented
**Design Doc:** `.czarina/hopper/enhancement-memory-architecture.md`

---

## Overview

The Czarina Memory System solves the "mayfly problem" - AI agents losing all context between sessions. It provides a 3-tier memory architecture that enables workers to remember past work, past mistakes, and accumulated project knowledge across sessions.

### Key Features

- **Persistent Memory**: Git-tracked markdown file for human-editable memories
- **Semantic Search**: Vector embeddings enable natural language queries
- **3-Tier Architecture**: Architectural core, project knowledge, and session context
- **Flexible Embedding**: Supports both OpenAI API and local models
- **CLI Integration**: Simple commands for managing memories

---

## Architecture

### Three Memory Tiers

#### 1. Architectural Core (Always Loaded)
**Purpose:** Essential project context loaded at every session start
**Size Target:** 2-4KB
**Contains:**
- Component dependencies and relationships
- Known couplings (explicit and implicit)
- Critical constraints and invariants
- Technology stack and key patterns

#### 2. Project Knowledge (Semantic Search)
**Purpose:** Searchable session history with learnings
**Access Pattern:** Query with task context, retrieve top 3-5 results
**Contains:**
- Session summaries (what was done, what was learned)
- Bug investigations and root causes
- Deployment issues and resolutions
- Decisions and their rationale
- "Scar tissue" - things that bit us

#### 3. Session Context (Ephemeral)
**Purpose:** Current session working state
**Lifecycle:** Created at start, discarded at end (after extraction)
**Contains:**
- Current phase and task
- Files touched this session
- Recent changes and effects
- Running notes for extraction

### File Structure

```
.czarina/
├── memories.md         # Human-readable, git-tracked (SOURCE OF TRUTH)
├── memories.index      # Vector embeddings (regenerable cache)
└── config.json         # Project configuration
```

### memories.md Format

The memory file follows a structured markdown format:

```markdown
# Project Memory: [Project Name]

---

## Architectural Core
[Always-loaded essential context]

---

## Project Knowledge

### Session: YYYY-MM-DD - [Description]
[Structured session notes]

---

## Patterns and Decisions

### [Pattern Name]
**Context:** Why this came up
**Decision:** What we chose
**Rationale:** Why
**Revisit if:** Conditions that would change this
```

---

## Installation

### Dependencies

Choose one embedding provider:

**Option 1: Local Embeddings (Free, Private)**
```bash
pip install sentence-transformers
```

**Option 2: OpenAI Embeddings (Paid, Higher Quality)**
```bash
pip install openai
export OPENAI_API_KEY=your-api-key
```

---

## Usage

### Initialize Memory System

Create the memories.md file:

```bash
czarina memory init
```

This creates `.czarina/memories.md` with template structure.

### Edit Architectural Core

Edit `.czarina/memories.md` to add essential project context:

```markdown
## Architectural Core

### Component Dependencies
- CLI (czarina) depends on czarina-core modules
- Workers communicate via git branches
- Daemon requires config.json

### Known Couplings
- Memory commands require .czarina directory
- Embedding providers need API keys or local models

### Critical Constraints
- All git operations must preserve branch history
- Worker isolation via git worktrees

### Technology Stack
- Python 3.8+ for core CLI
- Bash for orchestration scripts
- Git worktrees for worker isolation
```

### Build Search Index

After editing memories.md, rebuild the vector index:

```bash
czarina memory rebuild
```

This:
1. Parses memories.md into chunks
2. Generates embeddings for each chunk
3. Saves index to `.czarina/memories.index`

### Query Memories

Search for relevant context using natural language:

```bash
czarina memory query "how do workers communicate"
```

Optional: Customize number of results:

```bash
czarina memory query "debugging worker issues" --top-k 3
```

### Extract Session Learnings

At end of session, extract learnings to memory:

```bash
czarina memory extract
```

This prompts you to enter a session summary, then appends it to Project Knowledge section.

**Template:**
```markdown
### Session: 2025-12-28 - [Brief Description]

**What We Did:**
- Implemented feature X
- Fixed bug Y

**What Broke:**
- Tests failed due to Z

**Root Cause:**
- Missing dependency configuration

**Resolution:**
- Added dependency to config.json

**Learnings:**
- Always check dependency versions
- Integration tests catch configuration issues
```

### Show Architectural Core

Display the always-loaded architectural context:

```bash
czarina memory core
```

---

## CLI Reference

### `czarina memory init`

Initialize memory system for current project.

**Usage:**
```bash
czarina memory init [project-name]
```

**Effects:**
- Creates `.czarina/memories.md` with template structure
- Detects available embedding providers
- Displays next steps

### `czarina memory rebuild`

Rebuild vector index from memories.md.

**Usage:**
```bash
czarina memory rebuild
```

**When to use:**
- After manually editing memories.md
- After extracting new sessions
- When switching embedding providers

**Effects:**
- Parses memories.md into chunks
- Generates embeddings for all chunks
- Saves index to `.czarina/memories.index`

### `czarina memory query "<text>"`

Search memories for relevant context.

**Usage:**
```bash
czarina memory query "task description"
czarina memory query "debugging issue" --top-k 3
```

**Parameters:**
- `<text>`: Query string (natural language)
- `--top-k N`: Number of results (default: 5)

**Returns:**
- Architectural core (always included)
- Top N relevant chunks with similarity scores
- Formatted markdown output

### `czarina memory extract`

Extract session learnings to memories.md.

**Usage:**
```bash
czarina memory extract
```

**Interactive Process:**
1. Displays template
2. Reads multiline input (Ctrl+D to finish)
3. Appends to Project Knowledge section
4. Reminds to rebuild index

### `czarina memory core`

Display architectural core content.

**Usage:**
```bash
czarina memory core
```

**Returns:**
- Full architectural core section
- Always-loaded essential context

---

## Integration with Czarina

### Worker Integration

Workers can query memories at session start:

```bash
# In worker initialization
TASK="Implement user authentication"
czarina memory query "$TASK" > context.md
```

### Phase Integration

At phase boundaries:
- **Phase start:** Query memories relevant to phase objectives
- **Phase end:** Extract learnings, add to Project Knowledge
- **Cross-phase:** Architectural Core provides continuity

### Czar Coordination

Czar can monitor and query all worker memories:

```bash
# Check memories across project
czarina memory query "integration issues"

# Extract cross-worker learnings
czarina memory extract
```

---

## Best Practices

### Architectural Core

**Keep it tight:**
- Target: 2-4KB
- Only essential context
- Update as architecture evolves

**What to include:**
- Critical dependencies
- Known gotchas
- Must-know constraints
- Core patterns

**What NOT to include:**
- Detailed implementation notes
- Session-specific learnings (use Project Knowledge)
- Temporary workarounds

### Project Knowledge

**Good session notes:**
- Focus on learnings and insights
- Include failure context (what broke, why)
- Document root causes, not just symptoms
- Add "scar tissue" - things to avoid

**Bad session notes:**
- Detailed code changes (use git log)
- Obvious information
- No context or learnings
- Copy-paste of commits

### Memory Maintenance

**Regular cleanup:**
- Archive old sessions (move to separate file)
- Promote important learnings to Architectural Core
- Mark outdated entries as superseded

**Index regeneration:**
- Always rebuild after manual edits
- Index is disposable cache
- Markdown is source of truth

---

## Troubleshooting

### "memories.md not found"

**Problem:** Memory system not initialized

**Solution:**
```bash
czarina memory init
```

### "OPENAI_API_KEY not found"

**Problem:** OpenAI embeddings selected but no API key

**Solutions:**
1. Set API key: `export OPENAI_API_KEY=your-key`
2. Use local: `pip install sentence-transformers`

### "sentence-transformers not installed"

**Problem:** Local embeddings selected but package missing

**Solution:**
```bash
pip install sentence-transformers
```

### "Index out of date"

**Problem:** memories.md edited but index not rebuilt

**Solution:**
```bash
czarina memory rebuild
```

### "No relevant memories found"

**Problem:** Query returns no results

**Possible causes:**
1. Index not built: Run `czarina memory rebuild`
2. Empty memories.md: Add content and rebuild
3. Poor query match: Try different keywords
4. Similarity threshold too high: (Internal setting)

---

## Technical Details

### Embedding Models

**OpenAI (text-embedding-3-small):**
- API-based, requires key
- High quality embeddings
- Cost: ~$0.02 per 1M tokens
- Dimension: 1536

**Local (all-MiniLM-L6-v2):**
- Runs locally, no API key
- Good quality embeddings
- Free, private
- Dimension: 384

### Vector Search

**Algorithm:** Cosine similarity
**Threshold:** 0.7 (configurable in code)
**Ranking:** Top-k by similarity score

### Index Format

JSON file with structure:
```json
{
  "chunks": [
    {
      "id": "session-1",
      "title": "Session: 2025-12-28 - Description",
      "text": "[full chunk text]",
      "type": "session",
      "embedding": [0.023, -0.089, ...]
    }
  ],
  "metadata": {
    "embedding_model": "local",
    "chunk_count": 42,
    "last_indexed": "2025-12-28T14:30:00Z",
    "file_hash": "abc123..."
  }
}
```

### Performance

**Session start:** < 2 seconds (including search)
**Index rebuild:** < 10 seconds for 100 sessions
**Search accuracy:** 70%+ relevant in top 5

---

## Roadmap

### MVP (v0.7.0) ✅
- [x] memories.md format
- [x] Basic embedding (OpenAI + local)
- [x] JSON vector storage
- [x] Semantic search
- [x] CLI commands
- [x] Documentation

### Future Enhancements
- [ ] Automatic session extraction (prompt at end)
- [ ] Cross-project memory patterns
- [ ] Confidence decay (old memories weighted lower)
- [ ] Contradiction detection
- [ ] Attention tracking (which memories get used)
- [ ] Multi-modal memory (images, diagrams)

---

## Examples

See `.czarina/memories.md` for full example after initialization.

### Example Query Session

```bash
$ czarina memory query "worker communication patterns"

🔍 Searching memories for: "worker communication patterns"

======================================================================
### Architectural Core
*Always loaded*

## Architectural Core

### Component Dependencies
- Workers communicate via git branches
- Czar monitors worker status files
- Daemon provides autonomous operation

### Known Couplings
- Worker isolation requires git worktrees
- Status updates via .czarina/status/*.json

### Session: 2025-12-20 - Worker Communication Debug
*Relevance: 0.85*

**What We Did:**
- Debugged worker-to-worker communication
- Found issue with status file timing

**Root Cause:**
- Workers write status before git push
- Race condition on status reads

**Resolution:**
- Added status file locking
- Implemented retry logic

**Learnings:**
- Status files need atomic writes
- Git push timing matters for coordination
======================================================================

Found 2 relevant memories
```

---

## Contributing

Memory system enhancements welcome! See:
- Design doc: `.czarina/hopper/enhancement-memory-architecture.md`
- Implementation: `czarina-core/memory.py`
- Tests: `tests/test-memory-system.sh`

---

## License

Same as Czarina project (see LICENSE file)

---

**Questions?** Open an issue in the Czarina repository.
