# Task Dependencies

Dependencies define which tasks must be completed before a task can start.

## Format

In Workplan, dependencies are listed in the task definition:
```
Dependencies: TASK-001, TASK-002
```

Or if no dependencies:
```
Dependencies: None
```

## Rules

1. A task can only be selected if **all** its dependencies are completed
2. Check that each dependency has **[x]** status in Workplan
3. Tasks with incomplete dependencies are skipped during selection
4. Circular dependencies are not allowed and will cause errors
