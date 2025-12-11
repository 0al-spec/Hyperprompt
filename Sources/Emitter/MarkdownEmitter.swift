// MarkdownEmitter.swift
// Emitter module - C2: Markdown Emitter
//
// Transforms a fully resolved AST into a well-formed Markdown document.
// Handles tree traversal, depth calculation, heading generation, content embedding,
// and integration with HeadingAdjuster for nested Markdown files.

import Foundation
import Parser

/// Configuration for Markdown emission behavior.
///
/// Controls optional behaviors like blank line insertion and filename handling.
public struct EmitterConfig {
    /// Whether to insert blank lines between sibling nodes.
    /// Default: true (standard Markdown formatting).
    public let insertBlankLines: Bool

    /// Whether to use filename (without path) as heading for file references.
    /// Default: false (use full path for traceability).
    public let useFilenameAsHeading: Bool

    /// Creates a new EmitterConfig with default values.
    public init(
        insertBlankLines: Bool = true,
        useFilenameAsHeading: Bool = false
    ) {
        self.insertBlankLines = insertBlankLines
        self.useFilenameAsHeading = useFilenameAsHeading
    }
}

/// Transforms a fully resolved AST into a Markdown document.
///
/// The emitter traverses the AST in depth-first order, calculating effective depths,
/// generating headings, and embedding content with proper heading level adjustments.
///
/// Example:
/// ```swift
/// let emitter = MarkdownEmitter(config: EmitterConfig())
/// let markdown = emitter.emit(resolvedAST)
/// // markdown contains the complete output document
/// ```
public struct MarkdownEmitter {

    // MARK: - Constants

    /// Maximum Markdown heading level (H1-H6).
    private static let maxHeadingLevel = 6

    // MARK: - Properties

    /// Configuration controlling emission behavior.
    private let config: EmitterConfig

    /// HeadingAdjuster instance for transforming embedded Markdown.
    private let headingAdjuster: HeadingAdjuster

    // MARK: - Initialization

    /// Creates a new MarkdownEmitter with the given configuration.
    ///
    /// - Parameter config: The emission configuration (default: standard config).
    public init(config: EmitterConfig = EmitterConfig()) {
        self.config = config
        self.headingAdjuster = HeadingAdjuster()
    }

    // MARK: - Public API

    /// Emits a Markdown document from a fully resolved AST.
    ///
    /// - Parameter root: The root node of the resolved AST.
    /// - Returns: A Markdown document as a String.
    ///            Output is normalized to LF line endings and ends with exactly one LF.
    ///
    /// - Note: The input AST must be fully resolved (all `resolution` fields populated).
    ///         This is the responsibility of the resolver (B4).
    public func emit(_ root: Node) -> String {
        var builder = StringBuilder()
        emitNode(root, parentDepth: -1, output: &builder)
        return builder.build()
    }

    // MARK: - Tree Traversal

    /// Recursively emits a node and its children.
    ///
    /// - Parameters:
    ///   - node: The node to emit.
    ///   - parentDepth: The effective depth of the parent node.
    ///   - output: The output builder to accumulate content.
    private func emitNode(_ node: Node, parentDepth: Int, output: inout StringBuilder) {
        // Calculate effective depth based on tree structure, not source indentation
        // Each level in the tree hierarchy adds 1 to the depth
        // Root nodes (parentDepth == -1) start at depth 0
        let effectiveDepth = parentDepth + 1

        // Validate depth (resolver should enforce this)
        assert(effectiveDepth <= 10, "Depth exceeds maximum of 10 (resolver should prevent this)")

        // Generate and emit heading
        let headingLevel = effectiveDepth + 1
        let headingText = node.literal
        let heading = generateHeading(text: headingText, level: headingLevel)
        output.appendLine(heading)

        // Embed content based on resolution kind
        embedContent(for: node, effectiveDepth: effectiveDepth, output: &output)

        // Emit children with blank line separators
        for (index, child) in node.children.enumerated() {
            // Insert blank line between siblings
            if index > 0 && config.insertBlankLines {
                output.appendLine("")
            }
            emitNode(child, parentDepth: effectiveDepth, output: &output)
        }
    }

    // MARK: - Heading Generation

    /// Generates a Markdown heading at the specified level.
    ///
    /// - Parameters:
    ///   - text: The heading text content.
    ///   - level: The heading level (1-6 for H1-H6, >6 for overflow).
    /// - Returns: A formatted heading string (without trailing newline).
    private func generateHeading(text: String, level: Int) -> String {
        if level > Self.maxHeadingLevel {
            // Overflow: convert to bold
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? "" : "**\(trimmed)**"
        } else {
            // Standard heading
            let hashes = String(repeating: "#", count: level)
            return text.isEmpty ? hashes : "\(hashes) \(text)"
        }
    }

    // MARK: - Content Embedding

    /// Embeds content based on the node's resolution kind.
    ///
    /// - Parameters:
    ///   - node: The node containing the resolution information.
    ///   - effectiveDepth: The effective depth of the node.
    ///   - output: The output builder to accumulate content.
    private func embedContent(for node: Node, effectiveDepth: Int, output: inout StringBuilder) {
        guard let resolution = node.resolution else {
            // Treat as inline text (no additional content)
            return
        }

        switch resolution {
        case .inlineText:
            // No additional content beyond the heading
            break

        case let .markdownFile(_, content):
            // Embed Markdown content with adjusted headings
            let offset = effectiveDepth + 1
            let adjusted = headingAdjuster.adjustHeadings(in: content, offset: offset)
            // Append adjusted content (HeadingAdjuster ensures it ends with LF)
            // Remove trailing newline to avoid double newlines
            let trimmed = adjusted.trimmingSuffix("\n")
            if !trimmed.isEmpty {
                output.append(trimmed)
                output.append("\n")
            }

        case let .hypercodeFile(_, _):
            // Child AST already merged into node.children by B4
            // No additional content to emit here
            break

        case let .forbidden(ext):
            // This should not occur if resolver is correct
            // Emit error comment for diagnostic purposes
            output.appendLine("<!-- Error: Forbidden extension .\(ext) -->")
        }
    }
}

// MARK: - StringBuilder

/// Efficient string accumulation using an array-based approach.
///
/// Avoids O(N²) concatenation by collecting fragments and joining once at the end.
struct StringBuilder {

    /// Internal buffer of string fragments.
    private var buffer: [String] = []

    /// Appends a string fragment to the buffer.
    ///
    /// - Parameter text: The text to append.
    mutating func append(_ text: String) {
        buffer.append(text)
    }

    /// Appends a string fragment followed by a newline.
    ///
    /// - Parameter text: The text to append.
    mutating func appendLine(_ text: String) {
        buffer.append(text)
        buffer.append("\n")
    }

    /// Builds the final output string with normalized formatting.
    ///
    /// - Returns: The complete output string, normalized to LF endings
    ///            and ending with exactly one LF (unless empty).
    func build() -> String {
        let result = buffer.joined()

        // Ensure single trailing LF
        var trimmed = result
        while trimmed.hasSuffix("\n") {
            trimmed.removeLast()
        }

        return trimmed.isEmpty ? "" : trimmed + "\n"
    }
}

// MARK: - String Extensions

extension String {
    /// Removes a suffix from the string if present.
    ///
    /// - Parameter suffix: The suffix to remove.
    /// - Returns: String with suffix removed, or original if suffix not present.
    fileprivate func trimmingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else {
            return self
        }
        return String(dropLast(suffix.count))
    }
}
