# Context Management Patterns for AI-Assisted Development

**Purpose**: Strategies for managing context, attention, and memory in AI coding assistant interactions.

**Status**: To be populated with context management patterns.

## Overview

This directory will contain patterns for managing context, attention, and conversation memory when working with AI coding assistants. These patterns help maximize effectiveness within context windows and maintain coherent multi-turn interactions.

## Planned Content

The following patterns are planned for this directory:

### Memory Tiers
- Short-term context (current conversation)
- Mid-term context (recent files and changes)
- Long-term context (project knowledge)
- External memory (documentation, wikis)

### Context Window Management
- Prioritizing information within limited context
- Summarization strategies
- Context switching techniques
- File selection strategies

### Attention Management
- Focusing AI attention on relevant code
- Reducing noise in context
- Progressive disclosure patterns
- Context anchoring

### Conversation Management
- Multi-turn conversation strategies
- Context preservation across turns
- Reference management
- Conversation checkpointing

### Project Knowledge Management
- Maintaining project context
- Documentation as context
- Codebase navigation strategies
- Knowledge extraction from conversations

## Value Proposition

Context management patterns from real experience:
- More effective use of limited context windows
- Better AI understanding of project structure
- Reduced need to re-explain context
- Improved multi-turn conversation quality

## Contributing

When adding patterns to this directory:
1. Focus on practical context management techniques
2. Include examples of effective context usage
3. Explain the rationale and benefits
4. Show both good and bad context management
5. Provide metrics where possible (context usage, effectiveness)

## Related Core Rules

For design patterns that may involve memory and context, see:
- [Design Patterns](../../core-rules/design-patterns/README.md) - Overview of all design patterns
- [Caching Patterns](../../core-rules/design-patterns/CACHING_PATTERNS.md) - May include context caching strategies

## Related Patterns

For tools and workflows that affect context, see:
- [Tool Use Patterns](../tool-use/README.md) - Efficient tool usage affects context
- [Mode Capabilities](../mode-capabilities/README.md) - Different modes have different context needs
