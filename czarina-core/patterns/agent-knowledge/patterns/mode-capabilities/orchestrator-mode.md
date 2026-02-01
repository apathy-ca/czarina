# Orchestrator Mode

**Purpose**: Coordinate complex, multi-step projects across different specialties.

**Value**: Enables large projects by managing complexity, delegating to specialized modes, and tracking progress.

**Best For**: Multi-phase projects, complex workflows, work spanning multiple domains, team coordination.

---

## Capabilities

### Can Do

- Break down large tasks into subtasks
- Create task lists and project plans
- Coordinate work across modes
- Manage workflows and phases
- Track progress and dependencies
- Delegate to other modes appropriately
- Create overall project structure
- Manage handoffs between phases
- Plan work across multiple sessions
- Handle complex interdependencies

### Cannot Do

- Direct implementation (delegates to Code mode)
- Direct debugging (delegates to Debug mode)
- Direct design work (delegates to Architect mode)
- Direct learning/explanation (delegates to Ask mode)

**Note**: Orchestrator mode focuses on coordination, not execution. It delegates actual work to appropriate modes while managing overall flow.

---

## When to Use Orchestrator Mode

### Start with Orchestrator When

- Large, multi-phase project
- Work spans multiple domains or specialties
- Need coordination across different types of work
- Project takes multiple sessions
- Complex dependencies between tasks
- Team coordination needed

### Example Situations

**Scenario 1: Major System Refactor**
- Task: Refactor authentication system (currently monolithic, need microservice)
- Orchestrator breaks into:
  1. **Architect**: Design new service architecture
  2. **Code**: Create new authentication service
  3. **Code**: Update main app to use new service
  4. **Debug**: Test integration and fix issues
  5. **Code**: Remove old code once migration complete
  6. **Ask**: Document new architecture

**Scenario 2: New Product Feature**
- Task: Add subscription management to SaaS platform
- Orchestrator breaks into:
  1. **Architect**: Design subscription system
  2. **Code**: Implement subscription database schema
  3. **Code**: Implement subscription API
  4. **Code**: Implement billing integration
  5. **Code**: Implement UI for subscription management
  6. **Debug**: Test billing scenarios
  7. **Code**: Add monitoring and logging

**Scenario 3: Multi-Service Deployment**
- Task: Deploy 3 new microservices and integrate them
- Orchestrator breaks into:
  1. **Architect**: Design service interaction
  2. **Code**: Implement Service A
  3. **Code**: Implement Service B
  4. **Code**: Implement Service C
  5. **Code**: Create integration layer
  6. **Debug**: Integration testing
  7. **Code**: Deployment and monitoring

**Scenario 4: Performance Optimization Project**
- Task: Reduce page load time from 5s to 1s
- Orchestrator breaks into:
  1. **Debug**: Profile application (identify bottlenecks)
  2. **Architect**: Plan optimization strategy
  3. **Code**: Optimize database queries
  4. **Code**: Add caching layer
  5. **Code**: Optimize frontend assets
  6. **Debug**: Re-profile and verify improvement
  7. **Code**: Add performance monitoring

---

## Project Structure Patterns

### Pattern: Phased Project

**Large projects break into phases**:

```
Project: Build Multi-Tenant SaaS Platform

Phase 1: Foundation (Week 1-2)
├─ Architect: Design multi-tenant architecture
├─ Code: Implement basic tenant isolation
└─ Code: Set up database for tenants

Phase 2: Core Features (Week 3-4)
├─ Code: Implement user authentication
├─ Code: Implement product catalog
└─ Code: Implement shopping cart

Phase 3: Business Logic (Week 5-6)
├─ Code: Implement order processing
├─ Code: Implement payment integration
└─ Code: Implement reporting

Phase 4: Quality (Week 7)
├─ Debug: Test all features
├─ Code: Fix issues found
└─ Code: Add monitoring

Phase 5: Launch (Week 8)
├─ Code: Deploy to production
├─ Debug: Monitor in production
└─ Ask: Document for users
```

### Pattern: Parallel Streams

**Some work can happen in parallel**:

```
Project: API Redesign

Stream 1: New API
├─ Architect: Design new API
└─ Code: Implement new endpoints

Stream 2: Client Migration
├─ Architect: Plan client updates
└─ Code: Update clients to new API

Stream 3: Legacy Support
├─ Code: Maintain backward compatibility
└─ Code: Plan deprecation timeline

Integration: Bring together
├─ Debug: Test all streams together
├─ Code: Fix integration issues
└─ Ask: Document migration guide
```

### Pattern: Dependency-Based Sequencing

**Some tasks must happen in order**:

```
Project: Database Migration

1. Design new schema (Architect)
   ↓ Depends: Schema designed
2. Create new database (Code)
   ↓ Depends: Database created
3. Write migration script (Code)
   ↓ Depends: Script written
4. Test migration (Debug)
   ↓ Depends: Script validated
5. Run migration (Code)
   ↓ Depends: Migration done
6. Verify data (Debug)
   ↓ Depends: Data verified
7. Remove old database (Code)
```

---

## Coordination Strategies

### Strategy: Clear Task Handoffs

**When switching modes**, communicate:

1. **What's done**: What the previous mode accomplished
2. **What's next**: What the new mode should do
3. **Context needed**: Information the new mode needs
4. **Success criteria**: How we know the task is done
5. **Blockers**: Any known issues or constraints

**Example**:
```
From Architect to Code:

DONE: Architecture for user service designed
- Authentication logic spec'd
- API endpoints spec'd
- Database schema specified
- Error handling plan created

NEXT: Code mode implements the user service

CONTEXT NEEDED:
- Use existing database connection pooling
- Follow existing error handling patterns
- Use existing logging system

SUCCESS CRITERIA:
- All endpoints implement spec
- All tests pass
- Follows existing code style

KNOWN CONSTRAINTS:
- Must work with existing auth middleware
- Can't modify database structure (handled in migration)
```

### Strategy: Progress Tracking

**Track what's complete, what's in progress, what's blocked**:

```
Project Status: Authentication Refactor

COMPLETED (30%)
✓ Design new authentication service
✓ Create database schema
✓ Implement token generation

IN PROGRESS (40%)
→ Implement authentication API (Code mode)
→ Write authentication tests (Code mode)

BLOCKED (10%)
✗ Integration with legacy auth (waiting on dependency fix)

PENDING (20%)
○ Update client apps to use new auth
○ Deprecate old authentication
○ Monitor in production
```

### Strategy: Mode Delegation Rules

**Delegate based on task type**:

| Task Type | Delegate To | Why |
|-----------|------------|-----|
| Design/Plan | Architect | Specialized for planning |
| Implement | Code | Has full tool access |
| Fix issues | Debug → Code | Debug investigates, Code fixes |
| Learn/Understand | Ask | Specialized for explanation |
| Monitor workflow | Orchestrator | Stay here, don't switch |

---

## Risk Management

### Pattern: Identifying Dependencies

**Map what depends on what**:

```
Feature: Subscription Management

Dependencies:
- Billing API (external service)
  ├─ Depends: Stripe account setup
  └─ Impacts: Can't test payment without this

- User database changes
  ├─ Depends: Migration tool ready
  └─ Impacts: Can't ship without migrations

- Frontend UI
  ├─ Depends: Backend API stable
  └─ Impacts: Can't finalize UI until API ready

Critical path:
Stripe setup → Backend API → Frontend → Testing → Launch
```

### Pattern: Handling Unknowns

**When something is unknown**:

1. **Identify the unknown**: What do we not know?
2. **Delegate to investigate**: Use appropriate mode
3. **De-risk**: Learn what we need to know
4. **Plan accordingly**: Adjust plan based on learning
5. **Continue**: Move forward with new knowledge

**Example**:
```
Unknown: "How fast can our database handle our query?"

Action:
1. Delegate to Debug mode: Profile database
2. Learn: See if it meets performance requirements
3. Outcome: Needs optimization
4. Adjust plan: Add caching layer task
5. Continue: Proceed with updated plan
```

### Pattern: Contingency Planning

**For high-risk items, plan alternatives**:

```
Task: Integration with third-party payment API

Primary plan:
1. Implement against test API
2. Test thoroughly
3. Switch to production API

Contingency if API too slow:
- Add caching layer
- Implement async processing

Contingency if API unreliable:
- Add retry logic
- Implement queue system
- Fall back to manual processing

This ensures we have options if primary doesn't work.
```

---

## Session Management

### Pattern: Multi-Session Projects

**For work spanning multiple sessions**:

1. **Session start**: Review what was done, understand current state
2. **Session work**: Accomplish planned tasks for this session
3. **Session end**: Document state for next session

**Example**:

```
Session 1: Design Phase
- Architect designs system
- Document: "Design complete, ready to implement"

Session 2: Backend Implementation
- Code mode implements backend services
- Document: "Backend done, ready for frontend"

Session 3: Frontend Implementation
- Code mode implements UI
- Document: "UI done, ready for testing"

Session 4: Testing & Fixes
- Debug tests system
- Code fixes issues found
- Document: "Ready for launch"
```

### Pattern: Session Notes

**At end of each session, document**:

```markdown
## Session 3: Frontend Implementation - 2 hours

### What Was Accomplished
- Implemented login form component
- Implemented user dashboard
- Added error handling for failed requests

### Current Status
- Frontend UI complete
- Backend API fully functional
- Ready for integration testing

### Next Session
- Debug mode: Test all user flows
- Code mode: Fix issues found during testing
- Prepare for launch

### Known Issues
- Modal styling needs refinement (low priority)
- Performance on slow connections untested

### Context for Next Session
- API endpoint /api/user/{id} returns user data
- Authentication uses JWT tokens in localStorage
- Error handling pattern: try/catch with toast notifications
```

---

## When to Switch Modes

### Don't Switch From Orchestrator

**Orchestrator mode stays at the top level**:
- Don't switch to Code to implement one thing
- Don't switch to Architect for one design decision
- **Instead**: Delegate to appropriate mode, let it complete, return to Orchestrator

**Exception**: If very small task (< 5 minutes), might do directly, but stay focused on coordination role.

### How Orchestrator Delegates

**Orchestrator doesn't execute work**:
```
NOT this:
Orchestrator → Code (implement feature A)
             → Debug (fix bug)
             → Code (implement feature B)

Instead:
Orchestrator → [delegate to Code for feature A]
              [Code completes feature A and returns]
           → [delegate to Debug for bug]
              [Debug completes and returns]
           → [delegate to Code for feature B]
              [Code completes and returns]
           → [continue orchestrating]
```

---

## Coordination Best Practices

### 1. Clear Communication

**When delegating**:
- Be specific about what needs to be done
- Provide all context
- State success criteria
- Explain how it fits in larger project

### 2. Appropriate Granularity

**Break work into appropriate chunks**:
- Not too big (one mode should handle in one session)
- Not too small (overhead of handoff isn't worth it)
- Logically cohesive (related work together)

### 3. Track Dependencies

**Understand what depends on what**:
- Can tasks happen in parallel?
- What must happen first?
- What's the critical path?
- Where are the bottlenecks?

### 4. Monitor Progress

**Stay aware of**:
- What's complete
- What's in progress
- What's blocked
- Upcoming risks

### 5. Adapt as Needed

**Be ready to adjust**:
- If something takes longer, adjust timeline
- If dependencies change, re-sequence work
- If unknowns emerge, investigate first
- If goals change, re-evaluate plan

---

## Orchestrator vs Other Modes

### Orchestrator vs Architect

**Architect**: Designs individual components
**Orchestrator**: Coordinates multiple components across phases

**Example**:
- Architect: "Design the payment service"
- Orchestrator: "Plan the entire billing feature (payment service + UI + migrations)"

### Orchestrator vs Code

**Code**: Implements individual features
**Orchestrator**: Coordinates multiple features and phases

**Example**:
- Code: "Implement user service"
- Orchestrator: "Manage the refactor of 3 services, migration, integration, testing"

### Orchestrator vs Debug

**Debug**: Investigates individual issues
**Orchestrator**: Coordinates testing across system

**Example**:
- Debug: "Find why this test is failing"
- Orchestrator: "Plan full integration testing across all services"

### Orchestrator vs Ask

**Ask**: Answers specific questions
**Orchestrator**: Coordinates understanding across project

**Example**:
- Ask: "How does this service work?"
- Orchestrator: "Plan learning path for entire team on new architecture"

---

## Anti-Patterns

### Anti-Pattern: Orchestrator Doing Work

**Problem**: Orchestrator implementing instead of delegating
**Why it happens**: Faster than delegating? (Usually not true)
**Solution**: Delegate to appropriate mode

### Anti-Pattern: Poor Handoffs

**Problem**: Not giving next mode enough context
**Why it happens**: Assumes continuity
**Solution**: Explicit handoff documentation

### Anti-Pattern: No Progress Tracking

**Problem**: Don't know what's done, what's pending
**Why it happens**: Seems like overhead
**Solution**: Quick status updates save time overall

### Anti-Pattern: Ignoring Blockers

**Problem**: Tasks get stuck waiting on dependencies
**Why it happens**: Not tracking dependencies
**Solution**: Explicit dependency tracking

---

## Key Principles

1. **Coordinate, Don't Implement**: Stay focused on orchestration role
2. **Delegate Clearly**: Explicit handoffs prevent confusion
3. **Track Progress**: Know status at all times
4. **Manage Dependencies**: Understand what depends on what
5. **Adapt Flexibly**: Adjust plan based on learning

---

## Related Patterns

- [Mode Transitions](./mode-transitions.md) - How modes connect
- [Architect Mode](./architect-mode.md) - Planning phase delegation
- [Code Mode](./code-mode.md) - Implementation phase delegation
- [Debug Mode](./debug-mode.md) - Testing phase delegation

---

**Last Updated**: 2025-12-28
**Applicability**: Large, complex, multi-phase projects
**Source**: MODE_CAPABILITIES.md from agentic-dev-patterns

*"Orchestration turns complexity into manageable steps."*
