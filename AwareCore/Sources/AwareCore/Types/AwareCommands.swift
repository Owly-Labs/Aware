//
//  AwareCommands.swift
//  AwareCore
//
//  Command and result structures for Aware IPC and testing.
//

import Foundation
import CoreGraphics

// MARK: - Aware Command/Result

/// Command structure for Aware actions
public struct AwareCommand: Codable, Sendable {
    public let action: String       // "tap", "type", "assert", "snapshot"
    public let viewId: String?      // Target view ID
    public let value: String?       // For type: text to input, for assert: expected value
    public let key: String?         // For assert: state key to check

    public init(action: String, viewId: String? = nil, value: String? = nil, key: String? = nil) {
        self.action = action
        self.viewId = viewId
        self.value = value
        self.key = key
    }
}

/// Result structure for Aware actions
public struct AwareResult: Codable, Sendable {
    public let status: String       // "success" or "error"
    public let message: String?
    public let viewCount: Int?
    public let actual: String?      // For assert: actual value found
    public let snapshot: AwareSnapshotResult?

    public init(
        status: String,
        message: String? = nil,
        viewCount: Int? = nil,
        actual: String? = nil,
        snapshot: AwareSnapshotResult? = nil
    ) {
        self.status = status
        self.message = message
        self.viewCount = viewCount
        self.actual = actual
        self.snapshot = snapshot
    }

    public static func success(_ message: String) -> AwareResult {
        AwareResult(status: "success", message: message)
    }

    public static func error(_ message: String) -> AwareResult {
        AwareResult(status: "error", message: message)
    }
}

// MARK: - JSON Encoding Types (Internal)

struct AwareJSONSnapshot: Codable {
    let timestamp: String
    let viewCount: Int
    let views: [AwareJSONView]
}

struct AwareJSONView: Codable {
    let id: String
    let label: String?
    let frame: AwareJSONFrame?
    let visual: AwareJSONVisual?
    let state: [String: String]?
    let children: [AwareJSONView]?
    let animation: AwareAnimationState?
    let action: AwareActionMetadata?
    let behavior: AwareBehaviorMetadata?
}

struct AwareJSONFrame: Codable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}

struct AwareJSONVisual: Codable {
    let text: String?
    let backgroundColor: String?
    let foregroundColor: String?
    let font: String?
    let opacity: CGFloat?
    let isTextTruncated: Bool?
    let intrinsicWidth: CGFloat?
    let intrinsicHeight: CGFloat?
    let lineCount: Int?
    let maxLines: Int?
    let isFocused: Bool?
    let isHovered: Bool?
    let scrollX: CGFloat?
    let scrollY: CGFloat?
    let contentWidth: CGFloat?
    let contentHeight: CGFloat?
}

// MARK: - Snapshot Result

public struct AwareSnapshotResult: Codable, Sendable {
    public let format: String
    public let content: String
    public let viewCount: Int
    public let timestamp: Date

    public init(format: AwareSnapshotFormat, content: String, viewCount: Int, timestamp: Date = Date()) {
        self.format = format.rawValue
        self.content = content
        self.viewCount = viewCount
        self.timestamp = timestamp
    }
}

// MARK: - v3.0 Additional Result Types (others defined in AwareTypes.swift)

/// Result of swipe action
public struct AwareSwipeResult: Sendable {
    public let success: Bool
    public let viewId: String
    public let direction: String
    public let message: String

    public init(success: Bool, viewId: String, direction: String, message: String) {
        self.success = success
        self.viewId = viewId
        self.direction = direction
        self.message = message
    }
}

/// Result of text input action (typeText, setText, appendText, clearText)
public struct AwareTextResult: Sendable {
    public let success: Bool
    public let viewId: String
    public let actionType: TextActionType
    public let text: String?
    public let finalValue: String?
    public let message: String

    public init(success: Bool, viewId: String, actionType: TextActionType, text: String? = nil, finalValue: String? = nil, message: String) {
        self.success = success
        self.viewId = viewId
        self.actionType = actionType
        self.text = text
        self.finalValue = finalValue
        self.message = message
    }

    public enum TextActionType: String, Sendable {
        case type, setText, appendText, clearText
    }
}

/// Result of focus action (focus, blur, focusNext, focusPrevious)
public struct AwareFocusResult: Sendable {
    public let success: Bool
    public let focusedViewId: String?
    public let actionType: FocusActionType
    public let message: String

    public init(success: Bool, focusedViewId: String? = nil, actionType: FocusActionType, message: String) {
        self.success = success
        self.focusedViewId = focusedViewId
        self.actionType = actionType
        self.message = message
    }

    public enum FocusActionType: String, Sendable {
        case focus, blur, focusNext, focusPrevious
    }
}

/// Result of find query
public struct AwareFindResult: Sendable {
    public let success: Bool
    public let matches: [String]
    public let query: String
    public let message: String

    public init(success: Bool, matches: [String], query: String, message: String) {
        self.success = success
        self.matches = matches
        self.query = query
        self.message = message
    }
}

/// Result of navigation action (goBack, dismiss)
public struct AwareNavigationResult: Sendable {
    public let success: Bool
    public let actionType: NavigationActionType
    public let message: String

    public init(success: Bool, actionType: NavigationActionType, message: String) {
        self.success = success
        self.actionType = actionType
        self.message = message
    }

    public enum NavigationActionType: String, Sendable {
        case goBack, dismiss
    }
}
