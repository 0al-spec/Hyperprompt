import Foundation

// MARK: - Request ID (can be Int or String per JSON-RPC 2.0)
public enum RequestID: Codable, Hashable {
    case int(Int)
    case string(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                RequestID.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "ID must be int or string"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

// MARK: - JSON-RPC Request
public struct JSONRPCRequest: Codable {
    public let jsonrpc: String
    public let id: RequestID?
    public let method: String
    public let params: AnyCodable?

    public init(jsonrpc: String = "2.0", id: RequestID?, method: String, params: AnyCodable? = nil) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.method = method
        self.params = params
    }
}

// MARK: - JSON-RPC Response
public struct JSONRPCResponse: Codable {
    public let jsonrpc: String
    public let id: RequestID?
    public let result: AnyCodable?
    public let error: JSONRPCError?

    public init(jsonrpc: String = "2.0", id: RequestID?, result: AnyCodable? = nil, error: JSONRPCError? = nil) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.result = result
        self.error = error
    }
}

// MARK: - JSON-RPC Error
public struct JSONRPCError: Codable, Error {
    public let code: Int
    public let message: String
    public let data: AnyCodable?

    public init(code: Int, message: String, data: AnyCodable? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}

// MARK: - JSON-RPC Error Codes
public enum JSONRPCErrorCode: Int {
    case parseError = -32700
    case invalidRequest = -32600
    case methodNotFound = -32601
    case invalidParams = -32602
    case internalError = -32603
}

// MARK: - AnyCodable wrapper for arbitrary JSON values
public struct AnyCodable: Codable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = ()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Cannot encode value")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// MARK: - Helper Functions
public func successResponse<T: Encodable>(id: RequestID?, result: T) -> JSONRPCResponse {
    let encoder = JSONEncoder()
    let data = try! encoder.encode(result)
    let json = try! JSONSerialization.jsonObject(with: data)
    return JSONRPCResponse(id: id, result: AnyCodable(json), error: nil)
}

public func errorResponse(id: RequestID?, code: JSONRPCErrorCode, message: String, data: Any? = nil) -> JSONRPCResponse {
    let error = JSONRPCError(code: code.rawValue, message: message, data: data.map { AnyCodable($0) })
    return JSONRPCResponse(id: id, result: nil, error: error)
}
