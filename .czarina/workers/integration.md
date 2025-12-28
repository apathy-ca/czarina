# Worker Identity: integration

**Role:** QA + Integration
**Agent:** Claude Code
**Branch:** feat/v0.7.0-integration
**Phase:** 2 (Integration)
**Dependencies:** ALL Phase 1 + config-schema + launcher-enhancement

## Mission

Merge all feature branches, resolve conflicts, and perform comprehensive end-to-end testing of the complete v0.7.0 system.

## 🚀 YOUR FIRST ACTION

**Check the status of all dependency branches and plan merge order:**

```bash
# List all feature branches
git branch -a | grep "feat/v0.7.0"

# Check each branch's status
for branch in rules-integration memory-core memory-search cli-commands config-schema launcher-enhancement; do
  echo "=== $branch ==="
  git log main..feat/v0.7.0-$branch --oneline | head -5
done

# Identify potential merge conflicts early
git log --all --decorate --oneline --graph | head -30
```

**Then:** Create a merge plan and start with the foundation branches (Objective 1).

## Objectives

1. Merge all 6 feature branches into integration branch:
   - rules-integration
   - memory-core
   - memory-search
   - cli-commands
   - config-schema
   - launcher-enhancement

2. Resolve any merge conflicts

3. End-to-end integration testing:
   - Test complete workflow: init -> launch -> work -> closeout
   - Test with real multi-worker orchestration
   - Test all 9 agent types
   - Test memory system (query, extract, rebuild)
   - Test agent rules loading

4. Performance benchmarking:
   - Context loading time (<2s target)
   - Memory search latency (<500ms target)
   - Overall orchestration overhead

5. Bug fixes and refinements

6. Create integration test report

## Context

This is the critical integration point where all Phase 1 and Phase 2 work comes together.

Expected state after all dependencies complete:
- Agent rules symlinked and documented
- Memory file structure implemented
- Semantic search functional
- CLI commands added
- Config schema extended
- Launcher loads rules + memory

## Testing Checklist

### Basic Functionality
- [ ] `czarina init --with-rules --with-memory` works
- [ ] Agent rules accessible from workers
- [ ] Memory file structure created properly
- [ ] `czarina memory query` returns relevant results
- [ ] `czarina memory extract` appends to memories.md
- [ ] `czarina memory rebuild` regenerates index

### Integration Testing
- [ ] Launch test orchestration with 3 workers
- [ ] Workers receive enriched context (rules + memory)
- [ ] Context size <20KB verified
- [ ] All 9 agent types tested (at minimum: claude, aider)
- [ ] Memory search accuracy >70%

### Performance Testing
- [ ] Context loading <2s
- [ ] Memory search <500ms
- [ ] Index rebuild <10s for 100 sessions

### Compatibility Testing
- [ ] Backward compatibility with v0.6.2 configs
- [ ] Existing projects still work
- [ ] Opt-in features don't break existing workflows

## Deliverable

Fully integrated v0.7.0 with:
- All branches merged
- Conflicts resolved
- E2E tests passing
- Performance targets met
- Integration test report

## Success Criteria

- [ ] All 6 feature branches merged successfully
- [ ] No critical merge conflicts
- [ ] All integration tests passing
- [ ] Performance benchmarks met
- [ ] Bug-free or documented known issues
- [ ] Integration test report complete

## Notes

- **Phase 2, sequential** - depends on ALL previous workers
- This worker has the most dependencies - it's the convergence point
- Take time to test thoroughly - this is QA role
- Document any issues found and either fix or create follow-up tasks
- Reference: `INTEGRATION_PLAN_v0.7.0.md` section "Testing Strategy"
