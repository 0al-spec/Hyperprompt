# PRD — B2: Dependency Tracker (Memoization)

**Task ID:** B2
**Task Name:** Dependency Tracker
**Priority:** P2 (Medium)
**Phase:** Phase 4 — Reference Resolution
**Estimated Effort:** 4 hours
**Dependencies:** A4 ✅
**Status:** In Progress
**Date:** 2025-12-21
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Optimize circular dependency detection for deep reference trees by memoizing membership and index lookups in the dependency tracker.

**Restatement in Precise Terms:**
Implement memoized lookup structures in `DependencyTracker` so that:
1. Cycle membership checks are O(1) instead of linear stack scans
2. Cycle path construction uses cached indexes instead of repeated search
3. Behavior and error messages remain identical to current implementation

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| Memoized lookup map | Track stack membership/index for fast cycle checks |
| Updated tracker logic | Push/pop and cycle detection using memoization |
| Tests | Coverage for memoized behavior and stack consistency |

### 1.3 Success Criteria

The implementation is successful when:
1. ✅ `checkAndPush` and `getCyclePath` preserve existing outputs
2. ✅ Stack membership checks no longer scan the entire stack
3. ✅ Tests cover memoized push/pop consistency and cycle path output

### 1.4 Constraints

**Technical Constraints:**
- No new dependencies
- Preserve deterministic ordering and error formatting
- Keep API surface unchanged

**Design Constraints:**
- Memoized structures must stay consistent with the stack
- Works with pre-populated `initialStack`

### 1.5 Assumptions

1. Paths are canonicalized before being added to the stack
2. A path only appears once in the stack (unless cycle detection blocks it)
3. Reference resolution remains single-threaded

### 1.6 External Dependencies

| Dependency | Purpose | Version |
|-----------|---------|---------|
| Resolver | `DependencyTracker` | Hyperprompt 0.1+ |

---

## 2. Structured TODO Plan

### Phase 1: Memoization Data Structures

#### Task 2.1.1: Add stack index cache
**Priority:** Medium
**Effort:** 45 minutes
**Dependencies:** None

**Process:**
1. Add a `stackIndexByPath` dictionary to `DependencyTracker`
2. Initialize it from `initialStack` in `init`
3. Update `checkAndPush` and `pop` to keep the dictionary in sync

**Expected Output:**
- Updated `Sources/Resolver/DependencyTracker.swift`

**Acceptance Criteria:**
- ✅ Dictionary accurately reflects stack contents and indexes

---

### Phase 2: Optimize cycle detection

#### Task 2.2.1: Use memoized indexes for cycle detection
**Priority:** Medium
**Effort:** 45 minutes
**Dependencies:** 2.1.1

**Process:**
1. Replace `firstIndex(of:)` lookups with dictionary lookups
2. Build cycle paths using cached start index
3. Preserve current cycle path format and ordering

**Expected Output:**
- Faster cycle checks for deep stacks

**Acceptance Criteria:**
- ✅ `getCyclePath` and `checkAndPush` return identical cycle paths to current implementation

---

### Phase 3: Tests

#### Task 2.3.1: Add memoization consistency tests
**Priority:** Medium
**Effort:** 60 minutes
**Dependencies:** 2.2.1

**Process:**
1. Add test that push/pop updates memoized membership and allows re-add
2. Add test that initialStack builds memoized indexes correctly
3. Ensure existing cycle path tests still pass

**Expected Output:**
- Updated `Tests/ResolverTests/DependencyTrackerTests.swift`

**Acceptance Criteria:**
- ✅ New tests pass and protect memoization invariants

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. `checkAndPush` uses memoized membership lookup
2. `getCyclePath` uses memoized stack index
3. `pop` keeps memoized state consistent

### 3.2 Non-Functional Requirements

1. No change to public API
2. Deterministic output identical to prior implementation
3. Memory overhead limited to one dictionary of stack size

### 3.3 Acceptance Criteria per Task

- **2.1.1:** Stack index cache is consistent with stack
- **2.2.1:** Cycle path construction unchanged
- **2.3.1:** New tests covering memoized invariants pass

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
| Cache out of sync with stack | Incorrect cycle detection | Update cache on every push/pop; add tests |
| Regression in cycle path formatting | Test expectations break | Preserve current cycle path assembly logic |


---
**Archived:** 2025-12-21
