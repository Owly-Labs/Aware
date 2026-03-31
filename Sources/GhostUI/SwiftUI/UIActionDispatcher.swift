import Foundation
import SwiftUI
import Combine

// MARK: - UI Test Action

/// Actions that can be dispatched to control UI during tests
public enum UITestAction: Sendable {
    case tap(id: String)
    case doubleTap(id: String)
    case longPress(id: String)
    case swipe(id: String, direction: SwipeDirection)
    case type(id: String, text: String)
    case scroll(id: String, direction: ScrollDirection)
    case selectTab(name: String)
    case selectSubTab(name: String)
    case wait(seconds: TimeInterval)
    case waitForView(id: String, timeout: TimeInterval)
    case expectVisible(id: String)
    case expectHidden(id: String)
    case expectState(key: String, value: String)
    case custom(name: String)
    case log(message: String)

    public enum SwipeDirection: String, Sendable {
        case left, right, up, down
    }

    public enum ScrollDirection: String, Sendable {
        case up, down, left, right
    }
}

// MARK: - UI Action Dispatcher

/// Dispatches UI actions to views and tracks state for testing
/// Uses NotificationCenter for decoupled communication with SwiftUI views
@MainActor
public final class UIActionDispatcher: ObservableObject {

    // MARK: - Singleton

    public static let shared = UIActionDispatcher()

    // MARK: - State

    /// Currently visible views (by accessibility ID)
    @Published public private(set) var visibleViews: Set<String> = []

    /// Current UI state key-value pairs
    @Published public private(set) var state: [String: String] = [:]

    /// Execution log for plan vs actual comparison
    @Published public private(set) var executionLog: [ExecutionLogEntry] = []

    /// Registered action handlers
    private var actionHandlers: [String: (UITestAction) async -> Bool] = [:]

    /// Custom action handlers
    private var customHandlers: [String: () async -> Void] = [:]

    // MARK: - Notifications

    public static let actionNotification = Notification.Name("GhostUI.UIAction")
    public static let viewAppearedNotification = Notification.Name("GhostUI.ViewAppeared")
    public static let viewDisappearedNotification = Notification.Name("GhostUI.ViewDisappeared")
    public static let stateChangedNotification = Notification.Name("GhostUI.StateChanged")

    // MARK: - Publishers

    private let actionSubject = PassthroughSubject<UITestAction, Never>()
    public var actionPublisher: AnyPublisher<UITestAction, Never> {
        actionSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    private init() {
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: Self.viewAppearedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let viewId = notification.userInfo?["viewId"] as? String
            Task { @MainActor in
                if let viewId = viewId {
                    self?.visibleViews.insert(viewId)
                    self?.logExecution(.viewAppeared(viewId))
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: Self.viewDisappearedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let viewId = notification.userInfo?["viewId"] as? String
            Task { @MainActor in
                if let viewId = viewId {
                    self?.visibleViews.remove(viewId)
                    self?.logExecution(.viewDisappeared(viewId))
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: Self.stateChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let key = notification.userInfo?["key"] as? String
            let value = notification.userInfo?["value"] as? String
            Task { @MainActor in
                if let key = key, let value = value {
                    self?.state[key] = value
                    self?.logExecution(.stateChanged(key: key, value: value))
                }
            }
        }
    }

    // MARK: - Action Dispatch

    /// Dispatch an action to be handled by views
    public func dispatch(_ action: UITestAction) async -> DispatchResult {
        let startTime = Date()

        // Log planned action
        logExecution(.actionStarted(action))

        // Post notification for views to handle
        NotificationCenter.default.post(
            name: Self.actionNotification,
            object: nil,
            userInfo: ["action": action]
        )

        // Also publish to Combine subscribers
        actionSubject.send(action)

        var success = true
        var message: String? = nil

        // Handle action
        switch action {
        case .tap(let id):
            if let handler = actionHandlers[id] {
                success = await handler(action)
            } else {
                try? await Task.sleep(for: .milliseconds(100))
            }

        case .selectTab(let name):
            if let handler = actionHandlers["tab-\(name.lowercased())"] {
                success = await handler(action)
            }

        case .selectSubTab(let name):
            if let handler = actionHandlers["subtab-\(name.lowercased())"] {
                success = await handler(action)
            }

        case .custom(let name):
            if let handler = customHandlers[name] {
                await handler()
            } else {
                success = false
                message = "No handler for custom action: \(name)"
            }

        case .wait(let seconds):
            try? await Task.sleep(for: .seconds(seconds))

        case .waitForView(let id, let timeout):
            success = await waitForView(id, timeout: timeout)
            if !success {
                message = "Timeout waiting for view: \(id)"
            }

        case .expectVisible(let id):
            success = isViewVisible(id)
            if !success {
                message = "Expected view '\(id)' to be visible"
            }

        case .expectHidden(let id):
            success = !isViewVisible(id)
            if !success {
                message = "Expected view '\(id)' to be hidden"
            }

        case .expectState(let key, let value):
            success = state[key] == value
            if !success {
                message = "Expected state[\(key)] == '\(value)', got '\(state[key] ?? "nil")'"
            }

        case .log(let msg):
            Aware.logger.debug("📝 \(msg)")

        default:
            try? await Task.sleep(for: .milliseconds(100))
        }

        let duration = Date().timeIntervalSince(startTime)

        // Log actual result
        logExecution(.actionCompleted(action, success: success, duration: duration, message: message))

        return DispatchResult(success: success, duration: duration, message: message)
    }

    // MARK: - Handler Registration

    public func registerHandler(for id: String, handler: @escaping (UITestAction) async -> Bool) {
        actionHandlers[id] = handler
    }

    public func unregisterHandler(for id: String) {
        actionHandlers.removeValue(forKey: id)
    }

    public func registerCustomAction(_ name: String, handler: @escaping () async -> Void) {
        customHandlers[name] = handler
    }

    // MARK: - View Registration

    public func viewAppeared(_ id: String) {
        NotificationCenter.default.post(
            name: Self.viewAppearedNotification,
            object: nil,
            userInfo: ["viewId": id]
        )
    }

    public func viewDisappeared(_ id: String) {
        NotificationCenter.default.post(
            name: Self.viewDisappearedNotification,
            object: nil,
            userInfo: ["viewId": id]
        )
    }

    public func updateState(_ key: String, value: String) {
        NotificationCenter.default.post(
            name: Self.stateChangedNotification,
            object: nil,
            userInfo: ["key": key, "value": value]
        )
    }

    // MARK: - Queries

    public func isViewVisible(_ id: String) -> Bool {
        visibleViews.contains(id)
    }

    public func getState(_ key: String) -> String? {
        state[key]
    }

    public func waitForView(_ id: String, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if isViewVisible(id) {
                return true
            }
            try? await Task.sleep(for: .milliseconds(100))
        }

        return false
    }

    public func waitForState(_ key: String, equals value: String, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if state[key] == value {
                return true
            }
            try? await Task.sleep(for: .milliseconds(100))
        }

        return false
    }

    // MARK: - Execution Log (Plan vs Actual)

    private func logExecution(_ entry: ExecutionLogEntry) {
        executionLog.append(entry)
        Aware.logger.trace("🎯 \(entry.description)")
    }

    /// Clear execution log (call before test run)
    public func clearLog() {
        executionLog.removeAll()
    }

    /// Get formatted plan vs actual comparison
    public func getPlanVsActualReport() -> String {
        var report = "═══════════ PLAN VS ACTUAL ═══════════\n"

        for entry in executionLog {
            switch entry {
            case .actionStarted(let action):
                report += "▶ PLAN: \(actionDescription(action))\n"
            case .actionCompleted(let action, let success, let duration, let message):
                let status = success ? "✅" : "❌"
                report += "  ACTUAL: \(status) \(String(format: "%.2fs", duration))"
                if let msg = message {
                    report += " - \(msg)"
                }
                report += "\n"
            case .viewAppeared(let id):
                report += "  📱 View appeared: \(id)\n"
            case .viewDisappeared(let id):
                report += "  👋 View disappeared: \(id)\n"
            case .stateChanged(let key, let value):
                report += "  🔄 State: \(key)=\(value)\n"
            }
        }

        report += "═══════════════════════════════════════"
        return report
    }

    private func actionDescription(_ action: UITestAction) -> String {
        switch action {
        case .tap(let id): return "Tap '\(id)'"
        case .doubleTap(let id): return "Double-tap '\(id)'"
        case .longPress(let id): return "Long-press '\(id)'"
        case .swipe(let id, let dir): return "Swipe \(dir.rawValue) on '\(id)'"
        case .type(let id, let text): return "Type '\(text)' in '\(id)'"
        case .scroll(let id, let dir): return "Scroll \(dir.rawValue) on '\(id)'"
        case .selectTab(let name): return "Select tab '\(name)'"
        case .selectSubTab(let name): return "Select sub-tab '\(name)'"
        case .wait(let seconds): return "Wait \(seconds)s"
        case .waitForView(let id, let timeout): return "Wait for view '\(id)' (\(timeout)s timeout)"
        case .expectVisible(let id): return "Expect '\(id)' visible"
        case .expectHidden(let id): return "Expect '\(id)' hidden"
        case .expectState(let key, let value): return "Expect state[\(key)] == '\(value)'"
        case .custom(let name): return "Custom: \(name)"
        case .log(let msg): return "Log: \(msg)"
        }
    }

    // MARK: - Reset

    public func reset() {
        visibleViews.removeAll()
        state.removeAll()
        executionLog.removeAll()
    }
}

// MARK: - Dispatch Result

public struct DispatchResult: Sendable {
    public let success: Bool
    public let duration: TimeInterval
    public let message: String?

    public init(success: Bool, duration: TimeInterval, message: String? = nil) {
        self.success = success
        self.duration = duration
        self.message = message
    }
}

// MARK: - Execution Log Entry

public enum ExecutionLogEntry: Sendable {
    case actionStarted(UITestAction)
    case actionCompleted(UITestAction, success: Bool, duration: TimeInterval, message: String?)
    case viewAppeared(String)
    case viewDisappeared(String)
    case stateChanged(key: String, value: String)

    public var description: String {
        switch self {
        case .actionStarted(let action):
            return "[PLAN] \(action)"
        case .actionCompleted(let action, let success, let duration, let message):
            return "[ACTUAL] \(action) -> \(success ? "✅" : "❌") (\(String(format: "%.2fs", duration)))" + (message.map { " - \($0)" } ?? "")
        case .viewAppeared(let id):
            return "[VIEW+] \(id)"
        case .viewDisappeared(let id):
            return "[VIEW-] \(id)"
        case .stateChanged(let key, let value):
            return "[STATE] \(key)=\(value)"
        }
    }
}

// MARK: - View Modifiers

public extension View {
    /// Make view trackable by GhostUI's ghost UI layer.
    /// The view becomes invisible to the user but queryable by LLMs.
    func ghostID(_ id: String) -> some View {
        self
            .accessibilityIdentifier(id)
            .onAppear {
                Task { @MainActor in
                    UIActionDispatcher.shared.viewAppeared(id)
                }
            }
            .onDisappear {
                Task { @MainActor in
                    UIActionDispatcher.shared.viewDisappeared(id)
                }
            }
    }

    /// Track state changes in the ghost UI layer for LLM observability.
    func ghostTrackState(_ key: String, value: String) -> some View {
        self.onChange(of: value) { _, newValue in
            Task { @MainActor in
                UIActionDispatcher.shared.updateState(key, value: newValue)
            }
        }
    }
}
