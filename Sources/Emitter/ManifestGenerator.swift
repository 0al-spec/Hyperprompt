import Foundation
import Core

/// Generator for compilation manifest JSON output.
///
/// The ManifestGenerator transforms collected file metadata (from ManifestBuilder)
/// into a structured, deterministic JSON document. The manifest serves as a
/// record of compilation provenance, enabling downstream verification and
/// documentation of all input files.
///
/// Usage:
/// ```swift
/// let builder = ManifestBuilder()
/// // ... add entries during compilation ...
///
/// let generator = ManifestGenerator()
/// let manifest = generator.generate(
///     builder: builder,
///     version: "0.1.0",
///     root: "/path/to/root",
///     timestamp: Date()
/// )
///
/// let json = try generator.toJSON(manifest: manifest)
/// // Write json to file...
/// ```
///
/// **Key Features:**
/// - Deterministic output (identical metadata → identical JSON bytes)
/// - Alphabetically sorted keys throughout
/// - ISO 8601 timestamps with UTC timezone
/// - Valid JSON compatible with standard parsers
public struct ManifestGenerator {
    /// Initialize a manifest generator.
    public init() {}

    /// Generate a manifest from collected entries.
    ///
    /// - Parameters:
    ///   - builder: ManifestBuilder containing collected entries
    ///   - version: Compiler version string (e.g., "0.1.0")
    ///   - root: Root directory path
    ///   - timestamp: Compilation time (default: current time)
    ///
    /// - Returns: Manifest struct ready for JSON serialization
    ///
    /// The returned manifest has entries sorted by path for determinism.
    public func generate(
        builder: ManifestBuilder,
        version: String,
        root: String,
        timestamp: Date? = nil
    ) -> Manifest {
        let entries = builder.getEntries()
        let timestampString = formatTimestamp(timestamp ?? Date())

        return Manifest(
            root: root,
            sources: entries,  // Manifest.init will sort them
            timestamp: timestampString,
            version: version
        )
    }

    /// Convert manifest to JSON string.
    ///
    /// - Parameter manifest: The manifest to serialize
    ///
    /// - Returns: JSON string with alphabetically sorted keys
    ///
    /// - Throws: EncodingError if serialization fails
    ///
    /// **Output Format:**
    /// - Keys alphabetically sorted at all levels
    /// - Pretty-printed with 2-space indentation
    /// - Ends with exactly one LF character
    /// - UTF-8 encoding
    public func toJSON(manifest: Manifest) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let data = try encoder.encode(manifest)

        guard var json = String(data: data, encoding: .utf8) else {
            throw ManifestError.encodingFailed("Failed to convert JSON data to UTF-8 string")
        }

        // Ensure output ends with exactly one LF
        json = json.trimmingCharacters(in: .whitespacesAndNewlines)
        json += "\n"

        return json
    }

    /// Format a Date as ISO 8601 timestamp.
    ///
    /// - Parameter date: The date to format
    ///
    /// - Returns: ISO 8601 string in format `YYYY-MM-DDTHH:MM:SSZ`
    ///
    /// **Format Details:**
    /// - Timezone: Always UTC (Z suffix)
    /// - Precision: Seconds (no fractional seconds)
    /// - Zero-padded components
    /// - Example: `"2025-12-09T14:30:45Z"`
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")

        return formatter.string(from: date)
    }
}

/// Errors that can occur during manifest generation.
public enum ManifestError: Error, CustomStringConvertible {
    /// JSON encoding failed
    case encodingFailed(String)

    public var description: String {
        switch self {
        case .encodingFailed(let message):
            return "Manifest encoding error: \(message)"
        }
    }
}
