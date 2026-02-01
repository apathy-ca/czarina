# Ask Mode

**Purpose**: Explanations, documentation, and learning through analysis.

**Value**: Builds understanding faster than reading code alone. Enables informed decisions.

**Best For**: Learning codebase, understanding concepts, code analysis, getting recommendations.

---

## Capabilities

### Can Do

- Explain concepts and technologies
- Answer questions about code and architecture
- Provide documentation and tutorials
- Analyze code (read-only)
- Give recommendations and suggestions
- Teach and educate
- Clarify design decisions
- Explain error messages
- Compare different approaches
- Suggest best practices

### Cannot Do

- Modify files or code
- Execute commands or scripts
- Make any changes to codebase
- Run tests
- Create implementation

**Note**: Ask mode is read-only. It's focused on understanding, not doing. When you're ready to implement, switch to Code mode.

---

## Allowed File Patterns

**Can Read**: All files (read-only)
- Source code
- Tests
- Configuration
- Documentation
- Logs
- Anything

**Cannot Touch**: Any file modifications

---

## When to Use Ask Mode

### Start with Ask When

- Learning how existing system works
- Understanding a concept or technology
- Analyzing code architecture
- Getting design recommendations
- Understanding error messages
- Exploring how to solve problem (before implementing)

### Example Situations

**Scenario 1: New to Codebase**
- Task: "I just joined the team, how does authentication work?"
- Ask mode steps:
  1. Analyze authentication files
  2. Explain current architecture
  3. Show how login flow works
  4. Explain token management
  5. Clarify integration with services

**Scenario 2: Unfamiliar Technology**
- Task: "I need to use Redis, but don't know how it works"
- Ask mode steps:
  1. Explain what Redis is
  2. Explain when to use it (caching, sessions, queues)
  3. Show Redis patterns in existing code
  4. Explain best practices
  5. Ready to implement with understanding

**Scenario 3: Understanding Error**
- Task: "What does 'ECONNREFUSED' mean and why are we getting it?"
- Ask mode steps:
  1. Explain what ECONNREFUSED means
  2. Explain why it happens
  3. Show common causes
  4. Suggest investigation steps
  5. Ready to debug (switch to Debug mode)

**Scenario 4: Code Review**
- Task: "Can you explain this complex function?"
- Ask mode steps:
  1. Break down function into parts
  2. Explain what each part does
  3. Explain overall flow
  4. Suggest potential improvements
  5. Ready to refactor if desired

**Scenario 5: Design Decision**
- Task: "Why did we choose PostgreSQL instead of MongoDB?"
- Ask mode steps:
  1. Analyze both options
  2. Show trade-offs
  3. Explain this codebase's choice
  4. Clarify when each is better
  5. Ready to understand future decisions

---

## Learning Patterns

### Pattern: Active Reading

**Don't** just ask for explanation. **Do** guide the learning:

```
Not ideal: "Explain the user service"

Better: "Show me how the user service handles password changes,
from API endpoint to database."
```

The specific question guides deeper understanding.

### Pattern: Code-First Understanding

**When** analyzing code:
1. **Show the code**: What does it look like?
2. **Explain the flow**: What happens step-by-step?
3. **Explain the why**: Why was it done this way?
4. **Show alternatives**: What else could we do?
5. **Explain trade-offs**: What are pros/cons?

**Example**:
```
User: "Can you explain how the JWT refresh token works?"

Good response:
1. Shows the relevant code
2. Explains step-by-step flow (request → validate → refresh)
3. Explains why (security, UX)
4. Shows alternative approaches (sessions, cookies)
5. Explains trade-offs (stateless vs stateful)
```

### Pattern: Learning by Comparison

**When** learning concept, compare approaches:

```
Q: "How is our caching strategy different from other approaches?"

A:
- Redis in-memory: Fast, loses data on restart, good for sessions
- Memcached: Similar to Redis, distributed better
- Database query cache: Persistent, slower, good for stable data
- Our approach: Redis + database fallback (best of both)
```

### Pattern: Reverse Engineering

**When** code is complex:
1. **Find entry point**: Where does execution start?
2. **Trace the flow**: What happens next?
3. **Follow dependencies**: What does it call?
4. **See outputs**: What does it produce?

**Example**:
```
Following: POST /api/users

1. Controller receives request
2. Validates input
3. Calls UserService.create()
4. UserService hashes password
5. Saves to database
6. Returns created user

This shows the full flow clearly.
```

---

## Common Questions to Ask

### Understanding Code

**Questions to ask**:
- "How does this function work?"
- "What is this code trying to do?"
- "Why is it implemented this way?"
- "Are there simpler ways to do this?"
- "What could break this code?"

### Understanding Architecture

**Questions to ask**:
- "How do these components interact?"
- "What's the data flow through the system?"
- "Why are things organized this way?"
- "What are the main dependencies?"
- "What would happen if this service fails?"

### Understanding Decisions

**Questions to ask**:
- "Why did we choose this technology?"
- "What are the trade-offs?"
- "What were the alternatives?"
- "When would we use a different approach?"
- "What would change if requirements changed?"

### Understanding Problems

**Questions to ask**:
- "What does this error mean?"
- "Why might this be happening?"
- "How would we investigate this?"
- "What could we check first?"
- "What's the most likely cause?"

---

## Explanation Types

### Explanation: Concept

**When** learning new concept:
- What is it?
- How does it work?
- Why use it?
- When is it useful?
- What are alternatives?

**Example**: "Explain pub/sub messaging"

### Explanation: Code Analysis

**When** understanding existing code:
- What does it do?
- Why is it structured this way?
- How does it integrate with other code?
- What could be improved?
- Is it following best practices?

**Example**: "Analyze the authentication middleware"

### Explanation: Error Diagnosis

**When** understanding error:
- What does error message mean?
- Why might it be happening?
- What would we check first?
- Common causes for this error?
- How would we prevent it?

**Example**: "Help me understand 'EADDRINUSE' error"

### Explanation: Comparison

**When** choosing between approaches:
- What are the options?
- How do they differ?
- What are pros and cons?
- Which is best for our case?
- Are there hybrid approaches?

**Example**: "Compare REST vs GraphQL for our API"

---

## When to Switch Modes

### Switch to Code Mode When

- Ready to implement based on understanding
- Want to make changes informed by learning
- Have specific code to write
- Understanding complete, time to build

**Example transition**:
```
I now understand how the authentication flow works, including
JWT refresh tokens, cookie handling, and session management.

Switching to Code mode to implement the new role-based access
control feature, applying this knowledge.
```

### Switch to Architect Mode When

- Need to plan before implementation
- Understanding raises design questions
- Want to explore architecture options
- Learning reveals design flaws

**Example transition**:
```
Through analyzing the code, I see we have authentication spread
across multiple services without clear boundaries. Before
implementing new features, we should design a consistent
authentication architecture.

Switching to Architect mode to plan the refactor.
```

### Switch to Debug Mode When

- Understanding something and found an issue
- Need to investigate why something works/doesn't work
- Learning reveals hidden problem
- Want to trace execution

**Example transition**:
```
While analyzing the caching layer, I noticed something odd.
The cache doesn't seem to be invalidating properly in some cases.

Switching to Debug mode to investigate why.
```

---

## Anti-Patterns

### Anti-Pattern: Passive Reading

**Problem**: Just asking for explanation without engagement
**Why it happens**: Seems easier than active thinking
**Solution**: Ask specific questions, challenge explanations, think

**Better approach**:
```
Not: "Explain the system"
But: "Show me the data flow for a user login, step by step"
```

### Anti-Pattern: Analysis Paralysis

**Problem**: Learning too much before implementing
**Why it happens**: Want to understand everything
**Solution**: Learn enough to start, learn more while building

**Better approach**:
```
"Explain enough that I can implement the first feature,
I'll learn more as I build."
```

### Anti-Pattern: Ignoring Practice

**Problem**: Learning theory without practical application
**Why it happens**: Feels more productive
**Solution**: Learn → Apply → Reflect

**Better approach**:
1. Ask to understand concept
2. Switch to Code mode to apply it
3. Debug if something doesn't work
4. Back to Ask mode if confused
5. Repeat with next concept

### Anti-Pattern: Outdated Information

**Problem**: Learning things that aren't current
**Why it happens**: Following old tutorials
**Solution**: Check actual codebase for current patterns

**Better approach**:
```
"What pattern does this codebase use for [feature]?"
Not: "What's the best practice for [feature]?"
```

---

## Best Practices

### 1. Be Specific

**Vague**: "How does the app work?"
**Specific**: "How does a user login request flow from the web browser to the database?"

### 2. Show Your Thinking

**Not useful**: "Explain this code"
**Useful**: "I think this code queries the database, but I don't understand why it has three steps. Explain what each step does."

### 3. Verify Understanding

**After learning**, test your understanding:
- Explain it back in your own words
- Predict what happens in a scenario
- Suggest how to extend it
- Ask edge case questions

### 4. Apply Immediately

**After learning**, switch to Code and apply:
- Implement based on understanding
- Test your knowledge
- Deepen your understanding
- Circle back to Ask if stuck

### 5. Document Findings

**After learning**, capture knowledge:
- Add comments to code
- Update documentation
- Share with team
- Build on the knowledge

---

## Ask Mode as Teaching Tool

### When to Use for Teaching Others

Ask mode can be used to:
- **Explain architecture to new team members**
- **Document design decisions**
- **Create onboarding documentation**
- **Answer common questions**
- **Review code and suggest improvements**

### Creating Documentation

**Ask mode can help create**:
- Architecture documentation
- API documentation
- Design decision records
- Tutorial documentation
- Troubleshooting guides

**Process**:
1. Ask questions in Ask mode
2. Gather explanations
3. Switch to Code/Architect to document
4. Back to Ask to verify documentation clarity

---

## Key Principles

1. **Question Everything**: Understanding means asking why
2. **Show Your Work**: Explain back what you learned
3. **Test Your Knowledge**: Apply it to new situations
4. **Deepen Gradually**: Start broad, narrow down
5. **Know When to Switch**: Ask until you understand, then do

---

## Related Patterns

- [Mode Transitions](./mode-transitions.md) - When to switch from Ask
- [Architect Mode](./architect-mode.md) - Planning after learning
- [Code Mode](./code-mode.md) - Implementing after learning
- [Error Recovery Patterns](../error-recovery/README.md) - Understanding errors

---

**Last Updated**: 2025-12-28
**Applicability**: Learning-focused workflows in AI-assisted development
**Source**: MODE_CAPABILITIES.md from agentic-dev-patterns

*"Understanding before doing prevents doing it wrong."*
