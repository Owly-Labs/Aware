// MCPTransport.swift
// SwiftAware MCP Module
//
// Transport abstraction for MCP servers.

import Foundation
import Network

// MARK: - Transport Protocol

/// Protocol for MCP transport implementations.
/// Transports handle the low-level communication (stdio, HTTP, WebSocket, etc.)
public protocol MCPTransport: Sendable {
    /// Start the transport and begin processing messages
    func start() async throws

    /// Stop the transport
    func stop() async

    /// Send a response to the client
    func send(_ response: MCPResponse) async throws

    /// Receive messages from the transport
    func messages() -> AsyncStream<MCPRequest>
}

// MARK: - Transport Type

/// Enumeration of available transport types
public enum MCPTransportType: String, Sendable, CaseIterable {
    /// Standard input/output (for CLI integrations like Claude Code)
    case stdio

    /// HTTP server (for cloud deployments)
    case http

    /// WebSocket (for real-time cloud connections)
    case websocket

    /// Unix domain socket (for local IPC)
    case unixSocket
}

// MARK: - Stdio Transport

/// Transport implementation using standard input/output.
/// This is the default transport for CLI-based MCP integrations.
public actor StdioTransport: @preconcurrency MCPTransport {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var isRunning = false
    private var messageContinuation: AsyncStream<MCPRequest>.Continuation?

    public init() {
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    public func start() async throws {
        isRunning = true
    }

    public func stop() async {
        isRunning = false
        messageContinuation?.finish()
    }

    public func send(_ response: MCPResponse) async throws {
        let data = try encoder.encode(response)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw MCPTransportError.encodingFailed
        }

        // Write to stdout with newline delimiter
        print(jsonString)
        fflush(stdout)
    }

    public func messages() -> AsyncStream<MCPRequest> {
        AsyncStream { continuation in
            self.messageContinuation = continuation

            // Read from stdin in a detached task
            Task.detached { [weak self] in
                guard let self = self else { return }

                while await self.isRunning {
                    guard let line = readLine() else {
                        break
                    }

                    // Skip empty lines
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty { continue }

                    // Parse JSON-RPC request
                    guard let data = trimmed.data(using: .utf8) else { continue }

                    do {
                        let request = try self.decoder.decode(MCPRequest.self, from: data)
                        continuation.yield(request)
                    } catch {
                        // Log parse error but continue processing
                        fputs("Failed to parse request: \(error)\n", stderr)
                    }
                }

                continuation.finish()
            }
        }
    }

    private var decoder_: JSONDecoder { decoder }
}

// MARK: - HTTP Transport

/// Transport implementation using HTTP with NWListener.
/// Used for cloud deployments where MCP is accessed via REST API.
public actor HTTPTransport: @preconcurrency MCPTransport {
    private let port: UInt16
    private var isRunning = false
    private var listener: NWListener?
    private var messageContinuation: AsyncStream<MCPRequest>.Continuation?
    private var pendingResponses: [RequestId: CheckedContinuation<Void, Never>] = [:]
    private var responseData: [RequestId: MCPResponse] = [:]

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(port: Int = 8080) {
        self.port = UInt16(port)
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    public func start() async throws {
        guard !isRunning else { return }

        let parameters = NWParameters.tcp
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw MCPTransportError.connectionFailed("Invalid port: \(port)")
        }

        do {
            listener = try NWListener(using: parameters, on: nwPort)
        } catch {
            throw MCPTransportError.connectionFailed("Failed to create listener: \(error)")
        }

        listener?.newConnectionHandler = { [weak self] connection in
            Task { [weak self] in
                await self?.handleConnection(connection)
            }
        }

        listener?.stateUpdateHandler = { [weak self] state in
            Task { [weak self] in
                await self?.handleListenerState(state)
            }
        }

        listener?.start(queue: .global())
        isRunning = true
        print("HTTPTransport: Started on port \(port)")
    }

    public func stop() async {
        guard isRunning else { return }
        listener?.cancel()
        listener = nil
        messageContinuation?.finish()
        isRunning = false
        print("HTTPTransport: Stopped")
    }

    public func send(_ response: MCPResponse) async throws {
        let id = response.id
        responseData[id] = response
        if let continuation = pendingResponses.removeValue(forKey: id) {
            continuation.resume()
        }
    }

    public func messages() -> AsyncStream<MCPRequest> {
        AsyncStream { continuation in
            self.messageContinuation = continuation
        }
    }

    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            print("HTTPTransport: Listener ready on port \(port)")
        case .failed(let error):
            print("HTTPTransport: Listener failed: \(error)")
        case .cancelled:
            print("HTTPTransport: Listener cancelled")
        default:
            break
        }
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global())

        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self, let data = data, !data.isEmpty else {
                connection.cancel()
                return
            }

            Task {
                await self.processHTTPRequest(data: data, connection: connection)
            }

            if isComplete || error != nil {
                connection.cancel()
            }
        }
    }

    private func processHTTPRequest(data: Data, connection: NWConnection) async {
        guard let requestString = String(data: data, encoding: .utf8) else {
            sendHTTPResponse(connection: connection, statusCode: 400, body: "Invalid request")
            return
        }

        let lines = requestString.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            sendHTTPResponse(connection: connection, statusCode: 400, body: "Malformed request")
            return
        }

        let parts = firstLine.split(separator: " ")
        guard parts.count >= 2, parts[0] == "POST" else {
            sendHTTPResponse(connection: connection, statusCode: 405, body: "Method not allowed")
            return
        }

        var bodyStartIndex = 0
        for (index, line) in lines.enumerated() {
            if line.isEmpty && index > 0 {
                bodyStartIndex = index + 1
                break
            }
        }

        guard bodyStartIndex < lines.count else {
            sendHTTPResponse(connection: connection, statusCode: 400, body: "Missing body")
            return
        }

        let bodyString = lines[bodyStartIndex...].joined(separator: "\r\n")
        guard let bodyData = bodyString.data(using: .utf8) else {
            sendHTTPResponse(connection: connection, statusCode: 400, body: "Invalid body encoding")
            return
        }

        do {
            let request = try decoder.decode(MCPRequest.self, from: bodyData)

            messageContinuation?.yield(request)

            let requestId = request.id
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                pendingResponses[requestId] = continuation
            }

            if let response = responseData.removeValue(forKey: requestId) {
                let respData = try encoder.encode(response)
                sendHTTPResponse(connection: connection, statusCode: 200, body: respData)
            } else {
                sendHTTPResponse(connection: connection, statusCode: 500, body: "No response generated".data(using: .utf8))
            }
        } catch {
            sendHTTPResponse(connection: connection, statusCode: 400, body: "Parse error: \(error)".data(using: .utf8))
        }
    }

    private nonisolated func sendHTTPResponse(connection: NWConnection, statusCode: Int, body: Data?) {
        let statusText: String
        switch statusCode {
        case 200: statusText = "OK"
        case 204: statusText = "No Content"
        case 400: statusText = "Bad Request"
        case 405: statusText = "Method Not Allowed"
        case 500: statusText = "Internal Server Error"
        default: statusText = "Unknown"
        }

        var response = "HTTP/1.1 \(statusCode) \(statusText)\r\n"
        response += "Content-Type: application/json\r\n"

        if let body = body {
            response += "Content-Length: \(body.count)\r\n"
            response += "\r\n"
            if let headerData = response.data(using: .utf8) {
                connection.send(content: headerData, completion: .contentProcessed({ _ in }))
                connection.send(content: body, completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            }
        } else {
            response += "Content-Length: 0\r\n\r\n"
            if let headerData = response.data(using: .utf8) {
                connection.send(content: headerData, completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            }
        }
    }

    private nonisolated func sendHTTPResponse(connection: NWConnection, statusCode: Int, body: String?) {
        sendHTTPResponse(connection: connection, statusCode: statusCode, body: body?.data(using: .utf8))
    }
}

// MARK: - WebSocket Transport

/// Transport implementation using WebSocket.
/// Used for real-time cloud connections.
public actor WebSocketTransport: @preconcurrency MCPTransport {
    private let url: URL
    private var isRunning = false
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    private var messageContinuation: AsyncStream<MCPRequest>.Continuation?
    
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(url: URL) {
        self.url = url
        self.session = URLSession(configuration: .default)
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    public func start() async throws {
        guard !isRunning else { return }
        let request = URLRequest(url: url)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        isRunning = true
        print("WebSocketTransport: Connected to \(url)")
        receiveMessages()
    }

    public func stop() async {
        guard isRunning else { return }
        isRunning = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        messageContinuation?.finish()
        print("WebSocketTransport: Stopped")
    }

    public func send(_ response: MCPResponse) async throws {
        guard isRunning, let task = webSocketTask else {
            throw MCPTransportError.disconnected
        }
        let data = try encoder.encode(response)
        guard let string = String(data: data, encoding: .utf8) else {
            throw MCPTransportError.encodingFailed
        }
        let message = URLSessionWebSocketTask.Message.string(string)
        try await task.send(message)
    }

    public func messages() -> AsyncStream<MCPRequest> {
        AsyncStream { continuation in
            self.messageContinuation = continuation
        }
    }

    private func receiveMessages() {
        Task { [weak self] in
            guard let self = self else { return }
            while await self.isRunning {
                do {
                    guard let task = await self.webSocketTask else { break }
                    let message = try await task.receive()
                    await self.handleMessage(message)
                } catch {
                    if await self.isRunning {
                        print("WebSocketTransport error: \(error)")
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        if await self.isRunning {
                            print("WebSocketTransport: Reconnecting...")
                            await self.reconnect()
                        }
                    }
                }
            }
        }
    }

    private func reconnect() async {
        webSocketTask?.cancel()
        let request = URLRequest(url: url)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8) else { return }
            do {
                let request = try decoder.decode(MCPRequest.self, from: data)
                messageContinuation?.yield(request)
            } catch {
                print("WebSocketTransport: Decode error (string): \(error)")
            }
        case .data(let data):
            do {
                let request = try decoder.decode(MCPRequest.self, from: data)
                messageContinuation?.yield(request)
            } catch {
                print("WebSocketTransport: Decode error (data): \(error)")
            }
        @unknown default:
            break
        }
    }
}

// MARK: - Transport Errors

/// Errors that can occur during transport operations
public enum MCPTransportError: Error, Sendable {
    case connectionFailed(String)
    case disconnected
    case encodingFailed
    case decodingFailed
    case timeout
    case notImplemented(String)

    public var localizedDescription: String {
        switch self {
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .disconnected: return "Transport disconnected"
        case .encodingFailed: return "Failed to encode message"
        case .decodingFailed: return "Failed to decode message"
        case .timeout: return "Transport operation timed out"
        case .notImplemented(let transport): return "\(transport) not yet implemented"
        }
    }
}

// MARK: - Transport Factory

/// Factory for creating transport instances
public struct MCPTransportFactory {
    /// Create a transport for the specified type
    public static func create(_ type: MCPTransportType, config: TransportConfig = .init()) -> any MCPTransport {
        switch type {
        case .stdio:
            return StdioTransport()
        case .http:
            return HTTPTransport(port: config.httpPort)
        case .websocket:
            return WebSocketTransport(url: config.websocketURL ?? URL(string: "ws://localhost:8080")!)
        case .unixSocket:
            // Fall back to stdio for now
            return StdioTransport()
        }
    }

    /// Transport configuration
    public struct TransportConfig {
        public var httpPort: Int
        public var websocketURL: URL?
        public var unixSocketPath: String?

        public init(
            httpPort: Int = 8080,
            websocketURL: URL? = nil,
            unixSocketPath: String? = nil
        ) {
            self.httpPort = httpPort
            self.websocketURL = websocketURL
            self.unixSocketPath = unixSocketPath
        }
    }
}
