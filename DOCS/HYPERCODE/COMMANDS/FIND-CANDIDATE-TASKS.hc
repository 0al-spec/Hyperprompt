# FIND-CANDIDATE-TASKS Command
# Version: 3.0.0
# Purpose: Filter and identify candidate tasks from Workplan

"FIND-CANDIDATE-TASKS — Task Filtering Algorithm"
    "Version: 3.0.0"

    "Concepts"
        "DOCS/HYPERCODE/PRIMITIVES/workplan-file.md"
        "DOCS/HYPERCODE/PRIMITIVES/task-status.md"
        "DOCS/HYPERCODE/PRIMITIVES/task-priority.md"
        "DOCS/HYPERCODE/PRIMITIVES/task-dependencies.md"

    "Input: DOCS/Workplan.md"

    "Algorithm"
        "Filter by status: keep [ ] tasks, skip [x] completed"
        "Check dependencies: verify all deps marked [x]"
        "Sort by priority: P0 → P1 → P2"
        "Break ties: critical path → sequential order → Track A"

    "Output: First eligible task from sorted list"

    "Error: No available tasks → suggest review blockers"
