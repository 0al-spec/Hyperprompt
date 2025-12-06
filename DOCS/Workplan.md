# Hyperprompt Compiler v0.1 — Work Plan

**Document Version:** 2.0.0
**Date:** December 2, 2025
**Status:** Active Development
**Based on:** PRD v0.0.1, Design Spec v0.0.1, SpecificationCore Integration Spec v0.0.1

---

## Overview

This work plan combines tasks from:
- **Core Compiler Implementation** (PRD §7: Implementation Plan)
- **SpecificationCore Integration** (Design Spec §10: Implementation Checklist)
- **Testing & Documentation** requirements

**Total Estimated Effort:** ~60 hours (~8 days)

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

- [ ] **[P1, depends: A1]** Create `HypercodeGrammar` module with SpecificationCore dependency
- [ ] **[P1, depends: A2]** Define `RawLine` struct (text, lineNumber, filePath)
- [ ] **[P1, depends: A2]** Define `LineKind` enum (blank, comment, node)
- [ ] **[P1, depends: A2]** Define `ParsedLine` struct (kind, indentSpaces, depth, literal, location)
- [ ] **[P1, depends: A2]** Define `PathKind` enum (allowed, forbidden, invalid)
- [ ] **[P1, depends: A2]** Write unit tests for domain type conversions

**Acceptance Criteria:** Domain types properly model lexer/resolver input/output, tests verify correct behavior

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
**Dependencies:** A3
**Estimated:** 6 hours

- [ ] **[P1, depends: A3]** Implement `IsBlankLineSpec` (line contains only spaces)
- [ ] **[P1, depends: A3]** Implement `IsCommentLineSpec` (starts with # after indent)
- [ ] **[P1, depends: A3]** Implement `IsNodeLineSpec` (quoted literal on single line)
- [ ] **[P1, depends: A3]** Implement `StartsWithDoubleQuoteSpec`
- [ ] **[P1, depends: A3]** Implement `EndsWithDoubleQuoteSpec`
- [ ] **[P1, depends: A3]** Implement `ContentWithinQuotesIsSingleLineSpec`
- [ ] **[P1, depends: A3]** Implement `ValidQuotesSpec` (composite: starts AND ends AND single-line)
- [ ] **[P1, depends: A3]** Implement `ContainsLFSpec` (detects \n)
- [ ] **[P1, depends: A3]** Implement `ContainsCRSpec` (detects \r)
- [ ] **[P1, depends: A3]** Implement `SingleLineContentSpec` (composite: NOT (LF OR CR))
- [ ] **[P1, depends: A3]** Write unit tests for each specification (15+ test cases each)

**Acceptance Criteria:** All lexical specs pass unit tests, composition operators work correctly

**Blocks:** Integration-1 (lexer integration needs specs)

---

### Spec-2: Indentation & Depth Specifications **[P1]**
**Dependencies:** A3, Spec-1
**Estimated:** 4 hours

- [ ] **[P1, depends: A3]** Implement `NoTabsIndentSpec` (no tabs in indentation)
- [ ] **[P1, depends: A3]** Implement `IndentMultipleOf4Spec` (indent % 4 == 0)
- [ ] **[P1, depends: A3]** Implement `DepthWithinLimitSpec` (depth <= 10, configurable)
- [ ] **[P1, depends: Spec-1]** Write unit tests for edge cases (depth 0, depth 10, depth 11)
- [ ] **[P1, depends: Spec-1]** Test composition with ValidNodeLineSpec

**Acceptance Criteria:** Indentation validation catches all forbidden patterns, depth limits enforced correctly

**Blocks:** Integration-1 (lexer integration needs specs)

---

### Spec-3: Path Validation Specifications **[P1]**
**Dependencies:** A3
**Estimated:** 4 hours

- [ ] **[P1, depends: A3]** Implement `HasMarkdownExtensionSpec` (.md suffix)
- [ ] **[P1, depends: A3]** Implement `HasHypercodeExtensionSpec` (.hc suffix)
- [ ] **[P1, depends: A3]** Implement `IsAllowedExtensionSpec` (composite: .md OR .hc)
- [ ] **[P1, depends: A3]** Implement `ContainsPathSeparatorSpec` (contains /)
- [ ] **[P1, depends: A3]** Implement `ContainsExtensionDotSpec` (contains .)
- [ ] **[P1, depends: A3]** Implement `LooksLikeFileReferenceSpec` (heuristic: separator OR dot)
- [ ] **[P1, depends: A3]** Implement `NoTraversalSpec` (no .. components)
- [ ] **[P1, depends: A3]** Implement `WithinRootSpec` (path starts with root)
- [ ] **[P1, depends: A3]** Write unit tests for all path validation cases

**Acceptance Criteria:** Path specs correctly identify allowed/forbidden extensions, security violations detected

**Blocks:** Integration-2 (resolver integration needs specs)

---

### Spec-4: Composite & Decision Specifications **[P1]**
**Dependencies:** Spec-1, Spec-2, Spec-3
**Estimated:** 3 hours

- [ ] **[P1, depends: Spec-1, Spec-2]** Implement `ValidNodeLineSpec` (composite: NoTabs AND Indent AND Depth AND Quotes AND IsNode)
- [ ] **[P1, depends: Spec-3]** Implement `ValidReferencePathSpec` (composite: NoTraversal AND AllowedExtension)
- [ ] **[P1, depends: Spec-1]** Implement `IsSkippableLineSpec` (semantic: IsBlank OR IsComment)
- [ ] **[P1, depends: Spec-1]** Implement `IsSemanticLineSpec` (semantic: NOT IsSkippable)
- [ ] **[P1, depends: Spec-1]** Implement `LineKindDecision` using `FirstMatchSpec` (blank → comment → node priority)
- [ ] **[P1, depends: Spec-3]** Implement `PathTypeDecision` using `FirstMatchSpec`
- [ ] **[P1, depends: Spec-1, Spec-2, Spec-3]** Write composition tests (AND, OR, NOT truth tables)
- [ ] **[P1, depends: Spec-1, Spec-2, Spec-3]** Write decision spec tests (priority ordering, nil handling)
- [ ] **[P1, depends: Spec-1]** Test De Morgan's Law equivalences

**Acceptance Criteria:** Composite specs correctly combine atomic rules, decision specs return correct classifications

**Blocks:** Phase 7 (integration needs all specs)

---

## Phase 4: Reference Resolution

**Goal:** Implement file reference resolution with circular dependency detection
**Estimated Duration:** 12 hours
**Track:** A (Core Compiler)

### B1: Reference Resolver **[P0]**
**Dependencies:** A4 (needs AST)
**Estimated:** 6 hours
**Status:** ✅ Completed on 2025-12-06

- [x] **[P0, depends: A4]** Implement file existence checking against root directory
- [x] **[P0, depends: A4]** Classify literals as file references or inline text
- [x] **[P0, depends: A4]** Handle `.md` extension (load content, no recursion)
- [x] **[P0, depends: A4]** Handle `.hc` extension (recursive compilation)
- [x] **[P0, depends: A4]** Reject all other extensions (hard error, exit 3)
- [x] **[P0, depends: A4]** Implement strict mode (missing file → error)
- [x] **[P1, depends: A4]** Implement lenient mode (missing file → inline text)
- [ ] **[P1, depends: Spec-3]** Integrate `ValidReferencePathSpec` for pre-validation
- [ ] **[P1, depends: Spec-3]** Integrate `PathTypeDecision` for classification
- [x] **[P1, depends: A4]** Write resolver tests for all reference types

**Acceptance Criteria:** ✅ Resolver correctly classifies all reference types, strict/lenient modes work as specified

**Blocks:** B4 (recursive compilation needs resolver)

---

### B2: Dependency Tracker **[P1]**
**Dependencies:** A4
**Estimated:** 4 hours
**Status:** ✅ Completed on 2025-12-06

- [x] **[P1, depends: A4]** Implement visitation stack for cycle detection
- [x] **[P1, depends: A4]** Detect direct circular dependencies (A → A)
- [x] **[P1, depends: A4]** Detect transitive circular dependencies (A → B → A)
- [x] **[P1, depends: A4]** Produce clear cycle path descriptions in error messages
- [x] **[P2, depends: A4]** Optimize for deep trees with memoization
- [x] **[P1, depends: A4]** Write tests for various cycle patterns

**Acceptance Criteria:** All circular dependencies detected, error messages show full cycle path

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

- [ ] **[P1, depends: A2]** Parse ATX-style headings (# prefix)
- [ ] **[P1, depends: A2]** Parse Setext-style headings (underlines with = or -)
- [ ] **[P1, depends: A2]** Compute adjusted heading level (original + offset)
- [ ] **[P1, depends: A2]** Handle overflow beyond H6 (convert to **bold**)
- [ ] **[P2, depends: A2]** Preserve heading attributes and trailing content
- [ ] **[P1, depends: A2]** Normalize line endings in embedded content to LF
- [ ] **[P1, depends: A2]** Write tests for all heading styles and edge cases

**Acceptance Criteria:** All heading styles correctly adjusted, overflow handled, test corpus passes

**Blocks:** C2 (emitter uses heading adjuster)

---

### C2: Markdown Emitter **[P0]**
**Dependencies:** B4, C1
**Estimated:** 8 hours

- [ ] **[P0, depends: B4]** Implement tree traversal for output generation
- [ ] **[P0, depends: B4]** Generate headings from node content or file names
- [ ] **[P0, depends: B4]** Use effective depth for nested embeddings (parent + node depth)
- [ ] **[P0, depends: B4, C1]** Embed file content with adjusted headings
- [ ] **[P1, depends: B4]** Insert blank lines between sibling sections
- [ ] **[P0, depends: B4]** Handle inline text literals as body content
- [ ] **[P0, depends: B4]** Ensure final output ends with exactly one LF
- [ ] **[P1, depends: B4]** Write emitter tests matching expected output

**Acceptance Criteria:** Emitter produces valid Markdown matching expected output for all test cases

**Blocks:** D2 (driver needs emitter to produce output)

---

### C3: Manifest Generator **[P1]**
**Dependencies:** B3
**Estimated:** 3 hours

- [ ] **[P1, depends: B3]** Implement `Manifest` struct (timestamp, version, root, sources)
- [ ] **[P1, depends: B3]** Generate ISO 8601 timestamp
- [ ] **[P1, depends: B3]** Sort manifest JSON keys alphabetically for determinism
- [ ] **[P1, depends: B3]** Format JSON with consistent structure
- [ ] **[P1, depends: B3]** Write manifest to specified path
- [ ] **[P1, depends: B3]** Ensure manifest ends with exactly one LF
- [ ] **[P1, depends: B3]** Write tests for manifest accuracy

**Acceptance Criteria:** Manifest contains accurate metadata for all source files, JSON format is deterministic

**Blocks:** D2 (driver needs manifest generation)

---

## Phase 6: CLI & Integration

**Goal:** Command-line interface and end-to-end compilation
**Estimated Duration:** 13 hours
**Track:** A (Core Compiler)

### D1: Argument Parsing **[P1]**
**Dependencies:** A1
**Estimated:** 4 hours

- [ ] **[P1, depends: A1]** Define command structure with swift-argument-parser
- [ ] **[P1, depends: A1]** Implement `@Argument` for input file
- [ ] **[P1, depends: A1]** Implement `--output, -o` option
- [ ] **[P1, depends: A1]** Implement `--manifest, -m` option
- [ ] **[P1, depends: A1]** Implement `--root, -r` option
- [ ] **[P1, depends: A1]** Implement `--strict` flag (default)
- [ ] **[P1, depends: A1]** Implement `--lenient` flag
- [ ] **[P1, depends: A1]** Implement `--stats` flag
- [ ] **[P1, depends: A1]** Implement `--dry-run` flag
- [ ] **[P1, depends: A1]** Implement `--verbose, -v` flag
- [ ] **[P1, depends: A1]** Implement `--version` flag
- [ ] **[P1, depends: A1]** Implement `--help, -h` flag
- [ ] **[P1, depends: A1]** Validate argument combinations (strict XOR lenient)
- [ ] **[P1, depends: A1]** Generate help text
- [ ] **[P1, depends: A1]** Write argument parsing tests

**Acceptance Criteria:** All documented arguments recognized and validated, help text accurate

**Blocks:** D2 (driver needs argument parsing)

---

### D2: Compiler Driver **[P0]**
**Dependencies:** C2, C3, D1
**Estimated:** 6 hours

- [ ] **[P0, depends: C2, D1]** Implement `CompilerDriver` orchestrating parse → resolve → emit → manifest pipeline
- [ ] **[P1, depends: D1]** Implement dry-run mode (validate without writing)
- [ ] **[P1, depends: D1]** Implement verbose logging
- [ ] **[P2, depends: D1]** Handle interruption signals (SIGINT, SIGTERM) gracefully
- [ ] **[P1, depends: D1]** Set default values for output/manifest/root paths
- [ ] **[P1, depends: C2, C3]** Write end-to-end compilation tests
- [ ] **[P1, depends: C2, C3]** Test with all test corpus files (V01-V14, I01-I10)

**Acceptance Criteria:** End-to-end compilation succeeds for all valid inputs, fails correctly for invalid inputs

**Blocks:** E1 (integration tests need working driver)

---

### D3: Diagnostic Printer **[P1]**
**Dependencies:** A2
**Estimated:** 4 hours

- [ ] **[P1, depends: A2]** Format error messages with source context
- [ ] **[P1, depends: A2]** Implement format: `<file>:<line>: error: <message>`
- [ ] **[P1, depends: A2]** Show context line with caret (^^^) pointing to issue
- [ ] **[P2, depends: A2]** Colorize output for terminal display (optional)
- [ ] **[P1, depends: A2]** Support plain text output for non-terminal destinations
- [ ] **[P2, depends: A2]** Aggregate multiple errors when possible
- [ ] **[P1, depends: A2]** Write diagnostic formatting tests

**Acceptance Criteria:** Error messages clearly identify problem location and nature, format matches specification

---

### D4: Statistics Reporter **[P2]**
**Dependencies:** D1
**Estimated:** 3 hours

- [ ] **[P2, depends: D1]** Implement `StatsCollector` tracking compilation metrics
- [ ] **[P2, depends: D1]** Count Hypercode files processed
- [ ] **[P2, depends: D1]** Count Markdown files embedded
- [ ] **[P2, depends: D1]** Sum total input bytes
- [ ] **[P2, depends: D1]** Record output bytes
- [ ] **[P2, depends: D1]** Track maximum depth encountered
- [ ] **[P2, depends: D1]** Measure elapsed time (ms)
- [ ] **[P2, depends: D1]** Implement `StatsReporter` formatting output
- [ ] **[P2, depends: D1]** Integrate with `--stats` flag and verbose mode
- [ ] **[P2, depends: D1]** Write statistics tests

**Acceptance Criteria:** Statistics output includes all specified metrics, integrates with CLI flags

---

## Phase 7: Lexer & Resolver Integration with Specs

**Goal:** Replace imperative validation with declarative specifications
**Estimated Duration:** 11 hours
**Track:** Integration (requires both A and B tracks complete)

### Integration-1: Lexer with Specifications **[P1]**
**Dependencies:** Phase 2 (Lexer), Phase 3 (Specs)
**Estimated:** 5 hours

- [ ] **[P1, depends: Lexer, Spec-4]** Refactor Lexer to use `LineKindDecision` for classification
- [ ] **[P1, depends: Lexer, Spec-2]** Replace imperative tab checking with `NoTabsIndentSpec`
- [ ] **[P1, depends: Lexer, Spec-2]** Replace imperative indent validation with `IndentMultipleOf4Spec`
- [ ] **[P1, depends: Lexer, Spec-2]** Replace imperative depth checking with `DepthWithinLimitSpec`
- [ ] **[P1, depends: Lexer, Spec-4]** Use `ValidNodeLineSpec` for comprehensive node validation
- [ ] **[P1, depends: Lexer, Spec-4]** Update error messages to reference specification failures
- [ ] **[P1, depends: Lexer, Spec-4]** Verify all existing lexer tests pass
- [ ] **[P1, depends: Lexer, Spec-4]** Add integration tests for specification-based lexer
- [ ] **[P2, depends: Lexer, Spec-4]** Benchmark performance vs imperative version

**Acceptance Criteria:** Lexer uses specifications for all validation, tests pass, <10% performance overhead

---

### Integration-2: Resolver with Specifications **[P1]**
**Dependencies:** Phase 4 (Resolver), Phase 3 (Specs)
**Estimated:** 6 hours

- [ ] **[P1, depends: B1, Spec-4]** Refactor ReferenceResolver to use `ValidReferencePathSpec`
- [ ] **[P1, depends: B1, Spec-3]** Replace imperative path validation with `NoTraversalSpec`
- [ ] **[P1, depends: B1, Spec-3]** Replace imperative extension checking with `IsAllowedExtensionSpec`
- [ ] **[P1, depends: B1, Spec-4]** Use `PathTypeDecision` for path classification
- [ ] **[P1, depends: B1, Spec-3]** Integrate `LooksLikeFileReferenceSpec` for heuristic detection
- [ ] **[P1, depends: B1, Spec-4]** Update error messages for specification failures
- [ ] **[P1, depends: B1, Spec-4]** Verify all existing resolver tests pass
- [ ] **[P1, depends: B1, Spec-4]** Add integration tests for specification-based resolver
- [ ] **[P2, depends: B1, Spec-4]** Benchmark performance vs imperative version

**Acceptance Criteria:** Resolver uses specifications for all validation, tests pass, <10% performance overhead

---

## Phase 8: Testing & Quality Assurance

**Goal:** Comprehensive test coverage and cross-platform validation
**Estimated Duration:** 12 hours
**Track:** Integration (requires compiler complete)

### E1: Test Corpus Implementation **[P0]**
**Dependencies:** D2 (needs working compiler)
**Estimated:** 8 hours

- [ ] **[P1, depends: D2]** Create test corpus directory structure
- [ ] **[P0, depends: D2]** Implement Valid Input Tests (V01-V14):
  - [ ] **[P0]** V01: Single root node with inline text
  - [ ] **[P1]** V03: Nested hierarchy 3 levels deep
  - [ ] **[P0]** V04: Single Markdown file reference at root
  - [ ] **[P1]** V05: Nested Markdown file references
  - [ ] **[P0]** V06: Single Hypercode file reference
  - [ ] **[P1]** V07: Nested Hypercode files (3 levels)
  - [ ] **[P1]** V08: Mixed inline text and file references
  - [ ] **[P1]** V09: Markdown with headings H1-H4
  - [ ] **[P1]** V10: Markdown with Setext headings
  - [ ] **[P2]** V11: Comment lines interspersed
  - [ ] **[P2]** V12: Blank lines between node groups
  - [ ] **[P1]** V13: Maximum depth of 10 levels
  - [ ] **[P2]** V14: Unicode content in literals and files
- [ ] **[P0, depends: D2]** Implement Invalid Input Tests (I01-I10):
  - [ ] **[P0]** I01: Tab characters in indentation
  - [ ] **[P0]** I02: Misaligned indentation (not divisible by 4)
  - [ ] **[P0]** I03: Unclosed quotation mark
  - [ ] **[P1]** I04: Missing file reference (strict mode)
  - [ ] **[P1]** I05: Direct circular dependency (A → A)
  - [ ] **[P1]** I06: Indirect circular dependency (A → B → A)
  - [ ] **[P1]** I07: Depth exceeding 10
  - [ ] **[P0]** I08: Path traversal with ..
  - [ ] **[P2]** I09: Unreadable file (permission error)
  - [ ] **[P0]** I10: Multiple root nodes
- [ ] **[P1, depends: D2]** Create golden files for each test ({test-id}.expected.md, {test-id}.expected.json)
- [ ] **[P1, depends: D2]** Implement golden-file comparison tests
- [ ] **[P1, depends: D2]** Verify exit codes for all error scenarios
- [ ] **[P1, depends: D2]** Achieve >80% code coverage

**Acceptance Criteria:** All valid tests match golden files, all invalid tests fail predictably, >80% coverage

**Blocks:** E2 (cross-platform testing needs corpus)

---

### E2: Cross-Platform Testing **[P1]**
**Dependencies:** E1
**Estimated:** 4 hours

- [ ] **[P1, depends: E1]** Test on macOS Intel
- [ ] **[P1, depends: E1]** Test on macOS Apple Silicon (M1/M2)
- [ ] **[P1, depends: E1]** Test on Ubuntu 22.04 x86_64
- [ ] **[P2, depends: E1]** Test on Ubuntu 22.04 ARM64
- [ ] **[P2, depends: E1]** Test on Windows 10+ x86_64 (native)
- [ ] **[P2, depends: E1]** Test on Windows with WSL2
- [ ] **[P0, depends: E1]** Verify deterministic output (byte-for-byte identical across platforms)
- [ ] **[P2, depends: E1]** Document any platform-specific behaviors
- [ ] **[P0, depends: E1]** Verify LF line endings on all platforms

**Acceptance Criteria:** Identical inputs produce identical outputs on all platforms, no platform-specific bugs

---

### E3: Documentation **[P1]**
**Dependencies:** D2 (needs working compiler to document)
**Estimated:** 4 hours

- [ ] **[P1, depends: D2]** Write README with installation instructions
- [ ] **[P1, depends: D1, D2]** Document usage examples with all CLI flags
- [ ] **[P1, depends: D2]** Document Hypercode language specification (grammar)
- [ ] **[P1, depends: D2]** Provide example files demonstrating all features
- [ ] **[P2, depends: Phase 7]** Document SpecificationCore integration patterns
- [ ] **[P2, depends: D2]** Generate API documentation from source comments
- [ ] **[P2, depends: D2]** Write architecture overview with diagrams
- [ ] **[P1, depends: D2]** Document error codes and meanings (exit codes 0-4)
- [ ] **[P2, depends: D2]** Create troubleshooting guide
- [ ] **[P2, depends: D2]** Document future extensions (v0.2+)

**Acceptance Criteria:** Documentation is complete, accurate, and covers all features

---

## Phase 9: Optimization & Finalization

**Goal:** Performance tuning and release preparation
**Estimated Duration:** 4 hours
**Track:** Release

### Optimization Tasks **[P1]**
**Dependencies:** E1, E2
**Estimated:** 3 hours

- [ ] **[P2, depends: E1]** Profile compilation with Instruments (macOS) or Valgrind (Linux)
- [ ] **[P2, depends: E1]** Optimize hot paths identified in profiling
- [ ] **[P1, depends: E1]** Benchmark against performance targets:
  - [ ] **[P1]** 1000-node tree compilation < 5 seconds
  - [ ] **[P1]** Linear scaling with file count
- [ ] **[P0, depends: E2]** Verify deterministic output (repeated compilations identical)
- [ ] **[P2, depends: E1]** Test with large corpus (100+ files)
- [ ] **[P1, depends: E1]** Verify manifest JSON key alphabetical sorting
- [ ] **[P2, depends: E1]** Test memory usage with large files (>1MB)
- [ ] **[P2, depends: E1]** Fix any memory leaks detected

**Acceptance Criteria:** Performance targets met, no memory leaks, deterministic output verified

---

### Release Preparation **[P0]**
**Dependencies:** E1, E2, E3, Optimization
**Estimated:** 3 hours

- [ ] **[P0, depends: E1, E2]** Tag version 0.1.0
- [ ] **[P0, depends: E2]** Build release binaries for all platforms
- [ ] **[P1, depends: E2]** Create distribution packages (DMG, DEB, ZIP)
- [ ] **[P1, depends: E3]** Write release notes
- [ ] **[P1, depends: E3]** Update CHANGELOG
- [ ] **[P2, depends: E1]** Archive test results and coverage reports

**Acceptance Criteria:** Release packages built and tested, documentation finalized

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

**Overall Progress:** 0 / 153 tasks completed (0%)

### By Phase
- [ ] **Phase 1:** Foundation & Core Types (0/3 major tasks) — **6h** — Track A
- [ ] **Phase 2:** Lexer & Parser (0/2 major tasks) — **14h** — Track A
- [ ] **Phase 3:** Specifications (0/4 major tasks) — **17h** — Track B ⚡ **Parallel**
- [ ] **Phase 4:** Reference Resolution (0/4 major tasks) — **12h** — Track A
- [ ] **Phase 5:** Markdown Emission (0/3 major tasks) — **11h** — Track A
- [ ] **Phase 6:** CLI & Integration (0/4 major tasks) — **13h** — Track A
- [ ] **Phase 7:** Integration with Specs (0/2 major tasks) — **11h** — Integration
- [ ] **Phase 8:** Testing & QA (0/3 major tasks) — **12h** — Integration
- [ ] **Phase 9:** Optimization & Release (0/2 major tasks) — **4h** — Release

### By Priority
- **[P0] Critical:** 0 / 47 tasks (blocks project)
- **[P1] High:** 0 / 89 tasks (required for v0.1)
- **[P2] Medium:** 0 / 17 tasks (can defer)

### By Track
- **Track A (Core Compiler):** Phases 1, 2, 4, 5, 6 — Sequential, 56 hours
- **Track B (Specifications):** Phase 3 — Parallel with Track A, 17 hours
- **Integration:** Phase 7, 8 — Requires both tracks, 23 hours
- **Release:** Phase 9 — Final QA, 4 hours

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

## Revision History

| Version | Date       | Author          | Changes                                              |
|---------|------------|-----------------|------------------------------------------------------|
| 2.0.0   | 2025-12-02 | Egor Merkushev  | Add priorities, dependencies, tracks, critical path |
| 1.0.0   | 2025-12-02 | Egor Merkushev  | Initial work plan creation                           |
