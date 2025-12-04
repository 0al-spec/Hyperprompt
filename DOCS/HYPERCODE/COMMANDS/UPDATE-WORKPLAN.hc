# UPDATE-WORKPLAN Command
# Version: 3.0.0
# Purpose: Mark selected task as in progress in Workplan

"UPDATE-WORKPLAN — Progress Tracking Update"
    "Version: 3.0.0"

    "Concepts"
        "DOCS/HYPERCODE/PRIMITIVES/workplan-file.md"
        "DOCS/HYPERCODE/PRIMITIVES/task-status.md"

    "Input: Selected task ID + DOCS/Workplan.md"

    "Algorithm"
        "Find task row by ID in Workplan.md"
        "Add **INPROGRESS** marker, preserve formatting"
        "Write updated Workplan.md"

    "Output: DOCS/Workplan.md with INPROGRESS marker"

    "Error: Task not found OR Workplan missing"
