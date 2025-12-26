# PRD — BUG-CE1-001: Lenient Compile Includes Markdown Filename Heading

**Task ID:** BUG-CE1-001
**Task Name:** Lenient Compile Includes Markdown Filename Heading
**Priority:** P0 (Critical)
**Phase:** Hotfixes & Bug Reports
**Estimated Effort:** 1 hour
**Dependencies:** None
**Status:** In Progress
**Date:** 2025-12-27
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Document a lenient compilation bug where compiling `DOCS/examples/with-markdown.hc` emits an extra Markdown filename heading (`## prerequisites.md`) that should not appear in output.

**Restatement in Precise Terms:**
1. Create a bug report describing the incorrect output line.
2. Capture repro steps and expected vs actual output.
3. Record impact and note any suspected component.

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| Bug report document | Markdown report saved in `DOCS/INPROGRESS/` with repro, expected/actual, and impact |
| Summary document | Task summary with verification notes |

### 1.3 Success Criteria

1. ✅ Bug report exists with precise repro steps and output snippet
2. ✅ Expected and actual output are clearly contrasted
3. ✅ Task summary saved in `DOCS/INPROGRESS/`

### 1.4 Constraints

- Documentation-only change (no code fix in this task)
- Use ASCII-only content

### 1.5 Assumptions

- Lenient compilation should not surface Markdown filename headings in output

---

## 2. Structured TODO Plan

### Phase 1: Bug Report Authoring

#### Task 2.1.1: Draft bug report
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** None

**Process:**
1. Create a new bug report file in `DOCS/INPROGRESS/`
2. Record repro steps using `DOCS/examples/with-markdown.hc`
3. Include expected vs actual output snippet
4. Note impact and suspected area (compiler emission/lenient mode)

**Expected Output:**
- `DOCS/INPROGRESS/BUG-CE1-001_Bug_Report.md`

**Acceptance Criteria:**
- ✅ Report includes repro steps, expected output, actual output, and impact

---

### Phase 2: Validation & Documentation

#### Task 2.2.1: Validate and summarize
**Priority:** Medium
**Effort:** 30 minutes
**Dependencies:** 2.1.1

**Process:**
1. Run required validation commands
2. Update `next.md` status and checklist
3. Write task summary

**Expected Output:**
- Passing validation commands recorded in summary
- `DOCS/INPROGRESS/BUG-CE1-001-summary.md`

**Acceptance Criteria:**
- ✅ Summary saved with validation notes

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Bug report describes the incorrect `## prerequisites.md` heading in lenient output
2. Report includes concrete repro steps for VS Code/CLI usage

### 3.2 Non-Functional Requirements

1. Documentation is concise and unambiguous
2. ASCII-only formatting

### 3.3 Acceptance Criteria per Task

- **2.1.1:** Bug report saved with repro + expected/actual output
- **2.2.1:** Validation run noted and summary saved

---

## 4. Verification Plan

```bash
./.github/scripts/restore-build-cache.sh
swift test 2>&1
```

---

## 5. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Bug report lacks clarity | Slows future fix | Use precise repro and output snippets |

---
