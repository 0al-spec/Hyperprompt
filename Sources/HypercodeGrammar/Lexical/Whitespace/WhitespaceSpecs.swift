import Core
import Foundation
import SpecificationCore

/// Verifies that a line contains only spaces.
public struct IsBlankLineSpec: Specification {
    public typealias T = RawLine

    public init() {}

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        candidate.text
            .trimmingCharacters(in: .newlines)
            .allSatisfy { $0 == Whitespace.space }
    }
}

/// Verifies that indentation contains no tab characters.
public struct NoTabsIndentSpec: Specification {
    public typealias T = RawLine

    public init() {}

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        let indent = candidate.text.prefix {
            $0 == Whitespace.space || $0 == Whitespace.tab
        }
        return !indent.contains(Whitespace.tab)
    }
}

/// Verifies that indentation is a multiple of four spaces.
public struct IndentMultipleOf4Spec: Specification {
    public typealias T = RawLine

    public init() {}

    public func isSatisfiedBy(_ candidate: RawLine) -> Bool {
        candidate.leadingSpaces % 4 == 0
    }
}
