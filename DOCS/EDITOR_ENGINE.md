# EditorEngine — API Reference & Usage Guide

EditorEngine is an optional, trait-gated module that exposes IDE/editor-friendly APIs on top of the deterministic Hyperprompt compiler. It provides parsing with link spans, link resolution, editor compilation, and diagnostics mapping without introducing new language semantics.

---

## Build & Availability

EditorEngine is gated by the SwiftPM `Editor` trait and is not included in default builds.

- Build without EditorEngine:
  - `swift build`
- Build with EditorEngine:
  - `swift build --traits Editor`

---

## API Overview

### Project Indexing

- `EditorEngine.indexProject(workspaceRoot:options:) -> ProjectIndex`
- `ProjectIndex` provides deterministic listing of `.hc` and `.md` files.

Example:

```swift
import EditorEngine

let index = try EditorEngine.indexProject(workspaceRoot: "/path/to/workspace")
print("Found \(index.totalFiles) files")
```

### Parsing & Link Spans

- `EditorParser.parse(filePath:) -> ParsedFile` (returns diagnostics for I/O failures)
- `ParsedFile` includes `ast`, `linkSpans`, and `diagnostics`.

Example:

```swift
let parsed = EditorParser.parse(filePath: "main.hc")
for span in parsed.linkSpans {
    print("Link: \(span.literal) at \(span.lineRange)")
}
```

### Link Resolution

- `EditorResolver.resolve(link:) -> ResolutionResult`
- `ResolvedTarget` provides inline/markdown/hypercode/forbidden/invalid/ambiguous outcomes.

Example:

```swift
let resolver = EditorResolver(workspaceRoot: "/workspace")
let result = resolver.resolve(link: parsed.linkSpans[0])
print(result.target)
```

### Compilation

- `EditorCompiler.compile(entryFile:options:) -> CompileResult`
- `CompileOptions` controls mode, roots, and output handling.
- `CompileResult` contains `output`, `manifest`, `statistics`, and `diagnostics`.

Example:

```swift
let compiler = EditorCompiler()
let result = compiler.compile(entryFile: "main.hc")
if let output = result.output {
    print(output)
}
```

### Diagnostics Mapping

- `DiagnosticMapper.map(_:) -> Diagnostic`
- `Diagnostic` includes code, severity, message, and range.

Example:

```swift
if let error = result.diagnostics.first {
    let diagnostic = DiagnosticMapper.map(error)
    print("\(diagnostic.code): \(diagnostic.message)")
}
```

---

## Data Types

### LinkSpan

- `literal`: raw literal content
- `byteRange`: UTF-8 byte offsets (0-based)
- `lineRange` / `columnRange`: 1-based ranges
- `isFileReference`: heuristic flag

### ResolvedTarget

- `.inlineText`
- `.markdownFile(path:)`
- `.hypercodeFile(path:)`
- `.forbidden(extension:)`
- `.invalid(reason:)`
- `.ambiguous(candidates:)`

### CompileOptions

- `mode`: strict or lenient resolution
- `workspaceRoot`: optional root override
- `outputPath` / `manifestPath`: optional output overrides
- `emitManifest`: include manifest in results
- `collectStats`: include statistics
- `writeOutput`: write files to disk

### Diagnostic

- `code`: error code (E001/E100/E200/E900)
- `severity`: error/warning/info/hint
- `message`: diagnostic message
- `range`: optional line/column range

---

## Integration Patterns

### 3-Column Editor

1. Index workspace with `ProjectIndexer`
2. Parse active file with `EditorParser`
3. Resolve links with `EditorResolver`
4. Compile with `EditorCompiler` and show preview

### Live Preview Loop

1. On file change, parse + resolve
2. Compile in dry-run mode
3. Update preview only if output changes

### Hover/Peek Definition

1. Use `linkSpans` to find the hovered literal
2. Resolve with `EditorResolver`
3. Navigate to resolved path or show ambiguity

---

## Notes

- All APIs are deterministic and platform-stable.
- EditorEngine is experimental until v1.0.
- Some integration tests are skipped due to known compiler issues; see test notes.
