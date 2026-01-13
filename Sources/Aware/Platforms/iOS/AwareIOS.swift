//
//  AwareIOS.swift
//  Aware
//
//  Created by AetherSing Team
//  Integration of AetherSing's UIAware features into Aware framework
//
//  Adds iOS-specific capabilities:
//  - Direct action callbacks for ghost UI testing
//  - iOS SwiftUI modifier enhancements
//  - IPC communication protocol
//  - Assertion system for testing
//

#if os(iOS)
import UIKit
import SwiftUI

// MARK: - iOS Platform Extensions

public extension Aware {
    /// Configure Aware for iOS platform
    /// Sets up iOS-specific features and optimizations
    public static func configureForIOS(ipcPath: String = "~/.aware") {
        AwareIOSPlatform.shared.configure(ipcPath: ipcPath)

        #if DEBUG
        Logger.shared.info("Aware", "Configured for iOS platform")
        #endif
    }
}

// MARK: - iOS Platform Manager

@MainActor
final class AwareIOSPlatform {
    static let shared = AwareIOSPlatform()

    private var ipcService: AwareIPCService?
    private var isConfigured = false

    private init() {}

    func configure(ipcPath: String) {
        guard !isConfigured else { return }

        // Initialize IPC service
        ipcService = AwareIPCService(ipcPath: ipcPath)
        ipcService?.startHeartbeat()

        isConfigured = true

        #if DEBUG
        Logger.shared.info("AwareIOS", "iOS platform configured with IPC path: \(ipcPath)")
        #endif
    }

    // MARK: - Direct Action Callbacks

    private var actionCallbacks: [String: @MainActor () async -> Void] = [:]

    /// Register a direct action callback for ghost UI testing
    /// - Parameters:
    ///   - viewId: The view identifier
    ///   - callback: Action to execute when tapped
    public func registerActionCallback(
        _ viewId: String,
        callback: @escaping @MainActor () async -> Void
    ) {
        actionCallbacks[viewId] = callback

        #if DEBUG
        Logger.shared.debug("AwareIOS", "Registered action callback for view: \(viewId)")
        #endif
    }

    /// Execute direct action for ghost UI testing
    /// - Parameter viewId: The view identifier to tap
    /// - Returns: True if action was executed successfully
    public func tapDirect(_ viewId: String) async -> Bool {
        guard let callback = actionCallbacks[viewId] else {
            #if DEBUG
            Logger.shared.warn("AwareIOS", "No action callback registered for view: \(viewId)")
            #endif
            return false
        }

        #if DEBUG
        Logger.shared.debug("AwareIOS", "Executing direct tap for view: \(viewId)")
        #endif

        await callback()
        return true
    }

    /// Get registered view IDs with action callbacks
    public var actionableViewIds: [String] {
        Array(actionCallbacks.keys)
    }
}

// MARK: - IPC Service

@MainActor
final class AwareIPCService {
    private let ipcPath: String
    private var heartbeatTask: Task<Void, Never>?

    init(ipcPath: String) {
        self.ipcPath = (ipcPath as NSString).expandingTildeInPath
        setupIPC()
    }

    private func setupIPC() {
        // Create IPC directory
        try? FileManager.default.createDirectory(
            atPath: ipcPath,
            withIntermediateDirectories: true
        )

        #if DEBUG
        Logger.shared.info("AwareIPC", "IPC directory created at: \(ipcPath)")
        #endif
    }

    func startHeartbeat(interval: TimeInterval = 2.0) {
        heartbeatTask?.cancel()

        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.writeHeartbeat()
                try? await Task.sleep(for: .seconds(interval))
            }
        }

        #if DEBUG
        Logger.shared.info("AwareIPC", "Heartbeat started with \(interval)s interval")
        #endif
    }

    private func writeHeartbeat() {
        let heartbeatPath = ipcPath + "/ui_watcher_heartbeat.txt"
        let timestamp = ISO8601DateFormatter().string(from: Date())

        do {
            try timestamp.write(toFile: heartbeatPath, atomically: true, encoding: .utf8)
        } catch {
            #if DEBUG
            Logger.shared.error("AwareIPC", "Failed to write heartbeat: \(error.localizedDescription)")
            #endif
        }
    }

    func sendCommand(_ command: AwareCommand) async throws -> AwareResult {
        let commandPath = ipcPath + "/ui_command.json"
        let resultPath = ipcPath + "/ui_result.json"

        // Write command
        let commandData = try JSONEncoder().encode(command)
        try commandData.write(to: URL(fileURLWithPath: commandPath))

        // Wait for result (simple polling - could be enhanced)
        var attempts = 0
        while attempts < 50 { // 5 second timeout
            if FileManager.default.fileExists(atPath: resultPath) {
                let resultData = try Data(contentsOf: URL(fileURLWithPath: resultPath))
                return try JSONDecoder().decode(AwareResult.self, from: resultData)
            }
            try await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }

        throw AwareError.timeout
    }

    func stopHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }
}

// MARK: - Commands and Results

public struct AwareCommand: Codable {
    public let type: String
    public let viewId: String?
    public let parameters: [String: String]?

    public init(type: String, viewId: String? = nil, parameters: [String: String]? = nil) {
        self.type = type
        self.viewId = viewId
        self.parameters = parameters
    }
}

public struct AwareResult: Codable {
    public let success: Bool
    public let message: String?
    public let data: [String: String]?

    public init(success: Bool, message: String? = nil, data: [String: String]? = nil) {
        self.success = success
        self.message = message
        self.data = data
    }
}

enum AwareError: Error {
    case timeout
}

#endif // os(iOS)