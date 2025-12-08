import XCTest

@testable import Core

/// Comprehensive tests for FileLoader functionality.
///
/// Covers:
/// - UTF-8 file reading
/// - Line ending normalization
/// - Content caching
/// - SHA256 hash computation
/// - File type detection
/// - ManifestEntry creation
final class FileLoaderTests: XCTestCase {

    var fileSystem: MockFileSystem!
    var loader: FileLoader!

    override func setUp() {
        super.setUp()
        fileSystem = MockFileSystem()
        loader = FileLoader(fileSystem: fileSystem)
    }

    override func tearDown() {
        fileSystem = nil
        loader = nil
        super.tearDown()
    }

    // MARK: - UTF-8 Encoding Tests (5.1.1)

    func testLoadValidUTF8File() throws {
        // Given: Valid UTF-8 content
        fileSystem.addFile(at: "/test/file.md", content: "Hello, World!")

        // When: Load the file
        let result = try loader.load(path: "/test/file.md")

        // Then: Content is correctly loaded
        XCTAssertEqual(result.content, "Hello, World!")
    }

    func testLoadFileWithEmoji() throws {
        // Given: UTF-8 content with emoji
        fileSystem.addFile(at: "/test/emoji.hc", content: "Hello 👋 World 🌍")

        // When: Load the file
        let result = try loader.load(path: "/test/emoji.hc")

        // Then: Emoji is preserved correctly
        XCTAssertEqual(result.content, "Hello 👋 World 🌍")
    }

    func testLoadEmptyFile() throws {
        // Given: Empty file
        fileSystem.addFile(at: "/test/empty.md", content: "")

        // When: Load the file
        let result = try loader.load(path: "/test/empty.md")

        // Then: Empty content is handled correctly
        XCTAssertEqual(result.content, "")
        XCTAssertEqual(result.metadata.size, 0)
    }

    func testLoadFileNotFound() {
        // Given: No file exists
        // (fileSystem is empty)

        // When/Then: Loading throws IO error
        XCTAssertThrowsError(try loader.load(path: "/test/missing.md")) { error in
            guard let compilerError = error as? CompilerError else {
                XCTFail("Expected CompilerError")
                return
            }
            XCTAssertEqual(compilerError.category, .io)
        }
    }

    // MARK: - Line Ending Normalization Tests (5.1.2)

    func testNormalizeLineEndingsLF() {
        // Given: Content with LF line endings
        let content = "Line 1\nLine 2\nLine 3"

        // When: Normalize
        let normalized = loader.normalizeLineEndings(content)

        // Then: LF is preserved
        XCTAssertEqual(normalized, "Line 1\nLine 2\nLine 3")
    }

    func testNormalizeLineEndingsCRLF() {
        // Given: Content with CRLF line endings
        let content = "Line 1\r\nLine 2\r\nLine 3"

        // When: Normalize
        let normalized = loader.normalizeLineEndings(content)

        // Then: CRLF converted to LF
        XCTAssertEqual(normalized, "Line 1\nLine 2\nLine 3")
        XCTAssertFalse(normalized.contains(LineBreak.carriageReturn))
    }

    func testNormalizeLineEndingsCR() {
        // Given: Content with CR line endings
        let content = "Line 1\rLine 2\rLine 3"

        // When: Normalize
        let normalized = loader.normalizeLineEndings(content)

        // Then: CR converted to LF
        XCTAssertEqual(normalized, "Line 1\nLine 2\nLine 3")
        XCTAssertFalse(normalized.contains(LineBreak.carriageReturn))
    }

    func testNormalizeLineEndingsMixed() {
        // Given: Content with mixed line endings
        let content = "Line 1\nLine 2\r\nLine 3\rLine 4"

        // When: Normalize
        let normalized = loader.normalizeLineEndings(content)

        // Then: All converted to LF
        XCTAssertEqual(normalized, "Line 1\nLine 2\nLine 3\nLine 4")
        XCTAssertFalse(normalized.contains(LineBreak.carriageReturn))
    }

    func testNormalizeLineEndingsTrailingNewline() {
        // Given: Content with trailing newline
        let content = "Line 1\nLine 2\n"

        // When: Normalize
        let normalized = loader.normalizeLineEndings(content)

        // Then: Trailing newline preserved
        XCTAssertEqual(normalized, "Line 1\nLine 2\n")
    }

    // MARK: - Caching Tests (5.1.3)

    func testCacheHit() throws {
        // Given: File loaded once
        fileSystem.addFile(at: "/test/cached.md", content: "Original content")
        _ = try loader.load(path: "/test/cached.md")

        // When: File content changes on disk (but cache exists)
        fileSystem.addFile(at: "/test/cached.md", content: "Modified content")

        // Then: Second load returns cached content
        let result = try loader.load(path: "/test/cached.md")
        XCTAssertEqual(result.content, "Original content")
    }

    func testCacheSeparateFiles() throws {
        // Given: Two different files
        fileSystem.addFile(at: "/test/file1.md", content: "Content 1")
        fileSystem.addFile(at: "/test/file2.hc", content: "Content 2")

        // When: Load both files
        let result1 = try loader.load(path: "/test/file1.md")
        let result2 = try loader.load(path: "/test/file2.hc")

        // Then: Separate cache entries
        XCTAssertEqual(result1.content, "Content 1")
        XCTAssertEqual(result2.content, "Content 2")
        XCTAssertEqual(loader.cacheCount, 2)
    }

    func testClearCache() throws {
        // Given: File loaded and cached
        fileSystem.addFile(at: "/test/cached.md", content: "Original")
        _ = try loader.load(path: "/test/cached.md")
        XCTAssertEqual(loader.cacheCount, 1)

        // When: Clear cache
        loader.clearCache()

        // Then: Cache is empty
        XCTAssertEqual(loader.cacheCount, 0)

        // And: File content changes
        fileSystem.addFile(at: "/test/cached.md", content: "Modified")

        // Then: Load returns new content
        let result = try loader.load(path: "/test/cached.md")
        XCTAssertEqual(result.content, "Modified")
    }

    // MARK: - SHA256 Hash Tests (5.1.4)

    func testComputeHashEmptyString() {
        // Given: Empty string
        let content = ""

        // When: Compute hash
        let hash = loader.computeHash(content)

        // Then: Hash matches known SHA256 of empty string
        XCTAssertEqual(hash, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }

    func testComputeHashSingleLine() {
        // Given: Single line content
        let content = "Hello, World!"

        // When: Compute hash
        let hash = loader.computeHash(content)

        // Then: Hash is deterministic (64 hex chars)
        XCTAssertEqual(hash.count, 64)
        XCTAssertTrue(hash.allSatisfy { $0.isHexDigit })

        // Verify known hash (echo -n "Hello, World!" | sha256sum)
        XCTAssertEqual(hash, "dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f")
    }

    func testComputeHashMultiline() {
        // Given: Multiline content
        let content = "Line 1\nLine 2\nLine 3"

        // When: Compute hash
        let hash = loader.computeHash(content)

        // Then: Hash is deterministic
        XCTAssertEqual(hash.count, 64)
        XCTAssertTrue(hash.allSatisfy { $0.isHexDigit })
    }

    func testComputeHashDeterminism() {
        // Given: Same content
        let content = "Test content"

        // When: Compute hash twice
        let hash1 = loader.computeHash(content)
        let hash2 = loader.computeHash(content)

        // Then: Hashes are identical
        XCTAssertEqual(hash1, hash2)
    }

    func testComputeHashDifferentContent() {
        // Given: Different content
        let content1 = "Content 1"
        let content2 = "Content 2"

        // When: Compute hashes
        let hash1 = loader.computeHash(content1)
        let hash2 = loader.computeHash(content2)

        // Then: Hashes are different
        XCTAssertNotEqual(hash1, hash2)
    }

    func testHashComputedOnNormalizedContent() throws {
        // Given: File with CRLF line endings
        fileSystem.addFile(at: "/test/crlf.md", content: "Line 1\r\nLine 2\r\n")

        // When: Load file
        let result = try loader.load(path: "/test/crlf.md")

        // Then: Hash is computed on normalized content (LF)
        let expectedHash = loader.computeHash("Line 1\nLine 2\n")
        XCTAssertEqual(result.hash, expectedHash)
    }

    // MARK: - File Type Detection Tests (5.1.5)

    func testDetectFileTypeMarkdown() throws {
        // Given: .md file
        let fileType = try loader.detectFileType("/test/document.md")

        // Then: Detected as markdown
        XCTAssertEqual(fileType, .markdown)
    }

    func testDetectFileTypeHypercode() throws {
        // Given: .hc file
        let fileType = try loader.detectFileType("/test/program.hc")

        // Then: Detected as hypercode
        XCTAssertEqual(fileType, .hypercode)
    }

    func testDetectFileTypeMarkdownUppercase() throws {
        // Given: .MD file (uppercase)
        let fileType = try loader.detectFileType("/test/README.MD")

        // Then: Detected as markdown (case-insensitive)
        XCTAssertEqual(fileType, .markdown)
    }

    func testDetectFileTypeInvalidExtension() {
        // Given: Invalid extension
        let invalidPaths = [
            "/test/file.txt",
            "/test/file.html",
            "/test/file",
            "/test/file.mdx",
            "/test/file.hcc",
        ]

        // When/Then: All throw IO error
        for path in invalidPaths {
            XCTAssertThrowsError(try loader.detectFileType(path)) { error in
                guard let compilerError = error as? CompilerError else {
                    XCTFail("Expected CompilerError for path: \(path)")
                    return
                }
                XCTAssertEqual(compilerError.category, .io)
                XCTAssertTrue(compilerError.message.contains("Invalid file extension"))
            }
        }
    }

    // MARK: - ManifestEntry Tests (Integration)

    func testManifestEntryCreation() throws {
        // Given: Valid markdown file
        let content = "# Hello\n\nWorld"
        fileSystem.addFile(at: "/docs/intro.md", content: content)

        // When: Load file
        let result = try loader.load(path: "/docs/intro.md")

        // Then: ManifestEntry created correctly
        XCTAssertEqual(result.metadata.path, "/docs/intro.md")
        XCTAssertEqual(result.metadata.size, content.utf8.count)
        XCTAssertEqual(result.metadata.type, .markdown)
        XCTAssertEqual(result.metadata.sha256.count, 64)
    }

    func testManifestEntryHypercodeFile() throws {
        // Given: Valid hypercode file
        let content = "\"Root\"\n    \"Child\""
        fileSystem.addFile(at: "/src/app.hc", content: content)

        // When: Load file
        let result = try loader.load(path: "/src/app.hc")

        // Then: Type is hypercode
        XCTAssertEqual(result.metadata.type, .hypercode)
        XCTAssertEqual(result.metadata.path, "/src/app.hc")
    }

    func testManifestEntrySizeBeforeNormalization() throws {
        // Given: File with CRLF (2 bytes per line ending)
        let content = "Line 1\r\nLine 2\r\n"
        fileSystem.addFile(at: "/test/crlf.md", content: content)

        // When: Load file
        let result = try loader.load(path: "/test/crlf.md")

        // Then: Size reflects original content (16 bytes: 6+2+6+2)
        XCTAssertEqual(result.metadata.size, 16)
        // But content is normalized to LF (14 bytes: 6+1+6+1)
        XCTAssertEqual(result.content.utf8.count, 14)
    }

    // MARK: - Large File Tests

    func testLoadLargeFile() throws {
        // Given: Large file (>1MB of content)
        let largeContent = String(repeating: "A", count: 1_500_000)
        fileSystem.addFile(at: "/test/large.md", content: largeContent)

        // When: Load file
        let result = try loader.load(path: "/test/large.md")

        // Then: Content loaded correctly
        XCTAssertEqual(result.content.count, 1_500_000)
        XCTAssertEqual(result.metadata.size, 1_500_000)
    }

    // MARK: - Edge Cases

    func testLoadFileWithTrailingWhitespace() throws {
        // Given: File with trailing whitespace
        let content = "Line 1  \nLine 2\t\n"
        fileSystem.addFile(at: "/test/whitespace.md", content: content)

        // When: Load file
        let result = try loader.load(path: "/test/whitespace.md")

        // Then: Whitespace preserved (not trimmed)
        XCTAssertEqual(result.content, content)
    }

    func testLoadFileWithUnicodeContent() throws {
        // Given: File with various Unicode characters
        let content = "Hello 世界 🌍 Здравствуй مرحبا"
        fileSystem.addFile(at: "/test/unicode.md", content: content)

        // When: Load file
        let result = try loader.load(path: "/test/unicode.md")

        // Then: Unicode preserved correctly
        XCTAssertEqual(result.content, content)
        XCTAssertEqual(result.metadata.size, content.utf8.count)
    }
}

// MARK: - Character Extension for Hex Check

extension Character {
    var isHexDigit: Bool {
        return self.isASCII
            && (self.isNumber || ("a"..."f").contains(self) || ("A"..."F").contains(self))
    }
}
