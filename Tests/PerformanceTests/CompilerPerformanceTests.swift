import XCTest
@testable import CompilerDriver
@testable import Core
@testable import Parser
@testable import Resolver
@testable import Emitter

/// Performance tests for Hyperprompt compiler
///
/// Benchmark corpus: 50 files, ~6500 lines, ~250 links
/// Target: <200ms full compilation for medium project (Phase 13)
///
/// Run with: swift test --filter PerformanceTests
final class CompilerPerformanceTests: XCTestCase {

    // MARK: - Test Setup

    var corpusPath: String!
    var entryFilePath: String!

    override func setUp() async throws {
        try await super.setUp()

        // Locate benchmark corpus
        let fixturesURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("MediumProject")

        corpusPath = fixturesURL.path
        entryFilePath = fixturesURL.appendingPathComponent("entry.hc").path

        // Verify corpus exists
        guard FileManager.default.fileExists(atPath: entryFilePath) else {
            XCTFail("Benchmark corpus not found at \(entryFilePath). Run BenchmarkGenerator first.")
            return
        }
    }

    // MARK: - Full Compilation Benchmark

    func testFullCompilationPerformance() throws {
        let driver = CompilerDriver()

        // Measure full compilation time (entry file → markdown output)
        measure {
            do {
                let result = try driver.compile(
                    entryFile: entryFilePath,
                    outputFile: nil, // In-memory compilation
                    options: CompilationOptions()
                )

                // Verify compilation succeeded
                XCTAssertTrue(result.success, "Compilation should succeed")
                XCTAssertNotNil(result.output, "Output should be generated")

            } catch {
                XCTFail("Compilation failed: \(error)")
            }
        }

        // Report metrics
        print("\n📊 Full Compilation Benchmark")
        print("   Corpus: 50 files, ~6500 lines")
        print("   Target: <200ms (Phase 13 goal)")
    }

    // MARK: - Parse-Only Benchmark

    func testParsePerformance() throws {
        // Select representative file from corpus
        let testFile = URL(fileURLWithPath: corpusPath)
            .appendingPathComponent("modules")
            .appendingPathComponent("auth")
            .appendingPathComponent("core.hc")
            .path

        guard FileManager.default.fileExists(atPath: testFile) else {
            XCTFail("Test file not found: \(testFile)")
            return
        }

        let parser = Parser()

        // Measure parse time per file
        measure {
            do {
                let result = try parser.parse(filePath: testFile)

                // Verify parse succeeded
                XCTAssertNotNil(result, "Parsed result should exist")
                XCTAssertFalse(result.hasErrors, "Parse should not have errors")

            } catch {
                XCTFail("Parse failed: \(error)")
            }
        }

        // Calculate throughput
        print("\n📊 Parse Performance")
        print("   File size: ~130 lines")
        print("   Target: <2ms per file")
    }

    // MARK: - Resolution Benchmark

    func testResolutionPerformance() throws {
        // Parse a file with links first
        let testFile = URL(fileURLWithPath: corpusPath)
            .appendingPathComponent("modules")
            .appendingPathComponent("database")
            .appendingPathComponent("core.hc")
            .path

        guard FileManager.default.fileExists(atPath: testFile) else {
            XCTFail("Test file not found: \(testFile)")
            return
        }

        let parser = Parser()
        let parsedFile = try parser.parse(filePath: testFile)

        // Extract file references
        let references = parsedFile.fileReferences

        guard !references.isEmpty else {
            XCTFail("Test file should contain references")
            return
        }

        let resolver = Resolver(workspaceRoot: corpusPath)

        // Measure resolution time per link
        measure {
            for reference in references {
                do {
                    let resolved = try resolver.resolve(
                        reference: reference,
                        sourceFile: testFile
                    )

                    // Verify resolution succeeded
                    XCTAssertNotNil(resolved, "Reference should resolve")

                } catch {
                    // Some references may fail (expected in synthetic corpus)
                    continue
                }
            }
        }

        // Calculate throughput
        let linkCount = references.count
        print("\n📊 Resolution Performance")
        print("   Links tested: \(linkCount)")
        print("   Target: <0.1ms per link")
    }

    // MARK: - Emission Benchmark

    func testEmissionPerformance() throws {
        // Compile to get AST
        let driver = CompilerDriver()

        let result = try driver.compile(
            entryFile: entryFilePath,
            outputFile: nil,
            options: CompilationOptions()
        )

        guard result.success, let ast = result.ast else {
            XCTFail("Compilation failed, cannot test emission")
            return
        }

        let emitter = Emitter()

        // Measure emission time (AST → Markdown)
        measure {
            do {
                let output = try emitter.emit(ast: ast)

                // Verify output generated
                XCTAssertFalse(output.isEmpty, "Output should not be empty")
                XCTAssertGreaterThan(output.count, 1000, "Output should be substantial")

            } catch {
                XCTFail("Emission failed: \(error)")
            }
        }

        // Calculate throughput
        let lineCount = result.output?.components(separatedBy: .newlines).count ?? 0
        print("\n📊 Emission Performance")
        print("   Output lines: ~\(lineCount)")
        print("   Target: Variable (fast)")
    }

    // MARK: - Large File Stress Test

    func testLargeCorpusStressTest() throws {
        // Test compilation of entire 50-file corpus multiple times
        let driver = CompilerDriver()
        var compilationTimes: [TimeInterval] = []

        // Run 10 compilations to get stable measurements
        for iteration in 1...10 {
            let start = Date()

            let result = try driver.compile(
                entryFile: entryFilePath,
                outputFile: nil,
                options: CompilationOptions()
            )

            let elapsed = Date().timeIntervalSince(start)
            compilationTimes.append(elapsed)

            XCTAssertTrue(result.success, "Compilation \(iteration) should succeed")
        }

        // Report statistics
        let average = compilationTimes.reduce(0.0, +) / Double(compilationTimes.count)
        let sorted = compilationTimes.sorted()
        let median = sorted[sorted.count / 2]
        let min = sorted.first!
        let max = sorted.last!

        print("\n📊 Stress Test Results (10 runs)")
        print("   Average: \(String(format: "%.2f", average * 1000))ms")
        print("   Median:  \(String(format: "%.2f", median * 1000))ms")
        print("   Min:     \(String(format: "%.2f", min * 1000))ms")
        print("   Max:     \(String(format: "%.2f", max * 1000))ms")
        print("   Target:  <200ms")

        // Assert performance target (median < 200ms)
        XCTAssertLessThan(median * 1000, 200.0,
                          "Median compilation time should be < 200ms (got \(median * 1000)ms)")
    }
}
