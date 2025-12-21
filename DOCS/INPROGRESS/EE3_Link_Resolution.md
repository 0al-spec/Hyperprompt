# PRD — EE3: Link Resolution (EditorEngine)

**Task ID:** EE3
**Task Name:** Link Resolution
**Priority:** P1 (High)
**Phase:** Phase 10 — Editor Engine Module
**Estimated Effort:** 2 hours
**Dependencies:** EE2 (Parsing with Link Spans) ✅
**Status:** In Progress
**Date:** 2025-12-21
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Implement editor-facing link resolution that mirrors CLI behavior, returning structured resolution results and diagnostics without throwing from the public EditorEngine API.

**Restatement in Precise Terms:**
Create an `EditorResolver` that:
1. Accepts `LinkSpan` and a source file context
2. Resolves file references using existing resolver rules
3. Returns a `ResolvedTarget` enum indicating resolution outcome
4. Produces diagnostics for missing/ambiguous/invalid targets without fatal errors

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| `ResolvedTarget` enum | Represents link resolution outcomes (inline, md, hc, invalid, etc.) |
| `EditorResolver` | Wrapper around `ReferenceResolver` with editor-friendly API |
| Diagnostics mapping | Structured errors for missing/ambiguous/forbidden/invalid targets |
| Unit tests | 6+ tests including path traversal rejection |

### 1.3 Success Criteria

The implementation is successful when:
1. ✅ `ResolvedTarget` covers inline, markdown, hypercode, forbidden, invalid, ambiguous
2. ✅ Resolution behavior matches CLI rules exactly
3. ✅ Missing targets return diagnostics, not thrown errors
4. ✅ Ambiguous matches report all candidates
5. ✅ Unit tests cover path traversal rejection and core cases

### 1.4 Constraints

**Technical Constraints:**
- Must reuse existing `ReferenceResolver` and path validation specs
- Must not introduce new dependencies
- Must be deterministic across platforms

**Design Constraints:**
- Editor API must not throw for resolution failures
- Must respect workspace root resolution order:
  explicit root → entry file directory → current working directory

### 1.5 Assumptions

1. `ReferenceResolver` already encodes CLI semantics for path validation
2. Link spans provide literal text and source file path
3. Editor clients will interpret `ResolvedTarget` and diagnostics

### 1.6 External Dependencies

| Dependency | Purpose | Version |
|-----------|---------|---------|
| Resolver module | Reference resolution | Hyperprompt 0.1+ |
| Core diagnostics | Error reporting | Hyperprompt 0.1+ |
| HypercodeGrammar specs | Path heuristics | Hyperprompt 0.1+ |

---

## 2. Structured TODO Plan

### Phase 0: API Design

#### Task 2.0.1: Define `ResolvedTarget` Enum
**Priority:** High
**Effort:** 20 minutes
**Dependencies:** None

**Input:**
- Workplan EE3 requirements
- Existing `ResolutionKind` cases in Parser/Resolver

**Process:**
1. Define `ResolvedTarget` with cases:
   - `inlineText`
   - `markdownFile(path: String)`
   - `hypercodeFile(path: String)`
   - `forbidden(extension: String)`
   - `invalid(reason: String)`
   - `ambiguous(candidates: [String])`
2. Add documentation comments describing each case

**Expected Output:**
- Swift file: `Sources/EditorEngine/ResolvedTarget.swift`

**Acceptance Criteria:**
- ✅ Enum compiles and is equatable
- ✅ Cases cover all failure modes

---

### Phase 1: EditorResolver Implementation

#### Task 2.1.1: Implement `EditorResolver`
**Priority:** High
**Effort:** 60 minutes
**Dependencies:** 2.0.1

**Input:**
- `ReferenceResolver` implementation
- `LinkSpan` and `ParsedFile` types

**Process:**
1. Implement `EditorResolver` with:
   - `init(fileSystem: FileSystem, workspaceRoot: String?, mode: ResolutionMode)`
   - `resolve(link: LinkSpan, sourceFile: String) -> ResolvedTarget`
   - `resolveAll(parsed: ParsedFile) -> (targets: [ResolvedTarget], diagnostics: [CompilerError])`
2. Use `LooksLikeFileReferenceSpec` for heuristic check and short-circuit inline text
3. Use `ReferenceResolver` to resolve within the correct root order
4. Return diagnostics instead of throwing on failures
5. On ambiguous matches, return `ResolvedTarget.ambiguous` with candidates

**Expected Output:**
- Swift file: `Sources/EditorEngine/EditorResolver.swift`

**Acceptance Criteria:**
- ✅ Resolutions match CLI behavior
- ✅ No throwing for missing/invalid targets
- ✅ Diagnostics retained in results

---

### Phase 2: Tests

#### Task 2.2.1: Add Resolver Tests
**Priority:** High
**Effort:** 40 minutes
**Dependencies:** 2.1.1

**Input:**
- EditorEngine test utilities

**Process:**
1. Write tests for:
   - Inline text returns `.inlineText`
   - Markdown link resolves to `.markdownFile`
   - Hypercode link resolves to `.hypercodeFile`
   - Forbidden extension returns `.forbidden`
   - Path traversal is rejected with `.invalid`
   - Ambiguous matches return `.ambiguous` with candidates
2. Use `MockFileSystem` or temp filesystem fixtures

**Expected Output:**
- `Tests/EditorEngineTests/EditorResolverTests.swift`

**Acceptance Criteria:**
- ✅ 6+ tests pass
- ✅ Path traversal rejection verified

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Resolve link spans using existing resolver semantics
2. Return structured results for all success/failure cases
3. Preserve diagnostics for missing/invalid references
4. Maintain deterministic behavior and ordering

### 3.2 Non-Functional Requirements

1. No added dependencies
2. Deterministic across platforms
3. Minimal overhead (single-pass resolution)

### 3.3 Acceptance Criteria per Task

- **2.0.1:** `ResolvedTarget` compiles and covers all outcomes
- **2.1.1:** `EditorResolver` matches CLI semantics and returns diagnostics
- **2.2.1:** Tests pass, including path traversal rejection

---

## 4. User Interaction Flow (Editor Perspective)

1. Editor parses file to get `ParsedFile`
2. Editor calls `EditorResolver.resolveAll(parsed:)`
3. Editor displays resolved targets + diagnostics

---

## 5. Edge Cases & Failure Scenarios

- Ambiguous matches across multiple search roots
- Missing referenced files (strict vs lenient mode)
- Path traversal attempts (`../`)
- References with spaces or mixed case extensions

---

## 6. Verification Plan

### Mandatory

```bash
./.github/scripts/restore-build-cache.sh
swift test 2>&1
```

---

## 7. Quality Checklist

- [ ] Resolutions match CLI behavior
- [ ] No new dependencies introduced
- [ ] Ambiguous and missing targets return diagnostics
- [ ] Path traversal rejection covered by tests
- [ ] Deterministic output across platforms

---

## 8. Implementation Notes / Templates

### 8.1 Proposed Types

```swift
public enum ResolvedTarget: Equatable, Sendable {
    case inlineText
    case markdownFile(path: String)
    case hypercodeFile(path: String)
    case forbidden(extension: String)
    case invalid(reason: String)
    case ambiguous(candidates: [String])
}
```

---

## 9. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Divergence from CLI resolver | Editor inconsistencies | Reuse ReferenceResolver and tests |
| Ambiguity handling unclear | Broken UX | Return candidate list in ResolvedTarget |
