# Memory Tiers

**Purpose**: Organizing information into different memory tiers based on access patterns and longevity needs.

**Value**: Efficient information retention, faster recall, optimized context usage.

---

## Memory Tier Model

###Tier 1: Working Memory (Immediate Context)
**Scope**: Current task, active files, next 3-5 steps
**Lifetime**: Current conversation
**Size**: 20-40% of context window
**Access**: Constant

**What belongs here**:
- Files currently being edited
- Code snippets being modified
- Immediate next steps
- Active error messages
- Current command outputs

**Example**:
```markdown
Working Memory (Current):
- File: src/services/payment_service.py (lines 145-200)
- Task: Implementing refund handling
- Next: Add refund validation, call Stripe API, update database
- Error: None
- Context: 35% of window
```

---

### Tier 2: Session Memory (Task Context)
**Scope**: Current feature/task, related files, recent decisions
**Lifetime**: Until task complete
**Size**: 30-40% of context window
**Access**: Frequent

**What belongs here**:
- All files related to current feature
- Key decisions made
- Important configuration
- Test results
- Related documentation

**Example**:
```markdown
Session Memory (Payment Feature):
- Files: payment_service.py, payment.py, webhooks.py
- Decision: Using Stripe webhooks, not polling
- Config: Stripe API key in .env, webhook secret
- Tests: 8 tests passing
- Docs: Stripe API docs for refunds
```

---

### Tier 3: Project Memory (Architectural Context)
**Scope**: Project structure, patterns, standards
**Lifetime**: Entire project
**Size**: 10-20% of context window
**Access**: Occasional reference

**What belongs here**:
- Project architecture overview
- Coding standards
- Common patterns used
- Key dependencies
- Directory structure

**Example**:
```markdown
Project Memory (Symposium):
- Architecture: FastAPI backend, PostgreSQL DB, Redis cache
- Patterns: Service layer pattern, repository pattern
- Standards: Type hints required, 80%+ test coverage
- Key deps: FastAPI, SQLAlchemy, Stripe, Celery
- Structure: src/api, src/services, src/models, tests/
```

---

### Tier 4: Reference Memory (External Knowledge)
**Scope**: Documentation, API references, general knowledge
**Lifetime**: As needed
**Size**: 0-10% of context window (load on demand)
**Access**: Rare, when needed

**What belongs here**:
- API documentation
- Library references
- Stack Overflow solutions
- Design patterns
- Language syntax

**Example**:
```markdown
Reference Memory (As Needed):
- Stripe API docs: Load when implementing new endpoint
- SQLAlchemy docs: Load when writing complex query
- Python typing docs: Load when using advanced types
- FastAPI docs: Load when adding new feature
```

---

## Pattern: Tier Promotion

### Problem
Information becomes more important and needs more immediate access.

### Solution
**Promote information to higher tier when access pattern changes**:

```
Tier 4 → Tier 3 (Reference to Project)
"Using SQLAlchemy relationship patterns consistently across project"
→ Promote relationship syntax to project memory

Tier 3 → Tier 2 (Project to Session)
"Working on authentication, need frequent access to auth patterns"
→ Promote auth architecture to session memory

Tier 2 → Tier 1 (Session to Working)
"About to modify PaymentService.process_refund()"
→ Promote refund logic to working memory
```

### When to Promote

**To Working Memory**:
- Immediately before modifying
- When debugging specific code
- When writing tests for component

**To Session Memory**:
- Starting work on feature
- Pattern used multiple times
- Key decision affecting current work

**To Project Memory**:
- Pattern used across codebase
- Architectural standard
- Common dependency

---

## Pattern: Tier Demotion

### Problem
Obsolete information cluttering higher tiers.

### Solution
**Demote or evict information when no longer needed**:

```
Tier 1 → Tier 2 (Working to Session)
"Finished implementing refund validation"
→ Demote refund code from working memory
→ Keep summary in session memory

Tier 2 → Tier 3 (Session to Project)
"Payment feature complete and tested"
→ Demote payment details to project memory
→ Keep "payment module exists" in project memory

Tier 3 → Tier 4 (Project to Reference)
"Finished migration work, no more DB schema changes planned"
→ Demote SQLAlchemy migration patterns
→ Available in docs if needed later

Tier 4 → Evicted (Reference to Forgotten)
"Explored MongoDB, decided on PostgreSQL instead"
→ Evict MongoDB documentation
→ Can reload if decision changes
```

### When to Demote

**From Working Memory**:
- Function/section complete
- Moving to different file
- Task checkpoint reached

**From Session Memory**:
- Feature complete and tested
- Issue resolved
- Investigation concluded

**From Project Memory**:
- Technology no longer used
- Pattern superseded
- Temporary consideration

---

## Pattern: Memory Checkpointing

### Problem
Long-running task exhausting context window.

### Solution
**Create checkpoint summaries and reload essential tiers**:

```markdown
## Checkpoint: Payment Integration (End of Day 1)

### Tier 1: Working Memory (Clear for fresh start)
[Empty - will reload when resuming]

### Tier 2: Session Memory (Preserve)
Payment Integration Progress:
- Models: Payment, Refund (complete)
- Services: PaymentService 60% complete
  - process_payment: done
  - process_refund: in progress (line 156)
  - update_payment_method: todo
- Tests: 8 tests passing
- Next: Complete refund handling

### Tier 3: Project Memory (Keep)
- Architecture: Service layer with Stripe integration
- Pattern: Webhook-based payment confirmation
- Config: Stripe test keys in .env.test
- Standards: All amounts in cents, not dollars

### Tier 4: Reference Memory (Evicted, reload as needed)
[Stripe API docs can be reloaded]
```

**Next Session**:
```markdown
Resuming Payment Integration:

Restore Tier 3 (Project Memory):
[Load from checkpoint]

Restore Tier 2 (Session Memory):
[Load from checkpoint]

Restore Tier 1 (Working Memory):
- Read: src/services/payment_service.py (lines 150-180)
- Focus: process_refund method
- Context: Checkpoint says 60% complete, refund in progress

Resume work:
[Start implementing with fresh context window]
```

---

## Pattern: Selective Recall

### Problem
Need specific information from lower tier without loading everything.

### Solution
**Query lower tiers specifically, load only needed information**:

```markdown
Working on new feature, need to recall:

Query Project Memory:
"What pattern do we use for database transactions?"
→ Answer: "Repository pattern with context manager"
→ Load only transaction pattern, not entire architecture

Query Session Memory (from previous task):
"What Stripe webhook events are we handling?"
→ Answer: "payment_intent.succeeded, payment_intent.failed"
→ Load only webhook list, not entire payment implementation

Query Reference Memory:
"What's the syntax for SQLAlchemy relationship with back_populates?"
→ Load only relationship syntax example, not full docs
```

### Benefits
- Targeted information retrieval
- Minimal context usage
- Faster than reloading entire tier

---

## Pattern: Memory Consolidation

### Problem
Similar information scattered across tiers.

### Solution
**Consolidate related information at appropriate tier**:

```markdown
Before Consolidation:
- Working Memory: "UserService uses bcrypt for passwords"
- Session Memory: "AuthService also uses bcrypt"
- Working Memory: "PasswordResetService uses bcrypt too"

After Consolidation:
- Project Memory: "Standard: Use bcrypt for all password hashing"
- Working Memory: [Clear - refer to project standard]
- Session Memory: [Clear - refer to project standard]
```

### When to Consolidate

**Triggers**:
- Same pattern seen 3+ times
- Architectural decision affecting multiple areas
- Standard being established

**Process**:
1. Identify common pattern
2. Determine appropriate tier (usually Project)
3. Create consolidated entry
4. Clear duplicates from higher tiers
5. Reference consolidated entry when needed

---

## Pattern: Memory Budget Allocation

### Problem
Don't know how much context to allocate to each tier.

### Solution
**Budget context across tiers based on task type**:

### New Feature Implementation
```markdown
Tier 1 (Working): 35%
- Files being written
- Current implementation

Tier 2 (Session): 35%
- Related files
- Test files
- Recent decisions

Tier 3 (Project): 20%
- Architecture
- Patterns
- Standards

Tier 4 (Reference): 10%
- API docs
- Library references
```

### Bug Investigation
```markdown
Tier 1 (Working): 40%
- Error logs
- Suspect code
- Debugging output

Tier 2 (Session): 30%
- Related code
- Recent changes
- Test failures

Tier 3 (Project): 20%
- Architecture context
- Similar past bugs

Tier 4 (Reference): 10%
- Documentation
- Stack Overflow
```

### Code Review
```markdown
Tier 1 (Working): 30%
- Current file being reviewed
- Specific concerns

Tier 2 (Session): 40%
- All files in PR
- Related tests
- CI results

Tier 3 (Project): 25%
- Coding standards
- Project patterns
- Architecture rules

Tier 4 (Reference): 5%
- Style guides
- Best practices
```

---

## Pattern: Handoff Memory

### Problem
Switching between agents/modes, need to transfer essential context.

### Solution
**Create tier-aware handoff**:

```markdown
## Handoff from Architect to Code Mode

### Transfer Working Memory (Tier 1)
Implementation ready for:
- File: src/services/notification_service.py
- Methods to implement:
  - send_notification(user_id, message, channel)
  - get_user_notifications(user_id, limit=20)
  - mark_as_read(notification_id)

### Transfer Session Memory (Tier 2)
Notification Feature Context:
- Database: notifications table created (migration applied)
- Model: Notification model exists in src/models/notification.py
- Dependencies: EmailService and SMSService available
- Configuration: Notification channels in config/notifications.yaml

### Transfer Project Memory (Tier 3)
Standards to follow:
- Use service layer pattern (like UserService, PaymentService)
- Type hints required for all methods
- Write tests in tests/test_notification_service.py
- Follow existing error handling pattern (raise custom exceptions)

### No Transfer (Tier 4)
Reference memory not needed - Code mode can load as needed:
- Python documentation
- FastAPI docs
```

**Code Mode Receives**:
- Clear Working Memory (what to implement)
- Essential Session Memory (context for implementation)
- Project Memory (standards to follow)
- Freedom to load Reference as needed

---

## Best Practices

### Do
- ✅ Keep Working Memory lean (only current task)
- ✅ Promote information as it becomes more relevant
- ✅ Demote information as it becomes less relevant
- ✅ Consolidate patterns into Project Memory
- ✅ Create checkpoints for long tasks
- ✅ Budget context across tiers

### Don't
- ❌ Load entire project into Working Memory
- ❌ Keep obsolete information in high tiers
- ❌ Duplicate information across tiers
- ❌ Forget to checkpoint before context limit
- ❌ Load Reference Memory speculatively

---

## Memory Tier Checklist

**Starting New Task**:
- [ ] Load Project Memory (architecture, patterns)
- [ ] Load Session Memory (task context)
- [ ] Load Working Memory (immediate files)
- [ ] Budget: 20% / 35% / 35% / 10%

**Mid-Task**:
- [ ] Promote urgent information to Working Memory
- [ ] Demote completed work to Session Memory
- [ ] Consolidate repeated patterns to Project Memory

**Completing Task**:
- [ ] Demote Working Memory to Session Memory
- [ ] Consolidate learnings into Project Memory
- [ ] Create checkpoint if continuing later

**Switching Context**:
- [ ] Create tier-aware handoff
- [ ] Clear Working Memory
- [ ] Preserve Session and Project Memory
- [ ] Evict task-specific Reference Memory

---

## Related Patterns

- [Context Windows](./context-windows.md) - Managing context limits
- [Summarization](./summarization.md) - Condensing information for lower tiers
- [Attention Shaping](./attention-shaping.md) - Focusing on appropriate tier

---

**Last Updated**: 2025-12-29
**Source**: The Symposium development patterns
**Impact**: 60% improvement in context efficiency, faster task resumption

*"The right information, in the right place, at the right time."*
