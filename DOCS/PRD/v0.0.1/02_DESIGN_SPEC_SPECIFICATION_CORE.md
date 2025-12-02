# Hyperprompt Compiler — SpecificationCore Integration Design

**Document Version:** 0.0.1
**Date:** December 2, 2025
**Author:** Egor Merkushev
**Status:** Draft for Implementation

-----

## 1. Purpose

This document defines the integration strategy for [SpecificationCore](https://github.com/SoundBlaster/SpecificationCore) library into the Hyperprompt Compiler v0.1. While the compiler's base architecture (01_DESIGN_SPEC_001.md) establishes the overall structure, this specification details how the **Specification Pattern** can be applied to enhance validation, classification, and rule enforcement throughout the compilation pipeline.

### 1.1 Integration Goals

The integration of SpecificationCore serves three primary objectives:

1. **Declarative Validation**: Express complex validation rules as composable, testable specifications rather than imperative conditional logic scattered throughout the codebase.

2. **Enhanced Maintainability**: Encapsulate business rules (syntax constraints, path validation, depth limits) as explicit specification objects that serve as living documentation.

3. **Extensibility**: Provide a foundation for future language extensions (annotations, metadata, special syntax) without requiring fundamental parser rewrites.

### 1.2 Integration Scope

SpecificationCore will be integrated into the following compiler modules:

- **Parser Module (Lexer)**: Line classification, indentation validation, depth constraints
- **Resolver Module**: Path validation, extension checking, reference classification
- **Core Module (Validation)**: Centralized specification definitions and composition

The library will **not** replace the hand-written parser or AST construction logic. Instead, it acts as a declarative validation and classification layer on top of low-level lexical analysis.

-----

## 2. Architectural Overview

### 2.1 High-Level Strategy

SpecificationCore enhances the compiler's validation capabilities without replacing existing algorithms:

```
┌─────────────────────────────────────────────────────────┐
│                    Compiler Pipeline                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────┐   ┌──────────┐   ┌─────────┐          │
│  │  Lexer    │──→│  Parser  │──→│Resolver │──→ Emit  │
│  └─────┬─────┘   └──────────┘   └────┬────┘          │
│        │                               │               │
│        ├─ LineClassifier               ├─ PathValidator│
│        │  (FirstMatchSpec)             │  (Spec AND)  │
│        │                               │               │
│        ├─ IndentValidator              ├─ ExtValidator│
│        │  (Spec AND)                   │  (Spec OR)   │
│        │                               │               │
│        └─ DepthValidator               └─ SafetySpecs │
│           (PredicateSpec)                              │
│                                                         │
│                    ▲                                    │
│                    │                                    │
│              ┌─────┴──────┐                            │
│              │ Core.      │                            │
│              │ Validation │                            │
│              └────────────┘                            │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Module Boundary

A new **Core.Validation** submodule will be introduced:

```
Module_Core/
├── SourceLocation.swift
├── Diagnostic.swift
├── CompilerError.swift
├── FileSystem.swift
└── Validation/
    ├── Specifications/
    │   ├── LineSpecs.swift         # IsBlankLineSpec, IsCommentLineSpec, etc.
    │   ├── IndentationSpecs.swift  # NoTabsIndentSpec, IndentMultipleOf4Spec
    │   ├── DepthSpecs.swift        # DepthWithinLimitSpec
    │   ├── PathSpecs.swift         # IsAllowedExtensionSpec, NoTraversalSpec
    │   └── ContentSpecs.swift      # SingleLineContentSpec, ValidQuotesSpec
    ├── Decisions/
    │   ├── LineKindDecision.swift  # FirstMatchSpec for line classification
    │   └── PathTypeDecision.swift  # DecisionSpec for path resolution
    └── DomainTypes.swift           # RawLine, LineKind, ParsedLine
```

-----

## 3. Domain Types

### 3.1 Lexer Domain Types

Before integrating specifications, we introduce lightweight domain types for the lexer stage:

```swift
/// Raw line read from source file, before classification
struct RawLine {
    let text: String           // Full line text including indentation
    let lineNumber: Int        // 1-based line number for diagnostics
    let filePath: String       // Source file path
}

/// Classification result for a line
enum LineKind {
    case blank                 // Only whitespace
    case comment               // Starts with '#' after optional indent
    case node                  // Quoted literal with optional indent
}

/// Parsed line with extracted metadata
struct ParsedLine {
    let kind: LineKind
    let indentSpaces: Int      // Number of leading spaces
    let depth: Int             // indentSpaces / 4
    let literal: String?       // Extracted content for node lines (no quotes)
    let location: SourceLocation
}
```

### 3.2 Resolver Domain Types

```swift
/// Classification result for path validation
enum PathKind {
    case allowed(extension: String)   // .md or .hc
    case forbidden(extension: String) // All other extensions
    case invalid(reason: String)      // Traversal, symlink escape, etc.
}
```

-----

## 4. Specification Definitions

### 4.1 Line Classification Specifications

#### 4.1.1 IsBlankLineSpec

Verifies that a line contains only space characters (U+0020).

```swift
import SpecificationCore

struct IsBlankLineSpec: Specification {
    typealias Candidate = RawLine

    func isSatisfied(by candidate: RawLine) -> Bool {
        candidate.text.allSatisfy { $0 == " " }
    }
}
```

**Business Rule**: Blank lines are preserved structurally but do not contribute to AST.

#### 4.1.2 IsCommentLineSpec

Verifies that a line begins with `#` after optional indentation.

```swift
struct IsCommentLineSpec: Specification {
    typealias Candidate = RawLine

    func isSatisfied(by candidate: RawLine) -> Bool {
        let trimmedLeft = candidate.text.drop(while: { $0 == " " })
        return trimmedLeft.first == "#"
    }
}
```

**Business Rule**: Comments are ignored during AST construction but must be syntactically valid.

#### 4.1.3 IsNodeLineSpec

Verifies that a line is a valid node: quoted literal on a single line.

```swift
struct IsNodeLineSpec: Specification {
    typealias Candidate = RawLine

    func isSatisfied(by candidate: RawLine) -> Bool {
        let trimmedLeft = candidate.text.drop(while: { $0 == " " })

        // Must start and end with double quote
        guard trimmedLeft.first == "\"", trimmedLeft.last == "\"" else {
            return false
        }

        // Literal content must not contain newline (single-line constraint)
        let content = trimmedLeft.dropFirst().dropLast()
        return !content.contains("\n")
    }
}
```

**Business Rule**: Node literals must be single-line and fully quoted.

### 4.2 Indentation Specifications

#### 4.2.1 NoTabsIndentSpec

Verifies that indentation contains no tab characters.

```swift
struct NoTabsIndentSpec: Specification {
    typealias Candidate = RawLine

    func isSatisfied(by candidate: RawLine) -> Bool {
        // Extract indentation prefix (leading spaces/tabs)
        let indent = candidate.text.prefix { $0 == " " || $0 == "\t" }
        return !indent.contains("\t")
    }
}
```

**Business Rule**: Tabs are forbidden; only spaces allowed for indentation.
**Error**: Exit code 2 (Syntax Error) if violated.

#### 4.2.2 IndentMultipleOf4Spec

Verifies that indentation is a multiple of 4 spaces.

```swift
struct IndentMultipleOf4Spec: Specification {
    typealias Candidate = RawLine

    func isSatisfied(by candidate: RawLine) -> Bool {
        let spacesCount = candidate.text.prefix { $0 == " " }.count
        return spacesCount % 4 == 0
    }
}
```

**Business Rule**: Indentation must align to 4-space groups for correct depth calculation.
**Error**: Exit code 2 (Syntax Error) if violated.

### 4.3 Depth Specifications

#### 4.3.1 DepthWithinLimitSpec

Verifies that node depth does not exceed maximum of 10 levels.

```swift
struct DepthWithinLimitSpec: Specification {
    typealias Candidate = RawLine

    let maxDepth: Int

    init(maxDepth: Int = 10) {
        self.maxDepth = maxDepth
    }

    func isSatisfied(by candidate: RawLine) -> Bool {
        let spacesCount = candidate.text.prefix { $0 == " " }.count
        let depth = spacesCount / 4
        return depth <= maxDepth
    }
}
```

**Business Rule**: Maximum depth is 10. Deeper nesting causes compilation failure.
**Error**: Exit code 3 (Resolution Error) if violated.

### 4.4 Content Specifications

#### 4.4.1 Atomic Line Break Specifications

To properly detect all types of line breaks (LF, CR, CRLF), we define atomic specifications:

```swift
struct ContainsLFSpec: Specification {
    typealias Candidate = String  // Literal content

    func isSatisfied(by candidate: String) -> Bool {
        candidate.contains("\n")  // Unix/Linux/macOS (LF)
    }
}

struct ContainsCRSpec: Specification {
    typealias Candidate = String  // Literal content

    func isSatisfied(by candidate: String) -> Bool {
        candidate.contains("\r")  // Old Mac/Windows CR component
    }
}
```

**Business Rule**: Literal content must not contain any line break characters.

#### 4.4.2 SingleLineContentSpec (Composite with OR)

Verifies that literal content does not span multiple lines by checking for any type of line break.

```swift
struct SingleLineContentSpec: Specification {
    typealias Candidate = String  // Literal content

    private let spec: AnySpecification<String>

    init() {
        // OR composition: has LF OR has CR
        let hasAnyLineBreak = ContainsLFSpec().or(ContainsCRSpec())

        // NOT: no line breaks allowed
        self.spec = AnySpecification(!hasAnyLineBreak)
    }

    func isSatisfied(by candidate: String) -> Bool {
        spec.isSatisfied(by: candidate)
    }
}
```

**Alternative (Swift-idiomatic):**

```swift
struct SingleLineContentSpec: Specification {
    typealias Candidate = String

    func isSatisfied(by candidate: String) -> Bool {
        !candidate.contains(where: { $0.isNewline })
    }
}
```

**Context Note**: The PRD (§4.1) specifies that the parser normalizes all line endings to LF during `readLines()`. However, this composite approach provides defense-in-depth:
- Handles cases where content comes from non-normalized sources
- Explicitly documents the business rule
- Protects against future refactoring that might bypass normalization

#### 4.4.3 ValidQuotesSpec

Verifies that node line has matching opening and closing quotes.

```swift
struct ValidQuotesSpec: Specification {
    typealias Candidate = RawLine

    func isSatisfied(by candidate: RawLine) -> Bool {
        let trimmed = candidate.text.trimmingCharacters(in: .whitespaces)
        guard trimmed.first == "\"" else { return false }

        // Find closing quote (not preceded by backslash)
        var escaped = false
        var foundClosing = false

        for (index, char) in trimmed.enumerated() {
            if index == 0 { continue }  // Skip opening quote

            if escaped {
                escaped = false
                continue
            }

            if char == "\\" {
                escaped = true
                continue
            }

            if char == "\"" {
                foundClosing = true
                // Ensure it's at the end
                return index == trimmed.count - 1
            }
        }

        return false
    }
}
```

**Business Rule**: Node lines must have properly balanced quotes.
**Error**: Exit code 2 (Syntax Error) if violated.

### 4.5 Path Validation Specifications

#### 4.5.1 Atomic Extension Specifications

To support multiple allowed extensions in a composable way, define atomic specifications:

```swift
struct HasMarkdownExtensionSpec: Specification {
    typealias Candidate = String  // File path

    func isSatisfied(by candidate: String) -> Bool {
        candidate.hasSuffix(".md")
    }
}

struct HasHypercodeExtensionSpec: Specification {
    typealias Candidate = String  // File path

    func isSatisfied(by candidate: String) -> Bool {
        candidate.hasSuffix(".hc")
    }
}
```

**Business Rule**: Only specific file extensions are allowed for embedding.

#### 4.5.2 IsAllowedExtensionSpec (Composite with OR)

Verifies that file extension is `.md` or `.hc` using OR composition.

```swift
struct IsAllowedExtensionSpec: Specification {
    typealias Candidate = String  // File path

    private let spec: AnySpecification<String>

    init() {
        // OR composition: .md OR .hc
        let markdownExt = HasMarkdownExtensionSpec()
        let hypercodeExt = HasHypercodeExtensionSpec()

        self.spec = AnySpecification(markdownExt.or(hypercodeExt))
    }

    func isSatisfied(by candidate: String) -> Bool {
        spec.isSatisfied(by: candidate)
    }
}
```

**Alternative (direct implementation for simplicity):**

```swift
struct IsAllowedExtensionSpec: Specification {
    typealias Candidate = String

    func isSatisfied(by candidate: String) -> Bool {
        candidate.hasSuffix(".md") || candidate.hasSuffix(".hc")
    }
}
```

**Extensibility Note**: The atomic approach makes adding new extensions trivial:

```swift
// Future: support .txt files
struct HasTextExtensionSpec: Specification {
    typealias Candidate = String
    func isSatisfied(by candidate: String) -> Bool {
        candidate.hasSuffix(".txt")
    }
}

// Extended version
let allowedExtensions = HasMarkdownExtensionSpec()
    .or(HasHypercodeExtensionSpec())
    .or(HasTextExtensionSpec())
```

**Business Rule**: Only Markdown and Hypercode files can be referenced.
**Error**: Exit code 3 (Resolution Error) for other extensions.

#### 4.5.3 NoTraversalSpec

Verifies that path does not contain `..` components attempting to escape root.

```swift
struct NoTraversalSpec: Specification {
    typealias Candidate = String  // File path

    func isSatisfied(by candidate: String) -> Bool {
        !candidate.split(separator: "/").contains("..")
    }
}
```

**Business Rule**: Path traversal attempts are security violations.
**Error**: Exit code 3 (Resolution Error).

#### 4.5.4 WithinRootSpec

Verifies that resolved absolute path is within or below the root directory.

```swift
struct WithinRootSpec: Specification {
    typealias Candidate = String  // Absolute path

    let rootPath: String  // Canonical absolute root path

    init(rootPath: String) {
        self.rootPath = rootPath
    }

    func isSatisfied(by candidate: String) -> Bool {
        candidate.hasPrefix(rootPath)
    }
}
```

**Business Rule**: All references must resolve within the compilation root.
**Error**: Exit code 3 (Resolution Error).

### 4.6 Additional Composite Specification Candidates

The following specifications contain composite conditions that could be refactored into atomic specifications with composition. These are documented here for future refactoring or as design alternatives.

#### 4.6.1 IsNodeLineSpec (Multi-condition)

**Current Implementation:**

```swift
struct IsNodeLineSpec: Specification {
    typealias Candidate = RawLine

    func isSatisfied(by candidate: RawLine) -> Bool {
        let trimmedLeft = candidate.text.drop(while: { $0 == " " })

        // Must start and end with double quote
        guard trimmedLeft.first == "\"", trimmedLeft.last == "\"" else {
            return false
        }

        // Literal content must not contain newline (single-line constraint)
        let content = trimmedLeft.dropFirst().dropLast()
        return !content.contains("\n")
    }
}
```

**Composite Conditions:**
1. `trimmedLeft.first == "\""`  (starts with quote)
2. `trimmedLeft.last == "\""`   (ends with quote)
3. `!content.contains("\n")`    (single-line)

**Potential Atomic Refactoring:**

```swift
struct StartsWithQuoteSpec: Specification {
    typealias Candidate = RawLine
    func isSatisfied(by candidate: RawLine) -> Bool {
        let trimmedLeft = candidate.text.drop(while: { $0 == " " })
        return trimmedLeft.first == "\""
    }
}

struct EndsWithQuoteSpec: Specification {
    typealias Candidate = RawLine
    func isSatisfied(by candidate: RawLine) -> Bool {
        let trimmedLeft = candidate.text.drop(while: { $0 == " " })
        return trimmedLeft.last == "\""
    }
}

struct QuotedContentSingleLineSpec: Specification {
    typealias Candidate = RawLine
    func isSatisfied(by candidate: RawLine) -> Bool {
        let trimmedLeft = candidate.text.drop(while: { $0 == " " })
        guard trimmedLeft.first == "\"", trimmedLeft.last == "\"" else {
            return true  // Not quoted, not our concern
        }
        let content = trimmedLeft.dropFirst().dropLast()
        return !content.contains("\n")
    }
}

// Composition
struct IsNodeLineSpec: Specification {
    typealias Candidate = RawLine
    private let spec: AnySpecification<RawLine>

    init() {
        self.spec = AnySpecification(
            StartsWithQuoteSpec()
                .and(EndsWithQuoteSpec())
                .and(QuotedContentSingleLineSpec())
        )
    }

    func isSatisfied(by candidate: RawLine) -> Bool {
        spec.isSatisfied(by: candidate)
    }
}
```

**Trade-off Analysis:**
- **Pro**: More testable (each condition tested independently)
- **Pro**: More composable (can reuse StartsWithQuoteSpec elsewhere)
- **Con**: More verbose (3 specs vs 1)
- **Con**: Duplicate logic (trimmedLeft computed multiple times)

**Recommendation**: Keep current implementation for performance. Use atomic approach if quote validation becomes more complex (e.g., supporting single quotes, backticks).

#### 4.6.2 NoTabsIndentSpec (Implicit OR in prefix)

**Current Implementation:**

```swift
struct NoTabsIndentSpec: Specification {
    typealias Candidate = RawLine

    func isSatisfied(by candidate: RawLine) -> Bool {
        let indent = candidate.text.prefix { $0 == " " || $0 == "\t" }
        return !indent.contains("\t")
    }
}
```

**Composite Condition:**
- `$0 == " " || $0 == "\t"` in closure

**Potential Refactoring:**

```swift
struct IsWhitespaceCharSpec: Specification {
    typealias Candidate = Character
    func isSatisfied(by candidate: Character) -> Bool {
        candidate == " " || candidate == "\t"
    }
}

struct ContainsTabSpec: Specification {
    typealias Candidate = String
    func isSatisfied(by candidate: String) -> Bool {
        candidate.contains("\t")
    }
}

struct NoTabsIndentSpec: Specification {
    typealias Candidate = RawLine
    func isSatisfied(by candidate: RawLine) -> Bool {
        let whitespaceSpec = IsWhitespaceCharSpec()
        let indent = candidate.text.prefix { whitespaceSpec.isSatisfied(by: $0) }
        return !ContainsTabSpec().isSatisfied(by: String(indent))
    }
}
```

**Trade-off Analysis:**
- **Pro**: Explicit whitespace definition
- **Con**: Overly complex for simple task
- **Con**: Performance overhead

**Recommendation**: Keep current implementation. The closure is idiomatic Swift and clear.

#### 4.6.3 Path Reference Detection (Example Usage)

**Current Pattern (§11.4):**

```swift
if literal.contains("/") || literal.contains(".") {
    // Validate as path
}
```

**Composite Condition:**
- `literal.contains("/") || literal.contains(".")`

**Potential Atomic Refactoring:**

```swift
struct ContainsSlashSpec: Specification {
    typealias Candidate = String
    func isSatisfied(by candidate: String) -> Bool {
        candidate.contains("/")
    }
}

struct ContainsDotSpec: Specification {
    typealias Candidate = String
    func isSatisfied(by candidate: String) -> Bool {
        candidate.contains(".")
    }
}

struct LooksLikePathSpec: Specification {
    typealias Candidate = String
    private let spec: AnySpecification<String>

    init() {
        self.spec = AnySpecification(
            ContainsSlashSpec().or(ContainsDotSpec())
        )
    }

    func isSatisfied(by candidate: String) -> Bool {
        spec.isSatisfied(by: candidate)
    }
}

// Usage
if LooksLikePathSpec().isSatisfied(by: literal) {
    // Validate as path
}
```

**Trade-off Analysis:**
- **Pro**: More descriptive name (`LooksLikePathSpec` vs inline condition)
- **Pro**: Reusable across codebase
- **Con**: May be overkill for simple heuristic

**Recommendation**: Use atomic approach if path detection becomes more sophisticated (e.g., checking for URL schemes, absolute paths).

#### 4.6.4 IsBlankLineSpec or IsCommentLineSpec (Example Usage)

**Current Pattern (§11.1):**

```swift
if IsBlankLineSpec().isSatisfied(by: rawLine) ||
   IsCommentLineSpec().isSatisfied(by: rawLine) {
    continue
}
```

**Better Pattern with OR Composition:**

```swift
struct IsSkippableLineSpec: Specification {
    typealias Candidate = RawLine
    private let spec: AnySpecification<RawLine>

    init() {
        self.spec = AnySpecification(
            IsBlankLineSpec().or(IsCommentLineSpec())
        )
    }

    func isSatisfied(by candidate: RawLine) -> Bool {
        spec.isSatisfied(by: candidate)
    }
}

// Usage
if IsSkippableLineSpec().isSatisfied(by: rawLine) {
    continue
}
```

**Benefit**: Single semantic concept ("skippable line") instead of OR condition.

#### 4.6.5 Summary Table

| Specification | Composite Condition | Atomic Refactoring Recommended? | Reason |
|---|---|---|---|
| `IsNodeLineSpec` | AND of 3 conditions | 🟡 Optional | Performance vs testability trade-off |
| `NoTabsIndentSpec` | OR in closure | ❌ No | Current impl is idiomatic and clear |
| Path detection | OR of 2 contains | 🟢 Yes, if complex | Good for sophisticated path heuristics |
| Skip blank/comment | OR of 2 specs | 🟢 Yes | Creates semantic concept |
| `IsAllowedExtensionSpec` | OR of 2 suffixes | ✅ Done | Extensibility benefit (adding new extensions) |
| `SingleLineContentSpec` | OR of 2 line breaks | ✅ Done | Cross-platform robustness |

**Design Principle**: Refactor to atomic specs when:
1. **Extensibility**: Easy to add new alternatives (extensions, formats)
2. **Reusability**: Atomic specs used in multiple places
3. **Testability**: Complex conditions need isolated testing
4. **Semantics**: Composition creates clearer domain concept

Keep composite when:
1. **Performance**: Avoiding redundant computation
2. **Simplicity**: Atomic decomposition adds more complexity than value
3. **Idioms**: Using language idioms (closures, built-ins) appropriately

-----

## 5. Composite Specifications

### 5.1 ValidNodeLineSpec

Combines all syntactic requirements for a valid node line.

```swift
struct ValidNodeLineSpec: Specification {
    typealias Candidate = RawLine

    private let spec: AnySpecification<RawLine>

    init(maxDepth: Int = 10) {
        // Compose all requirements using AND logic
        let composed = NoTabsIndentSpec()
            .and(IndentMultipleOf4Spec())
            .and(DepthWithinLimitSpec(maxDepth: maxDepth))
            .and(ValidQuotesSpec())
            .and(IsNodeLineSpec())

        self.spec = AnySpecification(composed)
    }

    func isSatisfied(by candidate: RawLine) -> Bool {
        spec.isSatisfied(by: candidate)
    }
}
```

**Usage**: Single specification to validate all syntactic properties of a node line before AST construction.

### 5.2 ValidReferencePathSpec

Combines all path safety requirements.

```swift
struct ValidReferencePathSpec: Specification {
    typealias Candidate = String  // File path

    private let spec: AnySpecification<String>

    init(rootPath: String) {
        let composed = NoTraversalSpec()
            .and(IsAllowedExtensionSpec())

        self.spec = AnySpecification(composed)
    }

    func isSatisfied(by candidate: String) -> Bool {
        spec.isSatisfied(by: candidate)
    }
}
```

**Usage**: Pre-validation before file system access in Resolver module.

### 5.3 OR Composition and Complex Logic

SpecificationCore supports full boolean algebra through composition operators.

#### 5.3.1 OR Composition Basics

```swift
// Alternative extension checking: .md OR .hc
struct MarkdownExtensionSpec: Specification {
    typealias Candidate = String
    func isSatisfied(by candidate: String) -> Bool {
        candidate.hasSuffix(".md")
    }
}

struct HypercodeExtensionSpec: Specification {
    typealias Candidate = String
    func isSatisfied(by candidate: String) -> Bool {
        candidate.hasSuffix(".hc")
    }
}

// OR composition
let allowedExtension = MarkdownExtensionSpec().or(HypercodeExtensionSpec())
```

#### 5.3.2 Complex Boolean Expressions

SpecificationCore composition operators follow boolean algebra laws:

```swift
// De Morgan's Law: NOT (A OR B) = (NOT A) AND (NOT B)
let hasLF = ContainsLFSpec()
let hasCR = ContainsCRSpec()

// These are equivalent:
let noLineBreaks1 = !(hasLF.or(hasCR))
let noLineBreaks2 = (!hasLF).and(!hasCR)

// Distributive Law: A AND (B OR C) = (A AND B) OR (A AND C)
let validIndent = IndentMultipleOf4Spec()
let shallowDepth = PredicateSpec<RawLine> { $0.text.prefix { $0 == " " }.count < 20 }
let deepDepth = PredicateSpec<RawLine> { $0.text.prefix { $0 == " " }.count >= 20 }

// Accept valid indent with either shallow or deep depth
let acceptableNode = validIndent.and(shallowDepth.or(deepDepth))
```

#### 5.3.3 Multi-Alternative Specifications

For multiple alternatives, chain OR operations:

```swift
// Accept multiple comment styles (future extension example)
struct HashCommentSpec: Specification {
    typealias Candidate = RawLine
    func isSatisfied(by candidate: RawLine) -> Bool {
        candidate.text.trimmingCharacters(in: .whitespaces).hasPrefix("#")
    }
}

struct SlashCommentSpec: Specification {
    typealias Candidate = RawLine
    func isSatisfied(by candidate: RawLine) -> Bool {
        candidate.text.trimmingCharacters(in: .whitespaces).hasPrefix("//")
    }
}

struct BlockCommentSpec: Specification {
    typealias Candidate = RawLine
    func isSatisfied(by candidate: RawLine) -> Bool {
        candidate.text.trimmingCharacters(in: .whitespaces).hasPrefix("/*")
    }
}

// Chain multiple OR operations
let anyCommentStyle = HashCommentSpec()
    .or(SlashCommentSpec())
    .or(BlockCommentSpec())
```

#### 5.3.4 Conditional Specifications

Build specifications with conditional logic using AND/OR:

```swift
// "Valid node if indented correctly OR it's a root node (depth 0)"
struct FlexibleNodeSpec: Specification {
    typealias Candidate = RawLine

    private let spec: AnySpecification<RawLine>

    init() {
        let properIndent = IndentMultipleOf4Spec()
        let isRoot = PredicateSpec<RawLine> { line in
            line.text.prefix { $0 == " " }.count == 0
        }

        // Accept if: (proper indent AND not root) OR (is root)
        // Simplified: accept if proper indent OR is root
        self.spec = AnySpecification(properIndent.or(isRoot))
    }

    func isSatisfied(by candidate: RawLine) -> Bool {
        spec.isSatisfied(by: candidate)
    }
}
```

#### 5.3.5 Practical Example: Lenient vs Strict Mode

Use OR composition to implement mode-dependent validation:

```swift
struct LenientPathSpec: Specification {
    typealias Candidate = String

    private let spec: AnySpecification<String>

    init(strict: Bool, rootPath: String) {
        if strict {
            // Strict: must pass all validations
            let composed = NoTraversalSpec()
                .and(IsAllowedExtensionSpec())
                .and(WithinRootSpec(rootPath: rootPath))
            self.spec = AnySpecification(composed)
        } else {
            // Lenient: allow more variations
            // Must not traverse, but extension can be anything
            let composed = NoTraversalSpec()
                .and(WithinRootSpec(rootPath: rootPath))
            self.spec = AnySpecification(composed)
        }
    }

    func isSatisfied(by candidate: String) -> Bool {
        spec.isSatisfied(by: candidate)
    }
}
```

**Key Insight**: OR composition enables expressing alternative validation paths, making specifications flexible enough to handle:
- Multiple valid formats (extensions, comment styles)
- Conditional rules (strict vs lenient modes)
- Defense-in-depth (checking multiple error conditions)

-----

## 6. Decision Specifications

### 6.1 LineKindDecision

Uses `FirstMatchSpec` from SpecificationCore to classify lines.

```swift
struct LineKindDecision: DecisionSpec {
    typealias Candidate = RawLine
    typealias Result = LineKind

    private let decision: FirstMatchSpec<RawLine, LineKind>

    init() {
        // Priority order: blank → comment → node
        decision = FirstMatchSpec(decisions: [
            (IsBlankLineSpec(), .blank),
            (IsCommentLineSpec(), .comment),
            (ValidNodeLineSpec(), .node)
        ])
    }

    func decide(_ candidate: RawLine) -> LineKind? {
        decision.decide(candidate)
    }
}
```

**Behavior**:
- First specification that matches determines the line kind
- If no specification matches, returns `nil` → indicates syntax error
- Priority order ensures blank lines don't get misclassified as comments

### 6.2 PathTypeDecision

Classifies path validation results.

```swift
struct PathTypeDecision: DecisionSpec {
    typealias Candidate = String  // File path
    typealias Result = PathKind

    private let decision: FirstMatchSpec<String, PathKind>

    init() {
        decision = FirstMatchSpec(decisions: [
            (IsAllowedExtensionSpec(), .allowed(extension: "")),
            // Default: forbidden
        ])
    }

    func decide(_ candidate: String) -> PathKind? {
        // Custom logic to extract extension for result
        if let result = decision.decide(candidate) {
            let ext = String(candidate.split(separator: ".").last ?? "")
            switch result {
            case .allowed:
                return .allowed(extension: ext)
            default:
                return result
            }
        }

        let ext = String(candidate.split(separator: ".").last ?? "")
        return .forbidden(extension: ext)
    }
}
```

-----

## 7. Integration Points

### 7.1 Lexer Integration

The `Lexer` class in the Parser module will use specifications for line classification.

**Before (Imperative):**

```swift
func classifyLine(_ text: String, lineNumber: Int) -> Token {
    let trimmed = text.trimmingCharacters(in: .whitespaces)

    if trimmed.isEmpty {
        return .blank
    }

    if trimmed.hasPrefix("#") {
        let indent = countIndent(text)
        return .comment(indent: indent)
    }

    // Complex quote parsing logic...
    // Indentation validation...
    // Depth checking...

    return .node(indent: indent, literal: literal)
}
```

**After (Declarative):**

```swift
import Core.Validation

final class Lexer {
    private let classifier: LineKindDecision
    private let validator: ValidNodeLineSpec

    init(maxDepth: Int = 10) {
        self.classifier = LineKindDecision()
        self.validator = ValidNodeLineSpec(maxDepth: maxDepth)
    }

    func tokenize(_ filePath: String) throws -> [Token] {
        let lines = try readLines(filePath)
        var tokens: [Token] = []

        for (lineNumber, text) in lines.enumerated() {
            let rawLine = RawLine(
                text: text,
                lineNumber: lineNumber + 1,
                filePath: filePath
            )

            // Classify line using DecisionSpec
            guard let kind = classifier.decide(rawLine) else {
                throw SyntaxError.unknownLineKind(
                    location: SourceLocation(file: filePath, line: lineNumber + 1),
                    text: text
                )
            }

            // Convert to Token
            switch kind {
            case .blank:
                tokens.append(.blank)

            case .comment:
                let indent = countIndent(text)
                tokens.append(.comment(indent: indent))

            case .node:
                // Additional validation already done by ValidNodeLineSpec in classifier
                let indent = countIndent(text)
                let literal = extractLiteral(text)
                tokens.append(.node(indent: indent, literal: literal))
            }
        }

        return tokens
    }

    private func countIndent(_ text: String) -> Int {
        text.prefix { $0 == " " }.count
    }

    private func extractLiteral(_ text: String) -> String {
        let trimmedLeft = text.drop(while: { $0 == " " })
        return String(trimmedLeft.dropFirst().dropLast())  // Remove quotes
    }
}
```

**Benefits**:
- Clear separation between classification logic (specifications) and tokenization
- Specifications can be tested independently
- Adding new line kinds requires only new specifications, not lexer rewrites

### 7.2 Parser Integration

The `Parser` class can use specifications for additional validation during AST construction.

```swift
final class Parser {
    private let depthSpec: DepthWithinLimitSpec

    init(maxDepth: Int = 10) {
        self.depthSpec = DepthWithinLimitSpec(maxDepth: maxDepth)
    }

    func parse(_ tokens: [Token], filePath: String) throws -> Program {
        var depthStack: [(node: Node, depth: Int)] = []
        var root: Node?

        for token in tokens {
            guard case .node(let indent, let literal) = token else {
                continue  // Skip blank and comment tokens
            }

            let depth = indent / 4
            let location = SourceLocation(file: filePath, line: /* ... */)

            // Validate depth using specification
            let rawLine = RawLine(
                text: String(repeating: " ", count: indent) + "\"\(literal)\"",
                lineNumber: location.line,
                filePath: filePath
            )

            guard depthSpec.isSatisfied(by: rawLine) else {
                throw ResolutionError.depthExceeded(
                    location: location,
                    depth: depth,
                    maxDepth: depthSpec.maxDepth
                )
            }

            // Continue with AST construction...
        }

        return Program(root: root!)
    }
}
```

### 7.3 Resolver Integration

The `ReferenceResolver` class will use path specifications for validation.

```swift
final class ReferenceResolver {
    private let pathValidator: ValidReferencePathSpec
    private let pathDecision: PathTypeDecision
    private let rootPath: String

    init(rootPath: String) {
        self.rootPath = rootPath
        self.pathValidator = ValidReferencePathSpec(rootPath: rootPath)
        self.pathDecision = PathTypeDecision()
    }

    func resolve(_ node: Node, context: ResolverContext) throws {
        let literal = node.literal.trimmingCharacters(in: .whitespaces)
        let fullPath = joinPath(rootPath, literal)
        let canonicalPath = canonicalize(fullPath)

        // Validate path before file system access
        guard pathValidator.isSatisfied(by: canonicalPath) else {
            // Determine specific violation
            if !NoTraversalSpec().isSatisfied(by: literal) {
                throw ResolutionError.pathTraversal(
                    location: node.location,
                    path: literal
                )
            }

            if !IsAllowedExtensionSpec().isSatisfied(by: literal) {
                let ext = String(literal.split(separator: ".").last ?? "")
                throw ResolutionError.forbiddenExtension(
                    location: node.location,
                    path: literal,
                    extension: ext
                )
            }

            throw ResolutionError.invalidPath(
                location: node.location,
                path: literal
            )
        }

        // Check if file exists
        guard fileExists(canonicalPath) else {
            if context.strict {
                throw ResolutionError.unresolvedReference(
                    location: node.location,
                    path: literal
                )
            } else {
                node.resolution = .inlineText
                return
            }
        }

        // Classify path type using DecisionSpec
        guard let pathKind = pathDecision.decide(canonicalPath) else {
            throw ResolutionError.invalidPath(
                location: node.location,
                path: literal
            )
        }

        switch pathKind {
        case .allowed(let ext):
            if ext == "md" {
                let content = try loadFile(canonicalPath, context: context)
                node.resolution = .markdownFile(path: canonicalPath, content: content)
            } else if ext == "hc" {
                // Circular dependency check using context stack
                guard !context.stack.contains(canonicalPath) else {
                    throw ResolutionError.circularDependency(
                        location: node.location,
                        cycle: context.stack + [canonicalPath]
                    )
                }

                // Recursively compile
                let childAST = try parseAndResolve(
                    canonicalPath,
                    context: context.push(canonicalPath)
                )
                node.resolution = .hypercodeFile(path: canonicalPath, ast: childAST)
            }

        case .forbidden(let ext):
            throw ResolutionError.forbiddenExtension(
                location: node.location,
                path: literal,
                extension: ext
            )

        case .invalid(let reason):
            throw ResolutionError.invalidPath(
                location: node.location,
                path: literal,
                reason: reason
            )
        }

        // Recursively resolve children
        for child in node.children {
            try resolve(child, context: context)
        }
    }
}
```

**Benefits**:
- Path validation logic is centralized and testable
- Security constraints (traversal, extension whitelist) are explicit
- Easy to add new path validation rules without touching resolver logic

-----

## 8. Testing Strategy

### 8.1 Specification Unit Tests

Each specification should have comprehensive unit tests independent of the compiler:

```swift
import XCTest
@testable import Core.Validation

final class IsBlankLineSpecTests: XCTestCase {
    let spec = IsBlankLineSpec()

    func testEmptyLine() {
        let line = RawLine(text: "", lineNumber: 1, filePath: "test.hc")
        XCTAssertTrue(spec.isSatisfied(by: line))
    }

    func testLineWithOnlySpaces() {
        let line = RawLine(text: "    ", lineNumber: 1, filePath: "test.hc")
        XCTAssertTrue(spec.isSatisfied(by: line))
    }

    func testLineWithTab() {
        let line = RawLine(text: "\t", lineNumber: 1, filePath: "test.hc")
        XCTAssertFalse(spec.isSatisfied(by: line))
    }

    func testLineWithText() {
        let line = RawLine(text: "  text  ", lineNumber: 1, filePath: "test.hc")
        XCTAssertFalse(spec.isSatisfied(by: line))
    }
}
```

### 8.2 Composition Tests

Test composite specifications to ensure correct AND/OR logic:

```swift
final class ValidNodeLineSpecTests: XCTestCase {
    let spec = ValidNodeLineSpec(maxDepth: 10)

    func testValidNodeLine() {
        let line = RawLine(
            text: "    \"valid literal\"",
            lineNumber: 1,
            filePath: "test.hc"
        )
        XCTAssertTrue(spec.isSatisfied(by: line))
    }

    func testRejectsTabIndentation() {
        let line = RawLine(
            text: "\t\"invalid indent\"",
            lineNumber: 1,
            filePath: "test.hc"
        )
        XCTAssertFalse(spec.isSatisfied(by: line))
    }

    func testRejectsMisalignedIndentation() {
        let line = RawLine(
            text: "  \"misaligned\"",
            lineNumber: 1,
            filePath: "test.hc"
        )
        XCTAssertFalse(spec.isSatisfied(by: line))
    }

    func testRejectsDepthExceeded() {
        let line = RawLine(
            text: String(repeating: " ", count: 44) + "\"too deep\"",  // depth 11
            lineNumber: 1,
            filePath: "test.hc"
        )
        XCTAssertFalse(spec.isSatisfied(by: line))
    }

    func testRejectsUnclosedQuote() {
        let line = RawLine(
            text: "    \"unclosed",
            lineNumber: 1,
            filePath: "test.hc"
        )
        XCTAssertFalse(spec.isSatisfied(by: line))
    }

    func testRejectsMultilineLiteral() {
        let line = RawLine(
            text: "    \"line1\nline2\"",
            lineNumber: 1,
            filePath: "test.hc"
        )
        XCTAssertFalse(spec.isSatisfied(by: line))
    }
}
```

**OR Composition Tests:**

```swift
final class SingleLineContentSpecTests: XCTestCase {
    let spec = SingleLineContentSpec()

    func testAcceptsSingleLineContent() {
        XCTAssertTrue(spec.isSatisfied(by: "valid single line"))
    }

    func testRejectsLF() {
        XCTAssertFalse(spec.isSatisfied(by: "line1\nline2"))
    }

    func testRejectsCR() {
        XCTAssertFalse(spec.isSatisfied(by: "line1\rline2"))
    }

    func testRejectsCRLF() {
        XCTAssertFalse(spec.isSatisfied(by: "line1\r\nline2"))
    }

    func testRejectsEmbeddedLF() {
        XCTAssertFalse(spec.isSatisfied(by: "before\nafter"))
    }
}

final class ORCompositionTests: XCTestCase {
    func testORLogicWithMultipleAlternatives() {
        let hasLF = ContainsLFSpec()
        let hasCR = ContainsCRSpec()
        let hasAny = hasLF.or(hasCR)

        // Test OR truth table
        XCTAssertFalse(hasAny.isSatisfied(by: "no breaks"))  // false OR false = false
        XCTAssertTrue(hasAny.isSatisfied(by: "has\nLF"))     // true OR false = true
        XCTAssertTrue(hasAny.isSatisfied(by: "has\rCR"))     // false OR true = true
        XCTAssertTrue(hasAny.isSatisfied(by: "both\r\n"))    // true OR true = true
    }

    func testDeMorgansLaw() {
        let hasLF = ContainsLFSpec()
        let hasCR = ContainsCRSpec()

        // NOT (A OR B) should equal (NOT A) AND (NOT B)
        let notAorB = !(hasLF.or(hasCR))
        let notA_and_notB = (!hasLF).and(!hasCR)

        let testCases = [
            "no breaks",
            "has\nLF",
            "has\rCR",
            "both\r\n"
        ]

        for testCase in testCases {
            XCTAssertEqual(
                notAorB.isSatisfied(by: testCase),
                notA_and_notB.isSatisfied(by: testCase),
                "De Morgan's Law failed for: \(testCase)"
            )
        }
    }
}
```

### 8.3 Decision Specification Tests

Test `FirstMatchSpec` priority and coverage:

```swift
final class LineKindDecisionTests: XCTestCase {
    let decision = LineKindDecision()

    func testBlankLinePriorityOverComment() {
        // Line with only spaces should be classified as blank, not comment
        let line = RawLine(text: "    ", lineNumber: 1, filePath: "test.hc")
        XCTAssertEqual(decision.decide(line), .blank)
    }

    func testCommentLine() {
        let line = RawLine(text: "# comment", lineNumber: 1, filePath: "test.hc")
        XCTAssertEqual(decision.decide(line), .comment)
    }

    func testCommentWithIndent() {
        let line = RawLine(text: "    # indented comment", lineNumber: 1, filePath: "test.hc")
        XCTAssertEqual(decision.decide(line), .comment)
    }

    func testNodeLine() {
        let line = RawLine(text: "    \"literal\"", lineNumber: 1, filePath: "test.hc")
        XCTAssertEqual(decision.decide(line), .node)
    }

    func testInvalidLineReturnsNil() {
        // Line that matches no specification
        let line = RawLine(text: "    invalid syntax", lineNumber: 1, filePath: "test.hc")
        XCTAssertNil(decision.decide(line))
    }
}
```

### 8.4 Integration Tests

Verify that specifications integrate correctly with compiler modules:

```swift
final class LexerIntegrationTests: XCTestCase {
    func testValidHypercodeFile() throws {
        let source = """
        # Comment
        "Root"
            "Child 1"
            "Child 2"
        """

        let tempFile = createTempFile(content: source)
        let lexer = Lexer(maxDepth: 10)
        let tokens = try lexer.tokenize(tempFile)

        XCTAssertEqual(tokens.count, 4)  // comment + 3 nodes

        guard case .comment = tokens[0] else {
            XCTFail("Expected comment token")
            return
        }

        guard case .node(let indent1, let literal1) = tokens[1] else {
            XCTFail("Expected node token")
            return
        }
        XCTAssertEqual(indent1, 0)
        XCTAssertEqual(literal1, "Root")
    }

    func testTabIndentationThrowsError() {
        let source = "\t\"Invalid\""
        let tempFile = createTempFile(content: source)
        let lexer = Lexer(maxDepth: 10)

        XCTAssertThrowsError(try lexer.tokenize(tempFile)) { error in
            guard case SyntaxError.tabInIndentation = error else {
                XCTFail("Expected tabInIndentation error")
                return
            }
        }
    }
}
```

-----

## 9. Benefits of Integration

### 9.1 Declarative Rule Expression

Specifications make validation rules explicit and self-documenting:

**Before:**
```swift
// What does this check?
if text.prefix(while: { $0 == " " }).count % 4 != 0 {
    throw SyntaxError.invalidIndent
}
```

**After:**
```swift
// Clear intent
guard IndentMultipleOf4Spec().isSatisfied(by: line) else {
    throw SyntaxError.invalidIndent
}
```

### 9.2 Testability

Specifications can be tested in isolation without instantiating the full compiler:

```swift
// Test a single rule without Parser, Lexer, or file I/O
func testDepthLimit() {
    let spec = DepthWithinLimitSpec(maxDepth: 10)
    let validLine = RawLine(text: String(repeating: " ", count: 40) + "\"ok\"", ...)
    let invalidLine = RawLine(text: String(repeating: " ", count: 44) + "\"bad\"", ...)

    XCTAssertTrue(spec.isSatisfied(by: validLine))
    XCTAssertFalse(spec.isSatisfied(by: invalidLine))
}
```

### 9.3 Composition and Reusability

Build complex validations from simple primitives using AND/OR/NOT operators:

**AND Composition (all must pass):**

```swift
// Compose multiple rules with clear semantics
let strictNodeValidator = NoTabsIndentSpec()
    .and(IndentMultipleOf4Spec())
    .and(DepthWithinLimitSpec(maxDepth: 10))
    .and(ValidQuotesSpec())
    .and(IsNodeLineSpec())

// Reuse in different contexts
let lenientNodeValidator = IndentMultipleOf4Spec()
    .and(ValidQuotesSpec())
    .and(IsNodeLineSpec())
```

**OR Composition (at least one must pass):**

```swift
// Accept multiple valid extensions
let markdownExt = PredicateSpec<String> { $0.hasSuffix(".md") }
let hypercodeExt = PredicateSpec<String> { $0.hasSuffix(".hc") }
let allowedExtensions = markdownExt.or(hypercodeExt)

// Accept multiple comment styles (future feature)
let hashComment = PredicateSpec<RawLine> { $0.text.trimmed().hasPrefix("#") }
let slashComment = PredicateSpec<RawLine> { $0.text.trimmed().hasPrefix("//") }
let anyComment = hashComment.or(slashComment)
```

**NOT Composition (must not match):**

```swift
// Reject any line break type
let hasLF = ContainsLFSpec()
let hasCR = ContainsCRSpec()
let hasAnyBreak = hasLF.or(hasCR)
let singleLineOnly = !hasAnyBreak
```

**Complex Boolean Expressions:**

```swift
// (valid indent AND proper quotes) OR is root node
let validIndent = IndentMultipleOf4Spec()
let properQuotes = ValidQuotesSpec()
let isRoot = PredicateSpec<RawLine> {
    $0.text.prefix { $0 == " " }.count == 0
}

let acceptableNode = (validIndent.and(properQuotes)).or(isRoot)
```

### 9.4 Extensibility

Adding new syntax features requires only new specifications:

**Example: Future feature — node annotations**

```swift
// New specification for annotated nodes
struct IsAnnotatedNodeSpec: Specification {
    typealias Candidate = RawLine

    func isSatisfied(by candidate: RawLine) -> Bool {
        let trimmed = candidate.text.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("@") && trimmed.contains("\"")
    }
}

// Extend LineKindDecision without modifying existing specs
enum LineKind {
    case blank
    case comment
    case node
    case annotatedNode  // New kind
}

struct ExtendedLineKindDecision: DecisionSpec {
    // ...
    init() {
        decision = FirstMatchSpec(decisions: [
            (IsBlankLineSpec(), .blank),
            (IsCommentLineSpec(), .comment),
            (IsAnnotatedNodeSpec(), .annotatedNode),  // Higher priority
            (ValidNodeLineSpec(), .node)
        ])
    }
}
```

### 9.5 Error Diagnostics

Specifications can provide detailed failure reasons:

```swift
struct DiagnosticSpec<T>: Specification {
    let inner: AnySpecification<T>
    let failureMessage: (T) -> String

    func isSatisfied(by candidate: T) -> Bool {
        let result = inner.isSatisfied(by: candidate)
        if !result {
            print("Validation failed: \(failureMessage(candidate))")
        }
        return result
    }
}

// Usage
let spec = DiagnosticSpec(
    inner: AnySpecification(DepthWithinLimitSpec(maxDepth: 10)),
    failureMessage: { line in
        "Line \(line.lineNumber): Depth \(line.text.prefix { $0 == " " }.count / 4) exceeds maximum of 10"
    }
)
```

-----

## 10. Implementation Checklist

### Phase 1: Foundation (Estimated 4 hours)

- [ ] Add SpecificationCore dependency to Package.swift
- [ ] Create Core.Validation module structure
- [ ] Define domain types: `RawLine`, `LineKind`, `ParsedLine`, `PathKind`
- [ ] Write unit tests for domain types

### Phase 2: Line Specifications (Estimated 6 hours)

- [ ] Implement `IsBlankLineSpec` with tests
- [ ] Implement `IsCommentLineSpec` with tests
- [ ] Implement `IsNodeLineSpec` with tests
- [ ] Implement `ValidQuotesSpec` with tests
- [ ] Implement `SingleLineContentSpec` with tests

### Phase 3: Indentation & Depth Specifications (Estimated 4 hours)

- [ ] Implement `NoTabsIndentSpec` with tests
- [ ] Implement `IndentMultipleOf4Spec` with tests
- [ ] Implement `DepthWithinLimitSpec` with tests
- [ ] Implement `ValidNodeLineSpec` (composite) with tests

### Phase 4: Path Specifications (Estimated 4 hours)

- [ ] Implement `IsAllowedExtensionSpec` with tests
- [ ] Implement `NoTraversalSpec` with tests
- [ ] Implement `WithinRootSpec` with tests
- [ ] Implement `ValidReferencePathSpec` (composite) with tests

### Phase 5: Decision Specifications (Estimated 4 hours)

- [ ] Implement `LineKindDecision` with `FirstMatchSpec`
- [ ] Implement `PathTypeDecision`
- [ ] Write comprehensive decision tests
- [ ] Verify priority ordering in `FirstMatchSpec`

### Phase 6: Lexer Integration (Estimated 6 hours)

- [ ] Refactor Lexer to use `LineKindDecision`
- [ ] Replace imperative validation with `ValidNodeLineSpec`
- [ ] Update error messages to reference specification failures
- [ ] Verify all existing lexer tests pass
- [ ] Add new integration tests

### Phase 7: Resolver Integration (Estimated 6 hours)

- [ ] Refactor ReferenceResolver to use path specifications
- [ ] Replace imperative path validation with `ValidReferencePathSpec`
- [ ] Update error messages for specification failures
- [ ] Verify all existing resolver tests pass
- [ ] Add new integration tests

### Phase 8: Documentation & Examples (Estimated 3 hours)

- [ ] Document all specification classes with examples
- [ ] Create example usage guide for future extensions
- [ ] Update architecture diagrams to show specification integration
- [ ] Document testing strategy and patterns

**Total Estimated Effort:** 37 hours (~5 days)

-----

## 11. Example Usage Scenarios

### 11.1 Validating a Hypercode File

```swift
import Core.Validation

func validateHypercodeFile(_ filePath: String) throws {
    let lines = try readLines(filePath)
    let validator = ValidNodeLineSpec(maxDepth: 10)

    for (lineNumber, text) in lines.enumerated() {
        let rawLine = RawLine(
            text: text,
            lineNumber: lineNumber + 1,
            filePath: filePath
        )

        // Skip blank lines and comments
        if IsBlankLineSpec().isSatisfied(by: rawLine) ||
           IsCommentLineSpec().isSatisfied(by: rawLine) {
            continue
        }

        // Validate node line
        guard validator.isSatisfied(by: rawLine) else {
            // Determine specific violation
            if !NoTabsIndentSpec().isSatisfied(by: rawLine) {
                throw ValidationError.tabsInIndentation(line: lineNumber + 1)
            }
            if !IndentMultipleOf4Spec().isSatisfied(by: rawLine) {
                throw ValidationError.misalignedIndentation(line: lineNumber + 1)
            }
            if !DepthWithinLimitSpec().isSatisfied(by: rawLine) {
                throw ValidationError.depthExceeded(line: lineNumber + 1)
            }
            throw ValidationError.invalidNodeLine(line: lineNumber + 1)
        }
    }
}
```

### 11.2 Classifying Lines

```swift
func classifyAndProcess(_ filePath: String) throws {
    let lines = try readLines(filePath)
    let classifier = LineKindDecision()

    for (lineNumber, text) in lines.enumerated() {
        let rawLine = RawLine(
            text: text,
            lineNumber: lineNumber + 1,
            filePath: filePath
        )

        guard let kind = classifier.decide(rawLine) else {
            throw ParseError.unknownLineKind(
                file: filePath,
                line: lineNumber + 1,
                text: text
            )
        }

        switch kind {
        case .blank:
            print("Line \(lineNumber + 1): Blank")
        case .comment:
            print("Line \(lineNumber + 1): Comment")
        case .node:
            let literal = extractLiteral(text)
            print("Line \(lineNumber + 1): Node — \"\(literal)\"")
        }
    }
}
```

### 11.3 Validating File Paths

```swift
func validateReferencePaths(_ nodes: [Node], rootPath: String) throws {
    let pathValidator = ValidReferencePathSpec(rootPath: rootPath)
    let pathDecision = PathTypeDecision()

    for node in nodes {
        let literal = node.literal.trimmingCharacters(in: .whitespaces)
        let fullPath = joinPath(rootPath, literal)

        // Pre-validate path
        guard pathValidator.isSatisfied(by: literal) else {
            if !NoTraversalSpec().isSatisfied(by: literal) {
                throw ValidationError.pathTraversal(node: node, path: literal)
            }
            if !IsAllowedExtensionSpec().isSatisfied(by: literal) {
                throw ValidationError.forbiddenExtension(node: node, path: literal)
            }
            throw ValidationError.invalidPath(node: node, path: literal)
        }

        // Classify path type
        guard let pathKind = pathDecision.decide(fullPath) else {
            throw ValidationError.invalidPath(node: node, path: literal)
        }

        switch pathKind {
        case .allowed(let ext):
            print("Valid reference: \(literal) (.\(ext))")
        case .forbidden(let ext):
            throw ValidationError.forbiddenExtension(
                node: node,
                path: literal,
                extension: ext
            )
        case .invalid(let reason):
            throw ValidationError.invalidPath(
                node: node,
                path: literal,
                reason: reason
            )
        }

        // Recursively validate children
        try validateReferencePaths(node.children, rootPath: rootPath)
    }
}
```

### 11.4 Custom Validation Pipeline

```swift
// Build a custom validation pipeline for specific use cases
struct StrictHypercodeValidator {
    let lineValidator: ValidNodeLineSpec
    let pathValidator: ValidReferencePathSpec
    let depthLimit: Int

    init(rootPath: String, depthLimit: Int = 10) {
        self.depthLimit = depthLimit
        self.lineValidator = ValidNodeLineSpec(maxDepth: depthLimit)
        self.pathValidator = ValidReferencePathSpec(rootPath: rootPath)
    }

    func validate(_ filePath: String) throws {
        let lines = try readLines(filePath)
        let classifier = LineKindDecision()

        for (lineNumber, text) in lines.enumerated() {
            let rawLine = RawLine(
                text: text,
                lineNumber: lineNumber + 1,
                filePath: filePath
            )

            guard let kind = classifier.decide(rawLine) else {
                throw ValidationError.invalidSyntax(
                    file: filePath,
                    line: lineNumber + 1
                )
            }

            if case .node = kind {
                // Additional strict validation
                guard lineValidator.isSatisfied(by: rawLine) else {
                    throw ValidationError.invalidNodeLine(
                        file: filePath,
                        line: lineNumber + 1
                    )
                }

                // Extract and validate path if it looks like a reference
                let literal = extractLiteral(text)
                if literal.contains("/") || literal.contains(".") {
                    guard pathValidator.isSatisfied(by: literal) else {
                        throw ValidationError.invalidReference(
                            file: filePath,
                            line: lineNumber + 1,
                            path: literal
                        )
                    }
                }
            }
        }
    }
}
```

-----

## 12. Future Extensions

### 12.1 Context-Aware Specifications

For future versions with dynamic behavior (v0.2+):

```swift
import SpecificationCore

struct MaxNestingInContextSpec: Specification {
    typealias Candidate = RawLine

    let contextProvider: DefaultContextProvider
    let maxDepth: Int

    func isSatisfied(by candidate: RawLine) -> Bool {
        let context = contextProvider.context
        let currentDepth = candidate.text.prefix { $0 == " " }.count / 4

        // Check against global max
        guard currentDepth <= maxDepth else { return false }

        // Check against context-specific limits (from cascade sheets)
        if let contextMax = context.counters["maxDepth"] {
            return currentDepth <= contextMax
        }

        return true
    }
}
```

### 12.2 Metadata Annotations

For annotated nodes (potential v0.3+ feature):

```swift
struct NodeMetadataSpec: Specification {
    typealias Candidate = RawLine

    func isSatisfied(by candidate: RawLine) -> Bool {
        let trimmed = candidate.text.trimmingCharacters(in: .whitespaces)

        // Pattern: @metadata(key=value) "literal"
        guard trimmed.hasPrefix("@") else { return false }
        guard let metadataEnd = trimmed.firstIndex(of: ")") else { return false }
        guard let quoteStart = trimmed[trimmed.index(after: metadataEnd)...].firstIndex(of: "\"") else {
            return false
        }

        return true
    }
}
```

### 12.3 Performance Optimizations

Cache compiled specifications for reuse:

```swift
final class SpecificationCache {
    private var cache: [String: AnySpecification<RawLine>] = [:]

    func getOrCreate(
        key: String,
        factory: () -> AnySpecification<RawLine>
    ) -> AnySpecification<RawLine> {
        if let cached = cache[key] {
            return cached
        }

        let spec = factory()
        cache[key] = spec
        return spec
    }
}

// Usage
let cache = SpecificationCache()
let validator = cache.getOrCreate(key: "validNodeLine") {
    AnySpecification(ValidNodeLineSpec(maxDepth: 10))
}
```

-----

## 13. Alternatives Considered

### 13.1 Parser Combinators

**Approach**: Use a parser combinator library (e.g., SwiftParsec) for line parsing.

**Pros**:
- Composable grammar definitions
- Built-in error handling

**Cons**:
- Overcomplicated for line-by-line lexing
- Worse error messages for end users
- Additional dependency

**Decision**: Rejected. Hypercode grammar is simple enough for hand-written parser. SpecificationCore provides sufficient composition for validation without parser combinator complexity.

### 13.2 Regex-Based Validation

**Approach**: Use regular expressions for line classification and validation.

**Pros**:
- Compact syntax for simple patterns
- Built into Swift standard library

**Cons**:
- Poor readability for complex rules
- Difficult to compose (cannot AND/OR regex easily)
- Weak error diagnostics
- Hard to test individual rules

**Decision**: Rejected. SpecificationCore provides better composition, testability, and error reporting.

### 13.3 Schema Validation (JSON Schema / Similar)

**Approach**: Define Hypercode grammar as a schema and validate against it.

**Pros**:
- Declarative grammar definition
- Tooling support for schema languages

**Cons**:
- Hypercode is not a data format (it's a syntax tree)
- Schema languages designed for nested data, not indentation-based syntax
- Additional complexity for line-by-line processing

**Decision**: Rejected. Schema validation is not a good fit for indentation-based languages.

### 13.4 No Abstraction (Imperative Validation)

**Approach**: Keep all validation as imperative if/else logic in Lexer and Resolver.

**Pros**:
- No additional dependencies
- Straightforward implementation

**Cons**:
- Validation logic scattered across modules
- Difficult to test individual rules in isolation
- Poor extensibility for future features
- Hard to document business rules

**Decision**: Rejected. SpecificationCore provides significant maintainability and extensibility benefits for minimal cost.

-----

## 14. Dependencies

### 14.1 SpecificationCore

**Repository**: https://github.com/SoundBlaster/SpecificationCore
**Version**: Latest stable (recommend pinning to specific version)
**License**: MIT

**Package.swift Integration**:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Hyperprompt",
    platforms: [
        .macOS(.v12),
        .linux
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-crypto", from: "3.0.0"),
        .package(url: "https://github.com/SoundBlaster/SpecificationCore", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                "SpecificationCore"
            ]
        ),
        .target(
            name: "Parser",
            dependencies: ["Core"]
        ),
        .target(
            name: "Resolver",
            dependencies: ["Core", "Parser"]
        ),
        // ... other targets
    ]
)
```

### 14.2 Versioning Strategy

- Use semantic versioning for SpecificationCore dependency
- Pin to specific minor version to avoid breaking changes
- Review changelog before updating dependency
- Run full test suite after any dependency update

-----

## 15. Migration Path

### 15.1 Incremental Adoption

SpecificationCore can be integrated incrementally without rewriting the entire compiler:

**Phase 1**: Add dependency and domain types (no behavior changes)
**Phase 2**: Integrate specifications in Lexer (replace line classification logic)
**Phase 3**: Integrate specifications in Resolver (replace path validation logic)
**Phase 4**: Refactor error handling to use specification failures

Each phase should maintain full backward compatibility with existing tests.

### 15.2 Backward Compatibility

All existing tests must pass after each integration phase:

```bash
# Run before and after each phase
swift test --enable-code-coverage
swift test --filter LexerTests
swift test --filter ResolverTests
swift test --filter IntegrationTests
```

### 15.3 Performance Benchmarks

Measure compilation performance before and after integration:

```swift
func benchmark(name: String, iterations: Int = 100, block: () throws -> Void) {
    let start = Date()
    for _ in 0..<iterations {
        try? block()
    }
    let duration = Date().timeIntervalSince(start)
    print("\(name): \(duration / Double(iterations) * 1000)ms per iteration")
}

// Before integration
benchmark(name: "Lexer (imperative)") {
    _ = try Lexer().tokenize("test.hc")
}

// After integration
benchmark(name: "Lexer (specification)") {
    _ = try Lexer().tokenize("test.hc")
}
```

**Acceptance Criteria**: Specification-based implementation should not add more than 10% overhead compared to imperative implementation.

-----

## 16. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.0.1 | 2025-12-02 | Egor Merkushev | Initial SpecificationCore integration design |

-----

## 17. References

- **PRD v0.0.1**: `00_PRD_001.md` — Product requirements and success criteria
- **Design Spec v0.0.1**: `01_DESIGN_SPEC_001.md` — Compiler architecture and algorithms
- **SpecificationCore**: https://github.com/SoundBlaster/SpecificationCore
- **Specification Pattern**: Martin Fowler, https://martinfowler.com/apsupp/spec.pdf

-----

## Appendix A: Complete Specification List

### Line Specifications
| Specification | Validates | Exit Code |
|---|---|---|
| `IsBlankLineSpec` | Line contains only spaces | N/A |
| `IsCommentLineSpec` | Line is a comment (starts with #) | N/A |
| `IsNodeLineSpec` | Line is a valid node (quoted literal) | N/A |
| `ValidQuotesSpec` | Quotes are balanced and closed | 2 |
| `ContainsLFSpec` | String contains LF (`\n`) | N/A |
| `ContainsCRSpec` | String contains CR (`\r`) | N/A |
| `SingleLineContentSpec` | Literal does not span multiple lines (composite with OR) | 2 |

### Indentation Specifications
| Specification | Validates | Exit Code |
|---|---|---|
| `NoTabsIndentSpec` | No tabs in indentation | 2 |
| `IndentMultipleOf4Spec` | Indentation divisible by 4 | 2 |

### Depth Specifications
| Specification | Validates | Exit Code |
|---|---|---|
| `DepthWithinLimitSpec` | Depth <= 10 | 3 |

### Path Specifications
| Specification | Validates | Exit Code |
|---|---|---|
| `HasMarkdownExtensionSpec` | Extension is .md | N/A |
| `HasHypercodeExtensionSpec` | Extension is .hc | N/A |
| `IsAllowedExtensionSpec` | Extension is .md or .hc (composite with OR) | 3 |
| `NoTraversalSpec` | No `..` in path | 3 |
| `WithinRootSpec` | Path resolves within root | 3 |

### Composite Specifications
| Specification | Combines | Purpose |
|---|---|---|
| `ValidNodeLineSpec` | All line + indent + depth specs (AND) | Complete node validation |
| `ValidReferencePathSpec` | All path safety specs (AND) | Complete path validation |
| `SingleLineContentSpec` | `ContainsLFSpec` OR `ContainsCRSpec` (then NOT) | Multi-platform line break detection |
| `IsAllowedExtensionSpec` | `HasMarkdownExtensionSpec` OR `HasHypercodeExtensionSpec` | Extensible file type validation |

### Decision Specifications
| Specification | Returns | Purpose |
|---|---|---|
| `LineKindDecision` | `LineKind` | Classify line type |
| `PathTypeDecision` | `PathKind` | Classify path type |

-----

## Appendix B: Error Code Mapping

| Specification Failure | Error Type | Exit Code | Example |
|---|---|---|---|
| `NoTabsIndentSpec` | Syntax Error | 2 | `\t"literal"` |
| `IndentMultipleOf4Spec` | Syntax Error | 2 | `  "misaligned"` |
| `ValidQuotesSpec` | Syntax Error | 2 | `"unclosed` |
| `SingleLineContentSpec` | Syntax Error | 2 | `"line1\nline2"` or `"line1\rline2"` or `"line1\r\nline2"` |
| `DepthWithinLimitSpec` | Resolution Error | 3 | 44 spaces (depth 11) |
| `NoTraversalSpec` | Resolution Error | 3 | `"../etc/passwd"` |
| `IsAllowedExtensionSpec` | Resolution Error | 3 | `"file.txt"` |
| `WithinRootSpec` | Resolution Error | 3 | Symlink outside root |

-----

**End of Document**
