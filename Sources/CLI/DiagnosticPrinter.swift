import Foundation
import Core

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Formats compiler errors with source context and location information.
///
/// DiagnosticPrinter produces error messages in the format:
/// ```
/// <file>:<line>: error: <message>
/// <context_line>
/// <caret_indicator>
/// ```
///
/// Features:
/// - Source context extraction with line display
/// - Caret indicators (^ or ^^^) showing problem location
/// - ANSI color support for terminals (auto-detected)
/// - Plain text mode for non-terminal output (logs, CI)
/// - Multi-error aggregation and grouping
///
/// Example output:
/// ```
/// src/main.hc:5: error: Tab character in indentation
///     "content	here"
///             ^
/// ```
public struct DiagnosticPrinter {
    // MARK: - Configuration

    /// Enable ANSI colors (auto-detected or manually overridden)
    public let colorize: Bool

    /// Number of context lines before/after (0 for single line only)
    public let contextLines: Int

    /// Maximum line length before truncation
    public let maxLineLength: Int

    /// File system for reading source files
    private let fileSystem: FileSystem

    // MARK: - Initialization

    /// Initialize diagnostic printer with configuration.
    ///
    /// - Parameters:
    ///   - colorize: Enable colors (nil = auto-detect terminal). Default: auto-detect.
    ///   - contextLines: Lines before/after to show (0 = single line only). Default: 0.
    ///   - maxLineLength: Truncate lines longer than this. Default: 100.
    ///   - fileSystem: File system for reading source files. Default: LocalFileSystem.
    public init(
        colorize: Bool? = nil,
        contextLines: Int = 0,
        maxLineLength: Int = 100,
        fileSystem: FileSystem = LocalFileSystem()
    ) {
        self.colorize = colorize ?? Self.isTerminal()
        self.contextLines = contextLines
        self.maxLineLength = maxLineLength
        self.fileSystem = fileSystem
    }

    // MARK: - Public Methods

    /// Format a single compiler error with source context.
    ///
    /// - Parameter error: The compiler error to format
    /// - Returns: Formatted error message with location and context
    public func format(error: CompilerError) -> String {
        var output = ""

        // Format the error header: <file>:<line>: error: <message>
        if let location = error.location {
            let file = colorize ? AnsiColor.cyan.wrap(location.filePath) : location.filePath
            let line = colorize ? AnsiColor.yellow.wrap("\(location.line)") : "\(location.line)"
            let errorLabel = colorize ? AnsiColor.red.wrap("error:", bold: true) : "error:"

            output += "\(file):\(line): \(errorLabel) \(error.message)\n"

            // Add context line and caret if we can extract it
            if let context = extractContext(location: location) {
                output += context
            }
        } else {
            // No location - just show error message
            let errorLabel = colorize ? AnsiColor.red.wrap("error:", bold: true) : "error:"
            output += "\(errorLabel) \(error.message)\n"
        }

        return output
    }

    /// Format multiple compiler errors with aggregation and grouping.
    ///
    /// Errors are grouped by file and sorted by line number for readability.
    ///
    /// - Parameter errors: Array of compiler errors to format
    /// - Returns: Formatted error report with all errors and count summary
    public func formatMultiple(errors: [CompilerError]) -> String {
        guard !errors.isEmpty else { return "" }

        // Group errors by file path
        var errorsByFile: [String: [CompilerError]] = [:]
        var noLocationErrors: [CompilerError] = []

        for error in errors {
            if let location = error.location {
                errorsByFile[location.filePath, default: []].append(error)
            } else {
                noLocationErrors.append(error)
            }
        }

        // Sort errors within each file by line number
        for (file, fileErrors) in errorsByFile {
            errorsByFile[file] = fileErrors.sorted { ($0.location?.line ?? 0) < ($1.location?.line ?? 0) }
        }

        // Build output
        var output = ""

        // Errors with locations (sorted by file name)
        for file in errorsByFile.keys.sorted() {
            for error in errorsByFile[file]! {
                output += format(error: error)
                output += "\n"
            }
        }

        // Errors without locations
        for error in noLocationErrors {
            output += format(error: error)
            output += "\n"
        }

        // Add summary
        let count = errors.count
        let plural = count == 1 ? "error" : "errors"
        output += "Total: \(count) \(plural)\n"

        return output
    }

    /// Write a single error to a text output stream.
    ///
    /// - Parameters:
    ///   - error: The compiler error to format and write
    ///   - stream: Output stream to write to
    public func write<Stream: TextOutputStream>(error: CompilerError, to stream: inout Stream) {
        stream.write(format(error: error))
    }

    /// Write multiple errors to a text output stream.
    ///
    /// - Parameters:
    ///   - errors: Array of compiler errors to format and write
    ///   - stream: Output stream to write to
    public func write<Stream: TextOutputStream>(errors: [CompilerError], to stream: inout Stream) {
        stream.write(formatMultiple(errors: errors))
    }

    // MARK: - Private Methods

    /// Extract source context and generate caret indicator for an error location.
    ///
    /// - Parameter location: Source location of the error
    /// - Returns: Formatted context string with line and caret, or nil if file unavailable
    private func extractContext(location: SourceLocation) -> String? {
        guard fileSystem.fileExists(at: location.filePath) else {
            return nil
        }

        // Read file and extract line
        guard let fileContent = try? fileSystem.readFile(at: location.filePath) else {
            return nil
        }

        let lines = fileContent.components(separatedBy: "\n")
        let lineIndex = location.line - 1  // Convert to 0-based index

        guard lineIndex >= 0 && lineIndex < lines.count else {
            return nil
        }

        var contextLine = lines[lineIndex]

        // Truncate very long lines
        var wasTruncated = false
        if contextLine.count > maxLineLength {
            contextLine = String(contextLine.prefix(maxLineLength)) + "..."
            wasTruncated = true
        }

        // Trim trailing whitespace
        contextLine = contextLine.trimmingCharacters(in: .whitespacesAndNewlines)

        // Generate caret indicator
        // For now, we'll position it at the start of the quoted content or at column 0
        let caretPosition = findCaretPosition(in: lines[lineIndex])
        let caretLine = generateCaretLine(position: caretPosition, length: 1, wasTruncated: wasTruncated)

        let caret = colorize ? AnsiColor.red.wrap(caretLine, bold: true) : caretLine

        return "\(contextLine)\n\(caret)\n"
    }

    /// Find the position where the caret should be placed.
    ///
    /// Heuristic: Position at first non-whitespace character, or at the opening quote if present.
    ///
    /// - Parameter line: The source line to analyze
    /// - Returns: Column position (0-based) for the caret
    private func findCaretPosition(in line: String) -> Int {
        // Look for opening quote
        if let quoteIndex = line.firstIndex(of: "\"") {
            return line.distance(from: line.startIndex, to: quoteIndex)
        }

        // Look for first non-whitespace
        if let firstChar = line.firstIndex(where: { !$0.isWhitespace }) {
            return line.distance(from: line.startIndex, to: firstChar)
        }

        // Default to column 0
        return 0
    }

    /// Generate a caret indicator line with proper spacing.
    ///
    /// - Parameters:
    ///   - position: Column position (0-based) where caret should appear
    ///   - length: Number of characters to underline (1 for ^, 3+ for ^^^)
    ///   - wasTruncated: Whether the line was truncated (affects caret rendering)
    /// - Returns: String with spaces and caret characters
    private func generateCaretLine(position: Int, length: Int, wasTruncated: Bool) -> String {
        let spaces = String(repeating: " ", count: position)

        let caretChar: String
        if length == 1 {
            caretChar = "^"
        } else if length == 2 {
            caretChar = "^^"
        } else {
            caretChar = String(repeating: "^", count: min(length, 10))
        }

        return spaces + caretChar
    }

    /// Detect if output is connected to a terminal.
    ///
    /// Uses isatty() to check if stdout is a TTY (terminal device).
    ///
    /// - Returns: `true` if connected to terminal, `false` for pipes/files
    private static func isTerminal() -> Bool {
        #if os(Windows)
        // Windows terminal detection would go here
        return false
        #else
        return isatty(STDOUT_FILENO) != 0
        #endif
    }
}

// MARK: - ANSI Color Support

/// ANSI color codes for terminal output.
private enum AnsiColor {
    case none
    case red
    case cyan
    case yellow

    /// Get ANSI escape code for this color.
    ///
    /// - Parameter bold: Apply bold weight
    /// - Returns: ANSI escape sequence
    func code(bold: Bool = false) -> String {
        switch self {
        case .none:
            return ""
        case .red:
            return bold ? "\u{001B}[1;31m" : "\u{001B}[31m"
        case .cyan:
            return bold ? "\u{001B}[1;36m" : "\u{001B}[36m"
        case .yellow:
            return bold ? "\u{001B}[1;33m" : "\u{001B}[33m"
        }
    }

    /// Reset code to clear all formatting.
    static let reset = "\u{001B}[0m"

    /// Wrap text in this color.
    ///
    /// - Parameters:
    ///   - text: Text to colorize
    ///   - bold: Apply bold weight
    /// - Returns: Text wrapped in ANSI codes
    func wrap(_ text: String, bold: Bool = false) -> String {
        guard self != .none else { return text }
        return code(bold: bold) + text + AnsiColor.reset
    }
}
