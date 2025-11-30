# 📥 Czarina Improvement Inbox

## Purpose

This is the central inbox for **all Czarina improvements, fixes, and feedback** from Czar sessions and workers.

**Target audience:** Claude Code Czars, workers, and anyone improving Czarina on the fly

## Quick Start

### 🚀 I Fixed Something!

Drop your notes here:

```bash
# Already integrated the fix? Use FIX_DONE
cp czarina-inbox/templates/FIX_DONE.md czarina-inbox/fixes/YYYY-MM-DD-short-description.md

# Or if it's a quick fix that needs review? Use QUICK_FIX
cp czarina-inbox/templates/QUICK_FIX.md czarina-inbox/fixes/YYYY-MM-DD-short-description.md

# Edit and describe what you fixed
# That's it!
```

### 💡 I Have Feedback!

Drop your feedback here:

```bash
# Template for feedback
cp czarina-inbox/templates/FEEDBACK.md czarina-inbox/feedback/YYYY-MM-DD-topic.md

# Edit and share your thoughts
# Done!
```

### 🐛 I Found a Bug!

Report it here:

```bash
# Template for bugs
cp czarina-inbox/templates/BUG_REPORT.md czarina-inbox/bugs/YYYY-MM-DD-bug-name.md

# Fill in the details
# Submit!
```

## Directory Structure

```
czarina-inbox/
├── README.md                    # This file
├── templates/                   # Templates for different types of submissions
│   ├── FIX_DONE.md             # "I did a thing!" - already integrated
│   ├── QUICK_FIX.md            # Fix that needs review
│   ├── FEEDBACK.md
│   ├── BUG_REPORT.md
│   ├── FEATURE_REQUEST.md
│   └── SESSION_NOTES.md
├── fixes/                       # Code fixes and improvements
│   └── YYYY-MM-DD-name.md
├── feedback/                    # Feedback and suggestions
│   └── YYYY-MM-DD-topic.md
├── bugs/                        # Bug reports
│   └── YYYY-MM-DD-bug.md
├── features/                    # Feature requests
│   └── YYYY-MM-DD-feature.md
├── sessions/                    # Session notes from Czar work
│   └── YYYY-MM-DD-session-N.md
├── patterns/                    # Patterns to contribute upstream 🌐
│   └── YYYY-MM-DD-pattern.md
└── processed/                   # Moved here after integration
    └── YYYY-MM-DD-*.md
```

## Submission Types

### 1. Fix Done 🎯
**When:** You already did a fix and integrated it - "by the way, I did a thing!"

**Template:** `templates/FIX_DONE.md`

**Goes in:** `fixes/`

**Example:**
```markdown
# Fix: Daemon tmux session detection

## What I Fixed
The daemon couldn't find worker sessions with different naming patterns.

## Why I Fixed It
Was running a session and daemon kept failing to find workers.

## Changes Made
- Added multi-pattern session detection in czar-daemon.sh
- Falls back gracefully if session not found

## Integration Status
Already integrated: yes
Committed: abc123

## Testing
Tested with 3 different session naming patterns. Works!
```

### 2. Quick Fixes 🔧
**When:** You found a fix that needs review/testing before integration

**Template:** `templates/QUICK_FIX.md`

**Goes in:** `fixes/`

**Example:**
```markdown
# Fix: Config validation improvement

## What Needs Fixing
Config doesn't validate worker count limits.

## Proposed Fix
Add validation in load_config() function.

## Files to Change
- czarina-core/lib/config.py

## Needs Review
Should we hard-limit at 20 workers or make it configurable?
```

### 3. Feedback 💬
**When:** You have suggestions, observations, or general feedback

**Template:** `templates/FEEDBACK.md`

**Goes in:** `feedback/`

**Example:**
```markdown
# Feedback: Daemon could be smarter

## Observation
Daemon tries same approval repeatedly even when it fails.

## Suggestion
Add verification after approval attempts.

## Impact
Would save daemon cycles and provide better visibility.
```

### 4. Bug Reports 🐛
**When:** You found a bug (even if you didn't fix it)

**Template:** `templates/BUG_REPORT.md`

**Goes in:** `bugs/`

**Example:**
```markdown
# Bug: Dashboard crashes with missing config

## Description
Dashboard crashes if config.json is missing.

## Steps to Reproduce
1. Delete config.json
2. Run czarina dashboard myproject
3. Crash with stack trace

## Expected
Should show helpful error message.

## Actual
Python exception and stack trace.
```

### 5. Feature Requests ✨
**When:** You have an idea for a new feature

**Template:** `templates/FEATURE_REQUEST.md`

**Goes in:** `features/`

**Example:**
```markdown
# Feature: Slack notifications for stuck workers

## Description
Send Slack notification when worker gets stuck.

## Use Case
I'm away from computer but want to know if workers need attention.

## Implementation Ideas
- Read alerts.json file
- Post to Slack webhook
- Configurable in project config
```

### 6. Session Notes 📝
**When:** You completed a Czar session and want to share learnings

**Template:** `templates/SESSION_NOTES.md`

**Goes in:** `sessions/`

**Example:**
```markdown
# Session 3 Notes - SARK v2.0

## What We Built
- Alert system for stuck workers
- Visual status dashboard
- Real-time monitoring

## Key Learnings
- Claude Code UI doesn't respond to tmux send-keys
- Verification after approval is critical
- JSON alerts enable rich integrations

## Files Created
- czar-daemon-v2.sh
- czar-status-dashboard.sh
- ALERT_SYSTEM.md
```

### 7. Patterns 🌐 (Backchannel to Community)
**When:** You discovered a pattern worth sharing with the community

**Goes in:** `patterns/`

**What to document:**
- Error recovery patterns (took >30min to solve)
- Multi-agent coordination strategies
- Tool use optimizations
- Agent-specific quirks
- Automation improvements

**Example:**
```markdown
# Pattern: Daemon Verification Loop

**Problem:** Daemon approvals fail silently

**Solution:**
1. Send approval
2. Wait 0.5s
3. Verify it worked
4. Flag if still stuck

**Value:** Caught 15% of failures

**Metrics:**
- Before: 85% success rate
- After: 100% success rate with alerts

**Source:** SARK v2.0 Session 3
```

**Backchannel flow:**
1. Document pattern here
2. Check with: `czarina patterns pending`
3. Contribute upstream to agentic-dev-patterns
4. Pattern flows to all Czarina instances
5. Everyone codes better!

See [PATTERN_CONTRIBUTION_GUIDE.md](../czarina-core/patterns/PATTERN_CONTRIBUTION_GUIDE.md)

## Workflow

### For Contributors (Czars/Workers)

1. **Identify what you have:**
   - Already did a fix? → Use FIX_DONE.md
   - Found a fix that needs review? → Use QUICK_FIX.md
   - General feedback? → Use FEEDBACK.md
   - Bug report? → Use BUG_REPORT.md
   - Feature idea? → Use FEATURE_REQUEST.md
   - Session notes? → Use SESSION_NOTES.md

2. **Copy template:**
   ```bash
   cp czarina-inbox/templates/[TEMPLATE].md czarina-inbox/[category]/YYYY-MM-DD-name.md
   ```

3. **Fill it out:**
   - Be as detailed or brief as you want
   - Include code snippets if relevant
   - Link to files you modified

4. **Drop and go:**
   - No need to commit or PR
   - Just leave it in the inbox
   - Someone will process it later

### For Maintainers (Integration)

1. **Review inbox periodically:**
   ```bash
   ls -lt czarina-inbox/*/
   ```

2. **Process submissions:**
   - Evaluate impact and priority
   - Integrate fixes into core
   - Update documentation
   - Test changes

3. **Move to processed:**
   ```bash
   mv czarina-inbox/fixes/2025-11-29-*.md czarina-inbox/processed/
   ```

4. **Acknowledge contributors:**
   - Update CHANGELOG
   - Credit in commit messages
   - Thank in release notes

## Templates

### Minimal Template (All Types)

Every submission should at minimum include:

```markdown
# [Type]: [Short Description]

## What
[What is this about?]

## Why
[Why does it matter?]

## Details
[More information, code, screenshots, etc.]

## Author
[Your name/handle - optional]

## Date
YYYY-MM-DD
```

### Quick Template Usage

**From command line:**
```bash
# Quick fix
cat > czarina-inbox/fixes/$(date +%Y-%m-%d)-my-fix.md << 'EOF'
# Fix: Brief description

## What I Fixed
[Describe the fix]

## Files Changed
- path/to/file.sh

## Testing
[How you tested it]
EOF
```

## Examples from Real Sessions

### SARK Session 3
**Submission:** `sessions/2025-11-29-sark-session-3.md`

**Included:**
- Alert system implementation
- Dashboard improvements
- Claude Code limitation analysis
- Code files and documentation

**Integration status:** Ready for core integration

### Multi-Agent Support
**Submission:** `fixes/2025-11-29-daemon-core-integration.md`

**Included:**
- Generalized daemon for any project
- CLI commands integration
- Documentation updates

**Integration status:** Completed

## Guidelines

### DO ✅
- Drop any improvements, no matter how small
- Include code snippets and file paths
- Share learnings and observations
- Be brief or detailed - both are fine
- Submit even if partially complete
- Use templates (makes processing easier)

### DON'T ❌
- Wait for "perfect" documentation
- Worry about formatting too much
- Hesitate because it's "too small"
- Leave improvements undocumented
- Assume "someone else will document it"

## Philosophy

> **"If you built it, fixed it, or thought about it - drop a note in the inbox!"**

The inbox exists to:
- **Capture improvements** that happen during Czar sessions
- **Prevent lost knowledge** when fixes happen on the fly
- **Enable integration** by providing context for changes
- **Share learnings** across different projects/sessions
- **Make it easy** to contribute without formal process

## Processing Schedule

**Maintainers check inbox:**
- After major sessions (like SARK)
- Before releases
- When planning integration work
- At least weekly

**Fast-track items:**
- Critical bugs
- Security issues
- Breaking changes
- High-impact improvements

## Integration Priority

**High Priority (integrate immediately):**
- Critical bug fixes
- Security improvements
- Widely-tested improvements from sessions

**Medium Priority (integrate in next release):**
- Feature enhancements
- Performance improvements
- Documentation updates

**Low Priority (consider for future):**
- Nice-to-have features
- Experimental ideas
- Edge case fixes

## Success Metrics

**Inbox is working when:**
- Every session leaves notes
- Improvements are documented as they happen
- Integration is faster (context already captured)
- Knowledge doesn't get lost
- Contributors feel heard

## Current Inbox

**Check what's waiting:**
```bash
# See all pending items
find czarina-inbox -name "*.md" -type f | grep -v processed | grep -v templates

# See recent submissions
ls -lt czarina-inbox/*/*.md | head -10

# Count by category
echo "Fixes:    $(ls czarina-inbox/fixes/*.md 2>/dev/null | wc -l)"
echo "Feedback: $(ls czarina-inbox/feedback/*.md 2>/dev/null | wc -l)"
echo "Bugs:     $(ls czarina-inbox/bugs/*.md 2>/dev/null | wc -l)"
echo "Features: $(ls czarina-inbox/features/*.md 2>/dev/null | wc -l)"
echo "Sessions: $(ls czarina-inbox/sessions/*.md 2>/dev/null | wc -l)"
```

## Questions?

**Where do I submit?**
- Look at the submission types above
- Pick the closest match
- Use the template

**What if it doesn't fit a category?**
- Use SESSION_NOTES.md (most flexible)
- Or create a new file in the root

**Do I need to format perfectly?**
- No! Just capture the information
- Maintainers will clean up during integration

**What if I'm not sure it's important?**
- Submit it anyway!
- Let maintainers decide priority
- Better to have too much info than too little

**Can I submit multiple things?**
- Yes! One file per improvement
- Or group related items in a session note

---

**Created:** 2025-11-29
**Purpose:** Central collection point for all Czarina improvements
**Status:** Active and ready for submissions
**Goal:** Never lose an improvement or learning again! 🎯
