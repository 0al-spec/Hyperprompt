# Hyperprompt Compiler v0.1 — Design Specification

**Document Version:** 0.0.1
**Date:** November 25, 2025
**Author:** Egor Merkushev
**Status:** Draft for Implementation

-----

## 1. Purpose

This document defines **how** Hyperprompt Compiler v0.1 will be implemented. While the PRD (00_PRD_001.md) states **what** must happen, the Design Spec establishes the architecture, algorithms, data structures, and operational semantics necessary for a correct implementation.

### 1.1 Related Design Documents

**Specification Pattern Integration**: This design spec is complemented by [02_DESIGN_SPEC_SPECIFICATION_CORE.md](./02_DESIGN_SPEC_SPECIFICATION_CORE.md), which defines the integration of the SpecificationCore library for implementing validation and classification logic.

**Key approach**: Rather than implementing grammar validation as scattered imperative checks throughout the compiler, we use the Specification Pattern to create an executable representation of the Hypercode EBNF grammar. This is achieved through the **HypercodeGrammar** module—a separate Swift package depending on SpecificationCore that contains all grammar rules as composable specification objects.

**Organization**: Specifications are organized by linguistic levels:
- **Lexical** (terminal symbols): character-level checks for whitespace, line breaks, quotes
- **Syntactic** (non-terminal symbols): line and node structure validation
- **Semantic** (business rules): security policies, depth limits, path validation

**Core concepts**:
- **Atomic specifications**: Single-purpose validators (e.g., `ContainsLFSpec`, `HasMarkdownExtensionSpec`)
- **Composition**: Complex rules built using `.and()`, `.or()`, and `!` operators
- **Decision specifications**: `FirstMatchSpec` implements EBNF alternations (e.g., `line = blank | comment | node`)
- **Semantic naming**: Specifications use domain-focused names that explain intent (e.g., `ContainsPathSeparatorSpec` rather than `ContainsSlashSpec`)

**Benefits**:
- **Single source of truth**: Grammar lives in one module, not scattered across compiler code
- **Testability**: Each specification can be unit-tested independently
- **Extensibility**: Adding new language features (e.g., annotations) requires only grammar changes
- **Versioning**: Grammar module can evolve independently of compiler implementation

-----

## 2. High‑Level Architecture

### 2.1 Module Organization

The compiler is organized into six functional modules:

**Core Module**
- `SourceLocation`: File path + line number
- `Diagnostic`: Error message + category
- `CompilerError`: Protocol for all error types
- `FileSystem`: Abstraction for file I/O
  - `LocalFileSystem`: Production implementation
  - `MockFileSystem`: Testing implementation
- Utilities: path canonicalization, SHA256 computation, string helpers

**Parser Module**
- `Lexer`: Line-by-line tokenization
- `Token`: Classified input (blank, comment, node)
- `Parser`: AST construction from token stream
- `Node`: AST element (literal, depth, children, location)
- `Program`: Root AST container

**Resolver Module**
- `ReferenceResolver`: Classify literals as file references or inline text
- `DependencyTracker`: Circular dependency detection with visitation stack
- `FileLoader`: Read files, compute SHA256, cache content
- `ResolverContext`: Maintain state during resolution traversal

**Emitter Module**
- `MarkdownEmitter`: Tree traversal, heading generation, content embedding
- `HeadingAdjuster`: ATX and Setext heading level transformation
- `SeparatorPolicy`: Blank line insertion between sections
- `BoldFallbackProcessor`: Convert deep headings (depth >= 6) to bold text

**Manifest Module**
- `ManifestEntry`: Single source file metadata
- `ManifestBuilder`: Collect entries during compilation
- `ManifestWriter`: Serialize and write JSON

**CLI Module**
- Uses `swift-argument-parser` for command structure
- `CompilerDriver`: Orchestrate parse → resolve → emit → manifest pipeline
- `DiagnosticPrinter`: Format errors with location + context
- Argument validation and defaults

**Statistics Module**
- `StatsCollector`: Track metrics during compilation
- `StatsReporter`: Format and output statistics

-----

## 3. Data Structures

### 3.1 Node (AST Element)

```swift
struct Node {
    let literal: String              // Raw quoted content
    let depth: Int                   // Indentation / 4
    let location: SourceLocation     // Source file + line
    var children: [Node]             // Nested nodes
    var resolution: ResolutionKind?  // Determined during resolution phase
}
```

### 3.2 ResolutionKind (Semantic Classification)

```swift
enum ResolutionKind {
    case inlineText                          // Literal not matching any file
    case markdownFile(path: String, content: String)  // .md file content
    case hypercodeFile(path: String, ast: Node)       // Recursively compiled .hc
    case forbidden(extension: String)        // Disallowed extension
}
```

### 3.3 Manifest Model

```swift
struct ManifestEntry: Codable {
    let path: String        // Relative to root
    let sha256: String      // Lowercase hex
    let size: Int           // Bytes
    let type: SourceType    // "markdown" or "hypercode"
}

enum SourceType: String, Codable {
    case markdown = "markdown"
    case hypercode = "hypercode"
}

struct Manifest: Codable {
    let timestamp: String       // ISO 8601
    let version: String         // Compiler version
    let root: String            // Input file path
    let sources: [ManifestEntry]
}
```

### 3.4 Token (Lexer Output)

```swift
enum Token {
    case blank
    case comment(indent: Int)
    case node(indent: Int, literal: String)
}
```

-----

## 4. Algorithms

### 4.1 Parsing Algorithm

**Input:** Path to `.hc` file
**Output:** `Program` (single-rooted AST)

```
parse(filePath):
    lines ← readLines(filePath, UTF-8)
    tokens ← []
    for each line with lineNum:
        if isBlank(line):
            tokens.append(Token.blank)
        else if isComment(line):
            indent ← countIndent(line)
            tokens.append(Token.comment(indent))
        else:
            indent ← countIndent(line)
            validate(indent % 4 == 0) else error(MisalignedIndentation)
            validate(no tabs) else error(TabInIndentation)
            literal ← extractLiteral(line)
            validate(literal.hasClosingQuote) else error(UnclosedQuote)
            tokens.append(Token.node(indent, literal))

    // Build tree from tokens
    depthStack ← []
    root ← null

    for each token:
        if node:
            depth ← token.indent / 4
            node ← Node(literal, depth, location)

            // Pop stack until we find parent
            while depthStack.notEmpty and depthStack.top.depth >= depth:
                depthStack.pop()

            if depthStack.empty:
                // Trying to create root node
                validate(root == null) else error(MultipleRoots, exit 2)
                root ← node
            else:
                depthStack.top.children.append(node)

            depthStack.push(node)

    validate(root != null) else error(NoRootNode, exit 2)
    return Program(root)
```

**Line Ending Handling:**
- Parser internally uses LF for all line-based operations
- When reading source files, normalize CRLF/CR to LF immediately in `readLines()`
- Line numbering and error reporting use normalized line count
- No impact on syntax (lexer is line-ending agnostic after normalization)

**Error Conditions:**
- Tabs in indentation → **Syntax Error (exit 2)**
- Indentation not divisible by 4 → **Syntax Error (exit 2)**
- Missing closing quote → **Syntax Error (exit 2)**
- Literal spans multiple lines → **Syntax Error (exit 2)**
- Multiple root nodes (depth 0) → **Syntax Error (exit 2)**
- No root node found → **Syntax Error (exit 2)**

---

### 4.2 Reference Resolution Algorithm

**Input:** AST `Node`, root directory, `strict` flag, visitation stack
**Output:** `Node` with `resolution` field populated

```
resolve(node, root, strict, stack, fileCache):
    validate(node.depth <= 10) else error(DepthExceeded, exit 3)

    literal ← node.literal.trim()
    path ← canonicalize(joinPath(root, literal))

    validate(pathWithinRoot(path, root)) else error(PathTraversal, exit 3)

    if pathExists(path):
        ext ← getExtension(path)

        if ext == ".md":
            content ← loadFile(path, fileCache, stack)
            node.resolution ← ResolutionKind.markdownFile(path, content)

        else if ext == ".hc":
            validate(path not in stack) else error(CircularDependency, exit 3)

            newStack ← stack + [path]
            childAST ← parse(path)
            resolveTree(childAST, root, strict, newStack, fileCache)

            node.resolution ← ResolutionKind.hypercodeFile(path, childAST)

        else:
            // All other extensions forbidden
            error(ForbiddenExtension(ext), exit 3)

    else:
        // File does not exist
        if strict:
            error(UnresolvedReference(literal), exit 3)
        else:
            node.resolution ← ResolutionKind.inlineText

    // Recursively resolve children
    for child in node.children:
        resolve(child, root, strict, stack, fileCache)
```

**Circular Dependency Detection:**
- Stack contains canonical absolute paths of files being processed.
- Before resolving `.hc` reference, check if target path is already in stack.
- If yes, report full cycle path in error message.

**Path Validation:**
- Reject paths containing `..` component that would escape root.
- Reject symlinks pointing outside root.
- All paths canonicalized to absolute form.

**File Caching:**
- During loading, store content + SHA256 hash.
- Avoid redundant reads for same file.

---

### 4.3 Markdown Emission Algorithm

**Input:** Resolved AST `Node`, depth stack
**Output:** Markdown string

```
emit(node, parentDepth, output):
    // Calculate effective depth: parent's embedding depth + node's depth
    effectiveDepth ← parentDepth + node.depth

    // Determine heading with effective depth
    headingLevel ← effectiveDepth + 1

    if effectiveDepth >= 6:
        title ← "**" + node.literal + "**"
    else:
        hashes ← repeat("#", headingLevel)
        title ← hashes + " " + node.literal

    output.append(title)
    output.append("\n")

    // Emit content based on resolution
    if node.resolution == ResolutionKind.markdownFile:
        content ← node.resolution.content
        adjusted ← adjustHeadings(content, effectiveDepth + 1)
        output.append(adjusted)

    else if node.resolution == ResolutionKind.hypercodeFile:
        childAST ← node.resolution.ast
        for child in childAST.children:
            emit(child, effectiveDepth, output)  // Pass effective depth to children

    // Emit children
    for i, child in node.children:
        if i > 0:
            output.append("\n")  // Blank line between siblings
        emit(child, effectiveDepth, output)  // Pass effective depth to children
```

**Heading Adjustment:**

```
adjustHeadings(content, offset):
    result ← ""
    for each line:
        if isATXHeading(line):
            level ← countHashes(line)
            newLevel ← min(level + offset, 6)

            if newLevel > 6:
                line ← "**" + extractHeadingText(line) + "**"
            else:
                hashes ← repeat("#", newLevel)
                line ← hashes + " " + extractHeadingText(line)

        else if isSetextHeading(line, nextLine):
            level ← getSetextLevel(nextLine)
            newLevel ← min(level + offset, 6)

            if newLevel > 6:
                line ← "**" + line.trim() + "**"
                skip nextLine
            else:
                newUnderline ← repeat("=", length) or repeat("-", length)
                line ← line + "\n" + newUnderline

        result.append(line)

    return result
```

**Separator Insertion:**
- One blank line between consecutive sibling nodes.
- Two blank lines before H1/H2 headings (except at document start).

**Determinism and Normalization:**
- Line ending normalization happens during `loadFile()` (parser §4.1)
- All embedded markdown content is normalized to LF before heading adjustment
- Final output ensured to have exactly one trailing LF
- No platform-specific line ending handling
- All content uses Unix-style LF line endings regardless of source or platform

---

### 4.4 Manifest Generation

During file loading (in `FileLoader`):

```
loadFile(path, cache, stack):
    if path in cache:
        return cache[path].content

    content ← readFile(path, UTF-8)
    hash ← SHA256(content)

    entry ← ManifestEntry(
        path: relativeToRoot(path),
        sha256: hash.hex(),
        size: content.length,
        type: getSourceType(path)
    )

    manifestBuilder.add(entry)
    cache[path] ← (content, hash)

    return content
```

After emission:

```
writeManifest(outputPath):
    manifest ← Manifest(
        timestamp: now().iso8601(),
        version: COMPILER_VERSION,
        root: rootInputPath,
        sources: manifestBuilder.entries.sorted(by: path)
    )

    json ← jsonEncode(manifest)
    writeFile(outputPath, json)
```

**JSON Output Format:**
- Manifest JSON keys are alphabetically sorted for stable, deterministic output
- All timestamps are ISO 8601 format
- Manifest file ends with exactly one LF
- No pretty-printing customization (single-line or compact format for stability)

-----

## 5. CLI Design

### 5.1 Command Structure

```swift
@main
struct Hyperprompt: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Compile Hypercode to Markdown"
    )

    @Argument(help: "Input Hypercode file")
    var input: String

    @Option(name: [.short, .long], help: "Output Markdown file")
    var output: String?

    @Option(name: [.short, .long], help: "Manifest file")
    var manifest: String?

    @Option(name: [.short, .long], help: "Root directory for references")
    var root: String?

    @Flag(help: "Strict mode (default)")
    var strict: Bool = true

    @Flag(help: "Lenient mode")
    var lenient: Bool = false

    @Flag(help: "Print statistics")
    var stats: Bool = false

    @Flag(help: "Validate without writing")
    var dryRun: Bool = false

    @Flag(name: [.short, .long], help: "Verbose logging")
    var verbose: Bool = false
}
```

### 5.2 Execution Flow

```
main():
    args ← parseArguments()

    // Validate arguments
    validate(not (strict and lenient)) else error
    output ← args.output ?? replaceExt(args.input, ".md")
    manifest ← args.manifest ?? output + ".manifest.json"
    root ← args.root ?? dirname(args.input)

    // Create file system
    fs ← LocalFileSystem()

    // Create driver
    driver ← CompilerDriver(fs, strict: !args.lenient, verbose: args.verbose)

    try:
        result ← driver.compile(
            inputPath: args.input,
            outputPath: output,
            manifestPath: manifest,
            rootPath: root
        )

        if not args.dryRun:
            writeFile(output, result.markdown)
            writeFile(manifest, result.manifestJson)

        if args.stats:
            printStats(result.stats)

        exit(0)

    catch error as CompilerError:
        diagnosticPrinter.print(error, to: stderr)
        exit(error.exitCode)

    catch error:
        diagnosticPrinter.print(InternalError(error), to: stderr)
        exit(4)
```

-----

## 6. Error Handling

### 6.1 Error Protocol

```swift
protocol CompilerError: Error {
    var message: String { get }
    var location: SourceLocation? { get }
    var exitCode: Int { get }
}
```

### 6.2 Error Categories

| Error Type | Exit Code | Category |
|---|---|---|
| FileNotFound, PermissionDenied | 1 | IO Error |
| TabInIndentation, MisalignedIndentation, UnclosedQuote | 2 | Syntax Error |
| UnresolvedReference, CircularDependency, DepthExceeded, PathTraversal, ForbiddenExtension | 3 | Resolution Error |
| Internal, Panic | 4 | Internal Error |

### 6.3 Diagnostic Format

```
<file>:<line>: error: <message>
    context line
    ^^^
```

Printed to `stderr`.

-----

## 7. Statistics Collection

If `--stats` flag:

```
StatsCollector:
    - numHypercodeFiles: count of .hc files
    - numMarkdownFiles: count of .md files
    - totalInputBytes: sum of all file sizes
    - outputBytes: size of compiled .md
    - maxDepth: deepest node in tree
    - durationMs: elapsed time
```

Output format:
```
Compilation Statistics:
  Source files:   18
  Input size:     125 KB
  Output size:    42 KB
  Max depth:      7
  Time:           342 ms
```

-----

## 8. File System Rules (Implementation)

### 8.1 Path Handling

1. **Canonicalization:**
   - Resolve `..` components.
   - Normalize separators to `/` internally.
   - Convert to absolute path.

2. **Root Validation:**
   - All resolved paths must be within or below root.
   - Reject attempts to escape with `..`.

3. **Symlink Policy:**
   - Do not follow symlinks pointing outside root.
   - Report as unresolved reference if would escape.

### 8.2 Extension Validation

Only two extensions allowed:
- `.md` → embed as Markdown, adjust headings
- `.hc` → recursively parse and compile

All others → **hard error (exit 3)**.

### 8.3 File Encoding

- Input: UTF-8 without BOM
- Output: UTF-8 (standard Markdown)
- No encoding conversions performed.

-----

## 9. Extensibility & Future Directions

### 9.1 Design for v0.2+

**Cascade Sheets (.hcs):**
- Separate metadata file per `.hc`.
- Embedding mode overrides (inline vs. section).
- Property propagation to children.

**Node Selectors:**
- Address specific nodes in tree by path.
- Extract subtree for partial compilation.

**Incremental Compilation:**
- Hash-based change detection.
- Reuse manifest to skip unchanged files.

### 9.2 Parallelization

Current design is stateless within each `.hc` subtree:
- `.hc` files can be compiled independently (after resolution).
- Manifest can be merged from parallel branches.

Future: Concurrent resolution of independent subtrees.

-----

## 10. Example: End-to-End Compilation

### Input Directory
```
root/
├── main.hc
├── intro.md
└── chapters/
    ├── ch1.hc
    └── content.md
```

### main.hc
```hypercode
# Main Document
"Main Document"
    "intro.md"
    "Chapters"
        "chapters/ch1.hc"
```

### chapters/ch1.hc
```hypercode
"Chapter 1"
    "content.md"
```

### Execution
```
$ hyperprompt root/main.hc --root root --output main.compiled.md --stats
```

### Parse Phase
```
Program(
  Node(literal="Main Document", depth=0)
    Node(literal="intro.md", depth=1)
    Node(literal="Chapters", depth=1)
      Node(literal="chapters/ch1.hc", depth=2)
)
```

### Resolve Phase
- `main.hc` → inlineText
- `intro.md` → markdownFile(path, content)
- `chapters/ch1.hc` → hypercodeFile(path, ast)
- Recursively resolve `ch1.hc` subtree

### Emit Phase
```markdown
# Main Document

## intro.md heading
...

## Chapters

### Chapter 1

#### content.md heading
...
```

### Manifest
```json
{
  "version": "0.1",
  "timestamp": "2025-11-25T10:30:00Z",
  "root": "main.hc",
  "sources": [
    {
      "path": "main.hc",
      "sha256": "abc123...",
      "size": 128,
      "type": "hypercode"
    },
    {
      "path": "intro.md",
      "sha256": "def456...",
      "size": 2048,
      "type": "markdown"
    },
    {
      "path": "chapters/ch1.hc",
      "sha256": "ghi789...",
      "size": 256,
      "type": "hypercode"
    },
    {
      "path": "chapters/content.md",
      "sha256": "jkl012...",
      "size": 4096,
      "type": "markdown"
    }
  ]
}
```

-----

## 11. Revision

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.0.1 | 2025-11-25 | Egor Merkushev | Initial design specification |
