import XCTest
import Core
@testable import Resolver

final class DependencyTrackerTests: XCTestCase {
    private var fileSystem: MockFileSystem!

    override func setUp() {
        super.setUp()
        fileSystem = MockFileSystem()
        fileSystem.setCurrentDirectory("/workspace")
    }

    override func tearDown() {
        fileSystem.clear()
        fileSystem = nil
        super.tearDown()
    }

    func testDetectsSelfReferenceCycle() throws {
        var tracker = DependencyTracker(
            fileSystem: fileSystem,
            initialStack: ["/workspace/main.hc"]
        )

        let error = try tracker.checkAndPush(
            path: "./main.hc",
            location: SourceLocation(filePath: "main.hc", line: 5)
        )

        XCTAssertNotNil(error)
        XCTAssertEqual(error?.cyclePath, ["/workspace/main.hc", "/workspace/main.hc"])
        XCTAssertTrue(error?.message.contains("Circular dependency detected") ?? false)
    }

    func testBuildsCyclePathForTransitiveCycle() throws {
        let tracker = DependencyTracker(
            fileSystem: fileSystem,
            initialStack: [
                "/workspace/a.hc",
                "/workspace/b.hc",
                "/workspace/c.hc"
            ]
        )

        let cyclePath = try tracker.getCyclePath(offendingPath: "/workspace/a.hc")
        XCTAssertEqual(
            cyclePath,
            ["/workspace/a.hc", "/workspace/b.hc", "/workspace/c.hc", "/workspace/a.hc"]
        )
    }

    func testAcyclicPathPushesOnStack() throws {
        var tracker = DependencyTracker(fileSystem: fileSystem, initialStack: ["/workspace/root.hc"])

        let error = try tracker.checkAndPush(
            path: "./libs/module.hc",
            location: SourceLocation(filePath: "root.hc", line: 10)
        )

        XCTAssertNil(error)
        XCTAssertEqual(tracker.stack.last, "/workspace/libs/module.hc")
        XCTAssertFalse(try tracker.isInCycle(path: "other.hc"))
    }
}
