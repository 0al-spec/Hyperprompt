# SELECT — Next Task Selection

## Goal

Automatically select the next optimal task from the workplan (`DOCS/Workplan.md`) based on priorities, dependencies, and current progress.

## Input Data

- **Workplan:** `/home/user/Hyperprompt/DOCS/Workplan.md` — main work plan with hierarchy of phases and tasks
- **Current Task:** `/home/user/Hyperprompt/DOCS/INPROGRESS/next.md` — current task in progress

## Selection Algorithm

### Step 1: Determine Current Task Status

1. Read `DOCS/INPROGRESS/next.md`
2. Extract current task ID (e.g., `A1`, `A2`, `B1`, etc.)
3. Check in `DOCS/Workplan.md` if the task is marked as completed `[x]`

**If task is not completed:** Stop command execution and report that the current task is still in progress.

**If task is completed:** Continue to Step 2.

### Step 2: Find Candidates for Next Task

Scan `DOCS/Workplan.md` and select tasks that satisfy **all** conditions:

#### Condition 0: Task Not Completed
```markdown
- [ ] ❌ NOT completed (empty checkbox)
- [x] ✅ Completed (exclude)
```

#### Condition 1: Dependencies Satisfied

For each task, check the **Dependencies:** field
- If `Dependencies: None` → ✅ ready for execution
- If `Dependencies: A1` → verify that task A1 is marked `[x]` in Workplan
- If `Dependencies: A1, A2` → verify that **all** dependencies are completed

#### Condition 2: Priority

Tasks have three priority levels:
- **[P0] Critical** — critically important, blocks entire project
- **[P1] High** — important for core functionality
- **[P2] Medium** — nice-to-have, can be deferred

**Rule:** Among candidates, select the task with **highest priority** (P0 > P1 > P2).

#### Condition 3: Critical Path

If multiple tasks have the same priority, prefer tasks on the **critical path**:
```
A1 → A2 → A4 → B4 → C2 → D2 → E1 → Release
```

Tasks on the critical path are marked in comments or described in the `## 📊 Critical Path Analysis` section.

#### Condition 4: Sequential Order in Plan

If equivalent candidates remain, select the task that is **closest** to the last completed task in linear Workplan order.

### Step 3: Generate next.md

After selecting a task, create file `/home/user/Hyperprompt/DOCS/INPROGRESS/next.md` with minimal information:

```markdown
# {TASK_ID} — {TASK_NAME}
```

**Example:**
```markdown
# A2 — Core Types Implementation
```

### Step 4: Update Workplan.md

Mark the selected task as **in progress**:

**Before:**
```markdown
### A2: Core Types Implementation **[P0]**
**Dependencies:** A1
```

**After:**
```markdown
### A2: Core Types Implementation **[P0]** **INPROGRESS**
**Dependencies:** A1 ✅
```

## Output Data

1. **Updated file:** `/home/user/Hyperprompt/DOCS/INPROGRESS/next.md`
2. **Updated Workplan:** Task marked with `**INPROGRESS**` marker
3. **Console report:**
   ```
   ✅ Selected next task: A2 — Core Types Implementation [P0]
   📍 Phase: 1 — Foundation & Core Types
   ⏱️  Estimated: 4 hours
   🔗 Dependencies: A1 ✅
   📄 Details: /home/user/Hyperprompt/DOCS/INPROGRESS/next.md
   ```

## Exceptions and Edge Cases

### Case 1: No Available Tasks
If all tasks are either completed or blocked by dependencies:
```
⚠️  No available tasks found.
   Reason: All tasks are either completed or blocked by dependencies.
   Action: Review Workplan.md for potential circular dependencies.
```

### Case 2: Multiple P0 Tasks
If multiple tasks with priority [P0] are found, select the first one on the **critical path**.

### Case 3: Parallel Tracks
Workplan contains two independent tracks (A: Core Compiler, B: Specifications). If tasks from different tracks have the same priority, prefer **Track A** (critical path).

### Case 4: Current Task Not Completed
If a task exists in `next.md` but is not marked `[x]` in Workplan:
```
⚠️  Current task A1 is still in progress.
   Action: Complete current task before selecting next.
   Use: COMPLETE command to mark task as done.
```

## Checklist

Before executing the command, ensure:

- [ ] Current task in `next.md` is actually completed?
- [ ] Workplan is up to date and contains all dependencies?
- [ ] Critical path is considered in selection?
- [ ] If parallel tracks exist, correct track is selected?

---

**Version:** 1.0.0
**Date:** 2025-12-02
**Status:** Active
