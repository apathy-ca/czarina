# SARK v2.0 Session Coordinator Instructions

## Session Context

**Previous Session Summary:**
The team completed significant work that was committed directly to `main` (which has now been cleaned up). The work included:

1. **ENGINEER-1** - Week 1 foundation complete, ProtocolAdapter interface frozen
2. **ENGINEER-2** - HTTP/REST Adapter implementation report completed
3. **ENGINEER-3** - gRPC Protocol Adapter implementation completed
4. **ENGINEER-4** - Federation & Discovery implementation completed (2 commits)
5. **ENGINEER-5** - (Status unknown, check branch)
6. **ENGINEER-6** - Database schema and migrations completed
7. **QA-1** - Comprehensive integration test framework added
8. **QA-2** - Performance & Security infrastructure completed
9. **DOCS-1** - API documentation deliverables completed
10. **DOCS-2** - (Status unknown, check branch)

**Current State:**
- All workers are now in their proper feature branches (feat/v2-*)
- Main branch has the previous session's work
- Workers need to understand what they did before and what comes next

## Your Mission as Coordinator

Send this message to all workers to kick off the new session:

---

**Message to All Workers:**

Welcome to the new SARK v2.0 development session!

**Session Objective:** Analyze previous work and plan next steps

**Your Tasks:**

1. **Analyze Current State**
   - Check what commits exist on `main` that relate to your area
   - Review what work was already completed in the previous session
   - Understand what remains to be done per your role prompt

2. **Review Your Branch**
   - Your branch (feat/v2-*) is currently clean, branched from main
   - Previous session work is on main (will be cherry-picked/moved to branches)
   - Check if any of the main commits are yours

3. **Identify Next Tasks**
   - Based on your role prompt (already loaded)
   - Based on what's been completed
   - Based on dependencies from other engineers

4. **Report Back**
   - Summarize: What was completed in previous session
   - Propose: What you should work on in THIS session
   - Identify: Any blockers or dependencies
   - Ask: Any questions or clarifications needed

**Coordination Notes:**
- ENGINEER-1 leads architecture - others depend on their interface contracts
- Database (ENGINEER-6) work enables adapter implementations
- QA and Docs should track what engineers deliver

**Time Expectation:**
This is a planning phase. Take 15-30 minutes to analyze and propose your plan before starting implementation work.

---

## Coordinator Actions

1. ✅ Send message above to all workers via `./send-task.sh`
2. ⏳ Monitor workers for 15-30 minutes as they analyze
3. 📊 Watch dashboard for git activity
4. 🎯 Once plans are clear, workers can begin implementation
5. 🤖 Autonomous Czar can take over for ongoing monitoring

## Notes

- This coordinator role is temporary for session startup
- Once workers are oriented and working, autonomous monitoring takes over
- Human intervention only needed for major decisions or blockers
