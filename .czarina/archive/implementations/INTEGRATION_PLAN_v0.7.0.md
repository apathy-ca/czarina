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

**Implementation Approach:** Czarina Orchestration (Dogfooding!)
**Timeline:** 3-5 days for complete implementation
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

## Implementation Strategy: Czarina Orchestration

**Approach:** Use Czarina to build Czarina v0.7.0 (dogfooding!)

**Inspiration:** The agent-rules library was created by a 7-worker Czarina orchestration:
- 69 files, 43K+ lines created
- 100% worker success rate
- 3-week project completed in 2 days
- **Why not use the same approach for v0.7.0?**

### Orchestration Plan

**Session Name:** `czarina-v0.7.0`
**Orchestration Mode:** `parallel_spike` (Phase 1) → `sequential_dependencies` (Phase 2)
**Total Workers:** 9 workers across 2 phases
**Estimated Duration:** 3-5 days

### Phase 1: Foundation (Parallel - Day 1-2)

**4 workers working in parallel:**

#### Worker 1: `rules-integration`
- **Role:** Code
- **Agent:** Claude Code (or Aider)
- **Branch:** `feat/v0.7.0-rules-integration`
- **Dependencies:** None
- **Tasks:**
  - Create symlink: `czarina-core/agent-rules -> ../agent-rules/agent-rules`
  - Add to .gitignore
  - Create `AGENT_RULES.md` documentation
  - Update main README to mention agent rules
  - Test manual access from Czarina
- **Deliverable:** Agent rules accessible in Czarina

#### Worker 2: `memory-core`
- **Role:** Code
- **Agent:** Claude Code (or Aider)
- **Branch:** `feat/v0.7.0-memory-core`
- **Dependencies:** None
- **Tasks:**
  - Design `memories.md` schema (based on spec)
  - Implement basic file I/O in bash/python
  - Create `.czarina/memories.md` template
  - Manual extraction workflow
  - Basic validation
- **Deliverable:** Memory file structure working

#### Worker 3: `memory-search`
- **Role:** Code
- **Agent:** Claude Code
- **Branch:** `feat/v0.7.0-memory-search`
- **Dependencies:** None
- **Tasks:**
  - Choose embedding provider (OpenAI vs local)
  - Implement vector indexing (JSON-based)
  - Build search functionality
  - Test query accuracy
  - Document embedding strategy
- **Deliverable:** Semantic search functional

#### Worker 4: `cli-commands`
- **Role:** Code
- **Agent:** Aider (or Claude Code)
- **Branch:** `feat/v0.7.0-cli-commands`
- **Dependencies:** None
- **Tasks:**
  - Add `czarina memory query "<task>"`
  - Add `czarina memory extract`
  - Add `czarina memory rebuild`
  - Add `czarina init --with-rules --with-memory`
  - Update CLI help text
- **Deliverable:** CLI commands working

**Phase 1 Duration:** 1-2 days (workers in parallel)
**Phase 1 Outcome:** All 4 foundation components ready

---

### Phase 2: Integration (Sequential - Day 3-4)

**5 workers with dependencies:**

#### Worker 5: `config-schema`
- **Role:** Code
- **Agent:** Claude Code
- **Branch:** `feat/v0.7.0-config-schema`
- **Dependencies:** rules-integration, memory-core
- **Tasks:**
  - Extend config.json schema
  - Add `rules` configuration section
  - Add `memory` configuration section
  - Add worker-level `role` field
  - Update schema validation
  - Migration for existing configs
- **Deliverable:** Extended config schema

#### Worker 6: `launcher-enhancement`
- **Role:** Code
- **Agent:** Claude Code
- **Branch:** `feat/v0.7.0-launcher-enhancement`
- **Dependencies:** config-schema, memory-search, rules-integration
- **Tasks:**
  - Modify `czarina-core/agent-launcher.sh`
  - Implement role-to-rules mapping
  - Load architectural core from memory
  - Query relevant memories on worker start
  - Inject rules into worker context
  - Handle all 9 agent types
  - Test context size management
- **Deliverable:** Enhanced launcher with rules + memory

#### Worker 7: `integration`
- **Role:** QA + Integration
- **Agent:** Claude Code
- **Branch:** `feat/v0.7.0-integration`
- **Dependencies:** ALL previous workers
- **Tasks:**
  - Merge all feature branches
  - Resolve conflicts
  - End-to-end integration testing
  - Test with real multi-worker orchestration
  - Performance benchmarking
  - Bug fixes
- **Deliverable:** Fully integrated v0.7.0

#### Worker 8: `documentation`
- **Role:** Documentation
- **Agent:** Claude Code
- **Branch:** `feat/v0.7.0-documentation`
- **Dependencies:** integration (for accuracy)
- **Tasks:**
  - Update all documentation
  - Create migration guide from v0.6.2
  - Write v0.7.0 release notes
  - Create example `memories.md` files
  - Update QUICK_START.md
  - Create MEMORY_GUIDE.md
  - Update CHANGELOG.md
- **Deliverable:** Complete documentation

#### Worker 9: `release`
- **Role:** QA + Release
- **Agent:** Claude Code (or Human)
- **Branch:** `feat/v0.7.0-release`
- **Dependencies:** documentation, integration
- **Tasks:**
  - Final testing (all features)
  - Performance validation
  - Security review
  - Create git tag v0.7.0
  - Update CZARINA_STATUS.md
  - Prepare GitHub release
  - Publish release
- **Deliverable:** v0.7.0 released

**Phase 2 Duration:** 2-3 days (sequential with some parallelism)
**Phase 2 Outcome:** v0.7.0 complete, tested, documented, released

---

### Total Timeline

**Day 1-2:** Phase 1 (4 parallel workers)
**Day 3-4:** Phase 2 (5 workers, some sequential)
**Day 5:** Buffer/polish

**Total:** 3-5 days vs 3-4 weeks traditional development
**Speedup:** 6-8x faster using Czarina orchestration!

---

## Worker Orchestration Details

### Czarina Configuration (config.json)

```json
{
  "project": {
    "name": "czarina-v0.7.0",
    "slug": "czarina-v0-7-0",
    "description": "Memory System + Agent Rules Integration"
  },
  "orchestration": {
    "mode": "parallel_spike"
  },
  "workers": [
    {
      "id": "rules-integration",
      "role": "code",
      "agent": "claude",
      "branch": "feat/v0.7.0-rules-integration",
      "dependencies": []
    },
    {
      "id": "memory-core",
      "role": "code",
      "agent": "claude",
      "branch": "feat/v0.7.0-memory-core",
      "dependencies": []
    },
    {
      "id": "memory-search",
      "role": "code",
      "agent": "claude",
      "branch": "feat/v0.7.0-memory-search",
      "dependencies": []
    },
    {
      "id": "cli-commands",
      "role": "code",
      "agent": "aider",
      "branch": "feat/v0.7.0-cli-commands",
      "dependencies": []
    },
    {
      "id": "config-schema",
      "role": "code",
      "agent": "claude",
      "branch": "feat/v0.7.0-config-schema",
      "dependencies": ["rules-integration", "memory-core"]
    },
    {
      "id": "launcher-enhancement",
      "role": "code",
      "agent": "claude",
      "branch": "feat/v0.7.0-launcher-enhancement",
      "dependencies": ["config-schema", "memory-search", "rules-integration"]
    },
    {
      "id": "integration",
      "role": "qa",
      "agent": "claude",
      "branch": "feat/v0.7.0-integration",
      "dependencies": ["rules-integration", "memory-core", "memory-search", "cli-commands", "config-schema", "launcher-enhancement"]
    },
    {
      "id": "documentation",
      "role": "documentation",
      "agent": "claude",
      "branch": "feat/v0.7.0-documentation",
      "dependencies": ["integration"]
    },
    {
      "id": "release",
      "role": "qa",
      "agent": "claude",
      "branch": "feat/v0.7.0-release",
      "dependencies": ["documentation", "integration"]
    }
  ]
}
```

### Czar Responsibilities

The **Czar** (human or autonomous) will:
1. Launch Phase 1 workers (parallel)
2. Monitor progress via dashboard
3. Launch Phase 2 workers when Phase 1 complete
4. Coordinate dependency merges
5. Review integration worker output
6. Approve release

### Expected Outcomes by Phase

**After Phase 1 (Day 1-2):**
- ✅ Agent rules symlinked and documented
- ✅ Memory file structure implemented
- ✅ Semantic search working
- ✅ CLI commands added

**After Phase 2 (Day 3-4):**
- ✅ Config schema extended
- ✅ Launcher loads rules + memory
- ✅ All components integrated
- ✅ Documentation complete
- ✅ v0.7.0 ready for release

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

### Phase 1 Success Criteria (Foundation Workers)
- [ ] **rules-integration:** Agent rules symlinked, documented, accessible
- [ ] **memory-core:** Memory file structure created, templates working
- [ ] **memory-search:** Semantic search functional, accuracy > 70%
- [ ] **cli-commands:** All 4 CLI commands working

### Phase 2 Success Criteria (Integration Workers)
- [ ] **config-schema:** Extended schema, backward compatible
- [ ] **launcher-enhancement:** Rules + memory loaded, all 9 agents supported
- [ ] **integration:** All branches merged, tests passing, performance < 2s overhead
- [ ] **documentation:** Complete docs, migration guide, examples
- [ ] **release:** v0.7.0 tagged, published, status updated

### Orchestration Success Indicators

**Process Metrics:**
- ✅ All 9 workers complete successfully
- ✅ No critical merge conflicts
- ✅ Dependency coordination smooth
- ✅ 3-5 day timeline met
- ✅ Czar overhead minimal

**Technical Metrics:**
- Context loading < 2 seconds
- Memory search accuracy > 70%
- Context size < 20KB
- All 9 agents supported
- Backward compatibility maintained

**Quality Metrics:**
- Workers produce 30%+ fewer errors
- Debugging time reduced by 40%+
- Session-to-session repetition reduced 50%+
- Better code quality observed
- Reduced coordination overhead

**Market Impact:**
- First orchestrator with memory
- Unique market differentiation
- Dogfooding proof (Czarina built by Czarina)
- Positive user feedback

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
- [x] Revise plan to use Czarina orchestration (DONE)
- [ ] Review and approve orchestration plan
- [ ] Decide: Launch orchestration or refine plan

### Launch Preparation (Day 0)
- [ ] Create worker identity files in `.czarina/workers/`
- [ ] Create initial config.json for czarina-v0.7.0
- [ ] Initialize git branches for all 9 workers
- [ ] Set up tmux session
- [ ] Brief all workers via identity files

### Phase 1 Launch (Day 1)
- [ ] Launch 4 parallel workers: rules-integration, memory-core, memory-search, cli-commands
- [ ] Monitor progress via dashboard
- [ ] Czar coordination as needed
- [ ] Review deliverables at end of day

### Phase 2 Launch (Day 2-3)
- [ ] Launch config-schema (depends on Phase 1)
- [ ] Launch launcher-enhancement (depends on config-schema)
- [ ] Launch integration worker (depends on all previous)
- [ ] Launch documentation worker
- [ ] Launch release worker

### Completion (Day 4-5)
- [ ] Review all worker deliverables
- [ ] Final integration testing
- [ ] Publish v0.7.0
- [ ] Update CZARINA_STATUS.md
- [ ] Create orchestration closeout report

---

## Conclusion

**v0.7.0 represents a paradigm shift for Czarina:**

From: Multi-agent orchestrator
To: **Learning, knowledge-powered orchestration system**

**The combination of memory + agent rules creates:**
- Workers that learn from experience (memory)
- Workers that apply proven patterns (rules)
- Workers that get better over time (both!)

**Implementation Approach: Dogfooding at its finest**
- Using Czarina to build Czarina v0.7.0
- 9 workers, 2 phases, 3-5 days
- 6-8x faster than traditional development
- Proves Czarina's orchestration power

**Timeline:** 3-5 days (vs 3-4 weeks traditional)
**Complexity:** Medium
**Impact:** Very High
**Differentiation:** Unique in market

**This positions Czarina as the most sophisticated multi-agent orchestration system available.**

**Meta-Statement:** Just as the agent-rules library was created by Czarina orchestrating 7 workers (3-week project in 2 days), we'll use Czarina to build its own next version. **Czarina builds Czarina. 🐕**

---

**Status:** Ready for orchestration launch
**Implementation:** 9-worker Czarina orchestration
**Target Release:** v0.7.0
**Created:** 2025-12-27
**Revised for Orchestration:** 2025-12-28
