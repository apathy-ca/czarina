# Tool Use Patterns for AI-Assisted Development

**Purpose**: Efficient tool usage strategies and optimization patterns for AI coding assistants.

**Status**: To be populated with TOOL_USE_PATTERNS.md content from agentic-dev-patterns repository.

## Overview

This directory will contain specific tool usage patterns and optimization techniques that complement the comprehensive tool use design patterns in core-rules. While core-rules provide extensive implementations, this directory focuses on practical strategies specific to AI coding assistants.

## Planned Content

The following patterns are planned for this directory:

### File Reading Strategies
- Parallel vs sequential file reading
- When to use search vs read
- Minimizing context usage
- Progressive file exploration

### Modification Approaches
- apply_diff vs write_to_file
- Incremental changes vs full rewrites
- Preserving file structure
- Handling large files

### Command Execution Best Practices
- When to use shell commands
- Batching commands efficiently
- Error handling in commands
- Output parsing strategies

### Performance Optimization
- Reducing redundant operations
- Caching strategies
- Minimizing API calls
- Tool selection optimization

### Search Strategies
- Glob patterns for file discovery
- Grep for code search
- Combining search tools
- Search result interpretation

## Value Proposition

Tool use patterns from real AI-assisted development experience:
- 40-60% improvement in AI assistant efficiency
- Better use of tool capabilities
- Reduced context overhead
- Faster task completion

## Contributing

When adding patterns to this directory:
1. Focus on AI coding assistant tool usage
2. Include concrete examples showing tool usage
3. Explain why certain approaches are more efficient
4. Show both optimal and suboptimal patterns
5. Provide metrics where possible (time saved, context usage)

## Related Core Rules

For comprehensive tool usage design patterns and implementation, see:
- [Tool Use Design Patterns](../../core-rules/design-patterns/TOOL_USE_PATTERNS.md) - Comprehensive tool usage patterns

## Related Patterns

For related optimization strategies, see:
- [Context Management](../context-management/README.md) - Managing context windows and attention
- [Mode Capabilities](../mode-capabilities/README.md) - Tool access and permissions per mode
