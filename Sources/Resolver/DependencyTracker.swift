import Foundation
import Core

/// Tracks file visitation during reference resolution to detect circular dependencies.
///
/// The tracker keeps a stack of canonicalized absolute paths representing the current
/// resolution chain. Before resolving a new `.hc` reference, call
/// `checkAndPush(path:location:)` to detect cycles. After finishing resolution of that
/// file, call `pop()` to restore the previous state.
public struct DependencyTracker {
    /// File system used for canonicalization.
    private let fileSystem: FileSystem

    /// Visitation stack of canonical absolute paths.
    private var visitationStack: [String]

    /// Create a tracker with an optional initial stack (useful for tests).
    ///
    /// - Parameters:
    ///   - fileSystem: File system used to canonicalize paths.
    ///   - initialStack: Pre-populated visitation stack.
    public init(fileSystem: FileSystem, initialStack: [String] = []) {
        self.fileSystem = fileSystem
        self.visitationStack = initialStack
    }

    /// Current visitation stack (read-only).
    public var stack: [String] { visitationStack }

    /// Check for a cycle and push the canonical path onto the stack if safe.
    ///
    /// - Parameters:
    ///   - path: Path to the referenced `.hc` file (relative or absolute).
    ///   - location: Source location that triggered this visit.
    /// - Returns: CircularDependencyError when a cycle is found; otherwise `nil` after pushing.
    /// - Throws: CompilerError from the file system if canonicalization fails.
    @discardableResult
    public mutating func checkAndPush(path: String, location: SourceLocation) throws -> CircularDependencyError? {
        let canonicalPath = try canonicalize(path)

        if let cyclePath = cyclePathIfPresent(for: canonicalPath) {
            return CircularDependencyError(cyclePath: cyclePath, location: location)
        }

        visitationStack.append(canonicalPath)
        return nil
    }

    /// Remove the most recently visited path from the stack.
    public mutating func pop() {
        _ = visitationStack.popLast()
    }

    /// Determine whether the given path is already in the current visitation stack.
    ///
    /// - Parameter path: Path to check (relative or absolute).
    /// - Returns: `true` if the canonical path is already present.
    /// - Throws: CompilerError from the file system if canonicalization fails.
    public func isInCycle(path: String) throws -> Bool {
        let canonicalPath = try canonicalize(path)
        return visitationStack.contains(canonicalPath)
    }

    /// Get the full cycle path for an offending path using the current stack.
    ///
    /// - Parameter offendingPath: Path that triggered cycle detection.
    /// - Returns: Cycle path including the offending path at the end. Empty when no cycle exists.
    /// - Throws: CompilerError from the file system if canonicalization fails.
    public func getCyclePath(offendingPath: String) throws -> [String] {
        let canonicalPath = try canonicalize(offendingPath)
        return cyclePathIfPresent(for: canonicalPath) ?? []
    }

    /// Canonicalize a path using the configured file system.
    private func canonicalize(_ path: String) throws -> String {
        let canonical = try fileSystem.canonicalizePath(path)
        return NSString(string: canonical).standardizingPath
    }

    /// Build the cycle slice from the stack when present.
    private func cyclePathIfPresent(for canonicalPath: String) -> [String]? {
        guard let startIndex = visitationStack.firstIndex(of: canonicalPath) else {
            return nil
        }

        var cycle = Array(visitationStack[startIndex...])
        cycle.append(canonicalPath)
        return cycle
    }
}

/// Error describing a detected circular dependency during resolution.
public struct CircularDependencyError: CompilerError, Equatable {
    public let category: ErrorCategory = .resolution
    public let message: String
    public let location: SourceLocation?
    public let cyclePath: [String]

    /// Initialize with the detected cycle path and source location.
    public init(cyclePath: [String], location: SourceLocation) {
        self.cyclePath = cyclePath
        self.location = location
        self.message = [
            "Circular dependency detected",
            "Cycle path: \(cyclePath.joined(separator: " → "))"
        ].joined(separator: "\n")
    }
}
