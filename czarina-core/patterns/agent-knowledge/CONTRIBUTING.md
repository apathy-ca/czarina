# Contributing to Agent Knowledge

Thank you for contributing to the Agent Knowledge repository! This knowledge base grows through continuous learning extraction from real development work.

## How to Add a New Pattern

### 1. Identify the Pattern Category

Determine which category your pattern belongs to:
- **Error Recovery** - Retry patterns, fallback strategies, error handling
- **Tool Use** - Optimization, parallel execution, tool selection
- **Mode Capabilities** - Role-specific patterns (code, ask, orchestrator)
- **Context Management** - Memory optimization, summarization, context handoff
- **Git Workflows** - Branch strategies, commit patterns, PR workflows
- **Testing Patterns** - Test organization, mocking, integration testing
- **Other** - If none of the above fit, propose a new category

### 2. Use the Pattern Template

Copy the template to create your pattern:

```bash
cp meta/pattern-template.md patterns/<category>/<pattern-name>.md
```

For example:
```bash
cp meta/pattern-template.md patterns/error-recovery/circuit-breaker.md
```

### 3. Fill in the Template

Complete all sections of the template:

**Required sections:**
- **Pattern Name** - Clear, descriptive name
- **Category** - Which category it belongs to
- **Problem** - What problem does this solve? Be specific.
- **Context** - When should this pattern be used?
- **Solution** - Step-by-step description
- **Examples** - Real-world examples with code
- **Evidence** - Where was this tested? What projects used it?
- **Impact** - Quantified impact (e.g., "30% reduction in debugging time") or qualitative

**Recommended sections:**
- **Related Patterns** - Links to related patterns
- **Related Core Rules** - Links to relevant core rules
- **Trade-offs** - Pros and cons
- **Alternatives** - When would you use a different approach?
- **References** - External resources

### 4. Submit for Review

Create a pull request with:
- Your new pattern file
- Updated INDEX.md (add your pattern to the appropriate category)
- Link to evidence (session logs, commits, issues that demonstrate the pattern)
- Brief description of the impact

Tag relevant reviewers for feedback.

## Continuous Learning Integration

Patterns can be submitted in two ways:

### Manual Submission (You)

1. Identify a valuable pattern from your work
2. Use the pattern template
3. Fill in all sections with evidence
4. Submit PR
5. Respond to review feedback
6. Pattern merged when approved

### Automatic Submission (via Learnings Processor)

When systems complete work, they can automatically extract learnings:

**Czarina** - At phase closeout:
1. Workers document learnings in `.czarina/learnings/phase-{N}-closeout.json`
2. Learnings sent to Symposium Learnings Processor
3. LLM analyzes and proposes patterns
4. Human reviews and approves
5. Merged to agent-knowledge

**Hopper** - After task completion:
1. Task feedback captured in `.hopper/feedback/task-{ID}.json`
2. Sent to Learnings Processor
3. Patterns proposed if generalizable
4. Human review required
5. Merged if approved

**The Symposium** - Sage observations:
1. Agent collaboration patterns observed
2. Sage exports wisdom to `.symposium/sage/wisdom-{session-ID}.json`
3. Learnings Processor analyzes
4. Patterns proposed
5. Human review and merge

**SARK** - Security learnings:
1. Security patterns captured in `.sark/learnings/security-{ID}.json`
2. Analyzed for generalizability
3. Patterns proposed
4. Security review required
5. Merged if approved

See [Learning Extraction](./meta/learning-extraction.md) for detailed workflow.

## Review Process

All pattern submissions (manual or automatic) require human review.

### What Reviewers Check

**Generalizability:**
- Does this apply beyond one specific case?
- Can others use this pattern in different contexts?

**Actionability:**
- Are the steps clear and specific?
- Can someone implement this from the description?

**Evidence:**
- Is there proof this pattern works?
- What projects have used it?
- What were the results?

**Impact:**
- Does this provide measurable value?
- Is the impact documented (quantified or qualitative)?

**Clarity:**
- Is the documentation clear and complete?
- Are examples helpful and realistic?

**Compatibility:**
- Does this conflict with existing patterns?
- Does it complement or enhance existing knowledge?

### Review Checklist

Reviewers will verify:

- [ ] Pattern is generalizable (applies beyond one case)
- [ ] Pattern is actionable (clear implementation steps)
- [ ] Evidence is sufficient (tested in real projects)
- [ ] Impact is documented (quantified or qualitative)
- [ ] Documentation is clear and complete
- [ ] All template sections filled appropriately
- [ ] No conflicts with existing patterns
- [ ] Proper category placement
- [ ] Cross-references added where relevant

## Pattern Quality Standards

### Good Pattern Example

**Pattern:** Parallel Tool Calls for Independent Operations

**Problem:** Sequential tool calls waste time when operations are independent

**Solution:** Group independent tool calls in single message
```python
# Instead of:
result1 = read_file("a.py")
result2 = read_file("b.py")

# Do this:
# Call both read tools in parallel in one message
```

**Evidence:** Used in The Symposium project, reduced average task time from 45s to 28s (38% improvement)

**Impact:** 30-40% reduction in task completion time for multi-file operations

✅ **Why this is good:**
- Specific and actionable
- Clear before/after example
- Evidence from real project
- Quantified impact

### Bad Pattern Example

**Pattern:** Write Better Code

**Problem:** Code quality is important

**Solution:** Always write good code that follows best practices

**Evidence:** Everyone knows this

**Impact:** Better code

❌ **Why this is bad:**
- Vague and not actionable
- No specific steps
- No real evidence
- No measurable impact
- Not generalizable

### Pattern Quality Checklist

Before submitting, ensure your pattern has:

- [ ] Specific problem statement
- [ ] Clear context (when to use it)
- [ ] Step-by-step solution
- [ ] At least one concrete example with code/config
- [ ] Evidence from actual project usage
- [ ] Impact statement (quantified if possible, qualitative otherwise)
- [ ] Trade-offs documented
- [ ] All template sections completed

## Versioning

We follow [Semantic Versioning 2.0.0](https://semver.org/):

### Version Bump Guidelines

**Major Version (X.0.0)** - Breaking changes:
- Restructuring repository layout
- Removing significant patterns or rules
- Changing core organization system
- Changes requiring updates in consuming projects

**Minor Version (1.X.0)** - New functionality:
- Adding new patterns
- Adding new rules
- Adding new templates
- Significantly enhancing existing content
- Adding new categories or sections

**Patch Version (1.0.X)** - Bug fixes:
- Fixing typos or errors
- Clarifying existing content
- Updating cross-references
- Minor formatting improvements
- Link fixes

### Changelog Requirements

All changes must be documented in `CHANGELOG.md`:

1. Add entry to `[Unreleased]` section during development
2. Move to versioned section when releasing
3. Include:
   - What changed
   - Why it changed
   - Link to PR
   - Credit to contributor

See [Versioning Strategy](./meta/versioning.md) for details.

## Code of Conduct

### Our Standards

- Be respectful and professional
- Focus on constructive feedback
- Evidence-based discussions
- Collaborative problem-solving

### Quality Over Quantity

We prefer:
- One well-documented, evidence-backed pattern
- Over ten theoretical, untested ideas

### Attribution

When submitting patterns learned from others:
- Credit the source
- Link to original work
- Explain how you adapted it

## Getting Help

- **Questions about contributing?** Open an issue with the `question` label
- **Need feedback on a pattern idea?** Open a discussion
- **Found a problem?** Open an issue with the `bug` label
- **Want to propose a new category?** Open an issue with the `enhancement` label

## Thank You

Your contributions make this knowledge base valuable for the entire community. Every pattern you submit helps improve AI-assisted development for everyone using Hopper, Czarina, The Symposium, and SARK.

Together, we're building a comprehensive, evidence-based knowledge base that makes AI development more effective and efficient.
