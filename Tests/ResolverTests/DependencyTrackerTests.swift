import XCTest
@testable import Resolver
@testable import Core

/// Unit tests for DependencyTracker circular dependency detection.
///
/// Test coverage:
/// - Direct cycles (A → A)
/// - 2-file cycles (A → B → A)
/// - 3-file cycles (A → B → C → A)
/// - Deep cycles (10+ files)
/// - Acyclic graphs (no false positives)
/// - Cycle path extraction accuracy
/// - Error message formatting
final class DependencyTrackerTests: XCTestCase {

    // MARK: - Direct Cycle Tests (A → A)

    func testDirectSelfReference() {
        // Test case: A file references itself directly
        // Stack: ["/root/main.hc"]
        // Check: "/root/main.hc" (should detect cycle)

        let tracker = DependencyTracker()
        let stack = ["/root/main.hc"]
        let path = "/root/main.hc"

        // Should detect cycle
        XCTAssertTrue(tracker.isInCycle(path: path, stack: stack))

        // Cycle path should show: main.hc → main.hc
        let cyclePath = tracker.getCyclePath(stack: stack, offendingPath: path)
        XCTAssertEqual(cyclePath, ["/root/main.hc", "/root/main.hc"])
    }

    func testDirectCycleAtDepth() {
        // Test case: Self-reference at non-root level
        // Stack: ["/root/main.hc", "/root/a.hc", "/root/b.hc"]
        // Check: "/root/b.hc" (should detect cycle)

        let tracker = DependencyTracker()
        let stack = ["/root/main.hc", "/root/a.hc", "/root/b.hc"]
        let path = "/root/b.hc"

        XCTAssertTrue(tracker.isInCycle(path: path, stack: stack))

        let cyclePath = tracker.getCyclePath(stack: stack, offendingPath: path)
        XCTAssertEqual(cyclePath, ["/root/b.hc", "/root/b.hc"])
    }

    // MARK: - 2-File Cycle Tests (A → B → A)

    func testTwoFileCycle() {
        // Test case: A → B → A
        // Stack: ["/root/a.hc", "/root/b.hc"]
        // Check: "/root/a.hc" (should detect cycle)

        let tracker = DependencyTracker()
        let stack = ["/root/a.hc", "/root/b.hc"]
        let path = "/root/a.hc"

        XCTAssertTrue(tracker.isInCycle(path: path, stack: stack))

        let cyclePath = tracker.getCyclePath(stack: stack, offendingPath: path)
        XCTAssertEqual(cyclePath, ["/root/a.hc", "/root/b.hc", "/root/a.hc"])
    }

    func testTwoFileCycleWithPrefix() {
        // Test case: main → a → b → a (cycle in subtree)
        // Stack: ["/root/main.hc", "/root/a.hc", "/root/b.hc"]
        // Check: "/root/a.hc" (should detect cycle)

        let tracker = DependencyTracker()
        let stack = ["/root/main.hc", "/root/a.hc", "/root/b.hc"]
        let path = "/root/a.hc"

        XCTAssertTrue(tracker.isInCycle(path: path, stack: stack))

        // Cycle should exclude main.hc (not part of cycle)
        let cyclePath = tracker.getCyclePath(stack: stack, offendingPath: path)
        XCTAssertEqual(cyclePath, ["/root/a.hc", "/root/b.hc", "/root/a.hc"])
    }

    // MARK: - 3-File Cycle Tests (A → B → C → A)

    func testThreeFileCycle() {
        // Test case: A → B → C → A
        // Stack: ["/root/a.hc", "/root/b.hc", "/root/c.hc"]
        // Check: "/root/a.hc" (should detect cycle)

        let tracker = DependencyTracker()
        let stack = ["/root/a.hc", "/root/b.hc", "/root/c.hc"]
        let path = "/root/a.hc"

        XCTAssertTrue(tracker.isInCycle(path: path, stack: stack))

        let cyclePath = tracker.getCyclePath(stack: stack, offendingPath: path)
        XCTAssertEqual(cyclePath, ["/root/a.hc", "/root/b.hc", "/root/c.hc", "/root/a.hc"])
    }

    func testThreeFileCycleWithLongPrefix() {
        // Test case: main → x → y → a → b → c → a (cycle deep in tree)
        // Stack: ["/root/main.hc", "/root/x.hc", "/root/y.hc", "/root/a.hc", "/root/b.hc", "/root/c.hc"]
        // Check: "/root/a.hc" (should detect cycle)

        let tracker = DependencyTracker()
        let stack = ["/root/main.hc", "/root/x.hc", "/root/y.hc", "/root/a.hc", "/root/b.hc", "/root/c.hc"]
        let path = "/root/a.hc"

        XCTAssertTrue(tracker.isInCycle(path: path, stack: stack))

        // Cycle should only include a → b → c → a
        let cyclePath = tracker.getCyclePath(stack: stack, offendingPath: path)
        XCTAssertEqual(cyclePath, ["/root/a.hc", "/root/b.hc", "/root/c.hc", "/root/a.hc"])
    }

    // MARK: - Deep Cycle Tests (10+ Files)

    func testDeepCycle() {
        // Test case: Long cycle chain with 10+ files
        // Stack: [f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12]
        // Check: f1 (should detect cycle)

        let tracker = DependencyTracker()
        let stack = (1...12).map { "/root/file\($0).hc" }
        let path = "/root/file1.hc"

        XCTAssertTrue(tracker.isInCycle(path: path, stack: stack))

        let cyclePath = tracker.getCyclePath(stack: stack, offendingPath: path)
        XCTAssertEqual(cyclePath.count, 13) // 12 files + 1 repeat
        XCTAssertEqual(cyclePath.first, "/root/file1.hc")
        XCTAssertEqual(cyclePath.last, "/root/file1.hc")
    }

    func testDeepCycleInMiddle() {
        // Test case: Long prefix + cycle in middle
        // Stack: [f1, f2, f3, f4, f5, f6, f7, f8]
        // Check: f5 (cycle from f5 → f6 → f7 → f8 → f5)

        let tracker = DependencyTracker()
        let stack = (1...8).map { "/root/file\($0).hc" }
        let path = "/root/file5.hc"

        XCTAssertTrue(tracker.isInCycle(path: path, stack: stack))

        let cyclePath = tracker.getCyclePath(stack: stack, offendingPath: path)
        XCTAssertEqual(cyclePath, [
            "/root/file5.hc",
            "/root/file6.hc",
            "/root/file7.hc",
            "/root/file8.hc",
            "/root/file5.hc"
        ])
    }

    // MARK: - Acyclic Graph Tests (No False Positives)

    func testLinearChainNoCycle() {
        // Test case: A → B → C → D (no cycle)
        // Stack: ["/root/a.hc", "/root/b.hc", "/root/c.hc"]
        // Check: "/root/d.hc" (should NOT detect cycle)

        let tracker = DependencyTracker()
        let stack = ["/root/a.hc", "/root/b.hc", "/root/c.hc"]
        let path = "/root/d.hc"

        XCTAssertFalse(tracker.isInCycle(path: path, stack: stack))
    }

    func testEmptyStack() {
        // Test case: Empty stack (first file)
        // Stack: []
        // Check: "/root/main.hc" (should NOT detect cycle)

        let tracker = DependencyTracker()
        let stack: [String] = []
        let path = "/root/main.hc"

        XCTAssertFalse(tracker.isInCycle(path: path, stack: stack))
    }

    func testDAGWithMultiplePaths() {
        // Test case: Diamond pattern (A → {B, C} → D)
        // File D is referenced from both B and C, but no cycle exists
        // Stack: ["/root/a.hc", "/root/b.hc"]
        // Check: "/root/d.hc" (should NOT detect cycle)

        let tracker = DependencyTracker()
        let stackFromB = ["/root/a.hc", "/root/b.hc"]
        let path = "/root/d.hc"

        XCTAssertFalse(tracker.isInCycle(path: path, stack: stackFromB))

        // Also check from C path
        let stackFromC = ["/root/a.hc", "/root/c.hc"]
        XCTAssertFalse(tracker.isInCycle(path: path, stack: stackFromC))
    }

    func testFileReferencedFromMultipleParents() {
        // Test case: Common dependency (both A and B reference C)
        // Processing A → C:
        // Stack: ["/root/main.hc", "/root/a.hc"]
        // Check: "/root/c.hc" (should NOT detect cycle)
        //
        // Later processing B → C:
        // Stack: ["/root/main.hc", "/root/b.hc"]
        // Check: "/root/c.hc" (should NOT detect cycle)

        let tracker = DependencyTracker()

        // First path: main → a → c
        let stackA = ["/root/main.hc", "/root/a.hc"]
        XCTAssertFalse(tracker.isInCycle(path: "/root/c.hc", stack: stackA))

        // Second path: main → b → c (independent)
        let stackB = ["/root/main.hc", "/root/b.hc"]
        XCTAssertFalse(tracker.isInCycle(path: "/root/c.hc", stack: stackB))
    }

    // MARK: - Cycle Path Extraction Tests

    func testGetCyclePathEmptyStack() {
        // Edge case: Empty stack with offending path
        // This shouldn't happen in practice, but handle defensively

        let tracker = DependencyTracker()
        let stack: [String] = []
        let path = "/root/a.hc"

        let cyclePath = tracker.getCyclePath(stack: stack, offendingPath: path)
        // Should return [offendingPath] when stack is empty
        XCTAssertEqual(cyclePath, ["/root/a.hc"])
    }

    func testGetCyclePathNotInStack() {
        // Edge case: Offending path not actually in stack
        // This shouldn't happen if isInCycle was called first, but handle defensively

        let tracker = DependencyTracker()
        let stack = ["/root/a.hc", "/root/b.hc"]
        let path = "/root/x.hc" // Not in stack

        let cyclePath = tracker.getCyclePath(stack: stack, offendingPath: path)
        // Should return entire stack + offending path
        XCTAssertEqual(cyclePath, ["/root/a.hc", "/root/b.hc", "/root/x.hc"])
    }

    func testGetCyclePathAtStackStart() {
        // Test case: Cycle back to first element in stack
        // Stack: ["/root/a.hc", "/root/b.hc", "/root/c.hc"]
        // Offending: "/root/a.hc"

        let tracker = DependencyTracker()
        let stack = ["/root/a.hc", "/root/b.hc", "/root/c.hc"]
        let path = "/root/a.hc"

        let cyclePath = tracker.getCyclePath(stack: stack, offendingPath: path)
        XCTAssertEqual(cyclePath, ["/root/a.hc", "/root/b.hc", "/root/c.hc", "/root/a.hc"])
    }

    func testGetCyclePathAtStackEnd() {
        // Test case: Direct self-reference (last element)
        // Stack: ["/root/a.hc", "/root/b.hc", "/root/c.hc"]
        // Offending: "/root/c.hc"

        let tracker = DependencyTracker()
        let stack = ["/root/a.hc", "/root/b.hc", "/root/c.hc"]
        let path = "/root/c.hc"

        let cyclePath = tracker.getCyclePath(stack: stack, offendingPath: path)
        XCTAssertEqual(cyclePath, ["/root/c.hc", "/root/c.hc"])
    }

    // MARK: - Error Message Formatting Tests

    func testCircularDependencyErrorMessage() {
        // Test the ResolutionError.circularDependency factory method

        let cyclePath = ["/root/a.hc", "/root/b.hc", "/root/c.hc", "/root/a.hc"]
        let location = SourceLocation(filePath: "/root/c.hc", line: 5)

        let error = ResolutionError.circularDependency(cyclePath: cyclePath, location: location)

        // Verify error properties
        XCTAssertEqual(error.category, .resolution)
        XCTAssertEqual(error.location?.filePath, "/root/c.hc")
        XCTAssertEqual(error.location?.line, 5)

        // Verify message format
        let expectedMessage = """
        Circular dependency detected
          Cycle path: /root/a.hc → /root/b.hc → /root/c.hc → /root/a.hc
        """
        XCTAssertEqual(error.message, expectedMessage)
    }

    func testCircularDependencyErrorWithShortCycle() {
        // Test error message for direct self-reference

        let cyclePath = ["/root/main.hc", "/root/main.hc"]
        let location = SourceLocation(filePath: "/root/main.hc", line: 10)

        let error = ResolutionError.circularDependency(cyclePath: cyclePath, location: location)

        let expectedMessage = """
        Circular dependency detected
          Cycle path: /root/main.hc → /root/main.hc
        """
        XCTAssertEqual(error.message, expectedMessage)
    }

    func testCircularDependencyErrorWithLongCycle() {
        // Test error message for deep cycle

        let cyclePath = (1...6).map { "/root/file\($0).hc" } + ["/root/file1.hc"]
        let location = SourceLocation(filePath: "/root/file6.hc", line: 3)

        let error = ResolutionError.circularDependency(cyclePath: cyclePath, location: location)

        let expectedMessage = """
        Circular dependency detected
          Cycle path: /root/file1.hc → /root/file2.hc → /root/file3.hc → /root/file4.hc → /root/file5.hc → /root/file6.hc → /root/file1.hc
        """
        XCTAssertEqual(error.message, expectedMessage)
    }

    // MARK: - Integration Tests with ReferenceResolver

    func testReferenceResolverCheckForCycle() {
        // Test the ReferenceResolver integration with DependencyTracker

        let fileSystem = MockFileSystem(files: [:])
        var resolver = ReferenceResolver(
            fileSystem: fileSystem,
            rootPath: "/root",
            mode: .strict
        )

        // Simulate processing main.hc → a.hc → b.hc
        resolver.pushVisitationStack(path: "main.hc")
        resolver.pushVisitationStack(path: "a.hc")
        resolver.pushVisitationStack(path: "b.hc")

        // Check for cycle when trying to reference a.hc again
        let result = resolver.checkForCycle(path: "a.hc")

        // Should detect cycle
        if case .failure(let cyclePath) = result {
            XCTAssertEqual(cyclePath, [
                "/root/a.hc",
                "/root/b.hc",
                "/root/a.hc"
            ])
        } else {
            XCTFail("Expected cycle to be detected")
        }
    }

    func testReferenceResolverStackManagement() {
        // Test push/pop operations maintain stack correctly

        let fileSystem = MockFileSystem(files: [:])
        var resolver = ReferenceResolver(
            fileSystem: fileSystem,
            rootPath: "/root",
            mode: .strict
        )

        XCTAssertTrue(resolver.visitationStack.isEmpty)

        resolver.pushVisitationStack(path: "a.hc")
        XCTAssertEqual(resolver.visitationStack, ["/root/a.hc"])

        resolver.pushVisitationStack(path: "b.hc")
        XCTAssertEqual(resolver.visitationStack, ["/root/a.hc", "/root/b.hc"])

        resolver.popVisitationStack()
        XCTAssertEqual(resolver.visitationStack, ["/root/a.hc"])

        resolver.popVisitationStack()
        XCTAssertTrue(resolver.visitationStack.isEmpty)

        // Pop on empty stack should be safe
        resolver.popVisitationStack()
        XCTAssertTrue(resolver.visitationStack.isEmpty)
    }

    func testReferenceResolverClearStack() {
        // Test clearing the visitation stack

        let fileSystem = MockFileSystem(files: [:])
        var resolver = ReferenceResolver(
            fileSystem: fileSystem,
            rootPath: "/root",
            mode: .strict
        )

        resolver.pushVisitationStack(path: "a.hc")
        resolver.pushVisitationStack(path: "b.hc")
        resolver.pushVisitationStack(path: "c.hc")

        XCTAssertEqual(resolver.visitationStack.count, 3)

        resolver.clearVisitationStack()
        XCTAssertTrue(resolver.visitationStack.isEmpty)
    }

    func testReferenceResolverNoCycleInAcyclicGraph() {
        // Test that acyclic graphs don't trigger false positives

        let fileSystem = MockFileSystem(files: [:])
        var resolver = ReferenceResolver(
            fileSystem: fileSystem,
            rootPath: "/root",
            mode: .strict
        )

        resolver.pushVisitationStack(path: "main.hc")
        resolver.pushVisitationStack(path: "a.hc")
        resolver.pushVisitationStack(path: "b.hc")

        // Check for cycle with a new file (should not detect cycle)
        let result = resolver.checkForCycle(path: "c.hc")

        if case .failure = result {
            XCTFail("Should not detect cycle in acyclic graph")
        }
    }
}
