# EXECUTE — Execute Current CI Task

**Version:** 1.0.0

## Purpose

Provide a **thin workflow wrapper** around CI task execution. This command:
1. Performs pre-flight checks (git clean, dependencies satisfied)
2. Displays the implementation plan from PRD
3. **[DEVELOPER/CLAUDE DOES THE ACTUAL WORK]**
4. Validates results against acceptance criteria
5. Updates progress markers and commits

**Important:** EXECUTE is NOT an AI agent that implements code automatically. It's a structured checklist runner that automates the workflow **around** implementation.

## Philosophy

All implementation instructions already exist in:
- **PRD** — step-by-step plan, GitHub Actions snippets, acceptance criteria
- **CI Workplan** — context, dependencies, estimates
- **CI/PRD.md** — overall CI strategy and requirements

EXECUTE simply:
- Checks prerequisites
- Shows the plan
- Lets you work
- Validates results (runs workflow syntax check, validates YAML)
- Commits and updates documentation

---

## Input

- `DOCS/CI/INPROGRESS/next.md` — current CI task (extract TASK_ID)
- `DOCS/CI/INPROGRESS/{TASK_ID}_{TASK_NAME}.md` — PRD with implementation plan
- `DOCS/CI/Workplan.md` — project context

---

## Algorithm

### Phase 1: Pre-Flight Checks

**Purpose:** Ensure environment is ready for work

1. **Verify Git state:**
   ```bash
   git status --porcelain
   # Must be empty (no uncommitted changes)
   ```

2. **Load task context:**
   ```bash
   TASK_ID=$(head -1 DOCS/CI/INPROGRESS/next.md | sed 's/# Next Task: \(.*\) —.*/\1/')
   PRD="DOCS/CI/INPROGRESS/${TASK_ID}_*.md"
   ```

3. **Check dependencies:**
   - Read `Dependencies:` line from next.md
   - Verify all upstream tasks marked `[x]` in CI/Workplan
   - **Exit if dependencies not satisfied**

4. **Verify PRD exists:**
   - Check `DOCS/CI/INPROGRESS/{TASK_ID}_*.md` exists
   - **Exit if not found:** "Run PLAN command first"

5. **Display plan summary:**
   ```
   ╔════════════════════════════════════════════════════════════╗
   ║  EXECUTE: {TASK_ID} — {TASK_NAME}                         ║
   ╚════════════════════════════════════════════════════════════╝

   📋 Task: {TASK_ID} — {TASK_NAME}
   📄 PRD: DOCS/CI/INPROGRESS/{TASK_ID}_{TASK_NAME}.md
   ⏱️  Estimated: {TIME}
   🔗 Dependencies: {LIST or "None"}
   🎯 Phase: {Discovery/Workflow Skeleton/Quality Gates/Validation}

   📝 Plan Overview:
   - Step 1: {NAME}
   - Step 2: {NAME}
   - Step 3: {NAME}

   ✅ Acceptance Criteria: {COUNT} items
   ```

6. **Prompt user:**
   ```
   Ready to execute {TASK_ID}?
   - PRD contains all implementation instructions
   - GitHub Actions workflow templates in PRD
   - Acceptance criteria in PRD

   [Enter] to continue, [Ctrl+C] to abort
   ```

---

### Phase 2: Work Period

**[THIS IS WHERE DEVELOPER/CLAUDE WORKS]**

The PRD contains everything needed:
- **GitHub Actions workflow snippets** (YAML templates)
- **Step-by-step instructions** per subtask
- **Acceptance criteria** to validate each step
- **Verification commands** (e.g., actionlint, yamllint, gh workflow view)

**Developer works by:**
1. Reading PRD implementation plan
2. Following instructions for each subtask
3. Creating/modifying `.github/workflows/ci.yml`
4. Testing against acceptance criteria from PRD

**Optional: Interactive Progress Tracking**

If `--interactive` mode:
- Periodically prompt: "Mark completed subtasks? [y/n]"
- Show checklist from next.md
- User marks `[ ]` → `[x]` for completed items
- Update progress percentage
- Continue work

---

### Phase 3: Post-Flight Validation

**Purpose:** Verify implementation meets CI requirements

1. **Extract verification commands from PRD:**
   - Parse "Acceptance Criteria" section
   - Find validation commands

2. **Run CI-specific validations:**
   ```bash
   # Example validations:

   # Workflow file exists
   test -f .github/workflows/ci.yml

   # YAML syntax check (if yamllint available)
   yamllint .github/workflows/ci.yml || echo "yamllint not available, skipped"

   # GitHub Actions syntax check (if actionlint available)
   actionlint .github/workflows/ci.yml || echo "actionlint not available, skipped"

   # GitHub CLI workflow validation (if gh available)
   gh workflow view ci.yml || echo "gh not available, skipped"

   # Check required sections exist
   grep -q "on:" .github/workflows/ci.yml
   grep -q "jobs:" .github/workflows/ci.yml
   grep -q "runs-on: ubuntu-latest" .github/workflows/ci.yml

   # Task-specific checks from PRD
   ```

3. **Collect results:**
   ```
   Acceptance Criteria Validation:
   [✓] .github/workflows/ci.yml exists — PASS
   [✓] YAML syntax valid — PASS
   [✓] GitHub Actions syntax valid — PASS
   [✓] Required sections present — PASS
   [✓] Task-specific criteria — PASS

   Overall: 5/5 items verified (100%)
   ```

4. **Generate completion report:**
   ```
   ╔════════════════════════════════════════════════════════════╗
   ║  VALIDATION REPORT: {TASK_ID}                              ║
   ╚════════════════════════════════════════════════════════════╝

   Subtasks completed: {N}/{N} (100%)
   Acceptance criteria: {N}/{N} passed (100%)
   YAML validation: PASS ✓
   Workflow syntax: PASS ✓

   Status: READY TO COMMIT
   ```

5. **If validation fails:**
   ```
   ✗ VALIDATION FAILED

   Failed checks:
   - YAML syntax → Invalid indentation at line 15
   - Missing required section: permissions

   Fix issues and re-run: claude "EXECUTE: validate only"
   ```

---

### Phase 4: Finalization

**Purpose:** Update documentation and commit

1. **Update next.md:**
   - Mark task complete: add `**Status:** ✅ Completed on {DATE}`
   - Mark all checklist items `[x]`
   - Add completion timestamp

2. **Update CI/Workplan.md:**
   - Find task by ID (e.g., `CI-01`)
   - Mark as completed: `- [x]` instead of `- [ ]`
   - Remove `**INPROGRESS**` marker

3. **Auto-detect deliverables:**
   ```bash
   # Files created/modified since task start
   git diff --name-status HEAD
   ```

4. **Create commit:**
   ```
   Complete {TASK_ID} — {TASK_NAME}

   Deliverables:
   - {List of created/modified files}

   Verification:
   - Acceptance criteria: {N}/{N} passed
   - YAML validation: PASS
   - Workflow syntax: PASS

   Closes task {TASK_ID} from CI Workplan Phase {N}.
   ```

5. **Push to remote:**
   ```bash
   git push -u origin {branch-name}
   ```

6. **Suggest next action:**
   ```
   ✅ Task {TASK_ID} completed successfully!

   🎯 Next steps:
   1. Run SELECT to choose next CI task
      $ claude "Выполни команду SELECT для CI"

   2. Or test workflow if ready
      $ git commit --allow-empty -m "Trigger CI" && git push
   ```

---

## Execution Modes

### Mode 1: Full (default)

Pre-flight → Work → Post-flight → Finalize

```bash
$ claude "Выполни команду EXECUTE для CI"
```

**Use case:** Standard workflow for any CI task

---

### Mode 2: Show Plan Only

Only pre-flight checks and plan display

```bash
$ claude "CI EXECUTE: show plan"
```

**Use case:** Preview CI task before starting work

---

### Mode 3: Validate Only

Skip pre-flight, only run validation and finalization

```bash
$ claude "CI EXECUTE: validate and commit"
```

**Use case:** After manual implementation, validate and commit

---

### Mode 4: With Progress Tracking

Full mode + periodic progress prompts

```bash
$ claude "CI EXECUTE with progress tracking"
```

**Use case:** Long CI tasks (>1 hour), want checkpoints

---

## CI-Specific Validations

For different CI task types:

**CI-01 (Audit):**
- Verify audit report created
- Check language/toolchain documented

**CI-02 (Triggers):**
- Validate workflow triggers section
- Check path filters syntax

**CI-03 (Environment):**
- Verify runner configuration
- Check caching strategy defined
- Validate toolchain setup steps

**CI-04 (Static Analysis):**
- Verify lint step added
- Check conditional logic for missing scripts

**CI-05 (Tests):**
- Verify test step added
- Check artifact upload configuration

**CI-06 (Retries):**
- Verify retry logic implemented
- Check max retry count

**CI-07 (Permissions):**
- Verify permissions block exists
- Check least privilege principle

**CI-08 (Documentation):**
- Verify DOCS/CI/README.md exists
- Check completeness

**CI-09 (Validation):**
- Run act (if available) or syntax checks
- Archive validation output

**CI-10 (Branch Protection):**
- Verify documentation of status check names
- Check alignment with workflow job names

---

## Error Handling

### Pre-Flight Failures

**Git not clean:**
```
✗ Pre-flight check failed: Git working tree not clean

Uncommitted changes:
  M .github/workflows/ci.yml

Fix: Commit or stash changes, then retry
```

**Dependencies not met:**
```
✗ Pre-flight check failed: Dependencies not satisfied

Task CI-03 requires:
  [x] CI-01 — Audit ✓
  [x] CI-02 — Triggers ✓
  [ ] CI-07 — Permissions ✗

Fix: Complete CI-07 first or update CI Workplan dependencies
```

**No PRD:**
```
✗ Pre-flight check failed: PRD not found

Expected: DOCS/CI/INPROGRESS/CI-01_Audit.md

Fix: Run PLAN command first for CI tasks
```

---

### Validation Failures

**YAML errors:**
```
✗ Validation failed: YAML syntax

YAML errors:
  Line 15: Invalid indentation
  Line 24: Unexpected key 'step'

Fix issues and re-run validation
```

**Missing required sections:**
```
✗ Validation failed: Required workflow sections missing

Missing:
  [✗] permissions block
  [✗] path filters in triggers

Fix and retry
```

---

## Safety Features

1. **Idempotent:** Can run multiple times safely
2. **Non-destructive:** Only creates commit if validation passes
3. **Atomic commits:** Single commit per task completion
4. **Rollback support:** Can revert commit if CI breaks
5. **Checkpoint resume:** Can abort and resume later (work preserved)

---

## Integration with CI Workflow

```
SELECT → next.md created
  ↓
PLAN → PRD created
  ↓
EXECUTE (pre-flight) → Shows plan
  ↓
[DEVELOPER WORKS] → Follows PRD, edits .github/workflows/
  ↓
EXECUTE (post-flight) → Validates YAML, syntax
  ↓
Task complete → Run SELECT for next CI task
```

---

## Command Variants

```bash
# Standard execution for CI
claude "Выполни команду EXECUTE для CI"

# Show plan only
claude "CI EXECUTE: show plan"

# Validate and commit only
claude "CI EXECUTE: validate only"

# With progress tracking
claude "CI EXECUTE with progress tracking"
```

---

## What EXECUTE Does NOT Do

- ❌ Does NOT write workflow YAML automatically
- ❌ Does NOT "understand" CI requirements and implement
- ❌ Does NOT generate workflow files from descriptions
- ❌ Does NOT debug or fix workflow errors

**Developer (or Claude in separate requests) implements the CI task.**

EXECUTE only provides:
- ✅ Structured checklist
- ✅ Pre/post validation
- ✅ Automatic commit/push
- ✅ Progress tracking

---

## Exceptions

- **No next.md** → "No current CI task. Run SELECT first."
- **No PRD** → "No PRD for {TASK_ID}. Run PLAN first."
- **Task complete** → "Task already marked complete. Run SELECT for next."
- **Dependencies unsatisfied** → "Prerequisites not met: [list]. Complete them first."
- **Git not clean** → "Uncommitted changes. Commit or stash first."
- **Validation fails** → "Fix issues and retry with 'CI EXECUTE: validate only'"

---

## Notes

- EXECUTE is a **thin wrapper**, not an AI agent
- All implementation logic is in PRD, not in this command
- Developer follows PRD manually (or uses Claude in separate prompts)
- EXECUTE automates only the workflow boilerplate
- Can be run multiple times (idempotent)
- Always safe to abort (Ctrl+C)
- CI-specific: validates YAML syntax and GitHub Actions best practices

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-03 | Claude | Adapted from main EXECUTE for CI tasks |
