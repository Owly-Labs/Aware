//
//  AwareLLMSnapshotGenerator.swift
//  AwareCore
//
//  Generates LLM-optimized snapshots with intent inference and test suggestions.
//

import Foundation

// MARK: - LLM Snapshot Generation

extension Aware {
    /// Generate LLM-optimized snapshot
    public func generateLLMSnapshot() async -> String {
        await MainActor.run {
            do {
                // 1. Get all visible views
                let visibleIds = registeredViewIds.filter { id in
                    describeView(id)?.isVisible == true
                }

                guard !visibleIds.isEmpty else {
                    throw AwareError.snapshotGenerationFailed(
                        reason: "No views registered",
                        format: "llm"
                    )
                }

                // 2. Build view descriptors from visible views
                var elements: [ElementDescriptor] = []
                var rootLabel: String?
                var rootId: String?

                for id in visibleIds {
                    guard let desc = describeView(id) else { continue }

                    if rootLabel == nil {
                        rootLabel = desc.label
                        rootId = id
                    }

                    // Build element descriptor
                    let elementType = inferElementType(from: desc)
                    let elementState = inferElementState(from: desc)
                    let nextAction = generateNextAction(label: desc.label, type: elementType)
                    let exampleValue = generateExampleValue(label: desc.label, type: elementType)

                    let element = ElementDescriptor(
                        id: id,
                        type: elementType,
                        label: desc.label ?? id,
                        value: desc.state?["value"] ?? "",
                        state: elementState,
                        enabled: desc.state?["enabled"] != "false",
                        visible: desc.isVisible,
                        focused: desc.visual?.isFocused,
                        required: desc.state?["required"] == "true" ? true : nil,
                        validation: desc.state?["validation"],
                        errorMessage: desc.state?["error"],
                        placeholder: desc.state?["placeholder"],
                        nextAction: nextAction,
                        exampleValue: exampleValue,
                        action: desc.action?.actionDescription,
                        nextView: nil,  // Not available in current model
                        failureView: nil,
                        dependencies: desc.behavior?.dependencies,
                        accessibilityLabel: nil,  // Not in AwareSnapshot
                        accessibilityHint: nil,   // Not in AwareSnapshot
                        frame: desc.frame.map {
                            FrameDescriptor(
                                x: Double($0.minX),
                                y: Double($0.minY),
                                width: Double($0.width),
                                height: Double($0.height)
                            )
                        }
                    )

                    elements.append(element)
                }

                // 3. Infer intent and state for whole view
                let intent = inferIntent(label: rootLabel, id: rootId, elements: elements)
                let viewState = inferViewState(elements: elements)
                let testSuggestions = generateTestSuggestions(elements: elements)
                let commonErrors = getCommonErrors(for: rootLabel ?? "")

                // 4. Create view descriptor
                let viewDescriptor = ViewDescriptor(
                    id: rootId ?? "root",
                    type: rootLabel ?? "View",
                    intent: intent,
                    state: viewState,
                    elements: elements,
                    testSuggestions: testSuggestions,
                    commonErrors: commonErrors,
                    canNavigateBack: nil,
                    previousView: nil,
                    modalPresentation: nil
                )

                // 5. Create and encode snapshot (meta omitted for token efficiency)
                let snapshot = AwareLLMSnapshot(view: viewDescriptor, meta: nil)
                return try snapshot.toJSON()

            } catch {
                AwareError.snapshotGenerationFailed(
                    reason: "LLM snapshot generation failed: \(error.localizedDescription)",
                    format: "llm"
                ).log()
                return "{\"error\": \"Snapshot generation failed: \(error.localizedDescription)\"}"
            }
        }
    }

    // MARK: - Intent Inference

    private func inferIntent(label: String?, id: String?, elements: [ElementDescriptor]) -> String {
        let labelLower = (label ?? "").lowercased()
        let idLower = (id ?? "").lowercased()

        // Check for specific view types
        if labelLower.contains("login") || idLower.contains("login") {
            return "Authenticate user with email and password"
        }

        if labelLower.contains("signup") || labelLower.contains("register") ||
           idLower.contains("signup") || idLower.contains("register") {
            return "Create new user account"
        }

        if labelLower.contains("dashboard") || labelLower.contains("home") ||
           idLower.contains("dashboard") || idLower.contains("home") {
            return "Show main user dashboard and navigation"
        }

        if labelLower.contains("profile") || idLower.contains("profile") {
            return "Display and edit user profile information"
        }

        if labelLower.contains("settings") || idLower.contains("settings") {
            return "Configure application settings and preferences"
        }

        if labelLower.contains("search") || idLower.contains("search") {
            return "Search and filter content"
        }

        if labelLower.contains("detail") || idLower.contains("detail") {
            return "Display detailed information"
        }

        if labelLower.contains("list") || idLower.contains("list") {
            return "Display list of items"
        }

        if labelLower.contains("form") || idLower.contains("form") {
            return "Collect user input via form"
        }

        if labelLower.contains("checkout") || labelLower.contains("payment") ||
           idLower.contains("checkout") || idLower.contains("payment") {
            return "Process payment and complete purchase"
        }

        // Infer from elements
        let hasTextFields = elements.contains { $0.type == .textField || $0.type == .secureField }
        let hasButtons = elements.contains { $0.type == .button }

        if hasTextFields && hasButtons {
            return "Collect user input and submit"
        }

        return "Display view content"
    }

    // MARK: - View State Inference

    private func inferViewState(elements: [ElementDescriptor]) -> ViewState {
        // Check for loading indicators
        if elements.contains(where: { $0.type == .activityIndicator }) {
            return .loading
        }

        // Check for error messages
        if elements.contains(where: {
            ($0.type == .text) &&
            ($0.label.lowercased().contains("error") ||
             $0.label.lowercased().contains("failed") ||
             $0.label.lowercased().contains("invalid"))
        }) {
            return .error
        }

        // Check for success indicators
        if elements.contains(where: {
            ($0.type == .text) &&
            ($0.label.lowercased().contains("success") ||
             $0.label.lowercased().contains("welcome") ||
             $0.label.lowercased().contains("complete"))
        }) {
            return .success
        }

        // Check if primary buttons are disabled
        let primaryButtons = elements.filter {
            $0.type == .button &&
            !$0.label.lowercased().contains("cancel") &&
            !$0.label.lowercased().contains("back")
        }

        if !primaryButtons.isEmpty && primaryButtons.allSatisfy({ !$0.enabled }) {
            return .disabled
        }

        return .ready
    }

    // MARK: - Element Type Inference

    private func inferElementType(from desc: AwareViewDescription) -> ElementType {
        let label = (desc.label ?? "").lowercased()
        let visual = desc.visual

        // Check action metadata
        if let action = desc.action {
            switch action.actionType {
            case .navigation: return .button
            case .destructive: return .button
            case .mutation: return .button
            default: break
            }
        }

        // Check visual hints
        if visual?.text != nil {
            return .text
        }

        // Check label patterns
        if label.contains("button") { return .button }
        if label.contains("field") || label.contains("input") {
            return label.contains("secure") || label.contains("password") ? .secureField : .textField
        }
        if label.contains("toggle") || label.contains("switch") { return .toggle }
        if label.contains("picker") || label.contains("select") { return .picker }
        if label.contains("slider") { return .slider }
        if label.contains("link") { return .link }
        if label.contains("image") { return .image }
        if label.contains("list") { return .list }
        if label.contains("activity") || label.contains("spinner") || label.contains("loading") {
            return .activityIndicator
        }

        return .container
    }

    // MARK: - Element State Inference

    private func inferElementState(from desc: AwareViewDescription) -> ElementState {
        // Check state values
        if let state = desc.state {
            if state["error"] != nil || state["isError"] == "true" {
                return .error
            }
            if state["isLoading"] == "true" {
                return .loading
            }
            if let value = state["value"], !value.isEmpty {
                if let isValid = state["isValid"] {
                    return isValid == "true" ? .valid : .invalid
                }
                return .filled
            }
        }

        // Check visual focus
        if desc.visual?.isFocused == true {
            return .focused
        }

        // Check enabled state
        if !desc.isVisible {
            return .disabled
        }

        return .empty
    }

    // MARK: - Next Action Generation

    private func generateNextAction(label: String?, type: ElementType) -> String {
        let labelText = label ?? "element"
        let labelLower = labelText.lowercased()

        switch type {
        case .textField:
            if labelLower.contains("email") {
                return "Enter email address"
            } else if labelLower.contains("phone") {
                return "Enter phone number"
            } else if labelLower.contains("name") {
                return "Enter your name"
            } else if labelLower.contains("search") {
                return "Enter search query"
            } else {
                return "Enter \(labelLower)"
            }

        case .secureField:
            return "Enter password"

        case .button:
            if labelLower.contains("submit") || labelLower.contains("save") || labelLower.contains("login") {
                return "Tap to submit"
            } else if labelLower.contains("cancel") || labelLower.contains("close") {
                return "Tap to cancel"
            } else if labelLower.contains("delete") || labelLower.contains("remove") {
                return "Tap to delete"
            } else {
                return "Tap to \(labelLower)"
            }

        case .toggle:
            return "Toggle \(labelLower)"

        case .picker:
            return "Select \(labelLower)"

        case .slider:
            return "Adjust \(labelLower)"

        case .link:
            return "Navigate to \(labelLower)"

        default:
            return "Interact with \(labelLower)"
        }
    }

    // MARK: - Example Value Generation

    private func generateExampleValue(label: String?, type: ElementType) -> String? {
        guard let label = label else { return nil }
        let labelLower = label.lowercased()

        // Email
        if labelLower.contains("email") {
            return "test@example.com"
        }

        // Phone
        if labelLower.contains("phone") {
            return "+1234567890"
        }

        // Name
        if labelLower.contains("name") {
            if labelLower.contains("first") {
                return "John"
            } else if labelLower.contains("last") {
                return "Doe"
            } else {
                return "John Doe"
            }
        }

        // Username
        if labelLower.contains("username") {
            return "testuser"
        }

        // Password
        if labelLower.contains("password") || type == .secureField {
            return "••••••••"
        }

        // Address
        if labelLower.contains("address") {
            return "123 Main St, City, State 12345"
        }

        // ZIP/Postal
        if labelLower.contains("zip") || labelLower.contains("postal") {
            return "12345"
        }

        // Credit card
        if labelLower.contains("card") || labelLower.contains("credit") {
            return "4242 4242 4242 4242"
        }

        // Date
        if labelLower.contains("date") {
            return "2026-01-14"
        }

        return nil
    }

    // MARK: - Test Suggestion Generation

    private func generateTestSuggestions(elements: [ElementDescriptor]) -> [String] {
        var suggestions: [String] = []

        // 1. Suggest filling text fields
        let textFields = elements.filter {
            $0.type == .textField || $0.type == .secureField
        }

        for field in textFields {
            if let example = field.exampleValue {
                suggestions.append("Fill \(field.label) with '\(example)'")
            } else {
                suggestions.append("Fill \(field.label) field")
            }
        }

        // 2. Suggest primary action
        let primaryButtons = elements.filter {
            $0.type == .button &&
            !$0.label.lowercased().contains("cancel") &&
            !$0.label.lowercased().contains("back")
        }

        if let primaryButton = primaryButtons.first {
            suggestions.append("Tap '\(primaryButton.label)' button")
        }

        // 3. Suggest expected outcome
        if let nextView = primaryButtons.first?.nextView {
            suggestions.append("Expect navigation to \(nextView)")
        } else if !primaryButtons.isEmpty {
            suggestions.append("Expect state change or navigation")
        }

        // 4. Suggest validation tests
        if !textFields.isEmpty {
            suggestions.append("Test with invalid input")
            suggestions.append("Test with empty fields")
        }

        return suggestions
    }

    // MARK: - Common Errors

    private func getCommonErrors(for viewType: String) -> [String]? {
        let type = viewType.lowercased()

        if type.contains("login") {
            return [
                "User enters invalid email format",
                "User enters incorrect password",
                "Network timeout during authentication"
            ]
        }

        if type.contains("signup") || type.contains("register") {
            return [
                "Password too weak",
                "Email already registered",
                "Terms of service not accepted"
            ]
        }

        if type.contains("form") {
            return [
                "Required fields left empty",
                "Invalid format for specific fields",
                "Form submission without validation"
            ]
        }

        if type.contains("payment") || type.contains("checkout") {
            return [
                "Invalid credit card number",
                "Expired card",
                "Insufficient funds"
            ]
        }

        return nil
    }

    // MARK: - Helper Methods

    private func getDeviceName() -> String {
        #if os(iOS)
        return UIDevice.current.model
        #elseif os(macOS)
        return "Mac"
        #else
        return "Unknown"
        #endif
    }
}
