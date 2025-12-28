# PRD: EE-FIX-1 — Workspace Root Path Validation

**Task ID:** EE-FIX-1
**Priority:** P0 (Blocker)
**Estimated Effort:** 1 hour
**Status:** Pending
**Source:** [REVIEW_EditorEngine_Implementation.md](REVIEW_EditorEngine_Implementation.md) — Issue B-001

---

## 1. Scope and Intent

### 1.1 Objective

Add validation to `ProjectIndexer.index(workspaceRoot:)` to ensure the workspace root is an absolute path. Relative paths must be rejected with a clear error message.

### 1.2 Primary Deliverables

1. New error case `IndexerError.invalidWorkspaceRoot(path:reason:)`
2. Validation check in `ProjectIndexer.index()` before workspace existence check
3. Unit tests covering absolute/relative path validation

### 1.3 Success Criteria

- Calling `index(workspaceRoot: "relative/path")` throws `IndexerError.invalidWorkspaceRoot`
- Calling `index(workspaceRoot: "/absolute/path")` proceeds normally
- Error message clearly indicates the path must be absolute

### 1.4 Constraints and Assumptions

- Platform: macOS/Linux only (paths start with `/`)
- No Windows path support required (no drive letters like `C:\`)
- Existing API signature remains unchanged

---

## 2. Hierarchical TODO Plan

### Phase 1: Error Type Extension

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 1.1 | Add `invalidWorkspaceRoot(path:reason:)` case to `IndexerError` | IndexerError enum | Updated enum with new case | High |
| 1.2 | Add description for new error case in `CustomStringConvertible` | Error case | Human-readable error message | High |
| 1.3 | Add Equatable conformance for new case | Error case | Equatable implementation | Medium |

### Phase 2: Validation Logic

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 2.1 | Add `hasPrefix("/")` check at start of `index()` method | workspaceRoot parameter | Guard clause with throw | High |
| 2.2 | Position check before `fileExists` check | Code order | Validation before I/O | High |

### Phase 3: Unit Tests

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 3.1 | Add test `testIndexer_RelativePath_ThrowsError` | Relative path | Assert throws invalidWorkspaceRoot | High |
| 3.2 | Add test `testIndexer_AbsolutePath_Proceeds` | Absolute path | Assert no error on validation | High |
| 3.3 | Add test `testIndexerError_InvalidWorkspaceRoot_Description` | Error case | Assert description contains path | Medium |

---

## 3. Execution Metadata

### 3.1 Task Details

| Task | Effort | Tools/Frameworks | Verification Method |
|------|--------|------------------|---------------------|
| 1.1 | 5 min | Swift enum | Compilation |
| 1.2 | 5 min | Swift switch | Compilation |
| 1.3 | 5 min | Swift Equatable | Compilation |
| 2.1 | 10 min | Swift guard | Unit test |
| 2.2 | 5 min | Code review | Code inspection |
| 3.1 | 10 min | XCTest | Test execution |
| 3.2 | 10 min | XCTest, MockFileSystem | Test execution |
| 3.3 | 5 min | XCTest | Test execution |

### 3.2 Dependencies

- None (standalone fix)

### 3.3 Parallel Execution

- Phase 1 tasks (1.1, 1.2, 1.3) can be done together
- Phase 2 depends on Phase 1 completion
- Phase 3 depends on Phase 2 completion

---

## 4. Functional Requirements

### FR-1: Absolute Path Validation

The `index(workspaceRoot:)` method SHALL validate that the workspace root path begins with `/`.

### FR-2: Error Reporting

When a relative path is provided, the method SHALL throw `IndexerError.invalidWorkspaceRoot` with:
- The invalid path in the error
- A reason stating "Workspace root must be an absolute path"

### FR-3: Validation Order

Path validation SHALL occur before filesystem existence check to fail fast.

---

## 5. Non-Functional Requirements

### NFR-1: Performance

Validation adds O(1) string prefix check — negligible overhead.

### NFR-2: Security

Prevents unpredictable behavior when current directory changes during execution.

### NFR-3: Backwards Compatibility

Existing valid absolute paths continue to work unchanged.

---

## 6. Edge Cases and Failure Scenarios

| Scenario | Input | Expected Behavior |
|----------|-------|-------------------|
| Empty string | `""` | Throws `invalidWorkspaceRoot` |
| Current directory | `"."` | Throws `invalidWorkspaceRoot` |
| Parent directory | `"../foo"` | Throws `invalidWorkspaceRoot` |
| Relative path | `"src/project"` | Throws `invalidWorkspaceRoot` |
| Root path | `"/"` | Proceeds to existence check |
| Absolute path | `"/Users/dev/project"` | Proceeds to existence check |
| Path with tilde | `"~/project"` | Throws `invalidWorkspaceRoot` (tilde not expanded) |

---

## 7. Implementation Reference

### Current Code (ProjectIndexer.swift:136-140)

```swift
public func index(workspaceRoot: String) throws -> ProjectIndex {
    // Verify workspace exists
    guard fileSystem.fileExists(at: workspaceRoot) else {
        throw IndexerError.workspaceNotFound(path: workspaceRoot)
    }
    // ...
}
```

### Target Code

```swift
public func index(workspaceRoot: String) throws -> ProjectIndex {
    // Validate workspace root is absolute path
    guard workspaceRoot.hasPrefix("/") else {
        throw IndexerError.invalidWorkspaceRoot(
            path: workspaceRoot,
            reason: "Workspace root must be an absolute path"
        )
    }

    // Verify workspace exists
    guard fileSystem.fileExists(at: workspaceRoot) else {
        throw IndexerError.workspaceNotFound(path: workspaceRoot)
    }
    // ...
}
```

### New Error Case

```swift
public enum IndexerError: Error, Equatable {
    // ... existing cases ...

    /// Workspace root path is invalid (e.g., relative path)
    case invalidWorkspaceRoot(path: String, reason: String)
}

extension IndexerError: CustomStringConvertible {
    public var description: String {
        switch self {
        // ... existing cases ...
        case .invalidWorkspaceRoot(let path, let reason):
            return "Invalid workspace root '\(path)': \(reason)"
        }
    }
}
```

---

## 8. Acceptance Checklist

- [x] `IndexerError.invalidWorkspaceRoot` case added
- [x] Error description implemented
- [x] Validation guard clause added to `index()` method
- [x] Test for relative path rejection passes
- [x] Test for absolute path acceptance passes
- [x] All existing tests continue to pass
