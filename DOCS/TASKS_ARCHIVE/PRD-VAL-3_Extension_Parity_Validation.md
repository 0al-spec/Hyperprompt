# PRD — PRD-VAL-3: Extension Parity Validation

**Task ID:** PRD-VAL-3
**Task Name:** Extension Parity Validation
**Priority:** P1 (High)
**Phase:** Phase 15 — PRD Validation & Gap Closure
**Estimated Effort:** 2 hours
**Dependencies:** PRD-VAL-2 ✅
**Status:** In Progress
**Date:** 2025-12-27
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Add a deterministic output diff test to confirm CLI and VS Code extension parity for compiled output.

**Restatement in Precise Terms:**
1. Define a repeatable fixture for parity testing.
2. Add a test that compares CLI compile output with extension compile output.
3. Document any mismatches or known gaps.

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| Parity test | Automated test comparing CLI vs extension output |
| Summary report | `DOCS/INPROGRESS/PRD-VAL-3-summary.md` |

### 1.3 Success Criteria

1. Test compares deterministic output for the same fixture.
2. Any mismatch is flagged and documented.
3. Summary records validation commands and results.

### 1.4 Constraints

- Test must be deterministic across runs.
- Use existing fixtures whenever possible.

### 1.5 Assumptions

- CLI and extension output should match for strict compilation.

---

## 2. Structured TODO Plan

### Phase 1: Test Design

#### Task 2.1.1: Define parity fixture and approach
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** None

**Process:**
1. Choose a fixture from existing test corpus.
2. Decide where the parity test will live (extension tests or Swift tests).
3. Define expected output comparison method.

**Expected Output:**
- Documented fixture choice and test location.

**Acceptance Criteria:**
- Fixture is deterministic and reproducible.

---

### Phase 2: Test Implementation

#### Task 2.2.1: Implement parity test
**Priority:** High
**Effort:** 60 minutes
**Dependencies:** 2.1.1

**Process:**
1. Build CLI output using `hyperprompt compile` or existing APIs.
2. Invoke extension compile path and capture output.
3. Compare outputs and fail on mismatch.

**Expected Output:**
- New test(s) verifying parity.

**Acceptance Criteria:**
- Test fails on mismatch and passes on parity.

---

### Phase 3: Finalize

#### Task 2.3.1: Update tracking and summary
**Priority:** Medium
**Effort:** 15 minutes
**Dependencies:** 2.2.1

**Process:**
1. Update `DOCS/INPROGRESS/next.md` and `DOCS/Workplan.md`.
2. Write `DOCS/INPROGRESS/PRD-VAL-3-summary.md`.
3. Record validation commands.

**Expected Output:**
- Tracking files updated and summary saved.

**Acceptance Criteria:**
- Summary includes validation notes and evidence.

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Parity test compares CLI vs extension output deterministically.
2. Test integrates into existing test suites.

### 3.2 Non-Functional Requirements

1. No reliance on network or external systems.
2. Clear error reporting on mismatch.

### 3.3 Acceptance Criteria per Task

- **2.1.1:** Fixture and approach documented
- **2.2.1:** Parity test implemented
- **2.3.1:** Summary and tracking updates complete

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
| Extension test harness cannot access CLI output | Test blocked | Use CLI driver or Swift-level compile path |
| Output nondeterminism | Flaky tests | Normalize line endings and metadata |

---

---
**Archived:** 2025-12-27
