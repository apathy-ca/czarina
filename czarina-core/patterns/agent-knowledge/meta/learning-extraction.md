# Learning Extraction Process

This document describes how learnings from active development become patterns in the Agent Knowledge repository.

## Overview

The Agent Knowledge repository grows through continuous learning extraction from:
- **Hopper** - Task routing and execution learnings
- **Czarina** - Worker coordination and phase management learnings
- **The Symposium** - Multi-agent collaboration learnings
- **SARK** - Security and compliance learnings

This creates a **continuous improvement flywheel**: each project makes the knowledge base better, which makes future projects more effective.

## Learning Sources

### Czarina Closeout Learnings

When a Czarina phase closes, workers document:
- What worked well
- What didn't work
- What would I do differently
- What patterns emerged

**Location:** `.czarina/learnings/phase-{N}-closeout.json`

**Export trigger:** Worker completion or phase closeout

**Content:**
- Worker observations from actual implementation
- Time and effort metrics
- Files modified and patterns used
- Recommendations for future phases

### Hopper Task Feedback

When Hopper completes tasks, it captures:
- Routing decisions (which agent handled what)
- Task success/failure patterns
- Tool usage patterns
- Time and efficiency metrics

**Location:** `.hopper/feedback/task-{ID}.json`

**Export trigger:** Task completion

**Content:**
- Which agent was selected and why
- Tool usage patterns
- Success/failure indicators
- Retry patterns and recovery strategies

### Symposium Sage Wisdom

The Symposium's Sage agent observes:
- Agent interaction patterns
- Collaboration success factors
- Communication patterns
- Knowledge sharing effectiveness

**Location:** `.symposium/sage/wisdom-{session-ID}.json`

**Export trigger:** Session completion or periodic snapshots

**Content:**
- Multi-agent collaboration patterns
- Communication effectiveness
- Knowledge sharing patterns
- Conflict resolution strategies

### SARK Security Learnings

SARK captures:
- Security pattern effectiveness
- Compliance validation patterns
- Audit trail patterns

**Location:** `.sark/learnings/security-{ID}.json`

**Export trigger:** Security validation completion

**Content:**
- Security patterns that worked
- Compliance issues found and resolved
- Audit trail patterns
- Security best practices validated

## Extraction Workflow

### 1. Learning Collection

#### Automatic Collection

**Process:**
1. System completes work (task, phase, session, validation)
2. System exports learnings to JSON file
3. JSON sent to Symposium Learnings Processor
4. Processor queues for analysis

**Systems with automatic export:**
- Czarina (phase closeout)
- Hopper (task completion)
- The Symposium (Sage observations)
- SARK (security validations)

#### Manual Collection

**Process:**
1. Developer identifies valuable pattern during work
2. Developer creates pattern using template
3. Developer fills in all sections with evidence
4. Developer submits PR directly to agent-knowledge

**When to use manual:**
- Pattern discovered outside automated systems
- One-off insight from debugging or research
- Pattern observed across multiple projects
- Community contribution

### 2. Learning Analysis

**Symposium Learnings Processor workflow:**

1. **Receive** learning JSON from queue
2. **Parse** structured data and extract key information
3. **Analyze** with LLM (Claude) to identify potential patterns
4. **Evaluate** against quality criteria:
   - **Generalizability** - Applies beyond one specific case?
   - **Actionability** - Clear, implementable steps?
   - **Evidence** - Backed by real data and outcomes?
   - **Impact** - Measurable or qualitative improvement?
5. **Filter** out low-quality or non-generalizable learnings
6. **Propose** pattern if all criteria met

**Quality thresholds:**
- Must be generalizable to at least 2-3 different contexts
- Must have clear before/after or success metrics
- Must include specific implementation steps
- Must not conflict with existing patterns

### 3. Pattern Proposal

**If pattern identified:**

1. **Generate** pattern document using template (meta/pattern-template.md)
2. **Fill** all required sections:
   - Problem, context, solution
   - Real-world examples with code
   - Evidence from source learning
   - Impact metrics (quantified or qualitative)
3. **Create** PR to agent-knowledge repository
4. **Tag** for human review with `auto-generated` label
5. **Include** source learning JSON as evidence

**PR description format:**
```markdown
## Auto-Generated Pattern Proposal

**Source:** [Czarina Phase 3 / Hopper Task T-123 / Symposium Session S-456]
**Category:** [Error Recovery / Tool Use / etc.]
**Confidence:** [High / Medium / Low]

### Summary
[1-2 sentence summary of the pattern]

### Evidence
- Project: [project name]
- Context: [what was being built]
- Result: [what happened]
- Impact: [quantified or qualitative]

### Source Learning
[Link to or inline JSON of source learning]

### Review Checklist
- [ ] Generalizable beyond source context
- [ ] Actionable steps provided
- [ ] Evidence sufficient
- [ ] Impact documented
- [ ] No conflicts with existing patterns
```

### 4. Human Review

**Reviewer responsibilities:**

**Check generalizability:**
- Can this apply to other projects/contexts?
- Is it specific to one edge case?
- Does it represent a reusable strategy?

**Check actionability:**
- Are steps clear and specific?
- Can someone else implement this?
- Are examples helpful and realistic?

**Check evidence:**
- Is there proof this works?
- What project(s) validated this?
- Are metrics credible?

**Check impact:**
- Is impact documented?
- Are metrics realistic?
- Is qualitative impact meaningful?

**Check compatibility:**
- Conflicts with existing patterns?
- Complements or enhances existing knowledge?
- Fits in appropriate category?

**Review checklist:**
- [ ] Pattern is generalizable
- [ ] Pattern is actionable
- [ ] Evidence is sufficient
- [ ] Impact is documented
- [ ] Doesn't conflict with existing patterns
- [ ] Documentation is clear
- [ ] All template sections complete
- [ ] Proper category placement
- [ ] Cross-references added

**Possible outcomes:**
- **Approve** - Merge as-is
- **Request changes** - Needs improvements (more evidence, clearer steps, etc.)
- **Reject** - Not generalizable, conflicts, or insufficient evidence

### 5. Integration

**If approved:**

1. **Merge** pattern to appropriate category directory
2. **Update** patterns/INDEX.md to include new pattern
3. **Add** cross-references to related patterns and core rules
4. **Update** CHANGELOG.md in `[Unreleased]` section
5. **Bump** version (minor for new pattern)
6. **Notify** contributing system (Czarina/Hopper/Symposium/SARK)

**Post-merge:**
- Pattern becomes available to all systems
- Pattern appears in pattern index
- Pattern can be referenced in future learnings
- Pattern contributes to knowledge base growth

## Learning JSON Formats

### Czarina Closeout Learning

```json
{
  "source": "czarina",
  "project": "agent-knowledge-merge",
  "phase": "1",
  "worker_id": "harmonize-content",
  "timestamp": "2025-01-15T10:30:00Z",
  "learnings": {
    "what_worked": [
      "Cross-reference strategy was effective",
      "Clear separation between core-rules and patterns"
    ],
    "what_didnt_work": [
      "Initial link validation was manual and tedious"
    ],
    "would_do_differently": [
      "Automate link validation from the start"
    ],
    "patterns_observed": [
      "Separating 'what' (core-rules) from 'how' (patterns) improves navigation"
    ]
  },
  "metrics": {
    "time_spent_hours": 4,
    "files_modified": 23,
    "links_created": 47
  }
}
```

### Hopper Task Feedback

```json
{
  "source": "hopper",
  "task_id": "T-123",
  "timestamp": "2025-01-15T14:20:00Z",
  "routing": {
    "agent": "code",
    "confidence": 0.95,
    "reasoning": "Implementation task with clear requirements"
  },
  "execution": {
    "success": true,
    "duration_seconds": 180,
    "tools_used": ["read", "edit", "bash"],
    "retries": 0
  },
  "learnings": {
    "pattern": "Parallel file edits in single transaction reduce context overhead",
    "impact": "40% reduction in task completion time",
    "evidence": {
      "before": "Sequential edits took 300s average",
      "after": "Parallel edits took 180s average"
    }
  }
}
```

### Symposium Sage Wisdom

```json
{
  "source": "symposium",
  "session_id": "S-456",
  "timestamp": "2025-01-15T16:45:00Z",
  "participants": ["architect", "code", "qa"],
  "observation": {
    "pattern_name": "Architect-first design prevents rework",
    "description": "When architect agent designs before code agent implements, rework is reduced",
    "context": "Building authentication system",
    "evidence": {
      "sessions_with_architect_first": 5,
      "rework_rate": "10%",
      "sessions_without_architect": 3,
      "rework_rate_no_arch": "45%"
    },
    "impact": "35% reduction in rework when architect designs first"
  }
}
```

### SARK Security Learning

```json
{
  "source": "sark",
  "validation_id": "V-789",
  "timestamp": "2025-01-15T18:30:00Z",
  "security_pattern": {
    "name": "Input validation at API boundaries",
    "description": "Validating all inputs at API layer prevents downstream vulnerabilities",
    "context": "REST API endpoint validation",
    "evidence": {
      "vulnerabilities_found": 0,
      "endpoints_validated": 12,
      "validation_time_ms": 5
    },
    "impact": "Zero injection vulnerabilities, minimal performance overhead"
  }
}
```

## Pattern Maturity Levels

### Proposed

**Definition:** New pattern, not yet battle-tested

**Requirements:**
- Evidence from at least one project
- Complete template
- Human review pending

**Metadata:** `Status: Proposed`

**Lifecycle:** Remains proposed until validated in additional contexts

### Accepted

**Definition:** Reviewed and approved, has evidence from at least one project

**Requirements:**
- Human review completed and approved
- Evidence from at least one real project
- Impact documented
- Merged to main repository

**Metadata:** `Status: Accepted`

**Lifecycle:** Default status for newly merged patterns

### Proven

**Definition:** Used successfully in multiple projects, quantified impact available

**Requirements:**
- Used in 3+ different projects or contexts
- Quantified impact metrics from multiple sources
- Consistently positive outcomes
- Recommended for general use

**Metadata:** `Status: Proven`

**Lifecycle:** Elevated from Accepted after validation in multiple projects

### Deprecated

**Definition:** Superseded by better pattern, no longer recommended

**Requirements:**
- Replacement pattern identified
- Migration path documented
- Kept for historical reference

**Metadata:** `Status: Deprecated`

**Lifecycle:** Marked when better alternative emerges, removed in next major version

## Quality Standards

### Pattern Must Have

- [ ] Clear problem statement
- [ ] Step-by-step solution
- [ ] At least one real-world example
- [ ] Evidence from actual usage
- [ ] Impact statement (quantified or qualitative)

### Pattern Should Have

- [ ] Multiple examples from different contexts
- [ ] Quantified impact metrics
- [ ] Trade-offs documented
- [ ] Alternatives discussed
- [ ] Related patterns and core rules linked

### Pattern Quality Score

**High quality (90-100%):**
- Multiple real-world examples
- Quantified impact from multiple projects
- Comprehensive trade-off analysis
- All template sections complete

**Good quality (70-89%):**
- At least one detailed example
- Impact documented (quantified or qualitative)
- Trade-offs discussed
- Most template sections complete

**Acceptable quality (50-69%):**
- Basic example provided
- Evidence from one project
- Impact stated
- Required sections complete

**Below threshold (<50%):**
- Insufficient evidence
- Vague or theoretical
- Missing key sections
- Needs revision before acceptance

## Contribution Workflow

### For Automatic Submissions (via Learnings Processor)

```
System completes work
       ↓
Export learning JSON
       ↓
Send to Learnings Processor
       ↓
LLM analyzes for patterns
       ↓
Generate pattern proposal
       ↓
Create PR (auto-generated)
       ↓
Human review
       ↓
[Approved] → Merge
[Changes needed] → Revise
[Rejected] → Close with feedback
```

### For Manual Submissions

```
Developer identifies pattern
       ↓
Use pattern template
       ↓
Fill all sections with evidence
       ↓
Create PR manually
       ↓
Human review
       ↓
[Approved] → Merge
[Changes needed] → Revise
[Rejected] → Close with feedback
```

## Review Checklist

When reviewing a pattern submission:

**Generalizability:**
- [ ] Applies beyond one specific case
- [ ] Can be used in different contexts
- [ ] Not tied to specific implementation details

**Actionability:**
- [ ] Clear, implementable steps
- [ ] Sufficient detail to reproduce
- [ ] Examples are realistic and helpful

**Evidence:**
- [ ] Backed by real usage data
- [ ] Source project identified
- [ ] Outcomes documented

**Impact:**
- [ ] Measurable improvement (quantified or qualitative)
- [ ] Impact is credible and realistic
- [ ] Benefits outweigh costs/complexity

**Clarity:**
- [ ] Well-documented and understandable
- [ ] Examples enhance understanding
- [ ] No ambiguity in key sections

**Completeness:**
- [ ] All required template sections filled
- [ ] Related patterns identified
- [ ] Related core rules linked

**Compatibility:**
- [ ] Doesn't contradict existing patterns
- [ ] Fits in appropriate category
- [ ] Complements existing knowledge

## Continuous Improvement Cycle

```
Development Work
       ↓
Learnings Captured (Czarina, Hopper, Symposium, SARK)
       ↓
Exported to JSON
       ↓
Learnings Processor Analyzes (LLM)
       ↓
Pattern Proposed (if criteria met)
       ↓
Human Review (quality check)
       ↓
Merged to Knowledge Base (if approved)
       ↓
Used in Future Development (Hopper, Czarina, Symposium, SARK)
       ↓
(cycle repeats with new learnings)
```

### Flywheel Effect

Each iteration of the cycle:
1. **Captures** real learnings from actual work
2. **Validates** patterns through LLM analysis
3. **Curates** via human review
4. **Integrates** into knowledge base
5. **Applies** in next projects
6. **Generates** new learnings from improved practices

This creates exponential improvement over time.

## Metrics and Success Indicators

### Knowledge Base Growth
- Patterns added per month
- Pattern maturity progression (Proposed → Accepted → Proven)
- Coverage across categories

### Pattern Quality
- Acceptance rate of proposed patterns
- Time from proposal to acceptance
- Revision cycles per pattern

### Impact
- Pattern usage in projects
- Quantified impact metrics aggregated
- Developer satisfaction with patterns

### System Health
- Learning export rate
- Processor throughput
- Review turnaround time

## Future Enhancements

**Planned improvements:**
- Automated pattern similarity detection
- Pattern recommendation engine
- Impact tracking across projects
- Pattern versioning and evolution tracking
- Community voting on pattern quality

**Long-term vision:**
- Self-improving knowledge base
- Predictive pattern suggestion
- Automated cross-reference generation
- Pattern conflict detection
- Real-time learning integration

## Questions and Support

**For questions about:**
- Learning extraction process → Open issue with `learning-extraction` label
- Pattern submission → See [CONTRIBUTING.md](../CONTRIBUTING.md)
- Review process → Tag `@reviewers` in PR
- Technical issues → Open issue with `bug` label

Thank you for contributing to the continuous improvement of the Agent Knowledge repository!
