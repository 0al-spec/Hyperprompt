import Foundation
#if Editor
import Core
import EditorEngine

final class LSPServer {
    private var workspaceRoot: String?
    private var openDocuments: [String: String] = [:]
    private let sendMessage: (JSONRPCResponse) -> Void
    private let sendNotification: (String, Encodable) -> Void
    private var shouldExit = false

    init(sendMessage: @escaping (JSONRPCResponse) -> Void, sendNotification: @escaping (String, Encodable) -> Void) {
        self.sendMessage = sendMessage
        self.sendNotification = sendNotification
    }

    func handle(_ request: JSONRPCRequest) {
        switch request.method {
        case "initialize":
            handleInitialize(request)
        case "shutdown":
            handleShutdown(request)
        case "exit":
            shouldExit = true
        case "textDocument/didOpen":
            handleDidOpen(request)
        case "textDocument/didChange":
            handleDidChange(request)
        case "textDocument/didSave":
            handleDidSave(request)
        case "textDocument/definition":
            handleDefinition(request)
        case "textDocument/hover":
            handleHover(request)
        default:
            if request.id != nil {
                let response = errorResponse(id: request.id, code: .methodNotFound, message: "Unknown method")
                sendMessage(response)
            }
        }
    }

    func shouldTerminate() -> Bool {
        shouldExit
    }

    private func handleInitialize(_ request: JSONRPCRequest) {
        do {
            let params = try request.params?.decode(InitializeParams.self)
            workspaceRoot = params?.rootUri.flatMap(filePathFromURI) ?? params?.rootPath
            let capabilities = ServerCapabilities(
                textDocumentSync: .full,
                definitionProvider: true,
                hoverProvider: true
            )
            let result = InitializeResult(capabilities: capabilities)
            sendMessage(successResponse(id: request.id, result: result))
        } catch {
            sendMessage(errorResponse(id: request.id, code: .invalidParams, message: error.localizedDescription))
        }
    }

    private func handleShutdown(_ request: JSONRPCRequest) {
        sendMessage(successResponse(id: request.id, result: Optional<String>.none))
    }

    private func handleDidOpen(_ request: JSONRPCRequest) {
        guard let params = try? request.params?.decode(DidOpenTextDocumentParams.self) else {
            return
        }
        openDocuments[params.textDocument.uri] = params.textDocument.text
        writeTextIfNeeded(uri: params.textDocument.uri, text: params.textDocument.text)
        publishDiagnostics(for: params.textDocument.uri)
    }

    private func handleDidChange(_ request: JSONRPCRequest) {
        guard let params = try? request.params?.decode(DidChangeTextDocumentParams.self),
              let latest = params.contentChanges.last else {
            return
        }
        openDocuments[params.textDocument.uri] = latest.text
        writeTextIfNeeded(uri: params.textDocument.uri, text: latest.text)
        publishDiagnostics(for: params.textDocument.uri)
    }

    private func handleDidSave(_ request: JSONRPCRequest) {
        guard let params = try? request.params?.decode(DidSaveTextDocumentParams.self) else {
            return
        }
        publishDiagnostics(for: params.textDocument.uri)
    }

    private func handleDefinition(_ request: JSONRPCRequest) {
        guard let params = try? request.params?.decode(TextDocumentPositionParams.self) else {
            sendMessage(errorResponse(id: request.id, code: .invalidParams, message: "Invalid params"))
            return
        }

        guard let filePath = filePathFromURI(params.textDocument.uri) else {
            sendMessage(errorResponse(id: request.id, code: .invalidParams, message: "Invalid URI"))
            return
        }

        let parser = EditorParser()
        let parsed = parser.parse(filePath: filePath)
        let line = params.position.line + 1
        let column = params.position.character + 1
        guard let link = parser.linkAt(line: line, column: column, in: parsed) else {
            sendMessage(successResponse(id: request.id, result: Optional<Location>.none))
            return
        }

        let resolver = EditorResolver(workspaceRoot: resolveWorkspaceRoot(for: filePath))
        let result = resolver.resolve(link: link)
        guard let targetPath = resolvedPath(from: result.target) else {
            sendMessage(successResponse(id: request.id, result: Optional<Location>.none))
            return
        }

        let location = Location(
            uri: fileURI(from: targetPath),
            range: Range(
                start: Position(line: 0, character: 0),
                end: Position(line: 0, character: 0)
            )
        )

        sendMessage(successResponse(id: request.id, result: location))
    }

    private func handleHover(_ request: JSONRPCRequest) {
        guard let params = try? request.params?.decode(TextDocumentPositionParams.self) else {
            sendMessage(errorResponse(id: request.id, code: .invalidParams, message: "Invalid params"))
            return
        }

        guard let filePath = filePathFromURI(params.textDocument.uri) else {
            sendMessage(errorResponse(id: request.id, code: .invalidParams, message: "Invalid URI"))
            return
        }

        let parser = EditorParser()
        let parsed = parser.parse(filePath: filePath)
        let line = params.position.line + 1
        let column = params.position.character + 1
        guard let link = parser.linkAt(line: line, column: column, in: parsed) else {
            sendMessage(successResponse(id: request.id, result: Optional<Hover>.none))
            return
        }

        let resolver = EditorResolver(workspaceRoot: resolveWorkspaceRoot(for: filePath))
        let result = resolver.resolve(link: link)
        let hoverText = resolvedPath(from: result.target) ?? "Unresolved link"
        let hover = Hover(contents: MarkupContent(kind: "plaintext", value: hoverText))
        sendMessage(successResponse(id: request.id, result: hover))
    }

    private func publishDiagnostics(for uri: String) {
        guard let filePath = filePathFromURI(uri) else { return }

        let options = CompileOptions(
            mode: .strict,
            workspaceRoot: resolveWorkspaceRoot(for: filePath),
            outputWritePolicy: .dryRun
        )
        let compiler = EditorCompiler()
        let result = compiler.compile(entryFile: filePath, options: options)
        let diagnostics = DiagnosticMapper.mapAll(result.diagnostics).map(mapDiagnostic)
        let params = PublishDiagnosticsParams(uri: uri, diagnostics: diagnostics)
        sendNotification("textDocument/publishDiagnostics", params)
    }

    private func mapDiagnostic(_ diagnostic: Diagnostic) -> LSPDiagnostic {
        let range = diagnostic.range.map { range in
            Range(
                start: Position(line: range.start.line - 1, character: range.start.column - 1),
                end: Position(line: range.end.line - 1, character: range.end.column - 1)
            )
        } ?? Range(start: Position(line: 0, character: 0), end: Position(line: 0, character: 0))

        let severity: Int
        switch diagnostic.severity {
        case .error: severity = 1
        case .warning: severity = 2
        case .info: severity = 3
        case .hint: severity = 4
        }

        return LSPDiagnostic(
            range: range,
            severity: severity,
            code: diagnostic.code,
            source: "Hyperprompt",
            message: diagnostic.message
        )
    }

    private func resolvedPath(from target: ResolvedTarget) -> String? {
        switch target {
        case .markdownFile(let path):
            return path
        case .hypercodeFile(let path):
            return path
        case .ambiguous(let candidates):
            return candidates.first
        case .inlineText, .forbidden, .invalid:
            return nil
        }
    }

    private func resolveWorkspaceRoot(for filePath: String) -> String {
        if let workspaceRoot {
            return workspaceRoot
        }
        return URL(fileURLWithPath: filePath).deletingLastPathComponent().path
    }

    private func writeTextIfNeeded(uri: String, text: String) {
        guard let filePath = filePathFromURI(uri) else { return }
        do {
            try text.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {
            return
        }
    }

    private func filePathFromURI(_ uri: String) -> String? {
        URL(string: uri)?.path
    }

    private func fileURI(from path: String) -> String {
        URL(fileURLWithPath: path).absoluteString
    }
}
#endif
