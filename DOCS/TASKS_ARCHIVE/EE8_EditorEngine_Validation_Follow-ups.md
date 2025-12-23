# PRD — EE8: EditorEngine Validation Follow-ups

**Task ID:** EE8
**Task Name:** EditorEngine Validation Follow-ups
**Priority:** P1 (High)
**Phase:** Phase 10 — Editor Engine Module
**Estimated Effort:** 6 hours
**Dependencies:** EE7 (SpecificationCore Decision Refactor) ✅
**Status:** ✅ Completed on 2025-12-23
**Date:** 2025-12-23
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Complete the EditorEngine validation follow-ups by trait-gating the EditorEngine target/product, removing the CLI dependency via shared orchestration, archiving the EE7 summary, and mapping parser I/O failures to diagnostics without throwing.

**Restatement in Precise Terms:**
Deliver EditorEngine as an optional SwiftPM trait, move compilation orchestration into a shared module that EditorEngine and CLI both consume, archive EE7 summary artifacts, and ensure EditorParser reports file I/O errors as diagnostics rather than thrown errors (with tests).

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| SwiftPM Trait Gate | `Editor` trait in Package.swift and EditorEngine target/product gated by it |
| Shared Compiler Driver Module | CLI and EditorEngine share compilation orchestration without EditorEngine importing CLI |
| EE7 Summary Archive | EE7 summary moved to `DOCS/TASKS_ARCHIVE/` and indexed |
| EditorParser I/O Diagnostics | EditorParser converts read failures into diagnostics, with unit tests |

### 1.3 Success Criteria

1. EditorEngine builds only when `swift build --traits Editor` is used (trait disabled by default).
2. EditorEngine target has no dependency on the CLI target.
3. EE7 summary exists in `DOCS/TASKS_ARCHIVE/EE7-summary.md` and archive index references it.
4. EditorParser I/O errors return a `ParsedFile` with diagnostics and no thrown error.
5. Tests cover EditorParser I/O diagnostic mapping.

### 1.4 Constraints

- Keep public EditorEngine APIs stable except for removing throws where required.
- Shared compile orchestration must preserve CLI behavior and existing tests.
- Follow existing documentation format for archives and summaries.

### 1.5 Assumptions

- SwiftPM traits are supported by the toolchain in use.
- Existing compiler orchestration is encapsulated in `CompilerDriver`.

---

## 2. Structured TODO Plan

### Phase 0: Package & Module Restructure

#### Task 2.0.1: Define SwiftPM `Editor` Trait and Gate EditorEngine
**Priority:** High
**Effort:** 1 hour

**Process:**
1. Add the `Editor` trait to `Package.swift` (disabled by default).
2. Gate the `EditorEngine` product, target, and tests behind the `Editor` trait.
3. Ensure EditorEngine build settings reflect trait availability.

**Acceptance Criteria:**
- `swift build` succeeds without EditorEngine.
- `swift build --traits Editor` includes EditorEngine.

---

#### Task 2.0.2: Extract Compiler Driver Module
**Priority:** High
**Effort:** 1.5 hours

**Process:**
1. Move `CompilerDriver` and its supporting code into a new target (e.g., `CompilerDriver`).
2. Update `CLI` and `EditorEngine` to import the shared module.
3. Update tests importing `CompilerDriver` accordingly.

**Acceptance Criteria:**
- EditorEngine has no `CLI` dependency in `Package.swift`.
- CLI continues to compile and use the shared driver.

---

### Phase 1: Diagnostics & Tests

#### Task 2.1.1: Map EditorParser I/O Errors to Diagnostics
**Priority:** High
**Effort:** 1.5 hours

**Process:**
1. Update `EditorParser.parse(filePath:)` to return `ParsedFile` without throwing.
2. Capture file system read errors as `CompilerError` diagnostics.
3. Preserve current parsing behavior for content-based parsing.

**Acceptance Criteria:**
- I/O failures return `ParsedFile` with diagnostics and no thrown errors.
- Existing parser behavior remains unchanged for valid content.

---

#### Task 2.1.2: Add EditorParser I/O Diagnostic Tests
**Priority:** High
**Effort:** 1 hour

**Process:**
1. Add a unit test that simulates a read failure in EditorParser.
2. Assert returned diagnostics include the I/O error and empty AST.
3. Ensure tests cover both success and failure paths if needed.

**Acceptance Criteria:**
- Tests validate EditorParser diagnostic behavior for I/O errors.

---

### Phase 2: Documentation & Archiving

#### Task 2.2.1: Archive EE7 Summary
**Priority:** Medium
**Effort:** 0.5 hours

**Process:**
1. Move `DOCS/INPROGRESS/EE7-summary.md` to `DOCS/TASKS_ARCHIVE/EE7-summary.md`.
2. Update `DOCS/TASKS_ARCHIVE/INDEX.md` with EE7 entry and summary link.

**Acceptance Criteria:**
- Archive contains EE7 summary and index references it.

---

## 3. Requirements

### 3.1 Functional Requirements

- FR-1: EditorEngine is gated behind the SwiftPM `Editor` trait.
- FR-2: CLI and EditorEngine share `CompilerDriver` without direct CLI dependency.
- FR-3: EditorParser returns diagnostics for file read failures and does not throw.
- FR-4: EE7 summary is archived and indexed.

### 3.2 Non-Functional Requirements

- NFR-1: No regression in CLI behavior or test coverage.
- NFR-2: EditorEngine remains deterministic and matches CLI outputs.
- NFR-3: Documentation and archive index stay consistent with existing format.

### 3.3 Acceptance Criteria per Task

| Task | Acceptance Criteria | Verification |
|------|---------------------|--------------|
| 2.0.1 | Editor trait gates EditorEngine target/product | `swift build` vs `swift build --traits Editor` |
| 2.0.2 | CLI and EditorEngine use shared driver | Inspect `Package.swift`, imports, and build |
| 2.1.1 | EditorParser returns diagnostics for I/O errors | Unit test asserts diagnostics and no throws |
| 2.1.2 | Tests cover I/O diagnostic mapping | `swift test` passes |
| 2.2.1 | EE7 summary archived and indexed | `DOCS/TASKS_ARCHIVE/` contents + INDEX update |

---

## 4. User Interaction Flows

- Editor client invokes `EditorParser.parse(filePath:)` and receives diagnostics instead of exceptions on read failures.
- Developer builds the package without EditorEngine by default and enables it with `--traits Editor` when needed.

---

## 5. Edge Cases & Failure Scenarios

- File read errors (missing file, permission denied, invalid encoding) should surface as I/O diagnostics.
- Trait disabled: EditorEngine product/target should be unavailable without affecting CLI builds.

---

## 6. Dependencies & Impact

- Package.swift changes affect build graph; validate target dependencies.
- CompilerDriver module affects CLI, EditorEngine, and integration tests.

---

## 7. Quality Checklist

- [x] EditorEngine target/product gated by SwiftPM trait.
- [x] EditorEngine no longer depends on CLI.
- [x] Shared CompilerDriver target used by CLI and EditorEngine.
- [x] EditorParser I/O errors mapped to diagnostics with tests.
- [x] EE7 summary archived and indexed.

---

## 8. Implementation Notes / Templates

### 8.1 Package.swift Trait Gate (Pseudo-Template)

```swift
let package = Package(
    name: "Hyperprompt",
    traits: [
        "Editor": .init(description: "Enable EditorEngine", default: false)
    ],
    products: [
        .library(
            name: "EditorEngine",
            targets: ["EditorEngine"],
            traits: ["Editor"]
        )
    ],
    targets: [
        .target(
            name: "EditorEngine",
            dependencies: ["CompilerDriver", "Core", "Parser", "Resolver", "Emitter", "Statistics", "HypercodeGrammar", "SpecificationCore"],
            traits: ["Editor"]
        ),
        .testTarget(
            name: "EditorEngineTests",
            dependencies: ["EditorEngine", "CompilerDriver"],
            traits: ["Editor"]
        )
    ]
)
```

---

## 9. Verification Commands

```bash
./.github/scripts/restore-build-cache.sh
swift test 2>&1
```

---

## 10. Open Questions

- Confirm SwiftPM trait syntax for the current toolchain and adjust Package.swift accordingly.

---
**Archived:** 2025-12-23
