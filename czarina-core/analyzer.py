#!/usr/bin/env python3
"""
Czarina Project Analyzer
AI-powered analysis of implementation plans
"""

import json
import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime


class ProjectAnalyzer:
    """Analyzes implementation plans and generates orchestration setup"""

    def __init__(self, orchestrator_dir):
        self.orchestrator_dir = Path(orchestrator_dir)
        self.template_file = self.orchestrator_dir / "czarina-core" / "templates" / "ANALYSIS_TEMPLATE.md"

    def analyze(self, plan_content, plan_file_path, interactive=False):
        """
        Analyze implementation plan using Claude API

        Args:
            plan_content: The implementation plan text
            plan_file_path: Path to the plan file
            interactive: If True, use interactive mode (works with any AI agent)

        Returns: dict with analysis results following the schema in ANALYSIS_TEMPLATE.md
        """
        # Read the analysis template
        with open(self.template_file) as f:
            template = f.read()

        # Construct the prompt for Claude
        prompt = self._build_analysis_prompt(template, plan_content)

        # Call Claude API (interactive or automated)
        if interactive:
            analysis_result = self._call_via_interactive(prompt)
        else:
            analysis_result = self._call_claude_api(prompt)

        # Parse and validate the JSON response
        try:
            analysis = json.loads(analysis_result)
            self._validate_analysis(analysis)

            # Add metadata
            analysis["analysis_metadata"] = {
                "analyzed_at": datetime.now().isoformat(),
                "analyzer_version": "1.0.0",
                "input_file": str(plan_file_path),
                "analysis_tokens_used": self._estimate_tokens(prompt + analysis_result)
            }

            return analysis

        except json.JSONDecodeError as e:
            raise ValueError(f"Failed to parse AI response as JSON: {e}")

    def _build_analysis_prompt(self, template, plan_content):
        """Build the complete prompt for Claude"""
        # Replace {PLAN_CONTENT} placeholder in template
        prompt = template.replace("{PLAN_CONTENT}", plan_content)

        # Add instruction to return only JSON
        prompt += "\n\n---\n\n"
        prompt += "IMPORTANT: Return ONLY the JSON output following the schema above. "
        prompt += "Do not include any markdown code fences, explanatory text, or other content. "
        prompt += "Start your response with { and end with }."

        return prompt

    def _call_claude_api(self, prompt):
        """
        Call Claude API to analyze the plan

        Priority:
        1. Interactive mode - save prompt and wait for agent response
        2. Try Anthropic SDK if available
        3. Use subprocess with Python + anthropic
        4. Try Claude CLI as last resort
        """
        # Try interactive mode first (best for Claude Code / any agent)
        try:
            return self._call_via_interactive(prompt)
        except KeyboardInterrupt:
            raise  # Allow user to cancel
        except Exception as e:
            print(f"⚠️  Interactive mode skipped, trying automated methods...")

        # Try using Anthropic SDK directly
        try:
            return self._call_via_sdk(prompt)
        except (ImportError, Exception) as e:
            print(f"⚠️  SDK not available ({e}), trying subprocess...")

        # Try subprocess with Python
        try:
            return self._call_via_inline_python(prompt)
        except Exception as e:
            print(f"⚠️  Subprocess failed ({e}), trying Claude CLI...")

        # Fall back to Claude CLI
        try:
            return self._call_via_cli(prompt)
        except Exception as e:
            raise RuntimeError(
                f"Failed to call Claude API: {e}\n"
                f"Options:\n"
                f"1. Run interactively (recommended for Claude Code)\n"
                f"2. Install SDK: pip install anthropic + set ANTHROPIC_API_KEY\n"
                f"3. Use claude CLI tool"
            )

    def _call_via_interactive(self, prompt):
        """
        Interactive mode - save prompt to file for AI agent to process
        This works with ANY coding assistant (Claude Code, Cursor, etc.)

        If response file already exists, load it. Otherwise save prompt and exit.
        """
        print()
        print("=" * 60)
        print("📝 INTERACTIVE ANALYSIS MODE")
        print("=" * 60)
        print()

        # Save prompt to a file in current directory
        prompt_file = Path.cwd() / ".czarina-analysis-prompt.md"
        response_file = Path.cwd() / ".czarina-analysis-response.json"

        # Check if response already exists (agent completed the work)
        if response_file.exists():
            print(f"✅ Found existing response: {response_file}")
            print()

            with open(response_file, 'r') as f:
                response = f.read().strip()

            if not response:
                raise RuntimeError(f"Response file is empty: {response_file}")

            # Clean up markdown code fences if present
            if response.startswith("```"):
                lines = response.split('\n')
                if lines[0].startswith("```"):
                    lines = lines[1:]
                if lines and lines[-1].strip() == "```":
                    lines = lines[:-1]
                response = '\n'.join(lines).strip()

            print(f"✅ Response loaded successfully")
            print()

            # Clean up the temp files
            try:
                prompt_file.unlink()
                response_file.unlink()
            except:
                pass

            return response

        # Response doesn't exist yet - save prompt and exit with instructions
        with open(prompt_file, 'w') as f:
            f.write(prompt)

        print(f"✅ Analysis prompt saved to: {prompt_file}")
        print()
        print("=" * 60)
        print("📋 NEXT STEPS FOR AI AGENT")
        print("=" * 60)
        print()
        print("Please ask your AI agent (Claude Code, Cursor, etc.) to:")
        print()
        print(f"  1. Read and analyze: {prompt_file}")
        print(f"  2. Generate JSON response following the schema")
        print(f"  3. Save response to: {response_file}")
        print()
        print("Then run this command again:")
        print(f"  czarina analyze [plan-file] --interactive --init")
        print()
        print("The tool will detect the response file and continue automatically.")
        print()

        # Exit cleanly - agent needs to do the work
        sys.exit(0)

    def _call_via_inline_python(self, prompt):
        """
        Call Claude by executing Python code that imports anthropic
        This works when run from Claude Code or any environment with anthropic installed
        """
        import tempfile
        import subprocess

        print("🤖 Analyzing with Claude API (via subprocess)...")

        # Create a Python script that makes the API call
        script = f"""
import os
import sys

try:
    import anthropic
except ImportError:
    print("anthropic not installed", file=sys.stderr)
    sys.exit(1)

# Check for API key in multiple places
api_key = (
    os.environ.get("ANTHROPIC_API_KEY") or
    os.environ.get("CLAUDE_API_KEY") or
    os.environ.get("API_KEY")
)

if not api_key:
    # Try reading from config files
    import pathlib
    config_paths = [
        pathlib.Path.home() / ".anthropic" / "api_key",
        pathlib.Path.home() / ".config" / "anthropic" / "api_key",
    ]
    for path in config_paths:
        if path.exists():
            api_key = path.read_text().strip()
            break

if not api_key:
    print("No API key found", file=sys.stderr)
    sys.exit(1)

client = anthropic.Anthropic(api_key=api_key)

prompt = '''{{PROMPT}}'''

try:
    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=16000,
        temperature=0,
        messages=[{{"role": "user", "content": prompt}}]
    )

    response_text = message.content[0].text

    # Clean up markdown code fences if present
    if response_text.strip().startswith("```"):
        lines = response_text.strip().split('\\n')
        if lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        response_text = '\\n'.join(lines)

    print(response_text.strip())

except Exception as e:
    print(f"API call failed: {{e}}", file=sys.stderr)
    sys.exit(1)
"""
        # Replace the prompt placeholder (escape it properly)
        script = script.replace("{{PROMPT}}", prompt.replace("'", "\\'").replace('"', '\\"'))

        # Write script to temp file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
            f.write(script)
            script_path = f.name

        try:
            # Run the script with Python
            result = subprocess.run(
                ["python", script_path],
                capture_output=True,
                text=True,
                timeout=180
            )

            if result.returncode != 0:
                raise RuntimeError(f"Script failed: {result.stderr}")

            return result.stdout.strip()

        finally:
            os.unlink(script_path)

    def _call_via_sdk(self, prompt):
        """Call Claude via Anthropic Python SDK"""
        import anthropic

        # Check multiple sources for API key
        api_key = (
            os.environ.get("ANTHROPIC_API_KEY") or
            os.environ.get("CLAUDE_API_KEY") or
            os.environ.get("API_KEY")
        )

        if not api_key:
            # Try reading from common config locations
            config_paths = [
                Path.home() / ".anthropic" / "api_key",
                Path.home() / ".config" / "anthropic" / "api_key",
            ]
            for path in config_paths:
                if path.exists():
                    api_key = path.read_text().strip()
                    break

        if not api_key:
            raise ValueError(
                "ANTHROPIC_API_KEY not found. Set it via:\n"
                "  export ANTHROPIC_API_KEY=your-key-here\n"
                "Or save to: ~/.anthropic/api_key"
            )

        client = anthropic.Anthropic(api_key=api_key)

        print("🤖 Analyzing with Claude API (sonnet-4)...")

        message = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=16000,
            temperature=0,
            messages=[{
                "role": "user",
                "content": prompt
            }]
        )

        response_text = message.content[0].text

        # Clean up response if it has markdown code fences
        if response_text.strip().startswith("```"):
            # Remove code fences
            lines = response_text.strip().split('\n')
            if lines[0].startswith("```"):
                lines = lines[1:]
            if lines and lines[-1].strip() == "```":
                lines = lines[:-1]
            response_text = '\n'.join(lines)

        return response_text.strip()

    def _call_via_cli(self, prompt):
        """Call Claude via CLI (if available)"""
        # Check if claude CLI is available
        result = subprocess.run(
            ["which", "claude"],
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            raise RuntimeError("Claude CLI not found. Install Anthropic SDK: pip install anthropic")

        print("🤖 Analyzing with Claude CLI...")

        # Write prompt to temp file
        import tempfile
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write(prompt)
            temp_file = f.name

        try:
            result = subprocess.run(
                ["claude", "--file", temp_file, "--model", "claude-sonnet-4-20250514"],
                capture_output=True,
                text=True,
                timeout=120
            )

            if result.returncode != 0:
                raise RuntimeError(f"Claude CLI failed: {result.stderr}")

            response_text = result.stdout.strip()

            # Clean up response if it has markdown code fences
            if response_text.startswith("```"):
                lines = response_text.split('\n')
                if lines[0].startswith("```"):
                    lines = lines[1:]
                if lines and lines[-1].strip() == "```":
                    lines = lines[:-1]
                response_text = '\n'.join(lines)

            return response_text.strip()

        finally:
            os.unlink(temp_file)

    def _validate_analysis(self, analysis):
        """Validate that analysis follows the expected schema"""
        required_keys = [
            "analysis",
            "feature_analysis",
            "version_plan",
            "worker_recommendations",
            "generated_prompts"
        ]

        for key in required_keys:
            if key not in analysis:
                raise ValueError(f"Missing required key in analysis: {key}")

        # Validate no time-based planning
        analysis_str = json.dumps(analysis).lower()
        time_keywords = ["week", "day", "sprint", "quarter", "month"]
        for keyword in time_keywords:
            if keyword in analysis_str:
                print(f"⚠️  Warning: Analysis may contain time-based planning ('{keyword}')")

    def _estimate_tokens(self, text):
        """Rough estimate of tokens (4 chars ≈ 1 token)"""
        return len(text) // 4

    def generate_config(self, analysis, project_root):
        """Generate .czarina/config.json from analysis"""
        import re
        project_name = analysis["analysis"]["project_name"]
        # Create slug: lowercase, replace spaces/underscores with single dash, remove special chars
        slug = project_name.lower()
        slug = re.sub(r'[_\s]+', '-', slug)  # Replace spaces/underscores with single dash
        slug = re.sub(r'[^a-z0-9\-]', '', slug)  # Remove non-alphanumeric except dash
        slug = re.sub(r'-+', '-', slug)  # Collapse multiple dashes
        slug = slug.strip('-')  # Remove leading/trailing dashes

        workers = []
        for worker in analysis["worker_recommendations"]:
            workers.append({
                "id": worker["id"],
                "agent": worker["agent"],
                "branch": f"feat/v0.1.0-{worker['id']}",  # Will be updated per version
                "description": worker["description"],
                "total_token_budget": worker["total_token_budget"],
                "versions_assigned": worker["versions_assigned"]
            })

        config = {
            "project": {
                "name": project_name,
                "slug": slug,
                "repository": str(project_root),
                "orchestration_dir": ".czarina"
            },
            "workers": workers,
            "version_plan": {},
            "daemon": {
                "enabled": True,
                "auto_approve": ["read", "write", "commit"]
            },
            "analysis": {
                "total_tokens_projected": analysis["analysis"]["total_tokens_projected"],
                "complexity": analysis["analysis"]["complexity"],
                "recommended_workers": analysis["analysis"]["recommended_workers"],
                "recommended_versions": analysis["analysis"]["recommended_versions"]
            }
        }

        # Add version plan
        for version in analysis["version_plan"]:
            config["version_plan"][version["version"]] = {
                "description": version["description"],
                "features_included": version["features_included"],
                "token_budget": version["token_budget"],
                "workers_assigned": version["workers_assigned"],
                "dependencies": version.get("dependencies", []),
                "completion_criteria": version["completion_criteria"],
                "status": "planned"
            }

        return config

    def generate_worker_prompts(self, analysis):
        """Generate worker prompt files from analysis"""
        return analysis["generated_prompts"]

    def save_analysis(self, analysis, output_file):
        """Save complete analysis to JSON file"""
        with open(output_file, 'w') as f:
            json.dump(analysis, f, indent=2)

    def print_summary(self, analysis):
        """Print a human-readable summary of the analysis"""
        print("\n" + "=" * 60)
        print("📊 ANALYSIS COMPLETE")
        print("=" * 60)
        print()

        # Project overview
        proj = analysis["analysis"]
        print(f"🎯 Project: {proj['project_name']}")
        print(f"   Type: {proj['project_type']}")
        print(f"   Complexity: {proj['complexity']}")
        print(f"   Total Tokens: ~{proj['total_tokens_projected']:,}")
        print()

        # Workers
        print(f"👷 Recommended Workers: {len(analysis['worker_recommendations'])}")
        for worker in analysis["worker_recommendations"]:
            print(f"   • {worker['id']:15} - {worker['role']:20} ({worker['agent']:12}) - {worker['total_token_budget']:,} tokens")
        print()

        # Versions
        print(f"📦 Version Plan: {len(analysis['version_plan'])} versions")
        for version in analysis["version_plan"]:
            tokens = version["token_budget"]["projected"]
            print(f"   • {version['version']:20} - {version['description']:30} ({tokens:,} tokens)")
        print()

        # Efficiency factors
        if "efficiency_factors" in proj:
            print("⚡ Efficiency Factors:")
            for factor, multiplier in proj["efficiency_factors"].items():
                print(f"   • {factor}: {multiplier}x")
            print()
