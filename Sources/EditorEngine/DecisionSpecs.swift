import Foundation
import HypercodeGrammar
import Resolver
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

// MARK: - Indexer Option Policies

public enum HiddenEntryPolicy: String, Codable, Equatable, Sendable {
    case include
    case exclude
}

public enum SymlinkPolicy: String, Codable, Equatable, Sendable {
    case follow
    case skip
}
