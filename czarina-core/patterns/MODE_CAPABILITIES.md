# Mode Capabilities for Kilo Code

**Purpose**: Define what each Kilo Code mode can and cannot do to prevent mistakes and clarify when to switch modes.

**Value**: Clearer boundaries, fewer mode-switching mistakes, better task routing.

---

## 🎯 Mode Overview

Kilo Code has 5 specialized modes, each with specific capabilities and constraints:

1. **Architect** - Planning and design
2. **Code** - Implementation and modification
3. **Debug** - Troubleshooting and investigation
4. **Ask** - Explanations and learning
5. **Orchestrator** - Multi-task coordination

---

## 🏗️ Architect Mode

**Purpose**: Plan, design, and strategize before implementation.

### ✅ Can Do

- Create implementation plans
- Design system architecture
- Break down complex problems
- Create technical specifications
- Analyze requirements
- Propose solutions
- Create diagrams and flowcharts
- Write design documents
- Estimate effort and complexity

### ❌ Cannot Do

- Write or modify code files
- Execute commands
- Run tests
- Deploy changes
- Modify configuration files

### 📝 Allowed File Patterns

- `*.md` (Markdown documentation)
- `*.txt` (Text files)
- `*.mermaid` (Diagrams)

### 🎯 When to Use

- Starting a new feature
- Planning a refactor
- Designing architecture
- Breaking down complex tasks
- Creating specifications

### 🔄 When to Switch

**Switch to Code mode when**:
- Design is complete
- Ready to implement
- Need to write actual code

**Example**:
```xml
<switch_mode>
<mode_slug>code</mode_slug>
<reason>Design complete, ready to implement the user service</reason>
</switch_mode>
```

---

## 💻 Code Mode

**Purpose**: Write, modify, and refactor code.

### ✅ Can Do

- Create new files
- Modify existing code
- Refactor code
- Fix bugs
- Add features
- Update configuration
- Run tests
- Execute commands
- Use all file modification tools

### ❌ Cannot Do

- Nothing! Code mode has full access

### 📝 Allowed File Patterns

- All files (no restrictions)

### 🎯 When to Use

- Implementing features
- Fixing bugs
- Refactoring code
- Adding tests
- Updating configuration
- Most development work

### 🔄 When to Switch

**Switch to Architect mode when**:
- Need to plan complex changes
- Unclear how to proceed
- Need design before implementation

**Switch to Debug mode when**:
- Systematic troubleshooting needed
- Need to investigate errors
- Analyzing logs and traces

---

## 🐛 Debug Mode

**Purpose**: Systematic troubleshooting and investigation.

### ✅ Can Do

- Investigate errors
- Analyze logs
- Add logging statements
- Run diagnostic commands
- Check system state
- Trace execution
- Identify root causes
- Propose fixes

### ❌ Cannot Do

- Implement fixes (switch to Code mode for that)
- Major refactoring
- New feature development

### 📝 Allowed File Patterns

- All files (for reading and adding logs)
- Can modify files to add logging

### 🎯 When to Use

- Errors occurring
- Unexpected behavior
- Performance issues
- System not working as expected
- Need to understand what's happening

### 🔄 When to Switch

**Switch to Code mode when**:
- Root cause identified
- Ready to implement fix
- Need to refactor

---

## 💬 Ask Mode

**Purpose**: Explanations, documentation, and learning.

### ✅ Can Do

- Explain concepts
- Answer questions
- Provide documentation
- Analyze code (read-only)
- Give recommendations
- Teach and educate

### ❌ Cannot Do

- Modify files
- Execute commands
- Make changes
- Run tests

### 📝 Allowed File Patterns

- All files (read-only)

### 🎯 When to Use

- Learning about codebase
- Understanding concepts
- Getting recommendations
- Analyzing existing code
- Documentation review

### 🔄 When to Switch

**Switch to Code mode when**:
- Ready to implement suggestions
- Need to make changes

**Switch to Architect mode when**:
- Need to plan based on understanding

---

## 🎭 Orchestrator Mode

**Purpose**: Coordinate complex, multi-step projects across different specialties.

### ✅ Can Do

- Break down large tasks
- Create subtasks
- Coordinate work across modes
- Manage workflows
- Track progress
- Delegate to other modes

### ❌ Cannot Do

- Direct implementation (delegates to Code mode)
- Direct debugging (delegates to Debug mode)

### 📝 Allowed File Patterns

- All files (for coordination)

### 🎯 When to Use

- Large, multi-phase projects
- Work spanning multiple domains
- Need coordination across specialties
- Complex workflows

### 🔄 When to Switch

**Delegates to other modes**:
- Code mode for implementation
- Debug mode for troubleshooting
- Architect mode for planning
- Ask mode for explanations

---

## 🎨 Mode Selection Decision Tree

```
What do you need to do?
│
├─ Plan or design?
│  └─ Use: Architect mode
│
├─ Implement or modify code?
│  └─ Use: Code mode
│
├─ Troubleshoot or investigate?
│  └─ Use: Debug mode
│
├─ Learn or understand?
│  └─ Use: Ask mode
│
└─ Coordinate complex project?
   └─ Use: Orchestrator mode
```

---

## 💡 Best Practices

### 1. Start in the Right Mode

**Don't**:
- Start in Code mode for planning
- Start in Architect mode for quick fixes
- Start in Ask mode for implementation

**Do**:
- Match mode to task type
- Switch modes as task evolves
- Use Orchestrator for complex work

### 2. Switch Modes Deliberately

**When switching**:
- Explain why you're switching
- Summarize what was accomplished
- State what the new mode will do

**Example**:
```xml
<switch_mode>
<mode_slug>code</mode_slug>
<reason>Architecture design complete. Ready to implement the 3 services designed in the plan.</reason>
</switch_mode>
```

### 3. Respect Mode Constraints

**If Architect mode tries to edit code**:
```
Error: FileRestrictionError - Architect mode can only edit \.md$ files
```

**Solution**: Switch to Code mode first.

---

## 📊 Mode Usage Statistics (The Symposium)

**From v0.4.5 development** (11.3M tokens):

- **Code mode**: ~85% of work (implementation, testing, fixes)
- **Architect mode**: ~10% of work (planning, design docs)
- **Debug mode**: ~3% of work (troubleshooting)
- **Ask mode**: ~2% of work (understanding, explanations)
- **Orchestrator mode**: <1% (complex multi-phase work)

**Insight**: Most work is Code mode, but starting with Architect saves time on complex features.

---

## 🔗 Related Patterns

- [ERROR_RECOVERY_PATTERNS.md](ERROR_RECOVERY_PATTERNS.md) - Error handling
- [TOOL_USE_PATTERNS.md](TOOL_USE_PATTERNS.md) - Tool efficiency
- [GIT_WORKFLOW_PATTERNS.md](GIT_WORKFLOW_PATTERNS.md) - Git discipline

---

**Last Updated**: 2025-11-29  
**Applicable To**: Kilo Code (other AI assistants have different mode systems)  
**Source**: The Symposium development

*"The right mode for the right task makes all the difference."*