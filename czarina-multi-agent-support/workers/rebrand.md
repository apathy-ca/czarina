# REBRAND: Documentation Rebranding Specialist

## Role
documentation_engineer

## Skills
technical-writing, markdown, documentation, branding, find-and-replace

## Timeline
Phase 1 (Quick win - 30 minutes)

## Priority
high

## Responsibilities
- Rebrand documentation from "Claude Code" to agent-agnostic language
- Create template versions of key documentation files
- Add "Works with any AI coding assistant" messaging
- Update examples to be agent-neutral where possible

## Deliverables

### 1. Template Documentation Files
Create `.template` versions with placeholders:

- `czarina-core/templates/embedded-orchestration/START_WORKER.md.template`
- `czarina-core/templates/embedded-orchestration/README.md.template`
- `czarina-core/templates/WORKER_GIT_WORKFLOW.md.template`

**Placeholders to use:**
- `{{AGENT_NAME}}` - e.g., "Claude Code", "Cursor", "GitHub Copilot"
- `{{AGENT_TYPE}}` - e.g., "AI coding assistant", "AI pair programmer"
- `{{DISCOVERY_PATTERN}}` - Agent-specific discovery instructions

### 2. Update Main Documentation

**Files to update:**
- `CZARINA_README.md`
  - Add "Agent Compatibility" section
  - Show it works with multiple agents
  - Keep Claude Code as primary example

- `EMBEDDED_ORCHESTRATION_GUIDE.md`
  - Add "Works With Any Agent" section
  - Show examples for different agents
  - Document agent-specific notes

- `WORKER_SETUP_GUIDE.md`
  - Add multi-agent considerations
  - Show how to adapt for different agents

### 3. Create Agent Compatibility Matrix

Create new file: `AGENT_COMPATIBILITY.md`

**Content:**
- Compatibility matrix (which agents work, at what level)
- Agent-specific setup instructions
- Common adaptations needed
- Troubleshooting by agent

## Instructions

You are the **Documentation Rebranding Specialist** working on making Czarina agent-agnostic.

**Your Mission:** Rebrand documentation to be welcoming to all AI coding assistants while keeping Claude Code as the primary/tested example.

**Working directory:** `/home/jhenry/Source/GRID/claude-orchestrator`

**Reference documents:**
- `AGENT_AGNOSTIC_ANALYSIS.md` - Full analysis of what needs to change
- Current documentation files in root and `czarina-core/`

**Approach:**
1. **Don't break existing workflows** - Claude Code should still work perfectly
2. **Additive changes** - Add agent-agnostic options, don't remove Claude examples
3. **Use templates** - Create `.template` files for generation
4. **Be explicit** - "Works with Claude Code, Cursor, Copilot, and more"

## Success Criteria

- [ ] Template files created with proper placeholders
- [ ] Main docs updated to mention multi-agent support
- [ ] Agent compatibility matrix documented
- [ ] Claude Code workflows still work perfectly
- [ ] Clear instructions for using with other agents
- [ ] All changes committed to your branch

## Dependencies
- None (first worker!)

## Git Workflow

**Your assigned branch:** `feat/agent-agnostic-docs`

### Setup
```bash
cd /home/jhenry/Source/GRID/claude-orchestrator
git checkout main
git pull origin main
git checkout -b feat/agent-agnostic-docs
```

### Working
```bash
# Make your changes

# Commit frequently
git add <files>
git commit -m "docs(rebrand): <what you did>"

# Push to remote
git push -u origin feat/agent-agnostic-docs
```

### Commit Message Convention
```
docs(rebrand): <description>

Examples:
docs(rebrand): create template versions of embedded docs
docs(rebrand): add agent compatibility matrix
docs(rebrand): update main README with multi-agent support
```

### When Complete
```bash
# Create PR
gh pr create --base main --head feat/agent-agnostic-docs \
  --title "docs: Rebrand documentation for multi-agent support" \
  --body "$(cat <<'EOF'
## Summary
- Created template versions of key documentation files
- Added agent compatibility matrix
- Updated main documentation to mention multi-agent support
- Kept Claude Code as primary example

## Changes
- New: AGENT_COMPATIBILITY.md
- Templates: *.md.template files
- Updated: CZARINA_README.md, EMBEDDED_ORCHESTRATION_GUIDE.md

## Testing
- [ ] Verified templates have correct placeholders
- [ ] Checked all links still work
- [ ] Claude Code examples still accurate

🤖 Generated with Czarina Multi-Agent Orchestration
EOF
)"
```

## Tips

1. **Use sed for consistency**
   ```bash
   # Example: create template from existing file
   sed 's/Claude Code/{{AGENT_NAME}}/g' \
       START_WORKER.md > START_WORKER.md.template
   ```

2. **Keep it simple**
   - Don't over-engineer
   - Templates should be easy to fill
   - Examples are better than abstract descriptions

3. **Test as you go**
   - Read generated docs to make sure they make sense
   - Try mentally substituting "Cursor" for "Claude Code"
   - Does it still make sense?

## Quick Start Checklist

- [ ] Create branch: `feat/agent-agnostic-docs`
- [ ] Read `AGENT_AGNOSTIC_ANALYSIS.md` for context
- [ ] Create template files first (easy wins)
- [ ] Add agent compatibility matrix
- [ ] Update main README
- [ ] Update detailed guides
- [ ] Test that changes make sense
- [ ] Commit and push
- [ ] Create PR

**Let's make Czarina welcoming to all AI coding assistants!** 🌍🤖
