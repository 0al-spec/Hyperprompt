# SELECT — Next CI Task Selection

**Version:** 1.0.0

## Input
- `DOCS/CI/Workplan.md` — CI work plan
- `DOCS/CI/INPROGRESS/next.md` — current CI task

## Algorithm

1. **Find candidates** satisfying all:
   - Not completed `[ ]`
   - All dependencies satisfied
   - Highest priority (High > Medium)
   - Task breakdown order (CI-01 → CI-10)
   - Phase alignment (Discovery → Workflow Skeleton → Quality Gates → Validation & Docs)
2. **Add to** `next.md`: `# Next Task: {TASK_ID} — {TASK_NAME}`
3. **Update Workplan** with `**INPROGRESS**` marker and dependency checkmarks

## Output
- Updated `DOCS/CI/INPROGRESS/next.md`
- Updated `DOCS/CI/Workplan.md` with progress markers

## CI-Specific Priority Rules

Priority order based on CI Workplan:
1. **High priority tasks:** CI-01, CI-02, CI-03, CI-05, CI-07, CI-08, CI-10
2. **Medium priority tasks:** CI-04, CI-06, CI-09

Within same priority, follow:
- Phase order (Discovery → Workflow Skeleton → Quality Gates → Validation)
- Dependency chain (e.g., CI-02 before CI-03)
- Task ID sequence (CI-01 → CI-02 → CI-03...)

## Exceptions
- No available tasks → Exit with verbose error
- Multiple High priority tasks → Select first based on phase order and dependencies
- Parallel opportunities → Prefer critical path (CI-01 → CI-02 → CI-03 → CI-05 → CI-10)
