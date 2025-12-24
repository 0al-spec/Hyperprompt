# PRD — EE7: SpecificationCore Decision Refactor (EditorEngine)

**Task ID:** EE7
**Task Name:** SpecificationCore Decision Refactor
**Priority:** P1 (High)
**Phase:** Phase 10 — Editor Engine Module
**Estimated Effort:** 4 hours
**Dependencies:** EE6 (Documentation & Testing) ✅
**Status:** ✅ Completed on 2025-12-22
**Date:** 2025-12-22
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Refactor EditorEngine to model decision logic using SpecificationCore (Specification, DecisionSpec, FirstMatchSpec) instead of imperative if/else branches, boolean flags, and ad-hoc decision options.

**Restatement in Precise Terms:**
Implement SpecificationCore-driven decision models across EditorEngine so that:
1. All decision points are expressed as specs (including decisions that currently depend on boolean flags or enum switches).
2. Any priority or branching behavior uses DecisionSpec or FirstMatchSpec.
3. EditorEngine APIs expose spec-based decisions in place of boolean flags.

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| EditorEngine Spec Models | New SpecificationCore specs and decisions for EditorEngine decision points |
| Refactored Decision Paths | EditorEngine logic refactored to use spec evaluation instead of if/else and boolean flags |
| Updated Tests | Unit tests updated/added to cover spec-driven decision behavior |
| Package.swift Update | EditorEngine target explicitly depends on SpecificationCore |

### 1.3 Success Criteria

1. ✅ EditorEngine decision logic is implemented via SpecificationCore specs (DecisionSpec / FirstMatchSpec where applicable)
2. ✅ All boolean flags used solely for decision branching are removed or replaced by spec-driven decisions
3. ✅ Priority-based decisions are represented with FirstMatchSpec (or equivalent DecisionSpec)
4. ✅ Unit tests cover decision specs and ensure behavior parity with previous implementation

### 1.4 Constraints

- Refactor is limited to the EditorEngine module
- No behavior regressions (resolution and compilation outputs must match prior behavior)
- Use SpecificationCore components already vendored by the project

### 1.5 Assumptions

- SpecificationCore documentation in `DOCS/SpecificationCore-documentation` is authoritative
- Existing EditorEngine unit tests can be extended without changing the public API surface (unless explicitly required)

---

## 2. Structured TODO Plan

### Phase 0: Dependency & Inventory

#### Task 2.0.1: Add SpecificationCore Dependency to EditorEngine
**Priority:** High
**Effort:** 0.5 hours

**Process:**
1. Update `Package.swift` to add `SpecificationCore` to the EditorEngine target dependencies.
2. Confirm that EditorEngine sources can import SpecificationCore.

**Acceptance Criteria:**
- ✅ EditorEngine target lists `SpecificationCore` as a dependency

---

#### Task 2.0.2: Audit Decision Points in EditorEngine
**Priority:** High
**Effort:** 0.5 hours

**Process:**
1. Inventory decision logic in:
   - `Sources/EditorEngine/EditorResolver.swift`
   - `Sources/EditorEngine/ProjectIndexer.swift`
   - `Sources/EditorEngine/ProjectIndex.swift`
   - `Sources/EditorEngine/EditorCompiler.swift`
   - `Sources/EditorEngine/CompileOptions.swift`
   - `Sources/EditorEngine/LinkSpan.swift`
   - `Sources/EditorEngine/GlobMatcher.swift`
2. Document each decision point and its current branching behavior.

**Acceptance Criteria:**
- ✅ A list of EditorEngine decision points exists in the PRD task summary (or in code comments if needed)

---

### Phase 1: Specification Modeling

#### Task 2.1.1: Define SpecificationCore Specs for Decisions
**Priority:** High
**Effort:** 1 hour

**Process:**
1. Create a new specs file (e.g., `Sources/EditorEngine/DecisionSpecs.swift`).
2. Define specifications and decisions to replace boolean flags and if/else chains, such as:
   - File type detection (`IsHypercodeSpec`, `IsMarkdownSpec`, `IsTargetFileSpec`)
   - Directory skip decisions (`ShouldSkipDirectorySpec`, `IsIgnoredDirectorySpec`)
   - Path classification decisions (`EditorPathDecisionSpec` using FirstMatchSpec)
   - Resolution mode decisions (strict vs lenient) modeled as DecisionSpec
3. Prefer `DecisionSpec` with `FirstMatchSpec` where priority order matters.

**Acceptance Criteria:**
- ✅ Decision specs compile and map directly to prior branching logic

---

### Phase 2: Refactor EditorEngine Logic

#### Task 2.2.1: Replace Boolean Flags and Branching
**Priority:** High
**Effort:** 1.5 hours

**Process:**
1. Replace boolean flags in `CompileOptions` and `IndexerOptions` with spec-driven decision inputs where applicable.
2. Refactor EditorEngine decision points to use SpecificationCore evaluation:
   - Use `DecisionSpec.decide(_:)` in place of if/else chains.
   - Use `FirstMatchSpec` for ordered decision lists (e.g., path resolution roots, file type classification).
3. Keep non-decision guard/throw paths minimal and only for error handling, not branching logic.

**Acceptance Criteria:**
- ✅ EditorEngine decisions are spec-driven with no ad-hoc branching
- ✅ Public API remains stable unless explicitly required by this refactor

---

### Phase 3: Testing & Validation

#### Task 2.3.1: Update Unit Tests for Decision Specs
**Priority:** High
**Effort:** 0.5 hours

**Process:**
1. Add tests for newly introduced specs and decisions.
2. Update existing EditorEngine tests to validate behavior parity after refactor.
3. Ensure coverage for strict/lenient resolution paths and indexing filters.

**Acceptance Criteria:**
- ✅ Unit tests cover spec-driven decision logic and pass

---

## 3. Verification Plan

### Mandatory

```bash
./.github/scripts/restore-build-cache.sh
swift test 2>&1
```

### Additional Checks

- Confirm EditorEngine compiles with SpecificationCore imports
- Verify EditorEngine behaviors (indexing, resolution, compile options) match pre-refactor tests

---

## 4. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Decision refactor changes behavior | Output mismatch | Add spec-specific tests mirroring previous branching | 
| Over-refactor of non-decision guards | Stability regression | Keep guards only for error handling, not decision logic | 
| API churn from replacing flags | Downstream breakage | Preserve public API surface unless explicitly required |

---

## 5. References

- `DOCS/SpecificationCore-documentation/markdown/documentation/specificationcore/decisionspec.md`
- `DOCS/SpecificationCore-documentation/markdown/documentation/specificationcore/firstmatchspec.md`
- `DOCS/SpecificationCore-documentation/markdown/documentation/specificationcore/booleandecisionadapter.md`
- `DOCS/PRD/PRD_EditorEngine.md`

---
**Archived:** 2025-12-23
