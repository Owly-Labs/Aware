// MCPServer.swift
// GhostUI MCP Module
//
// MCP Server implementation with tool registry.

import Foundation

// MARK: - MCP Server

/// Actor-based MCP server that handles JSON-RPC requests.
/// Register tools and start with a transport to begin serving.
public actor MCPServer {

    // MARK: - Properties

    /// Server name
    public let name: String

    /// Server version
    public let version: String

    /// Registered tools
    private var tools: [String: any MCPTool] = [:]

    /// Current transport
    private var transport: (any MCPTransport)?

    /// Server state
    private var state: ServerState = .idle

    /// Server capabilities
    private var capabilities: MCPServerCapabilities

    // MARK: - State

    public enum ServerState: String, Sendable {
        case idle
        case starting
        case running
        case stopping
        case stopped
    }

    // MARK: - Initialization

    public init(name: String, version: String) {
        self.name = name
        self.version = version
        self.capabilities = MCPServerCapabilities(tools: .init())
    }

    // MARK: - Tool Registration

    /// Register a single tool
    public func registerTool(_ tool: any MCPTool) {
        tools[tool.name] = tool
    }

    /// Register multiple tools
    public func registerTools(_ newTools: [any MCPTool]) {
        for tool in newTools {
            tools[tool.name] = tool
        }
    }

    /// Unregister a tool by name
    public func unregisterTool(_ name: String) {
        tools.removeValue(forKey: name)
    }

    /// Get a tool by name
    public func tool(named name: String) -> (any MCPTool)? {
        tools[name]
    }

    /// Get all registered tool definitions
    public func allToolDefinitions() -> [MCPToolDefinition] {
        tools.values.map { MCPToolDefinition(from: $0) }
    }

    /// Check if a tool exists
    public func hasTool(_ name: String) -> Bool {
        tools[name] != nil
    }

    // MARK: - Server Lifecycle

    /// Start the server with the given transport
    public func start(transport: any MCPTransport) async throws {
        guard state == .idle || state == .stopped else {
            throw MCPServerError.invalidState("Cannot start server in state: \(state)")
        }

        state = .starting
        self.transport = transport

        do {
            try await transport.start()
            state = .running
            await processMessages(transport: transport)
        } catch {
            state = .stopped
            throw error
        }
    }

    /// Stop the server
    public func stop() async {
        guard state == .running else { return }

        state = .stopping
        await transport?.stop()
        transport = nil
        state = .stopped
    }

    /// Get current server state
    public func currentState() -> ServerState {
        state
    }

    // MARK: - Message Processing

    private func processMessages(transport: any MCPTransport) async {
        for await request in transport.messages() {
            let response = await handleRequest(request)
            do {
                try await transport.send(response)
            } catch {
                // Log send error but continue processing
                fputs("Failed to send response: \(error)\n", stderr)
            }
        }
    }

    private func handleRequest(_ request: MCPRequest) async -> MCPResponse {
        switch request.method {
        case "initialize":
            return handleInitialize(request)

        case "initialized":
            // Notification, no response needed but we return empty success
            return MCPResponse(id: request.id, result: .null)

        case "tools/list":
            return handleToolsList(request)

        case "tools/call":
            return await handleToolCall(request)

        case "ping":
            return MCPResponse(id: request.id, result: .object([:]))

        default:
            return MCPResponse(id: request.id, error: .methodNotFound)
        }
    }

    // MARK: - Request Handlers

    private func handleInitialize(_ request: MCPRequest) -> MCPResponse {
        let result = MCPInitializeResult(
            capabilities: capabilities,
            serverInfo: MCPServerInfo(name: name, version: version)
        )

        // Convert to MCPValue
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let data = try encoder.encode(result)
            let value = try decoder.decode(MCPValue.self, from: data)
            return MCPResponse(id: request.id, result: value)
        } catch {
            return MCPResponse(id: request.id, error: .internalError)
        }
    }

    private func handleToolsList(_ request: MCPRequest) -> MCPResponse {
        let toolDefs = allToolDefinitions()

        // Convert to JSON array
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let data = try encoder.encode(["tools": toolDefs])
            let value = try decoder.decode(MCPValue.self, from: data)
            return MCPResponse(id: request.id, result: value)
        } catch {
            return MCPResponse(id: request.id, error: .internalError)
        }
    }

    private func handleToolCall(_ request: MCPRequest) async -> MCPResponse {
        // Parse tool call params
        guard let params = request.params?.objectValue,
              let toolName = params["name"]?.stringValue else {
            return MCPResponse(id: request.id, error: .invalidParams)
        }

        let arguments = params["arguments"]?.objectValue

        // Find tool
        guard let tool = tools[toolName] else {
            return MCPResponse(
                id: request.id,
                error: .custom("Tool not found: \(toolName)", code: -32601)
            )
        }

        // Execute tool
        do {
            let result = try await tool.execute(arguments: arguments)

            // Convert result to MCPValue
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let data = try encoder.encode(result)
            let value = try decoder.decode(MCPValue.self, from: data)

            return MCPResponse(id: request.id, result: value)
        } catch {
            return MCPResponse(
                id: request.id,
                error: .custom("Tool execution failed: \(error.localizedDescription)")
            )
        }
    }
}

// MARK: - Server Errors

/// Errors that can occur during server operations
public enum MCPServerError: Error, Sendable {
    case invalidState(String)
    case toolNotFound(String)
    case transportError(String)
    case configurationError(String)

    public var localizedDescription: String {
        switch self {
        case .invalidState(let msg): return "Invalid state: \(msg)"
        case .toolNotFound(let name): return "Tool not found: \(name)"
        case .transportError(let msg): return "Transport error: \(msg)"
        case .configurationError(let msg): return "Configuration error: \(msg)"
        }
    }
}

// MARK: - Server Builder

/// Fluent builder for creating MCP servers
public class MCPServerBuilder {
    private var name: String = "AwareMCP"
    private var version: String = "1.0.0"
    private var tools: [any MCPTool] = []

    public init() {}

    /// Set server name
    @discardableResult
    public func name(_ name: String) -> Self {
        self.name = name
        return self
    }

    /// Set server version
    @discardableResult
    public func version(_ version: String) -> Self {
        self.version = version
        return self
    }

    /// Add a tool
    @discardableResult
    public func tool(_ tool: any MCPTool) -> Self {
        tools.append(tool)
        return self
    }

    /// Add multiple tools
    @discardableResult
    public func tools(_ tools: [any MCPTool]) -> Self {
        self.tools.append(contentsOf: tools)
        return self
    }

    /// Build the server
    public func build() async -> MCPServer {
        let server = MCPServer(name: name, version: version)
        await server.registerTools(tools)
        return server
    }
}

// MARK: - Convenience Extensions

extension MCPServer {
    /// Create a simple tool and register it
    public func registerSimpleTool(
        name: String,
        description: String,
        schema: MCPToolSchema = .empty,
        handler: @escaping @Sendable ([String: MCPValue]?) async throws -> MCPToolCallResult
    ) {
        let tool = SimpleMCPTool(
            name: name,
            description: description,
            inputSchema: schema,
            handler: handler
        )
        registerTool(tool)
    }
}
