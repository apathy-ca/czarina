# Worker Identity: one-command-launch

**Role:** Code
**Agent:** Claude Code
**Branch:** cz1/feat/one-command-launch
**Phase:** 1
**Dependencies:** None

## Mission

Implement `czarina analyze plan.md --go` to enable fully automated orchestration launch in <60 seconds. Eliminate the 8-step, 10-minute launch process.

## 🚀 YOUR FIRST ACTION

**Examine the current czarina CLI and plan structure:**
```bash
# Read the czarina Python CLI
head -100 czarina  # See structure
grep -n "def cmd_analyze" czarina  # Find analyze function

# Read a plan to understand structure
cat IMPLEMENTATION_PLAN_v0.7.1.md | head -200

# Identify what needs to be parsed:
# - Worker definitions
# - Config metadata
# - Dependencies
```

## Objectives

1. Implement markdown plan parser (extract workers, config metadata)
2. Implement automated config.json generator from parsed plan
3. Implement automated worker identity generator from parsed plan
4. Add `--go` flag to `czarina analyze` command
5. Implement full launch sequence automation
6. Add validation and error handling
7. Add `--dry-run` mode for safety
8. Test with IMPLEMENTATION_PLAN_v0.7.1.md (this plan!)
9. Test with INTEGRATION_PLAN_v0.7.0.md
10. Document new workflow

## Deliverables

- Plan parser implementation in `czarina` CLI
- Config generator function
- Worker identity generator function
- `--go` flag integrated
- Full automation workflow
- Comprehensive error handling
- Documentation and examples

## Success Criteria

- [ ] `czarina analyze plan.md --go` works end-to-end
- [ ] Launch time: <60 seconds (measured)
- [ ] Steps required: 1 (down from 8)
- [ ] Works with v0.7.1 plan
- [ ] Works with v0.7.0 plan
- [ ] Error handling prevents bad launches
- [ ] `--dry-run` shows what would happen

## Implementation Details

### Plan Parser
```python
def parse_plan(plan_file):
    """Extract structured data from markdown plan"""
    with open(plan_file) as f:
        content = f.read()

    # Extract project metadata
    project = extract_project_metadata(content)

    # Extract workers
    workers = extract_worker_definitions(content)

    return {
        "project": project,
        "workers": workers
    }
```

### Config Generator
```python
def generate_config(plan_data):
    """Generate config.json from parsed plan"""
    config = {
        "project": {
            "name": plan_data["project"]["name"],
            "slug": slugify(plan_data["project"]["name"]),
            "version": plan_data["project"]["version"],
            ...
        },
        "workers": [
            {
                "id": w["id"],
                "role": w["role"],
                "agent": w["agent"] or "claude",
                "branch": f"cz1/feat/{w['id']}",
                "description": w["description"],
                "dependencies": w["dependencies"]
            }
            for w in plan_data["workers"]
        ]
    }
    return config
```

### Worker Generator
```python
def generate_worker_identity(worker, plan_context):
    """Generate worker identity markdown from plan"""
    template = f"""# Worker Identity: {worker['id']}

**Role:** {worker['role']}
**Agent:** {worker['agent']}
**Branch:** cz1/feat/{worker['id']}

## Mission

{worker['mission']}

## 🚀 YOUR FIRST ACTION

{worker['first_action']}

## Objectives

{format_objectives(worker['tasks'])}
"""
    return template
```

## Context

**Problem:** 8 manual steps, 10+ minutes to go from plan → running orchestration
**Root Cause:** No automated plan parsing + orchestration setup
**Solution:** Parse plan, generate all files, launch automatically

**Reference:** `.czarina/hopper/enhancement-one-command-launch.md`

## Notes

- Start with plan parsing, validate early
- Use heuristics for extraction (look for patterns)
- Error handling is critical (don't launch bad configs)
- --dry-run helps validate before execution
- This will be used to launch future orchestrations!
- Test it on itself (v0.7.1 plan)
