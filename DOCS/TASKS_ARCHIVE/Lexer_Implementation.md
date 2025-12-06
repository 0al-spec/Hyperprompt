# PRD: Lexer Implementation

**Task ID:** Lexer Implementation
**Priority:** P0 (Critical)
**Phase:** Phase 2: Lexer & Parser (Core Compilation)
**Effort:** 6 hours
**Dependencies:** A2 (Core Types Implementation) ✅
**Status:** Planning Complete — Ready for Implementation
**Date:** December 5, 2025

---

## 1. Objective

Implement the **Lexer** component for the Hyperprompt Compiler v0.1, which performs line-by-line tokenization of Hypercode (.hc) source files. The lexer transforms raw text into a stream of classified tokens (blank, comment, node) that the Parser module will use for AST construction.

### 1.1 Success Criteria

- [ ] Lexer correctly tokenizes all valid Hypercode inputs from test corpus (V01-V14)
- [ ] Lexer rejects invalid inputs with appropriate syntax errors (I01, I02, I03)
- [ ] Line ending normalization works correctly (CRLF, CR, LF → LF)
- [ ] Indentation validation catches all forbidden patterns (tabs, misalignment)
- [ ] Single-line content constraint enforced for all literals
- [ ] Error messages include source location (file path + line number)
- [ ] Test coverage ≥90% for lexer module

---

## 2. Scope and Intent

### 2.1 In Scope

**Core Functionality:**
- Line-by-line reading with UTF-8 encoding
- Line ending normalization (CRLF/CR → LF)
- Token classification (blank, comment, node)
- Indentation extraction and validation
- Literal content extraction (between quotes)
- Single-line content enforcement
- Tab rejection in indentation
- Source location tracking for diagnostics

**Integration with SpecificationCore:**
- Use `RawLine`, `LineKind`, `ParsedLine` domain types
- Integrate `LineKindDecision` for classification
- Apply atomic specifications for validation (`NoTabsIndentSpec`, `IndentMultipleOf4Spec`)

**Error Handling:**
- Syntax errors with exit code 2
- Meaningful error messages with source context
- Line number and file path in all diagnostics

### 2.2 Out of Scope

- AST construction (handled by Parser in separate task A4)
- Depth validation (enforced during parsing, not lexing)
- File reference resolution (Resolver module, Phase 4)
- Circular dependency detection (Resolver module)
- Manifest generation (Manifest module, Phase 5)

### 2.3 Constraints

- UTF-8 encoding only, no BOM
- Maximum line length: reasonable (no hard limit, but must fit in memory)
- Tabs forbidden in indentation → **exit code 2**
- Indentation must be multiple of 4 spaces → **exit code 2**
- Literals must be single-line (no \n or \r) → **exit code 2**
- Unclosed quotes → **exit code 2**

### 2.4 Assumptions

- Input files exist and are readable (validated by caller)
- Core module (A2) provides `SourceLocation`, `CompilerError`, `FileSystem`
- HypercodeGrammar module provides specifications (if not yet available, fallback to imperative validation)

---

## 3. Requirements

### 3.1 Functional Requirements

#### FR-1: File Reading with Encoding
**Priority:** High
**Input:** File path (String)
**Process:** Read file content as UTF-8, split into lines
**Output:** Array of strings (raw lines)
**Acceptance Criteria:**
- Read UTF-8 files without BOM
- Handle empty files (return empty array)
- Handle files without trailing newline
- Report IO errors with meaningful diagnostics

#### FR-2: Line Ending Normalization
**Priority:** High
**Input:** Raw file content (String)
**Process:** Replace CRLF (\r\n) and CR (\r) with LF (\n)
**Output:** Normalized string
**Acceptance Criteria:**
- CRLF (\r\n) → LF (\n)
- CR (\r) → LF (\n)
- LF (\n) unchanged
- Line numbers match normalized line count
- Normalization occurs before tokenization

#### FR-3: Blank Line Recognition
**Priority:** High
**Input:** Line text (String)
**Process:** Check if line contains only space characters (U+0020)
**Output:** Token.blank
**Acceptance Criteria:**
- Empty line (length 0) → blank
- Line with only spaces → blank
- Line with tabs → NOT blank (tabs forbidden)
- Line with any other character → NOT blank

#### FR-4: Comment Line Recognition
**Priority:** High
**Input:** Line text (String)
**Process:** Check if line starts with `#` after optional indentation
**Output:** Token.comment(indent: Int)
**Acceptance Criteria:**
- Line starting with `#` (no indent) → comment
- Line with spaces followed by `#` → comment
- Extract indentation level (spaces / 4)
- Reject tabs in comment indentation → syntax error

#### FR-5: Node Line Recognition
**Priority:** High
**Input:** Line text (String)
**Process:** Check for quoted literal on single line
**Output:** Token.node(indent: Int, literal: String)
**Acceptance Criteria:**
- Must start with `"` (after optional indent)
- Must end with `"` on same line
- Extract literal content (between quotes)
- Extract indentation level (spaces before quote)
- Reject unclosed quotes → syntax error
- Reject multi-line literals (containing \n or \r) → syntax error

#### FR-6: Indentation Extraction
**Priority:** High
**Input:** Line text (String)
**Process:** Count leading spaces
**Output:** Indent count (Int)
**Acceptance Criteria:**
- Count consecutive spaces from line start
- Stop at first non-space character
- Return count (not depth — depth = count / 4, computed by Parser)
- Empty lines have indent = 0

#### FR-7: Indentation Validation
**Priority:** High
**Input:** Line text (String)
**Process:** Validate indentation rules
**Output:** Pass/Fail with error details
**Acceptance Criteria:**
- **No tabs allowed:** Any tab character → SyntaxError, exit 2
- **Multiple of 4:** Indent count % 4 must equal 0 → else SyntaxError, exit 2
- Apply only to semantic lines (node, comment), not blank lines
- Error message includes line number, file path, actual indent count

#### FR-8: Literal Extraction
**Priority:** High
**Input:** Line text (String)
**Process:** Extract content between quotes
**Output:** Literal string (no quotes)
**Acceptance Criteria:**
- Remove leading indentation
- Remove opening `"`
- Remove closing `"`
- Return content between quotes
- Handle escaped quotes (e.g., `\"` inside literal)
- Preserve all other characters (spaces, special chars, Unicode)

#### FR-9: Single-Line Content Enforcement
**Priority:** High
**Input:** Literal content (String)
**Process:** Verify no line breaks (\n, \r, \r\n)
**Output:** Pass/Fail with error details
**Acceptance Criteria:**
- Reject literals containing `\n` → SyntaxError, exit 2
- Reject literals containing `\r` → SyntaxError, exit 2
- Reject literals containing `\r\n` → SyntaxError, exit 2
- Error message shows offending line

#### FR-10: Source Location Tracking
**Priority:** High
**Input:** File path, line index
**Process:** Create SourceLocation for each token
**Output:** SourceLocation(file: String, line: Int)
**Acceptance Criteria:**
- Track 1-based line numbers (not 0-based array indices)
- Associate every token with source location
- Include location in all error diagnostics
- Maintain location consistency after normalization

### 3.2 Non-Functional Requirements

#### NFR-1: Performance
- Tokenize 1000-line file in < 100ms on dev hardware
- Linear time complexity: O(n) where n = line count
- Avoid redundant passes over input

#### NFR-2: Memory Efficiency
- Stream processing preferred (don't load entire file into memory if possible)
- Token array size proportional to input size
- No memory leaks

#### NFR-3: Error Diagnostics Quality
- Every error includes source location
- Error messages clearly state the problem
- Suggest fixes when applicable (e.g., "Use 4 spaces instead of tabs")
- Format: `<file>:<line>: error: <message>`

#### NFR-4: Testability
- Lexer can be tested in isolation (no file system dependencies via MockFileSystem)
- Unit tests for each token type (blank, comment, node)
- Integration tests with sample .hc files
- Test coverage ≥90%

#### NFR-5: Maintainability
- Clear separation: file reading → normalization → classification → validation
- Specifications used where applicable (if HypercodeGrammar available)
- Well-documented functions with examples
- No magic numbers (use named constants)

---

## 4. Design Overview

### 4.1 Module Structure

```
Module_Parser/
├── Lexer.swift              # Main lexer class
├── Token.swift              # Token enum definition
├── LexerError.swift         # Lexer-specific errors
└── Tests/
    ├── LexerTests.swift     # Unit tests
    └── LexerIntegrationTests.swift
```

### 4.2 Data Structures

#### Token (Lexer Output)

```swift
enum Token {
    case blank
    case comment(indent: Int)
    case node(indent: Int, literal: String)
}
```

#### Lexer Class

```swift
final class Lexer {
    private let fileSystem: FileSystem
    private let maxDepth: Int  // For depth spec (optional integration)

    init(fileSystem: FileSystem = LocalFileSystem(), maxDepth: Int = 10)

    func tokenize(_ filePath: String) throws -> [Token]

    // Internal helpers
    private func readLines(_ filePath: String) throws -> [String]
    private func normalizeLine(_ line: String) -> String
    private func classifyLine(_ rawLine: RawLine) throws -> Token?
    private func extractIndent(_ line: String) -> Int
    private func extractLiteral(_ line: String) throws -> String
    private func validateIndentation(_ line: String, lineNumber: Int, filePath: String) throws
}
```

### 4.3 Algorithm

```
tokenize(filePath):
    1. Read file content with UTF-8 encoding
    2. Normalize line endings (CRLF/CR → LF)
    3. Split into lines
    4. For each line with index:
        a. Create RawLine(text, lineNumber, filePath)
        b. Classify line → Token? (blank, comment, node)
        c. If node: validate indentation, extract literal
        d. Append token to result
    5. Return token array
```

**Line Classification Algorithm:**

```
classifyLine(rawLine):
    1. Check if blank (only spaces)
       → return Token.blank

    2. Check if comment (starts with # after indent)
       → validate indent (no tabs, multiple of 4)
       → return Token.comment(indent)

    3. Check if node (starts with " after indent)
       → validate indent (no tabs, multiple of 4)
       → validate closing quote exists
       → extract literal content
       → validate single-line (no \n, \r)
       → return Token.node(indent, literal)

    4. None matched → throw SyntaxError(unknownLineKind)
```

---

## 5. Implementation Plan

### 5.1 Task Breakdown

#### Task L1: Setup Lexer Structure
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** None
**Steps:**
- [ ] Create `Sources/Module_Parser/Lexer.swift`
- [ ] Create `Sources/Module_Parser/Token.swift`
- [ ] Create `Sources/Module_Parser/LexerError.swift`
- [ ] Create test file structure
- [ ] Import Core module for SourceLocation, CompilerError
**Acceptance:** Files created, project builds

#### Task L2: Implement File Reading
**Priority:** High
**Effort:** 45 minutes
**Dependencies:** L1
**Steps:**
- [ ] Implement `readLines(_ filePath:) throws -> [String]`
- [ ] Use `FileSystem` protocol for abstraction
- [ ] Handle UTF-8 decoding
- [ ] Handle file not found, permission errors
- [ ] Write unit tests for file reading
**Acceptance:** Can read .hc files, tests pass

#### Task L3: Implement Line Ending Normalization
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** L2
**Steps:**
- [ ] Implement `normalizeLine(_ line:) -> String`
- [ ] Replace `\r\n` → `\n`
- [ ] Replace `\r` → `\n`
- [ ] Write unit tests for all line ending types
**Acceptance:** All line endings normalized to LF, tests pass

#### Task L4: Implement Blank Line Classification
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** L3
**Steps:**
- [ ] Implement `isBlankLine(_ line:) -> Bool`
- [ ] Check if line contains only spaces or is empty
- [ ] Write unit tests for blank line detection
**Acceptance:** Blank lines correctly identified, tests pass

#### Task L5: Implement Comment Line Classification
**Priority:** High
**Effort:** 45 minutes
**Dependencies:** L4
**Steps:**
- [ ] Implement `isCommentLine(_ line:) -> Bool`
- [ ] Check for `#` after optional spaces
- [ ] Extract indentation
- [ ] Validate indentation (no tabs, multiple of 4)
- [ ] Write unit tests for comment lines
**Acceptance:** Comments correctly identified, tests pass

#### Task L6: Implement Node Line Classification
**Priority:** High
**Effort:** 1 hour
**Dependencies:** L5
**Steps:**
- [ ] Implement `isNodeLine(_ line:) -> Bool`
- [ ] Check for opening `"`
- [ ] Check for closing `"` on same line
- [ ] Extract indentation
- [ ] Extract literal content
- [ ] Validate indentation (no tabs, multiple of 4)
- [ ] Write unit tests for node lines
**Acceptance:** Nodes correctly identified, tests pass

#### Task L7: Implement Indentation Validation
**Priority:** High
**Effort:** 45 minutes
**Dependencies:** L6
**Steps:**
- [ ] Implement `validateIndentation(_ line:, lineNumber:, filePath:) throws`
- [ ] Check for tabs → throw SyntaxError
- [ ] Check for alignment (count % 4 == 0) → throw SyntaxError
- [ ] Include line number and file path in errors
- [ ] Write unit tests for indentation errors
**Acceptance:** Invalid indentation rejected with clear errors, tests pass

#### Task L8: Implement Literal Extraction
**Priority:** High
**Effort:** 45 minutes
**Dependencies:** L6
**Steps:**
- [ ] Implement `extractLiteral(_ line:) throws -> String`
- [ ] Remove leading spaces
- [ ] Remove opening `"`
- [ ] Remove closing `"`
- [ ] Handle escaped quotes (optional, document decision)
- [ ] Write unit tests for literal extraction
**Acceptance:** Literals correctly extracted, tests pass

#### Task L9: Implement Single-Line Enforcement
**Priority:** High
**Effort:** 30 minutes
**Dependencies:** L8
**Steps:**
- [ ] Check literal for `\n` → throw SyntaxError
- [ ] Check literal for `\r` → throw SyntaxError
- [ ] Check literal for `\r\n` → throw SyntaxError
- [ ] Write unit tests for multi-line literals
**Acceptance:** Multi-line literals rejected, tests pass

#### Task L10: Integrate Specifications (Optional)
**Priority:** Medium
**Effort:** 1 hour
**Dependencies:** L9, HypercodeGrammar module available
**Steps:**
- [ ] Import HypercodeGrammar module
- [ ] Use `LineKindDecision` for classification
- [ ] Use `NoTabsIndentSpec`, `IndentMultipleOf4Spec`
- [ ] Refactor classification logic to use specs
- [ ] Verify all tests still pass
**Acceptance:** Specifications integrated, tests pass, <10% performance overhead

#### Task L11: Write Lexer Integration Tests
**Priority:** High
**Effort:** 1 hour
**Dependencies:** L9
**Steps:**
- [ ] Create 20+ test .hc files (valid and invalid)
- [ ] Test V01: Single root node with inline text
- [ ] Test V11: Comment lines interspersed
- [ ] Test V12: Blank lines between node groups
- [ ] Test I01: Tab characters in indentation
- [ ] Test I02: Misaligned indentation (not divisible by 4)
- [ ] Test I03: Unclosed quotation mark
- [ ] Verify correct token streams for valid inputs
- [ ] Verify correct errors for invalid inputs
**Acceptance:** All integration tests pass

#### Task L12: Documentation and Cleanup
**Priority:** Medium
**Effort:** 30 minutes
**Dependencies:** L11
**Steps:**
- [ ] Add doc comments to public API
- [ ] Document algorithm and design decisions
- [ ] Add usage examples
- [ ] Clean up dead code
- [ ] Run linter and fix warnings
**Acceptance:** Code documented, linter clean

---

## 6. Testing Strategy

### 6.1 Unit Tests

**Test Coverage Targets:**
- Line classification: 100%
- Indentation validation: 100%
- Literal extraction: 100%
- Error handling: 100%
- Overall lexer: ≥90%

**Unit Test Cases:**

| Test Case | Input | Expected Output | Error Type |
|-----------|-------|-----------------|------------|
| `testEmptyLine` | `""` | `Token.blank` | None |
| `testLineWithSpaces` | `"    "` | `Token.blank` | None |
| `testCommentLine` | `"# comment"` | `Token.comment(indent: 0)` | None |
| `testCommentWithIndent` | `"    # comment"` | `Token.comment(indent: 4)` | None |
| `testSimpleNode` | `"\"literal\""` | `Token.node(indent: 0, literal: "literal")` | None |
| `testNodeWithIndent` | `"    \"literal\""` | `Token.node(indent: 4, literal: "literal")` | None |
| `testTabIndent` | `"\t\"literal\""` | Exception | `SyntaxError.tabInIndentation` |
| `testMisalignedIndent` | `"  \"literal\""` | Exception | `SyntaxError.misalignedIndentation` |
| `testUnclosedQuote` | `"\"unclosed"` | Exception | `SyntaxError.unclosedQuote` |
| `testMultilineLiteral` | `"\"line1\nline2\""` | Exception | `SyntaxError.multilineLiteral` |
| `testCRLFNormalization` | `"\"text\"\r\n"` | `Token.node(...)` | None |
| `testCRNormalization` | `"\"text\"\r"` | `Token.node(...)` | None |

### 6.2 Integration Tests

**Test Files:**
- `valid-simple.hc`: Single node, no indent
- `valid-nested.hc`: Multiple nodes with indentation
- `valid-comments.hc`: Comments interspersed
- `valid-blank-lines.hc`: Blank lines between groups
- `invalid-tab.hc`: Tab in indentation
- `invalid-misaligned.hc`: 2-space indent
- `invalid-unclosed.hc`: Unclosed quote
- `invalid-multiline.hc`: Literal with \n

**Integration Test Template:**

```swift
func testValidFile() throws {
    let lexer = Lexer()
    let tokens = try lexer.tokenize("Tests/Fixtures/valid-simple.hc")

    XCTAssertEqual(tokens.count, 1)

    guard case .node(let indent, let literal) = tokens[0] else {
        XCTFail("Expected node token")
        return
    }

    XCTAssertEqual(indent, 0)
    XCTAssertEqual(literal, "Root")
}

func testInvalidTab() {
    let lexer = Lexer()

    XCTAssertThrowsError(try lexer.tokenize("Tests/Fixtures/invalid-tab.hc")) { error in
        guard case LexerError.tabInIndentation = error else {
            XCTFail("Expected tabInIndentation error")
            return
        }
    }
}
```

### 6.3 Performance Tests

```swift
func testPerformanceLargeFile() {
    // Generate 1000-line file
    let lines = (0..<1000).map { "    \"Line \($0)\"" }.joined(separator: "\n")
    let tempFile = createTempFile(content: lines)

    let lexer = Lexer()

    measure {
        _ = try? lexer.tokenize(tempFile)
    }
}
```

**Performance Target:** 1000-line file tokenized in < 100ms

---

## 7. Error Scenarios

### 7.1 Syntax Errors (Exit Code 2)

| Error | Condition | Message Format |
|-------|-----------|----------------|
| `tabInIndentation` | Tab character in leading whitespace | `<file>:<line>: error: Tab characters not allowed in indentation. Use spaces instead.` |
| `misalignedIndentation` | Indent count % 4 ≠ 0 | `<file>:<line>: error: Indentation must be multiple of 4 spaces. Found <count> spaces.` |
| `unclosedQuote` | Opening `"` without closing `"` | `<file>:<line>: error: Unclosed quotation mark. Literals must be enclosed in double quotes.` |
| `multilineLiteral` | Literal contains \n or \r | `<file>:<line>: error: Literal content cannot span multiple lines.` |
| `unknownLineKind` | Line matches no classification | `<file>:<line>: error: Invalid syntax. Expected blank line, comment, or quoted literal.` |

### 7.2 IO Errors (Exit Code 1)

| Error | Condition | Message Format |
|-------|-----------|----------------|
| `fileNotFound` | File does not exist | `error: File not found: <path>` |
| `permissionDenied` | No read permission | `error: Permission denied: <path>` |
| `encodingError` | Not valid UTF-8 | `<file>: error: File is not valid UTF-8.` |

---

## 8. Edge Cases

### 8.1 Edge Case Catalog

| Edge Case | Expected Behavior |
|-----------|-------------------|
| Empty file | Return empty token array, no error |
| File with only blank lines | Return array of `Token.blank`, no error |
| File with only comments | Return array of `Token.comment(...)`, no error |
| File without trailing newline | Process last line normally |
| Very long line (>10KB) | Process normally (no hard limit) |
| Unicode in literals | Preserve exactly, no encoding changes |
| Quote inside literal (escaped) | Decide: support `\"` or forbid? Document decision. |
| Literal with only spaces | Valid: `"    "` → literal = `"    "` |
| Node with empty literal | Valid: `""` → literal = `""` |
| Mixed line endings (LF + CRLF) | Normalize all to LF |

### 8.2 Design Decisions

#### Decision: Escaped Quotes

**Options:**
1. Support `\"` inside literals (require escape parsing)
2. Forbid `"` inside literals (simpler lexer)

**Recommendation:** **Option 2 (Forbid)** for v0.1
- Simpler lexer implementation
- No escape parsing needed
- Literals are file references or inline text, not code (no escaping needed)
- Can add in v0.2 if user demand

**Documented in:** PRD §5.2, Design Spec §4.1

---

## 9. Dependencies

### 9.1 Required Modules

- **Core Module (A2):** ✅ Completed
  - `SourceLocation`: For error diagnostics
  - `CompilerError`: For error protocol
  - `FileSystem`: For file I/O abstraction
  - `LocalFileSystem`, `MockFileSystem`: Implementations

### 9.2 Optional Modules

- **HypercodeGrammar Module:** ⚠️ Not yet implemented (Phase 3)
  - `RawLine`, `LineKind`, `ParsedLine`: Domain types
  - `LineKindDecision`: Classification via FirstMatchSpec
  - `NoTabsIndentSpec`, `IndentMultipleOf4Spec`: Validation specs
  - **Fallback:** Use imperative validation if not available

---

## 10. Acceptance Checklist

### 10.1 Functional Acceptance

- [ ] Lexer tokenizes all valid test files (V01-V14)
- [ ] Lexer rejects all invalid test files with correct errors (I01-I03)
- [ ] Line ending normalization works (CRLF, CR, LF)
- [ ] Blank lines correctly classified
- [ ] Comments correctly classified
- [ ] Nodes correctly classified
- [ ] Indentation extracted correctly
- [ ] Literals extracted correctly (between quotes)
- [ ] Tabs rejected with SyntaxError
- [ ] Misalignment rejected with SyntaxError
- [ ] Unclosed quotes rejected with SyntaxError
- [ ] Multi-line literals rejected with SyntaxError

### 10.2 Quality Acceptance

- [ ] Test coverage ≥90%
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Performance test: 1000 lines < 100ms
- [ ] No memory leaks (verify with Instruments)
- [ ] Linter clean (no warnings)
- [ ] Code reviewed by peer

### 10.3 Documentation Acceptance

- [ ] Public API documented with doc comments
- [ ] Algorithm documented in code
- [ ] Design decisions documented
- [ ] Usage examples provided
- [ ] Error messages are clear and actionable

---

## 11. Implementation Notes

### 11.1 Line Ending Normalization Strategy

Normalize CRLF/CR → LF **before** tokenization:

```swift
func normalizeLine(_ line: String) -> String {
    line.replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\r", with: "\n")
}
```

**Rationale:** Simplifies lexer logic by guaranteeing LF line endings internally.

### 11.2 Indentation Validation Strategy

Validate indentation for **semantic lines only** (node, comment), not blank lines:

```swift
func validateIndentation(_ line: String, lineNumber: Int, filePath: String) throws {
    let indent = line.prefix(while: { $0 == " " || $0 == "\t" })

    // Check for tabs
    guard !indent.contains("\t") else {
        throw LexerError.tabInIndentation(
            location: SourceLocation(file: filePath, line: lineNumber)
        )
    }

    // Check for alignment
    let spaceCount = indent.filter { $0 == " " }.count
    guard spaceCount % 4 == 0 else {
        throw LexerError.misalignedIndentation(
            location: SourceLocation(file: filePath, line: lineNumber),
            actualIndent: spaceCount
        )
    }
}
```

### 11.3 Literal Extraction Strategy

Extract content between quotes, preserving all characters:

```swift
func extractLiteral(_ line: String) throws -> String {
    let trimmedLeft = line.drop(while: { $0 == " " })

    guard trimmedLeft.first == "\"" else {
        throw LexerError.invalidNodeSyntax(...)
    }

    guard let closingQuoteIndex = trimmedLeft.dropFirst().firstIndex(of: "\"") else {
        throw LexerError.unclosedQuote(...)
    }

    let literal = String(trimmedLeft.dropFirst().prefix(upTo: closingQuoteIndex))

    // Validate single-line
    guard !literal.contains("\n") && !literal.contains("\r") else {
        throw LexerError.multilineLiteral(...)
    }

    return literal
}
```

---

## 12. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-05 | Claude (PRD Generator) | Initial PRD creation from PLAN command |

---

## 13. References

- **PRD v0.0.1:** `DOCS/PRD/v0.0.1/00_PRD_001.md` — Product requirements
- **Design Spec v0.0.1:** `DOCS/PRD/v0.0.1/01_DESIGN_SPEC_001.md` — Architecture §4.1 (Parsing Algorithm)
- **SpecificationCore Integration:** `DOCS/PRD/v0.0.1/02_DESIGN_SPEC_SPECIFICATION_CORE.md` — §7.1 (Lexer Integration)
- **Workplan v2.0.0:** `DOCS/Workplan.md` — Phase 2, Lexer Implementation

---

**Status:** ✅ Planning Complete — Ready to begin implementation with Task L1

---

**Archived:** 2025-12-06
