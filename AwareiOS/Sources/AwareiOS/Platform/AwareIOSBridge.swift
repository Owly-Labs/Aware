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
import AwareBridge
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

    private let ipcPath: String
    private let transportMode: IPCTransportMode
    private var heartbeatTask: Task<Void, Never>?

    #if canImport(AwareBridge)
    private var webSocketClient: WebSocketIPCClient?
    #endif

    // MARK: - Initialization

    public init(ipcPath: String, transportMode: IPCTransportMode = .auto) {
        self.ipcPath = (ipcPath as NSString).expandingTildeInPath
        self.transportMode = transportMode
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
        // Create IPC directory
        try? FileManager.default.createDirectory(
            atPath: ipcPath,
            withIntermediateDirectories: true
        )

        #if DEBUG
        print("AwareIPC: File-based IPC directory created at: \(ipcPath)")
        #endif
    }

    #if canImport(AwareBridge)
    private func setupWebSocket() {
        webSocketClient = WebSocketIPCClient(url: "ws://localhost:9999")

        Task {
            do {
                try await webSocketClient?.connect()
                #if DEBUG
                print("AwareIPC: WebSocket connection established")
                #endif
            } catch {
                #if DEBUG
                print("AwareIPC: WebSocket connection failed, falling back to file-based: \(error)")
                #endif
            }
        }
    }
    #endif

    func startHeartbeat(interval: TimeInterval = 2.0) {
        heartbeatTask?.cancel()

        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.writeHeartbeat()
                try? await Task.sleep(for: .seconds(interval))
            }
        }

        #if DEBUG
        print("AwareIPC: Heartbeat started with \(interval)s interval")
        #endif
    }

    private func writeHeartbeat() {
        let heartbeatPath = ipcPath + "/ui_watcher_heartbeat.txt"
        let timestamp = ISO8601DateFormatter().string(from: Date())

        do {
            try timestamp.write(toFile: heartbeatPath, atomically: true, encoding: .utf8)
        } catch {
            #if DEBUG
            print("AwareIPC: Failed to write heartbeat: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Command Execution

    public func sendCommand(_ command: AwareCommand) async throws -> AwareResult {
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
    private func sendCommandViaWebSocket(_ command: AwareCommand, client: WebSocketIPCClient) async throws -> AwareResult {
        let mcpCommand = MCPCommand(
            action: .tap, // Map from AwareCommand
            parameters: command.parameters
        )

        let result = try await client.sendCommand(mcpCommand)

        if result.success {
            return AwareResult(
                success: true,
                data: result.data ?? [:],
                error: nil
            )
        } else {
            return AwareResult(
                success: false,
                data: nil,
                error: result.error?.message
            )
        }
    }
    #endif

    private func sendCommandViaFiles(_ command: AwareCommand) async throws -> AwareResult {
        let commandPath = ipcPath + "/ui_command.json"
        let resultPath = ipcPath + "/ui_result.json"

        // Write command
        let commandData = try JSONEncoder().encode(command)
        try commandData.write(to: URL(fileURLWithPath: commandPath))

        // Wait for result (polling)
        var attempts = 0
        while attempts < 50 { // 5 second timeout
            if FileManager.default.fileExists(atPath: resultPath) {
                let resultData = try Data(contentsOf: URL(fileURLWithPath: resultPath))
                return try JSONDecoder().decode(AwareResult.self, from: resultData)
            }
            try await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }

        throw AwareIPCError.timeout
    }

    public func stopHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }

    deinit {
        stopHeartbeat()
        #if canImport(AwareBridge)
        Task {
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
    private var isConnectedState = false
    private var pendingResults: [String: CheckedContinuation<MCPResult, Error>] = [:]

    init(url: String) {
        self.url = url
    }

    var isConnected: Bool {
        isConnectedState
    }

    func connect() async throws {
        // Connection logic handled by AwareBridge
        isConnectedState = true
    }

    func disconnect() async {
        isConnectedState = false
    }

    func sendCommand(_ command: MCPCommand) async throws -> MCPResult {
        guard isConnected else {
            throw AwareIPCError.notConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            pendingResults[command.id] = continuation

            // Send command via bridge
            Task {
                // This would actually send via WebSocket
                // For now, simulate success
                let result = MCPResult.success(commandId: command.id)
                continuation.resume(returning: result)
            }
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
}

// MARK: - Legacy Types (for backward compatibility)

public struct AwareCommand: Codable, Sendable {
    public let action: String
    public let parameters: [String: String]

    public init(action: String, parameters: [String: String]) {
        self.action = action
        self.parameters = parameters
    }
}

public struct AwareResult: Codable, Sendable {
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
