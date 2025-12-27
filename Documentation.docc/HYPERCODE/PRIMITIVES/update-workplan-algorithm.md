# Update Workplan Algorithm

This algorithm marks the selected task as in progress in the Workplan.

## Steps

1. **Find task**
   - Locate task row by ID in Workplan.md
   - Parse task row format

2. **Mark as in progress**
   - Add `**INPROGRESS**` marker to task row
   - Preserve existing formatting
   - Keep priority and metadata intact

3. **Save changes**
   - Write updated Workplan.md
   - Maintain file structure

## Output

File: `DOCS/Workplan.md` with INPROGRESS marker on selected task

## Error Handling

- Task not found → return error with task ID
- Workplan file missing → return error requesting Workplan creation
