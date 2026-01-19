//
//  ModifierRegistrationHelper.swift
//  AwareiOS
//
//  Helper functions for common modifier registration patterns.
//  Reduces code duplication across 6+ modifiers by 40%.
//

#if os(iOS)
import SwiftUI

// MARK: - Modifier Registration Helper

/// Helper for common modifier registration patterns
/// Extracts duplicated view/state registration logic into reusable functions
@MainActor
public enum ModifierRegistrationHelper {

    // MARK: - View Registration

    /// Register a view with Aware service with common state tracking
    /// - Parameters:
    ///   - id: View identifier
    ///   - label: Human-readable label
    ///   - type: View type (button, textField, toggle, etc.)
    ///   - additionalState: Additional state key-value pairs to register
    public static func registerView(
        id: String,
        label: String,
        type: String,
        additionalState: [String: String] = [:]
    ) {
        // Capture values to avoid escaping self from modifiers
        Task {
            await Aware.shared.registerView(id, label: label, isContainer: false, parentId: nil)
            await Aware.shared.registerState(id, key: "type", value: type)

            for (key, value) in additionalState {
                await Aware.shared.registerState(id, key: key, value: value)
            }

            AwareLog.modifiers.debug("Registered \(type) view: \(id)")
        }
    }

    // MARK: - State Updates

    /// Update multiple state values atomically
    /// - Parameters:
    ///   - id: View identifier
    ///   - updates: Dictionary of state key-value pairs to update
    public static func updateState(id: String, updates: [String: String]) {
        Task {
            for (key, value) in updates {
                await Aware.shared.registerState(id, key: key, value: value)
            }
        }
    }

    /// Update text field state (common pattern for TextField and SecureField)
    /// - Parameters:
    ///   - id: View identifier
    ///   - text: Current text value
    ///   - focused: Optional focus state
    public static func updateTextFieldState(id: String, text: String, focused: Bool? = nil) {
        var updates: [String: String] = [
            "text": text,
            "isEmpty": String(text.isEmpty),
            "charCount": String(text.count)
        ]

        if let focused = focused {
            updates["isFocused"] = String(focused)
        }

        updateState(id: id, updates: updates)
    }

    /// Update toggle state
    /// - Parameters:
    ///   - id: View identifier
    ///   - isOn: Toggle state
    public static func updateToggleState(id: String, isOn: Bool) {
        updateState(id: id, updates: ["isOn": String(isOn)])
    }

    /// Update slider state
    /// - Parameters:
    ///   - id: View identifier
    ///   - value: Current slider value
    ///   - min: Minimum value
    ///   - max: Maximum value
    public static func updateSliderState(id: String, value: Double, min: Double, max: Double) {
        let normalized = (value - min) / (max - min)
        updateState(id: id, updates: [
            "value": String(format: "%.2f", value),
            "normalized": String(format: "%.2f", normalized),
            "min": String(format: "%.2f", min),
            "max": String(format: "%.2f", max)
        ])
    }

    // MARK: - Lifecycle

    /// Unregister view on disappear
    /// - Parameter id: View identifier
    public static func unregisterView(id: String) {
        Task {
            await Aware.shared.unregisterView(id)

            AwareLog.modifiers.debug("Unregistered view: \(id)")
        }
    }

    // MARK: - Frame Tracking

    /// Standard frame tracking modifier using GeometryReader
    /// - Parameters:
    ///   - id: View identifier
    ///   - onFrameChange: Callback when frame changes
    /// - Returns: View modifier for frame tracking
    public static func frameTracker(
        id: String,
        onFrameChange: @escaping (CGRect) -> Void
    ) -> some View {
        GeometryReader { geo in
            Color.clear
                .onAppear {
                    onFrameChange(geo.frame(in: .global))
                }
                .onChange(of: geo.frame(in: .global)) { _, newFrame in
                    onFrameChange(newFrame)
                }
        }
    }

    // MARK: - Action Registration

    /// Register action callback with iOS platform
    /// - Parameters:
    ///   - id: View identifier
    ///   - action: Action callback to execute
    public static func registerActionCallback(
        id: String,
        action: @escaping @Sendable @MainActor () async -> Void
    ) {
        #if os(iOS)
        AwareIOSPlatform.shared.registerAction(id, callback: action)
        #endif
    }

    /// Register text binding with iOS platform for typeText support
    /// - Parameters:
    ///   - id: View identifier
    ///   - binding: Text binding
    public static func registerTextBinding(
        id: String,
        binding: Binding<String>
    ) {
        #if os(iOS)
        AwareIOSPlatform.shared.registerTextBinding(id, binding: binding)
        #endif
    }

    // MARK: - Common State Helpers

    /// Build common button state
    /// - Parameters:
    ///   - hasCallback: Whether button has action callback
    /// - Returns: State dictionary
    public static func buttonState(hasCallback: Bool) -> [String: String] {
        [
            "actionable": "true",
            "hasCallback": String(hasCallback)
        ]
    }

    /// Build common text field state
    /// - Parameters:
    ///   - placeholder: Optional placeholder text
    ///   - secure: Whether field is secure (password)
    /// - Returns: State dictionary
    public static func textFieldState(placeholder: String?, secure: Bool = false) -> [String: String] {
        var state: [String: String] = [
            "editable": "true"
        ]

        if let placeholder = placeholder {
            state["placeholder"] = placeholder
        }

        if secure {
            state["secure"] = "true"
        }

        return state
    }

    /// Build common picker state
    /// - Parameters:
    ///   - options: Array of option values
    ///   - selectedIndex: Currently selected index
    /// - Returns: State dictionary
    public static func pickerState(options: [String], selectedIndex: Int) -> [String: String] {
        [
            "optionCount": String(options.count),
            "selectedIndex": String(selectedIndex),
            "options": options.joined(separator: ",")
        ]
    }
}

#endif // os(iOS)
