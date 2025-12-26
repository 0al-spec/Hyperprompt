# PRD — EE-EXT-1B: Fix EditorParser linkAt Regression

**Task ID:** EE-EXT-1B
**Task Name:** Fix EditorParser linkAt Regression
**Priority:** P0 (Critical)
**Phase:** Phase 12 — EditorEngine API Enhancements
**Estimated Effort:** 2 hours
**Dependencies:** EE-EXT-1 ✅
**Status:** In Progress
**Date:** 2025-12-27
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Restore EditorParser link span extraction so `linkAt` queries work under the Editor trait, including correct handling of `@"..."` spans and UTF-8 byte offsets.

**Restatement in Precise Terms:**
1. Extract link spans from source content in a way that matches the lexer/normalization rules.
2. Ensure byte/column/line ranges include the optional `@` prefix.
3. Preserve link span extraction even if tokenization fails.
4. Pass `EditorParserLinkAtTests` under `swift test --traits Editor`.

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| Parser fix | Updated link span extraction logic in EditorParser |
| Tests | `EditorParserLinkAtTests` passing under Editor trait |
| Docs | Task summary and updated status in Workplan/next.md |

### 1.3 Success Criteria

1. ✅ Link spans extracted for `@"..."` and `"..."` references
2. ✅ Column/byte ranges match UTF-8 offsets with 1-based columns
3. ✅ `swift test --traits Editor` passes for EditorParserLinkAtTests

### 1.4 Constraints

- No new dependencies
- Maintain deterministic output
- Keep link span extraction aligned with normalization rules

### 1.5 Assumptions

- Normalized content is the intended source for tokenization and span calculation

---

## 2. Structured TODO Plan

### Phase 1: Extraction Fix

#### Task 2.1.1: Restore link span extraction
**Priority:** High
**Effort:** 45 minutes
**Dependencies:** None

**Process:**
1. Inspect current `EditorParser.parse` implementation
2. Align link span extraction with normalized content
3. Ensure spans are collected before tokenization and preserved on lexer errors

**Expected Output:**
- Updated `Sources/EditorEngine/EditorParser.swift`

**Acceptance Criteria:**
- ✅ Link spans computed even when tokenization fails

---

### Phase 2: Range Validation

#### Task 2.2.1: Validate byte/column ranges
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** 2.1.1

**Process:**
1. Verify UTF-8 byte offsets include `@` prefix when present
2. Ensure column ranges are 1-based and include the prefix
3. Confirm link spans match test expectations

**Expected Output:**
- Corrected range math if needed

**Acceptance Criteria:**
- ✅ Ranges align with EditorParserLinkAtTests

---

### Phase 3: Validation & Documentation

#### Task 2.3.1: Run tests and finalize docs
**Priority:** Medium
**Effort:** 45 minutes
**Dependencies:** 2.2.1

**Process:**
1. Restore build cache if available
2. Run `swift test --traits Editor`
3. Update `next.md` checklist
4. Update Workplan status and task summary

**Expected Output:**
- Passing test run
- `DOCS/INPROGRESS/EE-EXT-1B-summary.md`

**Acceptance Criteria:**
- ✅ Editor trait test run passes
- ✅ Summary saved with validation notes

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Link span extraction must detect inline `@"..."` and plain `"..."` literals
2. Link span extraction must return ranges that include the `@` prefix
3. Link spans must be returned even when the lexer fails

### 3.2 Non-Functional Requirements

1. Deterministic extraction for identical inputs
2. O(n) scan over source content

### 3.3 Acceptance Criteria per Task

- **2.1.1:** Link spans computed pre-tokenization and preserved on lexer errors
- **2.2.1:** Byte and column ranges match tests for @ prefix and UTF-8
- **2.3.1:** `swift test --traits Editor` passes for EditorParserLinkAtTests

---

## 4. Verification Plan

```bash
./.github/scripts/restore-build-cache.sh
swift test --traits Editor 2>&1
```

---

## 5. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Range math mismatch for UTF-8 | Failing linkAt tests | Use UTF-8 byte offset calculations and 1-based columns |
| Tokenization errors drop spans | Editor features broken | Compute spans before tokenization and preserve on failure |

---
