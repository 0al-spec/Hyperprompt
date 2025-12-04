# CREATE-NEXT-FILE Command
# Version: 1.0.0
# Purpose: Create minimal next.md file for selected task

"CREATE-NEXT-FILE — Generate Task Metadata File"
    "Version: 1.0.0"

    "Input"
        "Selected task from FIND-CANDIDATE-TASKS"
        "Task metadata from Workplan"

    "Algorithm"
        "Write task header"
            "Format: # Next Task: {TASK_ID} — {TASK_NAME}"

        "Add basic metadata"
            "Priority: P0/P1/P2"
            "Phase: {Phase Name}"
            "Effort: {Hours}"
            "Dependencies: {Task IDs or None}"
            "Status: Selected"

        "Add brief description"
            "Extract 1-2 sentences from Workplan"
            "Keep it minimal — no detailed plans"

        "Add next step prompt"
            "Tell user to run PLAN command"
            "Example: $ claude \"Выполни команду PLAN\""

    "Output"
        "DOCS/INPROGRESS/next.md"
            "Minimal task metadata only"
            "No checklists or implementation details"
            "Guides user to PLAN command"

    "Important"
        "Do NOT add acceptance criteria"
        "Do NOT add implementation steps"
        "Do NOT add code examples"
        "Keep file under 20 lines"
