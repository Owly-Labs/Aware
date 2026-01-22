//
//  UIConvenienceModifiers.swift
//  AwareiOS
//
//  Convenience modifiers for common UI patterns with rich state tracking.
//  Inspired by AetherSing's successful approach to LLM-friendly state representation.
//

#if os(iOS)
import SwiftUI
import AwareCore

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
                type: .unknown
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
                type: .unknown,
                isDestructive: false
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
                type: .mutation
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
                type: .unknown
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
                type: .network
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
                type: .unknown
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
                type: .unknown
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
                type: .unknown
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
        isEnabled: Bool = true
    ) -> some View {
        self
            .aware(id, label: label)
            .awareState(id, key: "text", value: text.wrappedValue)
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

// MARK: - Behavior Metadata Modifier

private struct UIBehaviorModifier: ViewModifier {
    let id: String
    let dataSource: String
    let refreshTrigger: String
    let cacheDuration: String
    let errorHandling: String
    let loadingBehavior: String
    let boundModel: String
    let validationRules: String
    let dependencies: String
    let descriptionText: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                Task { @MainActor in
                    Aware.shared.registerState(id, key: "dataSource", value: dataSource)
                    Aware.shared.registerState(id, key: "refreshTrigger", value: refreshTrigger)
                    Aware.shared.registerState(id, key: "cacheDuration", value: cacheDuration)
                    Aware.shared.registerState(id, key: "errorHandling", value: errorHandling)
                    Aware.shared.registerState(id, key: "loadingBehavior", value: loadingBehavior)
                    Aware.shared.registerState(id, key: "boundModel", value: boundModel)
                    Aware.shared.registerState(id, key: "validationRules", value: validationRules)
                    Aware.shared.registerState(id, key: "dependencies", value: dependencies)
                    Aware.shared.registerState(id, key: "_description", value: descriptionText)
                    Aware.shared.registerState(id, key: "_actionType", value: "network")
                }
            }
    }
}

extension View {
    /// Register backend behavior metadata for a data-bound view
    /// Provides LLM with context about data sources, refresh patterns, and validation rules
    public func uiBehavior(
        _ id: String,
        dataSource: String? = nil,
        refreshTrigger: String? = nil,
        cacheDuration: String? = nil,
        errorHandling: String? = nil,
        loadingBehavior: String? = nil,
        validationRules: [String]? = nil,
        boundModel: String? = nil,
        dependencies: [String]? = nil
    ) -> some View {
        self.modifier(UIBehaviorModifier(
            id: id,
            dataSource: dataSource ?? "",
            refreshTrigger: refreshTrigger ?? "",
            cacheDuration: cacheDuration ?? "",
            errorHandling: errorHandling ?? "",
            loadingBehavior: loadingBehavior ?? "",
            boundModel: boundModel ?? "",
            validationRules: validationRules?.joined(separator: "; ") ?? "",
            dependencies: dependencies?.joined(separator: ", ") ?? "",
            descriptionText: "Data-bound view: \(boundModel ?? dataSource ?? "unknown")"
        ))
    }
}

// MARK: - Debug Context

extension View {
    /// Add debug context explaining why view is in current state
    /// Helps LLM understand the reasoning behind UI state during debugging
    public func uiDebugContext(_ id: String, context: String) -> some View {
        self.awareState(id, key: "_debugContext", value: context)
    }

    /// Track view lifecycle events (appeared, disappeared) with timestamps
    public func uiLifecycle(_ id: String) -> some View {
        self
            .onAppear {
                Task { @MainActor in
                    Aware.shared.registerState(id, key: "_lifecycle", value: "appeared")
                    Aware.shared.registerState(id, key: "_lastAppear", value: ISO8601DateFormatter().string(from: Date()))
                }
            }
            .onDisappear {
                Task { @MainActor in
                    Aware.shared.registerState(id, key: "_lifecycle", value: "disappeared")
                    Aware.shared.registerState(id, key: "_lastDisappear", value: ISO8601DateFormatter().string(from: Date()))
                }
            }
    }

    /// Assert a condition and log result to snapshot for LLM debugging
    public func uiAssert(_ id: String, condition: Bool, message: String) -> some View {
        self.onAppear {
            Task { @MainActor in
                Aware.shared.registerState(id, key: "_assertion", value: condition ? "passed" : "failed")
                Aware.shared.registerState(id, key: "_assertionMessage", value: message)
            }
        }
    }
}

#endif // os(iOS)
