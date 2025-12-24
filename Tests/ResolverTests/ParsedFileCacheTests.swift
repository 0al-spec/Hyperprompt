import XCTest
@testable import Resolver
@testable import Parser
@testable import Core

final class ParsedFileCacheTests: XCTestCase {
    private func makeProgram(literal: String, filePath: String) -> Program {
        let location = SourceLocation(filePath: filePath, line: 1)
        let node = Node(literal: literal, depth: 0, location: location)
        return Program(root: node, sourceFile: filePath)
    }

    func testCacheHitReturnsProgram() {
        let cache = ParsedFileCache()
        let program = makeProgram(literal: "root", filePath: "/tmp/root.hc")
        cache.store(
            path: "/tmp/root.hc",
            checksum: "checksum-1",
            program: program,
            dependencies: []
        )

        let cached = cache.cachedProgram(for: "/tmp/root.hc", checksum: "checksum-1")

        XCTAssertEqual(cached, program)
    }

    func testChecksumMismatchInvalidatesEntry() {
        let cache = ParsedFileCache()
        let program = makeProgram(literal: "root", filePath: "/tmp/root.hc")
        cache.store(
            path: "/tmp/root.hc",
            checksum: "checksum-1",
            program: program,
            dependencies: []
        )

        let cached = cache.cachedProgram(for: "/tmp/root.hc", checksum: "checksum-2")

        XCTAssertNil(cached)
        XCTAssertEqual(cache.entryCount, 0)
    }

    func testCascadingInvalidationRemovesDependents() {
        let cache = ParsedFileCache()
        let dependencyProgram = makeProgram(literal: "dep", filePath: "/tmp/dep.hc")
        let parentProgram = makeProgram(literal: "parent", filePath: "/tmp/parent.hc")

        cache.store(
            path: "/tmp/dep.hc",
            checksum: "dep-checksum",
            program: dependencyProgram,
            dependencies: []
        )
        cache.store(
            path: "/tmp/parent.hc",
            checksum: "parent-checksum",
            program: parentProgram,
            dependencies: ["/tmp/dep.hc"]
        )

        cache.invalidate(path: "/tmp/dep.hc")

        XCTAssertNil(cache.cachedProgram(for: "/tmp/dep.hc", checksum: "dep-checksum"))
        XCTAssertNil(cache.cachedProgram(for: "/tmp/parent.hc", checksum: "parent-checksum"))
        XCTAssertEqual(cache.entryCount, 0)
    }

    func testLRUEvictionRemovesLeastRecentlyUsed() {
        let cache = ParsedFileCache(capacity: 2)
        let programA = makeProgram(literal: "a", filePath: "/tmp/a.hc")
        let programB = makeProgram(literal: "b", filePath: "/tmp/b.hc")
        let programC = makeProgram(literal: "c", filePath: "/tmp/c.hc")

        cache.store(path: "/tmp/a.hc", checksum: "a", program: programA, dependencies: [])
        cache.store(path: "/tmp/b.hc", checksum: "b", program: programB, dependencies: [])

        XCTAssertNotNil(cache.cachedProgram(for: "/tmp/a.hc", checksum: "a"))

        cache.store(path: "/tmp/c.hc", checksum: "c", program: programC, dependencies: [])

        XCTAssertNil(cache.cachedProgram(for: "/tmp/b.hc", checksum: "b"))
        XCTAssertNotNil(cache.cachedProgram(for: "/tmp/a.hc", checksum: "a"))
        XCTAssertNotNil(cache.cachedProgram(for: "/tmp/c.hc", checksum: "c"))
    }
}
