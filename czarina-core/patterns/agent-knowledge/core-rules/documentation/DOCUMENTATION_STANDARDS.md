# Documentation Standards

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This document defines comprehensive documentation standards synthesized from workflows, patterns, and best practices across all agent-rules extraction workers.

## Core Principle

**Documentation is synchronized with code**: Documentation updates must happen in the same commit as code changes. Documentation is never allowed to become stale.

## When to Write Documentation

### Required Documentation

Documentation is **mandatory** for:

1. **Public APIs**
   - All public functions, classes, and methods
   - Parameters, return values, and exceptions
   - Usage examples for non-trivial APIs

2. **Architecture Changes**
   - New components or services
   - Changes to system design
   - Integration patterns
   - Architecture Decision Records (ADRs)

3. **Configuration Changes**
   - New configuration options
   - Environment variables
   - Deployment requirements

4. **User-Facing Features**
   - New features or capabilities
   - Breaking changes
   - Migration guides

### Optional Documentation

Documentation is **recommended** for:

1. **Internal Implementation**
   - Complex algorithms
   - Non-obvious code patterns
   - Performance-critical sections

2. **Development Setup**
   - Local development instructions
   - Troubleshooting guides
   - Common development tasks

## Documentation Structure Standards

### Core Documentation Pattern (2-File Core)

Every project must have at minimum:

#### 1. README.md
**Purpose:** Project overview and getting started guide

**Required Sections:**
- **Project Overview:** What does this project do?
- **Quick Start:** Minimum steps to get running
- **Installation:** How to install/setup
- **Usage:** Basic usage examples
- **Documentation:** Links to other docs
- **License:** License information

**See:** [README Template](../../templates/readme-template.md)

#### 2. ROADMAP.md
**Purpose:** Development roadmap and planning

**Required Sections:**
- **Vision:** Long-term vision
- **Current Status:** Version and status
- **Phases:** Development phases with token budgets
- **Completed Milestones:** What's been done
- **Future Considerations:** What's being considered

**Example:**
\`\`\`markdown
# Roadmap

## Vision
[Long-term vision statement]

## Current Status
**Version:** 0.1.0
**Status:** Alpha

## Phases

### Phase 1: Foundation (Token Budget: 150,000)
**Status:** Complete

- [x] Task 1
- [x] Task 2

### Phase 2: Core Features (Token Budget: 200,000)
**Status:** In Progress

- [x] Task 1
- [ ] Task 2
- [ ] Task 3
\`\`\`

### Additional Core Files

#### VERSION
**Purpose:** Single source of truth for version number

**Format:** Semantic versioning (MAJOR.MINOR.PATCH)

**Example:**
\`\`\`
0.1.0
\`\`\`

**Usage in Code:**
\`\`\`python
# Python
from pathlib import Path

_version_file = Path(__file__).parent.parent / "VERSION"
__version__ = _version_file.read_text().strip()
\`\`\`

\`\`\`typescript
// TypeScript
import { readFileSync } from 'fs';
import { join } from 'path';

const versionFile = join(__dirname, '..', 'VERSION');
export const version = readFileSync(versionFile, 'utf-8').trim();
\`\`\`

#### CHANGELOG.md
**Purpose:** Track all changes across versions

**Format:** [Keep a Changelog](https://keepachangelog.com/)

**See:** [Changelog Standards](./CHANGELOG_STANDARDS.md)

## Inline Documentation Standards

### Python Docstrings

**Style:** Google-style docstrings

**Example:**
\`\`\`python
def calculate_total(
    items: list[Item],
    discount_percent: float = 0.0,
    include_tax: bool = True
) -> Decimal:
    """Calculate total price for items with optional discount and tax.

    This function calculates the total price by summing item prices,
    applying discount, and optionally adding tax. Tax is calculated
    at 10% of the discounted subtotal.

    Args:
        items: List of items to total
        discount_percent: Discount percentage (0-100). Defaults to 0.
        include_tax: Whether to include tax in total. Defaults to True.

    Returns:
        Total price as Decimal with 2 decimal places

    Raises:
        ValueError: If discount_percent is not in range 0-100
        ValueError: If items list is empty

    Example:
        >>> items = [Item(price=10.00), Item(price=20.00)]
        >>> calculate_total(items, discount_percent=10.0)
        Decimal('29.70')
    """
    if not items:
        raise ValueError("Items list cannot be empty")

    if not 0 <= discount_percent <= 100:
        raise ValueError("Discount must be between 0 and 100")

    subtotal = sum(item.price for item in items)
    discounted = subtotal * (1 - discount_percent / 100)

    if include_tax:
        return (discounted * Decimal('1.10')).quantize(Decimal('0.01'))

    return discounted.quantize(Decimal('0.01'))
\`\`\`

**Required Elements:**
- One-line summary (imperative mood)
- Detailed description (if needed)
- Args with types and descriptions
- Returns with type and description
- Raises for all exceptions
- Example for non-trivial usage

### TypeScript/JavaScript Documentation

**Style:** JSDoc with TypeScript types

**Example:**
\`\`\`typescript
/**
 * Calculate total price for items with optional discount and tax.
 *
 * This function calculates the total price by summing item prices,
 * applying discount, and optionally adding tax.
 *
 * @param items - List of items to total
 * @param discountPercent - Discount percentage (0-100). Defaults to 0.
 * @param includeTax - Whether to include tax. Defaults to true.
 * @returns Total price rounded to 2 decimal places
 * @throws {Error} If discount is not in range 0-100
 * @throws {Error} If items array is empty
 *
 * @example
 * ```ts
 * const items = [{ price: 10.00 }, { price: 20.00 }];
 * const total = calculateTotal(items, 10.0);
 * console.log(total); // 29.70
 * ```
 */
function calculateTotal(
  items: Item[],
  discountPercent: number = 0.0,
  includeTax: boolean = true
): number {
  if (items.length === 0) {
    throw new Error('Items array cannot be empty');
  }

  if (discountPercent < 0 || discountPercent > 100) {
    throw new Error('Discount must be between 0 and 100');
  }

  const subtotal = items.reduce((sum, item) => sum + item.price, 0);
  const discounted = subtotal * (1 - discountPercent / 100);

  if (includeTax) {
    return Number((discounted * 1.10).toFixed(2));
  }

  return Number(discounted.toFixed(2));
}
\`\`\`

### Code Comments

**When to Comment:**

✅ **Do comment:**
- Complex algorithms or logic
- Non-obvious decisions or workarounds
- Performance-critical sections
- Temporary fixes or TODOs
- Security-sensitive code

❌ **Don't comment:**
- Obvious code (let the code speak)
- Outdated comments (remove or update)
- Commented-out code (delete it, use git history)
- What the code does (it should be self-evident)

**Good Comments:**
\`\`\`python
# Use binary search for O(log n) lookup on sorted list
# Note: List must be pre-sorted by timestamp
index = binary_search(sorted_items, target_timestamp)

# TEMPORARY: Disable caching due to stale data issue
# TODO: Fix cache invalidation logic (ticket #123)
cache_enabled = False

# SECURITY: Validate input to prevent SQL injection
# All user input must be parameterized
query = "SELECT * FROM users WHERE id = %s"
\`\`\`

**Bad Comments:**
\`\`\`python
# Set x to 5
x = 5

# Loop through items
for item in items:
    # Process item
    process(item)

# Old implementation (don't do this - use git)
# def old_function():
#     ...
\`\`\`

## Documentation Workflow

### Synchronization with Code

**Rule:** Documentation updates must be in the same commit as code changes.

**Process:**
1. Make code changes
2. Update relevant documentation
3. Commit both code and documentation together

**Good Commit:**
\`\`\`bash
feat(api): add user authentication endpoint

- Add POST /api/auth/login endpoint
- Add JWT token generation
- Update API.md with authentication documentation
- Update CHANGELOG.md with new feature

Implements #42
\`\`\`

**Bad Commit:**
\`\`\`bash
# Commit 1
feat(api): add user authentication endpoint

# Commit 2 (later, maybe never)
docs: add authentication documentation
\`\`\`

### Documentation Review Checklist

Before submitting code for review:

- [ ] All new public APIs documented
- [ ] README.md updated if user-facing changes
- [ ] CHANGELOG.md updated with changes
- [ ] Architecture docs updated if design changes
- [ ] Examples validated and working
- [ ] Links between documents working
- [ ] No broken references
- [ ] Spelling and grammar checked

## Documentation Types

### 1. README Files

**Purpose:** Overview and quick start for a directory or project

**Structure:**
\`\`\`markdown
# [Component Name]

## Overview
[What this component/directory is for]

## Quick Reference
[Common tasks or key information]

## Contents
- [File/Directory 1] - [Description]
- [File/Directory 2] - [Description]

## Usage
[How to use this component]

## Related
- [Link to related docs]
\`\`\`

**See:** [README Template](../../templates/readme-template.md)

### 2. API Documentation

**Purpose:** Reference documentation for APIs

**Structure:**
- Endpoint/function listing
- Request/response formats
- Parameters and return values
- Error handling
- Examples

**See:** [API Documentation Standards](./API_DOCUMENTATION.md)

### 3. Architecture Documentation

**Purpose:** System design and component interactions

**Structure:**
- System overview
- Component architecture
- Data flows
- Integration patterns
- Decision records

**See:** [Architecture Documentation Standards](./ARCHITECTURE_DOCS.md)

### 4. Guides and Tutorials

**Purpose:** Step-by-step instructions for specific tasks

**Structure:**
1. Prerequisites
2. Step-by-step instructions
3. Validation/testing
4. Troubleshooting

**Example:**
\`\`\`markdown
# Setting Up Local Development

## Prerequisites

- Python 3.11+
- Docker Desktop
- Git

## Steps

### 1. Clone Repository

\`\`\`bash
git clone https://github.com/org/repo.git
cd repo
\`\`\`

### 2. Set Up Environment

\`\`\`bash
python -m venv venv
source venv/bin/activate
pip install -r requirements-dev.txt
\`\`\`

### 3. Start Services

\`\`\`bash
docker-compose up -d
\`\`\`

### 4. Verify Setup

\`\`\`bash
pytest tests/
\`\`\`

## Troubleshooting

**Problem:** Docker containers won't start
**Solution:** Check Docker Desktop is running...
\`\`\`
\`\`\`

## Documentation Quality Standards

### Clarity

✅ **Clear:**
- Use simple, direct language
- Define technical terms
- Use consistent terminology
- Short paragraphs (3-5 sentences)

❌ **Unclear:**
- Jargon without explanation
- Ambiguous pronouns
- Long, complex sentences
- Inconsistent terminology

### Completeness

✅ **Complete:**
- All parameters documented
- All exceptions documented
- Examples for non-trivial usage
- Links to related documentation

❌ **Incomplete:**
- Missing parameter descriptions
- No examples
- Broken links
- Outdated information

### Accuracy

✅ **Accurate:**
- Tested examples
- Current with code
- Correct technical details
- Working links

❌ **Inaccurate:**
- Untested examples
- Out of sync with code
- Technical errors
- Broken links

## Documentation Maintenance

### When Code Changes

**Always update:**
- Inline documentation (docstrings/comments)
- CHANGELOG.md
- README.md (if user-facing)
- API documentation (if API changes)

**Sometimes update:**
- Architecture docs (if design changes)
- Guides (if workflow changes)

**Rarely update:**
- Vision/mission statements
- Project history

### Regular Reviews

**Quarterly:**
- Review documentation for accuracy
- Check for broken links
- Update outdated examples
- Refresh screenshots

**Annually:**
- Major documentation audit
- Restructure if needed
- Archive obsolete docs
- Update guides for current practices

## Tools and Automation

### Documentation Generation

**API Documentation:**
- Python: Sphinx, pdoc
- TypeScript: TypeDoc, API Extractor
- REST: OpenAPI/Swagger

**Architecture Diagrams:**
- Mermaid (in Markdown)
- PlantUML
- Diagrams.net

### Link Checking

\`\`\`bash
# Check for broken links
markdown-link-check docs/**/*.md
\`\`\`

### Spell Checking

\`\`\`bash
# Check spelling
codespell docs/
\`\`\`

## Documentation Anti-Patterns

### ❌ Anti-Pattern 1: Outdated Documentation

**Problem:** Documentation doesn't match code

**Solution:** Update docs in same commit as code

### ❌ Anti-Pattern 2: No Examples

**Problem:** API documented but no usage examples

**Solution:** Add example for every non-trivial API

### ❌ Anti-Pattern 3: Documentation-Free Code

**Problem:** Public APIs without documentation

**Solution:** Require documentation in code review

### ❌ Anti-Pattern 4: Duplicate Documentation

**Problem:** Same information in multiple places

**Solution:** Single source of truth, link to it

### ❌ Anti-Pattern 5: README Soup

**Problem:** README has everything, too long

**Solution:** Keep README concise, link to detailed docs

## Examples from Projects

### Good Documentation: SARK

From the SARK project, excellent documentation practices:

- Comprehensive README with quick start
- Detailed API documentation
- Architecture diagrams
- Decision records
- Working examples

### Good Documentation: Czarina

From the Czarina orchestration:

- Worker definition templates
- Structured logging documentation
- Clear phase-based planning
- Comprehensive closeout reports

## Related Standards

- [API Documentation Standards](./API_DOCUMENTATION.md)
- [Architecture Documentation Standards](./ARCHITECTURE_DOCS.md)
- [Changelog Standards](./CHANGELOG_STANDARDS.md)
- [README Template](./README_TEMPLATE.md)
- [Documentation Workflow](../workflows/DOCUMENTATION_WORKFLOW.md)

## References

This document synthesizes patterns from:
- Workflows Worker: Documentation workflow, synchronization
- Foundation Worker: Code documentation, docstring patterns
- Patterns Worker: Documentation patterns
- All Workers: README structures, documentation practices
