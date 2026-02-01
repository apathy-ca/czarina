# Python Project Template

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This template provides a comprehensive structure for initializing a new Python project following established standards from the agent-rules repository.

## When to Use This Template

Use this template when:
- Starting a new Python application or service
- Setting up a Python package or library
- Creating a new microservice in a Python ecosystem
- Bootstrapping a Python-based AI agent or tool

## Quick Start

1. Copy this directory structure to your project location
2. Replace `[PROJECT_NAME]` with your project name
3. Replace `[PACKAGE_NAME]` with your Python package name
4. Update `[DESCRIPTION]` with your project description
5. Configure dependencies in `requirements.txt` and `pyproject.toml`
6. Initialize git repository and create initial commit

## Project Structure

```
[PROJECT_NAME]/
├── .github/
│   └── workflows/
│       ├── ci.yml                 # CI/CD pipeline
│       └── release.yml            # Release automation
├── src/
│   └── [PACKAGE_NAME]/
│       ├── __init__.py
│       ├── core/                  # Core business logic
│       │   ├── __init__.py
│       │   └── models.py          # Data models
│       ├── services/              # Service layer
│       │   ├── __init__.py
│       │   └── example_service.py
│       ├── utils/                 # Utility functions
│       │   ├── __init__.py
│       │   ├── logging.py         # Logging configuration
│       │   └── config.py          # Configuration management
│       └── api/                   # API layer (if applicable)
│           ├── __init__.py
│           └── routes.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py                # pytest fixtures
│   ├── unit/                      # Unit tests
│   │   ├── __init__.py
│   │   └── test_models.py
│   ├── integration/               # Integration tests
│   │   ├── __init__.py
│   │   └── test_services.py
│   └── fixtures/                  # Test data and fixtures
│       └── sample_data.json
├── docs/
│   ├── README.md                  # Project documentation
│   ├── ROADMAP.md                 # Development roadmap
│   ├── API.md                     # API documentation
│   └── ARCHITECTURE.md            # Architecture documentation
├── .env.example                   # Environment variables template
├── .gitignore                     # Git ignore patterns
├── pyproject.toml                 # Project metadata and build config
├── requirements.txt               # Production dependencies
├── requirements-dev.txt           # Development dependencies
├── pytest.ini                     # pytest configuration
├── .coveragerc                    # Coverage configuration
├── VERSION                        # Single source of truth for version
├── README.md                      # Project overview
└── LICENSE                        # License file
```

## File Templates

### pyproject.toml

```toml
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "[PACKAGE_NAME]"
version = "0.1.0"
description = "[DESCRIPTION]"
readme = "README.md"
requires-python = ">=3.11"
license = {text = "MIT"}
authors = [
    {name = "[AUTHOR_NAME]", email = "[AUTHOR_EMAIL]"}
]
classifiers = [
    "Development Status :: 3 - Alpha",
    "Intended Audience :: Developers",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
]

dependencies = [
    "pydantic>=2.0.0",
    "pydantic-settings>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-asyncio>=0.21.0",
    "pytest-cov>=4.0.0",
    "black>=23.0.0",
    "ruff>=0.1.0",
    "mypy>=1.0.0",
]

[tool.setuptools.packages.find]
where = ["src"]

[tool.black]
line-length = 100
target-version = ["py311"]

[tool.ruff]
line-length = 100
target-version = "py311"
select = ["E", "F", "I", "N", "W", "B", "UP"]

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
```

### pytest.ini

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
asyncio_mode = auto
addopts =
    -v
    --strict-markers
    --cov=src/[PACKAGE_NAME]
    --cov-report=term-missing
    --cov-report=html
    --cov-report=xml
    --cov-fail-under=80
markers =
    unit: Unit tests
    integration: Integration tests
    slow: Slow running tests
```

### .coveragerc

```ini
[run]
source = src/[PACKAGE_NAME]
omit =
    */tests/*
    */conftest.py
    */__init__.py

[report]
precision = 2
exclude_lines =
    pragma: no cover
    def __repr__
    raise AssertionError
    raise NotImplementedError
    if __name__ == .__main__.:
    if TYPE_CHECKING:
    @abstractmethod
```

### .env.example

```bash
# Application Configuration
APP_NAME=[PROJECT_NAME]
APP_ENV=development
LOG_LEVEL=INFO

# Database Configuration (if applicable)
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/[PROJECT_NAME]

# Redis Configuration (if applicable)
REDIS_URL=redis://localhost:6379/0

# API Configuration (if applicable)
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=4

# Security
SECRET_KEY=your-secret-key-here-change-in-production
```

### .gitignore

```gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environment
venv/
ENV/
env/

# Testing
.pytest_cache/
.coverage
htmlcov/
*.cover
.hypothesis/

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# Environment Variables
.env
.env.local

# OS
.DS_Store
Thumbs.db

# Project Specific
logs/
*.log
```

### VERSION

```
0.1.0
```

### requirements.txt

```
pydantic>=2.0.0
pydantic-settings>=2.0.0
```

### requirements-dev.txt

```
-r requirements.txt
pytest>=7.0.0
pytest-asyncio>=0.21.0
pytest-cov>=4.0.0
black>=23.0.0
ruff>=0.1.0
mypy>=1.0.0
```

### src/[PACKAGE_NAME]/__init__.py

```python
"""[PACKAGE_NAME] - [DESCRIPTION]"""

from pathlib import Path

# Read version from VERSION file
_version_file = Path(__file__).parent.parent.parent / "VERSION"
__version__ = _version_file.read_text().strip()

__all__ = ["__version__"]
```

### src/[PACKAGE_NAME]/utils/config.py

```python
"""Configuration management using Pydantic Settings."""

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Application
    app_name: str = Field(default="[PROJECT_NAME]", description="Application name")
    app_env: str = Field(default="development", description="Environment (development, production)")
    log_level: str = Field(default="INFO", description="Logging level")

    # Add your configuration fields here
    # database_url: str = Field(..., description="Database connection URL")
    # redis_url: str = Field(..., description="Redis connection URL")


# Singleton instance
settings = Settings()
```

### src/[PACKAGE_NAME]/utils/logging.py

```python
"""Logging configuration."""

import logging
import sys
from typing import Any

from .config import settings


def setup_logging() -> None:
    """Configure application logging."""
    logging.basicConfig(
        level=getattr(logging, settings.log_level.upper()),
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        handlers=[logging.StreamHandler(sys.stdout)],
    )


def get_logger(name: str) -> logging.Logger:
    """Get a logger instance.

    Args:
        name: Logger name (typically __name__)

    Returns:
        Configured logger instance
    """
    return logging.getLogger(name)
```

### tests/conftest.py

```python
"""Shared pytest fixtures."""

import pytest


@pytest.fixture
def sample_data() -> dict[str, Any]:
    """Provide sample test data.

    Returns:
        Dictionary with sample test data
    """
    return {
        "example": "data",
    }
```

### tests/unit/test_models.py

```python
"""Unit tests for models."""

import pytest


class TestExampleModel:
    """Test suite for ExampleModel."""

    def test_example(self) -> None:
        """Test example functionality."""
        # Arrange
        expected = True

        # Act
        result = True

        # Assert
        assert result == expected
```

## GitHub Actions CI/CD

### .github/workflows/ci.yml

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.11", "3.12"]

    steps:
    - uses: actions/checkout@v4

    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v5
      with:
        python-version: ${{ matrix.python-version }}

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements-dev.txt

    - name: Lint with ruff
      run: ruff check src/ tests/

    - name: Format check with black
      run: black --check src/ tests/

    - name: Type check with mypy
      run: mypy src/

    - name: Test with pytest
      run: pytest

    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
```

## Next Steps After Initialization

1. **Configure Version Control**
   ```bash
   git init
   git add .
   git commit -m "Initial commit: Project structure"
   ```

2. **Create Virtual Environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements-dev.txt
   ```

3. **Configure Pre-commit Hooks** (optional but recommended)
   ```bash
   pip install pre-commit
   # Create .pre-commit-config.yaml
   pre-commit install
   ```

4. **Update Documentation**
   - Fill in README.md with project-specific information
   - Create ROADMAP.md with development phases
   - Document architecture in docs/ARCHITECTURE.md

5. **Set Up CI/CD**
   - Push to GitHub
   - Configure repository settings
   - Set up branch protection rules

## Related Documents

- [Python Coding Standards](../core-rules/python-standards/CODING_STANDARDS.md)
- [Testing Patterns](../core-rules/python-standards/TESTING_PATTERNS.md)
- [Documentation Workflow](../core-rules/workflows/DOCUMENTATION_WORKFLOW.md)
- [Git Workflow](../core-rules/workflows/GIT_WORKFLOW.md)

## References

This template synthesizes patterns from:
- Foundation Worker: Python standards, project organization
- Testing Worker: Test structure, coverage configuration
- Workflows Worker: Documentation patterns, version management
- Security Worker: Configuration management, environment variables
