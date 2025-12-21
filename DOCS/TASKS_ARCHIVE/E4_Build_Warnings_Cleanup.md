# PRD — E4: Build Warnings Cleanup

**Task ID:** E4
**Task Name:** Build Warnings Cleanup
**Priority:** P2 (Medium)
**Phase:** Phase 8 — Testing & Quality Assurance
**Estimated Effort:** 2 hours
**Dependencies:** D2 (compiler driver) ✅, E1 (test corpus) ✅
**Status:** In Progress
**Date:** 2025-12-21
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Remove active build warnings from integration tests and update the build issues log to reflect a clean build.

**Restatement in Precise Terms:**
1. Eliminate unused variable warnings in integration tests
2. Remove unreachable code warnings caused by unconditional `XCTSkip`
3. Verify `swift test` emits zero warnings
4. Update `DOCS/INPROGRESS/build-issues.md` with clean status

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| Updated integration tests | No unused bindings or unreachable code warnings |
| Clean build log | build-issues.md reflects warning-free build |
| Validation | `swift test` output with no warnings |

### 1.3 Success Criteria

The implementation is successful when:
1. ✅ Integration tests compile without warnings
2. ✅ `swift test` output contains zero warnings
3. ✅ build-issues.md reflects clean build status

### 1.4 Constraints

**Technical Constraints:**
- No changes to compiler behavior
- Keep test intent intact
- No new dependencies

**Design Constraints:**
- Maintain existing skip reasons and comments
- Preserve test structure and readability

### 1.5 Assumptions

1. Warnings are limited to integration tests
2. Test skips remain necessary until follow-up tasks

### 1.6 External Dependencies

| Dependency | Purpose | Version |
|-----------|---------|---------|
| IntegrationTests | CompilerDriver tests | Hyperprompt 0.1+ |

---

## 2. Structured TODO Plan

### Phase 1: Test Cleanup

#### Task 2.1.1: Remove unused result warnings
**Priority:** Medium
**Effort:** 30 minutes
**Dependencies:** None

**Process:**
1. Find unused `result` bindings in integration tests
2. Replace with `_ =` or use the value

**Expected Output:**
- Updated `Tests/IntegrationTests/CompilerDriverTests.swift`

**Acceptance Criteria:**
- ✅ No unused-variable warnings

---

#### Task 2.1.2: Remove unreachable code warnings
**Priority:** Medium
**Effort:** 30 minutes
**Dependencies:** None

**Process:**
1. Convert unconditional `throw XCTSkip(...)` to a conditional skip
2. Ensure test body is reachable (even if skipped)

**Expected Output:**
- Updated `Tests/IntegrationTests/CompilerDriverTests.swift`

**Acceptance Criteria:**
- ✅ No unreachable-code warnings

---

### Phase 2: Validation & Documentation

#### Task 2.2.1: Validate warning-free build
**Priority:** Medium
**Effort:** 30 minutes
**Dependencies:** 2.1.1, 2.1.2

**Process:**
1. Run cache restore and `swift test`
2. Confirm no warnings in output

**Expected Output:**
- Clean `swift test` output

**Acceptance Criteria:**
- ✅ `swift test` emits zero warnings

---

#### Task 2.2.2: Update build issues log
**Priority:** Medium
**Effort:** 30 minutes
**Dependencies:** 2.2.1

**Process:**
1. Update `DOCS/INPROGRESS/build-issues.md` with new status
2. Move cleared warnings to Resolved section

**Expected Output:**
- Updated build issues log

**Acceptance Criteria:**
- ✅ build-issues.md reflects clean build

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Integration tests compile without warnings
2. Build issues log updated

### 3.2 Non-Functional Requirements

1. No change in test intent
2. Minimal code changes

### 3.3 Acceptance Criteria per Task

- **2.1.1:** Unused-variable warnings removed
- **2.1.2:** Unreachable-code warnings removed
- **2.2.1:** `swift test` clean
- **2.2.2:** build-issues.md updated

---

## 4. Verification Plan

### Mandatory

```bash
./.github/scripts/restore-build-cache.sh
swift test 2>&1
```

---

## 5. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Warnings persist after edits | Task incomplete | Re-check compiler output, adjust test code |
| Skip logic changes behavior | False test execution | Keep skip reasons and condition visible |


---
**Archived:** 2025-12-21
