# Next Task: B1 — Reference Resolver

**Priority:** P0
**Phase:** Phase 4 (Reference Resolution)
**Effort:** 6 hours
**Dependencies:** A4 (Parser & AST Construction)
**Status:** ✅ Completed on 2025-12-06

## Description

Implement file reference resolution with support for both Markdown (.md) and Hypercode (.hc) file extensions. Classify literals as file references or inline text, handle different file types appropriately, and reject invalid extensions with proper error handling.

## Completion Summary

### Deliverables

- [x] `ResolutionMode` enum (strict/lenient)
- [x] `ResolutionError` type with factory methods
- [x] `ReferenceResolver` struct with full API
- [x] Helper methods: `looksLikeFilePath`, `fileExtension`, `containsPathTraversal`
- [x] Integration hooks for B2/B3/B4
- [x] 50+ unit tests

### Files Created

- `Sources/Resolver/ResolutionMode.swift`
- `Sources/Resolver/ResolutionError.swift`
- `Sources/Resolver/ReferenceResolver.swift`
- `Tests/ResolverTests/MockFileSystem.swift`
- `Tests/ResolverTests/ReferenceResolverTests.swift`

### Acceptance Criteria

- [x] All node literals correctly classified as inline, .md, .hc, or forbidden
- [x] File existence validated against root directory
- [x] Strict mode: missing files → resolution error (exit code 3)
- [x] Lenient mode: missing files → treated as inline text
- [x] Forbidden extensions rejected with error message
- [x] Source location preserved in all error diagnostics
- [x] Integration points established for B2, B3, B4

## Next Step

Run SELECT command to choose next task:
```
$ claude "Выполни команду SELECT"
```
