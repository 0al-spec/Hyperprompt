import XCTest
import Resolver
@testable import EditorEngine

final class DecisionSpecsTests: XCTestCase {
    func testLinkReferenceHintDecisionSpecClassifiesFileReferences() {
        let spec = LinkReferenceHintDecisionSpec()

        XCTAssertEqual(spec.decide("docs/readme.md"), .fileReference)
        XCTAssertEqual(spec.decide("Just some text"), .inlineText)
    }

    func testLinkLiteralDecisionSpecClassifiesLiterals() {
        let spec = LinkLiteralDecisionSpec()

        XCTAssertEqual(spec.decide("Plain text"), .inlineText)
        XCTAssertEqual(spec.decide("../secret.md"), .invalidTraversal)
        XCTAssertEqual(spec.decide("notes.md"), .markdown)
        XCTAssertEqual(spec.decide("snippet.hc"), .hypercode)
        XCTAssertEqual(spec.decide("asset.txt"), .forbiddenExtension)
    }

    func testFileTypeDecisionSpecDetectsMarkdownAndHypercode() {
        let spec = FileTypeDecisionSpec()

        XCTAssertEqual(spec.decide("main.hc"), .hypercode)
        XCTAssertEqual(spec.decide("readme.md"), .markdown)
        XCTAssertNil(spec.decide("notes.txt"))
    }

    func testTargetFileSpecRequiresKnownExtensions() {
        let spec = TargetFileSpec()

        XCTAssertTrue(spec.isSatisfiedBy("src/main.hc"))
        XCTAssertTrue(spec.isSatisfiedBy("docs/readme.md"))
        XCTAssertFalse(spec.isSatisfiedBy("notes.txt"))
    }

    func testDirectoryDispositionDecisionSpecSkipsHiddenAndIgnoredDirectories() {
        let spec = DirectoryDispositionDecisionSpec()
        let ignored: Set<String> = ["node_modules"]

        let hiddenContext = DirectoryDecisionContext(
            path: "/workspace/.git",
            includeHidden: false,
            ignoredDirectories: ignored
        )
        XCTAssertEqual(spec.decide(hiddenContext), .skip)

        let ignoredContext = DirectoryDecisionContext(
            path: "/workspace/node_modules",
            includeHidden: true,
            ignoredDirectories: ignored
        )
        XCTAssertEqual(spec.decide(ignoredContext), .skip)

        let visibleContext = DirectoryDecisionContext(
            path: "/workspace/src",
            includeHidden: false,
            ignoredDirectories: ignored
        )
        XCTAssertEqual(spec.decide(visibleContext), .include)
    }

    func testRootEligibilityDecisionSpecRespectsResolutionMode() {
        let spec = RootEligibilityDecisionSpec()

        let eligibleContext = RootEligibilityContext(
            root: "/workspace",
            literal: "docs/readme.md",
            mode: .strict
        )
        XCTAssertEqual(spec.decide(eligibleContext), .eligible)

        let strictOutOfRoot = RootEligibilityContext(
            root: "/workspace",
            literal: "/tmp/elsewhere.md",
            mode: .strict
        )
        XCTAssertEqual(spec.decide(strictOutOfRoot), .outOfRootStrict)

        let lenientOutOfRoot = RootEligibilityContext(
            root: "/workspace",
            literal: "/tmp/elsewhere.md",
            mode: .lenient
        )
        XCTAssertEqual(spec.decide(lenientOutOfRoot), .outOfRootLenient)
    }

    func testCandidateResolutionDecisionSpecEvaluatesExistence() {
        let spec = CandidateResolutionDecisionSpec()

        XCTAssertEqual(
            spec.decide(CandidateResolutionContext(exists: true, mode: .strict)),
            .found
        )
        XCTAssertEqual(
            spec.decide(CandidateResolutionContext(exists: false, mode: .strict)),
            .missingStrict
        )
        XCTAssertEqual(
            spec.decide(CandidateResolutionContext(exists: false, mode: .lenient)),
            .missingLenient
        )
    }

    func testResolutionOutcomeDecisionSpecClassifiesCandidateCounts() {
        let spec = ResolutionOutcomeDecisionSpec()

        XCTAssertEqual(
            spec.decide(ResolutionOutcomeContext(candidateCount: 2, mode: .strict)),
            .ambiguous
        )
        XCTAssertEqual(
            spec.decide(ResolutionOutcomeContext(candidateCount: 1, mode: .strict)),
            .resolved
        )
        XCTAssertEqual(
            spec.decide(ResolutionOutcomeContext(candidateCount: 0, mode: .strict)),
            .unresolvedStrict
        )
        XCTAssertEqual(
            spec.decide(ResolutionOutcomeContext(candidateCount: 0, mode: .lenient)),
            .unresolvedLenient
        )
    }

    func testOutputPathStrategyDecisionSpecSelectsStrategy() {
        let spec = OutputPathStrategyDecisionSpec()

        XCTAssertEqual(spec.decide("docs/page.hc"), .replaceHypercodeExtension)
        XCTAssertEqual(spec.decide("docs/page.md"), .appendMarkdownExtension)
    }

    func testRootPathStrategyDecisionSpecUsesSeparator() {
        let spec = RootPathStrategyDecisionSpec()

        XCTAssertEqual(spec.decide("docs/page.hc"), .parentDirectory)
        XCTAssertEqual(spec.decide("page.hc"), .currentDirectory)
    }

    func testCompilePolicyDecisionSpecsReturnExpectedFlags() {
        let manifest = ManifestPolicyDecisionSpec()
        let statistics = StatisticsPolicyDecisionSpec()
        let outputWrite = OutputWritePolicyDecisionSpec()

        XCTAssertEqual(manifest.decide(.include), true)
        XCTAssertEqual(manifest.decide(.omit), false)

        XCTAssertEqual(statistics.decide(.include), true)
        XCTAssertEqual(statistics.decide(.omit), false)

        XCTAssertEqual(outputWrite.decide(.write), true)
        XCTAssertEqual(outputWrite.decide(.dryRun), false)
    }
}
