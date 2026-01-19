//
//  AwareLog.swift
//  AwareiOS
//
//  Structured logging wrapper for iOS platform.
//  Uses os.log in standalone builds, integrates with Breathe's Log when embedded.
//

#if os(iOS)
import Foundation
import os.log

// MARK: - Logging

/// Logging facade for AwareiOS
/// Provides structured logging with automatic debug-level filtering
public enum AwareLog {

    // MARK: - Loggers

    /// AwarePlatform-related logging (configuration, lifecycle)
    public static let platform = Logger(subsystem: "com.aware.ios", category: "platform")

    /// IPC-related logging (file-based, WebSocket)
    public static let ipc = Logger(subsystem: "com.aware.ios", category: "ipc")

    /// Modifier-related logging (registration, state updates)
    public static let modifiers = Logger(subsystem: "com.aware.ios", category: "modifiers")

    // MARK: - Convenience

    /// General logging (use when category unclear)
    public static let general = Logger(subsystem: "com.aware.ios", category: "general")
}

// MARK: - Logger Extension

extension Logger {

    /// Debug-level logging (automatically stripped in release builds)
    /// Use for high-volume development-only logs
    public func debug(_ message: String) {
        #if DEBUG
        self.log(level: .debug, "\(message, privacy: .public)")
        #endif
    }

    /// Info-level logging (visible in production)
    /// Use for important lifecycle events
    public func info(_ message: String) {
        self.log(level: .info, "\(message, privacy: .public)")
    }

    /// Warning-level logging (visible in production)
    /// Use for potential issues that don't prevent operation
    public func warning(_ message: String) {
        self.log(level: .default, "⚠️ \(message, privacy: .public)")
    }

    /// Error-level logging (visible in production)
    /// Use for critical failures
    public func error(_ message: String) {
        self.log(level: .error, "❌ \(message, privacy: .public)")
    }

    /// Fault-level logging (visible in production, captures stack traces)
    /// Use for unexpected conditions that should never happen
    public func fault(_ message: String) {
        self.log(level: .fault, "🔥 \(message, privacy: .public)")
    }
}

// MARK: - Global Convenience

/// Global logging instance for backward compatibility
/// Prefer using AwareLog.platform, AwareLog.ipc, etc. for categorized logging
public let Log = AwareLog.self

#endif // os(iOS)
