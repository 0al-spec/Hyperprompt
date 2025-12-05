# PRD: A2 — Core Types Implementation

**Task ID:** A2
**Priority:** P0 (Critical)
**Phase:** Phase 1: Foundation & Core Types
**Estimated Effort:** 4 hours
**Dependencies:** A1 (Project Initialization) — ✅ Completed
**Status:** In Progress

---

## 1. Objective & Scope

### 1.1 Objective

Implement the foundational type system for the Hyperprompt Compiler that will be used across all modules. This includes:

1. **SourceLocation**: Precise tracking of file locations for error reporting
2. **CompilerError**: Protocol-based error handling with diagnostic information
3. **Error Categories**: Classification of error types (IO, Syntax, Resolution, Internal)
4. **FileSystem Protocol**: Abstract interface for file operations enabling testability
5. **Production & Test Implementations**: Concrete file system implementations

### 1.2 Rationale

These core types establish the foundation for:
- **Error diagnostics**: All compiler errors must report precise source locations
- **Testability**: FileSystem protocol enables dependency injection for unit tests
- **Type safety**: Strong typing prevents mixing error categories
- **Maintainability**: Centralized error handling simplifies debugging and logging

### 1.3 Success Criteria

- All core types compile without errors in Swift
- Unit tests achieve >90% code coverage
- Mock file system enables testing without touching disk
- Error messages include file path and line number
- All error categories produce appropriate diagnostic output

### 1.4 Constraints

- Must compile with Swift 5.9+
- No external dependencies (stdlib only)
- Cross-platform: macOS, Linux, Windows
- UTF-8 encoding assumed for all file paths

---

## 2. Deliverables

| # | Deliverable | Location | Acceptance Criteria |
|---|-------------|----------|---------------------|
| 1 | `SourceLocation.swift` | `Sources/Core/SourceLocation.swift` | Stores file path + line number, implements CustomStringConvertible |
| 2 | `CompilerError.swift` | `Sources/Core/CompilerError.swift` | Protocol with diagnostic info, categorization, source location |
| 3 | `ErrorCategory.swift` | `Sources/Core/ErrorCategory.swift` | Enum with IO, Syntax, Resolution, Internal cases |
| 4 | `FileSystem.swift` | `Sources/Core/FileSystem.swift` | Protocol with readFile, fileExists, canonicalizePath methods |
| 5 | `LocalFileSystem.swift` | `Sources/Core/LocalFileSystem.swift` | Production implementation using Foundation APIs |
| 6 | `MockFileSystem.swift` | `Tests/CoreTests/MockFileSystem.swift` | In-memory test implementation |
| 7 | Unit Tests | `Tests/CoreTests/` | Test coverage >90%, all error cases verified |

---

## 3. Technical Specification

### 3.1 SourceLocation

**Purpose**: Track exact source position for error reporting.

**Definition**:
```swift
/// Represents a specific location in a source file
struct SourceLocation {
    /// Absolute or relative file path
    let filePath: String

    /// Line number (1-indexed)
    let line: Int

    /// Initialize with file path and line number
    init(filePath: String, line: Int)
}
```

**Conformances**:
- `Equatable`: Enable comparison in tests
- `CustomStringConvertible`: Format as `<file>:<line>`
- `Sendable`: Enable concurrent compilation (future)

**Validation**:
- `line` must be >= 1 (line numbers are 1-indexed)
- `filePath` can be empty for synthetic locations

**Example Output**:
```
/path/to/file.hc:42
```

---

### 3.2 CompilerError Protocol

**Purpose**: Unified error handling interface for all compiler errors.

**Definition**:
```swift
/// Protocol for all compiler errors
protocol CompilerError: Error {
    /// Error category (IO, Syntax, Resolution, Internal)
    var category: ErrorCategory { get }

    /// Human-readable error message
    var message: String { get }

    /// Source location where error occurred (optional)
    var location: SourceLocation? { get }

    /// Detailed diagnostic information for debugging
    var diagnosticInfo: String { get }
}
```

**Default Implementations**:
- `diagnosticInfo`: Combine category, location, and message into formatted output

**Example Diagnostic**:
```
Error [Syntax]: /path/to/file.hc:15
Tab characters are not allowed in indentation. Use 4 spaces per level.
```

---

### 3.3 ErrorCategory Enum

**Purpose**: Classify errors by type for appropriate handling and exit codes.

**Definition**:
```swift
/// Categories of compiler errors mapped to exit codes
enum ErrorCategory: String {
    case io = "IO"               // File not found, permission denied, disk full
    case syntax = "Syntax"       // Invalid Hypercode syntax
    case resolution = "Resolution" // Circular dependency, missing reference
    case internal = "Internal"   // Unexpected condition, compiler bug
}
```

**Exit Code Mapping** (from PRD §8.1):
- IO → Exit code 1
- Syntax → Exit code 2
- Resolution → Exit code 3
- Internal → Exit code 4

**Conformances**:
- `String`: Enable CustomStringConvertible
- `Equatable`: Enable comparison
- `CaseIterable`: Enable iteration over all categories

---

### 3.4 FileSystem Protocol

**Purpose**: Abstract file I/O for testability and cross-platform support.

**Definition**:
```swift
/// Abstract interface for file system operations
protocol FileSystem {
    /// Read entire file content as UTF-8 string
    /// - Parameter path: File path (absolute or relative)
    /// - Returns: File content as String
    /// - Throws: CompilerError with category .io if file cannot be read
    func readFile(at path: String) throws -> String

    /// Check if file exists at given path
    /// - Parameter path: File path (absolute or relative)
    /// - Returns: true if file exists and is readable, false otherwise
    func fileExists(at path: String) -> Bool

    /// Convert relative path to absolute canonical path
    /// - Parameter path: File path (may be relative)
    /// - Returns: Absolute canonical path with resolved symlinks
    /// - Throws: CompilerError with category .io if path is invalid
    func canonicalizePath(_ path: String) throws -> String

    /// Get current working directory
    /// - Returns: Absolute path to current directory
    func currentDirectory() -> String
}
```

**Error Handling**:
- All errors thrown must conform to `CompilerError`
- File not found → ErrorCategory.io
- Permission denied → ErrorCategory.io
- Invalid path → ErrorCategory.io

---

### 3.5 LocalFileSystem

**Purpose**: Production implementation using Foundation APIs.

**Implementation Notes**:
- Use `FileManager.default` for all operations
- Use `String(contentsOfFile:encoding:)` with `.utf8` encoding
- Normalize line endings: CRLF/CR → LF (handled in FileLoader, not here)
- Resolve symlinks using `FileManager.fileSystemRepresentation`

**Error Mapping**:
| Foundation Error | CompilerError Category |
|-----------------|------------------------|
| `NSFileReadNoSuchFileError` | IO |
| `NSFileReadNoPermissionError` | IO |
| `NSFileReadCorruptFileError` | IO |
| All others | Internal |

**Cross-Platform Considerations**:
- Path separators: Use Foundation's path APIs (handle / and \ automatically)
- Case sensitivity: Preserve platform behavior (case-sensitive on Linux, case-insensitive on macOS/Windows)
- Symlinks: Resolve to canonical paths, reject if pointing outside root

---

### 3.6 MockFileSystem

**Purpose**: In-memory file system for unit tests.

**Implementation**:
```swift
/// In-memory file system for testing
class MockFileSystem: FileSystem {
    /// In-memory file storage: path → content
    private var files: [String: String] = [:]

    /// Simulated current directory
    private var _currentDirectory: String = "/mock"

    /// Add a file to the mock file system
    func addFile(at path: String, content: String) {
        files[path] = content
    }

    /// Remove a file from the mock file system
    func removeFile(at path: String) {
        files.removeValue(forKey: path)
    }

    /// Clear all files
    func clear() {
        files.removeAll()
    }

    // FileSystem protocol implementations...
}
```

**Test Capabilities**:
- Simulate file not found errors
- Simulate permission errors
- Test relative path resolution
- Test symlink handling (optional for v0.1)
- Verify file access patterns (for caching tests)

---

## 4. Implementation Plan

### Phase 1: Core Data Types (1 hour)

#### Task 1.1: Implement SourceLocation
- **File**: `Sources/Core/SourceLocation.swift`
- **Steps**:
  1. Define struct with `filePath: String` and `line: Int` properties
  2. Implement `init(filePath: String, line: Int)`
  3. Add validation: `line >= 1` (precondition)
  4. Conform to `Equatable`
  5. Conform to `CustomStringConvertible` with format `<file>:<line>`
  6. Add `Sendable` conformance for future concurrency support
- **Acceptance**:
  - Compiles without warnings
  - Description format matches `file.hc:42`
  - Handles empty filePath gracefully

#### Task 1.2: Implement ErrorCategory
- **File**: `Sources/Core/ErrorCategory.swift`
- **Steps**:
  1. Define enum with cases: `io`, `syntax`, `resolution`, `internal`
  2. Set raw values: "IO", "Syntax", "Resolution", "Internal"
  3. Add computed property `exitCode: Int32` mapping categories to codes
  4. Conform to `CaseIterable` for testing
- **Acceptance**:
  - All four categories defined
  - Exit codes match PRD §8.1
  - String representation matches raw value

#### Task 1.3: Implement CompilerError Protocol
- **File**: `Sources/Core/CompilerError.swift`
- **Steps**:
  1. Define protocol inheriting from `Error`
  2. Add required properties: `category`, `message`, `location`, `diagnosticInfo`
  3. Provide default implementation for `diagnosticInfo`:
     - Format: `Error [<Category>]: <location>\n<message>`
     - If no location: `Error [<Category>]: <message>`
  4. Add convenience computed property: `exitCode` (from category)
- **Acceptance**:
  - Protocol compiles
  - Default diagnosticInfo includes all components
  - Location is optional (nil allowed)

---

### Phase 2: FileSystem Abstraction (1 hour)

#### Task 2.1: Define FileSystem Protocol
- **File**: `Sources/Core/FileSystem.swift`
- **Steps**:
  1. Define protocol with four methods: `readFile`, `fileExists`, `canonicalizePath`, `currentDirectory`
  2. Document each method with triple-slash comments
  3. Specify error types in documentation
  4. Define throws clauses for methods that can fail
- **Acceptance**:
  - Protocol compiles
  - All methods documented
  - Return types and throws clauses correct

#### Task 2.2: Implement LocalFileSystem
- **File**: `Sources/Core/LocalFileSystem.swift`
- **Steps**:
  1. Create struct conforming to `FileSystem`
  2. Implement `readFile(at:)`:
     - Use `String(contentsOfFile:encoding:)` with UTF-8
     - Wrap Foundation errors in CompilerError
     - Map NSError codes to ErrorCategory.io
  3. Implement `fileExists(at:)`:
     - Use `FileManager.default.fileExists(atPath:)`
     - Return boolean, no throws
  4. Implement `canonicalizePath(_:)`:
     - Use `URL(fileURLWithPath:).standardized.path`
     - Resolve symlinks
     - Return absolute path
  5. Implement `currentDirectory()`:
     - Use `FileManager.default.currentDirectoryPath`
  6. Add internal helper: `mapFoundationError(_ error: Error) -> CompilerError`
- **Acceptance**:
  - All methods compile
  - Foundation errors mapped to IO category
  - Paths normalized (symlinks resolved)
  - Works on macOS, Linux, Windows

---

### Phase 3: Test Infrastructure (1.5 hours)

#### Task 3.1: Implement MockFileSystem
- **File**: `Tests/CoreTests/MockFileSystem.swift`
- **Steps**:
  1. Create class conforming to `FileSystem`
  2. Add internal storage: `files: [String: String]`
  3. Add internal state: `_currentDirectory: String`
  4. Implement `addFile(at:content:)` for test setup
  5. Implement `removeFile(at:)` for test cleanup
  6. Implement `clear()` to reset state
  7. Implement `readFile(at:)`:
     - Check if file exists in `files` dict
     - Throw IO error if not found
  8. Implement `fileExists(at:)`:
     - Return `files.keys.contains(path)`
  9. Implement `canonicalizePath(_:)`:
     - Simple mock: prepend current directory if relative
  10. Implement `currentDirectory()`:
     - Return `_currentDirectory`
  11. Add method to simulate errors: `simulateError(for:category:message:)`
- **Acceptance**:
  - Fully implements FileSystem protocol
  - Supports adding/removing files
  - Can simulate file not found errors
  - No actual disk I/O performed

#### Task 3.2: Write SourceLocation Tests
- **File**: `Tests/CoreTests/SourceLocationTests.swift`
- **Test Cases**:
  1. `testInitialization`: Create with valid path and line
  2. `testEquality`: Two locations with same values are equal
  3. `testDescription`: Format matches `<file>:<line>`
  4. `testEmptyFilePath`: Handles empty string gracefully
  5. `testMinimumLineNumber`: Line 1 is valid
  6. `testLargeLineNumber`: Line 1000000 is valid
- **Coverage Target**: 100%

#### Task 3.3: Write ErrorCategory Tests
- **File**: `Tests/CoreTests/ErrorCategoryTests.swift`
- **Test Cases**:
  1. `testAllCases`: Verify all four categories exist
  2. `testRawValues`: Verify string representations
  3. `testExitCodes`: Verify mapping (IO→1, Syntax→2, Resolution→3, Internal→4)
  4. `testCaseIterable`: Iterate over all cases
- **Coverage Target**: 100%

#### Task 3.4: Write CompilerError Tests
- **File**: `Tests/CoreTests/CompilerErrorTests.swift`
- **Test Cases**:
  1. `testErrorWithLocation`: Create error with location, verify diagnosticInfo
  2. `testErrorWithoutLocation`: Create error without location, verify diagnosticInfo
  3. `testDiagnosticFormat`: Verify format matches specification
  4. `testExitCodeDelegation`: Verify exitCode comes from category
  5. Create concrete error type for testing:
     ```swift
     struct TestError: CompilerError {
         let category: ErrorCategory
         let message: String
         let location: SourceLocation?
     }
     ```
- **Coverage Target**: >90%

#### Task 3.5: Write FileSystem Tests
- **File**: `Tests/CoreTests/FileSystemTests.swift`
- **Test Cases**:
  1. `testMockFileSystemReadSuccess`: Add file, read it back
  2. `testMockFileSystemReadFailure`: Try to read non-existent file
  3. `testMockFileSystemFileExists`: Check existence of added file
  4. `testMockFileSystemFileNotExists`: Check non-existent file
  5. `testMockFileSystemCanonicalizePath`: Test absolute/relative path handling
  6. `testMockFileSystemCurrentDirectory`: Verify default directory
  7. `testMockFileSystemClear`: Add files, clear, verify empty
  8. Integration test with LocalFileSystem (optional, requires temp directory):
     - Create temp file
     - Read with LocalFileSystem
     - Verify content matches
     - Clean up temp file
- **Coverage Target**: >90%

---

### Phase 4: Integration & Documentation (0.5 hours)

#### Task 4.1: Integration Verification
- **Steps**:
  1. Run `swift build` and verify no errors
  2. Run `swift test` and verify all tests pass
  3. Check test coverage: `swift test --enable-code-coverage`
  4. Verify coverage >90% for Core module
  5. Review compiler warnings, fix if any

#### Task 4.2: Documentation
- **Steps**:
  1. Add module-level documentation to `Sources/Core/Core.swift`:
     ```swift
     /// Core module providing foundational types for the Hyperprompt Compiler.
     ///
     /// This module defines:
     /// - SourceLocation: Track source file positions
     /// - CompilerError: Protocol for all compiler errors
     /// - ErrorCategory: Classification of error types
     /// - FileSystem: Abstract file I/O interface
     /// - LocalFileSystem: Production file system implementation
     ```
  2. Verify all public APIs have triple-slash documentation
  3. Generate documentation: `swift package generate-documentation` (if docc available)

#### Task 4.3: Verify Cross-Platform Compilation
- **Platforms**:
  - macOS: `swift build`
  - Linux (Docker): `docker run --rm -v $(pwd):/workspace swift:5.9 bash -c "cd /workspace && swift build"`
  - Windows (optional): Build in Visual Studio or via Swift for Windows toolchain
- **Acceptance**:
  - All platforms compile successfully
  - All tests pass on all platforms
  - No platform-specific warnings

---

## 5. Acceptance Criteria Checklist

### Functional Requirements
- [ ] `SourceLocation` stores file path and line number
- [ ] `SourceLocation` formats as `<file>:<line>`
- [ ] `ErrorCategory` enum has all four categories
- [ ] `ErrorCategory` maps to correct exit codes (1, 2, 3, 4)
- [ ] `CompilerError` protocol includes category, message, location
- [ ] `CompilerError` provides formatted diagnostic output
- [ ] `FileSystem` protocol defines readFile, fileExists, canonicalizePath, currentDirectory
- [ ] `LocalFileSystem` reads UTF-8 files using Foundation
- [ ] `LocalFileSystem` maps Foundation errors to IO category
- [ ] `LocalFileSystem` resolves symlinks in canonicalizePath
- [ ] `MockFileSystem` implements all FileSystem methods
- [ ] `MockFileSystem` uses in-memory storage (no disk I/O)

### Quality Requirements
- [ ] All files compile without errors or warnings
- [ ] Unit tests achieve >90% code coverage
- [ ] All test cases pass
- [ ] Public APIs have documentation comments
- [ ] Code follows Swift naming conventions
- [ ] No force-unwraps (`!`) in production code
- [ ] Error messages are clear and actionable

### Cross-Platform Requirements
- [ ] Compiles on macOS with Swift 5.9+
- [ ] Compiles on Linux with Swift 5.9+
- [ ] All tests pass on macOS
- [ ] All tests pass on Linux
- [ ] (Optional) Compiles on Windows

### Integration Requirements
- [ ] Core types accessible from other modules
- [ ] FileSystem protocol enables dependency injection
- [ ] MockFileSystem usable in other module tests
- [ ] No circular dependencies between modules

---

## 6. Testing Strategy

### Unit Test Coverage

| Component | Test File | Target Coverage |
|-----------|-----------|-----------------|
| SourceLocation | SourceLocationTests.swift | 100% |
| ErrorCategory | ErrorCategoryTests.swift | 100% |
| CompilerError | CompilerErrorTests.swift | >90% |
| FileSystem (Mock) | FileSystemTests.swift | >90% |
| LocalFileSystem | LocalFileSystemTests.swift | >85% |

### Test Data

**Valid Inputs**:
- File path: `"test.hc"`, line: `42`
- File path: `"/absolute/path/file.hc"`, line: `1`
- File path: `""` (empty, synthetic location), line: `1`

**Invalid Inputs** (should be handled gracefully):
- Non-existent file path (LocalFileSystem should throw)
- Unreadable file (permission denied)
- Invalid UTF-8 content (should be caught by Foundation)

**Edge Cases**:
- Line number 1 (minimum)
- Line number 1000000 (large but valid)
- Very long file paths (platform limits)

---

## 7. Dependencies & Risks

### Dependencies
- **Upstream**: A1 (Project Initialization) ✅ Completed
- **Downstream**: All other phases depend on A2 completing

### Technical Risks
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Foundation API differences across platforms | Medium | High | Test on all target platforms early |
| UTF-8 decoding errors | Low | Medium | Use Foundation's error handling, map to IO errors |
| Symlink resolution edge cases | Low | Low | Use Foundation's standardized URL, document limitations |
| Test coverage below 90% | Low | Medium | Write tests first (TDD approach) |

### Mitigation Strategy
1. **Platform Testing**: Run CI on macOS + Linux from day 1
2. **Early Integration**: Use types in next task (A3) immediately to catch issues
3. **Mock Early**: MockFileSystem enables testing without platform dependencies

---

## 8. Exit Criteria

This task is complete when:
1. All code compiles without warnings on macOS and Linux
2. All unit tests pass
3. Test coverage >90% for Core module
4. All acceptance criteria checked off
5. Code reviewed (self-review against PRD and Design Spec)
6. Changes committed to git with descriptive message
7. Ready for A3 (Domain Types) to begin using these types

---

## 9. References

- **PRD**: `DOCS/PRD/v0.0.1/00_PRD_001.md` — §8 (Error Handling & Exit Codes)
- **Design Spec**: `DOCS/PRD/v0.0.1/01_DESIGN_SPEC_001.md` — §2.1, §3 (Module Organization, Data Structures)
- **Workplan**: `DOCS/Workplan.md` — Phase 1, Task A2
- **Swift API Guidelines**: https://swift.org/documentation/api-design-guidelines/
- **Foundation Documentation**: FileManager, String, URL APIs

---

## 10. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-04 | Claude (PLAN Command) | Initial PRD generated from Workplan task A2 |

---

**Archived:** 2025-12-05
