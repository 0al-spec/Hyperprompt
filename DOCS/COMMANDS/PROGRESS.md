# PROGRESS — Update Task Checklist

**Version:** 1.0.0

## Purpose

Update the checklist in `next.md` to track completion of subtasks within the current task. This command synchronizes progress between implementation and documentation.

## Input
- `DOCS/INPROGRESS/next.md` — current task with checklist
- `DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md` — PRD (optional, for reference)

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
- Updated `DOCS/INPROGRESS/next.md` with marked checklist items
- Progress indicator in task header: `[Progress: 5/13 = 38%]`
- Git commit with progress snapshot

## Alternative: Automatic Detection

If implementation includes specific markers (e.g., completed files, passing tests), auto-detect completion:

```
1. Check if Sources/Core/ exists → mark "Create Core directory" as [x]
2. Check if Package.swift contains "swift-crypto" → mark dependency as [x]
3. Run swift build → mark "Verify build" as [x] if exit code 0
```

## Exceptions
- No next.md → Exit with error "No current task"
- Task already 100% complete → Ask if should move to next task (run SELECT)
- PRD doesn't match next.md checklist → Warn about inconsistency

## Integration with Workflow

```
SELECT → next.md created
  ↓
PLAN → PRD created
  ↓
[Work on subtasks...]
  ↓
PROGRESS → Update checklist (repeat as needed)
  ↓
PROGRESS shows 100% → Run SELECT for next task
```

## Example Usage

```bash
# After completing directory setup for A1
$ claude "Run PROGRESS command"

Found task: A1 — Project Initialization
Progress: 2/13 subtasks completed (15%)

Subtask 3: "Create Sources/ directory"
Status: [ ] Not completed
Files detected: Sources/ exists
Auto-mark as completed? [y/n/skip]: y

Subtask 4: "Create Tests/ directory"
Status: [ ] Not completed
Files detected: Tests/ exists
Auto-mark as completed? [y/n/skip]: y

...

Updated next.md: 4/13 completed (31%)
Committed: "Progress: A1 — 4/13 subtasks completed"
```

## Notes

- This command is **optional** — you can manually edit next.md
- Useful for large tasks (>5 subtasks) to maintain visibility
- Progress tracking helps with time estimation for future tasks
- Consider running PROGRESS after each significant work session
