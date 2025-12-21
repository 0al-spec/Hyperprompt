import XCTest
import Core
import Resolver
@testable import EditorEngine

final class EditorResolverTests: XCTestCase {
    func testInlineTextReturnsInlineTarget() {
        let fs = MockFileSystem(currentDirectory: "/cwd")
        let resolver = EditorResolver(fileSystem: fs, workspaceRoot: "/workspace", mode: .strict)
        let link = LinkSpan(
            literal: "Hello world",
            byteRange: 0..<11,
            lineRange: 1..<2,
            columnRange: 1..<12,
            isFileReference: false,
            sourceFile: "/workspace/main.hc"
        )

        let result = resolver.resolve(link: link)

        XCTAssertEqual(result.target, .inlineText)
        XCTAssertTrue(result.diagnostics.isEmpty)
    }

    func testMarkdownFileResolvesToMarkdownTarget() {
        let fs = MockFileSystem(currentDirectory: "/cwd")
        fs.addFile(path: "/workspace/docs/readme.md")

        let resolver = EditorResolver(fileSystem: fs, workspaceRoot: "/workspace", mode: .strict)
        let link = LinkSpan(
            literal: "docs/readme.md",
            byteRange: 0..<14,
            lineRange: 1..<2,
            columnRange: 1..<15,
            isFileReference: true,
            sourceFile: "/workspace/main.hc"
        )

        let result = resolver.resolve(link: link)

        XCTAssertEqual(result.target, .markdownFile(path: "/workspace/docs/readme.md"))
        XCTAssertTrue(result.diagnostics.isEmpty)
    }

    func testHypercodeFileResolvesToHypercodeTarget() {
        let fs = MockFileSystem(currentDirectory: "/cwd")
        fs.addFile(path: "/workspace/src/main.hc")

        let resolver = EditorResolver(fileSystem: fs, workspaceRoot: "/workspace", mode: .strict)
        let link = LinkSpan(
            literal: "src/main.hc",
            byteRange: 0..<10,
            lineRange: 1..<2,
            columnRange: 1..<11,
            isFileReference: true,
            sourceFile: "/workspace/main.hc"
        )

        let result = resolver.resolve(link: link)

        XCTAssertEqual(result.target, .hypercodeFile(path: "/workspace/src/main.hc"))
        XCTAssertTrue(result.diagnostics.isEmpty)
    }

    func testForbiddenExtensionReturnsForbiddenTarget() {
        let fs = MockFileSystem(currentDirectory: "/cwd")
        let resolver = EditorResolver(fileSystem: fs, workspaceRoot: "/workspace", mode: .strict)
        let link = LinkSpan(
            literal: "notes.txt",
            byteRange: 0..<9,
            lineRange: 1..<2,
            columnRange: 1..<10,
            isFileReference: true,
            sourceFile: "/workspace/main.hc"
        )

        let result = resolver.resolve(link: link)

        XCTAssertEqual(result.target, .forbidden(extension: "txt"))
        XCTAssertFalse(result.diagnostics.isEmpty)
    }

    func testPathTraversalReturnsInvalidTarget() {
        let fs = MockFileSystem(currentDirectory: "/cwd")
        let resolver = EditorResolver(fileSystem: fs, workspaceRoot: "/workspace", mode: .strict)
        let link = LinkSpan(
            literal: "../secret.md",
            byteRange: 0..<12,
            lineRange: 1..<2,
            columnRange: 1..<13,
            isFileReference: true,
            sourceFile: "/workspace/main.hc"
        )

        let result = resolver.resolve(link: link)

        if case .invalid(let reason) = result.target {
            XCTAssertTrue(reason.contains("Path traversal"))
        } else {
            XCTFail("Expected invalid target for path traversal")
        }
        XCTAssertFalse(result.diagnostics.isEmpty)
    }

    func testAmbiguousResolutionReturnsAmbiguousTarget() {
        let fs = MockFileSystem(currentDirectory: "/cwd")
        fs.addFile(path: "/workspace/docs/readme.md")
        fs.addFile(path: "/cwd/docs/readme.md")

        let resolver = EditorResolver(fileSystem: fs, workspaceRoot: "/workspace", mode: .strict)
        let link = LinkSpan(
            literal: "docs/readme.md",
            byteRange: 0..<14,
            lineRange: 1..<2,
            columnRange: 1..<15,
            isFileReference: true,
            sourceFile: "/project/main.hc"
        )

        let result = resolver.resolve(link: link)

        if case .ambiguous(let candidates) = result.target {
            XCTAssertTrue(candidates.contains("/workspace/docs/readme.md"))
            XCTAssertTrue(candidates.contains("/cwd/docs/readme.md"))
        } else {
            XCTFail("Expected ambiguous target")
        }
        XCTAssertFalse(result.diagnostics.isEmpty)
    }
}

private final class MockFileSystem: FileSystem {
    private var files: [String: String] = [:]
    private var currentDir: String

    init(currentDirectory: String) {
        self.currentDir = currentDirectory
    }

    func addFile(path: String, content: String = "") {
        files[path] = content
    }

    func readFile(at path: String) throws -> String {
        guard let content = files[path] else {
            throw MockFileSystemError(message: "File not found: \(path)")
        }
        return content
    }

    func fileExists(at path: String) -> Bool {
        files[path] != nil
    }

    func canonicalizePath(_ path: String) throws -> String {
        if path.hasPrefix("/") {
            return path
        }
        return currentDir + "/" + path
    }

    func currentDirectory() -> String {
        currentDir
    }

    func writeFile(at path: String, content: String) throws {
        files[path] = content
    }

    func listDirectory(at path: String) throws -> [String] {
        []
    }

    func isDirectory(at path: String) -> Bool {
        false
    }

    func fileAttributes(at path: String) -> FileAttributes? {
        guard let content = files[path] else {
            return nil
        }
        return FileAttributes(size: content.utf8.count)
    }
}

private struct MockFileSystemError: CompilerError {
    let category: ErrorCategory = .io
    let message: String
    let location: SourceLocation? = nil
}
