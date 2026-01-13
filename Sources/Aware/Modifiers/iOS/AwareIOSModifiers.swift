//
//  AwareIOSModifiers.swift
//  Aware
//
//  Created by AetherSing Team
//  iOS-specific SwiftUI modifiers for enhanced LLM UI awareness
//
//  Based on AetherSing's UIAware modifier system
//  Provides specialized modifiers for different iOS view types
//

#if os(iOS)
import SwiftUI

// MARK: - iOS-Specific View Modifiers

extension View {
    /// Enhanced button modifier with action callback registration
    /// - Parameters:
    ///   - id: Unique identifier for the view
    ///   - label: Human-readable label
    ///   - action: Action to execute on tap (enables ghost UI testing)
    /// - Returns: Modified view
    public func awareButton(
        _ id: String,
        label: String,
        action: (@MainActor () async -> Void)? = nil
    ) -> some View {
        self.modifier(AwareButtonModifier(id: id, label: label, action: action))
    }

    /// Enhanced text field modifier with focus tracking
    /// - Parameters:
    ///   - id: Unique identifier for the view
    ///   - text: Binding to the text value
    ///   - label: Human-readable label
    ///   - placeholder: Placeholder text
    ///   - isFocused: Optional binding for focus state
    /// - Returns: Modified view
    public func awareTextField(
        _ id: String,
        text: Binding<String>,
        label: String,
        placeholder: String? = nil,
        isFocused: Binding<Bool>? = nil
    ) -> some View {
        self.modifier(AwareTextFieldModifier(
            id: id,
            text: text,
            label: label,
            placeholder: placeholder,
            isFocused: isFocused
        ))
    }

    /// Enhanced secure field modifier
    /// - Parameters:
    ///   - id: Unique identifier for the view
    ///   - text: Binding to the text value
    ///   - label: Human-readable label
    ///   - placeholder: Placeholder text
    /// - Returns: Modified view
    public func awareSecureField(
        _ id: String,
        text: Binding<String>,
        label: String,
        placeholder: String? = nil
    ) -> some View {
        self.modifier(AwareSecureFieldModifier(
            id: id,
            text: text,
            label: label,
            placeholder: placeholder
        ))
    }

    /// Enhanced toggle modifier with state tracking
    /// - Parameters:
    ///   - id: Unique identifier for the view
    ///   - isOn: Binding to the toggle state
    ///   - label: Human-readable label
    /// - Returns: Modified view
    public func awareToggle(
        _ id: String,
        isOn: Binding<Bool>,
        label: String
    ) -> some View {
        self.modifier(AwareToggleModifier(
            id: id,
            isOn: isOn,
            label: label
        ))
    }

    /// Enhanced picker modifier with selection tracking
    /// - Parameters:
    ///   - id: Unique identifier for the view
    ///   - selection: Binding to the selected value
    ///   - label: Human-readable label
    ///   - options: Array of selectable options
    /// - Returns: Modified view
    public func awarePicker<T: Hashable>(
        _ id: String,
        selection: Binding<T>,
        label: String,
        options: [T]
    ) -> some View {
        self.modifier(AwarePickerModifier(
            id: id,
            selection: selection,
            label: label,
            options: options
        ))
    }

    /// Enhanced slider modifier with value tracking
    /// - Parameters:
    ///   - id: Unique identifier for the view
    ///   - value: Binding to the slider value
    ///   - range: Closed range for the slider
    ///   - label: Human-readable label
    /// - Returns: Modified view
    public func awareSlider(
        _ id: String,
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        label: String
    ) -> some View {
        self.modifier(AwareSliderModifier(
            id: id,
            value: value,
            range: range,
            label: label
        ))
    }
}

// MARK: - Button Modifier

struct AwareButtonModifier: ViewModifier {
    let id: String
    let label: String
    let action: (@MainActor () async -> Void)?

    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frame = geo.frame(in: .global)
                            registerButton()
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            frame = newFrame
                            updateFrame()
                        }
                }
            )
            .onDisappear {
                Task { @MainActor in
                    Aware.shared.unregisterView(id)
                }
            }
    }

    private func registerButton() {
        Task { @MainActor in
            // Register with main Aware service
            Aware.shared.registerView(
                id,
                label: label,
                type: .button,
                frame: frame
            )

            // Register action callback for ghost UI testing
            if let action = action {
                AwareIOSPlatform.shared.registerActionCallback(id, callback: action)
            }

            // Add metadata
            Aware.shared.addMetadata(id, key: "type", value: "button")
            Aware.shared.addMetadata(id, key: "actionable", value: "true")
            if action != nil {
                Aware.shared.addMetadata(id, key: "hasCallback", value: "true")
            }
        }
    }

    private func updateFrame() {
        Task { @MainActor in
            Aware.shared.updateView(id, frame: frame)
        }
    }
}

// MARK: - Text Field Modifier

struct AwareTextFieldModifier: ViewModifier {
    let id: String
    let text: Binding<String>
    let label: String
    let placeholder: String?
    let isFocused: Binding<Bool>?

    @State private var frame: CGRect = .zero
    @FocusState private var focused: Bool

    init(
        id: String,
        text: Binding<String>,
        label: String,
        placeholder: String?,
        isFocused: Binding<Bool>?
    ) {
        self.id = id
        self.text = text
        self.label = label
        self.placeholder = placeholder
        self.isFocused = isFocused
        if let isFocused = isFocused {
            self._focused = FocusState(initialValue: isFocused.wrappedValue)
        }
    }

    func body(content: Content) -> some View {
        content
            .focused($focused)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frame = geo.frame(in: .global)
                            registerTextField()
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            frame = newFrame
                            updateFrame()
                        }
                }
            )
            .onChange(of: text.wrappedValue) { _, newValue in
                updateTextState(newValue)
            }
            .onChange(of: focused) { _, newValue in
                updateFocusState(newValue)
                isFocused?.wrappedValue = newValue
            }
            .onDisappear {
                Task { @MainActor in
                    Aware.shared.unregisterView(id)
                }
            }
    }

    private func registerTextField() {
        Task { @MainActor in
            Aware.shared.registerView(
                id,
                label: label,
                type: .textField,
                frame: frame
            )

            Aware.shared.addState(id, key: "text", value: text.wrappedValue)
            Aware.shared.addState(id, key: "isEmpty", value: String(text.wrappedValue.isEmpty))
            Aware.shared.addState(id, key: "charCount", value: String(text.wrappedValue.count))
            Aware.shared.addState(id, key: "isFocused", value: String(focused))

            if let placeholder = placeholder {
                Aware.shared.addMetadata(id, key: "placeholder", value: placeholder)
            }
            Aware.shared.addMetadata(id, key: "type", value: "textField")
            Aware.shared.addMetadata(id, key: "actionable", value: "true")
        }
    }

    private func updateFrame() {
        Task { @MainActor in
            Aware.shared.updateView(id, frame: frame)
        }
    }

    private func updateTextState(_ newValue: String) {
        Task { @MainActor in
            Aware.shared.updateState(id, key: "text", value: newValue)
            Aware.shared.updateState(id, key: "isEmpty", value: String(newValue.isEmpty))
            Aware.shared.updateState(id, key: "charCount", value: String(newValue.count))
        }
    }

    private func updateFocusState(_ newValue: Bool) {
        Task { @MainActor in
            Aware.shared.updateState(id, key: "isFocused", value: String(newValue))
        }
    }
}

// MARK: - Secure Field Modifier

struct AwareSecureFieldModifier: ViewModifier {
    let id: String
    let text: Binding<String>
    let label: String
    let placeholder: String?

    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frame = geo.frame(in: .global)
                            registerSecureField()
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            frame = newFrame
                            updateFrame()
                        }
                }
            )
            .onChange(of: text.wrappedValue) { _, newValue in
                updateTextState(newValue)
            }
            .onDisappear {
                Task { @MainActor in
                    Aware.shared.unregisterView(id)
                }
            }
    }

    private func registerSecureField() {
        Task { @MainActor in
            Aware.shared.registerView(
                id,
                label: label,
                type: .secureField,
                frame: frame
            )

            Aware.shared.addState(id, key: "isEmpty", value: String(text.wrappedValue.isEmpty))
            Aware.shared.addState(id, key: "charCount", value: String(text.wrappedValue.count))

            if let placeholder = placeholder {
                Aware.shared.addMetadata(id, key: "placeholder", value: placeholder)
            }
            Aware.shared.addMetadata(id, key: "type", value: "secureField")
            Aware.shared.addMetadata(id, key: "actionable", value: "true")
            Aware.shared.addMetadata(id, key: "secure", value: "true")
        }
    }

    private func updateFrame() {
        Task { @MainActor in
            Aware.shared.updateView(id, frame: frame)
        }
    }

    private func updateTextState(_ newValue: String) {
        Task { @MainActor in
            Aware.shared.updateState(id, key: "isEmpty", value: String(newValue.isEmpty))
            Aware.shared.updateState(id, key: "charCount", value: String(newValue.count))
        }
    }
}

// MARK: - Toggle Modifier

struct AwareToggleModifier: ViewModifier {
    let id: String
    let isOn: Binding<Bool>
    let label: String

    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frame = geo.frame(in: .global)
                            registerToggle()
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            frame = newFrame
                            updateFrame()
                        }
                }
            )
            .onChange(of: isOn.wrappedValue) { _, newValue in
                updateToggleState(newValue)
            }
            .onDisappear {
                Task { @MainActor in
                    Aware.shared.unregisterView(id)
                }
            }
    }

    private func registerToggle() {
        Task { @MainActor in
            Aware.shared.registerView(
                id,
                label: label,
                type: .toggle,
                frame: frame
            )

            Aware.shared.addState(id, key: "isOn", value: String(isOn.wrappedValue))
            Aware.shared.addMetadata(id, key: "type", value: "toggle")
            Aware.shared.addMetadata(id, key: "actionable", value: "true")
        }
    }

    private func updateFrame() {
        Task { @MainActor in
            Aware.shared.updateView(id, frame: frame)
        }
    }

    private func updateToggleState(_ newValue: Bool) {
        Task { @MainActor in
            Aware.shared.updateState(id, key: "isOn", value: String(newValue))
        }
    }
}

// MARK: - Picker Modifier

struct AwarePickerModifier<T: Hashable>: ViewModifier {
    let id: String
    let selection: Binding<T>
    let label: String
    let options: [T]

    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frame = geo.frame(in: .global)
                            registerPicker()
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            frame = newFrame
                            updateFrame()
                        }
                }
            )
            .onChange(of: selection.wrappedValue) { _, newValue in
                updateSelectionState(newValue)
            }
            .onDisappear {
                Task { @MainActor in
                    Aware.shared.unregisterView(id)
                }
            }
    }

    private func registerPicker() {
        Task { @MainActor in
            Aware.shared.registerView(
                id,
                label: label,
                type: .picker,
                frame: frame
            )

            let index = options.firstIndex(of: selection.wrappedValue) ?? 0
            Aware.shared.addState(id, key: "selection", value: String(describing: selection.wrappedValue))
            Aware.shared.addState(id, key: "selectedIndex", value: String(index))
            Aware.shared.addState(id, key: "optionCount", value: String(options.count))

            Aware.shared.addMetadata(id, key: "type", value: "picker")
            Aware.shared.addMetadata(id, key: "actionable", value: "true")
            Aware.shared.addMetadata(id, key: "options", value: options.map { String(describing: $0) }.joined(separator: ","))
        }
    }

    private func updateFrame() {
        Task { @MainActor in
            Aware.shared.updateView(id, frame: frame)
        }
    }

    private func updateSelectionState(_ newValue: T) {
        Task { @MainActor in
            let index = options.firstIndex(of: newValue) ?? 0
            Aware.shared.updateState(id, key: "selection", value: String(describing: newValue))
            Aware.shared.updateState(id, key: "selectedIndex", value: String(index))
        }
    }
}

// MARK: - Slider Modifier

struct AwareSliderModifier: ViewModifier {
    let id: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let label: String

    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            frame = geo.frame(in: .global)
                            registerSlider()
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            frame = newFrame
                            updateFrame()
                        }
                }
            )
            .onChange(of: value.wrappedValue) { _, newValue in
                updateValueState(newValue)
            }
            .onDisappear {
                Task { @MainActor in
                    Aware.shared.unregisterView(id)
                }
            }
    }

    private func registerSlider() {
        Task { @MainActor in
            Aware.shared.registerView(
                id,
                label: label,
                type: .slider,
                frame: frame
            )

            let normalized = (value.wrappedValue - range.lowerBound) / (range.upperBound - range.lowerBound)
            Aware.shared.addState(id, key: "value", value: String(format: "%.2f", value.wrappedValue))
            Aware.shared.addState(id, key: "normalized", value: String(format: "%.2f", normalized))
            Aware.shared.addState(id, key: "min", value: String(format: "%.2f", range.lowerBound))
            Aware.shared.addState(id, key: "max", value: String(format: "%.2f", range.upperBound))

            Aware.shared.addMetadata(id, key: "type", value: "slider")
            Aware.shared.addMetadata(id, key: "actionable", value: "true")
        }
    }

    private func updateFrame() {
        Task { @MainActor in
            Aware.shared.updateView(id, frame: frame)
        }
    }

    private func updateValueState(_ newValue: Double) {
        Task { @MainActor in
            let normalized = (newValue - range.lowerBound) / (range.upperBound - range.lowerBound)
            Aware.shared.updateState(id, key: "value", value: String(format: "%.2f", newValue))
            Aware.shared.updateState(id, key: "normalized", value: String(format: "%.2f", normalized))
        }
    }
}

#endif // os(iOS)