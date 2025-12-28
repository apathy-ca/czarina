# Czarina v0.7.0 Integration Plan
## Memory System + Agent Rules Library

**Version:** 0.7.0 (Target)
**Current:** 0.6.2
**Created:** 2025-12-27
**Status:** Planning

---

## Executive Summary

**Objective:** Transform Czarina from a multi-agent orchestrator into a **learning, knowledge-powered orchestration system** by integrating two major enhancements:

1. **Memory Architecture** - Persistent learning across sessions
2. **Agent Rules Library** - 43K+ lines of production-tested best practices

**Value Proposition:** First orchestrator that combines multi-agent coordination with institutional memory AND comprehensive knowledge base.

**Timeline:** 3-4 weeks for complete implementation
**Complexity:** Medium
**Impact:** Very High - Market differentiation

---

## The Vision

### Current State (v0.6.2)

Workers start each session with:
- ✅ General AI knowledge
- ✅ Task-specific instructions from worker files
- ✅ Project repository access

Workers are **amnesiacs** - they forget everything between sessions.

### Target State (v0.7.0)

Workers start each session with:
- ✅ General AI knowledge
- ✅ Task-specific instructions
- ✅ Project repository access
- 🆕 **Project memory** (what we learned in THIS project)
- 🆕 **Agent rules** (what works across ALL projects)
- 🆕 **Role-specific guidance** (architect patterns, code standards)

Workers have **institutional knowledge** and **continuous learning**.

---

## The Two Enhancements

### Enhancement 1: Memory Architecture

**What:** 3-tier memory system (Architectural Core, Project Knowledge, Session Context)

**Solves:** "Mayfly problem" - AI agents forgetting everything between sessions

**Key Features:**
- Architectural Core: Always-loaded essentials (~2-4KB)
- Project Knowledge: Semantic search of past sessions
- Session Context: Ephemeral working state

**Files:**
- `.czarina/memories.md` (human-readable, git-tracked)
- `.czarina/memories.index` (vector embeddings, regenerable)

**Timeline:** 1-2 weeks

### Enhancement 2: Agent Rules Integration

**What:** Integration of 43K-line agent rules library into Czarina

**Solves:** Workers lacking production-tested best practices and patterns

**Key Features:**
- 69 files covering 9 domains (Python, agents, workflows, patterns, testing, security, templates, documentation, orchestration)
- Automatic loading based on worker role
- Template-based worker creation

**Files:**
- `czarina-core/agent-rules/` (symlink to library)
- `.czarina/agent-rules/` (project-level access)

**Timeline:** 2-3 weeks

### The Synergy

**Separate:** Each is valuable
**Together:** Transformational

| Source | Agent Rules | Memory System |
|--------|-------------|---------------|
| **What** | Cross-project patterns | Project-specific learnings |
| **Scope** | Universal best practices | This project's history |
| **Updates** | Manual curation | Automatic extraction |
| **Example** | "Use async context managers" | "Our DB connections timeout after 30s" |

**Combined Example:**

A worker debugging a database connection issue:
1. **Agent Rules** say: "Use connection pooling, implement retries"
2. **Memory** recalls: "Last time this failed, it was because we forgot connection timeout"
3. **Worker** applies both: Uses pooling (from rules) AND sets 30s timeout (from memory)

**Result:** Faster, better solution combining universal wisdom + project experience

---

## Implementation Strategy

### Option A: Sequential Implementation (Lower Risk)

**Phase 1:** Agent Rules Integration (2-3 weeks)
- Week 1: Quick integration (symlink, docs)
- Week 2: Automatic loading
- Week 3: Templates + polish

**Phase 2:** Memory System (1-2 weeks)
- Week 1: Core implementation (MVP)
- Week 2: Integration + testing

**Total:** 3-5 weeks
**Risk:** Lower (one at a time)
**Benefit:** Each enhancement independent

### Option B: Parallel Implementation (Faster, Higher Risk)

**Workstream 1:** Agent Rules (Developer A)
**Workstream 2:** Memory System (Developer B)
**Workstream 3:** Integration (Week 3-4, both devs)

**Total:** 3-4 weeks
**Risk:** Higher (coordination needed)
**Benefit:** Faster delivery

### Option C: MVP-First (Recommended)

**Week 1: Quick Wins**
- Day 1-2: Agent rules symlink + basic docs
- Day 3-5: Memory MVP (basic structure, manual)

**Week 2: Core Features**
- Day 1-3: Agent rules auto-loading
- Day 4-5: Memory semantic search

**Week 3: Integration**
- Day 1-3: Combined worker context loading
- Day 4-5: Testing with real orchestration

**Week 4: Polish & Release**
- Day 1-2: Documentation
- Day 3-4: Examples + templates
- Day 5: Release v0.7.0

**Total:** 4 weeks
**Risk:** Medium (validates early)
**Benefit:** Iterative, user feedback early

**Recommendation:** Option C (MVP-First)

---

## Detailed Timeline (Option C)

### Week 1: Foundation

#### Days 1-2: Agent Rules Quick Integration
- [ ] Create symlink: `czarina-core/agent-rules`
- [ ] Write `AGENT_RULES.md` guide
- [ ] Update main README
- [ ] Add to documentation
- [ ] Test manual access

**Deliverable:** Agent rules accessible in Czarina

#### Days 3-5: Memory System MVP
- [ ] Design `memories.md` schema
- [ ] Implement basic file I/O
- [ ] Manual extraction workflow
- [ ] Basic CLI commands
- [ ] Documentation

**Deliverable:** Manual memory system working

**Week 1 Goal:** Both systems accessible, manual workflows defined

---

### Week 2: Automation

#### Days 1-2: Agent Rules Auto-Loading (Part 1)
- [ ] Define role-to-rules mapping
- [ ] Extend worker config schema
- [ ] Implement rule selection logic
- [ ] Create condensed quick-references

#### Days 3-4: Memory Semantic Search
- [ ] Choose embedding provider
- [ ] Implement vector indexing
- [ ] Build search functionality
- [ ] Test query accuracy

#### Day 5: Integration Point 1
- [ ] Combine rules + memory in worker context
- [ ] Test with single worker
- [ ] Measure context size
- [ ] Refine loading logic

**Week 2 Goal:** Both systems automated, working separately

---

### Week 3: Full Integration

#### Days 1-2: Agent Rules Auto-Loading (Part 2)
- [ ] Modify agent launcher
- [ ] Inject rules into worker context
- [ ] Handle different agent types
- [ ] Test with all 9 agents

#### Days 3-4: Memory Session Integration
- [ ] Session-start context loading
- [ ] Session-end extraction prompts
- [ ] File watcher for index rebuild
- [ ] Czar memory aggregation

#### Day 5: Combined Worker Launch
- [ ] Worker gets: task + rules + memory
- [ ] Test context size management
- [ ] Validate relevance of loaded content
- [ ] Optimize for performance

**Week 3 Goal:** Fully integrated, working together

---

### Week 4: Polish & Release

#### Days 1-2: Documentation
- [ ] Update all documentation
- [ ] Create migration guide
- [ ] Write v0.7.0 release notes
- [ ] Example orchestrations

#### Days 3-4: Examples & Templates
- [ ] Example `memories.md` files
- [ ] Worker templates using rules
- [ ] End-to-end orchestration example
- [ ] Video/demo (optional)

#### Day 5: Release Preparation
- [ ] Final testing
- [ ] Create git tag v0.7.0
- [ ] Update CZARINA_STATUS.md
- [ ] Publish release

**Week 4 Goal:** v0.7.0 released, documented, demoed

---

## Technical Architecture

### File Structure

```
czarina/
├── czarina-core/
│   ├── agent-rules/           # Symlink to library
│   ├── agent-launcher.sh      # Modified: loads rules + memory
│   ├── memory-manager.sh      # NEW: memory operations
│   └── ...

.czarina/  (in projects)
├── config.json                # Extended: rules + memory config
├── memories.md                # NEW: project memory
├── memories.index             # NEW: vector embeddings
├── agent-rules/               # Symlink to library
├── workers/
└── ...
```

### Worker Context Loading (Pseudocode)

```python
def load_worker_context(worker_id, role, task):
    context = []

    # 1. Task-specific instructions (existing)
    context.append(load_worker_file(worker_id))

    # 2. Architectural Core (NEW - memory)
    memory_core = load_memory_core()
    context.append(memory_core)

    # 3. Role-specific rules (NEW - agent rules)
    rules = load_rules_for_role(role)
    context.append(rules)

    # 4. Relevant memories (NEW - memory search)
    relevant_memories = search_memories(task, top_k=5)
    context.append(relevant_memories)

    # 5. Custom project rules (optional)
    if project_has_custom_rules():
        context.append(load_custom_rules())

    return optimize_context(context, max_size=20KB)
```

### Context Size Management

**Challenge:** Don't exceed context limits

**Strategy:**
- Architectural Core: Max 4KB (tight curation)
- Agent Rules: Condensed versions (2-5KB per domain)
- Relevant Memories: Top 5 chunks (~3KB)
- Worker Instructions: ~2KB

**Total Target:** < 20KB additional context

**Implementation:**
- Create "quick reference" versions of rules
- Limit memory search to top 5 results
- Provide full docs as references (links)

---

## Integration Points

### 1. Worker Launch

**Before (v0.6.2):**
```bash
# Agent launcher
launch_worker(worker_id, agent_type) {
    load_worker_identity()
    launch_agent(instructions)
}
```

**After (v0.7.0):**
```bash
# Enhanced agent launcher
launch_worker(worker_id, role, agent_type, task) {
    # Load all context sources
    identity = load_worker_identity()
    rules = load_agent_rules(role)
    memory_core = load_memory_core()
    relevant_mem = search_memories(task)

    # Combine into context
    context = build_context(identity, rules, memory_core, relevant_mem)

    # Launch with enriched context
    launch_agent(context)
}
```

### 2. Session End

**New Workflow:**
```bash
# After worker completes tasks
extract_session_learnings(worker_id) {
    # Prompt worker for summary
    summary = prompt_extraction()

    # Append to memories.md
    append_to_memories(summary)

    # Rebuild index
    rebuild_memory_index()
}
```

### 3. Phase Management

**Enhanced Phase Close:**
```bash
czarina phase close {
    # Existing: archive workers, create phase summary

    # NEW: Extract phase learnings
    extract_phase_learnings()

    # NEW: Update architectural core if needed
    prompt_core_updates()
}
```

---

## Configuration Schema

### Extended config.json

```json
{
  "project": {
    "name": "my-project",
    "slug": "my-project",
    // ... existing fields
  },

  "workers": [
    {
      "id": "backend",
      "role": "code",          // NEW: enables rule loading
      "agent": "claude",
      "branch": "feat/backend",

      "rules": {               // NEW: rules configuration
        "enabled": true,
        "auto_load": true,
        "domains": ["python", "testing", "security"]
      },

      "memory": {              // NEW: memory configuration
        "enabled": true,
        "use_core": true,
        "search_on_start": true
      }
    }
  ],

  "agent_rules": {             // NEW: global rules config
    "library_path": ".czarina/agent-rules",
    "mode": "auto",            // auto, manual, disabled
    "condensed": true
  },

  "memory": {                  // NEW: global memory config
    "enabled": true,
    "embedding_provider": "openai",  // or "local"
    "embedding_model": "text-embedding-3-small",
    "similarity_threshold": 0.7,
    "max_results": 5
  }
}
```

---

## Success Metrics

### Phase 1 (Week 1) - Foundation
- [ ] Agent rules accessible in Czarina
- [ ] Memory file structure created
- [ ] Manual workflows documented
- [ ] Basic CLI commands working

### Phase 2 (Week 2) - Automation
- [ ] Rules auto-load by role
- [ ] Memory semantic search functional
- [ ] Context size < 20KB
- [ ] Search accuracy > 70%

### Phase 3 (Week 3) - Integration
- [ ] Workers receive both rules + memory
- [ ] Full orchestration tested
- [ ] Performance acceptable (<2s overhead)
- [ ] Quality improvements measurable

### Phase 4 (Week 4) - Release
- [ ] Documentation complete
- [ ] Examples provided
- [ ] v0.7.0 tagged and released
- [ ] User feedback positive

### Overall Success Indicators

**Quantitative:**
- Workers produce 30%+ fewer errors
- Debugging time reduced by 40%+
- Session-to-session repetition reduced 50%+
- Context loading < 2 seconds
- Memory search accuracy > 70%

**Qualitative:**
- Users report "workers feel smarter"
- Less repetition observed
- Better code quality
- Reduced coordination overhead
- Positive market reception

---

## Risks & Mitigation

### Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Context size bloat | High | Medium | Condensed versions, size limits |
| Embedding costs | Medium | High | Support local models |
| Search irrelevance | Medium | Medium | Tunable threshold, human curation |
| Integration bugs | High | Medium | Extensive testing, rollback plan |
| Performance degradation | Medium | Low | Benchmarking, optimization |

### Scope Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Feature creep | Medium | High | Strict MVP scope, defer enhancements |
| Timeline slip | Medium | Medium | Weekly checkpoints, buffer time |
| Resource constraints | High | Low | Clear ownership, parallel work |

### UX Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Complexity overwhelms users | High | Medium | Smart defaults, "just works" mode |
| Poor documentation | High | Low | Comprehensive docs, examples |
| Migration difficulty | Medium | Low | Migration guide, backward compat |

---

## Backward Compatibility

### Must Maintain

- ✅ Existing config.json format (extend, don't break)
- ✅ Worker file format (no changes required)
- ✅ Agent launcher interface (extend parameters)
- ✅ All existing commands work unchanged

### Opt-In Features

- Memory system: Disabled by default, enable via config
- Agent rules: Available but not forced on users
- Both can be disabled completely for v0.6.2 behavior

### Migration Path

```bash
# Existing projects continue working
czarina launch  # Works as before

# Opt-in to new features
czarina init --with-memory --with-rules

# Or manually enable in config.json
{
  "memory": { "enabled": true },
  "agent_rules": { "enabled": true }
}
```

---

## Testing Strategy

### Unit Testing
- [ ] Memory file I/O operations
- [ ] Vector embedding/search
- [ ] Rule loading and selection
- [ ] Context building logic

### Integration Testing
- [ ] End-to-end worker launch
- [ ] Session extraction workflow
- [ ] Combined rules + memory loading
- [ ] Multi-worker orchestration

### Performance Testing
- [ ] Context loading time (target: <2s)
- [ ] Memory search latency (target: <500ms)
- [ ] Index rebuild time (target: <10s for 100 sessions)
- [ ] Overall orchestration overhead

### User Acceptance Testing
- [ ] Real project migration
- [ ] Multi-phase orchestration
- [ ] Different agent types
- [ ] Mixed worker configurations

---

## Release Checklist

### Code Complete
- [ ] All enhancements implemented
- [ ] Tests passing (unit + integration)
- [ ] Performance benchmarks met
- [ ] No critical bugs

### Documentation
- [ ] README updated
- [ ] AGENT_RULES.md created
- [ ] Memory usage guide written
- [ ] Migration guide complete
- [ ] API documentation updated
- [ ] CHANGELOG.md updated

### Examples
- [ ] Example memories.md provided
- [ ] Template orchestrations created
- [ ] Quick start guide updated
- [ ] Video demo (optional)

### Release Artifacts
- [ ] Version bumped to 0.7.0
- [ ] Git tag created: v0.7.0
- [ ] Release notes written
- [ ] CZARINA_STATUS.md updated
- [ ] GitHub release published

---

## Marketing Message

### The Pitch

**Czarina v0.7.0: The First Learning Orchestrator**

"While other tools forget everything between sessions, Czarina workers **remember, learn, and improve**. With 43,000 lines of production-tested best practices and a semantic memory system, your workers get smarter with every session."

### Key Messages

1. **First with Memory**
   - "Workers remember past mistakes, debugging discoveries, and architectural decisions"
   - "Semantic search retrieves relevant past experience for current tasks"

2. **Production Knowledge Built-In**
   - "43K+ lines of best practices from real production systems"
   - "Workers start with expert-level knowledge, not general AI"

3. **Continuous Improvement**
   - "Each session makes the next one better"
   - "Project knowledge accumulates over time"

4. **Unique in Market**
   - "No other orchestrator combines multi-agent coordination + memory + knowledge base"
   - "Created by Czarina, for Czarina (dogfooding proof!)"

### Social Proof

"The agent rules library was created BY a Czarina orchestration - 7 workers, 100% success rate, 3-week project in 2 days. This is Czarina improving itself!"

---

## Next Steps

### Immediate (Today)
- [x] Create hopper enhancements (DONE)
- [x] Create integration plan (DONE)
- [ ] Review and approve plan
- [ ] Assign ownership

### This Week
- [ ] Set up development environment
- [ ] Create feature branch: `feat/v0.7.0-memory-and-rules`
- [ ] Begin Week 1 implementation
- [ ] Daily standups to track progress

### Ongoing
- [ ] Weekly checkpoint meetings
- [ ] User feedback collection
- [ ] Documentation as we go
- [ ] Testing continuously

---

## Conclusion

**v0.7.0 represents a paradigm shift for Czarina:**

From: Multi-agent orchestrator
To: **Learning, knowledge-powered orchestration system**

**The combination of memory + agent rules creates:**
- Workers that learn from experience (memory)
- Workers that apply proven patterns (rules)
- Workers that get better over time (both!)

**Timeline:** 4 weeks
**Complexity:** Medium
**Impact:** Very High
**Differentiation:** Unique in market

**This positions Czarina as the most sophisticated multi-agent orchestration system available.**

---

**Status:** Ready for approval and implementation
**Owner:** TBD
**Target Release:** v0.7.0
**Created:** 2025-12-27
