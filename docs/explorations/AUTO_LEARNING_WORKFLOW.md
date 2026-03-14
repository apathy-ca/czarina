# Automatic Learning Workflow

## Problem Statement

Learning happens during work but rarely gets captured. Manual capture (`/hopper add`) is too much friction. Knowledge repositories (like agent-knowledge) go stale because the feedback loop requires human effort at every step.

**Current state**: Learnings die in the session where they occur.

**Desired state**: Learnings flow automatically from work → capture → distillation → upstream knowledge.

## Design Goals

1. **Zero-friction capture** - Agents capture learnings as a side effect of working
2. **Automatic novelty detection** - Agents recognize when they encounter/use something not in their knowledge sources
3. **Batched distillation** - Periodic synthesis of accumulated learnings into structured knowledge
4. **Multi-layer northbound** - Learnings route to appropriate upstream (personal, team, community)
5. **Human-in-the-loop at approval only** - Not at capture, not at tagging, not at distillation
6. **Cross-agent compatibility** - Works with any agent that can read AGENTS.md and run CLI commands

## Standards Alignment

This design builds on emerging standards:

| Standard | Purpose | Our Usage |
|----------|---------|-----------|
| **AGENTS.md** | Cross-agent project guidance (Linux Foundation AAIF) | Points agents to hopper, declares knowledge sources |
| **MCP** | Tool/data access protocol | Future: hopper-server for webchat agents |
| **Skills** | Portable markdown instructions | How agents learn to use hopper |

AGENTS.md is now adopted by 60k+ repos and supported by Cursor, Copilot, Codex, Claude, Gemini CLI, and others.

## Agent Integration Paths

Two paths to reach agents where they are:

```
┌─────────────────────────────────────────────────────────────────┐
│                      AGENTIC (CLI-capable)                      │
│                                                                 │
│   Cursor, Claude Code, Codex, Gemini CLI, czarina workers      │
│                            │                                    │
│                            ▼                                    │
│                    AGENTS.md + skills                           │
│                            │                                    │
│                            ▼                                    │
│                       hopper CLI                                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      WEBCHAT (sandboxed)                        │
│                                                                 │
│            Claude.ai, ChatGPT, Gemini web, etc.                │
│                            │                                    │
│                            ▼                                    │
│                      MCP protocol                               │
│                            │                                    │
│                            ▼                                    │
│                     hopper-server                               │
│                      (future work)                              │
└─────────────────────────────────────────────────────────────────┘
```

Both paths write to the same hopper storage. Learnings converge regardless of agent type.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        WORK PHASE                               │
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Worker 1   │    │   Worker 2   │    │   Worker N   │      │
│  │  (czarina)   │    │  (czarina)   │    │  (claude)    │      │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘      │
│         │                   │                   │               │
│         └───────────────────┼───────────────────┘               │
│                             │                                   │
│                             ▼                                   │
│                   ┌──────────────────┐                          │
│                   │  Novelty Filter  │                          │
│                   │  (diff against   │                          │
│                   │  knowledge srcs) │                          │
│                   └────────┬─────────┘                          │
│                            │                                    │
│                            ▼                                    │
│                   ┌──────────────────┐                          │
│                   │     Hopper       │                          │
│                   │  #auto-learned   │                          │
│                   └──────────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
                             │
                             │ accumulates
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     DISTILLATION PHASE                          │
│                      (periodic/triggered)                       │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  Distillation Agent                       │   │
│  │                                                           │   │
│  │  1. Read accumulated #auto-learned items                  │   │
│  │  2. Cluster related learnings                             │   │
│  │  3. Identify patterns and themes                          │   │
│  │  4. Synthesize into knowledge updates                     │   │
│  │  5. Determine target upstream (personal/team/community)   │   │
│  │  6. Generate draft PRs or knowledge patches               │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                             │
                             │ distilled knowledge
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      UPSTREAM PHASE                             │
│                                                                 │
│    ┌─────────────┐   ┌─────────────┐   ┌─────────────┐         │
│    │  personal   │   │    team     │   │  community  │         │
│    │  knowledge  │   │  knowledge  │   │ (agent-     │         │
│    │             │   │             │   │  knowledge) │         │
│    └─────────────┘   └─────────────┘   └─────────────┘         │
│           │                │                  │                 │
│           ▼                ▼                  ▼                 │
│       auto-merge      team review       community PR            │
│       (high conf)     (async)           (human approval)        │
└─────────────────────────────────────────────────────────────────┘
```

## Knowledge Source Hierarchy

Projects declare which knowledge sources they use:

```yaml
# .hopper/knowledge.yaml
sources:
  - name: agent-knowledge
    repo: apathy-ca/agent-knowledge
    path: patterns/

  - name: team-standards
    repo: myorg/engineering-standards
    path: ai-patterns/

  - name: personal
    path: ~/.config/knowledge/

northbound:
  default: personal
  rules:
    - pattern: "team-*"
      target: team-standards
    - pattern: "upstream-*"
      target: agent-knowledge
    - confidence: ">0.9"
      target: personal
      auto_merge: true
```

## Novelty Detection

Agent recognizes something is novel when:

1. **Unknown tool/pattern** - Using something not documented in loaded knowledge
2. **New solution** - Solving a problem in a way not covered by patterns
3. **Correction** - Knowledge says X, but Y actually works better
4. **Gap** - Knowledge is silent on something that should be documented

### Detection via AGENTS.md (Cross-Agent)

```markdown
# AGENTS.md (root of project)

## Memory & Learnings

This project uses [Hopper](https://github.com/apathy-ca/hopper) for persistent memory.

### On Session Start
$ hopper context

### During Work
When you encounter or use something novel (new pattern, unexpected solution,
correction to known approach), capture it:
$ hopper add "LEARNING: <description>" --tag auto-learned

### On Significant Completion
Assess what you learned and capture before ending:
$ hopper add "LEARNED: <what>" --tag auto-learned
```

This works with any agent that reads AGENTS.md: Claude Code, Cursor, Copilot, Codex, Gemini CLI, etc.

### Detection Hook (Czarina Workers)

```bash
# In worker completion hook
czarina worker on-complete:
  - extract: "patterns used, tools invoked, problems solved"
  - diff: against loaded knowledge sources
  - if novel:
      hopper add --auto --tag auto-learned "$LEARNING"
```

### Portable Skill (skills/hopper.md)

```markdown
# Hopper - Persistent Memory

## Capture Learning
When you discover something worth remembering:
$ hopper add "LEARNING: <description>" --tag auto-learned

## Check Context
Before starting work:
$ hopper context

## List Recent
$ hopper ls --limit 10
```

Any agent can read this skill file and follow the instructions.

## Distillation Agent

Runs periodically (daily? weekly? on-demand?) to process accumulated learnings.

### Input
- All Hopper items tagged `#auto-learned` since last run
- Current knowledge sources for context

### Process
1. **Cluster** - Group related learnings by topic/domain
2. **Deduplicate** - Merge similar learnings
3. **Validate** - Check learnings against each other for conflicts
4. **Synthesize** - Write coherent knowledge updates
5. **Route** - Determine which upstream each update targets
6. **Format** - Generate appropriate output (PR, patch, direct merge)

### Output
- Draft PRs for community upstream
- Merge-ready patches for team upstream
- Auto-merged updates for personal upstream (if confidence high)

## Implementation Phases

### Phase 1: Manual Trigger, Auto-Capture
- Add novelty detection prompts to czarina worker instructions
- Workers write to hopper with `#auto-learned` tag
- `czarina learnings distill` command runs distillation manually

### Phase 2: Worker Hooks
- Czarina worker completion hook runs novelty detection
- Automatic capture without worker needing to remember
- Distillation still manual

### Phase 3: Scheduled Distillation
- Periodic distillation runs (cron, or on `czarina phase close`)
- Generates draft upstream updates
- Human reviews batched output

### Phase 4: Confidence-Based Auto-Merge
- High-confidence personal learnings auto-merge
- Team learnings queue for async review
- Community learnings generate PRs

## Open Questions

1. **How to bootstrap knowledge sources?** First run has nothing to diff against.
2. **How to handle conflicting learnings?** Worker A says X, Worker B says not-X.
3. **What's the right distillation frequency?** Too often = noise, too rare = drift.
4. **How to measure learning quality?** Avoid accumulating garbage.
5. **How to handle sensitive/proprietary learnings?** Not everything should northbound.

## Success Criteria

- Learnings captured without explicit human action during work
- agent-knowledge (or equivalent) stays current with actual usage patterns
- Time from "learn something" to "available everywhere" < 1 week
- Human effort: review/approve only, not capture/write/organize

## Related

- [HOPPER.md](../HOPPER.md) - Hopper integration docs
- [czarina learnings](../guides/) - Current learnings commands
- [AGENTS.md spec](https://agents.md/) - Cross-agent project guidance standard
- [Agentic AI Foundation](https://aaif.io/) - Linux Foundation home for MCP, AGENTS.md, goose
- agent-knowledge repo - Target upstream for community patterns

## Testing

To validate this workflow:

1. **Basic capture test**: Agent reads AGENTS.md, performs work, captures learning
2. **Cross-agent test**: Same project, different agents (Claude Code, Cursor), learnings converge
3. **Distillation test**: Accumulated learnings synthesize into coherent knowledge update
4. **Northbound test**: Distilled knowledge routes to correct upstream
