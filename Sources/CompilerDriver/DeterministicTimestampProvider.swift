import Foundation

/// Provides deterministic timestamps for manifest generation.
///
/// The provider prefers explicit reproducible sources over wall clock time to
/// ensure byte-for-byte stable outputs across repeated compilations.
///
/// Resolution order:
/// 1. `HYPERPROMPT_BUILD_TIMESTAMP` (Unix epoch seconds)
/// 2. `SOURCE_DATE_EPOCH` (Unix epoch seconds, reproducible builds convention)
/// 3. Modification time of the input file (stable for unchanged inputs)
/// 4. Fallback to Unix epoch start (`1970-01-01T00:00:00Z`) for safety
struct DeterministicTimestampProvider {
    private let environment: [String: String]
    private let fileManager: FileManager

    init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) {
        self.environment = environment
        self.fileManager = fileManager
    }

    /// Resolve a deterministic `Date` for the given input path.
    func resolveDate(for inputPath: String) -> Date {
        if let explicit = resolveExplicitEpoch() {
            return explicit
        }

        if let mtime = resolveModificationDate(for: inputPath) {
            return mtime
        }

        // Deterministic, stable fallback
        return Date(timeIntervalSince1970: 0)
    }

    /// Resolve a deterministic ISO-8601 timestamp string in UTC.
    func resolveTimestampString(for inputPath: String) -> String {
        let date = resolveDate(for: inputPath)
        return Self.makeISO8601Formatter().string(from: date)
    }

    // MARK: - Helpers

    private func resolveExplicitEpoch() -> Date? {
        if let value = environment["HYPERPROMPT_BUILD_TIMESTAMP"] ?? environment["SOURCE_DATE_EPOCH"],
           let seconds = TimeInterval(value) {
            return Date(timeIntervalSince1970: seconds)
        }
        return nil
    }

    private func resolveModificationDate(for path: String) -> Date? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }

    private static func makeISO8601Formatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }
}
