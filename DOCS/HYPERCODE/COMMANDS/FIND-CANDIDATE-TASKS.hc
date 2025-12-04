# FIND-CANDIDATE-TASKS Command
# Version: 1.0.0
# Purpose: Filter and identify candidate tasks from Workplan

"FIND-CANDIDATE-TASKS — Task Filtering Algorithm"
    "Version: 1.0.0"

    "Input"
        "DOCS/Workplan.md"
            "Project tasks with priorities and dependencies"

    "Algorithm"
        "Filter by status"
            "Task checkbox must be [ ] not [x]"
            "Skip completed tasks"

        "Check dependencies"
            "Read Dependencies field from task"
            "Verify each dependency marked [x] in Workplan"
            "Skip tasks with incomplete dependencies"

        "Apply priority ordering"
            "P0 tasks — highest priority"
            "P1 tasks — medium priority"
            "P2 tasks — lowest priority"

        "Break ties"
            "Prefer critical path tasks"
            "Use sequential order if still tied"
            "Default to Track A in parallel tracks"

    "Output"
        "List of eligible tasks sorted by priority"
        "Selected task: first task in sorted list"

    "Error Cases"
        "No available tasks"
            "Return error message"
            "Suggest reviewing Workplan for blockers"
