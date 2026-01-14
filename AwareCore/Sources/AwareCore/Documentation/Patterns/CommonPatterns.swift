//
//  CommonPatterns.swift
//  AwareCore
//
//  Common UI patterns library for protocol-based development.
//  Provides templates and best practices for typical SwiftUI views.
//

import Foundation

/// Common UI pattern template
public struct UIPattern: Codable, Sendable {
    public let name: String
    public let category: PatternCategory
    public let description: String
    public let complexity: PatternComplexity
    public let codeTemplate: String
    public let elements: [String]  // UI elements used
    public let modifiersUsed: [String]
    public let bestPractices: [String]
    public let commonMistakes: [String]
    public let tokenEstimate: Int  // Estimated tokens for instrumented version
    public let exampleUseCases: [String]
}

public enum PatternCategory: String, Codable, Sendable {
    case authentication = "Authentication"
    case forms = "Forms"
    case lists = "Lists"
    case navigation = "Navigation"
    case settings = "Settings"
    case dataEntry = "Data Entry"
    case feedback = "Feedback"
}

public enum PatternComplexity: String, Codable, Sendable {
    case simple = "Simple"
    case moderate = "Moderate"
    case complex = "Complex"
}

/// Common patterns library
@MainActor
public struct CommonPatternsLibrary {
    public static let patterns: [UIPattern] = [
        // MARK: - Authentication Patterns

        loginFormPattern(),
        signupFormPattern(),
        forgotPasswordPattern(),

        // MARK: - Form Patterns

        basicFormPattern(),
        multiStepFormPattern(),
        validatedFormPattern(),

        // MARK: - List Patterns

        simpleListPattern(),
        pullToRefreshListPattern(),
        searchableListPattern(),

        // MARK: - Navigation Patterns

        tabbedInterfacePattern(),
        masterDetailPattern(),
        wizardPattern(),

        // MARK: - Settings Patterns

        settingsPanelPattern(),
        preferencesGroupPattern(),

        // MARK: - Feedback Patterns

        loadingStatePattern(),
        errorStatePattern(),
        emptyStatePattern(),
    ]

    // MARK: - Authentication Patterns

    private static func loginFormPattern() -> UIPattern {
        UIPattern(
            name: "Login Form",
            category: .authentication,
            description: "Standard login form with email and password fields",
            complexity: .simple,
            codeTemplate: """
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome Back")
                .aware("welcome-title", label: "Welcome Back")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .awareTextField("email-field", text: $email, label: "Email")
                .awareState("email-field", key: "value", value: email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .awareSecureField("password-field", text: $password, label: "Password")
                .awareState("password-field", key: "value", value: password)
                .textFieldStyle(.roundedBorder)

            if showError {
                Text(errorMessage)
                    .aware("error-message", label: "Error Message")
                    .awareState("error-message", key: "text", value: errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(isLoading ? "Signing In..." : "Sign In") {
                login()
            }
            .awareButton("login-button", label: "Sign In")
            .awareState("login-button", key: "isLoading", value: isLoading)
            .awareMetadata("login-button", description: "Authenticates user with email/password", type: "network")
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || email.isEmpty || password.isEmpty)
        }
        .awareContainer("login-form", label: "Login Form")
        .padding()
    }

    func login() {
        // Implementation
    }
}
""",
            elements: ["Text", "TextField", "SecureField", "Button", "VStack"],
            modifiersUsed: [".aware", ".awareTextField", ".awareSecureField", ".awareButton", ".awareState", ".awareMetadata", ".awareContainer"],
            bestPractices: [
                "Use .awareTextField() with text binding for Ghost UI typing",
                "Track loading state with .awareState() for test assertions",
                "Add .awareMetadata() to describe network action",
                "Disable button during loading to prevent double-submission",
                "Use .awareContainer() to group related elements"
            ],
            commonMistakes: [
                "Forgetting to track email/password state",
                "Not disabling button during loading",
                "Missing error state tracking",
                "Using generic IDs like \"button\" instead of \"login-button\""
            ],
            tokenEstimate: 162,
            exampleUseCases: ["User authentication", "Account login", "Session initiation"]
        )
    }

    private static func signupFormPattern() -> UIPattern {
        UIPattern(
            name: "Signup Form",
            category: .authentication,
            description: "Registration form with email, password, and confirmation",
            complexity: .moderate,
            codeTemplate: """
struct SignupView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var agreedToTerms = false

    var body: some View {
        Form {
            Section("Account Information") {
                TextField("Email", text: $email)
                    .awareTextField("signup-email", text: $email, label: "Email")
                    .awareState("signup-email", key: "value", value: email)

                SecureField("Password", text: $password)
                    .awareSecureField("signup-password", text: $password, label: "Password")
                    .awareState("signup-password", key: "value", value: password)

                SecureField("Confirm Password", text: $confirmPassword)
                    .awareSecureField("confirm-password", text: $confirmPassword, label: "Confirm Password")
                    .awareState("confirm-password", key: "value", value: confirmPassword)
            }
            .awareContainer("account-info", label: "Account Information Section")

            Section {
                Toggle("I agree to Terms & Conditions", isOn: $agreedToTerms)
                    .awareToggle("terms-toggle", isOn: $agreedToTerms, label: "Terms Agreement")
            }
            .awareContainer("terms-section", label: "Terms Agreement Section")

            Section {
                Button("Create Account") {
                    signup()
                }
                .awareButton("signup-button", label: "Create Account")
                .awareState("signup-button", key: "isLoading", value: isLoading)
                .awareMetadata("signup-button", description: "Creates new user account", type: "network")
                .disabled(!isValid || isLoading)
            }
        }
        .awareContainer("signup-form", label: "Signup Form")
    }

    var isValid: Bool {
        !email.isEmpty && !password.isEmpty && password == confirmPassword && agreedToTerms
    }

    func signup() {
        // Implementation
    }
}
""",
            elements: ["Form", "Section", "TextField", "SecureField", "Toggle", "Button"],
            modifiersUsed: [".awareTextField", ".awareSecureField", ".awareToggle", ".awareButton", ".awareState", ".awareMetadata", ".awareContainer"],
            bestPractices: [
                "Group related fields in Form sections",
                "Track password confirmation separately",
                "Use .awareToggle() for terms acceptance",
                "Validate all fields before enabling submit",
                "Track validation state with computed property"
            ],
            commonMistakes: [
                "Not comparing password and confirmPassword",
                "Missing terms agreement validation",
                "Not tracking toggle state",
                "Allowing submission without agreement"
            ],
            tokenEstimate: 234,
            exampleUseCases: ["User registration", "Account creation", "New member signup"]
        )
    }

    private static func forgotPasswordPattern() -> UIPattern {
        UIPattern(
            name: "Forgot Password",
            category: .authentication,
            description: "Password reset flow with email submission",
            complexity: .simple,
            codeTemplate: """
struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var emailSent = false

    var body: some View {
        VStack(spacing: 20) {
            if !emailSent {
                Text("Reset Password")
                    .aware("reset-title", label: "Reset Password Title")
                    .font(.title)

                Text("Enter your email address and we'll send you a reset link")
                    .aware("instructions", label: "Instructions")
                    .font(.caption)
                    .multilineTextAlignment(.center)

                TextField("Email", text: $email)
                    .awareTextField("reset-email", text: $email, label: "Email")
                    .awareState("reset-email", key: "value", value: email)
                    .textFieldStyle(.roundedBorder)

                Button("Send Reset Link") {
                    sendResetEmail()
                }
                .awareButton("send-reset-button", label: "Send Reset Link")
                .awareState("send-reset-button", key: "isLoading", value: isLoading)
                .awareMetadata("send-reset-button", description: "Sends password reset email", type: "network")
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || isLoading)
            } else {
                Text("Check Your Email")
                    .aware("success-title", label: "Success Title")
                    .font(.title)

                Text("We've sent a password reset link to \\(email)")
                    .aware("success-message", label: "Success Message")
                    .awareState("success-message", key: "email", value: email)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .awareContainer("forgot-password-view", label: "Forgot Password View")
        .awareState("forgot-password-view", key: "emailSent", value: emailSent)
        .padding()
    }

    func sendResetEmail() {
        // Implementation
    }
}
""",
            elements: ["VStack", "Text", "TextField", "Button"],
            modifiersUsed: [".aware", ".awareTextField", ".awareButton", ".awareState", ".awareMetadata", ".awareContainer"],
            bestPractices: [
                "Show different content before/after email sent",
                "Track emailSent state for flow control",
                "Display submitted email in confirmation",
                "Disable button during sending"
            ],
            commonMistakes: [
                "Not tracking emailSent state",
                "Not showing confirmation message",
                "Missing loading state"
            ],
            tokenEstimate: 180,
            exampleUseCases: ["Password recovery", "Account reset", "Email verification"]
        )
    }

    // MARK: - Form Patterns

    private static func basicFormPattern() -> UIPattern {
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

    private static func multiStepFormPattern() -> UIPattern {
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

    private static func validatedFormPattern() -> UIPattern {
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

    private static func simpleListPattern() -> UIPattern {
        UIPattern(
            name: "Simple List",
            category: .lists,
            description: "Basic list view with items",
            complexity: .simple,
            codeTemplate: """
struct SimpleListView: View {
    @State private var items: [String] = ["Item 1", "Item 2", "Item 3"]

    var body: some View {
        List {
            ForEach(items, id: \\.self) { item in
                Text(item)
                    .aware("list-item-\\(item.hashValue)", label: item)
            }
        }
        .awareContainer("simple-list", label: "Simple List")
        .awareState("simple-list", key: "itemCount", value: items.count)
    }
}
""",
            elements: ["List", "ForEach", "Text"],
            modifiersUsed: [".aware", ".awareContainer", ".awareState"],
            bestPractices: [
                "Use .aware() on list items for tracking",
                "Track item count with .awareState()",
                "Use unique IDs for list items"
            ],
            commonMistakes: [
                "Not tracking individual items",
                "Not tracking list count",
                "Using non-unique IDs"
            ],
            tokenEstimate: 90,
            exampleUseCases: ["Menu lists", "Item catalogs", "Simple displays"]
        )
    }

    private static func pullToRefreshListPattern() -> UIPattern {
        UIPattern(
            name: "Pull-to-Refresh List",
            category: .lists,
            description: "List with pull-to-refresh functionality",
            complexity: .moderate,
            codeTemplate: """
struct RefreshableListView: View {
    @State private var items: [String] = []
    @State private var isRefreshing = false

    var body: some View {
        List {
            ForEach(items, id: \\.self) { item in
                Text(item)
                    .aware("list-item-\\(item.hashValue)", label: item)
            }
        }
        .refreshable {
            await refresh()
        }
        .awareContainer("refreshable-list", label: "Refreshable List")
        .awareState("refreshable-list", key: "isRefreshing", value: isRefreshing)
        .awareState("refreshable-list", key: "itemCount", value: items.count)
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        // Fetch new data
    }
}
""",
            elements: ["List", "ForEach", "Text"],
            modifiersUsed: [".aware", ".awareContainer", ".awareState"],
            bestPractices: [
                "Track isRefreshing state",
                "Use async/await for refresh",
                "Track item count changes"
            ],
            commonMistakes: [
                "Not tracking refresh state",
                "Not using async properly",
                "Missing count updates"
            ],
            tokenEstimate: 126,
            exampleUseCases: ["News feeds", "Social media", "Data lists"]
        )
    }

    private static func searchableListPattern() -> UIPattern {
        UIPattern(
            name: "Searchable List",
            category: .lists,
            description: "List with search bar filtering",
            complexity: .moderate,
            codeTemplate: """
struct SearchableListView: View {
    @State private var items = ["Apple", "Banana", "Cherry"]
    @State private var searchText = ""

    var filteredItems: [String] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            ForEach(filteredItems, id: \\.self) { item in
                Text(item)
                    .aware("list-item-\\(item.hashValue)", label: item)
            }
        }
        .searchable(text: $searchText)
        .awareContainer("searchable-list", label: "Searchable List")
        .awareState("searchable-list", key: "searchText", value: searchText)
        .awareState("searchable-list", key: "filteredCount", value: filteredItems.count)
    }
}
""",
            elements: ["List", "ForEach", "Text"],
            modifiersUsed: [".aware", ".awareContainer", ".awareState"],
            bestPractices: [
                "Track search text state",
                "Track filtered count",
                "Use computed property for filtering"
            ],
            commonMistakes: [
                "Not tracking search text",
                "Not tracking filtered results",
                "Filtering inefficiently"
            ],
            tokenEstimate: 144,
            exampleUseCases: ["Contact lists", "Product catalogs", "Directory search"]
        )
    }

    // MARK: - Navigation Patterns

    private static func tabbedInterfacePattern() -> UIPattern {
        UIPattern(
            name: "Tabbed Interface",
            category: .navigation,
            description: "Tab bar navigation with multiple views",
            complexity: .simple,
            codeTemplate: """
struct TabbedAppView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(2)
        }
        .awareContainer("tabbed-interface", label: "Tabbed Interface")
        .awareState("tabbed-interface", key: "selectedTab", value: selectedTab)
    }
}
""",
            elements: ["TabView", "Label"],
            modifiersUsed: [".awareContainer", ".awareState"],
            bestPractices: [
                "Track selected tab index",
                "Use semantic tab names",
                "Use SF Symbols for icons"
            ],
            commonMistakes: [
                "Not tracking selected tab",
                "Missing tab labels",
                "Not using proper tags"
            ],
            tokenEstimate: 108,
            exampleUseCases: ["App navigation", "Multi-section apps", "Tab interfaces"]
        )
    }

    private static func masterDetailPattern() -> UIPattern {
        UIPattern(
            name: "Master-Detail",
            category: .navigation,
            description: "Two-column layout with list and detail view",
            complexity: .moderate,
            codeTemplate: """
struct MasterDetailView: View {
    @State private var items = ["Item 1", "Item 2"]
    @State private var selectedItem: String?

    var body: some View {
        NavigationSplitView {
            List(items, id: \\.self, selection: $selectedItem) { item in
                Text(item)
                    .aware("master-item-\\(item.hashValue)", label: item)
            }
            .awareContainer("master-list", label: "Master List")
            .awareState("master-list", key: "itemCount", value: items.count)
            .navigationTitle("Items")
        } detail: {
            if let item = selectedItem {
                DetailView(item: item)
                    .awareContainer("detail-view", label: "Detail View")
                    .awareState("detail-view", key: "selectedItem", value: item)
            } else {
                Text("Select an item")
                    .aware("no-selection", label: "No Selection Placeholder")
            }
        }
        .awareState("master-detail", key: "hasSelection", value: selectedItem != nil)
    }
}
""",
            elements: ["NavigationSplitView", "List", "Text"],
            modifiersUsed: [".aware", ".awareContainer", ".awareState"],
            bestPractices: [
                "Track selected item",
                "Show placeholder when nothing selected",
                "Track item count in master list"
            ],
            commonMistakes: [
                "Not tracking selection",
                "No placeholder for empty selection",
                "Missing navigation titles"
            ],
            tokenEstimate: 162,
            exampleUseCases: ["Email clients", "File browsers", "Settings panels"]
        )
    }

    private static func wizardPattern() -> UIPattern {
        UIPattern(
            name: "Wizard/Stepper",
            category: .navigation,
            description: "Step-by-step guided flow",
            complexity: .complex,
            codeTemplate: """
// See multiStepFormPattern() for full implementation
""",
            elements: ["VStack", "TabView", "Button"],
            modifiersUsed: [".aware", ".awareButton", ".awareState", ".awareContainer"],
            bestPractices: [
                "Show progress clearly",
                "Allow backward navigation",
                "Track current step",
                "Validate before advancing"
            ],
            commonMistakes: [
                "No visual progress indicator",
                "Can't go back",
                "Missing step validation"
            ],
            tokenEstimate: 324,
            exampleUseCases: ["Onboarding", "Setup flows", "Configuration"]
        )
    }

    // MARK: - Settings Patterns

    private static func settingsPanelPattern() -> UIPattern {
        UIPattern(
            name: "Settings Panel",
            category: .settings,
            description: "Standard settings screen with grouped options",
            complexity: .simple,
            codeTemplate: """
struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var fontSize = 14.0

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .awareToggle("notifications-toggle", isOn: $notificationsEnabled, label: "Enable Notifications")
            }
            .awareContainer("notifications-section", label: "Notifications Section")

            Section("Appearance") {
                Toggle("Dark Mode", isOn: $darkModeEnabled)
                    .awareToggle("dark-mode-toggle", isOn: $darkModeEnabled, label: "Dark Mode")

                Slider(value: $fontSize, in: 10...20, step: 1) {
                    Text("Font Size")
                }
                .awareState("font-size-slider", key: "value", value: fontSize)
            }
            .awareContainer("appearance-section", label: "Appearance Section")
        }
        .awareContainer("settings-view", label: "Settings View")
    }
}
""",
            elements: ["Form", "Section", "Toggle", "Slider", "Text"],
            modifiersUsed: [".awareToggle", ".awareState", ".awareContainer"],
            bestPractices: [
                "Group settings into sections",
                "Use .awareToggle() for boolean settings",
                "Track slider values with .awareState()",
                "Use semantic section names"
            ],
            commonMistakes: [
                "Not tracking toggle states",
                "Not tracking slider values",
                "Missing section organization"
            ],
            tokenEstimate: 180,
            exampleUseCases: ["App preferences", "User settings", "Configuration panels"]
        )
    }

    private static func preferencesGroupPattern() -> UIPattern {
        UIPattern(
            name: "Preferences Group",
            category: .settings,
            description: "Grouped preferences with labels",
            complexity: .simple,
            codeTemplate: """
struct PreferencesGroupView: View {
    @State private var option1 = true
    @State private var option2 = false
    @State private var selection = 0

    var body: some View {
        Form {
            Section("Options") {
                Toggle("Option 1", isOn: $option1)
                    .awareToggle("option-1-toggle", isOn: $option1, label: "Option 1")

                Toggle("Option 2", isOn: $option2)
                    .awareToggle("option-2-toggle", isOn: $option2, label: "Option 2")
            }
            .awareContainer("options-section", label: "Options Section")

            Section("Choice") {
                Picker("Select", selection: $selection) {
                    Text("Choice A").tag(0)
                    Text("Choice B").tag(1)
                    Text("Choice C").tag(2)
                }
                .awareState("selection-picker", key: "value", value: selection)
            }
            .awareContainer("choice-section", label: "Choice Section")
        }
        .awareContainer("preferences-group", label: "Preferences Group")
    }
}
""",
            elements: ["Form", "Section", "Toggle", "Picker", "Text"],
            modifiersUsed: [".awareToggle", ".awareState", ".awareContainer"],
            bestPractices: [
                "Group related preferences",
                "Track all toggle states",
                "Track picker selections",
                "Use descriptive labels"
            ],
            commonMistakes: [
                "Not tracking picker state",
                "Missing preference labels",
                "Not grouping logically"
            ],
            tokenEstimate: 162,
            exampleUseCases: ["Settings groups", "Preference panels", "Configuration"]
        )
    }

    // MARK: - Feedback Patterns

    private static func loadingStatePattern() -> UIPattern {
        UIPattern(
            name: "Loading State",
            category: .feedback,
            description: "Loading indicator with message",
            complexity: .simple,
            codeTemplate: """
struct LoadingStateView: View {
    @State private var isLoading = true
    @State private var loadingMessage = "Loading data..."

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView()
                    .aware("loading-spinner", label: "Loading Indicator")
                    .scaleEffect(1.5)

                Text(loadingMessage)
                    .aware("loading-message", label: "Loading Message")
                    .awareState("loading-message", key: "text", value: loadingMessage)
                    .font(.caption)
            } else {
                ContentView()
            }
        }
        .awareContainer("loading-state-view", label: "Loading State View")
        .awareState("loading-state-view", key: "isLoading", value: isLoading)
    }
}
""",
            elements: ["VStack", "ProgressView", "Text"],
            modifiersUsed: [".aware", ".awareState", ".awareContainer"],
            bestPractices: [
                "Track isLoading state",
                "Show descriptive message",
                "Track message text",
                "Show progress indicator"
            ],
            commonMistakes: [
                "Not tracking loading state",
                "Missing loading message",
                "No progress indicator"
            ],
            tokenEstimate: 108,
            exampleUseCases: ["Data loading", "Network requests", "Async operations"]
        )
    }

    private static func errorStatePattern() -> UIPattern {
        UIPattern(
            name: "Error State",
            category: .feedback,
            description: "Error display with retry action",
            complexity: .simple,
            codeTemplate: """
struct ErrorStateView: View {
    @State private var hasError = true
    @State private var errorMessage = "Failed to load data"
    @State private var canRetry = true

    var body: some View {
        VStack(spacing: 20) {
            if hasError {
                Image(systemName: "exclamationmark.triangle")
                    .aware("error-icon", label: "Error Icon")
                    .font(.system(size: 50))
                    .foregroundColor(.red)

                Text(errorMessage)
                    .aware("error-message", label: "Error Message")
                    .awareState("error-message", key: "text", value: errorMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                if canRetry {
                    Button("Retry") {
                        retry()
                    }
                    .awareButton("retry-button", label: "Retry")
                    .awareMetadata("retry-button", description: "Retries failed operation", type: "action")
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ContentView()
            }
        }
        .awareContainer("error-state-view", label: "Error State View")
        .awareState("error-state-view", key: "hasError", value: hasError)
        .awareState("error-state-view", key: "canRetry", value: canRetry)
        .padding()
    }

    func retry() {
        // Implementation
    }
}
""",
            elements: ["VStack", "Image", "Text", "Button"],
            modifiersUsed: [".aware", ".awareButton", ".awareState", ".awareMetadata", ".awareContainer"],
            bestPractices: [
                "Track hasError state",
                "Show descriptive error message",
                "Provide retry action",
                "Track canRetry state"
            ],
            commonMistakes: [
                "Not tracking error state",
                "Generic error messages",
                "No retry option",
                "Missing error tracking"
            ],
            tokenEstimate: 144,
            exampleUseCases: ["Network errors", "Failed operations", "Data loading errors"]
        )
    }

    private static func emptyStatePattern() -> UIPattern {
        UIPattern(
            name: "Empty State",
            category: .feedback,
            description: "Empty state with call-to-action",
            complexity: .simple,
            codeTemplate: """
struct EmptyStateView: View {
    @State private var isEmpty = true
    @State private var emptyMessage = "No items yet"

    var body: some View {
        VStack(spacing: 20) {
            if isEmpty {
                Image(systemName: "tray")
                    .aware("empty-icon", label: "Empty State Icon")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)

                Text(emptyMessage)
                    .aware("empty-message", label: "Empty State Message")
                    .awareState("empty-message", key: "text", value: emptyMessage)
                    .font(.headline)
                    .foregroundColor(.secondary)

                Button("Add Item") {
                    addItem()
                }
                .awareButton("add-item-button", label: "Add Item")
                .awareMetadata("add-item-button", description: "Creates first item", type: "action")
                .buttonStyle(.borderedProminent)
            } else {
                ContentView()
            }
        }
        .awareContainer("empty-state-view", label: "Empty State View")
        .awareState("empty-state-view", key: "isEmpty", value: isEmpty)
        .padding()
    }

    func addItem() {
        // Implementation
    }
}
""",
            elements: ["VStack", "Image", "Text", "Button"],
            modifiersUsed: [".aware", ".awareButton", ".awareState", ".awareMetadata", ".awareContainer"],
            bestPractices: [
                "Track isEmpty state",
                "Show helpful empty message",
                "Provide call-to-action",
                "Use descriptive icon"
            ],
            commonMistakes: [
                "Not tracking empty state",
                "Missing CTA button",
                "Unhelpful message",
                "No visual indicator"
            ],
            tokenEstimate: 126,
            exampleUseCases: ["Empty lists", "No data states", "First-time user experience"]
        )
    }
}
