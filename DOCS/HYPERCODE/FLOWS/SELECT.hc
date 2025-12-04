# SELECT Flow
# Version: 2.0.0
# Purpose: Orchestrate next task selection from workplan

"SELECT — Next Task Selection Flow"
    "Version: 2.0.0"

    "Purpose"
        "Identify next task to work on"
        "Create minimal task metadata"
        "Update progress tracking"

    "Input Files"
        "DOCS/Workplan.md"
        "DOCS/INPROGRESS/next.md"

    "Execution Flow"
        "Step 1: Find Next Task"
            "DOCS/HYPERCODE/COMMANDS/FIND-CANDIDATE-TASKS.hc"
                "Filters tasks by status, dependencies, priority"
                "Returns highest priority eligible task"

        "Step 2: Create Task File"
            "DOCS/HYPERCODE/COMMANDS/CREATE-NEXT-FILE.hc"
                "Generates minimal next.md with metadata"
                "Prompts user to run PLAN command"

        "Step 3: Update Progress"
            "DOCS/HYPERCODE/COMMANDS/UPDATE-WORKPLAN.hc"
                "Marks selected task as INPROGRESS"
                "Saves updated Workplan"

    "Output Files"
        "DOCS/INPROGRESS/next.md"
            "Minimal task metadata only"
        "DOCS/WORKPLAN.md"
            "Updated with INPROGRESS marker"

    "Command Separation"
        "SELECT responsibility"
            "Which task to work on next"
            "Minimal metadata tracking"

        "PLAN responsibility"
            "Detailed implementation plan (PRD)"
            "Acceptance criteria and checklists"

        "EXECUTE responsibility"
            "Actual implementation work"
            "Validation and commits"

    "Next Step"
        "User should run: $ claude \"Выполни команду PLAN\""
