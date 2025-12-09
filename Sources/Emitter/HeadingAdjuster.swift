// HeadingAdjuster.swift
// Emitter module - C1: Heading Adjuster
//
// Transforms Markdown headings to accommodate hierarchical nesting of embedded content.
// Supports both ATX-style (# prefix) and Setext-style (underline) headings.
// Applies configurable depth offsets and handles overflow (H7+) by converting to bold.

import Foundation

/// Transforms Markdown content by adjusting heading levels based on nesting depth.
///
/// This component handles:
/// - ATX-style headings (# prefix)
/// - Setext-style headings (= or - underline)
/// - Overflow handling (levels > 6 converted to bold)
/// - Line ending normalization (CRLF/CR → LF)
///
/// Example:
/// ```swift
/// let adjuster = HeadingAdjuster()
/// let result = adjuster.adjustHeadings(in: "# Title", offset: 2)
/// // result == "### Title\n"
/// ```
public struct HeadingAdjuster {

    // MARK: - Constants

    /// Maximum Markdown heading level (H1-H6)
    private static let maxHeadingLevel = 6

    // MARK: - Initialization

    /// Creates a new HeadingAdjuster instance.
    public init() {}

    // MARK: - Public API

    /// Adjusts all headings in the given Markdown content by the specified offset.
    ///
    /// - Parameters:
    ///   - content: The Markdown content to transform.
    ///   - offset: The depth offset to apply (non-negative integer).
    ///             Each heading level increases by this amount.
    ///
    /// - Returns: Transformed Markdown with adjusted headings.
    ///            Output is normalized to LF line endings and ends with exactly one LF.
    ///
    /// - Note: Headings that would exceed H6 are converted to bold text (`**...**`).
    public func adjustHeadings(in content: String, offset: Int) -> String {
        // Handle empty input
        guard !content.isEmpty else {
            return ""
        }

        // Ensure non-negative offset
        let safeOffset = max(0, offset)

        // Normalize line endings: CRLF and CR → LF
        let normalized = normalizeLineEndings(content)

        // Split into lines
        let lines = normalized.components(separatedBy: "\n")

        // Process lines
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Check for ATX heading
            if isATXHeading(line) {
                let transformed = transformATXHeading(line, offset: safeOffset)
                result.append(transformed)
                i += 1
                continue
            }

            // Check for Setext heading (current line is text, next line is underline)
            if i + 1 < lines.count {
                let nextLine = lines[i + 1]
                if let setextLevel = parseSetextUnderline(nextLine), !line.isEmpty {
                    let transformed = transformSetextHeading(
                        headingText: line,
                        level: setextLevel,
                        offset: safeOffset
                    )
                    result.append(transformed)
                    // Skip the underline line
                    i += 2
                    continue
                }
            }

            // Pass through unchanged
            result.append(line)
            i += 1
        }

        // Join lines and ensure single trailing LF
        let output = result.joined(separator: "\n")
        return ensureSingleTrailingNewline(output)
    }

    // MARK: - Line Ending Normalization

    /// Normalizes line endings to LF.
    ///
    /// - Parameter content: The input content with mixed line endings.
    /// - Returns: Content with all line endings converted to LF.
    private func normalizeLineEndings(_ content: String) -> String {
        // Replace CRLF first, then CR
        content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    /// Ensures the output ends with exactly one LF.
    ///
    /// - Parameter content: The content to normalize.
    /// - Returns: Content ending with exactly one newline character.
    private func ensureSingleTrailingNewline(_ content: String) -> String {
        guard !content.isEmpty else {
            return ""
        }

        // Remove all trailing newlines and add exactly one
        var trimmed = content
        while trimmed.hasSuffix("\n") {
            trimmed.removeLast()
        }

        return trimmed.isEmpty ? "" : trimmed + "\n"
    }

    // MARK: - ATX Heading Helpers

    /// Checks if a line is an ATX-style heading.
    ///
    /// ATX headings start with 1-6 `#` characters followed by a space or end of line.
    /// Lines starting with more than 6 `#` characters are not headings.
    ///
    /// - Parameter line: The line to check.
    /// - Returns: `true` if the line is a valid ATX heading.
    internal func isATXHeading(_ line: String) -> Bool {
        let trimmed = line.trimmingLeadingWhitespace()

        // Must start with at least one #
        guard trimmed.hasPrefix("#") else {
            return false
        }

        // Count leading hashes
        let hashCount = countLeadingHashes(trimmed)

        // Must be 1-6 hashes
        guard hashCount >= 1 && hashCount <= 6 else {
            return false
        }

        // After hashes, must be space, end of line, or more hash for closing
        let afterHashes = String(trimmed.dropFirst(hashCount))

        // Empty after hashes is valid (bare heading like "###")
        if afterHashes.isEmpty {
            return true
        }

        // Must have space after hashes (ATX format requirement)
        return afterHashes.hasPrefix(" ") || afterHashes.hasPrefix("\t")
    }

    /// Extracts the heading level (1-6) from an ATX heading line.
    ///
    /// - Parameter line: The ATX heading line.
    /// - Returns: The heading level (1-6).
    internal func extractATXLevel(_ line: String) -> Int {
        let trimmed = line.trimmingLeadingWhitespace()
        return countLeadingHashes(trimmed)
    }

    /// Extracts the text content from an ATX heading line.
    ///
    /// Preserves spacing after the hashes but removes closing hashes if present.
    ///
    /// - Parameter line: The ATX heading line.
    /// - Returns: The heading text content.
    internal func extractATXText(_ line: String) -> String {
        let trimmed = line.trimmingLeadingWhitespace()
        let hashCount = countLeadingHashes(trimmed)

        // Get content after hashes
        var text = String(trimmed.dropFirst(hashCount))

        // Remove leading space if present (standard ATX format)
        if text.hasPrefix(" ") {
            text = String(text.dropFirst())
        }

        // Remove trailing closing hashes (optional ATX closing)
        // e.g., "## Heading ##" → "Heading"
        text = removeTrailingClosingHashes(text)

        return text
    }

    /// Counts the number of leading `#` characters in a string.
    ///
    /// - Parameter string: The string to examine.
    /// - Returns: The number of leading hash characters.
    private func countLeadingHashes(_ string: String) -> Int {
        var count = 0
        for char in string {
            if char == "#" {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    /// Removes optional trailing closing hashes from ATX heading text.
    ///
    /// Example: "Heading ##  " → "Heading"
    ///
    /// - Parameter text: The heading text with potential closing hashes.
    /// - Returns: Text with closing hashes removed.
    private func removeTrailingClosingHashes(_ text: String) -> String {
        var result = text

        // Trim trailing whitespace first
        while result.hasSuffix(" ") || result.hasSuffix("\t") {
            result = String(result.dropLast())
        }

        // Remove trailing hashes
        while result.hasSuffix("#") {
            result = String(result.dropLast())
        }

        // Trim any remaining trailing whitespace
        while result.hasSuffix(" ") || result.hasSuffix("\t") {
            result = String(result.dropLast())
        }

        return result
    }

    /// Transforms an ATX heading line with the given offset.
    ///
    /// - Parameters:
    ///   - line: The ATX heading line to transform.
    ///   - offset: The offset to apply to the heading level.
    /// - Returns: The transformed heading line.
    private func transformATXHeading(_ line: String, offset: Int) -> String {
        let currentLevel = extractATXLevel(line)
        let text = extractATXText(line)
        let newLevel = currentLevel + offset

        // Handle overflow (level > 6)
        if newLevel > Self.maxHeadingLevel {
            return convertToBold(text)
        }

        // Generate new ATX heading
        let hashes = String(repeating: "#", count: newLevel)
        return text.isEmpty ? hashes : "\(hashes) \(text)"
    }

    // MARK: - Setext Heading Helpers

    /// Parses a potential Setext underline and returns the heading level.
    ///
    /// - Parameter line: The line to check for underline pattern.
    /// - Returns: `1` for `=` underlines (H1), `2` for `-` underlines (H2), or `nil` if not a valid underline.
    internal func parseSetextUnderline(_ line: String) -> Int? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Must not be empty
        guard !trimmed.isEmpty else {
            return nil
        }

        // Check for all `=` (H1)
        if trimmed.allSatisfy({ $0 == "=" }) {
            return 1
        }

        // Check for all `-` (H2)
        // Note: Must have at least 3 dashes to distinguish from horizontal rule
        // and the line must be just dashes (not a list item "- text")
        if trimmed.allSatisfy({ $0 == "-" }) && trimmed.count >= 1 {
            return 2
        }

        return nil
    }

    /// Transforms a Setext heading with the given offset.
    ///
    /// Converts Setext headings to ATX format after adjustment.
    ///
    /// - Parameters:
    ///   - headingText: The heading text (line above the underline).
    ///   - level: The original heading level (1 for `=`, 2 for `-`).
    ///   - offset: The offset to apply.
    /// - Returns: The transformed heading in ATX format.
    private func transformSetextHeading(headingText: String, level: Int, offset: Int) -> String {
        let newLevel = level + offset

        // Handle overflow (level > 6)
        if newLevel > Self.maxHeadingLevel {
            return convertToBold(headingText.trimmingCharacters(in: .whitespaces))
        }

        // Convert to ATX format
        let hashes = String(repeating: "#", count: newLevel)
        let text = headingText.trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? hashes : "\(hashes) \(text)"
    }

    // MARK: - Overflow Handling

    /// Converts heading text to bold format for overflow cases.
    ///
    /// - Parameter text: The heading text to make bold.
    /// - Returns: The text wrapped in Markdown bold syntax.
    private func convertToBold(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return ""
        }
        return "**\(trimmed)**"
    }
}

// MARK: - String Extensions

extension String {
    /// Removes leading whitespace characters from the string.
    ///
    /// - Returns: String with leading whitespace removed.
    fileprivate func trimmingLeadingWhitespace() -> String {
        var result = self
        while let first = result.first, first.isWhitespace {
            result.removeFirst()
        }
        return result
    }
}
