# PRD — EE-EXT-1: Position-to-Link Query API

**Task ID:** EE-EXT-1
**Phase:** Phase 12 — EditorEngine API Enhancements
**Priority:** P0 (Critical)
**Estimated Effort:** 3 hours
**Dependencies:** EE8 (Phase 10 — EditorEngine complete) ✅
**Status:** In Progress
**Blocks:** VSC-5 (Navigation Features — go-to-definition and hover)

---

## 1. Scope & Intent

### 1.1 Objective

Add **position-based query API** to `EditorParser` that enables VS Code extension to:
- Find which `LinkSpan` (if any) exists at a given cursor position (line, column)
- Support go-to-definition and hover features in the editor

The API must provide **O(log n) lookup performance** using binary search over sorted link spans.

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| `EditorParser.linkAt(line:column:)` | Public method returning `LinkSpan?` at cursor position |
| Binary search implementation | O(log n) position lookup over sorted spans |
| Edge case handling | Comprehensive coverage of boundary conditions |
| `ParsedFile.linksAt(range:)` | Range-based query for multi-line selections (P1) |
| Unit tests | 10+ edge cases with full coverage |

### 1.3 Success Criteria

- ✅ `linkAt(line:column:)` returns correct `LinkSpan` or `nil`
- ✅ Performance: O(log n) verified via benchmarks on 1000+ link corpus
- ✅ All edge cases handled correctly (boundaries, gaps, overlaps)
- ✅ 100% test coverage for new methods
- ✅ VS Code extension can use API for go-to-definition

### 1.4 Constraints & Assumptions

- Link spans in `ParsedFile.linkSpans` are **already sorted** by start position (line, then column)
- Positions use **1-based line/column** indices (matching VS Code API)
- Link spans use **end-exclusive ranges** (`lineRange: 5..<6` means line 5 only)
- EditorParser must remain **Sendable** and thread-safe
- No breaking changes to existing API

### 1.5 External Dependencies

| Dependency | Purpose |
|-----------|---------|
| `ParsedFile` | Container for link spans |
| `LinkSpan` | Link metadata with line/column ranges |
| Swift Standard Library | Binary search implementation |

---

## 2. Structured TODO Plan

### Phase 1: Core API Implementation (P0)

#### 2.1.1 Add `linkAt(line:column:)` method to EditorParser

**Input:**
- `line: Int` (1-based)
- `column: Int` (1-based)
- Sorted `ParsedFile.linkSpans` array

**Process:**
1. Validate input (line > 0, column > 0)
2. Binary search `linkSpans` by line number (primary key)
3. Linear scan matching line for column overlap
4. Return first matching `LinkSpan` or `nil`

**Output:** `LinkSpan?`

**Metadata:**
- Priority: High (P0)
- Effort: 1.5 hours
- Tools: Swift Standard Library
- Acceptance Criteria:
  - Returns `LinkSpan` when position inside link bounds
  - Returns `nil` when position outside all links
  - Handles empty `linkSpans` array
  - O(log n) performance for line lookup

**Implementation Notes:**
- Use Swift's `firstIndex(where:)` with binary search semantics
- Column matching is O(k) where k = links on same line (typically 1-3)
- Overall complexity: O(log n + k)

---

#### 2.1.2 Implement edge case handling

**Input:** Position at various boundary conditions

**Edge Cases to Handle:**

1. **Position before first link** → return `nil`
2. **Position after last link** → return `nil`
3. **Position between links (same line)** → return `nil`
4. **Position between links (different lines)** → return `nil`
5. **Position at link start boundary** → return link
6. **Position at link end boundary** → return `nil` (end-exclusive)
7. **Overlapping ranges** → return first match
8. **Empty linkSpans array** → return `nil`
9. **Line beyond file bounds** → return `nil`
10. **Column beyond line bounds** → return `nil`

**Process:**
- Implement precise range checks using `lineRange.contains()` and `columnRange.contains()`
- Handle end-exclusive semantics (column == columnRange.upperBound → not contained)

**Metadata:**
- Priority: High (P0)
- Effort: 0.5 hours
- Acceptance: All 10 edge cases pass unit tests

---

#### 2.1.3 Write unit tests

**Input:** Test corpus with known link positions

**Test Coverage:**
- ✅ Single link hit (inside bounds)
- ✅ Multiple links, hit first
- ✅ Multiple links, hit last
- ✅ Multiple links on same line
- ✅ Position before all links
- ✅ Position after all links
- ✅ Position between links (horizontal gap)
- ✅ Position between links (vertical gap)
- ✅ Boundary conditions (start inclusive, end exclusive)
- ✅ Empty file (no links)
- ✅ Large file (1000+ links, verify performance)

**Metadata:**
- Priority: High (P0)
- Effort: 1 hour
- Tools: XCTest
- Acceptance: All tests pass, code coverage >95%

---

### Phase 2: Range Query API (P1, Optional)

#### 2.2.1 Add `ParsedFile.linksAt(range:)` method

**Input:**
- `lineRange: Range<Int>` (1-based, end-exclusive)
- `columnRange: Range<Int>?` (optional, for single-line ranges)

**Process:**
1. Binary search for first link overlapping `lineRange.lowerBound`
2. Collect all links until `lineRange.upperBound`
3. Filter by `columnRange` if provided

**Output:** `[LinkSpan]`

**Metadata:**
- Priority: Medium (P1)
- Effort: Deferred to Phase 2 (not blocking VSC-5)
- Tools: Swift Standard Library
- Acceptance: Returns all links overlapping range

**Deferral Reason:** VSC-5 only requires single-position query, range query is enhancement for multi-cursor features.

---

## 3. Functional Requirements

### FR-1: Position-Based Link Lookup

**ID:** FR-1
**Priority:** P0
**Description:** EditorParser must provide `linkAt(line:column:) -> LinkSpan?` method.

**Acceptance Criteria:**
- Returns `LinkSpan` when position inside link bounds (inclusive start, exclusive end)
- Returns `nil` when position outside all links
- Works correctly for all edge cases (see 2.1.2)

---

### FR-2: Performance Guarantee

**ID:** FR-2
**Priority:** P0
**Description:** Position lookup must use binary search for O(log n) complexity.

**Acceptance Criteria:**
- Lookup time scales logarithmically with number of links
- 1000-link file: lookup <1ms on modern hardware
- Performance test passes in CI

---

### FR-3: Sorted Input Assumption

**ID:** FR-3
**Priority:** P0
**Description:** API assumes `linkSpans` are pre-sorted by (line, column) during parsing.

**Acceptance Criteria:**
- Document assumption in method DocC comments
- Verify existing `EditorParser.extractLinkSpans()` produces sorted output
- Add assertion in debug builds to detect violations

---

## 4. Non-Functional Requirements

### NFR-1: Thread Safety

**Priority:** P0
**Description:** Method must be safe to call from any thread (Sendable conformance).

**Rationale:** VS Code extension uses async APIs, may call from background threads.

**Acceptance:** No mutable state, no data races in ThreadSanitizer.

---

### NFR-2: Memory Efficiency

**Priority:** P1
**Description:** No additional memory allocation per query.

**Rationale:** Frequent queries during hover events, must not allocate.

**Acceptance:** Instruments Allocations profile shows zero allocations per call.

---

### NFR-3: API Stability

**Priority:** P0
**Description:** Method signature must remain stable for v0.1 release.

**Rationale:** VS Code extension depends on this API.

**Acceptance:** No breaking changes after merge.

---

## 5. Edge Cases & Failure Scenarios

### Edge Case Matrix

| Scenario | Input | Expected Output | Rationale |
|----------|-------|----------------|-----------|
| Empty file | `linkAt(1, 1)` on `linkSpans: []` | `nil` | No links to find |
| Before first link | `linkAt(1, 1)` when first link at line 5 | `nil` | Position outside bounds |
| After last link | `linkAt(100, 1)` when last link at line 50 | `nil` | Position outside bounds |
| Between links (horizontal) | `linkAt(5, 10)` when links at columns 1-5, 15-20 | `nil` | Column gap |
| Between links (vertical) | `linkAt(10, 1)` when links at lines 5, 15 | `nil` | Line gap |
| At link start | `linkAt(5, 10)` when link at `5:10..<5:20` | `LinkSpan` | Inclusive start |
| At link end | `linkAt(5, 20)` when link at `5:10..<5:20` | `nil` | Exclusive end |
| Overlapping spans | `linkAt(5, 15)` when spans at `5:10..<5:20`, `5:15..<5:25` | First span | First match wins |
| Multi-line link | `linkAt(6, 5)` when link spans lines 5-7 | `LinkSpan` | Line range check |
| Invalid input | `linkAt(-1, 0)` | `nil` | Guard against invalid positions |

---

## 6. Implementation Plan

### Step 1: Add Method Stub (5 min)

```swift
extension EditorParser {
    /// Finds the link span at the given line and column position.
    ///
    /// - Parameters:
    ///   - line: 1-based line number
    ///   - column: 1-based column number
    /// - Returns: LinkSpan at position, or nil if no link exists
    ///
    /// - Complexity: O(log n) where n is the number of link spans
    ///
    /// - Precondition: linkSpans must be sorted by (line, column)
    public func linkAt(line: Int, column: Int, in parsedFile: ParsedFile) -> LinkSpan? {
        // TODO: Implement binary search
        return nil
    }
}
```

---

### Step 2: Implement Binary Search (30 min)

Algorithm:
1. Guard: `line > 0 && column > 0`
2. Binary search for first span where `span.lineRange.contains(line)`
3. Linear scan forward while `span.lineRange.lowerBound == line`
4. Return first span where `span.columnRange.contains(column)`
5. Return `nil` if no match

---

### Step 3: Write Tests (60 min)

Test structure:
- `EditorParserLinkAtTests.swift`
- 10+ test methods covering edge case matrix
- Performance test with 1000-link file

---

### Step 4: Verify Sortedness (15 min)

Add assertion in `EditorParser.extractLinkSpans()`:
```swift
#if DEBUG
assert(spans.isSorted(by: { ($0.lineRange.lowerBound, $0.columnRange.lowerBound) < ($1.lineRange.lowerBound, $1.columnRange.lowerBound) }), "linkSpans must be sorted")
#endif
```

---

## 7. Testing Strategy

### Unit Tests (P0)

**Location:** `Tests/EditorEngineTests/EditorParserLinkAtTests.swift`

**Coverage:**
- Happy path: position inside link
- Edge cases: boundaries, gaps, empty
- Performance: 1000+ links

**Tools:** XCTest, XCTMeasure

---

### Integration Tests (P1, Deferred)

**Location:** VS Code extension tests

**Coverage:**
- Go-to-definition on file reference
- Hover shows resolved path

**Deferral:** Covered by VSC-5 acceptance tests

---

## 8. Documentation Requirements

### DocC Comments (P0)

- Add method documentation with:
  - Parameter descriptions (line, column semantics)
  - Return value description
  - Complexity guarantee (O(log n))
  - Precondition (sorted input)
  - Example usage

---

### Architecture Decision (P0)

**Decision:** Use binary search + linear column scan (not 2D search)

**Rationale:**
- Simple to implement and test
- Optimal for typical case (1-3 links per line)
- Avoids complex 2D tree structures

**Documented in:** Method comments + code comments

---

## 9. Dependencies & Blockers

### Dependencies

| Dependency | Status | Notes |
|-----------|--------|-------|
| EE8 (EditorEngine complete) | ✅ Done | Phase 10 complete |
| `ParsedFile` structure | ✅ Done | Existing API |
| `LinkSpan` structure | ✅ Done | Existing API |

### Blocks

| Task | Priority | Reason |
|------|---------|--------|
| VSC-5 (Navigation Features) | P0 | Requires `linkAt()` for go-to-definition |

---

## 10. Acceptance Checklist

### Implementation Complete

- [ ] `linkAt(line:column:)` method added to `EditorParser`
- [ ] Binary search implementation (O(log n))
- [ ] All 10 edge cases handled correctly
- [ ] Input validation (line > 0, column > 0)
- [ ] Debug assertion for sorted input

### Testing Complete

- [ ] 10+ unit tests written
- [ ] All tests pass
- [ ] Performance test passes (<1ms for 1000 links)
- [ ] Code coverage >95%

### Documentation Complete

- [ ] DocC method documentation
- [ ] Complexity guarantee documented
- [ ] Precondition documented
- [ ] Example usage provided

### Quality Gates

- [ ] Code compiles without warnings
- [ ] Swift 6.1 strict concurrency mode enabled
- [ ] ThreadSanitizer passes
- [ ] No memory leaks (Instruments)
- [ ] Code review approved

---

## 11. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-24 | Claude (AI) | Initial PRD for EE-EXT-1 |

---

## Appendix A: Example Usage

```swift
let parser = EditorParser()
let parsedFile = parser.parse(filePath: "example.hc")

// User clicks at line 5, column 15
if let link = parser.linkAt(line: 5, column: 15, in: parsedFile) {
    print("Link found: \(link.literal)")
    print("Range: \(link.lineRange), \(link.columnRange)")
    // Proceed to resolve link target
} else {
    print("No link at cursor position")
}
```

---

## Appendix B: Performance Benchmark

**Test Corpus:** 1000 randomly distributed links in a 10,000-line file

**Expected Performance:**
- Binary search: ~10 comparisons (log₂ 1000 ≈ 10)
- Column scan: 1-3 comparisons (typical)
- Total: <1ms on modern hardware

**Measured Performance:** (To be filled after implementation)

---

**End of PRD**
