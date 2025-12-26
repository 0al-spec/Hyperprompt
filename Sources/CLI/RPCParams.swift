import Foundation

// MARK: - RPC Parameter Types

public struct IndexProjectParams: Codable {
    public let workspaceRoot: String

    public init(workspaceRoot: String) {
        self.workspaceRoot = workspaceRoot
    }
}

public struct ParseParams: Codable {
    public let filePath: String

    public init(filePath: String) {
        self.filePath = filePath
    }
}

public struct ResolveParams: Codable {
    public let linkPath: String
    public let sourceFile: String
    public let workspaceRoot: String

    public init(linkPath: String, sourceFile: String, workspaceRoot: String) {
        self.linkPath = linkPath
        self.sourceFile = sourceFile
        self.workspaceRoot = workspaceRoot
    }
}

public struct CompileParams: Codable {
    public let entryFile: String
    public let workspaceRoot: String
    public let mode: String?  // "strict" or "lenient"
    public let includeOutput: Bool?

    public init(entryFile: String, workspaceRoot: String, mode: String? = nil, includeOutput: Bool? = nil) {
        self.entryFile = entryFile
        self.workspaceRoot = workspaceRoot
        self.mode = mode
        self.includeOutput = includeOutput
    }
}

public struct LinkAtParams: Codable {
    public let filePath: String
    public let line: Int  // 1-indexed
    public let column: Int  // 0-indexed

    public init(filePath: String, line: Int, column: Int) {
        self.filePath = filePath
        self.line = line
        self.column = column
    }
}
