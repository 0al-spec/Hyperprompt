import Emitter
import Foundation
import XCTest
@testable import CompilerDriver
@testable import Core

final class RFCAssemblyFixtureTests: XCTestCase {
    private var fixtureDirectory: URL!
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        fixtureDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/RFCAssembly")
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("hyperprompt-rfc-assembly-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testAbstractRFCFixtureWritesAllDeterministicArtifacts() throws {
        let output = tempDirectory.appendingPathComponent("abstract-rfc.md")
        let manifestPath = tempDirectory
            .appendingPathComponent("abstract-rfc.manifest.json")
        let sourceMapPath = tempDirectory
            .appendingPathComponent("abstract-rfc.map.json")

        let result = try compile(
            project: fixtureDirectory,
            output: output,
            manifest: manifestPath,
            sourceMap: sourceMapPath,
            dryRun: false
        )
        let compilationSourceMap = try XCTUnwrap(result.sourceMap)
        let sourceMapJSON = try XCTUnwrap(result.sourceMapJSON)

        let expectedMarkdown = try String(
            contentsOf: fixtureDirectory.appendingPathComponent("expected.md"),
            encoding: .utf8
        )
        XCTAssertEqual(result.markdown, expectedMarkdown)
        XCTAssertEqual(
            try String(contentsOf: output, encoding: .utf8),
            result.markdown
        )
        XCTAssertEqual(
            try String(contentsOf: manifestPath, encoding: .utf8),
            result.manifestJSON
        )
        XCTAssertEqual(
            try String(contentsOf: sourceMapPath, encoding: .utf8),
            sourceMapJSON
        )

        let manifest = try JSONDecoder().decode(
            Manifest.self,
            from: Data(result.manifestJSON.utf8)
        )
        XCTAssertEqual(manifest.root, "root.hc")
        XCTAssertEqual(
            manifest.sources.map(\.path),
            [
                "root.hc",
                "sections/core.md",
                "sections/evidence.md",
                "sections/introduction.md",
            ]
        )
        XCTAssertEqual(
            manifest.dependencies,
            [
                ManifestDependency(from: "root.hc", to: "sections/core.md"),
                ManifestDependency(from: "root.hc", to: "sections/evidence.md"),
                ManifestDependency(from: "root.hc", to: "sections/introduction.md"),
            ]
        )
        assertSource(
            manifest,
            path: "root.hc",
            hash: "e101967159aa5e78680887935aab65f31af4eecf0875e28eb01be264a32d8c61",
            size: 106,
            type: .hypercode
        )
        assertSource(
            manifest,
            path: "sections/core.md",
            hash: "6cc349360b893718b8b7e4f0ca127d91fe39cbf1e7790daab4749d004346d369",
            size: 112,
            type: .markdown
        )
        assertSource(
            manifest,
            path: "sections/evidence.md",
            hash: "8e13e3c97055f3ed61dcee3043ba06bc8b31f215b4aef48c24bb371c757de9ab",
            size: 64,
            type: .markdown
        )
        assertSource(
            manifest,
            path: "sections/introduction.md",
            hash: "49784175d53f3e306d39a57c80cd4db5cdf92fa21d457532bf875c2cc5f31105",
            size: 79,
            type: .markdown
        )

        XCTAssertEqual(
            compilationSourceMap,
            expectedSourceMap()
        )
        XCTAssertNoThrow(try compilationSourceMap.validate(for: result.markdown))
        XCTAssertFalse(result.manifestJSON.contains(fixtureDirectory.path))
        XCTAssertFalse(sourceMapJSON.contains(fixtureDirectory.path))
    }

    func testAbstractRFCFixtureDryRunWritesNothing() throws {
        let output = tempDirectory.appendingPathComponent("dry-run.md")
        let manifest = tempDirectory.appendingPathComponent("dry-run.manifest.json")
        let sourceMap = tempDirectory.appendingPathComponent("dry-run.map.json")

        let result = try compile(
            project: fixtureDirectory,
            output: output,
            manifest: manifest,
            sourceMap: sourceMap,
            dryRun: true
        )
        let compilationSourceMap = try XCTUnwrap(result.sourceMap)

        XCTAssertNoThrow(try compilationSourceMap.validate(for: result.markdown))
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: manifest.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: sourceMap.path))
    }

    func testAbstractRFCFixtureFailsClosedForMissingModule() throws {
        let invalidProject = fixtureDirectory
            .deletingLastPathComponent()
            .appendingPathComponent("RFCAssemblyInvalid")
        let output = tempDirectory.appendingPathComponent("invalid.md")
        let manifest = tempDirectory.appendingPathComponent("invalid.manifest.json")
        let sourceMap = tempDirectory.appendingPathComponent("invalid.map.json")

        XCTAssertThrowsError(
            try compile(
                project: invalidProject,
                output: output,
                manifest: manifest,
                sourceMap: sourceMap,
                dryRun: false
            )
        ) { error in
            guard let compilerError = error as? CompilerError else {
                return XCTFail("Expected CompilerError, got \(error)")
            }
            XCTAssertEqual(compilerError.category, .resolution)
            XCTAssertEqual(compilerError.location?.line, 2)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: manifest.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: sourceMap.path))
    }

    func testAbstractRFCArtifactsAreCheckoutIndependent() throws {
        let firstCheckout = tempDirectory.appendingPathComponent("checkout-a")
        let secondCheckout = tempDirectory.appendingPathComponent("checkout-b")
        try FileManager.default.copyItem(at: fixtureDirectory, to: firstCheckout)
        try FileManager.default.copyItem(at: fixtureDirectory, to: secondCheckout)

        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        for checkout in [firstCheckout, secondCheckout] {
            try FileManager.default.setAttributes(
                [.modificationDate: fixedDate],
                ofItemAtPath: checkout.appendingPathComponent("root.hc").path
            )
        }

        let first = try compileCheckout(firstCheckout, suffix: "a")
        let second = try compileCheckout(secondCheckout, suffix: "b")

        XCTAssertEqual(first.markdown, second.markdown)
        XCTAssertEqual(first.manifestJSON, second.manifestJSON)
        XCTAssertEqual(first.sourceMapJSON, second.sourceMapJSON)
        XCTAssertFalse(first.manifestJSON.contains(firstCheckout.path))
        XCTAssertFalse(
            try XCTUnwrap(first.sourceMapJSON).contains(firstCheckout.path)
        )
        XCTAssertFalse(second.manifestJSON.contains(secondCheckout.path))
        XCTAssertFalse(
            try XCTUnwrap(second.sourceMapJSON).contains(secondCheckout.path)
        )
    }

    private func compile(
        project: URL,
        output: URL,
        manifest: URL,
        sourceMap: URL,
        dryRun: Bool
    ) throws -> CompilationResult {
        try CompilerDriver().compile(
            CompilerArguments(
                input: project.appendingPathComponent("root.hc").path,
                output: output.path,
                manifest: manifest.path,
                sourceMap: sourceMap.path,
                root: project.path,
                mode: .strict,
                verbose: false,
                stats: false,
                dryRun: dryRun
            )
        )
    }

    private func compileCheckout(_ project: URL, suffix: String) throws
        -> CompilationResult
    {
        try compile(
            project: project,
            output: tempDirectory.appendingPathComponent("\(suffix).md"),
            manifest: tempDirectory.appendingPathComponent("\(suffix).manifest.json"),
            sourceMap: tempDirectory.appendingPathComponent("\(suffix).map.json"),
            dryRun: true
        )
    }

    private func assertSource(
        _ manifest: Manifest,
        path: String,
        hash: String,
        size: Int,
        type: FileType,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let source = manifest.sources.first(where: { $0.path == path }) else {
            return XCTFail("Missing source \(path)", file: file, line: line)
        }
        XCTAssertEqual(source.sha256, hash, file: file, line: line)
        XCTAssertEqual(source.size, size, file: file, line: line)
        XCTAssertEqual(source.type.rawValue, type.rawValue, file: file, line: line)
    }

    private func expectedSourceMap() -> CompilationSourceMap {
        let introduction = "sections/introduction.md"
        let core = "sections/core.md"
        let evidence = "sections/evidence.md"
        return CompilationSourceMap(
            outputSha256: "b3493beb641bbb8cab72832f7e442977bfa665fed1c46b1031b11f38708c3c63",
            mappings: [
                mapping(1, .hypercodeHeading, "root.hc", 1, 1),
                mapping(2, .markdown, introduction, 1, 2),
                mapping(3, .markdown, introduction, 3, 3),
                mapping(4, .markdown, introduction, 4, 4),
                mapping(5, .generatedSeparator),
                mapping(6, .markdown, core, 1, 1),
                mapping(7, .markdown, core, 2, 2),
                mapping(8, .markdown, core, 3, 3),
                mapping(9, .markdown, core, 4, 4),
                mapping(10, .markdown, core, 5, 5),
                mapping(11, .markdown, core, 6, 6),
                mapping(12, .markdown, core, 7, 7),
                mapping(13, .markdown, core, 8, 8),
                mapping(14, .markdown, core, 9, 9),
                mapping(15, .generatedSeparator),
                mapping(16, .markdown, evidence, 1, 2),
                mapping(17, .markdown, evidence, 3, 3),
                mapping(18, .markdown, evidence, 4, 4),
            ]
        )
    }

    private func mapping(
        _ generatedLine: Int,
        _ kind: CompilationSourceMappingKind,
        _ path: String? = nil,
        _ startLine: Int = 0,
        _ endLine: Int = 0
    ) -> CompilationSourceMapping {
        CompilationSourceMapping(
            generatedLine: generatedLine,
            kind: kind,
            source: path.map {
                CompilationSourceSpan(
                    path: $0,
                    startLine: startLine,
                    endLine: endLine
                )
            }
        )
    }
}
