# PRD: B3 — File Loader & Caching

**Task ID:** B3
**Task Name:** File Loader & Caching
**Priority:** [P0] Critical
**Phase:** Phase 4: Reference Resolution
**Estimated Effort:** 4 hours
**Dependencies:** A2 (Core Types Implementation)
**Blocks:** B4 (Recursive Compilation), C3 (Manifest Generator)
**Status:** Selected for Implementation

---

## 1. Scope & Intent

### 1.1 Objective

Implement a production-grade file loading subsystem for the Hyperprompt Compiler that:
- Reads file content with UTF-8 encoding and line ending normalization
- Caches loaded content to avoid redundant I/O operations
- Computes SHA256 hashes of loaded files using swift-crypto
- Collects structured file metadata for manifest generation

This task establishes the foundation for recursive file compilation (B4) and manifest generation (C3).

### 1.2 Success Criteria

**Implementation succeeds when:**
1. ✅ File content correctly loaded with UTF-8 encoding from all platforms
2. ✅ CRLF/CR line endings normalized to LF before processing
3. ✅ Loaded content cached in-memory to avoid redundant reads
4. ✅ SHA256 hashes computed accurately during loading (byte-for-byte identical hashes for identical content)
5. ✅ File metadata (path, hash, size, type) collected correctly
6. ✅ `ManifestEntry` and `ManifestBuilder` structures implement required interfaces
7. ✅ All edge cases handled correctly:
   - Empty files
   - Large files (>1MB)
   - Mixed line ending styles
   - Files with trailing whitespace
8. ✅ Unit tests achieve >90% code coverage for file loading logic

### 1.3 Constraints & Assumptions

**Constraints:**
- UTF-8 encoding only (no BOM, no other encodings)
- Must work cross-platform (macOS, Linux, Windows)
- Must use `swift-crypto` for SHA256 computation (already in Package.swift)
- File size limits: support files from 0 bytes to >1GB
- No network access
- No symlink following outside root directory

**Assumptions:**
- FileSystem protocol (A2) already provides abstraction for file operations
- CompilerError protocol (A2) exists for error handling
- SourceLocation struct (A2) available for tracking file locations
- Swift standard library provides necessary string/data operations

---

## 2. Functional Requirements

### 2.1 File Content Reading

#### Requirement FR-2.1.1: UTF-8 Encoding
- **Input:** File path (String)
- **Process:** Read file as UTF-8 bytes
- **Output:** String with UTF-8 content
- **Error Handling:**
  - Invalid UTF-8 → CompilerError with diagnostics
  - Encoding errors must indicate byte position where decoding failed

#### Requirement FR-2.1.2: Line Ending Normalization
- **Input:** Raw file content (String)
- **Process:**
  - Detect and normalize: CRLF → LF, CR → LF
  - Preserve LF as-is
  - Normalization happens after UTF-8 decoding, before caching
- **Output:** Normalized String with consistent LF line endings
- **Verification:** No CRLF or standalone CR remains in output

#### Requirement FR-2.1.3: Efficient Reading
- **Input:** File path (String)
- **Process:** Single pass read → decode → normalize → cache
- **Output:** Normalized content string in cache
- **Performance Target:** File read completes in <100ms for typical source files

### 2.2 Content Caching

#### Requirement FR-2.2.1: In-Memory Cache
- **Input:** File path (String), normalized content (String)
- **Process:** Store in dictionary/map: path → content
- **Output:** Cached content available for subsequent lookups
- **Structure:** Thread-safe cache (or document thread-safety requirements)
- **Lifetime:** Cache persists for duration of compilation session

#### Requirement FR-2.2.2: Cache Hits
- **Input:** File path (String)
- **Process:** Lookup path in cache; if found, return cached content
- **Output:** Content string (cached)
- **Behavior:** No disk I/O on cache hit; must be deterministic (same file always returns same content)

#### Requirement FR-2.2.3: Cache Misses
- **Input:** File path (String) not in cache
- **Process:** Load from disk, normalize, compute hash, cache
- **Output:** Content string and metadata in cache
- **Behavior:** Automatic loading on first access

### 2.3 SHA256 Hash Computation

#### Requirement FR-2.3.1: Hash Computation
- **Input:** File content (normalized String)
- **Process:**
  - Convert String to UTF-8 bytes
  - Compute SHA256 hash using swift-crypto
  - Produce hex-encoded string (lowercase)
- **Output:** SHA256 hash as 64-character hex string
- **Verification:** Hash computed only on normalized content (post-LF conversion)

#### Requirement FR-2.3.2: Hash Accuracy
- **Input:** File content
- **Process:** Compute SHA256 using swift-crypto's standard algorithm
- **Output:** Hash matching openssl sha256 (byte-for-byte identical)
- **Determinism:** Same content → identical hash; different content → different hash

#### Requirement FR-2.3.3: Hash Caching
- **Input:** File path
- **Process:** Store computed hash alongside cached content
- **Output:** Hash available without recomputation
- **Behavior:** Hash computed once per unique file content; reuse on subsequent references

### 2.4 File Metadata Collection

#### Requirement FR-2.4.1: Metadata Struct
- **Input:** File path, content, hash
- **Process:** Assemble metadata into `ManifestEntry` struct
- **Output:** ManifestEntry with fields:
  - `path: String` — file path relative to root
  - `sha256: String` — 64-char hex hash
  - `size: Int` — file size in bytes (original, pre-normalization)
  - `type: FileType` — enum: `.markdown` or `.hypercode`
- **Verification:** All fields populated; no nulls or defaults

#### Requirement FR-2.4.2: File Type Detection
- **Input:** File path (String)
- **Process:** Extract file extension; classify:
  - `.md` → `.markdown`
  - `.hc` → `.hypercode`
  - Other → error (invalid extension)
- **Output:** FileType enum value
- **Error Handling:** Invalid extension → CompilerError

#### Requirement FR-2.4.3: Size Tracking
- **Input:** File content bytes
- **Process:** Count total bytes in original (pre-normalized) content
- **Output:** Size as Int (bytes)
- **Verification:** Size ≥ 0; empty files have size 0

### 2.5 Manifest Builder

#### Requirement FR-2.5.1: ManifestBuilder Structure
- **Input:** (created empty at start of compilation)
- **Process:** Accumulate ManifestEntry objects
- **Output:** ManifestBuilder instance with collection interface
- **Methods Required:**
  - `add(entry: ManifestEntry)` → add single entry
  - `entries() -> [ManifestEntry]` → retrieve all accumulated entries
  - `clear()` → reset for next compilation (optional)

#### Requirement FR-2.5.2: Entry Accumulation
- **Input:** ManifestEntry objects (from file loading)
- **Process:** Store entries in ordered collection (maintain insertion order)
- **Output:** Entries retrievable in same order added
- **Behavior:** Duplicate paths allowed (different versions of same file during compilation)

#### Requirement FR-2.5.3: Metadata Export
- **Input:** ManifestBuilder with accumulated entries
- **Process:** Prepare entries for JSON serialization
- **Output:** [ManifestEntry] array with all required fields
- **Verification:** All entries JSON-serializable with standard encoding

---

## 3. Non-Functional Requirements

### 3.1 Performance

| Metric | Target | Rationale |
|--------|--------|-----------|
| Single file load | <10ms | Typical source file |
| Large file (>1MB) | <100ms | Acceptable for batch compilation |
| Cache hit | <1ms | In-memory lookup only |
| Hash computation | <50ms | Applies only once per file |

### 3.2 Correctness & Determinism

- **Determinism:** Identical file content produces identical normalized content and hash across all platforms
- **Consistency:** Once cached, file content never changes during compilation session
- **Accuracy:** SHA256 hashes match system utilities (openssl, sha256sum)

### 3.3 Error Handling

| Error Scenario | Exit Code | Behavior |
|---|---|---|
| File not found | 1 (IO Error) | CompilerError with path and suggestion |
| Permission denied | 1 (IO Error) | Clear error message |
| Invalid UTF-8 | 1 (IO Error) | Indicate byte position of decode failure |
| File too large | 1 (IO Error) | Graceful rejection with size info |
| Disk I/O failure | 1 (IO Error) | Retry once; then fail |

### 3.4 Memory Management

- Cache limited by available memory (document if needed)
- No memory leaks on error paths
- Proper cleanup of file handles (if using low-level I/O)

### 3.5 Cross-Platform Compatibility

- **Line endings:** Normalize all platforms' line endings identically
- **Path separators:** Handle `/` and `\` correctly (use FileSystem abstraction)
- **File permissions:** Handle read-only and unreadable files gracefully
- **File sizes:** Support same size range on macOS, Linux, Windows

---

## 4. Implementation Structure

### 4.1 New Types (Swift)

```swift
// File type enumeration
enum FileType: String, Codable {
    case markdown = "markdown"
    case hypercode = "hypercode"
}

// Metadata for single file
struct ManifestEntry: Codable {
    let path: String              // relative to root
    let sha256: String            // lowercase hex
    let size: Int                 // bytes
    let type: FileType            // .markdown or .hypercode
}

// Manifest builder for accumulating entries
class ManifestBuilder {
    private var entries: [ManifestEntry] = []

    func add(entry: ManifestEntry) { /* ... */ }
    func entries() -> [ManifestEntry] { /* ... */ }
}

// File loader with caching
class FileLoader {
    private let fileSystem: FileSystem
    private var cache: [String: (content: String, hash: String, metadata: ManifestEntry)] = [:]

    func load(path: String) throws -> (content: String, hash: String, metadata: ManifestEntry)
    func normalizeLineEndings(_ content: String) -> String
    func computeHash(_ data: Data) -> String
    func detectFileType(_ path: String) throws -> FileType
}
```

### 4.2 Integration Points

- **FileSystem:** Use existing abstraction for all file I/O
- **CompilerError:** Report all errors with CompilerError protocol
- **SourceLocation:** Track file locations for error diagnostics
- **A2 Core Types:** Depend on existing error handling infrastructure

---

## 5. Test Plan

### 5.1 Unit Tests (>90% coverage)

#### 5.1.1 UTF-8 Encoding Tests
- [ ] Valid UTF-8 file → correct content
- [ ] UTF-8 with emoji → preserved correctly
- [ ] Latin-1 encoded file → error with diagnostics
- [ ] File with BOM → handle correctly
- [ ] Invalid byte sequence → error with position

#### 5.1.2 Line Ending Normalization Tests
- [ ] LF-only file → unchanged
- [ ] CRLF file → converted to LF
- [ ] CR-only file → converted to LF
- [ ] Mixed line endings → all converted consistently
- [ ] Trailing newline preserved
- [ ] Empty file → no error

#### 5.1.3 Caching Tests
- [ ] First load → reads from disk
- [ ] Second load → cache hit (no disk I/O)
- [ ] Different files → separate cache entries
- [ ] Cache consistency → multiple loads identical
- [ ] Clear cache (if supported)

#### 5.1.4 SHA256 Hash Tests
- [ ] Empty file → correct SHA256 hash
- [ ] Single-line file → deterministic hash
- [ ] Multi-line file → correct hash
- [ ] Large file (>1MB) → accurate hash
- [ ] Hash matches openssl sha256 output
- [ ] Hash stability → same content always same hash

#### 5.1.5 File Type Detection Tests
- [ ] `.md` file → FileType.markdown
- [ ] `.hc` file → FileType.hypercode
- [ ] `.txt` file → error (invalid extension)
- [ ] No extension → error
- [ ] Case sensitivity (`.MD` vs `.md`) — document behavior

#### 5.1.6 ManifestEntry Tests
- [ ] Create entry with all fields
- [ ] Serialize to JSON
- [ ] Deserialize from JSON
- [ ] Field validation (non-empty path, valid hash format)

#### 5.1.7 ManifestBuilder Tests
- [ ] Add single entry
- [ ] Add multiple entries
- [ ] Retrieve entries in order
- [ ] Entries array is retrievable

### 5.2 Integration Tests

#### 5.2.1 End-to-End File Loading
- [ ] Load and parse sample `.hc` file
- [ ] Verify content, hash, and metadata match expectations
- [ ] Test with file references from Workplan examples

#### 5.2.2 Error Scenarios
- [ ] Missing file (strict mode)
- [ ] Unreadable file (permission denied)
- [ ] File modified during compilation
- [ ] Symlink behavior (if applicable)

### 5.3 Test Corpus

Use test files from `DOCS/TEST_CORPUS/` including:
- V01-V14: Valid inputs with various encodings and line endings
- I01-I10: Invalid inputs to verify error handling

---

## 6. Detailed Implementation Tasks

### Phase 1: Core File Loading (1.5 hours)

**Task 1.1: Implement UTF-8 File Reading**
- [ ] Create `FileLoader` class with FileSystem dependency
- [ ] Implement `load(path:)` → reads file as UTF-8 Data
- [ ] Handle UTF-8 decoding errors with diagnostics
- [ ] Acceptance: File content correctly loaded; encoding errors reported with position

**Task 1.2: Implement Line Ending Normalization**
- [ ] Create `normalizeLineEndings(_ content: String) -> String`
- [ ] Replace CRLF with LF
- [ ] Replace standalone CR with LF
- [ ] Preserve LF as-is
- [ ] Acceptance: All line endings normalized; output validated via tests

**Task 1.3: Write Initial File Reading Tests**
- [ ] Create test fixtures with various encodings
- [ ] Test UTF-8 valid content
- [ ] Test line ending normalization
- [ ] Acceptance: 10+ test cases passing

### Phase 2: Hashing & Metadata (1.5 hours)

**Task 2.1: Implement SHA256 Hash Computation**
- [ ] Import swift-crypto
- [ ] Create `computeHash(_ data: Data) -> String`
- [ ] Compute SHA256 on normalized content
- [ ] Return lowercase hex string
- [ ] Acceptance: Hash matches openssl sha256 for test files

**Task 2.2: Implement File Type Detection**
- [ ] Create `FileType` enum: markdown, hypercode
- [ ] Create `detectFileType(_ path: String) -> FileType`
- [ ] Recognize `.md` → markdown, `.hc` → hypercode
- [ ] Reject other extensions with error
- [ ] Acceptance: Correct type detection; invalid extensions rejected

**Task 2.3: Implement ManifestEntry Struct**
- [ ] Define `ManifestEntry`: path, sha256, size, type
- [ ] Make Codable for JSON serialization
- [ ] Document field semantics
- [ ] Acceptance: Struct creates and encodes to JSON correctly

**Task 2.4: Write Hash & Metadata Tests**
- [ ] Test hash computation for empty, small, large files
- [ ] Verify hash determinism
- [ ] Test file type detection
- [ ] Acceptance: 15+ test cases passing

### Phase 3: Caching & Building (1 hour)

**Task 3.1: Implement Content Caching**
- [ ] Add private `cache` dictionary to FileLoader
- [ ] Implement lookup logic (return cached if exists)
- [ ] Implement insertion logic (cache on first load)
- [ ] Ensure thread-safety or document single-thread requirement
- [ ] Acceptance: Cache hits verified via integration tests

**Task 3.2: Implement ManifestBuilder**
- [ ] Create `ManifestBuilder` class
- [ ] Implement `add(entry:)` method
- [ ] Implement `entries()` method
- [ ] Maintain insertion order
- [ ] Acceptance: Entries accumulate and retrieve correctly

**Task 3.3: Integrate Loader with Builder**
- [ ] FileLoader.load returns ManifestEntry
- [ ] Integrate with ManifestBuilder
- [ ] End-to-end test: load file → generate entry → add to builder
- [ ] Acceptance: Builder contains correct entries after loads

### Phase 4: Testing & Documentation (0.5 hours)

**Task 4.1: Comprehensive Test Coverage**
- [ ] Add remaining edge case tests
- [ ] Achieve >90% code coverage
- [ ] Document any untestable code paths
- [ ] Acceptance: Coverage report shows >90% (or documented exclusions)

**Task 4.2: Code Documentation**
- [ ] Add brief comments explaining caching strategy
- [ ] Document FileType detection rules
- [ ] Document line ending normalization
- [ ] Acceptance: Code is self-documenting; no ambiguous sections

---

## 7. Acceptance Criteria

**Implementation complete when:**

| Criterion | Status | Notes |
|-----------|--------|-------|
| FileLoader loads UTF-8 files | ✓ | Decoded correctly |
| CRLF/CR normalized to LF | ✓ | No CR or CRLF in output |
| Content cached after first load | ✓ | Second load uses cache |
| SHA256 computed accurately | ✓ | Matches openssl |
| ManifestEntry created with metadata | ✓ | All fields populated |
| File type detection works | ✓ | .md/.hc recognized |
| ManifestBuilder accumulates entries | ✓ | Entries retrievable in order |
| >90% test coverage | ✓ | Excluding trivial accessors |
| Error handling tested | ✓ | IO errors reported correctly |
| Cross-platform compatibility verified | ✓ | Works on macOS/Linux/Windows (if available) |

---

## 8. Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Large files consume too much memory | Low | Medium | Implement streaming if needed; document file size limits |
| Hash computation slower than expected | Low | Low | Profile and optimize; use swift-crypto's optimized path |
| UTF-8 decoding edge cases missed | Medium | High | Comprehensive test coverage with fuzzing if time allows |
| Cache invalidation issues | Low | High | Document cache lifetime; single-session model simplifies |
| Cross-platform line ending issues | Low | Medium | Thorough testing on each platform |

---

## 9. Deliverables

**Code Deliverables:**
- [ ] FileLoader class (file reading, normalization, hashing, caching)
- [ ] FileType enum (markdown, hypercode)
- [ ] ManifestEntry struct (Codable)
- [ ] ManifestBuilder class (entry accumulation)
- [ ] Comprehensive unit & integration tests (>90% coverage)

**Documentation Deliverables:**
- [ ] Code comments explaining caching strategy
- [ ] Test results showing all edge cases handled
- [ ] Performance metrics (file load time, hash computation time)

**Integration Readiness:**
- [ ] Blocks B4 (Recursive Compilation) — FileLoader ready for recursive calls
- [ ] Blocks C3 (Manifest Generator) — ManifestBuilder ready for manifest output
- [ ] All tests pass on development machine
- [ ] No external dependencies beyond swift-crypto (already in Package.swift)

---

## 10. Definition of Done

✅ **Task B3 is complete when:**

1. All code written and committed
2. All tests passing (>90% coverage)
3. Error handling verified for all scenarios (IO, encoding, permissions)
4. Cross-platform compatibility confirmed (at least macOS/Linux)
5. Performance targets met (<10ms typical, <100ms large files)
6. SHA256 hashes verified against system utilities
7. ManifestEntry and ManifestBuilder used in subsequent tasks (B4, C3)
8. Workplan updated: B3 marked as completed ✅
9. Changes committed and pushed to feature branch

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-06 | Hyperprompt Team | Initial PRD generation via PLAN command |
