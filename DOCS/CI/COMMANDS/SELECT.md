# SELECT — Next CI Task Selection

**Version:** 1.1.0

## Purpose

SELECT identifies the next CI task to work on based on priorities, dependencies, and phase order. It does **NOT** create implementation plans - that's the job of the PLAN command.

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
2. **Create minimal** `next.md` with ONLY:
   - Task ID and name: `# Next Task: {TASK_ID} — {TASK_NAME}`
   - Basic metadata: Priority, Phase, Effort, Dependencies
   - Brief description from Workplan (1-2 sentences)
   - Status: "Selected" (NOT detailed checklists or acceptance criteria)
3. **Update Workplan** with `**INPROGRESS**` marker

## Output
- Updated `DOCS/CI/INPROGRESS/next.md` (minimal metadata only)
- Updated `DOCS/CI/Workplan.md` with progress markers

## next.md Template (Minimal)

```markdown
# Next Task: {TASK_ID} — {TASK_NAME}

**Priority:** {High/Medium}
**Phase:** {Phase Name}
**Effort:** {Hours}
**Dependencies:** {Task IDs or "None"}
**Status:** Selected

## Description

{1-2 sentence description from Workplan}

## Next Step

Run PLAN command to generate detailed PRD:
$ claude "Выполни команду PLAN для CI"
```

**IMPORTANT:** Do NOT add:
- Detailed checklists
- Acceptance criteria
- Implementation steps
- Code examples or templates

These belong in the PRD created by PLAN command.

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

