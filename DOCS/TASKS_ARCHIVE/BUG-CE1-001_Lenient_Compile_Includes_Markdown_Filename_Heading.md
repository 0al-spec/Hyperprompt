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

Remove unintended filename headings when embedding resolved Markdown files in lenient (and strict) compilation.

**Restatement in Precise Terms:**
1. Update the Markdown emitter to avoid emitting node headings for resolved markdown file references.
2. Ensure embedded markdown content is adjusted relative to parent headings.
3. Validate output against fixtures and example file.

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| Emitter fix | Skip filename headings for markdown includes |
| Summary report | `DOCS/INPROGRESS/BUG-CE1-001-summary.md` |

### 1.3 Success Criteria

1. Markdown file references no longer emit filename headings.
2. Existing fixtures match expected output.
3. Summary captures validation results.

### 1.4 Constraints

- Do not alter heading generation for non-markdown nodes.
- Keep output deterministic.

---

## 2. Structured TODO Plan

### Phase 1: Implementation

#### Task 2.1.1: Update MarkdownEmitter
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** None

**Process:**
1. Detect markdownFile resolution nodes.
2. Skip heading emission for those nodes.
3. Adjust embedded heading offset relative to parent.

**Expected Output:**
- Updated `Sources/Emitter/MarkdownEmitter.swift`.

**Acceptance Criteria:**
- Markdown filename headings are removed for resolved markdown files.

---

### Phase 2: Validation

#### Task 2.2.1: Validate fixtures and example
**Priority:** Medium
**Effort:** 20 minutes
**Dependencies:** 2.1.1

**Process:**
1. Compare fixtures for markdown include output.
2. Verify `DOCS/examples/with-markdown.hc` output.

**Expected Output:**
- Updated test results documented in summary.

**Acceptance Criteria:**
- Fixture outputs match expected results.

---

### Phase 3: Finalize

#### Task 2.3.1: Update tracking and summary
**Priority:** Medium
**Effort:** 10 minutes
**Dependencies:** 2.2.1

**Process:**
1. Update `DOCS/INPROGRESS/next.md` and `DOCS/Workplan.md`.
2. Write `DOCS/INPROGRESS/BUG-CE1-001-summary.md`.
3. Record validation commands.

**Expected Output:**
- Tracking files updated and summary saved.

**Acceptance Criteria:**
- Summary includes validation notes.

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Markdown file references do not emit filename headings.
2. Embedded markdown heading offsets remain correct.

### 3.2 Non-Functional Requirements

1. No output regression for non-markdown nodes.

### 3.3 Acceptance Criteria per Task

- **2.1.1:** Emitter updated
- **2.2.1:** Fixtures and example validated
- **2.3.1:** Summary and tracking updated

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
| Heading offset regressions | Wrong levels | Use parent depth when skipping headings |

---

---
**Archived:** 2025-12-27
