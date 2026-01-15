import Foundation

public struct InitializeParams: Codable {
    public let rootUri: String?
    public let rootPath: String?
}

public struct InitializeResult: Codable {
    public let capabilities: ServerCapabilities
}

public struct ServerCapabilities: Codable {
    public let textDocumentSync: TextDocumentSyncKind
    public let definitionProvider: Bool
    public let hoverProvider: Bool
}

public enum TextDocumentSyncKind: Int, Codable {
    case none = 0
    case full = 1
    case incremental = 2
}

public struct TextDocumentItem: Codable {
    public let uri: String
    public let text: String
}

public struct TextDocumentIdentifier: Codable {
    public let uri: String
}

public struct VersionedTextDocumentIdentifier: Codable {
    public let uri: String
    public let version: Int?
}

public struct TextDocumentContentChangeEvent: Codable {
    public let text: String
}

public struct DidOpenTextDocumentParams: Codable {
    public let textDocument: TextDocumentItem
}

public struct DidChangeTextDocumentParams: Codable {
    public let textDocument: VersionedTextDocumentIdentifier
    public let contentChanges: [TextDocumentContentChangeEvent]
}

public struct DidSaveTextDocumentParams: Codable {
    public let textDocument: TextDocumentIdentifier
}

public struct Position: Codable {
    public let line: Int
    public let character: Int
}

public struct Range: Codable {
    public let start: Position
    public let end: Position
}

public struct Location: Codable {
    public let uri: String
    public let range: Range
}

public struct TextDocumentPositionParams: Codable {
    public let textDocument: TextDocumentIdentifier
    public let position: Position
}

public struct Hover: Codable {
    public let contents: MarkupContent
}

public struct MarkupContent: Codable {
    public let kind: String
    public let value: String
}

public struct PublishDiagnosticsParams: Codable {
    public let uri: String
    public let diagnostics: [LSPDiagnostic]
}

public struct LSPDiagnostic: Codable {
    public let range: Range
    public let severity: Int
    public let code: String?
    public let source: String?
    public let message: String
}
