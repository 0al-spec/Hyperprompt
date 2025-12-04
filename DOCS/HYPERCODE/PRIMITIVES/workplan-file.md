# Workplan.md File

The `DOCS/Workplan.md` file contains all project tasks organized by phases.

## Purpose

- Central registry of all project tasks
- Tracks status, priorities, and dependencies
- Shows progress and what's next

## Task Format

Each task is a table row with:
- **Checkbox** — [ ] or [x] for status
- **Task ID** — Unique identifier (e.g., CI-01)
- **Name** — Brief task description
- **Priority** — P0, P1, or P2
- **Effort** — Estimated hours
- **Dependencies** — Task IDs or "None"
- **Status marker** — **INPROGRESS** for current task

## Example

```markdown
| Status | ID    | Task Name        | Priority | Effort | Dependencies |
|--------|-------|------------------|----------|--------|--------------|
| [ ]    | CI-01 | Setup CI         | P0       | 4h     | None         | **INPROGRESS**
| [ ]    | CI-02 | Add tests        | P1       | 6h     | CI-01        |
| [x]    | CI-03 | Documentation    | P2       | 2h     | CI-02        |
```
