# PRD — VSC-11: Extension Testing & QA

**Task ID:** VSC-11
**Task Name:** Extension Testing & QA
**Priority:** P0 (Critical)
**Phase:** Phase 14 — VS Code Extension Development
**Estimated Effort:** 4 hours
**Dependencies:** VSC-5, VSC-6, VSC-7 ✅
**Status:** In Progress
**Date:** 2025-12-27
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Add VS Code extension integration tests for core features, cover error handling, and run extension tests in CI.

**Restatement in Precise Terms:**
1. Create integration tests for compile, navigation, diagnostics, and preview.
2. Cover error handling scenarios and multi-root cases where feasible.
3. Add a CI job to run extension tests on PRs.

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| Extension integration tests | VS Code test harness covering core features |
| Error handling coverage | Tests for RPC failure/timeout handling |
| CI job | Executes extension test suite on PRs |

### 1.3 Success Criteria

1. ✅ Integration tests run in VS Code test harness
2. ✅ Core feature flows covered (compile, navigation, diagnostics, preview)
3. ✅ CI job runs extension tests on PRs

### 1.4 Constraints

- No new dependencies beyond VS Code test tooling
- Tests should be deterministic
- Avoid requiring network access

### 1.5 Assumptions

- VS Code test harness is available via `@vscode/test-cli`

---

## 2. Structured TODO Plan

### Phase 1: Integration Tests

#### Task 2.1.1: Add integration tests for core features
**Priority:** High
**Effort:** 2 hours
**Dependencies:** None

**Process:**
1. Add tests for compile commands and output channel
2. Add tests for definition/hover providers
3. Add tests for preview panel creation

**Expected Output:**
- VS Code test suite for core features

**Acceptance Criteria:**
- ✅ Tests run via VS Code test harness

---

### Phase 2: Error Handling & Multi-Root

#### Task 2.2.1: Cover error handling and multi-root cases
**Priority:** Medium
**Effort:** 1 hour
**Dependencies:** 2.1.1

**Process:**
1. Add RPC timeout/engine-not-found scenarios
2. Add multi-root workspace behavior tests (where supported)

**Expected Output:**
- Additional coverage for failure modes

**Acceptance Criteria:**
- ✅ Error handling tests pass reliably

---

### Phase 3: CI Integration

#### Task 2.3.1: Add CI job for extension tests
**Priority:** Medium
**Effort:** 1 hour
**Dependencies:** 2.2.1

**Process:**
1. Update GitHub Actions workflow to run extension tests
2. Ensure job runs on PRs

**Expected Output:**
- CI job executing `npm test` in Tools/VSCodeExtension

**Acceptance Criteria:**
- ✅ CI job executes extension tests successfully

---

### Phase 4: Validation & Documentation

#### Task 2.4.1: Validate and finalize docs
**Priority:** Medium
**Effort:** 30 minutes
**Dependencies:** 2.3.1

**Process:**
1. Restore build cache if available
2. Run `swift test` and extension test suite
3. Update `next.md` checklist and Workplan status
4. Write task summary in `DOCS/INPROGRESS/`

**Expected Output:**
- Passing validation commands noted in summary
- `DOCS/INPROGRESS/VSC-11-summary.md`

**Acceptance Criteria:**
- ✅ Summary saved with validation notes

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Integration tests cover compile, navigation, diagnostics, preview
2. Error handling tests cover RPC failures/timeouts
3. CI job runs extension tests on PRs

### 3.2 Non-Functional Requirements

1. Tests complete in <5 minutes
2. No external network dependencies

### 3.3 Acceptance Criteria per Task

- **2.1.1:** Core integration tests added
- **2.2.1:** Error handling coverage added
- **2.3.1:** CI job added for extension tests
- **2.4.1:** Validation commands recorded in summary

---

## 4. Verification Plan

```bash
./.github/scripts/restore-build-cache.sh
swift test 2>&1
cd Tools/VSCodeExtension
npm test
```

---

## 5. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| VS Code test flakiness | Unstable CI | Use deterministic fixtures and timeouts |
| Missing engine in CI | Tests fail | Use mock RPC client for integration tests |

---
