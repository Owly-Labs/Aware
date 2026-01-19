//
//  WebSocketBridge.swift
//  AwareBridge
//
//  WebSocket server for real-time IPC between Breathe IDE and Aware apps.
//  Replaces file-based polling (50ms) with WebSocket (<5ms) for low-latency testing.
//

import Foundation
import NIO
import NIOCore
import NIOPosix
import NIOHTTP1
import NIOWebSocket

// MARK: - WebSocket Bridge

/// WebSocket server for Aware <-> Breathe IDE communication
@MainActor
public final class WebSocketBridge: @unchecked Sendable {
    // MARK: - Singleton

    public static let shared = WebSocketBridge()

    // MARK: - Configuration

    private let configuration: MCPConfiguration
    private var eventLoop: EventLoopGroup?
    private var server: Channel?
    private var connections: [WebSocketConnection] = []

    // MARK: - State

    private var isRunning = false
    private var eventBuffer: [MCPEvent] = []
    private var commandHandler: ((MCPCommand) async -> AwareMCPResult)?
    private var batchHandler: ((MCPBatch) async -> MCPBatchResult)?

    // MARK: - Initialization

    private init(configuration: MCPConfiguration = .breatheDefault) {
        self.configuration = configuration
    }

    // MARK: - Lifecycle

    /// Start WebSocket server
    public func start() async throws {
        guard !isRunning else { return }

        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.eventLoop = group

        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                let httpHandler = HTTPHandler()
                let wsUpgrader = NIOWebSocketServerUpgrader(
                    shouldUpgrade: { (channel: Channel, head: HTTPRequestHead) in
                        return channel.eventLoop.makeSucceededFuture(HTTPHeaders())
                    },
                    upgradePipelineHandler: { (channel: Channel, req: HTTPRequestHead) in
                        return channel.pipeline.addHandler(WebSocketHandler(bridge: self))
                    }
                )

                let config: NIOHTTPServerUpgradeConfiguration = (
                    upgraders: [wsUpgrader],
                    completionHandler: { _ in
                        channel.pipeline.removeHandler(httpHandler, promise: nil)
                    }
                )

                return channel.pipeline.configureHTTPServerPipeline(withServerUpgrade: config).flatMap {
                    channel.pipeline.addHandler(httpHandler)
                }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

        do {
            let channel = try await bootstrap.bind(host: configuration.host, port: configuration.port).get()
            self.server = channel
            self.isRunning = true
            print("✅ AwareBridge WebSocket server started on \(configuration.host):\(configuration.port)")
        } catch {
            print("❌ Failed to start WebSocket server: \(error)")
            throw error
        }
    }

    /// Stop WebSocket server
    public func stop() async {
        guard isRunning else { return }

        // Close all connections
        for connection in connections {
            connection.close()
        }
        connections.removeAll()

        // Close server
        do {
            try await server?.close().get()
        } catch {
            print("⚠️ WebSocketBridge: Error closing server: \(error.localizedDescription)")
        }
        server = nil

        // Shutdown event loop
        do {
            try await eventLoop?.shutdownGracefully()
        } catch {
            print("⚠️ WebSocketBridge: Error shutting down event loop: \(error.localizedDescription)")
        }
        eventLoop = nil

        isRunning = false
        print("🛑 AwareBridge WebSocket server stopped")
    }

    // MARK: - Connection Management

    func addConnection(_ ws: WebSocketConnection) {
        connections.append(ws)
        print("📡 WebSocket client connected (total: \(connections.count))")

        // Send ready event
        Task {
            await sendEvent(MCPEvent(type: .ready))
        }
    }

    func removeConnection(_ ws: WebSocketConnection) {
        connections.removeAll { $0 === ws }
        print("📡 WebSocket client disconnected (total: \(connections.count))")
    }

    // MARK: - Command Handling

    /// Register command handler
    public func onCommand(_ handler: @escaping (MCPCommand) async -> AwareMCPResult) {
        self.commandHandler = handler
    }

    /// Register batch handler
    public func onBatch(_ handler: @escaping (MCPBatch) async -> MCPBatchResult) {
        self.batchHandler = handler
    }

    /// Handle incoming command
    func handleCommand(_ command: MCPCommand, from ws: WebSocketConnection) async {
        guard let handler = commandHandler else {
            let error = AwareMCPError(code: "NO_HANDLER", message: "No command handler registered")
            let result = AwareMCPResult.failure(commandId: command.id, error: error)
            await sendResult(result, to: ws)
            return
        }

        let result = await handler(command)
        await sendResult(result, to: ws)
    }

    /// Handle incoming batch
    func handleBatch(_ batch: MCPBatch, from ws: WebSocketConnection) async {
        guard let handler = batchHandler else {
            let error = AwareMCPError(code: "NO_HANDLER", message: "No batch handler registered")
            let results = batch.commands.map { AwareMCPResult.failure(commandId: $0.id, error: error) }
            let batchResult = MCPBatchResult(batchId: batch.id, results: results)
            await sendBatchResult(batchResult, to: ws)
            return
        }

        let batchResult = await handler(batch)
        await sendBatchResult(batchResult, to: ws)
    }

    // MARK: - Event Broadcasting

    /// Send event to all connected clients
    public func sendEvent(_ event: MCPEvent) async {
        guard configuration.enableEvents else { return }

        // Add to buffer
        eventBuffer.append(event)
        if eventBuffer.count > configuration.eventBufferSize {
            eventBuffer.removeFirst()
        }

        // Broadcast to all connections
        let payload: Data
        do {
            payload = try JSONEncoder().encode(event)
        } catch {
            print("⚠️ WebSocketBridge: Failed to encode event: \(error.localizedDescription)")
            return
        }

        guard let payloadString = String(data: payload, encoding: .utf8) else {
            print("⚠️ WebSocketBridge: Failed to convert event payload to string")
            return
        }

        let wrapper: Data
        do {
            wrapper = try JSONSerialization.data(withJSONObject: ["type": "event", "payload": payloadString])
        } catch {
            print("⚠️ WebSocketBridge: Failed to create event wrapper: \(error.localizedDescription)")
            return
        }

        guard let text = String(data: wrapper, encoding: .utf8) else {
            print("⚠️ WebSocketBridge: Failed to convert event wrapper to string")
            return
        }

        for connection in connections {
            connection.send(text)
        }
    }

    /// Send result to specific connection
    func sendResult(_ result: AwareMCPResult, to ws: WebSocketConnection) async {
        let payload: Data
        do {
            payload = try JSONEncoder().encode(result)
        } catch {
            print("⚠️ WebSocketBridge: Failed to encode result: \(error.localizedDescription)")
            return
        }

        guard let payloadString = String(data: payload, encoding: .utf8) else {
            print("⚠️ WebSocketBridge: Failed to convert result payload to string")
            return
        }

        let wrapper: Data
        do {
            wrapper = try JSONSerialization.data(withJSONObject: ["type": "result", "payload": payloadString])
        } catch {
            print("⚠️ WebSocketBridge: Failed to create result wrapper: \(error.localizedDescription)")
            return
        }

        guard let text = String(data: wrapper, encoding: .utf8) else {
            print("⚠️ WebSocketBridge: Failed to convert result wrapper to string")
            return
        }

        ws.send(text)
    }

    /// Send batch result to specific connection
    func sendBatchResult(_ result: MCPBatchResult, to ws: WebSocketConnection) async {
        let payload: Data
        do {
            payload = try JSONEncoder().encode(result)
        } catch {
            print("⚠️ WebSocketBridge: Failed to encode batch result: \(error.localizedDescription)")
            return
        }

        guard let payloadString = String(data: payload, encoding: .utf8) else {
            print("⚠️ WebSocketBridge: Failed to convert batch result payload to string")
            return
        }

        let wrapper: Data
        do {
            wrapper = try JSONSerialization.data(withJSONObject: ["type": "batch_result", "payload": payloadString])
        } catch {
            print("⚠️ WebSocketBridge: Failed to create batch result wrapper: \(error.localizedDescription)")
            return
        }

        guard let text = String(data: wrapper, encoding: .utf8) else {
            print("⚠️ WebSocketBridge: Failed to convert batch result wrapper to string")
            return
        }

        ws.send(text)
    }

    // MARK: - Health

    public var isConnected: Bool {
        !connections.isEmpty
    }

    public var connectionCount: Int {
        connections.count
    }
}

// MARK: - HTTP Handler

private final class HTTPHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)

        switch reqPart {
        case .head(let head):
            if head.uri == "/health" {
                sendHealthCheck(context: context)
            } else {
                send404(context: context)
            }
        case .body, .end:
            break
        }
    }

    private func sendHealthCheck(context: ChannelHandlerContext) {
        let response = """
        {"status":"ok","service":"AwareBridge","version":"1.0.0"}
        """
        sendResponse(context: context, status: .ok, body: response)
    }

    private func send404(context: ChannelHandlerContext) {
        sendResponse(context: context, status: .notFound, body: "Not Found")
    }

    private func sendResponse(context: ChannelHandlerContext, status: HTTPResponseStatus, body: String) {
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "Content-Length", value: "\(body.utf8.count)")

        let head = HTTPResponseHead(version: .http1_1, status: status, headers: headers)
        context.write(self.wrapOutboundOut(.head(head)), promise: nil)

        var buffer = context.channel.allocator.buffer(capacity: body.utf8.count)
        buffer.writeString(body)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)

        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
}

// MARK: - WebSocket Connection Wrapper

final class WebSocketConnection: @unchecked Sendable {
    private let channel: Channel

    init(channel: Channel) {
        self.channel = channel
    }

    func send(_ text: String) {
        var buffer = channel.allocator.buffer(capacity: text.utf8.count)
        buffer.writeString(text)
        let frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
        channel.writeAndFlush(frame, promise: nil)
    }

    func close() {
        let frame = WebSocketFrame(fin: true, opcode: .connectionClose, data: ByteBuffer())
        _ = channel.writeAndFlush(frame).flatMap {
            self.channel.close()
        }
    }
}

// MARK: - WebSocket Handler

private final class WebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame

    private let bridge: WebSocketBridge
    private var webSocket: WebSocketConnection?

    init(bridge: WebSocketBridge) {
        self.bridge = bridge
    }

    func handlerAdded(context: ChannelHandlerContext) {
        let ws = WebSocketConnection(channel: context.channel)
        self.webSocket = ws

        Task { @MainActor in
            bridge.addConnection(ws)
        }
    }

    func handlerRemoved(context: ChannelHandlerContext) {
        if let ws = webSocket {
            Task { @MainActor in
                bridge.removeConnection(ws)
            }
        }
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)

        switch frame.opcode {
        case .text:
            var data = frame.unmaskedData
            guard let text = data.readString(length: data.readableBytes) else { return }
            handleMessage(text, context: context)

        case .connectionClose:
            context.close(promise: nil)

        case .ping:
            let pongFrame = WebSocketFrame(fin: true, opcode: .pong, data: frame.data)
            context.writeAndFlush(self.wrapOutboundOut(pongFrame), promise: nil)

        default:
            break
        }
    }

    private func handleMessage(_ text: String, context: ChannelHandlerContext) {
        guard let data = text.data(using: .utf8) else {
            print("⚠️ WebSocketHandler: Failed to convert message to data")
            return
        }

        let json: [String: Any]
        do {
            guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("⚠️ WebSocketHandler: Invalid JSON format")
                return
            }
            json = parsed
        } catch {
            print("⚠️ WebSocketHandler: Failed to parse JSON: \(error.localizedDescription)")
            return
        }

        guard let type = json["type"] as? String,
              let ws = webSocket else { return }

        Task { @MainActor in
            switch type {
            case "command":
                guard let payload = json["payload"] else {
                    print("⚠️ WebSocketHandler: Missing command payload")
                    return
                }

                let commandData: Data
                do {
                    commandData = try JSONSerialization.data(withJSONObject: payload)
                } catch {
                    print("⚠️ WebSocketHandler: Failed to serialize command payload: \(error.localizedDescription)")
                    return
                }

                let command: MCPCommand
                do {
                    command = try JSONDecoder().decode(MCPCommand.self, from: commandData)
                } catch {
                    print("⚠️ WebSocketHandler: Failed to decode command: \(error.localizedDescription)")
                    return
                }

                await bridge.handleCommand(command, from: ws)

            case "batch":
                guard let payload = json["payload"] else {
                    print("⚠️ WebSocketHandler: Missing batch payload")
                    return
                }

                let batchData: Data
                do {
                    batchData = try JSONSerialization.data(withJSONObject: payload)
                } catch {
                    print("⚠️ WebSocketHandler: Failed to serialize batch payload: \(error.localizedDescription)")
                    return
                }

                let batch: MCPBatch
                do {
                    batch = try JSONDecoder().decode(MCPBatch.self, from: batchData)
                } catch {
                    print("⚠️ WebSocketHandler: Failed to decode batch: \(error.localizedDescription)")
                    return
                }

                await bridge.handleBatch(batch, from: ws)

            default:
                break
            }
        }
    }
}
