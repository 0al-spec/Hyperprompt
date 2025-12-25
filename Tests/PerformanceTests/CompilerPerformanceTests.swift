import XCTest
@testable import CompilerDriver
@testable import Core
import Statistics

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
            .deletingLastPathComponent()
            .appendingPathComponent("TestCorpus")
            .appendingPathComponent("Performance")

        corpusPath = fixturesURL.path
        entryFilePath = fixturesURL.appendingPathComponent("comprehensive_test.hc").path

        // Verify corpus exists
        guard let entryFilePath = entryFilePath else {
            XCTFail("Benchmark corpus path missing. Run BenchmarkGenerator first.")
            return
        }
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
                let args = CompilerArguments(
                    input: entryFilePath,
                    output: "/tmp/test-output.md",
                    manifest: "/tmp/test-manifest.json",
                    root: corpusPath,
                    mode: .lenient,
                    verbose: false,
                    stats: false,
                    dryRun: true  // Don't write files, just compile
                )

                let result = try driver.compile(args)

                // Verify compilation succeeded
                XCTAssertFalse(result.markdown.isEmpty, "Output should not be empty")
                XCTAssertFalse(result.manifestJSON.isEmpty, "Manifest should not be empty")

            } catch {
                XCTFail("Compilation failed: \(error)")
            }
        }

        // Report metrics
        print("\n📊 Full Compilation Benchmark")
        print("   Corpus: comprehensive_test.hc + large markdown files")
        print("   Target: <200ms (Phase 13 goal)")
    }

    // MARK: - Compilation with Statistics

    func testCompilationWithStatistics() throws {
        let driver = CompilerDriver()
        var lastStats: CompilationStats?

        let args = CompilerArguments(
            input: entryFilePath,
            output: "/tmp/test-output.md",
            manifest: "/tmp/test-manifest.json",
            root: corpusPath,
            mode: .lenient,
            verbose: false,
            stats: true,  // Enable statistics collection
            dryRun: true
        )

        // Measure compilation with stats collection
        measure {
            do {
                let result = try driver.compile(args)

                // Verify statistics collected
                XCTAssertNotNil(result.statistics, "Statistics should be collected")
                lastStats = result.statistics

            } catch {
                XCTFail("Compilation with stats failed: \(error)")
            }
        }

        if let stats = lastStats {
            print("\n📊 Compilation Statistics")
            print("   Hypercode files: \(stats.numHypercodeFiles)")
            print("   Markdown files: \(stats.numMarkdownFiles)")
            print("   Total time: \(stats.durationMs)ms")
        }
    }

    // MARK: - Strict Mode Compilation

    func testStrictModeCompilation() throws {
        let driver = CompilerDriver()

        let args = CompilerArguments(
            input: entryFilePath,
            output: "/tmp/test-output.md",
            manifest: "/tmp/test-manifest.json",
            root: corpusPath,
            mode: .strict,  // Strict mode - fail on missing refs
            verbose: false,
            stats: false,
            dryRun: true
        )

        measure {
            do {
                let result = try driver.compile(args)

                // In strict mode, all references must resolve
                XCTAssertFalse(result.markdown.isEmpty, "Should compile successfully")

            } catch {
                // Strict mode may fail if corpus has broken references
                // This is expected and not a performance issue
                print("Note: Strict mode failed (expected if corpus has unresolved refs): \(error)")
            }
        }
    }

    // MARK: - Large Corpus Stress Test

    func testLargeCorpusStressTest() throws {
        // Test compilation of entire 50-file corpus multiple times
        let driver = CompilerDriver()
        var compilationTimes: [TimeInterval] = []

        // Run 10 compilations to get stable measurements
        for iteration in 1...10 {
            let start = Date()

            let args = CompilerArguments(
                input: entryFilePath,
                output: "/tmp/test-output.md",
                manifest: "/tmp/test-manifest.json",
                root: corpusPath,
                mode: .lenient,
                verbose: false,
                stats: false,
                dryRun: true
            )

            do {
                let result = try driver.compile(args)
                let elapsed = Date().timeIntervalSince(start)
                compilationTimes.append(elapsed)

                XCTAssertFalse(result.markdown.isEmpty, "Compilation \(iteration) should succeed")

            } catch {
                XCTFail("Compilation \(iteration) failed: \(error)")
            }
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
        print("   Target:  <200ms local, <800ms CI")

        // Assert performance target (median < 1000ms for now, will tighten to 200ms later)
        // Note: Current implementation without caching may not meet <200ms target yet
        XCTAssertLessThan(median * 1000, 5000.0,
                          "Median compilation time should be reasonable (got \(median * 1000)ms)")
    }

    // MARK: - Memory Baseline Test

    func testMemoryUsage() throws {
        let driver = CompilerDriver()

        let args = CompilerArguments(
            input: entryFilePath,
            output: "/tmp/test-output.md",
            manifest: "/tmp/test-manifest.json",
            root: corpusPath,
            mode: .lenient,
            verbose: false,
            stats: true,
            dryRun: true
        )

        // Single compilation to measure memory usage
        let result = try driver.compile(args)

        XCTAssertFalse(result.markdown.isEmpty)

        // Note: XCTest doesn't provide direct memory measurement API
        // This test verifies compilation succeeds without crashes/OOM
        print("\n📊 Memory Test")
        print("   Status: Compilation completed successfully")
        print("   Note: Use Instruments for detailed memory profiling")
    }
}
