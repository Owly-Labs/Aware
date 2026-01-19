//
//  UIConvenienceModifiers.swift
//  AwareiOS
//
//  Convenience modifiers for common UI patterns with rich state tracking.
//  Inspired by AetherSing's successful approach to LLM-friendly state representation.
//

#if os(iOS)
import SwiftUI

// MARK: - Loading State

extension View {
    /// Track loading state with optional message and progress
    public func uiLoadingState(
        _ id: String,
        isLoading: Bool,
        message: String? = nil,
        progress: Double? = nil
    ) -> some View {
        self
            .awareState(id, key: "isLoading", value: isLoading)
            .awareState(id, key: "loadingMessage", value: message ?? "")
            .awareState(id, key: "loadingProgress", value: progress.map { "\($0)" } ?? "")
            .awareMetadata(
                id,
                description: "Loading state: \(message ?? "Loading")",
                type: .query,
                metadata: [
                    "isLoading": "\(isLoading)",
                    "hasProgress": "\(progress != nil)"
                ]
            )
    }
}

// MARK: - Error State

extension View {
    /// Track error state with retry capability
    public func uiErrorState(
        _ id: String,
        error: Error?,
        canRetry: Bool = true
    ) -> some View {
        self
            .awareState(id, key: "hasError", value: error != nil)
            .awareState(id, key: "errorMessage", value: error?.localizedDescription ?? "")
            .awareState(id, key: "canRetry", value: canRetry)
            .awareMetadata(
                id,
                description: error != nil ? "Error: \(error!.localizedDescription)" : "No error",
                type: .query,
                isDestructive: false,
                metadata: [
                    "canRetry": "\(canRetry)",
                    "errorType": error != nil ? String(describing: type(of: error!)) : ""
                ]
            )
    }
}

// MARK: - Processing State

extension View {
    /// Track multi-step processing with current step and progress
    public func uiProcessingState(
        _ id: String,
        isProcessing: Bool,
        step: String? = nil,
        totalSteps: Int? = nil,
        currentStep: Int? = nil,
        progress: Double? = nil
    ) -> some View {
        self
            .awareState(id, key: "isProcessing", value: isProcessing)
            .awareState(id, key: "currentStep", value: step ?? "")
            .awareState(id, key: "stepProgress", value: progress.map { "\($0)" } ?? "")
            .awareState(id, key: "stepIndex", value: currentStep.map { "\($0)" } ?? "")
            .awareState(id, key: "totalSteps", value: totalSteps.map { "\($0)" } ?? "")
            .awareMetadata(
                id,
                description: isProcessing ? "Processing: \(step ?? "In progress")" : "Not processing",
                type: .mutation,
                metadata: [
                    "isProcessing": "\(isProcessing)",
                    "hasProgress": "\(progress != nil)"
                ]
            )
    }
}

// MARK: - Validation State

extension View {
    /// Track form validation state with errors
    public func uiValidationState(
        _ id: String,
        isValid: Bool,
        errors: [String] = [],
        warnings: [String] = []
    ) -> some View {
        self
            .awareState(id, key: "isValid", value: isValid)
            .awareState(id, key: "errorCount", value: "\(errors.count)")
            .awareState(id, key: "warningCount", value: "\(warnings.count)")
            .awareState(id, key: "errors", value: errors.joined(separator: "; "))
            .awareState(id, key: "warnings", value: warnings.joined(separator: "; "))
            .awareMetadata(
                id,
                description: isValid ? "Valid" : "Invalid: \(errors.joined(separator: ", "))",
                type: .query,
                metadata: [
                    "isValid": "\(isValid)",
                    "hasErrors": "\(!errors.isEmpty)",
                    "hasWarnings": "\(!warnings.isEmpty)"
                ]
            )
    }
}

// MARK: - Network State

extension View {
    /// Track network request state
    public func uiNetworkState(
        _ id: String,
        isConnected: Bool,
        isLoading: Bool = false,
        lastSync: Date? = nil,
        error: Error? = nil
    ) -> some View {
        self
            .awareState(id, key: "isConnected", value: isConnected)
            .awareState(id, key: "isLoading", value: isLoading)
            .awareState(id, key: "hasError", value: error != nil)
            .awareState(id, key: "lastSync", value: lastSync.map { ISO8601DateFormatter().string(from: $0) } ?? "")
            .awareMetadata(
                id,
                description: "Network: \(isConnected ? "Connected" : "Disconnected")",
                type: .network,
                metadata: [
                    "isConnected": "\(isConnected)",
                    "isLoading": "\(isLoading)",
                    "hasError": "\(error != nil)"
                ]
            )
    }
}

// MARK: - Selection State

extension View {
    /// Track selection state for lists and collections
    public func uiSelectionState<T: Hashable>(
        _ id: String,
        selectedItems: Set<T>,
        totalItems: Int,
        allowsMultipleSelection: Bool = false
    ) -> some View {
        self
            .awareState(id, key: "selectionCount", value: "\(selectedItems.count)")
            .awareState(id, key: "totalItems", value: "\(totalItems)")
            .awareState(id, key: "allowsMultiple", value: allowsMultipleSelection)
            .awareState(id, key: "hasSelection", value: !selectedItems.isEmpty)
            .awareMetadata(
                id,
                description: "\(selectedItems.count) of \(totalItems) selected",
                type: .query,
                metadata: [
                    "allowsMultiple": "\(allowsMultipleSelection)",
                    "selectionPercent": "\(totalItems > 0 ? Int((Double(selectedItems.count) / Double(totalItems)) * 100) : 0)"
                ]
            )
    }
}

// MARK: - Empty State

extension View {
    /// Track empty state with optional action
    public func uiEmptyState(
        _ id: String,
        isEmpty: Bool,
        message: String = "No items",
        canAddItems: Bool = false
    ) -> some View {
        self
            .awareState(id, key: "isEmpty", value: isEmpty)
            .awareState(id, key: "emptyMessage", value: message)
            .awareState(id, key: "canAddItems", value: canAddItems)
            .awareMetadata(
                id,
                description: isEmpty ? message : "Has content",
                type: .query,
                metadata: [
                    "isEmpty": "\(isEmpty)",
                    "canAddItems": "\(canAddItems)"
                ]
            )
    }
}

// MARK: - Authentication State

extension View {
    /// Track authentication state
    public func uiAuthState(
        _ id: String,
        isAuthenticated: Bool,
        username: String? = nil,
        requiresReauth: Bool = false
    ) -> some View {
        self
            .awareState(id, key: "isAuthenticated", value: isAuthenticated)
            .awareState(id, key: "username", value: username ?? "")
            .awareState(id, key: "requiresReauth", value: requiresReauth)
            .awareMetadata(
                id,
                description: isAuthenticated ? "Authenticated as \(username ?? "user")" : "Not authenticated",
                type: .query,
                metadata: [
                    "isAuthenticated": "\(isAuthenticated)",
                    "requiresReauth": "\(requiresReauth)"
                ]
            )
    }
}

// MARK: - Tappable with Direct Action

extension View {
    /// Make view tappable with direct action callback (ghost UI support)
    public func uiTappable(
        _ id: String,
        label: String,
        isEnabled: Bool = true,
        action: @escaping @MainActor () async -> Void
    ) -> some View {
        self
            .awareButton(id, label: label)
            .awareState(id, key: "isEnabled", value: isEnabled)
            .onTapGesture {
                guard isEnabled else { return }
                Task {
                    await action()
                }
            }
            .modifier(DirectActionModifier(viewId: id, action: action))
    }
}

// MARK: - Direct Action Modifier

/// Modifier that registers direct action callbacks for ghost UI testing
struct DirectActionModifier: ViewModifier {
    let viewId: String
    let action: @MainActor () async -> Void

    func body(content: Content) -> some View {
        content
            .task { [action, viewId] in
                // Register action with platform service
                #if os(iOS)
                if let platform = AwareIOSPlatform.shared as? AwareIOSPlatform {
                    await platform.registerAction(viewId, callback: action)
                }
                #endif
            }
    }
}

/// Modifier that registers text bindings for typeText support
struct TextBindingModifier: ViewModifier {
    let viewId: String
    let text: Binding<String>

    func body(content: Content) -> some View {
        content
            .task { [viewId, text] in
                // Register text binding with platform service
                #if os(iOS)
                AwareIOSPlatform.shared.registerTextBinding(viewId, binding: text)
                #endif
            }
    }
}

// MARK: - TextField with Enhanced Binding

extension View {
    /// Enhanced TextField tracking with typeText support
    public func uiTextField(
        _ id: String,
        text: Binding<String>,
        label: String,
        placeholder: String? = nil,
        isEnabled: Bool = true,
        isFocused: Binding<Bool>? = nil
    ) -> some View {
        self
            .awareTextField(id, text: text, label: label, isFocused: isFocused ?? .constant(false))
            .awareState(id, key: "placeholder", value: placeholder ?? "")
            .awareState(id, key: "isEnabled", value: isEnabled)
            .awareState(id, key: "characterCount", value: "\(text.wrappedValue.count)")
            .modifier(TextBindingModifier(viewId: id, text: text))
    }

    /// Enhanced SecureField tracking
    public func uiSecureField(
        _ id: String,
        text: Binding<String>,
        label: String,
        placeholder: String? = nil,
        isEnabled: Bool = true
    ) -> some View {
        self
            .awareSecureField(id, text: text, label: label)
            .awareState(id, key: "placeholder", value: placeholder ?? "")
            .awareState(id, key: "isEnabled", value: isEnabled)
            .awareState(id, key: "hasValue", value: !text.wrappedValue.isEmpty)
    }
}

// MARK: - Toggle with Enhanced State

extension View {
    /// Enhanced Toggle tracking
    public func uiToggle(
        _ id: String,
        isOn: Binding<Bool>,
        label: String,
        isEnabled: Bool = true
    ) -> some View {
        self
            .aware(id, label: label)
            .awareState(id, key: "isOn", value: isOn.wrappedValue)
            .awareState(id, key: "isEnabled", value: isEnabled)
            .awareMetadata(
                id,
                description: "\(label): \(isOn.wrappedValue ? "On" : "Off")",
                type: .mutation
            )
    }
}

#endif // os(iOS)
