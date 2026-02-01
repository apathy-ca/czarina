# Agent Rules Library - Usage Guide

**Version:** 1.0.0
**Last Updated:** 2025-12-27

This guide provides practical examples and workflows for using the Agent Rules Library in real-world scenarios.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Common Scenarios](#common-scenarios)
3. [Workflow Examples](#workflow-examples)
4. [Integration Patterns](#integration-patterns)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)

---

## Getting Started

### First-Time Users

**Step 1: Understand the Structure**
```bash
# Browse the complete index
cat agent-rules/INDEX.md

# Read the main overview
cat agent-rules/README.md
```

**Step 2: Identify Your Needs**

Ask yourself:
- What am I building? (new project, improvement, orchestration)
- What domain applies? (python, agents, security, etc.)
- What's my experience level? (beginner, intermediate, advanced)

**Step 3: Find Relevant Rules**

Use the [INDEX.md](INDEX.md) to find rules by category, or search:
```bash
# Find all rules about testing
grep -r "testing" agent-rules/INDEX.md

# Find all security-related rules
ls agent-rules/security/
```

---

## Common Scenarios

### Scenario 1: Building a New Python Agent

**Goal:** Create a new Python agent from scratch following best practices.

**Steps:**

1. **Review Python Standards**
   ```bash
   # Start with coding standards
   cat agent-rules/python/CODING_STANDARDS.md

   # Understand async patterns
   cat agent-rules/python/ASYNC_PATTERNS.md

   # Learn error handling
   cat agent-rules/python/ERROR_HANDLING.md
   ```

2. **Choose Agent Role**
   ```bash
   # Review role taxonomy
   cat agent-rules/agents/AGENT_ROLES.md

   # Example: Building a Code agent
   cat agent-rules/agents/CODE_ROLE.md
   ```

3. **Use Project Template**
   ```bash
   # Copy the template
   cp agent-rules/templates/agent-project-template.md my-agent/PLAN.md

   # Fill in project-specific details
   vim my-agent/PLAN.md
   ```

4. **Set Up Testing Early**
   ```bash
   # Review testing policy
   cat agent-rules/testing/TESTING_POLICY.md

   # Set up unit tests
   cat agent-rules/testing/UNIT_TESTING.md

   # Use test template
   cp agent-rules/templates/unit-test-template.md my-agent/tests/test_template.py
   ```

5. **Implement Security**
   ```bash
   # Review security practices
   cat agent-rules/security/SECRET_MANAGEMENT.md
   cat agent-rules/security/INJECTION_PREVENTION.md
   ```

**Expected Outcome:** A well-structured Python agent project with tests, security, and documentation.

---

### Scenario 2: Improving Existing Code

**Goal:** Apply best practices to an existing codebase.

**Steps:**

1. **Code Quality Audit**
   ```bash
   # Check against Python standards
   cat agent-rules/python/CODING_STANDARDS.md
   # Review your code for violations

   # Improve error handling
   cat agent-rules/python/ERROR_HANDLING.md
   # Identify areas lacking proper exception handling

   # Review async usage
   cat agent-rules/python/ASYNC_PATTERNS.md
   # Check for blocking calls, missing async/await
   ```

2. **Security Hardening**
   ```bash
   # Audit secret management
   cat agent-rules/security/SECRET_MANAGEMENT.md
   # Look for hardcoded credentials

   # Check for injections
   cat agent-rules/security/INJECTION_PREVENTION.md
   # Review SQL queries, shell commands, etc.

   # Add authentication
   cat agent-rules/security/AUTHENTICATION.md
   # Implement JWT or API key auth
   ```

3. **Add/Improve Tests**
   ```bash
   # Review testing policy
   cat agent-rules/testing/TESTING_POLICY.md

   # Add unit tests
   cat agent-rules/testing/UNIT_TESTING.md
   cp agent-rules/templates/unit-test-template.md tests/

   # Check coverage
   cat agent-rules/testing/COVERAGE_STANDARDS.md
   # Aim for 80%+ coverage
   ```

4. **Improve Documentation**
   ```bash
   # Review documentation standards
   cat agent-rules/documentation/DOCUMENTATION_STANDARDS.md

   # Update README
   cat agent-rules/documentation/README_TEMPLATE.md

   # Document API
   cat agent-rules/documentation/API_DOCUMENTATION.md
   ```

**Expected Outcome:** Code that meets production standards for quality, security, and maintainability.

---

### Scenario 3: Running a Multi-Agent Orchestration

**Goal:** Set up and manage a Czarina-style multi-agent orchestration.

**Steps:**

1. **Understand Orchestration**
   ```bash
   # Study orchestration patterns
   cat agent-rules/orchestration/ORCHESTRATION_PATTERNS.md

   # Review token planning
   cat agent-rules/workflows/TOKEN_PLANNING.md
   ```

2. **Define Workers**
   ```bash
   # Create worker definitions
   cp agent-rules/agents/templates/worker-definition-template.md workers/worker1.md
   cp agent-rules/agents/templates/worker-definition-template.md workers/worker2.md

   # Fill in tasks, dependencies, budgets
   vim workers/worker1.md
   vim workers/worker2.md
   ```

3. **Create Worker Identities**
   ```bash
   # Give each worker an identity
   cp agent-rules/agents/templates/worker-identity-template.md workers/WORKER1_IDENTITY.md
   cp agent-rules/agents/templates/worker-identity-template.md workers/WORKER2_IDENTITY.md

   # Customize for each worker
   vim workers/WORKER1_IDENTITY.md
   ```

4. **Set Up Git Workflow**
   ```bash
   # Review git workflow
   cat agent-rules/workflows/GIT_WORKFLOW.md

   # Create branches for each worker
   git checkout -b feat/worker1
   git checkout main
   git checkout -b feat/worker2
   ```

5. **Monitor Progress**
   ```bash
   # Workers should follow phase development
   cat agent-rules/workflows/PHASE_DEVELOPMENT.md

   # Track token usage
   # Review commits regularly
   ```

6. **Closeout**
   ```bash
   # Each worker creates closeout
   cp agent-rules/agents/templates/worker-closeout-template.md WORKER1_CLOSEOUT.md

   # QA worker creates final closeout
   cat agent-rules/workflows/CLOSEOUT_PROCESS.md
   ```

**Expected Outcome:** Successful multi-agent orchestration with clear task division and comprehensive closeout.

---

### Scenario 4: Integrating with Hopper

**Goal:** Configure Hopper to use agent rules for context-aware assistance.

**Steps:**

1. **Read Integration Guide**
   ```bash
   # Hopper-specific documentation
<!--    cat .hopper/README.md - .hopper directory not included -->
   ```

2. **Configure Modes**
   ```bash
   # Research mode
<!--    cat .hopper/modes/research.md - .hopper directory not included -->

   # Implementation mode
<!--    cat .hopper/modes/implementation.md - .hopper directory not included -->
   ```

3. **Reference Rules in Prompts**
   ```python
   # Example: Loading rules into Hopper context
   hopper_context = {
       "mode": "implementation",
       "rules": [
           "agent-rules/python/CODING_STANDARDS.md",
           "agent-rules/security/INJECTION_PREVENTION.md",
           "agent-rules/testing/UNIT_TESTING.md"
       ]
   }
   ```

4. **Use Rules During Development**
   ```bash
   # Ask Hopper to apply specific rules
   "Please implement this feature following agent-rules/python/ASYNC_PATTERNS.md"

   # Request code review against rules
   "Review this code against agent-rules/security/INJECTION_PREVENTION.md"
   ```

**Expected Outcome:** Hopper provides assistance aligned with your established best practices.

---

## Workflow Examples

### Daily Development Workflow

```bash
# Morning: Review relevant rules
cat agent-rules/python/CODING_STANDARDS.md

# During coding: Reference patterns
cat agent-rules/patterns/ERROR_RECOVERY.md

# Before commit: Check requirements
cat agent-rules/workflows/GIT_WORKFLOW.md

# Before PR: Validate
cat agent-rules/workflows/PR_REQUIREMENTS.md
```

### Code Review Workflow

```bash
# Check code quality
# Compare against: agent-rules/python/CODING_STANDARDS.md

# Check security
# Compare against: agent-rules/security/

# Check testing
# Verify: agent-rules/testing/COVERAGE_STANDARDS.md

# Check documentation
# Verify: agent-rules/documentation/DOCUMENTATION_STANDARDS.md
```

### Project Kickoff Workflow

```bash
# 1. Choose project template
cp agent-rules/templates/python-project-template.md PROJECT_PLAN.md

# 2. Define architecture
cat agent-rules/documentation/ARCHITECTURE_DOCS.md

# 3. Set up testing framework
cat agent-rules/testing/TESTING_POLICY.md

# 4. Plan token budget (if using AI)
cat agent-rules/workflows/TOKEN_PLANNING.md

# 5. Set up git workflow
cat agent-rules/workflows/GIT_WORKFLOW.md
```

---

## Integration Patterns

### Pattern 1: Pre-Commit Hooks

Use rules as validation in pre-commit hooks:

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Checking Python standards..."
# Run linter against agent-rules/python/CODING_STANDARDS.md

echo "Checking security..."
# Run security scanner against agent-rules/security/

echo "Checking test coverage..."
# Verify coverage meets agent-rules/testing/COVERAGE_STANDARDS.md
```

### Pattern 2: CI/CD Integration

Reference rules in CI/CD pipelines:

```yaml
# .github/workflows/ci.yml
name: CI

jobs:
  standards-check:
    runs-on: ubuntu-latest
    steps:
      - name: Check Coding Standards
        run: |
          # Validate against agent-rules/python/CODING_STANDARDS.md
          pylint src/

      - name: Security Scan
        run: |
          # Check against agent-rules/security/
          bandit -r src/

      - name: Test Coverage
        run: |
          # Verify agent-rules/testing/COVERAGE_STANDARDS.md (80%+)
          pytest --cov=src --cov-fail-under=80
```

### Pattern 3: Documentation Generation

Auto-generate docs from rules:

```python
# generate_docs.py
import os
import glob

# Collect all rules
rules = glob.glob("agent-rules/**/*.md", recursive=True)

# Generate index
with open("docs/index.md", "w") as f:
    f.write("# Generated Documentation\n\n")
    for rule in rules:
        # Extract title, create links
        # ...
```

### Pattern 4: LLM System Prompts

Include rules in LLM system prompts:

```python
system_prompt = f"""
You are a Python developer assistant.

Follow these coding standards:
{read_file('agent-rules/python/CODING_STANDARDS.md')}

Apply these security practices:
{read_file('agent-rules/security/INJECTION_PREVENTION.md')}

Write tests according to:
{read_file('agent-rules/testing/UNIT_TESTING.md')}
"""
```

---

## Best Practices

### 1. Start with the Index

Always begin with [INDEX.md](INDEX.md) to find relevant rules quickly.

### 2. Follow the Dependency Order

Some rules build on others:
1. Start with CODING_STANDARDS
2. Then ERROR_HANDLING
3. Then ASYNC_PATTERNS
4. Then TESTING_PATTERNS

### 3. Use Templates

Don't start from scratch:
- Use `templates/` for project structure
- Customize for your needs
- Share improvements back to the library

### 4. Cross-Reference Rules

Rules reference each other. Follow the links to build comprehensive understanding.

### 5. Apply Incrementally

Don't try to apply all rules at once:
- Pick 2-3 high-impact rules
- Apply them thoroughly
- Add more over time

### 6. Adapt to Your Context

These are guidelines, not rigid requirements:
- Understand the "why" behind each rule
- Adapt to your specific needs
- Document deviations

---

## Troubleshooting

### "Too Many Rules - Where Do I Start?"

**Solution:** Use the domain READMEs for curated introductions.

```bash
# Start with domain overview
cat agent-rules/python/README.md

# Then read individual rules
cat agent-rules/python/CODING_STANDARDS.md
```

### "Rules Conflict with My Current Approach"

**Solution:** Understand the reasoning, then decide:

1. Read the "Why This Matters" section in the rule
2. Check if your approach has benefits the rule doesn't consider
3. Make an informed decision
4. Document your choice

### "Can't Find Rule for My Specific Case"

**Solution:** Find the closest rule and adapt:

1. Check [INDEX.md](INDEX.md) for related rules
2. Read domain README for guidance
3. Combine multiple rules
4. Consider contributing a new rule

### "Rules Too Detailed / Not Detailed Enough"

**Solution:** Different audiences need different depth:

- **Too detailed:** Focus on "Overview" and "Quick Reference" sections
- **Not detailed enough:** Check "Related Rules" for deeper dives
- **Need examples:** Look for "Examples" sections in each rule

### "Hopper Integration Not Working"

**Solution:** Check the Hopper README:

```bash
<!-- cat .hopper/README.md - .hopper directory not included -->
```

Common issues:
- Rules not in Hopper's context path
- Mode configuration incorrect
- File references broken

---

## Quick Reference Cards

### New Project Checklist

- [ ] Read `python/CODING_STANDARDS.md`
- [ ] Choose agent role from `agents/AGENT_ROLES.md`
- [ ] Use `templates/agent-project-template.md`
- [ ] Set up testing per `testing/TESTING_POLICY.md`
- [ ] Implement security per `security/SECRET_MANAGEMENT.md`
- [ ] Follow git workflow from `workflows/GIT_WORKFLOW.md`

### Code Review Checklist

- [ ] Meets `python/CODING_STANDARDS.md`
- [ ] Has tests per `testing/UNIT_TESTING.md`
- [ ] Coverage ≥80% per `testing/COVERAGE_STANDARDS.md`
- [ ] No security issues per `security/`
- [ ] Documented per `documentation/DOCUMENTATION_STANDARDS.md`
- [ ] PR follows `workflows/PR_REQUIREMENTS.md`

### Orchestration Checklist

- [ ] Read `orchestration/ORCHESTRATION_PATTERNS.md`
- [ ] Plan tokens per `workflows/TOKEN_PLANNING.md`
- [ ] Define workers with `agents/templates/worker-definition-template.md`
- [ ] Create identities with `agents/templates/worker-identity-template.md`
- [ ] Set up git per `workflows/GIT_WORKFLOW.md`
- [ ] Closeout with `agents/templates/worker-closeout-template.md`

---

## Getting Help

1. **Check the INDEX:** [INDEX.md](INDEX.md)
2. **Read domain READMEs:** Each domain has comprehensive overview
3. **Search the library:** Use grep/search for keywords
4. **Follow cross-references:** Rules link to related rules
<!-- 5. **Consult Hopper integration:** <!-- .hopper/README.md - .hopper directory not included in this repository --> - .hopper directory not included -->

---

## Contributing

Found this guide helpful? Make it better:

1. Add more examples
2. Document new scenarios
3. Improve troubleshooting section
4. Share your integration patterns

See [README.md](README.md) for contribution guidelines.

---

**Ready to start?** Pick a scenario above and begin applying the rules!
