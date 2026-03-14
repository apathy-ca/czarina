# Czarina Project Analysis Template

**Purpose:** AI-driven analysis of implementation plans to generate optimal orchestration setup.

---

## Analysis Instructions

You are analyzing an implementation plan to recommend optimal Czarina orchestration using **version-based planning with token metrics** (NOT time-based).

### CRITICAL RULES

**❌ NEVER:**
- Use time estimates (weeks, days, sprints, quarters)
- Use calendar dates
- Use sprint numbers
- Reference time-based milestones

**✅ ALWAYS:**
- Use semantic versions (v0.1.0, v0.2.0, v1.0.0)
- Use phases for large features (v0.2.1-phase1, v0.2.1-phase2)
- Use token budgets (projected and recorded)
- Calculate efficiency ratios

---

## Input Plan

```
{PLAN_CONTENT}
```

---

## Analysis Framework

### 1. PROJECT OVERVIEW

**Analyze and extract:**

```json
{
  "project_name": "<extracted from plan>",
  "project_type": "<web app|API|library|CLI tool|mobile app|etc>",
  "complexity": "<simple|medium|medium-high|high|very complex>",
  "tech_stack": {
    "backend": ["<technologies>"],
    "frontend": ["<technologies>"],
    "database": ["<technologies>"],
    "infrastructure": ["<technologies>"]
  },
  "estimated_total_tokens": "<sum of all features>"
}
```

**Complexity factors:**
- Simple: Single component, < 500K tokens
- Medium: 2-3 components, 500K-1M tokens
- Medium-High: 3-5 components, 1M-2M tokens
- High: 5-10 components, 2M-4M tokens
- Very Complex: 10+ components, > 4M tokens

---

### 2. FEATURE BREAKDOWN

For each major feature in the plan:

```json
{
  "feature": "<feature name>",
  "description": "<brief description>",
  "complexity": "<simple|medium|high>",
  "tokens_estimated": <number>,
  "dependencies": ["<other features this depends on>"],
  "workers_suggested": ["<worker IDs>"],
  "version_suggested": "<v0.X.Y or v0.X.Y-phaseN>",
  "completion_criteria": ["<specific deliverables>"]
}
```

**Token estimation guidelines:**
- Simple feature: 10K-30K tokens
  - Single file changes
  - Configuration updates
  - Simple bug fixes

- Medium feature: 30K-100K tokens
  - New component
  - API endpoint with tests
  - UI screen with state

- High feature: 100K-300K tokens
  - Architecture changes
  - Multi-component integration
  - Complex algorithms

- Very high feature: 300K-500K tokens (requires phases)
  - Real-time systems
  - Authentication systems
  - Major refactors

**Complexity multipliers:**
- Testing: 1.2x (unit + integration tests)
- Documentation: 1.1x (API docs, guides)
- Integration: 1.3x (connecting multiple systems)
- Refactoring: 1.5x-3x (legacy code complexity)
- Real-time: 1.4x (WebSocket, streaming)
- Security: 1.3x (authentication, authorization)

---

### 3. VERSION PLANNING

Create versions following semantic versioning + phases:

```json
{
  "version": "v0.X.Y[-phaseN]",
  "description": "<what this version delivers>",
  "features_included": ["<feature names>"],
  "token_budget": {
    "projected": <total tokens for version>
  },
  "workers_assigned": ["<worker IDs>"],
  "dependencies": ["<previous versions required>"],
  "completion_criteria": [
    "<specific deliverable>",
    "<test coverage target>",
    "<documentation requirement>"
  ]
}
```

**Version progression rules:**
- v0.1.0: Foundation and architecture (1 architect, 100K-250K tokens)
- v0.2.0+: Major feature sets (2-4 workers, 200K-500K tokens)
- v0.X.Y-phase1, phase2: Large features split into phases (< 500K tokens each)
- v1.0.0: Production ready (testing, hardening, docs, 200K-400K tokens)

**When to use phases:**
- Feature estimate > 300K tokens → Split into phases
- Multiple integration points → One phase per integration
- Sequential dependencies → Phase for each dependency
- Testing requires stages → Phase for each test stage

**Phase naming:**
```
v0.2.1-phase1   First part of large feature
v0.2.1-phase2   Second part
v0.2.1-phase3   Third part (if needed)
v0.3.0          Integration of all phases
```

---

### 4. WORKER ALLOCATION

Recommend workers based on:

**Worker types by role:**
- **Architect**: System design, high-level architecture
  - Best agent: opencode (better at big picture)
  - Token budget: 100K-300K per architecture phase

- **Backend Developer**: APIs, services, business logic
  - Best agent: opencode (comprehensive understanding)
  - Token budget: 150K-400K per version

- **Frontend Developer**: UI components, state management
  - Best agent: opencode (excellent at UI/UX)
  - Token budget: 120K-350K per version

- **Full-Stack Developer**: Both backend and frontend
  - Best agent: opencode (handles full stack well)
  - Token budget: 200K-500K per version

- **QA Engineer**: Testing, quality assurance
  - Best agent: opencode (good at test automation)
  - Token budget: 100K-250K per version

- **DevOps Engineer**: CI/CD, infrastructure
  - Best agent: opencode (shell scripting & config)
  - Token budget: 80K-200K per version

- **Documentation Writer**: Technical writing
  - Best agent: opencode (better prose)
  - Token budget: 50K-150K per version

**Worker count guidelines:**
- Simple project (< 500K): 1-2 workers
- Medium project (500K-1M): 2-4 workers
- Medium-High (1M-2M): 4-7 workers
- High (2M-4M): 7-12 workers
- Very Complex (> 4M): 12-20 workers

**For each worker:**
```json
{
  "id": "<descriptive-id>",
  "role": "<role type>",
  "agent": "opencode",
  "description": "<clear role description>",
  "versions_assigned": ["v0.X.Y", "v0.X.Y-phaseN"],
  "total_token_budget": <sum across versions>,
  "rationale": "<why this worker and agent?>"
}
```

---

### 5. GENERATED WORKER PROMPTS

For each worker, generate a complete prompt file:

```markdown
# {Worker Role Title}

## Role
{Clear description of this worker's role}

## Version Assignments
{List of versions this worker participates in}

## Responsibilities

### v{X.Y.Z}[-phaseN] ({Description} - {Projected Tokens}K tokens)
- {Specific responsibility 1}
- {Specific responsibility 2}
- {Specific responsibility 3}

### v{Next Version} ({Description} - {Projected Tokens}K tokens)
- {Specific responsibility 1}
- {Specific responsibility 2}

## Files
- {Directory or file patterns this worker should focus on}

## Tech Stack
- {Technologies this worker will use}

## Token Budget
Total: {Total}K tokens
- v{X.Y.Z}: {Amount}K tokens
- v{Next}: {Amount}K tokens

## Git Workflow
Branches by version:
- v{X.Y.Z}: feat/v{X.Y.Z}-{worker-id}
- v{Next}: feat/v{Next}-{worker-id}

When complete:
1. Commit changes
2. Push to branch
3. Create PR to main
4. Update token metrics in status

## Pattern Library
Review before starting:
- czarina-core/patterns/ERROR_RECOVERY_PATTERNS.md
- czarina-core/patterns/CZARINA_PATTERNS.md

## Version Completion Criteria

### v{X.Y.Z} Complete When:
- [ ] {Deliverable 1}
- [ ] {Deliverable 2}
- [ ] {Test coverage target}
- [ ] Token budget: ≤ {110% of projected}K

### v{Next} Complete When:
- [ ] {Deliverable 1}
- [ ] {Deliverable 2}
- [ ] {Test coverage target}
- [ ] Token budget: ≤ {110% of projected}K
```

---

## Output Format

Generate complete JSON following this schema:

```json
{
  "analysis": {
    "project_name": "string",
    "project_type": "string",
    "complexity": "simple|medium|medium-high|high|very complex",
    "tech_stack": {
      "backend": ["string"],
      "frontend": ["string"],
      "database": ["string"],
      "infrastructure": ["string"]
    },
    "total_tokens_projected": number,
    "recommended_workers": number,
    "recommended_versions": number,
    "efficiency_factors": {
      "description_of_factor": number (1.0 = baseline, > 1.0 = additional complexity)
    }
  },

  "feature_analysis": [
    {
      "feature": "string",
      "description": "string",
      "complexity": "simple|medium|high",
      "tokens_estimated": number,
      "dependencies": ["string"],
      "workers_suggested": ["string"],
      "version_suggested": "vX.Y.Z[-phaseN]",
      "completion_criteria": ["string"]
    }
  ],

  "version_plan": [
    {
      "version": "vX.Y.Z[-phaseN]",
      "description": "string",
      "features_included": ["string"],
      "token_budget": {
        "projected": number
      },
      "workers_assigned": ["string"],
      "dependencies": ["string"],
      "completion_criteria": ["string"]
    }
  ],

  "worker_recommendations": [
    {
      "id": "string",
      "role": "string",
      "agent": "opencode",
      "description": "string",
      "versions_assigned": ["vX.Y.Z"],
      "total_token_budget": number,
      "rationale": "string"
    }
  ],

  "generated_prompts": {
    "worker-id": "string (full markdown prompt content)"
  },

  "analysis_metadata": {
    "analyzed_at": "ISO 8601 timestamp",
    "analyzer_version": "string",
    "input_file": "string",
    "analysis_tokens_used": number
  }
}
```

---

## Validation Checklist

Before returning analysis, verify:

- [ ] NO time-based estimates anywhere (weeks, days, sprints)
- [ ] All versions use semantic versioning + phases
- [ ] Phases used for features > 300K tokens
- [ ] Token budgets for all versions and workers
- [ ] Worker count appropriate for project size
- [ ] Agent selection rationale provided
- [ ] Worker prompts are complete and actionable
- [ ] Dependencies between versions identified
- [ ] Completion criteria are specific and measurable
- [ ] Total token budget is reasonable for project complexity

---

## Example Analysis Output

See: czarina-inbox/features/2025-11-30-project-analysis.md

for complete example with all generated artifacts.

---

**Version:** 1.0
**Last Updated:** 2025-11-30
**Usage:** `czarina analyze <plan-file>`
