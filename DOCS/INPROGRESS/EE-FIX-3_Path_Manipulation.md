# PRD: EE-FIX-3 — Path Manipulation Double-Slash Bug

**Task ID:** EE-FIX-3
**Priority:** P1 (High)
**Estimated Effort:** 1 hour
**Status:** Pending
**Source:** [REVIEW_EditorEngine_Implementation.md](REVIEW_EditorEngine_Implementation.md) — Issue H-001

---

## 1. Scope and Intent

### 1.1 Objective

Fix the `joinPath` function in `ProjectIndexer.swift` to properly handle edge cases that produce malformed paths with double slashes (`//`) or other invalid constructions.

### 1.2 Primary Deliverables

1. Fixed `joinPath` function with proper normalization
2. Unit tests for all edge cases
3. Verification that no `//` appears in indexed file paths

### 1.3 Success Criteria

- `joinPath("/path/", "file")` returns `"/path/file"` (not `"/path//file"`)
- `joinPath("/path", "/file")` returns `"/path/file"` (not `"/path//file"`)
- `joinPath("/path/", "")` returns `"/path"` (not `"/path/"`)
- All indexed paths are valid filesystem paths

### 1.4 Constraints and Assumptions

- Function is private to ProjectIndexer
- Only Unix-style paths (no Windows support)
- Empty component should return base unchanged

---

## 2. Hierarchical TODO Plan

### Phase 1: Implementation

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 1.1 | Handle empty component case | `joinPath(base, "")` | Return base | High |
| 1.2 | Normalize trailing slash on base | `base.hasSuffix("/")` | Remove trailing slash | High |
| 1.3 | Normalize leading slash on component | `component.hasPrefix("/")` | Remove leading slash | High |
| 1.4 | Join with single separator | Normalized parts | `base + "/" + component` | High |

### Phase 2: Testing

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 2.1 | Test: base with trailing slash | `"/path/", "file"` | `"/path/file"` | High |
| 2.2 | Test: component with leading slash | `"/path", "/file"` | `"/path/file"` | High |
| 2.3 | Test: both slashes present | `"/path/", "/file"` | `"/path/file"` | High |
| 2.4 | Test: empty component | `"/path", ""` | `"/path"` | High |
| 2.5 | Test: normal case | `"/path", "file"` | `"/path/file"` | High |
| 2.6 | Test: root path | `"/", "file"` | `"/file"` | Medium |

---

## 3. Execution Metadata

### 3.1 Task Details

| Task | Effort | Tools/Frameworks | Verification Method |
|------|--------|------------------|---------------------|
| 1.1-1.4 | 15 min | Swift | Unit test |
| 2.1-2.6 | 20 min | XCTest | Test execution |

### 3.2 Dependencies

- None (standalone fix)

### 3.3 Parallel Execution

- All tasks are sequential (implementation before testing)

---

## 4. Functional Requirements

### FR-1: Empty Component Handling

When component is empty, return base path unchanged.

### FR-2: Slash Normalization

Remove trailing slash from base and leading slash from component before joining.

### FR-3: Single Separator

Always join with exactly one `/` separator.

---

## 5. Non-Functional Requirements

### NFR-1: Performance

O(1) string operations — negligible overhead.

### NFR-2: No Side Effects

Function is pure — no filesystem access.

---

## 6. Edge Cases and Failure Scenarios

| Scenario | Input | Expected Output |
|----------|-------|-----------------|
| Normal join | `("/path", "file")` | `"/path/file"` |
| Trailing slash on base | `("/path/", "file")` | `"/path/file"` |
| Leading slash on component | `("/path", "/file")` | `"/path/file"` |
| Both slashes | `("/path/", "/file")` | `"/path/file"` |
| Empty component | `("/path", "")` | `"/path"` |
| Root base | `("/", "file")` | `"/file"` |
| Root base trailing | `("/", "/file")` | `"/file"` |
| Multiple slashes in base | `("/path//", "file")` | `"/path//file"` (only edge slashes normalized) |
| Nested path component | `("/a", "b/c")` | `"/a/b/c"` |

---

## 7. Implementation Reference

### Current Code (ProjectIndexer.swift:290-296)

```swift
private func joinPath(_ base: String, _ component: String) -> String {
    if base.hasSuffix("/") {
        return base + component  // Bug: can create "/path//file"
    }
    return base + "/" + component
}
```

### Fixed Code

```swift
private func joinPath(_ base: String, _ component: String) -> String {
    // Handle empty component
    guard !component.isEmpty else {
        return base
    }

    // Normalize trailing slash on base
    let normalizedBase = base.hasSuffix("/") ? String(base.dropLast()) : base

    // Normalize leading slash on component
    let normalizedComponent = component.hasPrefix("/")
        ? String(component.dropFirst())
        : component

    return normalizedBase + "/" + normalizedComponent
}
```

---

## 8. Test Cases

```swift
// MARK: - joinPath Tests

func testJoinPath_NormalCase() {
    let result = joinPath("/path", "file")
    XCTAssertEqual(result, "/path/file")
}

func testJoinPath_TrailingSlashOnBase() {
    let result = joinPath("/path/", "file")
    XCTAssertEqual(result, "/path/file")
}

func testJoinPath_LeadingSlashOnComponent() {
    let result = joinPath("/path", "/file")
    XCTAssertEqual(result, "/path/file")
}

func testJoinPath_BothSlashes() {
    let result = joinPath("/path/", "/file")
    XCTAssertEqual(result, "/path/file")
}

func testJoinPath_EmptyComponent() {
    let result = joinPath("/path", "")
    XCTAssertEqual(result, "/path")
}

func testJoinPath_RootBase() {
    let result = joinPath("/", "file")
    XCTAssertEqual(result, "/file")
}
```

---

## 9. Acceptance Checklist

- [ ] `joinPath` handles empty component correctly
- [ ] `joinPath` normalizes trailing slash on base
- [ ] `joinPath` normalizes leading slash on component
- [ ] No `//` in output for any valid input combination
- [ ] All 6 test cases pass
- [ ] All existing ProjectIndexer tests pass
