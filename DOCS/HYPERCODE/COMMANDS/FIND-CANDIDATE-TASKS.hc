# FIND-CANDIDATE-TASKS Command
# Version: 2.0.0
# Purpose: Filter and identify candidate tasks from Workplan

"FIND-CANDIDATE-TASKS — Task Filtering Algorithm"
    "Version: 2.0.0"

    "Concepts"
        → DOCS/HYPERCODE/PRIMITIVES/workplan-file.md
        → DOCS/HYPERCODE/PRIMITIVES/task-status.md
        → DOCS/HYPERCODE/PRIMITIVES/task-priority.md
        → DOCS/HYPERCODE/PRIMITIVES/task-dependencies.md

    "Input"
        "DOCS/Workplan.md"

    "Algorithm"
        "Step 1: Filter by status"
            "Read all tasks from Workplan"
            "Keep only tasks with [ ] checkbox"
            "Skip completed [x] tasks"

        "Step 2: Check dependencies"
            "For each candidate task"
                "Read Dependencies field"
                "Verify each dependency has [x] status"
                "Skip if any dependency incomplete"

        "Step 3: Sort by priority"
            "Group by priority level (P0, P1, P2)"
            "P0 first, then P1, then P2"

        "Step 4: Break ties"
            "Within same priority level"
                "Prefer critical path tasks"
                "Use sequential order if needed"
                "Default to Track A for parallel tracks"

    "Output"
        "Selected task: first eligible task from sorted list"

    "Error Cases"
        "No available tasks → error with blocker suggestion"
