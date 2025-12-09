# Next Task: C1 — Heading Adjuster

**Priority:** P1
**Phase:** Phase 5 (Markdown Emission)
**Effort:** 6 hours
**Dependencies:** A2 (Core Types Implementation)
**Status:** ✅ Completed on 2025-12-09

## Description

Parse ATX-style and Setext-style headings in Markdown content, compute adjusted heading levels with offset, and handle overflow beyond H6 by converting to bold text. Critical for embedding content with correct heading hierarchy in the final output.

## Completion Summary

### Deliverables
- [x] Created `HeadingAdjuster` struct with public API
- [x] Implemented ATX heading detection and transformation
- [x] Implemented Setext heading detection and transformation
- [x] Implemented overflow handling (H7+ → bold)
- [x] Implemented line ending normalization (CRLF/CR → LF)
- [x] Written comprehensive test suite (70+ test cases)

### Files Created/Modified
- `Sources/Emitter/HeadingAdjuster.swift` — Main implementation
- `Tests/EmitterTests/HeadingAdjusterTests.swift` — Comprehensive tests
- `Tests/EmitterTests/EmitterTests.swift` — Updated smoke tests

### Acceptance Criteria Status
- [x] All ATX headings (H1-H6) adjusted correctly
- [x] All Setext headings (H1-H2) adjusted correctly
- [x] Overflow headings (H7+) converted to bold
- [x] Non-heading content unchanged
- [x] Output normalized to LF endings
- [x] Output ends with exactly one LF

## Next Step

Run SELECT command to choose next task:
```
claude "Выполни команду SELECT"
```
