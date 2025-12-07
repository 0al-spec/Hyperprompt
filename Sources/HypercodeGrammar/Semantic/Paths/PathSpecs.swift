import Foundation
import SpecificationCore

/// Composite validation for references combining extension checks and security rules.
public struct ValidReferencePathSpec: Specification {
    public typealias T = String

    private let spec: AnySpecification<String>

    public init(rootPath: String) {
        let security = NoTraversalSpec().and(WithinRootSpec(rootPath: rootPath))
        let structure = LooksLikeFileReferenceSpec()
        self.spec = AnySpecification(security.and(structure))
    }

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        spec.isSatisfiedBy(candidate)
    }
}
