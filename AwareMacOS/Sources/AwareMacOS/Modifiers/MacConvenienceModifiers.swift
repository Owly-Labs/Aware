//
//  MacConvenienceModifiers.swift
//  AwareMacOS
//
//  Convenience modifiers for common UI patterns with rich state tracking.
//  Includes 12 modifiers ported from iOS (zero code changes) + 4 Mac-specific modifiers.
//

#if os(macOS)
import SwiftUI
import AwareCore

// MARK: - Loading State (Ported from iOS)

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
                type: .mutation,
            )
    }
}

// MARK: - Error State (Ported from iOS)

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
                type: .mutation,
                isDestructive: false,
            )
    }
}

// MARK: - Processing State (Ported from iOS)

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
            )
    }
}

// MARK: - Validation State (Ported from iOS)

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
                type: .mutation,
            )
    }
}

// MARK: - Network State (Ported from iOS)

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
            )
    }
}

// MARK: - Selection State (Ported from iOS)

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
                type: .mutation,
            )
    }
}

// MARK: - Empty State (Ported from iOS)

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
                type: .mutation,
            )
    }
}

// MARK: - Authentication State (Ported from iOS)

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
                type: .system,
            )
    }
}

// MARK: - Tappable with Direct Action (Ported from iOS)

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

// MARK: - Direct Action Modifier (Ported from iOS)

/// Modifier that registers direct action callbacks for ghost UI testing
struct DirectActionModifier: ViewModifier {
    let viewId: String
    let action: @MainActor () async -> Void

    func body(content: Content) -> some View {
        content
            .task {
                // Register action with platform service
                if let platform = AwareMacOSPlatform.shared as? AwareMacOSPlatform {
                    await platform.registerAction(viewId, callback: action)
                }
            }
    }
}

/// Modifier that registers text bindings for typeText support
struct MacTextBindingModifier: ViewModifier {
    let viewId: String
    let text: Binding<String>

    func body(content: Content) -> some View {
        content
            .task {
                // Register text binding with platform service
                AwareMacOSPlatform.shared.registerTextBinding(viewId, binding: text)
            }
    }
}

// MARK: - TextField with Enhanced Binding (Ported from iOS)

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
            .aware(id, label: label)
            .awareState(id, key: "value", value: text.wrappedValue)
            .awareState(id, key: "placeholder", value: placeholder ?? "")
            .awareState(id, key: "isEnabled", value: isEnabled)
            .awareState(id, key: "characterCount", value: "\(text.wrappedValue.count)")
            .modifier(MacTextBindingModifier(viewId: id, text: text))
    }

    /// Enhanced SecureField tracking (Ported from iOS)
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

// MARK: - Toggle with Enhanced State (Ported from iOS)

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

// MARK: - Toolbar State (Mac-Specific)

extension View {
    /// Track macOS toolbar state
    public func macToolbarState(
        _ id: String,
        isVisible: Bool,
        itemCount: Int,
        selectedItem: String? = nil,
        isCustomizable: Bool = false
    ) -> some View {
        self
            .awareState(id, key: "isVisible", value: isVisible)
            .awareState(id, key: "itemCount", value: "\(itemCount)")
            .awareState(id, key: "selectedItem", value: selectedItem ?? "")
            .awareState(id, key: "isCustomizable", value: isCustomizable)
            .awareMetadata(
                id,
                description: "Toolbar: \(isVisible ? "Visible" : "Hidden"), \(itemCount) items",
                type: .mutation,
            )
    }
}

// MARK: - Sidebar State (Mac-Specific)

extension View {
    /// Track macOS sidebar state
    public func macSidebarState(
        _ id: String,
        isExpanded: Bool,
        selectedItem: String? = nil,
        itemCount: Int,
        canCollapse: Bool = true
    ) -> some View {
        self
            .awareState(id, key: "isExpanded", value: isExpanded)
            .awareState(id, key: "selectedItem", value: selectedItem ?? "")
            .awareState(id, key: "itemCount", value: "\(itemCount)")
            .awareState(id, key: "canCollapse", value: canCollapse)
            .awareMetadata(
                id,
                description: "Sidebar: \(isExpanded ? "Expanded" : "Collapsed"), \(itemCount) items",
                type: .mutation,
            )
    }
}

// MARK: - Split View State (Mac-Specific)

extension View {
    /// Track macOS split view state
    public func macSplitViewState(
        _ id: String,
        dividerPosition: Double,
        isCollapsed: Bool = false,
        minimumWidth: Double? = nil,
        maximumWidth: Double? = nil
    ) -> some View {
        self
            .awareState(id, key: "dividerPosition", value: "\(dividerPosition)")
            .awareState(id, key: "isCollapsed", value: isCollapsed)
            .awareState(id, key: "minimumWidth", value: minimumWidth.map { "\($0)" } ?? "")
            .awareState(id, key: "maximumWidth", value: maximumWidth.map { "\($0)" } ?? "")
            .awareMetadata(
                id,
                description: isCollapsed ? "Split view collapsed" : "Split view: divider at \(Int(dividerPosition))",
                type: .mutation,
            )
    }
}

// MARK: - Window State (Mac-Specific)

extension View {
    /// Track macOS window state
    public func macWindowState(
        _ id: String,
        isFullScreen: Bool,
        isKeyWindow: Bool,
        title: String,
        isMinimized: Bool = false,
        isResizable: Bool = true
    ) -> some View {
        self
            .awareState(id, key: "isFullScreen", value: isFullScreen)
            .awareState(id, key: "isKeyWindow", value: isKeyWindow)
            .awareState(id, key: "title", value: title)
            .awareState(id, key: "isMinimized", value: isMinimized)
            .awareState(id, key: "isResizable", value: isResizable)
            .awareMetadata(
                id,
                description: "Window: '\(title)' \(isFullScreen ? "(fullscreen)" : "")\(isKeyWindow ? " (key)" : "")",
                type: .system,
            )
    }
}

// MARK: - Menu State (Mac-Specific)

extension View {
    /// Track macOS menu state
    public func macMenuState(
        _ id: String,
        isOpen: Bool,
        selectedItem: String? = nil,
        itemCount: Int,
        isContextMenu: Bool = false,
        isSubmenu: Bool = false
    ) -> some View {
        self
            .awareState(id, key: "isOpen", value: isOpen)
            .awareState(id, key: "selectedItem", value: selectedItem ?? "")
            .awareState(id, key: "itemCount", value: "\(itemCount)")
            .awareState(id, key: "isContextMenu", value: isContextMenu)
            .awareState(id, key: "isSubmenu", value: isSubmenu)
            .awareMetadata(
                id,
                description: "Menu: \(isOpen ? "Open" : "Closed"), \(itemCount) items",
                type: .system
            )
    }
}

// MARK: - Popover State (Mac-Specific)

extension View {
    /// Track macOS popover state
    public func macPopoverState(
        _ id: String,
        isPresented: Bool,
        edge: String? = nil,
        contentSize: String? = nil,
        behavior: String? = nil
    ) -> some View {
        self
            .awareState(id, key: "isPresented", value: isPresented)
            .awareState(id, key: "edge", value: edge ?? "")
            .awareState(id, key: "contentSize", value: contentSize ?? "")
            .awareState(id, key: "behavior", value: behavior ?? "")
            .awareMetadata(
                id,
                description: "Popover: \(isPresented ? "Presented" : "Dismissed")",
                type: .navigation
            )
    }
}

// MARK: - Preferences State (Mac-Specific)

extension View {
    /// Track macOS preferences window state
    public func macPreferencesState(
        _ id: String,
        isPresented: Bool,
        selectedTab: String? = nil,
        tabCount: Int,
        canDismiss: Bool = true
    ) -> some View {
        self
            .awareState(id, key: "isPresented", value: isPresented)
            .awareState(id, key: "selectedTab", value: selectedTab ?? "")
            .awareState(id, key: "tabCount", value: "\(tabCount)")
            .awareState(id, key: "canDismiss", value: canDismiss)
            .awareMetadata(
                id,
                description: "Preferences: \(isPresented ? "Open" : "Closed"), tab: \(selectedTab ?? "none")",
                type: .navigation
            )
    }
}

// MARK: - Status Bar State (Mac-Specific)

extension View {
    /// Track macOS status bar item state
    public func macStatusBarState(
        _ id: String,
        isVisible: Bool,
        isActive: Bool = false,
        iconName: String? = nil,
        hasMenu: Bool = true
    ) -> some View {
        self
            .awareState(id, key: "isVisible", value: isVisible)
            .awareState(id, key: "isActive", value: isActive)
            .awareState(id, key: "iconName", value: iconName ?? "")
            .awareState(id, key: "hasMenu", value: hasMenu)
            .awareMetadata(
                id,
                description: "Status bar: \(isVisible ? "Visible" : "Hidden"), \(isActive ? "Active" : "Inactive")",
                type: .system
            )
    }
}

// MARK: - Document State (Mac-Specific)

extension View {
    /// Track macOS document window state
    public func macDocumentState(
        _ id: String,
        hasUnsavedChanges: Bool,
        documentPath: String? = nil,
        isReadOnly: Bool = false,
        canUndo: Bool = false,
        canRedo: Bool = false,
        autosavesInPlace: Bool = true
    ) -> some View {
        self
            .awareState(id, key: "hasUnsavedChanges", value: hasUnsavedChanges)
            .awareState(id, key: "documentPath", value: documentPath ?? "")
            .awareState(id, key: "isReadOnly", value: isReadOnly)
            .awareState(id, key: "canUndo", value: canUndo)
            .awareState(id, key: "canRedo", value: canRedo)
            .awareState(id, key: "autosavesInPlace", value: autosavesInPlace)
            .awareMetadata(
                id,
                description: "Document: \(hasUnsavedChanges ? "Modified" : "Clean"), \(isReadOnly ? "Read-only" : "Editable")",
                type: .fileSystem
            )
    }
}

// MARK: - Statistics

extension View {
    /// Get modifier statistics
    public static var macConvenienceModifierCount: Int {
        return 21 // 12 ported from iOS + 9 Mac-specific
    }

    public static var macPortedModifierCount: Int {
        return 12
    }

    public static var macSpecificModifierCount: Int {
        return 9
    }
}

#endif // os(macOS)
