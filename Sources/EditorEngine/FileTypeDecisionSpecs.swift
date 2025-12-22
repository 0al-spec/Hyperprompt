import SpecificationCore

// MARK: - File Type Decisions

struct FileTypeDecisionSpec: DecisionSpec {
    private let decision: FirstMatchSpec<String, FileType>

    init() {
        let isHypercode = PredicateSpec<String>(description: "Has .hc extension") { path in
            path.hasSuffix(".hc")
        }
        let isMarkdown = PredicateSpec<String>(description: "Has .md extension") { path in
            path.hasSuffix(".md")
        }

        self.decision = FirstMatchSpec([
            (isHypercode, .hypercode),
            (isMarkdown, .markdown)
        ])
    }

    func decide(_ path: String) -> FileType? {
        decision.decide(path)
    }
}

struct TargetFileSpec: Specification {
    private let typeDecision = FileTypeDecisionSpec()

    func isSatisfiedBy(_ path: String) -> Bool {
        typeDecision.decide(path) != nil
    }
}
