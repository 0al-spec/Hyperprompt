import Foundation
import SpecificationCore

/// Determines whether a line represents a comment (after optional indentation).
public struct IsCommentLineSpec: Specification {
    public typealias T = RawLine

    public init() {}

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        trimmed(candidate).first == "#"
    }
}

/// Determines whether a line represents a quoted node literal.
public struct IsNodeLineSpec: Specification {
    public typealias T = RawLine

    private let spec: AnySpecification<RawLine>

    public init() {
        self.spec = AnySpecification(ValidQuotesSpec())
    }

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        spec.isSatisfiedBy(candidate)
    }
}

/// Lines that can be skipped by the parser (blank or comment).
public struct IsSkippableLineSpec: Specification {
    public typealias T = RawLine

    private let spec: AnySpecification<RawLine>

    public init() {
        let blankOrComment = IsBlankLineSpec().or(IsCommentLineSpec())
        self.spec = AnySpecification(blankOrComment)
    }

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        spec.isSatisfiedBy(candidate)
    }
}

/// Lines that carry semantic payload (negation of skippable).
public struct IsSemanticLineSpec: Specification {
    public typealias T = RawLine

    private let spec: AnySpecification<RawLine>

    public init() {
        self.spec = AnySpecification(IsSkippableLineSpec().not())
    }

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        spec.isSatisfiedBy(candidate)
    }
}

private func trimmed(_ candidate: RawLine) -> Substring {
    candidate.text.drop(while: { $0 == " " })
}
