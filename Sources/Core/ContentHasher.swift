import Foundation
import Crypto

/// Utility for computing content hashes.
public enum ContentHasher {
    /// Compute SHA256 hash of content and return lowercase hex string.
    public static func sha256Hex(_ content: String) -> String {
        let data = Data(content.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
