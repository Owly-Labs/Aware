//
//  AwareModifiers.swift
//  Aware
//
//  View modifiers for LLM UI awareness.
//  Automatically captures view frame, visual properties, and lifecycle events.
//

import SwiftUI

// MARK: - Aware Modifier

/// View modifier that captures visual properties and registers for snapshots
struct AwareModifier: ViewModifier {
    let viewId: String
    let label: String?
    let captureVisuals: Bool
    let parentId: String?
    let ttl: TimeInterval?

    @State private var capturedFrame: CGRect = .zero
    @Environment(\.colorScheme) private var colorScheme
    // AppState is optional - only available in Breathe IDE
    // // @Environment(AppState.self) private var appState

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(viewId)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            capturedFrame = geo.frame(in: .global)
                            registerView(frame: capturedFrame)
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            capturedFrame = newFrame
                            updateFrame(newFrame)
                        }
                }
            )
            .onDisappear {
                Task { @MainActor in
                    Aware.shared.unregisterView(viewId)
                    await AwareLogger.shared.disappeared(viewId)
                }
            }
    }

    private func registerView(frame: CGRect) {
        Task { @MainActor in
            Aware.shared.registerView(
                viewId,
                label: label,
                isContainer: false,
                parentId: parentId,
                projectId: nil, // appState.currentAwareProject?.id.uuidString,
                sessionId: nil, // appState.currentSessionId,
                ttl: ttl
            )
            let visual = captureVisuals ? captureVisualProperties(frame: frame) : nil
            Aware.shared.updateView(viewId, frame: frame, visual: visual)
            await AwareLogger.shared.appeared(viewId, label)
        }
    }

    private func updateFrame(_ frame: CGRect) {
        Task { @MainActor in
            let visual = captureVisuals ? captureVisualProperties(frame: frame) : nil
            Aware.shared.updateView(viewId, frame: frame, visual: visual)
        }
    }

    private func captureVisualProperties(frame: CGRect) -> AwareSnapshot {
        AwareSnapshot(
            frame: frame,
            opacity: 1.0,
            isHidden: false
        )
    }
}

// MARK: - Container Modifier

/// View modifier that marks a container for hierarchical snapshot capture
struct AwareContainerModifier: ViewModifier {
    let containerId: String
    let label: String?
    let parentId: String?
    let ttl: TimeInterval?

    @State private var capturedFrame: CGRect = .zero
    // @Environment(AppState.self) private var appState

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(containerId)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            capturedFrame = geo.frame(in: .global)
                            registerContainer(frame: capturedFrame)
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            capturedFrame = newFrame
                            updateFrame(newFrame)
                        }
                }
            )
            .onDisappear {
                Task { @MainActor in
                    Aware.shared.unregisterView(containerId)
                    await AwareLogger.shared.disappeared(containerId)
                }
            }
    }

    private func registerContainer(frame: CGRect) {
        Task { @MainActor in
            Aware.shared.registerView(
                containerId,
                label: label,
                isContainer: true,
                parentId: parentId,
                projectId: nil, // appState.currentAwareProject?.id.uuidString,
                sessionId: nil, // appState.currentSessionId,
                ttl: ttl
            )
            Aware.shared.updateFrame(containerId, frame: frame)
            await AwareLogger.shared.appeared(containerId, label)
        }
    }

    private func updateFrame(_ frame: CGRect) {
        Task { @MainActor in
            Aware.shared.updateFrame(containerId, frame: frame)
        }
    }
}

// MARK: - Button Modifier

/// Specialized modifier for buttons that captures tap events
struct AwareButtonModifier: ViewModifier {
    let buttonId: String
    let label: String
    let parentId: String?
    let ttl: TimeInterval?

    @State private var capturedFrame: CGRect = .zero
    // @Environment(AppState.self) private var appState

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(buttonId)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            capturedFrame = geo.frame(in: .global)
                            registerButton(frame: capturedFrame)
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            capturedFrame = newFrame
                            updateFrame(newFrame)
                        }
                }
            )
            .onChange(of: label) { _, newLabel in
                updateLabel(newLabel, frame: capturedFrame)
            }
            .onDisappear {
                Task { @MainActor in
                    Aware.shared.unregisterView(buttonId)
                }
            }
    }

    private func registerButton(frame: CGRect) {
        Task { @MainActor in
            Aware.shared.registerView(
                buttonId,
                label: "Button: \(label)",
                parentId: parentId,
                projectId: nil, // appState.currentAwareProject?.id.uuidString,
                sessionId: nil, // appState.currentSessionId,
                ttl: ttl
            )
            let visual = AwareSnapshot(
                frame: frame,
                text: label,
                opacity: 1.0,
                isHidden: false
            )
            Aware.shared.updateView(buttonId, frame: frame, visual: visual)
        }
    }

    private func updateLabel(_ newLabel: String, frame: CGRect) {
        Task { @MainActor in
            Aware.shared.registerView(
                buttonId,
                label: "Button: \(newLabel)",
                parentId: parentId,
                projectId: nil, // appState.currentAwareProject?.id.uuidString,
                sessionId: nil, // appState.currentSessionId,
                ttl: ttl
            )
            let visual = AwareSnapshot(
                frame: frame,
                text: newLabel,
                opacity: 1.0,
                isHidden: false
            )
            Aware.shared.updateView(buttonId, frame: frame, visual: visual)
        }
    }

    private func updateFrame(_ frame: CGRect) {
        Task { @MainActor in
            Aware.shared.updateFrame(buttonId, frame: frame)
        }
    }
}

// MARK: - Text Modifier

/// Specialized modifier for text views that captures content
struct AwareTextModifier: ViewModifier {
    let textId: String
    let text: String
    let parentId: String?
    let ttl: TimeInterval?

    @State private var capturedFrame: CGRect = .zero
    // @Environment(AppState.self) private var appState

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(textId)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            capturedFrame = geo.frame(in: .global)
                            registerText(frame: capturedFrame)
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            capturedFrame = newFrame
                            updateFrame(newFrame)
                        }
                }
            )
            .onDisappear {
                Task { @MainActor in
                    Aware.shared.unregisterView(textId)
                }
            }
    }

    private func registerText(frame: CGRect) {
        Task { @MainActor in
            Aware.shared.registerView(
                textId,
                label: "Text",
                parentId: parentId,
                projectId: nil, // appState.currentAwareProject?.id.uuidString,
                sessionId: nil, // appState.currentSessionId,
                ttl: ttl
            )
            let visual = AwareSnapshot(
                frame: frame,
                text: text,
                opacity: 1.0,
                isHidden: false
            )
            Aware.shared.updateView(textId, frame: frame, visual: visual)
        }
    }

    private func updateFrame(_ frame: CGRect) {
        Task { @MainActor in
            let visual = AwareSnapshot(
                frame: capturedFrame,
                text: text
            )
            Aware.shared.updateView(textId, frame: frame, visual: visual)
        }
    }
}

// MARK: - Action Registration Modifier

/// Modifier that registers action callbacks
private struct AwareActionModifier: ViewModifier {
    let id: String
    let action: @MainActor () async -> Void

    func body(content: Content) -> some View {
        MainActor.assumeIsolated {
            Aware.shared.registerAction(id, callback: action)
        }

        return content
            .onDisappear {
                Aware.shared.unregisterAction(id)
            }
    }
}

// MARK: - View Extensions

public extension View {
    /// Make this view aware for LLM feedback
    func aware(
        _ id: String,
        label: String? = nil,
        captureVisuals: Bool = true,
        parent: String? = nil,
        ttl: TimeInterval? = nil
    ) -> some View {
        modifier(AwareModifier(
            viewId: id,
            label: label,
            captureVisuals: captureVisuals,
            parentId: parent,
            ttl: ttl
        ))
    }

    /// Mark as container for hierarchical snapshot capture
    func awareContainer(
        _ id: String,
        label: String? = nil,
        parent: String? = nil,
        ttl: TimeInterval? = nil
    ) -> some View {
        modifier(AwareContainerModifier(
            containerId: id,
            label: label,
            parentId: parent,
            ttl: ttl
        ))
    }

    /// Mark as button with tap tracking
    func awareButton(
        _ id: String,
        label: String,
        parent: String? = nil,
        ttl: TimeInterval? = nil
    ) -> some View {
        modifier(AwareButtonModifier(
            buttonId: id,
            label: label,
            parentId: parent,
            ttl: ttl
        ))
    }

    /// Mark as text with content tracking
    func awareText(
        _ id: String,
        text: String,
        parent: String? = nil,
        ttl: TimeInterval? = nil
    ) -> some View {
        modifier(AwareTextModifier(
            textId: id,
            text: text,
            parentId: parent,
            ttl: ttl
        ))
    }

    /// Register a state value for snapshot capture
    func awareState<T>(_ viewId: String, key: String, value: T) -> some View {
        self.onAppear {
            // Delay state registration to next run loop to ensure container is registered first
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    Aware.shared.registerState(viewId, key: key, value: String(describing: value))
                }
            }
        }
        .onChange(of: String(describing: value)) { _, newValue in
            MainActor.assumeIsolated {
                Aware.shared.registerState(viewId, key: key, value: newValue)
            }
        }
    }

    /// Register a direct action callback for LLM-controlled testing
    func awareAction(_ id: String, action: @escaping @MainActor () async -> Void) -> some View {
        modifier(AwareActionModifier(id: id, action: action))
    }

    /// Complete button registration with action metadata
    func awareActionButton(
        _ id: String,
        label: String,
        action: String,
        type: AwareActionMetadata.ActionType = .mutation,
        isDestructive: Bool = false,
        shortcut: String? = nil,
        parent: String? = nil,
        ttl: TimeInterval? = nil
    ) -> some View {
        self
            .awareButton(id, label: label, parent: parent, ttl: ttl)
            .awareMetadata(
                id,
                description: action,
                type: type,
                isDestructive: isDestructive,
                shortcut: shortcut
            )
    }

    /// Complete button registration with action callback for LLM testing
    @ViewBuilder
    func awareTappable(
        _ id: String,
        label: String,
        description: String,
        action: @escaping @MainActor () async -> Void,
        type: AwareActionMetadata.ActionType = .mutation,
        isDestructive: Bool = false,
        parent: String? = nil,
        ttl: TimeInterval? = nil
    ) -> some View {
        self
            .awareActionButton(
                id,
                label: label,
                action: description,
                type: type,
                isDestructive: isDestructive,
                parent: parent,
                ttl: ttl
            )
            .awareAction(id, action: action)
    }

    /// Input field registration for LLM testing
    @ViewBuilder
    func awareInput(
        id: String,
        label: String,
        binding: Binding<String>
    ) -> some View {
        self
            .awareState(id, key: "value", value: binding.wrappedValue)
            .awareState(id, key: "label", value: label)
            .onChange(of: binding.wrappedValue) { _, newValue in
                MainActor.assumeIsolated {
                    Aware.shared.registerState(id, key: "value", value: newValue)
                }
            }
    }

    /// Batch state registration - registers multiple state keys at once
    /// More efficient than chaining multiple `.awareState()` calls
    ///
    /// Example:
    /// ```swift
    /// .awareStateGroup("songDetail", [
    ///     "title": song.title,
    ///     "artist": song.artist,
    ///     "duration": duration,
    ///     "isPlaying": isPlaying
    /// ])
    /// ```
    func awareStateGroup(_ viewId: String, _ states: [String: Any]) -> some View {
        // Register all states immediately to avoid race conditions
        Task { @MainActor in
            for (key, value) in states {
                Aware.shared.registerState(viewId, key: key, value: String(describing: value))
            }
        }

        return self
            .onAppear {
                MainActor.assumeIsolated {
                    for (key, value) in states {
                        Aware.shared.registerState(viewId, key: key, value: String(describing: value))
                    }
                }
            }
    }
}

// MARK: - View Lifecycle Tracking

public extension View {
    /// Track view lifecycle with appear/disappear metrics
    /// Useful for understanding dynamic content patterns
    ///
    /// Tracked metrics:
    /// - appearCount: Number of times view appeared
    /// - lastAppearTime: Timestamp of most recent appearance
    /// - totalVisibleDuration: Cumulative time view was visible
    ///
    /// Example:
    /// ```swift
    /// SomeView()
    ///     .awareLifecycle("myView", label: "My View")
    /// ```
    func awareLifecycle(_ viewId: String, label: String? = nil) -> some View {
        AwareLifecycleModifier(viewId: viewId, label: label, content: self)
    }
}

/// View modifier that tracks lifecycle metrics
struct AwareLifecycleModifier<Content: View>: View {
    let viewId: String
    let label: String?
    let content: Content

    @State private var appearTime: Date?
    @State private var appearCount: Int = 0

    var body: some View {
        content
            .onAppear {
                Task { @MainActor in
                    appearTime = Date()
                    appearCount += 1

                    Aware.shared.registerState(viewId, key: "_appearCount", value: String(appearCount))
                    Aware.shared.registerState(viewId, key: "_lastAppearTime", value: ISO8601DateFormatter().string(from: Date()))
                    Aware.shared.registerState(viewId, key: "_lifecycle", value: "appeared")

                    #if DEBUG
                    await AwareLogger.shared.log("[\(viewId)] Appeared (count: \(appearCount))")
                    #endif
                }
            }
            .onDisappear {
                Task { @MainActor in
                    if let appearTime = appearTime {
                        let duration = Date().timeIntervalSince(appearTime)
                        Aware.shared.registerState(viewId, key: "_lastVisibleDuration", value: String(format: "%.2f", duration))
                        Aware.shared.registerState(viewId, key: "_lifecycle", value: "disappeared")

                        #if DEBUG
                        await AwareLogger.shared.log("[\(viewId)] Disappeared (duration: \(String(format: "%.2f", duration))s)")
                        #endif
                    }
                }
            }
    }
}

// MARK: - State Validation (DEBUG only)

#if DEBUG
public extension View {
    /// Development-time validation: warns when state keys are accessed but never updated
    /// Only active in DEBUG builds
    ///
    /// Example:
    /// ```swift
    /// .awareState("view", key: "count", value: count)
    /// .awareValidateState("view", key: "count", expectedUpdateFrequency: .perSecond)
    /// ```
    func awareValidateState(
        _ viewId: String,
        key: String,
        expectedUpdateFrequency: StateUpdateFrequency = .perMinute
    ) -> some View {
        AwareStateValidationModifier(
            viewId: viewId,
            key: key,
            expectedFrequency: expectedUpdateFrequency,
            content: self
        )
    }
}

/// Expected update frequency for state validation
public enum StateUpdateFrequency {
    case perSecond    // Updates every ~1s (e.g., currentTime in media player)
    case perFiveSeconds  // Updates every ~5s (e.g., battery level)
    case perMinute    // Updates every ~60s (e.g., date/time display)
    case perHour      // Updates every ~3600s (e.g., weather data)
    case never        // Never updates after initial registration

    var warningThreshold: TimeInterval {
        switch self {
        case .perSecond: return 5.0
        case .perFiveSeconds: return 15.0
        case .perMinute: return 180.0
        case .perHour: return 7200.0
        case .never: return .infinity
        }
    }
}

/// View modifier that validates state update patterns (DEBUG only)
struct AwareStateValidationModifier<Content: View>: View {
    let viewId: String
    let key: String
    let expectedFrequency: StateUpdateFrequency
    let content: Content

    @State private var lastUpdateTime: Date?
    @State private var updateCount: Int = 0

    var body: some View {
        content
            .onAppear {
                Task { @MainActor in
                    lastUpdateTime = Date()
                    updateCount = 0

                    // Schedule validation check
                    DispatchQueue.main.asyncAfter(deadline: .now() + expectedFrequency.warningThreshold) {
                        validateStateUpdates()
                    }
                }
            }
            .onChange(of: Aware.shared.stateRegistry[viewId]?[key]) { _, _ in
                Task { @MainActor in
                    lastUpdateTime = Date()
                    updateCount += 1
                }
            }
    }

    private func validateStateUpdates() {
        guard let lastUpdate = lastUpdateTime else { return }

        let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)

        if timeSinceUpdate > expectedFrequency.warningThreshold && expectedFrequency != .static {
            let warning = """
            [Aware] STATE VALIDATION WARNING:
            View: \(viewId)
            Key: \(key)
            Expected frequency: \(expectedFrequency)
            Last update: \(String(format: "%.1f", timeSinceUpdate))s ago
            Update count: \(updateCount)
            Suggestion: State may be stale or not updating as expected
            """
            print(warning)
            Task { @MainActor in
                await AwareLogger.shared.log(warning)
            }
        }
    }
}
#endif
