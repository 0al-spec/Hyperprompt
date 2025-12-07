import Core
import Foundation
import SpecificationCore

/// Detects LF line endings within content.
public struct ContainsLFSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        candidate.contains(LineBreak.lineFeed)
    }
}

/// Detects CR characters within content.
public struct ContainsCRSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        candidate.contains(LineBreak.carriageReturn)
    }
}

/// Ensures content is confined to a single line.
public struct SingleLineContentSpec: Specification {
    public typealias T = String

    private let spec: AnySpecification<String>

    public init() {
        let hasAnyLineBreak = ContainsLFSpec().or(ContainsCRSpec())
        self.spec = AnySpecification(hasAnyLineBreak.not())
    }

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        spec.isSatisfiedBy(candidate)
    }
}
