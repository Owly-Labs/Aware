//
//  AwareIOSPlatform.swift
//  AwareiOS
//
//  iOS platform implementation of Aware framework.
//  Provides iOS-specific gesture handling, action callbacks, and IPC.
//
//  Based on AetherSing's successful iOS integration patterns.
//

#if os(iOS)
import UIKit
import SwiftUI

// MARK: - iOS AwarePlatform Implementation

/// iOS platform service implementing AwarePlatform protocol
@MainActor
public final class AwareIOSPlatform: AwarePlatformProtocol {
    public static let shared = AwareIOSPlatform()

    // MARK: - AwarePlatform Protocol

    public let platformName: String = "iOS"

    // MARK: - State

    private var actionCallbacks: [String: @Sendable @MainActor () async -> Void] = [:]
    private var gestureCallbacks: [String: [String: () async -> Void]] = [:]
    private var textBindings: [String: Binding<String>] = [:]
    private var ipcService: AwareIPCService?
    private var isConfigured = false

    private init() {
        // Auto-register with Aware.shared on initialization
        // Aware.shared.configurePlatform(self) // TODO: Uncomment when AwareService supports this
    }

    // MARK: - Configuration

    /// Configure iOS platform with type-safe configuration
    /// - Parameter config: Configuration settings
    public func configure(config: AwareIOSConfiguration) {
        guard !isConfigured else { return }

        // Validate configuration
        let errors = config.validate()
        if !errors.isEmpty {
            AwareLog.platform.warning("Configuration validation warnings: \(errors.joined(separator: ", "))")
        }

        // Initialize IPC service with configuration
        ipcService = AwareIPCService(config: config)
        ipcService?.startHeartbeat(interval: config.heartbeatInterval)

        isConfigured = true

        AwareLog.platform.info("AwarePlatform configured with IPC path: \(config.ipcPath), transport: \(config.transportMode)")
    }

    /// Configure iOS platform with legacy options dictionary (backward compatibility)
    /// - Parameter options: Configuration options dictionary
    @available(*, deprecated, message: "Use configure(config:) with AwareIOSConfiguration instead")
    public func configure(options: [String: Any]) {
        let ipcPath = options["ipcPath"] as? String ?? AwareIOSConfiguration.default.ipcPath
        let config = AwareIOSConfiguration(
            ipcPath: ipcPath,
            transportMode: .auto,
            webSocketHost: "localhost",
            webSocketPort: 9999,
            heartbeatInterval: 2.0,
            commandTimeoutAttempts: 50
        )
        configure(config: config)
    }

    // MARK: - Action Registration

    /// Register an action callback for ghost UI testing
    public func registerAction(_ viewId: String, callback: @escaping @Sendable @MainActor () async -> Void) {
        actionCallbacks[viewId] = callback

        AwareLog.platform.debug("Registered action for view: \(viewId)")
    }

    /// Execute a registered action
    public func executeAction(_ viewId: String) async -> Bool {
        guard let callback = actionCallbacks[viewId] else {
            AwareLog.platform.warning("No action callback registered for view: \(viewId)")
            return false
        }

        AwareLog.platform.debug("Executing action for view: \(viewId)")

        await callback()
        return true
    }

    // MARK: - Gesture Registration

    /// Register a gesture callback
    public func registerGesture(_ viewId: String, type: String, callback: @escaping () async -> Void) {
        if gestureCallbacks[viewId] == nil {
            gestureCallbacks[viewId] = [:]
        }
        gestureCallbacks[viewId]?[type] = callback

        AwareLog.platform.debug("Registered gesture '\(type)' for view: \(viewId)")
    }

    // MARK: - Input Simulation

    /// Simulate input command (iOS uses direct callbacks, not CGEvents)
    public func simulateInput(_ command: AwareInputCommand) async -> AwareInputResult {
        switch command.type {
        case .tap:
            let success = await executeAction(command.target)
            return AwareInputResult(
                success: success,
                message: success ? "Tapped '\(command.target)'" : "No action registered for '\(command.target)'"
            )

        case .longPress:
            let duration = command.parameters["duration"]
                .flatMap { TimeInterval($0) } ?? 0.5

            guard let callback = gestureCallbacks[command.target]?["longPress"] else {
                return AwareInputResult(
                    success: false,
                    message: "No long press registered for '\(command.target)'"
                )
            }

            // Execute after duration
            try? await Task.sleep(for: .seconds(duration))
            await callback()

            return AwareInputResult(success: true, message: "Long pressed '\(command.target)' for \(duration)s")

        case .swipe:
            guard let direction = command.parameters["direction"] else {
                return AwareInputResult(success: false, message: "swipe requires 'direction' parameter (up/down/left/right)")
            }

            let gestureType = "swipe\(direction.capitalized)"
            guard let callback = gestureCallbacks[command.target]?[gestureType] else {
                return AwareInputResult(success: false, message: "No \(direction) swipe registered for '\(command.target)'")
            }

            await callback()
            return AwareInputResult(success: true, message: "Swiped \(direction) on '\(command.target)'")

        case .scroll:
            guard let direction = command.parameters["direction"] else {
                return AwareInputResult(success: false, message: "scroll requires 'direction' parameter (up/down/left/right)")
            }

            let distance = command.parameters["distance"]
                .flatMap { Double($0) } ?? 100.0

            let gestureType = "scroll\(direction.capitalized)"
            guard let callback = gestureCallbacks[command.target]?[gestureType] else {
                return AwareInputResult(success: false, message: "No \(direction) scroll registered for '\(command.target)'")
            }

            await callback()
            return AwareInputResult(success: true, message: "Scrolled \(direction) by \(distance)pt on '\(command.target)'")

        case .type:
            // Implement text input simulation via textBindings
            guard let text = command.parameters["text"] else {
                return AwareInputResult(success: false, message: "Missing 'text' parameter")
            }

            guard let binding = textBindings[command.target] else {
                return AwareInputResult(success: false, message: "No text binding registered for '\(command.target)'")
            }

            // Update the binding
            binding.wrappedValue = text

            return AwareInputResult(
                success: true,
                message: "Typed '\(text)' into '\(command.target)'"
            )

        default:
            return AwareInputResult(success: false, message: "Unsupported input type: \(command.type.rawValue)")
        }
    }

    // MARK: - Snapshot Enhancement

    /// Enhance snapshot with iOS-specific metadata
    public func enhanceSnapshot(_ snapshot: AwareSnapshot) -> AwareSnapshot {
        // iOS-specific enhancements could include:
        // - Safe area insets
        // - Dynamic type scaling
        // - Accessibility traits
        // For now, return snapshot unchanged
        return snapshot
    }

    // MARK: - Text Input Support

    /// Register a text binding for typeText support
    public func registerTextBinding(_ viewId: String, binding: Binding<String>) {
        textBindings[viewId] = binding

        AwareLog.platform.debug("Registered text binding for view: \(viewId)")
    }

    /// Type text into a registered text field
    public func typeText(_ viewId: String, text: String) async -> Bool {
        guard let binding = textBindings[viewId] else {
            AwareLog.platform.warning("No text binding registered for view: \(viewId)")
            return false
        }

        binding.wrappedValue = text

        AwareLog.platform.debug("Typed '\(text)' into view: \(viewId)")

        return true
    }

    // MARK: - Convenience

    /// Get registered view IDs with action callbacks
    public var actionableViewIds: [String] {
        Array(actionCallbacks.keys)
    }

    /// Get registered view IDs with text bindings
    public var textInputViewIds: [String] {
        Array(textBindings.keys)
    }
}

// MARK: - Public Configuration Extension

public extension Aware {
    /// Configure Aware for iOS platform with type-safe configuration
    /// Sets up iOS-specific features and IPC communication
    /// - Parameter config: iOS platform configuration (default: .default)
    static func configureForIOS(config: AwareIOSConfiguration = .default) {
        AwareIOSPlatform.shared.configure(config: config)
        AwareLog.platform.info("Configured for iOS platform")
    }

    /// Configure Aware for iOS platform with legacy IPC path (backward compatibility)
    /// - Parameter ipcPath: Path to IPC directory (default: ~/.aware)
    @available(*, deprecated, message: "Use configureForIOS(config:) with AwareIOSConfiguration instead")
    static func configureForIOS(ipcPath: String) {
        let config = AwareIOSConfiguration(
            ipcPath: ipcPath,
            transportMode: .auto,
            webSocketHost: "localhost",
            webSocketPort: 9999,
            heartbeatInterval: 2.0,
            commandTimeoutAttempts: 50
        )
        configureForIOS(config: config)
    }
}

#endif // os(iOS)
