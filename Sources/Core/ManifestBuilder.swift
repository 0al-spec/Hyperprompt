/// Accumulator for manifest entries during compilation.
///
/// The ManifestBuilder collects metadata for all files processed during
/// a single compilation session. It maintains insertion order and allows
/// duplicate paths (e.g., if the same file is referenced multiple times
/// or different versions are processed).
///
/// Usage:
/// ```swift
/// let builder = ManifestBuilder()
///
/// // Add entries as files are loaded
/// builder.add(entry: ManifestEntry(
///     path: "docs/intro.md",
///     sha256: "abc123...",
///     size: 1024,
///     type: .markdown
/// ))
///
/// // Retrieve all entries for manifest generation
/// let allEntries = builder.getEntries()
/// ```
///
/// **Thread Safety:** Not thread-safe. Use from single thread only.
public class ManifestBuilder {
    /// Internal storage for manifest entries.
    ///
    /// Maintains insertion order. Duplicates are allowed (by design).
    private var entries: [ManifestEntry] = []

    /// Initialize an empty manifest builder.
    public init() {}

    /// Add a manifest entry to the collection.
    ///
    /// - Parameter entry: The manifest entry to add
    ///
    /// Entries are appended in order received. Duplicate paths are allowed.
    public func add(entry: ManifestEntry) {
        entries.append(entry)
    }

    /// Retrieve all accumulated manifest entries.
    ///
    /// - Returns: Array of manifest entries in insertion order
    ///
    /// The returned array is a copy; modifying it does not affect the builder.
    public func getEntries() -> [ManifestEntry] {
        return entries
    }

    /// Clear all accumulated entries.
    ///
    /// Resets the builder to empty state. Useful for reusing the same
    /// builder instance across multiple compilations (though typically
    /// a new instance is created per compilation).
    public func clear() {
        entries.removeAll()
    }

    /// Count of accumulated entries.
    ///
    /// - Returns: Number of entries currently in the builder
    public var count: Int {
        return entries.count
    }
}
