# Task B2: Dependency Tracker — Implementation PRD

**Task ID:** B2
**Task Name:** Dependency Tracker
**Phase:** Phase 4: Reference Resolution
**Priority:** P1 (High)
**Estimated Effort:** 4 hours
**Dependencies:** A4 (Parser & AST Construction) ✅
**Blocks:** B4 (Recursive Compilation)

---

## 1. Scope & Intent

### 1.1 Objective

Implement the `DependencyTracker` type that detects circular dependencies in Hypercode compilation. This task prevents infinite recursion when `.hc` files reference each other directly (A → A) or transitively (A → B → A), ensuring safe recursive compilation.

### 1.2 Primary Deliverables

- `DependencyTracker` type with visitation stack mechanism
- Detection of direct circular dependencies (file references itself)
- Detection of transitive circular dependencies (cycles via multiple files)
- Clear, actionable error messages showing the complete cycle path
- Comprehensive unit tests covering all cycle patterns

### 1.3 Success Criteria

Successful when:
- Direct circular dependencies are detected and reported (exit code 3)
- Transitive circular dependencies are detected and reported (exit code 3)
- Error messages include the full cycle path for debugging
- Unit tests achieve >90% code coverage for cycle scenarios
- All test cases from Workplan pass without regression

### 1.4 Constraints & Assumptions

- **Input:** Canonicalized absolute file paths (provided by resolution phase)
- **Scope:** Only detects cycles in `.hc` file references (not `.md` files)
- **Performance:** Optimizations (memoization) are P2, not required for v0.1
- **Error Model:** Cycle detection errors use exit code 3 (Resolution Error)

---

## 2. Feature Description & Rationale

### 2.1 Why This Task Matters

Without cycle detection, a compilation like `A.hc` → `B.hc` → `A.hc` would cause infinite recursion, crashing the compiler with stack overflow. The Hypercode specification (PRD §3.2) explicitly requires rejection of circular dependencies with exit code 3.

### 2.2 Integration Context

The `DependencyTracker` operates during the **Reference Resolution phase** (Phase 4, Task B4). When the resolver encounters a `.hc` file reference:

1. Resolver checks if the path is already in the visitation stack
2. If yes, `DependencyTracker` reports a cycle error
3. If no, path is added to stack before recursive parse/resolve
4. After resolution completes, path is removed from stack

### 2.3 Design Pattern

Uses the **Visitation Stack** pattern:
- Stack contains canonical absolute paths of files currently being processed
- Before resolving `.hc` reference, check if target is already in stack
- On detection, extract full cycle path from stack for error message
- Stack is maintained by the resolver (DependencyTracker provides detection only)

---

## 3. Functional Requirements

### 3.1 Detect Direct Circular Dependencies

**Requirement:** Detect when a file directly references itself.

**Example:**
```
main.hc contains:
    "main.hc"
```

**Behavior:**
- Resolver adds `main.hc` to stack
- When processing `"main.hc"` reference, detects `main.hc` is already in stack
- Reports error: `Circular dependency: main.hc → main.hc`
- Exit code 3

### 3.2 Detect Transitive Circular Dependencies

**Requirement:** Detect cycles through multiple files.

**Example:**
```
a.hc contains: "b.hc"
b.hc contains: "c.hc"
c.hc contains: "a.hc"
```

**Behavior:**
- Stack evolution: `[a.hc]` → `[a.hc, b.hc]` → `[a.hc, b.hc, c.hc]`
- When processing reference to `a.hc`, detects `a.hc` is already in stack
- Reports error: `Circular dependency: a.hc → b.hc → c.hc → a.hc`
- Exit code 3

### 3.3 Error Message Format

**Requirement:** Produce clear cycle path descriptions.

**Format:**
```
<input-file>:<line>: error: Circular dependency detected
  Cycle path: {path1} → {path2} → ... → {path1}
```

**Example Output:**
```
main.hc:5: error: Circular dependency detected
  Cycle path: /root/main.hc → /root/modules/config.hc → /root/main.hc
```

**Components:**
- Source location (file:line) of the reference causing cycle
- Full cycle path from stack for reproducible debugging
- Canonical absolute paths for unambiguous identification

### 3.4 Integration with Reference Resolver

**Requirement:** DependencyTracker works in coordination with ReferenceResolver.

**API Contract:**
```swift
protocol DependencyTracker {
    /// Check if path is in current visitation stack
    func isInCycle(path: String) -> Bool

    /// Extract full cycle path for error reporting
    func getCyclePath(stack: [String], offendingPath: String) -> [String]
}
```

**Resolver Integration:**
```swift
// Before resolving .hc file:
if tracker.isInCycle(path: resolvedPath) {
    let cyclePath = tracker.getCyclePath(stack: visitation, path: resolvedPath)
    return .error(CircularDependencyError(cyclePath))
}

// Add to stack before recursive resolution
stack.append(resolvedPath)
let result = resolve(childAST, root, strict, stack, fileCache)
stack.removeLast()
```

### 3.5 Path Canonicalization

**Requirement:** All paths must be canonicalized before cycle checking.

**Canonicalization Rules:**
- Resolve `..` components to absolute paths
- Normalize path separators to `/`
- Remove redundant separators (e.g., `//` → `/`)
- Symlink handling per file system policy

**Rationale:** Prevents false negatives where same file referenced multiple ways:
```
Good: Both resolve to /root/config.hc
  - "config.hc" (relative)
  - "./config.hc" (with `.`)
  - "/root/config.hc" (absolute)
```

---

## 4. Non-Functional Requirements

### 4.1 Performance

- **Cycle Detection:** O(n) where n = depth of stack (typically ≤10)
- **String Comparison:** Use string equality, no regex
- **Memory:** Stack size proportional to nesting depth (expected <100 entries)
- **No Optimization Required:** Memoization is P2 for future versions

### 4.2 Error Reporting

- Every cycle must produce a location + diagnostic
- Error message must be machine-parseable (for tools)
- Cycle path must be reproducible across runs

### 4.3 Testing & Coverage

- Unit tests for all cycle patterns:
  - Direct self-reference (A → A)
  - 2-file cycle (A → B → A)
  - 3+ file cycles (A → B → C → A)
  - Deep cycles (10+ file chains)
- >90% code coverage for DependencyTracker logic
- Negative tests: acyclic graphs should not trigger false positives

---

## 5. Edge Cases & Failure Scenarios

### 5.1 Edge Case: File Referenced from Multiple Parents

**Scenario:** `A.hc` and `B.hc` both reference `C.hc`

```
a.hc: "c.hc"
b.hc: "c.hc"
main.hc:
  "a.hc"
  "b.hc"
```

**Expected Behavior:** No cycle detected. `C.hc` is processed safely from both parents.

**Implementation Detail:** Stack maintains entry/exit properly:
- Process A: stack = `[main.hc, a.hc, c.hc]` → pop `c.hc`
- Process B: stack = `[main.hc, b.hc, c.hc]` → pop `c.hc`

### 5.2 Edge Case: Partial Cycle in Deep Tree

**Scenario:** Cycle exists in subtree, not at root

```
main.hc: "a.hc"
a.hc: "b.hc"
b.hc: "c.hc"
c.hc: "b.hc"  // Cycle here, not at root
```

**Expected Behavior:** Cycle detected on third reference

**Stack Evolution:**
- `[main.hc]` → `[main.hc, a.hc]` → `[main.hc, a.hc, b.hc]` → `[main.hc, a.hc, b.hc, c.hc]`
- Error on `b.hc` reference: `Cycle: b.hc → c.hc → b.hc`

### 5.3 Failure: No Valid Root Found After Cycle Detection

**Scenario:** Parser produces AST, but all paths in tree are part of cycles

**Expected Behavior:** Compiler reports all cycle errors, exits 3

**Implementation:** Not responsibility of DependencyTracker; handled by driver

### 5.4 Failure: Stack Becomes Corrupted

**Scenario:** Programming error in resolver leaves invalid paths in stack

**Implementation Detail:** Use immutable stack (functional style) or defensive copies to prevent corruption

---

## 6. TODO Decomposition

### Phase A: Core Implementation (2 hours)

#### A1: Define DependencyTracker Type
**Effort:** 30 min | **Priority:** High | **Acceptance:** Type compiles, basic structure in place

- [ ] Create `DependencyTracker.swift` file in Resolver module
- [x] Define `struct DependencyTracker` with visitation stack parameter
- [x] Implement `isInCycle(path:)` → `Bool` method (simple stack membership check)
- [x] Add initializer accepting optional stack for testing

#### A2: Implement Cycle Path Extraction
**Effort:** 30 min | **Priority:** High | **Acceptance:** Correct path extraction from stack

- [x] Implement `getCyclePath(stack:offendingPath:)` → `[String]` method
- [x] Extract cycle portion of stack starting from offending path
- [x] Append offending path to complete the cycle representation
- [x] Test with simple 2-file and 3-file cycles

#### A3: Define Error Type
**Effort:** 30 min | **Priority:** High | **Acceptance:** Error type conforms to CompilerError

- [x] Create `CircularDependencyError` struct conforming to `CompilerError`
- [x] Implement `message` property formatting cycle path
- [x] Implement `location` property (from resolver context)
- [x] Implement `exitCode` property = 3 (Resolution Error)

#### A4: Integration with Resolver
**Effort:** 30 min | **Priority:** High | **Acceptance:** Resolver calls DependencyTracker correctly

- [x] Modify `ReferenceResolver.resolve()` to check cycles before `.hc` resolution
- [x] Pass absolute canonical path to cycle check
- [x] Return `CircularDependencyError` on detection
- [x] Maintain stack correctly across recursive calls

### Phase B: Testing & Refinement (2 hours)

#### B1: Unit Tests — Direct Cycles
**Effort:** 45 min | **Priority:** High | **Acceptance:** All 4 test cases pass

- [x] Test case: A → A (self-reference)
- [x] Test case: A → B → A (2-file cycle)
- [x] Test case: A → B → C → A (3-file cycle)
- [x] Test case: Deep cycle (10+ files)
- [x] Verify error message includes full cycle path
- [x] Verify exit code = 3

#### B2: Unit Tests — Acyclic Graphs
**Effort:** 30 min | **Priority:** High | **Acceptance:** No false positives

- [x] Test case: Linear chain (A → B → C, no cycle)
- [x] Test case: DAG with multiple paths (A → {B, C} → D)
- [x] Test case: File referenced from multiple parents
- [x] Verify DependencyTracker returns `false` for all acyclic references

#### B3: Error Reporting Tests
**Effort:** 30 min | **Priority:** High | **Acceptance:** Error messages are clear and parseable

- [x] Test error message format matches spec
- [x] Test error includes source location (file:line)
- [x] Test error includes full cycle path
- [x] Test error is machine-parseable (no colorization, clear structure)

#### B4: Code Coverage & Documentation
**Effort:** 15 min | **Priority:** Medium | **Acceptance:** >90% coverage, inline comments

- [x] Measure code coverage for DependencyTracker
- [x] Add inline comments explaining stack mechanics
- [x] Document assumptions (e.g., paths are canonicalized)
- [x] Document integration contract with ReferenceResolver

---

## 7. Acceptance Criteria

### Must-Have (Blocking)
- [x] DependencyTracker type implemented and compiles
- [x] Direct cycles detected (A → A)
- [x] Transitive cycles detected (A → B → A, A → B → C → A)
- [x] Error messages include full cycle path
- [x] Exit code 3 on cycle detection
- [x] All TODO items from Phase B completed
- [x] >90% unit test coverage for DependencyTracker logic

### Nice-to-Have (Not Blocking)
- [ ] Memoization for repeated cycle checks (P2)
- [ ] Performance benchmarks (P2)
- [ ] Integration tests with full compiler pipeline (part of B4, not B2)

### Verification Method

```bash
# Run DependencyTracker unit tests
swift test -v DependencyTrackerTests

# Verify coverage threshold
swift test --enable-code-coverage
# Check coverage report: >90% for DependencyTracker module

# Manual integration test (after B4 implementation)
hyperprompt cyclic-test/a.hc --root cyclic-test/
# Expected exit code: 3
# Expected error: "Circular dependency detected: ... → ... → ..."
```

---

## 8. Context & References

### Related Documentation
- **PRD (00_PRD_001.md)** — §3.2 (Circular dependency requirements), §6.2 (Error handling)
- **Design Spec (01_DESIGN_SPEC_001.md)** — §4.2 (Reference resolution algorithm), §6.2 (Error categories)
- **Workplan (Workplan.md)** — Phase 4 (Reference Resolution), Critical Path dependency

### Prior Task
- **A4 (Parser & AST Construction)** ✅ — Provides AST nodes to traverse
- **B1 (Reference Resolver)** ✅ — Classifies file references

### Blocking Task
- **B4 (Recursive Compilation)** — Requires DependencyTracker for safe recursion

---

## 9. Implementation Notes

### Algorithm Overview

```swift
// Pseudocode for cycle detection
func resolveReference(path: String, stack: [String]) -> Result {
    // 1. Canonicalize path
    let canonicalPath = canonicalize(path)

    // 2. Check if already in stack (cycle detection)
    if stack.contains(canonicalPath) {
        let cyclePath = extractCycle(stack, canonicalPath)
        return .error(CircularDependencyError(cyclePath))
    }

    // 3. Add to stack and recurse
    let newStack = stack + [canonicalPath]
    let result = parseAndResolve(canonicalPath, newStack)

    return result
}
```

### Key Invariants

- **Stack Invariant:** Stack contains only canonicalized absolute paths
- **Immutability:** Use value semantics (arrays) or defensive copying
- **Single Root:** Only one entry point (`main.hc` or specified input)

### Testing Strategy

1. **Unit Tests:** DependencyTracker logic in isolation
2. **Integration Tests:** With ReferenceResolver (part of B4)
3. **End-to-End:** Full compiler with cyclic input files

---

## 10. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-06 | Claude Code | Initial PRD for B2 Dependency Tracker |
