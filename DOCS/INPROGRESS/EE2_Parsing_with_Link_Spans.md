# PRD — EE2: Parsing with Link Spans (EditorEngine)

**Task ID:** EE2
**Task Name:** Parsing with Link Spans
**Priority:** P1 (High)
**Phase:** Phase 10 — Editor Engine Module
**Estimated Effort:** 3 hours
**Dependencies:** EE1 (Project Indexing) ✅
**Status:** In Progress
**Date:** 2025-12-20
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Extend the Hyperprompt parser and EditorEngine API to capture **link spans** (file references) during parsing, including byte offsets and line/column ranges, while preserving deterministic behavior and graceful error handling.

**Restatement in Precise Terms:**
Implement a parsing pathway that:
1. Detects file-reference-like substrings inside parsed Hypercode content
2. Records each detected reference as a `LinkSpan` with UTF-8 byte offsets and 1-based line/column ranges
3. Returns a partial AST and diagnostics when parse errors occur
4. Preserves existing parser behavior and CLI output determinism

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| `LinkSpan` struct | Captures byte and line/column ranges for detected references |
| Parser link extraction | Extracts link spans alongside parsed output |
| Link detection heuristic | Implementation of `LooksLikeFileReferenceSpec` |
| Error-tolerant parsing | Partial AST + diagnostics on parse errors |
| Unit tests | 5+ tests including UTF-8 edge cases |

### 1.3 Success Criteria

The implementation is successful when:
1. ✅ All detected file references in Hypercode sources are captured with correct UTF-8 byte offsets
2. ✅ Line/column ranges are accurate and 1-based
3. ✅ Parser output remains deterministic and unchanged for non-link data
4. ✅ Parse errors return partial AST + diagnostics without crashing
5. ✅ Unit tests cover UTF-8 edge cases and mixed content

### 1.4 Constraints

**Technical Constraints:**
- Must reuse existing Parser module and not change Hypercode semantics
- Ranges are expressed in UTF-8 byte offsets and 1-based line/column pairs
- Input is normalized to `\n` for range calculations (per PRD_EditorEngine)
- No new dependencies outside current Swift package

**Design Constraints:**
- Link extraction must be deterministic across platforms
- Link extraction must not affect emitted output or CLI behavior
- EditorEngine public API must not throw for parse errors

### 1.5 Assumptions

1. Parser already provides token/line metadata needed for range calculation
2. Link detection heuristic can operate on parsed line literals without re-parsing
3. Existing diagnostics model can be reused or extended for parse errors
4. EditorEngine remains trait-gated under `Editor`

### 1.6 External Dependencies

| Dependency | Purpose | Version |
|-----------|---------|---------|
| Parser module | Base parsing and AST generation | Hyperprompt 0.1+ |
| Core diagnostics | Error representation | Hyperprompt 0.1+ |
| PRD_EditorEngine | Range definitions and behavior | Current |

---

## 2. Structured TODO Plan

### Phase 0: API & Data Model

#### Task 2.0.1: Define `LinkSpan` Data Structure
**Priority:** High
**Effort:** 20 minutes
**Dependencies:** None

**Input:**
- PRD_EditorEngine.md §2.1.2 (Parsing with Link Spans)
- Existing `SourceLocation` and parser range types

**Process:**
1. Define `LinkSpan` struct with:
   - `path: String` (raw detected reference text)
   - `byteRange: Range<Int>` (UTF-8 byte offsets)
   - `startLine: Int`, `startColumn: Int`, `endLine: Int`, `endColumn: Int` (1-based)
   - `sourceFile: String` (path for context)
2. Add documentation comments describing range semantics and normalization rules
3. Ensure the type is `Sendable`, `Equatable`, and `Codable` if applicable

**Expected Output:**
- Swift file: `Sources/EditorEngine/LinkSpan.swift` (or existing types file)

**Acceptance Criteria:**
- ✅ Compiles without warnings
- ✅ Struct is usable in tests and EditorEngine API

---

### Phase 1: Link Detection & Extraction

#### Task 2.1.1: Implement Link Detection Heuristic
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** 2.0.1

**Input:**
- `LooksLikeFileReferenceSpec` requirement (Workplan EE2)
- Existing parser line representation (literal text, indent info)

**Process:**
1. Implement a pure function `looksLikeFileReference(_:) -> Bool` that:
   - Accepts a string candidate
   - Checks for plausible file suffixes (e.g., `.hc`, `.md`)
   - Rejects obvious non-paths (whitespace-only, URL schemes if undesired)
2. Keep heuristic deterministic and documented
3. Add unit tests for common true/false cases

**Expected Output:**
- Swift file: `Sources/EditorEngine/LinkDetector.swift` (or similar)

**Acceptance Criteria:**
- ✅ Heuristic returns true for typical file references
- ✅ Heuristic rejects false positives

---

#### Task 2.1.2: Extend Parser to Extract Link Spans
**Priority:** High
**Effort:** 60 minutes
**Dependencies:** 2.1.1

**Input:**
- Parser AST output
- Line text and location metadata

**Process:**
1. Identify where parsed lines and literals are exposed in the Parser module
2. For each parsed line, scan literal text for candidate file references
3. When a candidate is found:
   - Compute UTF-8 byte offsets relative to the full file content
   - Compute 1-based line/column ranges
   - Append a `LinkSpan` entry
4. Return link spans alongside parsed AST (new or extended output type)

**Expected Output:**
- Parser update to return link spans
- EditorEngine API surface updated to expose link spans

**Acceptance Criteria:**
- ✅ Link spans are produced for valid references
- ✅ Offsets and line/column ranges are accurate
- ✅ Parser output remains deterministic and unchanged for AST

---

### Phase 2: Error Handling

#### Task 2.2.1: Graceful Parse Errors with Partial AST
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** 2.1.2

**Input:**
- Existing parser error types
- EditorEngine error handling expectations

**Process:**
1. Ensure parse failures return:
   - Partial AST (best-effort)
   - Diagnostics array with error details
2. Avoid throwing from EditorEngine API
3. Document expected behavior for editor clients

**Expected Output:**
- Parser/EditorEngine API returns `ParsedFile` with `diagnostics` on error

**Acceptance Criteria:**
- ✅ Parse errors do not crash EditorEngine
- ✅ Diagnostics include location and message

---

### Phase 3: Unit Tests

#### Task 2.3.1: Add Link Span Tests
**Priority:** High
**Effort:** 40 minutes
**Dependencies:** 2.2.1

**Input:**
- Existing EditorEngine test suite

**Process:**
1. Create tests covering:
   - Simple `.hc` and `.md` references
   - Multiple references on one line
   - UTF-8 characters before and inside references
   - Mixed content with comments/blank lines
   - Parse error scenarios with partial output
2. Validate byte offsets and line/column ranges

**Expected Output:**
- `Tests/EditorEngineTests/LinkSpanTests.swift`

**Acceptance Criteria:**
- ✅ 5+ tests pass
- ✅ UTF-8 offset calculations verified

---

## 3. Feature Requirements

### 3.1 Functional Requirements

1. Extract link spans from parsed Hypercode content
2. Provide both byte ranges and line/column ranges
3. Ensure deterministic output for a given input
4. Continue parsing even with errors, returning diagnostics

### 3.2 Non-Functional Requirements

1. Deterministic across platforms (macOS/Linux)
2. No additional dependencies
3. Minimal performance overhead (<5% parse time)
4. Memory usage proportional to number of links

### 3.3 Acceptance Criteria per Task

- **2.0.1:** `LinkSpan` compiles and is serializable
- **2.1.1:** Heuristic test cases pass
- **2.1.2:** Link spans produced with correct ranges
- **2.2.1:** Parse errors yield partial AST + diagnostics
- **2.3.1:** Tests pass, including UTF-8 cases

---

## 4. User Interaction Flow (Editor Perspective)

1. Editor calls `EditorParser.parse(fileURL)`
2. EditorEngine returns `ParsedFile` containing:
   - `ast`
   - `linkSpans`
   - `diagnostics`
3. Editor renders clickable links using `linkSpans`
4. Diagnostics are surfaced inline

---

## 5. Edge Cases & Failure Scenarios

- UTF-8 multibyte characters before/inside links
- Links adjacent to punctuation or markdown formatting
- Multiple links in a single line
- Malformed indentation causing parse errors
- Files with mixed line endings (`\n`, `\r\n`)

---

## 6. Verification Plan

### Mandatory

```bash
./.github/scripts/restore-build-cache.sh
swift test 2>&1
```

### Additional Checks

- `rg "LinkSpan" Sources/EditorEngine` to confirm type
- `rg "looksLikeFileReference" Sources` to confirm heuristic

---

## 7. Quality Checklist

- [ ] Link span ranges verified with UTF-8 test cases
- [ ] Parser output unchanged for non-link AST
- [ ] No new dependencies introduced
- [ ] Deterministic behavior across platforms
- [ ] Diagnostics returned on parse errors

---

## 8. Implementation Notes / Templates

### 8.1 Proposed Types

```swift
public struct LinkSpan: Sendable, Equatable {
    public let path: String
    public let byteRange: Range<Int>
    public let startLine: Int
    public let startColumn: Int
    public let endLine: Int
    public let endColumn: Int
    public let sourceFile: String
}
```

### 8.2 Parser Output Extension

```swift
public struct ParsedFile {
    public let ast: AST
    public let linkSpans: [LinkSpan]
    public let diagnostics: [Diagnostic]
}
```

---

## 9. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Incorrect UTF-8 offsets | Broken editor navigation | Add explicit UTF-8 tests and helpers |
| Overly broad heuristic | False positives | Tighten heuristic with suffix checks and path rules |
| Parser changes regress CLI | Build/test in CI, keep AST unchanged |

