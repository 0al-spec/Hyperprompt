# PRD: EE-FIX-6 — ProjectIndexer Integration Tests

**Task ID:** EE-FIX-6
**Priority:** P1 (High)
**Estimated Effort:** 4 hours
**Status:** Pending
**Source:** [REVIEW_EditorEngine_Implementation.md](REVIEW_EditorEngine_Implementation.md) — Issue H-004

---

## 1. Scope and Intent

### 1.1 Objective

Replace placeholder tests in `ProjectIndexerTests.swift` with comprehensive integration tests covering all core functionality. The current tests have comments like `XCTAssertTrue(true, "Integration tests require MockFileSystem implementation")` which provide no actual test coverage.

### 1.2 Primary Deliverables

1. MockFileSystem verification/enhancement for directory structures
2. 10 integration test scenarios implemented
3. Removal of all placeholder tests
4. Full coverage of ProjectIndexer core functionality

### 1.3 Success Criteria

- All 10 test scenarios pass
- No placeholder `XCTAssertTrue(true, ...)` tests remain
- Test coverage includes all indexer configuration options
- Tests are deterministic and isolated

### 1.4 Constraints and Assumptions

- MockFileSystem exists and supports basic file operations
- May need to enhance MockFileSystem for directory listing
- Tests run with `#if Editor` compilation flag

---

## 2. Hierarchical TODO Plan

### Phase 1: MockFileSystem Verification

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 1.1 | Verify `MockFileSystem.listDirectory` works | Test call | Directory contents | High |
| 1.2 | Verify `MockFileSystem.isDirectory` works | Test call | Boolean result | High |
| 1.3 | Add `addDirectory` helper if missing | MockFileSystem | Directory support | High |
| 1.4 | Add `addFile` helper if missing | MockFileSystem | File creation | High |

### Phase 2: Integration Tests Implementation

| # | Test Scenario | Description | Priority |
|---|---------------|-------------|----------|
| 2.1 | Multi-level directory traversal | Nested directories with .hc and .md files | High |
| 2.2 | .hyperpromptignore pattern matching | Glob patterns exclude matching files | High |
| 2.3 | Default ignore directory exclusion | .git, .build, node_modules excluded | High |
| 2.4 | Symlink skip policy | Symlinks not followed by default | High |
| 2.5 | Symlink follow policy | Symlinks followed when configured | Medium |
| 2.6 | Hidden file exclusion | Files starting with . excluded by default | High |
| 2.7 | Hidden file inclusion | Hidden files included when configured | Medium |
| 2.8 | Max depth limiting | Deep directories stop at configured depth | High |
| 2.9 | Deterministic ordering | Files returned in lexicographic order | High |
| 2.10 | Empty workspace | Workspace with no target files | Medium |

### Phase 3: Cleanup

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 3.1 | Remove placeholder test methods | Old tests | Deleted code | High |
| 3.2 | Update test file header comments | Comments | Accurate description | Low |
| 3.3 | Verify all tests pass | Test suite | 100% pass | High |

---

## 3. Execution Metadata

### 3.1 Task Details

| Task | Effort | Tools/Frameworks | Verification Method |
|------|--------|------------------|---------------------|
| 1.1-1.4 | 30 min | Swift, MockFileSystem | Compilation, test |
| 2.1-2.10 | 2.5 hours | XCTest | Test execution |
| 3.1-3.3 | 30 min | Code review | Test execution |

### 3.2 Dependencies

- MockFileSystem implementation in test utilities

### 3.3 Parallel Execution

- Phase 1 must complete first
- Phase 2 tests can be written in parallel
- Phase 3 runs after all tests pass

---

## 4. Test Specifications

### 4.1 Test: Multi-Level Directory Traversal

```swift
func testIndexer_MultiLevelDirectoryTraversal() throws {
    let mockFS = MockFileSystem()
    mockFS.addDirectory(path: "/workspace")
    mockFS.addDirectory(path: "/workspace/src")
    mockFS.addDirectory(path: "/workspace/docs")
    mockFS.addFile(path: "/workspace/main.hc", content: "")
    mockFS.addFile(path: "/workspace/src/utils.hc", content: "")
    mockFS.addFile(path: "/workspace/docs/readme.md", content: "")

    let indexer = ProjectIndexer(fileSystem: mockFS)
    let index = try indexer.index(workspaceRoot: "/workspace")

    XCTAssertEqual(index.totalFiles, 3)
    // Verify lexicographic ordering
    XCTAssertEqual(index.files[0].path, "docs/readme.md")
    XCTAssertEqual(index.files[1].path, "main.hc")
    XCTAssertEqual(index.files[2].path, "src/utils.hc")
}
```

### 4.2 Test: .hyperpromptignore Pattern Matching

```swift
func testIndexer_HyperpromptignoreExcludesMatches() throws {
    let mockFS = MockFileSystem()
    mockFS.addDirectory(path: "/workspace")
    mockFS.addDirectory(path: "/workspace/tmp")
    mockFS.addFile(path: "/workspace/.hyperpromptignore", content: "*.draft\ntmp/\n")
    mockFS.addFile(path: "/workspace/main.hc", content: "")
    mockFS.addFile(path: "/workspace/notes.draft", content: "")
    mockFS.addFile(path: "/workspace/tmp/temp.hc", content: "")

    let indexer = ProjectIndexer(fileSystem: mockFS)
    let index = try indexer.index(workspaceRoot: "/workspace")

    XCTAssertEqual(index.totalFiles, 1)
    XCTAssertEqual(index.files[0].path, "main.hc")
}
```

### 4.3 Test: Default Ignore Directory Exclusion

```swift
func testIndexer_DefaultIgnoreDirectoriesExcluded() throws {
    let mockFS = MockFileSystem()
    mockFS.addDirectory(path: "/workspace")
    mockFS.addDirectory(path: "/workspace/.git")
    mockFS.addDirectory(path: "/workspace/.build")
    mockFS.addDirectory(path: "/workspace/node_modules")
    mockFS.addFile(path: "/workspace/main.hc", content: "")
    mockFS.addFile(path: "/workspace/.git/config.hc", content: "")
    mockFS.addFile(path: "/workspace/.build/output.hc", content: "")
    mockFS.addFile(path: "/workspace/node_modules/package.hc", content: "")

    let indexer = ProjectIndexer(fileSystem: mockFS)
    let index = try indexer.index(workspaceRoot: "/workspace")

    XCTAssertEqual(index.totalFiles, 1)
    XCTAssertEqual(index.files[0].path, "main.hc")
}
```

### 4.4 Test: Symlink Skip Policy (Default)

```swift
func testIndexer_SymlinkSkipPolicy() throws {
    let mockFS = MockFileSystem()
    mockFS.addDirectory(path: "/workspace")
    mockFS.addDirectory(path: "/external")
    mockFS.addFile(path: "/workspace/main.hc", content: "")
    mockFS.addFile(path: "/external/linked.hc", content: "")
    mockFS.addSymlink(path: "/workspace/link", target: "/external")

    let indexer = ProjectIndexer(fileSystem: mockFS, options: IndexerOptions(symlinkPolicy: .skip))
    let index = try indexer.index(workspaceRoot: "/workspace")

    XCTAssertEqual(index.totalFiles, 1)
    XCTAssertEqual(index.files[0].path, "main.hc")
}
```

### 4.5 Test: Symlink Follow Policy

```swift
func testIndexer_SymlinkFollowPolicy() throws {
    let mockFS = MockFileSystem()
    mockFS.addDirectory(path: "/workspace")
    mockFS.addDirectory(path: "/external")
    mockFS.addFile(path: "/workspace/main.hc", content: "")
    mockFS.addFile(path: "/external/linked.hc", content: "")
    mockFS.addSymlink(path: "/workspace/link", target: "/external")

    let indexer = ProjectIndexer(fileSystem: mockFS, options: IndexerOptions(symlinkPolicy: .follow))
    let index = try indexer.index(workspaceRoot: "/workspace")

    XCTAssertEqual(index.totalFiles, 2)
}
```

### 4.6 Test: Hidden File Exclusion (Default)

```swift
func testIndexer_HiddenFilesExcluded() throws {
    let mockFS = MockFileSystem()
    mockFS.addDirectory(path: "/workspace")
    mockFS.addFile(path: "/workspace/main.hc", content: "")
    mockFS.addFile(path: "/workspace/.hidden.hc", content: "")

    let indexer = ProjectIndexer(fileSystem: mockFS, options: IndexerOptions(hiddenEntryPolicy: .exclude))
    let index = try indexer.index(workspaceRoot: "/workspace")

    XCTAssertEqual(index.totalFiles, 1)
    XCTAssertEqual(index.files[0].path, "main.hc")
}
```

### 4.7 Test: Hidden File Inclusion

```swift
func testIndexer_HiddenFilesIncluded() throws {
    let mockFS = MockFileSystem()
    mockFS.addDirectory(path: "/workspace")
    mockFS.addFile(path: "/workspace/main.hc", content: "")
    mockFS.addFile(path: "/workspace/.hidden.hc", content: "")

    let indexer = ProjectIndexer(fileSystem: mockFS, options: IndexerOptions(hiddenEntryPolicy: .include))
    let index = try indexer.index(workspaceRoot: "/workspace")

    XCTAssertEqual(index.totalFiles, 2)
}
```

### 4.8 Test: Max Depth Limiting

```swift
func testIndexer_MaxDepthLimiting() throws {
    let mockFS = MockFileSystem()
    mockFS.addDirectory(path: "/workspace")
    mockFS.addDirectory(path: "/workspace/level1")
    mockFS.addDirectory(path: "/workspace/level1/level2")
    mockFS.addDirectory(path: "/workspace/level1/level2/level3")
    mockFS.addFile(path: "/workspace/root.hc", content: "")
    mockFS.addFile(path: "/workspace/level1/l1.hc", content: "")
    mockFS.addFile(path: "/workspace/level1/level2/l2.hc", content: "")
    mockFS.addFile(path: "/workspace/level1/level2/level3/l3.hc", content: "")

    let indexer = ProjectIndexer(fileSystem: mockFS, options: IndexerOptions(maxDepth: 2))
    let index = try indexer.index(workspaceRoot: "/workspace")

    // Only root and level1 should be indexed (depth 0 and 1)
    XCTAssertEqual(index.totalFiles, 2)
    XCTAssertTrue(index.files.contains { $0.path == "root.hc" })
    XCTAssertTrue(index.files.contains { $0.path == "level1/l1.hc" })
}
```

### 4.9 Test: Deterministic Ordering

```swift
func testIndexer_DeterministicOrdering() throws {
    let mockFS = MockFileSystem()
    mockFS.addDirectory(path: "/workspace")
    mockFS.addFile(path: "/workspace/zebra.hc", content: "")
    mockFS.addFile(path: "/workspace/alpha.hc", content: "")
    mockFS.addFile(path: "/workspace/beta.md", content: "")

    let indexer = ProjectIndexer(fileSystem: mockFS)
    let index = try indexer.index(workspaceRoot: "/workspace")

    XCTAssertEqual(index.files[0].path, "alpha.hc")
    XCTAssertEqual(index.files[1].path, "beta.md")
    XCTAssertEqual(index.files[2].path, "zebra.hc")
}
```

### 4.10 Test: Empty Workspace

```swift
func testIndexer_EmptyWorkspace() throws {
    let mockFS = MockFileSystem()
    mockFS.addDirectory(path: "/workspace")
    // No files added

    let indexer = ProjectIndexer(fileSystem: mockFS)
    let index = try indexer.index(workspaceRoot: "/workspace")

    XCTAssertEqual(index.totalFiles, 0)
    XCTAssertTrue(index.files.isEmpty)
}
```

---

## 5. MockFileSystem Requirements

### Required Methods

```swift
protocol MockFileSystemProtocol {
    func addDirectory(path: String)
    func addFile(path: String, content: String)
    func addSymlink(path: String, target: String)

    // FileSystem protocol
    func fileExists(at path: String) -> Bool
    func isDirectory(at path: String) -> Bool
    func listDirectory(at path: String) throws -> [String]
    func readFile(at path: String) throws -> String
    func fileAttributes(at path: String) -> FileAttributes?
}
```

---

## 6. Acceptance Checklist

- [ ] MockFileSystem verified/enhanced for all required operations
- [ ] Test 2.1: Multi-level directory traversal passes
- [ ] Test 2.2: .hyperpromptignore pattern matching passes
- [ ] Test 2.3: Default ignore directory exclusion passes
- [ ] Test 2.4: Symlink skip policy passes
- [ ] Test 2.5: Symlink follow policy passes
- [ ] Test 2.6: Hidden file exclusion passes
- [ ] Test 2.7: Hidden file inclusion passes
- [ ] Test 2.8: Max depth limiting passes
- [ ] Test 2.9: Deterministic ordering passes
- [ ] Test 2.10: Empty workspace passes
- [ ] All placeholder tests removed
- [ ] All existing tests still pass
