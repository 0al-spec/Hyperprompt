# Validation Report: Hyperprompt Compiler v0.1
## PRD and Design Spec Review

**Date:** November 25, 2025
**Status:** Issues Found - Action Required

---

## Executive Summary

Found **6 critical issues** that must be resolved before implementation (note: issue #6 was a false alarm and removed), plus multiple edge cases and ambiguities.

---

## 🔴 CRITICAL ISSUES

### 1. Extension Handling Contradiction
**Severity:** CRITICAL
**Location:** PRD §1.4, §3.2 vs §5.3
**Problem:**
- §1.4 Success Criteria: "all other extensions are disallowed"
- §3.2 Allowed: Only `.md` and `.hc`
- §5.3 Semantic Rules: "File references to paths with other extensions are embedded as fenced code blocks with language hint"

This is a direct contradiction: are non-.md/.hc files allowed or forbidden?

**Impact:** Test corpus references V16 which tests `.swift` embedding, but this contradicts the hard error requirement.

**Action:** Decide:
- Option A: Only `.md` and `.hc` allowed → remove V16 test, reduce to 14 valid tests
- Option B: All extensions allowed → update PRD requirements, add code block embedding logic

---

### 2. Test V02 Now Invalid
**Severity:** CRITICAL
**Location:** PRD §8.1, Test V02
**Problem:**
- V02 described as: "covers multiple root nodes forming a document forest"
- But spec now requires: "Only one root node allowed (depth 0)"
- Multiple roots at depth 0 now produces Syntax Error (exit 2)

**Impact:** V02 is now invalid per the grammar. Either:
- Remove V02 (14 valid tests remain)
- Add "Multiple root nodes" as invalid test I10 (10 invalid tests)

**Current State:**
- PRD says 15 valid, 9 invalid
- Should be: 14 valid, 10 invalid (or clarify which approach)

**Action:** Update test corpus descriptions and counts.

---

### 3. Test Counts Mismatch
**Severity:** CRITICAL
**Location:** PRD §8, §9 (Acceptance Criteria)
**Problem:**
- §8.1: "Test V01...V15" = 15 valid tests
- §8.2: "Test I01...I09" = 9 invalid tests
- §9 Acceptance Criteria: "All 15 valid" and "All 9 invalid"
- BUT: V02 is now invalid, need to add I10 for multiple roots

**Correct Counts Should Be:**
- 14 valid tests (remove V02)
- 10 invalid tests (add I10: multiple root nodes)

**Action:** Update all references to test counts throughout both documents.

---

### 4. Path Resolution Root Ambiguity
**Severity:** CRITICAL
**Location:** PRD §3.1.3, Design Spec §4.2
**Problem:**
- PRD §3.1.3: "file exists at the path formed by joining the compilation root directory with the literal content"
- This is clear: relative to root

BUT what about nested .hc files? If `a.hc` in subdirectory `sub/` references a file `file.md`:
- Does it resolve from root? (root + "file.md")
- Or from containing file's directory? (root + "sub/file.md")

This is NOT specified and will cause implementation disputes.

**Current Assumption in Design Spec:** Uses single root parameter for all resolutions, suggesting all paths are relative to root, not to the containing file.

**Action:** Explicitly specify: "All file references resolve relative to the compilation root directory, NOT the containing file's directory."

---

### 5. Depth Handling in Nested Hypercode
**Severity:** CRITICAL
**Location:** Design Spec §4.2, section "resolve(node...)"
**Problem:**
- When `a.hc` (depth 0 at root level) references `b.hc` recursively:
  - Nodes in `b.hc` are parsed with depth 0 (their own indentation)
  - But what depth should they have in the final output?
  - Should they inherit embedding depth from parent?

Example:
```
# a.hc
"Root"
    "b.hc"  # Embedded at depth 1

# b.hc
"Chapter"  # Is this depth 0 or depth 1?
    "content.md"
```

**Design Spec shows:**
```
Node(literal="Root", depth=0)
  Node(literal="b.hc reference", depth=1)
    Node(literal="Chapter from b.hc", depth=???)
```

The depth of nodes from recursive .hc compilation is NOT specified.

**Action:** Clarify: Do nested .hc nodes inherit parent embedding depth?

---

### 6. Literal Extraction — FALSE ALARM (RESOLVED)
**Severity:** ~~CRITICAL~~ RESOLVED
**Location:** PRD §3.1.1, §5.3
**Problem (Original):**
- Validation report incorrectly claimed "first and last quote" rule would extract `File with "` from `"File with "quotes" inside.md"`

**Correction:**
The extraction rule **works correctly**. "Between the first and last double quotation mark" means:
- First quote: position 0
- Last quote: position at end of line
- Extracted content: `File with "quotes" inside.md` ✓

Interior quotation marks ARE allowed and handled correctly.

**Resolution:** Remove this from critical issues list. Interior quotes work as specified.

---

### 7. Determinism Requirements Incomplete
**Severity:** CRITICAL
**Location:** PRD §4.2 Reliability
**Problem:**
- PRD says output must be "byte-for-byte stable" (idempotent)
- But several things not specified:

1. **Line Endings:** Should output always be LF? Or platform-specific (CRLF on Windows)?
   - For determinism, must be specified (suggest: always LF)

2. **Trailing Newline:** Should compiled .md end with newline?

3. **Manifest JSON:** Key ordering (mention in design spec but not PRD requirements)

4. **Heading Adjustment:** If original markdown uses CRLF, output will be different
   - Should all embedded content be normalized to LF?

**Action:** Add to PRD §4.2:
- "All output uses LF line endings regardless of platform"
- "Compiled .md ends with single LF"
- "Manifest JSON uses sorted keys for stable output"

---

## 🟠 HIGH SEVERITY ISSUES

### 8. Symlink Policy Vague
**Location:** PRD §4.5, §3.1.4
**Problem:**
- "The compiler shall not follow symbolic links that point outside the root directory"
- But what about symlinks pointing INSIDE root that later reference outside?
- Should symlinks be followed at all, or rejected entirely?

**Recommendation:** "Symlinks are not followed. References to symlink paths are treated as regular file references; if the symlink target is outside root, path validation will reject it."

---

### 9. Empty File Handling
**Location:** Not specified
**Problem:**
- Can a referenced `.md` file be empty? (Should be allowed)
- Can a referenced `.hc` file have only comments/blank lines? (No - requires at least one node)
- Should these error or emit nothing?

**Recommendation:** Add to PRD: "Empty `.md` files produce no output. `.hc` files with no nodes after comment/blank stripping are Syntax Errors."

---

### 10. Heading Adjustment for Non-Heading Content
**Location:** Design Spec §4.3
**Problem:**
- Algorithm assumes markdown has headings to adjust
- What if embedded `.md` has NO headings at all? (Just body text)
- What if heading underlines are too short/long for Setext detection?

**Recommendation:** "If markdown contains no headings, no adjustment is performed. All content is embedded as-is."

---

### 11. Circular Dependency Error Message
**Location:** PRD §3.1.4, Design Spec §4.2
**Problem:**
- PRD says "emit an error message identifying the cycle path"
- But format of cycle path not specified

Example: If A→B→C→A, should error say:
- "Cycle detected: A → B → C → A"
- "Circular dependency in C (references A which is already being processed)"
- Something else?

**Recommendation:** "Error message must include the full cycle path in the format: `A → B → C → A`"

---

### 12. Lenient Mode with Unresolved Inline Text
**Location:** PRD §3.1.3
**Problem:**
- "If file does not exist and lenient mode is enabled, treat as inline text"
- But what if the literal contains special characters like `../../../etc/passwd`?
- These can appear to be file paths but are treated as inline text

No error in lenient mode, but dangerous-looking content isn't flagged.

**Recommendation:** Document clearly: "Lenient mode treats all unresolved references as plain text literals. Path validation is not performed on lenient references."

---

### 13. Manifest: Source Type for Recursive .hc
**Location:** PRD §3.3.1, Design Spec §3.3
**Problem:**
- Manifest records source files with type "markdown" or "hypercode"
- When `a.hc` references `b.hc`, the manifest should record both
- But if `b.hc` references `c.md`, all three appear in manifest
- Order/structure of listing not specified

**Action:** Clarify: "Manifest lists all files encountered during compilation in a flat array, regardless of nesting depth. Each entry records the file's actual extension (type = 'hypercode' for .hc, 'markdown' for .md)."

---

## 🟡 MEDIUM SEVERITY ISSUES

### 14. Test V01 Description Vague
**Location:** PRD §8.1
**Problem:**
- "Test V01 covers a single root node with inline text"
- But doesn't specify: just `"text"` or multiple child nodes with text?

---

### 15. Depth 0 Leaf Nodes
**Location:** Design Spec §4.3 "emit()"
**Problem:**
- Root node (depth 0) with no children generates H1 heading
- But if it's just inline text (no file reference), does it generate a heading?
- Example:
  ```
  "Just some text"
  ```
  Should output be `# Just some text\n` or just `Just some text\n`?

**Current Design Spec assumption:** Heading is always generated.

---

### 16. Circular Dependency in Lenient Mode
**Location:** Not specified
**Problem:**
- Circular dependencies error in exit code 3 (Resolution Error)
- But lenient mode allows unresolved references...
- Should lenient mode also allow circular references?
- Or should cycles always be fatal?

**Recommendation:** "Circular dependencies are fatal in both strict and lenient modes. Exit code 3."

---

### 17. Multi-level Depth Regression
**Location:** Design Spec §4.1 Algorithm
**Problem:**
- Algorithm uses `while` to pop stack until parent found
- If indentation jumps from depth 3 to depth 0, all nodes in between are orphaned
- This is handled but could be clearer in spec

---

### 18. Content Separator Edge Case
**Location:** PRD §3.2.3
**Problem:**
- "insert two blank lines before any H1 or H2 heading except at document start"
- What counts as "document start"? First heading? First non-blank line?

---

## Summary of Required Changes

### To PRD:
1. Resolve extension handling (§3.2, §5.3)
2. Update test counts: 14 valid, 10 invalid
3. Update Test V02 or add Test I10
4. Clarify path resolution (always from root)
5. Clarify line endings and determinism details
6. Specify symlink behavior more precisely
7. Add empty file handling

### To Design Spec:
1. Clarify depth inheritance in nested .hc files
2. Add interior quote handling rules
3. Specify symlink rejection behavior
4. Clarify circular dependency error format
5. Document heading adjustment for non-heading content

### Test Corpus:
- Remove V02 or move to I10
- Add tests for edge cases:
  - Empty `.md` file
  - `.hc` with only comments
  - Literal with interior quotes
  - Unicode edge cases

---

## Recommendation

**Suggest Decision Points:**

1. **Extensions:** Option A (only .md/.hc) or Option B (all extensions as code blocks)?
   - Current: Contradictory
   - Recommend: Option A for MVP simplicity

2. **Depth Inheritance:** How should nested .hc nodes be depth-adjusted?
   - Current: Not specified
   - Recommend: Inherit parent embedding depth

3. **Interior Quotes:** Allow or disallow in literals?
   - Current: Ambiguous
   - Recommend: Disallow for safety

Once these decisions are made, documents can be corrected.
