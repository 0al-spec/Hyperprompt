import Foundation
import SpecificationCore

/// Detects `.md` references.
public struct HasMarkdownExtensionSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        candidate.lowercased().hasSuffix(".md")
    }
}

/// Detects `.hc` references.
public struct HasHypercodeExtensionSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        candidate.lowercased().hasSuffix(".hc")
    }
}

/// Allows markdown or hypercode extensions.
public struct IsAllowedExtensionSpec: Specification {
    public typealias T = String

    private let spec: AnySpecification<String>

    public init() {
        let allowed = HasMarkdownExtensionSpec().or(HasHypercodeExtensionSpec())
        self.spec = AnySpecification(allowed)
    }

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        spec.isSatisfiedBy(candidate)
    }
}

/// Detects presence of path separators.
public struct ContainsPathSeparatorSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        candidate.contains("/") || candidate.contains("\\")
    }
}

/// Detects file extension delimiter.
public struct ContainsExtensionDotSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        guard let lastComponent = candidate.split(separator: "/").last else {
            return false
        }
        return lastComponent.contains(".")
    }
}

/// Detects known file extensions at the end of a string.
public struct HasKnownFileExtensionSpec: Specification {
    public typealias T = String

    private static let knownExtensions: Set<String> = [
        ".md", ".hc", ".txt", ".json", ".yaml", ".yml", ".xml",
        ".pdf", ".html", ".htm", ".css", ".js", ".ts", ".py",
        ".java", ".swift", ".c", ".cpp", ".h", ".sh", ".bash"
    ]

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        let lowercased = candidate.lowercased()
        return Self.knownExtensions.contains(where: { lowercased.hasSuffix($0) })
    }
}

/// Heuristic to determine if a string looks like a file reference.
///
/// A string is considered a file reference if it either:
/// 1. Contains a path separator (/ or \), OR
/// 2. Ends with a known file extension (.md, .hc, .txt, etc.), OR
/// 3. Is a path traversal pattern (.. or ../)
///
/// This heuristic avoids false positives like "Version: 3.0.0" or "Section A.1"
/// while still correctly identifying file paths and catching path traversal attempts.
public struct LooksLikeFileReferenceSpec: Specification {
    public typealias T = String

    private let spec: AnySpecification<String>

    public init() {
        let heuristic = ContainsPathSeparatorSpec()
            .or(HasKnownFileExtensionSpec())
            .or(IsPathTraversalPatternSpec())
        self.spec = AnySpecification(heuristic)
    }

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        spec.isSatisfiedBy(candidate)
    }
}

/// Detects path traversal patterns like ".." or "../"
public struct IsPathTraversalPatternSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        let trimmed = candidate.trimmingCharacters(in: .whitespaces)
        return trimmed == ".." || trimmed.hasPrefix("../") || trimmed.hasSuffix("/..")
            || trimmed.contains("/../")
    }
}
