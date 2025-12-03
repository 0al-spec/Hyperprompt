# PROGRESS — Update CI Task Checklist

**Version:** 1.0.0

## Purpose

Update the checklist in `next.md` to track completion of subtasks within the current CI task. This command synchronizes progress between implementation and documentation.

## Input
- `DOCS/CI/INPROGRESS/next.md` — current CI task with checklist
- `DOCS/CI/INPROGRESS/{TASK_ID}_{TASK_NAME}.md` — PRD (optional, for reference)

## Algorithm

1. **Identify current task** from `next.md` header (extract TASK_ID)
2. **Review checklist** in `next.md` (all `[ ]` and `[x]` items)
3. **Interactive prompt** for each uncompleted item:
   - Show subtask description
   - Ask: "Mark as completed? (y/n/skip)"
   - Update `[ ]` → `[x]` if confirmed
4. **Calculate progress**: `completed / total` percentage
5. **Update task header** with progress indicator
6. **Commit changes** with message: `"Progress: {TASK_ID} — {completed}/{total} subtasks completed"`

## Output
- Updated `DOCS/CI/INPROGRESS/next.md` with marked checklist items
- Progress indicator in task header: `[Progress: 3/8 = 38%]`
- Git commit with progress snapshot

## Alternative: Automatic Detection for CI Tasks

If implementation includes specific markers, auto-detect completion:

```
1. Check if .github/workflows/ci.yml exists → mark "Create workflow file" as [x]
2. Check if workflow has 'on:' section → mark "Define triggers" as [x]
3. Check if workflow has 'permissions:' → mark "Add permissions block" as [x]
4. Check if workflow has caching → mark "Configure caching" as [x]
5. Run yamllint .github/workflows/ci.yml → mark "Validate YAML syntax" as [x] if exit code 0
```

## CI-Specific Auto-Detection Examples

**CI-01 (Audit):**
```bash
# Check if audit results documented
test -f DOCS/CI/AUDIT.md && mark "Document findings" as [x]
```

**CI-02 (Triggers):**
```bash
# Check if triggers defined
grep -q "on:" .github/workflows/ci.yml && mark "Add triggers" as [x]
grep -q "paths:" .github/workflows/ci.yml && mark "Add path filters" as [x]
```

**CI-03 (Environment):**
```bash
# Check if runner and setup configured
grep -q "runs-on: ubuntu-latest" .github/workflows/ci.yml && mark "Configure runner" as [x]
grep -q "actions/setup-" .github/workflows/ci.yml && mark "Setup toolchain" as [x]
grep -q "actions/cache@" .github/workflows/ci.yml && mark "Configure caching" as [x]
```

**CI-04 (Static Analysis):**
```bash
# Check if lint step exists
grep -q "lint" .github/workflows/ci.yml && mark "Add lint step" as [x]
```

**CI-05 (Tests):**
```bash
# Check if test step exists
grep -q "test" .github/workflows/ci.yml && mark "Add test step" as [x]
grep -q "actions/upload-artifact@" .github/workflows/ci.yml && mark "Configure artifacts" as [x]
```

**CI-07 (Permissions):**
```bash
# Check if permissions defined
grep -q "permissions:" .github/workflows/ci.yml && mark "Define permissions" as [x]
```

## Exceptions
- No next.md → Exit with error "No current CI task"
- Task already 100% complete → Ask if should move to next task (run SELECT)
- PRD doesn't match next.md checklist → Warn about inconsistency

## Integration with CI Workflow

```
SELECT → next.md created
  ↓
PLAN → PRD created
  ↓
[Work on CI subtasks...]
  ↓
PROGRESS → Update checklist (repeat as needed)
  ↓
PROGRESS shows 100% → Run SELECT for next CI task
```

## Example Usage

```bash
# After completing trigger configuration for CI-02
$ claude "Run PROGRESS command for CI"

Found task: CI-02 — Define workflow triggers
Progress: 1/3 subtasks completed (33%)

Subtask 2: "Add path filters for source code"
Status: [ ] Not completed
Detection: Found 'paths:' in ci.yml
Auto-mark as completed? [y/n/skip]: y

Subtask 3: "Add manual dispatch trigger"
Status: [ ] Not completed
Detection: Found 'workflow_dispatch:' in ci.yml
Auto-mark as completed? [y/n/skip]: y

...

Updated next.md: 3/3 completed (100%)
Committed: "Progress: CI-02 — 3/3 subtasks completed"
```

## Notes

- This command is **optional** — you can manually edit next.md
- Useful for CI tasks with multiple workflow modifications
- Progress tracking helps identify which CI features are complete
- Consider running PROGRESS after each workflow file edit
- Auto-detection works by parsing .github/workflows/ci.yml
