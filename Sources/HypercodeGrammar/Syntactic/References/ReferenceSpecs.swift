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

/// Heuristic to determine if a string looks like a file reference.
public struct LooksLikeFileReferenceSpec: Specification {
    public typealias T = String

    private let spec: AnySpecification<String>

    public init() {
        let heuristic = ContainsExtensionDotSpec().or(ContainsPathSeparatorSpec())
        self.spec = AnySpecification(heuristic)
    }

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        spec.isSatisfiedBy(candidate)
    }
}
