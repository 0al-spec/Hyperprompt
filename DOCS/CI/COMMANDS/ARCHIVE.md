# ARCHIVE — Archive Completed CI Tasks

**Version:** 1.0.0

## Purpose

Move completed CI PRDs from `CI/INPROGRESS/` to `CI/TASKS_ARCHIVE/` and remove from `next.md`. Counterbalance to SELECT.

## Philosophy

- Keep `CI/INPROGRESS/` clean (only active work)
- Preserve completed CI PRDs for reference
- Remove completed tasks from next.md (opposite of SELECT)
- Run periodically — not required after every task

---

## Input

- `DOCS/CI/Workplan.md` — source of truth (`[x]` = complete)
- `DOCS/CI/INPROGRESS/next.md` — remove completed task references
- `DOCS/CI/INPROGRESS/{TASK_ID}_{TASK_NAME}.md` — PRD files to archive

---

## Algorithm

### 1. Find Completed CI Tasks

- Scan `CI/INPROGRESS/*.md` for PRD files
- Check `CI/Workplan.md`: task marked `[x]`
- Skip if task currently active in `next.md` (not marked completed)
- Add to candidates

### 2. Archive Each Task

```bash
# Remove from next.md (counterbalance to SELECT)
sed -i "/^# Next Task: ${TASK_ID}/,/^# Next Task:/d" DOCS/CI/INPROGRESS/next.md

# Move PRD to archive
mv "DOCS/CI/INPROGRESS/${TASK_ID}_${TASK_NAME}.md" \
   "DOCS/CI/TASKS_ARCHIVE/${TASK_ID}_${TASK_NAME}.md"

# Add archive timestamp
echo "\n---\n**Archived:** ${DATE}" >> "DOCS/CI/TASKS_ARCHIVE/${TASK_ID}_${TASK_NAME}.md"
```

### 3. Update INDEX.md

Create/update `DOCS/CI/TASKS_ARCHIVE/INDEX.md` with links organized by phase:

```markdown
# Archived CI Tasks

## Phase 1: Discovery
- [CI-01 — Audit repository](./CI-01_Audit.md) ✓ 2025-12-03

## Phase 2: Workflow Skeleton
- [CI-02 — Define triggers](./CI-02_Define_Triggers.md) ✓ 2025-12-03
- [CI-03 — Configure environment](./CI-03_Configure_Environment.md) ✓ 2025-12-03
- [CI-07 — Set permissions](./CI-07_Set_Permissions.md) ✓ 2025-12-04

## Phase 3: Quality Gates
- [CI-04 — Add static analysis](./CI-04_Static_Analysis.md) ✓ 2025-12-04
- [CI-05 — Add test step](./CI-05_Test_Step.md) ✓ 2025-12-04
- [CI-06 — Implement retries](./CI-06_Retries.md) ✓ 2025-12-04

## Phase 4: Validation & Docs
- [CI-08 — Document CI](./CI-08_Documentation.md) ✓ 2025-12-05
- [CI-09 — Validate workflow](./CI-09_Validation.md) ✓ 2025-12-05
- [CI-10 — Enable status checks](./CI-10_Status_Checks.md) ✓ 2025-12-05
```

### 4. Commit

```bash
git add DOCS/CI/INPROGRESS/ DOCS/CI/TASKS_ARCHIVE/
git commit -m "Archive completed CI tasks: CI-01, CI-02, CI-03"
git push
```

---

## Execution Modes

**Auto (default):**
```bash
$ claude "Выполни команду ARCHIVE для CI"
```
Archives all completed CI tasks from Workplan.

**Specific task:**
```bash
$ claude "ARCHIVE CI task CI-01"
```
Archives only specified CI task.

**Dry run:**
```bash
$ claude "CI ARCHIVE: dry run"
```
Shows what would be archived without changes.

---

## Example Output

```bash
$ claude "Выполни команду ARCHIVE для CI"

╔════════════════════════════════════════════╗
║  ARCHIVE — Clean CI Workspace              ║
╚════════════════════════════════════════════╝

Found 3 completed CI tasks:
  [✓] CI-01 — Audit repository
  [✓] CI-02 — Define workflow triggers
  [✓] CI-03 — Configure Linux job environment

Archiving CI-01...
  ✓ Removed from next.md
  ✓ Moved to CI/TASKS_ARCHIVE/
  ✓ Added archive metadata

Archiving CI-02...
  ✓ Removed from next.md
  ✓ Moved to CI/TASKS_ARCHIVE/
  ✓ Added archive metadata

Archiving CI-03...
  ✓ Removed from next.md
  ✓ Moved to CI/TASKS_ARCHIVE/
  ✓ Added archive metadata

✓ Updated INDEX.md
✓ Committed and pushed

✅ Archived 3 CI tasks successfully

CI Workspace: 1 active task, 3 archived
```

---

## Error Handling

**No completed tasks:**
```
ℹ️  No CI tasks ready for archiving
All tasks in CI/INPROGRESS are either:
  - In progress (not marked [x] in CI/Workplan)
  - Currently active (being worked on in next.md)
```

**Active task:**
```
✗ Cannot archive CI-04 — Static Analysis
Reason: Currently active in next.md

Complete the task first, then archive.
```

**Not complete in Workplan:**
```
✗ Cannot archive CI-05 — Test Step
Reason: Not marked [x] in CI/Workplan

Complete task first.
```

---

## Workflow Integration

```
SELECT → PLAN → EXECUTE → CI task complete
                            ↓
                      [Multiple CI tasks done]
                            ↓
                         ARCHIVE ← Clean CI workspace
                            ↓
                         SELECT (next CI task)
```

**When to run:**
- After completing multiple CI tasks (batch cleanup)
- Before moving to next phase
- When CI/INPROGRESS/ becomes cluttered
- After CI is fully implemented and tested

---

## Notes

- Optional command — run periodically to keep CI workspace clean
- Counterbalance to SELECT (adds to next.md ↔ removes from next.md)
- Source of truth: CI/Workplan.md `[x]` markers
- Non-destructive: uses `mv`, creates git commit
- Recovery: `git revert` or `mv` file back from CI/TASKS_ARCHIVE/
- All 10 CI tasks will eventually be archived when CI setup is complete

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-03 | Claude | Adapted from main ARCHIVE for CI tasks |
