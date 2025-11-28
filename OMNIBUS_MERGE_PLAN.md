# 🎯 SARK v1.1 Omnibus Merge Plan

## Branches to Merge

### Primary v1.1 Gateway Integration Workers
1. `feat/gateway-client` - Gateway models & client (Engineer 1)
2. `feat/gateway-api` - Gateway API endpoints (Engineer 2)
3. `feat/gateway-policies` - OPA policies (Engineer 3)
4. `feat/gateway-audit` - Audit & monitoring (Engineer 4)
5. `feat/gateway-tests` - Test infrastructure (QA)
6. `feat/gateway-docs` - Documentation (Docs)

### Additional Branch
7. **`chore/cleanup-linting-warnings`** - v2.0 preparation work (YOU - Worker #7!)

## Omnibus Branch

**Name**: `feat/gateway-integration-omnibus` (or `feat/v1.1-omnibus`)

**Base**: `main`

**Merge Order** (respects dependencies):
```bash
1. feat/gateway-client                # Foundation (models) first
2. chore/cleanup-linting-warnings     # v2.0 prep (merges cleanly with models)
3. feat/gateway-policies              # Uses models
4. feat/gateway-api                   # Uses models + policies
5. feat/gateway-audit                 # Uses everything above
6. feat/gateway-tests                 # Tests everything
7. feat/gateway-docs                  # Documents everything
```

## Expected Conflicts & Resolutions

### Conflict 1: `src/sark/models/__init__.py`

**Source**: `feat/gateway-client` + `chore/cleanup-linting-warnings`

**Conflict**:
```python
# feat/gateway-client adds:
from sark.models.gateway import (
    GatewayServerInfo,
    GatewayToolInfo,
    # ... gateway models
)

# chore/cleanup-linting-warnings adds:
from sark.models.v2 import (
    # ... v2.0 prep models
)
```

**Resolution**: Combine both import lists
```python
# Both additions are compatible
from sark.models.gateway import (
    GatewayServerInfo,
    GatewayToolInfo,
    # ... gateway models
)

from sark.models.v2 import (
    # ... v2.0 prep models
)
```

### Conflict 2: `src/sark/config.py`

**Source**: Various workers + `chore/cleanup-linting-warnings`

**Conflict**: Multiple config additions

**Resolution**: Merge all additions - they're compatible
```python
# All config additions are additive, no conflicts
# Just combine everything
```

### Other Potential Conflicts

**If they occur**: Most worker branches are isolated (different files/directories), so conflicts should be minimal.

**Strategy**:
- Gateway workers touch different parts of codebase
- v2.0 prep is preparatory (shouldn't conflict with v1.1 implementation)
- Test carefully after each merge

## Merge Commands

```bash
# 1. Create omnibus branch from main
cd /home/jhenry/Source/GRID/sark
git checkout main
git pull origin main
git checkout -b feat/gateway-integration-omnibus

# 2. Merge in dependency order
git merge feat/gateway-client --no-ff -m "Merge gateway client & models"
git merge chore/cleanup-linting-warnings --no-ff -m "Merge v2.0 preparation work"
# Resolve conflicts in models/__init__.py and config.py
git add .
git commit -m "Resolve conflicts: combine imports and config"

git merge feat/gateway-policies --no-ff -m "Merge gateway policies"
git merge feat/gateway-api --no-ff -m "Merge gateway API"
git merge feat/gateway-audit --no-ff -m "Merge gateway audit & monitoring"
git merge feat/gateway-tests --no-ff -m "Merge gateway tests"
git merge feat/gateway-docs --no-ff -m "Merge gateway documentation"

# 3. Final validation
pytest tests/
black .
ruff check .
mypy src/

# 4. Push omnibus
git push origin feat/gateway-integration-omnibus

# 5. Create PR to main
gh pr create \
  --title "feat: SARK v1.1 Gateway Integration (Omnibus)" \
  --body "Complete v1.1 Gateway Integration with v2.0 prep included" \
  --base main \
  --head feat/gateway-integration-omnibus
```

## Why Include v2.0 Prep

### Benefit 1: Clean Slate for v2.0
- v1.1 ships with v2.0 foundation already in place
- No separate "prep" branch to merge later
- v2.0 work can start immediately after v1.1 release

### Benefit 2: Avoid Future Conflicts
- Merge conflicts resolved NOW (with v1.1 context fresh)
- Not later when v1.1 is ancient history
- Easier to reason about conflicts with active knowledge

### Benefit 3: Atomic Release
- v1.1 = Gateway Integration + v2.0 foundation
- One clean release, not two separate merges
- Better git history

### Benefit 4: Testing Together
- v1.1 features + v2.0 prep tested together
- Catch any incompatibilities early
- Ensure v2.0 prep doesn't break v1.1

## Post-Merge Validation

### 1. Run Full Test Suite
```bash
pytest tests/ -v
pytest tests/integration/ -v
pytest tests/gateway/ -v
```

### 2. Check Linting
```bash
black --check .
ruff check .
mypy src/
```

### 3. Manual Testing
- Test gateway registration
- Test tool invocation
- Test policy enforcement
- Test audit logging
- Verify all v1.1 features work

### 4. Check v2.0 Prep
- Verify v2.0 models imported correctly
- Check config changes don't break v1.1
- Ensure no v2.0 code is actually active (just prep)

## Timeline

**When to create omnibus**: After all 6 gateway workers complete their work

**Current status**:
- ✅ Engineer 1: Complete (3 files)
- ⚠️ Engineer 2: Working (45 files)
- ✅ Engineer 3: Complete + PR (64 files)
- ⚠️ Engineer 4: Working (bonus tasks)
- ✅ QA: Working (92 files)
- ✅ Docs: Working (54 files)

**Estimated**: 2-4 hours until all workers complete

**Then**: Create omnibus, resolve conflicts, test, PR to main

## Success Criteria

✅ All 7 branches merged into omnibus
✅ All conflicts resolved (expect 2: imports, config)
✅ All tests passing
✅ Linting clean
✅ Manual testing successful
✅ v2.0 prep included and validated
✅ PR created to main
✅ Ready for final review and merge

## Notes

- **v2.0 prep is NOT active code** - just foundation/models for future work
- Including it in v1.1 omnibus is **preparatory**, not functional
- This follows the principle: "ship the foundation with the feature"
- v2.0 development starts clean after v1.1 ships

---

**Bottom Line**: Omnibus = 6 gateway workers + v2.0 prep = Complete v1.1 with v2.0 foundation ready

*The conflicts are straightforward. This is the right approach.* 🎯
