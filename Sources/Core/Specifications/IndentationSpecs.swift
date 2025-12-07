import SpecificationCore

/// Specification ensuring an integer aligns to the configured indentation width.
public struct IndentGroupAlignmentSpec: Specification {
    public typealias T = Int

    private let spacesPerLevel: Int

    public init(spacesPerLevel: Int = Indentation.spacesPerLevel) {
        self.spacesPerLevel = spacesPerLevel
    }

    public func isSatisfiedBy(_ candidate: Int) -> Bool {
        guard spacesPerLevel > 0 else {
            return false
        }
        return candidate % spacesPerLevel == 0
    }
}
