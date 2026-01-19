//
//  AwareLogger.swift
//  Aware
//
//  Logging system for UI lifecycle events.
//  Uses OSLog for structured logging.
//

import Foundation
import os.log

// MARK: - Log Level

public enum AwareLogLevel: String, Codable, Sendable {
    case debug
    case info
    case warning
    case error
    case critical
}

// MARK: - UI Logger

public actor AwareLogger {
    public static let shared = AwareLogger()

    private let logger = Logger(subsystem: "com.aware.framework", category: "UI")
    private var isEnabled = true

    public init() {}

    // MARK: - Configuration

    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    // MARK: - Event Types

    public enum Event {
        case viewAppeared(name: String, details: String?)
        case viewDisappeared(name: String)
        case buttonTapped(label: String, view: String?)
        case stateChanged(view: String, property: String, from: String, to: String)
        case listRendered(name: String, count: Int, items: [String]?)
        case navigation(from: String, to: String)
        case error(view: String, message: String)
        case custom(emoji: String, message: String)

        public var emoji: String {
            switch self {
            case .viewAppeared: return "📱"
            case .viewDisappeared: return "👋"
            case .buttonTapped: return "👆"
            case .stateChanged: return "🔄"
            case .listRendered: return "📋"
            case .navigation: return "🧭"
            case .error: return "❌"
            case .custom(let emoji, _): return emoji
            }
        }

        public var message: String {
            switch self {
            case .viewAppeared(let name, let details):
                return details != nil ? "\(name) appeared: \(details!)" : "\(name) appeared"
            case .viewDisappeared(let name):
                return "\(name) disappeared"
            case .buttonTapped(let label, let view):
                return view != nil ? "Button tapped: \"\(label)\" in \(view!)" : "Button tapped: \"\(label)\""
            case .stateChanged(let view, let property, let from, let to):
                return "\(view).\(property): \(from) → \(to)"
            case .listRendered(let name, let count, let items):
                var msg = "\(name): \(count) items"
                if let items = items, !items.isEmpty {
                    msg += " [\(items.prefix(3).joined(separator: ", "))]"
                    if items.count > 3 { msg += "..." }
                }
                return msg
            case .navigation(let from, let to):
                return "Navigate: \(from) → \(to)"
            case .error(let view, let message):
                return "\(view) error: \(message)"
            case .custom(_, let message):
                return message
            }
        }

        public var logLevel: AwareLogLevel {
            switch self {
            case .error: return .error
            case .stateChanged, .viewDisappeared: return .debug
            default: return .info
            }
        }

        public var viewName: String? {
            switch self {
            case .viewAppeared(let name, _), .viewDisappeared(let name), .listRendered(let name, _, _): return name
            case .buttonTapped(_, let view): return view
            case .stateChanged(let view, _, _, _), .error(let view, _): return view
            case .navigation, .custom: return nil
            }
        }
    }

    // MARK: - Logging

    /// Log a UI event
    public func log(_ event: Event) {
        guard isEnabled else { return }

        let line = "[UI] \(event.emoji) \(event.message)"

        switch event.logLevel {
        case .debug:
            logger.debug("\(line)")
        case .info:
            logger.info("\(line)")
        case .warning:
            logger.warning("\(line)")
        case .error:
            logger.error("\(line)")
        case .critical:
            logger.critical("\(line)")
        }
    }

    /// Log a simple message with emoji
    public func log(_ emoji: String, _ message: String) {
        log(.custom(emoji: emoji, message: message))
    }

    // MARK: - Tree Logging (delegates to Aware)

    /// Log a UI tree snapshot
    public func logTree(format: AwareSnapshotFormat = .text) async {
        guard isEnabled else { return }
        let snapshot = await MainActor.run {
            Aware.shared.captureSnapshot(format: format)
        }
        logger.info("[UI] ═══════ View Hierarchy ═══════")
        for line in snapshot.content.split(separator: "\n") {
            logger.info("[UI] \(line)")
        }
        logger.info("[UI] ═══════════════════════════════")
    }

    /// Log a compact UI tree (token-efficient for LLMs)
    public func logTreeCompact() async {
        await logTree(format: .compact)
    }
}

// MARK: - Convenience Extensions

public extension AwareLogger {
    /// Quick log for view appeared
    func appeared(_ name: String, _ details: String? = nil) {
        log(.viewAppeared(name: name, details: details))
    }

    /// Quick log for view disappeared
    func disappeared(_ name: String) {
        log(.viewDisappeared(name: name))
    }

    /// Quick log for button tap
    func tapped(_ label: String, in view: String? = nil) {
        log(.buttonTapped(label: label, view: view))
    }

    /// Quick log for state change
    func stateChanged(_ view: String, _ property: String, from: String, to: String) {
        log(.stateChanged(view: view, property: property, from: from, to: to))
    }

    /// Quick log for list
    func list(_ name: String, count: Int, items: [String]? = nil) {
        log(.listRendered(name: name, count: count, items: items))
    }
}
