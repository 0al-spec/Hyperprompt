import Foundation

/// Formats compilation statistics for display.
public struct StatsReporter {
    public init() {}

    /// Render statistics as a deterministic multi-line string.
    ///
    /// - Parameter stats: Statistics snapshot to format.
    /// - Returns: A string ending with a newline.
    public func format(_ stats: CompilationStats) -> String {
        var lines: [String] = []
        lines.append("Compilation Statistics")
        lines.append("----------------------")
        lines.append("Source files: \(stats.numHypercodeFiles + stats.numMarkdownFiles) " +
            "(Hypercode: \(stats.numHypercodeFiles), Markdown: \(stats.numMarkdownFiles))")
        lines.append("Input bytes: \(formatBytes(stats.totalInputBytes))")
        lines.append("Output bytes: \(formatBytes(stats.totalOutputBytes))")
        lines.append("Max depth: \(stats.maxDepth)")
        lines.append("Duration: \(stats.durationMs) ms")
        return lines.joined(separator: "\n") + "\n"
    }

    /// Print statistics to the provided file handle (defaults to stderr).
    public func print(_ stats: CompilationStats, to handle: FileHandle = .standardError) {
        let message = format(stats)
        if let data = message.data(using: .utf8) {
            handle.write(data)
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        switch bytes {
        case 0..<1024:
            return "\(bytes) bytes"
        case 1024..<(1024 * 1024):
            let kb = Double(bytes) / 1024.0
            return String(format: "%.1f KB", kb)
        default:
            let mb = Double(bytes) / (1024.0 * 1024.0)
            return String(format: "%.1f MB", mb)
        }
    }
}
