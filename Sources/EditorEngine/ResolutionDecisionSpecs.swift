import HypercodeGrammar
import Resolver
import SpecificationCore

// MARK: - Resolution Decisions

enum RootEligibilityDecision {
    case eligible
    case outOfRootStrict
    case outOfRootLenient
}

struct RootEligibilityContext {
    let root: String
    let literal: String
    let mode: ResolutionMode
}

struct RootEligibilityDecisionSpec: DecisionSpec {
    private let decision: FirstMatchSpec<RootEligibilityContext, RootEligibilityDecision>

    init() {
        let withinRoot = PredicateSpec<RootEligibilityContext>(
            description: "Within root"
        ) { context in
            WithinRootSpec(rootPath: context.root).isSatisfiedBy(context.literal)
        }
        let strictOutOfRoot = PredicateSpec<RootEligibilityContext>(
            description: "Out of root in strict mode"
        ) { context in
            context.mode == .strict
        }

        self.decision = FirstMatchSpec.withFallback(
            [
                (withinRoot, .eligible),
                (strictOutOfRoot, .outOfRootStrict)
            ],
            fallback: .outOfRootLenient
        )
    }

    func decide(_ context: RootEligibilityContext) -> RootEligibilityDecision? {
        decision.decide(context)
    }
}

enum CandidateResolutionDecision {
    case found
    case missingStrict
    case missingLenient
}

struct CandidateResolutionContext {
    let exists: Bool
    let mode: ResolutionMode
}

struct CandidateResolutionDecisionSpec: DecisionSpec {
    private let decision: FirstMatchSpec<CandidateResolutionContext, CandidateResolutionDecision>

    init() {
        let exists = PredicateSpec<CandidateResolutionContext>(description: "Candidate exists") { context in
            context.exists
        }
        let missingStrict = PredicateSpec<CandidateResolutionContext>(
            description: "Missing in strict mode"
        ) { context in
            !context.exists && context.mode == .strict
        }

        self.decision = FirstMatchSpec.withFallback(
            [
                (exists, .found),
                (missingStrict, .missingStrict)
            ],
            fallback: .missingLenient
        )
    }

    func decide(_ context: CandidateResolutionContext) -> CandidateResolutionDecision? {
        decision.decide(context)
    }
}

enum ResolutionOutcomeDecision {
    case ambiguous
    case resolved
    case unresolvedStrict
    case unresolvedLenient
}

struct ResolutionOutcomeContext {
    let candidateCount: Int
    let mode: ResolutionMode
}

struct ResolutionOutcomeDecisionSpec: DecisionSpec {
    private let decision: FirstMatchSpec<ResolutionOutcomeContext, ResolutionOutcomeDecision>

    init() {
        let ambiguous = PredicateSpec<ResolutionOutcomeContext>(description: "Ambiguous candidates") { context in
            context.candidateCount > 1
        }
        let resolved = PredicateSpec<ResolutionOutcomeContext>(description: "Single candidate") { context in
            context.candidateCount == 1
        }
        let unresolvedStrict = PredicateSpec<ResolutionOutcomeContext>(
            description: "Unresolved in strict mode"
        ) { context in
            context.candidateCount == 0 && context.mode == .strict
        }

        self.decision = FirstMatchSpec.withFallback(
            [
                (ambiguous, .ambiguous),
                (resolved, .resolved),
                (unresolvedStrict, .unresolvedStrict)
            ],
            fallback: .unresolvedLenient
        )
    }

    func decide(_ context: ResolutionOutcomeContext) -> ResolutionOutcomeDecision? {
        decision.decide(context)
    }
}
