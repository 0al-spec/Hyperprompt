# Integration-1 — Lexer with Specifications

**Version:** 1.0.0
**Date:** 2025-12-11
**Status:** Ready for EXECUTE phase
**Priority:** P1 (High)
**Effort:** 5 hours
**Phase:** Phase 7 (Lexer & Resolver Integration with Specs)

---

## 1. Executive Summary

Replace imperative validation logic in the Lexer (`Sources/Parser/Lexer.swift`) with declarative specifications from Phase 3. The Lexer currently uses manual validation in methods like `isBlankLine()`, `extractIndentation()`, and `extractLiteral()`. This task refactors these methods to use specification classes (`IsBlankLineSpec`, `NoTabsIndentSpec`, `ValidNodeLineSpec`, etc.) and decision specs (`LineKindDecision`) for cleaner, more testable code.

**Deliverables:**
1. Refactored Lexer using HypercodeGrammar specifications
2. All existing Lexer tests passing (14/14)
3. New integration tests demonstrating specification-based validation
4. Updated error messages referencing specification failures

**Success Criteria:**
- ✅ All specification classes used for validation
- ✅ All existing tests pass (0 failures)
- ✅ Performance overhead <10% vs imperative version
- ✅ Code coverage maintained or improved

---

## 2. Context & Motivation

### 2.1 Current State (Imperative Validation)

The Lexer currently validates lines using imperative checks embedded in methods:

```swift
// Current: Manual blank line checking
func isBlankLine(_ line: String) -> Bool {
    line.isEmpty || line.allSatisfy { $0 == Whitespace.space }
}

// Current: Manual indentation validation with imperative logic
func extractIndentation(_ line: String, location: SourceLocation) throws -> (Int, String.Index) {
    var indent = 0
    var index = line.startIndex
    while index < line.endIndex {
        let char = line[index]
        if char == Whitespace.space { ... }
        else if char == Whitespace.tab {
            throw LexerError.tabInIndentation(location: location)
        } else { break }
    }
    if !indentAlignmentSpec.isSatisfiedBy(indent) {
        throw LexerError.misalignedIndentation(...)
    }
    return (indent, index)
}

// Current: Manual literal extraction with embedded validation
func extractLiteral(_ content: String, location: SourceLocation) throws -> String {
    guard content.hasPrefix("\"") else { ... }
    guard let closingQuoteIndex = ... else {
        throw LexerError.unclosedQuote(location: location)
    }
    let literal = String(content[afterOpeningQuote..<closingQuoteIndex])
    if literal.contains("\n") || literal.contains("\r") {
        throw LexerError.multilineLiteral(location: location)
    }
    ...
}
```

**Problems with imperative approach:**
- Validation logic scattered across methods
- Difficult to test individual rules in isolation
- Duplicate validation logic (e.g., blank line check appears twice)
- No clear mapping to EBNF grammar
- Error messages don't reference specification names

### 2.2 Future State (Declarative Specifications)

Phase 3 provides specification classes that should replace the above logic:

```swift
// Phase 3 Specs: Declarative validation
let isBlank = IsBlankLineSpec()
let lineKindDecision = HypercodeGrammar.makeLineClassifier()

// Replace imperative with specification
func classifyLine(_ line: String, location: SourceLocation) throws -> Token {
    let rawLine = RawLine(text: line, lineNumber: location.line, filePath: location.filePath)

    // Use LineKindDecision instead of manual checks
    if let kind = lineKindDecision.decide(rawLine) {
        switch kind {
        case .blank:
            return .blank(location: location)
        case .comment(let prefix):
            return .comment(indent: ..., location: location)
        case .node(let literal):
            return .node(indent: ..., literal: literal, location: location)
        }
    }
    throw LexerError.invalidLineFormat(location: location)
}
```

**Benefits of declarative approach:**
- Validation rules are explicit, testable objects
- Clear EBNF grammar mapping
- Reusable across multiple components
- Better error messages with specification context
- Easier to add new validation rules

### 2.3 Phase 3 Specifications Available

**Lexical & Syntactic Specs (from Spec-1, Spec-2):**
- `IsBlankLineSpec` — Blank line detection
- `IsCommentLineSpec` — Comment line detection
- `NoTabsIndentSpec` — Tab validation
- `IndentMultipleOf4Spec` — Indentation alignment
- `DepthWithinLimitSpec(maxDepth: 10)` — Depth limits
- `ValidQuotesSpec` — Quote validation
- `SingleLineContentSpec` — Single-line content validation
- `IsNodeLineSpec` — Node line detection
- `ValidNodeLineSpec` — Complete node validation (all rules combined)
- `LineKindDecision` — Decision spec for line classification

**Decision Specs (from Spec-4):**
- `HypercodeGrammar.makeLineClassifier()` — Factory for LineKindDecision
- `LineKindDecision.decide(_ rawLine: RawLine) -> LineKind?` — Multi-valued classification

---

## 3. Requirements & Acceptance Criteria

### 3.1 Functional Requirements

1. **Replace line classification**
   - Use `LineKindDecision` in `classifyLine()` instead of manual if/else checks
   - Maintain same classification priority: blank → comment → node

2. **Replace blank line detection**
   - Use `IsBlankLineSpec` instead of custom `isBlankLine()` method
   - Or rely on LineKindDecision which uses IsBlankLineSpec internally

3. **Replace indentation validation**
   - Use `NoTabsIndentSpec` instead of manual tab checking
   - Use `IndentMultipleOf4Spec` instead of indentAlignmentSpec
   - Extract indent count from RawLine.leadingSpaces property (or calculate inline)

4. **Replace depth validation**
   - Use `DepthWithinLimitSpec(maxDepth: 10)` for depth checks
   - Pass maxDepth parameter to decision specs

5. **Replace quote validation**
   - Use `ValidQuotesSpec` and `SingleLineContentSpec` for quote/literal checks
   - Or rely on ValidNodeLineSpec which includes quote validation

6. **Update error messages**
   - Reference specification failures in error messages
   - Example: "Line does not satisfy `ValidNodeLineSpec`: missing closing quote"

7. **Verify existing tests**
   - All 14 existing Lexer tests must pass
   - No test failures, no skipped tests
   - No new compile errors or warnings

8. **Add integration tests**
   - Test that specifications produce same results as imperative code
   - Test composite specs: `ValidNodeLineSpec` combines multiple atomic specs
   - Test decision spec: `LineKindDecision` produces correct LineKind

### 3.2 Non-Functional Requirements

1. **Performance**
   - <10% performance overhead vs current imperative implementation
   - Benchmark: tokenizing large files (10,000+ lines) should be <1 second overhead
   - Measurement: Compare `swift build --release` timing

2. **Code Quality**
   - Zero compiler warnings
   - Test coverage maintained or improved (>80%)
   - Clear comments explaining specification usage

3. **Compatibility**
   - No breaking changes to Lexer public API
   - Token output identical to current implementation
   - Error types unchanged (LexerError enum)

### 3.3 Acceptance Criteria per Subtask

**Subtask 1: Refactor classifyLine() to use LineKindDecision**
- [ ] `classifyLine()` uses `HypercodeGrammar.makeLineClassifier()` or `LineKindDecision()`
- [ ] All branches (blank, comment, node) handled via LineKind cases
- [ ] Invalid lines throw LexerError.invalidLineFormat (same as before)
- [ ] No changes to Token enum or token construction

**Subtask 2: Replace tab checking with NoTabsIndentSpec**
- [ ] Manual tab-checking loop removed from extractIndentation()
- [ ] NoTabsIndentSpec used (via RawLine validation)
- [ ] LexerError.tabInIndentation still thrown on tab detection
- [ ] Test: `I01_Tab_Characters_In_Indentation` still fails correctly

**Subtask 3: Replace indent validation with IndentMultipleOf4Spec**
- [ ] Manual alignment check in extractIndentation() replaced
- [ ] IndentMultipleOf4Spec or equivalent used
- [ ] LexerError.misalignedIndentation still thrown on misalignment
- [ ] Test: `I02_Misaligned_Indentation` still fails correctly

**Subtask 4: Replace depth checking with DepthWithinLimitSpec**
- [ ] Depth validation logic uses DepthWithinLimitSpec(maxDepth: 10)
- [ ] ValidNodeLineSpec includes depth check via composition
- [ ] Test: `I07_Depth_Exceeding_10` still fails correctly

**Subtask 5: Use ValidNodeLineSpec for node validation**
- [ ] `extractLiteral()` replaced with ValidNodeLineSpec usage
- [ ] Quote validation uses `ValidQuotesSpec`
- [ ] Single-line validation uses `SingleLineContentSpec`
- [ ] Tests: `I03_Unclosed_Quotation` still fails correctly

**Subtask 6: Update error messages to reference specifications**
- [ ] LexerError cases updated with spec failure context
- [ ] Example: `tabInIndentation` message mentions `NoTabsIndentSpec`
- [ ] Error messages remain user-friendly (not overly technical)
- [ ] Existing tests still pass (error messages may be enhanced)

**Subtask 7: Verify all existing tests pass**
- [ ] `swift test` shows 14/14 Lexer tests passing
- [ ] Zero test failures
- [ ] Zero compilation warnings
- [ ] No skipped tests

**Subtask 8: Add integration tests for specification-based lexer**
- [ ] Test 1: LineKindDecision produces same results as classifyLine()
- [ ] Test 2: ValidNodeLineSpec correctly validates node lines (V01, V04, V07)
- [ ] Test 3: NoTabsIndentSpec rejects tabs (I01)
- [ ] Test 4: IndentMultipleOf4Spec rejects misalignment (I02)
- [ ] Test 5: DepthWithinLimitSpec enforces depth limit (I07)
- [ ] Test 6: Composite specs work correctly (e.g., ValidNodeLineSpec)
- [ ] All new tests passing (0 failures)

**Subtask 9: Benchmark performance (P2, optional)**
- [ ] Create benchmark script comparing imperative vs specification-based
- [ ] Measure tokenizing test corpus (V01-V14, I01-I10)
- [ ] Record baseline (current) and new (spec-based) timings
- [ ] Verify overhead <10% (target: 1-5% overhead)
- [ ] Document results in summary

---

## 4. Implementation Plan

### Phase 1: Analysis & Setup (30 min)

**Subtask 1.1: Understand current Lexer structure**
- Review `Sources/Parser/Lexer.swift` (already done above)
- Identify methods to refactor:
  - `classifyLine()` — main classification logic
  - `isBlankLine()` — blank detection
  - `extractIndentation()` — indentation validation
  - `extractLiteral()` — quote/literal validation
- Note: Some methods may be combined or removed

**Subtask 1.2: Understand HypercodeGrammar specifications**
- Review specification classes available:
  - `LineKindDecision` — main decision spec
  - `IsBlankLineSpec`, `IsCommentLineSpec`, `IsNodeLineSpec`
  - `NoTabsIndentSpec`, `IndentMultipleOf4Spec`, `DepthWithinLimitSpec`
  - `ValidQuotesSpec`, `SingleLineContentSpec`, `ValidNodeLineSpec`
- Check factory method: `HypercodeGrammar.makeLineClassifier()`
- Verify RawLine structure and properties (text, lineNumber, filePath, leadingSpaces)

**Subtask 1.3: Plan refactoring strategy**
- Strategy: Minimize changes to public API
- Approach: Replace imperative logic within existing methods
- Keep Token output identical
- Keep LexerError types unchanged (add context if needed)

---

### Phase 2: Refactor Lexer Methods (3 hours)

**Subtask 2.1: Create RawLine from input line (Lexer refactor prep)**
- Add logic to convert line string to RawLine in classifyLine()
- RawLine constructor: `RawLine(text: line, lineNumber: lineNumber, filePath: location.filePath)`
- Compute leadingSpaces property (count of leading spaces)
- Test: RawLine constructs correctly for various inputs

**Subtask 2.2: Use LineKindDecision in classifyLine()**
- Create classifier: `let classifier = HypercodeGrammar.makeLineClassifier()`
- Call: `let kind = classifier.decide(rawLine)`
- Handle result:
  - If `kind == .blank` → return `.blank(location: location)`
  - If `kind == .comment(prefix: "#")` → return `.comment(indent: indent, location: location)`
  - If `kind == .node(literal: ...)` → return `.node(indent: indent, literal: literal, location: location)`
  - If `nil` → throw `LexerError.invalidLineFormat(location: location)`
- Extract indent count from RawLine.leadingSpaces or manual calculation
- Remove old manual if/else logic for blank/comment/node detection

**Subtask 2.3: Remove/refactor isBlankLine() method**
- Option 1: Remove method entirely (now handled by LineKindDecision)
- Option 2: Keep for backward compatibility, implement via IsBlankLineSpec
- Recommended: Option 1 (simplify Lexer, specs handle blank detection)
- Test: No callers affected

**Subtask 2.4: Refactor extractIndentation() to use specifications**
- Keep method for compatibility (other code may call it)
- Update implementation:
  - Create RawLine from line
  - Use NoTabsIndentSpec to validate no tabs
  - Use IndentMultipleOf4Spec to validate alignment
  - Return (indent count, content start index) as before
- Throw same LexerError types (tabInIndentation, misalignedIndentation)
- Test: Behavior identical to current implementation

**Subtask 2.5: Refactor extractLiteral() to use specifications**
- Keep method for compatibility
- Update implementation:
  - Create RawLine from content (or line context)
  - Use ValidQuotesSpec or SingleLineContentSpec to validate
  - Extract and return literal string
- Throw same LexerError types (unclosedQuote, multilineLiteral)
- Test: Behavior identical to current implementation

**Subtask 2.6: Update error messages (optional enhancement)**
- Add context about which specification failed
- Example: "Missing closing quote (ValidQuotesSpec violation)"
- Keep messages user-friendly
- Note: Only if it improves error reporting without breaking tests

**Subtask 2.7: Verify compilation**
- Run `swift build` with refactored Lexer
- Fix any compilation errors
- No compiler warnings acceptable
- Test: Build succeeds without errors

---

### Phase 3: Testing & Validation (1.5 hours)

**Subtask 3.1: Run existing Lexer tests**
- Execute: `swift test --filter LexerTests` (or equivalent)
- Expected: 14/14 tests passing
- If failures: Debug and fix (token output should be identical)
- Test: All existing tests pass (0 failures, 0 skipped)

**Subtask 3.2: Add integration tests for LineKindDecision**
- Test: LineKindDecision produces correct LineKind for blank line
  - Input: RawLine with "   " (spaces only)
  - Expected: .blank
- Test: LineKindDecision produces correct LineKind for comment
  - Input: RawLine with "# comment"
  - Expected: .comment(prefix: "#")
- Test: LineKindDecision produces correct LineKind for node
  - Input: RawLine with `"literal"`
  - Expected: .node(literal: "literal")
- Test: LineKindDecision returns nil for invalid lines
  - Input: RawLine with text not matching any kind
  - Expected: nil

**Subtask 3.3: Add integration tests for specification usage**
- Test: NoTabsIndentSpec rejects tabs
  - Input: RawLine with `\t"node"`
  - Expected: LexerError.tabInIndentation
- Test: IndentMultipleOf4Spec rejects misalignment
  - Input: RawLine with 3 spaces (not divisible by 4)
  - Expected: LexerError.misalignedIndentation
- Test: DepthWithinLimitSpec enforces depth limit
  - Input: RawLine with 48 spaces (depth 12, exceeds max 10)
  - Expected: LexerError or decision failure
- Test: ValidQuotesSpec validates quotes
  - Input: RawLine with unclosed quote
  - Expected: LexerError.unclosedQuote

**Subtask 3.4: Run comprehensive test suite**
- Execute: `swift test`
- Expected: All tests pass (including new integration tests)
- Verify: Zero failures, zero skipped tests
- Check: No new compiler warnings

**Subtask 3.5: Validate test corpus (if applicable)**
- Run: Hyperprompt compiler on test corpus (V01-V14, I01-I10)
- Expected: Same results as before refactoring
- Verify: Valid tests produce correct output, invalid tests fail correctly
- Test: Test corpus passes with refactored Lexer

**Subtask 3.6: Benchmark performance (P2, optional)**
- Create benchmark: Tokenize large file (10,000+ lines)
- Measure: Time for specification-based approach
- Compare: Baseline (current) vs new (specification-based)
- Target: <10% overhead (1-5% typical)
- Document: Results in summary (if required)

---

## 5. Code Templates & Examples

### 5.1 Refactored classifyLine() using LineKindDecision

```swift
func classifyLine(_ line: String, location: SourceLocation) throws -> Token {
    let rawLine = RawLine(text: line, lineNumber: location.line, filePath: location.filePath)
    let classifier = HypercodeGrammar.makeLineClassifier()

    guard let kind = classifier.decide(rawLine) else {
        throw LexerError.invalidLineFormat(location: location)
    }

    let indent = rawLine.leadingSpaces / Indentation.spacesPerLevel

    switch kind {
    case .blank:
        return .blank(location: location)
    case .comment(let prefix):
        return .comment(indent: indent, location: location)
    case .node(let literal):
        return .node(indent: indent, literal: literal, location: location)
    }
}
```

### 5.2 Integration Test Example

```swift
func testLineKindDecisionBlankLine() {
    let rawLine = RawLine(text: "    ", lineNumber: 1, filePath: "test.hc")
    let classifier = HypercodeGrammar.makeLineClassifier()
    let kind = classifier.decide(rawLine)

    XCTAssertEqual(kind, .blank)
}

func testLineKindDecisionCommentLine() {
    let rawLine = RawLine(text: "# comment", lineNumber: 1, filePath: "test.hc")
    let classifier = HypercodeGrammar.makeLineClassifier()
    let kind = classifier.decide(rawLine)

    XCTAssertEqual(kind, .comment(prefix: "#"))
}

func testNoTabsIndentSpecRejectsTab() throws {
    let rawLine = RawLine(text: "\t\"node\"", lineNumber: 1, filePath: "test.hc")
    let spec = NoTabsIndentSpec()
    let result = spec.isSatisfiedBy(rawLine)

    XCTAssertFalse(result)
}
```

---

## 6. Quality Checklist

### Code Quality
- [ ] Zero compiler warnings
- [ ] All code follows Swift style guide
- [ ] Comments added for specification usage (explain why, not what)
- [ ] No code duplication
- [ ] Public API unchanged (backward compatible)

### Testing
- [ ] All 14 existing Lexer tests passing
- [ ] 5+ new integration tests added
- [ ] Test coverage maintained (>80%)
- [ ] Edge cases covered (empty, tabs, misalignment, unclosed quotes)
- [ ] Error cases still throw expected LexerError types

### Documentation
- [ ] Lexer docstrings updated (if validation logic described)
- [ ] Comments explain specification usage
- [ ] README or CONTRIBUTING.md updated (if needed)
- [ ] Commit message clear and detailed

### Performance
- [ ] Build time acceptable (<2 minutes)
- [ ] Test suite completes in reasonable time (<10 seconds)
- [ ] Lexer performance <10% overhead vs imperative (benchmark if applicable)

---

## 7. Success Indicators

✅ **Task Complete When:**
1. All existing Lexer tests pass (14/14)
2. New integration tests added and passing (5+ tests)
3. Zero compiler warnings
4. Refactored Lexer uses specifications for all validation
5. Error messages clear and reference specification failures (if enhanced)
6. Performance overhead <10% (benchmark if applicable)
7. Code review approved
8. Commit includes refactored Lexer, tests, and documentation

---

## 8. Known Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Performance regression | Specs slower than imperative | Benchmark & profile; optimize if needed |
| Breaking API changes | Dependent code fails | Keep public API unchanged; only refactor internal implementation |
| Test failures | Incomplete refactoring | Incrementally refactor; test after each change |
| Specification misuse | Incorrect validation | Review Phase 3 spec docs; understand composition patterns |
| Indent calculation errors | Wrong token indent field | Test RawLine.leadingSpaces property carefully |

---

## 9. Dependencies & Prerequisites

**Must be complete before starting:**
- ✅ Phase 2 (Lexer implementation) — Already exists, working
- ✅ Phase 3 (Specifications) — Already complete (Spec-1 through Spec-4 archived)
- ✅ HypercodeGrammar module — Already compiled, specs available

**External dependencies:**
- Swift 6.0+ (compiler)
- SpecificationCore (already imported)
- Core module (for SourceLocation, Whitespace constants)

---

## 10. Follow-Up Tasks

**After Integration-1 completes:**
1. **Integration-2** — Refactor Reference Resolver with Path specs
   - Similar approach: Replace imperative path validation with specifications
   - Estimated: 6 hours
   - Blocks: Phase 9 (Release)

2. **Phase 9** — Release & final validation
   - Compile all components together
   - Run full test suite
   - Prepare for v0.1 release

---

## 11. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-11 | Claude | Initial PRD for Integration-1 task |

---

**Status:** Ready for EXECUTE phase

Next: Run the EXECUTE command to begin implementation.

```bash
$ claude "Выполни команду EXECUTE"
```
