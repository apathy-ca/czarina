# Worker Identity: release

**Role:** QA + Release
**Agent:** Claude Code
**Branch:** feat/v0.7.0-release
**Phase:** 2 (Integration)
**Dependencies:** integration, documentation

## Mission

Perform final QA, create the v0.7.0 release tag, and publish Czarina v0.7.0 to the world.

## 🚀 YOUR FIRST ACTION

**Run comprehensive tests to verify all features are functional:**

```bash
# Run the full test suite
./tests/run-all-tests.sh

# Or if individual test files exist
pytest tests/ -v

# Check that all features work end-to-end
czarina memory query "test query"
czarina init test-project --with-memory --with-rules
```

**Then:** Review test results and proceed to Objective 2 (security review) if all tests pass.

## Objectives

1. **Final Testing**
   - All features functional
   - Documentation accurate
   - Examples working
   - No critical bugs
   - Performance targets met

2. **Security Review**
   - No secrets in code
   - Safe symlink handling
   - Input validation for memory queries
   - API key handling secure

3. **Version Management**
   - Update version numbers in code
   - Update CZARINA_STATUS.md
   - Verify all version references

4. **Release Artifacts**
   - Create git tag: v0.7.0
   - Write final release notes
   - Prepare GitHub release

5. **Publish Release**
   - Push tag to GitHub
   - Create GitHub release
   - Announce release

6. **Post-Release**
   - Create orchestration closeout report
   - Archive phase work
   - Document lessons learned

## Context

This is the final worker - everything converges here for the official v0.7.0 release.

## Pre-Release Checklist

### Code Quality
- [ ] All tests passing
- [ ] No critical bugs
- [ ] Code review complete
- [ ] Performance benchmarks met
- [ ] Security review complete

### Documentation
- [ ] All documentation complete
- [ ] Examples tested and working
- [ ] Migration guide accurate
- [ ] CHANGELOG.md updated
- [ ] README.md updated

### Version Management
- [ ] Version bumped to 0.7.0 in code
- [ ] All version references updated
- [ ] CZARINA_STATUS.md updated
- [ ] No references to "v0.6.2" where "v0.7.0" should be

### Release Artifacts
- [ ] Release notes written
- [ ] Git tag created: `git tag -a v0.7.0 -m "..."`
- [ ] Tag message comprehensive
- [ ] Tag pushed to GitHub

### GitHub Release
- [ ] Release created on GitHub
- [ ] Release notes formatted for GitHub
- [ ] Highlights/features listed
- [ ] Breaking changes noted (if any)
- [ ] Download/installation instructions

## Release Tag Message Template

```
Czarina v0.7.0 - Memory System + Agent Rules Integration

This release transforms Czarina from a multi-agent orchestrator into a
**learning, knowledge-powered orchestration system**.

## Major Features

### Memory System (Persistent Learning)
- 3-tier memory architecture
- Semantic search of past sessions
- Architectural Core always-loaded context
- CLI commands: query, extract, rebuild
- 70%+ search accuracy, <2s context loading

### Agent Rules Integration (Production Best Practices)
- 43K+ lines of production-tested patterns
- 69 files covering 9 domains
- Automatic loading based on worker role
- Created BY Czarina (dogfooding proof!)

### The Synergy
- Workers remember past mistakes (memory)
- Workers apply proven patterns (rules)
- Workers get smarter with every session

## Performance
- Context loading: <2s
- Memory search: <500ms
- Context size: <20KB
- All 9 agents supported

## Migration
- Fully backward compatible with v0.6.2
- Opt-in features: --with-memory --with-rules
- See MIGRATION_v0.7.0.md

## Implementation
Created by 9-worker Czarina orchestration (3-5 days)
- Czarina builds Czarina! 🐕
- 6-8x faster than traditional development

## Contributors
[List of workers and their contributions]

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Success Criteria

- [ ] All pre-release checklist items complete
- [ ] v0.7.0 tag created and pushed
- [ ] GitHub release published
- [ ] CZARINA_STATUS.md shows v0.7.0
- [ ] No critical issues in release
- [ ] Orchestration closeout report created

## Post-Release Tasks

1. **Orchestration Closeout**
   - Create comprehensive closeout report
   - Document what worked well
   - Document challenges and solutions
   - Record metrics (timeline, worker success rate)
   - Create lessons learned

2. **Archive Phase**
   - Use `czarina phase close` to archive
   - Preserve phase history

3. **Announcement**
   - Consider social media announcement
   - Update any external documentation
   - Notify users/testers

## Notes

- **Phase 2, sequential** - depends on integration and documentation
- This is the final convergence point
- Take time to ensure quality - this is what ships
- Document the entire v0.7.0 orchestration for marketing
- This orchestration itself is proof of Czarina's power
- Reference: `INTEGRATION_PLAN_v0.7.0.md` section "Release Checklist"

## Dogfooding Meta-Commentary

This v0.7.0 release is special because:
- Czarina building Czarina (just like agent-rules)
- 9 workers collaborating on complex feature set
- 3-5 day timeline vs 3-4 weeks traditional
- Real-world validation of orchestration approach
- Perfect marketing story

**The tools are building themselves.**
