# CI Workflow Commands

**Version:** 1.0.0

## Overview

Five commands implement a documentation-driven development workflow for GitHub Actions CI setup tasks.

| Command | Purpose | Details |
|---------|---------|---------|
| **SELECT** | Choose next CI task from Workplan | [SELECT.md](./SELECT.md) |
| **PLAN** | Generate implementation-ready PRD | [PLAN.md](./PLAN.md) |
| **EXECUTE** | Workflow wrapper (pre/post checks) | [EXECUTE.md](./EXECUTE.md) |
| **PROGRESS** | Update task checklist (optional) | [PROGRESS.md](./PROGRESS.md) |
| **ARCHIVE** | Move completed PRDs to archive | [ARCHIVE.md](./ARCHIVE.md) |

---

## Workflow

```
┌─────────┐
│ SELECT  │  Choose highest priority CI task
└────┬────┘  Updates: DOCS/CI/INPROGRESS/next.md, DOCS/CI/Workplan.md
     ↓
┌─────────┐
│  PLAN   │  Generate detailed PRD for CI task
└────┬────┘  Creates: DOCS/CI/INPROGRESS/{TASK_ID}_{TASK_NAME}.md
     ↓
┌─────────┐
│ EXECUTE │  Pre-flight → [YOU WORK] → Post-flight
└────┬────┘  Validates workflow YAML, commits, pushes
     ↓
  [REPEAT] ←──────────┐
     │                │
     │  (periodically)│
     ↓                │
┌─────────┐           │
│ ARCHIVE │  Clean workspace, move completed PRDs
└─────────┘  To: DOCS/CI/TASKS_ARCHIVE/
```

**Philosophy:** All implementation instructions exist in PRD/specs. Commands automate only workflow boilerplate.

---

## Quick Start

```bash
# 1. Choose CI task
$ claude "Выполни команду SELECT для CI"

# 2. Generate PRD
$ claude "Выполни команду PLAN для CI"

# 3. Execute (shows plan, you work, validates)
$ claude "Выполни команду EXECUTE для CI"

# 4. Repeat for next CI task
$ claude "Выполни команду SELECT для CI"
```

---

## CI Task Hierarchy

| Level | File | Granularity | Purpose |
|-------|------|-------------|---------|
| **Strategic** | DOCS/CI/Workplan.md | 10 items (CI-01 to CI-10) | High-level phases, dependencies |
| **Tactical** | next.md | 5-15 items | Daily checklist for current CI task |
| **Operational** | PRD | Atomic steps | Executable specification with YAML snippets |

**Example:**
- Workplan: `CI-03: Configure Linux job environment [High] — 1 hour`
- next.md: `- [ ] Add actions/setup-node step` (8 items)
- PRD: `Step 3.1: Add caching with hashFiles('**/package-lock.json')` (with acceptance criteria)

---

## CI Phases

Based on `DOCS/CI/Workplan.md`:

### Phase 1: Discovery (CI-01)
- Audit repository to identify language, package manager, existing scripts

### Phase 2: Workflow Skeleton (CI-02, CI-03, CI-07)
- Define triggers and path filters
- Configure Linux runner, toolchain, caching
- Set permissions block

### Phase 3: Quality Gates (CI-04, CI-05, CI-06)
- Add static analysis (lint) step
- Add test step with artifacts
- Implement retry wrappers

### Phase 4: Validation & Docs (CI-08, CI-09, CI-10)
- Document CI usage and extension
- Validate workflow locally
- Enable required status checks

---

## Command Details

### SELECT
Chooses next CI task based on:
- Dependencies satisfied (per Workplan §4 "Scheduling & Parallelization")
- Highest priority (High > Medium)
- Phase order preference

**Output:** Updates `DOCS/CI/INPROGRESS/next.md` and `DOCS/CI/Workplan.md`

👉 **[Full details in SELECT.md](./SELECT.md)**

---

### PLAN
Generates implementation-ready PRD from:
- Task in `DOCS/CI/INPROGRESS/next.md`
- Context from `DOCS/CI/Workplan.md`
- DOCS/CI/PRD.md for overall strategy
- Repository audit results (from CI-01)

**Output:** `DOCS/CI/INPROGRESS/{TASK_ID}_{TASK_NAME}.md` with GitHub Actions YAML snippets

👉 **[Full details in PLAN.md](./PLAN.md)**

---

### EXECUTE ⭐

**Thin workflow wrapper** (NOT an AI agent):

1. **Pre-flight:** Check git, dependencies, show plan
2. **Work period:** `[DEVELOPER FOLLOWS PRD, EDITS .github/workflows/ci.yml]`
3. **Post-flight:** Validate YAML syntax, workflow structure, commit, push
4. **Finalize:** Update docs, suggest next task

**Important:** PRD contains all implementation instructions (YAML snippets, step-by-step). EXECUTE only automates checks and commits.

**Modes:**
- Full (default) — complete workflow
- Show plan — preview only
- Validate only — post-implementation (yamllint, actionlint)
- Progress tracking — periodic checkpoints

**CI-Specific Validations:**
- YAML syntax (yamllint)
- GitHub Actions syntax (actionlint)
- Required sections (on:, jobs:, permissions:)
- Task-specific criteria from PRD

👉 **[Full details in EXECUTE.md](./EXECUTE.md)**

---

### PROGRESS
Optional command to update CI task checklist during work.

**Auto-detection examples:**
- Check if `.github/workflows/ci.yml` exists
- Verify workflow sections (triggers, permissions, caching)
- Run YAML validation

**Auto-called by EXECUTE**, so usually not needed separately.

👉 **[Full details in PROGRESS.md](./PROGRESS.md)**

---

### ARCHIVE
Moves completed CI task PRDs from `DOCS/CI/INPROGRESS/` to `DOCS/CI/TASKS_ARCHIVE/`.

**When to use:**
- After completing multiple CI tasks (batch cleanup)
- Before starting new phase
- After CI is fully implemented

**What it does:**
- Scans for completed tasks (marked `[x]` in DOCS/CI/Workplan.md)
- Moves PRDs to `DOCS/CI/TASKS_ARCHIVE/`
- Generates `INDEX.md` organized by phase
- Commits and pushes

**Not required** — run periodically to keep workspace clean.

👉 **[Full details in ARCHIVE.md](./ARCHIVE.md)**

---

## File Structure

```
DOCS/
├── CI/
│   ├── COMMANDS/              # This directory
│   │   ├── README.md          # This file (overview)
│   │   ├── SELECT.md          # Full SELECT spec
│   │   ├── PLAN.md            # Full PLAN spec
│   │   ├── EXECUTE.md         # Full EXECUTE spec
│   │   ├── PROGRESS.md        # Full PROGRESS spec
│   │   └── ARCHIVE.md         # Full ARCHIVE spec
│   │
│   ├── INPROGRESS/            # Active CI work
│   │   ├── next.md            # Current CI task
│   │   └── {TASK_ID}_{NAME}.md  # Active CI task PRDs
│   │
│   ├── TASKS_ARCHIVE/         # Completed CI tasks
│   │   ├── INDEX.md           # Organized by phase
│   │   └── {TASK_ID}_{NAME}.md  # Archived CI PRDs
│   │
│   ├── Workplan.md            # CI task list (CI-01 to CI-10)
│   └── PRD.md                 # CI project PRD
│
└── COMMANDS/                  # Main workflow commands (for general tasks)
    └── ...
```

---

## Common Workflows

### Starting CI Setup
```bash
# Start with CI-01 (Audit)
SELECT → PLAN → EXECUTE

# Continue with CI-02 (Triggers)
SELECT → PLAN → EXECUTE

# ... repeat for all 10 CI tasks
```

### Resuming After Break
```bash
# Check current CI task
$ cat DOCS/CI/INPROGRESS/next.md

# Continue with EXECUTE
$ claude "Выполни команду EXECUTE для CI"
```

### Checking CI Progress
```bash
# View checklist
$ cat DOCS/CI/INPROGRESS/next.md

# View PRD details
$ cat DOCS/CI/INPROGRESS/CI-03_Configure_Environment.md

# Overall CI Workplan status
$ grep "^| CI-" DOCS/CI/Workplan.md
```

### Testing Workflow
```bash
# After implementing CI tasks, test the workflow
$ git commit --allow-empty -m "Test CI workflow"
$ git push

# Or use act to test locally (CI-09)
$ act -l  # list workflows
$ act push  # simulate push event
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "No PRD found" | Run `PLAN` command first for CI |
| "Dependencies not satisfied" | Complete prerequisite CI tasks first (check DOCS/CI/Workplan.md) |
| "Git not clean" | Commit or stash changes |
| "YAML syntax error" | Fix `.github/workflows/ci.yml` indentation/structure |
| "Task already complete" | Run `SELECT` for next CI task |
| "Workflow file not found" | Ensure `.github/workflows/ci.yml` exists before validation |

For detailed error handling, see individual command files.

---

## Key Principles

1. **Single Source of Truth**
   - Implementation details → CI PRD
   - Task list → DOCS/CI/Workplan.md
   - Commands → automation only

2. **Documentation-Driven**
   - Write CI specs first
   - Implement following specs
   - Validate against acceptance criteria

3. **Thin Wrappers**
   - Commands don't implement workflow logic
   - Commands structure the CI setup process
   - Developer follows PRD documentation

4. **CI-Specific Validations**
   - YAML syntax checking
   - GitHub Actions best practices
   - Workflow structure validation
   - Required sections verification

5. **Incremental CI Setup**
   - 10 tasks from audit to status checks
   - Each task builds on previous
   - Clear acceptance criteria per task
   - Testable at each stage

---

## CI Task Dependencies

Based on `DOCS/CI/Workplan.md` §4 "Scheduling & Parallelization":

```
CI-01 (Audit) — Must run first
  ↓
CI-02 (Triggers) ←─┐
  ↓                 │
CI-03 (Environment) │ (CI-07 can run in parallel)
  ↓                 │
CI-07 (Permissions)─┘
  ↓
CI-04 (Static Analysis) ←─┐ (can run in parallel)
CI-05 (Tests) ←───────────┤
CI-06 (Retries) ←─────────┘
  ↓
CI-08 (Documentation) ←─┐ (can run in parallel)
CI-09 (Validation) ←────┘
  ↓
CI-10 (Status Checks) — Finalization
```

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-03 | Claude | Adapted from main COMMANDS/README for CI tasks |

---

## Learn More

- **SELECT.md** — CI task selection algorithm, priority rules, dependency checking
- **PLAN.md** — CI PRD generation process, input files, output structure
- **EXECUTE.md** — Workflow phases, execution modes, YAML validation details
- **PROGRESS.md** — Progress tracking mechanics, auto-detection for workflow files
- **ARCHIVE.md** — Archiving process, safety checks, INDEX generation

Each command file contains complete specifications, examples, and error handling specific to CI tasks.

---

## Integration with Main Workflow

These CI commands are **separate from** the main Hyperprompt workflow commands in `DOCS/COMMANDS/`.

- **Main commands** (`DOCS/COMMANDS/`) — for general project tasks
- **CI commands** (`DOCS/CI/COMMANDS/`) — specifically for CI setup tasks

Both use the same command patterns (SELECT, PLAN, EXECUTE, PROGRESS, ARCHIVE) but operate on different workplans and file structures.

After CI setup is complete (all 10 tasks done), the `.github/workflows/ci.yml` will be part of the repository, and these CI commands can be archived.
