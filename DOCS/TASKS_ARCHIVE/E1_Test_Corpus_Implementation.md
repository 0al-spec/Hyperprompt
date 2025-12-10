# Task E1 — Test Corpus Implementation

**Task ID:** E1
**Task Name:** Test Corpus Implementation
**Priority:** P0 (Critical)
**Phase:** Phase 8 — Testing & Quality Assurance
**Estimated Effort:** 8 hours
**Dependencies:** D2 (Compiler Driver ✅)
**Status:** Selected for Implementation

---

## 1. Objective

Implement comprehensive test corpus covering all 24 specified test cases (V01-V14 valid inputs, I01-I10 invalid inputs) with golden file comparison framework. Achieve >80% code coverage across the compiler codebase to ensure robustness and correctness before v0.1 release.

**Primary Deliverable:** A production-ready test suite that:
- Validates all valid input scenarios produce correct Markdown and manifest output
- Verifies all invalid input scenarios fail with appropriate errors and exit codes
- Provides golden file comparison infrastructure for regression testing
- Achieves comprehensive code coverage across all compiler modules

---

## 2. Scope and Intent

### 2.1 In Scope

**Test Fixtures:**
- All 14 valid input test cases (V01-V14) with `.hc` source files
- All 10 invalid input test cases (I01-I10) with `.hc` source files
- Golden files (`.expected.md`, `.expected.json`) for each valid test
- Error pattern files for each invalid test

**Test Infrastructure:**
- Golden file comparison framework for Markdown output
- JSON manifest comparison with sorted key normalization
- Exit code verification for all error scenarios
- Test helper utilities for file creation and cleanup

**Test Coverage:**
- Integration tests for end-to-end compilation
- Edge case coverage (max depth, Unicode, circular dependencies)
- Error handling coverage (all error categories: syntax, resolution, IO, internal)
- Cross-module coverage (Parser, Resolver, Emitter, Manifest Generator, CompilerDriver)

**Code Quality:**
- >80% code coverage across all modules
- Coverage report generation
- Identification of untested code paths

### 2.2 Out of Scope

**Deferred to Future Tasks:**
- Performance benchmarking tests (task E3 or later)
- Cross-platform testing automation (task E2)
- Fuzzing and property-based testing (future phases)
- UI/visual regression testing (not applicable)

**Explicitly Not Included:**
- Mutation testing
- Security penetration testing
- Load/stress testing
- Memory leak detection (covered by Swift's ARC)

### 2.3 Assumptions

- CompilerDriver (D2) is fully functional and integrated
- All pipeline components (Parser, Resolver, Emitter, ManifestGenerator) are working
- Test fixtures can reference external files (for V04-V07 file reference tests)
- Swift Package Manager test infrastructure is available

### 2.4 Constraints

**Technical Constraints:**
- Tests must run in deterministic order (no flaky tests)
- Tests must be platform-independent (macOS, Linux, Windows)
- Tests must not require network access or external resources
- Tests must complete in <60 seconds total runtime

**Operational Constraints:**
- Test fixtures must be small (<10KB each) for fast execution
- Golden files must be stored in Git (no LFS for small test files)
- Test directory structure must match Swift Package Manager conventions

---

## 3. Functional Requirements

### 3.1 Valid Input Tests (V01-V14)

#### FR-V01: Single Root Node with Inline Text

**Input:** `V01.hc`
```hypercode
"Root Node"
```

**Expected Output:** `V01.expected.md`
```markdown
# Root Node
```

**Expected Manifest:** `V01.expected.json`
```json
{
  "version": "0.1.0",
  "rootFile": "V01.hc",
  "entries": []
}
```

**Verification:**
- Markdown output matches golden file (byte-for-byte)
- Manifest JSON matches golden file (key-sorted comparison)
- Exit code 0
- No errors or warnings

**Status:** ✅ Partially implemented (fixture exists, needs golden files)

---

#### FR-V03: Nested Hierarchy (3 Levels Deep)

**Input:** `V03.hc`
```hypercode
"Level 0"
    "Level 1"
        "Level 2"
```

**Expected Output:** `V03.expected.md`
```markdown
# Level 0
## Level 1
#### Level 2
```

**Expected Manifest:** `V03.expected.json`
```json
{
  "version": "0.1.0",
  "rootFile": "V03.hc",
  "entries": []
}
```

**Verification:**
- Three-level heading structure (H1, H2, H4 — note skip from H2 to H4)
- Correct depth-to-heading mapping
- Exit code 0

**Status:** ✅ Partially implemented (fixture exists, needs golden files)

---

#### FR-V04: Single Markdown File Reference

**Input:** `V04.hc`
```hypercode
"main_goals.md"
```

**Referenced File:** `main_goals.md`
```markdown
# Project Goals

- Complete compiler v0.1
- Achieve 80% test coverage
```

**Expected Output:** `V04.expected.md`
```markdown
# Project Goals

- Complete compiler v0.1
- Achieve 80% test coverage
```

**Expected Manifest:** `V04.expected.json`
```json
{
  "version": "0.1.0",
  "rootFile": "V04.hc",
  "entries": [
    {
      "path": "main_goals.md",
      "type": "markdown",
      "sha256": "...",
      "size": 67
    }
  ]
}
```

**Verification:**
- Markdown file content embedded without extra heading levels
- Manifest contains entry for `main_goals.md` with correct SHA256
- Exit code 0

**Status:** ⏸️ Not implemented

---

#### FR-V05: Nested Markdown File References

**Input:** `V05.hc`
```hypercode
"Overview"
    "details/summary.md"
```

**Referenced File:** `details/summary.md`
```markdown
## Summary

This section provides details.
```

**Expected Output:** `V05.expected.md`
```markdown
# Overview
## Summary

This section provides details.
```

**Verification:**
- Nested Markdown file embedded at correct depth
- Heading levels NOT adjusted (embedded as-is)
- Manifest contains `details/summary.md` entry
- Exit code 0

**Status:** ⏸️ Not implemented

---

#### FR-V06: Single Hypercode File Reference

**Input:** `V06.hc`
```hypercode
"template.hc"
```

**Referenced File:** `template.hc`
```hypercode
"Template Content"
    "Nested Item"
```

**Expected Output:** `V06.expected.md`
```markdown
# Template Content
## Nested Item
```

**Expected Manifest:** `V06.expected.json`
```json
{
  "version": "0.1.0",
  "rootFile": "V06.hc",
  "entries": [
    {
      "path": "template.hc",
      "type": "hypercode",
      "sha256": "...",
      "size": 43
    }
  ]
}
```

**Verification:**
- Recursive Hypercode compilation works
- Nested .hc file AST merged correctly
- Manifest contains template.hc entry
- Exit code 0

**Status:** ⏸️ Not implemented

---

#### FR-V07: Nested Hypercode Files (3 Levels)

**Input:** `V07.hc`
```hypercode
"Root"
    "level1.hc"
```

**Referenced File:** `level1.hc`
```hypercode
"Level 1"
    "level2.hc"
```

**Referenced File:** `level2.hc`
```hypercode
"Level 2"
```

**Expected Output:** `V07.expected.md`
```markdown
# Root
## Level 1
### Level 2
```

**Expected Manifest:** Contains entries for both `level1.hc` and `level2.hc`

**Verification:**
- Three-level nested .hc compilation
- Correct depth propagation through nested files
- Manifest contains all referenced .hc files
- Exit code 0

**Status:** ⏸️ Not implemented

---

#### FR-V08: Mixed Inline Text and File References

**Input:** `V08.hc`
```hypercode
"Introduction"
    "Inline text node"
    "details.md"
    "Another inline node"
```

**Referenced File:** `details.md`
```markdown
## Details Section
```

**Expected Output:** `V08.expected.md`
```markdown
# Introduction
## Inline text node
## Details Section
## Another inline node
```

**Verification:**
- Inline text and file references can coexist at same depth
- Order preserved in output
- Exit code 0

**Status:** ⏸️ Not implemented

---

#### FR-V09: Markdown with Headings H1-H4

**Input:** `V09.hc`
```hypercode
"headings.md"
```

**Referenced File:** `headings.md`
```markdown
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
```

**Expected Output:** `V09.expected.md`
```markdown
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
```

**Verification:**
- ATX-style headings (# syntax) preserved
- Heading levels NOT adjusted when embedding at root
- Exit code 0

**Status:** ⏸️ Not implemented

---

#### FR-V10: Markdown with Setext Headings

**Input:** `V10.hc`
```hypercode
"setext.md"
```

**Referenced File:** `setext.md`
```markdown
Heading Level 1
===============

Heading Level 2
---------------
```

**Expected Output:** `V10.expected.md`
```markdown
# Heading Level 1

## Heading Level 2
```

**Verification:**
- Setext-style headings converted to ATX style
- H1 (===) → # H1
- H2 (---) → ## H2
- Exit code 0

**Status:** ⏸️ Not implemented

---

#### FR-V11: Comment Lines Interspersed

**Input:** `V11.hc`
```hypercode
# This is a comment
"Node 1"
# Another comment
    "Node 2"
# Final comment
```

**Expected Output:** `V11.expected.md`
```markdown
# Node 1
## Node 2
```

**Verification:**
- Comments ignored during parsing
- Comments do NOT appear in output
- Exit code 0

**Status:** ⏸️ Not implemented

---

#### FR-V12: Blank Lines Between Node Groups

**Input:** `V12.hc`
```hypercode
"Group 1"

"Group 2"
    "Child of Group 2"

```

**Expected Output:** `V12.expected.md`
```markdown
# Group 1
# Group 2
## Child of Group 2
```

**Verification:**
- Blank lines ignored during parsing
- Multiple roots NOT allowed (parser should fail — this test may be invalid)
- Exit code 0 OR exit code 2 (depending on interpretation)

**Note:** This test may conflict with single-root requirement. Need clarification from PRD.

**Status:** ⏸️ Not implemented (requires design decision)

---

#### FR-V13: Maximum Depth of 10 Levels

**Input:** `V13.hc`
```hypercode
"Level 0"
    "Level 1"
        "Level 2"
            "Level 3"
                "Level 4"
                    "Level 5"
                        "Level 6"
                            "Level 7"
                                "Level 8"
                                    "Level 9"
```

**Expected Output:** `V13.expected.md`
```markdown
# Level 0
## Level 1
### Level 2
#### Level 3
##### Level 4
###### Level 5
###### Level 6
###### Level 7
###### Level 8
###### Level 9
```

**Verification:**
- 10 levels of nesting (depth 0-9)
- Depths 5-9 all map to H6 (Markdown max)
- Exit code 0

**Status:** ⏸️ Not implemented

---

#### FR-V14: Unicode Content

**Input:** `V14.hc`
```hypercode
"Hello 世界 🌍"
    "Привет мир"
        "unicode.md"
```

**Referenced File:** `unicode.md`
```markdown
## Emoji: ✅ ❌ ⚠️
```

**Expected Output:** `V14.expected.md`
```markdown
# Hello 世界 🌍
## Привет мир
## Emoji: ✅ ❌ ⚠️
```

**Verification:**
- UTF-8 encoding preserved throughout pipeline
- Chinese, Cyrillic, emoji handled correctly
- Exit code 0

**Status:** ⏸️ Not implemented

---

### 3.2 Invalid Input Tests (I01-I10)

#### FR-I01: Tab Characters in Indentation

**Input:** `I01.hc`
```hypercode
"Root"
	"Child with tab"
```
(Note: Second line uses tab character, not spaces)

**Expected Behavior:**
- Compilation fails with Syntax Error (exit code 2)
- Error message contains "tab" or "indentation"
- Error location: line 2, column 1

**Verification:**
- Exit code 2
- Error category: `.syntax`
- Error message pattern: `/(tab|TAB|indentation)/i`

**Status:** ✅ Implemented (test passing)

---

#### FR-I02: Misaligned Indentation

**Input:** `I02.hc`
```hypercode
"Root"
  "Two spaces"
```
(Note: Second line uses 2 spaces instead of 0 or 4)

**Expected Behavior:**
- Compilation fails with Syntax Error (exit code 2)
- Error message contains "indent" or "divisible" or "align"
- Error location: line 2

**Verification:**
- Exit code 2
- Error category: `.syntax`
- Error message pattern: `/(indent|divisible|align)/i`

**Status:** ✅ Implemented (test fails on message wording — tech debt)

---

#### FR-I03: Unclosed Quotation Mark

**Input:** `I03.hc`
```hypercode
"Unclosed quote
```
(Note: Missing closing quote)

**Expected Behavior:**
- Compilation fails with Syntax Error (exit code 2)
- Error message contains "quote" or "unclosed" or "EOF"
- Error location: line 1

**Verification:**
- Exit code 2
- Error category: `.syntax`
- Error message pattern: `/(quote|unclosed|EOF)/i`

**Status:** ✅ Implemented (test passing)

---

#### FR-I04: Missing File Reference (Strict Mode)

**Input:** `I04.hc`
```hypercode
"nonexistent.md"
```
(File `nonexistent.md` does not exist)

**Expected Behavior:**
- Compilation fails with Resolution Error (exit code 3)
- Error message contains "not found" or "missing"
- Error location: line 1

**Verification:**
- Exit code 3
- Error category: `.resolution`
- Error message pattern: `/(not found|missing|does not exist)/i`

**Status:** ⏸️ Not implemented

---

#### FR-I05: Direct Circular Dependency

**Input:** `I05.hc`
```hypercode
"circular.hc"
```

**Referenced File:** `circular.hc`
```hypercode
"circular.hc"
```
(File references itself)

**Expected Behavior:**
- Compilation fails with Resolution Error (exit code 3)
- Error message contains "circular" or "cycle"
- Error location: line 1 of circular.hc

**Verification:**
- Exit code 3
- Error category: `.resolution`
- Error message pattern: `/(circular|cycle|dependency)/i`

**Status:** ⏸️ Not implemented

---

#### FR-I06: Indirect Circular Dependency

**Input:** `I06.hc`
```hypercode
"a.hc"
```

**Referenced File:** `a.hc`
```hypercode
"b.hc"
```

**Referenced File:** `b.hc`
```hypercode
"a.hc"
```
(A → B → A cycle)

**Expected Behavior:**
- Compilation fails with Resolution Error (exit code 3)
- Error message contains "circular" or "cycle"
- Error location: line 1 of b.hc

**Verification:**
- Exit code 3
- Error category: `.resolution`
- Error message pattern: `/(circular|cycle|dependency)/i`

**Status:** ⏸️ Not implemented

---

#### FR-I07: Depth Exceeding Maximum (10)

**Input:** `I07.hc`
```hypercode
"L0"
    "L1"
        "L2"
            "L3"
                "L4"
                    "L5"
                        "L6"
                            "L7"
                                "L8"
                                    "L9"
                                        "L10 — EXCEEDS MAX"
```
(11 levels: depth 0-10, exceeds limit of 10)

**Expected Behavior:**
- Compilation fails with Syntax Error (exit code 2)
- Error message contains "depth" or "exceeded" or "maximum"
- Error location: line 11

**Verification:**
- Exit code 2
- Error category: `.syntax`
- Error message pattern: `/(depth|exceeded|maximum|limit)/i`

**Status:** ⏸️ Not implemented

---

#### FR-I08: Path Traversal with ..

**Input:** `I08.hc`
```hypercode
"../etc/passwd"
```

**Expected Behavior:**
- Compilation fails with Resolution Error (exit code 3)
- Error message contains "traversal" or "invalid path" or ".."
- Error location: line 1

**Verification:**
- Exit code 3
- Error category: `.resolution`
- Error message pattern: `/(traversal|invalid path|\.\.)/i`

**Status:** ⏸️ Not implemented

---

#### FR-I09: Unreadable File (Permission Error)

**Input:** `I09.hc`
```hypercode
"unreadable.md"
```

**Referenced File:** `unreadable.md` (exists but chmod 000)

**Expected Behavior:**
- Compilation fails with IO Error (exit code 1)
- Error message contains "permission" or "unreadable"
- Error location: line 1

**Verification:**
- Exit code 1
- Error category: `.io`
- Error message pattern: `/(permission|unreadable|denied)/i`

**Status:** ⏸️ Not implemented

**Note:** May be difficult to test on all platforms (Windows handles permissions differently).

---

#### FR-I10: Multiple Root Nodes

**Input:** `I10.hc`
```hypercode
"Root 1"
"Root 2"
```

**Expected Behavior:**
- Compilation fails with Syntax Error (exit code 2)
- Error message contains "multiple" or "root"
- Error location: line 2

**Verification:**
- Exit code 2
- Error category: `.syntax`
- Error message pattern: `/(multiple|root|only one)/i`

**Status:** ✅ Implemented (test passing)

---

### 3.3 Golden File Comparison Framework

#### FR-GF1: Markdown Golden File Comparison

**Requirement:** Test infrastructure shall compare actual Markdown output to expected golden files.

**Implementation:**
- Byte-for-byte comparison (no normalization)
- Line ending normalization (CRLF/LF handled transparently)
- Diff output on mismatch showing expected vs actual

**Acceptance:**
- `XCTAssertEqual(actualMD, expectedMD, "Output matches golden file")`
- Clear error message showing diff when mismatch occurs

---

#### FR-GF2: Manifest JSON Comparison

**Requirement:** Test infrastructure shall compare actual manifest JSON to expected golden files with key normalization.

**Implementation:**
- Parse both JSON files
- Sort keys alphabetically before comparison
- Compare SHA256 hashes (if present in expected file)
- Ignore order of entries array (sort by path)

**Acceptance:**
- Manifests match after normalization
- SHA256 hashes match (within 1 bit tolerance for floating-point issues)

---

#### FR-GF3: Exit Code Verification

**Requirement:** Test infrastructure shall verify exit codes for all error scenarios.

**Implementation:**
- Capture exit code from compiler driver
- Map error category to expected exit code (0-4)
- Verify error category matches expected

**Acceptance:**
- All valid tests exit with code 0
- All invalid tests exit with correct code (1-4)
- Error categories correctly mapped

---

## 4. Non-Functional Requirements

### NFR-1: Code Coverage

**Requirement:** Test suite shall achieve >80% code coverage across all compiler modules.

**Measurement:**
- Use `swift test --enable-code-coverage`
- Generate coverage report with `xcrun llvm-cov`
- Identify untested code paths

**Acceptance:**
- Overall coverage ≥80%
- All P0 modules (Parser, Resolver, Emitter, ManifestGenerator, CompilerDriver) ≥85%
- No critical paths untested

---

### NFR-2: Test Execution Time

**Requirement:** Full test suite shall complete in <60 seconds.

**Measurement:**
- `swift test --parallel` runtime
- Individual test timeout: 5 seconds

**Acceptance:**
- Total runtime <60s on CI hardware
- No single test >5s
- Tests parallelizable (no shared state)

---

### NFR-3: Test Determinism

**Requirement:** Tests shall produce identical results across platforms and runs.

**Acceptance:**
- No flaky tests (100 consecutive runs pass)
- Platform-independent (macOS, Linux, Windows)
- No timing-dependent assertions

---

### NFR-4: Test Maintainability

**Requirement:** Tests shall be self-documenting and easy to update.

**Implementation:**
- Clear test names following pattern `test{TestID}_{Description}`
- Helper functions for common operations (compileFile, readFile, compareGolden)
- Fixtures organized by type (Valid/, Invalid/)

**Acceptance:**
- New developer can add test in <15 minutes
- Golden file updates automated via script

---

## 5. Hierarchical Task Breakdown

### Phase 1: Infrastructure Setup (2 hours)

#### Subtask E1.1: Test Directory Structure

**Estimated:** 30 minutes

**Implementation:**
- [ ] Create `Tests/IntegrationTests/Fixtures/Valid/` directory
- [ ] Create `Tests/IntegrationTests/Fixtures/Invalid/` directory
- [ ] Add `.copy("Fixtures")` resource to Package.swift
- [ ] Document directory structure in README.md

**Deliverables:**
- Organized test fixture directories
- Package.swift updated with resources

**Acceptance:** Directories exist, Package.swift builds successfully

---

#### Subtask E1.2: Golden File Comparison Utilities

**Estimated:** 1 hour

**Implementation:**
- [ ] Implement `GoldenFileComparator` utility class
- [ ] Add Markdown comparison with diff output
- [ ] Add JSON comparison with key sorting
- [ ] Add helper methods: `readGoldenFile()`, `updateGoldenFile()`

**Deliverables:**
- `Tests/IntegrationTests/GoldenFileComparator.swift` (150 lines)

**Acceptance:** Unit tests for comparator pass

---

#### Subtask E1.3: Test Helper Infrastructure

**Estimated:** 30 minutes

**Implementation:**
- [ ] Extend `CompilerDriverTests` with helper methods
- [ ] Add `createFixture(name:content:)` helper
- [ ] Add `compileAndCompare(testID:)` helper
- [ ] Add `assertCompilationFails(testID:expectedCode:)` helper

**Deliverables:**
- Helper methods in `CompilerDriverTests.swift`

**Acceptance:** Helpers reduce boilerplate in tests

---

### Phase 2: Valid Input Tests (3 hours)

#### Subtask E1.4: File Reference Tests (V04-V08)

**Estimated:** 2 hours

**Priority:** P0 (critical for compiler validation)

**Implementation:**
- [ ] Create V04 fixture (single Markdown reference)
- [ ] Create V04 golden files (.expected.md, .expected.json)
- [ ] Write `testV04_SingleMarkdownReference()` test
- [ ] Repeat for V05 (nested Markdown references)
- [ ] Create V06 fixture (single Hypercode reference)
- [ ] Create V06 golden files
- [ ] Write `testV06_SingleHypercodeReference()` test
- [ ] Create V07 fixture (nested Hypercode references, 3 levels)
- [ ] Create V07 golden files
- [ ] Write `testV07_NestedHypercodeReferences()` test
- [ ] Create V08 fixture (mixed inline + file references)
- [ ] Create V08 golden files
- [ ] Write `testV08_MixedInlineAndReferences()` test

**Deliverables:**
- 5 test fixtures with golden files (V04-V08)
- 5 test methods in CompilerDriverTests.swift

**Acceptance:** All 5 tests pass, golden files match

---

#### Subtask E1.5: Heading and Formatting Tests (V09-V12)

**Estimated:** 1 hour

**Priority:** P1

**Implementation:**
- [ ] Create V09 fixture (Markdown with H1-H4)
- [ ] Create V09 golden files
- [ ] Write `testV09_MarkdownHeadings()` test
- [ ] Create V10 fixture (Setext headings)
- [ ] Create V10 golden files
- [ ] Write `testV10_SetextHeadings()` test
- [ ] Create V11 fixture (comments interspersed)
- [ ] Create V11 golden files
- [ ] Write `testV11_CommentLines()` test
- [ ] Create V12 fixture (blank lines) — **requires design decision**
- [ ] Create V12 golden files
- [ ] Write `testV12_BlankLines()` test

**Deliverables:**
- 4 test fixtures with golden files (V09-V12)
- 4 test methods

**Acceptance:** All 4 tests pass

**Blocker:** V12 may conflict with single-root requirement — need clarification

---

#### Subtask E1.6: Edge Case Tests (V13-V14)

**Estimated:** 45 minutes

**Priority:** P1

**Implementation:**
- [ ] Create V13 fixture (max depth 10)
- [ ] Create V13 golden files
- [ ] Write `testV13_MaximumDepth()` test
- [ ] Create V14 fixture (Unicode content)
- [ ] Create V14 golden files
- [ ] Write `testV14_UnicodeContent()` test

**Deliverables:**
- 2 test fixtures with golden files (V13-V14)
- 2 test methods

**Acceptance:** Both tests pass

---

### Phase 3: Invalid Input Tests (2 hours)

#### Subtask E1.7: File and Dependency Error Tests (I04-I06)

**Estimated:** 1 hour

**Priority:** P1

**Implementation:**
- [ ] Create I04 fixture (missing file in strict mode)
- [ ] Write `testI04_MissingFileStrictMode()` test
- [ ] Create I05 fixture (direct circular dependency)
- [ ] Write `testI05_DirectCircularDependency()` test
- [ ] Create I06 fixtures (indirect circular dependency: a.hc, b.hc)
- [ ] Write `testI06_IndirectCircularDependency()` test

**Deliverables:**
- 4 test fixtures (I04.hc, I05.hc + circular.hc, I06.hc + a.hc + b.hc)
- 3 test methods

**Acceptance:** All 3 tests pass with correct exit codes

---

#### Subtask E1.8: Path and Depth Error Tests (I07-I09)

**Estimated:** 1 hour

**Priority:** P1

**Implementation:**
- [ ] Create I07 fixture (depth exceeding 10)
- [ ] Write `testI07_DepthExceeded()` test
- [ ] Create I08 fixture (path traversal with ..)
- [ ] Write `testI08_PathTraversal()` test
- [ ] Create I09 fixture (unreadable file)
- [ ] Write `testI09_UnreadableFile()` test — **platform-specific**

**Deliverables:**
- 3 test fixtures (I07.hc, I08.hc, I09.hc + unreadable.md)
- 3 test methods

**Acceptance:** All 3 tests pass (I09 may be skipped on Windows)

**Note:** I09 requires platform-specific file permission handling

---

### Phase 4: Coverage and Polish (1 hour)

#### Subtask E1.9: Code Coverage Analysis

**Estimated:** 30 minutes

**Priority:** P0

**Implementation:**
- [ ] Run `swift test --enable-code-coverage`
- [ ] Generate coverage report: `xcrun llvm-cov report`
- [ ] Identify untested code paths
- [ ] Add targeted tests for uncovered paths

**Deliverables:**
- Coverage report (>80% target)
- Additional tests for critical uncovered paths

**Acceptance:** Overall coverage ≥80%

---

#### Subtask E1.10: Documentation and Cleanup

**Estimated:** 30 minutes

**Priority:** P1

**Implementation:**
- [ ] Document test corpus structure in README.md
- [ ] Add golden file update script (update-golden-files.sh)
- [ ] Document how to add new tests
- [ ] Clean up temporary test files

**Deliverables:**
- README.md with test documentation
- Golden file update script

**Acceptance:** Documentation complete, no stale files

---

## 6. Acceptance Criteria Summary

**Must-Have (P0):**
- ✅ All 14 valid input tests (V01-V14) implemented with golden files
- ✅ All 10 invalid input tests (I01-I10) implemented with error verification
- ✅ Golden file comparison framework functional
- ✅ Exit code verification for all error scenarios
- ✅ Code coverage ≥80%

**Should-Have (P1):**
- ✅ Test execution time <60 seconds
- ✅ Tests deterministic across platforms
- ✅ Documentation complete and up-to-date
- ✅ Golden file update automation

**Nice-to-Have (P2):**
- ⚠️ Coverage ≥90% (stretch goal)
- ⚠️ Performance benchmarks integrated
- ⚠️ Automatic regression detection in CI

---

## 7. Testing Strategy

### 7.1 Test Organization

**Directory Structure:**
```
Tests/IntegrationTests/
├── CompilerDriverTests.swift        (existing, extend)
├── GoldenFileComparator.swift       (new utility)
├── Fixtures/
│   ├── Valid/
│   │   ├── V01.hc
│   │   ├── V01.expected.md
│   │   ├── V01.expected.json
│   │   ├── V03.hc
│   │   ├── V03.expected.md
│   │   ├── V03.expected.json
│   │   ├── V04.hc
│   │   ├── V04/
│   │   │   └── main_goals.md
│   │   ├── V04.expected.md
│   │   ├── V04.expected.json
│   │   ├── ... (V05-V14)
│   └── Invalid/
│       ├── I01.hc
│       ├── I02.hc
│       ├── I03.hc
│       ├── I04.hc
│       ├── I05.hc
│       ├── I05/
│       │   └── circular.hc
│       ├── I06.hc
│       ├── I06/
│       │   ├── a.hc
│       │   └── b.hc
│       ├── ... (I07-I10)
```

---

### 7.2 Test Execution

**Run all tests:**
```bash
swift test --filter IntegrationTests
```

**Run specific test:**
```bash
swift test --filter testV04_SingleMarkdownReference
```

**Run with coverage:**
```bash
swift test --enable-code-coverage
xcrun llvm-cov report .build/debug/HyperpromptPackageTests.xctest/Contents/MacOS/HyperpromptPackageTests \
    -instr-profile=.build/debug/codecov/default.profdata
```

---

### 7.3 Golden File Updates

**Automatic update script:**
```bash
#!/bin/bash
# update-golden-files.sh
# Re-generate all golden files from current compiler output

for test in V01 V03 V04 V05 V06 V07 V08 V09 V10 V11 V12 V13 V14; do
    echo "Updating $test..."
    swift run hyperprompt \
        Tests/IntegrationTests/Fixtures/Valid/$test.hc \
        -o Tests/IntegrationTests/Fixtures/Valid/$test.expected.md \
        --manifest Tests/IntegrationTests/Fixtures/Valid/$test.expected.json
done
```

**Usage:**
- Run after intentional compiler behavior changes
- Review diff before committing
- Never run automatically in CI (golden files are source of truth)

---

## 8. Implementation Templates

### 8.1 Test Method Template

```swift
func testV04_SingleMarkdownReference() throws {
    let input = fixtureURL("Valid/V04.hc")
    let output = tempURL("V04.md")
    let expectedMD = fixtureURL("Valid/V04.expected.md")
    let expectedJSON = fixtureURL("Valid/V04.expected.json")

    // Compile
    let result = try compileFile(input, outputPath: output)

    // Verify Markdown output
    let actualMD = try readFile(output)
    let goldenMD = try readFile(expectedMD)
    XCTAssertEqual(actualMD, goldenMD, "V04 markdown output matches golden file")

    // Verify manifest
    let manifestPath = output.deletingPathExtension().appendingPathExtension("json")
    let actualJSON = try readFile(manifestPath)
    let goldenJSON = try readFile(expectedJSON)

    let actualManifest = try JSONDecoder().decode(Manifest.self, from: actualJSON.data(using: .utf8)!)
    let expectedManifest = try JSONDecoder().decode(Manifest.self, from: goldenJSON.data(using: .utf8)!)

    XCTAssertEqual(actualManifest.entries.count, expectedManifest.entries.count)
    // Compare manifest entries (sorted by path)
}
```

---

### 8.2 Error Test Template

```swift
func testI04_MissingFileStrictMode() throws {
    let input = fixtureURL("Invalid/I04.hc")
    let output = tempURL("I04.md")

    // Compilation should fail
    XCTAssertThrowsError(try compileFile(input, outputPath: output)) { error in
        guard let compilerError = error as? CompilerError else {
            XCTFail("Expected CompilerError, got \(error)")
            return
        }

        // Verify error category
        XCTAssertEqual(compilerError.category, .resolution)

        // Verify error message
        XCTAssertTrue(
            compilerError.message.contains("not found") ||
            compilerError.message.contains("missing") ||
            compilerError.message.contains("does not exist"),
            "Error should mention file not found"
        )
    }

    // No output file should be written
    XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
}
```

---

### 8.3 GoldenFileComparator Utility

```swift
final class GoldenFileComparator {
    /// Compare actual output to golden file
    static func compare(
        actual: String,
        goldenFile: URL,
        testName: String
    ) throws {
        let expected = try String(contentsOf: goldenFile, encoding: .utf8)

        if actual != expected {
            let diff = generateDiff(expected: expected, actual: actual)
            XCTFail("""
                \(testName) output does not match golden file

                Diff:
                \(diff)

                To update golden file:
                  ./update-golden-files.sh \(testName)
                """)
        }
    }

    /// Generate unified diff
    private static func generateDiff(expected: String, actual: String) -> String {
        // Use `diff` or custom implementation
        // Return formatted diff output
    }
}
```

---

## 9. Dependencies and Blockers

### 9.1 Dependencies

**Satisfied:**
- ✅ D2: Compiler Driver (fully implemented and tested)
- ✅ C2: Markdown Emitter (working)
- ✅ C3: Manifest Generator (working)
- ✅ B4: Recursive Compilation (working)

**Required:**
- Swift Package Manager test infrastructure (available)
- XCTest framework (available)
- File I/O APIs (available)

---

### 9.2 Blockers

**Design Decisions Needed:**
- **V12 test:** Blank lines between node groups — does this violate single-root requirement?
  - **Resolution:** Review PRD §8.1, clarify with project spec
  - **Impact:** May need to reclassify V12 as invalid test (I11)

**Platform-Specific Issues:**
- **I09 test:** Unreadable file permissions — Windows handles permissions differently
  - **Resolution:** Use `#if os(Linux) || os(macOS)` conditional compilation
  - **Impact:** Test skipped on Windows (acceptable for v0.1)

---

## 10. Risk Assessment

### 10.1 Technical Risks

**Risk:** Golden files become stale after compiler changes
- **Mitigation:** Automated update script with manual review
- **Likelihood:** Medium
- **Impact:** Medium

**Risk:** Tests become flaky due to timing or filesystem issues
- **Mitigation:** Use deterministic fixtures, avoid timing dependencies
- **Likelihood:** Low
- **Impact:** High

**Risk:** Coverage target (80%) not achievable with current test set
- **Mitigation:** Add targeted unit tests for uncovered paths
- **Likelihood:** Low
- **Impact:** Medium

---

### 10.2 Schedule Risks

**Risk:** File reference tests (V04-V08) more complex than estimated
- **Mitigation:** Allocate buffer time, prioritize P0 tests
- **Likelihood:** Medium
- **Impact:** Low (can defer P1 tests to next task)

**Risk:** Platform-specific issues delay testing
- **Mitigation:** Test on Linux early, document Windows-specific skips
- **Likelihood:** Low
- **Impact:** Low

---

## 11. Success Metrics

**Quantitative:**
- ✅ 24/24 tests implemented (100% coverage)
- ✅ 22/24 tests passing (91%+ pass rate, accounting for V12 and I09 edge cases)
- ✅ Code coverage ≥80%
- ✅ Test execution time <60s

**Qualitative:**
- ✅ Tests are deterministic and reliable
- ✅ Test suite catches regressions effectively
- ✅ Documentation enables new contributors to add tests easily
- ✅ Golden files provide clear reference for expected behavior

---

## 12. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-10 | Claude | Initial PRD creation for E1 task |

---

## 13. Next Steps

After completing this PRD:
1. **Review with stakeholders** (if applicable)
2. **Execute EXECUTE command** to begin implementation
3. **Track progress** using task checklist in Workplan.md
4. **Update golden files** as tests are implemented
5. **Generate coverage report** before marking task complete

**Estimated completion:** 8 hours of focused implementation time

---

**Archived:** 2025-12-10
