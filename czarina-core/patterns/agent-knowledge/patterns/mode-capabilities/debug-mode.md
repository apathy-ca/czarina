# Debug Mode

**Purpose**: Systematic troubleshooting and investigation of issues.

**Value**: Reduces debugging time by 40-60% through methodical investigation rather than random fixes.

**Best For**: Errors, unexpected behavior, performance issues, understanding system state.

---

## Capabilities

### Can Do

- Investigate errors and error messages
- Analyze logs and traces
- Add logging statements for diagnosis
- Run diagnostic commands
- Check system state and configuration
- Trace code execution
- Identify root causes
- Propose fixes based on findings
- Create minimal reproducible examples
- Analyze performance bottlenecks

### Cannot Do

- Implement actual fixes (switch to Code mode for that)
- Perform major refactoring
- Develop new features
- Make production changes

**Note**: Debug mode focuses on investigation and diagnosis, not implementation. Once the root cause is identified, switch to Code mode to fix it.

---

## Allowed File Patterns

**Can Read**: All files (for investigation)

**Can Modify**:
- Add logging statements to any file
- Create temporary diagnostic files
- Add debug configuration

**Cannot**: Make permanent changes to fix issues (that's Code mode)

---

## When to Use Debug Mode

### Start with Debug When

- Tests are failing with unclear errors
- Application crashes or behaves unexpectedly
- Performance is degraded
- Feature works for some cases but not others
- Error messages are vague or misleading
- Want to understand system behavior

### Example Situations

**Scenario 1: Failing Test**
- Symptom: Test fails with "AssertionError: expected 3 to equal 4"
- Debug steps:
  1. Add logging to see what values are being processed
  2. Trace function calls to see execution flow
  3. Check test setup and data
  4. Identify what's happening differently than expected
  5. Switch to Code mode to fix the issue

**Scenario 2: Application Crash**
- Symptom: Server crashes after deployment, logs show generic error
- Debug steps:
  1. Review crash log in detail
  2. Reproduce error with minimal example
  3. Add logging around crash point
  4. Check related services and dependencies
  5. Identify what input triggers crash
  6. Switch to Code mode to add proper error handling

**Scenario 3: Performance Issue**
- Symptom: Page takes 10 seconds to load
- Debug steps:
  1. Profile network requests
  2. Identify slowest operations
  3. Check query performance
  4. Trace bottleneck location
  5. Understand why operation is slow
  6. Switch to Code mode to optimize

**Scenario 4: Intermittent Bug**
- Symptom: Feature works sometimes, fails others
- Debug steps:
  1. Collect all failure cases
  2. Identify common characteristics
  3. Test with specific data patterns
  4. Reproduce consistently
  5. Narrow down to root cause
  6. Switch to Code mode to fix race condition/edge case

---

## Debugging Methodology

### Pattern: Systematic Investigation

**Don't** guess or apply random fixes. **Do** follow the scientific method:

1. **Observe**: Gather evidence
   - What exactly happens?
   - When does it happen?
   - What precedes it?
   - Who does it affect?

2. **Hypothesize**: Form a theory
   - What could cause this behavior?
   - What's the most likely cause?
   - What are alternative explanations?

3. **Test**: Investigate the hypothesis
   - Add logging to test
   - Look for evidence in logs
   - Try to reproduce
   - Gather data

4. **Conclude**: Identify root cause
   - This is why it's happening
   - This is the proof
   - This is where to fix it

5. **Plan Fix**: Decide how to address
   - What needs to change?
   - What's the minimal fix?
   - What else could this affect?

### Pattern: The 5 Whys

**When** you identify an issue, ask "why" five times to find root cause:

```
Issue: User reports login failing
Why #1: Password validation returns false
Why #2: Password hash doesn't match database value
Why #3: Hashing function was changed last week
Why #4: New hashing algorithm wasn't applied to existing passwords
Why #5: Migration script didn't run for existing users

Root Cause: Existing users weren't migrated to new hashing algorithm
Fix: Run migration for existing users or support both algorithms
```

### Pattern: Reproduce First

**Always** get the issue to happen consistently before investigating deeply:

1. **Simple reproduction**: Write code that shows the problem
2. **Minimal reproduction**: Strip away everything not needed
3. **Consistent reproduction**: Show it happens every time
4. **Test reproduction**: Verify it's the issue (test fails)

Example:
```javascript
// Test that reproduces the bug
test('should handle empty user list', () => {
  const result = calculateTotal([]);
  expect(result).toBe(0);  // Fails: result is NaN
});
```

Now we have something to debug.

---

## Investigation Techniques

### Technique: Logging Strategy

**Add logs at key points**:
```javascript
// Before function
console.debug('getUser called with:', { id });

// Inside function
console.debug('Database query result:', result);

// Conditional logging
if (!result) {
  console.error('User not found:', { id });
}

// After operation
console.debug('getUser returning:', result);
```

**Log levels**:
- `debug`: Detailed info for debugging
- `info`: Normal operation events
- `warn`: Something unexpected but recovered
- `error`: Something failed, needs attention

### Technique: Tracing Execution

**Follow the code path**:
```javascript
function process(data) {
  console.log('1. process() called');
  const validated = validate(data);
  console.log('2. validate returned:', validated);

  const transformed = transform(validated);
  console.log('3. transform returned:', transformed);

  return save(transformed);
  console.log('4. save completed'); // Won't run if save fails
}
```

### Technique: Check Assumptions

**Question what you believe**:
- Is the data what I think it is?
- Is the function called with right arguments?
- Is the error message accurate?
- Is the timestamp correct?
- Is the condition evaluated as I expect?

Add checks:
```javascript
function processUser(user) {
  // Check assumption: user is an object
  console.assert(typeof user === 'object', 'user should be object');

  // Check assumption: user has required fields
  console.assert(user.id, 'user should have id');
  console.assert(user.email, 'user should have email');

  // Now we can proceed safely
}
```

### Technique: Compare Expected vs Actual

**Make explicit what should happen vs what does**:
```javascript
// Expected: User has email
const user = { name: 'Alice', id: 1 }; // Missing email!
console.log('Expected email:', 'test@example.com');
console.log('Actual email:', user.email); // undefined

// This shows the bug clearly
```

---

## Common Debugging Scenarios

### Scenario: API Returns Wrong Data

```
Observation: API endpoint returns user object without email
```

**Investigate**:
1. Check database - does user have email? ✓ Yes
2. Check query - is email field included? ✗ No
3. Check API code - is email mapped to response? ✗ No
4. Root cause: Response mapper excludes email field

**Fix**: Update response mapper to include email

### Scenario: Test Passes Locally, Fails in CI

```
Observation: Test works on my machine, fails on CI server
```

**Investigate**:
1. What's different? Environment variables, database state, time, etc.
2. Check test setup - does it depend on external state?
3. Check time-dependent code - are we using hardcoded time?
4. Check database - is CI using different data?
5. Root cause: Test depends on database state, CI has different data

**Fix**: Make test independent of database state

### Scenario: Performance Degrades Over Time

```
Observation: Application gets slower as time passes
```

**Investigate**:
1. Check memory usage - is it growing? (memory leak)
2. Check database - are queries getting slower? (missing index)
3. Check cache - is cache not invalidating? (stale data)
4. Check connections - are connections accumulating? (not closing)
5. Root cause: Database connections aren't being closed

**Fix**: Ensure connections close properly

### Scenario: Works for User A, Not User B

```
Observation: Feature works for some users but not others
```

**Investigate**:
1. What's different about the users? (location, subscription level, etc.)
2. What data differs? (stored data, configuration, permissions)
3. Check user-specific data - is there bad data?
4. Check permissions - does user have access?
5. Root cause: Certain users don't have required permission

**Fix**: Fix permission assignment or request

---

## Tools and Commands

### Logging Tools

**JavaScript/Node**:
```javascript
console.log() // Basic logging
console.debug() // Debugging info
console.error() // Error messages
console.table() // Table format for data
```

**Python**:
```python
import logging
logging.debug() # Debugging info
logging.info() # General info
logging.error() # Error messages
```

### Diagnostic Commands

**System**:
```bash
# Check running processes
ps aux | grep [process]

# Check open ports
netstat -an | grep LISTEN

# Check disk space
df -h

# Check memory
free -h

# Check CPU
top -b -n 1
```

**Application**:
```bash
# Run with verbose logging
./app --verbose

# Run with debugging
./app --debug

# Run with profiling
python -m cProfile app.py

# Check configuration
cat config.env
```

---

## When to Switch Modes

### Switch to Code Mode When

- Root cause is identified and clear
- Know exactly what needs to be fixed
- Ready to implement solution
- Have test case that reproduces issue

**Example transition**:
```
Investigation complete. Root cause identified:

The issue is in the user service's caching layer. When a user
updates their profile, the cache isn't invalidated, so old data
is served. The cache.invalidate() call is missing after the update.

Switching to Code mode to fix by adding cache invalidation
and adding a test to prevent regression.
```

### Switch to Architect Mode When

- Root cause reveals design flaw
- Issue affects multiple systems
- Systematic approach needed
- Need to redesign system component

**Example transition**:
```
Investigation revealed a fundamental flaw in how we handle
concurrent updates. The current design doesn't account for
race conditions between services.

Switching to Architect mode to redesign the update coordination
before implementing the fix.
```

### Switch to Ask Mode When

- Need to understand existing code
- Learning about technology or library
- Clarifying what an error means
- Understanding design decision

**Example transition**:
```
I've found the error location but need to understand how
the JWT refresh token flow currently works before I can
properly debug what's wrong.

Switching to Ask mode to get explanation of the auth flow.
```

---

## Debugging Anti-Patterns

### Anti-Pattern: Random Fixes

**Problem**: Applying random changes hoping one works
**Why it happens**: Under pressure, guessing seems faster
**Solution**: Follow systematic debugging process
**Reality**: Systematic approach is faster overall

### Anti-Pattern: Blaming External Code

**Problem**: Assuming the library/framework is broken
**Why it happens**: Library seems complex
**Solution**: Verify your code is using library correctly
**Reality**: Usually it's usage issue, not library bug

### Anti-Pattern: Logging Blindly

**Problem**: Adding 100 logging statements
**Why it happens**: Not sure where issue is
**Solution**: Think about where issue could be, log strategically
**Reality**: Smart logging finds issues faster

### Anti-Pattern: Changing Too Much

**Problem**: Changing multiple things trying to fix issue
**Why it happens**: Want to fix it fast
**Solution**: Change one thing at a time, test after each
**Reality**: Can't tell which change fixed it otherwise

---

## Key Principles

1. **Trust the Data**: Logs and error messages are telling you something
2. **Reproduce First**: Can't debug what you can't reproduce
3. **Think Systematically**: Scientific method is faster than guessing
4. **Change One Thing**: At a time, so you know what fixed it
5. **Document Findings**: Helps you and helps future you
6. **Question Assumptions**: Most bugs come from incorrect assumptions

---

## Related Patterns

- [Mode Transitions](./mode-transitions.md) - When to switch from Debug
- [Code Mode](./code-mode.md) - Implementing fixes
- [Error Recovery Patterns](../error-recovery/README.md) - Common errors
- [Testing Patterns](../testing-patterns/README.md) - Writing tests to prevent issues

---

**Last Updated**: 2025-12-28
**Applicability**: Debug-focused investigation workflows
**Source**: MODE_CAPABILITIES.md from agentic-dev-patterns

*"Methodical debugging beats random fixes every time."*
