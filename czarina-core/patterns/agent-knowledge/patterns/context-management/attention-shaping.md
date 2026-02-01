# Attention Shaping

**Purpose**: Techniques for directing AI assistant attention to the most important information.

**Value**: Faster task completion, fewer errors, better decision-making.

---

## Understanding Attention

### What is Attention in AI Assistants?

**Attention** is how an AI model focuses on different parts of the input context when generating responses:
- Not all information is weighted equally
- Recent information often has higher attention
- Explicit emphasis increases attention
- Structure and formatting affect attention

### Why Shape Attention?

**Problem**: AI has access to all context but may not focus on most important parts.

**Solution**: Actively shape what the AI pays attention to.

**Impact**:
- 40-50% reduction in mistakes
- Faster identification of relevant information
- Better alignment with user intent

---

## Pattern: Explicit Emphasis

### Problem
Important information buried in large context.

### Solution
**Use formatting and explicit markers to highlight critical information**:

```markdown
BAD (no emphasis):
The payment processing code is in src/services/payment_service.py.
The validation happens at line 145. There's a bug where refunds
over $1000 fail. The Stripe API key is in the .env file.

GOOD (with emphasis):
🚨 CRITICAL BUG: Refunds over $1000 failing

Location: src/services/payment_service.py, line 145

Issue: Validation logic rejects amounts > 100000 (cents)
Expected: Should allow refunds up to original payment amount

Context: Stripe API configured in .env (working for payments)
```

### Emphasis Techniques

**Visual Markers**:
- ⚠️ Warnings
- 🚨 Critical issues
- ✅ Confirmed facts
- ❌ Things to avoid
- 💡 Important insights

**Formatting**:
- **Bold** for key terms
- `code blocks` for technical details
- > Blockquotes for important notes
- Headers for section importance

**Explicit Labels**:
- "CRITICAL:"
- "IMPORTANT:"
- "NOTE:"
- "REMEMBER:"
- "DO NOT:"

---

## Pattern: Attention Anchors

### Problem
Need to ensure specific information isn't overlooked.

### Solution
**Create attention anchors that explicitly direct focus**:

```markdown
## ATTENTION: Authentication Changes

Before proceeding with the new feature, you MUST be aware:

1. Auth system was refactored yesterday
   - Old: JWT tokens in headers
   - New: Session cookies + CSRF tokens
   - Location: src/middleware/auth.py (completely rewritten)

2. All API endpoints now require CSRF token
   - Get token from GET /auth/csrf-token
   - Include in X-CSRF-Token header
   - Documented in src/api/README.md

3. Tests must be updated to use new auth
   - Example: tests/test_auth.py (updated)
   - Pattern: Use test_client.get_csrf_token() helper

Proceed with new feature using NEW auth system.
```

### When to Use Anchors

**Critical scenarios**:
- Recent breaking changes
- Security requirements
- Data loss risks
- Important constraints
- Known pitfalls

**Placement**:
- Start of conversation
- Before relevant task
- After context switches

---

## Pattern: Progressive Disclosure

### Problem
Too much information at once dilutes attention.

### Solution
**Reveal information progressively as needed**:

```markdown
BAD (information overload):
The system has UserService, PaymentService, NotificationService,
EmailService, SMSService, AuthService, LoggingService, CacheService,
DatabaseService, and QueueService. The UserService handles registration,
login, profile updates, password resets, email verification, and account
deletion. It uses bcrypt for passwords, JWT for tokens, and sends emails
via EmailService...

GOOD (progressive disclosure):
Phase 1 (Immediate Need):
Task: Add email verification to registration
Primary: UserService (handles registration)

[After understanding UserService]

Phase 2 (Dependencies):
UserService depends on:
- EmailService (for sending verification emails)
- AuthService (for generating verification tokens)

[After understanding flow]

Phase 3 (Implementation Details):
Email verification pattern:
- Generate token via AuthService.generate_verification_token()
- Send email via EmailService.send_verification()
- Verify via UserService.verify_email(token)
```

### Disclosure Strategy

**Level 1: Task Overview** (10% of information)
- What needs to be done
- Primary file/component
- Expected outcome

**Level 2: Context** (30% of information)
- Dependencies
- Related components
- Key constraints

**Level 3: Details** (60% of information)
- Implementation specifics
- Edge cases
- Configuration

---

## Pattern: Recency Emphasis

### Problem
Important information mentioned early in conversation forgotten.

### Solution
**Restate critical information closer to when it's needed**:

```markdown
[Beginning of conversation]
"The database is PostgreSQL 14 on port 5433."

[50 messages later, about to write database code]
"Remember: Our PostgreSQL database is on port 5433 (not default 5432).
Updating database connection code now..."

[Avoid]
[50 messages later]
"Writing database connection code..."
[AI might default to port 5432]
```

### Restatement Triggers

**When to restate**:
- Before critical operation
- After long investigation
- When switching contexts
- Before potentially destructive action

**What to restate**:
- Security constraints
- Configuration specifics
- Known bugs/pitfalls
- Important decisions

---

## Pattern: Negative Attention

### Problem
Need to ensure AI doesn't do something dangerous.

### Solution
**Use explicit "DO NOT" statements with emphasis**:

```markdown
🚨 DO NOT:
- Do NOT modify the production database connection string
- Do NOT commit the .env file
- Do NOT delete the migrations/ directory
- Do NOT change the authentication middleware without review

Safe to do:
- ✅ Modify test database configuration
- ✅ Update .env.example file
- ✅ Add new migrations (do not delete existing)
- ✅ Add new authentication methods (do not remove existing)
```

### Effectiveness Multipliers

**Make it impossible to miss**:
1. Use visual emphasis (🚨, ❌)
2. State positively what TO do (not just what not to do)
3. Place near beginning and near action
4. Repeat if critical

**Example**:
```markdown
[At start]
🚨 DO NOT delete any existing database migrations.

[Before task]
Adding new migration for email verification.

REMEMBER: Do NOT delete existing migrations - only ADD new ones.
File: migrations/20250129_add_email_verification.py

[Confirm understanding]
Understood: Creating NEW migration file, leaving all existing migrations intact.
```

---

## Pattern: Structured Attention

### Problem
Unstructured information hard to parse and prioritize.

### Solution
**Use consistent structure to guide attention**:

```markdown
## Task: Fix Payment Processing Bug

### Priority 1 (IMMEDIATE)
Fix: Refunds over $1000 failing
File: src/services/payment_service.py, line 145
Impact: Critical - blocking customer refunds

### Priority 2 (HIGH)
Test: Add test for large refunds
File: tests/test_payment_service.py
Impact: Prevent regression

### Priority 3 (MEDIUM)
Document: Update refund documentation
File: docs/api/payments.md
Impact: Developer experience

### Priority 4 (LOW)
Optimize: Refund processing performance
File: src/services/payment_service.py
Impact: Nice to have
```

### Structure Types

**By Priority**:
- Critical / High / Medium / Low
- Now / Soon / Later
- Must / Should / Could

**By Type**:
- Fix / Test / Document
- Backend / Frontend / Infrastructure
- Security / Feature / Bug

**By Sequence**:
- First / Then / Finally
- Step 1 / Step 2 / Step 3
- Phase 1 / Phase 2 / Phase 3

---

## Pattern: Attention Checkpoints

### Problem
Long tasks lose focus over time.

### Solution
**Create explicit checkpoints to refocus attention**:

```markdown
## Checkpoint 1: Understanding (COMPLETE)
✅ Understood payment refund flow
✅ Identified bug at line 145
✅ Reviewed Stripe API documentation

## Checkpoint 2: Implementation (IN PROGRESS)
🔄 Fixing validation logic
- Changed: amount <= 100000 → amount <= original_amount
- Testing: Manual test with $1500 refund
- Next: Add automated test

## Checkpoint 3: Testing (UPCOMING)
⏭️ Add test for large refunds
⏭️ Run full test suite
⏭️ Verify with Stripe test mode

## Checkpoint 4: Documentation (UPCOMING)
⏭️ Update API documentation
⏭️ Add changelog entry
⏭️ Update developer guide
```

### Checkpoint Benefits

**For AI**:
- Clear progress tracking
- Explicit focus on current phase
- Awareness of upcoming work

**For User**:
- Visibility into progress
- Easy resumption if interrupted
- Clear completion criteria

---

## Pattern: Contrast Emphasis

### Problem
Need to highlight change from previous state.

### Solution
**Use before/after contrast to focus attention**:

```markdown
## IMPORTANT CHANGE

BEFORE (old code):
\```python
def process_refund(payment_id, amount):
    if amount > 100000:  # Bug: arbitrary limit
        raise ValueError("Refund too large")
\```

AFTER (new code):
\```python
def process_refund(payment_id, amount):
    payment = get_payment(payment_id)
    if amount > payment.amount:  # Fix: validate against original
        raise ValueError("Refund exceeds payment amount")
\```

KEY CHANGE: Validation now checks against original payment amount instead of arbitrary $1000 limit.
```

### Contrast Techniques

**Code Changes**:
- Before / After
- Old / New
- Current / Proposed

**Behavior Changes**:
- Previously / Now
- Was / Is
- Used to / Will now

**Decision Changes**:
- Considered / Decided
- Initially / Finally
- Alternative / Chosen

---

## Pattern: Question-Driven Attention

### Problem
AI not focusing on the right aspects.

### Solution
**Ask explicit questions to direct attention**:

```markdown
BAD (vague request):
Look at the payment service and fix any issues.

GOOD (question-driven):
Questions to answer about payment_service.py:

1. Why are refunds over $1000 failing?
   → Look at validation logic around line 145

2. What is the correct validation rule?
   → Should check against original payment amount

3. Are there tests covering this scenario?
   → Check tests/test_payment_service.py for refund tests

4. What else might be affected by this bug?
   → Look for other places with similar validation

Please answer these questions, then propose a fix.
```

### Question Types

**Diagnostic**:
- "Why is X happening?"
- "What causes Y?"
- "Where is Z defined?"

**Analytical**:
- "What are the implications of X?"
- "How does Y affect Z?"
- "What are alternatives to X?"

**Directive**:
- "Should we do X or Y?"
- "What needs to change?"
- "What are the next steps?"

---

## Pattern: Scope Boundaries

### Problem
AI considering too much or too little context.

### Solution
**Explicitly define scope boundaries**:

```markdown
## Scope for This Task

### IN SCOPE ✅
- Fix refund validation in payment_service.py
- Add test for large refunds
- Update payment API documentation

### OUT OF SCOPE ❌
- Payment creation logic (working correctly)
- Stripe webhook handling (separate task)
- Frontend payment UI (frontend team responsibility)
- Performance optimization (future task)

### DEPENDENCIES (context only)
- Stripe API (read-only understanding)
- Payment model (reference, do not modify)
- Database schema (context, no changes)

Focus ONLY on in-scope items. Flag if out-of-scope changes seem necessary.
```

### Boundary Types

**Work Boundaries**:
- In scope / Out of scope
- Included / Excluded
- Responsibilities / Dependencies

**Time Boundaries**:
- Now / Later
- This sprint / Next sprint
- Immediate / Future

**Access Boundaries**:
- Can modify / Read-only
- Can create / Cannot create
- Can delete / Cannot delete

---

## Best Practices

### Do
- ✅ Use visual emphasis (🚨, ✅, ❌) for critical info
- ✅ Restate important constraints before actions
- ✅ Structure information hierarchically
- ✅ Create explicit checkpoints
- ✅ Define clear scope boundaries
- ✅ Use questions to direct focus

### Don't
- ❌ Bury critical info in long paragraphs
- ❌ Assume AI remembers from beginning
- ❌ Mix priorities without labels
- ❌ Give all information at once
- ❌ Use emphasis everywhere (dilutes effect)
- ❌ Leave scope ambiguous

---

## Attention-Shaping Checklist

**Before Starting Task**:
- [ ] Highlighted critical constraints
- [ ] Stated DO NOTs explicitly
- [ ] Defined scope boundaries
- [ ] Structured by priority

**During Task**:
- [ ] Created checkpoints for progress
- [ ] Restated important info before critical actions
- [ ] Used questions to guide investigation
- [ ] Progressive disclosure of details

**Before Critical Actions**:
- [ ] Restated security constraints
- [ ] Confirmed scope boundaries
- [ ] Highlighted DO NOTs again
- [ ] Explicit confirmation requested

---

## Related Patterns

- [Context Windows](./context-windows.md) - Managing what's in context
- [Memory Tiers](./memory-tiers.md) - Organizing information by importance
- [Summarization](./summarization.md) - Condensing while preserving emphasis

---

**Last Updated**: 2025-12-29
**Source**: The Symposium development patterns
**Impact**: 40-50% reduction in errors, faster task completion

*"Direct attention deliberately, not accidentally."*
