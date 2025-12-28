#!/usr/bin/env python3
"""
Czarina Memory System - Persistent AI Learning

Implements a 3-tier memory architecture:
1. Architectural Core - Essential project context (always loaded)
2. Project Knowledge - Searchable session history (semantic search)
3. Session Context - Ephemeral working state (discarded after extraction)

Design: .czarina/hopper/enhancement-memory-architecture.md
"""

import json
import os
import re
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional, Tuple
import hashlib


class MemorySystem:
    """
    Manages the Czarina memory system with vector embeddings for semantic search.

    File Structure:
    - .czarina/memories.md - Human-readable, git-tracked memory file
    - .czarina/memories.index - Vector embeddings (regenerable cache)
    """

    def __init__(self, czarina_dir: Path, embedding_provider: str = "openai"):
        """
        Initialize the memory system.

        Args:
            czarina_dir: Path to .czarina directory
            embedding_provider: "openai" or "local" (sentence-transformers)
        """
        self.czarina_dir = Path(czarina_dir)
        self.memories_file = self.czarina_dir / "memories.md"
        self.index_file = self.czarina_dir / "memories.index"
        self.embedding_provider = embedding_provider

        # Cache for embeddings
        self._embeddings_cache = None
        self._file_hash = None

    def _get_file_hash(self) -> str:
        """Calculate MD5 hash of memories.md to detect changes"""
        if not self.memories_file.exists():
            return ""
        with open(self.memories_file, 'rb') as f:
            return hashlib.md5(f.read()).hexdigest()

    def _needs_reindex(self) -> bool:
        """Check if the index needs to be regenerated"""
        if not self.index_file.exists():
            return True

        current_hash = self._get_file_hash()
        if not current_hash:
            return False

        try:
            with open(self.index_file, 'r') as f:
                index_data = json.load(f)
                stored_hash = index_data.get('metadata', {}).get('file_hash', '')
                return stored_hash != current_hash
        except (json.JSONDecodeError, FileNotFoundError):
            return True

    def initialize_memories_file(self, project_name: str):
        """
        Create initial memories.md file with template structure.

        Args:
            project_name: Name of the project
        """
        if self.memories_file.exists():
            print(f"⚠️  memories.md already exists at {self.memories_file}")
            return

        template = f"""# Project Memory: {project_name}

Last Updated: {datetime.now().strftime('%Y-%m-%d')}

---

## Architectural Core

**Essential project context - keep tight (target: 2-4KB)**

### Component Dependencies
<!-- Key components and their relationships -->

### Known Couplings
<!-- Implicit dependencies and gotchas -->

### Critical Constraints
<!-- Invariants that must not be violated -->

### Technology Stack
<!-- Key technologies and patterns -->

---

## Project Knowledge

**Searchable session history - what we learned**

<!-- Sessions are added here automatically via `czarina memory extract` -->
<!-- Each session should follow this structure:

### Session: YYYY-MM-DD - [Description]

**What We Did:**
-

**What Broke:**
-

**Root Cause:**
-

**Resolution:**
-

**Learnings:**
-

-->

---

## Patterns and Decisions

**Architectural decisions and their rationale**

<!-- Example:

### [Pattern Name]

**Context:** Why this came up

**Decision:** What we chose

**Rationale:** Why we chose it

**Revisit if:** Conditions that would change this decision

-->

---

## Notes

- This file is the **source of truth** for project memory
- The .index file is a regenerable cache (do not edit manually)
- Edit this file directly to add, update, or remove memories
- Run `czarina memory rebuild` after manual edits to regenerate the index
"""

        with open(self.memories_file, 'w') as f:
            f.write(template)

        print(f"✅ Created: {self.memories_file}")
        print(f"💡 Edit this file to add architectural context and learnings")

    def _parse_memories(self) -> Dict[str, List[Dict[str, any]]]:
        """
        Parse memories.md into structured chunks.

        Returns:
            Dictionary with 'architectural_core' and 'knowledge_chunks'
        """
        if not self.memories_file.exists():
            return {
                'architectural_core': None,
                'knowledge_chunks': []
            }

        with open(self.memories_file, 'r') as f:
            content = f.read()

        # Split into major sections
        sections = re.split(r'\n---\n', content)

        result = {
            'architectural_core': None,
            'knowledge_chunks': []
        }

        for section in sections:
            # Detect Architectural Core section (always loaded)
            if '## Architectural Core' in section:
                result['architectural_core'] = {
                    'text': section.strip(),
                    'type': 'core'
                }

            # Detect Project Knowledge section (searchable)
            elif '## Project Knowledge' in section:
                # Parse individual session entries
                # Sessions start with ### Session:
                session_pattern = r'### Session: (.+?)(?=\n###|\Z)'
                sessions = re.findall(session_pattern, section, re.DOTALL)

                for i, session_text in enumerate(sessions):
                    # Extract session title from first line
                    lines = session_text.strip().split('\n')
                    title = lines[0] if lines else f"Session {i+1}"

                    result['knowledge_chunks'].append({
                        'id': f"session-{i+1}",
                        'title': title,
                        'text': session_text.strip(),
                        'type': 'session'
                    })

            # Detect Patterns and Decisions section (searchable)
            elif '## Patterns and Decisions' in section:
                # Parse individual pattern entries
                pattern_pattern = r'### (.+?)(?=\n###|\Z)'
                patterns = re.findall(pattern_pattern, section, re.DOTALL)

                for i, pattern_text in enumerate(patterns):
                    lines = pattern_text.strip().split('\n')
                    title = lines[0] if lines else f"Pattern {i+1}"

                    result['knowledge_chunks'].append({
                        'id': f"pattern-{i+1}",
                        'title': title,
                        'text': pattern_text.strip(),
                        'type': 'pattern'
                    })

        return result

    def _embed_text(self, text: str) -> List[float]:
        """
        Generate embedding vector for text.

        Args:
            text: Text to embed

        Returns:
            Embedding vector
        """
        if self.embedding_provider == "openai":
            return self._embed_openai(text)
        elif self.embedding_provider == "local":
            return self._embed_local(text)
        else:
            raise ValueError(f"Unknown embedding provider: {self.embedding_provider}")

    def _embed_openai(self, text: str) -> List[float]:
        """Generate embedding using OpenAI API"""
        try:
            import openai

            # Check for API key
            api_key = os.environ.get('OPENAI_API_KEY')
            if not api_key:
                raise ValueError("OPENAI_API_KEY environment variable not set")

            client = openai.OpenAI(api_key=api_key)
            response = client.embeddings.create(
                model="text-embedding-3-small",
                input=text
            )
            return response.data[0].embedding
        except ImportError:
            raise ImportError("OpenAI package not installed. Run: pip install openai")

    def _embed_local(self, text: str) -> List[float]:
        """Generate embedding using local sentence-transformers model"""
        try:
            from sentence_transformers import SentenceTransformer

            # Initialize model (cached after first load)
            if not hasattr(self, '_local_model'):
                print("Loading local embedding model (first time only)...")
                self._local_model = SentenceTransformer('all-MiniLM-L6-v2')

            embedding = self._local_model.encode(text)
            return embedding.tolist()
        except ImportError:
            raise ImportError("sentence-transformers not installed. Run: pip install sentence-transformers")

    def build_index(self, verbose: bool = True) -> Dict:
        """
        Build vector index from memories.md.

        Args:
            verbose: Print progress messages

        Returns:
            Index metadata
        """
        if verbose:
            print(f"🔨 Building memory index from {self.memories_file}")

        # Parse memories
        memories = self._parse_memories()

        chunks = []

        # Add architectural core (embedded but always loaded anyway)
        if memories['architectural_core']:
            core = memories['architectural_core']
            if verbose:
                print(f"  • Embedding architectural core...")
            chunks.append({
                'id': 'architectural-core',
                'title': 'Architectural Core',
                'text': core['text'],
                'type': core['type'],
                'embedding': self._embed_text(core['text'])
            })

        # Add knowledge chunks
        for i, chunk in enumerate(memories['knowledge_chunks']):
            if verbose:
                print(f"  • Embedding {chunk['type']}: {chunk['title'][:50]}...")
            chunks.append({
                'id': chunk['id'],
                'title': chunk['title'],
                'text': chunk['text'],
                'type': chunk['type'],
                'embedding': self._embed_text(chunk['text'])
            })

        # Build index structure
        index_data = {
            'chunks': chunks,
            'metadata': {
                'embedding_model': self.embedding_provider,
                'chunk_count': len(chunks),
                'last_indexed': datetime.now().isoformat(),
                'file_hash': self._get_file_hash()
            }
        }

        # Save index
        with open(self.index_file, 'w') as f:
            json.dump(index_data, f, indent=2)

        if verbose:
            print(f"✅ Index built: {len(chunks)} chunks")
            print(f"   Saved to: {self.index_file}")

        # Update cache
        self._embeddings_cache = index_data
        self._file_hash = index_data['metadata']['file_hash']

        return index_data['metadata']

    def _load_index(self) -> Dict:
        """Load index from file or build if needed"""
        # Check cache first
        if self._embeddings_cache and self._file_hash == self._get_file_hash():
            return self._embeddings_cache

        # Check if reindex needed
        if self._needs_reindex():
            return self.build_index(verbose=False)

        # Load existing index
        with open(self.index_file, 'r') as f:
            index_data = json.load(f)

        self._embeddings_cache = index_data
        self._file_hash = index_data['metadata']['file_hash']

        return index_data

    def _cosine_similarity(self, vec1: List[float], vec2: List[float]) -> float:
        """Calculate cosine similarity between two vectors"""
        import math

        dot_product = sum(a * b for a, b in zip(vec1, vec2))
        magnitude1 = math.sqrt(sum(a * a for a in vec1))
        magnitude2 = math.sqrt(sum(b * b for b in vec2))

        if magnitude1 == 0 or magnitude2 == 0:
            return 0.0

        return dot_product / (magnitude1 * magnitude2)

    def query(self, query_text: str, top_k: int = 5,
              similarity_threshold: float = 0.7,
              include_core: bool = True) -> List[Dict]:
        """
        Search memories for relevant context.

        Args:
            query_text: Query string (e.g., current task description)
            top_k: Number of results to return
            similarity_threshold: Minimum similarity score (0.0 to 1.0)
            include_core: Always include architectural core in results

        Returns:
            List of relevant memory chunks with similarity scores
        """
        # Load index
        index_data = self._load_index()

        # Embed query
        query_embedding = self._embed_text(query_text)

        # Calculate similarities
        results = []
        core_chunk = None

        for chunk in index_data['chunks']:
            similarity = self._cosine_similarity(query_embedding, chunk['embedding'])

            result = {
                'id': chunk['id'],
                'title': chunk['title'],
                'text': chunk['text'],
                'type': chunk['type'],
                'similarity': similarity
            }

            if chunk['type'] == 'core':
                core_chunk = result
            elif similarity >= similarity_threshold:
                results.append(result)

        # Sort by similarity
        results.sort(key=lambda x: x['similarity'], reverse=True)

        # Take top_k
        results = results[:top_k]

        # Always include architectural core if requested
        if include_core and core_chunk:
            results.insert(0, core_chunk)

        return results

    def extract_session(self, session_summary: str) -> bool:
        """
        Add a new session entry to memories.md.

        Args:
            session_summary: Markdown-formatted session summary

        Returns:
            Success status
        """
        if not self.memories_file.exists():
            print("❌ memories.md not found. Run 'czarina memory init' first.")
            return False

        # Read current content
        with open(self.memories_file, 'r') as f:
            content = f.read()

        # Find Project Knowledge section
        knowledge_marker = "## Project Knowledge"
        if knowledge_marker not in content:
            print("❌ Project Knowledge section not found in memories.md")
            return False

        # Insert new session after the Project Knowledge header
        # Find the position after the header and any existing intro text
        parts = content.split(knowledge_marker)
        before = parts[0] + knowledge_marker
        after = parts[1]

        # Find where to insert (after header comments, before first session or next section)
        insert_pattern = r'\n(### Session:|---)'
        match = re.search(insert_pattern, after)

        if match:
            # Insert before first session or next section
            insert_pos = match.start()
            after = after[:insert_pos] + f"\n\n{session_summary}\n" + after[insert_pos:]
        else:
            # No existing sessions, add after header
            after = f"\n\n{session_summary}\n" + after

        # Combine and write
        new_content = before + after

        with open(self.memories_file, 'w') as f:
            f.write(new_content)

        print(f"✅ Session added to {self.memories_file}")
        print(f"💡 Run 'czarina memory rebuild' to update the search index")

        return True

    def get_architectural_core(self) -> Optional[str]:
        """
        Get the architectural core content (always-loaded context).

        Returns:
            Architectural core text or None if not found
        """
        memories = self._parse_memories()
        if memories['architectural_core']:
            return memories['architectural_core']['text']
        return None

    def format_context(self, query_results: List[Dict]) -> str:
        """
        Format query results into context for agent prompts.

        Args:
            query_results: Results from query()

        Returns:
            Formatted markdown context
        """
        if not query_results:
            return "No relevant memories found."

        sections = []

        for result in query_results:
            sections.append(f"### {result['title']}")
            if result['type'] != 'core':
                sections.append(f"*Relevance: {result['similarity']:.2f}*")
            sections.append("")
            sections.append(result['text'])
            sections.append("")

        return "\n".join(sections)


def main():
    """CLI interface for memory system (for testing)"""
    import sys

    if len(sys.argv) < 2:
        print("Usage: python memory.py <command> [args]")
        print("Commands:")
        print("  init <project-name>  - Initialize memories.md")
        print("  build                - Build vector index")
        print("  query <text>         - Search memories")
        sys.exit(1)

    command = sys.argv[1]

    # Find czarina directory
    from pathlib import Path
    current = Path.cwd()
    while current != current.parent:
        czarina_dir = current / ".czarina"
        if czarina_dir.exists():
            break
        current = current.parent
    else:
        print("❌ No .czarina directory found")
        sys.exit(1)

    memory = MemorySystem(czarina_dir, embedding_provider="local")

    if command == "init":
        project_name = sys.argv[2] if len(sys.argv) > 2 else "My Project"
        memory.initialize_memories_file(project_name)

    elif command == "build":
        memory.build_index()

    elif command == "query":
        query_text = " ".join(sys.argv[2:])
        results = memory.query(query_text)
        print("\n" + "="*60)
        print(memory.format_context(results))
        print("="*60)

    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
