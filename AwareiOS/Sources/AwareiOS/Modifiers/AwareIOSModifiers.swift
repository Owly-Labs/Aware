//
//  AwareIOSModifiers.swift
//  AwareiOS
//
//  iOS-specific SwiftUI modifiers for enhanced LLM UI awareness.
//  Based on AetherSing's UIAware modifier system.
//
//  Provides specialized modifiers for different iOS view types.
//  Note: Requires AwareCore API extensions (registerView with type enum, addMetadata, etc.)
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
    public func uiButton(
        _ id: String,
        label: String,
        action: (@Sendable @MainActor () async -> Void)? = nil
    ) -> some View {
        self.modifier(UIButtonModifier(id: id, label: label, action: action))
    }

    /// Enhanced text field modifier with focus tracking
    /// - Parameters:
    ///   - id: Unique identifier for the view
    ///   - text: Binding to the text value
    ///   - label: Human-readable label
    ///   - placeholder: Placeholder text
    ///   - isFocused: Optional binding for focus state
    /// - Returns: Modified view
    public func uiTextField(
        _ id: String,
        text: Binding<String>,
        label: String,
        placeholder: String? = nil,
        isFocused: Binding<Bool>? = nil
    ) -> some View {
        self.modifier(UITextFieldModifier(
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
    public func uiSecureField(
        _ id: String,
        text: Binding<String>,
        label: String,
        placeholder: String? = nil
    ) -> some View {
        self.modifier(UISecureFieldModifier(
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
    public func uiToggle(
        _ id: String,
        isOn: Binding<Bool>,
        label: String
    ) -> some View {
        self.modifier(UIToggleModifier(
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
    public func uiPicker<T: Hashable>(
        _ id: String,
        selection: Binding<T>,
        label: String,
        options: [T]
    ) -> some View {
        self.modifier(UIPickerModifier(
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
    public func uiSlider(
        _ id: String,
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        label: String
    ) -> some View {
        self.modifier(UISliderModifier(
            id: id,
            value: value,
            range: range,
            label: label
        ))
    }
}

// MARK: - Button Modifier

struct UIButtonModifier: ViewModifier {
    let id: String
    let label: String
    let action: (@Sendable @MainActor () async -> Void)?

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
                        }
                }
            )
            .onDisappear {
                ModifierRegistrationHelper.unregisterView(id: id)
            }
    }

    private func registerButton() {
        ModifierRegistrationHelper.registerView(
            id: id,
            label: label,
            type: "button",
            additionalState: ModifierRegistrationHelper.buttonState(hasCallback: action != nil)
        )

        if let action = action {
            ModifierRegistrationHelper.registerActionCallback(id: id, action: action)
        }
    }
}

// MARK: - Text Field Modifier

struct UITextFieldModifier: ViewModifier {
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
                ModifierRegistrationHelper.unregisterView(id: id)
            }
    }

    private func registerTextField() {
        var additionalState = ModifierRegistrationHelper.textFieldState(placeholder: placeholder)
        additionalState["text"] = text.wrappedValue
        additionalState["isEmpty"] = String(text.wrappedValue.isEmpty)
        additionalState["charCount"] = String(text.wrappedValue.count)
        additionalState["isFocused"] = String(focused)

        ModifierRegistrationHelper.registerView(
            id: id,
            label: label,
            type: "textField",
            additionalState: additionalState
        )
    }

    private func updateTextState(_ newValue: String) {
        ModifierRegistrationHelper.updateTextFieldState(id: id, text: newValue)
    }

    private func updateFocusState(_ newValue: Bool) {
        ModifierRegistrationHelper.updateTextFieldState(id: id, text: text.wrappedValue, focused: newValue)
    }
}

// MARK: - Secure Field Modifier

struct UISecureFieldModifier: ViewModifier {
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
                }
            )
            .onChange(of: text.wrappedValue) { _, newValue in
                updateTextState(newValue)
            }
            .onDisappear {
                ModifierRegistrationHelper.unregisterView(id: id)
            }
    }

    private func registerSecureField() {
        var additionalState = ModifierRegistrationHelper.textFieldState(placeholder: placeholder, secure: true)
        additionalState["isEmpty"] = String(text.wrappedValue.isEmpty)
        additionalState["charCount"] = String(text.wrappedValue.count)

        ModifierRegistrationHelper.registerView(
            id: id,
            label: label,
            type: "secureField",
            additionalState: additionalState
        )
    }

    private func updateTextState(_ newValue: String) {
        ModifierRegistrationHelper.updateState(id: id, updates: [
            "isEmpty": String(newValue.isEmpty),
            "charCount": String(newValue.count)
        ])
    }
}

// MARK: - Toggle Modifier

struct UIToggleModifier: ViewModifier {
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
                }
            )
            .onChange(of: isOn.wrappedValue) { _, newValue in
                updateToggleState(newValue)
            }
            .onDisappear {
                ModifierRegistrationHelper.unregisterView(id: id)
            }
    }

    private func registerToggle() {
        ModifierRegistrationHelper.registerView(
            id: id,
            label: label,
            type: "toggle",
            additionalState: ["isOn": String(isOn.wrappedValue)]
        )
    }

    private func updateToggleState(_ newValue: Bool) {
        ModifierRegistrationHelper.updateToggleState(id: id, isOn: newValue)
    }
}

// MARK: - Picker Modifier

struct UIPickerModifier<T: Hashable>: ViewModifier {
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
                }
            )
            .onChange(of: selection.wrappedValue) { _, newValue in
                updateSelectionState(newValue)
            }
            .onDisappear {
                ModifierRegistrationHelper.unregisterView(id: id)
            }
    }

    private func registerPicker() {
        let index = options.firstIndex(of: selection.wrappedValue) ?? 0
        let optionStrings = options.map { String(describing: $0) }

        var additionalState = ModifierRegistrationHelper.pickerState(options: optionStrings, selectedIndex: index)
        additionalState["selection"] = String(describing: selection.wrappedValue)

        ModifierRegistrationHelper.registerView(
            id: id,
            label: label,
            type: "picker",
            additionalState: additionalState
        )
    }

    private func updateSelectionState(_ newValue: T) {
        let index = options.firstIndex(of: newValue) ?? 0
        ModifierRegistrationHelper.updateState(id: id, updates: [
            "selection": String(describing: newValue),
            "selectedIndex": String(index)
        ])
    }
}

// MARK: - Slider Modifier

struct UISliderModifier: ViewModifier {
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
                }
            )
            .onChange(of: value.wrappedValue) { _, newValue in
                updateValueState(newValue)
            }
            .onDisappear {
                ModifierRegistrationHelper.unregisterView(id: id)
            }
    }

    private func registerSlider() {
        ModifierRegistrationHelper.registerView(
            id: id,
            label: label,
            type: "slider",
            additionalState: [:]
        )

        ModifierRegistrationHelper.updateSliderState(
            id: id,
            value: value.wrappedValue,
            min: range.lowerBound,
            max: range.upperBound
        )
    }

    private func updateValueState(_ newValue: Double) {
        ModifierRegistrationHelper.updateSliderState(
            id: id,
            value: newValue,
            min: range.lowerBound,
            max: range.upperBound
        )
    }
}

#endif // os(iOS)
