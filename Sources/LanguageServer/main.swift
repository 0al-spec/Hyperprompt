#if Editor
import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("Unsupported platform")
#endif

final class LSPTransport {
    private var parser = LSPMessageParser()

    func run(server: LSPServer) {
        var buffer = [UInt8](repeating: 0, count: 4096)

        while true {
            let bytesRead = read(STDIN_FILENO, &buffer, buffer.count)
            if bytesRead > 0 {
                parser.append(Data(buffer[0..<bytesRead]))
                while let message = parser.nextMessage() {
                    handleMessage(message, server: server)
                    if server.shouldTerminate() {
                        return
                    }
                }
            } else if bytesRead == 0 {
                return
            } else if errno == EINTR {
                continue
            } else {
                let response = errorResponse(id: nil, code: .internalError, message: "Failed to read stdin")
                write(response)
                return
            }
        }
    }

    private func handleMessage(_ data: Data, server: LSPServer) {
        do {
            let request = try JSONDecoder().decode(JSONRPCRequest.self, from: data)
            server.handle(request)
        } catch {
            let response = errorResponse(id: nil, code: .parseError, message: error.localizedDescription)
            write(response)
        }
    }

    func write(_ response: JSONRPCResponse) {
        guard let data = try? JSONEncoder().encode(response) else { return }
        writeRaw(data)
    }

    func writeNotification(method: String, params: Encodable) {
        let notification = JSONRPCRequest(jsonrpc: "2.0", id: nil, method: method, params: encodeParams(params))
        guard let data = try? JSONEncoder().encode(notification) else { return }
        writeRaw(data)
    }

    private func encodeParams(_ params: Encodable) -> AnyCodable? {
        do {
            let data = try JSONEncoder().encode(params)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return AnyCodable(json)
        } catch {
            return nil
        }
    }

    private func writeRaw(_ data: Data) {
        let header = "Content-Length: \(data.count)\r\n\r\n"
        guard let headerData = header.data(using: .utf8) else { return }
        FileHandle.standardOutput.write(headerData)
        FileHandle.standardOutput.write(data)
    }
}

let transport = LSPTransport()
let server = LSPServer(
    sendMessage: { response in
        transport.write(response)
    },
    sendNotification: { method, params in
        transport.writeNotification(method: method, params: params)
    }
)
transport.run(server: server)
#else
import Foundation
print("LanguageServer requires the Editor trait to be enabled.")
#endif
