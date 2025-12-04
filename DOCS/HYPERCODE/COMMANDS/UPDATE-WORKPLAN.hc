# UPDATE-WORKPLAN Command
# Version: 1.0.0
# Purpose: Mark selected task as in progress in Workplan

"UPDATE-WORKPLAN — Progress Tracking Update"
    "Version: 1.0.0"

    "Input"
        "Selected task ID"
        "DOCS/Workplan.md"

    "Algorithm"
        "Find task"
            "Locate task by ID in Workplan.md"
            "Parse task row format"

        "Mark as in progress"
            "Add **INPROGRESS** marker to task row"
            "Preserve existing formatting"
            "Keep priority and other metadata intact"

        "Save changes"
            "Write updated Workplan.md"
            "Maintain file structure"

    "Output"
        "DOCS/Workplan.md"
            "Updated with INPROGRESS marker on selected task"

    "Error Cases"
        "Task not found"
            "Return error with task ID"
        "Workplan file missing"
            "Return error requesting Workplan creation"
