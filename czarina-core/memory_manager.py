#!/usr/bin/env python3
"""
Memory Manager - Python module for Czarina memory operations
Provides structured access to memories.md with validation and parsing
"""

import os
import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Dict, Any


@dataclass
class SessionEntry:
    """Represents a single session entry in memory"""
    date: str
    description: str
    what_we_did: List[str]
    what_broke: List[str]
    root_cause: str
    resolution: str
    prevention: List[str]
    raw_content: str

    @property
    def title(self) -> str:
        """Get session title"""
        return f"Session: {self.date} - {self.description}"


@dataclass
class PatternEntry:
    """Represents a pattern or decision entry"""
    name: str
    context: str
    decision: str
    rationale: str
    revisit_if: str
    raw_content: str


class MemoryFile:
    """Handles reading and writing to memories.md"""

    def __init__(self, file_path: str = ".czarina/memories.md"):
        self.file_path = Path(file_path)
        self._content: Optional[str] = None

    def exists(self) -> bool:
        """Check if memory file exists"""
        return self.file_path.exists()

    def read(self) -> str:
        """Read the entire memory file"""
        if not self.exists():
            raise FileNotFoundError(f"Memory file not found: {self.file_path}")

        with open(self.file_path, 'r', encoding='utf-8') as f:
            self._content = f.read()
        return self._content

    def write(self, content: str) -> None:
        """Write content to memory file"""
        # Ensure parent directory exists
        self.file_path.parent.mkdir(parents=True, exist_ok=True)

        with open(self.file_path, 'w', encoding='utf-8') as f:
            f.write(content)

        self._content = content

    def read_section(self, section_name: str) -> str:
        """
        Read a specific section from the memory file

        Args:
            section_name: Name of the section (e.g., "Architectural Core")

        Returns:
            Content of the section
        """
        content = self._content or self.read()

        # Pattern to match section header to next section or end
        pattern = rf'^## {re.escape(section_name)}$(.*?)(?=^## |\Z)'
        match = re.search(pattern, content, re.MULTILINE | re.DOTALL)

        if match:
            return match.group(1).strip()

        return ""

    def read_architectural_core(self) -> str:
        """Read the Architectural Core section"""
        return self.read_section("Architectural Core")

    def read_project_knowledge(self) -> str:
        """Read the Project Knowledge section"""
        return self.read_section("Project Knowledge")

    def read_patterns_and_decisions(self) -> str:
        """Read the Patterns and Decisions section"""
        return self.read_section("Patterns and Decisions")

    def parse_sessions(self) -> List[SessionEntry]:
        """
        Parse all session entries from Project Knowledge section

        Returns:
            List of SessionEntry objects
        """
        knowledge = self.read_project_knowledge()
        sessions: List[SessionEntry] = []

        # Split by session headers
        session_pattern = r'^### Session: (\d{4}-\d{2}-\d{2}) - (.+?)$'
        parts = re.split(session_pattern, knowledge, flags=re.MULTILINE)

        # parts[0] is content before first session (comments, etc.)
        # Then alternating: date, description, content, date, description, content...
        for i in range(1, len(parts), 3):
            if i + 2 > len(parts):
                break

            date = parts[i]
            description = parts[i + 1]
            content = parts[i + 2]

            # Parse session content sections
            session = self._parse_session_content(date, description, content)
            if session:
                sessions.append(session)

        return sessions

    def _parse_session_content(self, date: str, description: str, content: str) -> Optional[SessionEntry]:
        """Parse the content of a single session entry"""
        try:
            # Extract subsections
            what_we_did = self._extract_list_section(content, "What We Did")
            what_broke = self._extract_list_section(content, "What Broke")
            root_cause = self._extract_text_section(content, "Root Cause")
            resolution = self._extract_text_section(content, "Resolution")
            prevention = self._extract_list_section(content, "Prevention")

            return SessionEntry(
                date=date,
                description=description,
                what_we_did=what_we_did,
                what_broke=what_broke,
                root_cause=root_cause,
                resolution=resolution,
                prevention=prevention,
                raw_content=content
            )
        except Exception as e:
            print(f"Warning: Failed to parse session {date}: {e}")
            return None

    def _extract_list_section(self, content: str, section_name: str) -> List[str]:
        """Extract a list section (bullet points)"""
        pattern = rf'^#### {re.escape(section_name)}$(.*?)(?=^#### |\Z)'
        match = re.search(pattern, content, re.MULTILINE | re.DOTALL)

        if not match:
            return []

        section_text = match.group(1).strip()
        # Extract bullet points
        items = re.findall(r'^- (.+)$', section_text, re.MULTILINE)
        return items

    def _extract_text_section(self, content: str, section_name: str) -> str:
        """Extract a text section"""
        pattern = rf'^#### {re.escape(section_name)}$(.*?)(?=^#### |\Z)'
        match = re.search(pattern, content, re.MULTILINE | re.DOTALL)

        if not match:
            return ""

        return match.group(1).strip()

    def append_session(self, session: SessionEntry) -> None:
        """
        Append a new session entry to the Project Knowledge section

        Args:
            session: SessionEntry to append
        """
        content = self._content or self.read()

        # Format the session entry
        session_md = self._format_session(session)

        # Find the Patterns and Decisions section
        pattern = r'^## Patterns and Decisions$'
        match = re.search(pattern, content, re.MULTILINE)

        if match:
            # Insert before Patterns and Decisions
            insert_pos = match.start()
            new_content = (
                content[:insert_pos] +
                session_md + "\n\n" +
                content[insert_pos:]
            )
        else:
            # Append to end if section not found
            new_content = content + "\n\n" + session_md

        self.write(new_content)

    def _format_session(self, session: SessionEntry) -> str:
        """Format a session entry as markdown"""
        lines = [
            f"### Session: {session.date} - {session.description}",
            "",
            "#### What We Did"
        ]

        for item in session.what_we_did:
            lines.append(f"- {item}")

        if session.what_broke:
            lines.append("")
            lines.append("#### What Broke")
            for item in session.what_broke:
                lines.append(f"- {item}")

        if session.root_cause:
            lines.append("")
            lines.append("#### Root Cause")
            lines.append(session.root_cause)

        if session.resolution:
            lines.append("")
            lines.append("#### Resolution")
            lines.append(session.resolution)

        if session.prevention:
            lines.append("")
            lines.append("#### Prevention")
            for item in session.prevention:
                lines.append(f"- {item}")

        return "\n".join(lines)

    def validate(self) -> tuple[bool, List[str]]:
        """
        Validate the memory file structure

        Returns:
            Tuple of (is_valid, error_messages)
        """
        errors = []

        if not self.exists():
            errors.append(f"Memory file not found: {self.file_path}")
            return False, errors

        content = self.read()

        # Check for required sections
        if not re.search(r'^# Project Memory:', content, re.MULTILINE):
            errors.append("Missing required header: # Project Memory:")

        required_sections = [
            "Architectural Core",
            "Project Knowledge",
            "Patterns and Decisions"
        ]

        for section in required_sections:
            if not re.search(rf'^## {re.escape(section)}$', content, re.MULTILINE):
                errors.append(f"Missing required section: ## {section}")

        return len(errors) == 0, errors

    def get_stats(self) -> Dict[str, Any]:
        """Get statistics about the memory file"""
        if not self.exists():
            return {}

        content = self.read()

        sessions = len(re.findall(r'^### Session:', content, re.MULTILINE))
        patterns = len(re.findall(r'^### \[.+\]$', content, re.MULTILINE))
        lines = content.count('\n') + 1
        size_bytes = len(content.encode('utf-8'))

        return {
            'file_path': str(self.file_path),
            'size_bytes': size_bytes,
            'size_kb': round(size_bytes / 1024, 2),
            'total_lines': lines,
            'session_count': sessions,
            'pattern_count': patterns
        }


def create_session_template(date: Optional[str] = None, description: str = "") -> SessionEntry:
    """
    Create a template session entry for manual filling

    Args:
        date: Session date (defaults to today)
        description: Brief description of the session

    Returns:
        SessionEntry template
    """
    if date is None:
        date = datetime.now().strftime("%Y-%m-%d")

    return SessionEntry(
        date=date,
        description=description or "Work Session",
        what_we_did=[],
        what_broke=[],
        root_cause="",
        resolution="",
        prevention=[],
        raw_content=""
    )


# CLI interface
def main():
    """Command-line interface for memory manager"""
    import sys
    import json

    if len(sys.argv) < 2:
        print("Usage: memory_manager.py <command> [args]")
        print("Commands: validate, stats, read-core, read-sessions")
        sys.exit(1)

    command = sys.argv[1]
    memory = MemoryFile()

    if command == "validate":
        is_valid, errors = memory.validate()
        if is_valid:
            print("✅ Memory file is valid")
            sys.exit(0)
        else:
            print("❌ Memory file validation failed:")
            for error in errors:
                print(f"  - {error}")
            sys.exit(1)

    elif command == "stats":
        stats = memory.get_stats()
        print(json.dumps(stats, indent=2))

    elif command == "read-core":
        core = memory.read_architectural_core()
        print(core)

    elif command == "read-sessions":
        sessions = memory.parse_sessions()
        print(f"Found {len(sessions)} session(s)")
        for session in sessions:
            print(f"\n{session.title}")
            print(f"  What we did: {len(session.what_we_did)} items")
            print(f"  What broke: {len(session.what_broke)} items")

    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
