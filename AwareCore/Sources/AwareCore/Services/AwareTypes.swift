//
//  AwareTypes.swift
//  Aware
//
//  Model types for the Aware UI snapshot service.
//  Enables LLM-driven UI testing, view state tracking, and staleness detection.
//

import Foundation
import SwiftUI

// MARK: - Snapshot Format

public enum AwareSnapshotFormat: String, Sendable {
    case text       // Readable, medium tokens
    case json       // Full JSON, most tokens
    case markdown   // Markdown wrapped text
    case compact    // Minimal tokens, LLM-optimized
}

// MARK: - Visual Properties

public struct AwareSnapshot: Codable, Sendable {
    public let frame: CGRect?
    public let backgroundColor: String?    // Hex color
    public let foregroundColor: String?    // Hex color
    public let font: String?               // e.g., "SF Pro Bold 16pt"
    public let text: String?               // Text content (truncated)
    public let opacity: CGFloat
    public let isHidden: Bool

    // Text overflow detection
    public let isTextTruncated: Bool?      // True if text is clipped
    public let intrinsicSize: CGSize?      // Natural size before constraints
    public let lineCount: Int?             // Actual lines rendered
    public let maxLines: Int?              // Max lines allowed (0 = unlimited)

    // Focus state
    public let isFocused: Bool?            // Has keyboard/responder focus
    public let isHovered: Bool?            // Mouse is hovering

    // Scroll state
    public let scrollOffset: CGPoint?      // Current scroll position
    public let contentSize: CGSize?        // Total scrollable content size
    public let visibleRect: CGRect?        // Currently visible portion

    public init(
        frame: CGRect? = nil,
        backgroundColor: String? = nil,
        foregroundColor: String? = nil,
        font: String? = nil,
        text: String? = nil,
        opacity: CGFloat = 1.0,
        isHidden: Bool = false,
        isTextTruncated: Bool? = nil,
        intrinsicSize: CGSize? = nil,
        lineCount: Int? = nil,
        maxLines: Int? = nil,
        isFocused: Bool? = nil,
        isHovered: Bool? = nil,
        scrollOffset: CGPoint? = nil,
        contentSize: CGSize? = nil,
        visibleRect: CGRect? = nil
    ) {
        self.frame = frame
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.font = font
        self.text = text
        self.opacity = opacity
        self.isHidden = isHidden
        self.isTextTruncated = isTextTruncated
        self.intrinsicSize = intrinsicSize
        self.lineCount = lineCount
        self.maxLines = maxLines
        self.isFocused = isFocused
        self.isHovered = isHovered
        self.scrollOffset = scrollOffset
        self.contentSize = contentSize
        self.visibleRect = visibleRect
    }

    /// Format as inline properties string
    public var inlineDescription: String {
        var parts: [String] = []
        if let text = text, !text.isEmpty {
            let truncated = text.count > 30 ? String(text.prefix(30)) + "..." : text
            parts.append("text:\"\(truncated)\"")
        }
        if let bg = backgroundColor { parts.append("bg:\(bg)") }
        if let fg = foregroundColor { parts.append("fg:\(fg)") }
        if let font = font { parts.append("font:\(font)") }
        if opacity < 1.0 { parts.append("alpha:\(String(format: "%.2f", opacity))") }
        if isHidden { parts.append("hidden") }

        // Overflow indication
        if isTextTruncated == true { parts.append("TRUNCATED") }
        if let lines = lineCount, let max = maxLines, max > 0 {
            parts.append("lines:\(lines)/\(max)")
        }

        // Focus/hover
        if isFocused == true { parts.append("focused") }
        if isHovered == true { parts.append("hovered") }

        // Scroll position
        if let offset = scrollOffset, offset.x != 0 || offset.y != 0 {
            parts.append("scroll:(\(Int(offset.x)),\(Int(offset.y)))")
        }

        return parts.isEmpty ? "" : "{\(parts.joined(separator: ", "))}"
    }
}

// MARK: - Animation State

public struct AwareAnimationState: Codable, Sendable {
    public let isAnimating: Bool
    public let animationType: String?      // "spring", "easeIn", "linear", etc.
    public let duration: Double?           // Animation duration in seconds
    public let progress: Double?           // 0.0 to 1.0 if trackable
    public let fromValue: String?          // Starting value (stringified)
    public let toValue: String?            // Target value (stringified)
    public let repeatCount: Int?           // Number of repeats (0 = infinite)

    public init(
        isAnimating: Bool = false,
        animationType: String? = nil,
        duration: Double? = nil,
        progress: Double? = nil,
        fromValue: String? = nil,
        toValue: String? = nil,
        repeatCount: Int? = nil
    ) {
        self.isAnimating = isAnimating
        self.animationType = animationType
        self.duration = duration
        self.progress = progress
        self.fromValue = fromValue
        self.toValue = toValue
        self.repeatCount = repeatCount
    }

    public var inlineDescription: String {
        guard isAnimating else { return "" }
        var parts = ["animating"]
        if let type = animationType { parts.append(type) }
        if let dur = duration { parts.append("\(dur)s") }
        if let prog = progress { parts.append("\(Int(prog * 100))%") }
        return "[\(parts.joined(separator: ":"))]"
    }
}

// MARK: - Button/Action Metadata

public struct AwareActionMetadata: Codable, Sendable {
    public let actionDescription: String   // Human-readable: "Saves document to disk"
    public let actionType: ActionType      // Category of action
    public let isEnabled: Bool
    public let isDestructive: Bool         // Red/warning action
    public let requiresConfirmation: Bool  // Shows alert before executing
    public let shortcutKey: String?        // Keyboard shortcut if any
    public let apiEndpoint: String?        // Backend API called (if known)
    public let sideEffects: [String]?      // ["writes file", "sends network request"]

    public enum ActionType: String, Codable, Sendable {
        case navigation    // Opens another view/screen
        case mutation      // Changes app state
        case network       // Makes API call
        case fileSystem    // Reads/writes files
        case system        // System-level (open URL, share, etc.)
        case destructive   // Deletes or irreversible
        case unknown
    }

    public init(
        actionDescription: String,
        actionType: ActionType = .unknown,
        isEnabled: Bool = true,
        isDestructive: Bool = false,
        requiresConfirmation: Bool = false,
        shortcutKey: String? = nil,
        apiEndpoint: String? = nil,
        sideEffects: [String]? = nil
    ) {
        self.actionDescription = actionDescription
        self.actionType = actionType
        self.isEnabled = isEnabled
        self.isDestructive = isDestructive
        self.requiresConfirmation = requiresConfirmation
        self.shortcutKey = shortcutKey
        self.apiEndpoint = apiEndpoint
        self.sideEffects = sideEffects
    }

    public var inlineDescription: String {
        var parts = [actionDescription]
        if !isEnabled { parts.append("disabled") }
        if isDestructive { parts.append("destructive") }
        if let key = shortcutKey { parts.append("⌘\(key)") }
        if let endpoint = apiEndpoint { parts.append("→\(endpoint)") }
        return parts.joined(separator: "|")
    }
}

// MARK: - Backend Behavior Metadata

public struct AwareBehaviorMetadata: Codable, Sendable {
    public let dataSource: String?         // "CoreData", "REST API", "UserDefaults"
    public let refreshTrigger: String?     // "onAppear", "pull-to-refresh", "timer(30s)"
    public let cacheDuration: String?      // "5m", "1h", "persistent"
    public let errorHandling: String?      // "retry(3)", "fallback", "show-alert"
    public let loadingBehavior: String?    // "skeleton", "spinner", "progressive"
    public let validationRules: [String]?  // ["required", "email", "min:3"]
    public let boundModel: String?         // "User", "Settings", etc.
    public let dependencies: [String]?     // Other views/services this depends on

    public init(
        dataSource: String? = nil,
        refreshTrigger: String? = nil,
        cacheDuration: String? = nil,
        errorHandling: String? = nil,
        loadingBehavior: String? = nil,
        validationRules: [String]? = nil,
        boundModel: String? = nil,
        dependencies: [String]? = nil
    ) {
        self.dataSource = dataSource
        self.refreshTrigger = refreshTrigger
        self.cacheDuration = cacheDuration
        self.errorHandling = errorHandling
        self.loadingBehavior = loadingBehavior
        self.validationRules = validationRules
        self.boundModel = boundModel
        self.dependencies = dependencies
    }

    public var inlineDescription: String {
        var parts: [String] = []
        if let ds = dataSource { parts.append("src:\(ds)") }
        if let refresh = refreshTrigger { parts.append("refresh:\(refresh)") }
        if let model = boundModel { parts.append("model:\(model)") }
        if let rules = validationRules, !rules.isEmpty {
            parts.append("validate:[\(rules.joined(separator: ","))]")
        }
        return parts.isEmpty ? "" : "<\(parts.joined(separator: " "))>"
    }
}

// MARK: - View Snapshot

public struct AwareViewSnapshot: Sendable {
    public let id: String
    public var label: String?
    public var isContainer: Bool
    public var isVisible: Bool
    public var frame: CGRect?
    public var visual: AwareSnapshot?
    public var parentId: String?
    public var childIds: [String]

    // Extended metadata
    public var animation: AwareAnimationState?
    public var action: AwareActionMetadata?
    public var behavior: AwareBehaviorMetadata?

    public init(
        id: String,
        label: String? = nil,
        isContainer: Bool = false,
        isVisible: Bool = true,
        frame: CGRect? = nil,
        visual: AwareSnapshot? = nil,
        parentId: String? = nil,
        childIds: [String] = [],
        animation: AwareAnimationState? = nil,
        action: AwareActionMetadata? = nil,
        behavior: AwareBehaviorMetadata? = nil
    ) {
        self.id = id
        self.label = label
        self.isContainer = isContainer
        self.isVisible = isVisible
        self.frame = frame
        self.visual = visual
        self.parentId = parentId
        self.childIds = childIds
        self.animation = animation
        self.action = action
        self.behavior = behavior
    }
}

// MARK: - View Node (for tree building)

public struct AwareViewNode: Sendable {
    public let id: String
    public let label: String?
    public let frame: CGRect?
    public let visual: AwareSnapshot?
    public let state: [String: String]?
    public var children: [AwareViewNode]

    // Extended metadata
    public let animation: AwareAnimationState?
    public let action: AwareActionMetadata?
    public let behavior: AwareBehaviorMetadata?

    public init(
        id: String,
        label: String? = nil,
        frame: CGRect? = nil,
        visual: AwareSnapshot? = nil,
        state: [String: String]? = nil,
        children: [AwareViewNode] = [],
        animation: AwareAnimationState? = nil,
        action: AwareActionMetadata? = nil,
        behavior: AwareBehaviorMetadata? = nil
    ) {
        self.id = id
        self.label = label
        self.frame = frame
        self.visual = visual
        self.state = state
        self.children = children
        self.animation = animation
        self.action = action
        self.behavior = behavior
    }
}

// MARK: - View Description (for single view queries)

public struct AwareViewDescription: Codable, Sendable {
    public let id: String
    public let label: String?
    public let frame: CGRect?
    public let visual: AwareSnapshot?
    public let state: [String: String]?
    public let isVisible: Bool
    public let childCount: Int

    // Extended metadata
    public let animation: AwareAnimationState?
    public let action: AwareActionMetadata?
    public let behavior: AwareBehaviorMetadata?
}

// MARK: - Prop-State Binding (Stale @State Detection)

/// Tracks a relationship between a prop value and a state variable
/// Used to detect when props change but @State doesn't follow (stale state bug)
public struct PropStateBinding: Sendable {
    public let propKey: String           // Key identifying the prop (e.g., "feature.id")
    public let stateKey: String          // Key identifying the state (e.g., "editableTitle")
    public var lastPropValue: String     // Last observed prop value
    public var lastStateValue: String    // Last observed state value
    public var lastSyncTime: Date        // When prop and state were last in sync

    public init(propKey: String, stateKey: String, propValue: String, stateValue: String) {
        self.propKey = propKey
        self.stateKey = stateKey
        self.lastPropValue = propValue
        self.lastStateValue = stateValue
        self.lastSyncTime = Date()
    }
}

/// Warning when a prop changed but the associated state didn't update
public struct StalenessWarning: Sendable, Identifiable {
    public let id: UUID
    public let viewId: String
    public let propKey: String
    public let stateKey: String
    public let propValue: String         // New prop value
    public let staleStateValue: String   // State value that didn't update
    public let detectedAt: Date
    public let staleDuration: TimeInterval  // How long state has been stale

    public init(
        viewId: String,
        propKey: String,
        stateKey: String,
        propValue: String,
        staleStateValue: String,
        staleDuration: TimeInterval
    ) {
        self.id = UUID()
        self.viewId = viewId
        self.propKey = propKey
        self.stateKey = stateKey
        self.propValue = propValue
        self.staleStateValue = staleStateValue
        self.detectedAt = Date()
        self.staleDuration = staleDuration
    }

    public var description: String {
        "STALE STATE in '\(viewId)': prop '\(propKey)'='\(propValue)' but state '\(stateKey)'='\(staleStateValue)' (stale for \(String(format: "%.1f", staleDuration))s)"
    }
}

// MARK: - Assertion Result (v3.0 Enhanced)

public struct AwareAssertionResult: Sendable {
    public let passed: Bool
    public let viewId: String
    public let key: String
    public let expected: String?
    public let actual: String?
    public let message: String

    public init(passed: Bool, viewId: String, key: String, expected: String? = nil, actual: String? = nil, message: String) {
        self.passed = passed
        self.viewId = viewId
        self.key = key
        self.expected = expected
        self.actual = actual
        self.message = message
    }

    public var emoji: String { passed ? "✅" : "❌" }

    public var description: String { "\(emoji) \(message)" }
}

// MARK: - Checkpoint & Diff

public struct AwareCheckpoint: Sendable {
    public let timestamp: Date
    public let viewIds: Set<String>
    public let states: [String: [String: String]]
    public let visibleCount: Int

    public init(timestamp: Date, viewIds: Set<String>, states: [String: [String: String]], visibleCount: Int) {
        self.timestamp = timestamp
        self.viewIds = viewIds
        self.states = states
        self.visibleCount = visibleCount
    }
}

public struct AwareDiff: Sendable {
    public let addedViews: Set<String>
    public let removedViews: Set<String>
    public let changedStates: [String: (old: String?, new: String?)]
    public let viewCountDelta: Int

    public init(addedViews: Set<String>, removedViews: Set<String>, changedStates: [String: (old: String?, new: String?)], viewCountDelta: Int) {
        self.addedViews = addedViews
        self.removedViews = removedViews
        self.changedStates = changedStates
        self.viewCountDelta = viewCountDelta
    }

    public var hasChanges: Bool {
        !addedViews.isEmpty || !removedViews.isEmpty || !changedStates.isEmpty
    }

    public var summary: String {
        var parts: [String] = []
        if !addedViews.isEmpty { parts.append("+\(addedViews.count) views") }
        if !removedViews.isEmpty { parts.append("-\(removedViews.count) views") }
        if !changedStates.isEmpty { parts.append("\(changedStates.count) state changes") }
        return parts.isEmpty ? "No changes" : parts.joined(separator: ", ")
    }
}

// MARK: - Tap Result (v3.0 Enhanced)

public struct AwareTapResult: Sendable {
    public let success: Bool
    public let viewId: String
    public let actionType: TapActionType
    public let message: String
    public let duration: TimeInterval?
    public let actionDescription: String?

    public init(success: Bool, viewId: String, actionType: TapActionType, message: String, duration: TimeInterval? = nil, actionDescription: String? = nil) {
        self.success = success
        self.viewId = viewId
        self.actionType = actionType
        self.message = message
        self.duration = duration
        self.actionDescription = actionDescription
    }

    public enum TapActionType: String, Sendable {
        case tap, longPress, doubleTap
    }

    public var emoji: String { success ? "✅" : "❌" }
    public var description: String { "\(emoji) \(message)" }
}

// MARK: - Color Helpers

public extension Color {
    /// Convert SwiftUI Color to hex string
    func toHex() -> String? {
        #if os(macOS)
        let nsColor = NSColor(self)
        let cgColor = nsColor.cgColor
        guard let components = cgColor.components,
              components.count >= 3 else {
            return nil
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
        #elseif os(iOS)
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return nil
        }
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        #else
        return nil
        #endif
    }
}

#if os(macOS)
import AppKit

public extension NSColor {
    /// Convert NSColor to hex string
    func toHex() -> String? {
        guard let rgbColor = usingColorSpace(.deviceRGB) else { return nil }
        let r = Int(rgbColor.redComponent * 255)
        let g = Int(rgbColor.greenComponent * 255)
        let b = Int(rgbColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
#endif

#if os(iOS)
import UIKit

public extension UIColor {
    /// Convert UIColor to hex string
    func toHex() -> String? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return nil
        }
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
#endif

// MARK: - iOS Gesture Types

/// Types of gestures that can be registered for LLM control
public enum AwareGestureType: String, Codable, Sendable {
    case tap
    case longPress
    case doubleTap
    case swipeUp
    case swipeDown
    case swipeLeft
    case swipeRight
    case pinchIn
    case pinchOut
    case pan
    case drag
}

/// Direction for swipe gestures
public enum AwareSwipeDirection: String, Codable, Sendable {
    case up
    case down
    case left
    case right
}

/// Parameters passed to parameterized gesture callbacks
public struct AwareGestureParameters: Sendable {
    public let direction: AwareSwipeDirection?
    public let distance: CGFloat?
    public let velocity: CGFloat?
    public let scale: CGFloat?           // For pinch
    public let translation: CGPoint?     // For pan/drag

    public init(
        direction: AwareSwipeDirection? = nil,
        distance: CGFloat? = nil,
        velocity: CGFloat? = nil,
        scale: CGFloat? = nil,
        translation: CGPoint? = nil
    ) {
        self.direction = direction
        self.distance = distance
        self.velocity = velocity
        self.scale = scale
        self.translation = translation
    }
}

// MARK: - Text Binding for Direct Manipulation

/// Wrapper for text field bindings that allows direct LLM manipulation
public final class AwareTextBinding: @unchecked Sendable {
    private let getter: @MainActor () -> String
    private let setter: @MainActor (String) -> Void

    public init(get: @escaping @MainActor () -> String, set: @escaping @MainActor (String) -> Void) {
        self.getter = get
        self.setter = set
    }

    @MainActor
    public var value: String {
        getter()
    }

    @MainActor
    public func setValue(_ newValue: String) {
        setter(newValue)
    }

    @MainActor
    public func append(_ text: String) {
        setter(getter() + text)
    }

    @MainActor
    public func clear() {
        setter("")
    }

    @MainActor
    public func replaceRange(_ range: Range<String.Index>, with text: String) {
        var current = getter()
        current.replaceSubrange(range, with: text)
        setter(current)
    }
}

// MARK: - Gesture Callback Types

/// Callback type for simple gesture handlers
public typealias AwareGestureCallback = @MainActor () async -> Void

/// Callback type for gestures with parameters
public typealias AwareParameterizedGestureCallback = @MainActor (AwareGestureParameters) async -> Void

// MARK: - Staleness Notification Names

public extension Notification.Name {
    /// Posted when staleness is detected for a view
    static let awareStalenessDetected = Notification.Name("awareStalenessDetected")
    /// Posted when staleness is cleared for a view
    static let awareStalenessCleared = Notification.Name("awareStalenessCleared")
    /// Posted when navigation is requested by LLM
    static let awareNavigationRequest = Notification.Name("awareNavigationRequest")
}
