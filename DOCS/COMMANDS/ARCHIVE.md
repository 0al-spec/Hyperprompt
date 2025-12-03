# ARCHIVE — Archive Completed Tasks

**Version:** 1.0.0

## Purpose

Move completed task PRDs from `DOCS/INPROGRESS/` to `DOCS/TASKS_ARCHIVE/` to keep workspace clean while preserving history.

## Philosophy

- Keep `INPROGRESS/` clean (only active work)
- Preserve completed PRDs for reference
- Maintain project history
- Enable workspace cleanup

---

## Input

- `DOCS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md` — completed PRD files
- `DOCS/Workplan.md` — verify tasks marked `[x]` complete
- `DOCS/INPROGRESS/next.md` — remove completed tasks (counterbalance to SELECT)

---

## Algorithm

### 1. Identify Completed Tasks

Scan `DOCS/INPROGRESS/` for PRD files and check if task completed:

```bash
for prd_file in DOCS/INPROGRESS/*.md; do
  TASK_ID=$(extract_task_id "$prd_file")

  # Check if marked complete in Workplan
  if grep -q "^\- \[x\].*${TASK_ID}" DOCS/Workplan.md; then
    # Check if currently active (being worked on) in next.md
    if grep -q "^# Next Task: ${TASK_ID}" DOCS/INPROGRESS/next.md && \
       ! grep -q "Status.*✅.*Completed" DOCS/INPROGRESS/next.md; then
      # Skip: task is currently being worked on
      continue
    else
      # Task is completed and safe to archive
      candidates+=("$prd_file")
    fi
  fi
done
```

**Safety checks:**
- ✅ Task marked `[x]` in Workplan (source of truth)
- ✅ Task NOT currently active in `next.md` (not being worked on)
- ✅ PRD file exists in INPROGRESS/

---

### 2. Archive Each Task

For each candidate:

```bash
# Extract metadata
TASK_ID="A1"
TASK_NAME="Project_Initialization"
COMPLETION_DATE=$(grep "Completed on" "$prd_file" || date +%Y-%m-%d)

# Remove task from next.md (counterbalance to SELECT)
# This cleans up completed task references
if grep -q "^# Next Task: ${TASK_ID}" DOCS/INPROGRESS/next.md; then
  # Remove the entire task section from next.md
  sed -i "/^# Next Task: ${TASK_ID}/,/^# Next Task:/d" DOCS/INPROGRESS/next.md
fi

# Create archive structure
mkdir -p DOCS/TASKS_ARCHIVE/

# Move PRD to archive
mv "DOCS/INPROGRESS/${TASK_ID}_${TASK_NAME}.md" \
   "DOCS/TASKS_ARCHIVE/${TASK_ID}_${TASK_NAME}.md"

# Add archive metadata to file
echo "\n---\n**Archived:** ${COMPLETION_DATE}" >> \
  "DOCS/TASKS_ARCHIVE/${TASK_ID}_${TASK_NAME}.md"
```

---

### 3. Generate Archive Index

Create/update `DOCS/TASKS_ARCHIVE/INDEX.md`:

```markdown
# Archived Tasks

## Phase 1: Foundation & Core Types

- [A1 — Project Initialization](./A1_Project_Initialization.md) ✓ 2025-12-03
- [A2 — Core Types Implementation](./A2_Core_Types.md) ✓ 2025-12-04

## Phase 2: Parser & AST
...
```

---

### 4. Create Commit

```bash
git add DOCS/INPROGRESS/ DOCS/TASKS_ARCHIVE/
git commit -m "Archive completed tasks: ${TASK_LIST}

Moved PRDs to TASKS_ARCHIVE:
- ${TASK_ID_1} — ${TASK_NAME_1}
- ${TASK_ID_2} — ${TASK_NAME_2}

Workspace cleanup after task completion."
```

---

## Execution Modes

### Mode 1: Auto (default)

Archive all completed tasks automatically.

```bash
$ claude "Выполни команду ARCHIVE"
```

**Process:**
- Scans INPROGRESS/ for completed tasks
- Archives all eligible PRDs
- Updates INDEX.md
- Commits changes

---

### Mode 2: Specific Task

Archive a specific task by ID.

```bash
$ claude "ARCHIVE task A1"
$ claude "Archive A1 — Project Initialization"
```

**Process:**
- Verifies task is complete in Workplan
- Removes task from next.md if present
- Archives only specified task
- Updates INDEX.md
- Commits

---

### Mode 3: Dry Run

Show what would be archived without making changes.

```bash
$ claude "ARCHIVE: dry run"
$ claude "Show what would be archived"
```

**Output:**
```
Archiving scan results:

Eligible for archiving (2 tasks):
  [✓] A1 — Project Initialization
      Completed: 2025-12-03
      File: DOCS/INPROGRESS/A1_Project_Initialization.md
      → DOCS/TASKS_ARCHIVE/A1_Project_Initialization.md

  [✓] A2 — Core Types Implementation
      Completed: 2025-12-04
      File: DOCS/INPROGRESS/A2_Core_Types.md
      → DOCS/TASKS_ARCHIVE/A2_Core_Types.md

Not eligible (1 task):
  [~] A3 — Domain Types
      Reason: Currently active in next.md

Run without --dry-run to archive.
```

---

## Example Output

```bash
$ claude "Выполни команду ARCHIVE"

╔════════════════════════════════════════════════════════════╗
║  ARCHIVE — Clean Workspace                                 ║
╚════════════════════════════════════════════════════════════╝

Scanning DOCS/INPROGRESS/ for completed tasks...

Found 2 completed tasks:
  [✓] A1 — Project Initialization (completed 2025-12-03)
  [✓] A2 — Core Types Implementation (completed 2025-12-04)

Safety checks:
  [✓] Both marked [x] in Workplan
  [✓] Neither is active in next.md
  [✓] PRD files exist

─────────────────────────────────────────────────────────────

Archiving A1 — Project Initialization...
  ✓ Removed from next.md (counterbalance to SELECT)
  ✓ Moved: INPROGRESS/A1_Project_Initialization.md
       → TASKS_ARCHIVE/A1_Project_Initialization.md
  ✓ Added archive metadata (completion date)

Archiving A2 — Core Types Implementation...
  ✓ Removed from next.md (counterbalance to SELECT)
  ✓ Moved: INPROGRESS/A2_Core_Types.md
       → TASKS_ARCHIVE/A2_Core_Types.md
  ✓ Added archive metadata (completion date)

─────────────────────────────────────────────────────────────

Updating DOCS/TASKS_ARCHIVE/INDEX.md...
  ✓ Added A1 to Phase 1 section
  ✓ Added A2 to Phase 1 section

Creating commit...
  ✓ Committed: "Archive completed tasks: A1, A2"
  ✓ Pushed to remote

─────────────────────────────────────────────────────────────

✅ Archived 2 tasks successfully

Workspace status:
  📂 INPROGRESS: 1 active task (A3)
  📦 ARCHIVE: 2 completed tasks

Clean workspace maintained! 🎉
```

---

## Archive Structure

```
DOCS/
├── INPROGRESS/              # Active work only
│   ├── next.md              # Current task
│   └── A3_Domain_Types.md   # Current task PRD
│
└── TASKS_ARCHIVE/           # Completed tasks
    ├── INDEX.md             # Organized by phase
    ├── A1_Project_Initialization.md
    ├── A2_Core_Types.md
    └── ...
```

**INDEX.md format:**
```markdown
# Archived Tasks

Quick reference to all completed tasks organized by phase.

## Phase 1: Foundation & Core Types

### Track A: Core Compiler
- ✅ [A1 — Project Initialization](./A1_Project_Initialization.md)
  - Completed: 2025-12-03
  - Duration: 47 minutes (estimated 2 hours)
  - Deliverables: Package.swift, module structure, build verification

- ✅ [A2 — Core Types Implementation](./A2_Core_Types.md)
  - Completed: 2025-12-04
  - Duration: 3.5 hours (estimated 4 hours)
  - Deliverables: SourceLocation, CompilerError, FileSystem protocol

### Track B: Resolver
...

## Phase 2: Parser & AST
...
```

---

## Safety Features

### Pre-Archive Checks

Before archiving, verify:

1. **Task is complete:**
   ```bash
   grep "^\- \[x\].*${TASK_ID}" DOCS/Workplan.md
   ```

2. **Task is not currently being worked on:**
   ```bash
   # Skip if task is in next.md AND not marked completed
   ! (grep -q "^# Next Task: ${TASK_ID}" DOCS/INPROGRESS/next.md && \
      ! grep -q "Status.*✅.*Completed" DOCS/INPROGRESS/next.md)
   ```

3. **PRD file exists:**
   ```bash
   test -f "DOCS/INPROGRESS/${TASK_ID}_*.md"
   ```

4. **Git is clean:**
   ```bash
   git status --porcelain | wc -l == 0
   ```

### Non-Destructive

- Uses `mv` (not `rm`) — files preserved
- Creates commit before push — can revert
- Maintains git history — can restore

### Recovery

If accidentally archived:
```bash
# Restore from archive
mv DOCS/TASKS_ARCHIVE/A1_Project_Initialization.md \
   DOCS/INPROGRESS/A1_Project_Initialization.md

# Or revert commit
git revert <archive_commit_hash>
```

---

## Integration with Workflow

```
SELECT → PLAN → EXECUTE → Task complete
                            ↓
                        [Time passes]
                            ↓
                        ARCHIVE ← Clean workspace
                            ↓
                        SELECT (next task)
```

**When to run ARCHIVE:**
- After completing multiple tasks (batch cleanup)
- Before starting new phase
- When INPROGRESS/ becomes cluttered
- End of sprint/milestone

**Not required after every task** — can accumulate completed PRDs and archive periodically.

---

## Command Variants

```bash
# Archive all completed tasks
claude "Выполни команду ARCHIVE"
claude "Archive completed tasks"

# Archive specific task
claude "ARCHIVE task A1"
claude "Archive A1 — Project Initialization"

# Dry run (preview)
claude "ARCHIVE: dry run"
claude "Show what would be archived"

# Force (skip safety checks - use with caution)
claude "ARCHIVE: force"  # Archives even if safety checks fail
```

---

## Error Handling

### No Completed Tasks

```
ℹ️  No tasks ready for archiving

INPROGRESS status:
  [~] A3 — Domain Types (in progress, in next.md)
  [~] A4 — Parser (not started, [ ] in Workplan)

Nothing to archive. Continue working!
```

### Active Task in Archive List

```
✗ Cannot archive A3 — Domain Types

Reason: Task is currently active in next.md

Complete the task first:
  $ claude "Выполни команду EXECUTE"

Then archive later.
```

### Incomplete Task

```
✗ Cannot archive A4 — Parser

Reason: Task not marked complete in Workplan
Status: [ ] (not done)

Complete the task first, then archive.
```

---

## Benefits

1. **Clean Workspace**
   - INPROGRESS/ contains only active work
   - Easy to find current task PRD
   - No clutter from old tasks

2. **Preserved History**
   - All completed PRDs saved
   - Searchable archive
   - Reference for future tasks

3. **Organized by Phase**
   - INDEX.md groups by project phase
   - Easy to see phase completion
   - Quick reference to past work

4. **Maintenance**
   - Periodic cleanup keeps workspace clean
   - Archive grows naturally with project
   - Git history intact

---

## Exceptions

- **No tasks to archive** → "Nothing to archive. Continue working!"
- **All tasks active** → "All PRDs in INPROGRESS are active. Complete tasks first."
- **Git not clean** → "Commit changes first, then archive."
- **Archive already exists** → "Task already archived. Check TASKS_ARCHIVE/."

---

## Notes

- ARCHIVE is optional — not required for workflow
- Can run periodically (weekly, end of phase, etc.)
- INDEX.md auto-generated — don't edit manually
- Archive is just moved files — can restore easily
- Consider archiving before major milestones

---

## Future Enhancements

- **Statistics:** Add metrics to INDEX.md (total time, accuracy of estimates)
- **Search:** Add command to search archived tasks
- **Compression:** Compress old archives (e.g., Phase 1 to .tar.gz after Phase 3)
- **Links:** Add links to git commits in archive metadata
- **Reports:** Generate phase completion reports from archive

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-03 | Claude | Initial ARCHIVE command specification |
