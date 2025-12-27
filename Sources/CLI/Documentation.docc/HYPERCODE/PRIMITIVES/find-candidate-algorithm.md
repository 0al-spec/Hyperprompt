# Find Candidate Tasks Algorithm

This algorithm filters and selects the next task from the Workplan.

## Steps

1. **Filter by status**
   - Read all tasks from Workplan
   - Keep only tasks with `[ ]` checkbox
   - Skip completed `[x]` tasks

2. **Check dependencies**
   - For each candidate task, read Dependencies field
   - Verify each dependency has `[x]` status
   - Skip if any dependency incomplete

3. **Sort by priority**
   - Group by priority level (P0, P1, P2)
   - P0 first, then P1, then P2

4. **Break ties**
   - Within same priority level:
     - Prefer critical path tasks
     - Use sequential order if needed
     - Default to Track A for parallel tracks

## Output

Selected task: first eligible task from sorted list

## Error Handling

If no available tasks → return error suggesting review of blockers
