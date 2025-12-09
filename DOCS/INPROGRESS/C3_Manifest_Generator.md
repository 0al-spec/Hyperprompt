# C3: Manifest Generator — PRD

**Phase:** Phase 5 (Markdown Emission)
**Priority:** P1
**Estimated Effort:** 3 hours
**Dependencies:** B3 (File Loader & Caching) ✅
**Status:** In Development

---

## 1. Objective

Implement a manifest generator component that collects file metadata during compilation and produces a machine-verifiable JSON manifest with complete provenance information for all processed source files. The manifest enables verification of compilation integrity and provides a record of all inputs with their cryptographic hashes.

**Success Criterion:** Generated manifest contains accurate metadata for all source files, uses deterministic JSON formatting with alphabetically sorted keys, and passes comprehensive validation tests.

---

## 2. Scope & Intent

### 2.1 Primary Responsibility

Transform collected file metadata (from B3: File Loader & Caching) into a structured, deterministic JSON manifest document. The manifest serves as a record of compilation provenance, enabling downstream verification and documentation of all input files processed during compilation.

### 2.2 Inputs & Outputs

**Input:**
- `ManifestBuilder` containing collected `ManifestEntry` items (from B3)
  - Each entry includes: path, sha256 hash, size (bytes), type (markdown or hypercode)
- Compilation timestamp (current time)
- Version string (from package configuration)
- Root directory path

**Output:**
- Manifest as JSON `String`
  - Top-level keys alphabetically sorted
  - ISO 8601 timestamp in UTC
  - Nested `sources` array with entries
  - Deterministic key ordering throughout
  - File ends with exactly one LF
  - UTF-8 encoding

### 2.3 Constraints

- Must use **alphabetically sorted keys** throughout JSON (determinism requirement)
- Must generate **valid, well-formed JSON** (parseable by standard JSON parsers)
- Must handle **empty manifest** gracefully (no sources processed)
- Must normalize timestamps to **ISO 8601 format** in UTC timezone
- Must maintain deterministic output (identical metadata → identical JSON bytes)
- Must ensure output ends with exactly one LF
- Must preserve relative paths exactly as provided (no normalization)

### 2.4 Assumptions

1. `ManifestEntry` items are already validated (path valid, hash computed, size known)
2. File type is known and set correctly in each entry (`markdown` or `hypercode`)
3. All paths are relative to the root directory
4. Timestamps can be obtained from system time (no custom clock needed)
5. JSON serialization library available (Foundation's `JSONEncoder` in Swift)

---

## 3. Functional Requirements

### 3.1 Manifest Structure

**Top-level JSON object:**

```json
{
  "root": "/path/to/root",
  "sources": [
    {
      "path": "input.hc",
      "sha256": "abc123...",
      "size": 1024,
      "type": "hypercode"
    },
    {
      "path": "included.md",
      "sha256": "def456...",
      "size": 2048,
      "type": "markdown"
    }
  ],
  "timestamp": "2025-12-09T14:30:45Z",
  "version": "0.1.0"
}
```

**Key Requirements:**
- All top-level keys **alphabetically sorted**: `root`, `sources`, `timestamp`, `version`
- `root`: Absolute or relative path to compilation root directory (string)
- `sources`: Array of manifest entries (sorted by path for determinism)
- `timestamp`: ISO 8601 format with Z suffix (UTC), exact format: `YYYY-MM-DDTHH:MM:SSZ`
- `version`: Package version as string (e.g., `"0.1.0"`)

### 3.2 Manifest Entry Structure

**Each entry in `sources` array:**

```json
{
  "path": "input.hc",
  "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "size": 1024,
  "type": "hypercode"
}
```

**Key Requirements:**
- `path`: Relative file path (string) — exactly as recorded during compilation
- `sha256`: Lowercase hexadecimal SHA256 hash (64 characters) — computed by B3
- `size`: File size in bytes (integer) — from file system
- `type`: Either `"markdown"` or `"hypercode"` (string) — determined by file extension

**Entry Ordering:**
- Sort entries by `path` (alphabetically, case-sensitive) for determinism
- Ensures reproducible manifest JSON output

### 3.3 Timestamp Generation

**ISO 8601 Format Requirements:**
- Format: `YYYY-MM-DDTHH:MM:SSZ`
- Example: `2025-12-09T14:30:45Z`
- Timezone: Always UTC (Z suffix indicates Zulu/UTC time)
- Precision: Seconds (no fractional seconds)
- All components zero-padded to 2 digits

**Implementation:**
```swift
let formatter = ISO8601DateFormatter()
formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
let isoString = formatter.string(from: Date()) // Use standard library
// Ensure format: "2025-12-09T14:30:45Z"
```

### 3.4 Key Ordering (Determinism)

**JSON Key Sorting:**
- All JSON object keys must be **alphabetically sorted** (A-Z)
- Applied recursively to all nested objects
- Ensures byte-for-byte identical output for identical metadata

**Example:**
```json
{
  "path": "...",      // 'p' comes first
  "sha256": "...",    // 's' comes second
  "size": 123,        // 's' (size) comes before 't' in top-level
  "type": "..."       // 't' comes last
}
```

---

## 4. Non-Functional Requirements

### 4.1 Performance

- Generate manifest for 1000+ files in < 500 ms
- Linear time complexity relative to number of entries
- Minimal memory overhead (streaming-friendly structure)
- JSON serialization uses standard library (no custom parsing)

### 4.2 Correctness & Determinism

- Identical manifest data → identical JSON bytes
- No random elements or timestamps (use provided time)
- No platform-specific behavior (consistent across macOS, Linux, Windows)
- Output ends with exactly one LF (`\n`)

### 4.3 Robustness

- Handle empty manifest gracefully (zero entries)
- Validate all required fields present before serialization
- Report clear errors if required data missing
- Fail-safe: output minimal valid JSON if field unavailable

### 4.4 Testability

- All functions pure (no side effects)
- Deterministic output enables golden file comparison
- Comprehensive test coverage for edge cases
- Support for test-specific timestamp injection (for reproducible tests)

### 4.5 Compatibility

- Output JSON compatible with standard JSON parsers
- No custom JSON extensions or non-standard syntax
- Valid JSON Schema definition available
- Supports pretty-printing (optional, for debugging)

---

## 5. Detailed TODO Breakdown

### Phase 1: Infrastructure (Effort: 0.5 hours)

- [ ] **[High]** Create `Manifest` struct with required fields
  - Fields: `root: String`, `sources: [ManifestEntry]`, `timestamp: String`, `version: String`
  - Initialize with empty sources array
  - Add basic documentation comments
  - Ensure all fields are immutable (let, not var)

- [ ] **[High]** Create `ManifestEntry` struct (if not already in B3)
  - Fields: `path: String`, `sha256: String`, `size: Int`, `type: String`
  - Type validation: `type` must be "markdown" or "hypercode"
  - Immutable structure

- [ ] **[High]** Define `ManifestGenerator` struct with public API
  - Method: `generate(builder: ManifestBuilder, version: String, root: String, timestamp: Date?) -> Manifest`
  - Method: `toJSON(manifest: Manifest) -> String`
  - Accept optional timestamp for testing (default: current time)

**Acceptance Criteria:**
- All structs compile without errors
- Public API defined and documented
- Immutable fields enforced

---

### Phase 2: Timestamp Handling (Effort: 0.5 hours)

- [ ] **[High]** Implement ISO 8601 timestamp generation
  - Input: `Date` (or nil for current time)
  - Output: ISO 8601 string with format `YYYY-MM-DDTHH:MM:SSZ`
  - Timezone: Always UTC (Z suffix)
  - Precision: Seconds only (no fractional seconds)
  - Test: verify exact format with known timestamps

- [ ] **[High]** Add timestamp validation function
  - Verify format matches `YYYY-MM-DDTHH:MM:SSZ` pattern
  - Validate month (01-12), day (01-31), hour (00-23), minute (00-59), second (00-59)
  - Reject invalid combinations (e.g., Feb 30)

- [ ] **[Medium]** Test timestamp generation
  - Generate timestamps for various dates (past, present, future)
  - Verify UTC conversion (if system time is in different timezone)
  - Test: edge cases (year 9999, Jan 1, Dec 31)

**Acceptance Criteria:**
- Timestamp always in format `YYYY-MM-DDTHH:MM:SSZ`
- UTC timezone guaranteed
- Test coverage: 5+ timestamp test cases

---

### Phase 3: Manifest Entry Processing (Effort: 0.75 hours)

- [ ] **[High]** Implement entry validation function
  - Validate `path` is non-empty string
  - Validate `sha256` is 64-character lowercase hex string
  - Validate `size` is non-negative integer
  - Validate `type` is either "markdown" or "hypercode"
  - Report clear error message if validation fails

- [ ] **[High]** Implement entry sorting by path
  - Sort entries alphabetically by `path` (case-sensitive)
  - Ensure deterministic ordering (e.g., "a.md" before "b.md", "a/b.md" before "a/c.md")
  - Test with various path patterns (nested, with special chars)

- [ ] **[Medium]** Test entry processing
  - Test validation with valid entries (all types)
  - Test validation with invalid entries (bad format, missing fields)
  - Test sorting with 10+ entries in random order
  - Verify sorted order matches expected alphabetical sequence

**Acceptance Criteria:**
- All entries validated correctly
- Entries sorted deterministically
- Error handling tested
- 100% of validation test cases pass

---

### Phase 4: JSON Serialization (Effort: 1 hour)

- [ ] **[High]** Implement alphabetical key sorting in JSON output
  - Serialize `Manifest` struct to JSON
  - Ensure top-level keys in alphabetical order: `root`, `sources`, `timestamp`, `version`
  - Sort entries within `sources` array by path
  - Use custom encoding if needed to guarantee key order

- [ ] **[High]** Implement `ManifestEntry` JSON serialization
  - Serialize each entry with alphabetically sorted keys: `path`, `sha256`, `size`, `type`
  - Validate output JSON structure matches spec
  - Test with various entry values

- [ ] **[High]** Ensure output format
  - JSON formatted with consistent indentation (2 spaces)
  - No trailing whitespace on lines
  - Document ends with exactly one LF (`\n`)
  - Valid JSON passable by standard parsers

- [ ] **[Medium]** Test JSON serialization
  - Generate manifest JSON for 1+ entries
  - Parse output with standard JSON decoder (verify valid JSON)
  - Compare generated JSON with golden files
  - Test empty manifest (zero entries)
  - Verify key order in output

**Acceptance Criteria:**
- JSON output always has alphabetically sorted keys
- JSON is valid and parseable
- Output ends with exactly one LF
- 100% of serialization test cases pass

---

### Phase 5: Edge Cases & Error Handling (Effort: 0.5 hours)

- [ ] **[High]** Handle empty manifest
  - Generate valid JSON with empty `sources` array
  - Test: zero entries → valid JSON with `sources: []`

- [ ] **[Medium]** Handle special characters in paths
  - Paths with spaces: `"my file.hc"` → JSON-escaped correctly
  - Paths with unicode: `"файл.hc"` → UTF-8 preserved
  - Paths with quotes: `"file\"with\"quotes.hc"` → properly escaped
  - Test each variant

- [ ] **[Medium]** Handle large manifests
  - Generate manifest for 1000+ entries
  - Verify performance (< 500 ms)
  - Verify JSON still parseable

- [ ] **[Low]** Add optional pretty-printing for debugging
  - Support both compact and pretty JSON formats
  - Pretty format: 2-space indentation, readable for humans
  - Compact format: minimal whitespace, optimal for storage

**Acceptance Criteria:**
- Empty manifest valid
- Special characters handled correctly
- Large manifests processable
- Performance requirements met

---

### Phase 6: Comprehensive Testing (Effort: 0.75 hours)

**Unit Tests: Manifest Creation**

- [ ] **[High]** Test manifest creation with various inputs
  - Single file (hypercode)
  - Single file (markdown)
  - Multiple files (mixed types)
  - Many files (10+, 100+)

- [ ] **[High]** Test timestamp injection for reproducibility
  - Generate same timestamp across multiple calls
  - Verify identical JSON output for identical metadata
  - Test: 3 generations with same timestamp → byte-for-byte match

**Unit Tests: Entry Sorting**

- [ ] **[High]** Test entry sorting
  - Entries provided in random order → sorted by path in output
  - Case-sensitive sorting: "A.hc" vs "a.hc"
  - Nested paths: "a/b.hc" vs "a/c.hc" vs "b/a.hc"

**Unit Tests: JSON Format**

- [ ] **[High]** Test JSON output structure
  - Parse generated JSON with standard decoder
  - Verify all required top-level keys present
  - Verify keys in alphabetical order
  - Verify no extra keys present

- [ ] **[High]** Test field values
  - Verify `root` matches provided path
  - Verify `version` matches provided version
  - Verify `timestamp` in ISO 8601 format
  - Verify each entry `path`, `sha256`, `size`, `type` correct

**Integration Tests**

- [ ] **[High]** Test with real B3 output
  - Create `ManifestBuilder` with entries from actual compilation
  - Generate manifest from builder
  - Verify all fields populated correctly
  - Verify manifest JSON valid

- [ ] **[Medium]** Golden file comparison
  - Create golden JSON files for test cases
  - Generate manifest for test inputs
  - Compare output with golden files (exact match)

**Edge Case Tests**

- [ ] **[Medium]** Empty manifest: zero entries → valid JSON with empty array
- [ ] **[Medium]** Special characters: unicode in paths → correctly escaped
- [ ] **[Medium]** Large manifest: 1000 entries → performance acceptable
- [ ] **[High]** Determinism: same input 3× → identical bytes

**Acceptance Criteria:**
- ≥ 90% test pass rate
- Coverage of all code paths
- No platform-specific failures
- Determinism verified (3-run comparison)
- JSON validity verified with standard parser

---

## 6. Acceptance Criteria Summary

### Functional AC

| Criterion | Requirement | Verification |
|-----------|-------------|--------------|
| Manifest structure | Top-level keys alphabetically sorted: `root`, `sources`, `timestamp`, `version` | JSON parse test |
| Entry fields | Each entry has `path`, `sha256`, `size`, `type` | JSON structure validation |
| Timestamp format | ISO 8601 with UTC timezone: `YYYY-MM-DDTHH:MM:SSZ` | Regex match + parsing |
| Key sorting | All keys recursively sorted alphabetically | Generated JSON inspection |
| Entry sorting | Entries sorted by `path` (alphabetically) | Array order verification |
| JSON validity | Output is valid JSON | JSONDecoder parse test |
| Line ending | Output ends with exactly one LF | Byte inspection |
| Empty manifest | Works with zero entries | Test with empty builder |
| SHA256 format | 64-character lowercase hex (from B3) | Format validation |

### Non-Functional AC

| Criterion | Requirement | Verification |
|-----------|-------------|--------------|
| Performance | 1000+ entries in < 500 ms | Benchmark test |
| Determinism | Identical metadata → identical bytes | 3-run comparison |
| Test coverage | ≥ 90% code paths covered | Coverage report |
| Platform compatibility | Works on macOS, Linux, Windows | CI/CD test runs |
| JSON compatibility | Standard JSON parsers can read output | JSONDecoder test |

---

## 7. Edge Cases & Assumptions

### Edge Cases

1. **Empty Manifest**
   - Input: `ManifestBuilder` with zero entries
   - Expected: Valid JSON with `"sources": []`
   - Action: Test with empty builder

2. **Special Characters in Paths**
   - Input: Paths with quotes, newlines, unicode
   - Expected: Properly JSON-escaped
   - Action: Test with various path patterns

3. **Large Manifests**
   - Input: 1000+ file entries
   - Expected: Processes in < 500 ms, valid JSON
   - Action: Performance benchmark test

4. **Hash Collisions** (theoretical)
   - Input: Different files with same SHA256 (impossible in practice)
   - Expected: Both entries included with same hash
   - Action: Document assumption that hashes are unique

5. **Timestamp at Year Boundary**
   - Input: Compilation at Dec 31, 23:59:59 UTC
   - Expected: Correct ISO 8601 output
   - Action: Test edge timestamps

### Assumptions

1. All `ManifestEntry` items from B3 are already validated
2. SHA256 hashes are precomputed and provided (not recomputed here)
3. File types correctly set in entries (no validation needed)
4. Paths already relative to root directory
5. System clock available for timestamp generation
6. JSON encoding library available (Swift standard library)
7. No concurrent modifications to `ManifestBuilder` during generation

---

## 8. Implementation Checklist

### Before Implementation

- [ ] Review B3 (File Loader & Caching) `ManifestBuilder` and `ManifestEntry` API
- [ ] Confirm Swift version and available JSON libraries
- [ ] Review test corpus for manifest expectations (D2 task)
- [ ] Confirm timestamp format with project team

### During Implementation

- [ ] Write tests alongside implementation (TDD approach)
- [ ] Verify deterministic output at each phase
- [ ] Check JSON validity with standard parser
- [ ] Test key ordering in generated JSON

### After Implementation

- [ ] Run full test suite (target ≥ 90% coverage)
- [ ] Performance benchmark (1000+ entries)
- [ ] Manual JSON inspection (readable format)
- [ ] Compare output with golden files
- [ ] Document any deviations from spec

---

## 9. Dependencies & Context

### Build Dependencies

- Swift standard library (Foundation, JSONEncoder)
- B3 output (`ManifestBuilder`, `ManifestEntry` structs)

### Integration Points

- **Input:** B3 (File Loader & Caching) provides `ManifestBuilder`
- **Output:** Consumed by D2 (Compiler Driver) to write manifest file
- **Related:** C2 (Markdown Emitter) produces similar output (Markdown)

### Testing Resources

- Test corpus: validation test cases V01-V14
- Golden files: expected manifest JSON output for each test
- Benchmark data: large manifests for performance testing

---

**Ready for implementation.**

---
