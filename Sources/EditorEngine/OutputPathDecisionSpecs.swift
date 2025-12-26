#if Editor
import SpecificationCore

// MARK: - Output Path Decisions

enum OutputPathStrategy {
    case replaceHypercodeExtension
    case appendMarkdownExtension
}

struct OutputPathStrategyDecisionSpec: DecisionSpec {
    private let decision: FirstMatchSpec<String, OutputPathStrategy>

    init() {
        let isHypercode = PredicateSpec<String>(description: "Hypercode input path") { path in
            path.hasSuffix(".hc")
        }

        self.decision = FirstMatchSpec.withFallback(
            [
                (isHypercode, .replaceHypercodeExtension)
            ],
            fallback: .appendMarkdownExtension
        )
    }

    func decide(_ inputPath: String) -> OutputPathStrategy? {
        decision.decide(inputPath)
    }
}

enum RootPathStrategy {
    case parentDirectory
    case currentDirectory
}

struct RootPathStrategyDecisionSpec: DecisionSpec {
    private let decision: FirstMatchSpec<String, RootPathStrategy>

    init() {
        let containsSeparator = PredicateSpec<String>(description: "Has path separator") { path in
            path.contains("/")
        }

        self.decision = FirstMatchSpec.withFallback(
            [
                (containsSeparator, .parentDirectory)
            ],
            fallback: .currentDirectory
        )
    }

    func decide(_ inputPath: String) -> RootPathStrategy? {
        decision.decide(inputPath)
    }
}
#endif
