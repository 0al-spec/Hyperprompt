# PRD — EE-EXT-3-FULL: Complete Source Map Implementation

**Task ID:** EE-EXT-3-FULL
**Task Name:** Complete Source Map Implementation
**Priority:** P2 (Medium)
**Phase:** Phase 12 — EditorEngine API Enhancements
**Estimated Effort:** 12-18 hours
**Dependencies:** EE-EXT-3 (stub ✅), EE8 (EditorEngine ✅)
**Status:** 🔵 TODO — Not started
**Date:** 2025-12-30
**Author:** Hyperprompt Planning System

---

## 1. Scope & Intent

### 1.1 Objective

Complete the Source Map Generation implementation by integrating SourceMapBuilder with the Emitter to track actual source file locations during compilation. Replace the current stub implementation that maps all output lines to the entry file with a real implementation that tracks multi-file includes and transformations.

**Restatement in Precise Terms:**
1. Modify `MarkdownEmitter` to accept optional `SourceMapBuilder` parameter
2. Track source file path and line number for each emitted output line
3. Handle file inclusions (@"file.hc" and @"file.md") with correct source tracking
4. Account for heading level adjustments and line transformations
5. Replace stub `buildStubSourceMap()` in `EditorCompiler` with Emitter-based implementation
6. Write comprehensive unit and integration tests

### 1.2 Primary Deliverables

| Deliverable | Description |
|------------|-------------|
| **Emitter Integration** | SourceMapBuilder integrated into MarkdownEmitter |
| **Multi-File Support** | Accurate source tracking for nested includes |
| **Transformation Tracking** | Heading adjustments and line shifts tracked |
| **Test Coverage** | Unit + integration tests for source map accuracy |
| **Documentation** | Updated API docs and usage examples |

### 1.3 Success Criteria

1. ✅ `MarkdownEmitter` can build source maps during emission
2. ✅ Output lines map to correct source files (not just entry file)
3. ✅ Included files (@"...") tracked with accurate line numbers
4. ✅ Heading adjustments don't break source mappings
5. ✅ Unit tests pass with >90% coverage
6. ✅ VSC-10 (bidirectional navigation) works with multi-file projects
7. ✅ No performance regression (compilation still <200ms for medium projects)

### 1.4 Constraints

- Must not break existing Emitter functionality
- Must maintain backward compatibility with EditorCompiler API
- SourceMapBuilder optional (can compile without source maps)
- Cannot add external dependencies (pure Swift)
- Must work within Editor trait (#if Editor)

### 1.5 Assumptions

- Node.resolution contains accurate source file paths
- HeadingAdjuster transformations are deterministic
- StringBuilder line counting is 0-indexed (output lines)
- SourceLocation uses 1-indexed line numbers (source lines)
- Emitter processes nodes in depth-first order

### 1.6 External Dependencies

- **SourceMap.swift** — Already exists (EE-EXT-3 stub)
- **SourceMapBuilder** — Already exists (EE-EXT-3 stub)
- **MarkdownEmitter** — Needs modification
- **EditorCompiler** — Needs modification (remove stub)
- **Node.resolution** — Provides source file paths

---

## 2. Hierarchical Task Breakdown

### Phase 1: Design & Planning (2-3 hours)

#### 2.1.1 Read and Understand Current Implementation **[High, 1h]**

**Input:**
- `Sources/Emitter/MarkdownEmitter.swift` (current implementation)
- `Sources/EditorEngine/SourceMap.swift` (stub)
- `Sources/EditorEngine/EditorCompiler.swift:118-147` (stub usage)

**Process:**
1. Trace `MarkdownEmitter.emit()` execution flow
2. Identify where `StringBuilder.appendLine()` is called
3. Map out how `embedContent()` handles different resolution types
4. Understand Node.resolution structure for source file tracking

**Output:**
- Design notes documenting:
  - Call graph of emit → emitNode → embedContent → appendLine
  - List of all appendLine() call sites
  - Source file information available at each call site

**Acceptance Criteria:**
- [ ] Can explain how output lines are generated
- [ ] Can trace source file path from Node to output
- [ ] Identified all places where source tracking needed

---

#### 2.1.2 Design Source Tracking Architecture **[High, 1-2h]**

**Input:**
- Understanding from 2.1.1
- SourceMap/SourceMapBuilder API

**Process:**
1. Design how to pass SourceMapBuilder through emitNode recursion
2. Design how StringBuilder tracks current output line number
3. Design how to extract source file path from Node.resolution
4. Design how to track source line numbers through Markdown content
5. Design how to handle heading adjustments (offset calculations)

**Output:**
- Architecture document covering:
  - Modified MarkdownEmitter signature: `emit(_ root: Node, sourceMapBuilder: SourceMapBuilder?) -> String`
  - Enhanced StringBuilder with line tracking: `currentLineNumber: Int`
  - Source context structure: `struct SourceContext { filePath: String, baseLine: Int }`
  - Mapping strategy for each resolution type (inlineText, markdownFile, hypercodeFile)

**Acceptance Criteria:**
- [ ] Design handles all Node.resolution types
- [ ] Design accounts for heading level adjustments
- [ ] Design is backward-compatible (sourceMapBuilder optional)
- [ ] Design doesn't require parsing Markdown content

---

### Phase 2: Emitter Integration (4-6 hours)

#### 2.2.1 Enhance StringBuilder with Line Tracking **[High, 1h]**

**Input:**
- `Sources/Emitter/MarkdownEmitter.swift:193-233` (StringBuilder)

**Process:**
1. Add `private var currentLine: Int = 0` to StringBuilder
2. Modify `appendLine()` to increment currentLine
3. Modify `append()` to count newlines in text and update currentLine
4. Add getter `var lineNumber: Int { currentLine }`
5. Update `build()` to reset line counter (or make StringBuilder non-mutating)

**Output:**
- Modified StringBuilder with:
```swift
struct StringBuilder {
    private var buffer: [String] = []
    private var currentLine: Int = 0  // 0-indexed output line

    var lineNumber: Int { currentLine }

    mutating func append(_ text: String) {
        buffer.append(text)
        // Count newlines in text
        currentLine += text.filter { $0 == "\n" }.count
    }

    mutating func appendLine(_ text: String) {
        buffer.append(text)
        buffer.append("\n")
        currentLine += 1
    }

    func build() -> String { /* existing */ }
}
```

**Acceptance Criteria:**
- [ ] `lineNumber` accurately tracks current output line (0-indexed)
- [ ] Works correctly for multi-line appends
- [ ] Existing tests still pass
- [ ] No performance regression

**Files:**
- `Sources/Emitter/MarkdownEmitter.swift` (modify StringBuilder)

---

#### 2.2.2 Add SourceMapBuilder Parameter to MarkdownEmitter **[High, 2h]**

**Input:**
- Design from 2.1.2
- Enhanced StringBuilder from 2.2.1

**Process:**
1. Add optional sourceMapBuilder to MarkdownEmitter.init():
   ```swift
   private let sourceMapBuilder: SourceMapBuilder?

   public init(config: EmitterConfig = EmitterConfig(), sourceMapBuilder: SourceMapBuilder? = nil) {
       self.config = config
       self.headingAdjuster = HeadingAdjuster()
       self.sourceMapBuilder = sourceMapBuilder
   }
   ```

2. Pass source context through emitNode recursion:
   ```swift
   private func emitNode(_ node: Node, parentDepth: Int, sourceContext: SourceContext, output: inout StringBuilder)
   ```

3. Define SourceContext:
   ```swift
   private struct SourceContext {
       let filePath: String  // Current source file
       let baseLine: Int     // Line offset in source file (for includes)
   }
   ```

4. Update emit() to initialize sourceContext with entry file

**Output:**
- Modified MarkdownEmitter with:
  - Optional sourceMapBuilder property
  - SourceContext struct
  - emitNode signature updated
  - emit() creates initial SourceContext

**Acceptance Criteria:**
- [ ] sourceMapBuilder is optional (backward compatible)
- [ ] SourceContext passed correctly through recursion
- [ ] Entry file path extracted from root Node
- [ ] Existing tests pass with sourceMapBuilder = nil

**Files:**
- `Sources/Emitter/MarkdownEmitter.swift`

---

#### 2.2.3 Implement Source Tracking in emitNode **[High, 2-3h]**

**Input:**
- Modified MarkdownEmitter from 2.2.2

**Process:**
1. Before emitting heading, record source mapping:
   ```swift
   if let builder = sourceMapBuilder {
       let sourceLocation = SourceLocation(
           filePath: sourceContext.filePath,
           line: sourceContext.baseLine + 1  // Convert to 1-indexed
       )
       builder.addMapping(outputLine: output.lineNumber, sourceLocation: sourceLocation)
   }
   ```

2. Update sourceContext when embedding content:
   - For `.markdownFile(path, content)`: create new context with path
   - For `.hypercodeFile(path, _)`: update context with path
   - For `.inlineText`: keep current context

3. Handle multi-line content embeddings:
   - Track how many lines were added by embedContent
   - Increment sourceContext.baseLine accordingly

4. Pass updated context to child nodes

**Output:**
- emitNode with source tracking:
  - Maps heading lines to source locations
  - Updates context for file inclusions
  - Tracks line offsets through content

**Acceptance Criteria:**
- [ ] Each output heading mapped to source location
- [ ] File inclusions update source context correctly
- [ ] Multi-line content tracked with line offsets
- [ ] Source mappings added before output appends
- [ ] Handles missing resolution gracefully (use parent context)

**Files:**
- `Sources/Emitter/MarkdownEmitter.swift`

---

#### 2.2.4 Handle Markdown Content Line Tracking **[Medium, 1-2h]**

**Input:**
- emitNode implementation from 2.2.3

**Process:**
1. In embedContent for `.markdownFile(path, content)`:
   ```swift
   case let .markdownFile(path, content):
       // Create new source context for this file
       let mdContext = SourceContext(filePath: path, baseLine: 0)

       // Track line-by-line mapping for markdown content
       if let builder = sourceMapBuilder {
           let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
           for (index, _) in lines.enumerated() {
               let sourceLoc = SourceLocation(
                   filePath: mdContext.filePath,
                   line: index + 1  // 1-indexed source line
               )
               builder.addMapping(outputLine: output.lineNumber + index, sourceLocation: sourceLoc)
           }
       }

       // Emit content (existing logic)
       let adjusted = headingAdjuster.adjustHeadings(in: content, offset: headingOffset)
       // ... rest of existing code
   ```

2. Account for HeadingAdjuster transformations (line count may change)

**Output:**
- embedContent with per-line source tracking for markdown files

**Acceptance Criteria:**
- [ ] Each markdown content line mapped to source
- [ ] Heading adjustments don't break mappings
- [ ] Line counts accurate after adjustments
- [ ] Empty lines tracked correctly

**Files:**
- `Sources/Emitter/MarkdownEmitter.swift`

---

### Phase 3: EditorCompiler Integration (2-3 hours)

#### 2.3.1 Remove Stub buildStubSourceMap **[High, 1h]**

**Input:**
- `Sources/EditorEngine/EditorCompiler.swift:118-147`

**Process:**
1. Delete `buildStubSourceMap()` function entirely
2. Update `compile()` to use MarkdownEmitter with sourceMapBuilder:
   ```swift
   // Create source map builder
   let sourceMapBuilder = SourceMapBuilder()

   // Create emitter with source map support
   let emitterConfig = EmitterConfig(
       insertBlankLines: true,
       useFilenameAsHeading: false
   )
   let emitter = MarkdownEmitter(config: emitterConfig, sourceMapBuilder: sourceMapBuilder)

   // Emit with source tracking
   let markdown = emitter.emit(result.resolvedAST)

   // Build source map
   let sourceMap = sourceMapBuilder.build()
   ```

3. Pass sourceMap to CompileResult

**Output:**
- EditorCompiler using real SourceMap from Emitter

**Acceptance Criteria:**
- [ ] buildStubSourceMap() deleted
- [ ] MarkdownEmitter called with sourceMapBuilder
- [ ] sourceMap built from SourceMapBuilder
- [ ] CompileResult contains real source map
- [ ] No references to "stub" in comments

**Files:**
- `Sources/EditorEngine/EditorCompiler.swift`

---

#### 2.3.2 Update CompilerDriver Integration **[Medium, 1h]**

**Input:**
- EditorCompiler from 2.3.1
- `Sources/CompilerDriver/CompilerDriver.swift`

**Process:**
1. Verify CompilerDriver doesn't break with new Emitter signature
2. Check if MarkdownEmitter is used elsewhere (search codebase)
3. Update any other call sites if needed
4. Ensure backward compatibility (sourceMapBuilder optional)

**Output:**
- CompilerDriver working with updated Emitter

**Acceptance Criteria:**
- [ ] CompilerDriver builds successfully
- [ ] All existing tests pass
- [ ] No breaking changes to public APIs
- [ ] CLI compilation still works

**Files:**
- `Sources/CompilerDriver/CompilerDriver.swift` (verify only)

---

#### 2.3.3 Test Integration with EditorEngine **[Medium, 1h]**

**Input:**
- Integrated EditorCompiler from 2.3.1-2.3.2

**Process:**
1. Create test fixture with multi-file project:
   ```
   entry.hc:
   # Main
   @"included.hc"
   @"doc.md"

   included.hc:
   ## Nested
   Some content

   doc.md:
   # Documentation
   More content
   ```

2. Compile with EditorCompiler
3. Inspect returned sourceMap
4. Verify mappings point to correct files

**Output:**
- Manual verification that source map works end-to-end

**Acceptance Criteria:**
- [ ] CompileResult.sourceMap not nil
- [ ] Source map contains mappings for all three files
- [ ] Mappings point to correct source files
- [ ] Line numbers roughly match expectations

**Files:**
- Manual test (no code changes)

---

### Phase 4: Unit Tests (3-4 hours)

#### 2.4.1 Test SourceMap Basic Functionality **[High, 1h]**

**Input:**
- `Sources/EditorEngine/SourceMap.swift`

**Process:**
1. Create `Tests/EditorEngineTests/SourceMapTests.swift`
2. Test SourceMap struct:
   - `testInitialization()` — empty map
   - `testLookupExisting()` — find mapped line
   - `testLookupMissing()` — return nil for unmapped
   - `testMultipleMappings()` — multiple lines
   - `testCodable()` — JSON encoding/decoding

3. Test SourceMapBuilder:
   - `testBuilderAddMapping()` — add single mapping
   - `testBuilderMultipleMappings()` — add many
   - `testBuilderBuild()` — build immutable map
   - `testBuilderThreadSafety()` — concurrent adds

**Output:**
- `Tests/EditorEngineTests/SourceMapTests.swift` with 8+ test cases

**Acceptance Criteria:**
- [ ] All SourceMap tests pass
- [ ] All SourceMapBuilder tests pass
- [ ] Coverage >90% for SourceMap.swift
- [ ] Thread safety verified

**Files:**
- `Tests/EditorEngineTests/SourceMapTests.swift` (new)

---

#### 2.4.2 Test Emitter Source Tracking **[High, 2-3h]**

**Input:**
- Modified MarkdownEmitter from Phase 2

**Process:**
1. Add tests to `Tests/EmitterTests/MarkdownEmitterTests.swift`
2. Test single-file emission:
   ```swift
   func testSourceMapSingleFile() {
       let builder = SourceMapBuilder()
       let emitter = MarkdownEmitter(config: EmitterConfig(), sourceMapBuilder: builder)

       let node = Node(literal: "Title", ...)
       let output = emitter.emit(node)
       let sourceMap = builder.build()

       // Verify heading mapped to source
       XCTAssertNotNil(sourceMap.lookup(outputLine: 0))
       XCTAssertEqual(sourceMap.lookup(outputLine: 0)?.filePath, "entry.hc")
   }
   ```

3. Test multi-file emission:
   - Entry file + included .hc file
   - Entry file + included .md file
   - Nested includes (3+ levels)

4. Test edge cases:
   - Empty files
   - Files with only whitespace
   - Files with many heading levels
   - Heading adjustments (verify offsets)

**Output:**
- 10+ test cases for Emitter source tracking

**Acceptance Criteria:**
- [ ] Single-file source maps work
- [ ] Multi-file source maps work
- [ ] Included files tracked correctly
- [ ] Line numbers accurate (±1 line tolerance)
- [ ] Edge cases handled gracefully

**Files:**
- `Tests/EmitterTests/MarkdownEmitterTests.swift` (update)

---

### Phase 5: Integration Tests & Validation (2-3 hours)

#### 2.5.1 Create Multi-File Test Fixture **[Medium, 1h]**

**Input:**
- Test corpus structure from E1

**Process:**
1. Create fixture in `Tests/Fixtures/source-map/`:
   ```
   simple/
     entry.hc
     included.hc
   nested/
     main.hc
     part1.hc
     part2.hc
     docs.md
   complex/
     root.hc
     deep/
       level1.hc
       level2.hc
       level3.hc
   ```

2. Design fixtures to cover:
   - Simple 2-file include
   - Nested 4+ file includes
   - Mixed .hc and .md includes
   - Deep nesting (test depth limits)

**Output:**
- Test fixtures in `Tests/Fixtures/source-map/`

**Acceptance Criteria:**
- [ ] At least 3 fixture projects created
- [ ] Fixtures cover 2-5 files each
- [ ] Mix of .hc and .md files
- [ ] Fixtures compile successfully

**Files:**
- `Tests/Fixtures/source-map/simple/entry.hc` (new)
- `Tests/Fixtures/source-map/simple/included.hc` (new)
- ... (more fixtures)

---

#### 2.5.2 Write Integration Tests **[High, 1-2h]**

**Input:**
- Fixtures from 2.5.1

**Process:**
1. Create `Tests/EditorEngineTests/SourceMapIntegrationTests.swift`
2. Test end-to-end compilation:
   ```swift
   func testSimpleInclude() {
       let compiler = EditorCompiler(fileSystem: mockFS)
       let result = compiler.compile(entryFile: ".../simple/entry.hc")

       guard let sourceMap = result.sourceMap else {
           XCTFail("Source map should not be nil")
           return
       }

       // Verify entry file lines
       let line0 = sourceMap.lookup(outputLine: 0)
       XCTAssertEqual(line0?.filePath, ".../simple/entry.hc")

       // Verify included file lines
       let line3 = sourceMap.lookup(outputLine: 3)
       XCTAssertEqual(line3?.filePath, ".../simple/included.hc")
   }
   ```

3. Test all fixtures
4. Verify accuracy (output line → source file/line)
5. Test with mock filesystem for isolation

**Output:**
- `Tests/EditorEngineTests/SourceMapIntegrationTests.swift` with 5+ tests

**Acceptance Criteria:**
- [ ] Simple include test passes
- [ ] Nested include test passes
- [ ] Mixed .hc/.md test passes
- [ ] Source file paths correct
- [ ] Line numbers within ±2 lines of expected

**Files:**
- `Tests/EditorEngineTests/SourceMapIntegrationTests.swift` (new)

---

### Phase 6: VSC-10 Verification & Documentation (1-2 hours)

#### 2.6.1 Verify VSC-10 Works with Multi-File Projects **[High, 1h]**

**Input:**
- Working source maps from Phase 5
- VSC-10 implementation (already exists)

**Process:**
1. Test VSC-10 manually with multi-file project:
   - Create test project with 3+ files
   - Open in VS Code with extension
   - Compile to preview
   - Click on line from included file
   - Verify navigation goes to correct source file

2. Document results in validation notes

**Output:**
- Validation report confirming VSC-10 multi-file navigation

**Acceptance Criteria:**
- [ ] Click on entry file content → navigates to entry file ✓
- [ ] Click on included .hc content → navigates to included .hc ✓
- [ ] Click on included .md content → navigates to included .md ✓
- [ ] Line numbers roughly correct (±2 lines acceptable)

**Files:**
- Manual testing (no code)
- Document results in task summary

---

#### 2.6.2 Update Documentation **[Medium, 1h]**

**Input:**
- Implemented source map system

**Process:**
1. Update `Sources/EditorEngine/SourceMap.swift` with DocC comments
2. Update `Sources/Emitter/MarkdownEmitter.swift` with usage examples
3. Update `README.md` (if needed) with source map feature
4. Document limitations:
   - Line numbers approximate (due to heading adjustments)
   - Requires Editor trait enabled
   - Optional feature (can compile without)

**Output:**
- Updated documentation and comments

**Acceptance Criteria:**
- [ ] All public APIs documented
- [ ] Usage examples provided
- [ ] Limitations documented
- [ ] Code examples compile

**Files:**
- `Sources/EditorEngine/SourceMap.swift`
- `Sources/Emitter/MarkdownEmitter.swift`
- `README.md` (maybe)

---

## 3. Functional Requirements

### FR-1: Emitter Source Tracking

**Requirement:** MarkdownEmitter must track source file and line for each emitted output line

**Details:**
- Optional SourceMapBuilder parameter
- No source tracking if builder nil (backward compatible)
- Tracks file inclusions (@"...")
- Handles heading level adjustments
- Updates source context through recursion

**Verification:**
```swift
let builder = SourceMapBuilder()
let emitter = MarkdownEmitter(sourceMapBuilder: builder)
let output = emitter.emit(ast)
let map = builder.build()

// Every output line should have source location
XCTAssertNotNil(map.lookup(outputLine: 0))
```

---

### FR-2: Multi-File Support

**Requirement:** Source maps must track included files, not just entry file

**Details:**
- `.hypercodeFile(path, _)` updates source context with path
- `.markdownFile(path, content)` creates new context
- Child nodes inherit correct source context
- Source paths are absolute

**Verification:**
```swift
// Compile project with includes
let result = compiler.compile(entryFile: "entry.hc")  // includes "sub.hc"
let map = result.sourceMap!

// Line from included file should map to that file
let loc = map.lookup(outputLine: 5)
XCTAssertEqual(loc?.filePath, ".../sub.hc")
```

---

### FR-3: Accurate Line Mapping

**Requirement:** Output lines map to correct source lines (within reasonable tolerance)

**Details:**
- Heading lines map to source heading location
- Content lines map to source content location
- Transformations (heading adjustments) tracked
- Tolerance: ±2 lines acceptable (due to insertBlankLines config)

**Verification:**
```swift
// Source line 10 in entry.hc → Output line ~10-12
let loc = map.lookup(outputLine: 11)
XCTAssertEqual(loc?.filePath, "entry.hc")
XCTAssertEqual(loc?.line, 10, accuracy: 2)
```

---

### FR-4: Backward Compatibility

**Requirement:** Existing code must work without source maps

**Details:**
- SourceMapBuilder is optional
- Default behavior unchanged (no source tracking)
- CompileResult.sourceMap can be nil
- No performance impact when disabled

**Verification:**
```swift
// Old API still works
let emitter = MarkdownEmitter()
let output = emitter.emit(ast)  // No source map

// CompileResult without source map
let result = compiler.compile(entryFile: "entry.hc")
// result.sourceMap may be nil (that's OK)
```

---

## 4. Non-Functional Requirements

### NFR-1: Performance

**Requirement:** No significant performance regression

**Details:**
- Source map construction overhead <5% of compilation time
- Medium project (50 files) still compiles in <200ms
- SourceMapBuilder.addMapping() is O(1)

**Verification:**
```bash
# Benchmark before and after
swift test --filter PerformanceTests
# Ensure <5% regression
```

---

### NFR-2: Memory Efficiency

**Requirement:** Source map memory usage proportional to output size

**Details:**
- SourceMap stores ~1 mapping per output line
- Mapping = (Int, SourceLocation) ≈ 40 bytes
- For 1000-line output: ~40KB memory

**Verification:**
- Test with large projects (500+ files)
- Verify memory usage acceptable (<10MB for source maps)

---

### NFR-3: Thread Safety

**Requirement:** SourceMapBuilder must be thread-safe

**Details:**
- Uses NSLock for thread safety (already implemented)
- Safe for concurrent addMapping() calls
- build() returns immutable SourceMap

**Verification:**
```swift
// Concurrent access test
DispatchQueue.concurrentPerform(iterations: 1000) { i in
    builder.addMapping(outputLine: i, sourceLocation: loc)
}
// No crashes, no data races
```

---

## 5. Edge Cases & Failure Scenarios

### EC-1: Missing Resolution

**Scenario:** Node.resolution is nil (inline text)

**Handling:**
- Use parent source context
- Continue with last known source file
- Don't add mapping (optional)

**Test:**
```swift
// Node without resolution
let node = Node(literal: "Text", resolution: nil)
// Should use parent context, not crash
```

---

### EC-2: Empty Files

**Scenario:** Included file is empty

**Handling:**
- No output lines generated
- No source mappings added
- No error (valid case)

**Test:**
```swift
// Include empty file
let result = compiler.compile("entry.hc")  // includes empty.hc
// Source map should not contain mappings for empty.hc
```

---

### EC-3: Deep Nesting

**Scenario:** 10+ levels of includes

**Handling:**
- Source context passed through all levels
- No stack overflow (tail recursion not required)
- All levels tracked correctly

**Test:**
```swift
// 15-level deep nesting
let result = compiler.compile("level0.hc")
// All files tracked in source map
```

---

### EC-4: Concurrent Compilation

**Scenario:** Multiple EditorCompiler instances compiling simultaneously

**Handling:**
- Each has own SourceMapBuilder (no shared state)
- Thread-safe SourceMapBuilder.addMapping()
- No data races

**Test:**
```swift
DispatchQueue.concurrentPerform(iterations: 10) { _ in
    let compiler = EditorCompiler()
    let result = compiler.compile("entry.hc")
    XCTAssertNotNil(result.sourceMap)
}
```

---

## 6. Implementation Notes

### 6.1 Critical Paths

1. **SourceContext Threading:**
   - Must pass context through emitNode recursion
   - Updates on file inclusion
   - Inherited by children

2. **Line Number Tracking:**
   - StringBuilder.lineNumber must be accurate
   - Counts newlines in all appends
   - Synchronized with source map additions

3. **Heading Adjustment Impact:**
   - HeadingAdjuster may change line count
   - Need to account for added/removed lines
   - Test thoroughly

### 6.2 Testing Strategy

1. **Unit Tests:**
   - SourceMap/SourceMapBuilder (8+ tests)
   - StringBuilder line tracking (5+ tests)
   - Emitter source tracking (10+ tests)

2. **Integration Tests:**
   - Multi-file fixtures (3+ projects)
   - End-to-end compilation (5+ tests)
   - Accuracy verification

3. **Manual Tests:**
   - VSC-10 with real projects
   - Performance benchmarks
   - Memory profiling

### 6.3 Rollback Plan

If critical issues found:
1. Revert Emitter changes
2. Keep SourceMap/SourceMapBuilder (no harm)
3. Restore stub buildStubSourceMap()
4. Mark task as blocked, investigate issues

---

## 7. Validation Checklist

### 7.1 Pre-Implementation

- [ ] Design reviewed and approved
- [ ] All dependencies available (SourceMap, Emitter)
- [ ] Test fixtures prepared
- [ ] Understood Emitter architecture

### 7.2 During Implementation

- [ ] Unit tests written before code (TDD)
- [ ] Each phase verified before next
- [ ] No compiler warnings
- [ ] Existing tests pass

### 7.3 Post-Implementation

- [ ] All acceptance criteria met (3/6 requirements → 6/6)
- [ ] Unit tests pass (>90% coverage)
- [ ] Integration tests pass (all fixtures)
- [ ] VSC-10 verified with multi-file projects
- [ ] Performance benchmarks acceptable (<5% regression)
- [ ] Documentation updated
- [ ] Code review ready

### 7.4 Quality Checklist

- [ ] SourceMap.swift fully tested
- [ ] MarkdownEmitter backward compatible
- [ ] EditorCompiler stub removed
- [ ] No "TODO" or "FIXME" comments
- [ ] All public APIs documented
- [ ] Thread safety verified
- [ ] Memory usage acceptable
- [ ] CI tests pass

---

## 8. Success Metrics

| Metric | Target | Verification |
|--------|--------|--------------|
| **Requirements Completion** | 6/6 (100%) | All FR-1 through FR-4 implemented |
| **Test Coverage** | >90% | `swift test --enable-code-coverage` |
| **Test Pass Rate** | 100% | All unit + integration tests pass |
| **Performance** | <5% regression | Benchmark medium project <210ms |
| **VSC-10 Multi-File** | Working | Manual test with 3+ file project |
| **Documentation** | Complete | All public APIs have DocC comments |

---

## 9. Timeline Estimate

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 1: Design & Planning | 2-3h | 2-3h |
| Phase 2: Emitter Integration | 4-6h | 6-9h |
| Phase 3: EditorCompiler Integration | 2-3h | 8-12h |
| Phase 4: Unit Tests | 3-4h | 11-16h |
| Phase 5: Integration Tests | 2-3h | 13-19h |
| Phase 6: Verification & Docs | 1-2h | 14-21h |

**Total Estimate:** 14-21 hours (conservative: 12-18h)

---

## 10. Dependencies & Blockers

### Dependencies (All Satisfied ✅)

- [x] EE-EXT-3 (stub implementation exists)
- [x] EE8 (EditorEngine complete)
- [x] MarkdownEmitter working
- [x] CompilerDriver working
- [x] VSC-10 (bidirectional navigation feature)

### Potential Blockers

- ❌ None identified (all dependencies complete)

**Risk Level:** LOW (straightforward implementation, well-defined scope)

---

## 11. Acceptance Criteria Summary

1. ✅ MarkdownEmitter integrated with SourceMapBuilder
2. ✅ Source maps track multiple files (not just entry)
3. ✅ Output lines map to correct source files
4. ✅ Line numbers accurate (±2 lines tolerance)
5. ✅ Unit tests >90% coverage, all pass
6. ✅ Integration tests with multi-file fixtures pass
7. ✅ VSC-10 works with multi-file projects
8. ✅ No performance regression (<5%)
9. ✅ Backward compatible (optional source maps)
10. ✅ Documentation complete

**Status:** READY FOR EXECUTION ✅

---

**Next Step:** Run EXECUTE command to begin implementation following this PRD.
