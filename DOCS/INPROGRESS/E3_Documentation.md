# E3 — Documentation

**Version:** 1.0.0
**Date:** 2025-12-12
**Status:** Planning (PLAN output)
**Priority:** P1 (High)
**Effort:** 4 hours
**Phase:** Phase 8 — Testing & Quality Assurance (requires D2 Compiler Driver ✅)

---

## 1. Objective & Scope

- **Goal:** Create comprehensive documentation for Hyperprompt Compiler v0.1, covering installation, usage, language specification, examples, integration patterns, and error handling. Documentation must be accurate, complete, and serve both end-users and developers.
- **Primary Deliverables:**
  1. `README.md` — Installation instructions, quick start, feature overview
  2. `USAGE.md` or inline help — CLI flags, examples with all arguments
  3. `LANGUAGE.md` — Hypercode grammar, syntax rules, file format specification
  4. Example files — Valid `.hc` files demonstrating core features
  5. `ERROR_CODES.md` — Exit codes 0-4 with descriptions and solutions
  6. `ARCHITECTURE.md` — System design, module relationships, data flow
  7. `SPECS_INTEGRATION.md` — How SpecificationCore is used in compiler
  8. API documentation — Generated from source code comments
  9. Troubleshooting guide — Common issues and solutions
  10. Future extensions roadmap — v0.2+ features
- **Constraints & Assumptions:**
  - Must reference actual CLI implementation (D1: Argument Parsing)
  - Must document actual error scenarios (from test corpus and error types)
  - Must include real code examples from test fixtures
  - Assume readers have basic CLI/compilation knowledge
  - Focus on accuracy over comprehensive feature explanations

---

## 2. Context & Dependencies

- **Dependencies:** Completion of D2 (Compiler Driver). All compilation phases complete, error handling defined, test corpus available.
- **Motivation:** Users need clear instructions to install, use, and troubleshoot Hyperprompt. Developers need architectural overview. Current codebase has no user-facing documentation.
- **Source Materials:**
  - Compiler error types (Core module)
  - CLI arguments (D1 implementation)
  - Exit codes reference (Workplan §"Exit Codes Reference")
  - Test corpus (E1: test fixtures with valid/invalid examples)
  - PRD v0.0.1 and Design Specs (feature descriptions)
  - Actual Swift code (for API documentation extraction)

---

## 3. Functional Requirements

1. **README.md**
   - Installation steps for macOS and Linux
   - Quick start: "compile your first file"
   - Feature overview (5-7 bullet points)
   - Links to detailed documentation
   - Requirements: Swift 5.5+

2. **USAGE.md (or embedded in README)**
   - All CLI arguments with descriptions
   - Examples for each flag combination
   - Strict vs lenient mode explanation with examples
   - Common workflows (single file, recursive, error handling)

3. **LANGUAGE.md**
   - Hypercode grammar (EBNF or similar)
   - File structure (root node, nesting, indentation)
   - Node types (inline text, .md references, .hc references)
   - Indentation rules, quote handling, comments
   - Line ending normalization
   - Examples: valid and invalid syntax

4. **ARCHITECTURE.md**
   - Module diagram (Core, Parser, Resolver, Emitter, CLI, Statistics)
   - Data flow: input → AST → resolution → output
   - Key interfaces (Node, Token, ResolutionKind, etc.)
   - Algorithm overview (parsing, resolution, emission)
   - SpecificationCore integration points

5. **SPECS_INTEGRATION.md**
   - Lexical specifications usage (IsBlankLineSpec, etc.)
   - Path specifications (NoTraversalSpec, WithinRootSpec, etc.)
   - Decision specifications (LineKindDecision, PathTypeDecision)
   - Benefits of specification-driven design
   - How to extend with new specifications

6. **ERROR_CODES.md**
   - Exit code 0: Success
   - Exit code 1: IO Error (file not found, permission denied)
   - Exit code 2: Syntax Error (invalid Hypercode)
   - Exit code 3: Resolution Error (missing reference, circular dependency)
   - Exit code 4: Internal Error (compiler bug)
   - Solutions for each error type

7. **Example Files** (in `docs/examples/`)
   - `hello.hc` — Single root node with inline text
   - `nested.hc` — Hierarchical structure with indentation
   - `with-markdown.hc` — References to `.md` files
   - `with-hypercode.hc` — Recursive `.hc` references
   - `comments.hc` — Using comments for documentation

8. **TROUBLESHOOTING.md**
   - "How do I...?" sections (install, run, debug)
   - Common errors and fixes
   - Platform-specific issues
   - Performance tips

9. **FUTURE.md**
   - v0.2 planned features
   - Community contribution guidelines
   - Feature request process

---

## 4. Non-Functional Requirements

- **Accuracy:** All documentation must match actual implementation (test against real CLI)
- **Completeness:** Cover all publicly documented features
- **Clarity:** Use clear language, avoid jargon, provide examples
- **Maintainability:** Documentation structure supports future updates
- **Accessibility:** Readable on GitHub, plain markdown format
- **Searchability:** Consistent terminology, clear section headings

---

## 5. Structured TODO Plan

| Step | Description | Priority | Effort | Inputs | Process | Output/Acceptance |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Research actual CLI and error behaviors | High | 0.5h | D1 implementation, error types | Run `hyperprompt --help`, test error scenarios | Documentation of actual behavior captured |
| 2 | Write README.md with installation & quick start | High | 1h | Swift version requirements, test fixture | Write install steps, quick start example, feature list | README complete, tested on target platforms |
| 3 | Write USAGE.md with all CLI flags & examples | High | 0.75h | D1 arguments, test fixtures | Document each flag, provide usage examples | Usage guide covers all arguments and modes |
| 4 | Write LANGUAGE.md with grammar & examples | High | 1h | Test corpus (V01-V14, I01-I10), grammar rules | Define syntax rules, provide valid/invalid examples | Grammar specification complete |
| 5 | Write ERROR_CODES.md with solutions | Medium | 0.5h | Exit code definitions, test error outputs | Map exit codes to scenarios, provide solutions | Error guide covers all 5 exit codes |
| 6 | Write ARCHITECTURE.md with diagrams | Medium | 0.75h | Module structure, data flow | Describe modules, show relationships, explain flow | Architecture overview complete |
| 7 | Write SPECS_INTEGRATION.md | Low | 0.5h | Specification implementations (Phase 3) | Explain how specs are used in lexer/resolver | Specs integration documented |
| 8 | Create example files in docs/examples/ | Medium | 0.5h | Test fixtures (V01, V03, V08, etc.) | Copy/adapt test fixtures to examples/ | 5-7 runnable example files |
| 9 | Generate API documentation | Low | 0.5h | Source code with doc comments | Extract/format API docs for public types | API reference available |
| 10 | Write TROUBLESHOOTING.md | Low | 0.5h | Common issues from tests/errors | Collect FAQs, provide solutions | Troubleshooting guide for common issues |
| 11 | Write FUTURE.md roadmap | Low | 0.25h | Workplan Phase 9 notes | Outline v0.2 features, contribution process | Future direction documented |

---

## 6. Acceptance Criteria & Verification

- **README Complete:** Installation, quick start, features, links all present; tested on target platform
- **USAGE Complete:** All CLI flags documented with examples; verified against actual `--help` output
- **LANGUAGE Complete:** Grammar defined with valid/invalid examples; syntax rules comprehensive
- **ERROR_CODES Complete:** All 5 exit codes mapped to scenarios with solutions
- **ARCHITECTURE Complete:** Module diagram, data flow, key interfaces described
- **EXAMPLES Complete:** 5-7 runnable .hc files in docs/examples/
- **Cross-links:** All docs cross-referenced (README → USAGE, ERROR_CODES, etc.)
- **No Typos/Grammar:** Documentation proofread for clarity

---

## 7. Documentation Templates

### README.md Template
```markdown
# Hyperprompt Compiler v0.1

A Swift-based compiler for Hypercode language that transforms nested document structures into Markdown.

## Installation

### macOS
\`\`\`bash
curl -L -o hyperprompt https://github.com/0al-spec/Hyperprompt/releases/download/v0.1.0/hyperprompt-macos
chmod +x hyperprompt
sudo mv hyperprompt /usr/local/bin/
\`\`\`

### Linux
\`\`\`bash
wget https://github.com/0al-spec/Hyperprompt/releases/download/v0.1.0/hyperprompt-linux
chmod +x hyperprompt
sudo mv hyperprompt /usr/local/bin/
\`\`\`

## Quick Start

\`\`\`bash
# Create a simple .hc file
echo '"Hello World"' > hello.hc

# Compile it
hyperprompt hello.hc --output output.md

# View result
cat output.md
\`\`\`

## Features

- **Hierarchical Compilation:** Nested document structures with indentation-based nesting
- **File References:** Include Markdown (.md) and Hypercode (.hc) files inline
- **Recursive Compilation:** .hc files compiled recursively with automatic depth adjustment
- **Circular Dependency Detection:** Prevent infinite loops in nested references
- **Declarative Validation:** Grammar validated via composable specifications
- **Deterministic Output:** Byte-for-byte identical across platforms

## Documentation

- [Usage Guide](USAGE.md) — All CLI flags and examples
- [Language Specification](LANGUAGE.md) — Hypercode grammar and syntax
- [Architecture](ARCHITECTURE.md) — System design and module overview
- [Error Codes](ERROR_CODES.md) — Exit codes and solutions
- [Troubleshooting](TROUBLESHOOTING.md) — Common issues and fixes

## Requirements

- Swift 5.5 or later
- macOS 11+ or Ubuntu 20.04+

## License

MIT
\`\`\`

### ERROR_CODES.md Template
```markdown
# Error Codes

## Exit Code 0: Success
Compilation completed without errors.

## Exit Code 1: IO Error
File not found, permission denied, or disk full.

**Common Causes:**
- Input file doesn't exist
- Referenced file missing (strict mode)
- No write permission for output

**Solutions:**
1. Verify input file path: \`ls -la input.hc\`
2. Check permissions: \`chmod +r input.hc\`
3. Use lenient mode: \`hyperprompt input.hc --lenient\`

## Exit Code 2: Syntax Error
Invalid Hypercode syntax in source file.

**Common Causes:**
- Unclosed quotes: \`"Missing closing quote\`
- Tab in indentation (must be spaces)
- Indentation not multiple of 4 spaces

**Solutions:**
1. Check line endings: \`file input.hc\` (should be LF, not CRLF)
2. Verify quotes: All node literals must be enclosed in double quotes
3. Check indentation: \`cat -A input.hc\` (no ^I for tabs)

... (continue for codes 3, 4)
\`\`\`

---

## 8. Files to Create

**Location:** `DOCS/` (user-facing documentation) and `docs/` (project root)

1. `README.md` — Main entry point
2. `USAGE.md` — CLI documentation
3. `LANGUAGE.md` — Grammar specification
4. `ARCHITECTURE.md` — System design
5. `SPECS_INTEGRATION.md` — SpecificationCore integration
6. `ERROR_CODES.md` — Exit code reference
7. `TROUBLESHOOTING.md` — FAQs and solutions
8. `FUTURE.md` — Roadmap for v0.2+
9. `docs/examples/hello.hc` — Basic example
10. `docs/examples/nested.hc` — Hierarchical example
11. `docs/examples/with-markdown.hc` — .md reference example
12. `docs/examples/with-hypercode.hc` — .hc reference example
13. `docs/examples/comments.hc` — Comment usage example
14. Update package docstrings for API docs

---

## 9. Risks & Mitigations

- **Risk:** Documentation becomes outdated as code changes.
  **Mitigation:** Link to test fixtures; keep examples in repo under version control.

- **Risk:** Users can't find answers in docs.
  **Mitigation:** Clear TOC, consistent terminology, search-friendly markdown.

- **Risk:** Installation steps fail on some platforms.
  **Mitigation:** Test on both macOS and Linux; provide binary distribution links.

---

## 10. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-12 | Claude (PLAN Generator) | Initial PRD creation from next.md |

---

## 11. References

- **Workplan v2.0.0:** `DOCS/Workplan.md` — Phase 8, E3
- **D1 PRD:** `DOCS/TASKS_ARCHIVE/D1_Argument_Parsing.md` — CLI argument definitions
- **PRD v0.0.1:** `DOCS/PRD/v0.0.1/00_PRD_001.md` — Feature descriptions
- **Design Spec:** `DOCS/PRD/v0.0.1/01_DESIGN_SPEC_001.md` — Architecture
- **Test Corpus:** `DOCS/TASKS_ARCHIVE/E1_Test_Corpus_Implementation.md` — Valid/invalid examples

---

**Status:** ✅ Planning Complete — Ready to begin implementation

---

**Archived:** 2025-12-12
