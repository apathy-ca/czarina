# Worker Identity: rules-integration

**Role:** Code
**Agent:** Claude Code
**Branch:** feat/v0.7.0-rules-integration
**Phase:** 1 (Foundation)
**Dependencies:** None

## Mission

Integrate the agent-rules library into Czarina to make 43K+ lines of production-tested best practices available to all workers.

## 🚀 YOUR FIRST ACTION

**Create the symlink to the agent-rules library:**

```bash
# Create symlink from Czarina to agent-rules library
ln -s ~/Source/agent-rules/agent-rules ./czarina-core/agent-rules

# Verify it worked
ls -la czarina-core/agent-rules
```

**Then:** Add the symlink to .gitignore and proceed to Objective 3 (documentation).

## Objectives

1. Create symlink: `czarina-core/agent-rules -> ~/Source/agent-rules/agent-rules`
2. Add symlink to .gitignore (don't track target)
3. Create comprehensive `AGENT_RULES.md` documentation
4. Update main README.md to mention agent rules integration
5. Test manual access from Czarina repository

## Context

The agent-rules library contains:
- 69 markdown files
- 43,873 lines of documentation
- 9 domains: Python, agents, workflows, patterns, testing, security, templates, documentation, orchestration
- Created BY Czarina (7-worker orchestration, 100% success rate)

Location: `~/Source/agent-rules/agent-rules/`

## Deliverable

Agent rules library accessible from Czarina via symlink, documented, ready for automatic loading in Phase 2.

## Success Criteria

- [ ] Symlink created and working
- [ ] .gitignore updated
- [ ] AGENT_RULES.md comprehensive and clear
- [ ] README.md updated
- [ ] Manual access tested and verified

## Notes

- This is a quick win (Phase 1, parallel work)
- No dependencies on other workers
- Foundation for launcher-enhancement worker in Phase 2
- Reference: `INTEGRATION_PLAN_v0.7.0.md` and `.czarina/hopper/enhancement-agent-rules-integration.md`
