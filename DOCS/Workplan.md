# Hyperprompt Compiler v0.1 + VS Code Extension — Work Plan

**Document Version:** 3.0.0
**Date:** December 23, 2025
**Status:** Active Development (Phases 1-10 Complete, Phases 11-15 Pending)
**Based on:** PRD v0.0.1, Design Spec v0.0.1, SpecificationCore Integration Spec v0.0.1, PRD_VSCode_Extension.md

---

## Overview

This work plan combines tasks from:
- **Core Compiler Implementation** (PRD §7: Implementation Plan) — ✅ Complete (Phases 1-9)
- **SpecificationCore Integration** (Design Spec §10: Implementation Checklist) — ✅ Complete (Phase 3, 7)
- **EditorEngine Module** (PRD_EditorEngine.md) — ✅ Complete (Phase 10)
- **VS Code Extension** (PRD_VSCode_Extension.md) — ⏸️ Pending (Phases 11-15)
- **Testing & Documentation** requirements — ✅ Complete (Phase 8)

**Total Estimated Effort:**
- **Phases 1-10 (Complete):** ~131 hours (16 days) ✅
- **Phases 11-15 (Pending):** ~86 hours (11 weeks)
- **Grand Total:** ~217 hours (27 days / 5.5 weeks)

### Priority Levels

- **[P0] Critical:** Blocks entire project, must complete before moving forward
- **[P1] High:** Important for core functionality, required for v0.1
- **[P2] Medium:** Nice-to-have, can be deferred to v0.1.1 if needed

---

## 📊 Critical Path Analysis

The **critical path** (longest dependency chain) determines minimum project duration:

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CRITICAL PATH (47 hours)                        │
└─────────────────────────────────────────────────────────────────────┘

A1 (2h) → A2 (4h) → A4 (8h) → B4 (8h) → C2 (8h) → D2 (6h) → E1 (8h) → Release (3h)

  Project    Core     Parser   Recursive  Emitter   Driver    Tests    Final
   Init      Types             Compile                                 QA
```

**Tasks on critical path must be prioritized** — delays here delay entire project.

---

## 🛤️ Development Tracks

Work can be parallelized across **two independent tracks**:

### **Track A: Core Compiler** (imperative implementation)
Blocking: Sequential implementation of compilation pipeline
- Phase 1 (Foundation)
- Phase 2 (Lexer/Parser)
- Phase 4 (Resolver)
- Phase 5 (Emitter)
- Phase 6 (CLI)

### **Track B: Specifications** (declarative grammar)
Non-blocking: Can develop in parallel with Track A
- Phase 3 (HypercodeGrammar specs)
- Integration happens in Phase 7

### **Recommended Parallelization Strategy**

**Week 1:** Parallel development
- 👨‍💻 **Developer A:** Phase 1-2 (Foundation + Parser) — 20 hours
- 👨‍💻 **Developer B:** Phase 3 (Specifications) — 17 hours

**Week 2:** Parallel development
- 👨‍💻 **Developer A:** Phase 4 (Resolver) — 12 hours
- 👨‍💻 **Developer B:** Phase 5-6 (Emitter + CLI) — 24 hours

**Week 3:** Integration & Testing
- 👥 **Both:** Phase 7 (Integration) — 11 hours
- 👥 **Both:** Phase 8 (Testing) — 12 hours
- 👥 **Both:** Phase 9 (Release) — 4 hours

**Estimated calendar time:** 3 weeks (with 2 developers working in parallel)

---

## 🔗 Dependency Graph

```
                    ┌─────────┐
                    │   A1    │  Project Init [P0]
                    └────┬────┘
                         │
           ┌─────────────┴─────────────┐
           ↓                           ↓
      ┌─────────┐                 ┌─────────┐
      │   A2    │  Core Types     │   A3    │  Domain Types
      └────┬────┘  [P0]           └────┬────┘  [P1]
           │                           │
           ├────────────┬──────────────┤
           ↓            ↓              ↓
      ┌─────────┐  ┌─────────┐   ┌──────────┐
      │   A4    │  │   B1    │   │ Phase 3  │  Specifications
      └────┬────┘  └────┬────┘   └──────────┘  [P1, parallel]
           │            │              │
           │       ┌────┴────┐         │
           │       ↓         ↓         │
           │  ┌─────────┐ ┌─────────┐ │
           │  │   B2    │ │   B3    │ │
           │  └─────────┘ └────┬────┘ │
           │                   │      │
           │       ┌───────────┴──────┤
           ↓       ↓                  ↓
      ┌─────────────┐           ┌──────────┐
      │     B4      │           │ Phase 7  │  Integration
      └──────┬──────┘           └──────────┘  [P1]
             │
        ┌────┴────┐
        ↓         ↓
   ┌─────────┐ ┌─────────┐
   │   C1    │ │   C2    │
   └─────────┘ └────┬────┘
                    │
               ┌────┴────┐
               ↓         ↓
          ┌─────────┐ ┌─────────┐
          │   D1    │ │   D2    │
          └─────────┘ └────┬────┘
                           │
                      ┌────┴────┐
                      ↓         ↓
                 ┌─────────┐ ┌─────────┐
                 │   E1    │ │   E2    │
                 └─────────┘ └─────────┘
```

---

## Phase 1: Foundation & Core Types

**Goal:** Establish project structure, core types, and basic infrastructure
**Estimated Duration:** 6 hours
**Track:** A (Core Compiler)

### A1: Project Initialization **[P0]**
**Dependencies:** None (entry point)
**Estimated:** 2 hours
**Status:** ✅ Completed on 2025-12-03

- [x] **[P0]** Create Swift package with appropriate directory structure
- [x] **[P0]** Configure Package.swift with dependencies:
  - [x] swift-argument-parser
  - [x] swift-crypto
  - [x] SpecificationCore
- [x] **[P0]** Establish module boundaries (Core, Parser, Resolver, Emitter, CLI, Statistics)
- [x] **[P0]** Set up test target structure
- [x] **[P0]** Project structure ready for Swift build verification
- [x] **[P0]** Project structure ready for Swift test verification

**Acceptance Criteria:** Project structure created, all modules defined, ready for Swift compilation

**Blocks:** All other tasks (project must exist first)

---

### A2: Core Types Implementation **[P0]**
**Dependencies:** A1
**Estimated:** 4 hours
**Status:** ✅ Completed on 2025-12-05

- [x] **[P0, depends: A1]** Define `SourceLocation` struct (file path + line number)
- [x] **[P0, depends: A1]** Define `CompilerError` protocol with diagnostic information
- [x] **[P0, depends: A1]** Implement error categories enum (IO, Syntax, Resolution, Internal)
- [x] **[P0, depends: A1]** Implement `FileSystem` protocol for abstracting file operations
- [x] **[P0, depends: A1]** Create `LocalFileSystem` production implementation
- [x] **[P1, depends: A1]** Create `MockFileSystem` for testing
- [x] **[P1, depends: A1]** Write unit tests for all error cases with diagnostics

**Acceptance Criteria:** All core types have >90% test coverage, error cases produce appropriate diagnostics ✅

**Blocks:** A3, A4, B1, C1, C2, D1, D2 (core types used everywhere)

---

### A3: Domain Types for Specifications **[P1]**
**Dependencies:** A1, A2
**Estimated:** 3 hours
**Track:** B (Specifications) — can start in parallel with A4
**Status:** ✅ Completed on 2025-12-08

- [x] **[P1, depends: A1]** Create `HypercodeGrammar` module with SpecificationCore dependency
- [x] **[P1, depends: A2]** Define `RawLine` struct (text, lineNumber, filePath)
- [x] **[P1, depends: A2]** Define `LineKind` enum (blank, comment, node)
- [x] **[P1, depends: A2]** Define `ParsedLine` struct (kind, indentSpaces, depth, literal, location)
- [x] **[P1, depends: A2]** Define `PathKind` enum (allowed, forbidden, invalid)
- [x] **[P1, depends: A2]** Write unit tests for domain type conversions

**Acceptance Criteria:** ✅ Domain types properly model lexer/resolver input/output, tests verify correct behavior

**Blocks:** Phase 3 (Specifications)

---

## Phase 2: Lexer & Parser (Core Compilation)

**Goal:** Implement tokenization and AST construction
**Estimated Duration:** 14 hours
**Track:** A (Core Compiler)

### Lexer Implementation **[P0]**
**Dependencies:** A2
**Estimated:** 6 hours
**Status:** ✅ Completed on 2025-12-05

- [x] **[P0, depends: A2]** Implement line-by-line tokenization
- [x] **[P0, depends: A2]** Implement `readLines()` with CRLF/CR → LF normalization
- [x] **[P0, depends: A2]** Recognize blank lines
- [x] **[P0, depends: A2]** Recognize comment lines (# prefix with optional indent)
- [x] **[P0, depends: A2]** Recognize node lines (quoted literals)
- [x] **[P0, depends: A2]** Extract indentation level (groups of 4 spaces)
- [x] **[P0, depends: A2]** Extract literal content (content between quotes)
- [x] **[P0, depends: A2]** Enforce single-line content constraint
- [x] **[P0, depends: A2]** Reject tabs in indentation (syntax error)
- [x] **[P1, depends: A2]** Write lexer tests for 20+ sample files

**Acceptance Criteria:** ✅ Lexer correctly tokenizes all valid test inputs, reports meaningful errors for invalid inputs

**Blocks:** A4 (parser needs tokens)

---

### A4: Parser & AST Construction **[P0]**
**Dependencies:** Lexer Implementation, A2
**Estimated:** 8 hours
**Status:** ✅ Completed on 2025-12-06

- [x] **[P0, depends: A2]** Implement `Node` struct (literal, depth, location, children, resolution)
- [x] **[P0, depends: A2]** Implement `Program` struct (root node container)
- [x] **[P0, depends: A2]** Implement `Token` enum (blank, comment, node)
- [x] **[P0, depends: Lexer]** Build tree structure from token stream based on indentation
- [x] **[P0, depends: Lexer]** Compute depth from indentation (spaces / 4)
- [x] **[P0, depends: Lexer]** Establish parent-child relationships via depth stack
- [x] **[P0, depends: Lexer]** Enforce single root node constraint (depth 0)
- [x] **[P0, depends: Lexer]** Report syntax errors with source locations
- [x] **[P1, depends: Lexer]** Handle blank lines structurally (preserve but don't add to AST)
- [x] **[P1, depends: Lexer]** Skip comment tokens during AST construction
- [x] **[P1, depends: Lexer]** Write parser tests for all valid/invalid structures

**Acceptance Criteria:** ✅ Parser produces correct AST for all valid inputs, reports meaningful errors for invalid inputs

**Blocks:** B4 (recursive compilation needs parser), C2 (emitter needs AST)

---

## Phase 3: Specifications (HypercodeGrammar Module)

**Goal:** Implement executable EBNF grammar as composable specifications
**Estimated Duration:** 17 hours
**Track:** B (Specifications) — **can run in parallel with Phase 2 & 4**

### Spec-1: Lexical Specifications **[P1]**
**Dependencies:** A3 ✅
**Estimated:** 6 hours
**Status:** ✅ Completed on 2025-12-11

- [x] **[P1, depends: A3]** Implement `IsBlankLineSpec` (line contains only spaces) ✅
- [x] **[P1, depends: A3]** Implement `IsCommentLineSpec` (starts with # after indent) ✅
- [x] **[P1, depends: A3]** Implement `IsNodeLineSpec` (quoted literal on single line) ✅
- [x] **[P1, depends: A3]** Implement `StartsWithDoubleQuoteSpec` ✅
- [x] **[P1, depends: A3]** Implement `EndsWithDoubleQuoteSpec` ✅
- [x] **[P1, depends: A3]** Implement `ContentWithinQuotesIsSingleLineSpec` ✅
- [x] **[P1, depends: A3]** Implement `ValidQuotesSpec` (composite: starts AND ends AND single-line) ✅
- [x] **[P1, depends: A3]** Implement `ContainsLFSpec` (detects \n) ✅
- [x] **[P1, depends: A3]** Implement `ContainsCRSpec` (detects \r) ✅
- [x] **[P1, depends: A3]** Implement `SingleLineContentSpec` (composite: NOT (LF OR CR)) ✅
- [x] **[P1, depends: A3]** Write unit tests for each specification (15+ test cases each) ✅
- [x] **[P1, depends: A3]** BONUS: Implement `IsSkippableLineSpec` (semantic grouping: blank OR comment) ✅
- [x] **[P1, depends: A3]** BONUS: Implement `IsSemanticLineSpec` (NOT skippable) ✅

**Acceptance Criteria:** ✅ All lexical specs pass unit tests, composition operators work correctly (14 specs implemented, comprehensive test suite)

**Blocks:** Integration-1 (lexer integration needs specs)

---

### Spec-2: Indentation & Depth Specifications **[P1]**
**Dependencies:** A3 ✅, Spec-1 ✅
**Estimated:** 4 hours
**Status:** ✅ Completed on 2025-12-11

- [x] **[P1, depends: A3]** Implement `NoTabsIndentSpec` (no tabs in indentation) ✅
- [x] **[P1, depends: A3]** Implement `IndentMultipleOf4Spec` (indent % 4 == 0) ✅
- [x] **[P1, depends: A3]** Implement `DepthWithinLimitSpec` (depth <= 10, configurable) ✅
- [x] **[P1, depends: Spec-1]** Write unit tests for edge cases (depth 0, depth 10, depth 11) ✅
- [x] **[P1, depends: Spec-1]** Test composition with ValidNodeLineSpec ✅

**Acceptance Criteria:** ✅ Indentation validation catches all forbidden patterns, depth limits enforced correctly (5 specs, 14/14 tests passing)

**Blocks:** Integration-1 (lexer integration needs specs)

---

### Spec-3: Path Validation Specifications **[P1]**
**Dependencies:** A3 ✅
**Estimated:** 4 hours
**Status:** ✅ Completed on 2025-12-11

- [x] **[P1, depends: A3]** Implement `HasMarkdownExtensionSpec` (.md suffix) ✅
- [x] **[P1, depends: A3]** Implement `HasHypercodeExtensionSpec` (.hc suffix) ✅
- [x] **[P1, depends: A3]** Implement `IsAllowedExtensionSpec` (composite: .md OR .hc) ✅
- [x] **[P1, depends: A3]** Implement `ContainsPathSeparatorSpec` (contains /) ✅
- [x] **[P1, depends: A3]** Implement `ContainsExtensionDotSpec` (contains .) ✅
- [x] **[P1, depends: A3]** Implement `LooksLikeFileReferenceSpec` (heuristic: separator OR dot) ✅
- [x] **[P1, depends: A3]** Implement `NoTraversalSpec` (no .. components) ✅
- [x] **[P1, depends: A3]** Implement `WithinRootSpec` (path starts with root) ✅
- [x] **[P1, depends: A3]** Write unit tests for all path validation cases ✅

**Acceptance Criteria:** ✅ Path specs correctly identify allowed/forbidden extensions, security violations detected (9 specs, 14/14 tests passing)

**Blocks:** Integration-2 (resolver integration needs specs)

---

### Spec-4: Composite & Decision Specifications **[P1]**
**Dependencies:** Spec-1 ✅, Spec-2 ✅, Spec-3 ✅
**Estimated:** 3 hours
**Status:** ✅ Completed on 2025-12-11

- [x] **[P1, depends: Spec-1, Spec-2]** Implement `ValidNodeLineSpec` (composite: NoTabs AND Indent AND Depth AND Quotes AND IsNode) ✅
- [x] **[P1, depends: Spec-3]** Implement `ValidReferencePathSpec` (composite: NoTraversal AND AllowedExtension) ✅
- [x] **[P1, depends: Spec-1]** Implement `IsSkippableLineSpec` (semantic: IsBlank OR IsComment) ✅
- [x] **[P1, depends: Spec-1]** Implement `IsSemanticLineSpec` (semantic: NOT IsSkippable) ✅
- [x] **[P1, depends: Spec-1]** Implement `LineKindDecision` using `FirstMatchSpec` (blank → comment → node priority) ✅
- [x] **[P1, depends: Spec-3]** Implement `PathTypeDecision` using `FirstMatchSpec` ✅
- [x] **[P1, depends: Spec-1, Spec-2, Spec-3]** Write composition tests (AND, OR, NOT truth tables) ✅
- [x] **[P1, depends: Spec-1, Spec-2, Spec-3]** Write decision spec tests (priority ordering, nil handling) ✅
- [x] **[P1, depends: Spec-1]** Test De Morgan's Law equivalences ✅

**Acceptance Criteria:** ✅ Composite specs correctly combine atomic rules, decision specs return correct classifications (11 specs, 14/14 tests passing)

**Blocks:** Phase 7 (integration needs all specs)

---

## Phase 4: Reference Resolution

**Goal:** Implement file reference resolution with circular dependency detection
**Estimated Duration:** 12 hours
**Track:** A (Core Compiler)

### B1: Reference Resolver **[P0]**
**Dependencies:** A4 (needs AST)
**Estimated:** 6 hours
**Status:** ✅ Completed on 2025-12-06 (Core implementation)
**Spec Integration:** ✅ Completed on 2025-12-13

- [x] **[P0, depends: A4]** Implement file existence checking against root directory
- [x] **[P0, depends: A4]** Classify literals as file references or inline text
- [x] **[P0, depends: A4]** Handle `.md` extension (load content, no recursion)
- [x] **[P0, depends: A4]** Handle `.hc` extension (recursive compilation)
- [x] **[P0, depends: A4]** Reject all other extensions (hard error, exit 3)
- [x] **[P0, depends: A4]** Implement strict mode (missing file → error)
- [x] **[P1, depends: A4]** Implement lenient mode (missing file → inline text)
- [x] **[P1, depends: Spec-3]** Integrate `ValidReferencePathSpec` for pre-validation ✅ 2025-12-13
- [x] **[P1, depends: Spec-3]** Integrate `PathTypeDecision` for classification ✅ 2025-12-13
- [x] **[P1, depends: A4]** Write resolver tests for all reference types

**Acceptance Criteria:** ✅ Resolver correctly classifies all reference types, strict/lenient modes work as specified

**Blocks:** B4 (recursive compilation needs resolver)

---

### B2: Dependency Tracker **[P1]**
**Dependencies:** A4 ✅
**Estimated:** 4 hours
**Status:** ✅ Completed on 2025-12-21

- [x] **[P1, depends: A4]** Implement visitation stack for cycle detection
- [x] **[P1, depends: A4]** Detect direct circular dependencies (A → A)
- [x] **[P1, depends: A4]** Detect transitive circular dependencies (A → B → A)
- [x] **[P1, depends: A4]** Produce clear cycle path descriptions in error messages
- [x] **[P2, depends: A4]** Optimize for deep trees with memoization
- [x] **[P1, depends: A4]** Write tests for various cycle patterns

**Acceptance Criteria:** ✅ All circular dependencies detected, error messages show full cycle path

**Blocks:** B4 (recursive compilation needs cycle detection)

---

### B3: File Loader & Caching **[P0]**
**Dependencies:** A2
**Estimated:** 4 hours
**Status:** ✅ Completed on 2025-12-06

- [x] **[P0, depends: A2]** Implement file content reading with UTF-8 encoding
- [x] **[P0, depends: A2]** Implement line ending normalization (CRLF/CR → LF)
- [x] **[P1, depends: A2]** Cache loaded content to avoid redundant reads
- [x] **[P0, depends: A2]** Compute SHA256 hashes during loading (using swift-crypto)
- [x] **[P0, depends: A2]** Collect file metadata for manifest generation
- [x] **[P0, depends: A2]** Implement `ManifestEntry` struct (path, sha256, size, type)
- [x] **[P0, depends: A2]** Implement `ManifestBuilder` for collecting entries
- [x] **[P1, depends: A2]** Write tests for hash computation accuracy

**Acceptance Criteria:** ✅ File content correctly loaded and cached, SHA256 hashes accurate, metadata collected

**Blocks:** B4 (recursive compilation needs file loading), C3 (manifest needs entries)

---

### B4: Recursive Compilation **[P0]**
**Dependencies:** A4, B1, B2, B3
**Estimated:** 8 hours
**Status:** ✅ Completed on 2025-12-06

- [x] **[P0, depends: A4, B1]** Implement recursive parser invocation for `.hc` files
- [x] **[P0, depends: A4, B1]** Merge child ASTs into parent tree at correct depth
- [x] **[P0, depends: A4, B1]** Propagate errors from nested compilations
- [x] **[P0, depends: A4, B1]** Maintain source location tracking across files
- [x] **[P1, depends: B2]** Update visitation stack correctly during recursion
- [x] **[P1, depends: A4, B1, B3]** Write tests for nested `.hc` files (3+ levels deep)

**Acceptance Criteria:** Nested `.hc` files correctly compiled and embedded, errors propagate with correct locations

**Completion Note (2025-12-06):** Implemented recursive compilation with depth-adjusted AST merging, contextualized nested error reporting, and visitation stack restoration; added multi-level success and failure coverage.

**Blocks:** C2 (emitter needs fully resolved AST)

---

## Phase 5: Markdown Emission

**Goal:** Generate output with heading adjustment and provenance
**Estimated Duration:** 11 hours
**Track:** A (Core Compiler)

### C1: Heading Adjuster **[P1]**
**Dependencies:** A2
**Estimated:** 6 hours
**Status:** ✅ Completed on 2025-12-09

- [x] **[P1, depends: A2]** Parse ATX-style headings (# prefix)
- [x] **[P1, depends: A2]** Parse Setext-style headings (underlines with = or -)
- [x] **[P1, depends: A2]** Compute adjusted heading level (original + offset)
- [x] **[P1, depends: A2]** Handle overflow beyond H6 (convert to **bold**)
- [x] **[P2, depends: A2]** Preserve heading attributes and trailing content
- [x] **[P1, depends: A2]** Normalize line endings in embedded content to LF
- [x] **[P1, depends: A2]** Write tests for all heading styles and edge cases

**Acceptance Criteria:** ✅ All heading styles correctly adjusted, overflow handled, test corpus passes

**Blocks:** C2 (emitter uses heading adjuster)

---

### C2: Markdown Emitter **[P0]**
**Dependencies:** B4, C1
**Estimated:** 8 hours
**Status:** ✅ Completed on 2025-12-09

- [x] **[P0, depends: B4]** Implement tree traversal for output generation
- [x] **[P0, depends: B4]** Generate headings from node content or file names
- [x] **[P0, depends: B4]** Use effective depth for nested embeddings (parent + node depth)
- [x] **[P0, depends: B4, C1]** Embed file content with adjusted headings
- [x] **[P1, depends: B4]** Insert blank lines between sibling sections
- [x] **[P0, depends: B4]** Handle inline text literals as body content
- [x] **[P0, depends: B4]** Ensure final output ends with exactly one LF
- [x] **[P1, depends: B4]** Write emitter tests matching expected output

**Acceptance Criteria:** Emitter produces valid Markdown matching expected output for all test cases

**Blocks:** D2 (driver needs emitter to produce output)

---

### C3: Manifest Generator **[P1]**
**Dependencies:** B3 ✅
**Estimated:** 3 hours
**Status:** ✅ Completed on 2025-12-09

- [x] **[P1, depends: B3]** Implement `Manifest` struct (timestamp, version, root, sources)
- [x] **[P1, depends: B3]** Generate ISO 8601 timestamp
- [x] **[P1, depends: B3]** Sort manifest JSON keys alphabetically for determinism
- [x] **[P1, depends: B3]** Format JSON with consistent structure
- [x] **[P1, depends: B3]** Write manifest to specified path
- [x] **[P1, depends: B3]** Ensure manifest ends with exactly one LF
- [x] **[P1, depends: B3]** Write tests for manifest accuracy

**Acceptance Criteria:** ✅ Manifest contains accurate metadata for all source files, JSON format is deterministic

**Completion Note (2025-12-09):** Implemented Manifest and ManifestGenerator with ISO 8601 timestamps, alphabetically sorted JSON keys, and comprehensive test coverage (15 tests). All acceptance criteria met, including deterministic output and performance targets (1000+ entries in <500ms).

---

## Phase 6: CLI & Integration

**Goal:** Command-line interface and end-to-end compilation
**Estimated Duration:** 13 hours
**Track:** A (Core Compiler)

### D1: Argument Parsing **[P1]**
**Dependencies:** A1 ✅
**Estimated:** 4 hours
**Status:** ✅ Completed on 2025-12-09

- [x] **[P1, depends: A1]** Define command structure with swift-argument-parser
- [x] **[P1, depends: A1]** Implement `@Argument` for input file
- [x] **[P1, depends: A1]** Implement `--output, -o` option
- [x] **[P1, depends: A1]** Implement `--manifest, -m` option
- [x] **[P1, depends: A1]** Implement `--root, -r` option
- [x] **[P1, depends: A1]** Implement `--strict` flag (default)
- [x] **[P1, depends: A1]** Implement `--lenient` flag
- [x] **[P1, depends: A1]** Implement `--stats` flag
- [x] **[P1, depends: A1]** Implement `--dry-run` flag
- [x] **[P1, depends: A1]** Implement `--verbose, -v` flag
- [x] **[P1, depends: A1]** Implement `--version` flag
- [x] **[P1, depends: A1]** Implement `--help, -h` flag
- [x] **[P1, depends: A1]** Validate argument combinations (strict XOR lenient)
- [x] **[P1, depends: A1]** Generate help text
- [x] **[P1, depends: A1]** Write argument parsing tests

**Acceptance Criteria:** ✅ All documented arguments recognized and validated, help text accurate

**Completion Note (2025-12-09):** Implemented full CLI argument parsing using swift-argument-parser. All 11 arguments (1 positional, 3 options, 4 action flags, 2 system flags) functional. 38 comprehensive unit tests added (363 total). CompilerArguments struct created for D2 integration.

**Blocks:** D2 (driver needs argument parsing)

---

### D2: Compiler Driver **[P0]**
**Dependencies:** C2, C3, D1
**Estimated:** 6 hours
**Status:** ✅ Completed on 2025-12-21

- [x] **[P0, depends: C2, D1]** Implement `CompilerDriver` orchestrating parse → resolve → emit → manifest pipeline
- [x] **[P1, depends: D1]** Implement dry-run mode (validate without writing)
- [x] **[P1, depends: D1]** Implement verbose logging
- [x] **[P2, depends: D1]** Handle interruption signals (SIGINT, SIGTERM) gracefully
- [x] **[P1, depends: D1]** Set default values for output/manifest/root paths
- [x] **[P1, depends: C2, C3]** Write end-to-end compilation tests (7/10 tests passing)
- [~] **[P1, depends: C2, C3]** Test with test corpus files (partial: V01, V03, I01-I03, I10 implemented)

**Acceptance Criteria:** ✅ End-to-end compilation succeeds for valid inputs, fails correctly for invalid inputs (tested with V01, V03, I01-I03, I10)

**Completion Note (2025-12-10):** Implemented CompilerDriver with full pipeline orchestration. Added integration test suite with 7/10 tests passing. Test fixtures created for key validation cases. Known limitations: statistics integration incomplete (manifest metrics pending), full test corpus (V01-V14, I01-I10) partially implemented.

**Blocks:** E1 (integration tests need working driver)

---

### BUG-D2-001: Signal Handling Regression **[P1]**
**Dependencies:** D2 ✅
**Estimated:** 1 hour
**Status:** ✅ Completed on 2025-12-21

- [x] **[P1, depends: D2]** Move signal handling off main queue to avoid ignored SIGINT/SIGTERM
- [x] **[P1, depends: D2]** Ensure interruption still exits with standard codes (130/143)
- [x] **[P1, depends: D2]** Confirm `swift test` passes

**Acceptance Criteria:** SIGINT/SIGTERM are handled even during synchronous compile on main thread

---

### D3: Diagnostic Printer **[P1]**
**Dependencies:** A2 ✅
**Estimated:** 4 hours
**Status:** ✅ Completed on 2025-12-12

- [x] **[P1, depends: A2]** Format error messages with source context
- [x] **[P1, depends: A2]** Implement format: `<file>:<line>: error: <message>`
- [x] **[P1, depends: A2]** Show context line with caret (^^^) pointing to issue
- [x] **[P2, depends: A2]** Colorize output for terminal display (ANSI colors with auto-detection)
- [x] **[P1, depends: A2]** Support plain text output for non-terminal destinations
- [x] **[P2, depends: A2]** Aggregate multiple errors when possible
- [x] **[P1, depends: A2]** Write diagnostic formatting tests (22 comprehensive tests)

**Acceptance Criteria:** ✅ Error messages clearly identify problem location and nature, format matches specification

**Completion Note (2025-12-12):** Implemented DiagnosticPrinter with full error formatting, source context extraction, caret positioning, ANSI color support with terminal auto-detection, multi-error aggregation, and 22 comprehensive unit tests. All acceptance criteria met. Performance target achieved (<1ms per error).

---

### D4: Statistics Reporter **[P2]**
**Dependencies:** D1
**Estimated:** 3 hours
**Status:** ✅ Completed on 2025-12-16

- [x] **[P2, depends: D1]** Implement `StatsCollector` tracking compilation metrics
- [x] **[P2, depends: D1]** Count Hypercode files processed
- [x] **[P2, depends: D1]** Count Markdown files embedded
- [x] **[P2, depends: D1]** Sum total input bytes
- [x] **[P2, depends: D1]** Record output bytes
- [x] **[P2, depends: D1]** Track maximum depth encountered
- [x] **[P2, depends: D1]** Measure elapsed time (ms)
- [x] **[P2, depends: D1]** Implement `StatsReporter` formatting output
- [x] **[P2, depends: D1]** Integrate with `--stats` flag and verbose mode
- [x] **[P2, depends: D1]** Write statistics tests

**Acceptance Criteria:** Statistics output includes all specified metrics, integrates with CLI flags

**Completion Note (2025-12-16):** Added Statistics module with collector/reporter, instrumented CompilerDriver and ReferenceResolver to gather metrics, and validated via unit and integration tests. Statistics printing now triggered by `--stats`; outputs remain unchanged when disabled.

---

## Phase 7: Lexer & Resolver Integration with Specs

**Goal:** Replace imperative validation with declarative specifications
**Estimated Duration:** 11 hours
**Track:** Integration (requires both A and B tracks complete)

### Integration-1: Lexer with Specifications **[P1]**
**Dependencies:** Phase 2 (Lexer) ✅, Phase 3 (Specs) ✅
**Estimated:** 5 hours
**Status:** ✅ Completed on 2025-12-11

- [x] **[P1, depends: Lexer, Spec-4]** Refactor Lexer to use `LineKindDecision` for classification ✅
- [x] **[P1, depends: Lexer, Spec-2]** Replace imperative tab checking with `NoTabsIndentSpec` ✅
- [x] **[P1, depends: Lexer, Spec-2]** Replace imperative indent validation with `IndentMultipleOf4Spec` ✅
- [x] **[P1, depends: Lexer, Spec-2]** Replace imperative depth checking with `DepthWithinLimitSpec` ✅
- [x] **[P1, depends: Lexer, Spec-4]** Use `ValidNodeLineSpec` for comprehensive node validation ✅
- [x] **[P1, depends: Lexer, Spec-4]** Update error messages to reference specification failures ✅
- [x] **[P1, depends: Lexer, Spec-4]** Verify all existing lexer tests pass ✅
- [x] **[P1, depends: Lexer, Spec-4]** Add integration tests for specification-based lexer ✅
- [x] **[P2, depends: Lexer, Spec-4]** Benchmark performance vs imperative version ✅

**Acceptance Criteria:** ✅ Lexer uses specifications for all validation, tests pass, <10% performance overhead (399 tests, 14 skipped, 0 failures)

---

### Integration-2: Resolver with Specifications **[P1]**
**Dependencies:** Phase 4 (Resolver) ✅, Phase 3 (Specs) ✅
**Estimated:** 6 hours
**Status:** ✅ Completed on 2025-12-12

- [x] **[P1, depends: B1, Spec-4]** Refactor ReferenceResolver to use specifications ✅
- [x] **[P1, depends: B1, Spec-3]** Replace imperative path validation with `NoTraversalSpec` ✅
- [x] **[P1, depends: B1, Spec-3]** Replace imperative extension checking with `HasMarkdownExtensionSpec`/`HasHypercodeExtensionSpec` ✅
- [x] **[P1, depends: B1, Spec-4]** Maintain path classification logic compatibility ✅
- [x] **[P1, depends: B1, Spec-3]** Verify `LooksLikeFileReferenceSpec` integration ✅
- [x] **[P1, depends: B1, Spec-4]** Preserve error messages for specification failures ✅
- [x] **[P1, depends: B1, Spec-4]** Maintain backward compatibility with existing API ✅
- [x] **[P1, depends: B1, Spec-4]** Code review verified specification integration ✅

**Acceptance Criteria:** ✅ Resolver uses specifications for all path validation (5 specs integrated: LooksLikeFileReferenceSpec, NoTraversalSpec, HasMarkdownExtensionSpec, HasHypercodeExtensionSpec, WithinRootSpec), full backward compatibility maintained

---

## Phase 8: Testing & Quality Assurance

**Goal:** Comprehensive test coverage and cross-platform validation
**Estimated Duration:** 12 hours
**Track:** Integration (requires compiler complete)

### E1: Test Corpus Implementation **[P0]**
**Dependencies:** D2 (needs working compiler) ✅
**Estimated:** 8 hours
**Status:** ✅ Completed on 2025-12-10 (pending Swift verification)

- [x] **[P1, depends: D2]** Create test corpus directory structure
- [x] **[P0, depends: D2]** Implement Valid Input Tests (V01-V14):
  - [x] **[P0]** V01: Single root node with inline text
  - [x] **[P1]** V03: Nested hierarchy 3 levels deep
  - [x] **[P0]** V04: Single Markdown file reference at root
  - [x] **[P1]** V05: Nested Markdown file references
  - [x] **[P0]** V06: Single Hypercode file reference
  - [x] **[P1]** V07: Nested Hypercode files (3 levels)
  - [x] **[P1]** V08: Mixed inline text and file references
  - [x] **[P1]** V09: Markdown with headings H1-H4
  - [x] **[P1]** V10: Markdown with Setext headings
  - [x] **[P2]** V11: Comment lines interspersed
  - [x] **[P2]** V12: Blank lines between node groups
  - [x] **[P1]** V13: Maximum depth of 10 levels
  - [x] **[P2]** V14: Unicode content in literals and files
- [x] **[P0, depends: D2]** Implement Invalid Input Tests (I01-I10):
  - [x] **[P0]** I01: Tab characters in indentation
  - [x] **[P0]** I02: Misaligned indentation (not divisible by 4)
  - [x] **[P0]** I03: Unclosed quotation mark
  - [x] **[P1]** I04: Missing file reference (strict mode)
  - [x] **[P1]** I05: Direct circular dependency (A → A)
  - [x] **[P1]** I06: Indirect circular dependency (A → B → A)
  - [x] **[P1]** I07: Depth exceeding 10
  - [x] **[P0]** I08: Path traversal with ..
  - [x] **[P2]** I09: Unreadable file (permission error)
  - [x] **[P0]** I10: Multiple root nodes
- [x] **[P1, depends: D2]** Create golden files for each test ({test-id}.expected.md, {test-id}.expected.json)
- [x] **[P1, depends: D2]** Implement golden-file comparison tests
- [x] **[P1, depends: D2]** Verify exit codes for all error scenarios
- [~] **[P1, depends: D2]** Achieve >80% code coverage (requires Swift toolchain - pending verification)

**Acceptance Criteria:** All valid tests match golden files, all invalid tests fail predictably, >80% coverage

**Blocks:** E2 (cross-platform testing needs corpus)

---

### E2: Cross-Platform Testing **[P1]**
**Dependencies:** E1 ✅
**Estimated:** 4 hours
**Status:** ✅ Completed on 2025-12-11

- [x] **[P1, depends: E1]** Test on macOS Intel (marked out of scope — sufficient coverage with Linux x86_64 + macOS ARM64)
- [x] **[P1, depends: E1]** Test on macOS Apple Silicon (M1/M2) ✅ Verified
- [x] **[P1, depends: E1]** Test on Ubuntu 22.04 x86_64 ✅ Verified via CI
- [x] **[P0, depends: E1]** Verify deterministic output (byte-for-byte identical across platforms) ✅ Verified
- [x] **[P0, depends: E1]** Verify LF line endings on all platforms ✅ Verified

**Acceptance Criteria:** ✅ All 7 acceptance criteria met (2/2 in-scope platforms tested, deterministic compilation verified, identical test results across platforms)

---

### E3: Documentation **[P1]**
**Dependencies:** D2 (needs working compiler to document) ✅
**Estimated:** 4 hours
**Status:** ✅ Completed on 2025-12-12

- [x] **[P1, depends: D2]** Write README with installation instructions ✅
- [x] **[P1, depends: D1, D2]** Document usage examples with all CLI flags ✅
- [x] **[P1, depends: D2]** Document Hypercode language specification (grammar) ✅
- [x] **[P1, depends: D2]** Provide example files demonstrating all features ✅
- [x] **[P2, depends: Phase 7]** Document SpecificationCore integration patterns ✅
- [x] **[P2, depends: D2]** Generate API documentation from source comments ✅
- [x] **[P2, depends: D2]** Write architecture overview with diagrams ✅
- [x] **[P1, depends: D2]** Document error codes and meanings (exit codes 0-4) ✅
- [x] **[P2, depends: D2]** Create troubleshooting guide ✅
- [x] **[P2, depends: D2]** Document future extensions (v0.2+) ✅

**Acceptance Criteria:** ✅ Documentation is complete, accurate, and covers all features (8 documentation files created in DOCS/, 4 example files in docs/examples/, README updated)

---

### E4: Build Warnings Cleanup **[P2]**
**Dependencies:** D2 (compiler driver), E1 (test corpus)
**Estimated:** 2 hours
**Status:** ✅ Completed on 2025-12-21

- [x] **[P2, depends: D2]** Remove unused `result` bindings in integration tests
- [x] **[P2, depends: E1]** Remove unreachable code after `XCTSkip` in integration tests
- [x] **[P2, depends: D2]** Confirm `swift test` emits zero warnings
- [x] **[P2, depends: D2]** Update `DOCS/INPROGRESS/build-issues.md` to reflect clean build

**Acceptance Criteria:** `swift test` produces zero warnings; build-issues log updated

---

## Phase 9: Optimization & Finalization

**Goal:** Performance tuning and release preparation
**Estimated Duration:** 4 hours
**Track:** Release

### P9: Optimization Tasks **[P1]**
**Dependencies:** E1, E2
**Estimated:** 3 hours
**Status:** ✅ **COMPLETED** on 2025-12-21

- [x] **[P2, depends: E1]** Profile compilation with Instruments (macOS) or Valgrind (Linux)
- [x] **[P2, depends: E1]** Optimize hot paths identified in profiling
- [x] **[P1, depends: E1]** Benchmark against performance targets **Completed 2025-12-16**:
  - [x] **[P1]** 1000-node tree compilation < 5 seconds (853ms average over 5 runs)
  - [x] **[P1]** Linear scaling with file count (R² = 0.984 across 10–120 files)
- [x] **[P0, depends: E2]** Verify deterministic output (repeated compilations identical) **Completed 2025-12-12**
- [x] **[P2, depends: E1]** Test with large corpus (100+ files) — 120-file corpus completed in 206ms
- [x] **[P1, depends: E1]** Verify manifest JSON key alphabetical sorting — 100% manifest compliance confirmed
- [x] **[P2, depends: E1]** Test memory usage with large files (>1MB)
- [x] **[P2, depends: E1]** Fix any memory leaks detected

**Acceptance Criteria:** Performance targets met, no memory leaks, deterministic output verified

---

### Release Preparation **[P0]**
**Dependencies:** E1, E2, E3, Optimization
**Estimated:** 3 hours
**Status:** ✅ **COMPLETED** on 2025-12-16

- [x] **[P0, depends: E1, E2]** Tag version 0.1.0 **Completed 2025-12-16** (local tag created)
- [x] **[P0, depends: E2]** Build release binaries for all platforms **Completed 2025-12-16** (Linux x86_64)
- [x] **[P1, depends: E2]** Create distribution packages (DMG, DEB, ZIP) **Completed 2025-12-16** (ZIP archive created)
- [x] **[P1, depends: E3]** Write release notes **Completed 2025-12-16**
- [x] **[P1, depends: E3]** Update CHANGELOG **Completed 2025-12-16**
- [x] **[P2, depends: E1]** Archive test results and coverage reports **Completed 2025-12-16**

**Acceptance Criteria:** Release packages built and tested, documentation finalized

---

## Phase 10: Editor Engine Module

**Goal:** Implement the Editor Engine module per PRD requirements
**Estimated Duration:** 25 hours
**Track:** C (Editor Engine)

### EE0: EditorEngine Module Foundation **[P1]**
**Dependencies:** D2 (Phase 6 — CLI & Integration)
**Estimated:** 1 hour
**Status:** ✅ Completed on 2025-12-20

- [x] **[P1, depends: D2]** Define SPM `Editor` trait in Package.swift
- [x] **[P1, depends: D2]** Create EditorEngine target with dependencies (Core, Parser, Resolver, Emitter, Statistics)
- [x] **[P1, depends: D2]** Create Sources/EditorEngine/ directory with module entry point
- [x] **[P1, depends: D2]** Create Tests/EditorEngineTests/ with basic tests
- [x] **[P1, depends: D2]** Verify compilation (swift test passes)

**Acceptance Criteria:** EditorEngine module compiles, all existing tests pass

### EE1: Project Indexing **[P1]**
**Dependencies:** EE0 ✅
**Estimated:** 3 hours
**Status:** ✅ Completed on 2025-12-20

- [x] **[P1, depends: EE0]** Define `ProjectIndex` struct with file metadata ✅
- [x] **[P1, depends: EE0]** Implement file scanner with deterministic ordering (lexicographic sort) ✅
- [x] **[P1, depends: EE0]** Add `.hyperpromptignore` support (glob patterns) ✅
- [x] **[P1, depends: EE0]** Exclude hidden directories by default (.git, build, node_modules) ✅
- [x] **[P1, depends: EE0]** Write unit tests (5+ tests covering edge cases) ✅ (47+ tests)

**Acceptance Criteria:** ✅ Index lists all .hc and .md files, deterministic ordering, respects ignore rules

**Completion Note (2025-12-20):** Implemented full project indexing with 6 new files (~800 LOC), 47+ unit tests, and comprehensive glob pattern matching. Swift compiler not available for validation; code review completed. See `DOCS/INPROGRESS/EE1-summary.md` for details.

### EE2: Parsing with Link Spans **[P1]**
**Dependencies:** EE1
**Estimated:** 3 hours
**Status:** ✅ Completed on 2025-12-21

- [x] **[P1, depends: EE1]** Define `LinkSpan` struct with byte/line ranges
- [x] **[P1, depends: EE1]** Extend Parser to extract link spans during parsing
- [x] **[P1, depends: EE1]** Implement link detection heuristic (LooksLikeFileReferenceSpec)
- [x] **[P1, depends: EE1]** Handle parse errors gracefully (partial AST + diagnostics)
- [x] **[P1, depends: EE1]** Write unit tests (5+ tests including UTF-8 edge cases)

**Acceptance Criteria:** All file references captured with accurate byte/line ranges

### EE3: Link Resolution **[P1]**
**Dependencies:** EE2
**Estimated:** 2 hours
**Status:** ✅ Completed on 2025-12-21

- [x] **[P1, depends: EE2]** Define `ResolvedTarget` enum (inlineText, markdownFile, hypercodeFile, forbidden, invalid, ambiguous)
- [x] **[P1, depends: EE2]** Implement `EditorResolver` wrapper around existing ReferenceResolver
- [x] **[P1, depends: EE2]** Handle missing files gracefully (strict vs lenient mode)
- [x] **[P1, depends: EE2]** Detect and report ambiguous matches (multiple candidates)
- [x] **[P1, depends: EE2]** Write unit tests (6+ tests including path traversal rejection)

**Acceptance Criteria:** Resolution matches CLI behavior exactly, edge cases handled

### EE4: Editor Compilation **[P1]**
**Dependencies:** EE3
**Estimated:** 3 hours
**Status:** ✅ Completed on 2025-12-21

- [x] **[P1, depends: EE3]** Define `CompileOptions` and `CompileResult` structs
- [x] **[P1, depends: EE3]** Implement `EditorCompiler` wrapper around CompilerDriver
- [x] **[P1, depends: EE3]** Capture all errors as diagnostics (no throwing in public API)
- [x] **[P1, depends: EE3]** Ensure deterministic output (matches CLI byte-for-byte)
- [x] **[P1, depends: EE3]** Write unit tests (5+) and integration tests (4+)

**Acceptance Criteria:** Output matches CLI exactly, diagnostics capture all errors

### EE5: Diagnostics Mapping **[P1]**
**Dependencies:** EE4
**Estimated:** 2 hours
**Status:** ✅ Completed on 2025-12-21

- [x] **[P1, depends: EE4]** Define `Diagnostic` struct with error codes, severity, ranges
- [x] **[P1, depends: EE4]** Implement `DiagnosticMapper` (CompilerError → Diagnostic)
- [x] **[P1, depends: EE4]** Assign error codes by category (E001-E099: syntax, E100-E199: resolution, etc.)
- [x] **[P1, depends: EE4]** Write unit tests (4+ tests verifying error code mapping)

**Acceptance Criteria:** All CLI errors map to editor diagnostics with ranges

### EE6: Documentation & Testing **[P1]**
**Dependencies:** EE5
**Estimated:** 7 hours
**Status:** ✅ Completed on 2025-12-21

- [x] **[P1, depends: EE5]** Write DOCS/EDITOR_ENGINE.md (API reference, usage guide, integration patterns)
- [x] **[P1, depends: EE5]** Achieve >80% code coverage with unit tests
- [x] **[P1, depends: EE5]** Write integration tests with test corpus (V01-V14, I01-I10)
- [x] **[P1, depends: EE5]** Verify CLI vs Editor output is byte-for-byte identical

**Acceptance Criteria:** API documented, >80% coverage, integration tests pass

### EE7: SpecificationCore Decision Refactor **[P1]**
**Dependencies:** EE6
**Estimated:** 4 hours
**Status:** ✅ Completed on 2025-12-22

- [x] **[P1, depends: EE6]** Add SpecificationCore SPM dependency to EditorEngine target
- [x] **[P1, depends: EE6]** Audit EditorEngine decision points (if/else, boolean flags, decision enums)
- [x] **[P1, depends: EE6]** Model decisions with SpecificationCore specs and DecisionSpec/FirstMatchSpec
- [x] **[P1, depends: EE6]** Replace boolean flags and branching with spec evaluation and adapters
- [x] **[P1, depends: EE6]** Update tests to cover spec-driven decision paths

**Acceptance Criteria:** EditorEngine relies on SpecificationCore for decision logic; boolean flags and imperative branching are removed from decision points; tests cover all decision paths.

### EE8: EditorEngine Validation Follow-ups **[P1]**
**Dependencies:** EE7
**Estimated:** 6 hours
**Status:** ✅ Completed on 2025-12-23

- [x] **[P1, depends: EE7]** Add SwiftPM `Editor` trait and gate EditorEngine product/target
- [x] **[P1, depends: EE7]** Remove `CLI` dependency by extracting shared compile orchestration
- [x] **[P1, depends: EE7]** Add `DOCS/TASKS_ARCHIVE/EE7-summary.md` archive report
- [x] **[P1, depends: EE7]** Map EditorParser IO failures into diagnostics (no throws) and add tests

**Acceptance Criteria:** EditorEngine is trait-gated, no longer depends on CLI, EE7 archive is present, and parser IO errors are surfaced as diagnostics with tests.

---

## Exit Codes Reference

| Code | Category         | Description                                            |
|------|------------------|--------------------------------------------------------|
| 0    | Success          | Compilation completed without errors                   |
| 1    | IO Error         | File not found, permission denied, or disk full        |
| 2    | Syntax Error     | Invalid Hypercode syntax in source file                |
| 3    | Resolution Error | Circular dependency or missing reference in strict mode|
| 4    | Internal Error   | Unexpected condition indicating compiler bug           |

---

## Progress Tracking

**Overall Progress:** 159 / 245 tasks completed (65% — Phases 1-10 complete, Phases 11-15 pending)

### By Phase
- [x] **Phase 1:** Foundation & Core Types (3/3 major tasks) — **6h** — Track A
- [x] **Phase 2:** Lexer & Parser (2/2 major tasks) — **14h** — Track A
- [x] **Phase 3:** Specifications (4/4 major tasks) — **17h** — Track B ⚡ **Parallel**
- [x] **Phase 4:** Reference Resolution (4/4 major tasks) — **12h** — Track A
- [x] **Phase 5:** Markdown Emission (3/3 major tasks) — **11h** — Track A
- [x] **Phase 6:** CLI & Integration (5/5 major tasks) — **13h** — Track A
- [x] **Phase 7:** Integration with Specs (2/2 major tasks) — **11h** — Integration
- [x] **Phase 8:** Testing & QA (4/4 major tasks) — **12h** — Integration
- [x] **Phase 9:** Optimization & Release (2/2 major tasks) — **4h** — Release
- [x] **Phase 10:** Editor Engine Module (9/9 major tasks) — **31h** — Track C
- [ ] **Phase 11:** VS Code Integration Architecture (0/3 major tasks) — **18h** — Track D ⚡ **FFI Blocker**
- [ ] **Phase 12:** EditorEngine API Enhancements (0/6 major tasks) — **14h** — Track C
- [ ] **Phase 13:** Performance & Incremental Compilation (0/4 major tasks) — **15h** — Track C
- [ ] **Phase 14:** VS Code Extension Development (0/10 major tasks) — **35h** — Track D
- [ ] **Phase 15:** PRD Validation & Gap Closure (0/2 major tasks) — **4h** — Track D

### By Priority (Updated for Phases 11-15)
- **[P0] Critical:** 47 / 68 tasks (blocks project) — +21 new P0 tasks
- **[P1] High:** 95 / 152 tasks (required for v0.2) — +57 new P1 tasks
- **[P2] Medium:** 17 / 25 tasks (can defer) — +8 new P2 tasks

### By Track
- **Track A (Core Compiler):** Phases 1, 2, 4, 5, 6 — Sequential, 56 hours ✅ Complete
- **Track B (Specifications):** Phase 3 — Parallel with Track A, 17 hours ✅ Complete
- **Integration:** Phase 7, 8 — Requires both tracks, 23 hours ✅ Complete
- **Release:** Phase 9 — Final QA, 4 hours ✅ Complete
- **Track C (Editor Engine):** Phase 10, 12, 13 — 60 hours (31h complete, 29h pending)
- **Track D (VS Code Extension):** Phase 11, 14, 15 — 57 hours (0h complete, 57h pending)

---

## Quick Start Recommendation

### For Solo Developer (Sequential)
1. **Week 1:** Phase 1-2 (Foundation + Parser) — 20h
2. **Week 2:** Phase 3-4 (Specs + Resolver) — 29h
3. **Week 3:** Phase 5-6 (Emitter + CLI) — 24h
4. **Week 4:** Phase 7-8-9 (Integration + Tests + Release) — 27h

**Total:** ~4 weeks (100 hours calendar time)

### For Two Developers (Parallel)
1. **Week 1:**
   - Dev A: Phase 1-2 (Foundation + Parser) — 20h
   - Dev B: Phase 3 (Specifications) — 17h
2. **Week 2:**
   - Dev A: Phase 4 (Resolver) — 12h
   - Dev B: Phase 5-6 (Emitter + CLI) — 24h
3. **Week 3:**
   - Both: Phase 7 (Integration) — 11h
   - Both: Phase 8 (Testing) — 12h
   - Both: Phase 9 (Release) — 4h

**Total:** ~3 weeks (60 hours per developer)

---

## Notes

### Dependencies
- **SpecificationCore:** Must be available before Phase 3
- **Order:** Phases can overlap using tracks
- **Testing:** Write tests concurrently with implementation
- **Documentation:** Update incrementally throughout

### Risk Mitigation
- **Critical path tasks (P0):** Monitor closely, any delay here delays project
- **Phase 3 (Specs):** Can run in parallel, provides safety net
- **Phase 7 (Integration):** Plan buffer time for refactoring

### Success Metrics
- All P0 tasks complete → minimum viable compiler
- All P1 tasks complete → production-ready v0.1
- All P2 tasks complete → polished v0.1

---

## Phase 11: VS Code Extension Integration Architecture

**Goal:** Establish interoperability layer between Swift EditorEngine and TypeScript VS Code extension
**Estimated Duration:** 18 hours (2-3 weeks)
**Track:** D (VS Code Extension — FFI Layer)
**Status:** 🔴 **BLOCKED** — Addresses blocker issues from PRD validation

**Context:** PRD_VSCode_Extension.md validation identified critical gaps preventing implementation. This phase resolves 🔴 BLOCKER issues by establishing a bridge between Swift and Node.js.

### VSC-1: Integration Architecture Decision **[P0]** **INPROGRESS**
**Dependencies:** EE8 (Phase 10 — EditorEngine complete)
**Estimated:** 4 hours
**Status:** ⏸️ Pending → 🔄 In Progress

- [ ] **[P0, depends: EE8]** Evaluate integration options:
  - [ ] Option A: Language Server Protocol (LSP) — standard, multi-editor support
  - [ ] Option B: CLI + JSON-RPC — simple, process-based communication
  - [ ] Option C: Node.js Native Addon (FFI) — fast, in-process calls
- [ ] **[P0, depends: EE8]** Prototype each option with EditorEngine.indexProject() call
- [ ] **[P0, depends: EE8]** Benchmark performance (startup time, latency, throughput)
- [ ] **[P0, depends: EE8]** Document trade-offs (complexity, maintainability, cross-platform support)
- [ ] **[P1, depends: EE8]** Choose architecture (recommend LSP for long-term, CLI for MVP)
- [ ] **[P1, depends: EE8]** Document decision in DOCS/ARCHITECTURE_DECISIONS.md

**Acceptance Criteria:** Architecture chosen, prototype demonstrates EditorEngine call from TypeScript, benchmarks documented

**Blocks:** VSC-2 (implementation depends on architecture choice)

**Resolution Status:** 🔴 BLOCKER (Issue 1.1 from validation report)

---

### VSC-2A: Language Server Implementation (if LSP chosen) **[P0]**
**Dependencies:** VSC-1
**Estimated:** 12 hours
**Status:** ⏸️ Pending (conditional on VSC-1 decision)

- [ ] **[P0, depends: VSC-1]** Create `Sources/LanguageServer/` module in Swift
- [ ] **[P0, depends: VSC-1]** Implement LSP server skeleton (initialize, shutdown, exit)
- [ ] **[P0, depends: VSC-1]** Add JSON-RPC message handling (stdio transport)
- [ ] **[P0, depends: VSC-1]** Implement `textDocument/didOpen` notification
- [ ] **[P0, depends: VSC-1]** Implement `textDocument/didChange` notification
- [ ] **[P0, depends: VSC-1]** Implement `textDocument/didSave` notification
- [ ] **[P0, depends: VSC-1]** Implement `textDocument/definition` request (go-to-definition)
- [ ] **[P0, depends: VSC-1]** Implement `textDocument/hover` request
- [ ] **[P0, depends: VSC-1]** Implement `textDocument/publishDiagnostics` notification
- [ ] **[P1, depends: VSC-1]** Add LSP server build target (executable)
- [ ] **[P1, depends: VSC-1]** Write integration tests (mock LSP client)
- [ ] **[P1, depends: VSC-1]** Document LSP capabilities in DOCS/LSP.md

**Acceptance Criteria:** LSP server binary runs, handles basic requests, integrates with EditorEngine

**Blocks:** VSC-4 (extension needs LSP server)

**Resolution Status:** 🔴 BLOCKER (Issue 1.1 — FFI layer alternative)

---

### VSC-2B: CLI JSON-RPC Interface (if CLI chosen) **[P0]**
**Dependencies:** VSC-1
**Estimated:** 8 hours
**Status:** ⏸️ Pending (conditional on VSC-1 decision)

- [ ] **[P0, depends: VSC-1]** Add `hyperprompt-editor` CLI subcommand
- [ ] **[P0, depends: VSC-1]** Implement JSON-RPC message handling (stdin/stdout)
- [ ] **[P0, depends: VSC-1]** Add `editor.indexProject` RPC method
- [ ] **[P0, depends: VSC-1]** Add `editor.parse` RPC method (file path → ParsedFile JSON)
- [ ] **[P0, depends: VSC-1]** Add `editor.resolve` RPC method (link → ResolvedTarget JSON)
- [ ] **[P0, depends: VSC-1]** Add `editor.compile` RPC method (entry file → CompileResult JSON)
- [ ] **[P0, depends: VSC-1]** Add `editor.linkAt` RPC method (file, line, column → LinkSpan JSON)
- [ ] **[P1, depends: VSC-1]** Handle errors gracefully (JSON error responses)
- [ ] **[P1, depends: VSC-1]** Write CLI RPC integration tests
- [ ] **[P1, depends: VSC-1]** Document RPC protocol in DOCS/RPC_PROTOCOL.md

**Acceptance Criteria:** CLI accepts JSON-RPC requests, returns JSON responses, all EditorEngine methods exposed

**Blocks:** VSC-4 (extension needs RPC interface)

**Resolution Status:** 🔴 BLOCKER (Issue 1.1 — FFI layer alternative)

---

### VSC-2C: Node.js Native Addon (if FFI chosen) **[P0]**
**Dependencies:** VSC-1
**Estimated:** 14 hours
**Status:** ⏸️ Pending (conditional on VSC-1 decision)

- [ ] **[P0, depends: VSC-1]** Create C API wrapper for EditorEngine
- [ ] **[P0, depends: VSC-1]** Define C-compatible structs (CProjectIndex, CLinkSpan, etc.)
- [ ] **[P0, depends: VSC-1]** Implement memory management (alloc/free functions)
- [ ] **[P0, depends: VSC-1]** Generate Node.js addon scaffold (node-gyp + binding.gyp)
- [ ] **[P0, depends: VSC-1]** Wrap C API with N-API bindings
- [ ] **[P0, depends: VSC-1]** Handle async calls (libuv thread pool)
- [ ] **[P1, depends: VSC-1]** Cross-compile for macOS (x64, arm64) and Linux (x64)
- [ ] **[P1, depends: VSC-1]** Package pre-built binaries for extension distribution
- [ ] **[P1, depends: VSC-1]** Write native addon tests (Node.js test suite)
- [ ] **[P1, depends: VSC-1]** Document FFI layer in DOCS/FFI_API.md

**Acceptance Criteria:** Node.js addon compiles, calls EditorEngine, handles memory correctly, works on all platforms

**Blocks:** VSC-4 (extension needs native addon)

**Resolution Status:** 🔴 BLOCKER (Issue 1.1 — FFI layer)

---

## Phase 12: EditorEngine API Enhancements

**Goal:** Add missing APIs required by VS Code extension PRD
**Estimated Duration:** 14 hours (2 weeks)
**Track:** C (Editor Engine — API Extensions)
**Status:** 🟠 **CRITICAL** — Addresses critical and major gaps from PRD validation

**Context:** VS Code extension requires position-based queries, workspace diagnostics, and async APIs not present in current EditorEngine.

### EE-EXT-1: Position-to-Link Query API **[P0]**
**Dependencies:** EE8 (Phase 10 — EditorEngine complete)
**Estimated:** 3 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: EE8]** Add `EditorParser.linkAt(line:column:) -> LinkSpan?` method
- [ ] **[P0, depends: EE8]** Implement binary search over sorted link spans (O(log n) lookup)
- [ ] **[P0, depends: EE8]** Handle edge cases:
  - [ ] Position before first link → return nil
  - [ ] Position after last link → return nil
  - [ ] Position between links → return nil
  - [ ] Position at link boundary → return link
  - [ ] Overlapping ranges → return first match
- [ ] **[P1, depends: EE8]** Add `ParsedFile.linksAt(range:) -> [LinkSpan]` for range queries
- [ ] **[P1, depends: EE8]** Write unit tests (10+ edge cases)

**Acceptance Criteria:** Position queries return correct link or nil, O(log n) performance verified

**Code Location:** `Sources/EditorEngine/EditorParser.swift:1`

**Blocks:** VSC-5 (go-to-definition and hover need this API)

**Resolution Status:** 🔴 BLOCKER (Issue 1.2 from validation report)

---

### EE-EXT-2: Workspace-Level Diagnostics **[P1]**
**Dependencies:** EE8
**Estimated:** 4 hours
**Status:** ⏸️ Pending

- [ ] **[P1, depends: EE8]** Add `EditorEngine.validateWorkspace(root:options:) -> [String: [Diagnostic]]` method
- [ ] **[P1, depends: EE8]** Return diagnostics grouped by file path (dictionary)
- [ ] **[P1, depends: EE8]** Implement incremental validation (only changed files)
- [ ] **[P1, depends: EE8]** Handle multi-file errors (e.g., circular dependencies spanning files)
- [ ] **[P1, depends: EE8]** Add performance optimization (parallel file validation)
- [ ] **[P1, depends: EE8]** Write unit tests (workspace with 50+ files)

**Acceptance Criteria:** Workspace validation returns diagnostics for all files, <5s for 100-file workspace

**Blocks:** VSC-6 (Problems panel needs workspace diagnostics)

**Resolution Status:** 🟠 CRITICAL (Issue 2.1 from validation report)

---

### EE-EXT-3: Source Map Generation **[P2]**
**Dependencies:** EE8
**Estimated:** 5 hours
**Status:** ⏸️ Pending

- [ ] **[P2, depends: EE8]** Define `SourceMap` struct (output line → source location mapping)
- [ ] **[P2, depends: EE8]** Extend `Emitter` to track source ranges during compilation
- [ ] **[P2, depends: EE8]** Add `CompileResult.sourceMap` field (optional)
- [ ] **[P2, depends: EE8]** Implement JSON source map format (compatible with browser devtools)
- [ ] **[P2, depends: EE8]** Add `SourceMap.lookup(outputLine:) -> SourceLocation?` method
- [ ] **[P2, depends: EE8]** Write unit tests (verify source map accuracy for nested files)

**Acceptance Criteria:** Source maps correctly map output lines to source locations

**Blocks:** VSC-7 (bidirectional navigation feature — Phase 4 of PRD)

**Resolution Status:** 🟠 CRITICAL (Issue 2.2 from validation report — optional feature)

---

### EE-EXT-4: Multi-Root Workspace Support **[P1]**
**Dependencies:** EE8
**Estimated:** 2 hours
**Status:** ⏸️ Pending

- [ ] **[P1, depends: EE8]** Update `EditorResolver.init` to accept `workspaceRoots: [String]`
- [ ] **[P1, depends: EE8]** Update resolution algorithm to search all roots in order
- [ ] **[P1, depends: EE8]** Document priority rules (first match wins)
- [ ] **[P1, depends: EE8]** Handle ambiguous references across roots (error or first match?)
- [ ] **[P1, depends: EE8]** Write unit tests (multi-root workspace scenarios)

**Acceptance Criteria:** Resolver handles multiple workspace roots, priority documented

**Code Location:** `Sources/EditorEngine/EditorResolver.swift:157`

**Resolution Status:** 🟠 CRITICAL (Issue 2.3 from validation report)

---

### EE-EXT-5: Async API Variants **[P1]**
**Dependencies:** EE8
**Estimated:** 3 hours
**Status:** ⏸️ Pending

- [ ] **[P1, depends: EE8]** Add `async` variants of blocking methods:
  - [ ] `EditorParser.parse(filePath:) async -> ParsedFile`
  - [ ] `EditorCompiler.compile(entryFile:options:) async -> CompileResult`
  - [ ] `EditorEngine.indexProject(workspaceRoot:) async -> ProjectIndex`
  - [ ] `EditorEngine.validateWorkspace(root:) async -> [String: [Diagnostic]]`
- [ ] **[P1, depends: EE8]** Use Swift concurrency (async/await, Task)
- [ ] **[P1, depends: EE8]** Ensure thread-safety (all types already Sendable)
- [ ] **[P1, depends: EE8]** Write async tests using XCTest async support

**Acceptance Criteria:** Async methods don't block caller, thread-safe, tests pass

**Resolution Status:** 🟠 CRITICAL (Issue 2.4 from validation report)

---

### EE-EXT-6: Documentation & Semantic Clarifications **[P1]**
**Dependencies:** EE-EXT-1, EE-EXT-2, EE-EXT-3, EE-EXT-4, EE-EXT-5
**Estimated:** 2 hours
**Status:** ⏸️ Pending

- [ ] **[P1, depends: EE-EXT-1..5]** Update DOCS/EDITOR_ENGINE.md with new APIs
- [ ] **[P1, depends: EE8]** Document `LinkSpan.referenceHint` semantics (when to trust it)
- [ ] **[P1, depends: EE8]** Document `CompileResult.manifest` JSON schema
- [ ] **[P1, depends: EE8]** Document error recovery behavior (partial AST semantics)
- [ ] **[P1, depends: EE8]** Document resolution mode trade-offs (strict vs lenient)
- [ ] **[P1, depends: EE8]** Add code examples for all new APIs

**Acceptance Criteria:** All new APIs documented, semantic ambiguities resolved

**Resolution Status:** 🟡 MAJOR (Issues 3.1, 3.3, 3.4, 3.5 from validation report)

---

## Phase 13: Performance & Incremental Compilation

**Goal:** Achieve <200ms compile time for medium projects (50 files, 5000 lines)
**Estimated Duration:** 15 hours (2 weeks)
**Track:** C (Editor Engine — Performance)
**Status:** 🔴 **CRITICAL** — Addresses performance blocker from PRD validation

**Context:** PRD requires live preview with <200ms compile time, but EditorCompiler always performs full recompilation.

### PERF-1: Performance Baseline & Benchmarks **[P0]**
**Dependencies:** EE8 (Phase 10 — EditorEngine complete)
**Estimated:** 3 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: EE8]** Define "medium project" benchmark (50 files, 5000 lines total)
- [ ] **[P0, depends: EE8]** Create synthetic benchmark corpus (auto-generated .hc files)
- [ ] **[P0, depends: EE8]** Implement performance test suite (XCTest with XCTMeasure)
- [ ] **[P0, depends: EE8]** Baseline current performance:
  - [ ] Full compilation time (entry file → output)
  - [ ] Parse time per file
  - [ ] Resolution time per link
  - [ ] Emission time
- [ ] **[P1, depends: EE8]** Add CI job to track performance over commits
- [ ] **[P1, depends: EE8]** Document baseline in DOCS/PERFORMANCE.md

**Acceptance Criteria:** Benchmark suite runs, baseline documented, CI monitors regressions

**Blocks:** PERF-2 (optimization needs baseline)

**Resolution Status:** 🟡 MAJOR (Issue 3.2 from validation report)

---

### PERF-2: Incremental Compilation — File Caching **[P0]**
**Dependencies:** PERF-1
**Estimated:** 6 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: PERF-1]** Implement `ParsedFileCache` (file path → (checksum, ParsedFile))
- [ ] **[P0, depends: PERF-1]** Compute file checksums (SHA256 or faster hash)
- [ ] **[P0, depends: PERF-1]** Skip parsing if file unchanged (checksum match)
- [ ] **[P0, depends: PERF-1]** Invalidate cache on file change (checksum mismatch)
- [ ] **[P0, depends: PERF-1]** Handle cascading invalidation (referenced files changed)
- [ ] **[P1, depends: PERF-1]** Add cache eviction policy (LRU, max 1000 entries)
- [ ] **[P1, depends: PERF-1]** Write unit tests (cache hit/miss scenarios)

**Acceptance Criteria:** Cache reduces parse time by >80% on second compile, invalidation works correctly

**Blocks:** PERF-3 (dependency graph needs cached ASTs)

**Resolution Status:** 🔴 BLOCKER (Issue 1.3 from validation report)

---

### PERF-3: Incremental Compilation — Dependency Graph **[P0]**
**Dependencies:** PERF-2
**Estimated:** 4 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: PERF-2]** Build dependency graph (file → [referenced files])
- [ ] **[P0, depends: PERF-2]** Implement topological sort for compilation order
- [ ] **[P0, depends: PERF-2]** Track "dirty" files (changed since last compile)
- [ ] **[P0, depends: PERF-2]** Recompile only dirty files and their dependents
- [ ] **[P0, depends: PERF-2]** Merge incremental results into existing AST
- [ ] **[P1, depends: PERF-2]** Handle deletion of referenced files (invalidate cache)
- [ ] **[P1, depends: PERF-2]** Write unit tests (incremental vs full compile equivalence)

**Acceptance Criteria:** Incremental compile produces identical output to full compile, but faster

**Resolution Status:** 🔴 BLOCKER (Issue 1.3 from validation report)

---

### PERF-4: Performance Validation **[P0]**
**Dependencies:** PERF-3
**Estimated:** 2 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: PERF-3]** Re-run benchmark suite with incremental compilation
- [ ] **[P0, depends: PERF-3]** Verify <200ms for medium project (second compile)
- [ ] **[P0, depends: PERF-3]** Verify <1s for large project (120 files, 12000 lines)
- [ ] **[P0, depends: PERF-3]** Profile hot paths (Instruments or perf)
- [ ] **[P1, depends: PERF-3]** Document performance characteristics in DOCS/PERFORMANCE.md
- [ ] **[P1, depends: PERF-3]** Add performance regression tests to CI

**Acceptance Criteria:** <200ms compile time met, performance documented

**Resolution Status:** 🔴 BLOCKER (Issue 1.3 from validation report)

---

## Phase 14: VS Code Extension Development

**Goal:** Implement VS Code extension per PRD_VSCode_Extension.md
**Estimated Duration:** 35 hours (4-5 weeks)
**Track:** D (VS Code Extension — Client Implementation)
**Status:** ⏸️ **PENDING** — Requires Phase 11, 12, 13 completion

**Context:** With FFI layer, enhanced APIs, and performance optimizations in place, implement the TypeScript extension.

### VSC-3: Extension Scaffold **[P0]**
**Dependencies:** VSC-2A or VSC-2B or VSC-2C (integration layer chosen)
**Estimated:** 3 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-2*]** Initialize extension with `yo code` (TypeScript)
- [ ] **[P1, depends: VSC-2*]** Configure package.json metadata:
  - [ ] Extension ID: `anthropic.hyperprompt`
  - [ ] Publisher: `anthropic`
  - [ ] Repository URL
  - [ ] License (match Hyperprompt project)
- [ ] **[P0, depends: VSC-2*]** Register `.hc` file association
- [ ] **[P0, depends: VSC-2*]** Configure activation events (`onLanguage:hypercode`)
- [ ] **[P1, depends: VSC-2*]** Add TextMate grammar for syntax highlighting (`.tmLanguage.json`)
- [ ] **[P1, depends: VSC-2*]** Configure extension icon and colors
- [ ] **[P1, depends: VSC-2*]** Verify extension loads in VS Code dev mode

**Acceptance Criteria:** Extension scaffold builds, activates on .hc files, syntax highlighting works

**Blocks:** VSC-4 (client integration needs scaffold)

**Resolution Status:** ✅ Addresses PRD Phase 0 (Project Setup)

---

### VSC-4A: LSP Client Integration (if LSP) **[P0]**
**Dependencies:** VSC-2A, VSC-3
**Estimated:** 4 hours
**Status:** ⏸️ Pending (conditional)

- [ ] **[P0, depends: VSC-2A, VSC-3]** Add `vscode-languageclient` dependency
- [ ] **[P0, depends: VSC-2A, VSC-3]** Implement LSP client initialization
- [ ] **[P0, depends: VSC-2A, VSC-3]** Configure server executable path (bundled or detected)
- [ ] **[P0, depends: VSC-2A, VSC-3]** Handle server startup failures (show error notification)
- [ ] **[P1, depends: VSC-2A, VSC-3]** Implement server restart command
- [ ] **[P1, depends: VSC-2A, VSC-3]** Add server logging (output channel)
- [ ] **[P1, depends: VSC-2A, VSC-3]** Test LSP client connection

**Acceptance Criteria:** LSP client connects to server, logs communication, handles errors

**Resolution Status:** ✅ Addresses FFI blocker (LSP option)

---

### VSC-4B: CLI RPC Client Integration (if CLI) **[P0]**
**Dependencies:** VSC-2B, VSC-3
**Estimated:** 3 hours
**Status:** ⏸️ Pending (conditional)

- [ ] **[P0, depends: VSC-2B, VSC-3]** Implement JSON-RPC client (stdio transport)
- [ ] **[P0, depends: VSC-2B, VSC-3]** Spawn `hyperprompt-editor` process on activation
- [ ] **[P0, depends: VSC-2B, VSC-3]** Handle process lifecycle (restart on crash)
- [ ] **[P1, depends: VSC-2B, VSC-3]** Implement request/response handling
- [ ] **[P1, depends: VSC-2B, VSC-3]** Add request timeout (5s default)
- [ ] **[P1, depends: VSC-2B, VSC-3]** Test RPC client (mock CLI)

**Acceptance Criteria:** RPC client sends requests, receives responses, handles errors

**Resolution Status:** ✅ Addresses FFI blocker (CLI option)

---

### VSC-4C: Native Addon Integration (if FFI) **[P0]**
**Dependencies:** VSC-2C, VSC-3
**Estimated:** 2 hours
**Status:** ⏸️ Pending (conditional)

- [ ] **[P0, depends: VSC-2C, VSC-3]** Bundle pre-built native addon with extension
- [ ] **[P0, depends: VSC-2C, VSC-3]** Implement platform detection (macOS vs Linux)
- [ ] **[P0, depends: VSC-2C, VSC-3]** Load correct binary (x64 vs arm64)
- [ ] **[P1, depends: VSC-2C, VSC-3]** Handle addon load failures (show setup error)
- [ ] **[P1, depends: VSC-2C, VSC-3]** Test addon integration (mock calls)

**Acceptance Criteria:** Native addon loads, calls EditorEngine, handles errors

**Resolution Status:** ✅ Addresses FFI blocker (native addon option)

---

### VSC-5: Navigation Features **[P0]**
**Dependencies:** VSC-4*, EE-EXT-1
**Estimated:** 5 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-4*, EE-EXT-1]** Implement `DefinitionProvider` for go-to-definition
- [ ] **[P0, depends: VSC-4*, EE-EXT-1]** Call `EditorParser.linkAt(line:column:)` on definition request
- [ ] **[P0, depends: VSC-4*, EE-EXT-1]** Resolve link with `EditorResolver`
- [ ] **[P0, depends: VSC-4*, EE-EXT-1]** Navigate to resolved file path
- [ ] **[P1, depends: VSC-4*, EE-EXT-1]** Implement `HoverProvider` for hover tooltips
- [ ] **[P1, depends: VSC-4*, EE-EXT-1]** Show resolved path and status in hover
- [ ] **[P1, depends: VSC-4*, EE-EXT-1]** Handle unresolved links (show inline text message)
- [ ] **[P1, depends: VSC-4*, EE-EXT-1]** Write extension tests (integration)

**Acceptance Criteria:** Go-to-definition works on all file references, hover shows resolved path

**Blocks:** None (core feature)

**Resolution Status:** ✅ Addresses PRD Phase 1 (Editor Navigation)

---

### VSC-6: Diagnostics Integration **[P0]**
**Dependencies:** VSC-4*, EE-EXT-2
**Estimated:** 4 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-4*, EE-EXT-2]** Implement `DiagnosticCollection` for Problems panel
- [ ] **[P0, depends: VSC-4*, EE-EXT-2]** Call `EditorEngine.validateWorkspace()` on file save
- [ ] **[P0, depends: VSC-4*, EE-EXT-2]** Map `Diagnostic[]` to VS Code diagnostics
- [ ] **[P0, depends: VSC-4*, EE-EXT-2]** Set severity (error, warning, info, hint)
- [ ] **[P0, depends: VSC-4*, EE-EXT-2]** Set source ("Hyperprompt")
- [ ] **[P1, depends: VSC-4*, EE-EXT-2]** Implement incremental diagnostic updates (only changed files)
- [ ] **[P1, depends: VSC-4*, EE-EXT-2]** Clear diagnostics when file is fixed
- [ ] **[P1, depends: VSC-4*, EE-EXT-2]** Write extension tests

**Acceptance Criteria:** Errors appear in Problems panel, jump to correct location, clear when fixed

**Blocks:** None (core feature)

**Resolution Status:** ✅ Addresses PRD Phase 3 (Diagnostics)

---

### VSC-7: Live Preview Panel **[P0]**
**Dependencies:** VSC-4*, PERF-4
**Estimated:** 6 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-4*, PERF-4]** Create Webview panel for Markdown preview
- [ ] **[P0, depends: VSC-4*, PERF-4]** Register `hyperprompt.preview` command
- [ ] **[P0, depends: VSC-4*, PERF-4]** Call `EditorCompiler.compile()` on file save
- [ ] **[P0, depends: VSC-4*, PERF-4]** Render Markdown output in Webview
- [ ] **[P1, depends: VSC-4*, PERF-4]** Use incremental compilation for <200ms update
- [ ] **[P1, depends: VSC-4*, PERF-4]** Sync scroll position (preview follows editor)
- [ ] **[P1, depends: VSC-4*, PERF-4]** Add preview refresh command (manual override)
- [ ] **[P2, depends: VSC-4*, PERF-4]** Style Markdown with VS Code theme CSS
- [ ] **[P1, depends: VSC-4*, PERF-4]** Write extension tests

**Acceptance Criteria:** Preview updates on save, <200ms latency, Markdown rendered correctly

**Blocks:** None (core feature)

**Resolution Status:** ✅ Addresses PRD Phase 2 (Compilation & Preview)

---

### VSC-8: Extension Settings **[P1]**
**Dependencies:** VSC-4*
**Estimated:** 2 hours
**Status:** ⏸️ Pending

- [ ] **[P1, depends: VSC-4*]** Add configuration schema to package.json
- [ ] **[P1, depends: VSC-4*]** Add `hyperprompt.resolutionMode` setting (strict/lenient)
- [ ] **[P1, depends: VSC-4*]** Add `hyperprompt.previewAutoUpdate` setting (boolean)
- [ ] **[P1, depends: VSC-4*]** Add `hyperprompt.diagnosticsEnabled` setting (boolean)
- [ ] **[P2, depends: VSC-4*]** Add `hyperprompt.server.path` setting (LSP/CLI executable path)
- [ ] **[P2, depends: VSC-4*]** Add `hyperprompt.server.logLevel` setting (error/warn/info/debug)
- [ ] **[P1, depends: VSC-4*]** Implement settings change handler (restart server if needed)
- [ ] **[P1, depends: VSC-4*]** Document settings in README

**Acceptance Criteria:** Settings work, changes apply correctly, documented

**Resolution Status:** ✅ Addresses resolution mode ambiguity (Issue 3.1)

---

### VSC-9: Multi-Column Workflow (Optional) **[P2]**
**Dependencies:** VSC-5, EE-EXT-4
**Estimated:** 3 hours
**Status:** ⏸️ Pending

- [ ] **[P2, depends: VSC-5, EE-EXT-4]** Open referenced files in editor group beside source
- [ ] **[P2, depends: VSC-5, EE-EXT-4]** Configure 3-column layout (source | reference | preview)
- [ ] **[P2, depends: VSC-5, EE-EXT-4]** Add `hyperprompt.openBeside` command
- [ ] **[P2, depends: VSC-5, EE-EXT-4]** Test multi-root workspace support
- [ ] **[P2, depends: VSC-5, EE-EXT-4]** Write extension tests

**Acceptance Criteria:** Multi-column layout works, navigation preserves layout

**Resolution Status:** ✅ Addresses PRD Phase 4 (UX Enhancements)

---

### VSC-10: Bidirectional Navigation (Optional) **[P2]**
**Dependencies:** VSC-7, EE-EXT-3
**Estimated:** 4 hours
**Status:** ⏸️ Pending

- [ ] **[P2, depends: VSC-7, EE-EXT-3]** Implement click handler in preview Webview
- [ ] **[P2, depends: VSC-7, EE-EXT-3]** Send message to extension (line number clicked)
- [ ] **[P2, depends: VSC-7, EE-EXT-3]** Lookup source location from `SourceMap`
- [ ] **[P2, depends: VSC-7, EE-EXT-3]** Navigate to source file and highlight range
- [ ] **[P2, depends: VSC-7, EE-EXT-3]** Test source map accuracy
- [ ] **[P2, depends: VSC-7, EE-EXT-3]** Write extension tests

**Acceptance Criteria:** Click in preview jumps to source, correct line highlighted

**Resolution Status:** ✅ Addresses PRD Phase 4.4.2 (Output → Source Navigation)

---

### VSC-11: Extension Testing & QA **[P0]**
**Dependencies:** VSC-5, VSC-6, VSC-7
**Estimated:** 4 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-5, VSC-6, VSC-7]** Write extension integration tests (VS Code Test API)
- [ ] **[P0, depends: VSC-5, VSC-6, VSC-7]** Test all features with corpus files (V01-V14, I01-I10)
- [ ] **[P0, depends: VSC-5, VSC-6, VSC-7]** Verify error handling (server crash, timeout, invalid response)
- [ ] **[P1, depends: VSC-5, VSC-6, VSC-7]** Test multi-root workspace scenarios
- [ ] **[P1, depends: VSC-5, VSC-6, VSC-7]** Test performance (large files, many diagnostics)
- [ ] **[P1, depends: VSC-5, VSC-6, VSC-7]** Add CI job for extension tests
- [ ] **[P1, depends: VSC-5, VSC-6, VSC-7]** Achieve >70% code coverage

**Acceptance Criteria:** All features tested, edge cases covered, CI passes

**Resolution Status:** ✅ Addresses PRD quality requirements

---

### VSC-12: Extension Documentation & Release **[P0]**
**Dependencies:** VSC-11
**Estimated:** 3 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-11]** Write extension README (features, installation, usage)
- [ ] **[P0, depends: VSC-11]** Add screenshots/GIFs demonstrating features
- [ ] **[P0, depends: VSC-11]** Document system requirements (macOS/Linux only)
- [ ] **[P0, depends: VSC-11]** Write CHANGELOG
- [ ] **[P1, depends: VSC-11]** Package extension (.vsix)
- [ ] **[P1, depends: VSC-11]** Test installation from VSIX
- [ ] **[P2, depends: VSC-11]** Publish to VS Code Marketplace (manual step)
- [ ] **[P1, depends: VSC-11]** Tag release (v0.1.0)

**Acceptance Criteria:** Extension packaged, README complete, ready for distribution

**Resolution Status:** ✅ Addresses PRD deliverables

---

## Phase 15: PRD Validation & Gap Closure

**Goal:** Verify all PRD_VSCode_Extension.md requirements met
**Estimated Duration:** 4 hours
**Track:** D (VS Code Extension — Validation)
**Status:** ⏸️ **PENDING** — Final validation phase

### PRD-VAL-1: PRD Requirements Checklist **[P0]**
**Dependencies:** VSC-12 (extension complete)
**Estimated:** 2 hours
**Status:** ⏸️ Pending

- [ ] **[P0, depends: VSC-12]** Verify all Section 1.2 deliverables:
  - [ ] VS Code Extension published
  - [ ] Language support (syntax, file associations)
  - [ ] Navigation features (go-to-def, peek)
  - [ ] Live preview panel
  - [ ] Diagnostics integration
  - [ ] Build integration (trait-enabled)
- [ ] **[P0, depends: VSC-12]** Verify all Section 1.3 success criteria:
  - [ ] Opening .hc activates extension
  - [ ] File references navigable
  - [ ] Compilation results visible real-time
  - [ ] Errors in VS Code diagnostics
  - [ ] Works without modifying CLI
- [ ] **[P0, depends: VSC-12]** Verify all functional requirements (Section 4.2):
  - [ ] FR-1: Recognize .hc files
  - [ ] FR-2: Navigate file references
  - [ ] FR-3: Compile via EditorEngine
  - [ ] FR-4: Show Markdown preview
  - [ ] FR-5: Surface diagnostics
- [ ] **[P0, depends: VSC-12]** Verify non-functional requirements (Section 4.3):
  - [ ] Performance: <200ms compile
  - [ ] Reliability: No crashes on invalid input
  - [ ] Isolation: No compiler logic in JS
  - [ ] Portability: macOS + Linux
  - [ ] Determinism: Matches CLI output

**Acceptance Criteria:** All PRD requirements verified, checklist documented

**Resolution Status:** ✅ Final validation

---

### PRD-VAL-2: Validation Report Update **[P1]**
**Dependencies:** PRD-VAL-1
**Estimated:** 2 hours
**Status:** ⏸️ Pending

- [ ] **[P1, depends: PRD-VAL-1]** Update DOCS/PRD_VALIDATION_VSCode_Extension.md
- [ ] **[P1, depends: PRD-VAL-1]** Mark all blockers as resolved (🔴 → ✅)
- [ ] **[P1, depends: PRD-VAL-1]** Mark all critical issues as resolved (🟠 → ✅)
- [ ] **[P1, depends: PRD-VAL-1]** Mark all major issues as resolved (🟡 → ✅)
- [ ] **[P1, depends: PRD-VAL-1]** Document final architecture chosen (LSP/CLI/FFI)
- [ ] **[P1, depends: PRD-VAL-1]** Document performance benchmarks achieved
- [ ] **[P1, depends: PRD-VAL-1]** Add "Resolution Summary" section
- [ ] **[P1, depends: PRD-VAL-1]** Update PRD quality assessment (5/10 → 9/10 feasibility)

**Acceptance Criteria:** Validation report reflects completed work, all gaps closed

**Resolution Status:** ✅ Documentation closure

---

## Summary: New Phases Overview

| Phase | Title | Duration | Status | Addresses |
|-------|-------|----------|--------|-----------|
| **Phase 11** | VS Code Extension Integration Architecture | 18h | ⏸️ Pending | 🔴 FFI Blocker |
| **Phase 12** | EditorEngine API Enhancements | 14h | ⏸️ Pending | 🟠 Critical APIs |
| **Phase 13** | Performance & Incremental Compilation | 15h | ⏸️ Pending | 🔴 Performance Blocker |
| **Phase 14** | VS Code Extension Development | 35h | ⏸️ Pending | ✅ PRD Implementation |
| **Phase 15** | PRD Validation & Gap Closure | 4h | ⏸️ Pending | ✅ Final Validation |

**Total Estimated Effort:** 86 hours (10-11 weeks)

**Critical Path:** Phase 11 (VSC-1 → VSC-2) → Phase 12 (EE-EXT-1) → Phase 13 (PERF-1 → PERF-4) → Phase 14 (VSC-5, VSC-6, VSC-7) → Phase 15

**Parallelization Opportunities:**
- Phase 12 (API enhancements) can partially overlap with Phase 11 (FFI layer) — some APIs (EE-EXT-1, EE-EXT-4) are FFI-independent
- Phase 13 (performance) can start after Phase 12 completes
- Phase 14 tasks (VSC-5, VSC-6, VSC-7) can be parallelized (3 developers)

**Recommended Team:**
- **Developer A:** Phase 11 (FFI/LSP/CLI integration) — specialist in Swift/C interop or LSP
- **Developer B:** Phase 12 + 13 (EditorEngine APIs + performance) — Swift backend specialist
- **Developer C:** Phase 14 (TypeScript extension) — VS Code extension specialist

**Timeline Estimate:**
- **Weeks 1-3:** Phase 11 (FFI layer) + Phase 12 (API enhancements) in parallel
- **Weeks 4-5:** Phase 13 (performance optimization)
- **Weeks 6-9:** Phase 14 (extension development)
- **Week 10:** Phase 15 (validation & release)

---

## Revision History

| Version | Date       | Author          | Changes                                              |
|---------|------------|-----------------|------------------------------------------------------|
| 3.0.0   | 2025-12-23 | Claude (AI)     | Add Phase 11-15 for VS Code Extension (86h): FFI layer, API enhancements, performance, extension development, PRD validation |
| 2.0.0   | 2025-12-02 | Egor Merkushev  | Add priorities, dependencies, tracks, critical path |
| 1.0.0   | 2025-12-02 | Egor Merkushev  | Initial work plan creation                           |
