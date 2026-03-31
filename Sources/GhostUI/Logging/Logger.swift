import Foundation
import os.log

/// Log levels for GhostUI logging
/// Named AwareLogLevel to avoid conflicts with other modules
public enum AwareLogLevel: String, Codable, Sendable, Comparable {
    case trace
    case debug
    case info
    case warn
    case error

    var priority: Int {
        switch self {
        case .trace: return 0
        case .debug: return 1
        case .info: return 2
        case .warn: return 3
        case .error: return 4
        }
    }

    var emoji: String {
        switch self {
        case .trace: return "🔍"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warn: return "⚠️"
        case .error: return "❌"
        }
    }

    var osLogType: OSLogType {
        switch self {
        case .trace, .debug: return .debug
        case .info: return .info
        case .warn: return .default
        case .error: return .error
        }
    }

    public static func < (lhs: AwareLogLevel, rhs: AwareLogLevel) -> Bool {
        lhs.priority < rhs.priority
    }
}

/// Backward compatibility typealias
public typealias LogLevel = AwareLogLevel

/// Structured log event
public struct LogEvent: Sendable {
    public let timestamp: Date
    public let level: LogLevel
    public let message: String
    public let category: String
    public let metadata: [String: String]?
    public let source: SourceLocation?

    public struct SourceLocation: Sendable {
        public let file: String
        public let function: String
        public let line: Int
    }
}

/// Thread-safe logger for GhostUI
public actor Logger {
    private let osLog: os.Logger
    private let config: LoggingConfig
    private let minLevel: LogLevel

    public init(config: LoggingConfig = LoggingConfig()) {
        self.config = config
        self.minLevel = config.level
        self.osLog = os.Logger(subsystem: "GhostUI", category: "General")
    }

    // MARK: - Convenience Methods (nonisolated)

    nonisolated public func trace(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        Task { await log(.trace, message, metadata: metadata, category: "GhostUI", file: file, function: function, line: line) }
    }

    nonisolated public func debug(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        Task { await log(.debug, message, metadata: metadata, category: "GhostUI", file: file, function: function, line: line) }
    }

    nonisolated public func info(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        Task { await log(.info, message, metadata: metadata, category: "GhostUI", file: file, function: function, line: line) }
    }

    nonisolated public func warn(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        Task { await log(.warn, message, metadata: metadata, category: "GhostUI", file: file, function: function, line: line) }
    }

    /// Alias for warn - for semantic clarity when warning about issues
    nonisolated public func warning(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        warn(message, metadata: metadata, file: file, function: function, line: line)
    }

    nonisolated public func error(
        _ message: String,
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        Task { await log(.error, message, metadata: metadata, category: "GhostUI", file: file, function: function, line: line) }
    }

    // MARK: - Core Logging

    private func log(
        _ level: LogLevel,
        _ message: String,
        metadata: [String: String]?,
        category: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= minLevel else { return }

        let event = LogEvent(
            timestamp: Date(),
            level: level,
            message: message,
            category: category,
            metadata: metadata,
            source: LogEvent.SourceLocation(file: file, function: function, line: line)
        )

        // Format and output
        let formatted = formatMessage(event)

        // Output to OSLog
        osLog.log(level: level.osLogType, "\(formatted)")

        // Also print for debug visibility
        #if DEBUG
        print(formatted)
        #endif
    }

    private func formatMessage(_ event: LogEvent) -> String {
        var parts: [String] = []

        if config.includeTimestamps {
            let formatter = ISO8601DateFormatter()
            parts.append("[\(formatter.string(from: event.timestamp))]")
        }

        if config.includeEmoji {
            parts.append(event.level.emoji)
        }

        parts.append("[\(event.level.rawValue.uppercased())]")
        parts.append("[\(event.category)]")
        parts.append(event.message)

        if let metadata = event.metadata, !metadata.isEmpty {
            let metaStr = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
            parts.append("(\(metaStr))")
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Test-Specific Logging

    nonisolated public func testStarted(_ testName: String, tier: TestTier) {
        info("Test started: \(testName)", metadata: ["tier": tier.rawValue])
    }

    nonisolated public func testPassed(_ testName: String, duration: TimeInterval) {
        info("✅ Test passed: \(testName)", metadata: ["duration": "\(Int(duration * 1000))ms"])
    }

    nonisolated public func testFailed(_ testName: String, error: String) {
        self.error("❌ Test failed: \(testName)", metadata: ["error": error])
    }

    nonisolated public func testSummary(passed: Int, failed: Int, skipped: Int, duration: TimeInterval) {
        let status = failed == 0 ? "✅" : "❌"
        let level: LogLevel = failed == 0 ? .info : .warn
        let message = "\(status) Tests: \(passed) passed, \(failed) failed, \(skipped) skipped (\(Int(duration * 1000))ms)"

        Task { await log(level, message, metadata: nil, category: "TestRunner", file: #file, function: #function, line: #line) }
    }
}
