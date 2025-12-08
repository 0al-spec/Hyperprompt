import Core
import Foundation
import SpecificationCore

/// Ensures a path does not traverse upward using `..` segments.
public struct NoTraversalSpec: Specification {
    public typealias T = String

    public init() {}

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        let components = candidate.components(separatedBy: PathSegment.separators)
        return !components.contains(PathSegment.traversal)
    }
}

/// Ensures a path remains within a configured root directory.
public struct WithinRootSpec: Specification {
    public typealias T = String

    private let root: URL

    public init(rootPath: String) {
        self.root = URL(fileURLWithPath: rootPath, isDirectory: true).standardizedFileURL
    }

    public func isSatisfiedBy(_ candidate: String) -> Bool {
        let candidateURL = URL(fileURLWithPath: candidate, relativeTo: root).standardizedFileURL
        let rootComponents = root.pathComponents
        let candidateComponents = candidateURL.pathComponents

        guard candidateComponents.count >= rootComponents.count else {
            return false
        }

        return candidateComponents.prefix(rootComponents.count).elementsEqual(rootComponents)
    }
}
