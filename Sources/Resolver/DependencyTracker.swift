import Core

/// Dependency tracker for detecting circular dependencies in Hypercode compilation.
///
/// The DependencyTracker uses a **visitation stack** pattern to detect cycles:
/// - Stack contains canonical absolute paths of files currently being processed
/// - Before resolving a `.hc` reference, check if target is already in stack
/// - On detection, extract full cycle path from stack for error message
///
/// ## Algorithm
///
/// ```swift
/// // Before resolving .hc file:
/// if tracker.isInCycle(path: resolvedPath, stack: visitationStack) {
///     let cyclePath = tracker.getCyclePath(stack: visitationStack, offendingPath: resolvedPath)
///     return .error(CircularDependencyError(cyclePath: cyclePath, location: location))
/// }
///
/// // Add to stack before recursive resolution
/// stack.append(resolvedPath)
/// let result = resolve(childAST, root, strict, stack, fileCache)
/// stack.removeLast()
/// ```
///
/// ## Invariants
///
/// - **Stack contains only canonicalized absolute paths**
/// - **All paths must be normalized before checking**
/// - **Stack is maintained by the resolver, not by this tracker**
///
/// ## Usage
///
/// ```swift
/// let tracker = DependencyTracker()
/// var visitationStack: [String] = []
///
/// // When resolving a file
/// visitationStack.append(canonicalPath)
/// defer { visitationStack.removeLast() }
///
/// // Before recursive resolution
/// if tracker.isInCycle(path: nextPath, stack: visitationStack) {
///     // Handle cycle error
/// }
/// ```
public struct DependencyTracker {
    /// Initialize a new dependency tracker.
    public init() {}

    // MARK: - Cycle Detection

    /// Check if a path is already in the current visitation stack.
    ///
    /// This method performs O(n) linear search through the stack where n is the
    /// depth of the current file tree (typically ≤10).
    ///
    /// - Parameters:
    ///   - path: The canonical absolute path to check
    ///   - stack: The current visitation stack
    /// - Returns: `true` if path is in stack (cycle detected), `false` otherwise
    ///
    /// ## Example
    ///
    /// ```swift
    /// let stack = ["/root/main.hc", "/root/a.hc", "/root/b.hc"]
    /// let tracker = DependencyTracker()
    ///
    /// tracker.isInCycle(path: "/root/a.hc", stack: stack)  // → true (cycle!)
    /// tracker.isInCycle(path: "/root/c.hc", stack: stack)  // → false (no cycle)
    /// ```
    public func isInCycle(path: String, stack: [String]) -> Bool {
        return stack.contains(path)
    }

    // MARK: - Cycle Path Extraction

    /// Extract the full cycle path from the visitation stack.
    ///
    /// When a cycle is detected, this method extracts the portion of the stack
    /// that forms the cycle, from the first occurrence of the offending path
    /// to the end of the stack, then appends the offending path to complete
    /// the cycle representation.
    ///
    /// - Parameters:
    ///   - stack: The current visitation stack
    ///   - offendingPath: The path that caused the cycle
    /// - Returns: Array of paths forming the complete cycle
    ///
    /// ## Example
    ///
    /// ```swift
    /// let stack = ["/root/main.hc", "/root/a.hc", "/root/b.hc", "/root/c.hc"]
    /// let offendingPath = "/root/a.hc"
    ///
    /// let cyclePath = tracker.getCyclePath(stack: stack, offendingPath: offendingPath)
    /// // Result: ["/root/a.hc", "/root/b.hc", "/root/c.hc", "/root/a.hc"]
    /// // Represents: a.hc → b.hc → c.hc → a.hc
    /// ```
    ///
    /// ## Edge Cases
    ///
    /// - If offending path is not in stack, returns stack + offending path
    /// - If offending path is at stack[0], returns stack[0...end] + offending path
    /// - Empty stack returns [offendingPath, offendingPath] (direct self-reference)
    public func getCyclePath(stack: [String], offendingPath: String) -> [String] {
        // Find the first occurrence of the offending path in the stack
        guard let cycleStartIndex = stack.firstIndex(of: offendingPath) else {
            // Offending path not in stack - shouldn't happen, but handle defensively
            // Return entire stack plus offending path
            return stack + [offendingPath]
        }

        // Extract the cycle portion from stack[cycleStartIndex...end]
        let cycleStack = Array(stack[cycleStartIndex...])

        // Append offending path to complete the cycle representation
        return cycleStack + [offendingPath]
    }
}
