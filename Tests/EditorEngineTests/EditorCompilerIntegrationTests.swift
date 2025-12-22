import XCTest
import CLI
import Core
@testable import EditorEngine

final class EditorCompilerIntegrationTests: XCTestCase {
    func testEditorCompilerMatchesCLI_V01() throws {
        try assertEditorMatchesCLI(fixture: "V01.hc")
    }

    func testEditorCompilerMatchesCLI_V03() throws {
        try assertEditorMatchesCLI(fixture: "V03.hc")
    }

    func testEditorCompilerMatchesCLI_V11() throws {
        try assertEditorMatchesCLI(fixture: "V11.hc")
    }

    func testEditorCompilerMatchesCLI_V15() throws {
        try assertEditorMatchesCLI(fixture: "V15.hc")
    }

    private func assertEditorMatchesCLI(fixture: String) throws {
        let inputPath = fixturePath(fixture)
        let outputPath = defaultOutputPath(for: inputPath)
        let manifestPath = defaultManifestPath(for: outputPath)
        let rootPath = defaultRootPath(for: inputPath)

        let cliArgs = CompilerArguments(
            input: inputPath,
            output: outputPath,
            manifest: manifestPath,
            root: rootPath,
            mode: .strict,
            verbose: false,
            stats: false,
            dryRun: true
        )

        let driver = CompilerDriver()
        let cliResult = try driver.compile(cliArgs)

        let compiler = EditorCompiler()
        let options = CompileOptions(
            mode: .strict,
            workspaceRoot: rootPath,
            outputPath: outputPath,
            manifestPath: manifestPath,
            manifestPolicy: .include,
            statisticsPolicy: .omit,
            outputWritePolicy: .dryRun
        )
        let editorResult = compiler.compile(entryFile: inputPath, options: options)

        XCTAssertEqual(editorResult.output, cliResult.markdown)
        XCTAssertEqual(editorResult.manifest, cliResult.manifestJSON)
        XCTAssertTrue(editorResult.diagnostics.isEmpty)
    }

    private func fixturePath(_ name: String) -> String {
        let root = FileManager.default.currentDirectoryPath
        return root + "/Tests/IntegrationTests/Fixtures/Valid/" + name
    }

    private func defaultOutputPath(for input: String) -> String {
        if input.hasSuffix(".hc") {
            return String(input.dropLast(3)) + ".md"
        }
        return input + ".md"
    }

    private func defaultManifestPath(for output: String) -> String {
        output + ".manifest.json"
    }

    private func defaultRootPath(for input: String) -> String {
        if let lastSlash = input.lastIndex(of: "/") {
            return String(input[..<lastSlash])
        }
        return "."
    }
}
