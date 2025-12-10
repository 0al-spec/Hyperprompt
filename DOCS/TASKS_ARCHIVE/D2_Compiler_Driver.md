# Task D2 — Compiler Driver

**Task ID:** D2
**Task Name:** Compiler Driver
**Priority:** P0 (Critical)
**Phase:** Phase 6 — CLI & Integration
**Estimated Effort:** 6 hours
**Dependencies:** C2 (Markdown Emitter ✅), C3 (Manifest Generator ✅), D1 (Argument Parsing ✅)
**Status:** Selected for Implementation

---

## 1. Objective

Implement the `CompilerDriver` orchestrator that integrates all compilation pipeline components (parser, resolver, emitter, manifest generator) into a cohesive end-to-end compilation system. The driver serves as the central coordination layer, managing the complete workflow from source file input to compiled output and manifest generation.

**Primary Deliverable:** A production-ready `CompilerDriver` class that:
- Orchestrates the parse → resolve → emit → manifest pipeline
- Handles all compilation modes (normal, dry-run, verbose)
- Provides comprehensive error handling and diagnostics
- Supports end-to-end testing with the complete test corpus

---

## 2. Scope and Intent

### 2.1 In Scope

**Core Orchestration:**
- Integration of Parser, Resolver, Emitter, and ManifestGenerator modules
- Sequential pipeline execution with proper error propagation
- State management across compilation phases
- Resource cleanup and lifecycle management

**Compilation Modes:**
- **Normal mode:** Full compilation with file output
- **Dry-run mode:** Validation without writing files (--dry-run)
- **Verbose mode:** Detailed logging of each pipeline stage (-v, --verbose)
- **Statistics mode:** Metric collection and reporting (--stats)

**Path Management:**
- Default value computation for output/manifest/root paths
- Path validation and canonicalization
- Root directory resolution based on input file location

**Error Handling:**
- Comprehensive error propagation from all pipeline stages
- Contextualized error messages with source location tracking
- Graceful degradation on non-fatal errors
- Exit code mapping per PRD §11 (0-4)

**Testing Integration:**
- End-to-end compilation tests with all 24 test corpus files
- Golden file comparison for valid inputs (V01-V14)
- Error validation for invalid inputs (I01-I10)
- Performance benchmarking infrastructure

### 2.2 Out of Scope

**Deferred to Future Versions:**
- Incremental compilation and caching (v0.2+)
- Watch mode for automatic recompilation (v0.5+)
- Manifest verification mode (v0.4+)
- Parallel compilation of independent subtrees (optimization phase)

**Explicitly Not Included:**
- Interactive mode or REPL
- Network-based compilation
- Plugin system for custom pipeline stages
- GUI or web-based interface

### 2.3 Assumptions

- All dependencies (C2, C3, D1) are fully implemented and tested
- `CompilerArguments` struct from D1 provides validated input
- FileSystem abstraction is available for I/O operations
- All modules expose clear, documented APIs for integration

### 2.4 Constraints

**Technical Constraints:**
- Must work on macOS, Linux, and Windows (cross-platform)
- Must produce deterministic output (byte-for-byte identical across platforms)
- Must not access the network or external resources
- Must complete compilation in linear time relative to input size

**Operational Constraints:**
- Single-threaded execution for v0.1 (simplicity over parallelism)
- No global mutable state (thread-safe design for future parallelization)
- Maximum memory usage proportional to input size (no unbounded caching)

---

## 3. Functional Requirements

### 3.1 Pipeline Orchestration

#### FR-1: Sequential Pipeline Execution

**Requirement:** The driver shall execute the compilation pipeline in strict sequential order:

```
Input File → Parse → Resolve → Emit → Manifest → Output
     ↓          ↓        ↓        ↓         ↓         ↓
   Validate   AST   Resolved  Markdown   JSON    Write
              Tree    Tree    String    String   Files
```

**Detailed Steps:**

1. **Pre-validation Phase:**
   - Validate input file exists and is readable
   - Canonicalize all paths (input, root, output, manifest)
   - Check root directory constraints (within bounds, no symlink escapes)
   - Create output directories if needed (unless dry-run mode)

2. **Parse Phase:**
   - Invoke `Parser.parse(inputPath)` to construct AST
   - Propagate syntax errors with file/line context
   - Validate single root node constraint
   - Track source locations for error reporting

3. **Resolve Phase:**
   - Invoke `ReferenceResolver.resolve(ast, rootPath, strict)` to resolve all references
   - Recursively compile nested `.hc` files
   - Load and cache `.md` file contents
   - Detect circular dependencies
   - Validate path security (traversal, extensions)
   - Collect manifest entries during file loading

4. **Emit Phase:**
   - Invoke `MarkdownEmitter.emit(resolvedAst)` to generate output
   - Apply heading adjustment to embedded content
   - Insert section separators
   - Ensure final output ends with exactly one LF

5. **Manifest Phase:**
   - Invoke `ManifestGenerator.generate(entries, metadata)` to create JSON
   - Include timestamp (ISO 8601), version, root path
   - Sort sources alphabetically by path
   - Ensure deterministic JSON key ordering

6. **Output Phase:**
   - Write compiled Markdown to output path (unless dry-run)
   - Write manifest JSON to manifest path (unless dry-run)
   - Ensure atomic writes (temp file + rename)
   - Verify file integrity after write

**Error Propagation:** Any error at any stage shall immediately halt the pipeline and return a descriptive error to the caller.

**Acceptance Criteria:**
- ✅ Pipeline executes all phases in order
- ✅ Errors propagate with correct exit codes
- ✅ Output files written only on success (or skipped in dry-run mode)
- ✅ All intermediate state cleaned up on error

---

#### FR-2: Dry-Run Mode

**Requirement:** When invoked with `--dry-run` flag, the driver shall execute the full pipeline without writing output files.

**Behavior:**
- Parse, resolve, and emit phases execute normally
- Markdown and manifest content are generated in memory
- No file writes occur (output and manifest paths validated but not written)
- Exit code reflects validation result (0 = success, 1-4 = errors)
- Verbose mode output shows "DRY RUN" indicator

**Use Cases:**
- Pre-flight validation before committing to compilation
- CI/CD pipeline checks for syntax/reference errors
- Testing compilation logic without side effects

**Acceptance Criteria:**
- ✅ Full pipeline validation without file I/O
- ✅ Exit code matches what non-dry-run would produce
- ✅ No files created or modified
- ✅ Verbose mode clearly indicates dry-run status

---

#### FR-3: Verbose Logging

**Requirement:** When invoked with `-v` or `--verbose` flag, the driver shall output detailed progress information to stderr.

**Logging Levels:**

**Phase Start/End:**
```
[PARSE] Starting: main.hc
[PARSE] Completed: 42 nodes, 3 levels deep
[RESOLVE] Starting: resolving references...
[RESOLVE] Completed: 8 files loaded (3 .hc, 5 .md)
[EMIT] Starting: generating Markdown...
[EMIT] Completed: 12,345 bytes written
[MANIFEST] Starting: collecting metadata...
[MANIFEST] Completed: 8 sources, 15,678 total bytes
```

**File Operations:**
```
[LOAD] intro.md (2,048 bytes, SHA256: abc123...)
[COMPILE] chapters/ch1.hc → depth 2
[EMBED] content.md → adjusted headings +2
```

**Validation Checks:**
```
[CHECK] Path validation: allowed extension (.md)
[CHECK] Circular dependency: none
[CHECK] Depth limit: 7/10 (OK)
```

**Dry-Run Indicator:**
```
[DRY RUN] Output would be written to: main.compiled.md (12,345 bytes)
[DRY RUN] Manifest would be written to: main.manifest.json (456 bytes)
```

**Format:** All log lines prefixed with `[TAG]` for easy filtering, written to stderr (not stdout).

**Acceptance Criteria:**
- ✅ Each pipeline phase logged with start/end markers
- ✅ File operations logged with paths and sizes
- ✅ Validation checks logged with results
- ✅ Dry-run mode clearly indicated
- ✅ All output goes to stderr (stdout remains clean)

---

### 3.2 Path Management

#### FR-4: Default Path Computation

**Requirement:** The driver shall compute sensible default values for output, manifest, and root paths when not explicitly provided.

**Default Rules:**

| Argument | Provided | Default Behavior |
|----------|----------|------------------|
| `--output` | ❌ No | Replace input extension: `file.hc` → `file.md` |
| `--manifest` | ❌ No | Append to output: `file.md` → `file.md.manifest.json` |
| `--root` | ❌ No | Parent directory of input file: `path/to/file.hc` → `path/to/` |

**Examples:**

```bash
# Input: project/main.hc
# Defaults:
#   output:   project/main.md
#   manifest: project/main.md.manifest.json
#   root:     project/
```

```bash
# Input: /absolute/path/doc.hc
# Defaults:
#   output:   /absolute/path/doc.md
#   manifest: /absolute/path/doc.md.manifest.json
#   root:     /absolute/path/
```

**Edge Cases:**
- Input has no extension: append `.md` (e.g., `README` → `README.md`)
- Input is in current directory: root defaults to `./`
- Relative paths: resolve to absolute before processing

**Acceptance Criteria:**
- ✅ Defaults computed correctly for all input path formats
- ✅ Explicit arguments override defaults
- ✅ Paths validated and canonicalized before use
- ✅ Edge cases handled gracefully

---

#### FR-5: Path Validation and Security

**Requirement:** The driver shall validate all paths before processing to prevent security vulnerabilities.

**Validation Checks:**

1. **Input File:**
   - Must exist and be readable
   - Must have `.hc` extension (hard requirement)
   - Must be a regular file (not directory, symlink, or special file)

2. **Root Directory:**
   - Must exist and be a directory
   - Must be readable and executable (for traversal)
   - Must not be a symlink to location outside allowed boundaries

3. **Output Paths:**
   - Parent directories must exist (or be creatable)
   - Must be writable (or dry-run mode)
   - Must not overwrite input file (sanity check)

4. **Security Constraints:**
   - No path traversal (`..`) that escapes root
   - No symlink following outside root
   - No access to system directories (`/etc`, `/sys`, etc.)

**Error Handling:**
- Path validation errors → Exit code 1 (IO Error)
- Security violations → Exit code 3 (Resolution Error)
- Permission denied → Exit code 1 (IO Error)

**Acceptance Criteria:**
- ✅ All paths validated before use
- ✅ Security constraints enforced
- ✅ Clear error messages for validation failures
- ✅ Correct exit codes for different failure types

---

### 3.3 Error Handling and Diagnostics

#### FR-6: Comprehensive Error Propagation

**Requirement:** The driver shall catch errors from all pipeline stages and map them to appropriate exit codes per PRD §11.

**Exit Code Mapping:**

| Exit Code | Category | Error Sources | Example |
|-----------|----------|---------------|---------|
| 0 | Success | N/A | Compilation completed without errors |
| 1 | IO Error | File not found, permission denied, disk full | `FileNotFoundError`, `PermissionDeniedError` |
| 2 | Syntax Error | Parser failures | `TabInIndentation`, `UnclosedQuote`, `MultipleRoots` |
| 3 | Resolution Error | Resolver failures | `CircularDependency`, `ForbiddenExtension`, `DepthExceeded` |
| 4 | Internal Error | Unexpected panics, assertions | `AssertionFailure`, `UnexpectedNil`, `InternalInconsistency` |

**Error Context Enrichment:**

All errors shall include:
- Source location (file path + line number) when applicable
- Clear description of the problem
- Suggested remediation when possible
- Full error chain (original error → wrapped context)

**Error Format (stderr):**
```
<file>:<line>: error: <message>
    <context line from source>
    <caret indicator: ^^^>
```

**Example:**
```
main.hc:5: error: circular dependency detected
    "chapters/ch1.hc"
    ^^^^^^^^^^^^^^^^^
    Dependency cycle: main.hc → chapters/ch1.hc → main.hc
```

**Acceptance Criteria:**
- ✅ All pipeline errors caught and categorized
- ✅ Exit codes match PRD specification
- ✅ Error messages include source location when available
- ✅ Error output formatted for human readability

---

#### FR-7: Graceful Signal Handling (Priority: P2)

**Requirement:** The driver should handle interruption signals (SIGINT, SIGTERM) gracefully by cleaning up temporary resources before exiting.

**Behavior:**
- On SIGINT (Ctrl+C): print "Interrupted by user" and exit cleanly
- On SIGTERM: print "Terminated" and exit cleanly
- Clean up any temporary files created during compilation
- Flush buffered I/O before exit
- Exit with code 130 (128 + SIGINT)

**Implementation Note:** This is a P2 (Medium priority) feature and may be deferred if time constraints arise.

**Acceptance Criteria:**
- ✅ SIGINT/SIGTERM handled without corrupting output
- ✅ Temporary files cleaned up
- ✅ Exit code 130 for interruption

---

### 3.4 Statistics Collection

#### FR-8: Compilation Metrics (when `--stats` enabled)

**Requirement:** When invoked with `--stats` flag, the driver shall collect and report compilation metrics.

**Metrics Collected:**

| Metric | Description | Source |
|--------|-------------|--------|
| `numHypercodeFiles` | Count of `.hc` files processed | Resolver |
| `numMarkdownFiles` | Count of `.md` files embedded | Resolver |
| `totalInputBytes` | Sum of all source file sizes | FileLoader |
| `outputBytes` | Size of compiled Markdown output | Emitter |
| `maxDepth` | Deepest nesting level encountered | Parser |
| `durationMs` | Total compilation time (milliseconds) | Driver |

**Derived Metrics:**
- Compression ratio: `outputBytes / totalInputBytes`
- Processing rate: `totalInputBytes / durationMs` (bytes/ms)

**Output Format (stderr):**
```
Compilation Statistics:
  Source files:     18 (12 Hypercode, 6 Markdown)
  Input size:       125 KB
  Output size:      42 KB
  Compression:      33.6%
  Max depth:        7/10
  Duration:         342 ms
  Processing rate:  365 KB/s
```

**Acceptance Criteria:**
- ✅ All specified metrics collected
- ✅ Statistics printed to stderr (not stdout)
- ✅ Format is human-readable and parseable
- ✅ Derived metrics computed correctly

---

## 4. Non-Functional Requirements

### 4.1 Performance

**NFR-1: Linear Scaling**
The driver shall complete compilation in time proportional to the total input size, with no exponential blowup.

**Target:** 1000-node tree with average 4 KB nodes → under 5 seconds on development hardware.

**NFR-2: Memory Efficiency**
Peak memory usage shall not exceed 10× the input file size (e.g., 10 MB input → max 100 MB memory).

**NFR-3: Deterministic Output**
Repeated compilations of identical inputs shall produce byte-for-byte identical outputs (same Markdown, same manifest JSON).

**Verification:**
- Compile the same input 10 times
- SHA256 hash all outputs
- All hashes must be identical

---

### 4.2 Reliability

**NFR-4: Error Recovery**
The driver shall not crash on invalid input. All errors must be caught and reported with appropriate exit codes.

**NFR-5: Resource Cleanup**
On both success and failure, the driver shall release all resources (file handles, memory buffers, temporary files).

**NFR-6: Atomic Writes**
Output files shall be written atomically (write to temp file, then rename) to prevent partial writes on failure.

---

### 4.3 Portability

**NFR-7: Cross-Platform Compatibility**
The driver shall produce identical output on macOS, Linux, and Windows for the same input.

**Platform-Specific Considerations:**
- Line endings: Always normalize to LF (Unix-style)
- Path separators: Use `/` internally, convert on I/O
- File permissions: Handle platform differences gracefully

---

### 4.4 Testability

**NFR-8: Test Corpus Coverage**
The driver shall be tested against all 24 test corpus files:
- **Valid inputs (V01-V14):** Compilation succeeds, output matches golden files
- **Invalid inputs (I01-I10):** Compilation fails with expected error and exit code

**NFR-9: Mocking and Isolation**
The driver shall use dependency injection for all I/O operations, enabling unit tests without file system access.

---

## 5. Detailed Task Breakdown

### 5.1 Phase 1: Core Driver Implementation (4 hours)

**Priority:** P0 (Critical)

#### Subtask D2.1: CompilerDriver Skeleton

**Estimated:** 1 hour

**Implementation:**
- [ ] Define `CompilerDriver` class with dependency injection
- [ ] Inject `FileSystem`, `Parser`, `ReferenceResolver`, `MarkdownEmitter`, `ManifestGenerator`
- [ ] Define `compile(inputPath:outputPath:manifestPath:rootPath:)` method signature
- [ ] Implement constructor with all dependencies
- [ ] Set up error handling infrastructure (Result types, error wrapping)

**Expected Output:** Compilable skeleton with method stubs.

**Verification:** `swift build` succeeds, unit test instantiates driver.

---

#### Subtask D2.2: Pipeline Orchestration

**Estimated:** 2 hours

**Implementation:**
- [ ] Implement path validation (input, root, output, manifest)
- [ ] Implement default path computation (output from input, manifest from output, root from input parent)
- [ ] Implement parse phase: invoke `Parser.parse(inputPath)`
- [ ] Implement resolve phase: invoke `ReferenceResolver.resolve(ast, rootPath, strict)`
- [ ] Implement emit phase: invoke `MarkdownEmitter.emit(resolvedAst)`
- [ ] Implement manifest phase: invoke `ManifestGenerator.generate(entries, metadata)`
- [ ] Implement error propagation with exit code mapping

**Expected Output:** Working end-to-end pipeline (no dry-run, verbose, or stats yet).

**Verification:** Successfully compiles a simple valid `.hc` file to `.md` and `.manifest.json`.

---

#### Subtask D2.3: Dry-Run Mode

**Estimated:** 0.5 hours

**Implementation:**
- [ ] Add `dryRun: Bool` parameter to `compile()` method
- [ ] Skip file write operations when `dryRun == true`
- [ ] Generate Markdown and manifest in memory
- [ ] Return success/failure without writing files
- [ ] Add dry-run indicator to verbose logging

**Expected Output:** Dry-run mode validates without creating files.

**Verification:** Test that `--dry-run` produces correct exit code but writes no files.

---

#### Subtask D2.4: Verbose Logging

**Estimated:** 0.5 hours

**Implementation:**
- [ ] Add `verbose: Bool` parameter to `compile()` method
- [ ] Implement logging helper that writes to stderr when verbose
- [ ] Add phase start/end log lines (PARSE, RESOLVE, EMIT, MANIFEST)
- [ ] Add file operation log lines (LOAD, COMPILE, EMBED)
- [ ] Add validation check log lines (CHECK)
- [ ] Add dry-run indicators to log output

**Expected Output:** Verbose mode outputs detailed progress to stderr.

**Verification:** Test that `-v` produces expected log format.

---

### 5.2 Phase 2: Testing and Validation (2 hours)

**Priority:** P1 (High)

#### Subtask D2.5: End-to-End Valid Input Tests

**Estimated:** 1 hour

**Implementation:**
- [ ] Implement test harness for golden file comparison
- [ ] Write test case for V01 (single root node)
- [ ] Write test case for V04 (single Markdown file reference)
- [ ] Write test case for V06 (single Hypercode file reference)
- [ ] Write test case for V07 (nested Hypercode files)
- [ ] Write test case for V08 (mixed inline and references)
- [ ] Write test case for V13 (maximum depth 10)
- [ ] Verify all test cases produce output matching golden files

**Expected Output:** 7+ passing integration tests for valid inputs.

**Verification:** `swift test --filter ValidInputTests` → all pass.

---

#### Subtask D2.6: End-to-End Invalid Input Tests

**Estimated:** 1 hour

**Implementation:**
- [ ] Write test case for I01 (tab indentation → exit 2)
- [ ] Write test case for I02 (misaligned indent → exit 2)
- [ ] Write test case for I03 (unclosed quote → exit 2)
- [ ] Write test case for I04 (missing file strict mode → exit 3)
- [ ] Write test case for I05 (direct circular dependency → exit 3)
- [ ] Write test case for I06 (indirect circular dependency → exit 3)
- [ ] Write test case for I07 (depth exceeded → exit 3)
- [ ] Write test case for I08 (path traversal → exit 3)
- [ ] Write test case for I10 (multiple roots → exit 2)
- [ ] Verify all test cases produce expected error and exit code

**Expected Output:** 9+ passing integration tests for invalid inputs.

**Verification:** `swift test --filter InvalidInputTests` → all pass.

---

## 6. Acceptance Criteria Summary

**Must-Have (P0):**
- ✅ Driver orchestrates full parse → resolve → emit → manifest pipeline
- ✅ All pipeline stages integrated and error propagation works
- ✅ Dry-run mode validates without writing files
- ✅ Verbose mode outputs detailed progress to stderr
- ✅ Default paths computed correctly
- ✅ All valid test inputs (V01-V14) compile successfully and match golden files
- ✅ All invalid test inputs (I01-I10) fail with correct error and exit code
- ✅ Exit codes match PRD specification (0-4)

**Should-Have (P1):**
- ✅ Statistics mode collects and reports metrics
- ✅ Atomic file writes (temp + rename)
- ✅ Resource cleanup on both success and failure
- ✅ Comprehensive error messages with source location

**Nice-to-Have (P2):**
- ⚠️ Graceful signal handling (SIGINT/SIGTERM)
- ⚠️ Performance benchmarks for 1000-node trees

---

## 7. Testing Strategy

### 7.1 Unit Tests

**Scope:** Test individual driver methods in isolation.

| Test | Validates | Mocking |
|------|-----------|---------|
| `testDefaultPathComputation` | Output/manifest/root defaults | None |
| `testPathValidation` | Input/root/output validation | MockFileSystem |
| `testErrorCodeMapping` | Exit code for each error type | Mock dependencies |
| `testDryRunMode` | No files written, correct exit code | MockFileSystem |
| `testVerboseLogging` | Stderr output format | Capture stderr |

**Estimated:** 15 unit tests, ~1 hour to implement.

---

### 7.2 Integration Tests

**Scope:** Test full pipeline with real Parser, Resolver, Emitter.

**Valid Input Tests (V01-V14):**
- Compile each test case
- Compare output `.md` to expected golden file (byte-for-byte)
- Compare manifest `.json` to expected golden file (sorted keys)
- Verify exit code 0

**Invalid Input Tests (I01-I10):**
- Compile each test case
- Verify compilation fails with expected error message pattern
- Verify exit code matches expected category (1-4)

**Estimated:** 24 integration tests, ~2 hours to implement.

---

### 7.3 End-to-End Tests

**Scope:** Test CLI invocation via `Hyperprompt.main()`.

| Test | Command | Expected Behavior |
|------|---------|-------------------|
| `testNormalMode` | `hyperprompt main.hc` | Output written, exit 0 |
| `testDryRun` | `hyperprompt main.hc --dry-run` | No output, exit 0 |
| `testVerbose` | `hyperprompt main.hc -v` | Stderr output, exit 0 |
| `testStats` | `hyperprompt main.hc --stats` | Statistics printed, exit 0 |
| `testLenientMode` | `hyperprompt main.hc --lenient` | Missing refs = inline, exit 0 |
| `testInvalidInput` | `hyperprompt invalid.hc` | Error message, exit 2 |

**Estimated:** 10+ end-to-end tests, ~1 hour to implement.

---

## 8. Implementation Sequence

**Recommended Order:**

1. **Week 1, Day 1 (2 hours):** Subtask D2.1 + D2.2 → Core pipeline working
2. **Week 1, Day 1 (1 hour):** Subtask D2.3 + D2.4 → Dry-run and verbose modes
3. **Week 1, Day 2 (2 hours):** Subtask D2.5 → Valid input tests (V01-V14)
4. **Week 1, Day 2 (1 hour):** Subtask D2.6 → Invalid input tests (I01-I10)

**Total Estimated Time:** 6 hours (matches work plan estimate)

---

## 9. API Design

### 9.1 CompilerDriver Class

```swift
import Core
import Parser
import Resolver
import Emitter
import Manifest

/// Orchestrates the complete compilation pipeline
final class CompilerDriver {
    private let fileSystem: FileSystem
    private let parser: Parser
    private let resolver: ReferenceResolver
    private let emitter: MarkdownEmitter
    private let manifestGenerator: ManifestGenerator

    init(
        fileSystem: FileSystem = LocalFileSystem(),
        parser: Parser = Parser(),
        resolver: ReferenceResolver,
        emitter: MarkdownEmitter = MarkdownEmitter(),
        manifestGenerator: ManifestGenerator = ManifestGenerator()
    ) {
        self.fileSystem = fileSystem
        self.parser = parser
        self.resolver = resolver
        self.emitter = emitter
        self.manifestGenerator = manifestGenerator
    }

    /// Main compilation entry point
    /// - Parameters:
    ///   - inputPath: Path to input .hc file
    ///   - outputPath: Path for compiled .md output (default: input.md)
    ///   - manifestPath: Path for manifest JSON (default: output.manifest.json)
    ///   - rootPath: Root directory for references (default: parent of input)
    ///   - strict: Strict mode (missing refs = error) vs lenient (missing refs = inline)
    ///   - dryRun: Validate without writing files
    ///   - verbose: Output detailed progress to stderr
    ///   - stats: Collect and report compilation metrics
    /// - Returns: CompilationResult on success
    /// - Throws: CompilerError with appropriate exit code
    func compile(
        inputPath: String,
        outputPath: String? = nil,
        manifestPath: String? = nil,
        rootPath: String? = nil,
        strict: Bool = true,
        dryRun: Bool = false,
        verbose: Bool = false,
        stats: Bool = false
    ) throws -> CompilationResult {
        // Implementation...
    }
}

/// Result of successful compilation
struct CompilationResult {
    let markdown: String            // Compiled Markdown content
    let manifestJson: String        // Manifest JSON content
    let statistics: CompilationStats?  // Metrics (if stats enabled)
}

/// Compilation metrics
struct CompilationStats {
    let numHypercodeFiles: Int
    let numMarkdownFiles: Int
    let totalInputBytes: Int
    let outputBytes: Int
    let maxDepth: Int
    let durationMs: Int
}
```

---

### 9.2 Usage Example

```swift
// Normal compilation
let driver = CompilerDriver(
    fileSystem: LocalFileSystem(),
    resolver: ReferenceResolver(rootPath: ".")
)

do {
    let result = try driver.compile(
        inputPath: "main.hc",
        outputPath: "main.md",
        manifestPath: "main.manifest.json",
        rootPath: ".",
        strict: true,
        dryRun: false,
        verbose: true,
        stats: true
    )

    print("Compilation successful!")
    if let stats = result.statistics {
        print("Processed \(stats.numHypercodeFiles) Hypercode files")
        print("Duration: \(stats.durationMs) ms")
    }
} catch let error as CompilerError {
    // Print diagnostic to stderr
    DiagnosticPrinter.print(error, to: stderr)
    exit(error.exitCode)
} catch {
    // Internal error
    DiagnosticPrinter.print(InternalError(error), to: stderr)
    exit(4)
}
```

---

## 10. Edge Cases and Failure Scenarios

### 10.1 Edge Cases

| Scenario | Expected Behavior | Test |
|----------|-------------------|------|
| Input file is empty | Parse error (no root node) → exit 2 | I-Empty |
| Output path = input path | Error: cannot overwrite input → exit 1 | I-Overwrite |
| Root directory is input file parent | Default behavior works correctly | V01 |
| Manifest parent directory missing | Create parent directories (or error if dry-run) | V-ManifestDir |
| Very deep nesting (depth 10) | Compiles successfully, H6 headings | V13 |
| Depth exceeds 10 | Resolution error → exit 3 | I07 |
| Unicode in file paths | Handled correctly (UTF-8 paths) | V14 |
| Disk full during write | IO error with clear message → exit 1 | I-DiskFull |

---

### 10.2 Failure Scenarios

| Failure | Detection | Recovery | Exit Code |
|---------|-----------|----------|-----------|
| Input file not found | Pre-validation | Report error, exit | 1 |
| Input file not readable | Pre-validation | Report error, exit | 1 |
| Root directory not found | Pre-validation | Report error, exit | 1 |
| Output directory not writable | Pre-validation | Report error, exit | 1 |
| Parser syntax error | Parse phase | Propagate with location | 2 |
| Circular dependency | Resolve phase | Propagate with cycle path | 3 |
| Forbidden extension | Resolve phase | Propagate with path | 3 |
| Depth exceeded | Resolve phase | Propagate with depth | 3 |
| Out of memory | Any phase | Catch, report as internal | 4 |
| Unexpected panic | Any phase | Catch, report as internal | 4 |

---

## 11. Dependencies and Blockers

### 11.1 Dependencies (All Completed ✅)

| Module | Status | Version | Notes |
|--------|--------|---------|-------|
| **C2 — Markdown Emitter** | ✅ Complete | 2025-12-09 | Emits Markdown from resolved AST |
| **C3 — Manifest Generator** | ✅ Complete | 2025-12-09 | Generates deterministic JSON manifest |
| **D1 — Argument Parsing** | ✅ Complete | 2025-12-09 | Provides validated CompilerArguments |

### 11.2 Blockers

**None.** All dependencies are complete and tested. Implementation can proceed immediately.

---

## 12. Quality Enforcement

### 12.1 Code Quality

- [ ] All public APIs documented with DocC comments
- [ ] All error cases covered by unit tests
- [ ] No compiler warnings
- [ ] SwiftLint passes with zero violations
- [ ] Code coverage >90% for CompilerDriver module

### 12.2 Testing Quality

- [ ] All valid test corpus files (V01-V14) pass with golden file match
- [ ] All invalid test corpus files (I01-I10) fail with correct exit code
- [ ] Dry-run mode tested (no file writes)
- [ ] Verbose mode tested (stderr capture)
- [ ] Statistics mode tested (metric validation)

### 12.3 Performance Quality

- [ ] 1000-node tree compiles in <5 seconds
- [ ] Memory usage <10× input size
- [ ] Deterministic output verified (10 compilations → identical SHA256)

---

## 13. Future Extensions

**For v0.2+:**
- Incremental compilation with change detection
- Parallel compilation of independent subtrees
- Caching of parsed/resolved ASTs
- Compilation progress bars for large projects

**For v0.3+:**
- Cascade sheet (.hcs) integration
- TaskRecord variable interpolation
- Dynamic content based on task context

**For v0.4+:**
- Manifest verification mode
- Signature validation for provenance

**For v0.5+:**
- Watch mode for automatic recompilation
- Hot reload during development

---

## 14. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-09 | Claude (Agent) | Initial PRD generation for task D2 |

---

## 15. Approval and Sign-Off

**Ready for Implementation:** ✅ Yes
**Estimated Effort:** 6 hours
**Risk Level:** Low (all dependencies complete, well-defined scope)
**Priority:** P0 (Critical) — Blocks E1 (integration tests need working driver)

---

**End of Document**

---
**Archived:** 2025-12-10
