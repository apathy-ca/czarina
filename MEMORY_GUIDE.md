# Memory System Guide

**Version:** 0.7.0
**Status:** Production Ready
**Last Updated:** 2025-12-28

## Overview

Czarina v0.7.0 introduces a **3-tier persistent memory system** that enables workers to learn from past sessions, remember architectural decisions, and avoid repeating mistakes. This transforms workers from amnesiacs (forgetting everything between sessions) to continuous learners with institutional knowledge.

### The Mayfly Problem

**Before v0.7.0:** AI workers start each session fresh
- No memory of past mistakes
- Re-learn the same lessons repeatedly
- Forget debugging discoveries
- Lose architectural context between sessions

**After v0.7.0:** Workers have persistent memory
- Remember what worked and what didn't
- Build on previous sessions' knowledge
- Recall past debugging insights
- Maintain architectural understanding over time

---

## Memory Architecture

Czarina uses a **3-tier memory system** optimized for practicality and effectiveness:

### Tier 1: Architectural Core
**Purpose:** Essential context loaded in every session
**Storage:** Top section of `.czarina/memories.md`
**Size:** 2-4KB (small enough to always include)
**Updates:** Manual curation by humans or workers

**Contains:**
- Component relationships and dependencies
- Known couplings (explicit and implicit)
- Critical constraints and invariants
- Technology stack patterns
- "Laws of the codebase" that must never be violated

**Example:**
```markdown
## Architectural Core

### Component Dependencies
- AuthContext must mount before any component making authenticated API calls
- SessionProvider wraps Router wraps App - order matters
- Database migrations run before app startup (enforced in docker-compose)

### Known Couplings
- UI re-renders can race with token refresh → intermittent auth failures
- Changing backend port requires updating 3 places: .env, docker-compose, nginx.conf
- Frontend build embeds API URL at build time (not runtime configurable)

### Critical Constraints
- All API calls MUST use /api prefix for reverse proxy routing
- Database connection pool size: 10-50 (DB_POOL_SIZE env var)
- Worker processes: Must be odd number for quorum (3, 5, or 7)
```

### Tier 2: Project Knowledge
**Purpose:** Searchable history of sessions and learnings
**Storage:** Session entries in `.czarina/memories.md`
**Access:** Semantic search based on current task
**Updates:** Automatic extraction at session end

**Contains:**
- Session summaries (what was done, what was learned)
- Bug investigations and root causes
- Deployment issues and resolutions
- Architectural decisions and rationale
- "Scar tissue" - painful lessons learned

**Example:**
```markdown
## Session: 2025-12-15 - Database Migration Failure

### What We Did
- Attempted to add full-text search indexes to articles table
- Migration ran successfully in dev, failed in staging

### What Broke
- PostgreSQL raised: "text search configuration 'english' does not exist"
- Migration rolled back, app wouldn't start

### Root Cause
- Dev environment had postgresql-contrib installed
- Staging didn't have the extension package
- Migration assumed text search was available

### Resolution
1. Updated docker-compose to install postgresql-contrib
2. Added migration step: CREATE EXTENSION IF NOT EXISTS pg_trgm
3. Documented extension dependencies in README

### Remember For Next Time
- ALWAYS check extension availability before using PostgreSQL features
- Dev/staging environment parity checklist needed
- Test migrations on clean database, not just existing dev DB
```

### Tier 3: Session Context
**Purpose:** Current session working state (ephemeral)
**Storage:** In-memory only (not persisted)
**Lifecycle:** Created at start, extracted to Tier 2 at end, then discarded

**Contains:**
- Current task and objectives
- Files modified this session
- Recent changes and their effects
- Open questions or uncertainties
- Working notes for end-of-session extraction

---

## File Structure

```
project/
├── .czarina/
│   ├── memories.md          # Human-readable memory (version controlled)
│   ├── memories.index       # Vector embeddings (regenerable, .gitignored)
│   └── config.json          # Memory configuration
```

### memories.md Format

```markdown
# Project Memory: My Awesome Project

## Architectural Core
[Essential, always-loaded context - keep tight, ~2-4KB]

### Component Dependencies
...

### Known Couplings
...

### Critical Constraints
...

---

## Project Knowledge

### Session: 2025-12-20 - Authentication Bug Fix
...

### Session: 2025-12-18 - API Performance Optimization
...

---

## Patterns and Decisions

### Decision: REST vs GraphQL
- **Context**: Frontend team requested GraphQL for flexibility
- **Decision**: Stuck with REST for now
- **Rationale**: Team inexperienced with GraphQL, REST working well
- **Revisit if**: Frontend complexity grows, need for flexible querying increases

### Pattern: Error Response Format
- **Format**: `{ "error": { "code": "...", "message": "...", "details": {} } }`
- **Why**: Consistent across all endpoints, easy to parse on frontend
- **Exceptions**: None - all errors use this format
```

---

## Using the Memory System

### 1. Initialize Memory

When setting up a new project:

```bash
cd my-project
czarina init --with-memory

# Or manually:
czarina memory init
```

This creates `.czarina/memories.md` with a template structure.

### 2. Populate Architectural Core

Edit `.czarina/memories.md` and fill in the Architectural Core section:

```markdown
## Architectural Core

### Component Dependencies
- [List critical dependency relationships]

### Known Couplings
- [Document implicit couplings that bite you]

### Critical Constraints
- [Laws of the codebase that must not be violated]
```

**Tip:** Keep this section small (2-4KB). Only include what's **truly essential**.

### 3. Launch Workers with Memory

Memory-enabled workers receive:
- Full Architectural Core (always loaded)
- Top 3-5 relevant past sessions (via semantic search)

**Automatic (recommended):**
```json
{
  "memory": {
    "enabled": true
  },
  "workers": [
    {
      "id": "backend",
      "role": "code"
      // Memory auto-enabled for all workers
    }
  ]
}
```

**Per-worker control:**
```json
{
  "memory": { "enabled": true },
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "memory": {
        "enabled": true,
        "use_core": true,
        "search_on_start": true
      }
    }
  ]
}
```

### 4. Extract Session Learnings

At the end of a session, extract what was learned:

```bash
czarina memory extract
```

This prompts you (or the worker) to summarize:
- What was accomplished
- What broke and why
- What was learned
- What should be remembered

The summary is appended to `.czarina/memories.md` as a new session entry.

### 5. Query Memories

Search memory for relevant past experience:

```bash
# Query for specific topic
czarina memory query "database connection issues"

# Returns top 5 relevant session excerpts
```

Workers can also query memory during their session when they encounter problems.

### 6. Rebuild Index

If you manually edit `memories.md`, rebuild the search index:

```bash
czarina memory rebuild
```

The index (`.czarina/memories.index`) is regenerable - `memories.md` is the source of truth.

---

## Configuration Reference

### Global Memory Config

```json
{
  "memory": {
    "enabled": true,                          // Enable memory system
    "embedding_provider": "openai",           // "openai" or "local"
    "embedding_model": "text-embedding-3-small",  // OpenAI model
    "similarity_threshold": 0.7,              // Min similarity for search results
    "max_results": 5,                         // Top N results to return
    "auto_extract": true,                     // Prompt for extraction at session end
    "index_path": ".czarina/memories.index"   // Vector index location
  }
}
```

### Per-Worker Memory Config

```json
{
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "memory": {
        "enabled": true,              // Enable for this worker
        "use_core": true,             // Load Architectural Core
        "search_on_start": true,      // Search for relevant memories at launch
        "max_context_kb": 10          // Max memory context to load
      }
    }
  ]
}
```

### Minimal Config (Uses Defaults)

```json
{
  "memory": {
    "enabled": true
  }
}
```

All workers get memory with sensible defaults.

---

## CLI Commands

### czarina memory init

Initialize memory system for current project.

```bash
czarina memory init
```

Creates:
- `.czarina/memories.md` with template
- Memory configuration in `.czarina/config.json`

### czarina memory query

Search memories for relevant past experience.

```bash
czarina memory query "authentication errors"
czarina memory query "deployment issues production"
czarina memory query "performance optimization database"
```

Returns top N most relevant session excerpts.

### czarina memory extract

Extract learnings from current session.

```bash
czarina memory extract
```

Prompts for:
- Session description
- What was accomplished
- What broke and why
- Key learnings
- What to remember

Appends structured entry to memories.md.

### czarina memory rebuild

Rebuild search index from memories.md.

```bash
czarina memory rebuild
```

Use after manually editing memories.md.

### czarina memory status

Show memory system status.

```bash
czarina memory status
```

Displays:
- Memory enabled: yes/no
- Core size: X KB
- Session count: N
- Last indexed: timestamp
- Index size: X KB

---

## Best Practices

### 1. Keep Architectural Core Tight

**Good Architectural Core (concise):**
```markdown
## Architectural Core

### Component Dependencies
- Auth must load before API calls
- Config loaded from .env at startup (not runtime)

### Known Couplings
- Changing API port breaks frontend (hardcoded at build)

### Critical Constraints
- All DB queries MUST be parameterized (no string interpolation)
```

**Bad Architectural Core (too verbose):**
```markdown
## Architectural Core

This project uses React for the frontend with Redux for state management.
We chose React because it's popular and has good documentation.
The backend is Node.js with Express because we like JavaScript.
We use PostgreSQL for the database which is a relational database...
[500 more lines of background information]
```

**Rule:** If it's not essential for EVERY session, it doesn't belong in Architectural Core.

### 2. Write Good Session Summaries

**Good Session Summary:**
```markdown
## Session: 2025-12-20 - Redis Connection Pool Exhaustion

### Problem
App crashed in production: "Error: Redis connection pool exhausted"

### Root Cause
- Connection pool size: 10 (default)
- Background jobs opening connections but not releasing them
- Proper cleanup only in happy path, not error path

### Solution
1. Increased pool size to 50 (REDIS_POOL_SIZE env var)
2. Added finally blocks to ensure connection release
3. Implemented connection timeout (5s)

### Prevention
- ALWAYS use try/finally for connection cleanup
- Monitor connection pool metrics
- Load test background job scenarios
```

**Bad Session Summary:**
```markdown
## Session: 2025-12-20

Fixed some Redis stuff. It was broken but now it works.
```

**Rule:** Future you (and future workers) should understand what happened and why.

### 3. Update Architectural Core Sparingly

Promote to Architectural Core only when:
- The pattern affects MANY sessions
- Violating it causes serious problems
- It's truly architectural (not tactical)

**Example of promotion:**
```markdown
# After Redis connection issue happens 3 times:

## Architectural Core

### Critical Constraints (ADDED)
- All resource connections (DB, Redis, etc.) MUST use try/finally for cleanup
- Connection pool sizes configured via env vars (never hardcoded)
```

### 4. Use Semantic Queries

**Good Queries (semantic):**
```bash
czarina memory query "why does deployment fail in production"
czarina memory query "authentication token refresh issues"
czarina memory query "database query performance problems"
```

**Less Effective Queries (keyword):**
```bash
czarina memory query "deployment"  # Too broad
czarina memory query "fix"         # Not specific enough
```

### 5. Review and Curate Periodically

Every few months:
1. Review session entries - are they still relevant?
2. Consolidate similar learnings
3. Promote important patterns to Architectural Core
4. Mark outdated entries as superseded
5. Rebuild index after edits

---

## Embedding Providers

### OpenAI (Recommended)

**Pros:**
- High quality embeddings
- Fast API response
- Well-tested and reliable

**Cons:**
- Requires API key and internet
- Small cost per embedding (~$0.0001 per 1K tokens)

**Setup:**
```json
{
  "memory": {
    "embedding_provider": "openai",
    "embedding_model": "text-embedding-3-small"
  }
}
```

Requires `OPENAI_API_KEY` environment variable.

### Local (Coming Soon)

**Pros:**
- No API key needed
- No internet required
- No cost
- Privacy-preserving

**Cons:**
- Slower on CPU
- Lower quality embeddings
- Requires local model download

**Setup:**
```json
{
  "memory": {
    "embedding_provider": "local",
    "local_model": "sentence-transformers/all-MiniLM-L6-v2"
  }
}
```

---

## Advanced Usage

### Manual Memory Queries in Worker Sessions

Workers can query memory during their session:

```bash
# In worker session
cat .czarina/memories.md  # Read full memory

# Or use CLI
czarina memory query "database timeout issues"
```

### Memory-Driven Debugging

When encountering an error:

1. **Query memory first:**
   ```bash
   czarina memory query "error message text"
   ```

2. **Check if similar issue was solved before**

3. **Apply previous solution or lessons learned**

4. **If new issue, document solution for next time**

### Cross-Project Patterns

For patterns that apply across ALL your projects, create a **personal knowledge base**:

```bash
# ~/my-agent-knowledge/common-patterns.md
## Database Connection Patterns
- Always use connection pooling
- Always cleanup in finally blocks
- Monitor pool exhaustion

## API Security Patterns
- Always validate input
- Always use parameterized queries
- Always rate limit endpoints
```

Reference this in your Czarina projects via agent rules or custom includes.

### Memory + Agent Rules Synergy

**Agent Rules** = Universal best practices ("use connection pooling")
**Memory** = Your project's specific learnings ("our pool size is 50, timeout is 5s")

**Together:**
```python
# From agent rules: Use connection pooling pattern
pool = await get_connection_pool()

# From memory: Use project-specific settings learned from past failures
pool_config = {
    'size': 50,        # From memory: "Learned after production crash"
    'timeout': 5       # From memory: "Prevents hanging connections"
}
```

See [AGENT_RULES.md](AGENT_RULES.md) for agent rules integration.

---

## Troubleshooting

### Memory Not Loading

**Symptom:** Workers don't seem to have memory context

**Solutions:**
1. Check `memory.enabled: true` in config.json
2. Verify `.czarina/memories.md` exists
3. Check worker config has memory enabled
4. Look for errors in logs

### Search Returns No Results

**Symptom:** `czarina memory query` returns empty

**Possible Causes:**
1. Index not built: Run `czarina memory rebuild`
2. Query too specific: Try broader semantic query
3. Similarity threshold too high: Lower in config
4. memories.md has no content yet

### Embedding API Errors

**Symptom:** "OpenAI API error" when rebuilding index

**Solutions:**
1. Check `OPENAI_API_KEY` environment variable is set
2. Verify API key is valid
3. Check internet connection
4. Consider switching to local embeddings

### Context Size Too Large

**Symptom:** Worker fails to start, context size error

**Solutions:**
1. Reduce Architectural Core size (trim to essentials)
2. Lower `max_results` in memory config
3. Reduce `max_context_kb` in worker memory config
4. Use memory more selectively

---

## Migration from v0.6.2

Memory system is **opt-in**. Existing projects work unchanged:

```bash
# v0.6.2 behavior - no memory
czarina launch  # Works exactly as before

# v0.7.0 with memory - opt in
czarina memory init
# Edit .czarina/memories.md
# Add to config.json:
{
  "memory": { "enabled": true }
}
czarina launch  # Now uses memory
```

See [MIGRATION_v0.7.0.md](MIGRATION_v0.7.0.md) for complete migration guide.

---

## Examples

### Example 1: Basic Memory Setup

**Initialize:**
```bash
czarina memory init
```

**Edit memories.md:**
```markdown
## Architectural Core

### Component Dependencies
- Frontend: React app, depends on backend API
- Backend: Node.js/Express, depends on PostgreSQL

### Critical Constraints
- API must be on port 8000 (frontend expects this)
- All env vars loaded from .env file at startup
```

**Launch with memory:**
```json
{
  "memory": { "enabled": true }
}
```

### Example 2: Post-Bug Session Extraction

**After fixing a bug:**
```bash
czarina memory extract
```

**Prompts:**
```
Session description: Database connection timeout fix
What was accomplished: Fixed intermittent DB connection failures
What broke: Connections timing out after 10 minutes
Root cause: No connection timeout set, defaults to infinity
Solution: Set connection_timeout=30s in DB config
Key learning: ALWAYS set timeouts for external resources
```

**Result in memories.md:**
```markdown
## Session: 2025-12-20 - Database Connection Timeout Fix

### Problem
Intermittent database connection failures in production

### Root Cause
Database driver default timeout is infinity
Long-running queries held connections indefinitely
Pool exhaustion after several hours

### Solution
Set connection_timeout=30s in database configuration
Added connection monitoring alerts

### Remember
ALWAYS set explicit timeouts for external resources (DB, Redis, API calls)
Never rely on defaults
```

### Example 3: Querying Before Implementation

**Before implementing caching:**
```bash
czarina memory query "caching implementation"
```

**Results:**
```
Session: 2025-11-15 - Redis Caching Attempt
- Tried Redis for caching API responses
- Performance improved but added complexity
- Decided against it: cache invalidation too tricky
- Stuck with in-memory cache with TTL

Session: 2025-10-20 - In-Memory Cache Implementation
- Implemented LRU cache with 5-minute TTL
- Cache hit rate: 60%
- Good balance of performance and simplicity
```

**Benefit:** Avoid re-debating Redis, remember what worked (in-memory LRU).

---

## FAQ

### How much does memory cost?

**Storage:** Negligible (memories.md is typically < 1MB)
**Embedding:** ~$0.0001 per 1K tokens with OpenAI (pennies per month)
**Compute:** < 1 second per query

### Can I edit memories.md manually?

Yes! memories.md is human-readable markdown. Edit freely, then:
```bash
czarina memory rebuild  # Regenerate search index
```

### What if I disagree with a memory?

Edit memories.md:
- Mark outdated entries with **[SUPERSEDED]**
- Add corrections or clarifications
- Delete entries that are no longer relevant

### Do all workers need memory?

No. Enable per-worker:
```json
{
  "workers": [
    {
      "id": "experiment",
      "memory": { "enabled": false }  // No memory for this worker
    }
  ]
}
```

### Can I share memories across projects?

Not directly, but you can:
1. Copy relevant entries between projects' memories.md
2. Use agent rules for universal patterns
3. Maintain personal knowledge base separately

### How often should I extract memories?

**Recommended:**
- After fixing bugs (capture root cause)
- After debugging sessions (capture discoveries)
- After architectural decisions (capture rationale)
- At phase completion (capture learnings)

**Not necessary:**
- Routine feature work
- Simple bug fixes
- Trivial changes

---

## Related Documentation

- [AGENT_RULES.md](AGENT_RULES.md) - Agent rules integration (complements memory)
- [MIGRATION_v0.7.0.md](MIGRATION_v0.7.0.md) - Upgrading from v0.6.2
- [QUICK_START.md](QUICK_START.md) - Getting started guide
- [czarina_memory_spec.md](czarina_memory_spec.md) - Technical specification

---

## Summary

**Memory System in v0.7.0:**
- ✅ 3-tier architecture (Core, Knowledge, Session)
- ✅ Human-readable markdown storage
- ✅ Semantic search for relevant past sessions
- ✅ Automatic extraction at session end
- ✅ Works with all AI coding agents
- ✅ Opt-in and backward compatible
- ✅ Negligible cost and overhead

**Workers that learn, remember, and improve over time.**

---

**Version:** 0.7.0
**Last Updated:** 2025-12-28
**Next:** [MIGRATION_v0.7.0.md](MIGRATION_v0.7.0.md)
