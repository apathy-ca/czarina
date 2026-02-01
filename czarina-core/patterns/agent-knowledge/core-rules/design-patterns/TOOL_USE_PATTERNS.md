# Tool Use Patterns for Agent Development

**Purpose**: Proven patterns for implementing and using tools in AI agent systems.

**Value**: Robust tool integration with health checking, error handling, and composition strategies.

**Source**: TheSymposium project (function calling system, tools integration, MCP support)

---

## 🎯 Philosophy

**Good tool use**:
- Checks tool availability before calling
- Validates parameters against schemas
- Handles errors gracefully with fallbacks
- Provides clear, structured responses
- Supports tool composition

**Bad tool use**:
- Calls tools without availability checks
- Passes unvalidated parameters
- Fails silently on errors
- Returns inconsistent response formats
- Tightly couples to specific tool names

---

## 📋 Table of Contents

1. [Tool Registry Pattern](#tool-registry-pattern)
2. [Tool Integration Layer](#tool-integration-layer)
3. [Function Calling System](#function-calling-system)
4. [Parameter Validation](#parameter-validation)
5. [Error Handling](#error-handling)
6. [Tool Composition](#tool-composition)
7. [Natural Language Function Parsing](#natural-language-function-parsing)
8. [MCP Integration](#mcp-integration)
9. [Testing Patterns](#testing-patterns)
10. [Anti-Patterns](#anti-patterns)

---

## Tool Registry Pattern

### Overview

Central tool discovery and management system with health status tracking.

### Implementation

**File Reference**: `thesymposium/sage-containers/core/sage_loop/tools_registry.py:14-256`

```python
from enum import Enum
from dataclasses import dataclass
from typing import Optional, Dict, List

class ToolStatus(Enum):
    """Tool availability status"""
    AVAILABLE = "available"
    UNAVAILABLE = "unavailable"
    ERROR = "error"
    UNKNOWN = "unknown"

@dataclass
class ToolInfo:
    """Tool metadata and status"""
    tool_id: str
    name: str
    description: str
    category: str
    health_status: ToolStatus
    last_checked: float
    endpoints: Dict[str, Dict]
    tags: List[str] = None

class ToolsRegistry:
    def __init__(self, tools_portal_url: str):
        self.tools_portal_url = tools_portal_url
        self._tools: Dict[str, ToolInfo] = {}
        self.last_discovery: Optional[float] = None

    async def discover_tools(self) -> Dict[str, ToolInfo]:
        """Discover available tools from portal"""

        # Graceful degradation: standalone mode detection
        if "none" in self.tools_portal_url.lower() or \
           "localhost" in self.tools_portal_url:
            logger.info("🔧 Standalone mode detected - skipping tools discovery")
            return {}

        try:
            response = await self.http_client.get(f"{self.tools_portal_url}/tools")
            if response.status_code == 200:
                tools_data = response.json()
                self._tools = self._parse_tools(tools_data)
                self.last_discovery = time.time()
                return self._tools
        except Exception as e:
            logger.error(f"Tool discovery failed: {e}")
            return {}

    async def check_tool_health(self, tool_id: str) -> ToolStatus:
        """Check if tool is currently available"""
        tool_info = self._tools.get(tool_id)
        if not tool_info:
            return ToolStatus.UNKNOWN

        try:
            # Health check endpoint
            response = await self.http_client.get(
                f"{self.tools_portal_url}/tools/{tool_id}/health"
            )
            if response.status_code == 200:
                tool_info.health_status = ToolStatus.AVAILABLE
            else:
                tool_info.health_status = ToolStatus.UNAVAILABLE
        except Exception as e:
            tool_info.health_status = ToolStatus.ERROR

        tool_info.last_checked = time.time()
        return tool_info.health_status

    def get_available_tools(self) -> List[ToolInfo]:
        """Filter tools by health status"""
        return [
            tool for tool in self._tools.values()
            if tool.health_status == ToolStatus.AVAILABLE
        ]
```

### Key Features

1. **Dynamic tool discovery** from external Tools Portal
2. **Health status tracking** with timestamps
3. **Graceful degradation** for standalone mode
4. **Tool categorization** and filtering
5. **Last discovery timestamp** for cache invalidation

### Best Practices

- Always check `health_status == ToolStatus.AVAILABLE` before calling
- Implement graceful degradation for offline operation
- Track last checked timestamp for cache invalidation
- Use tool categories for organization and filtering
- Log tool discovery failures for debugging

**File Reference**: `thesymposium/sage-containers/core/sage_loop/tools_registry.py:56-107`

---

## Tool Integration Layer

### Overview

HTTP-based tool invocation wrapper with consistent response format.

### Generic Tool Calling Interface

**File Reference**: `thesymposium/sage-containers/core/sage_loop/tools_integration.py:280-332`

```python
class ToolsIntegration:
    def __init__(self, tools_registry: ToolsRegistry):
        self.tools_registry = tools_registry
        self.http_client = httpx.AsyncClient(timeout=30.0)

    async def generic_tool_call(
        self,
        tool_id: str,
        endpoint_name: str,
        method: str = "GET",
        data: Optional[Dict[str, Any]] = None,
        params: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Universal tool calling interface

        Args:
            tool_id: Identifier for the tool
            endpoint_name: Specific endpoint to call
            method: HTTP method (GET, POST, PUT, DELETE)
            data: JSON body for POST/PUT
            params: Query parameters

        Returns:
            Standardized response format
        """
        # 1. Check tool availability
        tool_info = await self.tools_registry.get_tool_info(tool_id)
        if not tool_info or tool_info.health_status != ToolStatus.AVAILABLE:
            return {
                "success": False,
                "error": f"Tool '{tool_id}' not available",
                "tool": tool_id
            }

        # 2. Get endpoint configuration
        endpoint = tool_info.endpoints.get(endpoint_name)
        if not endpoint:
            return {
                "success": False,
                "error": f"Endpoint '{endpoint_name}' not found",
                "tool": tool_id
            }

        # 3. Build request URL
        url = f"{tool_info.base_url}{endpoint['path']}"

        # 4. Execute request
        try:
            if method == "GET":
                response = await self.http_client.get(url, params=params)
            elif method == "POST":
                response = await self.http_client.post(url, json=data)
            elif method == "PUT":
                response = await self.http_client.put(url, json=data)
            elif method == "DELETE":
                response = await self.http_client.delete(url)
            else:
                return {"success": False, "error": f"Unsupported method: {method}"}

            # 5. Process response
            if response.status_code == 200:
                try:
                    result_data = response.json()
                except json.JSONDecodeError:
                    result_data = {"text": response.text}

                return {
                    "success": True,
                    "tool": tool_id,
                    "endpoint": endpoint_name,
                    "data": result_data,
                    "status_code": response.status_code
                }
            else:
                return {
                    "success": False,
                    "error": f"HTTP {response.status_code}: {response.text}",
                    "tool": tool_id,
                    "status_code": response.status_code
                }

        except Exception as e:
            return {
                "success": False,
                "error": f"Request failed: {str(e)}",
                "tool": tool_id
            }
```

### Structured Response Format

All tool calls return a consistent format:

```python
{
    "success": bool,           # Operation success status
    "error": Optional[str],    # Error message if failed
    "tool": Optional[str],     # Tool identifier
    "endpoint": Optional[str], # Endpoint name
    "data": Optional[Dict],    # Response data
    "status_code": Optional[int]  # HTTP status code
}
```

### Best Practices

1. **Always set timeouts** - prevent hanging on unresponsive tools (default: 30s)
2. **Check HTTP status codes** explicitly - don't assume 200
3. **Handle JSON decode errors** - fallback to text response
4. **Return structured errors** - include context for debugging
5. **Use async/await** - non-blocking I/O for concurrent tool calls

**File Reference**: `thesymposium/sage-containers/core/sage_loop/tools_integration.py:33-63`

---

## Function Calling System

### Overview

Three-tier architecture for function registry, validation, and execution.

### Architecture

**File Reference**: `thesymposium/sage-containers/core/sage_loop/function_calling.py:18-27`

```python
class FunctionRegistry:
    """Central registry of available functions"""

    def __init__(self):
        self._functions: Dict[str, Dict] = {}

    def register(
        self,
        name: str,
        handler: Callable,
        description: str,
        parameters: Dict[str, Any]
    ):
        """
        Register a function with its handler and schema

        Args:
            name: Function name for LLM to call
            handler: Async function to execute
            description: What the function does
            parameters: JSON Schema format parameter definitions
        """
        self._functions[name] = {
            "handler": handler,
            "description": description,
            "parameters": parameters
        }

    def get_function_descriptions(self) -> List[Dict]:
        """Get all function descriptions for LLM context"""
        return [
            {
                "name": name,
                "description": func["description"],
                "parameters": func["parameters"]
            }
            for name, func in self._functions.items()
        ]
```

### Function Registration Example

```python
# Register DNS analysis function
registry.register(
    name="dns_analyze_domain",
    handler=self.tools_integration.dns_analyze_domain,
    description="Analyze DNS configuration for a domain",
    parameters={
        "type": "object",
        "properties": {
            "domain": {
                "type": "string",
                "description": "Domain name to analyze (e.g., example.com)"
            },
            "dns_server": {
                "type": "string",
                "description": "DNS server to query (optional, e.g., 8.8.8.8)"
            },
            "verbose": {
                "type": "boolean",
                "description": "Include detailed information",
                "default": False
            }
        },
        "required": ["domain"]
    }
)
```

### Best Practices

1. **Use JSON Schema** for parameter definitions - IDE support, validation
2. **Mark required fields** explicitly in schema
3. **Provide descriptions** for each parameter - helps LLM
4. **Include examples** in descriptions when helpful
5. **Use default values** for optional parameters

---

## Parameter Validation

### Overview

Comprehensive parameter validation before function execution.

### Implementation

**File Reference**: `thesymposium/sage-containers/core/sage_loop/function_calling.py:794-843`

```python
async def execute_function(
    self,
    function_name: str,
    parameters: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Execute a registered function with validation

    Args:
        function_name: Name of function to execute
        parameters: Function parameters

    Returns:
        Function result or error details
    """
    # 1. Check function exists
    if function_name not in self._functions:
        return {
            "success": False,
            "error": f"Function '{function_name}' not found",
            "available_functions": list(self._functions.keys())
        }

    func_info = self._functions[function_name]
    param_schema = func_info["parameters"]

    # 2. Validate required parameters
    required_params = param_schema.get("required", [])
    missing_params = []

    for param_name in required_params:
        if param_name not in parameters or parameters[param_name] is None:
            missing_params.append(param_name)

    if missing_params:
        # Build helpful error message
        param_details = param_schema.get("properties", {})
        hints = []
        for param in missing_params:
            if param in param_details:
                desc = param_details[param].get("description", "")
                hints.append(f"  - {param}: {desc}")

        return {
            "success": False,
            "error": f"Missing required parameters: {', '.join(missing_params)}",
            "hint": "Required parameters:\n" + "\n".join(hints),
            "example": self._build_example(function_name, param_schema)
        }

    # 3. Type conversion for known types
    converted_params = {}
    for key, value in parameters.items():
        if key in param_schema.get("properties", {}):
            expected_type = param_schema["properties"][key].get("type")
            if expected_type == "integer" and isinstance(value, str):
                converted_params[key] = int(value)
            elif expected_type == "boolean" and isinstance(value, str):
                converted_params[key] = value.lower() in ["true", "1", "yes"]
            else:
                converted_params[key] = value
        else:
            converted_params[key] = value

    # 4. Execute function
    try:
        handler = func_info["handler"]
        result = await handler(**converted_params)
        return result

    except TypeError as e:
        error_str = str(e)
        if "missing" in error_str and "required positional argument" in error_str:
            return {
                "success": False,
                "error": f"Function {function_name} is missing required parameters.",
                "hint": "Check the function description for required parameters",
                "details": error_str
            }
        raise

    except Exception as e:
        return {
            "success": False,
            "error": f"Function execution failed: {str(e)}",
            "function": function_name,
            "parameters": converted_params
        }
```

### Validation Features

1. **Required parameter checking** - before execution
2. **Type conversion** - automatic int/float/bool conversion
3. **Helpful error messages** - includes parameter descriptions
4. **Example generation** - shows correct usage
5. **Exception categorization** - type errors vs general errors

### Best Practices

- Validate parameters **before** executing expensive operations
- Provide **context** in error messages (what was expected)
- Include **examples** of correct usage in errors
- Convert **types automatically** when safe to do so
- Catch **specific exceptions** (TypeError) for better messages

---

## Error Handling

### Overview

Multi-level error handling with graceful degradation.

### Error Handling Hierarchy

**File Reference**: `thesymposium/sage-containers/core/sage_loop/function_calling.py:849-864`

```python
# Level 1: Pre-execution validation
if not function_exists:
    return {"success": False, "error": "Function not found"}

if missing_parameters:
    return {"success": False, "error": "Missing params", "hint": "..."}

# Level 2: Type errors (wrong arguments)
try:
    result = await handler(**parameters)
except TypeError as e:
    if "missing" in str(e) and "required positional argument" in str(e):
        return {
            "success": False,
            "error": "Missing required parameters",
            "hint": "Check function description",
            "details": str(e)
        }
    raise  # Re-raise if not parameter issue

# Level 3: General execution errors
except Exception as e:
    return {
        "success": False,
        "error": f"Execution failed: {str(e)}",
        "function": function_name,
        "parameters": parameters  # Include for debugging
    }
```

### Tool Availability Errors

**File Reference**: `thesymposium/sage-containers/core/sage_loop/tools_integration.py:34-35`

```python
# Check before calling
tool_info = await tools_registry.get_tool_info("dns-by-eye")
if not tool_info or tool_info.health_status != ToolStatus.AVAILABLE:
    return {
        "success": False,
        "error": "DNS By Eye tool not available",
        "fallback": "Try using alternative DNS tool or check later"
    }
```

### HTTP Error Handling

**File Reference**: `thesymposium/sage-containers/core/sage_loop/tools_integration.py:50-63`

```python
# Always check status codes
if response.status_code == 200:
    return {
        "success": True,
        "tool": "dns-by-eye",
        "data": response.json()
    }
elif response.status_code == 404:
    return {
        "success": False,
        "error": "Endpoint not found",
        "status_code": 404
    }
elif response.status_code >= 500:
    return {
        "success": False,
        "error": f"Server error: {response.status_code}",
        "retryable": True  # Indicate this might work later
    }
else:
    return {
        "success": False,
        "error": f"HTTP {response.status_code}: {response.text}"
    }
```

### Best Practices

1. **Fail gracefully** - return structured errors, don't raise
2. **Preserve context** - include function name, parameters in errors
3. **Indicate retryability** - mark temporary vs permanent failures
4. **Log appropriately**:
   - INFO: Successful operations
   - WARNING: Degraded states, fallbacks
   - ERROR: Actual failures
5. **Provide hints** - help user or LLM fix the issue

---

## Tool Composition

### Overview

Patterns for combining multiple tool calls effectively.

### Sequential Composition

**File Reference**: `thesymposium/sage-containers/core/sage_loop/sage_tools_demo.py:35-92`

```python
# LLM response with multiple tool calls
response = """
I'll analyze the DNS configuration for example.com:

CALL_FUNCTION(dns_analyze_domain, domain="example.com", verbose=true)

Now let me trace the DNS delegation:

CALL_FUNCTION(dns_trace_domain, domain="example.com", verbose=true)

And get the authoritative nameservers:

CALL_FUNCTION(dns_get_nameservers, domain="example.com")
"""

# Process each function call sequentially
processed_response = await function_calling.process_response(response)
```

### Execution Pipeline

**File Reference**: `thesymposium/sage-containers/core/sage_loop/function_calling.py:1049-1077`

```python
async def process_response(self, response_text: str) -> str:
    """
    Extract and execute function calls from LLM response

    Process:
    1. Extract CALL_FUNCTION() patterns
    2. Validate and execute each
    3. Replace calls with results
    4. Return processed response
    """
    # 1. Extract function calls
    function_calls = FunctionCallParser.extract_function_calls(response_text)

    # 2. Execute sequentially
    results = []
    for call in function_calls:
        function_name = call["function"]
        parameters = call["parameters"]

        result = await self.execute_function(function_name, parameters)
        results.append({
            "call": call,
            "result": result
        })

    # 3. Replace in response
    processed = response_text
    for item in results:
        call_text = item["call"]["original_text"]
        result_text = self._format_result(item["result"])
        processed = processed.replace(call_text, result_text)

    return processed
```

### Conditional Composition

Tools called based on natural language patterns:

```python
# Natural language → Tool selection
user_input = "What's the DNS configuration for example.com?"

# Parser detects intent
detected = await natural_parser.parse(user_input)
# Returns: {
#     "function": "dns_analyze_domain",
#     "parameters": {"domain": "example.com"},
#     "confidence": 0.85
# }

# Only call if confidence high enough
if detected["confidence"] > 0.7:
    result = await execute_function(
        detected["function"],
        detected["parameters"]
    )
```

### Best Practices

1. **Execute sequentially** when later calls need earlier results
2. **Use parallel execution** for independent operations
3. **Check confidence scores** for natural language parsing
4. **Limit composition depth** - avoid infinite chains
5. **Cache intermediate results** - avoid redundant calls

---

## Natural Language Function Parsing

### Overview

Convert natural language to function calls using pattern matching.

### Implementation

**File Reference**: `thesymposium/sage-containers/core/sage_loop/natural_function_parser.py:96-154`

```python
class NaturalFunctionParser:
    """Parse natural language into function calls"""

    # Intent patterns with priority
    PATTERNS = {
        r'(?:remember|recall|what did (?:we|I|you)|do you remember).*?(?:about|regarding|concerning)\s+([^?.!]+)': {
            'function': 'search_memories',
            'priority': 'high',
            'extract': ['topic']
        },
        r'(?:analyze|check|examine|investigate)\s+(?:the\s+)?dns.*?(?:for|of)\s+([^\s?.!]+)': {
            'function': 'dns_analyze_domain',
            'priority': 'high',
            'extract': ['domain']
        },
        r'(?:what|who).*?ip\s+address.*?([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})': {
            'function': 'ip_analyze',
            'priority': 'medium',
            'extract': ['ip_address']
        }
    }

    async def parse(self, text: str) -> Optional[Dict]:
        """
        Parse natural language to function call

        Returns:
            {
                "function": str,
                "parameters": Dict,
                "confidence": float,
                "matched_pattern": str
            }
        """
        matches = []

        for pattern, config in self.PATTERNS.items():
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                # Extract parameters
                parameters = {}
                for i, param_name in enumerate(config.get('extract', []), 1):
                    if i <= len(match.groups()):
                        parameters[param_name] = match.group(i).strip()

                # Calculate confidence
                confidence = self._calculate_confidence(
                    text, match, config['priority']
                )

                matches.append({
                    "function": config['function'],
                    "parameters": parameters,
                    "confidence": confidence,
                    "matched_pattern": pattern
                })

        # Return highest confidence match
        if matches:
            return max(matches, key=lambda x: x['confidence'])

        return None
```

### Confidence Calculation

**File Reference**: `thesymposium/sage-containers/core/sage_loop/natural_function_parser.py:311-339`

```python
def _calculate_confidence(
    self,
    text: str,
    match: re.Match,
    priority: str
) -> float:
    """
    Calculate confidence score (0.0 - 1.0)

    Factors:
    - Base: 0.5
    - Priority: +0.3 (high), +0.1 (medium), -0.1 (low)
    - Match quality: +0.1 if lengthy match
    - Context: +0.05 for questions, polite phrases
    """
    confidence = 0.5  # Base

    # Priority adjustment
    if priority == 'high':
        confidence += 0.3
    elif priority == 'medium':
        confidence += 0.1
    else:  # low priority
        confidence -= 0.1

    # Match quality
    matched_text = match.group(0)
    if len(matched_text) > 20:  # Substantial match
        confidence += 0.1

    # Context indicators
    if '?' in text:  # Question form
        confidence += 0.05
    if any(word in text.lower() for word in ['please', 'could', 'would']):
        confidence += 0.05

    return min(1.0, confidence)  # Cap at 1.0
```

### Best Practices

1. **Use priority levels** - differentiate common vs rare intents
2. **Calculate confidence** - only execute above threshold (0.7+)
3. **Extract parameters** from regex groups
4. **Handle ambiguity** - return top N matches if close
5. **Log low confidence** - identify patterns that need improvement

---

## MCP Integration

### Overview

Model Context Protocol (MCP) integration for dynamic tool registration.

### Dynamic Tool Registration

**File Reference**: `thesymposium/sage-containers/core/sage_loop/function_calling.py:158-202`

```python
def _register_mcp_tools(self):
    """Register tools from MCP servers dynamically"""

    servers = self.mcp_manager.get_available_servers()

    for server_name in servers:
        client = self.mcp_manager.get_client(server_name)

        for tool in client.available_tools:
            tool_name = tool.name

            # Create unique function name
            func_name = f"mcp_{server_name}_{tool_name}"

            # Create handler using closure
            def make_mcp_handler(srv_name, tl_name):
                async def handler(**kwargs):
                    return await self.mcp_manager.call_tool(
                        srv_name,
                        tl_name,
                        kwargs
                    )
                return handler

            # Register with function registry
            self.register_function(
                name=func_name,
                handler=make_mcp_handler(server_name, tool_name),
                description=tool.description,
                parameters=tool.input_schema
            )
```

### Key Pattern: Closure-Based Handlers

Using closures to capture server/tool names:

```python
def make_mcp_handler(srv_name, tl_name):
    # Closure captures srv_name and tl_name
    async def handler(**kwargs):
        return await self.mcp_manager.call_tool(srv_name, tl_name, kwargs)
    return handler
```

**Why closures?** Each handler needs its own server/tool reference, closures create separate contexts.

### Best Practices

1. **Use closures** for dynamic registration - each tool gets isolated context
2. **Prefix tool names** - avoid conflicts (`mcp_{server}_{tool}`)
3. **Pass through schemas** - use MCP's input_schema directly
4. **Handle connection lifecycle** - maintain MCP connections during session
5. **No automatic reconnection** - explicitly handle connection failures

---

## Testing Patterns

### Overview

Comprehensive testing strategy for tool integration.

### Test Structure

**File Reference**: `thesymposium/sage-containers/core/sage_loop/test_tools_integration.py:16-314`

```python
class ToolsIntegrationTests:
    """Comprehensive tool integration test suite"""

    @pytest.fixture
    async def tools_integration(self):
        """Setup test instance with mock registry"""
        registry = MockToolsRegistry()
        integration = ToolsIntegration(registry)
        yield integration
        await integration.close()

    async def test_tools_discovery(self) -> Dict[str, Any]:
        """Test 1: Tools Discovery"""
        try:
            result = await self.tools_integration.discover_tools()
            return {
                "test": "tools_discovery",
                "success": result.get("success", False),
                "tools_count": len(result.get("tools", [])),
                "total_tests": 1,
                "successful_tests": 1 if result.get("success") else 0
            }
        except Exception as e:
            return {
                "test": "tools_discovery",
                "success": False,
                "error": str(e)
            }

    async def test_dns_functions(self) -> Dict[str, Any]:
        """Test 2: DNS Analysis Functions"""
        tests = []

        # Test dns_analyze_domain
        result1 = await self.tools_integration.dns_analyze_domain(
            domain="example.com",
            verbose=True
        )
        tests.append({
            "function": "dns_analyze_domain",
            "success": result1.get("success", False)
        })

        # Test dns_trace_domain
        result2 = await self.tools_integration.dns_trace_domain(
            domain="example.com"
        )
        tests.append({
            "function": "dns_trace_domain",
            "success": result2.get("success", False)
        })

        success_count = sum(1 for t in tests if t["success"])
        return {
            "test": "dns_functions",
            "success": success_count == len(tests),
            "total_tests": len(tests),
            "successful_tests": success_count,
            "results": tests
        }

    async def test_function_calling_system(self) -> Dict[str, Any]:
        """Test 3: Function Calling Pipeline"""
        # Test parameter validation
        result1 = await self.function_registry.execute_function(
            "dns_analyze_domain",
            {"domain": "example.com"}
        )

        # Test missing parameters
        result2 = await self.function_registry.execute_function(
            "dns_analyze_domain",
            {}  # Missing required 'domain'
        )

        # Test unknown function
        result3 = await self.function_registry.execute_function(
            "unknown_function",
            {}
        )

        return {
            "test": "function_calling",
            "success": (
                result1.get("success") and
                not result2.get("success") and
                not result3.get("success")
            ),
            "validation_works": not result2.get("success"),
            "error_handling_works": not result3.get("success")
        }
```

### Test Categories

1. **Tools Discovery** - validates tool registry population
2. **Specific Tool Functions** - tests individual tool implementations
3. **Function Calling System** - tests execution pipeline
4. **Generic Tool Calls** - tests dynamic tool invocation
5. **Error Scenarios** - validates error handling

### Best Practices

1. **Use fixtures** for setup/teardown
2. **Test both success and failure** paths
3. **Validate error messages** - not just success flags
4. **Clean up resources** - async cleanup in fixtures
5. **Return structured results** - enable test aggregation

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Missing Health Checks

**Bad:**
```python
# Call tool without checking availability
result = await tools.call_dns_tool("example.com")
```

**Good:**
```python
# Check availability first
tool_info = await registry.get_tool_info("dns-tool")
if not tool_info or tool_info.health_status != ToolStatus.AVAILABLE:
    return {"success": False, "error": "Tool not available"}

result = await tools.call_dns_tool("example.com")
```

---

### ❌ Anti-Pattern 2: Unvalidated Parameters

**Bad:**
```python
# Pass parameters directly without validation
result = await handler(**parameters)
```

**Good:**
```python
# Validate against schema first
required = schema.get("required", [])
missing = [p for p in required if p not in parameters]

if missing:
    return {
        "success": False,
        "error": f"Missing parameters: {missing}",
        "hint": "Required: " + ", ".join(required)
    }

result = await handler(**parameters)
```

---

### ❌ Anti-Pattern 3: Ignored Status Codes

**Bad:**
```python
response = await http_client.get(url)
data = response.json()  # Assumes success
```

**Good:**
```python
response = await http_client.get(url)

if response.status_code == 200:
    data = response.json()
else:
    return {
        "success": False,
        "error": f"HTTP {response.status_code}",
        "retryable": response.status_code >= 500
    }
```

---

### ❌ Anti-Pattern 4: No Graceful Fallbacks

**Bad:**
```python
# Hard failure on tool unavailability
if not tool_available:
    raise Exception("Tool not available")
```

**Good:**
```python
# Return structured error allowing client handling
if not tool_available:
    return {
        "success": False,
        "error": "Tool not available",
        "fallback": "Try alternative tool or retry later"
    }
```

---

### ❌ Anti-Pattern 5: Tight Coupling to Tool Names

**Bad:**
```python
# Hardcoded tool references throughout code
result = await self.call_dns_by_eye_tool(domain)
result2 = await self.call_other_specific_tool(param)
```

**Good:**
```python
# Generic interface with tool_id parameter
result = await self.generic_tool_call(
    tool_id="dns-by-eye",
    endpoint="analyze",
    data={"domain": domain}
)
```

---

### ❌ Anti-Pattern 6: Silent Failures

**Bad:**
```python
try:
    result = await tool_call()
except Exception:
    pass  # Silent failure
```

**Good:**
```python
try:
    result = await tool_call()
except Exception as e:
    logger.error(f"Tool call failed: {e}", exc_info=True)
    return {
        "success": False,
        "error": str(e),
        "function": "tool_call"
    }
```

---

### ❌ Anti-Pattern 7: No Timeout Management

**Bad:**
```python
# HTTP client without timeout - can hang forever
client = httpx.AsyncClient()
```

**Good:**
```python
# Always set timeouts
client = httpx.AsyncClient(timeout=30.0)

# Or per-request
response = await client.get(url, timeout=10.0)
```

---

## 🔗 Related Patterns

- [ERROR_RECOVERY.md](ERROR_RECOVERY.md) - Error handling strategies
- [BATCH_OPERATIONS.md](BATCH_OPERATIONS.md) - Batch processing patterns
- [CACHING_PATTERNS.md](CACHING_PATTERNS.md) - Caching strategies
- [STREAMING_PATTERNS.md](STREAMING_PATTERNS.md) - Streaming patterns
- Cross-reference: `agent-rules/python/ASYNC_PATTERNS.md` (from foundation worker)

---

## Related Patterns (Extended)

For AI assistant tool optimization and usage patterns, see:
- [Tool Use Patterns](../../patterns/tool-use/README.md) - AI assistant tool optimization (40-60% efficiency improvement)
- [Optimization Patterns](../../patterns/tool-use/optimization-patterns.md) - Minimize round trips, choose right tools
- [Batching Patterns](../../patterns/tool-use/batching-patterns.md) - Parallel operations, batch modifications
- [Caching Patterns](../../patterns/tool-use/caching-patterns.md) - Mental caching, context retention
- [Parallel Execution](../../patterns/tool-use/parallel-execution.md) - Concurrent operations
- [Tool Selection](../../patterns/tool-use/tool-selection.md) - Choosing appropriate tools

---

**Last Updated**: 2025-12-26
**Patterns**: 10 documented
**Source**: TheSymposium (v0.4.5+)
**Lines of Code Analyzed**: ~2,500 lines

*"Every tool call is a promise - check it's available, validate parameters, handle errors gracefully."*
