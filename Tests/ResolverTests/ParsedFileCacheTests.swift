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

    func testDependencyAccessorsExposeGraph() {
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

        XCTAssertEqual(cache.dependencies(for: "/tmp/parent.hc"), ["/tmp/dep.hc"])
        XCTAssertEqual(cache.dependents(for: "/tmp/dep.hc"), ["/tmp/parent.hc"])
        XCTAssertEqual(cache.dependencyGraph()["/tmp/parent.hc"], ["/tmp/dep.hc"])
    }

    func testDirtyClosureIncludesDependents() {
        let cache = ParsedFileCache()
        let programA = makeProgram(literal: "a", filePath: "/tmp/a.hc")
        let programB = makeProgram(literal: "b", filePath: "/tmp/b.hc")
        let programC = makeProgram(literal: "c", filePath: "/tmp/c.hc")

        cache.store(
            path: "/tmp/a.hc",
            checksum: "a-checksum",
            program: programA,
            dependencies: []
        )
        cache.store(
            path: "/tmp/b.hc",
            checksum: "b-checksum",
            program: programB,
            dependencies: ["/tmp/a.hc"]
        )
        cache.store(
            path: "/tmp/c.hc",
            checksum: "c-checksum",
            program: programC,
            dependencies: ["/tmp/b.hc"]
        )

        let dirty = cache.dirtyClosure(for: ["/tmp/a.hc"])
        XCTAssertEqual(dirty, ["/tmp/a.hc", "/tmp/b.hc", "/tmp/c.hc"])
    }

    func testTopologicalOrderPlacesDependenciesFirst() {
        let cache = ParsedFileCache()
        let programA = makeProgram(literal: "a", filePath: "/tmp/a.hc")
        let programB = makeProgram(literal: "b", filePath: "/tmp/b.hc")
        let programC = makeProgram(literal: "c", filePath: "/tmp/c.hc")
        let programD = makeProgram(literal: "d", filePath: "/tmp/d.hc")

        cache.store(
            path: "/tmp/d.hc",
            checksum: "d-checksum",
            program: programD,
            dependencies: []
        )
        cache.store(
            path: "/tmp/b.hc",
            checksum: "b-checksum",
            program: programB,
            dependencies: ["/tmp/d.hc"]
        )
        cache.store(
            path: "/tmp/c.hc",
            checksum: "c-checksum",
            program: programC,
            dependencies: []
        )
        cache.store(
            path: "/tmp/a.hc",
            checksum: "a-checksum",
            program: programA,
            dependencies: ["/tmp/b.hc", "/tmp/c.hc"]
        )

        let order = cache.topologicalOrder(from: ["/tmp/a.hc"])
        let indexA = order.firstIndex(of: "/tmp/a.hc")
        let indexB = order.firstIndex(of: "/tmp/b.hc")
        let indexC = order.firstIndex(of: "/tmp/c.hc")
        let indexD = order.firstIndex(of: "/tmp/d.hc")

        XCTAssertNotNil(indexA)
        XCTAssertNotNil(indexB)
        XCTAssertNotNil(indexC)
        XCTAssertNotNil(indexD)
        XCTAssertLessThan(indexD!, indexB!)
        XCTAssertLessThan(indexB!, indexA!)
        XCTAssertLessThan(indexC!, indexA!)
    }
}
