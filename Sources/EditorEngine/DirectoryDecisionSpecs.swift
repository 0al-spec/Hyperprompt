import Foundation
import SpecificationCore

// MARK: - Directory Decisions

enum DirectoryDisposition {
    case include
    case skip
}

struct DirectoryDecisionContext {
    let path: String
    let includeHidden: Bool
    let ignoredDirectories: Set<String>
}

struct DirectoryDispositionDecisionSpec: DecisionSpec {
    private let decision: FirstMatchSpec<DirectoryDecisionContext, DirectoryDisposition>

    init() {
        let hiddenDirectory = PredicateSpec<DirectoryDecisionContext>(
            description: "Hidden directory excluded"
        ) { context in
            let basename = (context.path as NSString).lastPathComponent
            return !context.includeHidden && basename.hasPrefix(".")
        }

        let defaultIgnored = PredicateSpec<DirectoryDecisionContext>(
            description: "Default ignored directory"
        ) { context in
            let basename = (context.path as NSString).lastPathComponent
            return context.ignoredDirectories.contains(basename)
        }

        self.decision = FirstMatchSpec.withFallback(
            [
                (hiddenDirectory, .skip),
                (defaultIgnored, .skip)
            ],
            fallback: .include
        )
    }

    func decide(_ context: DirectoryDecisionContext) -> DirectoryDisposition? {
        decision.decide(context)
    }
}
