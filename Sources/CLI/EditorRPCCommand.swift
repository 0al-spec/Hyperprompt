#if Editor
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("Unsupported platform")
#endif
import Foundation
import ArgumentParser
import EditorEngine
import Core

struct EditorRPCCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "editor-rpc",
        abstract: "JSON-RPC interface for editor integration (VS Code extension)"
    )

    func run() throws {
        var buffer = Data()
        var temp = [UInt8](repeating: 0, count: 4096)

        while true {
            let bytesRead = read(STDIN_FILENO, &temp, temp.count)
            if bytesRead > 0 {
                buffer.append(contentsOf: temp[0..<bytesRead])
                processBuffer(&buffer)
            } else if bytesRead == 0 {
                break
            } else if errno == EINTR {
                continue
            } else {
                printError(id: nil, code: .internalError, message: "Failed to read stdin.")
                break
            }
        }

        if !buffer.isEmpty {
            handleLineData(buffer)
        }
    }

    private func processBuffer(_ buffer: inout Data) {
        while let newlineIndex = buffer.firstIndex(of: 0x0A) {
            let lineData = Data(buffer[..<newlineIndex])
            buffer.removeSubrange(...newlineIndex)
            handleLineData(lineData)
        }
    }

    private func handleLineData(_ lineData: Data) {
        var data = lineData
        if data.last == 0x0D {
            data.removeLast()
        }

        if data.isEmpty {
            return
        }

        do {
            let request = try JSONDecoder().decode(JSONRPCRequest.self, from: data)
            let response = handleRequest(request)
            let responseData = try JSONEncoder().encode(response)

            if let json = String(data: responseData, encoding: .utf8) {
                writeStdoutLine(json)
            }
        } catch {
            printError(id: nil, code: .parseError, message: "Invalid JSON-RPC request: \(error.localizedDescription)")
        }
    }

    func handleRequest(_ request: JSONRPCRequest) -> JSONRPCResponse {
        do {
            switch request.method {
            case "editor.indexProject":
                return try handleIndexProject(request)
            case "editor.parse":
                return try handleParse(request)
            case "editor.resolve":
                return try handleResolve(request)
            case "editor.compile":
                return try handleCompile(request)
            case "editor.linkAt":
                return try handleLinkAt(request)
            default:
                return errorResponse(
                    id: request.id,
                    code: .methodNotFound,
                    message: "Method not found: \(request.method)"
                )
            }
        } catch {
            return errorResponse(
                id: request.id,
                code: .internalError,
                message: error.localizedDescription
            )
        }
    }

    func handleIndexProject(_ request: JSONRPCRequest) throws -> JSONRPCResponse {
        let params = try decodeParams(IndexProjectParams.self, from: request.params)
        let index = try EditorEngine.indexProject(workspaceRoot: params.workspaceRoot)
        return successResponse(id: request.id, result: index)
    }

    func handleParse(_ request: JSONRPCRequest) throws -> JSONRPCResponse {
        let params = try decodeParams(ParseParams.self, from: request.params)
        let parsed = EditorParser.parse(filePath: params.filePath)

        // Create simplified response without AST
        let response = ParsedFileResponse(
            sourceFile: parsed.sourceFile,
            linkSpans: parsed.linkSpans,
            hasDiagnostics: parsed.hasDiagnostics
        )
        return successResponse(id: request.id, result: response)
    }

    func handleResolve(_ request: JSONRPCRequest) throws -> JSONRPCResponse {
        let params = try decodeParams(ResolveParams.self, from: request.params)

        // Create a LinkSpan from the provided link path
        let link = LinkSpan(
            literal: params.linkPath,
            byteRange: 0..<params.linkPath.count,
            lineRange: 1..<2,
            columnRange: 1..<2,
            referenceHint: .fileReference,
            sourceFile: params.sourceFile
        )

        let resolver = EditorResolver(workspaceRoot: params.workspaceRoot)
        let result = resolver.resolve(link: link)

        return successResponse(id: request.id, result: result.target)
    }

    func handleCompile(_ request: JSONRPCRequest) throws -> JSONRPCResponse {
        let params = try decodeParams(CompileParams.self, from: request.params)

        let mode: CompilerArguments.CompilationMode = {
            if let modeStr = params.mode?.lowercased() {
                return modeStr == "lenient" ? .lenient : .strict
            }
            return .strict
        }()

        let options = CompileOptions(
            mode: mode,
            workspaceRoot: params.workspaceRoot,
            outputWritePolicy: .dryRun
        )

        let compiler = EditorCompiler()
        let result = compiler.compile(entryFile: params.entryFile, options: options)

        // Map CompilerError to Diagnostic
        let diagnostics = result.diagnostics.map { error in
            DiagnosticMapper.map(error)
        }

        let includeOutput = params.includeOutput ?? true
        let compileResponse = CompileResultResponse(
            output: includeOutput ? result.output : nil,
            diagnostics: diagnostics,
            hasErrors: result.hasErrors
        )

        return successResponse(id: request.id, result: compileResponse)
    }

    func handleLinkAt(_ request: JSONRPCRequest) throws -> JSONRPCResponse {
        let params = try decodeParams(LinkAtParams.self, from: request.params)
        let parsed = EditorParser.parse(filePath: params.filePath)

        // Find link at position
        let link = findLinkAt(
            line: params.line,
            column: params.column,
            in: parsed.linkSpans
        )

        if let link = link {
            return successResponse(id: request.id, result: link)
        } else {
            return successResponse(id: request.id, result: AnyCodable(Optional<String>.none))
        }
    }

    private func findLinkAt(line: Int, column: Int, in linkSpans: [LinkSpan]) -> LinkSpan? {
        for span in linkSpans {
            if span.lineRange.contains(line) {
                if line == span.lineRange.lowerBound && span.columnRange.contains(column) {
                    return span
                } else if line > span.lineRange.lowerBound && line < span.lineRange.upperBound - 1 {
                    return span
                }
            }
        }
        return nil
    }

    func decodeParams<T: Decodable>(_ type: T.Type, from params: AnyCodable?) throws -> T {
        guard let params = params else {
            throw JSONRPCError(code: JSONRPCErrorCode.invalidParams.rawValue, message: "Missing params")
        }

        let jsonData = try JSONSerialization.data(withJSONObject: params.value)
        return try JSONDecoder().decode(type, from: jsonData)
    }

    func printError(id: RequestID?, code: JSONRPCErrorCode, message: String) {
        let response = errorResponse(id: id, code: code, message: message)
        if let data = try? JSONEncoder().encode(response),
           let json = String(data: data, encoding: .utf8) {
            writeStdoutLine(json)
        }
    }

    private func writeStdoutLine(_ message: String) {
        if let data = (message + "\n").data(using: .utf8) {
            FileHandle.standardOutput.write(data)
        }
    }
}

// MARK: - Response Types

struct ParsedFileResponse: Codable {
    let sourceFile: String
    let linkSpans: [LinkSpan]
    let hasDiagnostics: Bool
}

struct CompileResultResponse: Codable {
    let output: String?
    let diagnostics: [Diagnostic]
    let hasErrors: Bool
}
#endif
