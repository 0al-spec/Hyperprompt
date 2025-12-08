import Foundation
import SpecificationCore

/// Decision that classifies raw lines into `LineKind`.
public struct LineKindDecision: DecisionSpec {
    public typealias Context = RawLine
    public typealias Result = LineKind

    public init() {}

    public func decide(_ context: RawLine) -> LineKind? {
        if IsBlankLineSpec().isSatisfiedBy(context) {
            return .blank
        }

        if IsCommentLineSpec().isSatisfiedBy(context) {
            return .comment(prefix: "#")
        }

        if ValidNodeLineSpec().isSatisfiedBy(context), let literal = extractLiteral(context) {
            return .node(literal: literal)
        }

        return nil
    }
}

/// Decision that classifies paths into semantic categories.
public struct PathTypeDecision: DecisionSpec {
    public typealias Context = String
    public typealias Result = PathKind

    private let rootPath: String

    public init(rootPath: String) {
        self.rootPath = rootPath
    }

    public func decide(_ context: String) -> PathKind? {
        let traversalSafe = NoTraversalSpec().isSatisfiedBy(context)
        let withinRoot = WithinRootSpec(rootPath: rootPath).isSatisfiedBy(context)
        let looksLikeFile = LooksLikeFileReferenceSpec().isSatisfiedBy(context)

        guard traversalSafe && withinRoot && looksLikeFile else {
            return .invalid(reason: "Path escapes root or is malformed")
        }

        let allowedExtensions = IsAllowedExtensionSpec()
        let pathExtension = (context as NSString).pathExtension

        if allowedExtensions.isSatisfiedBy(context) {
            return .allowed(extension: pathExtension.lowercased())
        }

        return .forbidden(extension: pathExtension.lowercased())
    }
}

/// Factory helpers for grammar specifications.
public enum HypercodeGrammar {
    public static func makeLineClassifier() -> LineKindDecision {
        LineKindDecision()
    }

    public static func makePathClassifier(rootPath: String) -> PathTypeDecision {
        PathTypeDecision(rootPath: rootPath)
    }
}
