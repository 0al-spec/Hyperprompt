import XCTest
import Core
@testable import EditorEngine

final class DiagnosticMapperTests: XCTestCase {
    func testSyntaxErrorMapsToSyntaxCode() {
        let error = ConcreteCompilerError.syntaxError(
            message: "Syntax issue",
            location: SourceLocation(filePath: "main.hc", line: 2)
        )

        let diagnostic = DiagnosticMapper.map(error)

        XCTAssertEqual(diagnostic.code, "E001")
        XCTAssertEqual(diagnostic.severity, .error)
        XCTAssertEqual(diagnostic.message, "Syntax issue")
        XCTAssertNotNil(diagnostic.range)
    }

    func testResolutionErrorMapsToResolutionCode() {
        let error = ConcreteCompilerError.resolutionError(
            message: "Resolution issue",
            location: nil
        )

        let diagnostic = DiagnosticMapper.map(error)

        XCTAssertEqual(diagnostic.code, "E100")
        XCTAssertNil(diagnostic.range)
    }

    func testIoErrorMapsToIoCode() {
        let error = ConcreteCompilerError.ioError(
            message: "IO issue",
            location: nil
        )

        let diagnostic = DiagnosticMapper.map(error)

        XCTAssertEqual(diagnostic.code, "E200")
    }

    func testInternalErrorMapsToInternalCode() {
        let error = ConcreteCompilerError.internalError(
            message: "Internal issue",
            location: nil
        )

        let diagnostic = DiagnosticMapper.map(error)

        XCTAssertEqual(diagnostic.code, "E900")
    }

    func testRangeDefaultsToLineWithColumnOne() {
        let error = ConcreteCompilerError.syntaxError(
            message: "Syntax issue",
            location: SourceLocation(filePath: "main.hc", line: 7)
        )

        let diagnostic = DiagnosticMapper.map(error)
        let range = diagnostic.range

        XCTAssertEqual(range?.start.line, 7)
        XCTAssertEqual(range?.start.column, 1)
        XCTAssertEqual(range?.end.line, 7)
        XCTAssertEqual(range?.end.column, 2)
    }
}
