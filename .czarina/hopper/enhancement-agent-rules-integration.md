# Enhancement: Agent Rules Library Integration

**Priority:** High
**Complexity:** Low
**Value:** High
**Tags:** knowledge-base, best-practices, standards, quality
**Status:** Proposed
**Created:** 2025-12-27

---

## Summary

Integrate the comprehensive Agent Rules Library (43K+ lines, 69 files, 9 domains) into Czarina to provide workers with production-tested best practices, patterns, and standards automatically.

## Background

### What is Agent Rules Library?

A comprehensive knowledge base created **by Czarina** (7-worker orchestration) containing:
- **43,873 lines** of documentation
- **69 markdown files** (53+ rules + 13+ templates)
- **9 domains:** Python, agents, workflows, patterns, testing, security, templates, documentation, orchestration
- **100% production-tested** (extracted from SARK, thesymposium, Czarina)

**Key Achievement:** Created via Czarina orchestration - ultimate dogfooding proof!

### Current State

Agent Rules Library exists at `../agent-rules/agent-rules/` but is **not integrated** with Czarina. Workers don't automatically benefit from this knowledge.

### The Opportunity

Workers currently start with:
- General AI knowledge
- Task-specific instructions
- Project context

Workers **could** start with:
- ✅ General AI knowledge
- ✅ Task-specific instructions
- ✅ Project context
- 🆕 **Production-tested best practices** (agent rules)
- 🆕 **Role-specific guidance** (architect patterns, code standards, etc.)
- 🆕 **Domain expertise** (Python, security, testing, etc.)

---

## Proposal

### Integration Approach

Make agent rules available to workers through multiple mechanisms:

#### 1. **Symlink in Czarina** (Immediate - 5 minutes)

```bash
ln -s ~/Source/agent-rules/agent-rules ./czarina-core/agent-rules
```

**Benefit:** Rules immediately available in Czarina repo

#### 2. **Project-Level Integration** (Quick - 30 minutes)

```bash
czarina init --with-rules

# Creates:
# .czarina/
# ├── agent-rules -> ~/Source/agent-rules/agent-rules
# └── config.json
```

**Benefit:** Each project can reference rules

#### 3. **Automatic Context Loading** (Medium - 2-3 days)

Workers automatically load relevant rules based on their role:

```python
# agent-launcher.sh
def load_worker_context(worker_id, role):
    context = [
        load_worker_file(worker_id),
        load_architectural_core(),  # From memory system
    ]

    # Add role-specific rules
    if role == "code":
        context.append(load_rules("agents/CODE_ROLE.md"))
        context.append(load_rules("python/CODING_STANDARDS.md"))
    elif role == "architect":
        context.append(load_rules("agents/ARCHITECT_ROLE.md"))
        context.append(load_rules("patterns/TOOL_USE_PATTERNS.md"))
    elif role == "qa":
        context.append(load_rules("agents/QA_ROLE.md"))
        context.append(load_rules("testing/TESTING_POLICY.md"))

    return context
```

**Benefit:** Workers get relevant expertise automatically

#### 4. **Template-Based Worker Creation** (Medium - 3-4 days)

```bash
czarina create-worker engineer1 --role code --with-rules

# Generates worker file using:
# - agents/templates/worker-template.md
# - agents/CODE_ROLE.md
# - python/CODING_STANDARDS.md
```

**Benefit:** Consistent, high-quality worker definitions

---

## Implementation

### Phase 1: Quick Integration (1 day)

**Goal:** Make rules accessible to Czarina

**Steps:**
1. Create symlink: `czarina-core/agent-rules -> ../agent-rules/agent-rules`
2. Update documentation to reference rules
3. Add to `.gitignore` (don't track symlink target)
4. Test: Verify rules accessible from Czarina

**Deliverables:**
- [ ] Symlink created
- [ ] Documentation updated
- [ ] README mentions agent rules
- [ ] AGENT_RULES.md guide created

### Phase 2: Project Integration (2-3 days)

**Goal:** Projects can opt-in to rules

**Steps:**
1. Add `--with-rules` flag to `czarina init`
2. Create project-level symlink in `.czarina/agent-rules`
3. Update worker templates to reference rules
4. Add rule discovery to worker identity files

**Deliverables:**
- [ ] `czarina init --with-rules` working
- [ ] Project symlinks created correctly
- [ ] Worker identity mentions rules
- [ ] Documentation updated

### Phase 3: Automatic Loading (3-4 days)

**Goal:** Workers automatically get relevant rules

**Steps:**
1. Extend worker config with `role` field
2. Map roles to relevant rule files
3. Modify agent launcher to inject rules into context
4. Create condensed "quick reference" versions
5. Test with real orchestration

**Config Example:**
```json
{
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "agent": "claude",
      "branch": "feat/backend",
      "rules": {
        "auto_load": true,
        "include": ["python", "patterns", "testing"],
        "custom": ["./project-specific-rules.md"]
      }
    }
  ]
}
```

**Deliverables:**
- [ ] Role-to-rules mapping defined
- [ ] Automatic loading implemented
- [ ] Quick reference guides created
- [ ] Tested with multi-worker orchestration

### Phase 4: Templates & Creation (2-3 days)

**Goal:** Generate workers from templates

**Steps:**
1. Implement `czarina create-worker` command
2. Use agent-rules templates as source
3. Support role selection
4. Customize based on project type

**Deliverables:**
- [ ] `czarina create-worker` command
- [ ] Template-based generation
- [ ] Role customization
- [ ] Example workers generated

---

## Benefits

### For Individual Workers

**Code Workers:**
- ✅ Python coding standards loaded
- ✅ Async patterns available
- ✅ Error handling guidance
- ✅ Testing requirements clear

**Architect Workers:**
- ✅ Planning methodology defined
- ✅ Design patterns available
- ✅ Decision documentation templates
- ✅ Mermaid diagram examples

**QA Workers:**
- ✅ Testing policy understood
- ✅ Coverage standards defined
- ✅ Integration test patterns
- ✅ Closeout report templates

**Debug Workers:**
- ✅ Systematic debugging approach
- ✅ Error recovery patterns
- ✅ Log analysis techniques
- ✅ Root cause documentation

### For Orchestrations

- ✅ **Consistent quality** across all workers
- ✅ **Reduced errors** through standard patterns
- ✅ **Faster onboarding** (rules provide guidance)
- ✅ **Better collaboration** (shared vocabulary)
- ✅ **Self-documenting** (rules explain "why")

### For Czarina

- 🌟 **Market differentiation** - no competitor has this
- 🌟 **Quality improvement** - workers apply proven patterns
- 🌟 **Reduced friction** - less trial-and-error
- 🌟 **Dogfooding proof** - rules created by Czarina!
- 🌟 **Continuous improvement** - rules evolve with experience

---

## Synergy with Memory System

Agent rules + memory = **perfect combination**:

| Feature | Agent Rules | Memory System | Combined |
|---------|-------------|---------------|----------|
| **Scope** | Cross-project patterns | Project-specific learnings | Both! |
| **Source** | Production systems | This project's history | Comprehensive |
| **Updates** | Manual curation | Automatic extraction | Best of both |
| **Coverage** | Broad best practices | Deep project knowledge | Complete |

**Example Workflow:**
1. Worker starts → Loads agent rules (what works everywhere)
2. Worker starts → Loads project memory (what we learned here)
3. Worker works → Applies patterns from rules
4. Worker works → Recalls past mistakes from memory
5. Worker ends → Extracts learnings to memory
6. Next phase → Benefits from both knowledge sources!

**The Result:** Workers that are both broadly knowledgeable AND deeply experienced in this specific project.

---

## File Structure

### Option A: Symlink (Recommended)

```
czarina/
├── czarina-core/
│   ├── agent-rules -> ~/Source/agent-rules/agent-rules/
│   ├── agent-launcher.sh
│   └── ...
└── ...

.czarina/  (in projects)
├── agent-rules -> ~/Source/agent-rules/agent-rules/
├── memories.md
└── config.json
```

**Pros:** Single source of truth, easy updates
**Cons:** Requires agent-rules repo checked out

### Option B: Copy (Alternative)

```
czarina/
├── czarina-core/
│   ├── agent-rules/  (copied)
│   └── ...
```

**Pros:** Self-contained, no external dependency
**Cons:** Updates require re-copy, duplication

**Recommendation:** Use Option A (symlink)

---

## Configuration

### Worker Config Extension

```json
{
  "workers": [
    {
      "id": "backend",
      "role": "code",
      "agent": "claude",
      "branch": "feat/backend",
      "rules": {
        "enabled": true,
        "auto_load": true,
        "domains": ["python", "testing", "security"],
        "custom_rules": ["./docs/backend-patterns.md"]
      }
    }
  ],
  "rules": {
    "library_path": ".czarina/agent-rules",
    "mode": "auto",  // auto, manual, disabled
    "condensed": true  // Use quick-reference versions
  }
}
```

### Role-to-Rules Mapping

```yaml
# czarina-core/role-rules-mapping.yaml
roles:
  code:
    primary:
      - agents/CODE_ROLE.md
      - python/CODING_STANDARDS.md
    secondary:
      - patterns/TOOL_USE_PATTERNS.md
      - testing/UNIT_TESTING.md

  architect:
    primary:
      - agents/ARCHITECT_ROLE.md
      - patterns/TOOL_USE_PATTERNS.md
    secondary:
      - documentation/ARCHITECTURE_DOCS.md

  qa:
    primary:
      - agents/QA_ROLE.md
      - testing/TESTING_POLICY.md
    secondary:
      - testing/INTEGRATION_TESTING.md
      - testing/COVERAGE_STANDARDS.md

  debug:
    primary:
      - agents/DEBUG_ROLE.md
      - patterns/ERROR_RECOVERY.md
    secondary:
      - testing/MOCKING_STRATEGIES.md
```

---

## Risks & Considerations

### Technical Risks

**Context Bloat:**
- Rules are 43K+ lines, can't load everything
- *Mitigation:* Load only relevant domains, create condensed versions

**Symlink Issues:**
- Symlinks may not work on all systems (Windows)
- *Mitigation:* Provide copy fallback, document requirements

**Rule Staleness:**
- Rules may become outdated
- *Mitigation:* Version tracking, update mechanism

### UX Risks

**Configuration Complexity:**
- Too many options can confuse users
- *Mitigation:* Smart defaults, "just works" mode

**Discovery:**
- Users may not know rules exist
- *Mitigation:* Prominent documentation, examples

### Scope Risks

**Over-Engineering:**
- Easy to add too many features
- *Mitigation:* Start with Phase 1-2, iterate

---

## Success Metrics

### Phase 1 Success (Quick Integration)
- [ ] Rules accessible from Czarina
- [ ] Documentation references rules
- [ ] Users can manually reference rules

### Phase 2 Success (Project Integration)
- [ ] `czarina init --with-rules` works
- [ ] Projects have rules available
- [ ] Worker identities mention rules

### Phase 3 Success (Automatic Loading)
- [ ] Workers automatically load relevant rules
- [ ] Context size stays manageable (<20KB)
- [ ] Workers demonstrate better quality

### Overall Success Indicators
- Workers produce fewer errors
- Code quality improves measurably
- Users report reduced friction
- Orchestrations complete faster

---

## Implementation Timeline

### Week 1: Quick Integration
- Day 1: Symlink + documentation (Phase 1)
- Day 2: Project integration flag (Phase 2 start)
- Day 3: Worker identity updates (Phase 2 complete)

### Week 2: Automatic Loading
- Day 1-2: Role mapping + loader (Phase 3 start)
- Day 3: Condensed versions
- Day 4: Testing + refinement (Phase 3 complete)

### Week 3: Templates & Polish
- Day 1-2: Worker creation command (Phase 4)
- Day 3: Documentation + examples
- Day 4: Integration testing + release prep

**Total:** 12-15 days for complete implementation

---

## Acceptance Criteria

- [ ] Agent rules library symlinked or accessible
- [ ] `czarina init --with-rules` functional
- [ ] Worker config supports rules configuration
- [ ] Automatic rule loading based on role
- [ ] Condensed quick-reference guides created
- [ ] `czarina create-worker` command working
- [ ] Tested with real multi-worker orchestration
- [ ] Documentation complete
- [ ] Examples provided
- [ ] AGENT_RULES.md guide written

---

## Related Enhancements

### Complements
- **Memory System:** Rules + memories = complete knowledge
- **Phase Management:** Rules guide phase planning
- **Quality Metrics:** Rules define quality standards

### Enables
- **Higher autonomy:** Workers self-guided by rules
- **Better consistency:** All workers follow same standards
- **Faster onboarding:** New workers have built-in expertise

---

## Quick Start Example

After implementation:

```bash
# Create new project with rules
czarina init my-project --with-rules

# Create workers from templates
czarina create-worker backend --role code
czarina create-worker architect --role architect
czarina create-worker qa --role qa

# Launch - workers automatically get relevant rules
czarina launch

# Backend worker sees:
# - CODE_ROLE.md (how to code)
# - CODING_STANDARDS.md (Python standards)
# - TESTING_PATTERNS.md (testing requirements)

# Architect worker sees:
# - ARCHITECT_ROLE.md (planning methodology)
# - TOOL_USE_PATTERNS.md (design patterns)
# - ARCHITECTURE_DOCS.md (documentation standards)

# Result: High-quality, consistent work across all workers!
```

---

## References

- **Agent Rules Library:** `../agent-rules/`
- **Orchestration Closeout:** `../agent-rules/CZARINA_ORCHESTRATION_CLOSEOUT.md`
- **Rules Index:** `../agent-rules/agent-rules/INDEX.md`
- **Memory System:** `enhancement-memory-architecture.md` (synergy!)

---

**Status:** Ready for implementation
**Next Step:** Phase 1 (Quick Integration - 1 day)
**Owner:** TBD
**Synergy:** Combine with memory system for maximum impact
