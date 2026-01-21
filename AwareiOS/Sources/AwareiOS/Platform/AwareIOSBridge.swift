//
//  AwareIOSBridge.swift
//  AwareiOS
//
//  Unified IPC service for Breathe IDE integration.
//  Supports both file-based IPC (legacy, 50ms) and WebSocket IPC (<5ms).
//

#if os(iOS)
import Foundation
import AwareCore

#if canImport(AwareBridge)
#endif

// MARK: - IPC Service

/// IPC transport mode
public enum IPCTransportMode {
    case fileBased          // Legacy file polling (50ms latency)
    case webSocket          // Real-time WebSocket (<5ms latency)
    case auto               // Auto-detect (prefer WebSocket if available)
}

@MainActor
public final class AwareIPCService {
    // MARK: - Configuration

    private var ipcPath: String  // var to allow fallback path updates
    private let transportMode: IPCTransportMode
    private let config: AwareIOSConfiguration
    nonisolated(unsafe) private var heartbeatTask: Task<Void, Never>?

    #if canImport(AwareBridge)
    private var webSocketClient: WebSocketIPCClient?
    #endif

    // MARK: - Initialization

    public init(ipcPath: String, transportMode: IPCTransportMode = .auto) {
        // Legacy initializer for backward compatibility
        self.config = AwareIOSConfiguration(
            ipcPath: ipcPath,
            transportMode: transportMode,
            webSocketHost: "localhost",
            webSocketPort: 9999,
            webSocketTimeout: 5.0,
            heartbeatInterval: 2.0,
            heartbeatEnabled: true,
            commandPollInterval: 100,
            commandTimeoutAttempts: 50
        )
        self.ipcPath = (ipcPath as NSString).expandingTildeInPath
        self.transportMode = transportMode
        setupIPC()
    }

    public init(config: AwareIOSConfiguration) {
        self.config = config
        self.ipcPath = (config.ipcPath as NSString).expandingTildeInPath
        self.transportMode = config.transportMode
        setupIPC()
    }

    private func setupIPC() {
        // Always set up file-based IPC for fallback
        setupFileBased()

        // Try to set up WebSocket if requested
        #if canImport(AwareBridge)
        if case .webSocket = transportMode {
            setupWebSocket()
        } else if case .auto = transportMode {
            // Try WebSocket, fallback to file-based
            setupWebSocket()
        }
        #endif
    }

    // MARK: - Setup

    private func setupFileBased() {
        // Create IPC directory with error recovery
        do {
            try FileManager.default.createDirectory(
                atPath: ipcPath,
                withIntermediateDirectories: true
            )
            AwareLog.ipc.info("File-based IPC directory created at: \(ipcPath)")
        } catch {
            // Recovery: Use temp directory as fallback
            let fallbackPath = NSTemporaryDirectory() + "aware-ipc"
            AwareLog.ipc.error("Failed to create IPC directory at \(ipcPath): \(error.localizedDescription)")
            AwareLog.ipc.warning("Falling back to temp directory: \(fallbackPath)")

            // Update ipcPath to use fallback
            self.ipcPath = fallbackPath

            // Try creating fallback directory
            do {
                try FileManager.default.createDirectory(
                    atPath: fallbackPath,
                    withIntermediateDirectories: true
                )
                AwareLog.ipc.info("Fallback IPC directory created successfully")
            } catch {
                AwareLog.ipc.fault("Failed to create fallback IPC directory: \(error.localizedDescription)")
                // Continue anyway - operations will fail but won't crash
            }
        }
    }

    #if canImport(AwareBridge)
    private func setupWebSocket() {
        webSocketClient = WebSocketIPCClient(url: config.webSocketURL)

        Task { [webSocketClient] in
            do {
                try await webSocketClient?.connect()
                AwareLog.ipc.info("WebSocket connection established at \(config.webSocketURL)")
            } catch {
                AwareLog.ipc.warning("WebSocket connection failed, falling back to file-based: \(error.localizedDescription)")
                // Non-fatal: file-based IPC will be used as fallback
            }
        }
    }
    #endif

    func startHeartbeat(interval: TimeInterval = 2.0) {
        heartbeatTask?.cancel()

        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.writeHeartbeat()

                do {
                    try await Task.sleep(for: .seconds(interval))
                } catch {
                    // Only log if not cancelled (expected during teardown)
                    if !Task.isCancelled {
                        AwareLog.ipc.warning("Heartbeat sleep interrupted: \(error.localizedDescription)")
                    }
                    break
                }
            }
            AwareLog.ipc.debug("Heartbeat task stopped")
        }

        AwareLog.ipc.info("Heartbeat started with \(interval)s interval")
    }

    private func writeHeartbeat() {
        let heartbeatPath = ipcPath + "/ui_watcher_heartbeat.txt"
        let timestamp = ISO8601DateFormatter().string(from: Date())

        do {
            try timestamp.write(toFile: heartbeatPath, atomically: true, encoding: .utf8)
        } catch {
            AwareLog.ipc.warning("Failed to write heartbeat: \(error.localizedDescription)")
            // Non-fatal: heartbeat is for monitoring, not critical functionality
        }
    }

    // MARK: - Command Execution

    public func sendCommand(_ command: AwareIOSCommand) async throws -> AwareIOSResult {
        // Try WebSocket first if available
        #if canImport(AwareBridge)
        if let webSocketClient = webSocketClient, webSocketClient.isConnected {
            return try await sendCommandViaWebSocket(command, client: webSocketClient)
        }
        #endif

        // Fallback to file-based IPC
        return try await sendCommandViaFiles(command)
    }

    #if canImport(AwareBridge)
    private func sendCommandViaWebSocket(_ command: AwareIOSCommand, client: WebSocketIPCClient) async throws -> AwareIOSResult {
        let mcpCommand = MCPCommand(
            action: .tap, // Map from AwareCommand
            parameters: command.parameters
        )

        let result = try await client.sendCommand(mcpCommand)

        if result.success {
            return AwareIOSResult(
                success: true,
                data: result.data ?? [:],
                error: nil
            )
        } else {
            return AwareIOSResult(
                success: false,
                data: nil,
                error: result.error?.message
            )
        }
    }
    #endif

    private func sendCommandViaFiles(_ command: AwareIOSCommand) async throws -> AwareIOSResult {
        let commandPath = ipcPath + "/ui_command.json"
        let resultPath = ipcPath + "/ui_result.json"

        // Write command
        let commandData = try JSONEncoder().encode(command)
        try commandData.write(to: URL(fileURLWithPath: commandPath))

        // Wait for result (polling with configurable timeout)
        var attempts = 0
        let maxAttempts = config.commandTimeoutAttempts
        while attempts < maxAttempts {
            if FileManager.default.fileExists(atPath: resultPath) {
                let resultData = try Data(contentsOf: URL(fileURLWithPath: resultPath))
                return try JSONDecoder().decode(AwareIOSResult.self, from: resultData)
            }
            try await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }

        throw AwareIPCError.timeout
    }

    public func stopHeartbeat() {
        heartbeatTask?.cancel()
    }

    deinit {
        // Cancel heartbeat task directly in deinit (can't call async methods)
        heartbeatTask?.cancel()
        #if canImport(AwareBridge)
        Task { [webSocketClient] in
            await webSocketClient?.disconnect()
        }
        #endif
    }
}

// MARK: - WebSocket IPC Client

#if canImport(AwareBridge)
@MainActor
private final class WebSocketIPCClient {
    private let url: String
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var isConnectedState = false
    private var pendingResults: [String: CheckedContinuation<AwareMCPResult, Error>] = [:]
    private var receiveTask: Task<Void, Never>?

    init(url: String) {
        self.url = url
    }

    var isConnected: Bool {
        isConnectedState
    }

    func connect() async throws {
        guard let url = URL(string: url) else {
            throw AwareIPCError.invalidURL
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0

        session = URLSession(configuration: config)
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()

        // Wait for connection (2 second timeout with 100ms polling)
        var attempts = 0
        while attempts < 20 {
            if webSocketTask?.state == .running {
                isConnectedState = true
                startReceiving()
                AwareLog.ipc.debug("WebSocket client connected successfully")
                return
            }
            try await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }

        throw AwareIPCError.connectionTimeout
    }

    func disconnect() async {
        receiveTask?.cancel()
        receiveTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil
        isConnectedState = false
        AwareLog.ipc.debug("WebSocket client disconnected")
    }

    func sendCommand(_ command: MCPCommand) async throws -> AwareMCPResult {
        guard isConnected else {
            throw AwareIPCError.notConnected
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(command)

        let message = URLSessionWebSocketTask.Message.data(data)
        try await webSocketTask?.send(message)

        return try await withCheckedThrowingContinuation { continuation in
            pendingResults[command.id] = continuation

            // Timeout after 30 seconds
            Task { [weak self, command] in
                try? await Task.sleep(for: .seconds(30))
                if let pending = await self?.pendingResults.removeValue(forKey: command.id) {
                    pending.resume(throwing: AwareIPCError.timeout)
                }
            }
        }
    }

    private func startReceiving() {
        receiveTask = Task { [weak self] in
            while !Task.isCancelled, let self = self, self.isConnectedState {
                do {
                    let message = try await self.webSocketTask?.receive()
                    await self.handleMessage(message)
                } catch {
                    if !Task.isCancelled {
                        AwareLog.ipc.error("WebSocket receive error: \(error.localizedDescription)")
                        await self.disconnect()
                    }
                    break
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message?) async {
        guard let message = message else { return }

        switch message {
        case .data(let data):
            await handleResultData(data)
        case .string(let text):
            guard let data = text.data(using: .utf8) else { return }
            await handleResultData(data)
        @unknown default:
            AwareLog.ipc.warning("Unknown WebSocket message type received")
        }
    }

    private func handleResultData(_ data: Data) async {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(AwareMCPResult.self, from: data)

            if let continuation = pendingResults.removeValue(forKey: result.commandId) {
                continuation.resume(returning: result)
            }
        } catch {
            AwareLog.ipc.error("Failed to decode WebSocket result: \(error.localizedDescription)")
        }
    }
}
#endif

// MARK: - IPC Errors

public enum AwareIPCError: Error {
    case timeout
    case encodingFailed
    case decodingFailed
    case notConnected
    case invalidURL            // NEW: Invalid WebSocket URL
    case connectionTimeout     // NEW: WebSocket connection timeout
    case directoryCreationFailed(path: String, underlying: Error)  // NEW: IPC directory creation failed
    case heartbeatFailed(underlying: Error)  // NEW: Heartbeat write failed

    /// Human-readable error description
    public var localizedDescription: String {
        switch self {
        case .timeout:
            return "IPC command timed out after waiting for response"
        case .encodingFailed:
            return "Failed to encode command data"
        case .decodingFailed:
            return "Failed to decode result data"
        case .notConnected:
            return "WebSocket is not connected"
        case .invalidURL:
            return "Invalid WebSocket URL provided"
        case .connectionTimeout:
            return "WebSocket connection attempt timed out"
        case .directoryCreationFailed(let path, let underlying):
            return "Failed to create IPC directory at '\(path)': \(underlying.localizedDescription)"
        case .heartbeatFailed(let underlying):
            return "Failed to write heartbeat: \(underlying.localizedDescription)"
        }
    }
}

// MARK: - Legacy Types (for backward compatibility)

public struct AwareIOSCommand: Codable, Sendable {
    public let action: String
    public let parameters: [String: String]

    public init(action: String, parameters: [String: String]) {
        self.action = action
        self.parameters = parameters
    }
}

public struct AwareIOSResult: Codable, Sendable {
    public let success: Bool
    public let data: [String: String]?
    public let error: String?

    public init(success: Bool, data: [String: String]?, error: String?) {
        self.success = success
        self.data = data
        self.error = error
    }
}

#endif // os(iOS)
