# Code Mode

**Purpose**: Write, modify, and refactor code with full tool access.

**Value**: Most development work happens here. Code mode is where design becomes reality.

**Best For**: Implementation, bug fixes, testing, configuration, refactoring, almost all development work.

---

## Capabilities

### Can Do

- Create new files and directories
- Modify existing code
- Refactor code structure
- Fix bugs and issues
- Add new features
- Update configuration files
- Write tests
- Execute commands and scripts
- Run development servers
- Deploy changes
- Use all available file modification tools
- Read files for context
- Search codebase

### Cannot Do

- Nothing! Code mode has full access

**Note**: While Code mode has full capabilities, it's most efficient when Architect mode has done upfront planning, and Debug mode has done systematic investigation of issues.

---

## Allowed File Patterns

**Can Access**: All files (no restrictions)
- Source code: `.js`, `.py`, `.ts`, `.go`, `.java`, `.rs`, etc.
- Configuration: `.json`, `.yaml`, `.toml`, `.env`, `.ini`
- Tests: `.test.js`, `_test.py`, `.spec.ts`
- Markup: `.md`, `.html`, `.xml`
- Everything else

---

## When to Use Code Mode

### Start with Code When

- Implementation plan is ready (from Architect)
- Bug is identified (from Debug)
- Feature scope is clear
- Need to write or modify code
- Most development tasks

### Example Situations

**Scenario 1: Building a Planned Feature**
- Task: Implement the user authentication service designed in Architect mode
- Code mode steps:
  1. Create service file structure
  2. Implement authentication logic
  3. Write tests
  4. Add API endpoints
  5. Integrate with existing system
  6. Verify tests pass

**Scenario 2: Quick Bug Fix**
- Task: Fix login button not working on mobile
- Code mode steps:
  1. Locate button component
  2. Identify issue (CSS, JS, or API)
  3. Apply fix
  4. Test on mobile
  5. Verify no regressions

**Scenario 3: Feature Enhancement**
- Task: Add remember-me checkbox to login form
- Code mode steps:
  1. Update login form component
  2. Modify authentication service
  3. Update session management
  4. Test user flow
  5. Verify security implications

**Scenario 4: Refactoring**
- Task: Extract common validation logic into utilities
- Code mode steps:
  1. Create utility module
  2. Move validation functions
  3. Update imports across codebase
  4. Run tests
  5. Verify functionality preserved

---

## Development Workflow Patterns

### Pattern: Feature Implementation

**Flow**: Architect plan → Code implementation

1. **Review the design**: Read design document from Architect mode
2. **Set up**: Create file structure as specified
3. **Implement core logic**: Write the main functionality
4. **Add tests**: Write tests for new functionality
5. **Integrate**: Connect to existing code
6. **Verify**: Run all tests, check functionality

**Best practice**: Implement in logical pieces, commit after each piece works.

### Pattern: Bug Fix Workflow

**Flow**: Debug investigation → Code fix

1. **Review the diagnosis**: Understand what Debug mode found
2. **Locate the issue**: Find problematic code
3. **Apply minimal fix**: Fix the specific problem
4. **Test the fix**: Verify it works and doesn't break anything
5. **Consider root cause**: Should we prevent this pattern?
6. **Add regression test**: Ensure bug doesn't come back

**Best practice**: Keep fixes focused. One bug = one clear fix.

### Pattern: Refactoring

**Flow**: Code analysis → Refactoring → Verification

1. **Understand current code**: What does it do?
2. **Identify improvement**: What's the goal?
3. **Plan changes**: How to restructure?
4. **Refactor incrementally**: Change small pieces, test after each
5. **Run full test suite**: Ensure nothing broke
6. **Commit**: Clear commit message explaining change

**Best practice**: Never change logic AND structure simultaneously.

### Pattern: Test-First Development

**When**: Complex logic or fixing bugs

1. **Write failing test**: Clarifies what we want
2. **Write minimal implementation**: Make test pass
3. **Refactor**: Improve code quality
4. **Verify**: Test still passes, other tests pass

**Best practice**: Tests become documentation of expected behavior.

---

## Decision Points in Code Mode

### Should I Create a New File or Modify Existing?

**Create new file when**:
- Logically separate concern
- Can be tested independently
- Follows existing patterns (e.g., similar files exist)
- Doesn't create circular dependencies

**Modify existing file when**:
- Extending existing functionality
- Small, related change
- Keeps cohesive functionality together

### Should I Refactor While Implementing?

**Yes, refactor if**:
- You see duplicate code while implementing
- Code style is very inconsistent
- Improves clarity of your implementation

**No, refactor if**:
- It's not related to current feature
- Tests don't cover the code you're refactoring
- Would delay shipping feature significantly

**Better approach**: Create a TODO comment, ship feature, refactor later.

### Should I Make This Change Now?

**Make the change now if**:
- It's required for the feature you're building
- It's a small related improvement
- Tests exist and will catch issues

**Create an issue for later if**:
- It's a nice-to-have, not required
- Would delay feature shipping
- Needs more analysis first

---

## Code Quality Principles

### 1. Clear Intent

**Write code that expresses intent**:
```javascript
// Bad: What does 0x1 << 4 mean?
const result = data & 0x1 << 4;

// Good: What are we checking?
const isAdminUser = (permissions & ADMIN_PERMISSION) === ADMIN_PERMISSION;
```

### 2. Testable Code

**Write code that's easy to test**:
```javascript
// Bad: Tightly coupled to database
function getUser(id) {
  return database.query(`SELECT * FROM users WHERE id = ${id}`);
}

// Good: Separated concerns
function getUser(id, database) {
  return database.query(`SELECT * FROM users WHERE id = ${id}`);
}
```

### 3. Single Responsibility

**Each function does one thing**:
```javascript
// Bad: Does parsing AND processing AND formatting
function processUserData(raw) { ... }

// Good: Separated concerns
function parseUserData(raw) { ... }
function validateUserData(data) { ... }
function formatUserData(data) { ... }
```

### 4. Fail Fast

**Validate inputs early**:
```javascript
// Bad: Error happens deep in function
function calculateTotal(items) {
  let total = 0;
  for (const item of items) { // What if items is null?
    total += item.price;
  }
  return total;
}

// Good: Validate immediately
function calculateTotal(items) {
  if (!Array.isArray(items)) {
    throw new Error('items must be an array');
  }
  let total = 0;
  for (const item of items) {
    total += item.price;
  }
  return total;
}
```

---

## When to Switch Modes

### Switch to Architect Mode When

- Stuck on how to proceed
- Need to plan complex changes
- Realize design was incomplete
- Want second opinion on approach

**Example transition**:
```
Hit a complexity while implementing the payment system. The design
didn't account for how subscriptions interact with one-time purchases.

Switching to Architect mode to redesign the payment flow before
continuing implementation.
```

### Switch to Debug Mode When

- Tests fail and cause is unclear
- Unexpected behavior during implementation
- Need to investigate error
- Performance problem needs diagnosis

**Example transition**:
```
Tests are failing on certain data inputs, but the error message
is unclear. Need to debug what's happening.

Switching to Debug mode to investigate and trace the issue.
```

### Switch to Ask Mode When

- Need to understand something
- Learning how existing code works
- Understanding error messages
- Getting recommendations

**Example transition**:
```
I'm modifying the authentication system but need to understand
how the existing JWT refresh token logic works.

Switching to Ask mode to get explanation of current implementation.
```

---

## Common Code Mode Patterns

### Pattern: Incremental Implementation

**Don't** try to write everything at once.

```javascript
// Step 1: Basic structure
function processPayment(amount, cardToken) {
  // TODO: Implement
}

// Step 2: Add core logic
function processPayment(amount, cardToken) {
  const charge = chargeCard(cardToken, amount);
  return charge;
}

// Step 3: Add error handling
function processPayment(amount, cardToken) {
  try {
    const charge = chargeCard(cardToken, amount);
    return charge;
  } catch (error) {
    logError('Payment failed', { amount, error });
    throw error;
  }
}

// Step 4: Add validation
function processPayment(amount, cardToken) {
  if (amount <= 0) throw new Error('Amount must be positive');
  if (!cardToken) throw new Error('Card token required');

  try {
    const charge = chargeCard(cardToken, amount);
    return charge;
  } catch (error) {
    logError('Payment failed', { amount, error });
    throw error;
  }
}
```

### Pattern: Change Existing Code Safely

1. **Write test for current behavior** (even if buggy)
2. **Make the change**
3. **Verify test still passes**
4. **Update test if behavior should change**
5. **Add new tests for new behavior**

### Pattern: Large Refactors

For significant refactors:
1. **Create new structure alongside old**
2. **Gradually migrate code**
3. **Keep tests passing throughout**
4. **Remove old code once empty**

Example: Migrating from old auth to new auth:
```javascript
// Phase 1: Both systems exist
const user = authV2.getUser() || authV1.getUser();

// Phase 2: Mostly V2, fallback to V1
const user = authV2.getUser();
if (!user && legacy) user = authV1.getUser();

// Phase 3: V2 only
const user = authV2.getUser();
```

---

## Anti-Patterns

### Anti-Pattern: Coding Without a Plan

**Problem**: Implementing before design is clear
**Symptom**: Lots of backtracking, code doesn't fit together
**Solution**: Use Architect mode first, or ask before coding

### Anti-Pattern: Ignoring Tests

**Problem**: Writing code without tests
**Symptom**: Can't refactor safely, regressions appear
**Solution**: Write tests alongside code

### Anti-Pattern: Mixing Concerns

**Problem**: One function doing multiple things
**Symptom**: Hard to test, hard to reuse
**Solution**: Break into smaller, focused functions

### Anti-Pattern: Silent Failures

**Problem**: Errors happening without notification
**Symptom**: User sees nothing, logging shows errors
**Solution**: Fail fast with clear error messages

---

## Interaction with Other Modes

### With Architect Mode

**Flow**: Architect designs → Code implements
- Architect provides: Design spec, task list
- Code provides: Feedback on design viability
- Good interaction: Code finds issues, switches to Architect to redesign

### With Debug Mode

**Flow**: Tests fail → Debug investigates → Code fixes
- Debug identifies root cause
- Code implements fix and adds tests
- Good interaction: Debug findings → Code improvements

### With Ask Mode

**Flow**: Code uncertain → Ask explains → Code continues
- Ask clarifies API, library, or existing code
- Code continues implementation with better understanding
- Good interaction: Quick clarification without context loss

### With Orchestrator Mode

**Flow**: Orchestrator delegates to Code for implementation
- Orchestrator: Manages project phases
- Code: Executes individual implementation tasks
- Good interaction: Clear task handoff with all context

---

## Key Principles

1. **Write for Others**: Code is read much more than written
2. **Test What You Build**: Tests prevent regressions and enable refactoring
3. **Commit Often**: Small, clear commits are easier to understand and revert
4. **Keep It Simple**: Prefer clarity over cleverness
5. **Know When to Refactor**: Improve as you go, but focus on shipping first

---

## Related Patterns

- [Mode Transitions](./mode-transitions.md) - When to switch from Code
- [Architect Mode](./architect-mode.md) - Planning before coding
- [Debug Mode](./debug-mode.md) - Fixing issues found in Code
- [Testing Patterns](../testing-patterns/README.md) - Test strategies

---

**Last Updated**: 2025-12-28
**Applicability**: Code-focused development workflows
**Source**: MODE_CAPABILITIES.md from agentic-dev-patterns

*"Code is how you make ideas real."*
