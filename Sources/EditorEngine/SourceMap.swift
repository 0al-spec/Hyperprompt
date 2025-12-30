#if Editor
import Core
import Foundation

/// Minimal source map tracking output lines to source locations.
///
/// This provides basic bidirectional navigation from compiled output back to source files.
/// Unlike full source maps (e.g., browser devtools format), this only stores line-level mappings.
///
/// Note: Uses SourceLocation from Core module which has 1-indexed line numbers.
public struct SourceMap: Sendable, Codable {
    /// Mapping from 0-indexed output line to source location (1-indexed).
    private let mappings: [Int: SourceLocation]

    public init(mappings: [Int: SourceLocation] = [:]) {
        self.mappings = mappings
    }

    /// Lookup source location for given output line.
    ///
    /// - Parameter outputLine: 0-indexed line number in compiled output
    /// - Returns: Source location if mapping exists, nil otherwise
    public func lookup(outputLine: Int) -> SourceLocation? {
        return mappings[outputLine]
    }

    /// Returns all mappings (for debugging/testing).
    public var allMappings: [Int: SourceLocation] {
        return mappings
    }

    /// Number of mapped lines.
    public var count: Int {
        return mappings.count
    }

    // MARK: - Codable

    // Nested type for encoding/decoding SourceLocation (which isn't Codable itself)
    private struct CodableSourceLocation: Codable {
        let filePath: String
        let line: Int

        init(from sourceLocation: SourceLocation) {
            self.filePath = sourceLocation.filePath
            self.line = sourceLocation.line
        }

        func toSourceLocation() -> SourceLocation {
            return SourceLocation(filePath: filePath, line: line)
        }
    }

    enum CodingKeys: String, CodingKey {
        case mappings
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode dictionary with string keys (JSON limitation)
        let stringKeyMappings = try container.decode([String: CodableSourceLocation].self, forKey: .mappings)
        var intKeyMappings: [Int: SourceLocation] = [:]
        for (key, value) in stringKeyMappings {
            if let intKey = Int(key) {
                intKeyMappings[intKey] = value.toSourceLocation()
            }
        }
        self.mappings = intKeyMappings
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Encode with string keys (JSON requirement)
        let stringKeyMappings = Dictionary(
            uniqueKeysWithValues: mappings.map {
                (String($0.key), CodableSourceLocation(from: $0.value))
            }
        )
        try container.encode(stringKeyMappings, forKey: .mappings)
    }
}

/// Builder for constructing source maps during compilation.
public final class SourceMapBuilder {
    private let lock = NSLock()
    private var mappings: [Int: SourceLocation] = [:]

    public init() {}

    /// Add mapping from output line to source location.
    ///
    /// - Parameters:
    ///   - outputLine: 0-indexed line in compiled output
    ///   - sourceLocation: Location in original source file (1-indexed)
    public func addMapping(outputLine: Int, sourceLocation: SourceLocation) {
        lock.lock()
        defer { lock.unlock() }
        mappings[outputLine] = sourceLocation
    }

    /// Build immutable SourceMap.
    public func build() -> SourceMap {
        lock.lock()
        defer { lock.unlock() }
        return SourceMap(mappings: mappings)
    }
}
#endif
