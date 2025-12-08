import Foundation

/// Canonical definitions for string literal delimiters in Hypercode.
public enum QuoteDelimiter {
    /// Primary double-quote character used for literals.
    public static let doubleQuote: Character = "\""

    /// String representation for APIs that operate on `String`.
    public static let doubleQuoteString = String(doubleQuote)
}
