import XCTest
import Core
@testable import EditorEngine

final class EditorParserTests: XCTestCase {
    func testParseFilePathReportsIOError() {
        let fileSystem = FailingFileSystem()
        let parser = EditorParser(fileSystem: fileSystem)
        let result = parser.parse(filePath: "/workspace/missing.hc")

        XCTAssertNil(result.ast)
        XCTAssertTrue(result.linkSpans.isEmpty)
        XCTAssertEqual(result.sourceFile, "/workspace/missing.hc")
        XCTAssertEqual(result.diagnostics.count, 1)

        let diagnostic = result.diagnostics[0]
        XCTAssertEqual(diagnostic.category, .io)
        XCTAssertTrue(diagnostic.message.contains("File not found"))
    }
}

private final class FailingFileSystem: FileSystem {
    func readFile(at path: String) throws -> String {
        throw TestFileSystemError(message: "File not found: \(path)")
    }

    func fileExists(at path: String) -> Bool {
        false
    }

    func canonicalizePath(_ path: String) throws -> String {
        throw TestFileSystemError(message: "Invalid path: \(path)")
    }

    func currentDirectory() -> String {
        "/"
    }

    func writeFile(at path: String, content: String) throws {
        throw TestFileSystemError(message: "Write not supported: \(path)")
    }

    func listDirectory(at path: String) throws -> [String] {
        throw TestFileSystemError(message: "List not supported: \(path)")
    }

    func isDirectory(at path: String) -> Bool {
        false
    }

    func fileAttributes(at path: String) -> FileAttributes? {
        nil
    }
}

private struct TestFileSystemError: CompilerError {
    let category: ErrorCategory = .io
    let message: String
    let location: SourceLocation? = nil
}
