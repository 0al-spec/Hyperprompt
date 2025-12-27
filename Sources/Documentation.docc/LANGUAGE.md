# Hypercode Language Specification

Complete grammar and syntax specification for the Hypercode language.

## Table of Contents

1. [Overview](#overview)
2. [Grammar (EBNF)](#grammar-ebnf)
3. [File Structure](#file-structure)
4. [Node Types](#node-types)
5. [Syntax Rules](#syntax-rules)
6. [Examples](#examples)
7. [Error Scenarios](#error-scenarios)

---

## Overview

Hypercode is a declarative, indentation-based language for defining hierarchical document structures. Files are compiled into Markdown with file references resolved recursively.

**File Extension:** `.hc`

**Purpose:** Define nested sections and include files for document generation

**Design Principles:**
- Simple syntax with minimal cognitive load
- Indentation-based nesting (like Python)
- Explicit file references for composition
- Deterministic output across platforms

---

## Grammar (EBNF)

```ebnf
(* Hypercode Grammar *)

file = { whitespace } document-node { whitespace }

document-node = node { node }

node = indentation node-literal line-ending
       [ nested-nodes ]

nested-nodes = { child-node }

child-node = increased-indentation node-literal line-ending
             [ nested-nodes ]

indentation = 0*( SPACE SPACE SPACE SPACE )
              (* 0 to N groups of 4 spaces *)

increased-indentation = indentation SPACE SPACE SPACE SPACE
                        (* Previous indentation + 4 more spaces *)

node-literal = quoted-string
             | comment

quoted-string = DQUOTE string-content DQUOTE

string-content = { printable-char }

comment = "#" { printable-char }

printable-char = ( %x20 / %x21 / %x23-7E )
                 (* Printable ASCII except quote and hash *)

line-ending = LF / CRLF / ( CR LF )
              (* Unix (LF), Windows (CRLF), Mac (CR LF) *)

whitespace = blank-line / comment-line

blank-line = [ SPACE / TAB ]* line-ending

comment-line = [ SPACE / TAB ]* comment line-ending
```

### Grammar Notes

- **Indentation:** Exactly 4 spaces per level. Tabs not allowed.
- **Nesting:** Children must increase indentation by exactly 4 spaces
- **Quotes:** String content enclosed in double quotes
- **References:** Detected via heuristics (contains `/` or `.`)
- **Line Endings:** LF (Unix), CRLF (Windows), CR LF (Mac) all supported

---

## File Structure

### Root Node

Every Hypercode file must have a root node (no indentation).

```
"Root Document"
    "Child 1"
    "Child 2"
```

### Hierarchy Levels

Depth is controlled by indentation:

```
"Level 0"              (* 0 spaces *)
    "Level 1"          (* 4 spaces *)
        "Level 2"      (* 8 spaces *)
            "Level 3"  (* 12 spaces *)
```

### Blank Lines

Blank lines and comment lines are ignored:

```
"Section 1"

    "Subsection"    (* Blank line above is ignored *)

# This is a comment

    "Another item"
```

---

## Node Types

Each node contains exactly one literal string.

### Inline Text

Literal text content (no special characters indicating files):

```
"Hello World"
"This is a document section"
"Chapter 3: Advanced Topics"
```

When compiled to Markdown, inline text becomes heading:
```markdown
# Hello World
## This is a document section
### Chapter 3: Advanced Topics
```

### Markdown File References

Path to `.md` file (detected by `.md` extension):

```
"Introduction"
    "docs/intro.md"
```

Compiler:
1. Reads `docs/intro.md`
2. Includes content inline under "Introduction" heading
3. Adjusts heading depth for nesting

### Hypercode File References

Path to `.hc` file (detected by `.hc` extension):

```
"Main Document"
    "chapters/chapter1.hc"
    "chapters/chapter2.hc"
```

Compiler:
1. Recursively parses each `.hc` file
2. Merges AST into parent at specified depth
3. Tracks visited files (circular dependency detection)

### Path Heuristics

File references are detected when literal contains:
- `/` (path separator) — indicates a file path
- `.` (extension separator) — indicates a filename with extension
- Both combined — most reliable

Examples of detected references:
```
"path/to/file.md"       (* Both / and . *)
"file.md"               (* Extension *)
"folder/file"           (* Path separator *)
"docs"                  (* Common directory name - may be reference *)
```

Examples NOT detected as references (inline text):
```
"Hello World"           (* No / or . *)
"Section 2.5"           (* Looks like numbering, not extension *)
"Example: test"         (* No / or . *)
```

---

## Syntax Rules

### Indentation

**Rules:**
1. Must use spaces only (tabs forbidden)
2. Each level must be exactly 4 spaces more than parent
3. Root level has 0 spaces indentation
4. Blank lines can have any amount of whitespace (ignored)

**Valid:**
```
"Root"
    "Child"
        "Grandchild"
```

**Invalid (tabs):**
```
"Root"
→"Child"    (* Tab character - ERROR *)
```

**Invalid (wrong spaces):**
```
"Root"
  "Child"   (* Only 2 spaces - ERROR *)
```

**Invalid (mixed):**
```
"Root"
    "Child"
      "Grandchild"  (* 6 spaces instead of 8 - ERROR *)
```

### Quotes

**Rules:**
1. String content enclosed in double quotes `"`
2. Opening and closing quotes must match
3. Quotes must be on same line
4. No escaping within strings

**Valid:**
```
"Simple text"
"Text with numbers 123"
"Path with slashes: section/file.md"
```

**Invalid (unclosed):**
```
"Missing closing quote
```

**Invalid (mismatched):**
```
'Single quotes not allowed'
```

**Invalid (newline in string):**
```
"Text spanning
multiple lines"
```

### Line Endings

**Supported:**
- Unix/Linux: `LF` (`\n`)
- Windows: `CRLF` (`\r\n`)
- Classic Mac: `CR LF` (rare)

**Normalization:**
Compiler normalizes all to `LF` internally for consistent output.

### Comments

Lines starting with `#` (after optional whitespace) are comments:

```
# This is a comment line - ignored entirely
    # This is a nested comment - also ignored

"Section"  # This is NOT a comment (# inside quotes)
```

Comment lines:
- Completely ignored during parsing
- Useful for documentation
- Must be on their own line

---

## Examples

### Example 1: Simple Document

```
"Introduction"
    "Welcome"
    "Getting Started"
```

**Output:**
```markdown
# Introduction
## Welcome
## Getting Started
```

### Example 2: With File References

```
"Project Documentation"
    "README.md"
    "Installation"
        "install.md"
    "Usage"
        "usage/basic.md"
        "usage/advanced.md"
```

### Example 3: Recursive Structure

**main.hc:**
```
"Main Document"
    "Chapter 1"
        "ch1.hc"
    "Chapter 2"
        "ch2.hc"
```

**ch1.hc:**
```
"Introduction to Chapter 1"
    "Background"
    "Details"
```

**Output:**
```markdown
# Main Document
## Chapter 1
### Introduction to Chapter 1
#### Background
#### Details
## Chapter 2
...
```

### Example 4: Mixed Content

```
"User Guide"
    "overview.md"
    "Installation"
        "linux/install.md"
        "macos/install.md"
    "Tutorials"
        "tutorial1.hc"
        "tutorial2.hc"
    "FAQ"
        "faq.md"
```

---

## Error Scenarios

### Syntax Errors (Exit Code 2)

**Unclosed Quote:**
```
"Missing closing quote
```
Error: `Unclosed quote at line 1`

**Invalid Indentation:**
```
"Root"
  "Child"    (* 2 spaces instead of 4 *)
```
Error: `Invalid indentation at line 2 (expected multiple of 4 spaces)`

**Tab Character:**
```
"Root"
→"Child"    (* Tab - shown as → *)
```
Error: `Tabs not allowed - use spaces at line 2`

**Mixed Indentation:**
```
"Root"
    "Child"
      "Grandchild"  (* 6 spaces instead of 8 *)
```
Error: `Invalid indentation at line 3`

### Resolution Errors (Exit Code 3)

**Missing File (Strict Mode):**
```
"Document"
    "missing.md"
```
Running: `hyperprompt doc.hc`
Error: `File not found: missing.md`
Exit: 1

**Circular Dependency:**
```
File a.hc contains:
"A"
    "b.hc"

File b.hc contains:
"B"
    "a.hc"
```
Error: `Circular dependency detected: a.hc → b.hc → a.hc`
Exit: 3

**Path Traversal (Security):**
```
"Doc"
    "../etc/passwd"
```
Error: `Path traversal outside root: ../etc/passwd`
Exit: 3

**Forbidden Extension:**
```
"Doc"
    "script.js"
```
Error: `Forbidden file type: .js (allowed: .md, .hc)`
Exit: 3

---

## Special Cases

### Empty Files

File with only whitespace and comments is valid:

```
# This file only contains comments
#  and blank lines


```

Result: Empty output (no content)

### Deep Nesting

Supported but not recommended (performance):

```
"L0"
    "L1"
        "L2"
            "L3"
                "L4"
                    "L5"
```

Maximum depth is implementation-dependent but typically 64+ levels.

### Long Lines

Line length is unlimited:

```
"This is a very long section title that goes on and on and on and explains everything about the section comprehensively without any line breaks"
```

### Special Characters in Content

Allowed in quotes:
```
"Section: Getting Started (Beginner's Guide)"
"Email: user@example.com"
"Code example: if (x > 0) { ... }"
"Path: C:\Windows\System32\file.txt"
```

### Whitespace in Content

Leading/trailing spaces in quoted strings are preserved:

```
"  Text with leading spaces  "
```

Output: `#   Text with leading spaces  ` (spaces preserved)

---

## Grammar Validation Strategy

The compiler uses declarative specifications (SpecificationCore) to validate:

1. **Lexical Level:**
   - `IsBlankLineSpec` — Detects blank lines
   - `HasQuotesSpec` — Validates quote pairing
   - `IndentationMultipleOf4Spec` — Validates indentation

2. **Structural Level:**
   - `NoIncreasingIndentationSpec` — Ensures nesting increases by 4
   - `NestingDepthSpec` — Limits maximum depth

3. **Semantic Level:**
   - `LooksLikeFileReferenceSpec` — Detects file references
   - `NoTraversalSpec` — Prevents path traversal attacks

For implementation details, see [SPECS_INTEGRATION.md](SPECS_INTEGRATION.md).

---

## Comparison to Other Languages

| Feature | Hypercode | Markdown | YAML |
|---------|-----------|----------|------|
| Hierarchy | ✓ Explicit indentation | ✓ Implicit (#) | ✓ Indentation |
| File inclusion | ✓ Native | ✗ No | ✗ No |
| Line count | ✓ Compact | ✗ Verbose | ✓ Compact |
| Human-readable | ✓ Yes | ✓ Yes | ✓ Yes |
| Validation spec | ✓ Yes (SpecificationCore) | ✗ No | ✗ No |

---

## See Also

- [USAGE.md](USAGE.md) — CLI reference
- [ERROR_CODES.md](ERROR_CODES.md) — Error resolution
- [SPECS_INTEGRATION.md](SPECS_INTEGRATION.md) — Validation implementation
- [examples/](examples/) — Example files

---

**Last Updated:** December 12, 2025
