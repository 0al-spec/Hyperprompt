# Create Next File Algorithm

This algorithm generates the minimal `next.md` file for the selected task.

## Steps

1. **Write task header**
   - Format: `# Next Task: {TASK_ID} — {TASK_NAME}`

2. **Add metadata section**
   - Priority: P0/P1/P2
   - Phase: {Phase Name}
   - Effort: {Hours}
   - Dependencies: {Task IDs or None}
   - Status: Selected

3. **Add brief description**
   - Extract 1-2 sentences from Workplan
   - Keep it brief and clear

4. **Add next step prompt**
   - Tell user to run PLAN command
   - Example: `$ claude "Выполни команду PLAN"`

## Output

File: `DOCS/INPROGRESS/next.md`

## Constraints

- Keep file under 20 lines
- No implementation details
- No checklists or acceptance criteria
- Just metadata and pointer to PLAN command
