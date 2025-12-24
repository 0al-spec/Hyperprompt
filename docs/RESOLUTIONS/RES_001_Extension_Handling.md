# Resolution #1: Extension Handling Contradiction

**Status:** RESOLVED
**Date:** November 25, 2025

## Problem

PRD contains contradictory statements about non-.md/.hc file extensions:

- **§1.4 Success Criteria:** "all other extensions are disallowed"
- **§3.2 Allowed:** Only `.md` and `.hc` may be embedded
- **§5.3 Semantic Rules:** "File references to paths with other extensions are embedded as fenced code blocks"

This creates ambiguity: are non-.md/.hc files forbidden or allowed?

**Test Impact:**
- Test V15 describes embedding `.swift` files as code blocks
- Test V16 was referenced but doesn't exist in current corpus
- This test contradicts the "disallowed" requirement

## Decision: OPTION A - Only .md and .hc Allowed

**Rationale:**
1. **Simplicity:** MVP should minimize complexity
2. **Safety:** Prevents unexpected binary or system file embedding
3. **Clarity:** Single clear rule: only two extensions
4. **Consistency:** PRD §1.4 and §3.2 are explicit
5. **Tests:** Removes ambiguity from V15 (which tests .swift embedding)

**Implementation:**

Remove non-.md/.hc file embedding entirely.

## Changes Required

### PRD (00_PRD_001.md)

**Section 5.3 Semantic Rules - UPDATE:**
- Remove: "File references to paths with other extensions are embedded as fenced code blocks with language hint derived from the extension."

**Section 8.1 Valid Input Tests:**
- Remove Test V15 description about non-.md/.hc files
- Renumber remaining tests

### Design Spec (01_DESIGN_SPEC_001.md)

**Section 4.2 Reference Resolution Algorithm:**
- Existing code already correct: only .md and .hc checked
- Remove any mention of "other extensions" handling

### Test Corpus

**Section 8.1 Valid Input Tests:**
Current: 15 tests (V01-V15)
Updated: 14 tests (V01-V14, remove V15)

Valid tests (14):
- V01: Single root node with inline text
- V02: ~~Multiple root nodes~~ **INVALID** (handled separately)
- V03: Nested hierarchy three levels deep
- V04: Single Markdown file reference
- V05: Nested Markdown file references
- V06: Single Hypercode file reference
- V07: Nested Hypercode file references
- V08: Mixed inline text and file references
- V09: File reference to Markdown with headings H1-H4
- V10: File reference to Markdown with Setext headings
- V11: Comment lines interspersed with nodes
- V12: Blank lines between node groups
- V13: Maximum supported depth of 10 levels
- V14: Unicode content in literals and embedded files

**Removed:**
- V15: Non-.md/.hc file embedding (contradicts decision)

## Summary

✅ **Decision:** Only `.md` and `.hc` extensions allowed
✅ **Test Count:** 14 valid tests (was 15)
✅ **Clarity:** PRD §1.4 and §3.2 now consistent
✅ **Simplicity:** No code block embedding logic needed

