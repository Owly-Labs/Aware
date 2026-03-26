// MCPProtocol.swift
// SwiftAware MCP Module
//
// JSON-RPC 2.0 protocol types for Model Context Protocol (MCP).

import Foundation

// MARK: - JSON-RPC Request

/// JSON-RPC 2.0 request structure
public struct MCPRequest: Codable, Sendable {
    public let jsonrpc: String
    public let id: RequestId
    public let method: String
    public let params: MCPParams?

    public init(id: RequestId, method: String, params: MCPParams? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }
}

// MARK: - JSON-RPC Response

/// JSON-RPC 2.0 response structure
public struct MCPResponse: Codable, Sendable {
    public let jsonrpc: String
    public let id: RequestId
    public let result: MCPResult?
    public let error: MCPError?

    public init(id: RequestId, result: MCPResult) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = result
        self.error = nil
    }

    public init(id: RequestId, error: MCPError) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = nil
        self.error = error
    }
}

// MARK: - Request ID

/// Request ID can be string or integer
public enum RequestId: Codable, Sendable, Hashable {
    case string(String)
    case int(Int)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                RequestId.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected string or int")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        }
    }
}

// MARK: - MCP Error

/// JSON-RPC 2.0 error structure
public struct MCPError: Codable, Sendable, Error {
    public let code: Int
    public let message: String
    public let data: MCPValue?

    public init(code: Int, message: String, data: MCPValue? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }

    // Standard JSON-RPC error codes
    public static let parseError = MCPError(code: -32700, message: "Parse error")
    public static let invalidRequest = MCPError(code: -32600, message: "Invalid Request")
    public static let methodNotFound = MCPError(code: -32601, message: "Method not found")
    public static let invalidParams = MCPError(code: -32602, message: "Invalid params")
    public static let internalError = MCPError(code: -32603, message: "Internal error")

    // Custom error helper
    public static func custom(_ message: String, code: Int = -32000) -> MCPError {
        MCPError(code: code, message: message)
    }
}

// MARK: - MCP Value (Dynamic JSON)

/// Dynamic JSON value for MCP parameters and results
public enum MCPValue: Codable, Sendable, Equatable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([MCPValue])
    case object([String: MCPValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([MCPValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: MCPValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.typeMismatch(
                MCPValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown type")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }

    // MARK: - Accessors

    public var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }

    public var intValue: Int? {
        if case .int(let v) = self { return v }
        return nil
    }

    public var doubleValue: Double? {
        if case .double(let v) = self { return v }
        if case .int(let v) = self { return Double(v) }
        return nil
    }

    public var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    public var arrayValue: [MCPValue]? {
        if case .array(let v) = self { return v }
        return nil
    }

    public var objectValue: [String: MCPValue]? {
        if case .object(let v) = self { return v }
        return nil
    }

    /// Subscript access for objects
    public subscript(key: String) -> MCPValue? {
        if case .object(let dict) = self {
            return dict[key]
        }
        return nil
    }

    /// Subscript access for arrays
    public subscript(index: Int) -> MCPValue? {
        if case .array(let arr) = self, index >= 0 && index < arr.count {
            return arr[index]
        }
        return nil
    }
}

// MARK: - MCP Params (Request Parameters)

/// Parameters for MCP requests
public typealias MCPParams = MCPValue

// MARK: - MCP Result (Response Result)

/// Result for MCP responses
public typealias MCPResult = MCPValue

// MARK: - Tool Call Request

/// Request to call a tool
public struct MCPToolCallRequest: Codable, Sendable {
    public let name: String
    public let arguments: [String: MCPValue]?

    public init(name: String, arguments: [String: MCPValue]? = nil) {
        self.name = name
        self.arguments = arguments
    }
}

// MARK: - Tool Call Result

/// Result from a tool call
public struct MCPToolCallResult: Codable, Sendable {
    public let content: [MCPContent]
    public let isError: Bool?

    public init(content: [MCPContent], isError: Bool? = nil) {
        self.content = content
        self.isError = isError
    }

    /// Create a text result
    public static func text(_ text: String) -> MCPToolCallResult {
        MCPToolCallResult(content: [.text(text)])
    }

    /// Create an error result
    public static func error(_ message: String) -> MCPToolCallResult {
        MCPToolCallResult(content: [.text(message)], isError: true)
    }
}

// MARK: - MCP Content

/// Content types in tool results
public enum MCPContent: Codable, Sendable {
    case text(String)
    case image(data: String, mimeType: String)
    case resource(uri: String, mimeType: String?, text: String?)

    enum CodingKeys: String, CodingKey {
        case type, text, data, mimeType, uri
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case "image":
            let data = try container.decode(String.self, forKey: .data)
            let mimeType = try container.decode(String.self, forKey: .mimeType)
            self = .image(data: data, mimeType: mimeType)
        case "resource":
            let uri = try container.decode(String.self, forKey: .uri)
            let mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
            let text = try container.decodeIfPresent(String.self, forKey: .text)
            self = .resource(uri: uri, mimeType: mimeType, text: text)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown content type: \(type)")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let data, let mimeType):
            try container.encode("image", forKey: .type)
            try container.encode(data, forKey: .data)
            try container.encode(mimeType, forKey: .mimeType)
        case .resource(let uri, let mimeType, let text):
            try container.encode("resource", forKey: .type)
            try container.encode(uri, forKey: .uri)
            try container.encodeIfPresent(mimeType, forKey: .mimeType)
            try container.encodeIfPresent(text, forKey: .text)
        }
    }
}

// MARK: - Initialize Request

/// MCP initialize request parameters
public struct MCPInitializeParams: Codable, Sendable {
    public let protocolVersion: String
    public let capabilities: MCPClientCapabilities
    public let clientInfo: MCPClientInfo

    public init(protocolVersion: String = "2024-11-05", capabilities: MCPClientCapabilities = .init(), clientInfo: MCPClientInfo) {
        self.protocolVersion = protocolVersion
        self.capabilities = capabilities
        self.clientInfo = clientInfo
    }
}

/// Client capabilities
public struct MCPClientCapabilities: Codable, Sendable {
    public let roots: RootsCapability?
    public let sampling: SamplingCapability?

    public init(roots: RootsCapability? = nil, sampling: SamplingCapability? = nil) {
        self.roots = roots
        self.sampling = sampling
    }

    public struct RootsCapability: Codable, Sendable {
        public let listChanged: Bool?
        public init(listChanged: Bool? = nil) {
            self.listChanged = listChanged
        }
    }

    public struct SamplingCapability: Codable, Sendable {
        public init() {}
    }
}

/// Client info
public struct MCPClientInfo: Codable, Sendable {
    public let name: String
    public let version: String

    public init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}

// MARK: - Initialize Result

/// MCP initialize response result
public struct MCPInitializeResult: Codable, Sendable {
    public let protocolVersion: String
    public let capabilities: MCPServerCapabilities
    public let serverInfo: MCPServerInfo

    public init(protocolVersion: String = "2024-11-05", capabilities: MCPServerCapabilities, serverInfo: MCPServerInfo) {
        self.protocolVersion = protocolVersion
        self.capabilities = capabilities
        self.serverInfo = serverInfo
    }
}

/// Server capabilities
public struct MCPServerCapabilities: Codable, Sendable {
    public let tools: ToolsCapability?
    public let resources: ResourcesCapability?
    public let prompts: PromptsCapability?

    public init(tools: ToolsCapability? = .init(), resources: ResourcesCapability? = nil, prompts: PromptsCapability? = nil) {
        self.tools = tools
        self.resources = resources
        self.prompts = prompts
    }

    public struct ToolsCapability: Codable, Sendable {
        public let listChanged: Bool?
        public init(listChanged: Bool? = nil) {
            self.listChanged = listChanged
        }
    }

    public struct ResourcesCapability: Codable, Sendable {
        public let subscribe: Bool?
        public let listChanged: Bool?
        public init(subscribe: Bool? = nil, listChanged: Bool? = nil) {
            self.subscribe = subscribe
            self.listChanged = listChanged
        }
    }

    public struct PromptsCapability: Codable, Sendable {
        public let listChanged: Bool?
        public init(listChanged: Bool? = nil) {
            self.listChanged = listChanged
        }
    }
}

/// Server info
public struct MCPServerInfo: Codable, Sendable {
    public let name: String
    public let version: String

    public init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}
