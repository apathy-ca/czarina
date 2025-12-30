# Worker Identity: worker-onboarding-fix

**Role:** Code
**Agent:** Claude Code
**Branch:** cz1/feat/worker-onboarding-fix
**Phase:** 1
**Dependencies:** None

## Mission

Fix the "workers can't find their spot" issue by adding explicit first actions to worker identities. Make it impossible for workers to get stuck not knowing what to do first.

## 🚀 YOUR FIRST ACTION

**Read the current worker identity template:**
```bash
# If a template exists:
cat czarina-core/templates/worker-identity-template.md 2>/dev/null

# Otherwise, examine existing worker files:
ls -la .czarina/workers/
cat .czarina/workers/CZAR.md  # Example to see current format
```

**Then identify where to add the "YOUR FIRST ACTION" section**

## Objectives

1. Update worker identity template with explicit "🚀 YOUR FIRST ACTION" section
2. Add `first_action` field to worker config schema (if needed)
3. Backfill all existing worker identities from v0.7.0 with first actions
4. Create examples showing good vs bad onboarding
5. Document best practices for writing first actions
6. Test with a real worker launch

## Deliverables

- Updated worker identity template
- All v0.7.0 worker identities backfilled
- Documentation: "Writing Effective First Actions"
- Examples of good first actions
- Test report showing 0 stuck workers

## Success Criteria

- [ ] Template includes "🚀 YOUR FIRST ACTION" section
- [ ] Format is clear and actionable (specific command/action)
- [ ] All existing workers updated
- [ ] Documentation complete with examples
- [ ] Test launch shows workers take first action immediately

## Context

**Problem:** 1 worker per orchestration gets stuck, doesn't know what to do first
**Root Cause:** Worker identities describe mission/objectives but no explicit first step
**Solution:** Add unmissable "YOUR FIRST ACTION" section with specific command

**Reference:** `.czarina/hopper/issue-worker-onboarding-confusion.md`

## Notes

- This is dogfooding - we're implementing the fix we need!
- Your own identity has a first action - use it as inspiration
- Focus on making it impossible to miss and completely unambiguous
- Test with your own updated identity
