#!/usr/bin/env python3
"""
Czarina Configuration Validator

Validates config.json files against the Czarina configuration schema.
Supports loading, validating, and checking backward compatibility.
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import jsonschema
from jsonschema import validate, ValidationError, Draft7Validator


class ConfigValidator:
    """Validates Czarina config.json files against the schema."""

    def __init__(self, schema_path: Optional[Path] = None):
        """
        Initialize validator with schema.

        Args:
            schema_path: Path to config-schema.json. If None, uses default location.
        """
        if schema_path is None:
            # Default to schema in same directory as this script
            schema_path = Path(__file__).parent / "config-schema.json"

        self.schema_path = schema_path
        self.schema = self._load_schema()
        self.validator = Draft7Validator(self.schema)

    def _load_schema(self) -> Dict:
        """Load the JSON schema."""
        try:
            with open(self.schema_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"Error: Schema file not found at {self.schema_path}", file=sys.stderr)
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in schema file: {e}", file=sys.stderr)
            sys.exit(1)

    def load_config(self, config_path: Path) -> Dict:
        """
        Load a config.json file.

        Args:
            config_path: Path to config.json

        Returns:
            Parsed config dictionary
        """
        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"Error: Config file not found at {config_path}", file=sys.stderr)
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in config file: {e}", file=sys.stderr)
            sys.exit(1)

    def validate_config(self, config: Dict) -> Tuple[bool, List[str]]:
        """
        Validate a config dictionary against the schema.

        Args:
            config: Config dictionary to validate

        Returns:
            Tuple of (is_valid, error_messages)
        """
        errors = []

        # Collect all validation errors
        for error in self.validator.iter_errors(config):
            # Format error message with path
            path = " -> ".join(str(p) for p in error.path) if error.path else "root"
            errors.append(f"  [{path}] {error.message}")

        return (len(errors) == 0, errors)

    def validate_file(self, config_path: Path) -> bool:
        """
        Validate a config.json file and print results.

        Args:
            config_path: Path to config.json

        Returns:
            True if valid, False otherwise
        """
        print(f"Validating: {config_path}")
        config = self.load_config(config_path)
        is_valid, errors = self.validate_config(config)

        if is_valid:
            print("✓ Valid configuration")
            return True
        else:
            print("✗ Invalid configuration:")
            for error in errors:
                print(error)
            return False

    def check_backward_compatibility(self, config: Dict) -> Tuple[bool, List[str]]:
        """
        Check if config uses only v0.6.2 fields (backward compatible).

        Args:
            config: Config dictionary

        Returns:
            Tuple of (is_backward_compatible, new_features_used)
        """
        new_features = []

        # Check for new global sections
        if "agent_rules" in config:
            new_features.append("Global agent_rules configuration")

        if "memory" in config:
            new_features.append("Global memory configuration")

        # Check for new worker fields
        for worker in config.get("workers", []):
            worker_id = worker.get("id", "unknown")

            if "role" in worker:
                new_features.append(f"Worker '{worker_id}': role field")

            if "rules" in worker:
                new_features.append(f"Worker '{worker_id}': rules configuration")

            if "memory" in worker:
                new_features.append(f"Worker '{worker_id}': memory configuration")

        return (len(new_features) == 0, new_features)

    def get_summary(self, config_path: Path) -> str:
        """
        Get a human-readable summary of a config file.

        Args:
            config_path: Path to config.json

        Returns:
            Summary string
        """
        config = self.load_config(config_path)

        lines = []
        lines.append(f"Configuration: {config_path}")
        lines.append("")

        # Project info
        project = config.get("project", {})
        lines.append(f"Project: {project.get('name', 'unknown')}")
        lines.append(f"  Version: {project.get('version', 'not specified')}")
        lines.append(f"  Repository: {project.get('repository', 'not specified')}")
        lines.append("")

        # Workers
        workers = config.get("workers", [])
        lines.append(f"Workers: {len(workers)}")
        for worker in workers:
            worker_id = worker.get("id", "unknown")
            agent = worker.get("agent", "unknown")
            role = worker.get("role", "not specified")
            has_rules = "rules" in worker
            has_memory = "memory" in worker

            lines.append(f"  - {worker_id}")
            lines.append(f"    Agent: {agent}")
            lines.append(f"    Role: {role}")
            lines.append(f"    Branch: {worker.get('branch', 'not specified')}")
            if has_rules:
                lines.append(f"    Rules: configured")
            if has_memory:
                lines.append(f"    Memory: configured")
        lines.append("")

        # New features
        has_agent_rules = "agent_rules" in config
        has_memory = "memory" in config

        if has_agent_rules or has_memory:
            lines.append("Global Configuration:")
            if has_agent_rules:
                rules = config["agent_rules"]
                lines.append(f"  Agent Rules: {rules.get('mode', 'auto')} mode")
            if has_memory:
                mem = config["memory"]
                lines.append(f"  Memory: {mem.get('embedding_provider', 'openai')}")
            lines.append("")

        # Backward compatibility
        is_compat, new_features = self.check_backward_compatibility(config)
        if is_compat:
            lines.append("Backward Compatibility: v0.6.2 compatible (no new features)")
        else:
            lines.append("Backward Compatibility: Uses v0.7.0 features")
            for feature in new_features:
                lines.append(f"  - {feature}")

        return "\n".join(lines)


def main():
    """CLI entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Validate Czarina config.json files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s validate .czarina/config.json
  %(prog)s summary .czarina/config.json
  %(prog)s check-compat .czarina/config.json
        """
    )

    parser.add_argument(
        "command",
        choices=["validate", "summary", "check-compat"],
        help="Command to execute"
    )

    parser.add_argument(
        "config_path",
        type=Path,
        help="Path to config.json file"
    )

    parser.add_argument(
        "--schema",
        type=Path,
        help="Path to config-schema.json (default: ./schema/config-schema.json)"
    )

    args = parser.parse_args()

    # Initialize validator
    validator = ConfigValidator(schema_path=args.schema)

    # Execute command
    if args.command == "validate":
        is_valid = validator.validate_file(args.config_path)
        sys.exit(0 if is_valid else 1)

    elif args.command == "summary":
        print(validator.get_summary(args.config_path))
        sys.exit(0)

    elif args.command == "check-compat":
        config = validator.load_config(args.config_path)
        is_compat, new_features = validator.check_backward_compatibility(config)

        print(f"Checking: {args.config_path}")
        if is_compat:
            print("✓ Backward compatible with v0.6.2")
            sys.exit(0)
        else:
            print("✗ Uses v0.7.0 features:")
            for feature in new_features:
                print(f"  - {feature}")
            sys.exit(1)


if __name__ == "__main__":
    main()
