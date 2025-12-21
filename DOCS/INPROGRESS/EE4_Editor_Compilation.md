# PRD — EE4: Editor Compilation (EditorEngine)

**Task ID:** EE4
**Task Name:** Editor Compilation
**Priority:** P1 (High)
**Phase:** Phase 10 — Editor Engine Module
**Estimated Effort:** 3 hours
**Dependencies:** EE3 (Link Resolution) ✅
**Status:** In Progress
**Date:** 2025-12-21
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Provide editor-facing compilation that mirrors CLI output byte-for-byte while returning diagnostics in a non-throwing API suitable for IDE integrations.

**Restatement in Precise Terms:**
Implement an `EditorCompiler` wrapper that:
1. Accepts entry file + options
2. Invokes the core compiler pipeline deterministically
3. Returns compiled output and diagnostics without throwing
4. Matches CLI output exactly for the same inputs

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| `CompileOptions` | Editor compilation configuration (mode, root, output, stats) |
| `CompileResult` | Output + diagnostics + optional manifest/stats |
| `EditorCompiler` | Wrapper around `CompilerDriver` for editor usage |
| Tests | Unit tests and integration tests validating CLI parity |

### 1.3 Success Criteria

The implementation is successful when:
1. ✅ `EditorCompiler` returns output matching CLI byte-for-byte
2. ✅ Errors are returned as diagnostics (no throwing in public API)
3. ✅ Strict/lenient modes behave the same as CLI
4. ✅ Unit tests and integration tests pass (5+ unit, 4+ integration)

### 1.4 Constraints

**Technical Constraints:**
- Must reuse `CompilerDriver` and existing core modules
- Deterministic output required
- No new dependencies

**Design Constraints:**
- Public API must not throw for compilation failures
- Diagnostics must be complete and ordered deterministically

### 1.5 Assumptions

1. CLI output is the source of truth for correctness
2. Editor clients will provide workspace root or rely on defaults
3. Statistics and manifests are optional for editor use

### 1.6 External Dependencies

| Dependency | Purpose | Version |
|-----------|---------|---------|
| CLI module | CompilerDriver | Hyperprompt 0.1+ |
| Core diagnostics | Error reporting | Hyperprompt 0.1+ |
| Statistics | Optional stats collection | Hyperprompt 0.1+ |

---

## 2. Structured TODO Plan

### Phase 0: API Design

#### Task 2.0.1: Define `CompileOptions`
**Priority:** High
**Effort:** 20 minutes
**Dependencies:** None

**Input:**
- CLI compiler options

**Process:**
1. Define `CompileOptions` with:
   - `mode: ResolutionMode`
   - `workspaceRoot: String?`
   - `outputPath: String?`
   - `emitManifest: Bool`
   - `collectStats: Bool`
2. Provide sensible defaults matching CLI

**Expected Output:**
- Swift file: `Sources/EditorEngine/CompileOptions.swift`

**Acceptance Criteria:**
- ✅ Options compile and are documented

---

#### Task 2.0.2: Define `CompileResult`
**Priority:** High
**Effort:** 20 minutes
**Dependencies:** 2.0.1

**Input:**
- CLI compiler outputs

**Process:**
1. Define `CompileResult` with:
   - `output: String?`
   - `diagnostics: [CompilerError]`
   - `manifest: String?`
   - `statistics: String?`
2. Add helper `hasErrors` property

**Expected Output:**
- Swift file: `Sources/EditorEngine/CompileResult.swift`

**Acceptance Criteria:**
- ✅ Result usable in tests and editor clients

---

### Phase 1: EditorCompiler Implementation

#### Task 2.1.1: Implement `EditorCompiler`
**Priority:** High
**Effort:** 60 minutes
**Dependencies:** 2.0.2

**Input:**
- `CompilerDriver`
- `CompileOptions`

**Process:**
1. Implement `EditorCompiler.compile(entryFile:options:)`:
   - Invoke `CompilerDriver` directly
   - Capture output in memory
   - Catch errors and convert to diagnostics
2. Ensure deterministic output (same as CLI)
3. Avoid throwing in public API

**Expected Output:**
- Swift file: `Sources/EditorEngine/EditorCompiler.swift`

**Acceptance Criteria:**
- ✅ Output matches CLI for same inputs
- ✅ Diagnostics capture all errors

---

### Phase 2: Tests

#### Task 2.2.1: Add Unit Tests
**Priority:** High
**Effort:** 40 minutes
**Dependencies:** 2.1.1

**Process:**
1. Unit tests for:
   - Valid compilation returns output
   - Missing file returns diagnostics
   - Strict vs lenient behavior
   - Manifest/statistics optional behavior
   - Deterministic output

**Expected Output:**
- `Tests/EditorEngineTests/EditorCompilerTests.swift`

**Acceptance Criteria:**
- ✅ 5+ unit tests pass

---

#### Task 2.2.2: Add Integration Tests
**Priority:** Medium
**Effort:** 40 minutes
**Dependencies:** 2.2.1

**Process:**
1. Integration tests comparing CLI and EditorCompiler output
2. Use existing test fixtures (V01-V10)
3. Compare output byte-for-byte

**Expected Output:**
- `Tests/EditorEngineTests/EditorCompilerIntegrationTests.swift`

**Acceptance Criteria:**
- ✅ 4+ integration tests pass

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Compile Hypercode entry files with editor-friendly API
2. Return diagnostics without throwing
3. Match CLI output exactly
4. Support optional manifest/statistics outputs

### 3.2 Non-Functional Requirements

1. Deterministic output across platforms
2. No added dependencies
3. Minimal overhead for editor use

### 3.3 Acceptance Criteria per Task

- **2.0.1:** CompileOptions defined with defaults
- **2.0.2:** CompileResult defined and usable
- **2.1.1:** EditorCompiler implemented without throws
- **2.2.1:** Unit tests pass
- **2.2.2:** Integration tests pass

---

## 4. Edge Cases & Failure Scenarios

- Missing entry file
- Strict vs lenient mismatches
- Output path invalid
- Manifest/statistics optionality

---

## 5. Verification Plan

### Mandatory

```bash
./.github/scripts/restore-build-cache.sh
swift test 2>&1
```

---

## 6. Quality Checklist

- [ ] Output matches CLI byte-for-byte
- [ ] Diagnostics returned without throwing
- [ ] Tests cover strict/lenient modes
- [ ] Integration tests compare CLI/editor output

---

## 7. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Output mismatch vs CLI | Editor inconsistencies | Use CompilerDriver directly, compare in tests |
| Diagnostics incomplete | Poor editor UX | Capture and return all CompilerError instances |
