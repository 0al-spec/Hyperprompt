# CREATE-NEXT-FILE Command
# Version: 3.0.0
# Purpose: Create minimal next.md file for selected task

"CREATE-NEXT-FILE — Generate Task Metadata File"
    "Version: 3.0.0"

    "Concepts"
        "DOCS/HYPERCODE/PRIMITIVES/next-file.md"

    "Input: Selected task from FIND-CANDIDATE-TASKS + Workplan metadata"

    "Algorithm"
        "Write header: # Next Task: {TASK_ID} — {TASK_NAME}"
        "Add metadata: Priority, Phase, Effort, Dependencies, Status"
        "Add brief description: 1-2 sentences from Workplan"
        "Add next step: Run PLAN command"

    "Output: DOCS/INPROGRESS/next.md"

    "Constraints: <20 lines, no implementation details, just metadata"
