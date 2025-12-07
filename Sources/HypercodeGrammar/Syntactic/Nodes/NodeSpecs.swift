import Core
import Foundation
import SpecificationCore

/// Ensures indentation depth does not exceed configured maximum.
public struct DepthWithinLimitSpec: Specification {
    public typealias T = RawLine

    private let maxDepth: Int

    public init(maxDepth: Int = 10) {
        self.maxDepth = maxDepth
    }

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        let depth = candidate.leadingSpaces / 4
        return depth <= maxDepth
    }
}

/// Composite validation for node lines including indentation and quoting rules.
public struct ValidNodeLineSpec: Specification {
    public typealias T = RawLine

    private let spec: AnySpecification<RawLine>

    public init(maxDepth: Int = 10) {
        let indentation = NoTabsIndentSpec()
            .and(IndentMultipleOf4Spec())
            .and(DepthWithinLimitSpec(maxDepth: maxDepth))

        let quoting = ValidQuotesSpec()
            .and(SingleLineLiteralSpec())

        self.spec = AnySpecification(indentation.and(quoting))
    }

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        spec.isSatisfiedBy(candidate)
    }
}

/// Validates that extracted literal content for a node is single-line.
public struct SingleLineLiteralSpec: Specification {
    public typealias T = RawLine

    private let contentSpec = SingleLineContentSpec()

    public init() {}

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        guard let literal = extractLiteral(candidate) else {
            return false
        }
        return contentSpec.isSatisfiedBy(literal)
    }
}

/// Extracts literal content (without quotes) from a raw node line when possible.
public func extractLiteral(_ candidate: RawLine) -> String? {
    let trimmed = candidate.text.drop(while: { $0 == " " })
    guard trimmed.first == QuoteDelimiter.doubleQuote,
        trimmed.last == QuoteDelimiter.doubleQuote
    else {
        return nil
    }
    return String(trimmed.dropFirst().dropLast())
}
