# EXECUTE — Execute Current Task

**Version:** 2.0.0

## Purpose

Provide a **thin workflow wrapper** around task execution. This command:
1. Performs pre-flight checks (git clean, dependencies satisfied)
2. Displays the implementation plan from PRD
3. **[DEVELOPER/CLAUDE DOES THE ACTUAL WORK]**
4. Validates results against acceptance criteria
5. Updates progress markers and commits

**Important:** EXECUTE is NOT an AI agent that implements code automatically. It's a structured checklist runner that automates the workflow **around** implementation.

> **CRITICAL VALIDATION REQUIREMENT**
>
> - **Swift must be installed before starting EXECUTE.** If it's missing, run INSTALL_SWIFT first: **[`PRIMITIVES/INSTALL_SWIFT.md`](./PRIMITIVES/INSTALL_SWIFT.md)**
> - After code changes, validation may restore a local build cache first, then MUST run tests (which also build):
>   ```bash
>   ./.github/scripts/restore-build-cache.sh || true
>   swift test 2>&1
>   ```
> - Do NOT commit code that doesn't compile or has failing tests
> - If Swift or the cache cannot be used in the environment, note this explicitly in the commit message and task summary

## Philosophy

All implementation instructions already exist in:
- **PRD** — step-by-step plan, templates, acceptance criteria
- **Design Specs** — architecture, algorithms, data structures
- **Workplan** — context, dependencies, estimates

EXECUTE simply:
- Checks prerequisites
- Shows the plan
- Lets you work
- Validates results
- Commits and updates documentation

**Important:** Follow the [XP-Inspired TDD Workflow (Outside-In)](../RULES/03_XP_TDD_Workflow.md) when implementing tasks.
This ensures test-driven development, incremental delivery, and continuous main-branch readiness.

---

## Input

- `DOCS/INPROGRESS/next.md` — current task (extract TASK_ID)
- `DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md` — PRD with implementation plan
- `DOCS/Workplan.md` — project context

---

## Algorithm

### Phase 1: Pre-Flight Checks

**Purpose:** Ensure environment is ready for work

1. **Ensure Swift is available (install if missing):**
   - Run **[INSTALL_SWIFT](./PRIMITIVES/INSTALL_SWIFT.md)** command if Swift not installed
   - Confirm installation: `swift --version`

2. **Verify Git state:**
   ```bash
   git status --porcelain
   # Must be empty (no uncommitted changes)
   ```

3. **Load task context:**
   ```bash
   TASK_ID=$(head -1 DOCS/INPROGRESS/next.md | sed 's/# Next Task: \(.*\) —.*/\1/')
   PRD="DOCS/INPROGRESS/${TASK_ID}_*.md"
   ```

4. **Check dependencies:**
   - Read `Dependencies:` line from next.md
   - Verify all upstream tasks marked `[x]` in Workplan
   - **Exit if dependencies not satisfied**

5. **Verify PRD exists:**
   - Check `DOCS/INPROGRESS/{TASK_ID}_*.md` exists
   - **Exit if not found:** "Run PLAN command first"

6. **Display plan summary:**
   ```
   ╔════════════════════════════════════════════════════════════╗
   ║  EXECUTE: {TASK_ID} — {TASK_NAME}                         ║
   ╚════════════════════════════════════════════════════════════╝

   📋 Task: {TASK_ID} — {TASK_NAME}
   📄 PRD: DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md
   ⏱️  Estimated: {TIME}
   🔗 Dependencies: {LIST or "None"}

   📝 Plan Overview:
   - Phase 1: {NAME} ({SUBTASK_COUNT} subtasks)
   - Phase 2: {NAME} ({SUBTASK_COUNT} subtasks)
   - Phase 3: {NAME} ({SUBTASK_COUNT} subtasks)

   ✅ Acceptance Criteria: {COUNT} items
   ✅ Quality Checklist: {COUNT} items
   ```

7. **Prompt user:**
   ```
   Ready to execute {TASK_ID}?
   - PRD contains all implementation instructions
   - Templates available in PRD §8
   - Acceptance criteria in PRD §3.3
   - Quality checklist in PRD §7.4

   [Enter] to continue, [Ctrl+C] to abort
   ```

---

### Phase 2: Work Period

**[THIS IS WHERE DEVELOPER/CLAUDE WORKS]**

The PRD contains everything needed:
- **Implementation templates** (e.g., Package.swift, main.swift)
- **Step-by-step instructions** per subtask
- **Acceptance criteria** to validate each step
- **Verification commands** (e.g., swift build, swift test)

**Developer works by:**
1. Reading PRD §2 "Hierarchical Task Breakdown"
2. Following instructions for each subtask
3. Using templates from PRD §8 "Implementation Template"
4. Testing against acceptance criteria from PRD §3.3

**Optional: Interactive Progress Tracking**

If `--interactive` mode:
- Periodically prompt: "Mark completed subtasks? [y/n]"
- Show checklist from next.md
- User marks `[ ]` → `[x]` for completed items
- Update progress percentage
- Continue work

**Note:** This is optional. Developer can manually update next.md checklist anytime.

---

### Phase 3: Post-Flight Validation

**Purpose:** Verify implementation meets requirements

**CRITICAL:** Every EXECUTE cycle MUST run `swift test` (which performs the build) before committing. Restoring a local build cache is optional and must not depend on Git LFS.

1. **OPTIONAL: Restore build cache for faster compilation:**
   ```bash
   # Speeds up compilation from 82s to ~5-10s (8-16x faster)
   ./.github/scripts/restore-build-cache.sh
   ```

   **What this does:**
   - Restores pre-built Swift package dependencies from `.build-cache/`
   - Eliminates dependency resolution and compilation time
   - Uses platform-specific cache: `swift-build-cache-{OS}-{ARCH}.tar.gz`

   **If cache doesn't exist:**
   - Script will show available caches or indicate none exist
   - First build will be slower (82s), but subsequent builds faster (2-5s incremental)
   - After successful build, create cache: `./.github/scripts/create-build-cache.sh`

   **Notes:**
   - Cache is stored in `.build-cache/` and ignored by Git
   - Safe to skip if cache not available — build will work normally
   - Update cache after changing `Package.swift`: `./.github/scripts/update-build-cache.sh`

2. **MANDATORY: Run test-backed validation instead of bare `swift build`:**
   ```bash
   # Optional speedup; safe to skip on cache miss
   ./.github/scripts/restore-build-cache.sh || true

   # REQUIRED - Must pass before commit
   swift test 2>&1
   ```

   **If `swift test` (build + tests) fails:**
   - Fix all compilation errors or failing tests before proceeding
   - Do NOT commit code that doesn't compile
   - Re-run tests (which rebuild) until they pass

   **If `swift test` fails:**
   - Fix all failing tests before proceeding
   - Do NOT commit code with failing tests
   - Re-run tests until all pass

   **After successful first build (if no cache was used):**
   ```bash
   # Create cache for future use (saves 70+ seconds on next build)
   ./.github/scripts/create-build-cache.sh
   ```

3. **Extract additional verification commands from PRD §3.3:**
   - Parse "Acceptance Criteria per Task" section
   - Find validation commands (ls, grep, etc.)

4. **Run each verification command:**
   ```bash
   # Example for A1:
   swift package resolve
   swift build           # MANDATORY
   swift test            # MANDATORY
   ls -la Sources/       # Check directories exist
   cat Package.swift | grep "swift-crypto"  # Check dependency
   ```

5. **Collect results:**
   ```
   Acceptance Criteria Validation:
   [✓] swift package resolve — PASS (3 dependencies resolved)
   [✓] swift build — PASS (0 errors, 0 warnings)
   [✓] swift test — PASS (0 tests, 0 failures)
   [✓] 6 source directories exist — PASS
   [✓] Package.swift contains dependencies — PASS

   Quality Checklist from PRD §7.4:
   [✓] All 6 source module directories exist
   [✓] All 7 test module directories exist
   [✓] Package.swift contains all 3 dependencies
   [✓] Package.swift defines all 6 module targets
   [✓] CLI defined as executableTarget
   [~] No compiler warnings (manual check)

   Overall: 11/12 items verified (92%)
   ```

6. **Generate completion report:**
   ```
   ╔════════════════════════════════════════════════════════════╗
   ║  VALIDATION REPORT: {TASK_ID}                              ║
   ╚════════════════════════════════════════════════════════════╝

   Subtasks completed: 13/13 (100%)
   Acceptance criteria: 5/5 passed (100%)
   Quality checklist: 11/12 verified (92%)
   Build: PASS ✓
   Tests: PASS ✓

   Status: READY TO COMMIT
   ```

7. **If validation fails:**
   ```
   ✗ VALIDATION FAILED

   Failed checks:
   - swift build → 3 errors
   - Quality item #7: Module boundaries not defined

   Fix issues and re-run: claude "EXECUTE: validate only"
   ```

---

### Phase 4: Finalization

**Purpose:** Update documentation and commit

1. **Update next.md:**
   - Mark task complete: add `**Status:** ✅ Completed on {DATE}`
   - Mark all checklist items `[x]`
   - Add completion timestamp

2. **Update Workplan.md:**
   - Find task by ID (e.g., `### A1:`)
   - Mark as completed: `- [x]` instead of `- [ ]`
   - Remove `**Status:** INPROGRESS`

3. **Save task summary (if applicable):**
   - **IMPORTANT:** Task summaries must be saved in `DOCS/INPROGRESS/` folder
   - File naming: `{TASK_ID}-summary.md` (e.g., `A1-summary.md`, `A2-summary.md`)
   - Include: task metrics, key findings, deliverables, acceptance criteria verification, next steps
   - This is a comprehensive report for the task, complementing the checklist in the PRD

4. **Auto-detect deliverables:**
   ```bash
   # Files created/modified since task start
   git diff --name-status HEAD
   ```

5. **Create commit:**
   Follow the lightweight checklist in [`DOCS/COMMANDS/PRIMITIVES/COMMIT.md`](./PRIMITIVES/COMMIT.md) to stage and record the changes before pushing.

6. **Push to remote:**
   ```bash
   git push -u origin {branch-name}
   ```

7. **Suggest next action:**
   ```
   ✅ Task {TASK_ID} completed successfully!

   🎯 Next steps:
   1. Run SELECT to choose next task
      $ claude "Выполни команду SELECT"

   2. Or create a PR if phase complete
      $ gh pr create --title "Complete Phase 1: Foundation"
   ```

---

## Execution Modes

### Mode 1: Full (default)

Pre-flight → Work → Post-flight → Finalize

```bash
$ claude "Выполни команду EXECUTE"
```

**Use case:** Standard workflow for any task

---

### Mode 2: Show Plan Only

Only pre-flight checks and plan display

```bash
$ claude "EXECUTE: show plan"
$ claude "Show execution plan for current task"
```

**Use case:** Preview task before starting work

**Output:** Plan summary, no git checks

---

### Mode 3: Validate Only

Skip pre-flight, only run validation and finalization

```bash
$ claude "EXECUTE: validate and commit"
$ claude "Validate current task and commit"
```

**Use case:** After manual implementation, validate and commit

**Flow:**
- Assumes work already done
- Runs acceptance tests
- Creates commit if validation passes

---

### Mode 4: With Progress Tracking

Full mode + periodic progress prompts

```bash
$ claude "EXECUTE with progress tracking"
```

**Use case:** Long tasks (>2 hours), want checkpoints

**Flow:**
- Shows plan
- Developer works
- Every N minutes: "Update progress? [y/n]"
- Runs validation
- Commits

---

## Example Output

```
$ claude "Выполни команду EXECUTE"

╔════════════════════════════════════════════════════════════╗
║  EXECUTE: A1 — Project Initialization                      ║
╚════════════════════════════════════════════════════════════╝

📋 Task: A1 — Project Initialization
📄 PRD: DOCS/INPROGRESS/A1_Project_Initialization.md
⏱️  Estimated: 2 hours
🔗 Dependencies: None (entry point)

─────────────────────────────────────────────────────────────

✓ Pre-Flight Checks:
  [✓] Git working tree clean
  [✓] PRD exists
  [✓] Dependencies satisfied (none required)
  [✓] Task not already complete

📝 Plan Overview:
  Phase 1: Directory Structure (2 subtasks, 30 min)
  Phase 2: Package Configuration (8 subtasks, 1 hour)
  Phase 3: Verification (3 subtasks, 30 min)

  Total: 13 subtasks across 3 phases

📋 Key Acceptance Criteria:
  • swift build completes without errors
  • All 6 module directories created
  • All 3 dependencies resolved
  • Empty test suite runs successfully

─────────────────────────────────────────────────────────────

Ready to execute A1 — Project Initialization?

The PRD contains:
• Implementation templates (Package.swift in §8.1)
• Step-by-step instructions (§2 Task Breakdown)
• Acceptance criteria (§3.3 per subtask)
• Quality checklist (§7.4 validation)

Press [Enter] to continue, [Ctrl+C] to abort: ▊

─────────────────────────────────────────────────────────────

[YOU WORK ON THE TASK FOLLOWING PRD]

... (time passes) ...

─────────────────────────────────────────────────────────────

Running validation...

✓ Acceptance Tests:
  [✓] swift package resolve — PASS (3 dependencies)
  [✓] swift build — PASS (0 errors)
  [✓] swift test — PASS (0 tests)
  [✓] Directory structure — PASS (13 dirs exist)
  [✓] Package.swift dependencies — PASS (all present)

✓ Quality Checklist (PRD §7.4):
  [✓] All 6 source module directories exist
  [✓] All 7 test module directories exist
  [✓] Package.swift contains all 3 dependencies
  [✓] Package.swift defines all 6 module targets
  [✓] CLI as executableTarget
  [✓] All test targets defined
  [✓] No compiler warnings

╔════════════════════════════════════════════════════════════╗
║  VALIDATION REPORT                                         ║
╚════════════════════════════════════════════════════════════╝

Subtasks: 13/13 completed (100%)
Acceptance: 5/5 passed (100%)
Quality: 7/7 verified (100%)

Build: PASS ✓
Tests: PASS ✓

Status: ✅ READY TO COMMIT

─────────────────────────────────────────────────────────────

Finalizing...

✓ Updated next.md (marked complete)
✓ Updated Workplan.md (marked [x] A1)
✓ Created commit: "Complete A1 — Project Initialization"
✓ Pushed to remote: claude/execute-plan-command-015km...

─────────────────────────────────────────────────────────────

✅ Task A1 completed successfully!

🎯 Next steps:
   $ claude "Выполни команду SELECT"

   (Will choose A2: Core Types Implementation)
```

---

## Error Handling

### Pre-Flight Failures

**Git not clean:**
```
✗ Pre-flight check failed: Git working tree not clean

Uncommitted changes:
  M DOCS/Workplan.md
  ?? new_file.swift

Fix: Commit or stash changes, then retry
```

**Dependencies not met:**
```
✗ Pre-flight check failed: Dependencies not satisfied

Task A2 requires:
  [x] A1 — Project Initialization ✓
  [ ] A3 — Domain Types ✗

Fix: Complete A3 first or update Workplan dependencies
```

**No PRD:**
```
✗ Pre-flight check failed: PRD not found

Expected: DOCS/INPROGRESS/A1_Project_Initialization.md

Fix: Run PLAN command first
     $ claude "Выполни команду PLAN"
```

---

### Validation Failures

**Build errors:**
```
✗ Validation failed: swift build

Build errors:
  Sources/Core/File.swift:10: error: use of unresolved identifier 'foo'
  Sources/Parser/Lexer.swift:24: error: missing return

Fix issues and re-run validation:
  $ claude "EXECUTE: validate only"
```

**Acceptance criteria not met:**
```
✗ Validation failed: 3/5 acceptance criteria not met

Failed:
  [✗] All 6 directories exist
      → Only 4 directories found
  [✗] Package.swift contains dependencies
      → swift-crypto not declared
  [✗] Empty test suite runs
      → swift test failed with errors

Fix issues and retry
```

---

## Safety Features

1. **Idempotent:** Can run multiple times safely
2. **Non-destructive:** Only creates commit if validation passes
3. **Atomic commits:** Single commit per task completion
4. **Rollback support:** Can revert commit if issues found
5. **Checkpoint resume:** Can abort and resume later (work preserved)

---

## Integration with Workflow

```
SELECT → next.md created
  ↓
PLAN → PRD created
  ↓
EXECUTE (pre-flight) → Shows plan
  ↓
[DEVELOPER WORKS] → Follows PRD
  ↓
EXECUTE (post-flight) → Validates
  ↓
Task complete → Run SELECT
```

---

## Command Variants

```bash
# Standard execution
claude "Выполни команду EXECUTE"
claude "Execute current task"

# Show plan only (no validation)
claude "EXECUTE: show plan"
claude "Show execution plan"

# Validate and commit only (skip pre-flight)
claude "EXECUTE: validate only"
claude "Validate and commit current task"

# With progress tracking
claude "EXECUTE with progress tracking"
```

---

## What EXECUTE Does NOT Do

- ❌ Does NOT write code automatically
- ❌ Does NOT "understand" requirements and implement
- ❌ Does NOT generate files from descriptions
- ❌ Does NOT debug or fix errors

**Developer (or Claude in separate requests) implements the task.**

EXECUTE only provides:
- ✅ Structured checklist
- ✅ Pre/post validation
- ✅ Automatic commit/push
- ✅ Progress tracking

---

## Exceptions

- **No next.md** → "No current task. Run SELECT first."
- **No PRD** → "No PRD for {TASK_ID}. Run PLAN first."
- **Task complete** → "Task already marked complete. Run SELECT for next."
- **Dependencies unsatisfied** → "Prerequisites not met: [list]. Complete them first."
- **Git not clean** → "Uncommitted changes. Commit or stash first."
- **Validation fails** → "Fix issues and retry with 'EXECUTE: validate only'"

---

## Notes

- EXECUTE is a **thin wrapper**, not an AI agent
- All implementation logic is in PRD, not in this command
- Developer follows PRD manually (or uses Claude in separate prompts)
- EXECUTE automates only the workflow boilerplate
- Can be run multiple times (idempotent)
- Always safe to abort (Ctrl+C)

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 2.0.0 | 2025-12-03 | Claude | Simplified to thin wrapper (removed auto-implementation) |
| 1.0.0 | 2025-12-03 | Claude | Initial version (too complex, deprecated) |
