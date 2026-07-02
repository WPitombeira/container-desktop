import Foundation

public final class StdioMCPServer {
    private let registry: AuraMCPToolRegistry
    private let decoder = JSONDecoder()
    private let encoder: JSONEncoder

    public init(registry: AuraMCPToolRegistry = AuraMCPToolRegistry()) {
        self.registry = registry
        encoder = JSONEncoder()
    }

    public func run() async {
        while let line = readLine(strippingNewline: true) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            guard let data = trimmed.data(using: .utf8) else { continue }
            await handle(data: data)
        }
    }

    public func handle(data: Data) async {
        do {
            let request = try decoder.decode(JSONRPCRequest.self, from: data)
            guard request.id != nil else {
                return
            }
            let result = try await responseResult(for: request)
            write(JSONRPCResponse(id: request.id, result: result, error: nil))
        } catch let error as JSONRPCError {
            write(JSONRPCResponse(id: nil, result: nil, error: error))
        } catch {
            write(JSONRPCResponse(id: nil, result: nil, error: .init(code: -32700, message: error.localizedDescription)))
        }
    }

    private func responseResult(for request: JSONRPCRequest) async throws -> JSONValue {
        switch request.method {
        case "initialize":
            return .object([
                "protocolVersion": .string("2025-03-26"),
                "capabilities": .object([
                    "tools": .object([:])
                ]),
                "serverInfo": .object([
                    "name": .string("aura-container-desktop"),
                    "version": .string("0.1.0")
                ])
            ])
        case "ping":
            return .object([:])
        case "tools/list":
            let tools = try registry.tools.map { tool -> JSONValue in
                let data = try encoder.encode(tool)
                return try decoder.decode(JSONValue.self, from: data)
            }
            return .object(["tools": .array(tools)])
        case "tools/call":
            let params = request.params?.objectValue ?? [:]
            guard let name = params["name"]?.stringValue else {
                throw JSONRPCError(code: -32602, message: "tools/call requires a tool name.")
            }
            let arguments = params["arguments"]?.objectValue ?? [:]
            let toolResult = await registry.callTool(name: name, arguments: arguments)
            let data = try encoder.encode(toolResult)
            return try decoder.decode(JSONValue.self, from: data)
        default:
            throw JSONRPCError(code: -32601, message: "Method not found: \(request.method)")
        }
    }

    private func write(_ response: JSONRPCResponse) {
        guard let data = try? encoder.encode(response),
              let line = String(data: data, encoding: .utf8)
        else {
            return
        }
        print(line)
        fflush(stdout)
    }
}

public struct JSONRPCRequest: Codable, Equatable, Sendable {
    public let jsonrpc: String?
    public let id: JSONValue?
    public let method: String
    public let params: JSONValue?
}

public struct JSONRPCResponse: Encodable, Equatable, Sendable {
    public let jsonrpc = "2.0"
    public let id: JSONValue?
    public let result: JSONValue?
    public let error: JSONRPCError?
}

public struct JSONRPCError: Error, Codable, Equatable, Sendable {
    public let code: Int
    public let message: String
}
