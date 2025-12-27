# PRD — DOC-REORG-001: Move User Docs to Documentation.docc

**Task ID:** DOC-REORG-001
**Task Name:** Move User Docs to Documentation.docc
**Priority:** P0 (Critical)
**Phase:** Hotfixes & Bug Reports
**Estimated Effort:** 2 hours
**Dependencies:** None
**Status:** In Progress
**Date:** 2025-12-27
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Relocate user-facing documentation from `DOCS/` into `Documentation.docc/` (DocC format) while preserving development process docs in `DOCS/`, and ensure all references point to the new locations.

**Restatement in Precise Terms:**
1. Move user documentation files and folders into `Documentation.docc/`.
2. Keep process and workflow docs (commands, rules, PRDs, workplan, in-progress logs) in `DOCS/`.
3. Update links in README and documentation to the new paths.

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| DocC relocation | User docs moved into `Documentation.docc/` |
| Link updates | Internal references updated to new doc paths |
| Tracking update | Workplan/next tracking and summary updated |

### 1.3 Success Criteria

1. User-facing docs are located under `Documentation.docc/`.
2. Process docs remain in `DOCS/`.
3. All internal links resolve to the new locations.

### 1.4 Constraints

- Do not move development process documentation (commands, rules, PRDs, in-progress logs).
- Prefer ASCII content changes unless non-ASCII already present.
- Maintain existing file contents unless path updates are required.

---

## 2. Structured TODO Plan

### Phase 1: Relocate User Documentation

#### Task 2.1.1: Identify user-facing docs
**Priority:** High
**Effort:** 20 minutes
**Dependencies:** None

**Process:**
1. Inventory user-facing docs in `DOCS/` (architecture, usage, troubleshooting, examples, releases).
2. Confirm process docs to keep in `DOCS/` (commands, rules, PRDs, workplan, in-progress logs).

**Expected Output:**
- Confirmed move list for `Documentation.docc/`.

**Acceptance Criteria:**
- List of user docs confirmed before moves.

#### Task 2.1.2: Move user docs into Documentation.docc
**Priority:** High
**Effort:** 40 minutes
**Dependencies:** 2.1.1

**Process:**
1. Create `Documentation.docc/` at repo root (if missing).
2. Move user-facing docs and folders into `Documentation.docc/`.
3. Preserve folder structure and filenames.

**Expected Output:**
- User documentation present under `Documentation.docc/`.

**Acceptance Criteria:**
- No user-facing docs remain in `DOCS/`.

---

### Phase 2: Update References

#### Task 2.2.1: Update top-level entrypoints
**Priority:** High
**Effort:** 20 minutes
**Dependencies:** 2.1.2

**Process:**
1. Update README and quickstart references to `Documentation.docc/` paths.
2. Adjust any other root-level doc references.

**Expected Output:**
- README and quickstart links updated.

**Acceptance Criteria:**
- Root docs reference new doc locations.

#### Task 2.2.2: Update internal doc links
**Priority:** Medium
**Effort:** 30 minutes
**Dependencies:** 2.1.2

**Process:**
1. Search `Documentation.docc/` for `DOCS/` references.
2. Update references for moved docs only (keep process-doc references in `DOCS/`).

**Expected Output:**
- Internal links updated to new paths.

**Acceptance Criteria:**
- No stale references to moved docs remain.

---

### Phase 3: Validation & Tracking

#### Task 2.3.1: Validate doc structure
**Priority:** Medium
**Effort:** 10 minutes
**Dependencies:** 2.2.1, 2.2.2

**Process:**
1. Re-scan for `DOCS/` references under `Documentation.docc/` and confirm only process-doc paths remain.
2. Confirm `Documentation.docc/` contains user docs and examples.

**Expected Output:**
- Clean reference scan results noted in summary.

**Acceptance Criteria:**
- Doc tree matches relocation intent.

#### Task 2.3.2: Update tracking and summary
**Priority:** Medium
**Effort:** 10 minutes
**Dependencies:** 2.3.1

**Process:**
1. Update `DOCS/INPROGRESS/next.md` checklist.
2. Update `DOCS/Workplan.md` status to completed.
3. Write a brief summary in `DOCS/INPROGRESS/DOC-REORG-001-summary.md`.

**Expected Output:**
- Tracking files updated and summary saved.

**Acceptance Criteria:**
- Summary includes scope and verification notes.

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Move user-facing docs into `Documentation.docc/`.
2. Preserve process docs in `DOCS/`.
3. Update references to new locations.

### 3.2 Non-Functional Requirements

1. No accidental content changes to docs beyond path updates.
2. Documentation tree remains navigable from README.

### 3.3 Acceptance Criteria per Task

- **2.1.1:** User docs list confirmed.
- **2.1.2:** Docs moved into `Documentation.docc/`.
- **2.2.1:** README/quickstart updated.
- **2.2.2:** Internal links updated.
- **2.3.1:** Reference scan clean for moved docs.
- **2.3.2:** Tracking and summary updated.

---

## 4. Edge Cases & Failure Scenarios

1. Links to process docs should remain under `DOCS/` and not be moved.
2. Release notes must keep references to their own moved assets.
3. Example paths referenced in docs must match the new `Documentation.docc/examples` path.

---

## 5. Dependencies & Risks

- Risk: Broken references in release notes and validation reports.
- Mitigation: Scan for `DOCS/` references and update only those pointing to moved docs.

---

## 6. Validation Plan

- Use `rg -n "DOCS/" Documentation.docc` to find and resolve stale references.
- Manually verify README links to moved docs.

---

## 7. Quality Checklist

- [ ] Moved docs are in `Documentation.docc/`.
- [ ] Process docs remain in `DOCS/`.
- [ ] README links are updated.
- [ ] Internal references updated.
- [ ] Summary and tracking updated.

---

## 8. Implementation Notes

- Prefer updating links within `Documentation.docc/` to relative paths when possible.
- Avoid reformatting doc contents unrelated to path updates.

---
**Archived:** 2025-12-27
