# CREATE-NEXT-FILE Command
# Version: 2.0.0
# Purpose: Create minimal next.md file for selected task

"CREATE-NEXT-FILE — Generate Task Metadata File"
    "Version: 2.0.0"

    "Concepts"
        → DOCS/HYPERCODE/PRIMITIVES/next-file.md

    "Input"
        "Selected task from FIND-CANDIDATE-TASKS"
        "Task metadata from Workplan"

    "Algorithm"
        "Step 1: Write task header"
            "Format: # Next Task: {TASK_ID} — {TASK_NAME}"

        "Step 2: Add metadata section"
            "Priority: P0/P1/P2"
            "Phase: {Phase Name}"
            "Effort: {Hours}"
            "Dependencies: {Task IDs or None}"
            "Status: Selected"

        "Step 3: Add description"
            "Extract 1-2 sentences from Workplan"
            "Keep it brief and clear"

        "Step 4: Add next step"
            "Tell user to run PLAN command"
            "Example: $ claude \"Выполни команду PLAN\""

    "Output"
        "DOCS/INPROGRESS/next.md"

    "Constraints"
        "Keep file under 20 lines"
        "No implementation details"
        "No checklists or criteria"
        "Just metadata and PLAN pointer"
