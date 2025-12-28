# Enhancement: Memory Architecture for Persistent AI Learning

**Priority:** High
**Complexity:** Medium
**Value:** Very High
**Tags:** memory, learning, persistence, context, differentiation
**Status:** Proposed
**Created:** 2025-12-27

---

## Summary

Implement a 3-tier memory architecture to solve the "mayfly problem" - AI agents losing all context between sessions. Enable workers to remember past work, past mistakes, and accumulated project knowledge across sessions.

## Background

### The Mayfly Problem

AI coding assistants start each session fresh with no memory of:
- Past mistakes and their solutions
- Hard-won knowledge about codebase quirks
- Architectural decisions and their rationale
- Debugging discoveries
- Project-specific patterns

This leads to:
- ❌ Repeating the same errors across sessions
- ❌ Losing valuable debugging insights
- ❌ Inability to learn from corrections
- ❌ Increasing friction as project complexity grows
- ❌ Workers rediscovering the same issues

### Why This Matters for Czarina

Multi-agent orchestrations amplify the problem:
- Workers can't learn from each other's discoveries
- Phase knowledge doesn't carry forward
- Integration issues get re-debugged
- Architectural understanding gets lost

**With memory:** Workers build institutional knowledge over time.

---

## Proposal

### Three-Tier Memory System

#### Tier 1: Architectural Core (~2-4KB, always loaded)
**Purpose:** Essential project context loaded at every session start

**Contains:**
- Component dependencies and relationships
- Known couplings (explicit and implicit)
- Critical constraints and invariants
- Technology stack and key patterns

**Example:**
```markdown
## Architectural Core

### Component Dependencies
- AuthContext must mount before any authenticated API calls
- SessionProvider wraps Router wraps App - order matters
- OpenSearch index requires specific mapping schema

### Known Couplings
- UI re-renders can race with token refresh → auth failures
- Docker network mode affects RabbitMQ connection strings
- Frontend build assumes backend on port 8000

### Constraints
- All API calls through /api prefix for proxy routing
- Environment variables loaded at build time (frontend)
```

#### Tier 2: Project Knowledge (semantic search)
**Purpose:** Searchable session history with learnings

**Contains:**
- Session summaries (what was done, what was learned)
- Bug investigations and root causes
- Deployment issues and resolutions
- Decisions and their rationale
- "Scar tissue" - things that bit us

**Access Pattern:**
- Query with current task context
- Retrieve top 3-5 relevant entries
- Include in worker context

**Example:**
```markdown
## Session: 2025-12-08 - Phase 4 Deployment

### What We Did
- Deployed attention shaping service
- Integrated per-Sage learning

### What Broke
- OpenSearch rejected mapping update
- Error: mapper_parsing_exception

### Root Cause
- Existing index had attention_weight as float
- New code expected nested object
- OpenSearch doesn't allow type changes

### Resolution
- Deleted index, allowed recreation
- Data loss acceptable (dev environment)

### Prevention
- TODO: Implement index versioning
- Consider: Index-per-version pattern
```

#### Tier 3: Session Context (ephemeral)
**Purpose:** Current session working state

**Lifecycle:** Created at start, discarded at end (after extraction)

**Contains:**
- Current phase and task
- Files touched this session
- Recent changes and effects
- Pending questions
- Running notes for extraction

---

## Implementation

### File Structure

```
.czarina/
├── memories.md         # Human-readable, git-tracked
├── memories.index      # Vector embeddings (regenerable cache)
└── config.json         # Memory settings
```

### memories.md Format

```markdown
# Project Memory: [Project Name]

## Architectural Core
[Always-loaded essential context - keep tight]

---

## Project Knowledge

### Session: YYYY-MM-DD - [Description]
[Structured session notes]

---

## Patterns and Decisions

### [Pattern Name]
- **Context**: Why this came up
- **Decision**: What we chose
- **Rationale**: Why
- **Revisit if**: Conditions that would change this
```

### Operations

**Session Start:**
1. Load full Architectural Core into context
2. Parse current task/phase description
3. Query Tier 2 for relevant knowledge (semantic search)
4. Include top 3-5 results in context

**During Session:**
1. Maintain running session notes (Tier 3)
2. Flag discoveries for end-of-session capture
3. Allow manual "remember this" from human

**Session End:**
1. Prompt for session summary extraction
2. Append structured entry to Project Knowledge
3. Regenerate vector index
4. Clear Tier 3

**On Human Edit:**
1. Detect changes to memories.md
2. Regenerate memories.index from scratch
3. Index is disposable cache, markdown is truth

### Embedding Strategy

**Chunking:**
- Architectural Core: Single chunk (loaded whole)
- Project Knowledge: One chunk per session
- Large sessions: Split at ### headers

**Vector Storage (memories.index):**
```json
{
  "chunks": [
    {
      "id": "session-2025-12-08-001",
      "source_line_start": 45,
      "source_line_end": 78,
      "text": "[chunk text]",
      "embedding": [0.023, -0.089, ...]
    }
  ],
  "metadata": {
    "embedding_model": "text-embedding-3-small",
    "chunk_count": 42,
    "last_indexed": "2025-12-10T14:30:00Z"
  }
}
```

**Search:**
- Embed current task description
- Cosine similarity against all chunks
- Return top 3-5 with similarity > 0.7
- Include full chunk text in context

---

## Integration with Czarina

### Phase Integration
- **Phase start:** Query memories relevant to phase objectives
- **Phase end:** Extract learnings, add to Project Knowledge
- **Cross-phase:** Architectural Core provides continuity

### Worker Integration
- **Worker launch:** Load core + relevant knowledge
- **Worker work:** Access to search memories
- **Worker completion:** Extract session learnings

### Czar Coordination
- **Czar monitors:** Can query all worker memories
- **Cross-worker learning:** Workers benefit from each other
- **Integration:** Past integration issues inform current

### Human Override
- Human can edit memories.md anytime
- Mark entries as "deprecated" or "superseded"
- Promote learnings to Architectural Core

---

## MVP Scope

### Include in MVP:
1. ✅ memories.md with manual structure
2. ✅ Simple embedding (OpenAI or local model)
3. ✅ JSON file for vector storage
4. ✅ Session-start query for relevant context
5. ✅ Session-end prompt for extraction
6. ✅ Regenerate index on file change
7. ✅ Basic CLI commands:
   - `czarina memory query "task description"`
   - `czarina memory extract` (end of session)
   - `czarina memory rebuild` (regenerate index)

### Skip for MVP:
- ❌ Automatic chunking optimization
- ❌ Confidence scoring
- ❌ Cross-project memory
- ❌ Attention feedback loops
- ❌ Contradiction detection
- ❌ Advanced UI

---

## Benefits

### For Single Workers
- ✅ Learn from past mistakes
- ✅ Remember debugging discoveries
- ✅ Maintain architectural understanding
- ✅ Recall project quirks and couplings

### For Multi-Agent Orchestrations
- ✅ Workers learn from each other
- ✅ Phase knowledge carries forward
- ✅ Integration patterns remembered
- ✅ Czar has full context of all workers

### For Users
- ✅ Reduced repetition and re-work
- ✅ Faster debugging (past issues recalled)
- ✅ Better quality (patterns reinforced)
- ✅ Lower friction over time

### Competitive Differentiation
- 🌟 **First orchestrator with memory**
- 🌟 Unique in market
- 🌟 Solves fundamental AI limitation
- 🌟 Demonstrates Czarina's sophistication

---

## Risks & Considerations

### Technical Risks
- **Embedding costs:** OpenAI API has per-query cost
  - *Mitigation:* Support local models (sentence-transformers)

- **Index stale:** File edited but index not rebuilt
  - *Mitigation:* File watcher or git hook

- **Context pollution:** Irrelevant memories retrieved
  - *Mitigation:* Similarity threshold, human curation

### UX Risks
- **Manual extraction burden:** Users forget to extract learnings
  - *Mitigation:* Automatic prompts at session end

- **Memory bloat:** memories.md grows too large
  - *Mitigation:* Archive old sessions, keep core tight

### Scope Risks
- **Feature creep:** Easy to over-engineer
  - *Mitigation:* Strict MVP scope, iterate after validation

---

## Success Metrics

### MVP Success Criteria
- [ ] memories.md created and populated
- [ ] Vector search returns relevant results
- [ ] Workers successfully use memory in context
- [ ] 80%+ of sessions extract learnings
- [ ] User reports reduced repetition

### Performance Targets
- Session start: < 2 seconds (including search)
- Index rebuild: < 10 seconds for 100 sessions
- Search accuracy: 70%+ relevant in top 5

### Quality Indicators
- Architectural Core stays under 5KB
- Session entries follow structure
- Learnings actually get reused

---

## Implementation Timeline

### Week 1: Foundation (3-4 days)
- [ ] Design memories.md schema
- [ ] Implement basic file I/O
- [ ] Choose embedding provider
- [ ] Build index generation
- [ ] Basic search functionality

### Week 2: Integration (3-4 days)
- [ ] Integrate with agent launcher
- [ ] Session-start context loading
- [ ] Session-end extraction prompts
- [ ] CLI commands
- [ ] Documentation

### Week 3: Testing & Polish (2-3 days)
- [ ] Test with real orchestration
- [ ] Refine prompts and structure
- [ ] Performance optimization
- [ ] User documentation
- [ ] Example memories.md

**Total:** 8-11 days for full MVP

---

## Related Work

### Complements
- **Agent Rules Library:** Rules provide "what to remember"
- **Phase Management:** Natural extraction points
- **Logging System:** Source of session data
- **Hopper:** Task context for queries

### Future Enhancements
- Cross-project patterns (personal "scar tissue")
- Confidence decay (old memories weighted lower)
- Contradiction detection
- Attention shaping (track which memories get used)
- Multi-modal memory (images, diagrams)

---

## Acceptance Criteria

- [ ] memories.md format defined and documented
- [ ] Embedding provider integrated (OpenAI or local)
- [ ] Vector index generation working
- [ ] Semantic search returns relevant results
- [ ] Session-start loads core + relevant knowledge
- [ ] Session-end extracts learnings
- [ ] CLI commands functional
- [ ] Tested with real orchestration
- [ ] Documentation complete
- [ ] Example project with memories

---

## References

- **Design Spec:** `czarina_memory_spec.md`
- **Agent Rules:** Provides patterns worth remembering
- **Czarina Logging:** Session data source
- **Phase Management:** Natural memory boundaries

---

**Status:** Ready for implementation
**Next Step:** Prototype with one project, validate design
**Owner:** TBD
