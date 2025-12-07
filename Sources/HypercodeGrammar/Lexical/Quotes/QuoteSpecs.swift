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

    public init() {}

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        let trimmed = trimmedCandidate(candidate)
        guard trimmed.first == "\"", trimmed.last == "\"" else {
            return false
        }

        let content = trimmed.dropFirst().dropLast()
        return !content.contains("\n") && !content.contains("\r")
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
