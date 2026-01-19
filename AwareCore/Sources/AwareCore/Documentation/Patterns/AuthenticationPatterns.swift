//
//  AuthenticationPatterns.swift
//  Breathe
//
//  Authentication pattern examples extracted from CommonPatterns.swift
//  Phase 3.6 Architecture Refactoring
//

import Foundation

@MainActor
extension CommonPatternsLibrary {
    // MARK: - Authentication Patterns

    static func loginFormPattern() -> UIPattern {
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

    static func signupFormPattern() -> UIPattern {
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

    static func forgotPasswordPattern() -> UIPattern {
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
}
