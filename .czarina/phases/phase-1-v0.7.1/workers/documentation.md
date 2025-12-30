# Worker Identity: documentation

**Role:** Documentation
**Agent:** Claude Code
**Branch:** feat/v0.7.0-documentation
**Phase:** 2 (Integration)
**Dependencies:** integration

## Mission

Create comprehensive documentation for v0.7.0 memory and agent rules features, including migration guides and examples.

## 🚀 YOUR FIRST ACTION

**Review the implemented features from the integration worker:**

```bash
# Read the integration worker's completion report to understand what was built
cat .czarina/work/*/workers/integration/completion.md

# Or check the integration branch directly
git log feat/v0.7.0-integration --oneline | head -20

# Review the actual implementations to document accurately
ls -la czarina-core/
```

**Then:** Start creating AGENT_RULES.md based on the actual implementation (Objective 1).

## Objectives

1. Create `AGENT_RULES.md` - Complete guide to agent rules integration
2. Create `MEMORY_GUIDE.md` - Memory system usage and best practices
3. Create `MIGRATION_v0.7.0.md` - Migration guide from v0.6.2 to v0.7.0
4. Update `README.md` - Add v0.7.0 features and highlights
5. Update `QUICK_START.md` - Include new flags and commands
6. Update `CHANGELOG.md` - Complete v0.7.0 changelog
7. Create example `memories.md` files
8. Write v0.7.0 release notes

## Context

v0.7.0 adds two major features:
1. **Memory System** - 3-tier persistent learning architecture
2. **Agent Rules Integration** - 43K+ lines of best practices

Both need comprehensive documentation for users to understand and adopt.

## Documentation Deliverables

### AGENT_RULES.md
- What are agent rules?
- How they're integrated into Czarina
- How to use them (manual and automatic)
- Role-to-rules mapping
- Creating custom project rules
- Examples

### MEMORY_GUIDE.md
- Memory architecture (3 tiers)
- How to use memory system
- CLI commands (query, extract, rebuild)
- Best practices for memory maintenance
- Example workflows
- Troubleshooting

### MIGRATION_v0.7.0.md
- What's new in v0.7.0
- Breaking changes (if any)
- Step-by-step migration from v0.6.2
- Opting in to new features
- Config changes needed
- Before/after examples

### README.md Updates
- Add v0.7.0 highlights to top
- Update feature list
- Add memory + rules to key features
- Update examples to show new capabilities

### QUICK_START.md Updates
- Add `--with-rules` and `--with-memory` flags
- Show memory commands
- Update workflows to include memory/rules

### CHANGELOG.md
- Complete v0.7.0 entry
- List all new features
- List all improvements
- Note any breaking changes
- Credit contributors/workers

### Example Files
- `examples/memories-example.md` - Sample memories file
- `examples/config-v0.7.0-full.json` - Config with all features
- `examples/config-v0.7.0-minimal.json` - Minimal v0.7.0 config

## Release Notes

Create compelling release notes that emphasize:
- First orchestrator with persistent memory
- 43K+ lines of production best practices built-in
- Market differentiation
- Dogfooding proof (Czarina built by Czarina)
- Performance improvements
- Example use cases

## Success Criteria

- [ ] AGENT_RULES.md complete and comprehensive
- [ ] MEMORY_GUIDE.md complete and comprehensive
- [ ] MIGRATION_v0.7.0.md clear and actionable
- [ ] README.md updated with v0.7.0 highlights
- [ ] QUICK_START.md updated
- [ ] CHANGELOG.md updated
- [ ] Example files created
- [ ] Release notes written
- [ ] All documentation reviewed for accuracy

## Documentation Standards

- Clear, concise writing
- Real examples, not abstract concepts
- Step-by-step instructions where appropriate
- Troubleshooting sections
- Links to related documentation
- Consistent formatting and style
- Code blocks with syntax highlighting

## Notes

- **Phase 2, sequential** - depends on integration (for accuracy)
- Documentation should reflect the actual implementation from integration worker
- Test all examples and commands before documenting
- This is critical for user adoption
- Reference: `INTEGRATION_PLAN_v0.7.0.md` section "Release Checklist"
