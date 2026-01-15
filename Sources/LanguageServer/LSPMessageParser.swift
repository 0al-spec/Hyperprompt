import Foundation

struct LSPMessageParser {
    private var buffer = Data()

    mutating func append(_ data: Data) {
        buffer.append(data)
    }

    mutating func nextMessage() -> Data? {
        guard let headerRange = buffer.range(of: Data("\r\n\r\n".utf8)) else {
            return nil
        }

        let headerData = buffer[..<headerRange.lowerBound]
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            return nil
        }

        let contentLength = parseContentLength(from: headerString)
        guard contentLength >= 0 else {
            return nil
        }

        let bodyStart = headerRange.upperBound
        let bodyEnd = bodyStart + contentLength
        guard buffer.count >= bodyEnd else {
            return nil
        }

        let body = buffer[bodyStart..<bodyEnd]
        buffer.removeSubrange(..<bodyEnd)
        return Data(body)
    }

    private func parseContentLength(from header: String) -> Int {
        let lines = header.split(separator: "\r\n")
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            if key.caseInsensitiveCompare("Content-Length") == .orderedSame {
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                return Int(value) ?? -1
            }
        }
        return -1
    }
}
