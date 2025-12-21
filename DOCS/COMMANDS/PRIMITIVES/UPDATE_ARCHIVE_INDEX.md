# UPDATE-ARCHIVE-INDEX — Refresh Archive Index

**Version:** 1.0

## Purpose

Keep `DOCS/TASKS_ARCHIVE/INDEX.md` in sync with newly archived tasks by inserting their entries under the correct phase, updating statistics, and preserving the historical metadata.

## Usage

1. Open `DOCS/TASKS_ARCHIVE/INDEX.md` and locate the phase section that corresponds to the archived task.
2. Append a list item with a short description, links to the PRD/summary, completion date, and effort and dependency notes if desired. Follow the existing formatting (bullet list, `✓ date`, references via relative links).
3. Refresh the Statistics block at the bottom:
   - Increase **Total Archived** by one.
   - Add the new duration to **Total Effort** (if tracking per task).
   - Keep the **Phases Represented** line accurate.

## Guidelines

- Maintain the chronological order within each phase.
- Preserve the separator blocks (`---`) between sections.
- If the phase section does not yet exist, create it before adding the entry (copy the existing block structure).
