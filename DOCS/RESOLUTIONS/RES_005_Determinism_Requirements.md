# Resolution #5: Determinism Requirements Incomplete

**Status:** RESOLVED
**Date:** December 2, 2025

## Problem

The PRD specifies that output must be "byte-for-byte stable" (deterministic), but several critical details are missing:

1. **Line Endings:** Should output use LF, CRLF, or platform-specific?
2. **Trailing Newline:** Should compiled .md end with newline?
3. **Manifest JSON Ordering:** Should keys be sorted for stable hashing?
4. **Content Normalization:** Should embedded markdown be normalized to LF?

**Example Issue:**
- Input .md file uses CRLF (Windows-style)
- Embedded into output with headings adjusted
- Result depends on platform line-ending handling
- **Not deterministic** if implementation doesn't normalize

## Decision: Strict Determinism Standards

**Rationale:**
1. **Cross-Platform Reproducibility:** Same input must produce identical output on any OS
2. **Version Control:** Deterministic output enables proper git tracking
3. **LLM Integration:** LLMs require stable prompts for reproducible responses
4. **Manifest Integrity:** Hash-based provenance needs sorted keys

## Specifications

### 1. Line Endings: Always LF

**Standard:**
- All output files (.md and .json) use **LF (Unix-style) line endings**
- **Platform:** Not affected by OS (even on Windows, output is LF)
- **Embedded Content:** All embedded markdown content normalized to LF during processing

**Implementation:**
```swift
// Normalize input content to LF before processing
normalizeLineEndings(content: String) -> String {
    return content
        .replacingOccurrences(of: "\r\n", with: "\n")  // CRLF → LF
        .replacingOccurrences(of: "\r", with: "\n")    // CR → LF
}

// Apply when loading .md files for embedding
content ← normalizeLineEndings(loadFile(path))
```

**Impact:**
- Compiled .md output always has LF
- Manifest JSON always has LF in string fields
- Binary hash (SHA256) matches exactly across all platforms

### 2. Trailing Newline: Single LF

**Standard:**
- Compiled markdown output ends with exactly **one LF character**
- No trailing blank lines
- No platform-specific handling

**Example:**
```markdown
# Document
## Section
Content here.
<LF>
```
(ends with single newline, no extra blank lines)

**Implementation:**
```swift
// After emit() completes, ensure exactly one trailing LF
output.ensureSingleTrailingNewline()

// Equivalent to:
if output.isEmpty:
    output ← ""
else if !output.endsWith("\n"):
    output.append("\n")
else if output.endsWith("\n\n"):
    // Remove excess trailing newlines
    while output.endsWith("\n\n"):
        output ← output.dropLast()
        output.append("\n")
```

### 3. Manifest JSON: Sorted Keys

**Standard:**
- All JSON keys in manifest are **alphabetically sorted**
- Arrays preserve insertion order (not sorted)
- Ensures stable hash of manifest file

**Example (Manifest):**
```json
{
  "root": "main.hc",
  "sources": [ ... ],
  "timestamp": "2025-11-25T10:30:00Z",
  "version": "0.1"
}
```

Keys are sorted: root, sources, timestamp, version (✓ alphabetical)

**Implementation:**
```swift
// When building manifest JSON, use sorted key order
struct Manifest: Codable {
    let version: String
    let timestamp: String
    let root: String
    let sources: [Source]

    // Swift's Codable with explicit key ordering via CodingKeys
    enum CodingKeys: String, CodingKey {
        case root = "root"
        case sources = "sources"
        case timestamp = "timestamp"
        case version = "version"
    }

    // Encode in sorted key order
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(root, forKey: .root)
        try container.encode(sources, forKey: .sources)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(version, forKey: .version)
    }
}
```

### 4. Embedded Content: Normalized

**Standard:**
- All content from embedded .md files normalized to LF
- Heading lines normalized (e.g., `--- ` setext underlines)
- Whitespace preserved exactly otherwise

**Processing:**
```swift
// For each embedded .md file:
content ← loadFile(path)
content ← normalizeLineEndings(content)
// Then pass to adjustHeadings() and emit()
```

**Heading-Specific Handling:**
- Setext-style underline detection must work with LF only
- Pattern: `---+` or `===+` on line following heading
- After normalization, these patterns are LF-terminated

## Changes Required

### PRD (00_PRD_001.md)

**Section 4.2 Reliability - ADD:**
```markdown
### 4.2 Reliability
- No crashes on invalid input.
- Every error must have location + diagnostic.
- **Deterministic output:** All compilation produces byte-for-byte identical output for identical input, regardless of platform or execution order.
  - All output uses LF (Unix-style) line endings
  - Compiled markdown ends with exactly one LF
  - Manifest JSON keys are alphabetically sorted
  - Embedded content normalized to LF before processing
```

**Section 1.3 Objectives - CLARIFY:**
Current: "Produces deterministic output (byte-for-byte stable)"
Updated: "Produces deterministic output (byte-for-byte stable across all platforms)"

### Design Spec (01_DESIGN_SPEC_001.md)

**Section 4.3 Markdown Emission Algorithm - ADD subsection:**
```markdown
**Determinism and Normalization:**
- Line ending normalization happens during `loadFile()`
- All embedded markdown content is normalized to LF before heading adjustment
- Final output ensured to have exactly one trailing LF
- No platform-specific line ending handling
```

**Section 3.3 Manifest Generation - ADD subsection:**
```markdown
**JSON Output Format:**
- Keys are sorted alphabetically for stable output
- Manifest.json has exactly one trailing LF
- No pretty-printing or customization (stable format)
```

**Section 4.1 Parser - ADD note:**
```markdown
**Line Ending Handling:**
- Parser internally uses LF for all line-based operations
- When reading source files, normalize CRLF/CR to LF immediately
- No impact on syntax (lexer is line-ending agnostic)
```

## Implementation Checklist

**Parser (4.1):**
- [ ] `loadFile()` normalizes line endings to LF
- [ ] All internal line tracking uses LF

**Resolver (4.2):**
- [ ] Markdown content normalized to LF when loaded
- [ ] No line-ending specific logic in path validation

**Emitter (4.3):**
- [ ] Heading adjustment works correctly with LF
- [ ] Output ends with exactly one LF
- [ ] `adjustHeadings()` preserves normalized content

**Manifest (4.4):**
- [ ] JSON encoder produces sorted keys
- [ ] Manifest ends with single LF
- [ ] All timestamps formatted as ISO 8601

## Test Impact

**Existing Tests:**
- V01-V14: Output verified against golden files with LF endings
- I01-I10: Error messages use LF endings

**New Determinism Tests (future):**
- Test that compiled output matches golden file byte-for-byte
- Test that CRLF input produces same LF output
- Test that recompilation produces identical manifest

## Acceptance Criteria Impact

**Updated:**
- ✅ Output byte-for-byte stable across all platforms (LF line endings)
- ✅ Trailing whitespace deterministic (exactly one LF)
- ✅ Manifest JSON deterministic (sorted keys)
- ✅ Embedded content normalized consistently (no line-ending variations)
