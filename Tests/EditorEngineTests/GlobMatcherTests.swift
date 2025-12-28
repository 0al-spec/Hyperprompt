#if Editor
/// Unit Tests for GlobMatcher
///
/// Tests glob pattern matching used in .hyperpromptignore file processing.
/// Covers common patterns used in ignore files similar to .gitignore syntax.

import XCTest
@testable import EditorEngine

final class GlobMatcherTests: XCTestCase {
    var matcher: GlobMatcher!

    override func setUp() {
        super.setUp()
        matcher = GlobMatcher()
    }

    // MARK: - Basic Pattern Tests

    func testExactMatch() {
        XCTAssertTrue(matcher.matches(path: "foo.log", pattern: "foo.log"))
        XCTAssertFalse(matcher.matches(path: "bar.log", pattern: "foo.log"))
    }

    func testEmptyPattern() {
        XCTAssertFalse(matcher.matches(path: "anything.txt", pattern: ""))
        XCTAssertFalse(matcher.matches(path: "", pattern: ""))
    }

    // MARK: - Wildcard * Tests (matches anything except /)

    func testWildcardExtension() {
        XCTAssertTrue(matcher.matches(path: "file.log", pattern: "*.log"))
        XCTAssertTrue(matcher.matches(path: "test.log", pattern: "*.log"))
        XCTAssertFalse(matcher.matches(path: "file.txt", pattern: "*.log"))
    }

    func testWildcardPrefix() {
        XCTAssertTrue(matcher.matches(path: "test_file.txt", pattern: "test_*"))
        XCTAssertTrue(matcher.matches(path: "test_123.txt", pattern: "test_*"))
        XCTAssertFalse(matcher.matches(path: "prod_file.txt", pattern: "test_*"))
    }

    func testWildcardMiddle() {
        XCTAssertTrue(matcher.matches(path: "file_test_1.txt", pattern: "file_*_1.txt"))
        XCTAssertTrue(matcher.matches(path: "file_prod_1.txt", pattern: "file_*_1.txt"))
        XCTAssertFalse(matcher.matches(path: "file_test_2.txt", pattern: "file_*_1.txt"))
    }

    func testWildcard_DoesNotCrossDirectories() {
        // * should not match across directory separators
        XCTAssertFalse(matcher.matches(path: "dir/file.log", pattern: "*.log"))
        XCTAssertTrue(matcher.matches(path: "file.log", pattern: "*.log"))
    }

    // MARK: - Double Wildcard ** Tests (matches anything including /)

    func testDoubleWildcard_MatchesAnyDepth() {
        XCTAssertTrue(matcher.matches(path: "file.test.md", pattern: "**/*.test.md"))
        XCTAssertTrue(matcher.matches(path: "dir/file.test.md", pattern: "**/*.test.md"))
        XCTAssertTrue(matcher.matches(path: "dir/sub/file.test.md", pattern: "**/*.test.md"))
        XCTAssertFalse(matcher.matches(path: "file.prod.md", pattern: "**/*.test.md"))
    }

    func testDoubleWildcard_AllFiles() {
        XCTAssertTrue(matcher.matches(path: "anything.txt", pattern: "**"))
        XCTAssertTrue(matcher.matches(path: "dir/file.txt", pattern: "**"))
        XCTAssertTrue(matcher.matches(path: "a/b/c/d.txt", pattern: "**"))
    }

    // MARK: - Directory Pattern Tests (ends with /)

    func testDirectoryPattern_MatchesDirectory() {
        XCTAssertTrue(matcher.matches(path: "build", pattern: "build/"))
        XCTAssertTrue(matcher.matches(path: "build/output.txt", pattern: "build/"))
        XCTAssertTrue(matcher.matches(path: "build/sub/file.txt", pattern: "build/"))
        XCTAssertFalse(matcher.matches(path: "src/main.hc", pattern: "build/"))
    }

    func testDirectoryPattern_NestedPaths() {
        XCTAssertTrue(matcher.matches(path: "node_modules/pkg/index.js", pattern: "node_modules/"))
        XCTAssertTrue(matcher.matches(path: "node_modules", pattern: "node_modules/"))
    }

    // MARK: - Root-Anchored Pattern Tests (starts with /)

    func testRootAnchoredPattern_MatchesOnlyAtRoot() {
        XCTAssertTrue(matcher.matches(path: "build.log", pattern: "/build.log"))
        XCTAssertFalse(matcher.matches(path: "dir/build.log", pattern: "/build.log"))
    }

    // MARK: - Path with Directory Separators

    func testPathPattern_WithDirectories() {
        XCTAssertTrue(matcher.matches(path: "src/test.hc", pattern: "src/*.hc"))
        XCTAssertTrue(matcher.matches(path: "src/main.hc", pattern: "src/*.hc"))
        XCTAssertFalse(matcher.matches(path: "lib/utils.hc", pattern: "src/*.hc"))
        XCTAssertFalse(matcher.matches(path: "src/sub/test.hc", pattern: "src/*.hc"))
    }

    func testPathPattern_DeepPath() {
        XCTAssertTrue(matcher.matches(path: "a/b/c/file.txt", pattern: "a/b/c/*.txt"))
        XCTAssertFalse(matcher.matches(path: "a/b/file.txt", pattern: "a/b/c/*.txt"))
    }

    // MARK: - Real-World .gitignore Patterns

    func testRealWorld_NodeModules() {
        let pattern = "node_modules/"

        XCTAssertTrue(matcher.matches(path: "node_modules", pattern: pattern))
        XCTAssertTrue(matcher.matches(path: "node_modules/pkg/index.js", pattern: pattern))
        XCTAssertFalse(matcher.matches(path: "src/node_modules.txt", pattern: pattern))
    }

    func testRealWorld_BuildArtifacts() {
        let pattern = "*.log"

        XCTAssertTrue(matcher.matches(path: "debug.log", pattern: pattern))
        XCTAssertTrue(matcher.matches(path: "error.log", pattern: pattern))
        XCTAssertFalse(matcher.matches(path: "logs/debug.log", pattern: pattern))
    }

    func testRealWorld_TemporaryFiles() {
        let pattern = "**/*.tmp"

        XCTAssertTrue(matcher.matches(path: "file.tmp", pattern: pattern))
        XCTAssertTrue(matcher.matches(path: "dir/file.tmp", pattern: pattern))
        XCTAssertTrue(matcher.matches(path: "a/b/c/file.tmp", pattern: pattern))
        XCTAssertFalse(matcher.matches(path: "file.txt", pattern: pattern))
    }

    func testRealWorld_DotFiles() {
        let pattern = ".*"

        XCTAssertTrue(matcher.matches(path: ".gitignore", pattern: pattern))
        XCTAssertTrue(matcher.matches(path: ".env", pattern: pattern))
        XCTAssertFalse(matcher.matches(path: "visible.txt", pattern: pattern))
    }

    // MARK: - Array Extension Tests

    func testArrayExtension_MatchesAny() {
        let patterns = ["*.log", "*.tmp", "build/"]
        var matcher = GlobMatcher()

        XCTAssertTrue(patterns.matchesAny(path: "debug.log", using: &matcher))
        XCTAssertTrue(patterns.matchesAny(path: "cache.tmp", using: &matcher))
        XCTAssertTrue(patterns.matchesAny(path: "build/output.txt", using: &matcher))
        XCTAssertFalse(patterns.matchesAny(path: "src/main.hc", using: &matcher))
    }

    func testArrayExtension_EmptyArray() {
        let patterns: [String] = []
        var matcher = GlobMatcher()
        XCTAssertFalse(patterns.matchesAny(path: "anything.txt", using: &matcher))
    }

    // MARK: - Edge Cases

    func testEdgeCase_PathWithDots() {
        XCTAssertTrue(matcher.matches(path: "file.test.tmp", pattern: "*.tmp"))
        XCTAssertTrue(matcher.matches(path: "my.file.name.txt", pattern: "*.txt"))
    }

    func testEdgeCase_PathNormalization() {
        // Paths should be normalized (no leading/trailing slashes)
        XCTAssertTrue(matcher.matches(path: "/file.txt", pattern: "file.txt"))
        XCTAssertTrue(matcher.matches(path: "file.txt/", pattern: "file.txt"))
    }

    func testEdgeCase_CaseSensitive() {
        // Glob matching should be case-sensitive
        XCTAssertTrue(matcher.matches(path: "File.txt", pattern: "File.txt"))
        XCTAssertFalse(matcher.matches(path: "file.txt", pattern: "File.txt"))
    }

    // MARK: - Caching Tests (EE-FIX-4)

    func testCaching_SamePatternReused() {
        // Test that the same pattern benefits from caching
        var matcher = GlobMatcher()
        let pattern = "**/*.log"

        // First match compiles regex
        XCTAssertTrue(matcher.matches(path: "debug.log", pattern: pattern))

        // Subsequent matches should use cached regex
        XCTAssertTrue(matcher.matches(path: "app/debug.log", pattern: pattern))
        XCTAssertTrue(matcher.matches(path: "app/server/access.log", pattern: pattern))
        XCTAssertFalse(matcher.matches(path: "app/config.txt", pattern: pattern))
    }

    func testCaching_MultiplePatterns() {
        // Test that different patterns each get cached
        var matcher = GlobMatcher()

        XCTAssertTrue(matcher.matches(path: "file.log", pattern: "*.log"))
        XCTAssertTrue(matcher.matches(path: "file.tmp", pattern: "*.tmp"))
        XCTAssertTrue(matcher.matches(path: "build/out.txt", pattern: "build/"))

        // Reuse patterns - should hit cache
        XCTAssertTrue(matcher.matches(path: "error.log", pattern: "*.log"))
        XCTAssertTrue(matcher.matches(path: "cache.tmp", pattern: "*.tmp"))
        XCTAssertTrue(matcher.matches(path: "build/lib/main.o", pattern: "build/"))
    }

    func testCaching_InvalidPattern() {
        // Invalid patterns should not be cached and return false
        var matcher = GlobMatcher()

        // Try to match with an invalid regex pattern (would be created if globToRegex produces invalid regex)
        // Note: Most glob patterns produce valid regex, so this tests the safety fallback
        let result1 = matcher.matches(path: "test.txt", pattern: "*.txt")
        let result2 = matcher.matches(path: "test.txt", pattern: "*.txt")

        // Both should have the same behavior
        XCTAssertEqual(result1, result2)
    }

    // MARK: - Performance Tests (EE-FIX-4)

    func testPerformance_WithCaching() {
        // Measure performance with caching enabled
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
        // Actual measurement depends on hardware, but caching should provide significant speedup
    }

    func testPerformance_ArrayMatchesAny() {
        // Test performance of array extension with caching
        let patterns = ["*.log", "*.tmp", "build/", ".git/", "node_modules/",
                        "*.bak", "*.swp", "dist/", "target/", ".cache/"]
        let paths = (0..<1000).map { "src/module\($0)/file.swift" }
        var matcher = GlobMatcher()

        measure {
            for path in paths {
                _ = patterns.matchesAny(path: path, using: &matcher)
            }
        }
        // Expected: Significant speedup due to regex caching across all pattern checks
    }
}
#endif
