import XCTest
@testable import Parser
@testable import Core

/// Tests for the Parser component (AST construction).
///
/// Tests cover:
/// - Valid tree structures (single root, nested hierarchy, wide/deep trees)
/// - Invalid structures (multiple roots, no root, depth gaps, exceeded depth)
/// - Token handling (blank, comment, node)
/// - Error reporting and location tracking
final class ParserTests: XCTestCase {
    var parser: Parser!

    override func setUp() {
        super.setUp()
        parser = Parser()
    }

    // MARK: - Valid Structures

    func test_parser_valid_single_root() {
        let location = SourceLocation(filePath: "test.hc", line: 1)
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: location)
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isSuccess)
        let program = try! result.get()
        XCTAssertEqual(program.root.literal, "root")
        XCTAssertEqual(program.root.depth, 0)
        XCTAssertEqual(program.root.children.count, 0)
    }

    func test_parser_valid_root_with_single_child() {
        let loc1 = SourceLocation(filePath: "test.hc", line: 1)
        let loc2 = SourceLocation(filePath: "test.hc", line: 2)
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: loc1),
            .node(indent: 4, literal: "child", location: loc2)
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isSuccess)
        let program = try! result.get()
        XCTAssertEqual(program.root.literal, "root")
        XCTAssertEqual(program.root.children.count, 1)
        XCTAssertEqual(program.root.children[0].literal, "child")
        XCTAssertEqual(program.root.children[0].depth, 1)
    }

    func test_parser_valid_root_with_multiple_siblings() {
        let loc1 = SourceLocation(filePath: "test.hc", line: 1)
        let loc2 = SourceLocation(filePath: "test.hc", line: 2)
        let loc3 = SourceLocation(filePath: "test.hc", line: 3)
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: loc1),
            .node(indent: 4, literal: "child1", location: loc2),
            .node(indent: 4, literal: "child2", location: loc3)
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isSuccess)
        let program = try! result.get()
        XCTAssertEqual(program.root.children.count, 2)
        XCTAssertEqual(program.root.children[0].literal, "child1")
        XCTAssertEqual(program.root.children[1].literal, "child2")
    }

    func test_parser_valid_three_level_nesting() {
        let loc1 = SourceLocation(filePath: "test.hc", line: 1)
        let loc2 = SourceLocation(filePath: "test.hc", line: 2)
        let loc3 = SourceLocation(filePath: "test.hc", line: 3)
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: loc1),
            .node(indent: 4, literal: "level1", location: loc2),
            .node(indent: 8, literal: "level2", location: loc3)
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isSuccess)
        let program = try! result.get()
        XCTAssertEqual(program.root.children.count, 1)
        XCTAssertEqual(program.root.children[0].children.count, 1)
        XCTAssertEqual(program.root.children[0].children[0].literal, "level2")
        XCTAssertEqual(program.root.children[0].children[0].depth, 2)
    }

    func test_parser_valid_maximum_depth_10() {
        var tokens: [Token] = []
        for depth in 0...10 {
            let indent = depth * 4
            let location = SourceLocation(filePath: "test.hc", line: depth + 1)
            tokens.append(.node(indent: indent, literal: "node\(depth)", location: location))
        }

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isSuccess)
        let program = try! result.get()
        XCTAssertEqual(program.maxDepth, 10)
        XCTAssertEqual(program.nodeCount, 11)
    }

    func test_parser_valid_complex_tree() {
        let loc = { SourceLocation(filePath: "test.hc", line: $0) }
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: loc(1)),
            .node(indent: 4, literal: "a", location: loc(2)),
            .node(indent: 8, literal: "a1", location: loc(3)),
            .node(indent: 8, literal: "a2", location: loc(4)),
            .node(indent: 4, literal: "b", location: loc(5)),
            .node(indent: 8, literal: "b1", location: loc(6))
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isSuccess)
        let program = try! result.get()
        XCTAssertEqual(program.root.literal, "root")
        XCTAssertEqual(program.root.children.count, 2)
        XCTAssertEqual(program.root.children[0].literal, "a")
        XCTAssertEqual(program.root.children[0].children.count, 2)
        XCTAssertEqual(program.root.children[1].literal, "b")
        XCTAssertEqual(program.root.children[1].children.count, 1)
    }

    func test_parser_valid_with_blank_lines() {
        let loc = { SourceLocation(filePath: "test.hc", line: $0) }
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: loc(1)),
            .blank(location: loc(2)),
            .node(indent: 4, literal: "child", location: loc(3))
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isSuccess)
        let program = try! result.get()
        XCTAssertEqual(program.root.children.count, 1)
    }

    func test_parser_valid_with_comment_lines() {
        let loc = { SourceLocation(filePath: "test.hc", line: $0) }
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: loc(1)),
            .comment(indent: 0, location: loc(2)),
            .node(indent: 4, literal: "child", location: loc(3))
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isSuccess)
        let program = try! result.get()
        XCTAssertEqual(program.root.children.count, 1)
    }

    // MARK: - Invalid Structures

    func test_parser_invalid_multiple_roots() {
        let loc = { SourceLocation(filePath: "test.hc", line: $0) }
        let tokens: [Token] = [
            .node(indent: 0, literal: "root1", location: loc(1)),
            .node(indent: 0, literal: "root2", location: loc(2))
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result,
           case .multipleRoots(let locations) = error {
            XCTAssertEqual(locations.count, 2)
        } else {
            XCTFail("Expected multipleRoots error")
        }
    }

    func test_parser_invalid_no_root() {
        let loc = { SourceLocation(filePath: "test.hc", line: $0) }
        let tokens: [Token] = [
            .node(indent: 4, literal: "orphan", location: loc(1))
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result,
           case .invalidDepthJump = error {
            // Expected
        } else {
            XCTFail("Expected invalidDepthJump error")
        }
    }

    func test_parser_invalid_depth_jump_0_to_2() {
        let loc = { SourceLocation(filePath: "test.hc", line: $0) }
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: loc(1)),
            .node(indent: 8, literal: "invalid", location: loc(2))
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result,
           case .invalidDepthJump(let from, let to, _) = error {
            XCTAssertEqual(from, 0)
            XCTAssertEqual(to, 2)
        } else {
            XCTFail("Expected invalidDepthJump error")
        }
    }

    func test_parser_invalid_depth_jump_1_to_3() {
        let loc = { SourceLocation(filePath: "test.hc", line: $0) }
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: loc(1)),
            .node(indent: 4, literal: "level1", location: loc(2)),
            .node(indent: 12, literal: "invalid", location: loc(3))
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result,
           case .invalidDepthJump(let from, let to, _) = error {
            XCTAssertEqual(from, 1)
            XCTAssertEqual(to, 3)
        } else {
            XCTFail("Expected invalidDepthJump error")
        }
    }

    func test_parser_invalid_depth_exceeded() {
        let loc = { SourceLocation(filePath: "test.hc", line: $0) }
        var tokens: [Token] = []
        for depth in 0...11 {
            let indent = depth * 4
            tokens.append(.node(indent: indent, literal: "node\(depth)", location: loc(depth + 1)))
        }

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result,
           case .depthExceeded(let depth, _) = error {
            XCTAssertEqual(depth, 11)
        } else {
            XCTFail("Expected depthExceeded error")
        }
    }

    // MARK: - Edge Cases

    func test_parser_empty_token_stream() {
        let tokens: [Token] = []

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result,
           case .emptyTokenStream = error {
            // Expected
        } else {
            XCTFail("Expected emptyTokenStream error")
        }
    }

    func test_parser_only_blank_and_comment_tokens() {
        let loc = { SourceLocation(filePath: "test.hc", line: $0) }
        let tokens: [Token] = [
            .blank(location: loc(1)),
            .comment(indent: 0, location: loc(2)),
            .blank(location: loc(3))
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result,
           case .emptyTokenStream = error {
            // Expected
        } else {
            XCTFail("Expected emptyTokenStream error")
        }
    }

    func test_parser_resets_after_depth_decrease() {
        let loc = { SourceLocation(filePath: "test.hc", line: $0) }
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: loc(1)),
            .node(indent: 4, literal: "a", location: loc(2)),
            .node(indent: 8, literal: "a1", location: loc(3)),
            .node(indent: 4, literal: "b", location: loc(4)),
            .node(indent: 8, literal: "b1", location: loc(5))
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isSuccess)
        let program = try! result.get()
        XCTAssertEqual(program.root.children.count, 2)
        XCTAssertEqual(program.root.children[0].literal, "a")
        XCTAssertEqual(program.root.children[0].children[0].literal, "a1")
        XCTAssertEqual(program.root.children[1].literal, "b")
        XCTAssertEqual(program.root.children[1].children[0].literal, "b1")
    }

    // MARK: - Source Location Tracking

    func test_parser_preserves_source_locations() {
        let loc1 = SourceLocation(filePath: "main.hc", line: 5)
        let loc2 = SourceLocation(filePath: "main.hc", line: 10)
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: loc1),
            .node(indent: 4, literal: "child", location: loc2)
        ]

        let result = parser.parse(tokens: tokens)

        XCTAssertTrue(result.isSuccess)
        let program = try! result.get()
        XCTAssertEqual(program.root.location, loc1)
        XCTAssertEqual(program.root.children[0].location, loc2)
    }

    func test_parser_error_includes_location() {
        let loc = SourceLocation(filePath: "test.hc", line: 42)
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: loc),
            .node(indent: 12, literal: "invalid", location: loc)
        ]

        let result = parser.parse(tokens: tokens)

        guard case .failure(let error) = result else {
            XCTFail("Expected error")
            return
        }
        XCTAssertNotNil(error.location)
        XCTAssertEqual(error.location?.line, 42)
    }

    // MARK: - Program Properties

    func test_program_node_count() {
        let loc = { SourceLocation(filePath: "test.hc", line: $0) }
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: loc(1)),
            .node(indent: 4, literal: "a", location: loc(2)),
            .node(indent: 4, literal: "b", location: loc(3)),
            .node(indent: 8, literal: "b1", location: loc(4))
        ]

        let result = parser.parse(tokens: tokens)
        let program = try! result.get()

        XCTAssertEqual(program.nodeCount, 4)
    }

    func test_program_max_depth() {
        let loc = { SourceLocation(filePath: "test.hc", line: $0) }
        let tokens: [Token] = [
            .node(indent: 0, literal: "root", location: loc(1)),
            .node(indent: 4, literal: "a", location: loc(2)),
            .node(indent: 8, literal: "b", location: loc(3)),
            .node(indent: 12, literal: "c", location: loc(4))
        ]

        let result = parser.parse(tokens: tokens)
        let program = try! result.get()

        XCTAssertEqual(program.maxDepth, 3)
    }
}

// MARK: - Helper Extension

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    var isFailure: Bool {
        !isSuccess
    }
}
