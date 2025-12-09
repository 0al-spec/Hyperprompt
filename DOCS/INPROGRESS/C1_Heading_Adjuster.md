# C1: Heading Adjuster — PRD

**Phase:** Phase 5 (Markdown Emission)
**Priority:** P1
**Estimated Effort:** 6 hours
**Dependencies:** A2 (Core Types Implementation)
**Status:** In Development

---

## 1. Objective

Implement a robust heading adjuster component that transforms Markdown headings to accommodate the hierarchical nesting of embedded content. This component must support both ATX-style and Setext-style headings, apply configurable depth offsets, and gracefully handle overflow when adjusted levels exceed H6.

**Success Criterion:** All heading styles are correctly transformed with proper overflow handling, passing comprehensive test corpus.

---

## 2. Scope & Intent

### 2.1 Primary Responsibility

Transform embedded Markdown content by adjusting all heading levels based on the nesting depth at which the content is embedded. This ensures that heading hierarchy is preserved and remains semantically meaningful in the compiled output.

### 2.2 Inputs & Outputs

**Input:**
- Markdown content as `String` (normalized to LF line endings)
- Offset value: `Int` (depth adjustment: parent depth + 1)

**Output:**
- Transformed Markdown content with adjusted headings
- Overflow headings (depth ≥ 6) converted to bold text
- All line endings normalized to LF
- Single newline at end of content

### 2.3 Constraints

- Must preserve all non-heading content exactly (no modifications to prose)
- Must handle both ATX (`#`) and Setext (underline) heading styles
- Must not modify content within code blocks or inline code
- Must normalize line endings (CRLF/CR → LF) during processing
- Must ensure deterministic output (identical inputs → identical outputs)

### 2.4 Assumptions

1. Input content is well-formed Markdown (lexically valid)
2. Headings use standard Markdown syntax (not malformed)
3. Offset is non-negative integer (≥ 0)
4. Input has already been normalized to LF line endings

---

## 3. Functional Requirements

### 3.1 ATX-Style Heading Transformation

**Rule:** Lines starting with `#` (after any leading whitespace) are ATX headings.

**Algorithm:**
1. Count leading `#` characters to determine current level
2. Calculate new level: `min(current_level + offset, 6)`
3. If new level > 6: convert to bold text format `**heading_text**`
4. Otherwise: generate new heading with adjusted hash count
5. Preserve all content after the hashes (on same line)

**Examples:**

```
Input offset: +2
"# Heading 1"      → "### Heading 1"  (1+2=3)
"## Heading 2"     → "#### Heading 2" (2+2=4)
"##### Heading 5"  → "**Heading 5**"  (5+2=7 > 6, overflow)
```

**Edge Cases:**
- Preserve trailing spaces after hashes: `##  Text` → `####  Text`
- Handle inline formatting: `## *italic* **bold**` → correct hash adjustment
- Reject malformed: `# # Not a heading` → pass through unchanged

### 3.2 Setext-Style Heading Transformation

**Rule:** Lines followed by underline of `=` or `-` form H1 or H2 headings respectively.

**Algorithm:**
1. Detect Setext heading: current line + next line (underline)
2. Determine current level: `=` → H1 (level 1), `-` → H2 (level 2)
3. Calculate new level: `min(current_level + offset, 6)`
4. If new level > 6: convert to bold
5. Otherwise: generate ATX equivalent with adjusted level (preferred) OR generate new Setext with adjusted underline

**Examples:**

```
Input offset: +3
Heading          → **Heading**           (1+3=4 stays ATX, but... 1+3=4)
=========
(becomes)        → "#### Heading"        (convert to ATX)

Subheading       → **Subheading**        (2+3=5 stays ATX)
-----------
(becomes)        → "##### Subheading"
```

**Conversion Strategy:**
- For levels ≤ 6 after adjustment: convert Setext to ATX (simpler, more portable)
- For levels > 6: convert to bold text
- Normalize output to ATX style (remove underline line)

**Edge Cases:**
- Underlines of varying length: match heading content length or accept any length
- Embedded `-` in heading text: require underline to be all same character
- Multiple underline styles: detect both `=` and `-` correctly

### 3.3 Overflow Handling (Level > 6)

**Rule:** Markdown supports H1-H6. Headings that would overflow use bold text instead.

**Format for Overflow:**
```
**Heading Text**
```

**Algorithm:**
1. Check if adjusted level > 6
2. Extract heading text (remove hashes or underline)
3. Wrap in `**...**` for bold
4. Place on single line
5. Preserve trailing whitespace/punctuation

**Examples:**

```
Input offset: +6
"# Very Deep"      → "**Very Deep**"  (1+6=7 > 6)
"## Also Deep"     → "**Also Deep**"  (2+6=8 > 6)
```

**Non-Overflow Cases:**
```
Input offset: +5
"# Okay"           → "###### Okay"  (1+5=6, exactly H6, OK)
```

---

## 4. Non-Functional Requirements

### 4.1 Performance
- Process Markdown files up to 1 MB in <100 ms
- Linear time complexity relative to content length
- Minimal memory overhead (streaming-friendly design)

### 4.2 Correctness & Determinism
- Identical inputs produce identical outputs
- All line endings normalized to LF before output
- No platform-specific behavior
- Output ends with exactly one LF

### 4.3 Robustness
- Handle edge cases without crashing (malformed input → best-effort transformation)
- Preserve original content on failures (fail-safe)
- Report diagnostics if transformations are incomplete

### 4.4 Testability
- All functions pure (no side effects)
- Comprehensive test coverage for both heading styles
- Edge case coverage: depth limits, overflow, mixed content

---

## 5. Detailed TODO Breakdown

### Phase 1: Infrastructure (Effort: 1.5 hours)

- [ ] **[High]** Create `HeadingAdjuster` struct with public API
  - Input: `content: String, offset: Int` → `String`
  - Handle nil/empty cases early
  - Add basic documentation comments

- [ ] **[High]** Define internal helper functions
  - `isATXHeading(_ line: String) -> Bool`
  - `extractATXLevel(_ line: String) -> Int`
  - `extractATXText(_ line: String) -> String`
  - `isSetextUnderline(_ line: String) -> (isSyntax: Bool, level: Int)`

- [ ] **[Medium]** Normalize input/output
  - Ensure input uses LF line endings
  - Ensure output ends with exactly one LF
  - Handle empty input gracefully

**Acceptance Criteria:**
- All helper functions compile and have basic unit tests
- Edge cases (nil, empty, invalid offset) handled

---

### Phase 2: ATX Parsing & Transformation (Effort: 2 hours)

- [ ] **[High]** Implement ATX heading detection
  - Count leading `#` characters
  - Validate format: `#` prefix + space + text
  - Reject malformed: `# # Text`, `##Text` (no space)
  - Unit test with 10+ variants

- [ ] **[High]** Implement heading level adjustment
  - Calculate new level: `min(current + offset, 6)`
  - Generate output: hashes + space + text OR bold
  - Preserve exact spacing (after hashes)

- [ ] **[High]** Implement ATX transformation loop
  - Iterate through lines
  - Classify each line (heading vs non-heading)
  - Transform headings, pass through others
  - Accumulate output with correct line endings

- [ ] **[Medium]** Handle special cases
  - Multiple spaces after hashes: `##   Text` → preserve count
  - Text with special characters: `## Code: function()`
  - Inline formatting: `## *Italic* **Bold**`
  - Unit test for each case

**Acceptance Criteria:**
- All ATX headings correctly adjusted
- Overflow to bold working
- 100% of ATX test cases pass
- Output deterministic

---

### Phase 3: Setext Parsing & Transformation (Effort: 1.5 hours)

- [ ] **[High]** Implement Setext detection
  - Detect underline line: all `=` or all `-`
  - Match heading + underline pattern
  - Validate: underline length ≥ 1 (or ≥ heading text length)
  - Unit test with 8+ variants

- [ ] **[High]** Implement Setext transformation
  - Determine level: `=` → 1, `-` → 2
  - Calculate adjusted level
  - Convert to ATX format (preferred)
  - Handle overflow (convert to bold)

- [ ] **[Medium]** Handle edge cases
  - Underline longer than heading: accept/normalize
  - Heading with trailing/leading spaces: preserve
  - Multiple underlines in document
  - Unit test for each

- [ ] **[Low]** Setext underline regeneration (optional)
  - Instead of converting to ATX, regenerate underline
  - Match heading text length or use fixed width
  - Only if preservation is required; otherwise convert to ATX

**Acceptance Criteria:**
- All Setext headings correctly transformed
- Overflow handling consistent with ATX
- 100% of Setext test cases pass

---

### Phase 4: Overflow & Edge Case Handling (Effort: 0.5 hours)

- [ ] **[High]** Bold text fallback for H7+
  - Extract clean heading text (no hashes/underlines)
  - Wrap in `**...**`
  - Ensure no extra newlines
  - Test: various input levels with high offsets

- [ ] **[Medium]** Line ending normalization
  - Handle CRLF → LF conversion
  - Handle CR → LF conversion
  - Preserve LF as-is
  - Unit test all three cases

- [ ] **[Medium]** Determinism verification
  - Output structure: exact same bytes for identical input
  - No random elements, timestamps, or platform-specific behavior
  - Test: run 3× and verify byte-for-byte match

**Acceptance Criteria:**
- No headings exceed H6 in output (except bold)
- All line endings LF
- Output ends with single LF
- Deterministic output verified

---

### Phase 5: Comprehensive Testing (Effort: 1 hour)

**Unit Tests: ATX Headings**

- [ ] **[High]** Test all levels H1-H6 with various offsets
  - H1 + offset 1 → H2
  - H1 + offset 5 → bold
  - H6 + offset 1 → bold
  - Coverage: 15+ test cases

- [ ] **[High]** Test edge cases
  - Spaces after hashes: `##  ` → preserved
  - No space after hashes: `##Text` → not a heading
  - Multiple hashes: `######## Level 8` → pass-through
  - Tab character in content: preserved

**Unit Tests: Setext Headings**

- [ ] **[High]** Test H1 and H2 with various offsets
  - H1 (`=`) → H3 with offset 2
  - H2 (`-`) → bold with offset 5+
  - Coverage: 10+ test cases

- [ ] **[Medium]** Test underline variations
  - Longer underline: `===== Longer`
  - Shorter underline: `= Too Short`
  - Multiple underline styles in same content

**Integration Tests: Mixed Content**

- [ ] **[High]** Test documents with multiple heading styles
  - Mix ATX and Setext
  - Various levels and offsets
  - Golden files: input + expected output

- [ ] **[High]** Test with real Markdown samples (V09, V10 from corpus)
  - File: `test-files/headings-atx.md`
  - File: `test-files/headings-setext.md`
  - Verify output matches golden file

**Edge Case Tests**

- [ ] **[Medium]** Empty input: `` → empty
- [ ] **[Medium]** Single heading: `# Title` → transformed
- [ ] **[Low]** Unicode in headings: `# 中文标题` → preserved
- [ ] **[Low]** Heading at end without newline: handled correctly
- [ ] **[High]** Determinism test: same input 3× → identical output

**Acceptance Criteria:**
- ≥ 95% test pass rate
- Coverage of all major paths
- No platform-specific failures
- Determinism verified (3-run comparison)

---

## 6. Acceptance Criteria Summary

### Functional AC

- ✅ All ATX headings (H1-H6) adjusted correctly
- ✅ All Setext headings (H1-H2) adjusted correctly
- ✅ Overflow headings (H7+) converted to bold
- ✅ Non-heading content unchanged
- ✅ Output normalized to LF endings
- ✅ Output ends with exactly one LF

### Quality AC

- ✅ ≥ 95% of test cases pass
- ✅ 100% determinism: identical input → byte-for-byte output
- ✅ No crashes on malformed input (best-effort transformation)
- ✅ Edge cases documented and tested
- ✅ Code coverage ≥ 90%

### Integration AC

- ✅ Integrates with `MarkdownEmitter` module
- ✅ Accepts depth offset from parent embedding context
- ✅ Produces output ready for final document assembly
- ✅ Works with all valid test corpus files (V09, V10)

---

## 7. Technical Design Notes

### 7.1 Algorithm: Line-by-Line Processing

```
function adjustHeadings(content, offset):
    lines ← split content by LF
    result ← []

    for i = 0 to lines.length - 1:
        line ← lines[i]
        nextLine ← lines[i+1] (if exists)

        if isATXHeading(line):
            transformed ← transformATX(line, offset)
            result.append(transformed)

        else if isSetextUnderline(nextLine):
            // Setext heading: current line + next line
            transformed ← transformSetext(line, nextLine, offset)
            result.append(transformed.headingLine)
            skip nextLine (i += 1)

        else:
            result.append(line)  // Pass through

    return join(result, LF) + LF
```

### 7.2 ATX Transformation Detail

```swift
func transformATX(_ line: String, offset: Int) -> String {
    let level = countLeadingHashes(line)
    let text = extractTextAfterHashes(line)
    let newLevel = min(level + offset, 6)

    if newLevel > 6 {
        return "**\(text.trimmed())**"
    } else {
        let hashes = String(repeating: "#", count: newLevel)
        return "\(hashes) \(text)"
    }
}
```

### 7.3 Setext Transformation Detail

```swift
func transformSetext(_ heading: String, underline: String, offset: Int) -> (heading: String, skip: Bool) {
    let underlineChar = underline.first
    let level = underlineChar == "=" ? 1 : 2
    let newLevel = min(level + offset, 6)

    if newLevel > 6 {
        return ("**\(heading)**", true)
    } else {
        let hashes = String(repeating: "#", count: newLevel)
        return ("\(hashes) \(heading)", true)
    }
}
```

### 7.4 Data Flow Diagram

```
Input Markdown
      ↓
[Normalize to LF]
      ↓
[Split into lines]
      ↓
[For each line]
  ├─→ [isATXHeading?] ─→ [Transform ATX] ─→ [Append]
  ├─→ [isSetext?] ─→ [Transform Setext + skip underline] ─→ [Append]
  └─→ [Pass through unchanged] ─→ [Append]
      ↓
[Join lines with LF]
      ↓
[Ensure single trailing LF]
      ↓
Output Markdown
```

---

## 8. Implementation Notes

### 8.1 Language Features

- Use Swift `String` for content (UTF-8 aware)
- Use `String.split(separator:)` for line breaking
- Regex for heading detection (if available) or direct character checks
- Pattern matching for Setext detection

### 8.2 Optimization Opportunities

1. **Lazy Evaluation**: Process line-by-line (no full string allocation until end)
2. **StringBuilder Pattern**: Accumulate lines in array, join once
3. **Regex Caching**: Compile heading patterns once, reuse across calls
4. **Early Exit**: Return immediately on empty input

### 8.3 Testing Strategy

- **Parametrized Tests**: Multiple offset values (0, 1, 5, 6, 10)
- **Golden Files**: Expected output for each test case
- **Determinism**: Run same input 3×, compare bytes
- **Corpus-Based**: Use real markdown files from test corpus

---

## 9. Success Metrics

| Metric | Target | Method |
|--------|--------|--------|
| ATX Pass Rate | 100% | Unit tests + golden files |
| Setext Pass Rate | 100% | Unit tests + golden files |
| Overflow Correctness | 100% | Verify no H7+ in output |
| Determinism | 100% | 3-run byte-for-byte comparison |
| Code Coverage | ≥ 90% | Coverage report |
| Performance | <100 ms | Benchmark on 1 MB file |

---

## 10. Blockers & Dependencies

### 10.1 External Dependencies

- **Core Types (A2)**: `SourceLocation` (optional, for error reporting)
- **Test Corpus**: V09, V10 test files (Markdown with headings)

### 10.2 Internal Dependencies

- None (standalone module)

### 10.3 Potential Blockers

- No blockers identified
- Can be developed independently once Core Types are available

---

## 11. Scope Exclusions

**Out of Scope (v0.1):**

- Handling code blocks (e.g., markdown within ````python` blocks)
- Custom heading ID/anchor preservation
- Heading outline generation
- YAML frontmatter in Markdown
- LaTeX or mathematical expressions in headings

**These are suitable for v0.1.1+ enhancements.**

---

## 12. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-09 | Claude | Initial PRD for C1 task |

---

## 13. Questions for Clarification

1. **Underline Length**: For Setext headings, should underline length exactly match heading text, or is any length acceptable?
   - **Assumption**: Any length ≥ 1 is acceptable (common Markdown leniency)

2. **Code Block Handling**: Should headings within code blocks be transformed?
   - **Assumption**: No, out of scope for v0.1. Only transform top-level headings.

3. **Inline Formatting**: Should heading text preserve inline Markdown (bold, italic)?
   - **Assumption**: Yes, extract and preserve all formatting within heading text.

4. **Trailing Whitespace**: Should trailing spaces on heading lines be preserved?
   - **Assumption**: Yes, preserve exactly as found in input.

---

## 14. References

- **PRD v0.0.1**: `00_PRD_001.md` §3.3 (Heading adjustment requirements)
- **Design Spec v0.0.1**: `01_DESIGN_SPEC_001.md` §4.3 (Markdown emission algorithm)
- **Workplan**: `Workplan.md` Phase 5, Task C1
- **Markdown Spec**: CommonMark (https://spec.commonmark.org/)
  - ATX headings: §4.2
  - Setext headings: §4.3

---

**Ready for implementation.**
