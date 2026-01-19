//
//  FormPatterns.swift
//  Breathe
//
//  Form pattern examples extracted from CommonPatterns.swift
//  Phase 3.6 Architecture Refactoring
//

import Foundation

@MainActor
extension CommonPatternsLibrary {
    // MARK: - Form Patterns

    static func basicFormPattern() -> UIPattern {
        UIPattern(
            name: "Basic Form",
            category: .forms,
            description: "Simple form with text fields and submit button",
            complexity: .simple,
            codeTemplate: """
struct BasicFormView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var notes = ""

    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("Name", text: $name)
                    .awareTextField("name-field", text: $name, label: "Name")
                    .awareState("name-field", key: "value", value: name)

                TextField("Email", text: $email)
                    .awareTextField("email-field", text: $email, label: "Email")
                    .awareState("email-field", key: "value", value: email)
                    .keyboardType(.emailAddress)
            }
            .awareContainer("personal-info-section", label: "Personal Information")

            Section("Additional Notes") {
                TextEditor(text: $notes)
                    .awareTextField("notes-field", text: $notes, label: "Notes")
                    .awareState("notes-field", key: "value", value: notes)
                    .frame(height: 100)
            }
            .awareContainer("notes-section", label: "Notes Section")

            Section {
                Button("Submit") {
                    submit()
                }
                .awareButton("submit-button", label: "Submit Form")
                .awareMetadata("submit-button", description: "Submits form data", type: "network")
                .disabled(name.isEmpty || email.isEmpty)
            }
        }
        .awareContainer("basic-form", label: "Basic Form")
    }

    func submit() {
        // Implementation
    }
}
""",
            elements: ["Form", "Section", "TextField", "TextEditor", "Button"],
            modifiersUsed: [".awareTextField", ".awareButton", ".awareState", ".awareMetadata", ".awareContainer"],
            bestPractices: [
                "Group fields into logical sections",
                "Track each field's state",
                "Validate required fields",
                "Use appropriate keyboard types"
            ],
            commonMistakes: [
                "Not tracking all field states",
                "Missing validation logic",
                "Not using Form sections"
            ],
            tokenEstimate: 198,
            exampleUseCases: ["Contact forms", "Feedback submission", "Data collection"]
        )
    }

    static func multiStepFormPattern() -> UIPattern {
        UIPattern(
            name: "Multi-Step Form (Wizard)",
            category: .forms,
            description: "Multi-page form with navigation between steps",
            complexity: .complex,
            codeTemplate: """
struct WizardFormView: View {
    @State private var currentStep = 0
    @State private var step1Data = ""
    @State private var step2Data = ""
    @State private var step3Data = ""

    var body: some View {
        VStack {
            // Progress indicator
            HStack(spacing: 10) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.blue : Color.gray)
                        .aware("step-indicator-\\(index)", label: "Step \\(index + 1) Indicator")
                        .awareState("step-indicator-\\(index)", key: "active", value: index <= currentStep)
                        .frame(width: 30, height: 30)
                }
            }
            .awareContainer("progress-indicator", label: "Progress Indicator")

            TabView(selection: $currentStep) {
                // Step 1
                stepView(step: 0, data: $step1Data)
                    .tag(0)

                // Step 2
                stepView(step: 1, data: $step2Data)
                    .tag(1)

                // Step 3
                stepView(step: 2, data: $step3Data)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .awareState("wizard-tab", key: "currentStep", value: currentStep)

            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Previous") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .awareButton("previous-button", label: "Previous Step")
                }

                Spacer()

                Button(currentStep == 2 ? "Finish" : "Next") {
                    if currentStep < 2 {
                        withAnimation {
                            currentStep += 1
                        }
                    } else {
                        finish()
                    }
                }
                .awareButton("next-button", label: currentStep == 2 ? "Finish" : "Next")
                .awareState("next-button", key: "step", value: currentStep)
            }
            .awareContainer("navigation-buttons", label: "Navigation Buttons")
        }
        .awareContainer("wizard-form", label: "Wizard Form")
        .awareState("wizard-form", key: "currentStep", value: currentStep)
        .padding()
    }

    func stepView(step: Int, data: Binding<String>) -> some View {
        VStack {
            Text("Step \\(step + 1)")
                .aware("step-\\(step)-title", label: "Step \\(step + 1) Title")
                .font(.title)

            TextField("Enter data", text: data)
                .awareTextField("step-\\(step)-input", text: data, label: "Step \\(step + 1) Input")
                .awareState("step-\\(step)-input", key: "value", value: data.wrappedValue)
                .textFieldStyle(.roundedBorder)
        }
        .awareContainer("step-\\(step)-view", label: "Step \\(step + 1) View")
    }

    func finish() {
        // Implementation
    }
}
""",
            elements: ["VStack", "HStack", "TabView", "Circle", "Text", "TextField", "Button"],
            modifiersUsed: [".aware", ".awareTextField", ".awareButton", ".awareState", ".awareContainer"],
            bestPractices: [
                "Track current step for navigation",
                "Show progress visually",
                "Allow backward navigation",
                "Track each step's data separately",
                "Use animations for transitions"
            ],
            commonMistakes: [
                "Not tracking currentStep state",
                "Missing progress indicator",
                "No backward navigation",
                "Not validating before advancing"
            ],
            tokenEstimate: 324,
            exampleUseCases: ["Onboarding flows", "Multi-page surveys", "Configuration wizards"]
        )
    }

    static func validatedFormPattern() -> UIPattern {
        UIPattern(
            name: "Validated Form",
            category: .forms,
            description: "Form with real-time validation and error messages",
            complexity: .moderate,
            codeTemplate: """
struct ValidatedFormView: View {
    @State private var email = ""
    @State private var age = ""
    @State private var emailError: String?
    @State private var ageError: String?

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Email", text: $email)
                        .awareTextField("email-field", text: $email, label: "Email")
                        .awareState("email-field", key: "value", value: email)
                        .onChange(of: email) { _, newValue in
                            validateEmail(newValue)
                        }

                    if let error = emailError {
                        Text(error)
                            .aware("email-error", label: "Email Error Message")
                            .awareState("email-error", key: "message", value: error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Age", text: $age)
                        .awareTextField("age-field", text: $age, label: "Age")
                        .awareState("age-field", key: "value", value: age)
                        .keyboardType(.numberPad)
                        .onChange(of: age) { _, newValue in
                            validateAge(newValue)
                        }

                    if let error = ageError {
                        Text(error)
                            .aware("age-error", label: "Age Error Message")
                            .awareState("age-error", key: "message", value: error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .awareContainer("form-fields", label: "Form Fields")

            Section {
                Button("Submit") {
                    submit()
                }
                .awareButton("submit-button", label: "Submit")
                .awareState("submit-button", key: "isValid", value: isValid)
                .disabled(!isValid)
            }
        }
        .awareContainer("validated-form", label: "Validated Form")
        .awareState("validated-form", key: "hasErrors", value: !isValid)
    }

    var isValid: Bool {
        emailError == nil && ageError == nil && !email.isEmpty && !age.isEmpty
    }

    func validateEmail(_ email: String) {
        if email.isEmpty {
            emailError = nil
        } else if !email.contains("@") {
            emailError = "Invalid email format"
        } else {
            emailError = nil
        }
    }

    func validateAge(_ age: String) {
        if age.isEmpty {
            ageError = nil
        } else if Int(age) == nil {
            ageError = "Must be a number"
        } else if let value = Int(age), value < 18 {
            ageError = "Must be 18 or older"
        } else {
            ageError = nil
        }
    }

    func submit() {
        // Implementation
    }
}
""",
            elements: ["Form", "Section", "VStack", "TextField", "Text", "Button"],
            modifiersUsed: [".awareTextField", ".aware", ".awareButton", ".awareState", ".awareContainer"],
            bestPractices: [
                "Validate on change, not just on submit",
                "Show inline error messages",
                "Track error state for each field",
                "Disable submit when invalid",
                "Use computed property for overall validation"
            ],
            commonMistakes: [
                "Only validating on submit",
                "Not tracking error messages as state",
                "Not showing validation feedback",
                "Missing keyboard type hints"
            ],
            tokenEstimate: 270,
            exampleUseCases: ["Contact forms", "Registration", "Data entry"]
        )
    }

    // MARK: - List Patterns
}
