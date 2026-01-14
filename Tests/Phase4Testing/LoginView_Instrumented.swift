import SwiftUI

// MARK: - Aware-Lite Protocol Stubs (paste once at project root)
extension View {
    func aware(_ id: String, label: String? = nil, captureVisuals: Bool = true, parent: String? = nil) -> some View { self }
    func awareContainer(_ id: String, label: String? = nil, parent: String? = nil) -> some View { self }
    func awareButton(_ id: String, label: String, parent: String? = nil) -> some View { self }
    func awareTextField(_ id: String, text: Binding<String>, label: String?, placeholder: String? = nil, isFocused: Binding<Bool>? = nil) -> some View { self }
    func awareSecureField(_ id: String, text: Binding<String>, label: String?, isFocused: Binding<Bool>? = nil) -> some View { self }
    func awareState(_ viewId: String, key: String, value: Any) -> some View { self }
}

// MARK: - Login View (Fully Instrumented with Protocol Stubs)
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
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || email.isEmpty || password.isEmpty)

            HStack {
                Button("Forgot Password?") {
                    // Handle forgot password
                }
                .awareButton("forgot-password", label: "Forgot Password")

                Spacer()

                Button("Create Account") {
                    // Handle signup
                }
                .awareButton("signup-link", label: "Create Account")
            }
            .awareContainer("login-actions", label: "Additional Actions")
            .font(.caption)
        }
        .awareContainer("login-form", label: "Login Form")
        .padding()
    }

    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            showError = true
            errorMessage = "Please enter both email and password"
            return
        }

        isLoading = true
        showError = false

        // Login API call would go here
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
        }
    }
}

// MARK: - Token Efficiency Demonstration
/*
**Snapshot Token Estimate for this view:**
- 9 UI elements instrumented
- ~18 tokens per element (compact format)
- Total: ~162 tokens

**Comparison:**
- Screenshot (2048x1536): ~15,000 tokens (99% reduction) ✅
- Accessibility Tree: ~1,500 tokens (89% reduction) ✅
- Raw SwiftUI code: ~400 tokens (60% reduction - but no runtime state)

**What LLM Gets:**
- Full UI hierarchy
- All state values (email, password, isLoading, showError, errorMessage)
- Element types and labels
- Enabled/disabled status
- Button press handlers
- Total: ~162 tokens
*/
