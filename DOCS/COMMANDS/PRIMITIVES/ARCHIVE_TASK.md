# ARCHIVE-TASK — Move Completed PRD

**Version:** 1.0

## Purpose

Perform the per-task steps of the ARCHIVE command: remove the reference from `next.md`, move the PRD from `INPROGRESS/` to `TASKS_ARCHIVE/`, and add the archive timestamp so the history remains traceable.

## Usage

1. Remove the completed entry from `DOCS/INPROGRESS/next.md`. Use a ranged `sed` deletion or edit manually to drop the section that starts with `# Next Task: {TASK_ID}` and ends right before the following `# Next Task:` or end of file.
2. Move the PRD:
   ```bash
   mv "DOCS/INPROGRESS/${TASK_ID}_${TASK_NAME}.md" "DOCS/TASKS_ARCHIVE/${TASK_ID}_${TASK_NAME}.md"
   ```
3. Record the archive timestamp:
   ```bash
   echo "\n---\n**Archived:** $(date '+%Y-%m-%d')" >> "DOCS/TASKS_ARCHIVE/${TASK_ID}_${TASK_NAME}.md"
   ```

## Guidelines

- Perform all three steps before touching the archive index so the file exists with the metadata entry in place.
- Double-check `next.md` after the edit to ensure only the intended block was removed.
- Keep the `TASK_ID_Task_Name` casing consistent between source and target paths.
