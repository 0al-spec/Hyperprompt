import Foundation

/// Canonical whitespace definitions shared across modules.
public enum Whitespace {
    public static let space: Character = " "
    public static let tab: Character = "\t"

    public static let spaceString = String(space)
    public static let tabString = String(tab)
}

/// Lexical comment delimiters.
public enum CommentDelimiter {
    public static let hash: Character = "#"
    public static let hashString = String(hash)
}

/// Shared path syntactic tokens.
public enum PathSegment {
    public static let traversal = ".."
    public static let forwardSlash: Character = "/"
    public static let backslash: Character = "\\"

    public static let separators = CharacterSet(
        charactersIn: String([forwardSlash, backslash])
    )
}

/// Indentation configuration shared across modules.
public enum Indentation {
    public static let spacesPerLevel = 4
}
