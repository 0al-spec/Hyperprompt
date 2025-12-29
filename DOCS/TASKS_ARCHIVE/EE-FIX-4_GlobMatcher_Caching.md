# PRD: EE-FIX-4 — GlobMatcher Regex Caching

**Task ID:** EE-FIX-4
**Priority:** P1 (High)
**Estimated Effort:** 2 hours
**Status:** Pending
**Source:** [REVIEW_EditorEngine_Implementation.md](REVIEW_EditorEngine_Implementation.md) — Issue H-002

---

## 1. Scope and Intent

### 1.1 Objective

Add regex caching to `GlobMatcher` to avoid recompiling the same regex pattern on every match call. This is particularly expensive during project indexing where the same ignore patterns are checked against thousands of files.

### 1.2 Primary Deliverables

1. Regex cache dictionary in GlobMatcher
2. Cache lookup before regex compilation
3. Updated call sites to reuse matcher instance
4. Performance test demonstrating improvement

### 1.3 Success Criteria

- Regex compilation reduced by >80% on repeated pattern matching
- Indexing 1000 files with 10 patterns: overhead reduced from ~100ms to ~5ms
- No change in matching behavior

### 1.4 Constraints and Assumptions

- GlobMatcher is currently a struct (immutable)
- Must make GlobMatcher mutable or use class for caching
- Cache does not need eviction for typical use (< 100 patterns)

---

## 2. Hierarchical TODO Plan

### Phase 1: GlobMatcher Refactoring

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 1.1 | Add `regexCache: [String: NSRegularExpression]` property | Struct | Mutable property | High |
| 1.2 | Make `matchesGlobPattern` mutating | Current method | Mutating method | High |
| 1.3 | Add cache lookup before compilation | Method body | Cache check logic | High |
| 1.4 | Store compiled regex in cache | Compiled regex | Cache population | High |

### Phase 2: Call Site Updates

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 2.1 | Update `matchesIgnorePattern` to reuse matcher | ProjectIndexer | Single matcher instance | High |
| 2.2 | Update `matchesAny` extension if needed | Array extension | Matcher reuse | Medium |
| 2.3 | Verify all call sites compile | Full build | No errors | High |

### Phase 3: Testing

| # | Task | Input | Output | Priority |
|---|------|-------|--------|----------|
| 3.1 | Add unit test: cache hit scenario | Same pattern twice | Single compilation | High |
| 3.2 | Add unit test: cache miss scenario | Different patterns | Multiple compilations | High |
| 3.3 | Add performance test | 1000 files, 10 patterns | Measure time difference | High |
| 3.4 | Verify existing glob tests pass | Test suite | All green | High |

---

## 3. Execution Metadata

### 3.1 Task Details

| Task | Effort | Tools/Frameworks | Verification Method |
|------|--------|------------------|---------------------|
| 1.1-1.4 | 30 min | Swift | Compilation |
| 2.1-2.3 | 20 min | Swift | Compilation |
| 3.1-3.4 | 50 min | XCTest, XCTMeasure | Test execution |

### 3.2 Dependencies

- None (standalone fix)

### 3.3 Parallel Execution

- Phase 1 and Phase 2 are sequential
- Phase 3 tests can be written in parallel

---

## 4. Functional Requirements

### FR-1: Cache Storage

GlobMatcher SHALL maintain a dictionary mapping regex pattern strings to compiled `NSRegularExpression` objects.

### FR-2: Cache Lookup

Before compiling a regex, the matcher SHALL check if the pattern is already cached.

### FR-3: Cache Population

After successfully compiling a regex, the matcher SHALL store it in the cache.

### FR-4: Matching Behavior

Cached regex SHALL produce identical matching results to freshly compiled regex.

---

## 5. Non-Functional Requirements

### NFR-1: Performance

- Cache hit: O(1) dictionary lookup
- Cache miss: O(pattern length) regex compilation + O(1) cache store
- Expected 20x speedup for repeated patterns

### NFR-2: Memory

- Cache size proportional to unique patterns
- Typical use case: < 100 patterns = < 1KB overhead

### NFR-3: Thread Safety

- Not required for current single-threaded use
- Note: If async indexing added later, cache needs synchronization

---

## 6. Edge Cases and Failure Scenarios

| Scenario | Expected Behavior |
|----------|-------------------|
| Same pattern matched 1000 times | 1 compilation, 999 cache hits |
| 100 different patterns | 100 compilations, 100 cache entries |
| Invalid pattern (fails compilation) | Not cached, returns false each time |
| Empty cache at start | First match compiles and caches |

---

## 7. Implementation Reference

### Current Code (GlobMatcher.swift:90-100)

```swift
private func matchesGlobPattern(path: String, pattern: String) -> Bool {
    let regex = globToRegex(pattern)

    guard let regexObj = try? NSRegularExpression(pattern: regex, options: []) else {
        // Invalid regex - fall back to exact match
        return path == pattern
    }

    let range = NSRange(path.startIndex..., in: path)
    return regexObj.firstMatch(in: path, options: [], range: range) != nil
}
```

### Fixed Code

```swift
/// Glob pattern matcher for file paths
struct GlobMatcher {
    /// Cache of compiled regular expressions
    private var regexCache: [String: NSRegularExpression] = [:]

    /// Checks if a path matches a glob pattern
    mutating func matches(path: String, pattern: String) -> Bool {
        // ... existing normalization logic ...
        return matchesGlobPattern(path: normalizedPath, pattern: normalizedPattern)
    }

    /// Matches path against glob pattern using cached regex
    private mutating func matchesGlobPattern(path: String, pattern: String) -> Bool {
        let regexPattern = globToRegex(pattern)

        // Check cache first
        let regexObj: NSRegularExpression
        if let cached = regexCache[regexPattern] {
            regexObj = cached
        } else {
            guard let compiled = try? NSRegularExpression(pattern: regexPattern, options: []) else {
                // Invalid regex - return false for safety (see EE-FIX-5)
                return false
            }
            regexCache[regexPattern] = compiled
            regexObj = compiled
        }

        let range = NSRange(path.startIndex..., in: path)
        return regexObj.firstMatch(in: path, options: [], range: range) != nil
    }
}
```

### Call Site Update (ProjectIndexer.swift)

```swift
/// Checks if a path matches any ignore pattern using glob matching
private mutating func matchesIgnorePattern(path: String, patterns: [String]) -> Bool {
    // Reuse single matcher instance for caching benefit
    var matcher = GlobMatcher()
    return patterns.matchesAny(path: path, using: &matcher)
}
```

### Array Extension Update

```swift
extension Array where Element == String {
    /// Checks if any pattern in array matches the given path
    mutating func matchesAny(path: String, using matcher: inout GlobMatcher) -> Bool {
        for pattern in self {
            if matcher.matches(path: path, pattern: pattern) {
                return true
            }
        }
        return false
    }
}
```

---

## 8. Performance Test

```swift
func testGlobMatcher_PerformanceWithCaching() {
    var matcher = GlobMatcher()
    let patterns = ["*.log", "*.tmp", "build/", ".git/", "node_modules/",
                    "*.bak", "*.swp", "dist/", "target/", ".cache/"]
    let paths = (0..<1000).map { "src/module\($0)/file.swift" }

    measure {
        for path in paths {
            for pattern in patterns {
                _ = matcher.matches(path: path, pattern: pattern)
            }
        }
    }
    // Expected: < 10ms with caching vs ~100ms without
}
```

---

## 9. Acceptance Checklist

- [ ] `regexCache` property added to GlobMatcher
- [ ] `matchesGlobPattern` uses cache before compilation
- [ ] Compiled regex stored in cache
- [ ] Call sites updated to reuse matcher instance
- [ ] Performance test shows >80% reduction in overhead
- [ ] All existing pattern matching tests pass
- [ ] No change in matching behavior

---
**Archived:** 2025-12-28
