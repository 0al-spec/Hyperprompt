import XCTest
@testable import Statistics

final class StatisticsTests: XCTestCase {
    func testCollectorRecordsUniqueFilesAndTiming() {
        var timestamps: [Date] = [
            Date(timeIntervalSince1970: 1.0),
            Date(timeIntervalSince1970: 1.2)
        ]

        let collector = StatsCollector(enabled: true) {
            guard !timestamps.isEmpty else {
                return Date()
            }
            return timestamps.removeFirst()
        }

        collector.start()
        collector.recordHypercodeFile(path: "/project/main.hc", bytes: 120)
        collector.recordHypercodeFile(path: "/project/main.hc", bytes: 120) // dedup
        collector.recordMarkdownFile(path: "/project/docs.md", bytes: 80)
        collector.recordMarkdownFile(path: "/project/docs.md", bytes: 80) // dedup
        collector.updateMaxDepth(1)
        collector.updateMaxDepth(3)
        collector.recordOutputBytes(640)

        let stats = collector.finish()

        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.numHypercodeFiles, 1)
        XCTAssertEqual(stats?.numMarkdownFiles, 1)
        XCTAssertEqual(stats?.totalInputBytes, 200)
        XCTAssertEqual(stats?.totalOutputBytes, 640)
        XCTAssertEqual(stats?.maxDepth, 3)
        XCTAssertEqual(stats?.durationMs, 200)
    }

    func testDisabledCollectorReturnsNil() {
        let collector = StatsCollector(enabled: false)
        collector.start()
        collector.recordHypercodeFile(path: "/project/main.hc", bytes: 10)
        collector.recordMarkdownFile(path: "/project/docs.md", bytes: 5)
        collector.recordOutputBytes(50)
        collector.updateMaxDepth(2)

        XCTAssertNil(collector.finish())
    }

    func testReporterFormatsOutputDeterministically() {
        let stats = CompilationStats(
            numHypercodeFiles: 2,
            numMarkdownFiles: 1,
            totalInputBytes: 1536,
            totalOutputBytes: 2048,
            maxDepth: 4,
            durationMs: 42
        )

        let reporter = StatsReporter()
        let formatted = reporter.format(stats)

        XCTAssertTrue(formatted.contains("Source files: 3 (Hypercode: 2, Markdown: 1)"))
        XCTAssertTrue(formatted.contains("Input bytes: 1.5 KB"))
        XCTAssertTrue(formatted.contains("Output bytes: 2.0 KB"))
        XCTAssertTrue(formatted.contains("Max depth: 4"))
        XCTAssertTrue(formatted.contains("Duration: 42 ms"))
        XCTAssertTrue(formatted.hasSuffix("\n"))
    }
}
