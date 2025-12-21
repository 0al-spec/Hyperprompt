# PRD: EE1 — Editor Engine Implementation

**Task ID:** EE1
**Task Name:** Editor Engine Implementation
**Priority:** P1 (High — required for v0.2)
**Phase:** Phase 10 — Editor Engine Module
**Estimated Effort:** 16 hours
**Dependencies:** D2 (Phase 6 — CLI & Integration) ✅
**Status:** In Progress
**Date:** 2025-12-20

---

## 1. Scope and Intent

### 1.1 Objective

Implement the **EditorEngine** module as an optional, trait-gated component within the Hyperprompt project. This module provides IDE/editor-oriented capabilities on top of the deterministic Hyperprompt compiler, enabling rich editor experiences without compromising the compiler's CLI-first design.

### 1.2 Primary Deliverables

| Deliverable | Description | Acceptance Criteria |
|------------|-------------|---------------------|
| `EditorEngine` Swift target | Separate module gated by SPM `Editor` trait | Module builds only when `--traits Editor` flag is set |
| Public Editor API | Minimal API surface for editor integrations | API includes: parsing with link awareness, reference resolution, compilation with diagnostics |
| Diagnostic Model | Structured diagnostics aligned with compiler error codes | All compiler errors map to editor diagnostics with ranges and metadata |
| Link & Resolution Model | Precise mapping of links → targets | Links expose byte/line ranges, resolution matches CLI behavior |
| Compile Result Model | Output + diagnostics + optional manifest/stats | Byte-for-byte identical output to CLI compilation |
| Documentation | `DOCS/EDITOR_ENGINE.md` usage guide | Complete documentation of API, examples, and integration patterns |

### 1.3 Success Criteria

- ✅ Hyperprompt builds **without EditorEngine** by default (`swift build` excludes module)
- ✅ With `--traits Editor`, EditorEngine builds cleanly and is importable
- ✅ EditorEngine exposes **no UI code** (no SwiftUI, AppKit, HTML, WebView)
- ✅ All outputs are deterministic and reproducible (same input → same output)
- ✅ EditorEngine can power a 3-column editor UX without CLI invocation
- ✅ Unit tests achieve >80% code coverage for EditorEngine module
- ✅ Integration tests verify API matches CLI behavior exactly

### 1.4 Constraints

- **Experimental status**: EditorEngine is experimental until Hyperprompt v1.0
- **No API stability guarantees** before v1.0
- **Must reuse existing compiler modules**: Core, Parser, Resolver, Emitter, Statistics
- **No platform-specific dependencies**: Avoid SwiftUI, AppKit, UIKit, WebView, HTML
- **Trait-gated compilation**: Must not affect default build (`swift build`)

### 1.5 External Dependencies

| Dependency | Purpose | Version |
|-----------|---------|---------|
| Swift 6.1+ | Language & concurrency model | Required |
| SwiftPM Traits | Optional compilation (`Editor` trait) | SPM 5.9+ |
| Hyperprompt Core Modules | Parsing, resolution, emission | Current |
| SpecificationCore | Grammar validation (via HypercodeGrammar) | 1.0.0+ |

### 1.6 Assumptions

- **Workspace Root**: Directory passed by editor client; defaults to entry file's parent if not provided
- **Indexing Order**: Files collected via deterministic traversal (lexicographic sort on full path)
- **Offsets**: Source ranges expressed in UTF-8 byte offsets and 1-based line/column pairs
- **Line Endings**: Input normalized to `\n` before range calculations; original file contents unchanged

---

## 2. Structured TODO Plan

### Phase 0: Package & Build Integration

#### Task 0.1: Define SPM Trait

**Input:** `Package.swift` manifest
**Process:** Add trait `Editor`, disabled by default
**Output:** Trait-gated compilation path

**Metadata:**
- **Priority:** High
- **Effort:** Low (30 minutes)
- **Tools:** SwiftPM
- **Acceptance Criteria:**
  - `swift build` succeeds without Editor module
  - `swift build --traits Editor` includes EditorEngine target
  - `swift test --traits Editor` runs EditorEngine tests

**Steps:**
1. Edit `Package.swift` to add `Editor` trait to package definition
2. Add `EditorEngine` target with trait requirement
3. Verify default build excludes EditorEngine
4. Verify trait-enabled build includes EditorEngine

---

#### Task 0.2: Create EditorEngine Target

**Input:** `Package.swift` manifest
**Process:** Add new target `EditorEngine` with proper dependencies
**Output:** Isolated module with no CLI dependency

**Metadata:**
- **Priority:** High
- **Effort:** Low (30 minutes)
- **Tools:** SwiftPM
- **Acceptance Criteria:**
  - CLI target does not import EditorEngine
  - EditorEngine can import Core, Parser, Resolver, Emitter, Statistics
  - Module boundary prevents circular dependencies

**Steps:**
1. Create `Sources/EditorEngine` directory structure
2. Add `EditorEngine` target to `Package.swift` with dependencies: `[Core, Parser, Resolver, Emitter, Statistics]`
3. Add `EditorEngineTests` test target
4. Create placeholder `EditorEngine.swift` with module entry point
5. Verify module compiles in isolation

---

### Phase 1: Core Editor API

#### Task 1.1: Project Indexing

**Input:** Workspace root URL
**Process:** Scan supported files (`.hc`, `.md`) with deterministic ordering
**Output:** `ProjectIndex` struct containing all reachable files

**Metadata:**
- **Priority:** High
- **Effort:** Medium (3 hours)
- **Tools:** `FileManager`, existing `FileSystem` abstraction
- **Acceptance Criteria:**
  - Index lists all reachable `.hc` and `.md` files
  - File order is deterministic (lexicographic sort)
  - Ignores hidden directories (`.git`, `build`, `node_modules`, `Packages`)
  - Respects `.hyperpromptignore` if present
  - Does not follow symlinks unless explicitly enabled

**Subtasks:**
1. **Define `ProjectIndex` struct** (30 min)
   - Fields: `workspaceRoot: URL`, `files: [FileEntry]`, `timestamp: Date`
   - `FileEntry`: `path: String`, `url: URL`, `type: FileType`
   - `FileType` enum: `.hypercode`, `.markdown`

2. **Implement file scanner** (1 hour)
   - Use `FileManager.enumerator(at:includingPropertiesForKeys:options:)`
   - Filter by extensions: `.hc`, `.md`
   - Exclude hidden directories by default
   - Apply lexicographic sorting to results

3. **Add ignore rules support** (1 hour)
   - Parse `.hyperpromptignore` (glob patterns)
   - Apply ignore patterns during traversal
   - Default ignores: `.git`, `build`, `node_modules`, `Packages`, `DerivedData`

4. **Write unit tests** (30 min)
   - Test: Empty workspace returns empty index
   - Test: Mixed `.hc` and `.md` files indexed correctly
   - Test: Hidden directories excluded
   - Test: Symlinks not followed by default
   - Test: `.hyperpromptignore` patterns applied correctly

---

#### Task 1.2: Parsing with Link Spans

**Input:** File contents (String)
**Process:** Parse Hypercode, extract link ranges
**Output:** `ParsedFile { ast: Node, linkSpans: [LinkSpan] }`

**Metadata:**
- **Priority:** High
- **Effort:** Medium (3 hours)
- **Tools:** Existing `Parser`, new `LinkSpanExtractor`
- **Acceptance Criteria:**
  - All file references captured with byte/line ranges
  - Line endings normalized to LF before offset calculation
  - Ranges are UTF-8 byte offsets and 1-based line/column pairs
  - Partial parse allowed even with syntax errors (best-effort recovery)

**Subtasks:**
1. **Define `LinkSpan` struct** (30 min)
   - Fields: `literal: String`, `byteRange: Range<Int>`, `lineRange: Range<Int>`, `columnRange: Range<Int>`, `isFileReference: Bool`
   - Computed property: `sourceLocation: SourceLocation`

2. **Extend Parser to extract spans** (1.5 hours)
   - Augment existing `Node` parsing to record offset ranges
   - Track UTF-8 byte offsets during tokenization
   - Compute line/column from normalized input
   - Store spans in `ParsedFile` alongside AST

3. **Implement link detection heuristic** (30 min)
   - Use `LooksLikeFileReferenceSpec` from HypercodeGrammar
   - Mark literals containing `/` or `.` as potential file references
   - Store heuristic result in `LinkSpan.isFileReference`

4. **Handle parse errors gracefully** (30 min)
   - Return partial AST + diagnostics on syntax errors
   - Continue extracting link spans from valid nodes
   - Attach error diagnostics to `ParsedFile`

5. **Write unit tests** (1 hour)
   - Test: Simple `.hc` file with single link
   - Test: Nested references (3+ levels)
   - Test: Mixed inline text and file references
   - Test: UTF-8 multi-byte characters in literals
   - Test: Syntax errors with partial recovery

---

#### Task 1.3: Link Resolution

**Input:** `LinkSpan` + source file path
**Process:** Resolve path using Resolver rules
**Output:** `ResolvedTarget` enum

**Metadata:**
- **Priority:** High
- **Effort:** Low (2 hours)
- **Tools:** Existing `ReferenceResolver`, new `EditorResolver` wrapper
- **Acceptance Criteria:**
  - Resolution matches CLI behavior exactly
  - Explicit workspace root takes precedence
  - Ambiguous matches return diagnostic with all candidates
  - Missing targets return diagnostic, not fatal error
  - Path traversal attempts rejected

**Subtasks:**
1. **Define `ResolvedTarget` enum** (30 min)
   ```swift
   enum ResolvedTarget {
       case inlineText
       case markdownFile(path: String, exists: Bool)
       case hypercodeFile(path: String, exists: Bool)
       case forbidden(extension: String)
       case invalid(reason: String)
       case ambiguous(candidates: [String])
   }
   ```

2. **Implement `EditorResolver`** (1 hour)
   - Wrapper around existing `ReferenceResolver`
   - Add workspace root resolution order: explicit root → entry file directory → CWD
   - Handle missing files gracefully (return `.markdownFile(exists: false)` vs throwing)
   - Detect ambiguous matches (multiple files match relative path)

3. **Write unit tests** (30 min)
   - Test: Absolute path resolution
   - Test: Relative path resolution with multiple roots
   - Test: Missing file handling (strict vs lenient modes)
   - Test: Forbidden extensions (`.txt`, `.json`)
   - Test: Path traversal rejection (`..`)
   - Test: Ambiguous matches (multiple candidates)

---

### Phase 2: Compilation for Editors

#### Task 2.1: Editor Compilation Entry Point

**Input:** Entry file path, `CompileOptions`
**Process:** Invoke compiler pipeline, capture diagnostics
**Output:** `CompileResult`

**Metadata:**
- **Priority:** High
- **Effort:** Medium (3 hours)
- **Tools:** Existing `CompilerDriver`, new `EditorCompiler` wrapper
- **Acceptance Criteria:**
  - Output matches CLI byte-for-byte (deterministic)
  - Diagnostics include all errors from compilation
  - Statistics collected if requested
  - Manifest generated if requested
  - Dry-run mode supported (validate without writing)

**Subtasks:**
1. **Define `CompileOptions` struct** (30 min)
   ```swift
   struct CompileOptions {
       let workspaceRoot: String?
       let outputPath: String?
       let manifestPath: String?
       let strict: Bool
       let collectStats: Bool
       let dryRun: Bool
   }
   ```

2. **Define `CompileResult` struct** (30 min)
   ```swift
   struct CompileResult {
       let markdown: String
       let diagnostics: [Diagnostic]
       let manifest: Manifest?
       let stats: CompilationStats?
       let success: Bool
   }
   ```

3. **Implement `EditorCompiler`** (1.5 hours)
   - Use existing `CompilerDriver` internally
   - Capture all errors as diagnostics instead of throwing
   - Return partial output on errors if possible
   - Ensure deterministic output (line endings, manifest key sorting)

4. **Write unit tests** (30 min)
   - Test: Valid compilation matches CLI output
   - Test: Syntax error returns diagnostic
   - Test: Missing reference in strict mode returns diagnostic
   - Test: Circular dependency returns diagnostic
   - Test: Dry-run mode does not write files

5. **Integration tests** (30 min)
   - Test: Compile V01 test corpus via EditorCompiler
   - Test: Compile V03 nested hierarchy
   - Test: Invalid I01 (tabs) returns diagnostic
   - Test: Compare CLI vs Editor output (byte-for-byte identical)

---

#### Task 2.2: Diagnostics Mapping

**Input:** Compiler errors/warnings
**Process:** Map to structured `Diagnostic` model
**Output:** `[Diagnostic]` with ranges and metadata

**Metadata:**
- **Priority:** High
- **Effort:** Medium (2 hours)
- **Tools:** Existing `CompilerError` protocol, new `DiagnosticMapper`
- **Acceptance Criteria:**
  - All CLI errors appear as editor diagnostics
  - Diagnostics include: code, severity, message, primary range, related ranges
  - Partial parse output allowed even with errors
  - Fix-its provided where applicable (optional)

**Subtasks:**
1. **Define `Diagnostic` struct** (30 min)
   ```swift
   struct Diagnostic {
       let code: String           // e.g., "E002", "W001"
       let severity: Severity     // error, warning, info
       let message: String
       let primaryRange: SourceRange
       let relatedRanges: [SourceRange]
       let fixIts: [FixIt]?       // Optional suggested fixes
   }

   enum Severity {
       case error, warning, info
   }

   struct SourceRange {
       let filePath: String
       let byteRange: Range<Int>
       let lineRange: Range<Int>
       let columnRange: Range<Int>
   }

   struct FixIt {
       let description: String
       let replacement: String
       let range: SourceRange
   }
   ```

2. **Implement `DiagnosticMapper`** (1 hour)
   - Map `CompilerError` → `Diagnostic`
   - Assign error codes based on `CompilerError` category:
     - Syntax errors: E001–E099
     - Resolution errors: E100–E199
     - IO errors: E200–E299
     - Internal errors: E900–E999
   - Extract source ranges from `SourceLocation`
   - Compute byte offsets for range calculation

3. **Write unit tests** (30 min)
   - Test: SyntaxError.tabInIndentation → Diagnostic with code "E001"
   - Test: ResolutionError.circularDependency → Diagnostic with code "E101"
   - Test: IOError.fileNotFound → Diagnostic with code "E201"
   - Test: Diagnostic includes correct line/column ranges

---

### Phase 3: Documentation & Testing

#### Task 3.1: API Documentation

**Input:** EditorEngine source code
**Process:** Write comprehensive API docs
**Output:** `DOCS/EDITOR_ENGINE.md`

**Metadata:**
- **Priority:** Medium
- **Effort:** High (2 hours)
- **Tools:** Markdown documentation
- **Acceptance Criteria:**
  - Documents all public API types
  - Includes usage examples for each API
  - Explains integration patterns (3-column editor UX)
  - Documents build configuration (`--traits Editor`)

**Subtasks:**
1. **Write API reference** (1 hour)
   - Document `ProjectIndex` and `indexProject()`
   - Document `ParsedFile`, `LinkSpan`, `parseFile()`
   - Document `ResolvedTarget`, `resolveLink()`
   - Document `CompileOptions`, `CompileResult`, `compile()`
   - Document `Diagnostic`, `SourceRange`, error codes

2. **Write usage guide** (30 min)
   - Example: Index a workspace
   - Example: Parse file and extract links
   - Example: Resolve link to target
   - Example: Compile project with diagnostics

3. **Write integration patterns** (30 min)
   - Pattern: 3-column editor (file tree + editor + preview)
   - Pattern: Live preview with incremental compilation
   - Pattern: Hover tooltips with link resolution
   - Pattern: Error squiggles with diagnostics

---

#### Task 3.2: Unit Tests

**Input:** EditorEngine implementation
**Process:** Write comprehensive unit tests
**Output:** >80% code coverage

**Metadata:**
- **Priority:** High
- **Effort:** High (3 hours)
- **Tools:** XCTest
- **Acceptance Criteria:**
  - All public APIs have unit tests
  - Edge cases covered (missing files, syntax errors, circular deps)
  - Code coverage >80%

**Subtasks:**
1. **ProjectIndex tests** (30 min)
   - Test: Empty workspace
   - Test: Mixed `.hc` and `.md` files
   - Test: Hidden directories excluded
   - Test: Ignore patterns applied

2. **ParsedFile tests** (1 hour)
   - Test: Simple file with single link
   - Test: Nested links (3+ levels)
   - Test: UTF-8 multi-byte characters
   - Test: Syntax errors with partial recovery

3. **Link resolution tests** (1 hour)
   - Test: Absolute and relative paths
   - Test: Missing files
   - Test: Forbidden extensions
   - Test: Path traversal attempts
   - Test: Ambiguous matches

4. **Compilation tests** (30 min)
   - Test: Valid compilation
   - Test: Syntax errors → diagnostics
   - Test: Circular deps → diagnostics
   - Test: Output matches CLI

---

#### Task 3.3: Integration Tests

**Input:** Test corpus files
**Process:** Verify EditorEngine matches CLI behavior
**Output:** Integration test suite

**Metadata:**
- **Priority:** High
- **Effort:** Medium (2 hours)
- **Tools:** XCTest, existing test corpus
- **Acceptance Criteria:**
  - EditorEngine output matches CLI output byte-for-byte
  - All V01–V14 valid tests pass
  - All I01–I10 invalid tests produce correct diagnostics

**Subtasks:**
1. **Valid input tests** (1 hour)
   - Test: V01 single root node
   - Test: V03 nested hierarchy
   - Test: V06 Hypercode file reference
   - Test: V07 nested Hypercode files
   - Test: V13 maximum depth (10)

2. **Invalid input tests** (1 hour)
   - Test: I01 tabs in indentation → E001
   - Test: I03 unclosed quote → E002
   - Test: I05 circular dependency → E101
   - Test: I08 path traversal → E102
   - Test: I10 multiple roots → E003

---

## 3. PRD Section

### 3.1 Feature Description & Rationale

**EditorEngine** enables rich editor experiences for Hyperprompt without compromising the compiler's deterministic, CLI-first design. It bridges the gap between language semantics (compiler) and developer experience (editors, IDEs).

**Rationale:**
- **Editor integration**: Enables LSP servers, VS Code extensions, JetBrains plugins
- **Live preview**: Compile on save, show rendered Markdown instantly
- **Navigation**: Jump to definition for file references
- **Diagnostics**: Real-time error reporting as you type
- **Discoverability**: Hover tooltips, autocomplete for file paths

### 3.2 Functional Requirements

| ID | Requirement | Verification |
|----|-------------|--------------|
| FR-1 | Parse Hypercode files and expose link spans | Unit test: `testLinkSpanExtraction()` |
| FR-2 | Resolve file references identically to CLI | Integration test: compare CLI vs Editor resolution |
| FR-3 | Compile projects programmatically | Integration test: compare CLI vs Editor output |
| FR-4 | Emit structured diagnostics | Unit test: all error codes mapped to diagnostics |
| FR-5 | Be disabled unless `Editor` trait is enabled | Build test: `swift build` excludes EditorEngine |
| FR-6 | Provide deterministic indexing with defined ignore rules | Unit test: `testDeterministicIndexing()` |
| FR-7 | Provide offset conventions suitable for editor integrations | Unit test: UTF-8 byte offsets and 1-based line/column |

### 3.3 Non-Functional Requirements

| Category | Requirement | Target |
|----------|-------------|--------|
| **Determinism** | Same input → same output | 100% reproducible compilation |
| **Performance** | Indexing + parsing + compilation | <100ms for medium projects (warm caches) |
| **Stability** | Invalid files never crash engine | No panics on malformed input |
| **Portability** | macOS + Linux | CI validates both platforms |
| **Isolation** | No UI or LLM dependencies | Static analysis: no SwiftUI/AppKit imports |

### 3.4 User Interaction Flows (Conceptual)

```
┌─────────────────────────────────────────────────────────┐
│                    Editor Client                        │
│  (VS Code Extension, JetBrains Plugin, LSP Server)      │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────┐
    │        EditorEngine.parse()          │
    │  Input: File path                    │
    │  Output: ParsedFile + LinkSpans      │
    └──────────────┬───────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────┐
    │       EditorEngine.resolve()         │
    │  Input: LinkSpan                     │
    │  Output: ResolvedTarget              │
    └──────────────┬───────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────┐
    │       EditorEngine.compile()         │
    │  Input: Entry file + options         │
    │  Output: CompileResult + Diagnostics │
    └──────────────┬───────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────┐
    │         Editor UI Updates            │
    │  • Show diagnostics (squiggles)      │
    │  • Render preview (live Markdown)    │
    │  • Enable navigation (jump to def)   │
    └──────────────────────────────────────┘
```

### 3.5 Edge Cases & Failure Scenarios

| Case | Handling | Expected Behavior |
|------|----------|-------------------|
| **Missing file** | Return `ResolvedTarget.markdownFile(exists: false)` | Diagnostic with severity based on strict/lenient mode |
| **Circular reference** | Detect during compilation | `Diagnostic` with error code E101, full cycle path |
| **Invalid syntax** | Parse with recovery | Partial AST + `Diagnostic` with error code E001–E099 |
| **Trait disabled** | EditorEngine not compiled | Import fails at compile time |
| **Path traversal** | Reject during resolution | `Diagnostic` with error code E102 |
| **Ambiguous path** | Multiple candidates found | `Diagnostic` listing all candidates |

---

## 4. Quality Enforcement Rules

### 4.1 Code Quality

- ✅ **No implicit behavior**: All APIs document their effects clearly
- ✅ **No hidden side effects**: Functions are pure or explicitly state IO
- ✅ **All APIs testable**: Unit tests for every public function
- ✅ **All outputs serializable**: Results are data structures, not opaque objects
- ✅ **All errors surfaced as diagnostics**: No throwing in public API

### 4.2 Testing Standards

- ✅ **>80% code coverage** for EditorEngine module
- ✅ **All public APIs have unit tests**
- ✅ **Integration tests verify CLI parity**
- ✅ **Edge cases covered**: Missing files, syntax errors, circular deps
- ✅ **Performance benchmarks**: Indexing, parsing, compilation targets met

### 4.3 Documentation Standards

- ✅ **API reference complete**: All public types documented
- ✅ **Usage examples provided**: At least one example per API
- ✅ **Integration patterns documented**: 3-column editor, live preview
- ✅ **Build instructions clear**: How to enable `Editor` trait

---

## 5. Implementation Checklist

### Phase 0: Package & Build Integration (1 hour)
- [ ] 0.1: Define SPM `Editor` trait in Package.swift
- [ ] 0.2: Create EditorEngine target with dependencies

### Phase 1: Core Editor API (8 hours)
- [ ] 1.1: Implement Project Indexing
  - [ ] Define `ProjectIndex` struct
  - [ ] Implement file scanner with deterministic ordering
  - [ ] Add `.hyperpromptignore` support
  - [ ] Write unit tests (5 tests)
- [ ] 1.2: Implement Parsing with Link Spans
  - [ ] Define `LinkSpan` struct
  - [ ] Extend Parser to extract byte/line ranges
  - [ ] Implement link detection heuristic
  - [ ] Handle parse errors gracefully
  - [ ] Write unit tests (5 tests)
- [ ] 1.3: Implement Link Resolution
  - [ ] Define `ResolvedTarget` enum
  - [ ] Implement `EditorResolver` wrapper
  - [ ] Write unit tests (6 tests)

### Phase 2: Compilation for Editors (5 hours)
- [ ] 2.1: Implement Editor Compilation Entry Point
  - [ ] Define `CompileOptions` and `CompileResult`
  - [ ] Implement `EditorCompiler` wrapper
  - [ ] Write unit tests (5 tests)
  - [ ] Write integration tests (4 tests)
- [ ] 2.2: Implement Diagnostics Mapping
  - [ ] Define `Diagnostic` struct with error codes
  - [ ] Implement `DiagnosticMapper`
  - [ ] Write unit tests (4 tests)

### Phase 3: Documentation & Testing (7 hours)
- [ ] 3.1: Write API Documentation (DOCS/EDITOR_ENGINE.md)
  - [ ] API reference section
  - [ ] Usage guide with examples
  - [ ] Integration patterns (3-column editor)
- [ ] 3.2: Write Unit Tests (>80% coverage)
  - [ ] ProjectIndex tests
  - [ ] ParsedFile tests
  - [ ] Link resolution tests
  - [ ] Compilation tests
- [ ] 3.3: Write Integration Tests
  - [ ] Valid input tests (V01, V03, V06, V07, V13)
  - [ ] Invalid input tests (I01, I03, I05, I08, I10)

**Total Estimated Effort:** 21 hours (includes buffer for debugging and refinement)

---

## 6. Acceptance Criteria Summary

| Criterion | Verification Method |
|-----------|---------------------|
| **Builds without trait** | `swift build` excludes EditorEngine |
| **Builds with trait** | `swift build --traits Editor` includes EditorEngine |
| **No UI dependencies** | Static analysis: no SwiftUI/AppKit imports |
| **Deterministic output** | Integration test: CLI vs Editor byte-for-byte comparison |
| **3-column UX support** | Example implementation in docs |
| **>80% code coverage** | `swift test --enable-code-coverage` |
| **CLI behavior parity** | Integration tests with test corpus (V01–V14, I01–I10) |
| **API documentation** | DOCS/EDITOR_ENGINE.md complete |

---

## 7. Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Performance regression** | Editor feels slow | Medium | Benchmark indexing/parsing, optimize hot paths |
| **API instability** | Breaking changes in v0.2 | Low | Mark as experimental, version API carefully |
| **CLI divergence** | Editor output != CLI | Medium | Comprehensive integration tests, shared code paths |
| **Trait build failure** | Feature unusable | Low | CI validates both builds (with/without trait) |

---

## 8. Future Work (Out of Scope for EE1)

### Phase 3 Enhancements (Post-MVP)

#### 8.1 Source Map (Optional)
- **Input:** Compilation traversal
- **Output:** Mapping from output lines to source ranges
- **Use case:** Click on preview → jump to source

#### 8.2 Symbol Index (Optional)
- **Input:** Parsed ASTs
- **Output:** Definition/reference index for identifiers
- **Use case:** Peek definition without recompiling

#### 8.3 Incremental Parsing & Caching (Optional)
- **Input:** File versions + edits
- **Output:** Cached parse trees and resolution results
- **Use case:** Typing in single file doesn't reparse entire workspace

---

## 9. References

- **EditorEngine PRD**: `DOCS/PRD/PRD_EditorEngine.md` — Detailed feature specification
- **Workplan**: `DOCS/Workplan.md` — Task breakdown and dependencies
- **Main PRD**: `DOCS/PRD/v0.0.1/00_PRD_001.md` — Compiler requirements
- **Design Spec**: `DOCS/PRD/v0.0.1/01_DESIGN_SPEC_001.md` — Compiler architecture

---

## 10. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-20 | LLM Agent | Initial PRD generation from task EE1 |

---

**End of PRD**

---
**Archived:** 2025-12-21
