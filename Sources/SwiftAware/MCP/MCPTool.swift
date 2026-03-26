// MCPTool.swift
// SwiftAware MCP Module
//
// Tool definition protocol for MCP servers.

import Foundation

// MARK: - MCP Tool Protocol

/// Protocol for defining MCP tools.
/// Implement this to create tools that can be registered with an MCPServer.
public protocol MCPTool: Sendable {
    /// Unique name of the tool
    var name: String { get }

    /// Human-readable description of what the tool does
    var description: String { get }

    /// JSON Schema for the tool's input parameters
    var inputSchema: MCPToolSchema { get }

    /// Execute the tool with the given arguments
    /// - Parameter arguments: The arguments passed to the tool
    /// - Returns: The result of the tool execution
    func execute(arguments: [String: MCPValue]?) async throws -> MCPToolCallResult
}

// MARK: - Tool Schema

/// JSON Schema definition for tool input parameters
public struct MCPToolSchema: Codable, Sendable {
    public let type: String
    public let properties: [String: MCPPropertySchema]?
    public let required: [String]?

    public init(
        type: String = "object",
        properties: [String: MCPPropertySchema]? = nil,
        required: [String]? = nil
    ) {
        self.type = type
        self.properties = properties
        self.required = required
    }

    /// Create an empty schema (no parameters)
    public static let empty = MCPToolSchema()

    /// Builder for creating schemas
    public static func builder() -> MCPToolSchemaBuilder {
        MCPToolSchemaBuilder()
    }
}

// MARK: - Property Schema

/// Schema for a single property in tool input
public struct MCPPropertySchema: Codable, Sendable {
    public let type: String
    public let description: String?
    public let `enum`: [String]?
    /// For array types, the schema of array items (boxed to avoid recursion)
    private let _items: MCPPropertySchemaBox?
    public let `default`: MCPValue?

    public var items: MCPPropertySchema? {
        _items?.value
    }

    public init(
        type: String,
        description: String? = nil,
        `enum`: [String]? = nil,
        items: MCPPropertySchema? = nil,
        `default`: MCPValue? = nil
    ) {
        self.type = type
        self.description = description
        self.`enum` = `enum`
        self._items = items.map { MCPPropertySchemaBox($0) }
        self.`default` = `default`
    }

    enum CodingKeys: String, CodingKey {
        case type, description, `enum`, `default`
        case _items = "items"
    }

    // Common property types
    public static func string(_ description: String? = nil) -> MCPPropertySchema {
        MCPPropertySchema(type: "string", description: description)
    }

    public static func int(_ description: String? = nil) -> MCPPropertySchema {
        MCPPropertySchema(type: "integer", description: description)
    }

    public static func number(_ description: String? = nil) -> MCPPropertySchema {
        MCPPropertySchema(type: "number", description: description)
    }

    public static func bool(_ description: String? = nil) -> MCPPropertySchema {
        MCPPropertySchema(type: "boolean", description: description)
    }

    public static func array(_ items: MCPPropertySchema, description: String? = nil) -> MCPPropertySchema {
        MCPPropertySchema(type: "array", description: description, items: items)
    }

    public static func enumeration(_ values: [String], description: String? = nil) -> MCPPropertySchema {
        MCPPropertySchema(type: "string", description: description, enum: values)
    }
}

/// Box to avoid recursive struct issue
private final class MCPPropertySchemaBox: Codable, @unchecked Sendable {
    let value: MCPPropertySchema

    init(_ value: MCPPropertySchema) {
        self.value = value
    }

    required init(from decoder: Decoder) throws {
        self.value = try MCPPropertySchema(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

// MARK: - Schema Builder

/// Fluent builder for creating tool schemas
public class MCPToolSchemaBuilder {
    private var properties: [String: MCPPropertySchema] = [:]
    private var required: [String] = []

    /// Add a string property
    @discardableResult
    public func string(_ name: String, description: String? = nil, required: Bool = false) -> Self {
        properties[name] = .string(description)
        if required { self.required.append(name) }
        return self
    }

    /// Add an integer property
    @discardableResult
    public func int(_ name: String, description: String? = nil, required: Bool = false) -> Self {
        properties[name] = .int(description)
        if required { self.required.append(name) }
        return self
    }

    /// Add a number property
    @discardableResult
    public func number(_ name: String, description: String? = nil, required: Bool = false) -> Self {
        properties[name] = .number(description)
        if required { self.required.append(name) }
        return self
    }

    /// Add a boolean property
    @discardableResult
    public func bool(_ name: String, description: String? = nil, required: Bool = false) -> Self {
        properties[name] = .bool(description)
        if required { self.required.append(name) }
        return self
    }

    /// Add an array property
    @discardableResult
    public func array(_ name: String, items: MCPPropertySchema, description: String? = nil, required: Bool = false) -> Self {
        properties[name] = .array(items, description: description)
        if required { self.required.append(name) }
        return self
    }

    /// Add an enum property
    @discardableResult
    public func enumeration(_ name: String, values: [String], description: String? = nil, required: Bool = false) -> Self {
        properties[name] = .enumeration(values, description: description)
        if required { self.required.append(name) }
        return self
    }

    /// Add a custom property
    @discardableResult
    public func property(_ name: String, schema: MCPPropertySchema, required: Bool = false) -> Self {
        properties[name] = schema
        if required { self.required.append(name) }
        return self
    }

    /// Build the schema
    public func build() -> MCPToolSchema {
        MCPToolSchema(
            properties: properties.isEmpty ? nil : properties,
            required: required.isEmpty ? nil : required
        )
    }
}

// MARK: - Tool Definition

/// Concrete tool definition that can be registered
public struct MCPToolDefinition: Codable, Sendable {
    public let name: String
    public let description: String?
    public let inputSchema: MCPToolSchema

    public init(name: String, description: String?, inputSchema: MCPToolSchema) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }

    /// Create from an MCPTool
    public init(from tool: any MCPTool) {
        self.name = tool.name
        self.description = tool.description
        self.inputSchema = tool.inputSchema
    }
}

// MARK: - Simple Tool Implementation

/// A simple tool implementation using a closure
public struct SimpleMCPTool: MCPTool {
    public let name: String
    public let description: String
    public let inputSchema: MCPToolSchema
    private let handler: @Sendable ([String: MCPValue]?) async throws -> MCPToolCallResult

    public init(
        name: String,
        description: String,
        inputSchema: MCPToolSchema = .empty,
        handler: @escaping @Sendable ([String: MCPValue]?) async throws -> MCPToolCallResult
    ) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
        self.handler = handler
    }

    public func execute(arguments: [String: MCPValue]?) async throws -> MCPToolCallResult {
        try await handler(arguments)
    }
}

// MARK: - Tool Errors

/// Errors that can occur during tool execution
public enum MCPToolError: Error, Sendable {
    case invalidArguments(String)
    case executionFailed(String)
    case notFound(String)
    case timeout
    case cancelled

    public var localizedDescription: String {
        switch self {
        case .invalidArguments(let msg): return "Invalid arguments: \(msg)"
        case .executionFailed(let msg): return "Execution failed: \(msg)"
        case .notFound(let name): return "Tool not found: \(name)"
        case .timeout: return "Tool execution timed out"
        case .cancelled: return "Tool execution was cancelled"
        }
    }
}
