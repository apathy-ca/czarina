# Pattern Template

Use this template when submitting a new pattern to the Agent Knowledge repository.

## Pattern Name

[Clear, descriptive name - e.g., "Parallel Tool Calls for Independent Operations"]

## Category

[Select one or propose new category]
- Error Recovery
- Tool Use
- Mode Capabilities
- Context Management
- Git Workflows
- Testing Patterns
- Other (specify)

## Problem

[What problem does this pattern solve? Be specific.]

**Example:**
> Sequential tool calls waste time when operations are independent. Waiting for each operation to complete before starting the next adds unnecessary latency.

## Context

[When should this pattern be used? What are the prerequisites or conditions?]

**Example:**
> Use this pattern when:
> - You need to perform multiple operations
> - The operations are independent (no data dependencies)
> - You're working with tools that support parallel execution
> - Latency is a concern

## Solution

[Step-by-step description of the pattern]

**Example:**
> 1. Identify independent operations in your workflow
> 2. Group them into a single tool call batch
> 3. Execute all operations in parallel
> 4. Process results as they arrive

### Implementation Steps

1. [First step - be specific]
2. [Second step - include details]
3. [Third step - mention gotchas if any]
...

### Code Example (if applicable)

```python
# Example implementation
# Replace this with your actual code example

# BAD: Sequential execution
result1 = await read_file("a.py")
result2 = await read_file("b.py")
result3 = await grep("pattern", "*.py")

# GOOD: Parallel execution
results = await asyncio.gather(
    read_file("a.py"),
    read_file("b.py"),
    grep("pattern", "*.py")
)
```

Or for configuration/YAML examples:

```yaml
# Example configuration
example_key: value
```

## Examples

[Real-world examples of this pattern in use]

### Example 1: [Descriptive Title]

[Brief description of the scenario]

**Context:** [What was the situation?]

**Implementation:**
```
[Code, configuration, or step-by-step description]
```

**Result:** [What happened? What was the outcome?]

### Example 2: [Descriptive Title]

[Brief description of the scenario]

**Context:** [What was the situation?]

**Implementation:**
```
[Code, configuration, or step-by-step description]
```

**Result:** [What happened? What was the outcome?]

## Evidence

[Where was this pattern tested? What projects used it? This is REQUIRED.]

**Project:** [e.g., The Symposium, Hopper, Czarina, SARK, or specific project name]

**Context:** [What was being built? What was the task?]

**Results:** [What happened when you applied this pattern?]

**Metrics (if available):**
- Metric 1: [e.g., Task completion time reduced from X to Y]
- Metric 2: [e.g., Error rate decreased by Z%]
- Observation: [e.g., Code became clearer, debugging was easier]

## Impact

[Quantified impact if possible, qualitative otherwise. This is REQUIRED.]

**Quantitative:**
- **Metric 1:** [e.g., 30% reduction in debugging time]
- **Metric 2:** [e.g., 50% fewer errors]
- **Metric 3:** [e.g., 2x faster task completion]

**Qualitative:**
- [e.g., Improved code clarity and maintainability]
- [e.g., Easier to onboard new developers]
- [e.g., Reduced cognitive load]

**Overall:** [Summary statement - e.g., "This pattern reduced average task time by 38% across 15 tasks in The Symposium project."]

## Related Patterns

[Links to related patterns in this repository]

- Pattern Name 1 <!-- example path --> - [Brief description of relationship]
- Pattern Name 2 <!-- example path --> - [Brief description of relationship]

**Use together with:**
- [Pattern that complements this one]

**Alternative to:**
- [Pattern that solves similar problem differently]

## Related Core Rules

[Links to related core rules in this repository]

- Rule Name 1 <!-- example path --> - [Why it's related]
- Rule Name 2 <!-- example path --> - [Why it's related]

## Trade-offs

[What are the drawbacks or limitations of this pattern? Be honest.]

**Pros:**
- ✅ [Benefit 1]
- ✅ [Benefit 2]
- ✅ [Benefit 3]

**Cons:**
- ❌ [Drawback 1]
- ❌ [Drawback 2]
- ❌ [Limitation 1]

**When NOT to use:**
- [Scenario where this pattern is not appropriate]
- [Condition that makes this pattern counterproductive]

## Alternatives

[What are alternative approaches? When would you use them instead?]

### Alternative 1: [Name]

**Description:** [How this approach differs]

**When to use:** [Conditions that make this alternative better]

**Trade-offs:** [Pros and cons vs. this pattern]

### Alternative 2: [Name]

**Description:** [How this approach differs]

**When to use:** [Conditions that make this alternative better]

**Trade-offs:** [Pros and cons vs. this pattern]

## References

[External references, papers, blog posts, documentation, etc.]

- [Reference Title 1](https://example.com) - [Brief description]
- [Reference Title 2](https://example.com) - [Brief description]
- [Documentation Link](https://example.com/docs) - [What it documents]

## Metadata

- **Author:** [Your name or GitHub handle]
- **Date Added:** [YYYY-MM-DD]
- **Last Updated:** [YYYY-MM-DD]
- **Status:** [Proposed | Accepted | Proven | Deprecated]
- **Version:** [Pattern version, if applicable]

**Status definitions:**
- **Proposed:** New pattern, not yet battle-tested, requires review
- **Accepted:** Reviewed and approved, has evidence from at least one project
- **Proven:** Used successfully in multiple projects, quantified impact available
- **Deprecated:** Superseded by better pattern, kept for historical reference

---

## Checklist for Submission

Before submitting, ensure:

- [ ] Pattern name is clear and descriptive
- [ ] Category is appropriate
- [ ] Problem statement is specific
- [ ] Context explains when to use this
- [ ] Solution has step-by-step instructions
- [ ] At least one code/configuration example provided
- [ ] At least two real-world examples included
- [ ] Evidence section completed with actual project data
- [ ] Impact documented (quantified or qualitative)
- [ ] Related patterns identified and linked
- [ ] Related core rules identified and linked
- [ ] Trade-offs are honest and complete
- [ ] Alternatives discussed
- [ ] References added (if applicable)
- [ ] Metadata complete
- [ ] All sections filled appropriately

## Notes for Contributors

**Required sections:**
- Pattern Name, Category, Problem, Context, Solution, Examples, Evidence, Impact

**Strongly recommended:**
- Related Patterns, Related Core Rules, Trade-offs, Alternatives

**Optional:**
- References (but highly encouraged)

**Tips:**
- Be specific and actionable
- Use real examples from your experience
- Quantify impact when possible
- Be honest about limitations
- Think about edge cases
- Consider maintenance burden

**Quality over quantity:**
- One well-documented, evidence-backed pattern is better than five theoretical ideas
- Focus on patterns you've actually used and seen work
- Provide enough detail that someone else can implement it

Thank you for contributing to the Agent Knowledge repository!
