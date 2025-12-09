# ARCHIVE — Archive Completed Tasks

**Version:** 2.0.0

## Purpose

Move completed PRDs from `INPROGRESS/` to `TASKS_ARCHIVE/` and remove from `next.md`. Counterbalance to SELECT.

## Philosophy

- Keep `INPROGRESS/` clean (only active work)
- Preserve completed PRDs for reference
- Remove completed tasks from next.md (opposite of SELECT)
- Run periodically — not required after every task

---

## Input

- `DOCS/Workplan.md` — source of truth (`[x]` = complete)
- `DOCS/INPROGRESS/next.md` — remove completed task references
- `DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md` — PRD files to archive

---

## Algorithm

### 1. Find Completed Tasks

- Scan `INPROGRESS/*.md` for PRD files
- Check `Workplan.md`: task marked `[x]`
- Add to candidates (will remove from `next.md` if present)
- Archive regardless of whether task is currently active in `next.md`

### 2. Archive Each Task

```bash
# Remove from next.md (counterbalance to SELECT)
sed -i "/^# Next Task: ${TASK_ID}/,/^# Next Task:/d" DOCS/INPROGRESS/next.md

# Move PRD to archive
mv "DOCS/INPROGRESS/${TASK_ID}_${TASK_NAME}.md" \
   "DOCS/TASKS_ARCHIVE/${TASK_ID}_${TASK_NAME}.md"

# Add archive timestamp
echo "\n---\n**Archived:** ${DATE}" >> "DOCS/TASKS_ARCHIVE/${TASK_ID}_${TASK_NAME}.md"
```

### 3. Update INDEX.md

Create/update `DOCS/TASKS_ARCHIVE/INDEX.md` with links organized by phase:

```markdown
# Archived Tasks

## Phase 1: Foundation
- [A1 — Project Initialization](./A1_Project_Initialization.md) ✓ 2025-12-03
- [A2 — Core Types](./A2_Core_Types.md) ✓ 2025-12-04
```

### 4. Commit

```bash
git add DOCS/INPROGRESS/ DOCS/TASKS_ARCHIVE/
git commit -m "Archive completed tasks: A1, A2"
git push
```

---

## Execution Modes

**Auto (default):**
```bash
$ claude "Выполни команду ARCHIVE"
```
Archives all completed tasks from Workplan.

**Specific task:**
```bash
$ claude "ARCHIVE task A1"
```
Archives only specified task.

**Dry run:**
```bash
$ claude "ARCHIVE: dry run"
```
Shows what would be archived without changes.

---

## Example Output

```bash
$ claude "Выполни команду ARCHIVE"

╔════════════════════════════════════════════╗
║  ARCHIVE — Clean Workspace                 ║
╚════════════════════════════════════════════╝

Found 2 completed tasks:
  [✓] A1 — Project Initialization
  [✓] A2 — Core Types Implementation

Archiving A1...
  ✓ Removed from next.md
  ✓ Moved to TASKS_ARCHIVE/
  ✓ Added archive metadata

Archiving A2...
  ✓ Removed from next.md
  ✓ Moved to TASKS_ARCHIVE/
  ✓ Added archive metadata

✓ Updated INDEX.md
✓ Committed and pushed

✅ Archived 2 tasks successfully

Workspace: 1 active task, 2 archived
```

---

## Error Handling

**No completed tasks:**
```
ℹ️  No tasks ready for archiving
All tasks in INPROGRESS are either:
  - In progress (not marked [x] in Workplan)
  - Currently active (being worked on in next.md)
```

**Active task:**
```
✗ Cannot archive A3 — Domain Types
Reason: Currently active in next.md

Complete the task first, then archive.
```

**Not complete in Workplan:**
```
✗ Cannot archive A4 — Parser
Reason: Not marked [x] in Workplan

Complete task first.
```

---

## Workflow Integration

```
SELECT → PLAN → EXECUTE → Task complete
                            ↓
                      [Time passes, multiple tasks done]
                            ↓
                         ARCHIVE ← Clean workspace
                            ↓
                         SELECT (next task)
```

**When to run:**
- After completing multiple tasks (batch cleanup)
- Before starting new phase
- When INPROGRESS/ becomes cluttered
- End of sprint/milestone

---

## Notes

- Optional command — run periodically to keep workspace clean
- Counterbalance to SELECT (adds to next.md ↔ removes from next.md)
- Source of truth: Workplan.md `[x]` markers
- Non-destructive: uses `mv`, creates git commit
- Recovery: `git revert` or `mv` file back from TASKS_ARCHIVE/

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 2.0.0 | 2025-12-03 | Claude | Simplified (50% shorter), clarified next.md logic |
| 1.0.0 | 2025-12-03 | Claude | Initial version |
