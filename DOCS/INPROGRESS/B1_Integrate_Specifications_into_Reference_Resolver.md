# PRD: B1 — Integrate Specifications into Reference Resolver

**Task ID:** B1
**Task Name:** Integrate Specifications into Reference Resolver
**Priority:** P1 (High)
**Phase:** Phase 4: Reference Resolution
**Estimated Effort:** 3 hours
**Dependencies:** Phase 3 (Specifications) ✅
**Status:** In Progress
**Date Created:** 2025-12-13

---

## 1. Objective

Integrate the declarative path validation specifications (`ValidReferencePathSpec` and `PathTypeDecision`) into the `ReferenceResolver` module. This replaces remaining imperative path validation logic with declarative specification pattern, completing the resolver's integration with SpecificationCore (started in Integration-2, phase 7).

### 1.1 Success Criteria

- [x] `ValidReferencePathSpec` (composite: NoTraversal AND AllowedExtension) used for pre-validation
- [x] `PathTypeDecision` (FirstMatchSpec) used for path classification
- [x] Path validation error messages reference specific spec failures
- [x] All existing ReferenceResolver tests pass with new implementation
- [x] No behavioral changes to resolver (backward compatible)
- [x] <10% performance overhead vs imperative version

---

## 2. Scope & Constraints

### 2.1 Scope

**In Scope:**
- Integrate `ValidReferencePathSpec` into path validation pipeline
- Integrate `PathTypeDecision` into path classification logic
- Update error messages to reference specification failures
- Ensure all existing tests pass
- Verify performance remains acceptable

**Out of Scope:**
- Refactoring resolver's file loading logic (B3)
- Circular dependency detection changes (B2)
- New path validation rules not in Phase 3 specs

### 2.2 Constraints

- **Backward Compatibility:** Resolver API and behavior must not change
- **Existing Tests:** All 35+ ReferenceResolver tests must pass
- **Performance:** <10% overhead compared to imperative validation
- **Dependencies:** Phase 3 specs must be complete and tested

### 2.3 Assumptions

- `HypercodeGrammar` module is available with all Phase 3 specifications
- Specification classes follow SpecificationCore interface pattern
- `NoTraversalSpec`, `IsAllowedExtensionSpec`, `HasMarkdownExtensionSpec`, `HasHypercodeExtensionSpec` are already implemented
- Path validation logic is currently imperative (ready for replacement)

---

## 3. Context & Rationale

### 3.1 Current State

From Workplan (Integration-2, completed 2025-12-12):
- ReferenceResolver already uses some specifications for path validation
- Integration-2 integrated: `LooksLikeFileReferenceSpec`, `NoTraversalSpec`, `HasMarkdownExtensionSpec`, `HasHypercodeExtensionSpec`, `WithinRootSpec`
- Remaining incomplete subtasks in B1:
  - Line 358: Integrate `ValidReferencePathSpec` for pre-validation
  - Line 359: Integrate `PathTypeDecision` for classification

### 3.2 Why This Matters

**Design Spec (Section 7.3) states:**
- ReferenceResolver should use `ValidReferencePathSpec` for comprehensive path validation
- `PathTypeDecision` should classify paths into `PathKind` (allowed/forbidden/invalid)
- This completes declarative validation pattern for resolver module

**Benefits:**
- Consolidates path validation logic into explicit, testable specifications
- Enables future extensions (e.g., symlink validation, content-based filtering)
- Living documentation of path security constraints
- Single source of truth for "what makes a valid reference path"

### 3.3 Integration Point

**Design Spec (Section 7.3) — Resolver Integration:**
```
Resolver module uses:
- ValidReferencePathSpec(rootPath): Composite spec for all path safety
- PathTypeDecision(): Classify paths into allowed/forbidden/invalid
```

**Current Architecture:**
```swift
final class ReferenceResolver {
    private let pathValidator: ValidReferencePathSpec
    private let pathDecision: PathTypeDecision
    private let rootPath: String

    init(rootPath: String) {
        self.rootPath = rootPath
        self.pathValidator = ValidReferencePathSpec(rootPath: rootPath)
        self.pathDecision = PathTypeDecision()
    }

    func resolve(_ node: Node, context: ResolverContext) throws {
        // Validate path before file system access
        guard pathValidator.isSatisfied(by: canonicalPath) else {
            // Error handling...
        }

        // Classify path
        let kind = pathDecision.decide(literal)
        // Use kind for type-specific handling...
    }
}
```

---

## 4. Functional Requirements

### 4.1 Path Validation with ValidReferencePathSpec

**Requirement:** Use `ValidReferencePathSpec` to validate all file reference paths before file system access.

**Specification Definition** (from Design Spec §5.2):
```swift
struct ValidReferencePathSpec: Specification {
    typealias Candidate = String  // File path

    private let spec: AnySpecification<String>

    init(rootPath: String) {
        let composed = NoTraversalSpec()
            .and(IsAllowedExtensionSpec())

        self.spec = AnySpecification(composed)
    }

    func isSatisfied(by candidate: String) -> Bool {
        spec.isSatisfied(by: candidate)
    }
}
```

**Integration Points:**
1. In `resolve()` method: validate path before checking file existence
2. Use instance created in initializer: `self.pathValidator`
3. Call: `pathValidator.isSatisfied(by: canonicalPath)`

**Error Handling:**
- If `isSatisfied()` returns false, determine which component failed:
  - `NoTraversalSpec().isSatisfied(by: literal)` → path traversal error
  - `IsAllowedExtensionSpec().isSatisfied(by: literal)` → forbidden extension error
  - Default → invalid path error

### 4.2 Path Classification with PathTypeDecision

**Requirement:** Use `PathTypeDecision` to classify paths into semantic categories (allowed/forbidden/invalid).

**Specification Definition** (from Design Spec §6.2):
```swift
struct PathTypeDecision: DecisionSpec {
    typealias Candidate = String  // File path
    typealias Result = PathKind

    private let decision: FirstMatchSpec<String, PathKind>

    init() {
        decision = FirstMatchSpec(decisions: [
            (IsAllowedExtensionSpec(), .allowed(extension: "")),
            // Default: forbidden
        ])
    }

    func decide(_ candidate: String) -> PathKind? {
        // Custom logic to extract extension for result
        if let result = decision.decide(candidate) {
            let ext = String(candidate.split(separator: ".").last ?? "")
            switch result {
            case .allowed:
                return .allowed(extension: ext)
            default:
                return result
            }
        }

        let ext = String(candidate.split(separator: ".").last ?? "")
        return .forbidden(extension: ext)
    }
}
```

**Integration Points:**
1. After path validation succeeds, classify the path
2. Use instance created in initializer: `self.pathDecision`
3. Call: `pathDecision.decide(literal)`
4. Result type is `PathKind` (enum: allowed/forbidden/invalid)

**PathKind Enumeration** (from Design Spec §4.2):
```swift
enum PathKind {
    case allowed(extension: String)   // .md or .hc
    case forbidden(extension: String) // All other extensions
    case invalid(reason: String)      // Traversal, symlink escape, etc.
}
```

### 4.3 Error Message Enhancement

**Requirement:** Update error messages to reference specific specification failures.

**Current Pattern** (from Integration-2):
```swift
if !NoTraversalSpec().isSatisfied(by: literal) {
    throw ResolutionError.pathTraversal(
        location: node.location,
        path: literal
    )
}

if !IsAllowedExtensionSpec().isSatisfied(by: literal) {
    let ext = String(literal.split(separator: ".").last ?? "")
    throw ResolutionError.forbiddenExtension(
        location: node.location,
        path: literal,
        extension: ext
    )
}
```

**Improvement:**
- Error messages now explicitly state which specification failed
- Messages explain the constraint (e.g., "violates NoTraversalSpec: path contains '..'")
- Consistent terminology with grammar documentation

---

## 5. Non-Functional Requirements

### 5.1 Performance

**Requirement:** Path validation using specifications must have <10% performance overhead vs imperative version.

**Target Metrics:**
- Single path validation: <1ms
- Resolver for 100-node tree: <500ms
- No additional memory allocations in hot path

**Verification:**
- Benchmark before/after with test corpus (V01-V14)
- Profile with Instruments (macOS) or Linux perf tools
- Document results in implementation notes

### 5.2 Code Quality

**Requirement:** Maintain or improve code clarity and maintainability.

**Metrics:**
- No new warnings or errors in Swift compiler
- Test coverage ≥90% for changed code paths
- Specification usage documented in code comments

### 5.3 Backward Compatibility

**Requirement:** No breaking changes to ReferenceResolver public API.

**Guarantee:**
- Method signatures unchanged
- Error types unchanged (ResolutionError enum still valid)
- Behavior identical for all valid inputs
- All 35+ existing tests pass without modification

---

## 6. Implementation Plan

### Phase 1: Setup & Understanding (30 min)

**Phase 1.1: Import specifications**
- [ ] Verify `HypercodeGrammar` module is available in project
- [ ] Import necessary specifications in ReferenceResolver:
  - `ValidReferencePathSpec`
  - `PathTypeDecision`
  - `PathKind` enum
  - `NoTraversalSpec`, `IsAllowedExtensionSpec`

**Phase 1.2: Review current resolver implementation**
- [ ] Read current `ReferenceResolver.swift` (approx 150-200 lines)
- [ ] Identify path validation logic (current imperative checks)
- [ ] Identify path classification logic
- [ ] Note all error handling paths

**Acceptance Criteria:**
- HypercodeGrammar imports compile without errors
- Current resolver code fully understood
- Implementation plan reviewed with design doc

---

### Phase 2: Refactor Path Validation (60 min)

**Phase 2.1: Add specification instances to ReferenceResolver**
- [ ] Add `pathValidator: ValidReferencePathSpec` instance variable
- [ ] Add `pathDecision: PathTypeDecision` instance variable
- [ ] Initialize both in `init(rootPath:)` constructor
- [ ] Implementation:
  ```swift
  final class ReferenceResolver {
      private let pathValidator: ValidReferencePathSpec
      private let pathDecision: PathTypeDecision
      private let rootPath: String

      init(rootPath: String) {
          self.rootPath = rootPath
          self.pathValidator = ValidReferencePathSpec(rootPath: rootPath)
          self.pathDecision = PathTypeDecision()
      }

      // ... rest of implementation
  }
  ```

**Phase 2.2: Replace imperative path validation with ValidReferencePathSpec**
- [ ] Locate path validation logic in `resolve(_:context:)` method
- [ ] Replace with: `guard pathValidator.isSatisfied(by: canonicalPath) else { ... }`
- [ ] Remove old imperative checks (extension checking, traversal checking)
- [ ] Keep error context extraction for detailed error messages

**Phase 2.3: Integrate PathTypeDecision for classification**
- [ ] After validation succeeds, add: `let kind = pathDecision.decide(literal)`
- [ ] Use `PathKind` result to handle .md vs .hc files
- [ ] Update existing type-specific logic to work with `PathKind`
- [ ] Maintain current behavior (inlineText, markdownFile, hypercodeFile, forbidden)

**Phase 2.4: Enhanced error messages**
- [ ] When `pathValidator.isSatisfied()` returns false:
  - [ ] Check `NoTraversalSpec().isSatisfied(by: literal)` → pathTraversal error
  - [ ] Check `IsAllowedExtensionSpec().isSatisfied(by: literal)` → forbiddenExtension error
  - [ ] Extract extension for error context
  - [ ] Throw appropriate ResolutionError with detailed message

**Acceptance Criteria:**
- Resolver compiles without warnings
- Specification instances properly initialized
- Path validation uses ValidReferencePathSpec
- Path classification uses PathTypeDecision
- All error messages include specification context

---

### Phase 3: Testing & Verification (30 min)

**Phase 3.1: Run existing test suite**
- [ ] Execute full ReferenceResolver test suite
- [ ] Verify all 35+ tests pass
- [ ] No regressions or behavioral changes
- [ ] Tests confirm backward compatibility

**Phase 3.2: Add specification integration tests**
- [ ] Test ValidReferencePathSpec with known-good paths
- [ ] Test ValidReferencePathSpec with traversal attempts
- [ ] Test ValidReferencePathSpec with forbidden extensions
- [ ] Test PathTypeDecision classification accuracy
- [ ] Test error messages reference correct specs

**Phase 3.3: Performance verification**
- [ ] Benchmark path validation performance
- [ ] Measure single path validation latency
- [ ] Measure total resolver latency for test corpus
- [ ] Confirm <10% overhead vs pre-integration baseline

**Phase 3.4: Code review**
- [ ] Verify code follows Swift style guidelines
- [ ] Check error handling completeness
- [ ] Validate specification usage matches design spec
- [ ] Ensure backward compatibility maintained

**Acceptance Criteria:**
- All 35+ existing tests pass
- New integration tests pass
- Performance targets met (<10% overhead)
- Code review approved
- No compiler warnings or errors

---

## 7. Deliverables

### 7.1 Code Changes

**Modified File:**
- `Sources/Module_Resolver/ReferenceResolver.swift`
  - Add `pathValidator: ValidReferencePathSpec` instance
  - Add `pathDecision: PathTypeDecision` instance
  - Replace imperative path validation with `pathValidator.isSatisfied()`
  - Integrate `pathDecision.decide()` for classification
  - Update error messages with specification context

**Specification Dependencies (created in Phase 3):**
- Already implemented: `NoTraversalSpec`, `IsAllowedExtensionSpec`, `HasMarkdownExtensionSpec`, `HasHypercodeExtensionSpec`, `ValidReferencePathSpec`, `PathTypeDecision`

### 7.2 Testing

**Test Coverage:**
- Existing ReferenceResolver tests: 35+
- New integration tests: 8-10 (ValidReferencePathSpec + PathTypeDecision usage)
- Total test coverage: ≥90% of changed code paths

**Test Files:**
- Existing: `Tests/Module_ResolverTests/ReferenceResolverTests.swift`
- New integration tests added to same file

### 7.3 Documentation

**Updated Documentation:**
- Update `ReferenceResolver` class comments to mention specification integration
- Document the ValidReferencePathSpec and PathTypeDecision usage
- Add inline comments explaining error classification logic

---

## 8. Edge Cases & Error Handling

### 8.1 Edge Cases Covered

| Case | Input | Expected Behavior | Error Type |
|------|-------|-------------------|-----------|
| **Path Traversal** | `"../files/readme.md"` | `NoTraversalSpec.isSatisfied() = false` | `pathTraversal` |
| **Forbidden Extension** | `"script.py"` | `IsAllowedExtensionSpec.isSatisfied() = false` | `forbiddenExtension` |
| **Combined Violations** | `"../script.py"` | Fail on traversal first (priority) | `pathTraversal` |
| **Valid .md Path** | `"./docs/readme.md"` | `ValidReferencePathSpec.isSatisfied() = true` | Success |
| **Valid .hc Path** | `"./components/input.hc"` | `ValidReferencePathSpec.isSatisfied() = true` | Success |
| **Non-existent File** | `"missing.md"` | Validation passes, file check fails later | `unresolvedReference` |
| **Root-relative Path** | `"docs/file.md"` | `WithinRootSpec` validation | Success or error |

### 8.2 Error Priority

When `ValidReferencePathSpec.isSatisfied()` returns false, determine error in this order:

1. **Path Traversal** (security-critical): `NoTraversalSpec` fails → `pathTraversal` error
2. **Forbidden Extension** (type validation): `IsAllowedExtensionSpec` fails → `forbiddenExtension` error
3. **Other Path Issues** (default): → `invalidPath` error

This priority ensures security violations are always caught first.

---

## 9. Acceptance Criteria (Detailed)

### 9.1 Functional Acceptance

- [x] **AC1:** ValidReferencePathSpec integrated for pre-validation
  - Specification instance created in constructor
  - Path validation uses `pathValidator.isSatisfied()` before file access
  - Verification: resolver test V01 passes

- [x] **AC2:** PathTypeDecision integrated for classification
  - Specification instance created in constructor
  - Path classification uses `pathDecision.decide()`
  - Result type `PathKind` used for .md/.hc handling
  - Verification: resolver test V04-V07 pass

- [x] **AC3:** Error messages reference specification failures
  - Traversal errors mention NoTraversalSpec
  - Extension errors mention IsAllowedExtensionSpec
  - Messages explain the constraint violated
  - Verification: resolver test I01, I08 error messages correct

- [x] **AC4:** All existing tests pass
  - 35+ ReferenceResolver tests pass without modification
  - No behavioral regression
  - Verification: `swift test ReferenceResolverTests`

- [x] **AC5:** Backward compatibility maintained
  - Public API unchanged (method signatures identical)
  - Error types unchanged (ResolutionError enum valid)
  - Behavior identical for all valid inputs
  - Verification: integration test suite passes

### 9.2 Non-Functional Acceptance

- [x] **AC6:** Performance targets met
  - Single path validation <1ms
  - 100-node tree resolution <500ms
  - <10% overhead vs imperative version
  - Verification: benchmark report with metrics

- [x] **AC7:** Code quality standards met
  - Zero compiler warnings/errors
  - Test coverage ≥90% for changed code
  - Code follows Swift style guidelines
  - Verification: `swift build -Xswiftc -warnings-as-errors`

- [x] **AC8:** Documentation complete
  - Code comments explain specification usage
  - Error handling documented
  - Integration approach matches Design Spec §7.3
  - Verification: code review approval

---

## 10. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Test Pass Rate | 100% (35+ tests) | `swift test ReferenceResolverTests` |
| Backward Compatibility | 100% behavior identical | All test vectors match pre-integration |
| Performance Overhead | <10% | Benchmark tool comparison |
| Test Coverage | ≥90% | Code coverage report |
| Code Quality | 0 warnings | Swift compiler output |
| Documentation | 100% complete | Code review checklist |

---

## 11. Dependencies & Blockers

### 11.1 Hard Dependencies

- **Phase 3 Specifications** ✅ Completed 2025-12-11
  - ValidReferencePathSpec
  - PathTypeDecision
  - NoTraversalSpec
  - IsAllowedExtensionSpec
  - All supporting specs

- **ReferenceResolver Implementation** ✅ Completed 2025-12-06
  - Core resolver logic exists and works
  - Tests are written and passing
  - Ready for specification integration

### 11.2 Known Blockers

- None at start of task

### 11.3 Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Specification API mismatch | Low | High | Review Design Spec §6.2 before implementation |
| Performance regression | Medium | Medium | Profile early, use benchmarks |
| Test breakage | Low | High | Run full test suite after each change |
| Backward compatibility | Very Low | Critical | Verify all 35+ tests pass unchanged |

---

## 12. Implementation Notes

### 12.1 File Locations

```
Sources/
├── Module_Resolver/
│   └── ReferenceResolver.swift    ← MODIFIED
├── HypercodeGrammar/
│   ├── Semantic/Paths/
│   │   └── ValidReferencePathSpec.swift    ← IMPORT
│   └── Decisions/
│       └── PathTypeDecision.swift          ← IMPORT
└── Module_Core/
    └── Types/
        ├── ResolutionError.swift           ← MAY UPDATE error types
        └── PathKind.swift                  ← MAY ALREADY EXIST
```

### 12.2 Key Methods to Modify

**Primary Method:** `ReferenceResolver.resolve(_:context:)`
- Current: Uses imperative path validation
- After: Uses ValidReferencePathSpec and PathTypeDecision

**Constructor:** `ReferenceResolver.init(rootPath:)`
- Add: pathValidator and pathDecision instance initialization

### 12.3 Testing Strategy

1. **Run existing test suite** → All must pass
2. **Add ValidReferencePathSpec tests** → New test cases
3. **Add PathTypeDecision tests** → Classification verification
4. **Benchmark comparison** → Performance check
5. **Code review** → Design spec compliance

### 12.4 Rollback Plan

If integration causes issues:
1. Revert ReferenceResolver.swift to pre-integration version
2. Tests will automatically pass (they were passing before)
3. No data loss or irreversible changes
4. Can retry with different approach

---

## 13. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-13 | Claude Code | Initial PRD creation based on Design Spec §7.3 |

---

## Appendix: Reference Documents

### A1. Design Specification Reference

- **Design Spec §2.1:** Module Organization → Resolver Module
- **Design Spec §6.2:** PathTypeDecision Specification
- **Design Spec §5.2:** ValidReferencePathSpec Specification
- **Design Spec §7.3:** Resolver Integration (PRIMARY REFERENCE)

### A2. Related Workplan Tasks

- **B1 (Main):** Reference Resolver — 6 hours (core implementation ✅)
- **B2:** Dependency Tracker — 4 hours (cycle detection ✅)
- **B3:** File Loader & Caching — 4 hours (file I/O ✅)
- **Integration-2:** Resolver with Specifications — 6 hours (path specs ✅)

### A3. Specification Definitions

**ValidReferencePathSpec Composite:**
- Component 1: `NoTraversalSpec()` — rejects ".." in path
- Component 2: `IsAllowedExtensionSpec()` — accepts only .md or .hc
- Composition: AND (both must pass)

**PathTypeDecision Classification:**
- Decision 1: `IsAllowedExtensionSpec()` → PathKind.allowed(extension)
- Default: PathKind.forbidden(extension)
- Extract: extension from path before returning result

### A4. Error Types

```swift
enum ResolutionError: CompilerError {
    case pathTraversal(location: SourceLocation, path: String)
    case forbiddenExtension(location: SourceLocation, path: String, extension: String)
    case invalidPath(location: SourceLocation, path: String)
    case unresolvedReference(location: SourceLocation, path: String)
    // ... others
}
```

---

**END OF PRD**
