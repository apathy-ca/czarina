# Summarization Patterns

**Purpose**: Techniques for condensing information while preserving essential details.

**Value**: Extends effective context window, maintains continuity across conversations, reduces cognitive load.

---

## When to Summarize

### Triggers for Summarization

**Time-based**:
- Long conversation (>50 messages)
- Multiple hours of work
- Approaching context limit

**Content-based**:
- Completed investigation phase
- Finished implementing feature
- Resolved error or issue
- Switching to new subtask

**Continuity-based**:
- Starting new conversation
- Handing off to different agent/mode
- Creating checkpoint for later resumption

---

## Pattern: Investigation Summarization

### Problem
Spent significant context exploring issue, need to condense findings before implementing fix.

### Solution
**Summarize investigations into actionable conclusions**:

```markdown
## Investigation Summary: User Authentication Failing

### Root Cause
Token expiration logic in AuthService.validate_token() checks wrong timestamp.
- File: src/services/auth_service.py, line 87
- Issue: Comparing `created_at` instead of `expires_at`
- Impact: All tokens expire immediately

### Fix Required
Change line 87 from:
\```python
if token.created_at < now:
\```
To:
\```python
if token.expires_at < now:
\```

### Verified
- Checked token model: has both created_at and expires_at
- Reviewed tests: test expects expires_at comparison
- Confirmed in logs: tokens failing immediately after creation

### Files to Modify
1. src/services/auth_service.py (line 87)
2. tests/test_auth_service.py (add regression test)
```

### What to Include
- ✅ Root cause identified
- ✅ Specific file and line numbers
- ✅ Exact change needed
- ✅ Verification steps taken
- ✅ Files affected

### What to Exclude
- ❌ Exploration paths that didn't pan out
- ❌ File contents that aren't relevant
- ❌ Detailed error logs (just key insights)
- ❌ Process details ("first I tried X, then Y")

### Impact
- Reduces 40-50 messages of investigation to 10-line summary
- Preserves actionable information
- Enables immediate implementation

---

## Pattern: Feature Implementation Summarization

### Problem
Implemented complex feature across multiple files, need to remember what was done for testing/documentation.

### Solution
**Create implementation summary focusing on changes made**:

```markdown
## Implementation Summary: Email Verification

### Changes Made

#### 1. Database Migration
File: migrations/20250129_add_email_verification.py
- Added `email_verified` boolean field to User table
- Added `verification_token` string field
- Added `verification_sent_at` timestamp field

#### 2. User Model
File: src/models/user.py
- Added email_verified field (default=False)
- Added verification_token field
- Added generate_verification_token() method
- Added verify_email() method

#### 3. User Service
File: src/services/user_service.py
- Modified register_user() to generate token and send email
- Added verify_email(token) method
- Added resend_verification() method

#### 4. Email Service
File: src/services/email_service.py
- Added send_verification_email() method
- Added verification email template

#### 5. API Endpoints
File: src/api/auth.py
- Added POST /auth/verify-email endpoint
- Added POST /auth/resend-verification endpoint

#### 6. Tests
File: tests/test_user_service.py
- Added test_register_user_sends_verification
- Added test_verify_email_success
- Added test_verify_email_invalid_token
- Added test_resend_verification

### Configuration
- Added VERIFICATION_TOKEN_EXPIRY=24h to config
- Added verification email template to templates/email/

### Remaining Work
- [ ] Add frontend verification page
- [ ] Update API documentation
- [ ] Add email verification to user dashboard
```

### What to Include
- ✅ Every file modified with specific changes
- ✅ New methods/functions added
- ✅ Configuration changes
- ✅ Tests written
- ✅ What's left to do

### What to Exclude
- ❌ Exact code snippets (unless critical)
- ❌ Implementation reasoning (unless novel)
- ❌ Alternative approaches considered

---

## Pattern: Conversation Handoff

### Problem
Need to pause work and resume later, or hand off to different agent/mode.

### Solution
**Create comprehensive handoff document**:

```markdown
## Handoff: Implementing Payment Processing

### Context
Working on Stripe payment integration for subscription system.

### Progress (60% complete)

#### ✅ Completed
1. Stripe SDK installed and configured
2. Payment model created with migrations
3. Stripe webhook endpoint implemented
4. Payment creation flow working
5. Tests for payment creation (3 tests passing)

#### 🚧 In Progress
Currently implementing refund handling:
- File open: src/services/payment_service.py
- Method: process_refund() (line 156, partially complete)
- Issue: Need to handle partial refunds vs. full refunds
- Next: Add refund amount validation

#### ⏸️ Blocked
Waiting for clarification on refund policy:
- Should partial refunds be allowed?
- What's the refund window (30 days? 90 days?)
- Do we refund processing fees?

#### ⏭️ Upcoming
After refund handling:
1. Implement subscription cancellation
2. Add payment method updates
3. Create admin refund dashboard
4. Write integration tests with Stripe test mode

### Key Decisions Made
1. Using Stripe webhook for payment confirmations (not polling)
2. Storing payment_intent_id for idempotency
3. Refunds create new Payment record (not modifying original)

### Important Context
- Stripe test keys in .env.test
- Webhook secret: whsec_test123 (local testing)
- Payment model has status field: pending|completed|failed|refunded
- All amounts in cents (not dollars) to avoid float errors

### Files to Remember
- src/services/payment_service.py (main implementation)
- src/models/payment.py (data model)
- src/api/webhooks.py (Stripe webhook handler)
- tests/test_payment_service.py (8 tests, all passing)

### Code Context
\```python
# Current state of process_refund (line 156-170)
def process_refund(self, payment_id: str, amount: Optional[int] = None):
    payment = Payment.query.get(payment_id)
    if not payment:
        raise PaymentNotFound(payment_id)

    if payment.status != PaymentStatus.COMPLETED:
        raise CannotRefundPayment("Only completed payments can be refunded")

    # TODO: Validate refund amount
    # TODO: Handle partial vs. full refunds
    # TODO: Create refund via Stripe API
    # TODO: Create refund Payment record
    # TODO: Update original payment status
\```

### Next Session Starts Here
1. Get clarification on refund policy (ask user if needed)
2. Implement refund amount validation
3. Complete process_refund() method
4. Add tests for refund scenarios
```

### What to Include
- ✅ Full progress breakdown (completed, in progress, blocked, upcoming)
- ✅ Key decisions and rationale
- ✅ Important configuration/constants
- ✅ Exact file and line numbers for in-progress work
- ✅ Code snippet of current state
- ✅ Explicit "start here" for next session

### What to Exclude
- ❌ Completed work details (just checklist)
- ❌ Dead-end explorations
- ❌ Full file contents

### Impact
- Seamless resumption in new conversation
- Zero context re-loading needed
- Maintains momentum across sessions

---

## Pattern: Progressive Summarization

### Problem
Information accumulates gradually, need to summarize without losing work.

### Solution
**Summarize in layers, keeping progressively more condensed versions**:

### Layer 1: Full Detail (Current Work)
Keep complete context for active work:
- All files currently being modified
- Recent conversation
- Immediate next steps

### Layer 2: Summary (Recent Completed Work)
Condense recently completed work:
- What was done (not how)
- Files changed
- Key decisions

### Layer 3: Archive (Old Completed Work)
Minimal summary of old work:
- Feature name
- Status (complete/deployed)
- Files modified (list only)

### Example Evolution

**Day 1 (Layer 1 - Full Detail)**:
```markdown
Working on user authentication:
- Implemented login endpoint
- Added JWT token generation
- Created token validation middleware
[Full code snippets, detailed decisions]
```

**Day 3 (Layer 2 - Summary)**:
```markdown
Completed user authentication (Day 1):
- Login endpoint: POST /auth/login
- JWT tokens with 24h expiry
- Auth middleware applied to protected routes
Files: src/api/auth.py, src/middleware/auth.py, tests/test_auth.py
```

**Day 7 (Layer 3 - Archive)**:
```markdown
✅ User authentication system (deployed v1.0)
```

### When to Compress

- Layer 1 → Layer 2: When starting next feature (usually same day)
- Layer 2 → Layer 3: After code is tested and deployed
- Remove Layer 3: After feature is stable for 1+ week

---

## Pattern: Error Investigation Summarization

### Problem
Spent hours debugging, need to capture solution without all the false starts.

### Solution
**Summarize as solution recipe, not investigation journey**:

```markdown
BAD (narrative of investigation):
First I checked the logs and saw errors about database connection.
Then I looked at the database config but it seemed fine.
Then I tried restarting the database but that didn't work.
Then I checked the network and realized the port was wrong.
Finally I changed the port from 5432 to 5433 and it worked.

GOOD (solution recipe):
## Issue: Database Connection Failures

### Problem
Application couldn't connect to PostgreSQL database.

### Root Cause
Database port configured as 5432 in config/database.yaml, but PostgreSQL running on 5433.

### Solution
Changed database.yaml port from 5432 to 5433.

### Verification
\```bash
psql -h localhost -p 5433 -U myapp  # Connection successful
docker ps | grep postgres  # Confirmed port 5433
\```

### Prevention
Added port validation to startup script to fail fast if port mismatch.
```

### What to Include
- ✅ Concise problem statement
- ✅ Root cause
- ✅ Exact solution
- ✅ Verification steps
- ✅ Prevention measures

### What to Exclude
- ❌ Exploration paths that failed
- ❌ Red herrings investigated
- ❌ Reasoning process
- ❌ Timeline of investigation

---

## Pattern: Decision Summarization

### Problem
Made important architectural decisions, need to remember rationale without full discussion.

### Solution
**Use decision record format**:

```markdown
## Decision: Use PostgreSQL for User Data

### Context
Need to choose database for user management system.

### Considered Options
1. PostgreSQL - Relational, ACID, complex queries
2. MongoDB - Document store, flexible schema
3. Redis - In-memory, fast, limited querying

### Decision
PostgreSQL

### Rationale
- User data is highly relational (users → posts → comments)
- Need ACID guarantees for payment processing
- Complex queries for user analytics
- Team has PostgreSQL expertise
- Redis for caching, not primary storage
- MongoDB schema flexibility not needed (stable user model)

### Consequences
- ✅ Strong consistency guarantees
- ✅ Complex joins supported
- ✅ Mature ecosystem and tools
- ❌ Slightly slower than NoSQL for simple reads
- ❌ Schema migrations required

### Date
2025-12-29

### Status
Accepted, implemented in v1.0
```

### What to Include
- ✅ Options considered (all viable alternatives)
- ✅ Rationale for choice
- ✅ Trade-offs accepted
- ✅ Date and status

### What to Exclude
- ❌ Options that were clearly unsuitable
- ❌ Detailed technical comparisons
- ❌ Implementation details

---

## Best Practices

### Do
- ✅ Summarize after completing phases
- ✅ Focus on actionable information
- ✅ Include specific file/line references
- ✅ Use progressive summarization for long projects
- ✅ Create handoffs for context switches
- ✅ Keep decision rationale

### Don't
- ❌ Summarize before understanding is complete
- ❌ Include exploration dead-ends
- ❌ Write narrative timelines
- ❌ Over-summarize active work
- ❌ Lose critical code snippets
- ❌ Forget configuration details

---

## Summarization Checklist

When creating a summary, ensure it includes:

**For Investigations**:
- [ ] Root cause identified
- [ ] Solution stated clearly
- [ ] Files and line numbers
- [ ] Verification performed

**For Implementations**:
- [ ] All files changed listed
- [ ] New methods/functions noted
- [ ] Configuration changes
- [ ] Tests added
- [ ] Remaining work

**For Handoffs**:
- [ ] Current progress percentage
- [ ] Completed checklist
- [ ] In-progress details
- [ ] Blocked items
- [ ] Next steps explicit
- [ ] Code context for resumption

---

## Related Patterns

- [Context Windows](./context-windows.md) - Managing context limits
- [Memory Tiers](./memory-tiers.md) - What to remember long-term
- [Attention Shaping](./attention-shaping.md) - Focusing on important information

---

**Last Updated**: 2025-12-29
**Source**: The Symposium development patterns
**Impact**: Enables seamless work across conversations, reduces context re-loading by 80%

*"Summarize the what and why, forget the how we got there."*
