# Agent Project Template

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This template provides a comprehensive structure for creating AI agent projects, including tool integration, orchestration patterns, and multi-agent coordination.

## When to Use This Template

Use this template when:
- Building an AI agent application
- Creating a multi-agent orchestration system
- Developing agent-based automation tools
- Implementing tool-calling agents with MCP integration

## Quick Start

1. Start with [Python Project Template](./python-project-template.md) as base
2. Add agent-specific components from this template
3. Replace `[AGENT_NAME]` with your agent name
4. Replace `[TOOL_CATEGORY]` with your tool domain (e.g., "code", "data", "search")
5. Configure agent roles and orchestration patterns

## Project Structure

```
[AGENT_NAME]/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── agent-validation.yml     # Agent-specific validation
├── src/
│   └── [AGENT_NAME]/
│       ├── __init__.py
│       ├── agents/                  # Agent definitions
│       │   ├── __init__.py
│       │   ├── base.py              # Base agent class
│       │   ├── architect.py         # Planning/design agent
│       │   ├── code.py              # Implementation agent
│       │   ├── debug.py             # Troubleshooting agent
│       │   └── qa.py                # Quality assurance agent
│       ├── tools/                   # Agent tools
│       │   ├── __init__.py
│       │   ├── registry.py          # Tool registry pattern
│       │   ├── [TOOL_CATEGORY]/
│       │   │   ├── __init__.py
│       │   │   └── tool_impl.py
│       │   └── validators.py        # Tool parameter validation
│       ├── orchestration/           # Multi-agent coordination
│       │   ├── __init__.py
│       │   ├── coordinator.py       # Agent coordinator
│       │   ├── workflow.py          # Workflow management
│       │   └── state.py             # Shared state management
│       ├── prompts/                 # Prompt templates
│       │   ├── __init__.py
│       │   ├── system_prompts.py
│       │   └── task_templates.py
│       ├── memory/                  # Agent memory/context
│       │   ├── __init__.py
│       │   ├── context_manager.py
│       │   └── conversation.py
│       ├── utils/
│       │   ├── __init__.py
│       │   ├── config.py
│       │   ├── logging.py
│       │   └── metrics.py           # Agent performance metrics
│       └── api/
│           ├── __init__.py
│           ├── routes.py
│           └── schemas.py           # Pydantic models
├── tests/
│   ├── conftest.py
│   ├── unit/
│   │   ├── test_agents.py
│   │   ├── test_tools.py
│   │   └── test_orchestration.py
│   ├── integration/
│   │   ├── test_agent_workflows.py
│   │   └── test_tool_integration.py
│   └── fixtures/
│       ├── mock_tools.py
│       └── sample_conversations.json
├── agent-rules/                     # Agent behavior rules
│   ├── agents/                      # Agent role definitions
│   ├── patterns/                    # Design patterns
│   ├── workflows/                   # Workflow rules
│   └── security/                    # Security policies
├── prompts/                         # Prompt templates (external)
│   ├── system/
│   │   ├── architect.md
│   │   ├── code.md
│   │   └── debug.md
│   └── tasks/
│       └── examples/
├── .hopper/                         # Hopper integration (if applicable)
│   ├── modes/
│   └── config.yml
├── .env.example
├── pyproject.toml
├── requirements.txt
├── requirements-dev.txt
└── README.md
```

## Core Agent Components

### Base Agent Class

`src/[AGENT_NAME]/agents/base.py`

```python
"""Base agent class with common functionality."""

from abc import ABC, abstractmethod
from typing import Any, AsyncGenerator
from pydantic import BaseModel, Field


class AgentConfig(BaseModel):
    """Agent configuration."""

    name: str = Field(..., description="Agent name")
    role: str = Field(..., description="Agent role (architect, code, debug, qa)")
    model: str = Field(default="claude-opus-4", description="LLM model")
    temperature: float = Field(default=0.7, ge=0.0, le=2.0, description="Temperature")
    max_tokens: int = Field(default=4096, gt=0, description="Maximum tokens")
    system_prompt: str = Field(..., description="System prompt")


class BaseAgent(ABC):
    """Base class for all agents."""

    def __init__(self, config: AgentConfig) -> None:
        """Initialize agent.

        Args:
            config: Agent configuration
        """
        self.config = config
        self.conversation_history: list[dict[str, Any]] = []

    @abstractmethod
    async def process(self, task: str, context: dict[str, Any]) -> str:
        """Process a task.

        Args:
            task: Task description
            context: Task context and parameters

        Returns:
            Agent response
        """
        pass

    @abstractmethod
    async def stream_process(
        self, task: str, context: dict[str, Any]
    ) -> AsyncGenerator[str, None]:
        """Process a task with streaming response.

        Args:
            task: Task description
            context: Task context and parameters

        Yields:
            Response chunks
        """
        yield ""  # Abstract method, must be implemented

    def add_to_history(self, role: str, content: str) -> None:
        """Add message to conversation history.

        Args:
            role: Message role (user, assistant, system)
            content: Message content
        """
        self.conversation_history.append({"role": role, "content": content})

    def clear_history(self) -> None:
        """Clear conversation history."""
        self.conversation_history.clear()
```

### Tool Registry Pattern

`src/[AGENT_NAME]/tools/registry.py`

```python
"""Tool registry for managing agent tools."""

from typing import Any, Callable, Optional
from pydantic import BaseModel, Field


class ToolDefinition(BaseModel):
    """Tool definition with metadata."""

    name: str = Field(..., description="Tool name")
    description: str = Field(..., description="Tool description")
    parameters: dict[str, Any] = Field(..., description="Parameter schema")
    function: Callable[..., Any] = Field(..., description="Tool function")
    category: str = Field(default="general", description="Tool category")
    requires_approval: bool = Field(default=False, description="Requires user approval")


class ToolRegistry:
    """Registry for agent tools."""

    def __init__(self) -> None:
        """Initialize tool registry."""
        self._tools: dict[str, ToolDefinition] = {}

    def register(
        self,
        name: str,
        description: str,
        parameters: dict[str, Any],
        category: str = "general",
        requires_approval: bool = False,
    ) -> Callable[[Callable[..., Any]], Callable[..., Any]]:
        """Register a tool (decorator).

        Args:
            name: Tool name
            description: Tool description
            parameters: Parameter JSON schema
            category: Tool category
            requires_approval: Whether tool requires user approval

        Returns:
            Decorator function
        """

        def decorator(func: Callable[..., Any]) -> Callable[..., Any]:
            tool_def = ToolDefinition(
                name=name,
                description=description,
                parameters=parameters,
                function=func,
                category=category,
                requires_approval=requires_approval,
            )
            self._tools[name] = tool_def
            return func

        return decorator

    def get_tool(self, name: str) -> Optional[ToolDefinition]:
        """Get tool by name.

        Args:
            name: Tool name

        Returns:
            Tool definition or None if not found
        """
        return self._tools.get(name)

    def get_tools_by_category(self, category: str) -> list[ToolDefinition]:
        """Get all tools in a category.

        Args:
            category: Tool category

        Returns:
            List of tool definitions
        """
        return [tool for tool in self._tools.values() if tool.category == category]

    def list_tools(self) -> list[dict[str, Any]]:
        """List all registered tools.

        Returns:
            List of tool definitions (for API schema)
        """
        return [
            {
                "name": tool.name,
                "description": tool.description,
                "parameters": tool.parameters,
                "category": tool.category,
            }
            for tool in self._tools.values()
        ]


# Global registry instance
tool_registry = ToolRegistry()
```

### Agent Coordinator (Orchestration)

`src/[AGENT_NAME]/orchestration/coordinator.py`

```python
"""Agent coordinator for multi-agent workflows."""

from enum import Enum
from typing import Any, Optional
from pydantic import BaseModel, Field

from ..agents.base import BaseAgent


class AgentState(str, Enum):
    """Agent execution states."""

    PENDING = "pending"
    READY = "ready"
    ACTIVE = "active"
    BLOCKED = "blocked"
    COMPLETE = "complete"
    FAILED = "failed"


class AgentTask(BaseModel):
    """Agent task definition."""

    agent_id: str = Field(..., description="Unique agent identifier")
    agent: BaseAgent = Field(..., description="Agent instance")
    task: str = Field(..., description="Task description")
    dependencies: list[str] = Field(default_factory=list, description="Dependency agent IDs")
    state: AgentState = Field(default=AgentState.PENDING, description="Current state")
    result: Optional[str] = Field(default=None, description="Task result")
    error: Optional[str] = Field(default=None, description="Error message if failed")


class AgentCoordinator:
    """Coordinates multiple agents in a workflow."""

    def __init__(self) -> None:
        """Initialize coordinator."""
        self._agents: dict[str, AgentTask] = {}

    def register_agent(
        self, agent_id: str, agent: BaseAgent, task: str, dependencies: list[str] = []
    ) -> None:
        """Register an agent for execution.

        Args:
            agent_id: Unique agent identifier
            agent: Agent instance
            task: Task description
            dependencies: List of agent IDs this agent depends on
        """
        self._agents[agent_id] = AgentTask(
            agent_id=agent_id, agent=agent, task=task, dependencies=dependencies
        )

    async def execute_workflow(self) -> dict[str, str]:
        """Execute all agents respecting dependencies.

        Returns:
            Dictionary of agent_id -> result
        """
        results: dict[str, str] = {}

        # Calculate execution order (topological sort)
        execution_order = self._calculate_execution_order()

        # Execute agents in order
        for agent_id in execution_order:
            agent_task = self._agents[agent_id]

            # Wait for dependencies
            for dep_id in agent_task.dependencies:
                if dep_id not in results:
                    agent_task.state = AgentState.BLOCKED
                    raise ValueError(f"Dependency {dep_id} not completed for {agent_id}")

            # Execute agent
            agent_task.state = AgentState.ACTIVE
            try:
                # Build context from dependency results
                context = {dep_id: results[dep_id] for dep_id in agent_task.dependencies}

                result = await agent_task.agent.process(agent_task.task, context)
                agent_task.result = result
                agent_task.state = AgentState.COMPLETE
                results[agent_id] = result
            except Exception as e:
                agent_task.state = AgentState.FAILED
                agent_task.error = str(e)
                raise

        return results

    def _calculate_execution_order(self) -> list[str]:
        """Calculate execution order using topological sort.

        Returns:
            List of agent IDs in execution order
        """
        # Simple topological sort implementation
        visited = set()
        order = []

        def visit(agent_id: str) -> None:
            if agent_id in visited:
                return
            visited.add(agent_id)

            # Visit dependencies first
            agent_task = self._agents[agent_id]
            for dep_id in agent_task.dependencies:
                visit(dep_id)

            order.append(agent_id)

        for agent_id in self._agents:
            visit(agent_id)

        return order
```

### Prompt Template System

`src/[AGENT_NAME]/prompts/system_prompts.py`

```python
"""System prompt templates for different agent roles."""

ARCHITECT_PROMPT = """You are an expert system architect and technical planner.

Your role:
- Design system architecture and APIs
- Create comprehensive technical specifications
- Make informed technology decisions
- Document architecture decisions (ADRs)
- Plan implementation phases

Follow these principles:
- Prefer simple, proven solutions over complex ones
- Document the "why" behind decisions
- Consider scalability and maintainability
- Account for security and testing requirements

Output format:
- Clear, structured specifications
- Architecture diagrams (Mermaid syntax)
- Decision documentation
- Phase-based implementation plan
"""

CODE_PROMPT = """You are an expert software engineer specializing in implementation.

Your role:
- Implement features following specifications
- Write clean, tested, documented code
- Follow coding standards and best practices
- Create comprehensive unit tests
- Perform self-code review

Follow these principles:
- Code quality over speed
- Test-driven development when appropriate
- Clear commit messages and documentation
- Security-first mindset
- Follow established patterns

Output format:
- Working, tested code
- Comprehensive tests
- Documentation updates
- Commit checkpoints
"""

DEBUG_PROMPT = """You are an expert debugger and troubleshooter.

Your role:
- Diagnose and fix bugs systematically
- Analyze error patterns and root causes
- Implement robust error handling
- Document debugging process
- Prevent similar issues

Follow these steps:
1. Reproduce the issue
2. Isolate the problem
3. Gather evidence (logs, traces, state)
4. Form hypotheses
5. Test fixes
6. Implement solution with tests

Output format:
- Root cause analysis
- Fix implementation with tests
- Prevention measures
- Post-mortem documentation
"""

QA_PROMPT = """You are an expert QA engineer focused on quality and integration.

Your role:
- Perform integration testing
- Validate cross-component functionality
- Review code quality and standards
- Ensure documentation completeness
- Generate closeout reports

Follow these principles:
- Comprehensive testing coverage
- Standards compliance
- Documentation validation
- Metrics collection
- Continuous improvement

Output format:
- Integration test results
- Quality assessment
- Documentation review
- Closeout report
"""
```

## Configuration

### Agent-Specific Settings

`src/[AGENT_NAME]/utils/config.py` (extends base config)

```python
"""Agent-specific configuration."""

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class AgentSettings(BaseSettings):
    """Agent application settings."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Application
    app_name: str = Field(default="[AGENT_NAME]", description="Agent name")
    app_env: str = Field(default="development", description="Environment")
    log_level: str = Field(default="INFO", description="Logging level")

    # LLM Configuration
    anthropic_api_key: str = Field(..., description="Anthropic API key")
    default_model: str = Field(default="claude-opus-4", description="Default LLM model")
    max_tokens: int = Field(default=4096, description="Maximum tokens per request")
    temperature: float = Field(default=0.7, description="LLM temperature")

    # Tool Configuration
    tools_enabled: bool = Field(default=True, description="Enable tool use")
    tool_approval_required: bool = Field(default=False, description="Require approval for tools")

    # Orchestration
    max_concurrent_agents: int = Field(default=5, description="Maximum concurrent agents")
    agent_timeout_seconds: int = Field(default=300, description="Agent timeout in seconds")

    # Memory/Context
    max_conversation_history: int = Field(
        default=50, description="Maximum conversation messages"
    )
    context_window_tokens: int = Field(default=100000, description="Context window size")


settings = AgentSettings()
```

### .env.example

```bash
# Agent Configuration
APP_NAME=[AGENT_NAME]
APP_ENV=development
LOG_LEVEL=INFO

# LLM Configuration
ANTHROPIC_API_KEY=your-api-key-here
DEFAULT_MODEL=claude-opus-4
MAX_TOKENS=4096
TEMPERATURE=0.7

# Tool Configuration
TOOLS_ENABLED=true
TOOL_APPROVAL_REQUIRED=false

# Orchestration
MAX_CONCURRENT_AGENTS=5
AGENT_TIMEOUT_SECONDS=300

# Memory/Context
MAX_CONVERSATION_HISTORY=50
CONTEXT_WINDOW_TOKENS=100000

# Database (if needed)
# DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/[AGENT_NAME]

# Redis (if needed for caching/queuing)
# REDIS_URL=redis://localhost:6379/0
```

## Testing Agent Systems

### Test Configuration

`tests/conftest.py` (agent-specific fixtures)

```python
"""Agent-specific test fixtures."""

import pytest
from unittest.mock import AsyncMock

from src.[AGENT_NAME].agents.base import AgentConfig, BaseAgent
from src.[AGENT_NAME].tools.registry import ToolRegistry


@pytest.fixture
def mock_llm_response() -> str:
    """Provide mock LLM response."""
    return "This is a mock agent response."


@pytest.fixture
def agent_config() -> AgentConfig:
    """Provide test agent configuration."""
    return AgentConfig(
        name="test-agent",
        role="code",
        model="claude-opus-4",
        temperature=0.7,
        max_tokens=1024,
        system_prompt="You are a test agent.",
    )


@pytest.fixture
def tool_registry() -> ToolRegistry:
    """Provide clean tool registry for testing."""
    registry = ToolRegistry()

    # Register test tool
    @registry.register(
        name="test_tool",
        description="A test tool",
        parameters={"type": "object", "properties": {}},
        category="test",
    )
    def test_tool() -> str:
        return "test result"

    return registry


@pytest.fixture
def mock_agent(agent_config: AgentConfig) -> BaseAgent:
    """Provide mock agent for testing."""

    class MockAgent(BaseAgent):
        async def process(self, task: str, context: dict) -> str:
            return f"Processed: {task}"

        async def stream_process(self, task: str, context: dict):
            yield "Streaming response"

    return MockAgent(agent_config)
```

## Related Documents

- [Agent Roles](../core-rules/agent-roles/AGENT_ROLES.md)
- [Tool Use Patterns](../patterns/tool-use/README.md)
- [Error Recovery](../patterns/error-recovery/README.md)
- [Testing Patterns](../core-rules/python-standards/TESTING_PATTERNS.md)
- [Security Patterns](../core-rules/security/README.md)

## References

This template synthesizes patterns from:
- Foundation Worker: Agent roles, orchestration patterns
- Patterns Worker: Tool use, error recovery, streaming
- Testing Worker: Agent testing strategies
- Security Worker: Tool validation, authentication
- Workflows Worker: Multi-agent coordination
