# BUG: Lenient Compile Includes Markdown Filename Heading

**Bug ID:** BUG-CE1-001
**Component:** Compiler / Lenient Mode / Markdown Emission
**Severity:** Medium
**Status:** Open
**Discovered:** 2025-12-27
**Related Task:** BUG-CE1-001 — Lenient Compile Includes Markdown Filename Heading

---

## Summary

Lenient compilation of `DOCS/examples/with-markdown.hc` emits a Markdown filename heading (`## prerequisites.md`) that should not appear in the output. The output should only include the contents of the referenced Markdown file (`Hello`).

---

## Reproduction Steps

1. Open `DOCS/examples/with-markdown.hc` in VS Code.
2. Run `Hyperprompt: Compile Lenient`.
3. Observe the generated Markdown output.

---

## Expected Output

```markdown
# Project Documentation
## Installation Guide

Hello

## Usage

## introduction.md
```

---

## Actual Output

```markdown
# Project Documentation
## Installation Guide

## prerequisites.md
Hello

## Usage

## introduction.md
```

---

## Impact

- Output contains an extra filename heading that is not part of the intended document.
- This breaks formatting expectations and makes lenient output inconsistent with strict compilation.

---

## Notes

- Observed in VS Code via `Hyperprompt: Compile Lenient`.
- Likely tied to how lenient mode handles Markdown include nodes in the emitter.

---
