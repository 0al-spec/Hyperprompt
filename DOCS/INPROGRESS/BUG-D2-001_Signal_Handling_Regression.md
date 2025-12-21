# PRD — BUG-D2-001: Signal Handling Regression

**Task ID:** BUG-D2-001
**Task Name:** Signal Handling Regression
**Priority:** P1 (High)
**Phase:** Phase 6 — CLI & Integration
**Estimated Effort:** 1 hour
**Dependencies:** D2 ✅
**Status:** In Progress
**Date:** 2025-12-21
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Fix signal handling so SIGINT/SIGTERM are processed even when the main thread is busy during compilation.

**Restatement in Precise Terms:**
1. Move signal dispatch sources off `DispatchQueue.main`
2. Keep exit codes and messages unchanged
3. Ensure no regression in CLI behavior

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| Signal queue change | Dispatch sources run on a dedicated background queue |
| Tests | Existing tests still pass |
| Documentation | Workplan and summary updates |

### 1.3 Success Criteria

1. ✅ SIGINT/SIGTERM handled even during synchronous compile on main thread
2. ✅ Exit codes remain 130 (SIGINT) and 143 (SIGTERM)
3. ✅ `swift test` passes

### 1.4 Constraints

- No new dependencies
- Preserve existing CLI output and exit code mapping

### 1.5 Assumptions

- Dispatch sources can be processed on a background queue while main is busy

---

## 2. Structured TODO Plan

### Phase 1: Implementation

#### Task 2.1.1: Move signal handling off main queue
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** None

**Process:**
1. Add a dedicated serial queue for signal handling
2. Register DispatchSourceSignal on that queue
3. Keep existing SIG_IGN and exit logic

**Expected Output:**
- Updated `Sources/CLI/Hyperprompt.swift`

**Acceptance Criteria:**
- ✅ Signal sources run on a non-main queue

---

### Phase 2: Validation & Documentation

#### Task 2.2.1: Validate tests
**Priority:** Medium
**Effort:** 20 minutes
**Dependencies:** 2.1.1

**Process:**
1. Restore build cache if available
2. Run `swift test`

**Expected Output:**
- Passing test suite

**Acceptance Criteria:**
- ✅ `swift test` passes

---

#### Task 2.2.2: Update task docs
**Priority:** Medium
**Effort:** 10 minutes
**Dependencies:** 2.2.1

**Process:**
1. Update Workplan status
2. Update next.md
3. Write task summary

**Expected Output:**
- Completed docs in DOCS/INPROGRESS

**Acceptance Criteria:**
- ✅ Docs reflect completion

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Dispatch sources run on a dedicated background queue
2. Exit codes and message format unchanged

### 3.2 Non-Functional Requirements

1. No behavior regression outside signal handling
2. Minimal code change

### 3.3 Acceptance Criteria per Task

- **2.1.1:** Signal queue is non-main
- **2.2.1:** Tests pass
- **2.2.2:** Docs updated

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
| Background queue doesn't fire in CLI runtime | Signals still ignored | Use a dedicated serial queue and keep sources alive |

