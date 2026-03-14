# Czarina Integration Tests

Tests for the Czarina orchestration engine. These tests exercise the full
lifecycle of the hopper integration without requiring tmux, real agents, or
an active orchestration session.

---

## Test Suite

### `test-hopper-instruction-store.sh`

**52 assertions** across 14 sections covering the complete hopper integration:

| Section | What it tests |
|---------|---------------|
| 1. Prerequisites | hopper installed, jq available, script syntax |
| 2. Function API | All 17 required functions defined in hopper-integration.sh |
| 3. Task ID store | Init, write, read round-trips for `.czarina/hopper-tasks.json` |
| 4. Brief storage | `--brief-file` stores full markdown, content preserved, JSON output, `--with-lessons` accepted |
| 5. Status transitions | `open → in_progress → blocked → completed` via integration helpers |
| 6. Full registration | `hopper_register_orchestration` creates project + worker tasks with full briefs and correct tags |
| 7. Worker start | `hopper_worker_start` marks the correct task `in_progress` |
| 8. Status display | `hopper_print_status` renders summary line and per-worker rows |
| 9. Session recovery | Worker re-discovers task by tag, retrieves full brief, re-claims status |
| 10. Closeout | All tasks marked completed/cancelled; project task completed |
| 11. CLI flags | `--non-interactive`, `--with-lessons`, `--brief-file` server-mode rejection |
| 12. Validation | hopper is a hard required check in `validate-config.sh` |
| 13. Identity template | Hopper-first, recovery section, lesson-filing section, no old file-based prompts |
| 14. Launch ordering | `hopper_register_orchestration` called before `create_worker_window` |

---

## Running

```bash
# From the czarina repo root
bash czarina-core/tests/test-hopper-instruction-store.sh

# With verbose output (shows hopper CLI output for each step)
bash czarina-core/tests/test-hopper-instruction-store.sh --verbose
```

**Expected output:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Hopper Instruction Store — Integration Test Suite
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

▶ 1. Prerequisites
  ✓  hopper binary available
  ✓  jq available
  ✓  hopper-integration.sh syntax valid

... (52 tests total) ...

  Passed:  52
  Failed:  0
  Skipped: 0

  ✅ All tests passed
```

---

## Test Design

**No side effects on your environment.** The test:
- Creates an isolated temp directory for all operations
- Uses hopper's auto-detection to keep test tasks out of `~/.hopper`
- Cancels any test tasks created during the run via the `EXIT` trap
- Does not require tmux, git repos, or running agents

**Synthetic project fixture.** The test builds a minimal czarina project:
```
/tmp/czarina-test-XXXXXX/
├── .hopper/              # Isolated hopper store for this test run
└── project/
    └── .czarina/
        ├── config.json   # 2-worker test config (backend + qa)
        └── workers/
            ├── backend.md   # Realistic worker brief
            └── qa.md        # Realistic worker brief
```

---

## Prerequisites

- `hopper` binary installed (`pip install hopper-cli`)
- `jq` installed
- bash 4+

Run `czarina validate` in any czarina project to check all prerequisites.

---

## Adding Tests

The test file is a single bash script with a clear section-based structure.
To add a new test:

1. Find the appropriate section or add a new one
2. Use the `pass()` / `fail()` / `skip()` helpers
3. Test both the happy path and failure modes
4. Clean up any resources you create (tasks, files) within the section

```bash
section "15. My new feature"

MY_OUTPUT=$(some_command 2>&1)
if echo "$MY_OUTPUT" | grep -q "expected"; then
    pass "Command produces expected output"
else
    fail "Expected 'expected' in output, got: $MY_OUTPUT"
fi
```
