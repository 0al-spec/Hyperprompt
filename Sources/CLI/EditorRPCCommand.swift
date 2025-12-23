import Foundation
import ArgumentParser
import EditorEngine

struct EditorRPCCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "editor-rpc",
        abstract: "JSON-RPC interface for editor integration (VS Code extension)"
    )

    func run() throws {
        // Read JSON-RPC requests from stdin, write responses to stdout
        while let line = readLine() {
            do {
                guard let data = line.data(using: .utf8) else {
                    printError(id: nil, code: .parseError, message: "Invalid UTF-8")
                    continue
                }

                let request = try JSONDecoder().decode(JSONRPCRequest.self, from: data)
                let response = handleRequest(request)
                let responseData = try JSONEncoder().encode(response)

                if let json = String(data: responseData, encoding: .utf8) {
                    print(json)
                    try? FileHandle.standardOutput.synchronize()
                }
            } catch {
                printError(id: nil, code: .parseError, message: "Invalid JSON-RPC request: \(error.localizedDescription)")
            }
        }
    }

    func handleRequest(_ request: JSONRPCRequest) -> JSONRPCResponse {
        do {
            switch request.method {
            case "editor.indexProject":
                return try handleIndexProject(request)
            case "editor.parse":
                return errorResponse(id: request.id, code: .internalError, message: "Method not yet implemented")
            case "editor.resolve":
                return errorResponse(id: request.id, code: .internalError, message: "Method not yet implemented")
            case "editor.compile":
                return errorResponse(id: request.id, code: .internalError, message: "Method not yet implemented")
            case "editor.linkAt":
                return errorResponse(id: request.id, code: .internalError, message: "Method not yet implemented")
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
            print(json)
            try? FileHandle.standardOutput.synchronize()
        }
    }
}
