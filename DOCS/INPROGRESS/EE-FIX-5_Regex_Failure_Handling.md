# PRD: EE-FIX-5 — Silent Regex Failure Handling

**Task ID:** EE-FIX-5
**Priority:** P1 (High)
**Estimated Effort:** 2 hours
**Status:** Pending
**Dependencies:** EE-FIX-4 (GlobMatcher refactoring)
**Source:** [REVIEW_EditorEngine_Implementation.md](REVIEW_EditorEngine_Implementation.md) — Issue H-003

---

## 1. Scope and Intent

### 1.1 Objective

Fix the silent failure handling in GlobMatcher when regex compilation fails. Currently, invalid patterns silently fall back to exact string matching, which masks bugs and produces unexpected behavior. Users are not warned when their `.hyperpromptignore` patterns are invalid.

### 1.2 Primary Deliverables

1. Debug assertion for invalid regex patterns
2. Safe default behavior (return `false` instead of exact match)
3. Pattern validation during ignore file loading
4. Clear error messages with line numbers for invalid patterns

### 1.3 Success Criteria

- Invalid patterns in `.hyperpromptignore` throw `IndexerError.invalidIgnoreFile`
- Error message includes line number and the invalid pattern
- Debug builds assert on regex compilation failure
- Production builds return `false` for invalid patterns (no silent exact match)

### 1.4 Constraints and Assumptions

- Depends on EE-FIX-4 for GlobMatcher structure changes
- Must not break valid pattern handling
- Error messages should be actionable for users

---

## 2. Hierarchical TODO Plan

### Phase 1: GlobMatcher Changes

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 1.1 | Add debug assertion for invalid regex | Compilation failure | `assertionFailure` in DEBUG | High |
| 1.2 | Return `false` instead of exact match | Invalid pattern | Safe default | High |
| 1.3 | Expose `globToRegex` for validation | Private method | Internal method | Medium |

### Phase 2: Pattern Validation in ProjectIndexer

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 2.1 | Add pattern validation loop in `loadIgnorePatterns` | Pattern list | Validated patterns | High |
| 2.2 | Compile test regex for each pattern | Pattern string | Validation result | High |
| 2.3 | Throw `IndexerError.invalidIgnoreFile` with line number | Invalid pattern | Descriptive error | High |
| 2.4 | Include pattern text in error message | Error details | User-actionable message | High |

### Phase 3: Testing

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 3.1 | Test: Invalid pattern returns false | Bad pattern | `matches()` returns false | High |
| 3.2 | Test: Invalid pattern in ignore file throws | Bad .hyperpromptignore | IndexerError thrown | High |
| 3.3 | Test: Error message contains line number | Error output | Line number present | High |
| 3.4 | Test: Valid patterns still work | Valid .hyperpromptignore | Normal indexing | High |
| 3.5 | Test: Mixed valid/invalid patterns | Mix in file | Error on first invalid | Medium |

---

## 3. Execution Metadata

### 3.1 Task Details

| Task | Effort | Tools/Frameworks | Verification Method |
|------|--------|------------------|---------------------|
| 1.1-1.3 | 20 min | Swift | Unit test |
| 2.1-2.4 | 40 min | Swift | Unit test |
| 3.1-3.5 | 40 min | XCTest | Test execution |

### 3.2 Dependencies

- EE-FIX-4: GlobMatcher must be refactored first

### 3.3 Parallel Execution

- Phase 1 and Phase 2 can be done in parallel after EE-FIX-4
- Phase 3 tests depend on Phase 1 and Phase 2

---

## 4. Functional Requirements

### FR-1: Debug Assertion

In DEBUG builds, invalid regex patterns SHALL trigger `assertionFailure` to surface bugs during development.

### FR-2: Safe Production Default

In production builds, invalid patterns SHALL return `false` (no match) instead of falling back to exact string comparison.

### FR-3: Pattern Validation

During `.hyperpromptignore` loading, each pattern SHALL be validated by attempting regex compilation.

### FR-4: Descriptive Errors

Invalid pattern errors SHALL include:
- File path of the ignore file
- Line number where the invalid pattern appears (1-indexed)
- The invalid pattern text

---

## 5. Non-Functional Requirements

### NFR-1: User Experience

Error messages must be actionable — users should be able to find and fix the invalid pattern.

### NFR-2: Fail Fast

Validation happens at load time, not during matching, to surface errors early.

### NFR-3: Backwards Compatibility

Valid `.hyperpromptignore` files continue to work without changes.

---

## 6. Edge Cases and Failure Scenarios

| Scenario | Expected Behavior |
|----------|-------------------|
| Pattern with unbalanced brackets `[a` | Error at load time with line number |
| Pattern with invalid regex escape `\z` | Error at load time |
| Empty pattern | Skipped (not an error) |
| Comment line `# comment` | Skipped (not validated as pattern) |
| First line invalid | Error points to line 1 |
| Last line invalid | Error points to correct line number |
| Multiple invalid patterns | Error on first invalid (fail fast) |

---

## 7. Implementation Reference

### Current Code (GlobMatcher.swift:93-96)

```swift
guard let regexObj = try? NSRegularExpression(pattern: regex, options: []) else {
    // Invalid regex - fall back to exact match
    return path == pattern
}
```

### Fixed GlobMatcher Code

```swift
guard let regexObj = try? NSRegularExpression(pattern: regex, options: []) else {
    // Log the error in debug builds for developer awareness
    #if DEBUG
    assertionFailure(
        "Invalid regex pattern '\(regex)' generated from glob '\(pattern)'"
    )
    #endif
    // In production, treat invalid patterns as non-matching for safety
    return false
}
```

### Pattern Validation in ProjectIndexer

```swift
/// Loads and validates ignore patterns from .hyperpromptignore file
private func loadIgnorePatterns(workspaceRoot: String) throws -> [String] {
    let ignorePath = joinPath(workspaceRoot, ".hyperpromptignore")

    guard fileSystem.fileExists(at: ignorePath) else {
        return options.customIgnorePatterns
    }

    guard let content = try? fileSystem.readFile(at: ignorePath) else {
        return options.customIgnorePatterns
    }

    let lines = content.components(separatedBy: .newlines)
    var validPatterns: [String] = []
    let matcher = GlobMatcher()

    for (lineIndex, line) in lines.enumerated() {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Skip empty lines and comments
        if trimmed.isEmpty || trimmed.hasPrefix("#") {
            continue
        }

        // Validate pattern compiles to valid regex
        let testRegex = matcher.globToRegex(trimmed)
        guard (try? NSRegularExpression(pattern: testRegex, options: [])) != nil else {
            throw IndexerError.invalidIgnoreFile(
                path: ignorePath,
                reason: "Invalid glob pattern at line \(lineIndex + 1): '\(trimmed)'"
            )
        }

        validPatterns.append(trimmed)
    }

    return validPatterns + options.customIgnorePatterns
}
```

### Expose globToRegex (GlobMatcher.swift)

```swift
/// Converts glob pattern to regular expression (internal for validation)
func globToRegex(_ pattern: String) -> String {
    // ... existing implementation ...
}
```

---

## 8. Test Cases

```swift
// MARK: - Invalid Pattern Tests

func testGlobMatcher_InvalidPattern_ReturnsFalse() {
    var matcher = GlobMatcher()
    // Unbalanced bracket is invalid regex
    let result = matcher.matches(path: "file.txt", pattern: "[invalid")
    XCTAssertFalse(result)
}

func testLoadIgnorePatterns_InvalidPattern_ThrowsError() {
    let mockFS = MockFileSystem()
    mockFS.addFile(
        path: "/workspace/.hyperpromptignore",
        content: "*.log\n[invalid\n*.tmp"
    )

    let indexer = ProjectIndexer(fileSystem: mockFS)

    XCTAssertThrowsError(try indexer.index(workspaceRoot: "/workspace")) { error in
        guard case IndexerError.invalidIgnoreFile(let path, let reason) = error else {
            XCTFail("Expected invalidIgnoreFile error")
            return
        }
        XCTAssertTrue(path.contains(".hyperpromptignore"))
        XCTAssertTrue(reason.contains("line 2"))
        XCTAssertTrue(reason.contains("[invalid"))
    }
}

func testLoadIgnorePatterns_ValidPatterns_Succeeds() {
    let mockFS = MockFileSystem()
    mockFS.addFile(
        path: "/workspace/.hyperpromptignore",
        content: "*.log\nbuild/\n**/*.tmp"
    )
    mockFS.addDirectory(path: "/workspace")

    let indexer = ProjectIndexer(fileSystem: mockFS)

    XCTAssertNoThrow(try indexer.index(workspaceRoot: "/workspace"))
}

func testLoadIgnorePatterns_CommentsAndEmptyLines_Skipped() {
    let mockFS = MockFileSystem()
    mockFS.addFile(
        path: "/workspace/.hyperpromptignore",
        content: "# This is a comment\n\n*.log\n  # Another comment\n"
    )
    mockFS.addDirectory(path: "/workspace")

    let indexer = ProjectIndexer(fileSystem: mockFS)

    XCTAssertNoThrow(try indexer.index(workspaceRoot: "/workspace"))
}
```

---

## 9. Acceptance Checklist

- [ ] Debug assertion added for invalid regex in DEBUG builds
- [ ] Invalid patterns return `false` in production (not exact match)
- [ ] Pattern validation added to `loadIgnorePatterns`
- [ ] `IndexerError.invalidIgnoreFile` thrown for invalid patterns
- [ ] Error message includes line number
- [ ] Error message includes invalid pattern text
- [ ] Test: invalid pattern returns false
- [ ] Test: invalid pattern in ignore file throws
- [ ] Test: valid patterns still work
- [ ] All existing tests pass
