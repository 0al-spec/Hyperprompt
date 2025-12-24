import Foundation
import Parser

/// In-memory cache for parsed Hypercode programs with dependency tracking.
public final class ParsedFileCache {
    public struct Entry {
        public let checksum: String
        public let program: Program
        public let dependencies: Set<String>
    }

    private var entries: [String: Entry] = [:]
    private var accessOrder: [String] = []
    private var dependentsByPath: [String: Set<String>] = [:]
    private let capacity: Int

    public init(capacity: Int = 1000) {
        self.capacity = max(1, capacity)
    }

    public var entryCount: Int {
        entries.count
    }

    public func dependencies(for path: String) -> Set<String> {
        entries[path]?.dependencies ?? []
    }

    public func dependents(for path: String) -> Set<String> {
        dependentsByPath[path] ?? []
    }

    public func dependencyGraph() -> [String: Set<String>] {
        var graph: [String: Set<String>] = [:]
        for (path, entry) in entries {
            graph[path] = entry.dependencies
        }
        return graph
    }

    public func dirtyClosure(for paths: Set<String>) -> Set<String> {
        var queue = Array(paths)
        var dirty: Set<String> = []

        while let current = queue.first {
            queue.removeFirst()

            guard !dirty.contains(current) else {
                continue
            }

            dirty.insert(current)

            if let dependents = dependentsByPath[current] {
                queue.append(contentsOf: dependents)
            }
        }

        return dirty
    }

    public func cachedProgram(for path: String, checksum: String) -> Program? {
        guard let entry = entries[path] else {
            return nil
        }

        guard entry.checksum == checksum else {
            invalidate(path: path)
            return nil
        }

        markAccessed(path)
        return entry.program
    }

    public func store(
        path: String,
        checksum: String,
        program: Program,
        dependencies: Set<String>
    ) {
        if let existing = entries[path] {
            removeDependents(for: path, dependencies: existing.dependencies)
        }

        entries[path] = Entry(
            checksum: checksum,
            program: program,
            dependencies: dependencies
        )

        for dependency in dependencies {
            var dependents = dependentsByPath[dependency, default: []]
            dependents.insert(path)
            dependentsByPath[dependency] = dependents
        }

        markAccessed(path)
        evictIfNeeded()
    }

    public func invalidate(path: String) {
        invalidate(paths: [path])
    }

    private func invalidate(paths: [String]) {
        var queue = paths
        var visited: Set<String> = []

        while let current = queue.first {
            queue.removeFirst()

            guard !visited.contains(current) else {
                continue
            }
            visited.insert(current)

            if let dependents = dependentsByPath[current] {
                queue.append(contentsOf: dependents)
            }

            removeEntry(path: current)
        }
    }

    private func removeEntry(path: String) {
        guard let entry = entries.removeValue(forKey: path) else {
            dependentsByPath.removeValue(forKey: path)
            return
        }

        removeDependents(for: path, dependencies: entry.dependencies)
        accessOrder.removeAll { $0 == path }
        dependentsByPath.removeValue(forKey: path)
    }

    private func removeDependents(for path: String, dependencies: Set<String>) {
        for dependency in dependencies {
            guard var dependents = dependentsByPath[dependency] else {
                continue
            }
            dependents.remove(path)
            if dependents.isEmpty {
                dependentsByPath.removeValue(forKey: dependency)
            } else {
                dependentsByPath[dependency] = dependents
            }
        }
    }

    private func markAccessed(_ path: String) {
        accessOrder.removeAll { $0 == path }
        accessOrder.append(path)
    }

    private func evictIfNeeded() {
        while accessOrder.count > capacity {
            guard let evicted = accessOrder.first else {
                break
            }
            accessOrder.removeFirst()
            removeEntry(path: evicted)
        }
    }
}
