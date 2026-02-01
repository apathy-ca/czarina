# Mode Transitions

**Purpose**: Decision tree and guidelines for choosing and switching between modes.

**Value**: Clear transitions reduce context-switching overhead and prevent mode mismatches.

---

## Decision Tree: Choose Your Starting Mode

```
What needs to happen?
│
├─ Starting new feature/project?
│  └─ Need to plan/design first?
│     ├─ Yes → START: Architect Mode
│     └─ No (clear requirements) → START: Code Mode
│
├─ Application broken/behaving wrong?
│  └─ START: Debug Mode
│     (Investigate, then Code to fix)
│
├─ Need to understand how it works?
│  └─ START: Ask Mode
│     (Learn, then switch to appropriate mode)
│
├─ Large multi-phase project?
│  └─ Need to coordinate complex work?
│     ├─ Yes → START: Orchestrator Mode
│     └─ No → Start with appropriate mode above
│
└─ Have plan/design/spec ready to implement?
   └─ START: Code Mode
```

---

## Detailed Mode Selection Guide

### When to Start with Architect

**Choose Architect when**:
- Feature is complex (more than a few hours of work)
- Architecture impacts multiple systems
- Design decisions affect future work
- Need to evaluate trade-offs
- Team alignment needed before implementation
- Want to prevent costly rework

**Example scenarios**:
- "Add multi-tenant support to monolith"
- "Refactor authentication system"
- "Design new microservice architecture"
- "Plan performance optimization"
- "Design data migration strategy"

**Telltale sign**: If you're asking "what's the best way to..." → Architect mode

### When to Start with Code

**Choose Code when**:
- Design/plan is already done
- Clear requirements exist
- Feature is straightforward
- Just need to implement
- Fixing obvious bugs
- Small enhancements

**Example scenarios**:
- "Implement the user service from design spec"
- "Add new button to dashboard"
- "Fix typo in error message"
- "Add field to form"
- "Optimize SQL query"

**Telltale sign**: If requirements are clear and you can start coding → Code mode

### When to Start with Debug

**Choose Debug when**:
- Something is broken
- Tests are failing
- Unexpected behavior observed
- Error messages don't make sense
- Performance is degraded

**Example scenarios**:
- "Why does login fail with certain passwords?"
- "Application crashes on startup"
- "Test failures in CI but works locally"
- "Page load takes 30 seconds"
- "API returns wrong data sometimes"

**Telltale sign**: If there's an error or issue → Debug mode

### When to Start with Ask

**Choose Ask when**:
- Need to learn something before proceeding
- Code is unfamiliar
- Technology is new
- Want to understand before implementing
- Code review or analysis needed
- Recommendations wanted

**Example scenarios**:
- "How does the existing caching work?"
- "What does this error message mean?"
- "Can you explain the authentication flow?"
- "What are best practices for error handling?"
- "Why is this code structured this way?"

**Telltale sign**: If you need understanding before deciding what to do → Ask mode

### When to Start with Orchestrator

**Choose Orchestrator when**:
- Project is multi-phase (3+ distinct phases)
- Multiple teams or specialties involved
- Complex dependencies between tasks
- Project spans multiple days/sessions
- Need progress tracking
- Coordination between modes needed

**Example scenarios**:
- "Plan 3-month migration project"
- "Coordinate backend and frontend teams"
- "Launch new product with multiple features"
- "Refactor 5 services and integrate them"
- "Performance optimization across full stack"

**Telltale sign**: If you're thinking about phases and coordination → Orchestrator mode

---

## Mode Transition Decision Tree

### From Architect Mode

```
Architect mode is complete
│
├─ Ready to implement?
│  └─ YES → Switch to Code Mode
│
├─ Need to understand something first?
│  └─ YES → Switch to Ask Mode
│
├─ Found design flaw while planning?
│  └─ YES → Stay in Architect, iterate design
│
└─ Coordinating large project?
   └─ YES → Switch to Orchestrator Mode
```

**Example transitions**:

1. **Design → Code**
   ```
   Architect completed design for user service.
   Ready to implement.
   → Switch to Code mode to implement services
   ```

2. **Design → Ask**
   ```
   During design, realized we don't understand
   how JWT refresh tokens work.
   → Switch to Ask mode to learn
   → Return to Architect to continue design
   → Switch to Code to implement
   ```

3. **Design → Orchestrator**
   ```
   Architecture spans 3 services, database migration,
   and client updates. Too complex for single flow.
   → Switch to Orchestrator to coordinate
   ```

### From Code Mode

```
Code mode task is complete
│
├─ Ready for next task in plan?
│  └─ YES → Continue in Code Mode
│
├─ Tests failing, need to investigate?
│  └─ YES → Switch to Debug Mode
│
├─ Hit a complex issue, need to redesign?
│  └─ YES → Switch to Architect Mode
│
├─ Need to understand something before continuing?
│  └─ YES → Switch to Ask Mode
│
└─ Whole project done?
   └─ YES → Mission complete!
```

**Example transitions**:

1. **Code → Code**
   ```
   Implemented user service successfully.
   Next task: implement auth service.
   → Continue in Code mode
   ```

2. **Code → Debug**
   ```
   Tests are failing with unclear error messages.
   Need to debug to understand issue.
   → Switch to Debug mode
   → Debug identifies root cause
   → Switch back to Code to fix
   ```

3. **Code → Architect**
   ```
   Started implementing feature, realized the design
   doesn't account for edge cases we found.
   → Switch to Architect to redesign
   → Switch back to Code to implement revised design
   ```

### From Debug Mode

```
Debug investigation complete
│
├─ Root cause identified?
│  └─ YES → Switch to Code Mode
│       (unless it's a design flaw)
│       └─ Design flaw → Architect Mode
│
└─ Still investigating?
   └─ YES → Stay in Debug Mode
```

**Example transitions**:

1. **Debug → Code**
   ```
   Investigation shows user cache isn't invalidating
   on updates. Root cause found.
   → Switch to Code to add cache invalidation
   ```

2. **Debug → Architect**
   ```
   Investigation reveals fundamental design flaw:
   concurrent updates not properly handled.
   → Switch to Architect to redesign
   → Switch to Code to implement fix
   ```

### From Ask Mode

```
Learning/understanding complete
│
├─ Ready to implement?
│  └─ YES → Switch to Code Mode
│
├─ Need to plan/design?
│  └─ YES → Switch to Architect Mode
│
├─ Need to investigate something?
│  └─ YES → Switch to Debug Mode
│
└─ Need more understanding?
   └─ YES → Continue in Ask Mode
```

**Example transitions**:

1. **Ask → Code**
   ```
   Understood how authentication works.
   Now ready to implement new features.
   → Switch to Code to implement
   ```

2. **Ask → Architect**
   ```
   Learned current architecture has limitations.
   Need to plan how to restructure.
   → Switch to Architect to design improvements
   ```

### From Orchestrator Mode

```
Orchestrator delegates work
│
└─ Wait for delegated modes to complete
   └─ When task completes
      ├─ Is there more work?
      │  └─ YES → Delegate next task
      └─ All work done?
         └─ YES → Project complete!
```

**Note**: Orchestrator typically stays in coordination role. It delegates to other modes and waits for completion rather than switching modes.

---

## Transition Examples

### Example 1: Building a Feature from Scratch

```
Start: Feature requirements given

1. Architect Mode
   └─ Design the feature
      ✓ Create implementation plan
      ✓ Design architecture
      ✓ Document specifications
      → Switch when: Design is ready

2. Code Mode
   └─ Implement the design
      ✓ Create files and structure
      ✓ Implement functionality
      ✓ Write tests
      ↓ Tests fail? Switch to Debug
      → Switch when: Implementation complete and tests pass

3. (Possibly) Debug Mode
   └─ If tests fail
      ✓ Investigate why tests fail
      ✓ Identify root cause
      ✓ Plan fix
      → Switch back to Code to fix

END: Feature implemented and tested
```

### Example 2: Fixing a Bug

```
Start: Bug reported - "Login fails for users with special characters in password"

1. Debug Mode
   └─ Investigate the bug
      ✓ Create test case that reproduces bug
      ✓ Trace where it fails
      ✓ Find: Password validation doesn't handle special chars
      ✓ Identify: Hash function doesn't escape properly
      → Switch when: Root cause identified

2. Code Mode
   └─ Fix the bug
      ✓ Apply fix to hash function
      ✓ Verify test now passes
      ✓ Run all tests (ensure no regressions)
      → Switch when: Bug fixed and tested

END: Bug fixed
```

### Example 3: Large System Refactor

```
Start: "Refactor monolith into microservices"

1. Orchestrator Mode
   └─ Plan the project
      ✓ Break into phases
      ✓ Identify dependencies
      ✓ Create task list
      → Delegate: Architect for design
      → Delegate: Code for implementation
      → Delegate: Debug for testing

2. Architect Mode (delegated)
   └─ Design new architecture
      ✓ Design service boundaries
      ✓ Design service interactions
      ✓ Plan data migration
      → Back to Orchestrator

3. Code Mode (delegated)
   └─ Implement Service A
      ✓ Create service code
      ✓ Write tests
      → Back to Orchestrator

4. Code Mode (delegated)
   └─ Implement Service B
      ✓ Create service code
      ✓ Write tests
      → Back to Orchestrator

5. Code Mode (delegated)
   └─ Implement Service C
      ✓ Create service code
      ✓ Write tests
      → Back to Orchestrator

6. Code Mode (delegated)
   └─ Implement integration layer
      ✓ Create API gateway
      ✓ Handle routing
      ✓ Handle inter-service communication
      → Back to Orchestrator

7. Debug Mode (delegated)
   └─ Test integration
      ✓ Run integration tests
      ✓ Identify issues
      → Back to Orchestrator

8. Code Mode (delegated)
   └─ Fix issues found
      ✓ Apply fixes
      ✓ Re-test
      → Back to Orchestrator

END: Refactor complete, old code removed
```

### Example 4: Learning Before Building

```
Start: Need to use Redis but unfamiliar with it

1. Ask Mode
   └─ Learn about Redis
      ✓ What is Redis?
      ✓ How is it used in this codebase?
      ✓ What are common patterns?
      ✓ How does cache invalidation work?
      → Switch when: Understanding complete

2. Architect Mode
   └─ Design caching strategy
      ✓ Where to add caching
      ✓ Cache invalidation strategy
      ✓ Implementation plan
      → Switch when: Design ready

3. Code Mode
   └─ Implement caching
      ✓ Add Redis integration
      ✓ Add caching logic
      ✓ Add cache invalidation
      ✓ Write tests
      → Switch when: Implementation complete

END: Caching implemented
```

---

## Transition Guidelines

### 1. Always Explain Transitions

**When switching modes, state**:
- What was accomplished in current mode
- Why you're switching
- What the next mode will do
- Any relevant context

**Bad**: Just switching without explanation
**Good**:
```
Architect mode design complete. The user service API is specified,
database schema is designed, and error handling is planned.

Switching to Code mode to implement the user service according
to the design specifications.
```

### 2. Provide Context for Next Mode

**Give next mode what it needs**:
- Design documents (if switching from Architect)
- Investigation findings (if switching from Debug)
- Implementation specifics (if switching from Code)

### 3. Don't Abandon Work

**If switching mid-task**:
- Explain why you're pausing
- Document where you left off
- State what needs to happen next
- Return to complete it

**Example**:
```
Pausing Code mode implementation.

CONTEXT:
- Implemented authentication service endpoints
- Tests written but failing
- Error is in token validation logic (not in endpoint code)

SWITCHING TO: Debug mode to investigate token validation error

NEXT STEPS:
- Debug identifies root cause
- Return to Code mode to fix token validation
- Complete implementation
```

### 4. Minimize Context Switching

**Better to batch work in single mode**:

❌ Less efficient:
```
Code (implement feature A)
↓ Switch
Ask (learn about caching)
↓ Switch
Code (implement feature B)
↓ Switch
Debug (fix issue)
```

✅ More efficient:
```
Ask (learn everything needed)
↓ Switch
Code (implement both features)
↓ Switch
Debug (fix all issues together)
```

### 5. Return to Orchestrator When Appropriate

**For coordinated projects**:
- Delegate to specialized modes
- Let them complete their work
- Return to Orchestrator for next task
- Don't bounce between modes unnecessarily

---

## Anti-Patterns

### Anti-Pattern: Mode Paralysis

**Problem**: Can't decide which mode to use
**Solution**: Use decision tree, start with best guess, adjust if wrong

### Anti-Pattern: Staying in Wrong Mode

**Problem**: Trying to code in Architect mode (won't work)
**Solution**: If you hit mode constraints, switch immediately

### Anti-Pattern: Frequent Switching

**Problem**: Switching modes every few minutes
**Why it's bad**: Context switching overhead
**Solution**: Batch work in single mode, switch only when needed

### Anti-Pattern: Unclear Transitions

**Problem**: Switching without explaining why
**Why it's bad**: Next mode loses context
**Solution**: Always explain transitions

### Anti-Pattern: Forgetting Previous Work

**Problem**: Switching modes and losing context
**Why it's bad**: Duplicated work, missed opportunities
**Solution**: Document before switching

---

## Quick Reference: Mode Switching

| From | To | When | Context Needed |
|------|----|----|---|
| Architect | Code | Design done | Design spec, task list |
| Architect | Ask | Need to learn | Learning goals |
| Architect | Orchestrator | Large project | Design overview |
| Code | Debug | Tests fail | Test output, code context |
| Code | Architect | Hit complexity | Current implementation, issue |
| Code | Ask | Need understanding | Question, code location |
| Debug | Code | Root cause found | Investigation findings, fix plan |
| Debug | Architect | Design flaw | Investigation findings, issue |
| Ask | Code | Ready to implement | Understanding gained, spec |
| Ask | Architect | Need to plan | Learning, requirements |
| Orchestrator | Any | Delegate task | Task specification |
| Any | Orchestrator | Coordinating large work | Work breakdown, timeline |

---

## When NOT to Switch

### Don't switch if task is almost done in current mode
- Switching costs context
- Usually faster to finish in current mode

### Don't switch just because you could
- Each switch has overhead
- Only switch when necessary

### Don't switch on every small question
- Batch questions and ask at end
- Or ask briefly without full mode switch

---

## Key Principles

1. **Match Mode to Task**: Right mode for right task
2. **Explain Transitions**: Clear reasoning prevents confusion
3. **Batch Work**: Do similar work in single mode
4. **Minimize Switching**: Each switch costs time
5. **Provide Context**: Next mode needs what previous mode learned

---

## Related Patterns

- [Architect Mode](./architect-mode.md) - Planning mode
- [Code Mode](./code-mode.md) - Implementation mode
- [Debug Mode](./debug-mode.md) - Investigation mode
- [Ask Mode](./ask-mode.md) - Learning mode
- [Orchestrator Mode](./orchestrator-mode.md) - Coordination mode

---

**Last Updated**: 2025-12-28
**Applicability**: All AI-assisted development workflows
**Source**: MODE_CAPABILITIES.md from agentic-dev-patterns

*"The right transition at the right time keeps projects flowing smoothly."*
