# FLOW — Iterative Development Workflow

**Version:** 2.0.0

## Purpose

Defines the canonical iterative workflow for **Hyperprompt** development. This cycle ensures systematic progression through `DOCS/Workplan.md` while maintaining clean task tracking and validation.

FLOW is the top-level orchestrator; each step is a dedicated command with its own responsibility.

## Workflow Cycle

```
┌──────────────┐
│   SELECT     │  Choose highest priority task
└──────┬───────┘  Updates: next.md, Workplan.md
       ↓
┌──────────────┐
│    PLAN      │  Generate detailed PRD
└──────┬───────┘  Creates: DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md
       ↓
┌──────────────┐
│ INSTALL_SWIFT│  Install Swift toolchain (one-time setup)
└──────┬───────┘  Required: Swift compiler for build/test
       ↓
┌──────────────┐
│   EXECUTE    │  Pre-flight → [YOU WORK] → Post-flight
└──────┬───────┘  Validates, commits, pushes
       ↓
    [REPEAT] ←──────────┐
       │                │
       │  (periodically)│
       ↓                │
┌──────────────┐        │
│   ARCHIVE    │  Clean workspace, move completed PRDs
└──────────────┘  To: DOCS/TASKS_ARCHIVE/
```

## Commands

### 1. SELECT

See `DOCS/COMMANDS/SELECT.md` for details.

Choose the highest priority task and record it to `DOCS/INPROGRESS/next.md`, updating `DOCS/Workplan.md` status.

---

### 2. PLAN

See `DOCS/COMMANDS/PLAN.md` for details.

Generate a detailed PRD at `DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md` from the selected task.

---

### 3. INSTALL_SWIFT

See `DOCS/COMMANDS/PRIMITIVES/INSTALL_SWIFT.md` for details.

Install Swift compiler and toolchain required for building and testing Hyperprompt. **One-time setup** per development environment.

**Skip if:** Swift already installed (`swift --version` works)

---

### 4. EXECUTE

See `DOCS/COMMANDS/EXECUTE.md` for details.

Run pre-flight checks, implement following XP/TDD, then validate like CI and update task documentation.

---

### 5. PROGRESS (Optional)

See `DOCS/COMMANDS/PROGRESS.md` for details.

Update task checklists during execution (auto-called by EXECUTE).

---

### 6. ARCHIVE

See `DOCS/COMMANDS/ARCHIVE.md` for details.

Clean workspace, move completed PRDs to `DOCS/TASKS_ARCHIVE/`, and update the archive index.

---

## When to Use This Flow

**Use this flow when:**
- Starting a new development session
- Completing a task and ready for the next one
- Unsure what to work on next
- Need to maintain systematic progress through `DOCS/Workplan.md`

**Skip this flow when:**
- Handling urgent hotfixes (can return to flow after)
- Making trivial documentation updates
- Responding to immediate build/test failures

## Flow Discipline

1. **Complete the cycle**: Don't skip steps. Each step has essential outputs for the next.
2. **One task at a time**: Finish EXECUTE before running SELECT again.
3. **Validate always**: Never skip EXECUTE validation, even for "simple" changes.
4. **Archive regularly**: Keep `DOCS/INPROGRESS/` clean to avoid confusion.

## Exceptions

- **No tasks available**: SELECT will report "Nothing to do" — project may be complete.
- **Validation fails**: Stay in EXECUTE until all checks pass; do not proceed to ARCHIVE.
- **Dependencies blocked**: SELECT may allow selection but flag for resolution in PLAN.

## Related Documentation

- `DOCS/COMMANDS/README.md` — Command system overview
- `DOCS/COMMANDS/PROGRESS.md` — Status tracking across tasks
- `DOCS/PRD/PRD_EditorEngine.md` — Canonical requirements (current primary PRD)
- `DOCS/Workplan.md` — Master task list
- `DOCS/RULES/03_XP_TDD_Workflow.md` — Development methodology
