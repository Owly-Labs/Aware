//
//  AwareProtocols.swift
//  AwareCore
//
//  AwarePlatform abstraction protocols for cross-platform support.
//

import Foundation

// MARK: - AwarePlatform Abstraction Protocol

/// AwarePlatform-specific operations abstraction
@MainActor
public protocol AwarePlatformProtocol: Sendable {
    /// AwarePlatform identifier (e.g., "iOS", "macOS", "web")
    var platformName: String { get }

    /// Configure platform-specific features
    func configure(options: [String: Any])

    /// Register platform-specific action callback
    func registerAction(_ viewId: String, callback: @escaping @Sendable @MainActor () async -> Void)

    /// Execute platform-specific action
    func executeAction(_ viewId: String) async -> Bool

    /// Register gesture callback (iOS gestures, macOS events)
    /// Note: AwareGestureType and AwareGestureCallback are defined in AwareTypes.swift
    func registerGesture(_ viewId: String, type: String, callback: @escaping () async -> Void)

    /// Simulate input (macOS CGEvent or iOS direct manipulation)
    func simulateInput(_ command: AwareInputCommand) async -> AwareInputResult

    /// Get platform-specific snapshot enhancements
    func enhanceSnapshot(_ snapshot: AwareSnapshot) -> AwareSnapshot
}

// MARK: - Input Command Abstraction

/// Input command for cross-platform input simulation
public struct AwareInputCommand: Sendable {
    public let type: AwareInputType
    public let target: String
    public let parameters: [String: String]

    public init(type: AwareInputType, target: String, parameters: [String: String] = [:]) {
        self.type = type
        self.target = target
        self.parameters = parameters
    }
}

/// Input types supported across platforms
public enum AwareInputType: String, Sendable {
    case tap
    case type
    case swipe
    case scroll
    case gesture
    case longPress
    case doubleTap
}

/// Result of input simulation
public struct AwareInputResult: Sendable {
    public let success: Bool
    public let message: String?

    public init(success: Bool, message: String? = nil) {
        self.success = success
        self.message = message
    }
}

// Note: AwareGestureType, AwareGestureCallback, and AwareSnapshot are defined in AwareTypes.swift
