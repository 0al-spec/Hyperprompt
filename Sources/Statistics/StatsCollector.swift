import Foundation

/// Collects compilation statistics with optional enablement.
///
/// When disabled, all methods are no-ops to keep overhead near zero.
/// When enabled, metrics are deduplicated by canonicalized file path.
public final class StatsCollector {
    private let isEnabled: Bool
    private let clock: () -> Date

    private var startTime: Date?

    private var hypercodeFiles: Set<String> = []
    private var markdownFiles: Set<String> = []

    private var inputBytes: Int = 0
    private var outputBytes: Int = 0
    private var maxDepth: Int = 0

    /// Create a new collector.
    ///
    /// - Parameters:
    ///   - enabled: Whether metrics should be recorded.
    ///   - clock:   Time source for duration measurement (injectable for tests).
    public init(enabled: Bool, clock: @escaping () -> Date = Date.init) {
        self.isEnabled = enabled
        self.clock = clock
    }

    /// A disabled collector that drops all updates.
    public static var disabled: StatsCollector {
        StatsCollector(enabled: false)
    }

    /// Start timing the compilation.
    public func start() {
        guard isEnabled else { return }
        startTime = clock()
    }

    /// Record a Hypercode file read.
    ///
    /// - Parameters:
    ///   - path: Canonical file path (used for deduplication).
    ///   - bytes: Size of file content in bytes.
    public func recordHypercodeFile(path: String, bytes: Int) {
        guard isEnabled else { return }

        if hypercodeFiles.insert(path).inserted {
            inputBytes += bytes
        }
    }

    /// Record a Markdown file read.
    ///
    /// - Parameters:
    ///   - path: Canonical file path (used for deduplication).
    ///   - bytes: Size of file content in bytes.
    public func recordMarkdownFile(path: String, bytes: Int) {
        guard isEnabled else { return }

        if markdownFiles.insert(path).inserted {
            inputBytes += bytes
        }
    }

    /// Record total bytes produced by the pipeline.
    public func recordOutputBytes(_ bytes: Int) {
        guard isEnabled else { return }
        outputBytes += bytes
    }

    /// Update maximum depth encountered.
    public func updateMaxDepth(_ depth: Int) {
        guard isEnabled else { return }
        maxDepth = Swift.max(maxDepth, depth)
    }

    /// Finalize collection and return immutable statistics.
    ///
    /// - Returns: `CompilationStats` snapshot or `nil` if disabled.
    public func finish() -> CompilationStats? {
        guard isEnabled else { return nil }

        let duration: Int
        if let startTime {
            let endTime = clock()
            duration = Int((endTime.timeIntervalSince(startTime) * 1000).rounded())
        } else {
            duration = 0
        }

        return CompilationStats(
            numHypercodeFiles: hypercodeFiles.count,
            numMarkdownFiles: markdownFiles.count,
            totalInputBytes: inputBytes,
            totalOutputBytes: outputBytes,
            maxDepth: maxDepth,
            durationMs: duration
        )
    }
}
