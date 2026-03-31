import Foundation

// MARK: - Log Bridge Protocol

/// Protocol for bridging GhostUI logs to external systems
///
/// Implement this protocol to forward logs to your app's logging infrastructure.
/// Example: LogAggregatorService, analytics, crash reporting, etc.
public protocol AwareLogBridge: Sendable {
    /// Called for every UI-related log event
    func logUI(_ message: String, emoji: String, level: LogLevel) async

    /// Called for flow tracking events (view transitions, navigation)
    func logFlow(_ event: AwareFlowEvent) async

    /// Called for test-related events
    func logTest(_ event: AwareTestEvent) async
}

/// Default implementation with empty methods
public extension AwareLogBridge {
    func logUI(_ message: String, emoji: String, level: LogLevel) async {}
    func logFlow(_ event: AwareFlowEvent) async {}
    func logTest(_ event: AwareTestEvent) async {}
}

// MARK: - Flow Events

/// Represents a UI flow event for analytics and monitoring
public struct AwareFlowEvent: Sendable {
    public let type: FlowEventType
    public let emoji: String
    public let message: String
    public let viewName: String?
    public let properties: [String: String]?
    public let timestamp: Date

    public enum FlowEventType: String, Sendable {
        case viewAppeared
        case viewDisappeared
        case buttonTapped
        case stateChanged
        case navigation
        case custom
    }

    public init(
        type: FlowEventType,
        emoji: String,
        message: String,
        viewName: String? = nil,
        properties: [String: String]? = nil
    ) {
        self.type = type
        self.emoji = emoji
        self.message = message
        self.viewName = viewName
        self.properties = properties
        self.timestamp = Date()
    }
}

// MARK: - Test Events

/// Represents a test-related event
public struct AwareTestEvent: Sendable {
    public let type: TestEventType
    public let testName: String
    public let tier: TestTier?
    public let result: TestResult?
    public let error: String?
    public let duration: TimeInterval?
    public let timestamp: Date

    public enum TestEventType: String, Sendable {
        case started
        case passed
        case failed
        case skipped
        case summary
    }

    public init(
        type: TestEventType,
        testName: String,
        tier: TestTier? = nil,
        result: TestResult? = nil,
        error: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.type = type
        self.testName = testName
        self.tier = tier
        self.result = result
        self.error = error
        self.duration = duration
        self.timestamp = Date()
    }
}

// MARK: - Bridge Registry

/// Manages registered log bridges
public actor AwareBridgeRegistry {
    public static let shared = AwareBridgeRegistry()

    private var bridges: [any AwareLogBridge] = []

    /// Register a log bridge
    public func register(_ bridge: any AwareLogBridge) {
        bridges.append(bridge)
    }

    /// Clear all registered bridges
    public func clearBridges() {
        bridges.removeAll()
    }

    /// Forward UI log to all bridges
    public func forwardUILog(_ message: String, emoji: String, level: LogLevel) async {
        for bridge in bridges {
            await bridge.logUI(message, emoji: emoji, level: level)
        }
    }

    /// Forward flow event to all bridges
    public func forwardFlow(_ event: AwareFlowEvent) async {
        for bridge in bridges {
            await bridge.logFlow(event)
        }
    }

    /// Forward test event to all bridges
    public func forwardTest(_ event: AwareTestEvent) async {
        for bridge in bridges {
            await bridge.logTest(event)
        }
    }
}

// MARK: - Aware Extensions

public extension Aware {
    /// Set a log bridge for external integration
    static func setLogBridge(_ bridge: any AwareLogBridge) async {
        await AwareBridgeRegistry.shared.register(bridge)
    }

    /// Clear all log bridges
    static func clearLogBridges() async {
        await AwareBridgeRegistry.shared.clearBridges()
    }
}
