# Command Separation

The Hyperprompt workflow is divided into three distinct commands:

## SELECT
- **Purpose:** Identify which task to work on next
- **Output:** Minimal task metadata file (next.md)
- **Action:** Update progress tracking in Workplan

## PLAN
- **Purpose:** Generate detailed implementation plan (PRD)
- **Output:** Acceptance criteria and step-by-step checklist
- **Action:** Prepare everything needed for implementation

## EXECUTE
- **Purpose:** Perform the actual implementation work
- **Output:** Working code, tests, documentation
- **Action:** Validate against criteria and commit changes

Each command has a single, clear responsibility in the workflow.
