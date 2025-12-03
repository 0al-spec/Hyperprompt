# PLAN — Generate PRD from CI Task

**Version:** 1.0.0

## Input
- `DOCS/CI/INPROGRESS/next.md` — current CI task
- `DOCS/RULES/01_PRD_PROMPT.md` — PRD rules (if applicable, otherwise use standard technical spec format)
- `DOCS/CI/Workplan.md` — CI task context
- `DOCS/CI/PRD.md` — CI project PRD
- Repository context (package.json, requirements.txt, etc. discovered in CI-01)

## Algorithm

1. **Extract task** from `next.md` (ID, name)
2. **Gather context** from `CI/Workplan.md` (priority, phase, dependencies, description, acceptance criteria)
3. **Apply CI-specific rules:**
   - Focus on GitHub Actions workflow implementation
   - Include Linux runner-specific configuration
   - Reference detected toolchain from CI-01 audit
   - Include path filters, triggers, caching strategies
   - Specify retry logic for network operations
   - Define permissions and secrets handling
4. **Generate** `DOCS/CI/INPROGRESS/{TASK_ID}_{TASK_NAME}.md` following technical specification structure

## Output
- PRD file at `DOCS/CI/INPROGRESS/{TASK_ID}_{TASK_NAME}.md`

## CI-Specific PRD Structure

```markdown
# {TASK_ID} — {TASK_NAME}

## 1. Context
- Phase: {Discovery/Workflow Skeleton/Quality Gates/Validation}
- Priority: {High/Medium}
- Dependencies: {List from Workplan}
- Effort: {Hours from Workplan}

## 2. Objectives
{Specific goals for this CI task}

## 3. Implementation Plan
{Step-by-step breakdown}

## 4. Acceptance Criteria
{From Workplan + additional validation steps}

## 5. GitHub Actions Specifics
- Runner: ubuntu-latest
- Triggers: {from CI-02}
- Path filters: {from CI-02}
- Caching strategy: {from CI-03}
- Toolchain: {from CI-01 audit}

## 6. Testing & Validation
{How to verify this CI step works}

## 7. Rollback Plan
{If CI breaks, how to revert}
```

## Exceptions
- No task in `next.md` → Exit with verbose error
- Task not in CI Workplan → Exit with verbose error
- PRD exists → Use --overwrite or --append
- Insufficient context → Refer to CI-01 audit results or manual enrichment needed
- Pre-CI-01 tasks → Warn that toolchain info may be incomplete
