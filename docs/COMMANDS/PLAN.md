# PLAN — Generate PRD from Task

**Version:** 1.0.0

## Input
- `DOCS/INPROGRESS/next.md` — current task
- `DOCS/RULES/01_PRD_PROMPT.md` — PRD rules
- `DOCS/Workplan.md` — task context
- `DOCS/PRD/v0.0.1/00_PRD_001.md` — project PRD
- `DOCS/PRD/PRD_EditorEngine.md` — future EditorEngine module PRD
- `DOCS/PRD/v0.0.1/01_DESIGN_SPEC_001.md` — design spec
- `DOCS/PRD/v0.0.1/02_DESIGN_SPEC_SPECIFICATION_CORE.md` — SpecCore spec

## Algorithm

1. **Extract task** from `next.md` (ID, name)
2. **Gather context** from `Workplan.md` (priority, phase, dependencies, description)
3. **Apply rules** from `01_PRD_PROMPT.md`
4. **Generate** `DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md` following `01_PRD_PROMPT.md` structure

## Output
- PRD file at `DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md`

## Exceptions
- No task in `next.md` → Exit with verbose error
- Task not in Workplan → Exit with verbose error
- PRD exists → Use --overwrite or --append
- Insufficient context → Manual enrichment needed
