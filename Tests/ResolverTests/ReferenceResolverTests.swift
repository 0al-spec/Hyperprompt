import XCTest
import Core
import Parser
@testable import Resolver

/// Unit tests for ReferenceResolver.
///
/// Test categories:
/// A. Basic Classification (Inline vs. File)
/// B. Markdown File Resolution
/// C. Hypercode File Resolution
/// D. Forbidden Extensions
/// E. Path Traversal
/// F. Source Location Preservation
/// G. Integration Hooks
final class ReferenceResolverTests: XCTestCase {

    private var mockFS: MockFileSystem!
    private let rootPath = "/project"

    override func setUp() {
        super.setUp()
        mockFS = MockFileSystem()
        mockFS.setCurrentDirectory(rootPath)
    }

    override func tearDown() {
        mockFS.clear()
        mockFS = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeNode(_ literal: String, line: Int = 1) -> Node {
        Node(
            literal: literal,
            depth: 0,
            location: SourceLocation(filePath: "test.hc", line: line)
        )
    }

    private func makeResolver(
        mode: ResolutionMode = .strict,
        tracker: DependencyTracker? = nil
    ) -> ReferenceResolver {
        ReferenceResolver(
            fileSystem: mockFS,
            rootPath: rootPath,
            mode: mode,
            dependencyTracker: tracker
        )
    }

    // MARK: - A. Basic Classification Tests (Inline vs. File)

    func testInlineTextWithoutSlashesOrDots() {
        // Inline text without slashes or dots → inlineText
        var resolver = makeResolver()
        let node = makeNode("Hello World")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            XCTAssertEqual(kind, .inlineText)
        case .failure(let error):
            XCTFail("Expected success, got error: \(error.message)")
        }
    }

    func testInlineTextWithSpacesOnly() {
        var resolver = makeResolver()
        let node = makeNode("   Some text with spaces   ")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            XCTAssertEqual(kind, .inlineText)
        case .failure:
            XCTFail("Expected inline text")
        }
    }

    func testTextWithSentenceEndingDotTreatedAsPotentialPath() {
        // "Version 1.0" contains a dot, so it's treated as potential path
        // In strict mode, missing file → error
        var resolver = makeResolver(mode: .strict)
        let node = makeNode("Version 1.0")

        let result = resolver.resolve(node: node)

        // Contains "." so looks like file path
        // Extension would be "0" which is forbidden
        switch result {
        case .success:
            XCTFail("Expected forbidden extension error for '.0'")
        case .failure(let error):
            XCTAssertTrue(error.message.contains("Unsupported file extension"))
        }
    }

    func testTextWithSentenceEndingDotLenientMode() {
        // In lenient mode, forbidden extension still causes error
        var resolver = makeResolver(mode: .lenient)
        let node = makeNode("Version 1.0")

        let result = resolver.resolve(node: node)

        // Forbidden extensions are always errors regardless of mode
        switch result {
        case .success:
            XCTFail("Expected forbidden extension error")
        case .failure(let error):
            XCTAssertTrue(error.message.contains("Unsupported file extension"))
        }
    }

    func testPathWithSlashNoExtension() {
        // "docs/readme" has slash but no extension → inlineText
        var resolver = makeResolver()
        let node = makeNode("docs/readme")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            XCTAssertEqual(kind, .inlineText)
        case .failure:
            XCTFail("Expected inline text for path without extension")
        }
    }

    // MARK: - B. Markdown File Resolution Tests

    func testMarkdownFileExistsStrictMode() {
        mockFS.addFile(at: "/project/README.md", content: "# Readme\n\nContent here.")
        var resolver = makeResolver(mode: .strict)
        let node = makeNode("README.md")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            if case .markdownFile(let path, let content) = kind {
                XCTAssertEqual(path, "README.md")
                XCTAssertEqual(content, "# Readme\n\nContent here.")
            } else {
                XCTFail("Expected markdownFile, got \(kind)")
            }
        case .failure(let error):
            XCTFail("Expected success, got error: \(error.message)")
        }
    }

    func testMarkdownFileExistsLenientMode() {
        mockFS.addFile(at: "/project/docs/guide.md", content: "# Guide")
        var resolver = makeResolver(mode: .lenient)
        let node = makeNode("docs/guide.md")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            if case .markdownFile(let path, _) = kind {
                XCTAssertEqual(path, "docs/guide.md")
            } else {
                XCTFail("Expected markdownFile")
            }
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testMarkdownFileMissingStrictMode() {
        // No file added
        var resolver = makeResolver(mode: .strict)
        let node = makeNode("missing.md", line: 5)

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected error for missing file in strict mode")
        case .failure(let error):
            XCTAssertTrue(error.message.contains("File not found in strict mode"))
            XCTAssertEqual(error.location?.line, 5)
        }
    }

    func testMarkdownFileMissingLenientMode() {
        // No file added
        var resolver = makeResolver(mode: .lenient)
        let node = makeNode("missing.md")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            XCTAssertEqual(kind, .inlineText)
        case .failure:
            XCTFail("Expected inlineText in lenient mode")
        }
    }

    func testMarkdownFileWithSpacesInPath() {
        mockFS.addFile(at: "/project/my docs/my file.md", content: "Content")
        var resolver = makeResolver()
        let node = makeNode("my docs/my file.md")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            if case .markdownFile(let path, _) = kind {
                XCTAssertEqual(path, "my docs/my file.md")
            } else {
                XCTFail("Expected markdownFile")
            }
        case .failure:
            XCTFail("Expected success for path with spaces")
        }
    }

    // MARK: - C. Hypercode File Resolution Tests

    func testHypercodeFileExistsStrictMode() {
        mockFS.addFile(at: "/project/nested.hc", content: "\"Nested content\"")
        var resolver = makeResolver(mode: .strict)
        let node = makeNode("nested.hc")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            if case .hypercodeFile(let path, _) = kind {
                XCTAssertEqual(path, "nested.hc")
            } else {
                XCTFail("Expected hypercodeFile")
            }
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testHypercodeFileExistsLenientMode() {
        mockFS.addFile(at: "/project/templates/form.hc", content: "\"Form\"")
        var resolver = makeResolver(mode: .lenient)
        let node = makeNode("templates/form.hc")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            if case .hypercodeFile(let path, _) = kind {
                XCTAssertEqual(path, "templates/form.hc")
            } else {
                XCTFail("Expected hypercodeFile")
            }
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testHypercodeFileMissingStrictMode() {
        var resolver = makeResolver(mode: .strict)
        let node = makeNode("missing.hc", line: 10)

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected error for missing file")
        case .failure(let error):
            XCTAssertTrue(error.message.contains("File not found"))
            XCTAssertEqual(error.location?.line, 10)
        }
    }

    func testHypercodeFileMissingLenientMode() {
        var resolver = makeResolver(mode: .lenient)
        let node = makeNode("missing.hc")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            XCTAssertEqual(kind, .inlineText)
        case .failure:
            XCTFail("Expected inlineText")
        }
    }

    func testNestedHypercodeFilePath() {
        mockFS.addFile(at: "/project/subdir/deep/file.hc", content: "\"Deep\"")
        var resolver = makeResolver()
        let node = makeNode("subdir/deep/file.hc")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            if case .hypercodeFile(let path, _) = kind {
                XCTAssertEqual(path, "subdir/deep/file.hc")
            } else {
                XCTFail("Expected hypercodeFile")
            }
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testHypercodeCycleDetectedWithTracker() {
        mockFS.addFile(at: "/project/main.hc", content: "\"A\"")
        let tracker = DependencyTracker(fileSystem: mockFS, initialStack: ["/project/main.hc"])
        var resolver = makeResolver(tracker: tracker)
        let node = makeNode("main.hc", line: 3)

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected circular dependency error")
        case .failure(let error):
            XCTAssertTrue(error.message.contains("Circular dependency"))
            XCTAssertTrue(error.message.contains("Cycle path"))
        }
    }

    // MARK: - D. Forbidden Extensions Tests

    func testForbiddenExtensionJson() {
        var resolver = makeResolver()
        let node = makeNode("config.json", line: 3)

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected forbidden error")
        case .failure(let error):
            XCTAssertTrue(error.message.contains("Unsupported file extension"))
            XCTAssertTrue(error.message.contains(".json"))
            XCTAssertEqual(error.location?.line, 3)
        }
    }

    func testForbiddenExtensionTxt() {
        var resolver = makeResolver()
        let node = makeNode("notes.txt")

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected forbidden error")
        case .failure(let error):
            XCTAssertTrue(error.message.contains(".txt"))
        }
    }

    func testForbiddenExtensionJs() {
        var resolver = makeResolver()
        let node = makeNode("script.js")

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected forbidden error")
        case .failure(let error):
            XCTAssertTrue(error.message.contains(".js"))
        }
    }

    func testForbiddenExtensionPy() {
        var resolver = makeResolver()
        let node = makeNode("utils/helper.py")

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected forbidden error")
        case .failure(let error):
            XCTAssertTrue(error.message.contains(".py"))
        }
    }

    func testNoExtensionLooksLikeFile() {
        // "README" without extension → inlineText (no extension)
        var resolver = makeResolver()
        let node = makeNode("README")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            XCTAssertEqual(kind, .inlineText)
        case .failure:
            XCTFail("Expected inlineText")
        }
    }

    func testCaseInsensitiveExtensionMd() {
        mockFS.addFile(at: "/project/FILE.MD", content: "Upper case")
        var resolver = makeResolver()
        let node = makeNode("FILE.MD")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            if case .markdownFile = kind {
                // Success - case insensitive
            } else {
                XCTFail("Expected markdownFile")
            }
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testCaseInsensitiveExtensionHc() {
        mockFS.addFile(at: "/project/FILE.HC", content: "\"Upper\"")
        var resolver = makeResolver()
        let node = makeNode("FILE.HC")

        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            if case .hypercodeFile = kind {
                // Success
            } else {
                XCTFail("Expected hypercodeFile")
            }
        case .failure:
            XCTFail("Expected success")
        }
    }

    // MARK: - E. Path Traversal Tests

    func testPathTraversalFromRoot() {
        var resolver = makeResolver()
        let node = makeNode("../../../etc/passwd", line: 7)

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected path traversal error")
        case .failure(let error):
            XCTAssertTrue(error.message.contains("Path traversal"))
            XCTAssertEqual(error.location?.line, 7)
        }
    }

    func testPathTraversalInMiddle() {
        var resolver = makeResolver()
        let node = makeNode("subdir/../../../escape.md")

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected path traversal error")
        case .failure(let error):
            XCTAssertTrue(error.message.contains("Path traversal"))
        }
    }

    func testPathTraversalAtEnd() {
        var resolver = makeResolver()
        let node = makeNode("subdir/..")

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected path traversal error")
        case .failure(let error):
            XCTAssertTrue(error.message.contains("Path traversal"))
        }
    }

    func testPathTraversalJustDotDot() {
        var resolver = makeResolver()
        let node = makeNode("..")

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected path traversal error")
        case .failure(let error):
            XCTAssertTrue(error.message.contains("Path traversal"))
        }
    }

    func testSameDirectoryReferenceAllowed() {
        // "./file.md" should be allowed (same directory)
        mockFS.addFile(at: "/project/./file.md", content: "Content")
        // Actually, need to handle ./ normalization
        // For now, ./ won't trigger traversal detection
        var resolver = makeResolver()
        let node = makeNode("./file.md")

        let result = resolver.resolve(node: node)

        // ./ doesn't contain .. so no traversal error
        // But the file lookup will use "./file.md" which might not match
        // This is a valid case for the heuristic
        switch result {
        case .success, .failure:
            // Either is acceptable - the key is no traversal error for ./
            if case .failure(let error) = result {
                XCTAssertFalse(error.message.contains("Path traversal"),
                              "./ should not trigger path traversal")
            }
        }
    }

    func testFileWithoutSlashNotFlaggedAsTraversal() {
        // "file.md" without / is not flagged as traversal
        var resolver = makeResolver()
        let node = makeNode("file.md")

        let result = resolver.resolve(node: node)

        switch result {
        case .success, .failure:
            if case .failure(let error) = result {
                XCTAssertFalse(error.message.contains("Path traversal"))
            }
        }
    }

    // MARK: - F. Source Location Preservation Tests

    func testErrorIncludesCorrectLineNumber() {
        var resolver = makeResolver(mode: .strict)
        let node = makeNode("missing.md", line: 42)

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error.location?.line, 42)
            XCTAssertEqual(error.location?.filePath, "test.hc")
        }
    }

    func testErrorIncludesFilePath() {
        var resolver = makeResolver(mode: .strict)
        let node = Node(
            literal: "missing.md",
            depth: 0,
            location: SourceLocation(filePath: "source/input.hc", line: 15)
        )

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertEqual(error.location?.filePath, "source/input.hc")
            XCTAssertEqual(error.location?.line, 15)
        }
    }

    func testDiagnosticInfoIsReadable() {
        var resolver = makeResolver(mode: .strict)
        let node = makeNode("missing.md", line: 5)

        let result = resolver.resolve(node: node)

        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            let diagnostic = error.diagnosticInfo
            XCTAssertTrue(diagnostic.contains("test.hc:5"))
            XCTAssertTrue(diagnostic.contains("Resolution"))
        }
    }

    // MARK: - G. Integration Hooks Tests (for B2, B3, B4)

    func testDependencyTrackerPushesAndPopsDuringHypercodeResolution() {
        mockFS.addFile(at: "/project/child.hc", content: "\"Child\"")
        let tracker = DependencyTracker(fileSystem: mockFS, initialStack: ["/project/root.hc"])
        var resolver = makeResolver(tracker: tracker)

        let node = makeNode("child.hc")
        let result = resolver.resolve(node: node)

        switch result {
        case .success(let kind):
            if case .hypercodeFile = kind {
                XCTAssertEqual(resolver.dependencyTracker?.stack, ["/project/root.hc"])
            } else {
                XCTFail("Expected hypercodeFile")
            }
        case .failure(let error):
            XCTFail("Unexpected failure: \(error.message)")
        }
    }

    func testClearVisited() {
        let tracker = DependencyTracker(fileSystem: mockFS, initialStack: ["/project/root.hc"])
        var resolver = makeResolver(tracker: tracker)

        resolver.clearVisited()
        XCTAssertNil(resolver.dependencyTracker)
    }

    func testResolveTreeSetsResolutionKind() {
        mockFS.addFile(at: "/project/child.md", content: "Child content")
        var resolver = makeResolver()

        let root = makeNode("Root text")
        let child = makeNode("child.md")
        root.addChild(child)

        let result = resolver.resolveTree(root: root)

        switch result {
        case .success:
            XCTAssertEqual(root.resolution, .inlineText)
            if case .markdownFile(_, _) = child.resolution {
                // Success
            } else {
                XCTFail("Expected child to be markdownFile")
            }
        case .failure(let error):
            XCTFail("Expected success, got: \(error.message)")
        }
    }

    func testResolveTreeStopsOnFirstError() {
        // No files exist
        var resolver = makeResolver(mode: .strict)

        let root = makeNode("root.md")  // Will fail
        let child = makeNode("child.md")  // Won't be reached
        root.addChild(child)

        let result = resolver.resolveTree(root: root)

        switch result {
        case .success:
            XCTFail("Expected error")
        case .failure(let error):
            XCTAssertTrue(error.message.contains("root.md"))
            // Child resolution should not have been set
            XCTAssertNil(child.resolution)
        }
    }

    // MARK: - Helper Method Tests

    func testLooksLikeFilePathWithSlash() {
        let resolver = makeResolver()
        XCTAssertTrue(resolver.looksLikeFilePath("docs/file"))
        XCTAssertTrue(resolver.looksLikeFilePath("a/b/c"))
        XCTAssertTrue(resolver.looksLikeFilePath("/absolute"))
    }

    func testLooksLikeFilePathWithDot() {
        let resolver = makeResolver()
        XCTAssertTrue(resolver.looksLikeFilePath("file.md"))
        XCTAssertTrue(resolver.looksLikeFilePath(".hidden"))
        XCTAssertTrue(resolver.looksLikeFilePath("name.ext.backup"))
    }

    func testLooksLikeFilePathWithNeither() {
        let resolver = makeResolver()
        XCTAssertFalse(resolver.looksLikeFilePath("plaintext"))
        XCTAssertFalse(resolver.looksLikeFilePath("Hello World"))
        XCTAssertFalse(resolver.looksLikeFilePath(""))
    }

    func testFileExtensionNormal() {
        let resolver = makeResolver()
        XCTAssertEqual(resolver.fileExtension("file.md"), "md")
        XCTAssertEqual(resolver.fileExtension("file.hc"), "hc")
        XCTAssertEqual(resolver.fileExtension("path/to/file.txt"), "txt")
    }

    func testFileExtensionNone() {
        let resolver = makeResolver()
        XCTAssertNil(resolver.fileExtension("README"))
        XCTAssertNil(resolver.fileExtension("path/to/noext"))
    }

    func testFileExtensionHidden() {
        let resolver = makeResolver()
        // ".hidden" is a hidden file, not an extension
        XCTAssertNil(resolver.fileExtension(".hidden"))
        XCTAssertNil(resolver.fileExtension(".gitignore"))
    }

    func testFileExtensionTrailingDot() {
        let resolver = makeResolver()
        XCTAssertNil(resolver.fileExtension("file."))
        XCTAssertNil(resolver.fileExtension("name."))
    }

    func testFileExtensionMultipleDots() {
        let resolver = makeResolver()
        // Returns last extension
        XCTAssertEqual(resolver.fileExtension("file.tar.gz"), "gz")
        XCTAssertEqual(resolver.fileExtension("name.backup.md"), "md")
    }

    func testContainsPathTraversalPositive() {
        let resolver = makeResolver()
        XCTAssertTrue(resolver.containsPathTraversal(".."))
        XCTAssertTrue(resolver.containsPathTraversal("../file"))
        XCTAssertTrue(resolver.containsPathTraversal("dir/../file"))
        XCTAssertTrue(resolver.containsPathTraversal("a/b/../c"))
        XCTAssertTrue(resolver.containsPathTraversal("dir/.."))
    }

    func testContainsPathTraversalNegative() {
        let resolver = makeResolver()
        XCTAssertFalse(resolver.containsPathTraversal("file"))
        XCTAssertFalse(resolver.containsPathTraversal("dir/file"))
        XCTAssertFalse(resolver.containsPathTraversal("./file"))
        XCTAssertFalse(resolver.containsPathTraversal("a/b/c"))
        XCTAssertFalse(resolver.containsPathTraversal("..."))  // Three dots is not traversal
        XCTAssertFalse(resolver.containsPathTraversal("a..b"))  // .. not as path component
    }

    func testFileExistsTrue() {
        mockFS.addFile(at: "/project/exists.md", content: "Content")
        let resolver = makeResolver()
        XCTAssertTrue(resolver.fileExists(at: "exists.md"))
    }

    func testFileExistsFalse() {
        let resolver = makeResolver()
        XCTAssertFalse(resolver.fileExists(at: "nonexistent.md"))
    }
}
