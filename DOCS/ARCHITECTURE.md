# Architecture and System Design

High-level overview of Hyperprompt compiler architecture, module relationships, and data flow.

## Table of Contents

1. [System Overview](#system-overview)
2. [Module Structure](#module-structure)
3. [Data Flow](#data-flow)
4. [Key Components](#key-components)
5. [Design Patterns](#design-patterns)
6. [Extension Points](#extension-points)

---

## System Overview

Hyperprompt is a multi-stage compiler that transforms Hypercode files into Markdown documents with manifest generation.

### Compilation Pipeline

```
┌──────────────────────────────────────────────────────────┐
│ Input: root.hc file                                      │
└──────────────────┬───────────────────────────────────────┘
                   │
        ┌──────────▼───────────┐
        │  1. CLI (Argument    │
        │     Parsing)         │
        │  ↓                   │
        │  Parsed Arguments    │
        └──────────┬───────────┘
                   │
        ┌──────────▼───────────┐
        │  2. Parser           │
        │  (Syntax Analysis)   │
        │  ↓                   │
        │  Abstract Syntax     │
        │  Tree (AST)          │
        └──────────┬───────────┘
                   │
        ┌──────────▼───────────┐
        │  3. Resolver         │
        │  (Reference Res.)    │
        │  ↓                   │
        │  Resolved AST        │
        │  + Dependencies      │
        └──────────┬───────────┘
                   │
        ┌──────────▼───────────┐
        │  4. Emitter          │
        │  (Code Generation)   │
        │  ↓                   │
        │  Markdown Content    │
        └──────────┬───────────┘
                   │
        ┌──────────▼────────────────────────┐
        │  5. Output                         │
        │  ├── out.md (Markdown)             │
        │  └── manifest.json (Metadata)      │
        └─────────────────────────────────────┘
```

---

## Module Structure

```
Sources/
├── CLI/
│   ├── Command.swift              Main CLI interface (ArgumentParser)
│   └── ArgumentParsing.swift      Argument validation logic
│
├── Core/
│   ├── Errors.swift               Error types and exit codes
│   ├── Types.swift                Basic types (Node, Token, etc.)
│   └── Statistics.swift           Compilation metrics
│
├── Parser/
│   ├── Lexer.swift                Tokenization
│   ├── Parser.swift               AST construction
│   └── ParserTests/               Unit tests
│
├── Resolver/
│   ├── ReferenceResolver.swift    File reference resolution
│   ├── DependencyTracker.swift    Circular dependency detection
│   └── ResolverTests/             Unit tests
│
├── Emitter/
│   ├── MarkdownEmitter.swift      AST → Markdown conversion
│   └── EmitterTests/              Unit tests
│
├── HypercodeGrammar/
│   ├── Specifications.swift       Declarative validation specs
│   └── HypercodeGrammarTests/     Specification tests
│
├── Statistics/
│   ├── StatisticsCollector.swift  Metrics collection
│   └── StatisticsTests/           Unit tests
│
└── IntegrationTests/
    └── Fixtures/                  Test data
        ├── Valid/V01.hc...V17.hc
        └── Invalid/I01.hc...I10.hc
```

### Module Dependencies

```
CLI
  ↓
Core
  ├← Parser
  ├← Resolver
  ├← Emitter
  └← Statistics

Parser → HypercodeGrammar
Resolver → HypercodeGrammar
Emitter → (no further deps)
```

---

## Data Flow

### Phase 1: CLI & Arguments

```
User Input
    ↓
hyperprompt root.hc --output out.md --manifest meta.json --lenient
    ↓
ArgumentParser (swift-argument-parser)
    ├─ Validate argument types
    ├─ Enforce mutual exclusivity (strict XOR lenient)
    └─ Create CompilerArguments struct
```

**Output:** `CompilerArguments` containing:
- `input: String` — Input file path
- `output: String` — Output file path (default: `out.md`)
- `manifest: String` — Manifest path (default: `manifest.json`)
- `root: String` — Root directory (default: `.`)
- `mode: CompilationMode` — Strict or lenient
- `verbose, stats, dryRun: Bool` — Flags

### Phase 2: Reading Input

```
Input file path
    ↓
FileManager.default.contents(atPath:)
    ↓
Raw bytes
    ↓
String(decoding:as:)  — UTF-8 decoding
    ↓
Source code string
```

### Phase 3: Parsing

```
Source Code String
    ↓
Lexer (Character-by-character analysis)
  ├─ Tokenize lines
  ├─ Identify node types (text, reference)
  ├─ Track indentation levels
  └─ Produce Token stream
    ↓
Parser (Token analysis)
  ├─ Validate syntax (quotes, indentation)
  ├─ Build hierarchical structure
  ├─ Apply grammar specifications
  └─ Produce Abstract Syntax Tree (AST)
    ↓
AST (Hierarchical representation)
```

**AST Node Structure:**
```swift
class Node {
    let literal: String              // Quoted content
    let depth: Int                   // Nesting level (0 = root)
    let isReference: Bool            // Is this a file reference?
    var children: [Node] = []        // Child nodes
    var lineNumber: Int              // For error reporting
}
```

### Phase 4: Resolution

```
AST + Input metadata
    ↓
Resolver (Reference processing)
  ├─ For each Node:
  │  ├─ Check if file reference (heuristic)
  │  ├─ Validate path (no traversal attacks)
  │  ├─ Check file type (.md or .hc)
  │  ├─ Handle missing files (strict vs lenient)
  │  └─ For .hc files: Recursively parse
  │
  ├─ DependencyTracker
  │  ├─ Track visited files
  │  └─ Detect cycles
  │
  └─ Produce Resolved AST
    ↓
Resolved AST (with embedded referenced content)
```

### Phase 5: Emission

```
Resolved AST
    ↓
Emitter (AST → Markdown)
  ├─ Convert nodes to headings
  │  ├─ Depth → Heading level (depth 0 = #, depth 1 = ##, etc.)
  │  └─ Preserve content
  │
  ├─ Embed file content
  │  └─ Maintain heading hierarchy
  │
  └─ Generate Markdown
    ↓
Markdown String
```

**Example Conversion:**
```
AST:
  Node(literal: "Title", depth: 0)
    Node(literal: "Section", depth: 1)
      Node(literal: "Subsection", depth: 2)

→

Markdown:
# Title
## Section
### Subsection
```

### Phase 6: Statistics Collection

```
Throughout pipeline
    ↓
StatisticsCollector
  ├─ Lines processed
  ├─ Nodes in AST
  ├─ Max nesting depth
  ├─ Files referenced
  ├─ Compilation time
  └─ Output size
    ↓
Statistics report (optional with --stats flag)
```

### Phase 7: Output

```
Markdown String + Statistics + Dependencies
    ↓
┌─────────────────────────────────────────┐
│ Output Generation                       │
├─────────────────────────────────────────┤
│ ├─ Write Markdown to --output file      │
│ ├─ Generate manifest.json               │
│ ├─ Report statistics (if --stats)       │
│ └─ Print results (if --verbose)         │
└─────────────────────────────────────────┘
    ↓
Exit with code 0 (success) or 1-4 (error)
```

---

## Key Components

### 1. Parser Module

**Responsibility:** Parse Hypercode syntax into AST

**Key Functions:**
- `func parse(_ source: String) throws -> Node`
- `func tokenize(_ source: String) -> [Token]`
- `func validateSyntax(_ tokens: [Token]) throws`

**Uses Specifications:**
- `IsBlankLineSpec` — Identify blank lines
- `HasQuotesSpec` — Validate string boundaries
- `IndentationMultipleOf4Spec` — Ensure 4-space indentation

### 2. Resolver Module

**Responsibility:** Resolve file references recursively

**Key Functions:**
- `func resolve(_ node: Node) throws -> ResolutionResult`
- `func resolveFile(_ path: String) throws -> String`
- `func containsPathTraversal(_ path: String) -> Bool`

**Uses Specifications:**
- `LooksLikeFileReferenceSpec` — Heuristic path detection
- `HasMarkdownExtensionSpec` — Detect `.md` files
- `HasHypercodeExtensionSpec` — Detect `.hc` files
- `NoTraversalSpec` — Prevent `..` escaping
- `WithinRootSpec` — Enforce root boundary

**DependencyTracker:**
- Maintains visited files set
- Tracks file→file references
- Detects circular dependencies

### 3. Emitter Module

**Responsibility:** Convert resolved AST to Markdown

**Key Functions:**
- `func emit(_ node: Node, maxDepth: Int) -> String`
- `func headingFromDepth(_ depth: Int) -> String`
- `func escapeMarkdown(_ text: String) -> String`

**Handles:**
- Heading level calculation
- Content escaping
- Hierarchy preservation

### 4. HypercodeGrammar Module

**Responsibility:** Declarative specification-based validation

**Specifications:**
- **Lexical:** Quote matching, indentation rules
- **Structural:** Nesting levels, depth limits
- **Semantic:** File type validation, path security

**Pattern:** Each validation rule is a `Specification` object with `isSatisfiedBy(_:) -> Bool` method

---

## Design Patterns

### 1. Specification Pattern (SpecificationCore Integration)

Each validation rule is a reusable specification:

```swift
protocol Specification {
    func isSatisfiedBy(_ candidate: String) -> Bool
}

// Examples:
struct HasMarkdownExtensionSpec: Specification {
    func isSatisfiedBy(_ path: String) -> Bool {
        path.lowercased().hasSuffix(".md")
    }
}

struct NoTraversalSpec: Specification {
    func isSatisfiedBy(_ path: String) -> Bool {
        !path.contains("..")
    }
}
```

**Benefits:**
- Composable: Combine multiple specs
- Testable: Each spec independently testable
- Maintainable: Business logic isolated
- Declarative: Reads like requirements

### 2. Visitor Pattern

AST traversal uses visitor pattern (implicit in recursive functions):

```swift
func visitNode(_ node: Node, depth: Int, visitor: NodeVisitor) {
    visitor.visit(node, depth: depth)
    for child in node.children {
        visitNode(child, depth: depth + 1, visitor: visitor)
    }
}
```

### 3. Strategy Pattern

Different resolution strategies for different file types:

```swift
switch fileExtension {
case ".md":
    return try resolveMarkdown(literal, node: node)
case ".hc":
    return try resolveHypercode(literal, node: node)
default:
    throw ResolutionError.forbiddenExtension(ext)
}
```

### 4. Error Handling Strategy

- **Lexical errors:** Throw immediately (fail-fast)
- **Syntax errors:** Report with line numbers
- **Resolution errors:** Provide context and suggestions
- **Exit codes:** Standardized (0-4) for scripting

---

## Extension Points

### Adding New Specifications

1. **Create specification in HypercodeGrammar:**
   ```swift
   struct MyValidationSpec: Specification {
       func isSatisfiedBy(_ candidate: String) -> Bool {
           // Custom validation logic
       }
   }
   ```

2. **Use in parser or resolver:**
   ```swift
   if !MyValidationSpec().isSatisfiedBy(value) {
       throw ParserError.validationFailed
   }
   ```

### Adding New File Types

Currently supported: `.md`, `.hc`

To add `.txt` support:

1. **Create specification:**
   ```swift
   struct HasTextExtensionSpec: Specification {
       func isSatisfiedBy(_ path: String) -> Bool {
           path.lowercased().hasSuffix(".txt")
       }
   }
   ```

2. **Update resolver:**
   ```swift
   if HasTextExtensionSpec().isSatisfiedBy(literal) {
       return resolveText(literal, node: node)
   }
   ```

3. **Implement resolution:**
   ```swift
   private func resolveText(_ path: String, node: Node) throws -> ResolutionResult {
       let content = try readFile(path)
       return .success(.text(content))
   }
   ```

### Adding Custom Output Formats

Current: Markdown only

To add JSON output:

1. **Create JSON emitter:**
   ```swift
   class JSONEmitter {
       func emit(_ node: Node) -> String {
           // Convert AST to JSON
       }
   }
   ```

2. **Add CLI flag:**
   ```swift
   @Option(name: .shortAndLong, help: "Output format: markdown, json")
   var format: String = "markdown"
   ```

3. **Update driver:**
   ```swift
   let output = format == "json"
       ? JSONEmitter().emit(ast)
       : MarkdownEmitter().emit(ast)
   ```

---

## Performance Characteristics

| Operation | Complexity | Notes |
|-----------|-----------|-------|
| Parsing | O(n) | Linear in source size |
| Resolution | O(n + m) | n=nodes, m=files |
| Circular detection | O(m² × d) | m=files, d=avg depth |
| Emission | O(n) | Linear in AST size |
| **Total** | **O(n + m²)** | Dominated by file I/O |

**Optimization opportunities:**
1. Cache parsed ASTs for repeated files
2. Parallel file reading
3. Lazy evaluation for large references
4. Memoization of specification checks

---

## Security Considerations

### Path Traversal Protection

All file paths validated against:
1. **NoTraversalSpec:** Rejects `..` components
2. **WithinRootSpec:** Enforces `--root` boundary
3. **Extension whitelist:** Only `.md` and `.hc`

### Access Control

- Only reads files (no modifications outside output)
- Output files created in specified directory
- Respects file permissions (fails on permission denied)

### Input Validation

- All user input validated before use
- Indentation checked for malformed nesting
- Quote matching verified (no injection attacks)

---

## Error Recovery

**Strategy:** Fail-fast for syntax errors, detailed reporting

1. **Parse-time:** Stop on first syntax error
2. **Resolution-time:** Stop on first missing file (strict) or continue (lenient)
3. **Emission-time:** Rare; includes context if occurs
4. **Output-time:** Report I/O errors with paths

---

## Future Enhancements

### Planned for v0.2+

1. **Caching:**
   - Cache parsed ASTs
   - Invalidate on file change

2. **Parallel Processing:**
   - Parse multiple files concurrently
   - Resolve references in parallel

3. **Additional Formats:**
   - HTML output
   - PDF via pandoc
   - DOCX

4. **Advanced Features:**
   - Template system
   - Macro expansion
   - Conditional inclusion

5. **Tooling:**
   - Language server (LSP)
   - Editor plugins
   - Linter/formatter
   - EditorEngine module for editor integrations (planned, see `DOCS/PRD/PRD_EditorEngine.md`)

---

## See Also

- [SPECS_INTEGRATION.md](SPECS_INTEGRATION.md) — Specification usage details
- [LANGUAGE.md](LANGUAGE.md) — Grammar and syntax
- [USAGE.md](USAGE.md) — CLI interface

---

**Last Updated:** December 12, 2025
