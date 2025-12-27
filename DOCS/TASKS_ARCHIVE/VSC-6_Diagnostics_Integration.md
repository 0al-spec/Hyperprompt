# PRD — VSC-6: Diagnostics Integration

**Task ID:** VSC-6
**Task Name:** Diagnostics Integration
**Priority:** P0 (Critical)
**Phase:** Phase 14 — VS Code Extension Development
**Estimated Effort:** 4 hours
**Dependencies:** VSC-4*, EE-EXT-2 ✅
**Status:** In Progress
**Date:** 2025-12-27
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Implement diagnostics integration in the VS Code extension, mapping EditorEngine workspace diagnostics into VS Code Problems panel entries.

**Restatement in Precise Terms:**
1. Add a DiagnosticCollection and RPC wiring to call workspace validation.
2. Map diagnostics to VS Code ranges and severities with correct offsets.
3. Ensure diagnostics update on save and clear when fixed.

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| DiagnosticCollection | VS Code diagnostics populated from EditorEngine results |
| RPC wiring | Calls `editor.validateWorkspace` (or equivalent) on save |
| Tests | Coverage for diagnostic mapping and update logic |

### 1.3 Success Criteria

1. ✅ Diagnostics appear in Problems panel after save
2. ✅ Line/column ranges match source locations
3. ✅ Diagnostics clear when issues are resolved

### 1.4 Constraints

- Use existing RPC client and EditorEngine APIs
- No new dependencies
- Maintain consistent setting usage (`diagnosticsEnabled`)

### 1.5 Assumptions

- Editor RPC provides workspace diagnostics endpoint

---

## 2. Structured TODO Plan

### Phase 1: Diagnostics Wiring

#### Task 2.1.1: Implement DiagnosticCollection + RPC wiring
**Priority:** High
**Effort:** 1.5 hours
**Dependencies:** None

**Process:**
1. Create a DiagnosticCollection in activation
2. Add file save handler to request workspace diagnostics
3. Gate execution via `diagnosticsEnabled`

**Expected Output:**
- Diagnostic collection updated from RPC results

**Acceptance Criteria:**
- ✅ Diagnostics show in Problems panel

---

### Phase 2: Mapping & Updates

#### Task 2.2.1: Map diagnostics to VS Code ranges
**Priority:** High
**Effort:** 1.5 hours
**Dependencies:** 2.1.1

**Process:**
1. Convert 1-based line/column to VS Code 0-based ranges
2. Map severity strings to `vscode.DiagnosticSeverity`
3. Ensure diagnostics clear for fixed files

**Expected Output:**
- Correct ranges and severities

**Acceptance Criteria:**
- ✅ Diagnostics point to correct locations and clear when fixed

---

### Phase 3: Tests & Validation

#### Task 2.3.1: Add diagnostics tests
**Priority:** Medium
**Effort:** 45 minutes
**Dependencies:** 2.2.1

**Process:**
1. Add tests for severity and range mapping
2. Add tests for diagnostics clearing behavior

**Expected Output:**
- Diagnostics tests passing

**Acceptance Criteria:**
- ✅ Tests cover mapping and update logic

---

#### Task 2.3.2: Validate and finalize docs
**Priority:** Medium
**Effort:** 30 minutes
**Dependencies:** 2.3.1

**Process:**
1. Restore build cache if available
2. Run `swift test` and extension test suite if configured
3. Update `next.md` checklist and Workplan status
4. Write task summary in `DOCS/INPROGRESS/`

**Expected Output:**
- Passing validation commands noted in summary
- `DOCS/INPROGRESS/VSC-6-summary.md`

**Acceptance Criteria:**
- ✅ Summary saved with validation notes

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Diagnostics are updated on save for Hypercode files
2. Diagnostics are grouped per file and mapped to VS Code ranges
3. Diagnostics can be disabled via settings

### 3.2 Non-Functional Requirements

1. Diagnostics request completes within 200ms for typical files
2. No crashes on missing RPC engine

### 3.3 Acceptance Criteria per Task

- **2.1.1:** DiagnosticCollection populated via RPC
- **2.2.1:** Range and severity mapping correct
- **2.3.1:** Tests added for mapping and update logic
- **2.3.2:** Validation commands recorded in summary

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
| RPC method not available | Diagnostics fail silently | Gracefully log and skip updates |
| Range offsets incorrect | Incorrect highlights | Use explicit 1-based to 0-based mapping |

---

---
**Archived:** 2025-12-27
