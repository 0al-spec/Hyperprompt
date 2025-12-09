# C2: Markdown Emitter — PRD

**Phase:** Phase 5 (Markdown Emission)
**Priority:** P0 (Critical)
**Estimated Effort:** 8 hours
**Dependencies:** B4 (Recursive Compilation) ✅, C1 (Heading Adjuster) ✅
**Status:** INPROGRESS

---

## 1. Objective

Implement a robust Markdown emitter that traverses the fully resolved AST and generates well-formed output documents. The emitter must correctly calculate effective depths for nested content, generate appropriate headings, embed file content with adjusted heading levels, insert proper spacing between sections, and ensure deterministic output following Markdown conventions.

**Success Criterion:** All test cases produce valid Markdown matching golden files, with correct heading hierarchy, proper content embedding, and deterministic formatting.

---

## 2. Scope & Intent

### 2.1 Primary Responsibility

Transform a fully resolved AST (produced by B4 — Recursive Compilation) into a single, coherent Markdown document. This involves:
- Traversing the AST tree structure
- Calculating effective depths for nested embeddings
- Generating headings from node literals or file references
- Embedding Markdown file content with adjusted headings
- Embedding Hypercode file content recursively
- Handling inline text literals as body content
- Ensuring proper spacing and formatting

### 2.2 Inputs & Outputs

**Input:**
- Resolved AST `Node` (root node with complete resolution information)
- Root directory path for resolving relative references
- Configuration settings (separator policy, formatting rules)

**Output:**
- Markdown document as `String`
- All line endings normalized to LF
- Document ends with exactly one LF
- Headings properly hierarchical based on effective depth
- Content embedded with correct depth offsets

### 2.3 Constraints

- Must preserve semantic hierarchy of AST in output
- Must handle depths 0-10 without corruption
- Headings beyond H6 must use bold fallback (`**text**`)
- Must integrate seamlessly with HeadingAdjuster (C1) for embedded Markdown
- No modification to resolved content (preserve exactly as loaded)
- Deterministic output (identical AST → identical output)
- Must support both `.md` and `.hc` embeddings at any depth

### 2.4 Assumptions

1. Input AST is fully resolved (all `resolution` fields populated by B4)
2. HeadingAdjuster (C1) is available and correctly transforms heading levels
3. All file content has been loaded and normalized to LF line endings
4. Circular dependencies have been detected and rejected (B4 responsibility)
5. Node depths are validated to be ≤ 10 (resolver responsibility)

---

## 3. Functional Requirements

### 3.1 Tree Traversal Algorithm

**FR1.1: Depth-First Traversal**
- Traverse AST in depth-first order, processing parent before children
- Maintain effective depth calculation: `effectiveDepth = parentDepth + node.depth`
- Track parent context to correctly calculate nesting levels

**FR1.2: Sibling Ordering**
- Process node children in order (preserve AST sequence)
- Insert blank lines between consecutive sibling sections
- Maintain consistent separator policy throughout document

**FR1.3: State Management**
- No global mutable state (pure functional traversal)
- Pass depth context explicitly through recursion
- Accumulate output incrementally (StringBuilder pattern)

### 3.2 Heading Generation

**FR2.1: Effective Depth Calculation**
- Formula: `effectiveDepth = parentDepth + node.depth`
- For root node (depth 0, parentDepth 0): effectiveDepth = 0
- Heading level: `headingLevel = effectiveDepth + 1`

**FR2.2: Heading Text Determination**

Based on resolution kind:

1. **InlineText**: Use node literal as heading
   ```
   node.literal = "Introduction"
   → heading = "# Introduction"
   ```

2. **MarkdownFile**: Use node literal (file reference) as heading
   ```
   node.literal = "docs/guide.md"
   → heading = "# docs/guide.md" or extract filename
   ```

3. **HypercodeFile**: Use node literal as section heading
   ```
   node.literal = "chapter1.hc"
   → heading = "# chapter1.hc" or extract filename
   ```

**FR2.3: Heading Formatting**

For `headingLevel` ≤ 6:
```
hashes = "#" repeated headingLevel times
output = hashes + " " + headingText + "\n"
```

For `headingLevel` > 6 (overflow):
```
output = "**" + headingText + "**\n"
```

**Examples:**
```
effectiveDepth = 0 → heading = "# Text"    (H1)
effectiveDepth = 2 → heading = "### Text"  (H3)
effectiveDepth = 5 → heading = "###### Text" (H6)
effectiveDepth = 6 → heading = "**Text**"  (bold fallback)
```

### 3.3 Content Embedding

**FR3.1: Inline Text Handling**

When `node.resolution == .inlineText`:
- Emit heading based on node.literal
- No additional body content
- Proceed to emit children

**FR3.2: Markdown File Embedding**

When `node.resolution == .markdownFile(path, content)`:
1. Emit heading for the file reference
2. Calculate heading offset: `offset = effectiveDepth + 1`
3. Apply HeadingAdjuster to content:
   ```swift
   let adjuster = HeadingAdjuster()
   let adjusted = adjuster.adjustHeadings(in: content, offset: offset)
   ```
4. Append adjusted content to output
5. Proceed to emit children (if any)

**Example:**
```
Node at effectiveDepth 1, references "guide.md" containing "# Introduction"
→ Emit "## guide.md\n"
→ Adjust "# Introduction" with offset 2 → "### Introduction"
→ Append adjusted content
```

**FR3.3: Hypercode File Embedding**

When `node.resolution == .hypercodeFile(path, childAST)`:
1. Emit heading for the file reference
2. **Do NOT** recursively emit the childAST here
   - Child nodes are already merged into parent AST by B4
   - They appear as children of current node
3. Proceed to emit children normally

**FR3.4: Forbidden Extension Handling**

When `node.resolution == .forbidden(extension)`:
- This case should not occur if resolver is correct
- If encountered: emit heading and add error comment
- Or: throw internal error (resolver should have rejected)

### 3.4 Blank Line Insertion

**FR4.1: Separator Between Siblings**

Between consecutive children of the same parent:
```
for i, child in node.children.enumerated() {
    if i > 0 {
        output.append("\n")  // Blank line separator
    }
    emit(child, effectiveDepth, &output)
}
```

**FR4.2: No Separator After Parent Heading**

After emitting a heading, do NOT insert blank line before content/children
```
output.append("## Heading\n")
// NO blank line here
output.append(content)
```

**FR4.3: Content Boundary Handling**

- Embedded Markdown content already has internal line breaks preserved
- Do not add extra blank lines at start/end of embedded content
- Trust HeadingAdjuster to preserve content structure

### 3.5 Output Formatting

**FR5.1: Line Ending Normalization**
- All output uses LF (`\n`) exclusively
- No CRLF or CR in final output
- HeadingAdjuster ensures embedded content uses LF

**FR5.2: Trailing Newline**
- Output must end with exactly one LF
- Trim any extra trailing newlines before final append
- Final operation: ensure single `\n` at end

**FR5.3: Determinism**
- Identical AST inputs produce byte-for-byte identical outputs
- No timestamps, random values, or platform-specific behavior
- Consistent traversal order (children processed in array order)

---

## 4. Non-Functional Requirements

### 4.1 Performance

- **Large Trees**: Process AST with 1000+ nodes in < 5 seconds
- **Deep Nesting**: Handle maximum depth (10 levels) without stack overflow
- **Linear Complexity**: Time complexity O(N) where N = total nodes
- **Memory Efficiency**: Accumulate output incrementally (avoid repeated string copying)

**Target Metrics:**
- 100 nodes: < 100 ms
- 1000 nodes: < 5 seconds
- 10000 nodes: < 60 seconds

### 4.2 Correctness & Determinism

- **Identical Outputs**: Same AST produces identical Markdown every time
- **Platform Independence**: No platform-specific line endings or file paths
- **Depth Accuracy**: Effective depth calculated correctly at every level
- **Heading Integrity**: All headings follow Markdown conventions

### 4.3 Robustness

- **Malformed AST**: Handle unexpected resolution states gracefully
- **Deep Nesting**: Support full depth range (0-10) without errors
- **Empty Nodes**: Handle nodes with empty literals or no children
- **Large Content**: Process large embedded Markdown files (> 1 MB)

### 4.4 Testability

- **Pure Functions**: Emitter logic is pure (no side effects)
- **Mockable Dependencies**: HeadingAdjuster can be tested independently
- **Golden Files**: Output compared against reference files byte-for-byte
- **Coverage**: All code paths exercised by test corpus

---

## 5. Detailed TODO Breakdown

### Phase 1: Core Data Structure & Emitter Infrastructure

**Effort:** 1.5 hours

- [ ] **[High]** Create `MarkdownEmitter` struct with public API
  - **Input**: `root: Node`, `config: EmitterConfig`
  - **Output**: `String` (Markdown document)
  - **Method Signature**: `func emit(_ node: Node) -> String`
  - **Acceptance**: Compiles, basic structure in place

- [ ] **[High]** Define `EmitterConfig` struct
  - Fields: `insertBlankLines: Bool`, `useFilenameAsHeading: Bool`
  - Default values for standard behavior
  - **Acceptance**: Config struct documented and tested

- [ ] **[Medium]** Create internal helper structures
  - `EmitterContext`: Tracks effective depth, output buffer
  - `StringBuilder`: Efficient string accumulation
  - **Acceptance**: Helpers compile and have basic unit tests

- [ ] **[High]** Implement output buffer management
  - Initialize with capacity estimate (avoid repeated allocations)
  - Methods: `append(_:)`, `appendLine(_:)`, `insertBlankLine()`
  - **Acceptance**: Buffer operations efficient, no memory leaks

**Acceptance Criteria:**
- MarkdownEmitter compiles without errors
- Basic structure ready for traversal implementation
- Helper types tested independently

---

### Phase 2: Tree Traversal & Heading Generation

**Effort:** 2 hours

- [ ] **[High]** Implement depth-first tree traversal
  - Recursive function: `emit(node: Node, parentDepth: Int, output: inout StringBuilder)`
  - Base case: leaf nodes (no children)
  - Recursive case: process children after node content
  - **Acceptance**: Traversal visits all nodes exactly once

- [ ] **[High]** Implement effective depth calculation
  - Formula: `effectiveDepth = parentDepth + node.depth`
  - Validate: `effectiveDepth` never exceeds 10
  - Pass updated depth to children: `emit(child, effectiveDepth, &output)`
  - **Acceptance**: Unit tests verify depth at all levels 0-10

- [ ] **[High]** Implement heading generation
  - Extract heading text from node.literal
  - Calculate heading level: `headingLevel = effectiveDepth + 1`
  - Generate heading string:
    ```swift
    if headingLevel <= 6 {
        let hashes = String(repeating: "#", count: headingLevel)
        return "\(hashes) \(text)\n"
    } else {
        return "**\(text)**\n"
    }
    ```
  - **Acceptance**: Test all heading levels 1-6 plus overflow (7+)

- [ ] **[Medium]** Handle heading text extraction
  - Use node.literal as-is for inline text
  - Option to extract filename from paths (e.g., "docs/guide.md" → "guide")
  - Preserve special characters in literals
  - **Acceptance**: Various literal formats handled correctly

- [ ] **[High]** Integrate heading generation into traversal
  - Emit heading before processing node content
  - Order: heading → content → children
  - **Acceptance**: Output structure matches expected hierarchy

**Acceptance Criteria:**
- Traversal correctly processes trees of depth 0-10
- Headings generated with correct level based on effective depth
- H7+ converted to bold text
- Output shows proper hierarchical structure

---

### Phase 3: Content Embedding (Markdown, Hypercode, Inline)

**Effort:** 2.5 hours

- [ ] **[High]** Implement inline text handling
  - When `resolution == nil` or `.inlineText`: emit heading only
  - No additional body content (children may follow)
  - **Acceptance**: Inline text nodes produce heading + children

- [ ] **[High]** Implement Markdown file embedding
  - Detect: `case .markdownFile(let path, let content)`
  - Calculate offset: `offset = effectiveDepth + 1`
  - Invoke HeadingAdjuster:
    ```swift
    let adjuster = HeadingAdjuster()
    let adjusted = adjuster.adjustHeadings(in: content, offset: offset)
    ```
  - Append adjusted content to output
  - **Acceptance**: Markdown files embedded with correct heading adjustment

- [ ] **[Medium]** Test Markdown embedding at various depths
  - Depth 0: offset = 1 (H1 in file → H2 in output)
  - Depth 3: offset = 4 (H1 in file → H5 in output)
  - Depth 6+: overflow (H1 in file → bold in output)
  - **Acceptance**: All depth scenarios tested with golden files

- [ ] **[High]** Implement Hypercode file embedding
  - Detect: `case .hypercodeFile(let path, let childAST)`
  - Emit heading for file reference
  - Process node children (child AST already merged by B4)
  - **Acceptance**: Hypercode embeddings show correct nesting

- [ ] **[Low]** Handle forbidden extension case
  - Detect: `case .forbidden(let ext)`
  - Decision: emit heading + error comment OR throw internal error
  - Log warning in verbose mode
  - **Acceptance**: Forbidden cases handled without crash

- [ ] **[High]** Test mixed content scenarios
  - Tree with inline text, Markdown files, Hypercode files
  - Multiple nesting levels
  - Verify correct heading offsets and content preservation
  - **Acceptance**: Mixed trees produce correct output

**Acceptance Criteria:**
- Inline text nodes emit heading only
- Markdown files embedded with adjusted headings (via C1)
- Hypercode files show proper nesting
- All resolution kinds handled
- Mixed content trees produce correct hierarchical output

---

### Phase 4: Heading Adjustment Integration

**Effort:** 1 hour

- [ ] **[High]** Import HeadingAdjuster from C1
  - Add dependency in module configuration
  - Verify API compatibility: `adjustHeadings(in:offset:) -> String`
  - **Acceptance**: HeadingAdjuster imports and compiles

- [ ] **[High]** Test integration with HeadingAdjuster
  - Create test cases with Markdown containing headings
  - Verify offset calculation: `offset = effectiveDepth + 1`
  - Confirm output matches HeadingAdjuster expectations
  - **Acceptance**: Integration tests pass

- [ ] **[Medium]** Handle HeadingAdjuster edge cases
  - Empty Markdown content: return empty
  - No headings in content: pass through unchanged
  - All headings overflow: converted to bold
  - **Acceptance**: Edge cases tested

- [ ] **[Low]** Optimize HeadingAdjuster calls
  - Avoid redundant calls for same content
  - Cache adjuster instance if stateless
  - **Acceptance**: No performance regression

**Acceptance Criteria:**
- HeadingAdjuster seamlessly integrated
- Offset calculation correct at all depths
- Edge cases handled without errors
- Integration tests confirm correct heading transformation

---

### Phase 5: Output Formatting & Determinism

**Effort:** 1 hour

- [ ] **[High]** Implement blank line insertion between siblings
  - Logic: insert `\n` before child if index > 0
  - Apply only between siblings, not after parent heading
  - **Acceptance**: Blank lines appear only between siblings

- [ ] **[Medium]** Test separator policy
  - Single child: no extra blank lines
  - Multiple children: blank line between each pair
  - Deep nesting: separators at each level
  - **Acceptance**: Separator tests pass with golden files

- [ ] **[High]** Implement line ending normalization
  - Ensure all `\n` (LF) in output
  - No CRLF or CR
  - HeadingAdjuster guarantees LF in embedded content
  - **Acceptance**: Output contains only LF

- [ ] **[High]** Implement trailing newline guarantee
  - After assembling output, ensure ends with exactly one `\n`
  - Trim extra newlines: `output.trimmingCharacters(in: .newlines) + "\n"`
  - **Acceptance**: All outputs end with single LF

- [ ] **[High]** Verify determinism
  - Run same AST through emitter 3 times
  - Compare outputs byte-for-byte
  - Ensure no timestamps, randomness, or platform differences
  - **Acceptance**: All runs produce identical output

**Acceptance Criteria:**
- Blank lines inserted correctly between siblings
- All line endings are LF
- Output ends with exactly one LF
- Determinism verified (3-run comparison)

---

### Phase 6: Testing & Edge Cases

**Effort:** 2 hours

**Unit Tests: Tree Traversal**

- [ ] **[High]** Test single root node (inline text)
  - Depth 0 → H1
  - No children
  - **Expected**: `# Text\n`

- [ ] **[High]** Test nested hierarchy (3 levels)
  - Root + child + grandchild
  - Depths 0, 1, 2 → H1, H3, H5
  - **Expected**: Correct heading levels

- [ ] **[High]** Test maximum depth (10 levels)
  - Nodes at depths 0-10
  - Effective depths up to 10 → headings up to H11 (overflow)
  - **Expected**: H1-H6, then bold for H7+

**Unit Tests: Content Embedding**

- [ ] **[High]** Test Markdown file at depth 0
  - File contains H1, H2, H3
  - Offset = 1 → H2, H3, H4 in output
  - **Expected**: Match golden file

- [ ] **[High]** Test Markdown file at depth 5
  - File contains H1
  - Offset = 6 → Overflow to bold
  - **Expected**: Bold text in output

- [ ] **[High]** Test Hypercode file embedding
  - `.hc` reference at depth 2
  - Child AST merged with parent
  - **Expected**: Correct nesting and heading levels

**Integration Tests: Test Corpus**

- [ ] **[High]** Test V01: Single root node with inline text
  - **Expected**: `# Root\n`

- [ ] **[High]** Test V03: Nested hierarchy 3 levels deep
  - **Expected**: H1, H2, H3 structure

- [ ] **[High]** Test V04: Single Markdown file reference at root
  - **Expected**: File embedded with offset 1

- [ ] **[High]** Test V06: Single Hypercode file reference
  - **Expected**: Nested structure preserved

- [ ] **[High]** Test V07: Nested Hypercode files (3 levels)
  - **Expected**: Deep hierarchy with correct offsets

- [ ] **[High]** Test V09: Markdown with headings H1-H4
  - **Expected**: Headings adjusted correctly

- [ ] **[High]** Test V13: Maximum depth of 10 levels
  - **Expected**: Overflow handling for deep headings

**Edge Case Tests**

- [ ] **[Medium]** Empty node literal: `""`
  - **Expected**: Heading with empty text or skip

- [ ] **[Medium]** Node with no children
  - **Expected**: Heading only, no blank lines

- [ ] **[Medium]** Node with single child
  - **Expected**: No blank line between heading and child

- [ ] **[High]** Multiple siblings at same level
  - **Expected**: Blank lines between siblings

- [ ] **[Medium]** Large embedded Markdown (> 1 MB)
  - **Expected**: Process without memory issues

- [ ] **[High]** Determinism test
  - Same input 3× → byte-for-byte identical
  - **Expected**: Perfect match

**Acceptance Criteria:**
- ≥ 95% of test cases pass
- All valid test corpus files (V01-V14) produce correct output
- Edge cases handled without crashes
- Golden file comparisons succeed
- Determinism verified

---

## 6. Acceptance Criteria Summary

### Functional AC

- ✅ Tree traversal processes all nodes in depth-first order
- ✅ Effective depth calculated correctly: `parentDepth + node.depth`
- ✅ Headings generated with correct level based on effective depth
- ✅ H7+ headings converted to bold fallback
- ✅ Inline text produces heading only
- ✅ Markdown files embedded with adjusted headings (via C1)
- ✅ Hypercode files show correct nested structure
- ✅ Blank lines inserted between siblings
- ✅ Output normalized to LF endings
- ✅ Output ends with exactly one LF

### Quality AC

- ✅ ≥ 95% of test cases pass
- ✅ 100% determinism: identical AST → byte-for-byte output
- ✅ All test corpus files (V01-V14) produce golden file matches
- ✅ No crashes on edge cases (empty nodes, deep nesting)
- ✅ Code coverage ≥ 90%
- ✅ Performance targets met (1000 nodes < 5s)

### Integration AC

- ✅ Integrates with B4 (accepts fully resolved AST)
- ✅ Integrates with C1 (uses HeadingAdjuster for Markdown)
- ✅ Produces output ready for file writing (D2)
- ✅ Works with all valid test corpus files

---

## 7. Technical Design Notes

### 7.1 Algorithm: Recursive Emission with Depth Context

```swift
func emit(_ node: Node, parentDepth: Int = 0, output: inout StringBuilder) {
    // Calculate effective depth
    let effectiveDepth = parentDepth + node.depth

    // Validate depth
    assert(effectiveDepth <= 10, "Depth exceeds maximum (resolver should prevent)")

    // Generate heading
    let headingLevel = effectiveDepth + 1
    let heading = generateHeading(text: node.literal, level: headingLevel)
    output.appendLine(heading)

    // Embed content based on resolution
    switch node.resolution {
    case .inlineText:
        // No additional content
        break

    case let .markdownFile(_, content):
        let offset = effectiveDepth + 1
        let adjuster = HeadingAdjuster()
        let adjusted = adjuster.adjustHeadings(in: content, offset: offset)
        output.append(adjusted)

    case let .hypercodeFile(_, _):
        // Child AST already merged into node.children by B4
        // Process children normally below
        break

    case let .forbidden(ext):
        // Error case - should not occur
        output.appendLine("<!-- Error: Forbidden extension \(ext) -->")

    case nil:
        // Treat as inline text
        break
    }

    // Emit children with blank line separators
    for (index, child) in node.children.enumerated() {
        if index > 0 {
            output.appendLine("")  // Blank line between siblings
        }
        emit(child, effectiveDepth, &output)
    }
}
```

### 7.2 Heading Generation Detail

```swift
func generateHeading(text: String, level: Int) -> String {
    if level > 6 {
        // Overflow: convert to bold
        return "**\(text)**"
    } else {
        // Standard heading
        let hashes = String(repeating: "#", count: level)
        return "\(hashes) \(text)"
    }
}
```

### 7.3 Data Flow Diagram

```
Resolved AST (from B4)
        ↓
[Initialize Emitter]
        ↓
[Start Traversal: root node, parentDepth=0]
        ↓
[Calculate effectiveDepth = parentDepth + node.depth]
        ↓
[Generate Heading: level = effectiveDepth + 1]
        ↓
[Append Heading to Output]
        ↓
[Check Resolution Kind]
    ├─→ [InlineText] ─→ [No content, skip to children]
    ├─→ [MarkdownFile] ─→ [Apply HeadingAdjuster] ─→ [Append adjusted content]
    ├─→ [HypercodeFile] ─→ [Children already merged, skip to children]
    └─→ [Forbidden] ─→ [Log error or throw]
        ↓
[For each child:]
    ├─→ [If index > 0: insert blank line]
    └─→ [Recurse: emit(child, effectiveDepth, output)]
        ↓
[After all nodes processed]
        ↓
[Ensure output ends with single LF]
        ↓
Final Markdown Document
```

### 7.4 StringBuilder Pattern

```swift
struct StringBuilder {
    private var buffer: [String] = []

    mutating func append(_ text: String) {
        buffer.append(text)
    }

    mutating func appendLine(_ text: String) {
        buffer.append(text)
        buffer.append("\n")
    }

    func build() -> String {
        let result = buffer.joined()
        // Ensure single trailing LF
        let trimmed = result.trimmingCharacters(in: .newlines)
        return trimmed.isEmpty ? "" : trimmed + "\n"
    }
}
```

### 7.5 Effective Depth Examples

```
AST Structure:
    Root (depth=0)
        ├─ Child1 (depth=1)
        │   └─ Grandchild1 (depth=2)
        └─ Child2 (depth=1)

Traversal:
    emit(Root, parentDepth=0)
        effectiveDepth = 0 + 0 = 0 → H1

        emit(Child1, parentDepth=0)
            effectiveDepth = 0 + 1 = 1 → H2

            emit(Grandchild1, parentDepth=1)
                effectiveDepth = 1 + 2 = 3 → H4

        emit(Child2, parentDepth=0)
            effectiveDepth = 0 + 1 = 1 → H2

Output:
    # Root
    ## Child1
    #### Grandchild1

    ## Child2
```

---

## 8. Success Metrics

| Metric | Target | Verification Method |
|--------|--------|---------------------|
| Tree Traversal Correctness | 100% | Unit tests covering all node counts and depths |
| Heading Level Accuracy | 100% | Tests verify H1-H6 at correct depths, H7+ → bold |
| Content Embedding Accuracy | 100% | Golden file comparison for all test cases |
| Blank Line Insertion | 100% | Tests verify separators between siblings only |
| Line Ending Normalization | 100% | Output contains only LF characters |
| Trailing Newline | 100% | All outputs end with exactly one LF |
| Determinism | 100% | 3-run byte-for-byte comparison |
| Test Corpus Pass Rate | 100% | All V01-V14 valid tests match golden files |
| Code Coverage | ≥ 90% | Coverage report from test suite |
| Performance (1000 nodes) | < 5 seconds | Benchmark tests |
| Performance (100 nodes) | < 100 ms | Benchmark tests |

---

## 9. Implementation Notes

### 9.1 Language Features (Swift)

- Use `struct MarkdownEmitter` (value type, no shared state)
- Use `inout` parameters for output accumulation (avoid copying)
- Use `switch` on `ResolutionKind` for exhaustive handling
- Use `String(repeating:count:)` for hash generation
- Use `Array.enumerated()` for index-based sibling detection

### 9.2 Optimization Opportunities

1. **StringBuilder Pattern**: Accumulate strings in array, join once at end (avoid O(N²) concatenation)
2. **Depth Validation**: Assert depth ≤ 10 (resolver should enforce, emitter double-checks)
3. **HeadingAdjuster Reuse**: Create single instance, call multiple times (if stateless)
4. **Early Exit**: Return immediately for empty AST
5. **Capacity Hints**: Initialize StringBuilder with estimated capacity based on node count

### 9.3 Testing Strategy

- **Parametrized Tests**: Test all depths 0-10, all resolution kinds
- **Golden Files**: Reference outputs for all test corpus files
- **Differential Testing**: Compare against hand-written expected outputs
- **Determinism**: Run emitter 3× on same input, verify identical bytes
- **Performance**: Benchmark with trees of 100, 1000, 10000 nodes

---

## 10. Blockers & Dependencies

### 10.1 External Dependencies

- **B4 (Recursive Compilation)**: ✅ **Completed** — Provides fully resolved AST with all `resolution` fields populated
- **C1 (Heading Adjuster)**: ✅ **Completed** — Provides heading transformation for embedded Markdown

### 10.2 Internal Dependencies

- **Core Types (A2)**: ✅ **Completed** — `Node`, `ResolutionKind`, `SourceLocation`
- **Parser (A4)**: ✅ **Completed** — AST structure

### 10.3 Potential Blockers

**No blockers identified.** All dependencies are satisfied.

- B4 provides correct AST structure with merged child nodes
- C1 provides heading adjustment functionality
- Can proceed with implementation immediately

---

## 11. Scope Exclusions (Out of Scope for C2)

**Not included in C2 (handled elsewhere or deferred):**

- Manifest generation (covered by C3)
- File writing to disk (covered by D2 — Compiler Driver)
- CLI argument parsing (covered by D1)
- Error diagnostics formatting (covered by D3)
- Statistics collection (covered by D4)
- Validation of AST structure (resolver's responsibility)
- Circular dependency detection (B2, B4)
- Path traversal security checks (resolver's responsibility)

**Future Enhancements (v0.1.1+):**

- Custom separator policies (configurable blank line rules)
- Heading ID/anchor generation
- Table of contents generation
- Front matter injection
- Custom heading text extraction (e.g., use filename instead of path)

---

## 12. References

### 12.1 Project Documents

- **PRD v0.0.1**: `/home/user/Hyperprompt/DOCS/PRD/v0.0.1/00_PRD_001.md` §3.3 (Output generation requirements)
- **Design Spec v0.0.1**: `/home/user/Hyperprompt/DOCS/PRD/v0.0.1/01_DESIGN_SPEC_001.md` §4.3 (Markdown emission algorithm)
- **Workplan v2.0.0**: `/home/user/Hyperprompt/DOCS/Workplan.md` Phase 5, Task C2

### 12.2 Dependency Tasks

- **B4 — Recursive Compilation**: `/home/user/Hyperprompt/DOCS/TASKS_ARCHIVE/B4_Recursive_Compilation.md`
- **C1 — Heading Adjuster**: `/home/user/Hyperprompt/DOCS/TASKS_ARCHIVE/C1_Heading_Adjuster.md`

### 12.3 Specifications

- **Markdown Spec**: CommonMark (https://spec.commonmark.org/)
  - ATX headings: §4.2
  - Setext headings: §4.3

---

## 13. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-09 | Claude Code | Initial PRD for C2 task |

---

## 14. Questions for Clarification

### 14.1 Heading Text for File References

**Question**: When emitting a heading for a file reference (e.g., `"docs/guide.md"`), should we:
- Option A: Use the full path as heading text: `# docs/guide.md`
- Option B: Extract filename only: `# guide.md`
- Option C: Extract filename without extension: `# guide`

**Assumption for v0.1**: Use **Option A** (full path) for traceability. Can add config option in v0.1.1.

### 14.2 Blank Lines Around Embedded Content

**Question**: Should there be blank lines before/after embedded Markdown content?
- Current assumption: No extra blank lines (trust embedded content structure)
- Alternative: Insert blank line before embedded content for visual separation

**Assumption for v0.1**: No extra blank lines (preserve content as-is).

### 14.3 Forbidden Extension Handling

**Question**: If emitter encounters `.forbidden(ext)` resolution, should it:
- Option A: Throw internal error (resolver should have rejected)
- Option B: Emit heading + error comment
- Option C: Skip the node silently

**Assumption for v0.1**: Use **Option A** (throw internal error) since resolver should prevent this.

---

**Ready for implementation.**

---

**Archived:** 2025-12-09
