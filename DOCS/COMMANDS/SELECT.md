# SELECT — Next Task Selection

**Version:** 1.1.0

## Purpose

SELECT identifies the next task to work on based on priorities, dependencies, and critical path. It does **NOT** create implementation plans - that's the job of the PLAN command.

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
2. **Create minimal** `next.md` with ONLY:
   - Task ID and name: `# Next Task: {TASK_ID} — {TASK_NAME}`
   - Basic metadata: Priority, Phase, Effort, Dependencies
   - Brief description from Workplan (1-2 sentences)
   - Status: "Selected" (NOT detailed checklists or acceptance criteria)
3. **Update Workplan** with `**INPROGRESS**` marker

## Output
- Updated `DOCS/INPROGRESS/next.md` (minimal metadata only)
- Updated `DOCS/Workplan.md` with progress markers

## next.md Template (Minimal)

```markdown
# Next Task: {TASK_ID} — {TASK_NAME}

**Priority:** {P0/P1/P2}
**Phase:** {Phase Name}
**Effort:** {Hours}
**Dependencies:** {Task IDs or "None"}
**Status:** Selected

## Description

{1-2 sentence description from Workplan}

## Next Step

Run PLAN command to generate detailed PRD:
$ claude "Выполни команду PLAN"
```

**IMPORTANT:** Do NOT add:
- Detailed checklists
- Acceptance criteria
- Implementation steps
- Code examples or templates

These belong in the PRD created by PLAN command.

## Exceptions
- No available tasks → Exit with verbose error
- Multiple P0 tasks → Select first on critical path
- Parallel tracks tie → Prefer Track A

