import Foundation
import SpecificationCore

/// Checks that the line starts with a double quote after optional indentation.
public struct StartsWithDoubleQuoteSpec: Specification {
    public typealias T = RawLine

    public init() {}

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        trimmedCandidate(candidate).first == "\""
    }
}

/// Checks that the line ends with a double quote after optional indentation.
public struct EndsWithDoubleQuoteSpec: Specification {
    public typealias T = RawLine

    public init() {}

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        trimmedCandidate(candidate).last == "\""
    }
}

/// Ensures that the content between quotes is single-line.
public struct ContentWithinQuotesIsSingleLineSpec: Specification {
    public typealias T = RawLine

    private let boundariesSpec: AnySpecification<RawLine>
    private let singleLineSpec: AnySpecification<String>

    public init() {
        self.boundariesSpec = AnySpecification(
            StartsWithDoubleQuoteSpec().and(EndsWithDoubleQuoteSpec())
        )
        self.singleLineSpec = AnySpecification(SingleLineContentSpec())
    }

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        guard boundariesSpec.isSatisfiedBy(candidate) else {
            return false
        }

        let trimmed = trimmedCandidate(candidate)
        let content = String(trimmed.dropFirst().dropLast())
        return singleLineSpec.isSatisfiedBy(content)
    }
}

/// Composite validation ensuring well-formed quotes and single-line content.
public struct ValidQuotesSpec: Specification {
    public typealias T = RawLine

    private let spec: AnySpecification<RawLine>

    public init() {
        self.spec = AnySpecification(
            StartsWithDoubleQuoteSpec()
                .and(EndsWithDoubleQuoteSpec())
                .and(ContentWithinQuotesIsSingleLineSpec())
        )
    }

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        spec.isSatisfiedBy(candidate)
    }
}

private func trimmedCandidate(_ candidate: RawLine) -> Substring {
    candidate.text.drop(while: { $0 == " " })
}
