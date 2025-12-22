import SpecificationCore

// MARK: - Compile Option Policies

public enum ManifestPolicy: String, Codable, Equatable, Sendable {
    case include
    case omit
}

public enum StatisticsPolicy: String, Codable, Equatable, Sendable {
    case include
    case omit
}

public enum OutputWritePolicy: String, Codable, Equatable, Sendable {
    case write
    case dryRun
}

struct ManifestPolicyDecisionSpec: DecisionSpec {
    private let decision: FirstMatchSpec<ManifestPolicy, Bool>

    init() {
        let include = PredicateSpec<ManifestPolicy>(description: "Include manifest") { policy in
            policy == .include
        }
        self.decision = FirstMatchSpec.withFallback(
            [
                (include, true)
            ],
            fallback: false
        )
    }

    func decide(_ policy: ManifestPolicy) -> Bool? {
        decision.decide(policy)
    }
}

struct StatisticsPolicyDecisionSpec: DecisionSpec {
    private let decision: FirstMatchSpec<StatisticsPolicy, Bool>

    init() {
        let include = PredicateSpec<StatisticsPolicy>(description: "Include statistics") { policy in
            policy == .include
        }
        self.decision = FirstMatchSpec.withFallback(
            [
                (include, true)
            ],
            fallback: false
        )
    }

    func decide(_ policy: StatisticsPolicy) -> Bool? {
        decision.decide(policy)
    }
}

struct OutputWritePolicyDecisionSpec: DecisionSpec {
    private let decision: FirstMatchSpec<OutputWritePolicy, Bool>

    init() {
        let write = PredicateSpec<OutputWritePolicy>(description: "Write output files") { policy in
            policy == .write
        }
        self.decision = FirstMatchSpec.withFallback(
            [
                (write, true)
            ],
            fallback: false
        )
    }

    func decide(_ policy: OutputWritePolicy) -> Bool? {
        decision.decide(policy)
    }
}
