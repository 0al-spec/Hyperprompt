# PLAN — Detailed Task Execution Plan Creation

## Goal

Transform a brief task from `next.md` into a comprehensive PRD (Product Requirements Document) with a detailed execution plan, applying rules from `DOCS/RULES/01_PRD_PROMPT.md`.

## Input Data

- **Current Task:** `/home/user/Hyperprompt/DOCS/INPROGRESS/next.md` — current task (ID and name)
- **PRD Rules:** `/home/user/Hyperprompt/DOCS/RULES/01_PRD_PROMPT.md` — PRD creation rules
- **Workplan:** `/home/user/Hyperprompt/DOCS/Workplan.md` — task context from overall plan
- **Project PRD:** `/home/user/Hyperprompt/DOCS/PRD/v0.0.1/00_PRD_001.md` — project requirements document
- **Design Specs:**
  - `/home/user/Hyperprompt/DOCS/PRD/v0.0.1/01_DESIGN_SPEC_001.md` — core design specification
  - `/home/user/Hyperprompt/DOCS/PRD/v0.0.1/02_DESIGN_SPEC_SPECIFICATION_CORE.md` — SpecificationCore integration spec

## Plan Creation Algorithm

### Step 1: Extract Task Information

1. Read `DOCS/INPROGRESS/next.md`
2. Extract task ID (e.g., `A1`, `A2`, `B1`)
3. Extract task name (e.g., `Project Initialization`, `Core Types Implementation`)

### Step 2: Gather Context from Workplan

1. Find task in `DOCS/Workplan.md` by ID
2. Extract full information:
   - Priority (`[P0]`, `[P1]`, `[P2]`)
   - Phase and track
   - Time estimate
   - Dependencies
   - Task description
   - Subtask list (if any)
   - Acceptance criteria (if any)

### Step 3: Apply PRD Rules

Read `DOCS/RULES/01_PRD_PROMPT.md` and apply all authoring rules to transform the task into an implementation-ready PRD:

- Follow the 6-step process defined in PRD authoring rules
- Ensure output is self-contained, unambiguous, and machine-readable
- Structure the plan for direct execution by LLM agents without human clarification

### Step 4: Generate PRD File

Create file `/home/user/Hyperprompt/DOCS/INPROGRESS/{TASK_ID}.md` following the structure defined in `01_PRD_PROMPT.md`:

**Required sections:**
1. Scope & Intent (objective, deliverables, success criteria, constraints, assumptions)
2. Hierarchical TODO Plan (atomic tasks with input/process/output/acceptance/effort)
3. Execution Metadata (table with priorities, effort, tools, verification)
4. Requirements (functional and non-functional)
5. Interaction Flows (if applicable)
6. Edge Cases & Failure Scenarios
7. Verification Plan (unit tests, integration tests, manual verification)
8. Definition of Done (completion checklist)
9. References (Workplan, PRD rules, Project PRD, Design Specs, related tasks)

**Output format:** Machine- and human-readable Markdown with tables, lists, and headings

### Step 5: Update next.md (Optional)

Optionally add a reference to the created PRD file in `next.md`:

```markdown
# {TASK_ID} — {TASK_NAME}

**PRD:** `/home/user/Hyperprompt/DOCS/INPROGRESS/{TASK_ID}.md`
```

## Output Data

1. **PRD file:** `/home/user/Hyperprompt/DOCS/INPROGRESS/{TASK_ID}.md`
2. **Console report:**
   ```
   ✅ PRD created for task: A2 — Core Types Implementation
   📄 Location: /home/user/Hyperprompt/DOCS/INPROGRESS/A2.md
   📊 Structure:
      - 8 hierarchical phases
      - 23 atomic tasks
      - 12 acceptance criteria
      - 5 edge cases documented
   ⏱️  Total estimated effort: 4 hours
   🚀 Status: Ready for execution
   ```

## Exceptions and Edge Cases

### Case 1: next.md Empty or Missing
```
⚠️  No current task found in next.md
   Action: Run SELECT command first to choose a task
```

### Case 2: Task Not Found in Workplan
```
⚠️  Task {TASK_ID} not found in Workplan.md
   Action: Verify task ID is correct and exists in Workplan
```

### Case 3: PRD File Already Exists
```
⚠️  PRD file already exists: DOCS/INPROGRESS/{TASK_ID}.md
   Options:
   - Use --overwrite flag to replace existing PRD
   - Use --append flag to add to existing PRD
   - Use different filename
```

### Case 4: Insufficient Context in Workplan
```
⚠️  Insufficient context in Workplan for task {TASK_ID}
   Action: PRD created with basic structure, manual enrichment needed
   Note: Review and expand sections marked with [TODO]
```

## Checklist

Before executing the command, ensure:

- [ ] Task selected via SELECT and present in `next.md`?
- [ ] Sufficient context about task from Workplan?
- [ ] PRD rules in `01_PRD_PROMPT.md` are up to date?
- [ ] Ready for detailed task planning?

---

**Version:** 1.0.0
**Date:** 2025-12-02
**Status:** Active
