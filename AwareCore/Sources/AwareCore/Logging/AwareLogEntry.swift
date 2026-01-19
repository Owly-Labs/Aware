//
//  AwareLogEntry.swift
//  Breathe
//
//  Structured log entry for LLM-aware debugging
//  Correlates logs with UI snapshots, state, and code location
//

import Foundation

// MARK: - AwareLogLevel Extension

extension AwareLogLevel {
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🔥"
        }
    }
}

// MARK: - AwareLogEntry

/// Structured log entry with full debugging context
public struct AwareLogEntry: Codable, Identifiable, Sendable {
    public let id: String
    public let timestamp: Date
    public let level: AwareLogLevel

    // Message content
    public let component: String  // e.g. "MCPClientService", "OllamaService"
    public let message: String
    public let error: String?     // Error.localizedDescription if available

    // Code location
    public let file: String
    public let line: Int
    public let function: String

    // Context
    public let uiSnapshotId: String?     // Reference to UI snapshot at time of log
    public let stateSnapshot: [String: String]?  // Key state values at time of log
    public let stackTrace: [String]?     // Stack trace for errors

    // Metadata
    public let threadName: String
    public let tags: [String]            // e.g. ["network", "auth", "database"]

    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        level: AwareLogLevel,
        component: String,
        message: String,
        error: Error? = nil,
        file: String = #file,
        line: Int = #line,
        function: String = #function,
        uiSnapshotId: String? = nil,
        stateSnapshot: [String: String]? = nil,
        stackTrace: [String]? = nil,
        threadName: String = Thread.current.name ?? "Unknown",
        tags: [String] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.component = component
        self.message = message
        self.error = error?.localizedDescription
        self.file = file
        self.line = line
        self.function = function
        self.uiSnapshotId = uiSnapshotId
        self.stateSnapshot = stateSnapshot
        self.stackTrace = stackTrace ?? (error != nil ? Thread.callStackSymbols : nil)
        self.threadName = threadName
        self.tags = tags
    }

    /// LLM-friendly formatted log entry
    public var llmDescription: String {
        var parts: [String] = []

        // Header: timestamp, level, component
        let timeStr = timestamp.formatted(date: .omitted, time: .standard)
        parts.append("[\(timeStr)] \(level.emoji) \(level.rawValue) [\(component)]")

        // Message
        parts.append("Message: \(message)")

        // Error details if present
        if let error = error {
            parts.append("Error: \(error)")
        }

        // Code location
        let fileName = (file as NSString).lastPathComponent
        parts.append("Location: \(fileName):\(line) in \(function)")

        // UI context if available
        if let snapshotId = uiSnapshotId {
            parts.append("UI Snapshot: \(snapshotId)")
        }

        // State snapshot if available
        if let state = stateSnapshot, !state.isEmpty {
            let stateStr = state.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            parts.append("State: \(stateStr)")
        }

        // Tags
        if !tags.isEmpty {
            parts.append("Tags: \(tags.joined(separator: ", "))")
        }

        return parts.joined(separator: "\n")
    }

    /// Compact single-line format for quick scanning
    public var compactDescription: String {
        let fileName = (file as NSString).lastPathComponent
        let errorSuffix = error.map { " | \($0)" } ?? ""
        return "[\(level.emoji) \(component)] \(message) (\(fileName):\(line))\(errorSuffix)"
    }
}

/// Log query parameters for filtering
public struct AwareLogQuery: Sendable {
    public let startTime: Date?
    public let endTime: Date?
    public let levels: [AwareLogLevel]?
    public let components: [String]?
    public let tags: [String]?
    public let searchText: String?
    public let hasError: Bool?
    public let hasUISnapshot: Bool?
    public let limit: Int?

    public init(
        startTime: Date? = nil,
        endTime: Date? = nil,
        levels: [AwareLogLevel]? = nil,
        components: [String]? = nil,
        tags: [String]? = nil,
        searchText: String? = nil,
        hasError: Bool? = nil,
        hasUISnapshot: Bool? = nil,
        limit: Int? = nil
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.levels = levels
        self.components = components
        self.tags = tags
        self.searchText = searchText
        self.hasError = hasError
        self.hasUISnapshot = hasUISnapshot
        self.limit = limit
    }
}
