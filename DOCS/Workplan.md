# Hyperprompt Compiler v0.1 — Work Plan

**Document Version:** 1.0.0
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

---

## Phase 1: Foundation & Core Types

**Goal:** Establish project structure, core types, and basic infrastructure
**Estimated Duration:** 6 hours

### A1: Project Initialization
- [ ] Create Swift package with appropriate directory structure
- [ ] Configure Package.swift with dependencies:
  - [ ] swift-argument-parser
  - [ ] swift-crypto
  - [ ] SpecificationCore
- [ ] Establish module boundaries (Core, Parser, Resolver, Emitter, CLI, Statistics)
- [ ] Set up test target structure
- [ ] Verify `swift build` completes without errors
- [ ] Verify `swift test` runs empty test suite

**Acceptance Criteria:** Project builds successfully, all modules defined, dependencies resolved

---

### A2: Core Types Implementation
- [ ] Define `SourceLocation` struct (file path + line number)
- [ ] Define `CompilerError` protocol with diagnostic information
- [ ] Implement error categories enum (IO, Syntax, Resolution, Internal)
- [ ] Implement `FileSystem` protocol for abstracting file operations
- [ ] Create `LocalFileSystem` production implementation
- [ ] Create `MockFileSystem` for testing
- [ ] Write unit tests for all error cases with diagnostics

**Acceptance Criteria:** All core types have >90% test coverage, error cases produce appropriate diagnostics

---

### A3: Domain Types for Specifications
- [ ] Create `HypercodeGrammar` module with SpecificationCore dependency
- [ ] Define `RawLine` struct (text, lineNumber, filePath)
- [ ] Define `LineKind` enum (blank, comment, node)
- [ ] Define `ParsedLine` struct (kind, indentSpaces, depth, literal, location)
- [ ] Define `PathKind` enum (allowed, forbidden, invalid)
- [ ] Write unit tests for domain type conversions

**Acceptance Criteria:** Domain types properly model lexer/resolver input/output, tests verify correct behavior

---

## Phase 2: Lexer & Parser (Core Compilation)

**Goal:** Implement tokenization and AST construction
**Estimated Duration:** 14 hours

### A3 (continued): Lexer Implementation
- [ ] Implement line-by-line tokenization
- [ ] Implement `readLines()` with CRLF/CR → LF normalization
- [ ] Recognize blank lines
- [ ] Recognize comment lines (# prefix with optional indent)
- [ ] Recognize node lines (quoted literals)
- [ ] Extract indentation level (groups of 4 spaces)
- [ ] Extract literal content (content between quotes)
- [ ] Enforce single-line content constraint
- [ ] Reject tabs in indentation (syntax error)
- [ ] Write lexer tests for 20+ sample files

**Acceptance Criteria:** Lexer correctly tokenizes all valid test inputs, reports meaningful errors for invalid inputs

---

### A4: Parser & AST Construction
- [ ] Implement `Node` struct (literal, depth, location, children, resolution)
- [ ] Implement `Program` struct (root node container)
- [ ] Implement `Token` enum (blank, comment, node)
- [ ] Build tree structure from token stream based on indentation
- [ ] Compute depth from indentation (spaces / 4)
- [ ] Establish parent-child relationships via depth stack
- [ ] Enforce single root node constraint (depth 0)
- [ ] Report syntax errors with source locations
- [ ] Handle blank lines structurally (preserve but don't add to AST)
- [ ] Skip comment tokens during AST construction
- [ ] Write parser tests for all valid/invalid structures

**Acceptance Criteria:** Parser produces correct AST for all valid inputs, reports meaningful errors for invalid inputs

---

## Phase 3: Specifications (HypercodeGrammar Module)

**Goal:** Implement executable EBNF grammar as composable specifications
**Estimated Duration:** 17 hours

### Spec-1: Lexical Specifications
- [ ] Implement `IsBlankLineSpec` (line contains only spaces)
- [ ] Implement `IsCommentLineSpec` (starts with # after indent)
- [ ] Implement `IsNodeLineSpec` (quoted literal on single line)
- [ ] Implement `StartsWithDoubleQuoteSpec`
- [ ] Implement `EndsWithDoubleQuoteSpec`
- [ ] Implement `ContentWithinQuotesIsSingleLineSpec`
- [ ] Implement `ValidQuotesSpec` (composite: starts AND ends AND single-line)
- [ ] Implement `ContainsLFSpec` (detects \n)
- [ ] Implement `ContainsCRSpec` (detects \r)
- [ ] Implement `SingleLineContentSpec` (composite: NOT (LF OR CR))
- [ ] Write unit tests for each specification (15+ test cases each)

**Acceptance Criteria:** All lexical specs pass unit tests, composition operators work correctly

---

### Spec-2: Indentation & Depth Specifications
- [ ] Implement `NoTabsIndentSpec` (no tabs in indentation)
- [ ] Implement `IndentMultipleOf4Spec` (indent % 4 == 0)
- [ ] Implement `DepthWithinLimitSpec` (depth <= 10, configurable)
- [ ] Write unit tests for edge cases (depth 0, depth 10, depth 11)
- [ ] Test composition with ValidNodeLineSpec

**Acceptance Criteria:** Indentation validation catches all forbidden patterns, depth limits enforced correctly

---

### Spec-3: Path Validation Specifications
- [ ] Implement `HasMarkdownExtensionSpec` (.md suffix)
- [ ] Implement `HasHypercodeExtensionSpec` (.hc suffix)
- [ ] Implement `IsAllowedExtensionSpec` (composite: .md OR .hc)
- [ ] Implement `ContainsPathSeparatorSpec` (contains /)
- [ ] Implement `ContainsExtensionDotSpec` (contains .)
- [ ] Implement `LooksLikeFileReferenceSpec` (heuristic: separator OR dot)
- [ ] Implement `NoTraversalSpec` (no .. components)
- [ ] Implement `WithinRootSpec` (path starts with root)
- [ ] Write unit tests for all path validation cases

**Acceptance Criteria:** Path specs correctly identify allowed/forbidden extensions, security violations detected

---

### Spec-4: Composite & Decision Specifications
- [ ] Implement `ValidNodeLineSpec` (composite: NoTabs AND Indent AND Depth AND Quotes AND IsNode)
- [ ] Implement `ValidReferencePathSpec` (composite: NoTraversal AND AllowedExtension)
- [ ] Implement `IsSkippableLineSpec` (semantic: IsBlank OR IsComment)
- [ ] Implement `IsSemanticLineSpec` (semantic: NOT IsSkippable)
- [ ] Implement `LineKindDecision` using `FirstMatchSpec` (blank → comment → node priority)
- [ ] Implement `PathTypeDecision` using `FirstMatchSpec`
- [ ] Write composition tests (AND, OR, NOT truth tables)
- [ ] Write decision spec tests (priority ordering, nil handling)
- [ ] Test De Morgan's Law equivalences

**Acceptance Criteria:** Composite specs correctly combine atomic rules, decision specs return correct classifications

---

## Phase 4: Reference Resolution

**Goal:** Implement file reference resolution with circular dependency detection
**Estimated Duration:** 12 hours

### B1: Reference Resolver
- [ ] Implement file existence checking against root directory
- [ ] Classify literals as file references or inline text
- [ ] Handle `.md` extension (load content, no recursion)
- [ ] Handle `.hc` extension (recursive compilation)
- [ ] Reject all other extensions (hard error, exit 3)
- [ ] Implement strict mode (missing file → error)
- [ ] Implement lenient mode (missing file → inline text)
- [ ] Integrate `ValidReferencePathSpec` for pre-validation
- [ ] Integrate `PathTypeDecision` for classification
- [ ] Write resolver tests for all reference types

**Acceptance Criteria:** Resolver correctly classifies all reference types, strict/lenient modes work as specified

---

### B2: Dependency Tracker
- [ ] Implement visitation stack for cycle detection
- [ ] Detect direct circular dependencies (A → A)
- [ ] Detect transitive circular dependencies (A → B → A)
- [ ] Produce clear cycle path descriptions in error messages
- [ ] Optimize for deep trees with memoization
- [ ] Write tests for various cycle patterns

**Acceptance Criteria:** All circular dependencies detected, error messages show full cycle path

---

### B3: File Loader & Caching
- [ ] Implement file content reading with UTF-8 encoding
- [ ] Implement line ending normalization (CRLF/CR → LF)
- [ ] Cache loaded content to avoid redundant reads
- [ ] Compute SHA256 hashes during loading (using swift-crypto)
- [ ] Collect file metadata for manifest generation
- [ ] Implement `ManifestEntry` struct (path, sha256, size, type)
- [ ] Implement `ManifestBuilder` for collecting entries
- [ ] Write tests for hash computation accuracy

**Acceptance Criteria:** File content correctly loaded and cached, SHA256 hashes accurate, metadata collected

---

### B4: Recursive Compilation
- [ ] Implement recursive parser invocation for `.hc` files
- [ ] Merge child ASTs into parent tree at correct depth
- [ ] Propagate errors from nested compilations
- [ ] Maintain source location tracking across files
- [ ] Update visitation stack correctly during recursion
- [ ] Write tests for nested `.hc` files (3+ levels deep)

**Acceptance Criteria:** Nested `.hc` files correctly compiled and embedded, errors propagate with correct locations

---

## Phase 5: Markdown Emission

**Goal:** Generate output with heading adjustment and provenance
**Estimated Duration:** 11 hours

### C1: Heading Adjuster
- [ ] Parse ATX-style headings (# prefix)
- [ ] Parse Setext-style headings (underlines with = or -)
- [ ] Compute adjusted heading level (original + offset)
- [ ] Handle overflow beyond H6 (convert to **bold**)
- [ ] Preserve heading attributes and trailing content
- [ ] Normalize line endings in embedded content to LF
- [ ] Write tests for all heading styles and edge cases

**Acceptance Criteria:** All heading styles correctly adjusted, overflow handled, test corpus passes

---

### C2: Markdown Emitter
- [ ] Implement tree traversal for output generation
- [ ] Generate headings from node content or file names
- [ ] Use effective depth for nested embeddings (parent + node depth)
- [ ] Embed file content with adjusted headings
- [ ] Insert blank lines between sibling sections
- [ ] Handle inline text literals as body content
- [ ] Ensure final output ends with exactly one LF
- [ ] Write emitter tests matching expected output

**Acceptance Criteria:** Emitter produces valid Markdown matching expected output for all test cases

---

### C3: Manifest Generator
- [ ] Implement `Manifest` struct (timestamp, version, root, sources)
- [ ] Generate ISO 8601 timestamp
- [ ] Sort manifest JSON keys alphabetically for determinism
- [ ] Format JSON with consistent structure
- [ ] Write manifest to specified path
- [ ] Ensure manifest ends with exactly one LF
- [ ] Write tests for manifest accuracy

**Acceptance Criteria:** Manifest contains accurate metadata for all source files, JSON format is deterministic

---

## Phase 6: CLI & Integration

**Goal:** Command-line interface and end-to-end compilation
**Estimated Duration:** 13 hours

### D1: Argument Parsing
- [ ] Define command structure with swift-argument-parser
- [ ] Implement `@Argument` for input file
- [ ] Implement `--output, -o` option
- [ ] Implement `--manifest, -m` option
- [ ] Implement `--root, -r` option
- [ ] Implement `--strict` flag (default)
- [ ] Implement `--lenient` flag
- [ ] Implement `--stats` flag
- [ ] Implement `--dry-run` flag
- [ ] Implement `--verbose, -v` flag
- [ ] Implement `--version` flag
- [ ] Implement `--help, -h` flag
- [ ] Validate argument combinations (strict XOR lenient)
- [ ] Generate help text
- [ ] Write argument parsing tests

**Acceptance Criteria:** All documented arguments recognized and validated, help text accurate

---

### D2: Compiler Driver
- [ ] Implement `CompilerDriver` orchestrating parse → resolve → emit → manifest pipeline
- [ ] Implement dry-run mode (validate without writing)
- [ ] Implement verbose logging
- [ ] Handle interruption signals (SIGINT, SIGTERM) gracefully
- [ ] Set default values for output/manifest/root paths
- [ ] Write end-to-end compilation tests
- [ ] Test with all test corpus files (V01-V14, I01-I10)

**Acceptance Criteria:** End-to-end compilation succeeds for all valid inputs, fails correctly for invalid inputs

---

### D3: Diagnostic Printer
- [ ] Format error messages with source context
- [ ] Implement format: `<file>:<line>: error: <message>`
- [ ] Show context line with caret (^^^) pointing to issue
- [ ] Colorize output for terminal display (optional)
- [ ] Support plain text output for non-terminal destinations
- [ ] Aggregate multiple errors when possible
- [ ] Write diagnostic formatting tests

**Acceptance Criteria:** Error messages clearly identify problem location and nature, format matches specification

---

### D4: Statistics Reporter
- [ ] Implement `StatsCollector` tracking compilation metrics
- [ ] Count Hypercode files processed
- [ ] Count Markdown files embedded
- [ ] Sum total input bytes
- [ ] Record output bytes
- [ ] Track maximum depth encountered
- [ ] Measure elapsed time (ms)
- [ ] Implement `StatsReporter` formatting output
- [ ] Integrate with `--stats` flag and verbose mode
- [ ] Write statistics tests

**Acceptance Criteria:** Statistics output includes all specified metrics, integrates with CLI flags

---

## Phase 7: Lexer & Resolver Integration with Specs

**Goal:** Replace imperative validation with declarative specifications
**Estimated Duration:** 11 hours

### Integration-1: Lexer with Specifications
- [ ] Refactor Lexer to use `LineKindDecision` for classification
- [ ] Replace imperative tab checking with `NoTabsIndentSpec`
- [ ] Replace imperative indent validation with `IndentMultipleOf4Spec`
- [ ] Replace imperative depth checking with `DepthWithinLimitSpec`
- [ ] Use `ValidNodeLineSpec` for comprehensive node validation
- [ ] Update error messages to reference specification failures
- [ ] Verify all existing lexer tests pass
- [ ] Add integration tests for specification-based lexer
- [ ] Benchmark performance vs imperative version

**Acceptance Criteria:** Lexer uses specifications for all validation, tests pass, <10% performance overhead

---

### Integration-2: Resolver with Specifications
- [ ] Refactor ReferenceResolver to use `ValidReferencePathSpec`
- [ ] Replace imperative path validation with `NoTraversalSpec`
- [ ] Replace imperative extension checking with `IsAllowedExtensionSpec`
- [ ] Use `PathTypeDecision` for path classification
- [ ] Integrate `LooksLikeFileReferenceSpec` for heuristic detection
- [ ] Update error messages for specification failures
- [ ] Verify all existing resolver tests pass
- [ ] Add integration tests for specification-based resolver
- [ ] Benchmark performance vs imperative version

**Acceptance Criteria:** Resolver uses specifications for all validation, tests pass, <10% performance overhead

---

## Phase 8: Testing & Quality Assurance

**Goal:** Comprehensive test coverage and cross-platform validation
**Estimated Duration:** 12 hours

### E1: Test Corpus Implementation
- [ ] Create test corpus directory structure
- [ ] Implement Valid Input Tests (V01-V14):
  - [ ] V01: Single root node with inline text
  - [ ] V03: Nested hierarchy 3 levels deep
  - [ ] V04: Single Markdown file reference at root
  - [ ] V05: Nested Markdown file references
  - [ ] V06: Single Hypercode file reference
  - [ ] V07: Nested Hypercode files (3 levels)
  - [ ] V08: Mixed inline text and file references
  - [ ] V09: Markdown with headings H1-H4
  - [ ] V10: Markdown with Setext headings
  - [ ] V11: Comment lines interspersed
  - [ ] V12: Blank lines between node groups
  - [ ] V13: Maximum depth of 10 levels
  - [ ] V14: Unicode content in literals and files
- [ ] Implement Invalid Input Tests (I01-I10):
  - [ ] I01: Tab characters in indentation
  - [ ] I02: Misaligned indentation (not divisible by 4)
  - [ ] I03: Unclosed quotation mark
  - [ ] I04: Missing file reference (strict mode)
  - [ ] I05: Direct circular dependency (A → A)
  - [ ] I06: Indirect circular dependency (A → B → A)
  - [ ] I07: Depth exceeding 10
  - [ ] I08: Path traversal with ..
  - [ ] I09: Unreadable file (permission error)
  - [ ] I10: Multiple root nodes
- [ ] Create golden files for each test ({test-id}.expected.md, {test-id}.expected.json)
- [ ] Implement golden-file comparison tests
- [ ] Verify exit codes for all error scenarios
- [ ] Achieve >80% code coverage

**Acceptance Criteria:** All valid tests match golden files, all invalid tests fail predictably, >80% coverage

---

### E2: Cross-Platform Testing
- [ ] Test on macOS Intel
- [ ] Test on macOS Apple Silicon (M1/M2)
- [ ] Test on Ubuntu 22.04 x86_64
- [ ] Test on Ubuntu 22.04 ARM64
- [ ] Test on Windows 10+ x86_64 (native)
- [ ] Test on Windows with WSL2
- [ ] Verify deterministic output (byte-for-byte identical across platforms)
- [ ] Document any platform-specific behaviors
- [ ] Verify LF line endings on all platforms

**Acceptance Criteria:** Identical inputs produce identical outputs on all platforms, no platform-specific bugs

---

### E3: Documentation
- [ ] Write README with installation instructions
- [ ] Document usage examples with all CLI flags
- [ ] Document Hypercode language specification (grammar)
- [ ] Provide example files demonstrating all features
- [ ] Document SpecificationCore integration patterns
- [ ] Generate API documentation from source comments
- [ ] Write architecture overview with diagrams
- [ ] Document error codes and meanings (exit codes 0-4)
- [ ] Create troubleshooting guide
- [ ] Document future extensions (v0.2+)

**Acceptance Criteria:** Documentation is complete, accurate, and covers all features

---

## Phase 9: Optimization & Finalization

**Goal:** Performance tuning and release preparation
**Estimated Duration:** 4 hours

### Optimization Tasks
- [ ] Profile compilation with Instruments (macOS) or Valgrind (Linux)
- [ ] Optimize hot paths identified in profiling
- [ ] Benchmark against performance targets:
  - [ ] 1000-node tree compilation < 5 seconds
  - [ ] Linear scaling with file count
- [ ] Verify deterministic output (repeated compilations identical)
- [ ] Test with large corpus (100+ files)
- [ ] Verify manifest JSON key alphabetical sorting
- [ ] Test memory usage with large files (>1MB)
- [ ] Fix any memory leaks detected

**Acceptance Criteria:** Performance targets met, no memory leaks, deterministic output verified

---

### Release Preparation
- [ ] Tag version 0.1.0
- [ ] Build release binaries for all platforms
- [ ] Create distribution packages (DMG, DEB, ZIP)
- [ ] Write release notes
- [ ] Update CHANGELOG
- [ ] Archive test results and coverage reports

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
- [ ] Phase 1: Foundation & Core Types (0/3 major tasks)
- [ ] Phase 2: Lexer & Parser (0/2 major tasks)
- [ ] Phase 3: Specifications (0/4 major tasks)
- [ ] Phase 4: Reference Resolution (0/4 major tasks)
- [ ] Phase 5: Markdown Emission (0/3 major tasks)
- [ ] Phase 6: CLI & Integration (0/4 major tasks)
- [ ] Phase 7: Integration with Specs (0/2 major tasks)
- [ ] Phase 8: Testing & QA (0/3 major tasks)
- [ ] Phase 9: Optimization & Release (0/2 major tasks)

---

## Notes

- **Dependencies:** SpecificationCore must be available before Phase 3
- **Order:** Phases can overlap, but specifications should be complete before integration (Phase 7)
- **Testing:** Write tests concurrently with implementation, not as separate phase
- **Documentation:** Update incrementally, not just in Phase 8

---

## Revision History

| Version | Date       | Author          | Changes                    |
|---------|------------|-----------------|----------------------------|
| 1.0.0   | 2025-12-02 | Egor Merkushev  | Initial work plan creation |
