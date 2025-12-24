# PRD — EE1: Project Indexing (EditorEngine)

**Task ID:** EE1
**Task Name:** Project Indexing
**Priority:** P1 (High)
**Phase:** Phase 10 — Editor Engine Module
**Estimated Effort:** 3 hours
**Dependencies:** EE0 (EditorEngine Module Foundation) ✅
**Status:** In Progress
**Date:** 2025-12-20
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Implement **project indexing** for the EditorEngine module in the Hyperprompt compiler. This system enables editor clients to discover and enumerate all Hypercode (`.hc`) and Markdown (`.md`) files within a workspace with deterministic ordering, configurable ignore patterns, and built-in exclusion of common build artifacts and hidden directories.

**Restatement in Precise Terms:**
Create a file discovery subsystem that:
1. Recursively scans a workspace directory for `.hc` and `.md` files
2. Produces a deterministic, lexicographically sorted list of file paths
3. Respects `.hyperpromptignore` patterns (if present)
4. Excludes hidden directories (`.git`, `build`, `node_modules`, `Packages`) by default
5. Provides metadata for each discovered file (path, type, size)

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| `ProjectIndex` struct | Data structure containing discovered files with metadata |
| `ProjectIndexer` type | File scanner with configurable ignore rules |
| `.hyperpromptignore` support | Glob pattern matching for exclusion rules |
| Unit test suite | 5+ tests covering edge cases and ignore patterns |
| Integration with EditorEngine | Public API accessible to editor clients |

### 1.3 Success Criteria

**The implementation is successful when:**
1. ✅ All `.hc` and `.md` files in a test workspace are discovered
2. ✅ File ordering is deterministic (lexicographic sort by full path)
3. ✅ `.hyperpromptignore` patterns correctly exclude matching files
4. ✅ Hidden directories (`.git`, `build`, `node_modules`, `Packages`) are excluded by default
5. ✅ Unit tests achieve >90% code coverage for indexer logic
6. ✅ Performance: indexing 1000 files completes in <500ms
7. ✅ API is accessible from EditorEngine module (trait-gated)

### 1.4 Constraints

**Technical Constraints:**
- Must use Swift 6.1+ FileManager APIs
- Must not follow symlinks (security constraint)
- Must not access files outside workspace root (path traversal protection)
- Must be deterministic across platforms (macOS, Linux)
- Must be trait-gated under `Editor` trait (SPM Traits)

**Design Constraints:**
- Reuse existing `FileSystem` abstraction from Core module
- No network access
- No caching in v1 (cache can be added in future versions)
- No UI dependencies (this is backend logic only)

### 1.5 Assumptions

1. Workspace root is a valid, readable directory
2. File system permissions allow reading directory contents
3. `.hyperpromptignore` file (if present) is valid UTF-8
4. Maximum directory depth: 100 levels (reasonable limit to prevent infinite recursion)
5. Editor clients will handle UI presentation of indexed files

### 1.6 External Dependencies

| Dependency | Purpose | Version |
|-----------|---------|---------|
| Foundation.FileManager | Directory traversal, file metadata | Swift stdlib |
| Core.FileSystem | File I/O abstraction | Hyperprompt 0.1+ |
| Swift Glob | Pattern matching for ignore rules | TBD (or implement simple matcher) |

---

## 2. Structured TODO Plan

### Phase 0: API Design & Data Structures

#### Task 2.0.1: Define `ProjectIndex` Struct
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** None (entry point)

**Input:**
- Requirements from PRD_EditorEngine.md (§2.1.1)
- Existing `ManifestEntry` struct from Emitter module (for reference)

**Process:**
1. Define `FileIndexEntry` struct with:
   - `path: String` (relative to workspace root)
   - `type: FileType` (enum: `.hypercode`, `.markdown`)
   - `size: Int` (bytes)
   - `lastModified: Date` (optional for future caching)
2. Define `ProjectIndex` struct with:
   - `workspaceRoot: String`
   - `files: [FileIndexEntry]` (sorted by path)
   - `discoveredAt: Date`
   - `totalFiles: Int` (computed property)

**Expected Output:**
- Swift file: `Sources/EditorEngine/ProjectIndex.swift`
- Types are `Codable` for future serialization
- Clear documentation comments

**Acceptance Criteria:**
- ✅ Structs compile without errors
- ✅ All properties have clear semantic meaning
- ✅ Conforms to `Codable` protocol
- ✅ Unit tests can instantiate and serialize/deserialize

**Verification:**
```swift
let entry = FileIndexEntry(path: "foo.hc", type: .hypercode, size: 1024)
let index = ProjectIndex(workspaceRoot: "/test", files: [entry])
XCTAssertEqual(index.totalFiles, 1)
```

---

#### Task 2.0.2: Define `ProjectIndexer` API
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** 2.0.1 (needs `ProjectIndex` struct)

**Input:**
- `ProjectIndex` struct definition
- `FileSystem` protocol from Core module

**Process:**
1. Define `IndexerOptions` struct:
   - `followSymlinks: Bool = false`
   - `includeHidden: Bool = false`
   - `maxDepth: Int = 100`
   - `customIgnorePatterns: [String] = []`
2. Define `ProjectIndexer` class/struct:
   - `init(fileSystem: FileSystem, options: IndexerOptions)`
   - `func index(workspaceRoot: String) throws -> ProjectIndex`
3. Define error types:
   - `IndexerError.workspaceNotFound(path: String)`
   - `IndexerError.permissionDenied(path: String)`
   - `IndexerError.maxDepthExceeded(depth: Int)`

**Expected Output:**
- Swift file: `Sources/EditorEngine/ProjectIndexer.swift`
- Clean, minimal API surface
- Error handling strategy documented

**Acceptance Criteria:**
- ✅ API is self-documenting (clear parameter names)
- ✅ Errors are actionable (include context)
- ✅ Compiles with no warnings
- ✅ Can be mocked for testing

**Verification:**
```swift
let indexer = ProjectIndexer(fileSystem: LocalFileSystem(), options: .default)
let index = try indexer.index(workspaceRoot: "/test/workspace")
XCTAssertNotNil(index)
```

---

### Phase 1: Core Indexing Logic

#### Task 2.1.1: Implement File Discovery (Recursive Scan)
**Priority:** High
**Effort:** 1 hour
**Dependencies:** 2.0.2 (needs `ProjectIndexer` API)

**Input:**
- `workspaceRoot: String`
- `FileSystem` protocol for I/O operations

**Process:**
1. Implement recursive directory traversal:
   ```swift
   func discoverFiles(at directory: String, depth: Int) throws -> [String] {
       guard depth < options.maxDepth else {
           throw IndexerError.maxDepthExceeded(depth: depth)
       }

       let contents = try fileSystem.listDirectory(at: directory)
       var files: [String] = []

       for item in contents.sorted() {  // Deterministic ordering
           let fullPath = joinPath(directory, item)

           if isDirectory(fullPath) {
               if shouldSkipDirectory(fullPath) { continue }
               files.append(contentsOf: try discoverFiles(at: fullPath, depth: depth + 1))
           } else if isTargetFile(fullPath) {
               files.append(fullPath)
           }
       }

       return files
   }
   ```

2. Implement helper predicates:
   - `isTargetFile(path: String) -> Bool` (checks for `.hc` or `.md` extension)
   - `isDirectory(path: String) -> Bool`
   - `shouldSkipDirectory(path: String) -> Bool` (checks default ignore list)

3. Handle symlinks:
   - If `followSymlinks == false`, skip symlinks
   - If `followSymlinks == true`, resolve and check for cycles

**Expected Output:**
- List of discovered file paths (absolute)
- Sorted lexicographically
- No duplicates

**Acceptance Criteria:**
- ✅ Discovers all `.hc` and `.md` files in test workspace
- ✅ Ordering is deterministic (same input → same output)
- ✅ No crashes on permission errors (graceful error handling)
- ✅ Respects `maxDepth` limit
- ✅ Symlinks are handled according to `followSymlinks` option

**Verification:**
```bash
# Test workspace structure:
/test/
  ├── main.hc
  ├── docs/
  │   └── intro.md
  ├── .git/  (should be skipped)
  └── build/  (should be skipped)

# Expected output:
["/test/docs/intro.md", "/test/main.hc"]
```

---

#### Task 2.1.2: Implement Default Ignore Rules
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** 2.1.1 (needs directory traversal logic)

**Input:**
- Directory path being scanned

**Process:**
1. Define default ignore list:
   ```swift
   static let defaultIgnoreDirs: Set<String> = [
       ".git",
       "build",
       "node_modules",
       "Packages",
       ".build",
       "DerivedData",
       ".vscode",
       ".idea"
   ]
   ```

2. Implement `shouldSkipDirectory(path: String) -> Bool`:
   ```swift
   func shouldSkipDirectory(_ path: String) -> Bool {
       let basename = path.lastPathComponent

       // Skip hidden directories (unless includeHidden == true)
       if !options.includeHidden && basename.hasPrefix(".") {
           return true
       }

       // Skip default ignore list
       if Self.defaultIgnoreDirs.contains(basename) {
           return true
       }

       return false
   }
   ```

**Expected Output:**
- Directories in default ignore list are excluded
- Hidden directories are excluded (unless `includeHidden == true`)

**Acceptance Criteria:**
- ✅ `.git` directory is never scanned
- ✅ `build`, `node_modules`, `Packages` are excluded
- ✅ Hidden directories (`.foo`) are excluded by default
- ✅ Option `includeHidden` can override hidden directory exclusion

**Verification:**
```swift
let indexer = ProjectIndexer(fileSystem: fs, options: .default)
let index = try indexer.index(workspaceRoot: "/test")
// Assert that index.files contains no paths starting with ".git/"
XCTAssertFalse(index.files.contains { $0.path.contains(".git/") })
```

---

### Phase 2: .hyperpromptignore Support

#### Task 2.2.1: Parse .hyperpromptignore File
**Priority:** High
**Effort:** 45 minutes
**Dependencies:** 2.1.1 (needs file discovery logic)

**Input:**
- Workspace root directory
- Optional `.hyperpromptignore` file path

**Process:**
1. Check if `.hyperpromptignore` exists at workspace root:
   ```swift
   let ignorePath = joinPath(workspaceRoot, ".hyperpromptignore")
   guard fileSystem.fileExists(at: ignorePath) else { return [] }
   ```

2. Parse ignore file (similar to `.gitignore` format):
   - One pattern per line
   - Lines starting with `#` are comments (skip)
   - Empty lines are ignored
   - Patterns are glob-style (`*.log`, `tmp/`, `**/*.tmp`)

3. Store patterns in `[String]` array

**Expected Output:**
- Array of ignore patterns: `["*.log", "tmp/", "**/*.tmp"]`

**Acceptance Criteria:**
- ✅ `.hyperpromptignore` file is parsed correctly
- ✅ Comments and blank lines are ignored
- ✅ Patterns are trimmed (no leading/trailing whitespace)
- ✅ Invalid patterns are logged but don't crash indexer

**Verification:**
```
# .hyperpromptignore
# Build artifacts
*.log
tmp/

# Test files
**/*.test.md
```

Expected patterns: `["*.log", "tmp/", "**/*.test.md"]`

---

#### Task 2.2.2: Implement Glob Pattern Matching
**Priority:** High
**Effort:** 1 hour
**Dependencies:** 2.2.1 (needs parsed patterns)

**Input:**
- File path (relative to workspace root)
- List of glob patterns

**Process:**
1. Implement simple glob matcher or use library:
   - `*` matches any characters except `/`
   - `**` matches any characters including `/`
   - `?` matches single character
   - `[abc]` matches any character in set

2. Implement `matches(path: String, pattern: String) -> Bool`:
   ```swift
   func matches(path: String, pattern: String) -> Bool {
       // Convert glob pattern to regex
       let regex = globToRegex(pattern)
       return path.range(of: regex, options: .regularExpression) != nil
   }
   ```

3. Integrate into file discovery:
   ```swift
   if ignorePatterns.contains(where: { matches(path: relativePath, pattern: $0) }) {
       continue  // Skip this file
   }
   ```

**Expected Output:**
- Files matching ignore patterns are excluded from index

**Acceptance Criteria:**
- ✅ `*.log` excludes all `.log` files
- ✅ `tmp/` excludes `tmp` directory and all contents
- ✅ `**/*.test.md` excludes `.test.md` files at any depth
- ✅ Patterns are case-sensitive (unless platform requires otherwise)

**Verification:**
```
Workspace:
  ├── main.hc
  ├── debug.log  (excluded by *.log)
  └── tests/
      └── foo.test.md  (excluded by **/*.test.md)

Index should contain only: ["main.hc"]
```

---

### Phase 3: Metadata Collection & Finalization

#### Task 2.3.1: Collect File Metadata
**Priority:** Medium
**Effort:** 30 minutes
**Dependencies:** 2.1.1 (needs discovered file list)

**Input:**
- List of discovered file paths

**Process:**
1. For each discovered file, gather metadata:
   ```swift
   func getFileMetadata(path: String) throws -> FileIndexEntry {
       let attrs = try fileSystem.attributes(at: path)
       let type: FileType = path.hasSuffix(".hc") ? .hypercode : .markdown

       return FileIndexEntry(
           path: relativePath(path, to: workspaceRoot),
           type: type,
           size: attrs.size,
           lastModified: attrs.modificationDate
       )
   }
   ```

2. Build `ProjectIndex`:
   ```swift
   let entries = try discoveredPaths.map { try getFileMetadata(path: $0) }
       .sorted { $0.path < $1.path }  // Deterministic ordering

   return ProjectIndex(
       workspaceRoot: workspaceRoot,
       files: entries,
       discoveredAt: Date()
   )
   ```

**Expected Output:**
- `ProjectIndex` with complete metadata for all files

**Acceptance Criteria:**
- ✅ All files have accurate size information
- ✅ Relative paths are correct (relative to workspace root)
- ✅ File types are correctly identified (`.hc` vs `.md`)
- ✅ Entries are sorted lexicographically by path

**Verification:**
```swift
let index = try indexer.index(workspaceRoot: "/test")
XCTAssertEqual(index.files[0].path, "docs/intro.md")
XCTAssertEqual(index.files[1].path, "main.hc")
XCTAssertTrue(index.files[0].size > 0)
```

---

### Phase 4: Testing & Integration

#### Task 2.4.1: Write Unit Tests (Edge Cases)
**Priority:** High
**Effort:** 1 hour
**Dependencies:** All implementation tasks complete

**Input:**
- Implemented `ProjectIndexer`
- `MockFileSystem` from Core module

**Process:**
Create 5+ unit tests covering:

1. **Test: Empty Workspace**
   - Input: Empty directory
   - Expected: `ProjectIndex` with 0 files

2. **Test: Single File**
   - Input: Workspace with one `main.hc`
   - Expected: Index contains exactly one entry

3. **Test: Nested Directories**
   - Input: Multi-level directory structure
   - Expected: All files discovered, correct relative paths

4. **Test: Ignore Patterns**
   - Input: Workspace with `.hyperpromptignore` containing `*.log`
   - Expected: `.log` files excluded

5. **Test: Hidden Directories**
   - Input: Workspace with `.git/` directory containing files
   - Expected: `.git/` excluded, files not in index

6. **Test: Symlink Handling**
   - Input: Workspace with symlink to external file
   - Expected: Symlink not followed (default behavior)

7. **Test: Permission Errors**
   - Input: Directory with unreadable subdirectory
   - Expected: Graceful error or skip

8. **Test: Deterministic Ordering**
   - Input: Workspace scanned twice
   - Expected: Identical output (same order)

**Expected Output:**
- Test file: `Tests/EditorEngineTests/ProjectIndexerTests.swift`
- All tests pass
- Code coverage >90%

**Acceptance Criteria:**
- ✅ All 5+ tests pass
- ✅ Tests use `MockFileSystem` (no actual I/O)
- ✅ Edge cases are covered (empty workspace, symlinks, errors)
- ✅ Tests run in <100ms total

---

#### Task 2.4.2: Integration with EditorEngine Module
**Priority:** High
**Effort:** 15 minutes
**Dependencies:** 2.4.1 (tests must pass first)

**Input:**
- Implemented `ProjectIndexer`
- EditorEngine module structure (from EE0)

**Process:**
1. Export public API from EditorEngine module:
   ```swift
   // Sources/EditorEngine/EditorEngine.swift
   public struct EditorEngine {
       public func indexProject(workspaceRoot: String) throws -> ProjectIndex {
           let indexer = ProjectIndexer(fileSystem: LocalFileSystem())
           return try indexer.index(workspaceRoot: workspaceRoot)
       }
   }
   ```

2. Update module visibility:
   - `ProjectIndex`: `public`
   - `FileIndexEntry`: `public`
   - `ProjectIndexer`: `internal` (not exposed directly)

3. Verify trait gating:
   - EditorEngine compiles only with `--traits Editor`

**Expected Output:**
- Public API accessible from EditorEngine module
- CLI target does not import EditorEngine (verified by build)

**Acceptance Criteria:**
- ✅ `swift build` succeeds without EditorEngine
- ✅ `swift build --traits Editor` includes EditorEngine
- ✅ Public API is minimal and clean
- ✅ All existing tests still pass

---

## 3. Execution Metadata Summary

### Parallelization Opportunities

| Phase | Can Parallelize? | Notes |
|-------|-----------------|-------|
| Phase 0 (API Design) | No | Sequential (2.0.2 depends on 2.0.1) |
| Phase 1 (Core Logic) | Partial | 2.1.2 can be designed in parallel with 2.1.1 |
| Phase 2 (Ignore Rules) | No | 2.2.2 depends on 2.2.1 |
| Phase 3 (Metadata) | No | Depends on Phase 1 completion |
| Phase 4 (Testing) | No | 2.4.2 depends on 2.4.1 |

### Critical Path

```
2.0.1 → 2.0.2 → 2.1.1 → 2.2.1 → 2.2.2 → 2.3.1 → 2.4.1 → 2.4.2
```

**Estimated Duration:** 5.5 hours (includes buffer for debugging)

---

## 4. PRD Section: Features & Requirements

### 4.1 Feature Description & Rationale

**Feature:** Project-wide file indexing for EditorEngine

**Rationale:**
Editor clients (IDEs, text editors with Hyperprompt support) need to:
1. Display workspace file tree to users
2. Provide file navigation (jump to file, autocomplete)
3. Enable project-wide search and analysis
4. Compute dependency graphs (future feature)

Without indexing, editor clients would need to:
- Invoke CLI commands repeatedly (slow, inefficient)
- Implement their own file discovery (duplicates logic, error-prone)
- Lack deterministic ordering (inconsistent UX)

**Business Value:**
- Enables rich editor UX (file tree, navigation, autocomplete)
- Provides foundation for future features (incremental compilation, caching)
- Maintains consistency with CLI behavior (reuses Core types)

---

### 4.2 Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-1 | Index all `.hc` and `.md` files in workspace | P0 (Critical) |
| FR-2 | Produce deterministic, sorted file list | P0 (Critical) |
| FR-3 | Exclude hidden directories by default | P0 (Critical) |
| FR-4 | Support `.hyperpromptignore` glob patterns | P1 (High) |
| FR-5 | Collect file metadata (path, type, size) | P1 (High) |
| FR-6 | Handle permission errors gracefully | P1 (High) |
| FR-7 | Respect symlink policy (no follow by default) | P0 (Security) |
| FR-8 | Provide configurable max depth limit | P2 (Medium) |

---

### 4.3 Non-Functional Requirements

| Category | Requirement | Target |
|----------|-------------|--------|
| Performance | Index 1000 files in <500ms | 500ms |
| Determinism | Same workspace → same index (byte-for-byte) | 100% |
| Portability | Works on macOS and Linux | Both |
| Memory | Index does not cache file contents | No limit |
| Security | No path traversal outside workspace | 100% enforced |
| Testability | >90% code coverage | 90%+ |

---

### 4.4 User Interaction Flows (Conceptual)

**Editor Client → EditorEngine API:**

```
1. User opens workspace in editor
   ↓
2. Editor calls: EditorEngine.indexProject(workspaceRoot: "/path/to/workspace")
   ↓
3. EditorEngine scans workspace, applies ignore rules
   ↓
4. Returns: ProjectIndex with sorted file list
   ↓
5. Editor displays file tree UI to user
```

**Expected Flow Duration:** <500ms for typical workspace (100-1000 files)

---

### 4.5 Edge Cases & Failure Scenarios

| Case | Handling | Exit Behavior |
|------|----------|---------------|
| Workspace does not exist | Throw `IndexerError.workspaceNotFound` | Return error to caller |
| Permission denied on subdirectory | Log warning, skip directory | Continue indexing |
| Circular symlinks | Detect cycle, skip | Continue indexing |
| `.hyperpromptignore` is malformed | Log warning, ignore file | Use default rules only |
| Max depth exceeded | Throw `IndexerError.maxDepthExceeded` | Return error to caller |
| Empty workspace (no files) | Return `ProjectIndex` with 0 files | Success (valid case) |
| Very large workspace (10,000+ files) | Index normally (may be slow) | Log warning if >5000 files |

---

## 5. Quality Enforcement Rules

### 5.1 No Implicit Behavior
- All default ignore patterns are documented
- Options are explicit (no hidden flags)
- Errors are actionable (include file path in error message)

### 5.2 No Hidden Side Effects
- Indexing does not modify file system
- No global state
- Thread-safe (can be called concurrently with different workspaces)

### 5.3 Determinism
- Same workspace → same index (guaranteed)
- Lexicographic sort is platform-independent
- No timestamps in output (except metadata, which is optional)

### 5.4 Testability
- All logic testable with `MockFileSystem`
- No I/O in unit tests
- Edge cases covered by tests

---

## 6. Output Format

**Primary:** Markdown (this document)
**Alternative:** JSON PRD schema (available on request)

---

## 7. Appendix: Example .hyperpromptignore

```gitignore
# Hyperprompt Ignore File
# Syntax: glob patterns (like .gitignore)

# Build artifacts
*.log
*.tmp
build/
.build/

# Editor directories
.vscode/
.idea/

# Test fixtures
**/fixtures/
**/snapshots/

# Temporary files
tmp/
temp/
**/*.swp
```

---

## 8. Appendix: API Examples

### Example 1: Basic Indexing

```swift
import EditorEngine

let engine = EditorEngine()
let index = try engine.indexProject(workspaceRoot: "/path/to/workspace")

print("Discovered \(index.totalFiles) files:")
for file in index.files {
    print("  - \(file.path) (\(file.type), \(file.size) bytes)")
}
```

**Expected Output:**
```
Discovered 3 files:
  - docs/intro.md (markdown, 2048 bytes)
  - main.hc (hypercode, 512 bytes)
  - src/chapter1.hc (hypercode, 1024 bytes)
```

### Example 2: Custom Ignore Patterns

```swift
let options = IndexerOptions(
    customIgnorePatterns: ["*.draft.md", "tmp/"]
)
let indexer = ProjectIndexer(fileSystem: LocalFileSystem(), options: options)
let index = try indexer.index(workspaceRoot: "/workspace")
```

---

## 9. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-20 | Hyperprompt Planning System | Initial PRD for EE1 |

---

**Status:** Ready for Implementation
**Target Completion:** 3 hours
**Next Step:** Begin implementation with Task 2.0.1 (Define `ProjectIndex` Struct)

---
**Archived:** 2025-12-21
