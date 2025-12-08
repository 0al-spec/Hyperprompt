import Foundation

/// Canonical definitions for supported line break characters.
public enum LineBreak {
    /// Unix line feed character.
    public static let lineFeed: Character = "\n"

    /// Classic Mac carriage return character.
    public static let carriageReturn: Character = "\r"

    /// Convenience string values for APIs that expect `String`.
    public static let lineFeedString = String(lineFeed)
    public static let carriageReturnString = String(carriageReturn)

    /// Character set containing all supported line break characters.
    public static let characterSet = CharacterSet(
        charactersIn: String([lineFeed, carriageReturn])
    )
}
