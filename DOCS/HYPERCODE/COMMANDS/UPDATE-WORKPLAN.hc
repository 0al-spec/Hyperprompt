# UPDATE-WORKPLAN Command
# Version: 2.0.0
# Purpose: Mark selected task as in progress in Workplan

"UPDATE-WORKPLAN — Progress Tracking Update"
    "Version: 2.0.0"

    "Concepts"
        → DOCS/HYPERCODE/PRIMITIVES/workplan-file.md
        → DOCS/HYPERCODE/PRIMITIVES/task-status.md

    "Input"
        "Selected task ID"
        "DOCS/Workplan.md"

    "Algorithm"
        "Step 1: Find task"
            "Locate task row by ID in Workplan.md"
            "Parse task row format"

        "Step 2: Mark as in progress"
            "Add **INPROGRESS** marker to task row"
            "Preserve existing formatting"
            "Keep priority and metadata intact"

        "Step 3: Save changes"
            "Write updated Workplan.md"
            "Maintain file structure"

    "Output"
        "DOCS/Workplan.md with INPROGRESS marker"

    "Error Cases"
        "Task not found → error with task ID"
        "Workplan missing → error requesting creation"
