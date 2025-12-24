# PR 65 — Fix Caret Alignment in DiagnosticPrinter

**Date:** 2025-12-12
**Status:** Archived (merged)
**Scope:** Phase 6 — CLI & Integration
**PR:** https://github.com/0al-spec/Hyperprompt/pull/65

---

## Summary

Resolved a caret misalignment bug in `DiagnosticPrinter` by preserving leading indentation when preparing context lines. The caret indicator now aligns with displayed source lines on indented input.

## Details
- **Problem:** Context lines were trimmed with `trimmingCharacters(in: .whitespacesAndNewlines)`, removing both leading and trailing spaces while caret position calculations still used the original untrimmed text. This caused the caret (`^`) to point to the wrong column on indented lines.
- **Solution:** Strip only trailing whitespace via a manual loop, keeping leading indentation intact for accurate caret positioning.
- **Files Changed:** `Sources/CLI/DiagnosticPrinter.swift` (trailing-whitespace handling)
- **Testing:** Logic reviewed; environment lacked Swift toolchain for execution in upstream PR.

## Notes
- Fix authored and merged in PR #65: “Fix caret alignment on indented lines in DiagnosticPrinter.”
- Change complements the DiagnosticPrinter PRD (`D3`) by ensuring formatted output respects indentation when highlighting errors.

---
**Archived:** 2025-12-12
