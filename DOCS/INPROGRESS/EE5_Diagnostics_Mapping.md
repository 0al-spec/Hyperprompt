# PRD — EE5: Diagnostics Mapping (EditorEngine)

**Task ID:** EE5
**Task Name:** Diagnostics Mapping
**Priority:** P1 (High)
**Phase:** Phase 10 — Editor Engine Module
**Estimated Effort:** 2 hours
**Dependencies:** EE4 (Editor Compilation) ✅
**Status:** In Progress
**Date:** 2025-12-21
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Map compiler errors to editor-friendly diagnostics with error codes, severity, and ranges suitable for IDE integrations.

**Restatement in Precise Terms:**
Implement a `Diagnostic` model and a `DiagnosticMapper` that:
1. Converts `CompilerError` instances into structured diagnostics
2. Assigns stable error codes by category (syntax, resolution, IO, internal)
3. Attaches source ranges when locations are available
4. Produces deterministic, ordered output

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| `Diagnostic` struct | Includes code, severity, message, range, related info |
| `DiagnosticSeverity` | Enum for error, warning, info, hint |
| `SourceRange` | Line/column range for editor highlighting |
| `DiagnosticMapper` | Maps `CompilerError` → `Diagnostic` |
| Unit tests | 4+ tests verifying mapping and codes |

### 1.3 Success Criteria

The implementation is successful when:
1. ✅ All `CompilerError` values map to `Diagnostic`
2. ✅ Error codes follow category ranges (E001–E099 syntax, E100–E199 resolution, E200–E299 IO, E900+ internal)
3. ✅ Diagnostics include source range when location exists
4. ✅ Unit tests verify mapping correctness and stability

### 1.4 Constraints

**Technical Constraints:**
- Must reuse existing `CompilerError` category and location
- No new dependencies
- Deterministic output ordering

**Design Constraints:**
- Diagnostics should be stable across runs
- Range mapping uses 1-based lines/columns

### 1.5 Assumptions

1. `CompilerError` includes category, message, and optional location
2. Column information may not be available and should default sensibly
3. Editor clients handle missing range information

### 1.6 External Dependencies

| Dependency | Purpose | Version |
|-----------|---------|---------|
| Core | CompilerError + SourceLocation | Hyperprompt 0.1+ |

---

## 2. Structured TODO Plan

### Phase 0: Data Model

#### Task 2.0.1: Define `Diagnostic` and Supporting Types
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** None

**Process:**
1. Define `DiagnosticSeverity` enum
2. Define `SourcePosition` and `SourceRange` structs
3. Define `Diagnostic` struct with:
   - `code: String`
   - `severity: DiagnosticSeverity`
   - `message: String`
   - `range: SourceRange?`
   - `related: [DiagnosticRelatedInfo]` (optional)

**Expected Output:**
- Swift files in `Sources/EditorEngine/`

**Acceptance Criteria:**
- ✅ Types compile and are documented

---

### Phase 1: Mapping

#### Task 2.1.1: Implement `DiagnosticMapper`
**Priority:** High
**Effort:** 45 minutes
**Dependencies:** 2.0.1

**Process:**
1. Map `CompilerError.category` to code prefix and severity
2. Map `SourceLocation` to `SourceRange` with default column span
3. Use stable code numbering per category
4. Return `Diagnostic` for any `CompilerError`

**Expected Output:**
- `Sources/EditorEngine/DiagnosticMapper.swift`

**Acceptance Criteria:**
- ✅ All error categories map to codes
- ✅ Range present when location exists

---

### Phase 2: Tests

#### Task 2.2.1: Add Diagnostic Mapping Tests
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** 2.1.1

**Process:**
1. Tests for syntax, resolution, IO, internal code ranges
2. Test range mapping with location
3. Test mapping without location
4. Test deterministic code generation

**Expected Output:**
- `Tests/EditorEngineTests/DiagnosticMapperTests.swift`

**Acceptance Criteria:**
- ✅ 4+ tests pass

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Convert `CompilerError` to `Diagnostic`
2. Assign stable error codes by category
3. Include ranges when available

### 3.2 Non-Functional Requirements

1. Deterministic output
2. No added dependencies
3. Minimal overhead

### 3.3 Acceptance Criteria per Task

- **2.0.1:** Types compile and are documented
- **2.1.1:** Mapper outputs codes and ranges
- **2.2.1:** Tests pass

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
| Incorrect codes | Editor UX confusion | Centralize code mapping and test | 
| Missing ranges | Poor highlighting | Default to line range when column unknown |
