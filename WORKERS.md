# 🎯 Multi-Agent Orchestration

This repository uses **Czarina** for multi-agent orchestration.

## For Claude Code Web

When a human tells you "You are Engineer 1" (or any worker), do this:

```bash
# Step 1: Find your worker file
ls czarina-multi-agent-support/workers/

# Step 2: Read your specific prompt (example for engineer1)
cat czarina-multi-agent-support/workers/engineer1.md

# Step 3: Follow the instructions in that file exactly
```

All worker prompts are in: `czarina-multi-agent-support/workers/`

## Available Workers

    {
      "id": "rebrand",
      "branch": "feat/agent-agnostic-docs",

## Quick Reference

Human says → You read:
- "Engineer 1" → `czarina-multi-agent-support/workers/engineer1.md`
- "Engineer 2" → `czarina-multi-agent-support/workers/engineer2.md`
- "QA 1" → `czarina-multi-agent-support/workers/qa1.md`
- "Docs 1" → `czarina-multi-agent-support/workers/docs1.md`

## Helper Script (Local)

```bash
./czarina-multi-agent-support/.worker-init engineer1
```

Shows your full prompt and branch info.

## More Info

See: `czarina-multi-agent-support/README.md`
