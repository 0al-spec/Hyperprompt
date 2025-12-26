#if Editor
import Foundation
import HypercodeGrammar
import SpecificationCore

// MARK: - Link Reference Hint

public enum LinkReferenceHint: String, Codable, Equatable, Sendable {
    case fileReference
    case inlineText
}

struct LinkReferenceHintDecisionSpec: DecisionSpec {
    private let decision: FirstMatchSpec<String, LinkReferenceHint>

    init() {
        let looksLike = LooksLikeFileReferenceSpec()
        let isReference = PredicateSpec<String>(description: "Looks like file reference") { literal in
            looksLike.isSatisfiedBy(literal)
        }
        self.decision = FirstMatchSpec.withFallback(
            [
                (isReference, .fileReference)
            ],
            fallback: .inlineText
        )
    }

    func decide(_ literal: String) -> LinkReferenceHint? {
        decision.decide(literal)
    }
}

// MARK: - Link Literal Decision

enum LinkLiteralDecision {
    case inlineText
    case invalidTraversal
    case forbiddenExtension
    case markdown
    case hypercode
}

struct LinkLiteralDecisionSpec: DecisionSpec {
    private let decision: FirstMatchSpec<String, LinkLiteralDecision>

    init() {
        let looksLike = LooksLikeFileReferenceSpec()
        let traversal = NoTraversalSpec()
        let hasMarkdown = HasMarkdownExtensionSpec()
        let hasHypercode = HasHypercodeExtensionSpec()

        let notReference = PredicateSpec<String>(description: "Not a file reference") { literal in
            !looksLike.isSatisfiedBy(literal)
        }
        let traversalViolation = PredicateSpec<String>(description: "Path traversal detected") { literal in
            !traversal.isSatisfiedBy(literal)
        }
        let markdown = PredicateSpec<String>(description: "Markdown extension") { literal in
            hasMarkdown.isSatisfiedBy(literal)
        }
        let hypercode = PredicateSpec<String>(description: "Hypercode extension") { literal in
            hasHypercode.isSatisfiedBy(literal)
        }
        let forbiddenExtension = PredicateSpec<String>(description: "Forbidden extension") { literal in
            let ext = (literal as NSString).pathExtension.lowercased()
            guard !ext.isEmpty else {
                return false
            }
            return !hasMarkdown.isSatisfiedBy(literal) && !hasHypercode.isSatisfiedBy(literal)
        }

        self.decision = FirstMatchSpec.withFallback(
            [
                (notReference, .inlineText),
                (traversalViolation, .invalidTraversal),
                (markdown, .markdown),
                (hypercode, .hypercode),
                (forbiddenExtension, .forbiddenExtension)
            ],
            fallback: .inlineText
        )
    }

    func decide(_ literal: String) -> LinkLiteralDecision? {
        decision.decide(literal)
    }
}
#endif
