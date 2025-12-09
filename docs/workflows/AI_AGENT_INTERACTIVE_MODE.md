# AI Agent Interactive Mode

**Status:** ✅ Implemented (as of v0.4.0)
**Use Case:** AI coding assistants (Claude Code, Cursor, etc.) analyzing implementation plans

---

## Problem

The original interactive mode used `input()` which blocks in non-interactive contexts, causing `EOFError` when AI agents try to run:
```bash
czarina analyze plan.md --interactive --init
```

## Solution

Two-pass workflow that works seamlessly with AI agents:

### Pass 1: Save Prompt
```bash
czarina analyze docs/plan.md --interactive --init
```

**What happens:**
1. ✅ Reads implementation plan
2. ✅ Generates analysis prompt
3. ✅ Saves to `.czarina-analysis-prompt.md`
4. ✅ Exits with instructions (no blocking!)

**Output:**
```
✅ Analysis prompt saved to: .czarina-analysis-prompt.md

📋 NEXT STEPS FOR AI AGENT

  1. Read and analyze: .czarina-analysis-prompt.md
  2. Generate JSON response following the schema
  3. Save response to: .czarina-analysis-response.json

Then run this command again:
  czarina analyze docs/plan.md --interactive --init
```

### Pass 2: Load Response & Initialize
AI agent:
1. Reads `.czarina-analysis-prompt.md`
2. Analyzes the implementation plan
3. Generates JSON following the schema
4. Saves to `.czarina-analysis-response.json`

Then runs the **same command** again:
```bash
czarina analyze docs/plan.md --interactive --init
```

**What happens:**
1. ✅ Detects existing `.czarina-analysis-response.json`
2. ✅ Loads and validates JSON
3. ✅ Creates `.czarina/` directory structure
4. ✅ Generates `config.json` and worker prompts
5. ✅ Cleans up temporary files
6. ✅ Project ready to launch!

---

## Workflow Diagram

```
┌─────────────────────────────────────────────┐
│ USER: czarina analyze plan.md --interactive │
│                      --init                  │
└────────────────┬────────────────────────────┘
                 │
                 ▼
     ┌───────────────────────┐
     │ Check for response    │
     │ file exists?          │
     └───────┬───────────────┘
             │
      ┌──────┴──────┐
      │             │
     NO            YES
      │             │
      ▼             ▼
┌──────────────┐  ┌────────────────┐
│ Save prompt  │  │ Load response  │
│ Exit(0)      │  │ Continue init  │
└──────────────┘  └────────────────┘
      │                    │
      ▼                    ▼
┌──────────────┐  ┌────────────────┐
│ AI AGENT:    │  │ Create .czarina│
│ Read prompt  │  │ Success!       │
│ Create JSON  │  └────────────────┘
└──────────────┘
      │
      ▼
 Repeat command
```

---

## Example: Full Workflow

### 1. User initiates analysis
```bash
$ czarina analyze docs/v1.2.0/IMPLEMENTATION_PLAN.md --interactive --init

🔍 Czarina Project Analysis
============================================================

📄 Input Plan: docs/v1.2.0/IMPLEMENTATION_PLAN.md

📊 Plan Statistics:
   Lines: 1198
   Words: 4606
   Characters: 35402

📝 INTERACTIVE ANALYSIS MODE
============================================================

✅ Analysis prompt saved to: .czarina-analysis-prompt.md

📋 NEXT STEPS FOR AI AGENT

Please ask your AI agent (Claude Code, Cursor, etc.) to:

  1. Read and analyze: .czarina-analysis-prompt.md
  2. Generate JSON response following the schema
  3. Save response to: .czarina-analysis-response.json

Then run this command again:
  czarina analyze docs/v1.2.0/IMPLEMENTATION_PLAN.md --interactive --init

The tool will detect the response file and continue automatically.
```

### 2. AI agent processes prompt

**User to AI agent:**
> "Read .czarina-analysis-prompt.md, analyze the plan, and save your JSON response to .czarina-analysis-response.json"

**AI agent:**
- Reads prompt (plan + analysis instructions)
- Analyzes implementation plan
- Generates JSON with workers, versions, token budgets
- Saves to `.czarina-analysis-response.json`

### 3. User re-runs command
```bash
$ czarina analyze docs/v1.2.0/IMPLEMENTATION_PLAN.md --interactive --init

🔍 Czarina Project Analysis
============================================================

📄 Input Plan: docs/v1.2.0/IMPLEMENTATION_PLAN.md

📝 INTERACTIVE ANALYSIS MODE
============================================================

✅ Found existing response: .czarina-analysis-response.json

✅ Response loaded successfully

📊 Analysis Summary
============================================================
Project: SARK v1.2.0
Workers: 5
Versions: 5
Total Token Budget: 1,750,000

🚀 Auto-initializing project...

✅ Created: .czarina/config.json
✅ Created: .czarina/workers/gateway-http-sse.md
✅ Created: .czarina/workers/gateway-stdio.md
✅ Created: .czarina/workers/integration.md
✅ Created: .czarina/workers/policy.md
✅ Created: .czarina/workers/qa.md
✅ Created: .czarina/analysis.json

🎉 Project initialized successfully!

📋 Next steps:
  1. Review worker prompts in .czarina/workers/
  2. czarina launch
```

---

## Key Benefits

1. **No blocking** - Exits cleanly instead of waiting for input
2. **Idempotent** - Running same command twice works correctly
3. **Agent-friendly** - Clear instructions for what to do
4. **Automatic** - Detects response file and continues seamlessly
5. **Clean** - Temporary files cleaned up after successful init

---

## Technical Details

### File Detection Logic

```python
response_file = Path.cwd() / ".czarina-analysis-response.json"

if response_file.exists():
    # Pass 2: Load and continue
    response = load_json(response_file)
    cleanup_temp_files()
    return response
else:
    # Pass 1: Save prompt and exit
    save_prompt(prompt_file)
    print_instructions()
    sys.exit(0)  # Clean exit
```

### Why Not Poll/Wait?

Original approach tried to poll for file creation, but this:
- Adds unnecessary complexity
- Creates timeout issues
- Doesn't work well with agent workflows
- Makes the UX unclear

The two-pass approach is:
- Simpler to understand
- More explicit about what's happening
- Works consistently across all environments
- Easier to debug

---

## Troubleshooting

### "EOFError: EOF when reading a line"

**Before fix:** Interactive mode blocked on `input()` call
**After fix:** Exits cleanly with instructions

### Response file not created

Check that AI agent:
1. Can read `.czarina-analysis-prompt.md`
2. Has permission to write `.czarina-analysis-response.json`
3. Generated valid JSON (no syntax errors)

### Validation errors

If response doesn't match schema:
```bash
# Check the JSON manually
cat .czarina-analysis-response.json | python -m json.tool

# Try again with corrected JSON
czarina analyze plan.md --interactive --init
```

---

## Future Improvements

Potential enhancements:
- [ ] Auto-detect if running inside Claude Code and skip pass 1
- [ ] Provide example JSON response in prompt
- [ ] Validate partial JSON and suggest fixes
- [ ] Support resuming from incomplete analysis
- [ ] Add `--continue` flag to explicitly load existing response

---

**Version:** 0.4.0
**Last Updated:** 2025-12-09
**Status:** ✅ Production Ready
