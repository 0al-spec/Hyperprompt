# PRD: B1 — Reference Resolver

**Task ID:** B1
**Task Name:** Reference Resolver
**Priority:** [P0] Critical
**Phase:** Phase 4 (Reference Resolution)
**Effort:** 6 hours
**Dependencies:** A4 (Parser & AST Construction)
**Status:** Ready for Implementation

---

## 1. Scope and Intent

### 1.1 Objective

Implement the `ReferenceResolver` type that determines the semantic classification of each node literal in the compiled AST. A literal is either:
- **Inline text:** Raw content to be used as-is in output
- **Markdown file reference (.md):** File path resolving to a `.md` file; content embedded with heading adjustment
- **Hypercode file reference (.hc):** File path resolving to a `.hc` file; compiled recursively with AST merged into parent
- **Forbidden extension:** Any other extension → hard error (exit code 3)

The resolver must validate all references against the root directory, enforce strict/lenient modes for missing files, and maintain context for dependent modules (circular dependency detection, file loading, caching).

### 1.2 Primary Deliverables

1. **`ReferenceResolver` type** — public API for resolving node literals
   - `resolveNode(node: Node, rootPath: String, mode: ResolutionMode) -> ResolutionKind`
   - Support for strict/lenient modes
   - Clear error reporting with source location

2. **`ResolutionKind` enum** — semantic classification
   ```swift
   enum ResolutionKind {
       case inlineText                          // Not a file reference
       case markdownFile(path: String, content: String)  // .md file embedded
       case hypercodeFile(path: String, ast: Node)       // Compiled .hc subtree
       case forbidden(extension: String)        // Disallowed extension
   }
   ```

3. **Integration hooks** — for dependent modules
   - File loading interface (for B3: FileLoader)
   - Circular dependency reporting (for B2: DependencyTracker)
   - AST recursion support (for B4: Recursive Compilation)

4. **Test coverage** — >90% for ReferenceResolver module
   - File reference classification tests
   - Strict/lenient mode tests
   - Error reporting tests

### 1.3 Success Criteria

- ✅ All node literals correctly classified as inline, `.md`, `.hc`, or forbidden
- ✅ File existence validated against root directory
- ✅ Strict mode: missing files → resolution error (exit code 3)
- ✅ Lenient mode: missing files → treated as inline text
- ✅ Forbidden extensions rejected with error message
- ✅ Source location preserved in all error diagnostics
- ✅ Integration points established for B2, B3, B4
- ✅ Unit tests achieve >90% coverage

### 1.4 Constraints & Assumptions

**Constraints:**
- Must not follow symlinks outside root directory
- Must not allow path traversal (`..`)
- Must handle UTF-8 file paths
- No network access
- Must work unchanged on macOS, Linux, Windows

**Assumptions:**
- A4 (Parser) has completed: AST available with correct node structure
- Root directory is absolute, accessible, and canonical
- File system is stable during compilation (no concurrent modifications)
- All file paths are relative to root (enforced by parser)

---

## 2. Functional Requirements

### 2.1 Reference Classification

**Input:** Node literal string from AST
**Output:** `ResolutionKind` classification

**Classification logic:**

```
if literal matches file path pattern (contains '/' or '.'):
    if literal contains path traversal (contains '..'):
        return forbidden with error: "Path traversal detected"

    extract extension from literal

    if extension == '.hc':
        if file exists at (root + '/' + literal):
            return hypercodeFile(path, ast)  // AST from recursive compilation
        else:
            if strict mode:
                return error: "File not found in strict mode"
            else:  // lenient mode
                return inlineText  // Treat as literal

    else if extension == '.md':
        if file exists at (root + '/' + literal):
            return markdownFile(path, content)  // Content loaded from file
        else:
            if strict mode:
                return error: "File not found in strict mode"
            else:  // lenient mode
                return inlineText  // Treat as literal

    else:
        // Forbidden extension
        return forbidden(extension) with error: "Extension not supported: {extension}"
else:
    // No file path pattern detected
    return inlineText
```

### 2.2 File Path Detection

A literal is heuristically identified as a potential file path if:
- Contains path separator (`/`), OR
- Contains extension marker (`.`)

This heuristic is safe because:
- Pure inline text typically doesn't contain slashes or dots
- If a literal looks like a path but isn't, lenient mode treats it as inline
- Strict mode explicitly fails on missing files (catch errors early)

**Examples:**
- `"README.md"` → heuristic match, extension `.md`, classified based on existence
- `"docs/guide.hc"` → heuristic match, extension `.hc`, classified based on existence
- `"Hello World"` → no match, inline text
- `"Version 1.0"` → contains dot but no slash; heuristic match; treated as path; likely missing in strict mode
- `"Config file: settings.json"` → heuristic match, extension `.json`, forbidden extension error

### 2.3 File Existence Checking

**Method:**
- Use `FileSystem` abstraction (already defined in A2: Core Types)
- Check if file exists at `root + "/" + literal`
- Resolve path to canonical form (normalize `./`, `../` handling at filesystem level)

**Error cases:**
- Missing file + strict mode → `ResolutionError` (exit code 3)
- Missing file + lenient mode → `inlineText`
- Permission denied → `IOError` (exit code 1)
- File is directory → treat as missing file (not a reference)

### 2.4 Mode Handling

**Strict Mode (default):**
- Missing file reference → hard error
- Exit code: 3 (Resolution Error)
- Error message: `{path}: File not found in strict mode`

**Lenient Mode:**
- Missing file reference → treat as inline text
- Allows compilation to proceed
- Useful for templates/placeholders

**Validation:**
- CLI enforces: `--strict` XOR `--lenient`, not both
- Default: strict mode

### 2.5 Integration Points

**For B2: DependencyTracker (circular dependency detection)**
- Resolver must provide hooks to report file visits
- When visiting a `.hc` file, inform dependency tracker
- Tracker detects cycles before loader reads file

**For B3: FileLoader (file loading & caching)**
- Resolver identifies which files need loading
- Pass path to loader; loader handles reading, caching, hashing
- Resolver receives back: (content, sha256, size)

**For B4: Recursive Compilation (nested .hc files)**
- When a `.hc` file is classified, resolver requests recursion
- Parser invoked on `.hc` content
- Returned AST merged into parent at node's depth
- Source location tracking maintained (file origin preserved)

---

## 3. Non-Functional Requirements

### 3.1 Performance
- Single node classification: <1ms
- Full tree resolution (100 nodes): <100ms
- No N² behavior; linear with node count

### 3.2 Error Diagnostics
- Every error includes:
  - Source location (file path + line number)
  - Clear error message (what failed, why)
  - Exit code category (1, 2, 3, or 4)
  - Actionable suggestion when possible

**Example error:**
```
input.hc:5: error: File not found in strict mode
    "missing-file.hc"
    ^^^^^^^^^^^^^^^^^
Suggestion: Create the file or use --lenient mode to treat as inline text.
```

### 3.3 Code Quality
- Type-safe: use Swift enums and optionals, not stringly-typed checks
- Immutable: `ResolutionKind` values immutable after creation
- Testable: public test initializers for ResolutionKind; no hidden dependencies
- Maintainable: clear separation of concerns (classify vs. load vs. track)

---

## 4. Implementation Architecture

### 4.1 Module Structure

**Location:** `Sources/Core/ReferenceResolver.swift`

**Types:**

```swift
/// Public resolution mode enumeration
public enum ResolutionMode {
    case strict      // Missing files → error
    case lenient     // Missing files → inline text
}

/// Semantic classification of node literal
public enum ResolutionKind {
    case inlineText                          // Not a file ref
    case markdownFile(path: String, content: String)
    case hypercodeFile(path: String, ast: Node)
    case forbidden(extension: String)        // Disallowed ext
}

/// Reference resolver for node classification
public struct ReferenceResolver {
    private let fileSystem: FileSystem
    private let rootPath: String
    private let mode: ResolutionMode

    // Constructor
    public init(fileSystem: FileSystem, rootPath: String, mode: ResolutionMode)

    // Main API
    public func resolve(node: Node) -> Result<ResolutionKind, CompilerError>

    // Helper: detect file path heuristic
    private func looksLikeFilePath(_ literal: String) -> Bool

    // Helper: extract extension
    private func fileExtension(_ literal: String) -> String?

    // Helper: check for path traversal
    private func containsPathTraversal(_ path: String) -> Bool

    // Helper: file existence check (uses fileSystem)
    private func fileExists(at path: String) -> Bool

    // For circular dependency tracking (called by B2)
    public var visitedPaths: Set<String> { get }
}
```

### 4.2 Algorithm Details

**`resolve(node: Node)` algorithm:**

```swift
func resolve(node: Node) -> Result<ResolutionKind, CompilerError> {
    let literal = node.literal.trimmingCharacters(in: .whitespaces)

    // Check if looks like a file path
    guard looksLikeFilePath(literal) else {
        return .success(.inlineText)
    }

    // Check for path traversal
    if containsPathTraversal(literal) {
        let error = CompilerError.resolutionError(
            message: "Path traversal detected: \(literal)",
            location: node.location
        )
        return .failure(error)
    }

    // Get extension
    guard let ext = fileExtension(literal) else {
        return .success(.inlineText)
    }

    // Route by extension
    switch ext.lowercased() {
    case ".md":
        return resolveMarkdown(literal, node: node)
    case ".hc":
        return resolveHypercode(literal, node: node)
    default:
        let error = CompilerError.resolutionError(
            message: "Unsupported file extension: .\(ext)",
            location: node.location
        )
        return .failure(error)
    }
}

private func resolveMarkdown(_ path: String, node: Node) -> Result<ResolutionKind, CompilerError> {
    let fullPath = rootPath + "/" + path

    if fileExists(at: fullPath) {
        // Load content (via FileLoader in B3)
        // For now: placeholder, will integrate with B3
        return .success(.markdownFile(path: path, content: ""))
    } else {
        switch mode {
        case .strict:
            let error = CompilerError.resolutionError(
                message: "File not found in strict mode: \(path)",
                location: node.location
            )
            return .failure(error)
        case .lenient:
            return .success(.inlineText)
        }
    }
}

private func resolveHypercode(_ path: String, node: Node) -> Result<ResolutionKind, CompilerError> {
    let fullPath = rootPath + "/" + path

    if fileExists(at: fullPath) {
        // Recursively compile (via B4 integration)
        // For now: placeholder, will integrate with B4
        return .success(.hypercodeFile(path: path, ast: node))
    } else {
        switch mode {
        case .strict:
            let error = CompilerError.resolutionError(
                message: "File not found in strict mode: \(path)",
                location: node.location
            )
            return .failure(error)
        case .lenient:
            return .success(.inlineText)
        }
    }
}
```

### 4.3 Integration Boundaries

**B2: DependencyTracker**
- Resolver passes file path to tracker before recursing
- Tracker checks if path already visited (cycle detection)
- If cycle detected, tracker returns error to resolver

**B3: FileLoader**
- Resolver calls loader: `loadFile(path) -> Result<(content, sha256, size), CompilerError>`
- Loader handles UTF-8 decoding, hashing, caching
- Resolver receives back semantic content

**B4: Recursive Compilation**
- Resolver identifies `.hc` file
- Calls parser recursively: `parse(hypercodeContent) -> Result<Program, CompilerError>`
- Parser returns AST; resolver wraps in `.hypercodeFile`

---

## 5. Testing Strategy

### 5.1 Unit Tests

**Test file:** `Tests/CoreTests/ReferenceResolverTests.swift`

**Test categories:**

**A. Basic Classification (Inline vs. File)**
- [ ] Inline text without slashes/dots → `inlineText`
- [ ] Inline text with sentence-ending dots → `inlineText`
- [ ] Single filename with `.md` → attempts resolution
- [ ] Path with `/` and `.md` → attempts resolution
- [ ] Path with only `/` (no extension) → `inlineText` (no extension)

**B. Markdown File Resolution**
- [ ] Existing `.md` file (strict mode) → `markdownFile` (placeholder content)
- [ ] Existing `.md` file (lenient mode) → `markdownFile`
- [ ] Missing `.md` file (strict mode) → error
- [ ] Missing `.md` file (lenient mode) → `inlineText`
- [ ] `.md` file with spaces in path → correct handling

**C. Hypercode File Resolution**
- [ ] Existing `.hc` file (strict mode) → `hypercodeFile` (placeholder AST)
- [ ] Existing `.hc` file (lenient mode) → `hypercodeFile`
- [ ] Missing `.hc` file (strict mode) → error
- [ ] Missing `.hc` file (lenient mode) → `inlineText`
- [ ] Nested path like `subdir/file.hc` → correct handling

**D. Forbidden Extensions**
- [ ] `.json` extension → `forbidden` error
- [ ] `.txt` extension → `forbidden` error
- [ ] `.js` extension → `forbidden` error
- [ ] No extension but looks like file (e.g., `README`) → `inlineText`
- [ ] `.mD` (case insensitive) → `markdownFile` or error

**E. Path Traversal**
- [ ] `../../../etc/passwd` → path traversal error
- [ ] `./file.md` → allowed (same directory)
- [ ] `subdir/../file.md` → path traversal error
- [ ] `file.md` (no `/`) → not flagged as traversal

**F. Source Location Preservation**
- [ ] Error includes correct line number from node
- [ ] Error includes correct file path from node.location
- [ ] Diagnostic readable and actionable

**G. Integration Hooks (Placeholders for B2, B3, B4)**
- [ ] Resolver provides visited paths for tracker
- [ ] Resolver accepts file loader interface
- [ ] Resolver reports AST back to parent

### 5.2 Test Fixtures

**Mock FileSystem** (already defined in A2):
```swift
let mockFS = MockFileSystem()
mockFS.addFile(at: "README.md", content: "# Test")
mockFS.addFile(at: "nested/doc.md", content: "Content")
mockFS.addFile(at: "script.hc", content: "\"Inline\"")

let resolver = ReferenceResolver(fileSystem: mockFS, rootPath: "/root", mode: .strict)
```

### 5.3 Coverage Target

- **Line coverage:** >90%
- **Branch coverage:** >85% (if/else paths)
- **Missing coverage:** explicitly documented in test comments

---

## 6. TODO Breakdown

### Phase 1: Core Resolver Implementation (3 hours)

- [ ] **1.1** Define `ResolutionKind` enum with all cases
  - Time: 0.25h
  - Acceptance: Enum compiles, covers inline, markdown, hypercode, forbidden
  - Tools: Swift

- [ ] **1.2** Define `ResolutionMode` enum (strict, lenient)
  - Time: 0.25h
  - Acceptance: Enum compiles, properly used as parameter
  - Tools: Swift

- [ ] **1.3** Implement `ReferenceResolver` struct skeleton
  - Time: 0.5h
  - Acceptance: Type compiles; init accepts fileSystem, rootPath, mode
  - Tools: Swift

- [ ] **1.4** Implement `looksLikeFilePath()` heuristic
  - Time: 0.5h
  - Acceptance: Correctly identifies paths with `/` or `.`
  - Tests: 8+ test cases

- [ ] **1.5** Implement `fileExtension()` helper
  - Time: 0.5h
  - Acceptance: Extracts extension correctly; handles no extension
  - Tests: 10+ test cases (include `.`, `..`, case sensitivity)

- [ ] **1.6** Implement `containsPathTraversal()` check
  - Time: 0.5h
  - Acceptance: Detects `..` at all positions; allows `./`
  - Tests: 8+ test cases

### Phase 2: Classification Logic (2 hours)

- [ ] **2.1** Implement main `resolve()` method structure
  - Time: 0.5h
  - Acceptance: Calls helpers in correct order; returns `Result<ResolutionKind, CompilerError>`
  - Tools: Swift

- [ ] **2.2** Implement Markdown resolution path
  - Time: 0.75h
  - Acceptance: Classifies `.md` files; handles missing files per mode
  - Tests: 6+ test cases (exists/missing × strict/lenient, path variants)

- [ ] **2.3** Implement Hypercode resolution path
  - Time: 0.75h
  - Acceptance: Classifies `.hc` files; handles missing files per mode
  - Tests: 6+ test cases

- [ ] **2.4** Implement forbidden extension handling
  - Time: 0.25h
  - Acceptance: Reports clear error; includes extension in message
  - Tests: 5+ test cases

### Phase 3: Error Handling & Integration (1 hour)

- [ ] **3.1** Implement error diagnostic construction
  - Time: 0.5h
  - Acceptance: Errors include location, message, suggestion
  - Tests: 5+ test cases for error messages

- [ ] **3.2** Add integration hooks for B2, B3, B4
  - Time: 0.5h
  - Acceptance: Public methods defined for dependency tracker, file loader, recursive compilation
  - Tools: Swift (interface design)

### Phase 4: Testing (1 hour)

- [ ] **4.1** Implement 40+ unit tests covering all categories
  - Time: 0.75h
  - Acceptance: All tests pass; coverage >90%
  - Tools: XCTest

- [ ] **4.2** Verify MockFileSystem integration
  - Time: 0.25h
  - Acceptance: Tests use mock correctly; no real file I/O
  - Tools: XCTest

---

## 7. Acceptance Criteria (Detailed)

### 7.1 Functional Acceptance

- [ ] **AC-1:** Inline text literals → `ResolutionKind.inlineText`
  - Examples: `"Hello"`, `"Version 1.0"`, `"No file here"`
  - Verified by: 5+ unit tests

- [ ] **AC-2:** `.md` file paths → `ResolutionKind.markdownFile` (if exists)
  - Examples: `"README.md"`, `"docs/guide.md"`
  - Verified by: 6+ unit tests

- [ ] **AC-3:** `.hc` file paths → `ResolutionKind.hypercodeFile` (if exists)
  - Examples: `"nested.hc"`, `"templates/form.hc"`
  - Verified by: 6+ unit tests

- [ ] **AC-4:** Forbidden extensions → `ResolutionKind.forbidden`
  - Examples: `"config.json"`, `"style.css"`, `"image.png"`
  - Error message includes extension name
  - Exit code: 3 (Resolution Error)
  - Verified by: 5+ unit tests

- [ ] **AC-5:** Path traversal → resolution error
  - Examples: `"../../../etc/passwd"`, `"subdir/../../../escape.md"`
  - Error message: "Path traversal detected"
  - Exit code: 3 (Resolution Error)
  - Verified by: 4+ unit tests

- [ ] **AC-6:** Strict mode + missing file → error
  - File not created; resolver attempts classification
  - Error message: "File not found in strict mode"
  - Exit code: 3 (Resolution Error)
  - Verified by: 4+ unit tests

- [ ] **AC-7:** Lenient mode + missing file → inlineText
  - File not created; resolver attempts classification
  - Returns `ResolutionKind.inlineText` (not error)
  - Verified by: 4+ unit tests

- [ ] **AC-8:** All errors include source location
  - Node.location (file path + line number) preserved
  - Error diagnostic contains location info
  - Verified by: 5+ unit tests

- [ ] **AC-9:** Integration hooks established
  - Public methods for dependency tracker (visited paths)
  - Public methods for file loader (load interface)
  - Public methods for recursive compilation (AST return)
  - Verified by: integration test stubs (detailed tests in B2, B3, B4)

### 7.2 Quality Acceptance

- [ ] **AC-10:** Unit test coverage >90%
  - Measured by: `swift test --enable-code-coverage`
  - Report: Coverage report generated

- [ ] **AC-11:** All tests pass
  - Command: `swift test`
  - Exit code: 0

- [ ] **AC-12:** No compiler warnings
  - Command: `swift build`
  - Output: No warnings in ReferenceResolver.swift

---

## 8. Failure Modes & Recovery

### 8.1 File System Errors

**Failure:** File exists but cannot be read (permission denied)
**Recovery:** Return `IOError` (exit code 1)
**Message:** `{path}: Permission denied`

**Failure:** File system is unstable (concurrent modifications)
**Recovery:** Document assumption; accept single-pass compilation model
**Message:** Not applicable; not handled (assumed won't happen during compilation)

### 8.2 Invalid Input

**Failure:** Node.literal contains invalid UTF-8
**Recovery:** Assume parser (A4) already validated; treat as string
**Message:** Not applicable

**Failure:** Root path is not absolute or canonical
**Recovery:** Assume CLI (D1) validates and canonicalizes
**Message:** Not applicable

### 8.3 Logic Errors

**Failure:** Heuristic misclassifies a literal (e.g., "my.file.backup" treated as path)
**Recovery:** Strict mode catches in testing; lenient mode accepts as inline
**Message:** Document heuristic limitations in code comments

---

## 9. Dependencies & Blockers

### 9.1 Internal Dependencies

- **A2 (Core Types):** `CompilerError`, `SourceLocation`, `FileSystem`
  - Status: ✅ Completed
  - Interface available: Yes

- **A4 (Parser):** `Node`, `Program` structures
  - Status: ✅ Completed
  - Interface available: Yes

### 9.2 External Dependencies (for integration)

- **B2 (Dependency Tracker):** Circular dependency detection
  - Status: Pending (will implement after B1)
  - Integration point: Resolver calls tracker before recursing

- **B3 (File Loader):** File reading, caching, hashing
  - Status: Pending (will implement after B1)
  - Integration point: Resolver requests loader for content

- **B4 (Recursive Compilation):** Recursive parser invocation
  - Status: Pending (will implement after B1)
  - Integration point: Resolver calls parser on `.hc` content

### 9.3 Blockers

**None identified.** B1 can be implemented and tested in isolation using mocks for B2, B3, B4.

---

## 10. Notes & Clarifications

### 10.1 Heuristic Limitations

The file path heuristic (contains `/` or `.`) is **not foolproof**. Examples of edge cases:

- **False positive:** `"Version 1.0"` contains dot → treated as potential file path → missing in strict mode → error
  - Mitigation: Use lenient mode for templates; or place quotes around ambiguous literals
  - Recommendation: Document in user-facing error messages

- **False negative:** `"file_no_extension"` doesn't match heuristic → treated as inline text → won't load `.hc` file
  - Mitigation: This is intentional; Hypercode files should have `.hc` extension
  - Recommendation: Convention over configuration

### 10.2 Case Sensitivity

File path resolution is **case-sensitive on Linux/macOS, case-insensitive on Windows** (per file system behavior).

- Extension checking uses **case-insensitive** comparison (`.md`, `.MD`, `.Md` all accepted)
- Path checking uses **file system case semantics** (e.g., on Windows, `README.md` and `readme.md` both resolve)

### 10.3 Symlink Handling

Symlinks are **followed but not escaped** (per FileSystem abstraction).

- If symlink points outside root, `fileExists()` will return false (safe)
- Symlinks within root are dereferenced transparently
- Documented assumption in code comments

### 10.4 Future Extensions

**Not in scope for v0.1, but consider architecture:**
- **Glob patterns** (`"docs/*.md"`) → requires file enumeration
- **Selective embedding** (pick specific sections) → requires content indexing
- **Variable interpolation** (`"${path}/readme.hc"`) → requires context awareness

Current architecture supports these extensions without breaking changes.

---

## 11. Revision History

| Version | Date       | Author         | Changes                                 |
|---------|------------|----------------|-----------------------------------------|
| 1.0.0   | 2025-12-06 | Claude Code    | Initial PRD for B1 - Reference Resolver |

---

## 12. Sign-Off

**Task Lead:** Claude Code Agent
**Status:** Ready for Implementation
**Next Step:** Begin Phase 1 (Core Resolver Implementation) → Run tests → Proceed to B2



---

**Archived:** 2025-12-06
