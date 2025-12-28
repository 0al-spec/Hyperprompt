# PRD: EE-FIX-2 — Byte Offset Calculation Fix

**Task ID:** EE-FIX-2
**Priority:** P0 (Blocker)
**Estimated Effort:** 2 hours
**Status:** Pending
**Source:** [REVIEW_EditorEngine_Implementation.md](REVIEW_EditorEngine_Implementation.md) — Issue B-002

---

## 1. Scope and Intent

### 1.1 Objective

Review and fix the `computeLineStartOffsets` function in `EditorParser.swift` to ensure byte offsets are correctly calculated for files with trailing newlines. The current implementation may produce incorrect byte ranges for link spans.

### 1.2 Primary Deliverables

1. Validated or fixed `computeLineStartOffsets` function
2. Integration tests verifying byte ranges match actual file content positions
3. Test coverage for trailing newline edge cases

### 1.3 Success Criteria

- Byte ranges in `LinkSpan` correctly map to source file positions
- LSP protocol position mappings work correctly
- Files with/without trailing newlines produce correct offsets

### 1.4 Constraints and Assumptions

- Line endings are normalized to `\n` before processing
- `splitIntoLines` removes empty trailing element when file ends with `\n`
- Byte offsets use UTF-8 encoding

---

## 2. Hierarchical TODO Plan

### Phase 1: Analysis and Verification

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 1.1 | Create test file with trailing newline | `"Line1\nLine2\n"` | Test fixture | High |
| 1.2 | Create test file without trailing newline | `"Line1\nLine2"` | Test fixture | High |
| 1.3 | Trace through `computeLineStartOffsets` manually | Algorithm walkthrough | Document expected vs actual | High |
| 1.4 | Verify if bug exists or review claim is incorrect | Analysis | Bug confirmed or refuted | High |

### Phase 2: Fix Implementation (if bug confirmed)

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 2.1 | Determine correct offset calculation for trailing newlines | Bug analysis | Fix strategy | High |
| 2.2 | Update `computeLineStartOffsets` logic | Current code | Fixed code | High |
| 2.3 | Ensure `splitIntoLines` and offset calculation are consistent | Both functions | Aligned behavior | High |

### Phase 3: Testing

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 3.1 | Add test: File with trailing newline byte positions | Test content | Correct byte ranges | High |
| 3.2 | Add test: File without trailing newline byte positions | Test content | Correct byte ranges | High |
| 3.3 | Add test: Multi-byte UTF-8 characters | Unicode content | Correct byte offsets | High |
| 3.4 | Add test: LinkSpan byte range extraction accuracy | Parsed file | Byte ranges match content | High |
| 3.5 | Add test: Empty file handling | Empty string | No crash, empty spans | Medium |

---

## 3. Execution Metadata

### 3.1 Task Details

| Task | Effort | Tools/Frameworks | Verification Method |
|------|--------|------------------|---------------------|
| 1.1-1.4 | 30 min | Manual analysis | Documentation |
| 2.1-2.3 | 30 min | Swift | Code review |
| 3.1-3.5 | 60 min | XCTest | Test execution |

### 3.2 Dependencies

- None (standalone fix)

### 3.3 Parallel Execution

- Phase 1 must complete before Phase 2
- Phase 3 tests can be written in parallel after Phase 2

---

## 4. Functional Requirements

### FR-1: Line Start Offset Accuracy

`computeLineStartOffsets` SHALL return byte offsets where:
- Offset for line N is the byte position of the first character of line N
- Offsets account for newline characters between lines

### FR-2: Trailing Newline Handling

When a file ends with `\n`:
- The empty line after the final newline is NOT counted
- The newline character IS included in total byte count

### FR-3: UTF-8 Compatibility

Byte offsets SHALL use UTF-8 byte counts, not character counts.

---

## 5. Non-Functional Requirements

### NFR-1: LSP Protocol Compatibility

Byte offsets must be compatible with Language Server Protocol position specifications.

### NFR-2: Performance

O(n) where n = number of lines — no change from current implementation.

---

## 6. Edge Cases and Failure Scenarios

| Scenario | Input | Expected Line Start Offsets |
|----------|-------|----------------------------|
| Empty file | `""` | `[]` |
| Single line no newline | `"abc"` | `[0]` |
| Single line with newline | `"abc\n"` | `[0]` |
| Two lines no trailing | `"abc\ndef"` | `[0, 4]` |
| Two lines with trailing | `"abc\ndef\n"` | `[0, 4]` |
| Multi-byte UTF-8 | `"日本\nabc"` | `[0, 7]` (日本 = 6 bytes + 1 newline) |
| Multiple empty lines | `"\n\n\n"` | `[0, 1, 2]` |

---

## 7. Implementation Reference

### Current Code (EditorParser.swift:188-202)

```swift
private func computeLineStartOffsets(_ lines: [String]) -> [Int] {
    var offsets: [Int] = []
    offsets.reserveCapacity(lines.count)

    var currentOffset = 0
    for (index, line) in lines.enumerated() {
        offsets.append(currentOffset)
        currentOffset += line.utf8.count
        if index < lines.count - 1 {  // Potential issue here
            currentOffset += 1
        }
    }

    return offsets
}
```

### Review Claim

The review claims this is incorrect for trailing newlines because:
- File `"Line1\nLine2\n"` has 12 bytes
- After split: `["Line1", "Line2"]`
- Current: Line 0 offset 0, Line 1 offset 6, no +1 for last line
- But the original content did have a trailing newline

### Analysis Required

Verify whether byte offsets are meant to index into:
1. The original content (including trailing newline) — may need fix
2. The logical line content only — current behavior may be correct

### Potential Fix (if needed)

```swift
private func computeLineStartOffsets(_ lines: [String]) -> [Int] {
    var offsets: [Int] = []
    offsets.reserveCapacity(lines.count)

    var currentOffset = 0
    for line in lines {
        offsets.append(currentOffset)
        // Always add line length + 1 for newline (normalized content)
        currentOffset += line.utf8.count + 1
    }

    return offsets
}
```

---

## 8. Test Cases

### Test 1: Trailing Newline File

```swift
func testByteOffsets_TrailingNewline() {
    let content = "Line1\nLine2\n"  // 12 bytes
    let parser = EditorParser()
    let parsed = parser.parse(content: content, filePath: "test.hc")

    // Verify byte ranges if content has links
    // Example: @"ref" on line 1 starting at column 1
    // Should have byteRange starting at 0
}
```

### Test 2: No Trailing Newline

```swift
func testByteOffsets_NoTrailingNewline() {
    let content = "Line1\nLine2"  // 11 bytes
    let parser = EditorParser()
    let parsed = parser.parse(content: content, filePath: "test.hc")

    // Verify line 2 starts at byte 6
}
```

### Test 3: UTF-8 Characters

```swift
func testByteOffsets_UTF8Characters() {
    let content = "日本語\nabc"  // 9 + 1 + 3 = 13 bytes (日本語 = 9 UTF-8 bytes)
    let parser = EditorParser()
    let parsed = parser.parse(content: content, filePath: "test.hc")

    // Verify line 2 starts at byte 10
}
```

---

## 9. Acceptance Checklist

- [ ] Analysis completed: bug confirmed or refuted
- [ ] If bug exists: fix implemented
- [ ] Test: trailing newline byte positions correct
- [ ] Test: no trailing newline byte positions correct
- [ ] Test: UTF-8 byte offsets correct
- [ ] Test: LinkSpan byte ranges match source positions
- [ ] All existing EditorParserLinkAtTests pass
