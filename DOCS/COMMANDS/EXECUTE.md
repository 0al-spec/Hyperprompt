# EXECUTE — Execute Current Task

**Version:** 1.0.0

## Purpose

Execute the current task from `next.md` by following the implementation plan in the corresponding PRD. This command performs actual implementation work: creates files, writes code, runs commands, and verifies results.

## Input
- `DOCS/INPROGRESS/next.md` — current task (extract TASK_ID)
- `DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md` — PRD with implementation plan
- `DOCS/Workplan.md` — project context
- `DOCS/PRD/v0.0.1/` — design specifications (for reference)

## Algorithm

### Phase 1: Preparation
1. **Read next.md** → Extract TASK_ID and TASK_NAME
2. **Read PRD** → Load `DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md`
3. **Parse task breakdown** → Extract phases, subtasks, acceptance criteria
4. **Check dependencies** → Verify all upstream tasks completed (from Workplan)
5. **Confirm execution** → Show plan summary, ask user to proceed

### Phase 2: Execution (Interactive)
For each phase in PRD:
  1. **Show phase header** → Display phase name, goal, estimated time
  2. **For each subtask in phase:**
     - Display subtask description, input, process, output
     - **Execute actions:**
       - Create files/directories
       - Write code using templates from PRD
       - Run shell commands
       - Verify results against acceptance criteria
     - **Checkpoint:**
       - Show what was done
       - Mark subtask in next.md checklist as [x]
       - Ask: "Continue to next subtask? (y/n/skip/abort)"
  3. **Phase completion:**
     - Run phase verification commands
     - Commit changes: `"Complete {PHASE_NAME} for {TASK_ID}"`
     - Update PROGRESS

### Phase 3: Verification
1. **Run all acceptance tests** from PRD §3.3
2. **Verify quality checklist** from PRD §7.4
3. **Run final validation** commands
4. **Generate completion report:**
   - All subtasks completed: X/Y
   - All acceptance criteria met: ✓/✗
   - Build status: pass/fail
   - Test status: pass/fail

### Phase 4: Finalization
1. **Mark task complete in next.md** → Add completion timestamp
2. **Update Workplan.md** → Mark task as [x] completed
3. **Create final commit:**
   ```
   Complete {TASK_ID} — {TASK_NAME}

   Deliverables:
   - [List of files created]
   - [List of features implemented]

   Verification:
   - All acceptance criteria met
   - Build: PASS
   - Tests: PASS
   ```
4. **Push to remote**
5. **Suggest next action:** "Run SELECT to choose next task"

## Execution Modes

### Mode 1: Fully Automatic (default)
Execute all subtasks without interaction (dangerous for complex tasks).

```bash
$ claude "Execute task automatically"
```

### Mode 2: Interactive (recommended)
Pause after each subtask for user confirmation.

```bash
$ claude "Execute task interactively"
# or just:
$ claude "Выполни команду EXECUTE"
```

### Mode 3: Phase-by-Phase
Execute one phase, stop, wait for user to continue.

```bash
$ claude "Execute Phase 1 of current task"
```

### Mode 4: Dry Run
Show what would be executed without making changes.

```bash
$ claude "Dry run EXECUTE command"
```

## Smart Actions

The EXECUTE command understands common patterns from PRD and can automatically:

### File Operations
- **Create directories:** Parse "Create `Sources/Core/`" → `mkdir -p Sources/Core`
- **Write files:** Use templates from PRD §8 "Implementation Template"
- **Copy files:** Handle file references

### Code Generation
- **Package.swift:** Use template from PRD, fill in actual values
- **main.swift:** Use CLI entry point template
- **Test stubs:** Create empty test files with boilerplate

### Command Execution
- **Build commands:** `swift build`, `swift test`
- **Dependency resolution:** `swift package resolve`
- **Verification:** Check exit codes, parse output

### Validation
- **File existence:** Verify created files exist
- **Syntax checking:** Run language-specific linters
- **Test execution:** Run test suite, parse results

## Example: Executing A1

```
$ claude "Выполни команду EXECUTE"

╔════════════════════════════════════════════════════════════╗
║  EXECUTE: A1 — Project Initialization                      ║
╚════════════════════════════════════════════════════════════╝

📋 Task: A1 — Project Initialization
📄 PRD: DOCS/INPROGRESS/A1_Project_Initialization.md
⏱️  Estimated: 2 hours
✅ Dependencies: None (entry point)

─────────────────────────────────────────────────────────────

PHASE 1: Directory Structure Creation
Goal: Create all required directories for sources and tests
Estimated: 30 minutes

Subtask 1.1: Create Sources Directory Structure
├─ Input: Empty project directory
├─ Process: Create 6 module directories
└─ Output: Complete Sources/ tree

🔧 Action: mkdir -p Sources/{Core,Parser,Resolver,Emitter,CLI,Statistics}
✅ Created: Sources/Core/
✅ Created: Sources/Parser/
✅ Created: Sources/Resolver/
✅ Created: Sources/Emitter/
✅ Created: Sources/CLI/
✅ Created: Sources/Statistics/
✓ Verification: All 6 directories exist

✓ Subtask 1.1 completed
✓ Updated checklist: next.md [1/13 = 8%]

Continue to next subtask? [y/n/skip/abort]: y

Subtask 1.2: Create Tests Directory Structure
├─ Input: Empty project directory
├─ Process: Create 7 test directories
└─ Output: Complete Tests/ tree

🔧 Action: mkdir -p Tests/{CoreTests,ParserTests,ResolverTests,EmitterTests,CLITests,StatisticsTests,IntegrationTests}
✅ Created: Tests/CoreTests/
✅ Created: Tests/ParserTests/
... (etc)

✓ Phase 1 completed (2/13 subtasks = 15%)
✓ Committed: "Complete Phase 1: Directory Structure for A1"

─────────────────────────────────────────────────────────────

PHASE 2: Package Configuration
Goal: Configure Package.swift with dependencies and targets
Estimated: 1 hour

Subtask 2.1: Add Dependencies Section
...

🔧 Action: Create Package.swift from template
✅ Writing Package.swift...
✅ Added swift-argument-parser dependency
✅ Added swift-crypto dependency
✅ Added SpecificationCore dependency

✓ Verification: swift package dump-package
✓ Output: Valid JSON (dependencies declared)

Continue? [y/n/skip/abort]: y

... (continue through all subtasks)

─────────────────────────────────────────────────────────────

PHASE 3: Verification
Goal: Verify build system and test framework

Subtask 3.1: Resolve Dependencies
🔧 Action: swift package resolve
⏳ Resolving dependencies... (may take 1-2 minutes)
✅ Resolved: swift-argument-parser 1.5.0
✅ Resolved: swift-crypto 3.8.0
✅ Resolved: SpecificationCore 1.0.2
✓ Created: Package.resolved

Subtask 3.2: Build Package
🔧 Action: swift build
⏳ Building Hyperprompt...
✅ Build succeeded (0 errors, 0 warnings)

Subtask 3.3: Run Test Suite
🔧 Action: swift test
✅ Test suite passed (0 tests)

─────────────────────────────────────────────────────────────

✅ TASK COMPLETED: A1 — Project Initialization

📊 Execution Summary:
   • Subtasks completed: 13/13 (100%)
   • Phases completed: 3/3
   • Time elapsed: 47 minutes
   • Acceptance criteria met: 6/6 ✓
   • Build status: PASS ✓
   • Test status: PASS ✓

📁 Deliverables:
   • Created 6 source module directories
   • Created 7 test directories
   • Configured Package.swift with 3 dependencies
   • Created CLI entry point (main.swift)
   • Verified build system functional

✓ Committed: "Complete A1 — Project Initialization"
✓ Updated: next.md (marked complete)
✓ Updated: Workplan.md (marked [x] A1)
✓ Pushed to remote

─────────────────────────────────────────────────────────────

🎯 Next Action: Run SELECT to choose next task (A2)
   $ claude "Выполни команду SELECT"
```

## Error Handling

### Build Failures
If `swift build` fails:
1. Show full error output
2. Offer to retry after user fixes
3. Offer to continue with next phase (if non-critical)
4. Offer to abort execution

### Missing Dependencies
If upstream task not completed:
1. Show dependency chain
2. Suggest completing prerequisites first
3. Abort execution with clear error

### Acceptance Criteria Not Met
If validation fails:
1. Show which criteria failed
2. Show expected vs actual
3. Offer to retry subtask
4. Offer to skip (mark as known issue)

### User Abort
If user aborts mid-execution:
1. Commit work done so far: "Partial: {TASK_ID} — {PHASE_NAME} incomplete"
2. Mark subtasks completed up to abort point
3. Update PROGRESS
4. Leave task in next.md (not complete)

## Integration with Workflow

```
SELECT → next.md created
  ↓
PLAN → PRD created
  ↓
EXECUTE → Task implemented (auto-updates PROGRESS)
  ↓
Task complete → Run SELECT for next task
```

## Command Variants

```bash
# Standard execution (interactive)
claude "Выполни команду EXECUTE"
claude "Execute current task"

# Specific phase
claude "Execute Phase 1"
claude "Execute Phase 2: Package Configuration"

# Dry run (no changes)
claude "Dry run execute"
claude "Show execution plan for A1"

# Automatic (no interaction)
claude "Execute automatically"  # DANGEROUS

# Resume from checkpoint
claude "Resume execution of A1"
```

## Safety Features

1. **Pre-flight checks:**
   - Git working tree must be clean (no uncommitted changes)
   - All dependencies verified
   - User confirmation before destructive actions

2. **Atomic phases:**
   - Each phase commits independently
   - Can resume from last successful phase
   - Rollback possible if needed

3. **Validation gates:**
   - Must pass acceptance criteria to proceed
   - Build must succeed before marking complete
   - Tests must pass (if applicable)

4. **User control:**
   - Can skip subtasks (mark as TODO)
   - Can abort at any checkpoint
   - Can retry failed steps

## Output Files

After EXECUTE completes:
- ✅ All files from PRD templates created
- ✅ next.md updated with [x] marks
- ✅ Workplan.md updated with task [x]
- ✅ Git commits for each phase
- ✅ Everything pushed to remote

## Exceptions

- **No next.md** → Exit: "No current task. Run SELECT first."
- **No PRD found** → Exit: "No PRD for {TASK_ID}. Run PLAN first."
- **Task already complete** → Ask: "Task marked complete. Re-run? (y/n)"
- **Dependencies not met** → Exit: "Prerequisites not completed: [list]"
- **Git not clean** → Exit: "Uncommitted changes. Commit or stash first."

## Notes

- EXECUTE is the **main implementation command**
- Combines automation with human oversight
- Updates PROGRESS automatically (no need to run separately)
- Creates atomic commits for traceability
- Can be paused/resumed at any phase boundary
- Smart enough to parse PRD templates and execute them

## Future Enhancements

- **AI code generation:** Generate implementations from PRD descriptions
- **Test generation:** Auto-create test cases from acceptance criteria
- **Parallel execution:** Run independent subtasks concurrently
- **Rollback:** Undo phases if validation fails
- **Time tracking:** Measure actual vs estimated time
- **Learning:** Improve time estimates based on history
