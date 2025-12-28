#if Editor
/// GlobMatcher — Pattern Matching for .hyperpromptignore
///
/// Implements glob-style pattern matching similar to .gitignore syntax.
/// Supports common patterns used in ignore files.
///
/// ## Supported Patterns
///
/// - `*` - Matches any characters except path separator (/)
/// - `**` - Matches any characters including path separators
/// - `?` - Matches exactly one character except path separator
/// - `foo/` - Matches directory foo and all its contents
/// - `/foo` - Matches only at root level
/// - `*.ext` - Matches all files with extension .ext
/// - `dir/*.ext` - Matches files with extension .ext in directory dir
///
/// ## Usage
///
/// ```swift
/// let matcher = GlobMatcher()
/// matcher.matches(path: "main.log", pattern: "*.log")  // true
/// matcher.matches(path: "src/main.log", pattern: "*.log")  // false
/// matcher.matches(path: "src/main.log", pattern: "**/*.log")  // true
/// matcher.matches(path: "build/output.txt", pattern: "build/")  // true
/// matcher.matches(path: "tests/foo.test.md", pattern: "**/*.test.md")  // true
/// ```

import Foundation

/// Glob pattern matcher for file paths
struct GlobMatcher {
    /// Cache of compiled regular expressions
    /// Maps regex pattern strings to compiled NSRegularExpression objects
    private var regexCache: [String: NSRegularExpression] = [:]

    /// Checks if a path matches a glob pattern
    /// - Parameters:
    ///   - path: File path to check (relative to workspace root)
    ///   - pattern: Glob pattern (similar to .gitignore syntax)
    /// - Returns: true if path matches pattern
    mutating func matches(path: String, pattern: String) -> Bool {
        let normalizedPath = normalizePath(path)
        let normalizedPattern = pattern.trimmingCharacters(in: .whitespaces)

        // Empty pattern matches nothing
        guard !normalizedPattern.isEmpty else {
            return false
        }

        // Directory pattern (ends with /)
        if normalizedPattern.hasSuffix("/") {
            let dirPattern = String(normalizedPattern.dropLast())
            return normalizedPath.hasPrefix(dirPattern + "/") || normalizedPath == dirPattern
        }

        // Root-anchored pattern (starts with /)
        if normalizedPattern.hasPrefix("/") {
            let rootPattern = String(normalizedPattern.dropFirst())
            return matchesGlobPattern(path: normalizedPath, pattern: rootPattern)
        }

        if !normalizedPattern.contains("/") {
            // If the pattern uses **, allow matching across directories even without '/'.
            if normalizedPattern.contains("**") {
                return matchesGlobPattern(path: normalizedPath, pattern: normalizedPattern)
            }
            // Pattern without directory separator - match only root-level entries
            // (i.e., no directory components in the path).
            guard !normalizedPath.contains("/") else {
                return false
            }
            return matchesGlobPattern(path: normalizedPath, pattern: normalizedPattern)
        }

        // Full path pattern
        return matchesGlobPattern(path: normalizedPath, pattern: normalizedPattern)
    }

    // MARK: - Private Implementation

    /// Normalizes path by removing leading/trailing slashes
    private func normalizePath(_ path: String) -> String {
        var normalized = path
        if normalized.hasPrefix("/") {
            normalized = String(normalized.dropFirst())
        }
        if normalized.hasSuffix("/") {
            normalized = String(normalized.dropLast())
        }
        return normalized
    }

    /// Matches path against glob pattern using regex conversion
    /// Uses cache to avoid recompiling the same regex pattern
    private mutating func matchesGlobPattern(path: String, pattern: String) -> Bool {
        let regexPattern = globToRegex(pattern)

        // Check cache first
        let regexObj: NSRegularExpression
        if let cached = regexCache[regexPattern] {
            regexObj = cached
        } else {
            guard let compiled = try? NSRegularExpression(pattern: regexPattern, options: []) else {
                // Invalid regex - return false for safety
                // Note: This differs from previous exact match fallback (see EE-FIX-5)
                return false
            }
            regexCache[regexPattern] = compiled
            regexObj = compiled
        }

        let range = NSRange(path.startIndex..., in: path)
        return regexObj.firstMatch(in: path, options: [], range: range) != nil
    }

    /// Converts glob pattern to regular expression
    ///
    /// Transformation rules:
    /// - `**` → `.*` (matches any characters including /)
    /// - `*` → `[^/]*` (matches any characters except /)
    /// - `?` → `[^/]` (matches single character except /)
    /// - `.` → `\.` (escape dots)
    /// - Other special regex chars → escaped
    private func globToRegex(_ pattern: String) -> String {
        var regex = "^"
        var i = pattern.startIndex

        while i < pattern.endIndex {
            let char = pattern[i]

            switch char {
            case "*":
                // Check for **
                let nextIndex = pattern.index(after: i)
                if nextIndex < pattern.endIndex && pattern[nextIndex] == "*" {
                    let afterDoubleStar = pattern.index(after: nextIndex)
                    if afterDoubleStar < pattern.endIndex, pattern[afterDoubleStar] == "/" {
                        // **/ matches zero or more path components (including "no directory")
                        regex += "(?:.*/)?"
                        i = pattern.index(after: afterDoubleStar)
                        continue
                    } else {
                        // ** matches any characters including /
                        regex += ".*"
                        i = afterDoubleStar
                        continue
                    }
                } else {
                    // * matches any characters except /
                    regex += "[^/]*"
                }

            case "?":
                // ? matches single character except /
                regex += "[^/]"

            case ".":
                // Escape dot
                regex += "\\."

            case "(", ")", "[", "]", "{", "}", "+", "^", "$", "|", "\\":
                // Escape other regex special characters
                regex += "\\\(char)"

            default:
                regex += String(char)
            }

            i = pattern.index(after: i)
        }

        regex += "$"
        return regex
    }
}

// MARK: - Array Extension for Convenience

extension Array where Element == String {
    /// Checks if any pattern in array matches the given path
    /// - Parameters:
    ///   - path: File path to check
    ///   - matcher: Glob matcher to use (pass by inout to benefit from regex caching)
    /// - Returns: true if any pattern matches
    func matchesAny(path: String, using matcher: inout GlobMatcher) -> Bool {
        for pattern in self {
            if matcher.matches(path: path, pattern: pattern) {
                return true
            }
        }
        return false
    }
}
#endif
