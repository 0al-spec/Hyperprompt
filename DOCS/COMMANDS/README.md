# Hyperprompt Workflow Commands

**Version:** 2.0.0

## Overview

Four commands implement a documentation-driven development workflow with three-level task hierarchy.

| Command | Purpose | Details |
|---------|---------|---------|
| **SELECT** | Choose next task from Workplan | [SELECT.md](./SELECT.md) |
| **PLAN** | Generate implementation-ready PRD | [PLAN.md](./PLAN.md) |
| **EXECUTE** | Workflow wrapper (pre/post checks) | [EXECUTE.md](./EXECUTE.md) |
| **PROGRESS** | Update task checklist (optional) | [PROGRESS.md](./PROGRESS.md) |

---

## Workflow

```
┌─────────┐
│ SELECT  │  Choose highest priority task
└────┬────┘  Updates: next.md, Workplan.md
     ↓
┌─────────┐
│  PLAN   │  Generate detailed PRD
└────┬────┘  Creates: DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md
     ↓
┌─────────┐
│ EXECUTE │  Pre-flight → [YOU WORK] → Post-flight
└────┬────┘  Validates, commits, pushes
     ↓
  [REPEAT]
```

**Philosophy:** All implementation instructions exist in PRD/specs. Commands automate only workflow boilerplate.

---

## Quick Start

```bash
# 1. Choose task
$ claude "Выполни команду SELECT"

# 2. Generate PRD
$ claude "Выполни команду PLAN"

# 3. Execute (shows plan, you work, validates)
$ claude "Выполни команду EXECUTE"

# 4. Repeat
$ claude "Выполни команду SELECT"
```

---

## Three-Level Task Hierarchy

| Level | File | Granularity | Purpose |
|-------|------|-------------|---------|
| **Strategic** | Workplan.md | 3-5 items | High-level phases, dependencies |
| **Tactical** | next.md | 10-20 items | Daily checklist |
| **Operational** | PRD | Atomic steps | Executable specification |

**Example:**
- Workplan: `A1: Project Initialization [P0] — 2 hours`
- next.md: `- [ ] Create Sources/Core/ directory` (20 items)
- PRD: `Task 1.1: mkdir -p Sources/Core` (with acceptance criteria)

---

## Command Details

### SELECT
Chooses next task based on:
- Dependencies satisfied
- Highest priority (P0 > P1 > P2)
- Critical path preference

**Output:** Updates `next.md` and `Workplan.md`

👉 **[Full details in SELECT.md](./SELECT.md)**

---

### PLAN
Generates implementation-ready PRD from:
- Task in `next.md`
- Context from `Workplan.md`
- Rules from `01_PRD_PROMPT.md`
- Project specs

**Output:** `DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md`

👉 **[Full details in PLAN.md](./PLAN.md)**

---

### EXECUTE ⭐

**Thin workflow wrapper** (NOT an AI agent):

1. **Pre-flight:** Check git, dependencies, show plan
2. **Work period:** `[DEVELOPER FOLLOWS PRD]`
3. **Post-flight:** Validate, commit, push
4. **Finalize:** Update docs, suggest next task

**Important:** PRD contains all implementation instructions. EXECUTE only automates checks and commits.

**Modes:**
- Full (default) — complete workflow
- Show plan — preview only
- Validate only — post-implementation
- Progress tracking — periodic checkpoints

👉 **[Full details in EXECUTE.md](./EXECUTE.md)**

---

### PROGRESS
Optional command to update task checklist during work.

**Auto-called by EXECUTE**, so usually not needed separately.

👉 **[Full details in PROGRESS.md](./PROGRESS.md)**

---

## File Structure

```
DOCS/
├── COMMANDS/              # This directory
│   ├── README.md          # This file (overview)
│   ├── SELECT.md          # Full SELECT spec
│   ├── PLAN.md            # Full PLAN spec
│   ├── EXECUTE.md         # Full EXECUTE spec
│   └── PROGRESS.md        # Full PROGRESS spec
│
├── INPROGRESS/            # Active work
│   ├── next.md            # Current task
│   └── {TASK_ID}_{NAME}.md  # PRDs
│
├── Workplan.md            # Master task list
├── RULES/
│   └── 01_PRD_PROMPT.md   # PRD generation rules
│
└── PRD/v0.0.1/            # Project specs
    ├── 00_PRD_001.md
    ├── 01_DESIGN_SPEC_001.md
    └── 02_DESIGN_SPEC_SPECIFICATION_CORE.md
```

---

## Common Workflows

### Starting New Task
```bash
SELECT → PLAN → EXECUTE
```

### Resuming After Break
```bash
# Check current task
$ cat DOCS/INPROGRESS/next.md

# Continue with EXECUTE
$ claude "Выполни команду EXECUTE"
```

### Checking Progress
```bash
# View checklist
$ cat DOCS/INPROGRESS/next.md

# View PRD details
$ cat DOCS/INPROGRESS/A1_Project_Initialization.md

# Overall Workplan status
$ grep "^\- \[.\]" DOCS/Workplan.md | head -20
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "No PRD found" | Run `PLAN` command first |
| "Dependencies not satisfied" | Complete prerequisite tasks first |
| "Git not clean" | Commit or stash changes |
| "Task already complete" | Run `SELECT` for next task |

For detailed error handling, see individual command files.

---

## Key Principles

1. **Single Source of Truth**
   - Implementation details → PRD
   - Task list → Workplan
   - Commands → automation only

2. **Documentation-Driven**
   - Write specs first
   - Implement following specs
   - Validate against acceptance criteria

3. **Thin Wrappers**
   - Commands don't implement logic
   - Commands structure the process
   - Developer follows documentation

4. **Three-Level Hierarchy**
   - Workplan = strategy
   - next.md = tactics
   - PRD = operations

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 2.0.0 | 2025-12-03 | Claude | Simplified to overview (removed duplication) |
| 1.1.0 | 2025-12-03 | Claude | EXECUTE thin wrapper philosophy |
| 1.0.0 | 2025-12-03 | Claude | Initial comprehensive version (deprecated) |

---

## Learn More

- **SELECT.md** — Task selection algorithm, priority rules, dependency checking
- **PLAN.md** — PRD generation process, input files, output structure
- **EXECUTE.md** — Workflow phases, execution modes, validation details
- **PROGRESS.md** — Progress tracking mechanics, auto-detection, manual updates

Each command file contains complete specifications, examples, and error handling.
