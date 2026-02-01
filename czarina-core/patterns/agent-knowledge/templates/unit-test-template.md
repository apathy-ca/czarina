# Unit Test Template

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This template provides a comprehensive structure for writing unit tests following the AAA (Arrange-Act-Assert) pattern and best practices from the testing worker.

## When to Use This Template

Use this template for:
- Testing individual functions or methods in isolation
- Testing class behavior without external dependencies
- Fast, deterministic tests (< 100ms per test)
- Tests that use mocks for external dependencies

## Quick Start

Copy the appropriate template below and customize for your specific test needs.

---

## Python Unit Test Template (pytest)

### Basic Function Test

\`\`\`python
"""Unit tests for [module_name].[function/class_name]."""

import pytest
from unittest.mock import Mock, patch, MagicMock

from src.[package_name].[module_name] import [FunctionOrClass]


class Test[FunctionOrClassName]:
    """Test suite for [FunctionOrClassName]."""

    def test_[functionality]_[expected_behavior](self) -> None:
        """Test that [functionality] [expected behavior].

        This test verifies that when [condition], the function [expected outcome].
        """
        # Arrange
        input_value = "test_input"
        expected_result = "expected_output"

        # Act
        result = [FunctionOrClass](input_value)

        # Assert
        assert result == expected_result

    def test_[functionality]_raises_error_when_[condition](self) -> None:
        """Test that [functionality] raises [ErrorType] when [condition]."""
        # Arrange
        invalid_input = None

        # Act & Assert
        with pytest.raises([ErrorType]) as exc_info:
            [FunctionOrClass](invalid_input)

        assert str(exc_info.value) == "Expected error message"
\`\`\`

### Class with Dependencies Test

\`\`\`python
"""Unit tests for [ClassName]."""

import pytest
from unittest.mock import Mock, AsyncMock, patch

from src.[package_name].[module_name] import [ClassName]


class Test[ClassName]:
    """Test suite for [ClassName]."""

    @pytest.fixture
    def mock_dependency(self) -> Mock:
        """Provide mock dependency."""
        mock = Mock()
        mock.method_name.return_value = "mocked_result"
        return mock

    @pytest.fixture
    def instance(self, mock_dependency: Mock) -> [ClassName]:
        """Provide [ClassName] instance with mocked dependencies."""
        return [ClassName](dependency=mock_dependency)

    def test_method_[expected_behavior](
        self, instance: [ClassName], mock_dependency: Mock
    ) -> None:
        """Test that method [expected behavior]."""
        # Arrange
        input_data = {"key": "value"}
        expected_output = "result"

        # Act
        result = instance.method_name(input_data)

        # Assert
        assert result == expected_output
        mock_dependency.method_name.assert_called_once_with(input_data)

    def test_method_handles_dependency_failure(
        self, instance: [ClassName], mock_dependency: Mock
    ) -> None:
        """Test that method handles dependency failure gracefully."""
        # Arrange
        mock_dependency.method_name.side_effect = Exception("Dependency failed")

        # Act & Assert
        with pytest.raises([ErrorType]):
            instance.method_name({"key": "value"})
\`\`\`

### Async Function/Method Test

\`\`\`python
"""Unit tests for async [module_name]."""

import pytest
from unittest.mock import AsyncMock, Mock

from src.[package_name].[module_name] import [AsyncClass]


class Test[AsyncClass]:
    """Test suite for [AsyncClass]."""

    @pytest.fixture
    def mock_async_dependency(self) -> AsyncMock:
        """Provide async mock dependency."""
        mock = AsyncMock()
        mock.async_method.return_value = "async_result"
        return mock

    @pytest.fixture
    def instance(self, mock_async_dependency: AsyncMock) -> [AsyncClass]:
        """Provide instance with mocked async dependencies."""
        return [AsyncClass](dependency=mock_async_dependency)

    async def test_async_method_[expected_behavior](
        self, instance: [AsyncClass], mock_async_dependency: AsyncMock
    ) -> None:
        """Test that async_method [expected behavior]."""
        # Arrange
        input_data = "test_input"
        expected_result = "expected_output"
        mock_async_dependency.async_method.return_value = expected_result

        # Act
        result = await instance.async_method(input_data)

        # Assert
        assert result == expected_result
        mock_async_dependency.async_method.assert_called_once_with(input_data)

    async def test_async_method_retries_on_failure(
        self, instance: [AsyncClass], mock_async_dependency: AsyncMock
    ) -> None:
        """Test that async_method retries on transient failures."""
        # Arrange
        mock_async_dependency.async_method.side_effect = [
            Exception("Transient error"),
            Exception("Transient error"),
            "success",
        ]

        # Act
        result = await instance.async_method("input")

        # Assert
        assert result == "success"
        assert mock_async_dependency.async_method.call_count == 3
\`\`\`

### Parametrized Tests

\`\`\`python
"""Parametrized unit tests."""

import pytest

from src.[package_name].[module_name] import [function_name]


@pytest.mark.parametrize(
    "input_value,expected_output",
    [
        ("input1", "output1"),
        ("input2", "output2"),
        ("input3", "output3"),
        ("edge_case", "edge_output"),
    ],
    ids=["case1", "case2", "case3", "edge_case"],
)
def test_[function_name]_with_various_inputs(
    input_value: str, expected_output: str
) -> None:
    """Test [function_name] with various inputs."""
    # Act
    result = [function_name](input_value)

    # Assert
    assert result == expected_output


@pytest.mark.parametrize(
    "invalid_input,expected_error",
    [
        (None, ValueError),
        ("", ValueError),
        (-1, ValueError),
    ],
    ids=["none", "empty", "negative"],
)
def test_[function_name]_raises_error_for_invalid_inputs(
    invalid_input: Any, expected_error: type[Exception]
) -> None:
    """Test that [function_name] raises appropriate errors for invalid inputs."""
    # Act & Assert
    with pytest.raises(expected_error):
        [function_name](invalid_input)
\`\`\`

### Testing with Pydantic Models

\`\`\`python
"""Unit tests for Pydantic models."""

import pytest
from pydantic import ValidationError

from src.[package_name].models import [ModelName]


class Test[ModelName]:
    """Test suite for [ModelName] Pydantic model."""

    def test_valid_model_creation(self) -> None:
        """Test creating model with valid data."""
        # Arrange
        valid_data = {
            "field1": "value1",
            "field2": 123,
            "field3": True,
        }

        # Act
        model = [ModelName](**valid_data)

        # Assert
        assert model.field1 == "value1"
        assert model.field2 == 123
        assert model.field3 is True

    def test_model_validation_fails_for_invalid_data(self) -> None:
        """Test that model validation fails for invalid data."""
        # Arrange
        invalid_data = {
            "field1": 123,  # Should be string
            "field2": "invalid",  # Should be int
        }

        # Act & Assert
        with pytest.raises(ValidationError) as exc_info:
            [ModelName](**invalid_data)

        errors = exc_info.value.errors()
        assert len(errors) == 2
        assert errors[0]["loc"] == ("field1",)
        assert errors[1]["loc"] == ("field2",)

    def test_model_default_values(self) -> None:
        """Test model default values."""
        # Arrange
        minimal_data = {
            "field1": "value1",  # Required field only
        }

        # Act
        model = [ModelName](**minimal_data)

        # Assert
        assert model.field2 == 0  # Default value
        assert model.field3 is False  # Default value
\`\`\`

### Patching External Dependencies

\`\`\`python
"""Unit tests with patched external dependencies."""

import pytest
from unittest.mock import patch, Mock

from src.[package_name].[module_name] import [function_using_external_service]


class Test[FunctionName]:
    """Test suite for [function_name]."""

    @patch("src.[package_name].[module_name].[ExternalService]")
    def test_function_uses_external_service(
        self, mock_service: Mock
    ) -> None:
        """Test that function correctly uses external service."""
        # Arrange
        mock_service.return_value.method.return_value = "service_result"
        input_data = "test_input"

        # Act
        result = [function_using_external_service](input_data)

        # Assert
        assert result == "processed: service_result"
        mock_service.return_value.method.assert_called_once_with(input_data)

    @patch("src.[package_name].[module_name].requests.get")
    def test_function_handles_http_errors(self, mock_get: Mock) -> None:
        """Test that function handles HTTP errors gracefully."""
        # Arrange
        mock_get.side_effect = ConnectionError("Network error")

        # Act & Assert
        with pytest.raises([CustomErrorType]):
            [function_using_external_service]("input")
\`\`\`

## TypeScript/JavaScript Unit Test Template (Jest)

### Basic Function Test

\`\`\`typescript
/**
 * Unit tests for [functionName]
 */

import { [functionName] } from '../src/[moduleName]';

describe('[FunctionName]', () => {
  describe('[functionality]', () => {
    it('should [expected behavior]', () => {
      // Arrange
      const input = 'test_input';
      const expected = 'expected_output';

      // Act
      const result = [functionName](input);

      // Assert
      expect(result).toBe(expected);
    });

    it('should throw error when [condition]', () => {
      // Arrange
      const invalidInput = null;

      // Act & Assert
      expect(() => [functionName](invalidInput)).toThrow('[ErrorType]');
      expect(() => [functionName](invalidInput)).toThrow('Expected error message');
    });
  });
});
\`\`\`

### Class with Dependencies Test

\`\`\`typescript
/**
 * Unit tests for [ClassName]
 */

import { [ClassName] } from '../src/[moduleName]';
import { [DependencyType] } from '../src/types';

// Mock the dependency
jest.mock('../src/[dependencyModule]');

describe('[ClassName]', () => {
  let instance: [ClassName];
  let mockDependency: jest.Mocked<[DependencyType]>;

  beforeEach(() => {
    // Arrange - Create mocks
    mockDependency = {
      method: jest.fn().mockResolvedValue('mocked_result'),
    } as unknown as jest.Mocked<[DependencyType]>;

    instance = new [ClassName](mockDependency);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('method', () => {
    it('should [expected behavior]', async () => {
      // Arrange
      const input = { key: 'value' };
      const expected = 'result';

      // Act
      const result = await instance.method(input);

      // Assert
      expect(result).toBe(expected);
      expect(mockDependency.method).toHaveBeenCalledWith(input);
      expect(mockDependency.method).toHaveBeenCalledTimes(1);
    });

    it('should handle dependency failure', async () => {
      // Arrange
      mockDependency.method.mockRejectedValue(new Error('Dependency failed'));

      // Act & Assert
      await expect(instance.method({ key: 'value' })).rejects.toThrow(
        '[ErrorType]'
      );
    });
  });
});
\`\`\`

### Async Function Test

\`\`\`typescript
/**
 * Unit tests for async [functionName]
 */

import { [asyncFunctionName] } from '../src/[moduleName]';

describe('[AsyncFunctionName]', () => {
  it('should return expected result', async () => {
    // Arrange
    const input = 'test_input';
    const expected = 'expected_result';

    // Act
    const result = await [asyncFunctionName](input);

    // Assert
    expect(result).toBe(expected);
  });

  it('should handle errors', async () => {
    // Arrange
    const invalidInput = null;

    // Act & Assert
    await expect([asyncFunctionName](invalidInput)).rejects.toThrow();
  });
});
\`\`\`

## Best Practices

### Test Organization

✅ **Good:**
\`\`\`python
# tests/unit/test_user_service.py
class TestUserService:
    class TestCreateUser:
        def test_creates_user_with_valid_data(self): ...
        def test_raises_error_when_email_invalid(self): ...

    class TestUpdateUser:
        def test_updates_user_fields(self): ...
        def test_raises_error_when_user_not_found(self): ...
\`\`\`

❌ **Bad:**
\`\`\`python
# tests/test_everything.py
def test_user1(): ...
def test_user2(): ...
def test_order1(): ...
def test_order2(): ...
\`\`\`

### Test Naming

✅ **Good:**
\`\`\`python
def test_calculate_discount_applies_10_percent_for_premium_users(self): ...
def test_calculate_discount_raises_error_when_price_negative(self): ...
\`\`\`

❌ **Bad:**
\`\`\`python
def test1(self): ...
def test_discount(self): ...
def test_error(self): ...
\`\`\`

### AAA Pattern

✅ **Good:**
\`\`\`python
def test_add_numbers(self):
    # Arrange
    a = 5
    b = 3
    expected = 8

    # Act
    result = add(a, b)

    # Assert
    assert result == expected
\`\`\`

❌ **Bad:**
\`\`\`python
def test_add_numbers(self):
    assert add(5, 3) == 8  # All in one line, hard to debug
\`\`\`

### Mocking

✅ **Good:**
\`\`\`python
@patch('src.module.external_api')
def test_function_calls_api(mock_api):
    # Mock only what you need
    mock_api.get.return_value = {"data": "value"}
    result = function_that_uses_api()
    assert result == "processed_value"
\`\`\`

❌ **Bad:**
\`\`\`python
def test_function_calls_api():
    # Calling real external API in unit test
    result = function_that_uses_api()
    assert result is not None  # Flaky, slow, requires network
\`\`\`

## Common Patterns

### Testing Error Handling

\`\`\`python
def test_function_handles_specific_exception(self):
    """Test that function handles specific exception."""
    # Arrange
    mock_dependency = Mock()
    mock_dependency.method.side_effect = SpecificException("Error message")

    # Act & Assert
    with pytest.raises(CustomException) as exc_info:
        function_under_test(mock_dependency)

    assert "Handled: Error message" in str(exc_info.value)
\`\`\`

### Testing with Multiple Scenarios

\`\`\`python
@pytest.mark.parametrize("input,expected", [
    ({"name": "Alice", "age": 30}, "Valid"),
    ({"name": "Bob"}, "Valid"),  # age is optional
    ({}, "Invalid"),  # name is required
])
def test_validate_user_data(input, expected):
    result = validate_user_data(input)
    assert result == expected
\`\`\`

### Testing State Changes

\`\`\`python
def test_method_changes_state(self):
    """Test that method correctly changes object state."""
    # Arrange
    instance = MyClass(initial_state="inactive")
    assert instance.state == "inactive"

    # Act
    instance.activate()

    # Assert
    assert instance.state == "active"
    assert instance.activation_timestamp is not None
\`\`\`

## Related Templates

- [Integration Test Template](./integration-test-template.md)
- [Test Fixture Template](./test-fixture-template.md)
- [Python Project Template](./python-project-template.md)

## Related Documents

- [Testing Policy](../core-rules/testing/TESTING_POLICY.md)
- [Unit Testing Best Practices](../core-rules/testing/UNIT_TESTING.md)
- [Mocking Strategies](../core-rules/testing/README.md#mocking)

## References

This template synthesizes patterns from:
- Testing Worker: AAA pattern, test organization, coverage standards
- Foundation Worker: Python testing patterns, AsyncMock usage
- Patterns Worker: Error handling patterns
