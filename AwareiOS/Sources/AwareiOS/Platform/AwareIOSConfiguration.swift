//
//  AwareIOSConfiguration.swift
//  AwareiOS
//
//  Type-safe configuration for iOS platform with environment variable support.
//  Replaces hardcoded values with configurable settings.
//

#if os(iOS)
import Foundation

// MARK: - Configuration

/// Type-safe configuration for AwareiOS platform
public struct AwareIOSConfiguration: Sendable {

    // MARK: - IPC Configuration

    /// IPC base path (default: ~/.aware)
    public var ipcPath: String

    /// IPC transport mode
    public var transportMode: IPCTransportMode

    // MARK: - WebSocket Configuration

    /// WebSocket host (default: localhost)
    public var webSocketHost: String

    /// WebSocket port (default: 9999, env: AWARE_WEBSOCKET_PORT)
    public var webSocketPort: Int

    /// WebSocket connection timeout in seconds (default: 5.0)
    public var webSocketTimeout: TimeInterval

    // MARK: - Heartbeat Configuration

    /// Heartbeat interval in seconds (default: 2.0)
    public var heartbeatInterval: TimeInterval

    /// Enable heartbeat (default: true)
    public var heartbeatEnabled: Bool

    // MARK: - File-Based IPC Configuration

    /// Command polling interval in milliseconds (default: 100)
    public var commandPollInterval: UInt64

    /// Command timeout in attempts (default: 50, = 5 seconds with 100ms polling)
    public var commandTimeoutAttempts: Int

    // MARK: - Initialization

    public init(
        ipcPath: String,
        transportMode: IPCTransportMode,
        webSocketHost: String,
        webSocketPort: Int,
        webSocketTimeout: TimeInterval,
        heartbeatInterval: TimeInterval,
        heartbeatEnabled: Bool,
        commandPollInterval: UInt64,
        commandTimeoutAttempts: Int
    ) {
        self.ipcPath = ipcPath
        self.transportMode = transportMode
        self.webSocketHost = webSocketHost
        self.webSocketPort = webSocketPort
        self.webSocketTimeout = webSocketTimeout
        self.heartbeatInterval = heartbeatInterval
        self.heartbeatEnabled = heartbeatEnabled
        self.commandPollInterval = commandPollInterval
        self.commandTimeoutAttempts = commandTimeoutAttempts
    }

    // MARK: - Defaults

    /// Default configuration with sensible defaults
    public static let `default` = AwareIOSConfiguration(
        ipcPath: "~/.aware",
        transportMode: .auto,
        webSocketHost: "localhost",
        webSocketPort: ProcessInfo.processInfo.environment["AWARE_WEBSOCKET_PORT"].flatMap(Int.init) ?? 9999,
        webSocketTimeout: 5.0,
        heartbeatInterval: 2.0,
        heartbeatEnabled: true,
        commandPollInterval: 100,
        commandTimeoutAttempts: 50
    )

    // MARK: - Environment-Based Configuration

    /// Load configuration from environment variables
    /// Overrides default values with environment variable values if present
    public static func fromEnvironment() -> AwareIOSConfiguration {
        var config = AwareIOSConfiguration.default

        // Override with environment variables
        if let port = ProcessInfo.processInfo.environment["AWARE_WEBSOCKET_PORT"],
           let portInt = Int(port) {
            config.webSocketPort = portInt
        }

        if let host = ProcessInfo.processInfo.environment["AWARE_WEBSOCKET_HOST"] {
            config.webSocketHost = host
        }

        if let path = ProcessInfo.processInfo.environment["AWARE_IPC_PATH"] {
            config.ipcPath = path
        }

        if let interval = ProcessInfo.processInfo.environment["AWARE_HEARTBEAT_INTERVAL"],
           let intervalDouble = Double(interval) {
            config.heartbeatInterval = intervalDouble
        }

        if let disabled = ProcessInfo.processInfo.environment["AWARE_HEARTBEAT_DISABLED"],
           disabled == "1" || disabled.lowercased() == "true" {
            config.heartbeatEnabled = false
        }

        if let timeout = ProcessInfo.processInfo.environment["AWARE_COMMAND_TIMEOUT_MS"],
           let timeoutInt = Int(timeout) {
            // Convert milliseconds to attempts (100ms per attempt)
            config.commandTimeoutAttempts = timeoutInt / 100
        }

        return config
    }

    // MARK: - Validation

    /// Validate configuration and return warnings for potentially problematic values
    /// Returns empty array if configuration is valid
    public func validate() -> [String] {
        var warnings: [String] = []

        if heartbeatInterval < 0.1 {
            warnings.append("Heartbeat interval \(heartbeatInterval)s is very low, may cause performance issues")
        }

        if heartbeatInterval > 30.0 {
            warnings.append("Heartbeat interval \(heartbeatInterval)s is very high, may cause connection timeouts")
        }

        let totalTimeout = commandTimeoutAttempts * Int(commandPollInterval)
        if totalTimeout < 1000 {
            warnings.append("Command timeout \(totalTimeout)ms is very low, may cause premature timeouts")
        }

        if webSocketPort < 1024 {
            warnings.append("WebSocket port \(webSocketPort) is in privileged range (<1024), may require elevated permissions")
        }

        if webSocketPort > 65535 {
            warnings.append("WebSocket port \(webSocketPort) is outside valid range (1-65535)")
        }

        if webSocketTimeout < 1.0 {
            warnings.append("WebSocket timeout \(webSocketTimeout)s is very low, may fail to connect")
        }

        return warnings
    }

    // MARK: - Computed Properties

    /// Full WebSocket URL constructed from host and port
    public var webSocketURL: String {
        "ws://\(webSocketHost):\(webSocketPort)"
    }

    /// Command timeout duration in seconds
    public var commandTimeoutDuration: TimeInterval {
        Double(commandTimeoutAttempts) * (Double(commandPollInterval) / 1000.0)
    }

    /// Human-readable description of configuration
    public var description: String {
        """
        AwareIOSConfiguration:
          - IPC Path: \(ipcPath)
          - Transport Mode: \(transportMode)
          - WebSocket: \(webSocketURL) (timeout: \(webSocketTimeout)s)
          - Heartbeat: \(heartbeatEnabled ? "enabled" : "disabled") (\(heartbeatInterval)s)
          - Command Timeout: \(commandTimeoutDuration)s (\(commandTimeoutAttempts) attempts)
        """
    }
}

// MARK: - CustomStringConvertible

extension AwareIOSConfiguration: CustomStringConvertible {}

#endif // os(iOS)
