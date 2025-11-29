#!/usr/bin/env python3
"""
Czarina Agent Profile Loader

Loads and validates agent profiles for multi-agent support.
Provides utilities for listing, loading, and validating agent profiles.

Usage:
    python3 profile-loader.py list                    # List all available profiles
    python3 profile-loader.py load <agent-id>         # Load a specific profile
    python3 profile-loader.py validate <agent-id>     # Validate a profile
    python3 profile-loader.py validate-all            # Validate all profiles
"""

import json
import sys
import os
from pathlib import Path
from typing import Dict, List, Optional, Any
import jsonschema
from jsonschema import validate, ValidationError


class AgentProfileLoader:
    """Loads and manages agent profiles for Czarina orchestration."""

    def __init__(self, profiles_dir: Optional[Path] = None):
        """
        Initialize the profile loader.

        Args:
            profiles_dir: Path to profiles directory. If None, uses default location.
        """
        if profiles_dir is None:
            # Default to agents/profiles relative to this script
            script_dir = Path(__file__).parent
            profiles_dir = script_dir / "profiles"

        self.profiles_dir = Path(profiles_dir)
        self.schema_path = self.profiles_dir / "schema.json"
        self._schema = None

    @property
    def schema(self) -> Dict[str, Any]:
        """Load and cache the JSON schema."""
        if self._schema is None:
            if not self.schema_path.exists():
                raise FileNotFoundError(f"Schema not found at {self.schema_path}")

            with open(self.schema_path, 'r') as f:
                self._schema = json.load(f)

        return self._schema

    def list_profiles(self) -> List[str]:
        """
        List all available agent profile IDs.

        Returns:
            List of agent IDs (profile filenames without .json extension)
        """
        if not self.profiles_dir.exists():
            return []

        profiles = []
        for file_path in self.profiles_dir.glob("*.json"):
            # Skip schema.json
            if file_path.name == "schema.json":
                continue

            # Get agent ID from filename
            agent_id = file_path.stem
            profiles.append(agent_id)

        return sorted(profiles)

    def load_profile(self, agent_id: str) -> Dict[str, Any]:
        """
        Load an agent profile by ID.

        Args:
            agent_id: The agent identifier (e.g., 'claude-code', 'cursor')

        Returns:
            Dictionary containing the agent profile data

        Raises:
            FileNotFoundError: If profile doesn't exist
            json.JSONDecodeError: If profile is invalid JSON
        """
        profile_path = self.profiles_dir / f"{agent_id}.json"

        if not profile_path.exists():
            raise FileNotFoundError(
                f"Profile for agent '{agent_id}' not found at {profile_path}\n"
                f"Available agents: {', '.join(self.list_profiles())}"
            )

        with open(profile_path, 'r') as f:
            profile = json.load(f)

        return profile

    def validate_profile(self, profile: Dict[str, Any], agent_id: Optional[str] = None) -> bool:
        """
        Validate a profile against the schema.

        Args:
            profile: The profile data to validate
            agent_id: Optional agent ID for error messages

        Returns:
            True if valid

        Raises:
            ValidationError: If profile is invalid
        """
        try:
            validate(instance=profile, schema=self.schema)
            return True
        except ValidationError as e:
            agent_str = f" for agent '{agent_id}'" if agent_id else ""
            raise ValidationError(
                f"Profile{agent_str} validation failed: {e.message}\n"
                f"Path: {' -> '.join(str(p) for p in e.path)}"
            )

    def load_and_validate(self, agent_id: str) -> Dict[str, Any]:
        """
        Load and validate an agent profile.

        Args:
            agent_id: The agent identifier

        Returns:
            Validated profile dictionary

        Raises:
            FileNotFoundError: If profile doesn't exist
            ValidationError: If profile is invalid
        """
        profile = self.load_profile(agent_id)
        self.validate_profile(profile, agent_id)
        return profile

    def get_profile_summary(self, agent_id: str) -> str:
        """
        Get a human-readable summary of a profile.

        Args:
            agent_id: The agent identifier

        Returns:
            Formatted summary string
        """
        profile = self.load_profile(agent_id)

        summary = f"""
Agent Profile: {profile['name']}
ID: {profile['id']}
Type: {profile['type']}
Vendor: {profile.get('vendor', 'N/A')}
Website: {profile.get('website', 'N/A')}

Discovery:
  Pattern: {profile['discovery']['pattern']}
  Instruction: {profile['discovery']['instruction']}

Capabilities:
  File Reading: {profile['capabilities']['file_reading']}
  File Writing: {profile['capabilities'].get('file_writing', 'N/A')}
  Git Support: {profile['capabilities']['git_support']}
  PR Creation: {profile['capabilities']['pr_creation']}
  Terminal Access: {profile['capabilities'].get('terminal_access', 'N/A')}
  Multi-File Edit: {profile['capabilities'].get('multi_file_edit', 'N/A')}
  Search: {profile['capabilities'].get('search', 'N/A')}

Documentation:
  {profile['documentation'].get('getting_started', 'No getting started guide available.')}
"""

        if 'tips' in profile['documentation']:
            summary += "\nTips:\n"
            for tip in profile['documentation']['tips']:
                summary += f"  • {tip}\n"

        return summary.strip()


def main():
    """CLI entry point for the profile loader."""
    loader = AgentProfileLoader()

    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    command = sys.argv[1]

    try:
        if command == "list":
            # List all available profiles
            profiles = loader.list_profiles()
            if not profiles:
                print("No agent profiles found.")
                sys.exit(1)

            print("Available agent profiles:")
            for agent_id in profiles:
                try:
                    profile = loader.load_profile(agent_id)
                    print(f"  • {agent_id:15} - {profile['name']} ({profile['type']})")
                except Exception as e:
                    print(f"  • {agent_id:15} - Error loading: {e}")

        elif command == "load":
            # Load a specific profile
            if len(sys.argv) < 3:
                print("Error: Missing agent ID")
                print("Usage: profile-loader.py load <agent-id>")
                sys.exit(1)

            agent_id = sys.argv[2]
            profile = loader.load_profile(agent_id)
            print(json.dumps(profile, indent=2))

        elif command == "validate":
            # Validate a specific profile
            if len(sys.argv) < 3:
                print("Error: Missing agent ID")
                print("Usage: profile-loader.py validate <agent-id>")
                sys.exit(1)

            agent_id = sys.argv[2]
            profile = loader.load_profile(agent_id)
            loader.validate_profile(profile, agent_id)
            print(f"✅ Profile '{agent_id}' is valid")

        elif command == "validate-all":
            # Validate all profiles
            profiles = loader.list_profiles()
            errors = []

            for agent_id in profiles:
                try:
                    profile = loader.load_profile(agent_id)
                    loader.validate_profile(profile, agent_id)
                    print(f"✅ {agent_id}")
                except Exception as e:
                    print(f"❌ {agent_id}: {e}")
                    errors.append((agent_id, str(e)))

            if errors:
                print(f"\n{len(errors)} profile(s) failed validation")
                sys.exit(1)
            else:
                print(f"\n✅ All {len(profiles)} profiles are valid")

        elif command == "summary":
            # Show profile summary
            if len(sys.argv) < 3:
                print("Error: Missing agent ID")
                print("Usage: profile-loader.py summary <agent-id>")
                sys.exit(1)

            agent_id = sys.argv[2]
            print(loader.get_profile_summary(agent_id))

        else:
            print(f"Error: Unknown command '{command}'")
            print(__doc__)
            sys.exit(1)

    except FileNotFoundError as e:
        print(f"Error: {e}")
        sys.exit(1)
    except ValidationError as e:
        print(f"Validation Error: {e}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"JSON Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
