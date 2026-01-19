//
//  AwareMacOSBridge.swift
//  AwareMacOS
//
//  IPC bridge for macOS Aware framework.
//  Supports file-based and WebSocket communication for Breathe IDE integration.
//

#if os(macOS)
import Foundation
import AwareCore

// MARK: - IPC Transport Mode

/// Transport mode for IPC communication
public enum IPCTransportMode: String, Sendable {
    case fileBased = "file"      // File-based IPC (~50ms latency)
    case webSocket = "websocket" // WebSocket IPC (<5ms latency)
    case auto = "auto"           // Auto-detect best available transport
}

// MARK: - IPC Service

/// IPC service for macOS Aware framework
/// Enables communication with external tools (e.g., Breathe IDE, MCP servers)
@MainActor
public final class AwareMacOSIPCService {
    public static let shared = AwareMacOSIPCService()

    // MARK: - State

    private var ipcPath: String?
    private var transportMode: IPCTransportMode = .auto
    private var isConfigured = false
    private var heartbeatTimer: Timer?
    private var lastHeartbeat: Date?

    private init() {}

    // MARK: - Configuration

    /// Configure IPC service
    /// - Parameters:
    ///   - ipcPath: Base directory for IPC files (e.g., ~/.aware)
    ///   - mode: Transport mode (.auto, .fileBased, .webSocket)
    ///   - heartbeatInterval: Heartbeat interval in seconds (default: 2.0)
    public func configure(
        ipcPath: String,
        mode: IPCTransportMode = .auto,
        heartbeatInterval: TimeInterval = 2.0
    ) {
        guard !isConfigured else {
            #if DEBUG
            print("AwareMacOS IPC: Already configured")
            #endif
            return
        }

        self.ipcPath = expandPath(ipcPath)
        self.transportMode = mode
        self.isConfigured = true

        // Create IPC directory if needed
        createIPCDirectory()

        // Start heartbeat
        startHeartbeat(interval: heartbeatInterval)

        #if DEBUG
        print("AwareMacOS IPC: Configured at '\(self.ipcPath!)' with mode '\(mode.rawValue)'")
        #endif
    }

    /// Expand path with ~ and environment variables
    private func expandPath(_ path: String) -> String {
        let expanded = NSString(string: path).expandingTildeInPath
        return expanded
    }

    /// Create IPC directory structure
    private func createIPCDirectory() {
        guard let ipcPath = ipcPath else { return }

        let fileManager = FileManager.default

        do {
            try fileManager.createDirectory(
                atPath: ipcPath,
                withIntermediateDirectories: true,
                attributes: nil
            )

            #if DEBUG
            print("AwareMacOS IPC: Created directory at '\(ipcPath)'")
            #endif
        } catch {
            #if DEBUG
            print("AwareMacOS IPC: Failed to create directory: \(error)")
            #endif
        }
    }

    // MARK: - Heartbeat

    /// Start heartbeat monitoring
    /// - Parameter interval: Heartbeat interval in seconds
    public func startHeartbeat(interval: TimeInterval = 2.0) {
        stopHeartbeat()

        heartbeatTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.sendHeartbeat()
            }
        }

        #if DEBUG
        print("AwareMacOS IPC: Started heartbeat (interval: \(interval)s)")
        #endif
    }

    /// Stop heartbeat monitoring
    public func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil

        #if DEBUG
        print("AwareMacOS IPC: Stopped heartbeat")
        #endif
    }

    /// Send heartbeat signal
    private func sendHeartbeat() async {
        guard let ipcPath = ipcPath else { return }

        let heartbeatPath = "\(ipcPath)/heartbeat.txt"
        let timestamp = ISO8601DateFormatter().string(from: Date())

        do {
            try timestamp.write(toFile: heartbeatPath, atomically: true, encoding: .utf8)
            lastHeartbeat = Date()

            #if DEBUG
            // print("AwareMacOS IPC: Heartbeat sent")
            #endif
        } catch {
            #if DEBUG
            print("AwareMacOS IPC: Failed to send heartbeat: \(error)")
            #endif
        }
    }

    // MARK: - Command Handling

    /// Send command via IPC
    /// - Parameters:
    ///   - command: Aware command to send
    /// - Returns: Command result
    public func sendCommand(_ command: AwareMacOSCommand) async throws -> AwareCommandResult {
        guard isConfigured, let ipcPath = ipcPath else {
            throw IPCError.notConfigured
        }

        switch transportMode {
        case .fileBased:
            return try await sendCommandViaFiles(command, ipcPath: ipcPath)

        case .webSocket:
            return try await sendCommandViaWebSocket(command)

        case .auto:
            // Try WebSocket first (fast), fall back to files if unavailable
            do {
                return try await sendCommandViaWebSocket(command)
            } catch {
                #if DEBUG
                print("AwareMacOS IPC: WebSocket unavailable, falling back to file-based")
                #endif
                return try await sendCommandViaFiles(command, ipcPath: ipcPath)
            }
        }
    }

    /// Send command via file-based IPC (~50ms latency)
    private func sendCommandViaFiles(_ command: AwareMacOSCommand, ipcPath: String) async throws -> AwareCommandResult {
        let commandPath = "\(ipcPath)/command.json"
        let resultPath = "\(ipcPath)/result.json"

        // Encode command
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let commandData = try encoder.encode(command)

        // Write command file
        try commandData.write(to: URL(fileURLWithPath: commandPath))

        #if DEBUG
        print("AwareMacOS IPC: Sent command via file: \(command.action)")
        #endif

        // Wait for result file (with timeout)
        let startTime = Date()
        let timeout: TimeInterval = 5.0

        while Date().timeIntervalSince(startTime) < timeout {
            if FileManager.default.fileExists(atPath: resultPath) {
                // Read result
                let resultData = try Data(contentsOf: URL(fileURLWithPath: resultPath))
                let decoder = JSONDecoder()
                let result = try decoder.decode(AwareCommandResult.self, from: resultData)

                // Clean up result file
                try? FileManager.default.removeItem(atPath: resultPath)

                #if DEBUG
                print("AwareMacOS IPC: Received result via file: \(result.success)")
                #endif

                return result
            }

            // Wait 10ms before checking again
            try await Task.sleep(for: .milliseconds(10))
        }

        throw IPCError.timeout
    }

    /// Send command via WebSocket IPC (<5ms latency)
    private func sendCommandViaWebSocket(_ command: AwareMacOSCommand) async throws -> AwareCommandResult {
        // TODO: Implement WebSocket transport
        // This requires URLSession WebSocket support or a WebSocket library
        throw IPCError.notImplemented("WebSocket transport not yet implemented")
    }

    // MARK: - Snapshot Broadcasting

    /// Broadcast snapshot via IPC
    /// - Parameter snapshot: Snapshot to broadcast
    public func broadcastSnapshot(_ snapshot: AwareSnapshot) async {
        guard isConfigured, let ipcPath = ipcPath else { return }

        let snapshotPath = "\(ipcPath)/snapshot.json"

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let snapshotData = try encoder.encode(snapshot)
            try snapshotData.write(to: URL(fileURLWithPath: snapshotPath))

            #if DEBUG
            // print("AwareMacOS IPC: Broadcasted snapshot (\(snapshot.viewCount) views)")
            #endif
        } catch {
            #if DEBUG
            print("AwareMacOS IPC: Failed to broadcast snapshot: \(error)")
            #endif
        }
    }

    // MARK: - Status

    /// Get IPC service status
    public var status: IPCStatus {
        return IPCStatus(
            isConfigured: isConfigured,
            ipcPath: ipcPath,
            transportMode: transportMode,
            lastHeartbeat: lastHeartbeat
        )
    }
}

// MARK: - IPC Status

/// IPC service status
public struct IPCStatus: Sendable {
    public let isConfigured: Bool
    public let ipcPath: String?
    public let transportMode: IPCTransportMode
    public let lastHeartbeat: Date?

    public var isHealthy: Bool {
        guard isConfigured else { return false }
        guard let lastHeartbeat = lastHeartbeat else { return false }

        // Healthy if heartbeat within last 10 seconds
        return Date().timeIntervalSince(lastHeartbeat) < 10.0
    }
}

// MARK: - IPC Errors

/// IPC-specific errors
public enum IPCError: Error, LocalizedError {
    case notConfigured
    case timeout
    case notImplemented(String)
    case encodingFailed
    case decodingFailed
    case fileError(String)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "IPC service not configured. Call configure() first."
        case .timeout:
            return "IPC operation timed out"
        case .notImplemented(let feature):
            return "IPC feature not implemented: \(feature)"
        case .encodingFailed:
            return "Failed to encode IPC message"
        case .decodingFailed:
            return "Failed to decode IPC message"
        case .fileError(let message):
            return "File error: \(message)"
        }
    }
}

// MARK: - Aware Command & Result Types

/// Command sent via IPC
public struct AwareMacOSCommand: Codable, Sendable {
    public let id: String
    public let action: String
    public let parameters: [String: String]
    public let timestamp: Date

    public init(id: String = UUID().uuidString, action: String, parameters: [String: String] = [:]) {
        self.id = id
        self.action = action
        self.parameters = parameters
        self.timestamp = Date()
    }
}

/// Result received via IPC
public struct AwareCommandResult: Codable, Sendable {
    public let commandId: String
    public let success: Bool
    public let message: String
    public let data: [String: String]?
    public let timestamp: Date

    public init(commandId: String, success: Bool, message: String, data: [String: String]? = nil) {
        self.commandId = commandId
        self.success = success
        self.message = message
        self.data = data
        self.timestamp = Date()
    }
}

// MARK: - Public Configuration Extension

public extension Aware {
    /// Configure Aware for macOS with IPC support
    /// - Parameters:
    ///   - ipcPath: IPC directory path (default: ~/.aware)
    ///   - mode: Transport mode (.auto, .fileBased, .webSocket)
    static func configureForMacOS(ipcPath: String? = nil, mode: IPCTransportMode = .auto) {
        // Configure platform
        AwareMacOSPlatform.shared.configure(options: [:])

        // Configure IPC if path provided
        if let ipcPath = ipcPath {
            AwareMacOSIPCService.shared.configure(ipcPath: ipcPath, mode: mode)
        }

        #if DEBUG
        print("Aware: Configured for macOS with IPC support")
        #endif
    }
}

#endif // os(macOS)
