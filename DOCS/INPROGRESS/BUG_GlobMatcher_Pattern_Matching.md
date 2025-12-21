# BUG: GlobMatcher Pattern Matching Issues

**Bug ID:** BUG-EE1-001
**Component:** EditorEngine / GlobMatcher
**Severity:** Medium
**Status:** Open
**Discovered:** 2025-12-21
**Related Task:** EE1 — Project Indexing

---

## Summary

The `GlobMatcher` implementation in EE1 has 4 failing tests related to pattern matching semantics. The glob pattern matching does not correctly implement the expected `.gitignore`-style behavior for wildcards and directory handling.

---

## Failing Tests

| Test | Line | Expected Behavior | Actual Behavior |
|------|------|-------------------|-----------------|
| `testWildcard_DoesNotCrossDirectories` | 51 | `*.log` should NOT match `dir/file.log` | Matches (incorrectly) |
| `testDoubleWildcard_MatchesAnyDepth` | 58 | `**/*.test.md` should match `file.test.md` | Does not match |
| `testRealWorld_BuildArtifacts` | 120 | `*.log` should NOT match `logs/debug.log` | Matches (incorrectly) |
| `testRealWorld_TemporaryFiles` | 126 | `**/*.tmp` should match `file.tmp` | Does not match |

---

## Root Cause Analysis

### Issue 1: Single Wildcard `*` Crossing Directories

The current implementation uses `[^/]*` regex for `*` but the `matches()` function extracts the basename for patterns without `/`:

```swift
// GlobMatcher.swift:57-61
if !normalizedPattern.contains("/") {
    // Pattern without directory separator - match basename
    let basename = (normalizedPath as NSString).lastPathComponent
    return matchesGlobPattern(path: basename, pattern: normalizedPattern)
}
```

This works for `file.log` matching `*.log`, but then `dir/file.log` also matches because:
- Pattern `*.log` has no `/`
- Basename of `dir/file.log` is `file.log`
- `file.log` matches `*.log`

**Expected**: `*.log` without `/` should only match files in the current directory, not in subdirectories.

### Issue 2: Double Wildcard `**` with Slash Pattern

The pattern `**/*.test.md` should match at any depth including the root. Currently:
- `file.test.md` does NOT match `**/*.test.md`
- `dir/file.test.md` DOES match

The issue is that `**/` should also match "zero directories" (i.e., the root level).

---

## Proposed Fix

### Option A: Match `.gitignore` Semantics Exactly

1. **`*` without `/`**: Match against basename only, but also check if the path has no directory components
2. **`**` patterns**: Special-case `**/` to optionally match zero path components

### Option B: Simplify Pattern Matching

1. **`*` always matches basename**: Current behavior (simpler but different from gitignore)
2. **Document the difference**: Tests should reflect actual behavior

### Recommended: Option A

Implement `.gitignore`-compatible semantics since this is what users expect.

---

## Files to Modify

1. **`Sources/EditorEngine/GlobMatcher.swift`** — Fix pattern matching logic
2. **`Tests/EditorEngineTests/GlobMatcherTests.swift`** — Verify tests pass after fix

---

## Acceptance Criteria

1. All 26 GlobMatcherTests pass
2. `*.log` matches `file.log` but NOT `dir/file.log`
3. `**/*.tmp` matches `file.tmp`, `dir/file.tmp`, and `a/b/c/file.tmp`
4. Edge cases documented in test comments

---

## Priority

**P2 (Medium)** — The indexer still functions correctly for most use cases. The pattern matching edge cases primarily affect `.hyperpromptignore` files with complex patterns.

---

## Workaround

Users can use explicit patterns instead:
- Use `*.log` AND `**/*.log` to match all `.log` files
- Use `dir/*.tmp` instead of `**/*.tmp` for specific directories

---

## References

- **Implementation**: `Sources/EditorEngine/GlobMatcher.swift:34-65`
- **Tests**: `Tests/EditorEngineTests/GlobMatcherTests.swift`
- **PRD**: `DOCS/INPROGRESS/EE1_Project_Indexing.md` (Section 2.2.2)
- **gitignore spec**: https://git-scm.com/docs/gitignore

---

**Reported by:** Validation during EE1 implementation review
**Assigned to:** Unassigned
