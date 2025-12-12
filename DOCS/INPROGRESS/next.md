# Next Task: Integration-2 — Resolver with Specifications

**Priority:** P1
**Phase:** Phase 7 - Lexer & Resolver Integration with Specs
**Effort:** 6 hours
**Dependencies:** Phase 4 (Resolver) ✅, Phase 3 (Specs) ✅
**Status:** ✅ Completed on 2025-12-12

## Summary

Successfully refactored ReferenceResolver to use HypercodeGrammar specifications for path validation and classification:

- ✅ `NoTraversalSpec` — Replaced imperative `..` detection
- ✅ `HasMarkdownExtensionSpec` — Markdown file detection
- ✅ `HasHypercodeExtensionSpec` — Hypercode file detection
- ✅ `WithinRootSpec` — Root boundary validation
- ✅ `LooksLikeFileReferenceSpec` — Heuristic path detection (verified)

All changes maintain full backward compatibility with existing API.

## Deliverables

- `Sources/Resolver/ReferenceResolver.swift` — 5 specification integrations
- `DOCS/INPROGRESS/Integration-2-summary.md` — Detailed implementation report

## Next Step

Ready for Phase 8 (Testing & QA) or Phase 9 (Release). Run SELECT to choose next task:
$ claude "Выполни команду SELECT"
