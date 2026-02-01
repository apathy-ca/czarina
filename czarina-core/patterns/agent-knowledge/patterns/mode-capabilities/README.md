# Mode Capabilities and Optimization Patterns

**Purpose**: Mode-specific capabilities, constraints, and optimization patterns for AI coding assistants.

**Status**: To be populated with MODE_CAPABILITIES.md content from agentic-dev-patterns repository.

## Overview

This directory will contain mode-specific patterns and optimization techniques that complement the generic agent role definitions in core-rules. While core-rules define what roles should do in general, this directory shows how to optimize work within specific modes of AI coding assistants.

## Relationship to Core Rules

**Core Rules** define generic agent roles and responsibilities (the "what"):
- [Agent Roles Overview](../../core-rules/agent-roles/README.md) - Role taxonomy and quick start
- [Architect Role](../../core-rules/agent-roles/ARCHITECT_ROLE.md) - Planning and design responsibilities
- [Code Role](../../core-rules/agent-roles/CODE_ROLE.md) - Implementation responsibilities
- [Debug Role](../../core-rules/agent-roles/DEBUG_ROLE.md) - Troubleshooting responsibilities
- [QA Role](../../core-rules/agent-roles/QA_ROLE.md) - Quality assurance responsibilities
- [Orchestrator Role](../../core-rules/agent-roles/ORCHESTRATOR_ROLE.md) - Multi-task coordination

**Patterns** show tool-specific mode optimization (the "how"):
- Mode capabilities and constraints (what each mode can/cannot do)
- Mode transition patterns (when to switch modes)
- Mode-specific workflows (how to work efficiently in each mode)
- Performance optimization per mode
- Tool-specific patterns (Kilo Code, Claude Code, etc.)

## Planned Content

The following patterns are planned for this directory:

### Mode Definitions
- **Architect Mode** - Planning, design, and strategy capabilities
- **Code Mode** - Implementation and modification capabilities
- **Debug Mode** - Troubleshooting and investigation capabilities
- **Ask Mode** - Explanation and learning capabilities
- **Orchestrator Mode** - Multi-task coordination capabilities

### Mode Capabilities Patterns
- What each mode can do
- What each mode cannot do
- File patterns allowed per mode
- Command execution permissions
- Tool access per mode

### Mode Transition Patterns
- When to switch from Architect to Code
- When to switch from Code to Debug
- When to use Ask mode for clarification
- When to escalate to Orchestrator
- Cost optimization through mode selection

### Mode Optimization Techniques
- Maximizing effectiveness in each mode
- Avoiding common mode mistakes
- Mode-specific best practices
- Tool-specific optimizations

### Tool-Specific Patterns
- Kilo Code mode patterns
- Claude Code patterns
- Cursor patterns
- Other AI assistant modes

## Value Proposition

Mode capability patterns from real experience:
- Clearer boundaries between modes
- Fewer mode-switching mistakes
- Better task routing
- Improved cost efficiency
- Optimized workflows per mode

## Relationship Between Roles and Modes

**Agent Roles** (core-rules) are generic:
- Define responsibilities independent of tool
- Describe what work should be done
- Applicable across different AI assistants
- Focus on coordination and handoffs

**Mode Capabilities** (patterns) are tool-specific:
- Define what a specific tool's mode can do
- Optimize workflow within mode constraints
- Tool-specific features and limitations
- Focus on efficient mode usage

## Contributing

When adding patterns to this directory:
1. Specify which AI tool the pattern applies to
2. Include concrete examples of mode capabilities
3. Show both successful and failed approaches
4. Explain mode transition rationale
5. Cross-reference to related agent roles

## Related Core Rules

For generic agent role definitions and responsibilities, see:
- [Agent Roles Overview](../../core-rules/agent-roles/README.md) - Complete role taxonomy
- [Architect Role](../../core-rules/agent-roles/ARCHITECT_ROLE.md) - Design and planning role
- [Code Role](../../core-rules/agent-roles/CODE_ROLE.md) - Implementation role
- [Debug Role](../../core-rules/agent-roles/DEBUG_ROLE.md) - Troubleshooting role
- [QA Role](../../core-rules/agent-roles/QA_ROLE.md) - Quality assurance role
- [Orchestrator Role](../../core-rules/agent-roles/ORCHESTRATOR_ROLE.md) - Coordination role

## Related Patterns

For tool usage optimization, see:
- [Tool Use Patterns](../tool-use/README.md) - Efficient tool usage strategies
