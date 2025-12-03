# SELECT — Next Task Selection

**Version:** 1.0.0

## Input
- `DOCS/Workplan.md` — work plan
- `DOCS/INPROGRESS/next.md` — current task

## Algorithm

1. **Find candidates** satisfying all:
   - Not completed `[ ]`
   - All dependencies satisfied
   - Highest priority (P0 > P1 > P2)
   - On critical path (if tie)
   - Sequential order (if tie)
2. **Add to** `next.md`: `# {TASK_ID} — {TASK_NAME}`
3. **Update Workplan** with `**INPROGRESS**` marker and dependency checkmarks

## Output
- Updated `DOCS/INPROGRESS/next.md`
- Updated `DOCS/Workplan.md` with progress markers

## Exceptions
- No available tasks → Exit with verbose error
- Multiple P0 tasks → Select first on critical path
- Parallel tracks tie → Prefer Track A
