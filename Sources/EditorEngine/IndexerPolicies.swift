#if Editor
// MARK: - Indexer Option Policies

public enum HiddenEntryPolicy: String, Codable, Equatable, Sendable {
    case include
    case exclude
}

public enum SymlinkPolicy: String, Codable, Equatable, Sendable {
    case follow
    case skip
}
#endif
