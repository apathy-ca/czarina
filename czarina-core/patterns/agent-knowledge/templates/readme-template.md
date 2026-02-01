# README Template

**Source:** Agent Rules Extraction - Templates Worker
**Version:** 1.0.0
**Last Updated:** 2025-12-26

## Overview

This is a comprehensive README template following documentation best practices. Choose sections based on your project type.

## When to Use This Template

Use this template for:
- New project README files
- Updating existing README files to follow standards
- Ensuring comprehensive project documentation
- Maintaining consistency across multiple projects

## Template Structure

Choose appropriate sections for your project type:
- **All Projects:** Title, Overview, Quick Start, License
- **Libraries/Packages:** Installation, API Reference, Examples
- **Applications:** Features, Usage, Configuration, Deployment
- **Tools/CLI:** Commands, Options, Examples
- **Frameworks:** Getting Started, Concepts, Guides

---

# [PROJECT_NAME]

> [TAGLINE - One sentence describing your project]

[![CI Status](https://github.com/[ORG]/[REPO]/workflows/CI/badge.svg)](https://github.com/[ORG]/[REPO]/actions)
[![Coverage](https://codecov.io/gh/[ORG]/[REPO]/branch/main/graph/badge.svg)](https://codecov.io/gh/[ORG]/[REPO])
[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](VERSION)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## Overview

[PROJECT_NAME] is [2-3 sentence description of what the project does and why it exists].

### Key Features

- **Feature 1:** Description of key capability
- **Feature 2:** Description of key capability
- **Feature 3:** Description of key capability
- **Feature 4:** Description of key capability

### Use Cases

- Use case 1: Description
- Use case 2: Description
- Use case 3: Description

## Quick Start

### Prerequisites

- [Tool/Language] version X.X+ ([Installation Link](https://example.com))
- [Dependency] ([Installation Link](https://example.com))
- [Optional Dependency] (optional, for feature X)

### Installation

**From Package Manager:**

\`\`\`bash
# Python (PyPI)
pip install [package-name]

# Node.js (npm)
npm install [package-name]

# Alternative package manager
# ...
\`\`\`

**From Source:**

\`\`\`bash
git clone https://github.com/[ORG]/[REPO].git
cd [REPO]
# Installation commands specific to your project
\`\`\`

### Quick Example

\`\`\`[language]
# Minimal working example
# Show the simplest possible use case
# Make it copy-pasteable and runnable
\`\`\`

**Output:**
\`\`\`
Expected output from the example
\`\`\`

## Usage

### Basic Usage

\`\`\`[language]
# Common usage patterns
# Include 3-5 most common use cases
\`\`\`

### Configuration

\`\`\`[language/yaml/toml]
# Configuration file example
# Or programmatic configuration
\`\`\`

**Configuration Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `option_1` | string | `"default"` | Description of option 1 |
| `option_2` | number | `42` | Description of option 2 |
| `option_3` | boolean | `true` | Description of option 3 |

### Advanced Usage

\`\`\`[language]
# More complex examples
# Show advanced features
# Include error handling
\`\`\`

## Documentation

### Core Documentation

- **[Getting Started Guide](docs/YOUR-GETTING-STARTED.md)** - Detailed setup and first steps
- **[API Reference](docs/YOUR-API-DOCS.md)** - Complete API documentation
- **[Architecture](docs/YOUR-ARCHITECTURE.md)** - System design and architecture
- **[Examples](examples/)** - Comprehensive examples
- **[FAQ](docs/FAQ.md)** - Frequently asked questions

### Additional Resources

- **[Roadmap](docs/ROADMAP.md)** - Development roadmap and future plans
- **[Contributing](CONTRIBUTING.md)** - How to contribute
- **[Changelog](CHANGELOG.md)** - Version history and changes
- **[Migration Guide](docs/MIGRATION.md)** - Upgrading between versions

## Development

### Setup Development Environment

\`\`\`bash
# Clone repository
git clone https://github.com/[ORG]/[REPO].git
cd [REPO]

# Install dependencies
[install command]

# Set up environment
cp .env.example .env
# Edit .env with your configuration

# Initialize database/services (if applicable)
[init commands]
\`\`\`

### Running Locally

\`\`\`bash
# Development server/run command
[run command]
\`\`\`

### Running Tests

\`\`\`bash
# Run all tests
[test command]

# Run specific test suite
[specific test command]

# Run with coverage
[coverage command]
\`\`\`

### Code Quality

\`\`\`bash
# Linting
[lint command]

# Formatting
[format command]

# Type checking
[type-check command]

# All quality checks
[all-checks command]
\`\`\`

### Project Structure

\`\`\`
[REPO]/
├── src/                 # Source code
│   └── [package]/       # Main package
├── tests/               # Test files
│   ├── unit/            # Unit tests
│   └── integration/     # Integration tests
├── docs/                # Documentation
├── examples/            # Example code
└── [config files]       # Configuration
\`\`\`

## Architecture

### High-Level Overview

\`\`\`
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
┌──────▼──────┐
│  API Layer  │
└──────┬──────┘
       │
┌──────▼──────┐
│  Business   │
│   Logic     │
└──────┬──────┘
       │
┌──────▼──────┐
│ Data Layer  │
└─────────────┘
\`\`\`

### Key Components

- **Component 1:** Description and responsibility
- **Component 2:** Description and responsibility
- **Component 3:** Description and responsibility

For detailed architecture documentation, see [ARCHITECTURE.md](docs/YOUR-ARCHITECTURE.md).

## API Reference

### Core API

\`\`\`[language]
# Primary API surface
# Document key functions/classes/methods
\`\`\`

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `param1` | string | Yes | Description |
| `param2` | number | No | Description (default: X) |

### Returns

Description of return value(s).

### Errors

| Error | Condition | Resolution |
|-------|-----------|------------|
| `ErrorType1` | When X occurs | Do Y |
| `ErrorType2` | When Z occurs | Do W |

For complete API documentation, see [API.md](docs/YOUR-API-DOCS.md).

## Deployment

### Production Deployment

\`\`\`bash
# Build for production
[build command]

# Deploy
[deploy command]
\`\`\`

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `VAR_1` | Yes | Description |
| `VAR_2` | No | Description (default: X) |

### Docker

\`\`\`bash
# Build image
docker build -t [image-name] .

# Run container
docker run -p 8000:8000 [image-name]
\`\`\`

### Performance Considerations

- Consideration 1: Details and recommendations
- Consideration 2: Details and recommendations

## Security

### Security Best Practices

- Practice 1: Description
- Practice 2: Description
- Practice 3: Description

### Reporting Security Issues

Please report security vulnerabilities to [security@example.com](mailto:security@example.com).
Do not open public issues for security vulnerabilities.

## Performance

### Benchmarks

| Operation | Time | Throughput |
|-----------|------|------------|
| Operation 1 | Xms | Y ops/sec |
| Operation 2 | Xms | Y ops/sec |

### Optimization Tips

- Tip 1: Description
- Tip 2: Description

## Troubleshooting

### Common Issues

**Issue 1: [Problem description]**

\`\`\`
Error message
\`\`\`

**Solution:**
Steps to resolve...

**Issue 2: [Problem description]**

**Solution:**
Steps to resolve...

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### Quick Contribution Guide

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Write/update tests
5. Update documentation
6. Commit: `git commit -m "feat: your feature description"`
7. Push: `git push origin feature/your-feature`
8. Open a Pull Request

### Development Workflow

- Follow [Conventional Commits](https://www.conventionalcommits.org/)
- Ensure tests pass and coverage remains above 80%
- Update documentation for user-facing changes
- Follow the code style guide

## License

This project is licensed under the [LICENSE_TYPE] License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Credit 1
- Credit 2
- Credit 3

## Support

- **Documentation:** [https://docs.example.com](https://docs.example.com)
- **Issues:** [GitHub Issues](https://github.com/[ORG]/[REPO]/issues)
- **Discussions:** [GitHub Discussions](https://github.com/[ORG]/[REPO]/discussions)
- **Email:** [support@example.com](mailto:support@example.com)

## Status

**Current Version:** 0.1.0
**Status:** Alpha/Beta/Stable
**Last Updated:** YYYY-MM-DD

---

Made with ❤️ by [AUTHOR/ORGANIZATION]

## Customization Guide

### For Different Project Types

**Library/Package:**
- Focus on Installation, API Reference, Examples
- Include language-specific package manager instructions
- Provide comprehensive API documentation
- Show integration examples

**Application/Service:**
- Emphasize Features, Configuration, Deployment
- Include environment setup
- Document configuration options thoroughly
- Provide deployment guides for different platforms

**CLI Tool:**
- Focus on Commands, Options, Examples
- Include usage patterns for common tasks
- Document all command-line flags
- Provide shell completion instructions

**Framework:**
- Emphasize Getting Started, Concepts, Guides
- Include tutorials for common use cases
- Document architectural patterns
- Provide migration guides between versions

### Optional Sections

Add these sections if relevant:

- **Comparison:** How your project differs from alternatives
- **Ecosystem:** Related projects and integrations
- **Sponsors:** Project sponsors and supporters
- **Team:** Core team members and maintainers
- **Roadmap:** Inline summary (or link to docs/ROADMAP.md)
- **Screenshots:** For UI/visual projects
- **Live Demo:** Link to hosted demo instance

## Related Templates

- [API Documentation Template](./api-documentation-template.md)
- [Architecture Documentation Template](./architecture-documentation-template.md)
- [Repository Structure Template](./repository-structure-template.md)

## References

This template synthesizes patterns from:
- Workflows Worker: Documentation workflow, version management
- Foundation Worker: Project structure, organization
- Testing Worker: Test documentation, coverage reporting
- Security Worker: Security documentation, vulnerability reporting
