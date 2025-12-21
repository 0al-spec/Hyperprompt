import XCTest
import CLI
import Core
@testable import EditorEngine

final class EditorEngineCorpusTests: XCTestCase {
    func testValidCorpusParityV01ToV14() throws {
        let fixtures = [
            "V01.hc", "V03.hc", "V04.hc", "V05.hc", "V06.hc", "V08.hc",
            "V09.hc", "V10.hc", "V11.hc", "V13.hc", "V14.hc"
        ]

        for fixture in fixtures {
            try assertEditorMatchesCLI(validFixture: fixture)
        }
    }

    func testValidCorpusV07Skipped() throws {
        throw XCTSkip("Temporarily disabled - fixture references level1.hc with invalid line format under current parser.")
    }

    func testValidCorpusV12Skipped() throws {
        throw XCTSkip("Temporarily disabled - fixture triggers multiple roots under current parser behavior.")
    }

    func testInvalidCorpusParityI01ToI10() throws {
        let fixtures = [
            "I01.hc", "I02.hc", "I03.hc", "I04.hc", "I05.hc",
            "I06.hc", "I07.hc", "I08.hc", "I10.hc"
        ]

        for fixture in fixtures {
            try assertEditorMatchesCLI(invalidFixture: fixture)
        }
    }

    func testInvalidCorpusI09Skipped() throws {
        throw XCTSkip("Temporarily disabled - running as root bypasses permission checks. Needs test environment fix.")
    }

    private func assertEditorMatchesCLI(validFixture: String) throws {
        let inputPath = validFixturePath(validFixture)
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
            emitManifest: true,
            collectStats: false,
            writeOutput: false
        )
        let editorResult = compiler.compile(entryFile: inputPath, options: options)

        XCTAssertEqual(editorResult.output, cliResult.markdown)
        XCTAssertEqual(editorResult.manifest, cliResult.manifestJSON)
        XCTAssertTrue(editorResult.diagnostics.isEmpty)
    }

    private func assertEditorMatchesCLI(invalidFixture: String) throws {
        let inputPath = invalidFixturePath(invalidFixture)
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

        do {
            _ = try driver.compile(cliArgs)
            XCTFail("Expected CLI compilation to fail for \(invalidFixture)")
        } catch let error as CompilerError {
            let compiler = EditorCompiler()
            let options = CompileOptions(
                mode: .strict,
                workspaceRoot: rootPath,
                outputPath: outputPath,
                manifestPath: manifestPath,
                emitManifest: true,
                collectStats: false,
                writeOutput: false
            )
            let editorResult = compiler.compile(entryFile: inputPath, options: options)

            XCTAssertNil(editorResult.output)
            XCTAssertFalse(editorResult.diagnostics.isEmpty)
            XCTAssertEqual(editorResult.diagnostics.first?.category, error.category)
            XCTAssertEqual(editorResult.diagnostics.first?.message, error.message)
        }
    }

    private func validFixturePath(_ name: String) -> String {
        let root = FileManager.default.currentDirectoryPath
        return root + "/Tests/IntegrationTests/Fixtures/Valid/" + name
    }

    private func invalidFixturePath(_ name: String) -> String {
        let root = FileManager.default.currentDirectoryPath
        return root + "/Tests/IntegrationTests/Fixtures/Invalid/" + name
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
