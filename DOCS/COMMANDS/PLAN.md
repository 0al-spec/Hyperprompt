# PLAN — Detailed Task Execution Plan Creation

## Goal

Transform a brief task from `next.md` into a comprehensive PRD (Product Requirements Document) with a detailed execution plan, applying rules from `DOCS/RULES/01_PRD_PROMPT.md`.

## Input Data

- **Current Task:** `/home/user/Hyperprompt/DOCS/INPROGRESS/next.md` — current task (ID and name)
- **PRD Rules:** `/home/user/Hyperprompt/DOCS/RULES/01_PRD_PROMPT.md` — PRD creation rules
- **Workplan:** `/home/user/Hyperprompt/DOCS/Workplan.md` — task context from overall plan

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

Read `DOCS/RULES/01_PRD_PROMPT.md` and apply all rules for creating a detailed plan:

1. **Define scope and intent**
   - Restate task objective in precise terms
   - Define deliverables and success criteria
   - Note constraints, assumptions, dependencies

2. **Decompose into hierarchical TODO plan**
   - Break down into atomic, verifiable subtasks
   - For each subtask define: input, process, output
   - Group by logical categories
   - Explicitly state dependencies and parallelization opportunities

3. **Enrich with metadata**
   - Priority (High / Medium / Low)
   - Effort estimate (time or complexity)
   - Required tools, frameworks, APIs, datasets
   - Acceptance criteria and verification methods

4. **Create PRD sections**
   - Feature description and rationale
   - Functional requirements
   - Non-functional requirements (performance, scalability, security)
   - User interaction flows (if applicable)
   - Edge cases and failure scenarios

5. **Apply quality rules**
   - Avoid vague language
   - Each step must be actionable without external interpretation
   - Maintain terminology consistency

### Step 4: Generate PRD File

Create file `/home/user/Hyperprompt/DOCS/INPROGRESS/{TASK_ID}.md` with the following structure:

```markdown
# {TASK_ID}: {TASK_NAME}

**Priority:** {PRIORITY}
**Phase:** {PHASE_NUMBER} — {PHASE_NAME}
**Track:** {TRACK_ID} (Track Name)
**Estimated Time:** {HOURS} hours
**Dependencies:** {DEPENDENCIES_LIST}
**Status:** Planning Complete

---

## 1. Scope & Intent

### Objective
{Precise, unambiguous restatement of the task objective}

### Deliverables
- {Deliverable 1}
- {Deliverable 2}

### Success Criteria
- {Criterion 1}
- {Criterion 2}

### Constraints
- {Constraint 1}
- {Constraint 2}

### Assumptions
- {Assumption 1}

### External Dependencies
- {Dependency 1}

---

## 2. Hierarchical TODO Plan

### Phase 2.1: {Phase Name}
**Priority:** High | Medium | Low
**Estimated:** {hours}h
**Dependencies:** None | {task_ids}

- [ ] **Task 2.1.1:** {Task description}
  - **Input:** {What is needed to start}
  - **Process:** {What to do}
  - **Output:** {Expected result}
  - **Acceptance:** {How to verify}
  - **Effort:** {time estimate}

- [ ] **Task 2.1.2:** {Task description}
  - **Input:** {What is needed to start}
  - **Process:** {What to do}
  - **Output:** {Expected result}
  - **Acceptance:** {How to verify}
  - **Effort:** {time estimate}

### Phase 2.2: {Phase Name}
{...}

**Parallelization Opportunities:**
- Tasks 2.1.1 and 2.1.2 can run in parallel
- Phase 2.2 can start after Task 2.1.1 completes

---

## 3. Execution Metadata

| Task ID | Priority | Effort | Tools/Frameworks | Verification Method |
|---------|----------|--------|------------------|---------------------|
| 2.1.1   | High     | 2h     | Swift, XCTest    | Unit tests pass     |
| 2.1.2   | Medium   | 1h     | Git              | Files committed     |

---

## 4. Requirements

### 4.1 Functional Requirements

**FR1:** {Requirement description}
- **Details:** {Implementation details}
- **Acceptance:** {How to verify}

**FR2:** {Requirement description}
- **Details:** {Implementation details}
- **Acceptance:** {How to verify}

### 4.2 Non-Functional Requirements

**NFR1 — Performance:**
- {Performance requirement}

**NFR2 — Scalability:**
- {Scalability requirement}

**NFR3 — Security:**
- {Security requirement}

**NFR4 — Compatibility:**
- {Compatibility requirement}

---

## 5. Interaction Flows

### Flow 5.1: {Flow name}
```
1. {Step 1}
2. {Step 2}
3. {Step 3}
```

---

## 6. Edge Cases & Failure Scenarios

### Case 6.1: {Edge case name}
**Scenario:** {Description}
**Expected Behavior:** {How to handle}
**Mitigation:** {Prevention strategy}

### Case 6.2: {Failure scenario}
**Scenario:** {Description}
**Expected Behavior:** {How to handle}
**Recovery:** {Recovery strategy}

---

## 7. Verification Plan

### 7.1 Unit Tests
- [ ] {Test description}
- [ ] {Test description}

### 7.2 Integration Tests
- [ ] {Test description}
- [ ] {Test description}

### 7.3 Manual Verification
- [ ] {Verification step}
- [ ] {Verification step}

---

## 8. Definition of Done

Task is considered complete when:
- [ ] All TODO items checked off
- [ ] All functional requirements met
- [ ] All non-functional requirements satisfied
- [ ] All tests passing
- [ ] Code reviewed (if applicable)
- [ ] Documentation updated
- [ ] No known blockers remain

---

## 9. References

- **Workplan:** `/home/user/Hyperprompt/DOCS/Workplan.md` (Phase {N}, Section {TASK_ID})
- **PRD Authoring Rules:** `/home/user/Hyperprompt/DOCS/RULES/01_PRD_PROMPT.md`
- **Related Tasks:** {List of related task IDs}
- **Critical Path:** {Position on critical path, if applicable}

---

**Document Version:** 1.0
**Created:** {date}
**Status:** Ready for Execution
```

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

## Workflow Integration

### Typical workflow:

1. **SELECT** → Choose next task from Workplan
2. **PLAN** → Create detailed PRD for task
3. **EXECUTE** → Execute tasks from PRD
4. **VERIFY** → Check Definition of Done
5. **COMPLETE** → Mark task as completed

### Usage example:

```bash
# 1. Select task
$ SELECT
✅ Selected: A2 — Core Types Implementation

# 2. Create detailed plan
$ PLAN
✅ PRD created: DOCS/INPROGRESS/A2.md
📊 23 atomic tasks identified

# 3. Start execution
$ cat DOCS/INPROGRESS/A2.md
# Read the detailed plan and start executing...
```

---

**Version:** 1.0.0
**Date:** 2025-12-02
**Status:** Active
