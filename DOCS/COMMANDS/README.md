# Hyperprompt Workflow Commands

**Version:** 1.0.0
**Date:** December 3, 2025

## Overview

This directory contains workflow commands for managing the Hyperprompt Compiler v0.1 development process. These commands implement a three-level task hierarchy with automated execution and progress tracking.

## Available Commands

| Command | Purpose | Input | Output |
|---------|---------|-------|--------|
| **SELECT** | Choose next task from Workplan | `Workplan.md` | `next.md` updated |
| **PLAN** | Generate PRD for current task | `next.md` | `{TASK_ID}_{TASK_NAME}.md` |
| **EXECUTE** | Implement current task | PRD + templates | Code, commits, updates |
| **PROGRESS** | Update task checklist | `next.md` | Checklist marked, % calculated |

## Complete Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    HYPERPROMPT WORKFLOW                      │
└─────────────────────────────────────────────────────────────┘

    [Start Project]
          ↓
    ┌─────────┐
    │ SELECT  │ ← Choose highest priority task from Workplan
    └────┬────┘   - Checks dependencies satisfied
         │        - Updates next.md with task details
         │        - Marks task as INPROGRESS in Workplan
         ↓
    next.md created
         │
         ↓
    ┌─────────┐
    │  PLAN   │ ← Generate detailed PRD
    └────┬────┘   - Reads next.md, Workplan, project specs
         │        - Creates atomic subtask breakdown
         │        - Defines acceptance criteria
         ↓
    PRD created: DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md
         │
         ↓
    ┌─────────┐
    │ EXECUTE │ ← Implement the task (MAIN COMMAND)
    └────┬────┘   - Creates files from templates
         │        - Runs build/test commands
         │        - Validates acceptance criteria
         │        - Auto-updates PROGRESS
         │        - Commits per phase
         │
         ├─────→ [Interactive Mode]
         │       ├─ Show subtask
         │       ├─ Execute actions
         │       ├─ Verify results
         │       └─ Ask: Continue? (y/n/skip/abort)
         │
         ├─────→ [Automatic commits]
         │       ├─ Phase 1 complete → commit
         │       ├─ Phase 2 complete → commit
         │       └─ Task complete → final commit
         │
         ↓
    Task completed
         │
         ├─────→ next.md marked complete ✓
         ├─────→ Workplan.md task marked [x]
         ├─────→ All changes pushed to remote
         │
         ↓
    ┌─────────┐
    │ SELECT  │ ← Choose next task (repeat cycle)
    └─────────┘

    [Loop continues until all tasks complete]
```

## Detailed Flow

### 1. SELECT Command

**When to use:** At the start of a new task, or after completing the previous one.

```bash
$ claude "Выполни команду SELECT"
```

**What it does:**
- Scans `Workplan.md` for available tasks
- Filters by: not completed, dependencies satisfied, highest priority
- Prefers critical path tasks when tied
- Updates `next.md` with selected task
- Marks task as **INPROGRESS** in Workplan

**Output:**
```markdown
# Next Task: A1 — Project Initialization

**Priority:** [P0] Critical
**Phase:** 1 — Foundation & Core Types
**Dependencies:** None (entry point)

## Description
Establish the foundational project structure...

## Tasks Checklist
- [ ] Create Swift package structure
- [ ] Configure Package.swift
...
```

---

### 2. PLAN Command

**When to use:** Immediately after SELECT, before starting implementation.

```bash
$ claude "Выполни команду PLAN"
```

**What it does:**
- Reads current task from `next.md`
- Gathers context from Workplan and project specs
- Applies PRD authoring rules (`01_PRD_PROMPT.md`)
- Generates comprehensive implementation-ready PRD

**Output:**
```
DOCS/INPROGRESS/A1_Project_Initialization.md
```

Contains:
- Scope and intent
- Hierarchical task breakdown (atomic subtasks)
- Metadata (priority, effort, tools)
- Acceptance criteria per subtask
- Functional/non-functional requirements
- Edge cases and error handling
- Implementation templates
- Quality enforcement checklist

---

### 3. EXECUTE Command (CORE)

**When to use:** After PLAN is generated, to implement the task.

```bash
$ claude "Выполни команду EXECUTE"
```

**What it does:**

**Phase 1: Preparation**
- Reads PRD for current task
- Parses task breakdown
- Checks dependencies
- Shows execution plan

**Phase 2: Execution (Interactive)**
For each phase in PRD:
  - Display phase goal
  - For each subtask:
    - Execute actions (create files, run commands)
    - Verify acceptance criteria
    - Mark in checklist ✓
    - Ask: Continue? (y/n/skip/abort)
  - Commit phase completion

**Phase 3: Verification**
- Run all acceptance tests
- Verify quality checklist
- Generate completion report

**Phase 4: Finalization**
- Mark task complete in next.md
- Update Workplan with [x]
- Create final commit
- Push to remote
- Suggest: "Run SELECT for next task"

**Smart Actions:**
- Parses PRD templates → executes them
- Creates directories: `mkdir -p Sources/{Core,Parser,...}`
- Writes files from templates: `Package.swift`, `main.swift`
- Runs commands: `swift build`, `swift test`
- Validates results against acceptance criteria

**Example output:**
```
╔════════════════════════════════════════════════════════════╗
║  EXECUTE: A1 — Project Initialization                      ║
╚════════════════════════════════════════════════════════════╝

PHASE 1: Directory Structure Creation

Subtask 1.1: Create Sources Directory Structure
🔧 Action: mkdir -p Sources/{Core,Parser,Resolver,Emitter,CLI,Statistics}
✅ Created: Sources/Core/
✅ Created: Sources/Parser/
...
✓ Verification: All 6 directories exist
✓ Updated checklist: [1/13 = 8%]

Continue to next subtask? [y/n]: y

... (continues through all subtasks)

✅ TASK COMPLETED: A1 — Project Initialization
📊 Subtasks: 13/13 (100%)
✓ Committed and pushed

🎯 Next: Run SELECT to choose A2
```

---

### 4. PROGRESS Command (Optional)

**When to use:** If you manually work on subtasks and want to update checklist.

```bash
$ claude "Выполни команду PROGRESS"
```

**What it does:**
- Reviews checklist in `next.md`
- Interactively asks about each uncompleted item
- Auto-detects completed work (files, tests)
- Updates `[ ]` → `[x]`
- Calculates progress percentage
- Commits progress snapshot

**Note:** EXECUTE calls PROGRESS automatically, so you rarely need this separately.

---

## Three-Level Task Hierarchy

### Level 1: Strategic (Workplan.md)

High-level phases and tasks:
```markdown
### A1: Project Initialization **[P0]** — 2 hours
- [ ] Create Swift package structure
- [ ] Configure dependencies
- [ ] Verify build system
```
**Granularity:** 3-5 items per task
**Purpose:** Strategic planning, dependency tracking

### Level 2: Tactical (next.md)

Detailed checklist for daily work:
```markdown
## Tasks Checklist

- [x] Create Sources/Core/ directory
- [x] Create Sources/Parser/ directory
- [ ] Create Sources/Resolver/ directory
- [ ] Configure Package.swift dependencies
- [ ] Run swift build
...
```
**Granularity:** 10-20 items per task
**Purpose:** Daily progress tracking

### Level 3: Operational (PRD)

Atomic subtasks with specifications:
```markdown
### Task 1.1: Create Sources Directory Structure
- **Input:** Empty project directory
- **Process:** mkdir -p Sources/{Core,Parser,Resolver,Emitter,CLI,Statistics}
- **Output:** Directory tree created
- **Acceptance:** All 6 directories exist with correct permissions
```
**Granularity:** One action per subtask
**Purpose:** Execution-ready specification

---

## Execution Modes

### Interactive Mode (Default, Recommended)

Pauses after each subtask for confirmation:
```bash
$ claude "Выполни команду EXECUTE"
```

**Best for:**
- Complex tasks
- First-time task execution
- Learning the workflow

### Phase-by-Phase Mode

Execute one phase at a time:
```bash
$ claude "Execute Phase 1"
$ claude "Execute Phase 2"
```

**Best for:**
- Large tasks (>4 hours)
- When interruptions expected
- Code review between phases

### Automatic Mode (USE WITH CAUTION)

Executes everything without interaction:
```bash
$ claude "Execute automatically"
```

**Best for:**
- Well-tested tasks
- Repeated executions
- CI/CD automation

### Dry Run Mode

Shows execution plan without changes:
```bash
$ claude "Dry run execute"
```

**Best for:**
- Understanding task scope
- Debugging workflow
- Planning time estimates

---

## File Structure

```
DOCS/
├── COMMANDS/              # This directory
│   ├── README.md          # This file
│   ├── SELECT.md          # Task selection
│   ├── PLAN.md            # PRD generation
│   ├── EXECUTE.md         # Task execution
│   └── PROGRESS.md        # Progress tracking
│
├── INPROGRESS/            # Active work
│   ├── next.md            # Current task (1 file only)
│   ├── A1_Project_Initialization.md   # PRD for A1
│   ├── A2_Core_Types.md               # PRD for A2 (when selected)
│   └── ...
│
├── Workplan.md            # Master task list
│
├── RULES/
│   └── 01_PRD_PROMPT.md   # PRD authoring rules
│
└── PRD/v0.0.1/            # Project specifications
    ├── 00_PRD_001.md
    ├── 01_DESIGN_SPEC_001.md
    └── 02_DESIGN_SPEC_SPECIFICATION_CORE.md
```

---

## Quick Start Guide

### Starting a New Task

```bash
# 1. Choose task
$ claude "Выполни команду SELECT"
# → Creates next.md with A1

# 2. Generate PRD
$ claude "Выполни команду PLAN"
# → Creates A1_Project_Initialization.md

# 3. Execute task (interactive)
$ claude "Выполни команду EXECUTE"
# → Implements A1, commits, pushes

# 4. Repeat for next task
$ claude "Выполни команду SELECT"
# → Chooses A2, cycle continues
```

### Checking Progress

```bash
# View current task
$ cat DOCS/INPROGRESS/next.md

# View PRD
$ cat DOCS/INPROGRESS/A1_Project_Initialization.md

# Check overall progress
$ grep -E "^\- \[.\]" DOCS/Workplan.md | wc -l  # Total tasks
$ grep -E "^\- \[x\]" DOCS/Workplan.md | wc -l  # Completed
```

### Resuming After Interruption

```bash
# Check current task
$ cat DOCS/INPROGRESS/next.md

# Resume execution
$ claude "Resume execution of A1"
# or just:
$ claude "Выполни команду EXECUTE"
```

---

## Safety Features

### Pre-flight Checks

Before EXECUTE runs:
- ✅ Git working tree is clean (no uncommitted changes)
- ✅ All dependencies verified
- ✅ PRD exists for current task
- ✅ User confirms execution plan

### Atomic Commits

Each phase commits independently:
```
Complete Phase 1: Directory Structure for A1
Complete Phase 2: Package Configuration for A1
Complete A1 — Project Initialization
```

### Rollback Support

If something fails:
- Changes committed per phase → can revert to last good state
- Can skip failed subtasks (mark as TODO)
- Can abort without losing work

### Validation Gates

Must pass to proceed:
- Acceptance criteria met
- Build succeeds (if applicable)
- Tests pass (if applicable)

---

## Error Handling

### Dependency Not Met

```
ERROR: Cannot execute A2 — dependencies not satisfied
Missing: A1 (Project Initialization)

Suggestion: Complete A1 first or update Workplan
```

### Build Failure

```
ERROR: swift build failed with 3 errors

1. Sources/Core/File.swift:10:5
   error: use of unresolved identifier 'foo'

Options:
  [r] Retry after fixing
  [s] Skip this subtask (mark as TODO)
  [a] Abort execution
```

### Acceptance Criteria Not Met

```
WARNING: Acceptance criteria not met for Subtask 2.3

Expected: Package.swift contains "swift-crypto"
Actual: Dependency not found

Options:
  [r] Retry this subtask
  [s] Skip (mark as known issue)
  [a] Abort execution
```

---

## Best Practices

### ✅ Do's

- Run SELECT at the start of each work session
- Generate PRD immediately after SELECT
- Use interactive mode for unfamiliar tasks
- Commit atomically per phase (EXECUTE does this)
- Review PRD before executing
- Verify acceptance criteria carefully

### ❌ Don'ts

- Don't skip PLAN (PRD is essential for EXECUTE)
- Don't use automatic mode for complex tasks
- Don't manually edit Workplan task order (breaks dependencies)
- Don't commit partial work outside EXECUTE (breaks atomicity)
- Don't skip acceptance criteria validation

---

## Troubleshooting

### "No PRD found for task A1"

**Solution:** Run `claude "Выполни команду PLAN"` first

### "Task already marked complete"

**Solution:** Run `claude "Выполни команду SELECT"` to choose next task

### "Dependencies not satisfied"

**Solution:** Complete prerequisite tasks first (check Workplan)

### "Git working tree not clean"

**Solution:** Commit or stash changes, then retry

### EXECUTE stuck in middle of task

**Solution:**
- Abort (type 'a' at next checkpoint)
- Resume later with same command
- Work committed per phase → no data loss

---

## Command Summary

| Command | Usage | When |
|---------|-------|------|
| SELECT | `claude "Выполни команду SELECT"` | Start new task |
| PLAN | `claude "Выполни команду PLAN"` | After SELECT |
| EXECUTE | `claude "Выполни команду EXECUTE"` | After PLAN |
| PROGRESS | `claude "Выполни команду PROGRESS"` | Manual progress update (optional) |

**Typical cycle time:**
- SELECT: 1 minute
- PLAN: 2-3 minutes
- EXECUTE: Task-dependent (A1 = 47 min, A2 = 4 hours)
- Total: ~2 hours for A1

---

## Future Enhancements

- **VERIFY** — Validate completed task against PRD
- **REVIEW** — Request code review before marking complete
- **ESTIMATE** — Improve time estimates using historical data
- **PARALLEL** — Execute independent tasks concurrently
- **ROLLBACK** — Undo phases if validation fails

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-03 | Claude | Initial workflow documentation |

---

**Questions?** Check individual command files:
- `SELECT.md` — Task selection algorithm
- `PLAN.md` — PRD generation rules
- `EXECUTE.md` — Execution details and modes
- `PROGRESS.md` — Progress tracking mechanics
