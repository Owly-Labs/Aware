//
//  AwareMacOSPlatform.swift
//  AwareMacOS
//
//  macOS platform implementation of Aware framework.
//  Provides CGEvent-based input simulation for mouse and keyboard.
//

#if os(macOS)
import AppKit
import SwiftUI
import AwareCore

// MARK: - macOS Platform Implementation

/// macOS platform service implementing AwarePlatform protocol
@MainActor
public final class AwareMacOSPlatform: AwarePlatform {
    public static let shared = AwareMacOSPlatform()

    // MARK: - AwarePlatform Protocol

    public let platformName: String = "macOS"

    // MARK: - State

    private var actionCallbacks: [String: @Sendable @MainActor () async -> Void] = [:]
    private var gestureCallbacks: [String: [String: () async -> Void]] = [:]
    private var textBindings: [String: Binding<String>] = [:] // NEW: Text binding registry for Ghost UI
    private var isConfigured = false

    private init() {
        // Auto-register with Aware.shared on initialization
        // Aware.shared.configurePlatform(self) // TODO: Uncomment when AwareService supports this
    }

    // MARK: - Configuration

    /// Configure macOS platform
    /// - Parameters:
    ///   - options: Configuration options (reserved for future use)
    public func configure(options: [String: Any]) {
        guard !isConfigured else { return }

        isConfigured = true

        #if DEBUG
        print("AwareMacOS: Platform configured")
        #endif
    }

    // MARK: - Action Registration

    /// Register an action callback
    public func registerAction(_ viewId: String, callback: @escaping @Sendable @MainActor () async -> Void) {
        actionCallbacks[viewId] = callback

        #if DEBUG
        print("AwareMacOS: Registered action for view: \(viewId)")
        #endif
    }

    /// Execute a registered action
    public func executeAction(_ viewId: String) async -> Bool {
        guard let callback = actionCallbacks[viewId] else {
            #if DEBUG
            print("AwareMacOS: No action callback registered for view: \(viewId)")
            #endif
            return false
        }

        #if DEBUG
        print("AwareMacOS: Executing action for view: \(viewId)")
        #endif

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

        #if DEBUG
        print("AwareMacOS: Registered gesture '\(type)' for view: \(viewId)")
        #endif
    }

    // MARK: - Text Binding Registry (Ghost UI Enhancement)

    /// Register a text binding for direct text input without CGEvents
    /// Enables instant, reliable text entry for instrumented views
    public func registerTextBinding(_ viewId: String, binding: Binding<String>) {
        textBindings[viewId] = binding

        #if DEBUG
        print("AwareMacOS: Registered text binding for view: \(viewId)")
        #endif
    }

    /// Type text into a view using binding (fast) or CGEvent (fallback)
    /// - Parameters:
    ///   - viewId: Target view identifier
    ///   - text: Text to type
    /// - Returns: Success status
    public func typeText(_ viewId: String, text: String) async -> Bool {
        // Try binding first (fast path <1ms)
        if let binding = textBindings[viewId] {
            binding.wrappedValue = text

            #if DEBUG
            print("AwareMacOS: Typed '\(text)' via binding (fast path)")
            #endif

            return true
        }

        // Fallback to CGEvent (slow path ~50ms)
        #if DEBUG
        print("AwareMacOS: No binding found, falling back to CGEvent (slow path)")
        #endif

        await AwareMacOSInput.type(text)
        return true
    }

    // MARK: - Input Simulation

    /// Simulate input command using CGEvents
    public func simulateInput(_ command: AwareInputCommand) async -> AwareInputResult {
        switch command.type {
        case .tap:
            // Try direct callback first, fall back to CGEvent if no callback
            if let callback = actionCallbacks[command.target] {
                await callback()
                return AwareInputResult(success: true, message: "Tapped '\(command.target)' via callback")
            }

            // Parse coordinates from parameters if available
            if let xStr = command.parameters["x"],
               let yStr = command.parameters["y"],
               let x = Double(xStr),
               let y = Double(yStr) {
                let point = CGPoint(x: x, y: y)
                let success = await AwareMacOSInput.click(at: point)
                return AwareInputResult(
                    success: success,
                    message: success ? "Clicked at (\(Int(x)), \(Int(y)))" : "Click failed"
                )
            }

            return AwareInputResult(success: false, message: "No callback or coordinates for '\(command.target)'")

        case .longPress:
            if let xStr = command.parameters["x"],
               let yStr = command.parameters["y"],
               let x = Double(xStr),
               let y = Double(yStr) {
                let duration = Double(command.parameters["duration"] ?? "0.5") ?? 0.5
                let point = CGPoint(x: x, y: y)
                let success = await AwareMacOSInput.longPress(at: point, duration: duration)
                return AwareInputResult(
                    success: success,
                    message: success ? "Long pressed at (\(Int(x)), \(Int(y))) for \(duration)s" : "Long press failed"
                )
            }

            return AwareInputResult(success: false, message: "Missing coordinates for long press")

        case .type:
            if let text = command.parameters["text"] {
                let success = await typeText(command.target, text: text)
                return AwareInputResult(
                    success: success,
                    message: "Typed \(text.count) characters to '\(command.target)'"
                )
            }

            return AwareInputResult(success: false, message: "Missing text parameter")

        case .scroll, .swipe:
            // TODO: Implement scroll and swipe simulation
            return AwareInputResult(success: false, message: "Scroll/swipe not yet implemented on macOS")

        default:
            return AwareInputResult(success: false, message: "Unsupported input type: \(command.type.rawValue)")
        }
    }

    // MARK: - Snapshot Enhancement

    /// Enhance snapshot with macOS-specific metadata
    public func enhanceSnapshot(_ snapshot: AwareSnapshot) -> AwareSnapshot {
        // macOS-specific enhancements could include:
        // - Window title bar info
        // - Dock/menu bar state
        // - Mouse cursor position
        // For now, return snapshot unchanged
        return snapshot
    }

    // MARK: - Convenience

    /// Get registered view IDs with action callbacks
    public var actionableViewIds: [String] {
        Array(actionCallbacks.keys)
    }
}

// MARK: - Public Configuration Extension

public extension Aware {
    /// Configure Aware for macOS platform
    /// Sets up macOS-specific features and CGEvent input simulation
    static func configureForMacOS() {
        AwareMacOSPlatform.shared.configure(options: [:])

        #if DEBUG
        print("Aware: Configured for macOS platform")
        #endif
    }
}

#endif // os(macOS)
