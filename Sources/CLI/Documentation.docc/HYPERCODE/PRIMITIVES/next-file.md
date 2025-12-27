# next.md File

The `DOCS/INPROGRESS/next.md` file contains metadata for the currently selected task.

## Purpose

- Tracks which task is currently being worked on
- Provides minimal context for the task
- Guides user to run PLAN command for details

## Structure

```markdown
# Next Task: {TASK_ID} — {TASK_NAME}

**Priority:** P0/P1/P2
**Phase:** {Phase Name}
**Effort:** {Hours}
**Dependencies:** {Task IDs or None}
**Status:** Selected

## Description

{1-2 sentence description from Workplan}

## Next Step

Run PLAN command to generate implementation plan:
$ claude "Выполни команду PLAN"
```

## Important

- Keep minimal — under 20 lines
- No implementation details
- No checklists or acceptance criteria
- Just metadata and pointer to PLAN
